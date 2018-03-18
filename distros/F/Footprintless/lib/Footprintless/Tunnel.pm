use strict;
use warnings;

package Footprintless::Tunnel;
$Footprintless::Tunnel::VERSION = '1.28';
# ABSTRACT: Provides tunneling over ssh
# PODNAME: Footprintless::Tunnel

use parent qw(Footprintless::MixableBase);

use Carp;
use File::Path qw(make_path);
use File::Spec;
use File::Temp;
use Footprintless::Mixins qw(
    _entity
);
use IO::Socket::INET;
use Log::Any;
use POSIX ":sys_wait_h";

my $logger = Log::Any->get_logger();

my $number = 0;

sub _build_command {
    my ( $self, $command ) = @_;

    my @command = ( $self->{ssh}, ' -S ', $self->{control_socket} );

    if ( $command eq 'open' ) {
        push( @command, ' -nfN -oControlMaster=yes -L ' );
        if ( $self->{local_hostname} ) {
            push( @command, $self->{local_hostname}, ':' );
        }
        push( @command,
            $self->{local_port}, ':', $self->{destination_hostname},
            ':',                 $self->{destination_port} );
    }
    else {
        push( @command, ' -O ', $command );
    }

    push( @command, ' ' );
    if ( $self->{tunnel_username} ) {
        push( @command, $self->{tunnel_username}, '@' );
    }
    push( @command, $self->{tunnel_hostname}, ' 2> /dev/null' );

    return join( '', @command );
}

sub close {
    my ($self) = @_;

    if ( $self->{pid} ) {
        my $command = $self->_build_command('exit');
        $logger->tracef( 'closing tunnel with: `%s`', $command );
        `$command`;
        my $child = waitpid( $self->{pid}, WNOHANG );
        $logger->debugf( 'forked child closed: %s', $child );
        delete( $self->{control_socket} );
        delete( $self->{pid} );
        if ( $self->{dynamic_local_port} ) {
            delete( $self->{local_port} );
            delete( $self->{dynamic_local_port} );
        }
    }
}

sub DESTROY {
    $_[0]->close();
}

sub _find_port {

    # results in slight race condition, but for now, its ok.
    my $sock = IO::Socket::INET->new(
        Proto     => 'tcp',
        LocalPort => 0,
        LocalAddr => 'localhost'
    );
    my $port = $sock->sockport();
    $sock->close();
    return $port;
}

sub get_local_hostname {
    return $_[0]->{local_hostname};
}

sub get_local_port {
    return $_[0]->{local_port};
}

sub _init {
    my ( $self, %options ) = @_;

    my $entity = $self->_entity( $self->{coordinate} );
    $self->{ssh} = $options{ssh} || $entity->{ssh} || 'ssh -q';
    $self->{local_hostname} = $options{local_hostname}
        || $entity->{local_hostname};
    $self->{local_port} = $options{local_port} || $entity->{local_port};
    $self->{tunnel_hostname} = $options{tunnel_hostname}
        || $entity->{tunnel_hostname};
    $self->{tunnel_username} = $options{tunnel_username}
        || $entity->{tunnel_username};
    $self->{destination_hostname} = $options{destination_hostname}
        || $entity->{destination_hostname};
    $self->{destination_port} = $options{destination_port}
        || $entity->{destination_port};
    $self->{control_socket_dir} =
           $options{control_socket_dir}
        || $entity->{control_socket_dir}
        || File::Spec->catdir( ( $ENV{HOME} ? $ENV{HOME} : $ENV{USERPROFILE} ),
        '.ssh', 'control_socket' );
    $self->{tries} = $options{tries} || $entity->{tries} || 10;
    $self->{wait_seconds} =
           $options{wait_seconds}
        || $entity->{wait_seconds}
        || 1;

    return $self;
}

sub is_open {
    my ($self) = @_;

    if ( !$self->{control_socket} ) {
        return 0;
    }

    my $command = $self->_build_command('check');
    $logger->tracef( 'checking tunnel with: `%s`', $command );
    `$command`;
    return ( WIFEXITED( ${^CHILD_ERROR_NATIVE} ) && WEXITSTATUS( ${^CHILD_ERROR_NATIVE} ) == 0 );
}

sub open {
    my ( $self, %options ) = @_;

    if ( !$self->{local_port} ) {
        $self->{local_port}         = $self->_find_port();
        $self->{dynamic_local_port} = 1;
    }
    $self->{control_socket} = $self->_temp_control_socket();
    $self->{pid}            = fork();
    croak("too few resources to open tunnel") if ( !defined( $self->{pid} ) );

    if ( $self->{pid} == 0 ) {
        my $command = $self->_build_command('open');
        $logger->debugf( 'opening tunnel with: `%s`', $command );
        exec($command);
        exit(0);
    }

    my $open            = 0;
    my $remaining_tries = $options{tries} || $self->{tries};
    my $wait_seconds    = $options{wait_seconds} || $self->{wait_seconds};
    while ( $remaining_tries-- > 0 ) {
        if ( $self->is_open() ) {
            $open = 1;
            last;
        }
        $logger->tracef( 'not yet open, %s tries remaining. sleeping...', $remaining_tries );
        sleep($wait_seconds);
    }

    croak('failed to open tunnel') if ( !$open );

    $logger->debug('tunnel open');
}

sub _temp_control_socket {
    my ($self) = shift;

    make_path( $self->{control_socket_dir} );
    return File::Spec->catfile( $self->{control_socket_dir}, $$ . '_' . $number++ );
}

1;

__END__

=pod

=head1 NAME

Footprintless::Tunnel - Provides tunneling over ssh

=head1 VERSION

version 1.28

=head1 SYNOPSIS

    # Standard way of creating tunnels
    use Footprintless;
    my $tunnel = Footprintless->new()->tunnel($coordinate);

    eval {
        $tunnel->open();
        my $local_hostname = $tunnel->get_local_hostname();
        my $port = $tunnel->get_local_port();

        # do stuff with tunnel
    }
    my $error = $@;
    eval {$tunnel->close()};
    die($error) if ($error);

=head1 DESCRIPTION

This module provides tunneling over ssh

=head1 ENTITIES

    tunnel => {
        ssh => 'ssh -q',
        local_hostname => 'foo',
        local_port => 1234,
        tunnel_hostname => 'bar',
        tunnel_usename => 'fred',
        destination_hostname => 'baz',
        destination_port => 5678,
        control_socket_dir => '/home/me/.ssh/control_socket',
        tries => 10, 
        wait_seconds => 1, 
    }

=head1 CONSTRUCTORS

=head2 new($entity, $coordinate, %options)

Creates a new tunnel configured by C<$entities>.

=head1 METHODS

=head2 close()

Closes the tunnel.

=head2 get_local_hostname()

Returns the hostname used to access the tunnel.

=head2 get_local_port()

Returns the port used to access the tunnel.

=head2 is_open()

Returns a I<truthy> value if the tunnel is open.

=head2 open([%options])

Opens the tunnel.  The available options are:

=over 4

=item tries <COUNT>

Number of times to check if the connection is open before giving up.
Defaults to 10.

=item wait_seconds <SECONDS>

Number of seconds to wait between each check to see if the connection 
is open.  Defaults to 1.

=back

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

L<Footprintless|Footprintless>

=item *

L<Config::Entities|Config::Entities>

=item *

L<Footprintless|Footprintless>

=back

=cut
