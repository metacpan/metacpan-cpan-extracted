use strict;
use warnings;

package Footprintless::Plugin::Database::OracleProvider;
$Footprintless::Plugin::Database::OracleProvider::VERSION = '1.04';
# ABSTRACT: A Oracle provider implementation
# PODNAME: Footprintless::Plugin::Database::OracleProvider

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

sub _client_command {
    my ( $self, $command, @additional_options ) = @_;

    my $cnf = $self->_cnf();
    my ( $hostname, $port ) = $self->_hostname_port();

    return join( ' ', $command, @additional_options );
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

        my $command = $self->_client_command(
            'sqlplus', @{ $options{client_options} },
            '/nolog', sprintf( "'\@%s'", $self->_cnf() )
        );
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
        my ( $hostname, $port ) = $self->_hostname_port();
        File::Temp->safe_level(File::Temp::HIGH);
        my $cnf = File::Temp->new( SUFFIX => '.sql' );
        if ( !chmod( 0600, $cnf ) ) {
            croak("unable to create secure temp file");
        }
        printf( $cnf "connect %s/%s\@%s:%d/%s\n",
            $self->{username}, $self->{password}, $hostname, $port, $self->{schema} );
        close($cnf);
        $self->{cnf} = $cnf;
        if ( lc($^O) eq 'cygwin' ) {
            $self->{cnf_ms_windows} = `cygpath --windows $cnf`;
            chomp( $self->{cnf_ms_windows} );
        }
    }

    return $self->{cnf_ms_windows} || $self->{cnf};
}

sub _connection_string {
    my ($self) = @_;
    my ( $hostname, $port ) = $self->_hostname_port();
    return sprintf( "dbi:Oracle://%s:%d/%s", $hostname, $port, $self->{schema} );
}

sub _init {
    my ( $self, %options ) = @_;
    $self->Footprintless::Plugin::Database::AbstractProvider::_init(%options);

    $self->{port} = 3306 unless ( $self->{port} );

    return $self;
}

1;

__END__

=pod

=head1 NAME

Footprintless::Plugin::Database::OracleProvider - A Oracle provider implementation

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
