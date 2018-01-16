use strict;
use warnings;

package Footprintless::Plugin::Database::MySqlProvider;
$Footprintless::Plugin::Database::MySqlProvider::VERSION = '1.04';
# ABSTRACT: A MySql provider implementation
# PODNAME: Footprintless::Plugin::Database::MySqlProvider

use parent qw(Footprintless::Plugin::Database::AbstractProvider);

use overload q{""} => 'to_string', fallback => 1;

use Carp;
use File::Temp;
use Footprintless::Command qw(
    command
    pipe_command
    sed_command
);
use Footprintless::Mixins qw(
    _run_or_die
);
use Log::Any;

my $logger = Log::Any->get_logger();

sub backup {
    my ( $self, $to, %options ) = @_;

    croak("not connected backup")
        unless ( $self->{connection}
        || ( !$options{live} && defined( $self->{backup} ) ) );

    $logger->info('backing up database');
    if ( $options{ignore_all_views} ) {
        my @views = ();
        $self->query(
            {   sql => 'select table_name '
                    . 'from information_schema.tables '
                    . 'where table_type like \'VIEW\' and table_schema = ?',
                parameters => [ $self->{schema} ]
            },
            sub {
                push( @views, $_[0] );
            }
        );

        if (@views) {
            if ( !$options{ignore_tables} ) {
                $options{ignore_tables} = \@views;
            }
            else {
                push( @{ $options{ignore_tables} }, @views );
            }
        }
    }

    my $command = $self->_dump_command(%options);

    if ( eval { $to->isa('Footprintless::Plugin::Database::MySqlProvider') } ) {
        $to->restore(
            $self,
            'clean'  => $options{clean},
            'backup' => {
                command => $command,
                options => \%options
            }
        );
    }
    elsif ( ref($to) eq 'CODE' ) {
        $self->_run_or_die(
            $command,
            {   out_callback => $to,
                err_handle   => \*STDERR
            }
        );
    }
    elsif ( ref($to) eq 'GLOB' ) {
        $logger->debug('writing to GLOB');
        $self->_run_or_die(
            $command,
            {   out_handle => $to,
                err_handle => \*STDERR
            }
        );
    }
    else {
        $logger->debugf( 'writing to file %s', $to );
        open( my $filehandle, '>', $to );
        $self->_run_or_die(
            $command,
            {   out_handle => $filehandle,
                err_handle => \*STDERR
            }
        );
        close($filehandle);
    }

    $logger->info('finished backing up database');
}

sub _client_command {
    my ( $self, $command, @additional_options ) = @_;

    my $cnf = $self->_cnf();
    my ( $hostname, $port ) = $self->_hostname_port();

    return join( ' ',
        $command, "--defaults-file=$cnf", '--default-character-set=utf8',
        '--max_allowed_packet=512M', "-h $hostname", "-P $port", @additional_options,
        $self->{schema} );
}

sub client {
    my ( $self, %options ) = @_;

    my $in_file;
    eval {
        my $in_handle = delete( $options{in_handle} );
        if ( $options{in_file} ) {
            open( $in_file, '<', delete( $options{in_file} ) )
                || croak("invalid in_file: $!");
        }
        if ( $options{in_string} ) {
            my $string = delete( $options{in_string} );
            open( $in_file, '<', \$string )
                || croak("invalid in_string: $!");
        }
        $self->_connect_tunnel();

        my $command = $self->_client_command( 'mysql', @{ $options{client_options} } );
        $self->_run_or_die(
            $command,
            {   in_handle => $in_file || $in_handle || \*STDIN,
                out_handle => \*STDOUT,
                err_handle => \*STDERR
            }
        );
    };
    my $error = $@;
    $self->disconnect();
    if ($in_file) {
        close($in_file);
    }

    croak($error) if ($error);
}

sub _cnf {
    my ($self) = @_;

    if ( !$self->{cnf} ) {
        File::Temp->safe_level(File::Temp::HIGH);
        my $cnf = File::Temp->new();
        if ( !chmod( 0600, $cnf ) ) {
            croak("unable to create secure temp file");
        }
        print( $cnf
                join( "\n", '[client]', "user=$self->{username}", "password=$self->{password}" )
        );
        close($cnf);

        $self->{cnf} = $cnf;
    }

    return $self->{cnf};
}

sub _connection_string {
    my ($self) = @_;
    my ( $hostname, $port ) = $self->_hostname_port();
    return join( '',
        'DBI:mysql:', 'database=', $self->{schema}, ';', 'host=',
        $hostname,    ';',         'port=',         $port );
}

sub _dump_command {
    my ( $self, %options ) = @_;

    my $dump_command;
    if ( $options{live} || !defined( $self->{backup} ) ) {
        my @only_tables       = ();
        my $and_in_tables     = '';
        my @ignore_tables     = ();
        my $and_not_in_tables = '';
        my @parameters;
        if ( defined( $options{only_tables} ) && scalar( @{ $options{only_tables} } ) ) {
            my @in_placeholders = ();
            foreach my $table ( @{ $options{only_tables} } ) {
                push( @in_placeholders, '?' );
                push( @only_tables,     $table );
                push( @parameters,      $table );
            }
            $and_in_tables = ' AND table_name IN (' . join( ',', @in_placeholders ) . ')';
        }
        elsif ( defined( $options{ignore_tables} ) && scalar( @{ $options{ignore_tables} } ) ) {
            my @not_in_placeholders = ();
            foreach my $table ( @{ $options{ignore_tables} } ) {
                push( @not_in_placeholders, '?' );
                push( @ignore_tables,       "--ignore-table=$self->{schema}.$table" );
                push( @parameters,          $table );
            }
            $and_not_in_tables =
                ' AND table_name NOT IN (' . join( ',', @not_in_placeholders ) . ')';
        }

        my $cnf = $self->_cnf();
        my ( $hostname, $port ) = $self->_hostname_port();

        my $size =
            $options{where}
            ? 0
            : $self->query_for_scalar(
            {   sql => 'SELECT SUM(data_length + index_length) AS bytes '
                    . 'FROM information_schema.TABLES '
                    . 'WHERE table_schema = ? '
                    . $and_in_tables
                    . $and_not_in_tables,
                parameters => [ $self->{schema}, @parameters ]
            }
            );

        my $client_command = $self->_client_command(
            'mysqldump',
            ( $options{where}              ? "--where=\"$options{where}\"" : () ),
            ( $options{single_transaction} ? "--single-transaction"        : () ),
            @ignore_tables
        );
        $dump_command = pipe_command(
            join( ' ', $client_command, @only_tables ),
            "pv -f " . ( $size ? "-s $size" : "-b" )
        );
    }
    else {
        my $backup_base = $self->{backup}{base};
        my $command_options =
              $self->{backup}{command_options}
            ? $self->{factory}->command_options( %{ $self->{backup}{command_options} } )
            : $self->{factory}->command_options( hostname => $self->{hostname} );

        # find backup file
        require Date::Parse;
        my $listing = $self->_run_or_die( command( "ls $backup_base", $command_options ),
            { out_buffer => 1, timeout => 10 } );
        my @folders = split( /\s+/, $listing );
        my $most_recent;
        my $most_recent_time = 0;
        foreach my $folder (@folders) {
            my $folder_time = Date::Parse::str2time($folder);
            if ( $folder_time > $most_recent_time ) {
                $most_recent      = $folder;
                $most_recent_time = $folder_time;
            }
        }
        my $backup_file = "$backup_base/$most_recent/$self->{schema}.sql.gz";

        # get size of file for progress meter
        my $size = int(
            $self->_run_or_die(
                command( "stat -c \"\%s\" $backup_file", $command_options ),
                { out_buffer => 1, timeout => 10 }
            )
        );

        # build the command
        $dump_command = pipe_command( command( "cat $backup_file", $command_options ),
            "pv -f -s $size", "gunzip" );
    }

    return pipe_command(
        $dump_command,
        sed_command(
            {   replace_map => {
                    'VIEW `[^`]`'      => 'VIEW ',
                    'DEFINER=[^*]*\\*' => '\\*'
                }
            }
        ),
        ( $options{pipeline} ? @{ $options{pipeline} } : () )
    );
}

sub _init {
    my ( $self, %options ) = @_;
    $self->Footprintless::Plugin::Database::AbstractProvider::_init(%options);

    $self->{port} = 3306 unless ( $self->{port} );

    return $self;
}

sub restore {
    my ( $self, $from, %options ) = @_;

    croak('not connected backup') unless ( $self->{connection} );

    $logger->infof( 'restoring database on %s', $self->{hostname} );

    if ( $options{clean} ) {
        my @tables = ();
        my @views  = ();
        $self->query(
            {   sql => 'select table_name, table_type '
                    . 'from information_schema.tables '
                    . 'where table_schema = ?',
                parameters => [ $self->{schema} ]
            },
            sub {
                my ( $table_name, $table_type ) = @_;
                if ( uc($table_type) eq 'VIEW' ) {
                    push( @views, $table_name );
                }
                else {
                    push( @tables, $table_name );
                }
            }
        );

        if (@views) {
            my $drop_views_sql = 'drop view `' . join( '`,`', @views ) . '`';
            $logger->infof( 'dropping views: %s', $drop_views_sql );
            $self->execute( { sql => $drop_views_sql } );
        }

        if (@tables) {
            my $drop_tables_sql = 'drop table `' . join( '`,`', @tables ) . '`';
            $logger->infof( 'dropping tables: %s', $drop_tables_sql );
            $self->execute( { sql => $drop_tables_sql } );
        }
    }

    my $command = $self->_client_command('mysql');

    if ( eval { $from->isa('Footprintless::Plugin::Database::MySqlProvider') } ) {
        $logger->debug('Restoring from another mysql instance');
        $self->_run_or_die( pipe_command( $options{backup}{command}, $command ),
            { err_handle => \*STDERR } );

        $options{post_restore} = $options{backup}{options}{post_restore}
            if ( $options{backup}{options} );
    }
    elsif ( ref($from) eq 'HASH' ) {
        $logger->debug("Restoring from HASH");
        $self->_run_or_die( pipe_command( $from->{command}, $command ),
            { err_handle => \*STDERR } );

        $options{post_restore} = $from->{options}{post_restore}
            if ( $from->{options} );
    }
    elsif ( ref($from) eq 'GLOB' ) {
        $logger->debug('Restoring from GLOB');
        $self->_run_or_die(
            pipe_command( "pv -b", $command ),
            {   in_handle  => $from,
                err_handle => \*STDERR
            }
        );
    }
    else {
        $logger->debugf( 'Restoring from %s', $from );
        $self->_run_or_die( pipe_command( "pv $from", $command ), { err_handle => \*STDERR } );
    }

    if ( $options{post_restore} ) {
        $self->_run_or_die( pipe_command( "cat \"$options{post_restore}\"", $command ) );
    }

    $logger->info("finished restoring database");
}

1;

__END__

=pod

=head1 NAME

Footprintless::Plugin::Database::MySqlProvider - A MySql provider implementation

=head1 VERSION

version 1.04

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless::Plugin::Database|Footprintless::Plugin::Database>

=back

=cut
