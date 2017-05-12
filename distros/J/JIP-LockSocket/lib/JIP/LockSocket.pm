package JIP::LockSocket;

use 5.006;
use strict;
use warnings;
use JIP::ClassField;
use Carp qw(croak);
use English qw(-no_match_vars);
use Socket qw(inet_aton pack_sockaddr_in PF_INET SOCK_STREAM);

our $VERSION = '0.02';

map { has $_ => (get => '+', set => '-') } qw(port addr socket is_locked);

sub new {
    my ($class, %param) = @ARG;

    # Mandatory options
    croak qq{Mandatory argument "port" is missing\n}
        unless exists $param{'port'};

    # Check "port"
    my $port = $param{'port'};
    croak qq{Bad argument "port"\n}
        unless defined $port and $port =~ m{^\d+$}x;

    # Check "addr"
    my $addr = (exists $param{'addr'} and length $param{'addr'})
        ? $param{'addr'} : '127.0.0.1';

    # Class to object
    return bless({}, $class)
        ->_set_is_locked(0)
        ->_set_port($port)
        ->_set_addr($addr)
        ->_set_socket(undef);
}

# Lock or raise an exception
sub lock {
    my $self = shift;

    # Re-locking changes nothing
    return $self if $self->is_locked;

    my $socket = $self->_init_socket;

    bind($socket, pack_sockaddr_in($self->port, $self->_get_inet_addr))
        or croak(sprintf qq{Can't lock port "%s": %s\n}, $self->port, $OS_ERROR);

    return $self->_set_socket($socket)->_set_is_locked(1);
}

# Or just return undef
sub try_lock {
    my $self = shift;

    # Re-locking changes nothing
    return $self if $self->is_locked;

    my $socket = $self->_init_socket;

    if (bind($socket, pack_sockaddr_in($self->port, $self->_get_inet_addr))) {
        return $self->_set_socket($socket)->_set_is_locked(1);
    }
    else {
        return;
    }
}

# You can manually unlock
sub unlock {
    my $self = shift;

    # Re-unlocking changes nothing
    return $self if not $self->is_locked;

    return $self->_set_socket(undef)->_set_is_locked(0);
}

# unlocking on scope exit
sub DESTROY {
    my $self = shift;
    return $self->unlock;
}

sub _get_inet_addr {
    my $self = shift;
    return inet_aton($self->addr);
}

sub _init_socket {
    socket(my $socket, PF_INET, SOCK_STREAM, getprotobyname('tcp'))
        or croak(sprintf qq{Can't init socket: %s\n}, $OS_ERROR);

    return $socket;
}

1;

__END__

=head1 NAME

JIP::LockSocket - application lock/mutex based on sockets

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use JIP::LockSocket;

    my $port = 4242;

    my $foo = JIP::LockSocket->new(port => $port);
    my $wtf = JIP::LockSocket->new(port => $port);

    $foo->port; # required
    $foo->addr; # defaults to 127.0.0.1

    $foo->lock;           # lock
    eval { $wtf->lock; }; # or raise exception

    # Can check its status in case you forgot
    $foo->is_locked; # 1
    $wtf->is_locked; # 0

    $foo->lock; # Re-locking changes nothing

    # But trying to get a lock is ok
    $wtf->try_lock;  # 0
    $wtf->is_locked; # 0

    # You can manually unlock
    $foo->unlock;

    # Re-unlocking changes nothing
    $foo->unlock;

    # ... or unlocking is automatic on scope exit
    undef $foo;

=head1 SEE ALSO

Lock::File, Lock::Socket and JIP::LockFile

=head1 AUTHOR

Vladimir Zhavoronkov, C<< <flyweight at yandex.ru> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Vladimir Zhavoronkov.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

