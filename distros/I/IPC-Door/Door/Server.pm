package IPC::Door::Server;

#$Id: Server.pm 37 2005-06-07 05:50:05Z asari $

use 5.006;
use strict;
use warnings;

use POSIX qw[ :fcntl_h ];
use IPC::Door qw( :attr );

our @ISA = qw[ IPC::Door ];

sub revoke {
    my $self = shift;
    my $path = $self->{'path'};

    return undef unless $self->is_door;

    $self->__revoke($path);

    1;
}

sub DESTROY {
    my $self = shift;

    $self->SUPER::DESTROY;
    unlink $self->{'path'} if ( -e $self->{'path'} );
}

1;    # end of IPC::Door::Server

__END__

=head1 NAME

IPC::Door::Server - door server object for Solaris (>= 2.6)

=head2 SYNOPSIS

    use IPC::Door::Server;

    $door = '/path/to/door';

    $dserver = new IPC::Door::Server($door, \&mysub);

=head1 DESCRIPTION

C<IPC::Door::Server> is a Perl class for door servers.
It creates a door C<$door> and listens to client requests through it.

When a door client sends a request through its door,
the C<IPC::Door::Server> passes the data to C<&mysub>, and sends its
return value to the client.

=head2 SERVER PROCESS

Each C<IPC::Door::Server> object is associated with a server process
(C<&mysub> throughout this documentation).
C<&mysub> must take exactly one scalar and return exactly one scalar.

Currently, these arguments can't be a reference or any other data
structure.
See <IPC::Door/"KNOWN ISSUES">.

=head2 SPECIAL VARIABLES

When an C<IPC::Door::Client> process makes a call, the
C<IPC::Door::Server> process sets 5 special variables as a result of
C<door_cred>/C<doore_ucred> (3DOOR) call.
These corresponds to self-explanatory credentials of the client process:
C<$IPC::Door::CLIENT_EUID>,
C<$IPC::Door::CLIENT_EGID>,
C<$IPC::Door::CLIENT_RUID>,
C<$IPC::Door::CLIENT_RGID>, and
C<$IPC::Door::CLIENT_PID>.

(These names may change in the future releases of this module.)

=head1 SEE ALSO

L<IPC::Door>

=head1 AUTHOR

ASARI Hirotsugu <asarih at cpan dot org>

L<http://www.asari.net/perl>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2005 by ASARI Hirotsugu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
