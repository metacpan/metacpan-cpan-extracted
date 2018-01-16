use strict;
use warnings;

package Footprintless::Plugin::Database::PostgreSqlProvider;
$Footprintless::Plugin::Database::PostgreSqlProvider::VERSION = '1.04';
# ABSTRACT: A PostgreSql provider implementation
# PODNAME: Footprintless::Plugin::Database::AbstractProvider

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

    if ( eval { $to->isa('Footprintless::Plugin::Database::PostgreSqlProvider') } ) {
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
        $logger->debug('sending to a callback');
        $self->_run_or_die( $command, { out_callback => $to, err_handle => \*STDERR } );
    }
    elsif ( ref($to) eq 'GLOB' ) {
        $logger->debug('writing to GLOB');
        $self->_run_or_die( $command, { out_handle => $to, err_handle => \*STDERR } );
    }
    else {
        $logger->debug( 'writing to file ', $to );
        open( my $filehandle, '>', $to );
        $self->_run_or_die( $command, { out_handle => $filehandle, err_handle => \*STDERR } );
        close($filehandle);
    }
    $logger->info('finished backing up database');
}

sub _client_command {
    my ( $self, $command, $database, @additional_options ) = @_;

    my $cnf = $self->_cnf();
    my ( $hostname, $port ) = $self->_hostname_port();

    $ENV{PGPASSFILE} = $cnf;
    if ( $self->{schema} ) {
        $ENV{PGOPTIONS} = "-c search_path=$self->{schema}";
    }
    return join( ' ',
        $command, "-h $hostname", "-p $port", "-U $self->{username}",
        @additional_options, $database );
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

        my $command =
            $self->_client_command( 'psql', $self->{database}, @{ $options{client_options} } );
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

    unless ( $self->{cnf} ) {
        File::Temp->safe_level(File::Temp::HIGH);
        my $cnf = File::Temp->new();

        if ( !chmod( 0600, $cnf ) ) {
            croak("unable to create secure temp file");
        }
        print( $cnf "*:*:*:*:$self->{password}\n" );
        close($cnf);

        $self->{cnf} = $cnf;
    }

    return $self->{cnf};
}

sub _connection_string {
    my ($self) = @_;
    my ( $hostname, $port ) = $self->_hostname_port();

    my @pg_options = ();
    if ( $self->{schema} ) {
        push( @pg_options, "-c search_path=$self->{schema}" );
    }

    return join( '',
        'DBI:Pg:', 'dbname=', $self->{database}, ';', 'host=', $hostname, ';', 'port=', $port,
        ( @pg_options ? ( "options=", join( ' ', @pg_options ) ) : () ) );
}

sub _dump_command {
    my ( $self, %options ) = @_;

    my $dump_command;
    if ( $options{live} || !defined( $self->{backup} ) ) {
        my $cnf = $self->_cnf();
        my ( $hostname, $port ) = $self->_hostname_port();

        my $size = $self->query_for_scalar(
            {   sql        => "select pg_database_size(?)",
                parameters => [ $self->{database} ]
            }
        );

        $dump_command = pipe_command(
            $self->_client_command( 'pg_dump', $self->{database}, '--create', '--clean' ),
            "pv -f " . ( $size ? "-s $size" : "-b" ) );
    }
    else {
        die("dump from backup not yet implemented");
    }

    if ( $options{pipeline} ) {
        $dump_command = pipe_command( $dump_command, @{ $options{pipeline} } );
    }

    return $dump_command;
}

sub _init {
    my ( $self, %options ) = @_;
    $self->Footprintless::Plugin::Database::AbstractProvider::_init(%options);

    $self->{port} = 5432 unless ( $self->{port} );

    return $self;
}

sub restore {
    my ( $self, $from, %options ) = @_;

    croak('not connected restore') unless ( $self->{connection} );

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
            my $drop_views_sql = 'drop view `' . join( "`,`", @views ) . '`';
            $logger->info( $self->{hostname}, ': ', $drop_views_sql );
            $self->execute( { sql => $drop_views_sql } );
        }

        if (@tables) {
            my $drop_tables_sql = 'drop table `' . join( "`,`", @tables ) . '`';
            $logger->info( $self->{hostname}, ': ', $drop_tables_sql );
            $self->execute( { sql => $drop_tables_sql } );
        }
    }

    eval {
        $logger->debug("Forcibly disconnecting all clients");
        $self->execute(
            {   sql => "select pg_terminate_backend(pid) from pg_stat_activity where datname = ?",
                parameters => [ $self->{database} ]
            }
        );
    };

    my $command = $self->_client_command( 'psql', $self->{database} );

    if ( eval { $from->isa('Footprintless::Plugin::Database::PostgreSqlProvider') } ) {
        $logger->debug("Restoring from another postgres instance");
        $self->_run_or_die( pipe_command( $options{backup}{command}, $command ),
            { err_handle => \*STDERR } );
        if (   $options{backup}{options}
            && $options{backup}{options}{post_restore} )
        {
            $self->_run_or_die(
                pipe_command( "cat \"$options{backup}{options}{post_restore}\"", $command ) );
        }
    }
    elsif ( ref($from) eq 'HASH' ) {
        $logger->debug("Restoring from HASH");
        $self->_run_or_die( pipe_command( $from->{command}, $command ),
            { err_handle => \*STDERR } );
        if (   $from->{options}
            && $from->{options}{post_restore} )
        {
            $self->_run_or_die(
                pipe_command( "cat \"$from->{options}{post_restore}\"", $command ) );
        }
    }
    elsif ( ref($from) eq 'GLOB' ) {
        $logger->debug('Restoring from GLOB');
        $self->_run_or_die(
            pipe_command( "pv -b", $command ),
            {   in_handle  => $from,
                err_handle => \*STDERR
            }
        );
        if ( $options{post_restore} ) {
            $self->_run_or_die( pipe_command( "cat \"$options{post_restore}\"", $command ) );
        }
    }
    else {
        $logger->debug( 'Restoring from ', $from );
        $self->_run_or_die( pipe_command( "pv $from", $command ), { err_handle => \*STDERR } );
        if ( $options{post_restore} ) {
            $self->_run_or_die( pipe_command( "cat \"$options{post_restore}\"", $command ) );
        }
    }
    $logger->info("finished restoring database");
}

1;

__END__

=pod

=head1 NAME

Footprintless::Plugin::Database::AbstractProvider - A PostgreSql provider implementation

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
