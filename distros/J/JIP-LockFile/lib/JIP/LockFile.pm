package JIP::LockFile;

use 5.006;
use strict;
use warnings;
use IO::File;
use JIP::ClassField 0.05;
use Carp qw(croak);
use Fcntl qw(LOCK_EX LOCK_NB);
use English qw(-no_match_vars);

our $VERSION = '0.051';

has [qw(lock_file is_locked)] => (get => q{+}, set => q{-});

has fh => (get => q{-}, set => q{-});

sub new {
    my ($class, %param) = @ARG;

    # Mandatory options
    croak q{Mandatory argument "lock_file" is missing}
        unless exists $param{'lock_file'};

    # Check "lock_file"
    my $lock_file = $param{'lock_file'};
    croak q{Bad argument "lock_file"}
        unless defined $lock_file and length $lock_file;

    # Class to object
    return bless({}, $class)
        ->_set_is_locked(0)
        ->_set_lock_file($lock_file)
        ->_set_fh(undef);
}

# Lock or raise an exception
sub lock {
    my $self = shift;

    # Re-locking changes nothing
    return $self if $self->is_locked;

    my $fh = IO::File->new($self->lock_file, O_RDWR|O_CREAT)
        or croak(sprintf q{Can't open "%s": %s}, $self->lock_file, $OS_ERROR);

    flock $fh, LOCK_EX|LOCK_NB
        or croak(sprintf q{Can't lock "%s": %s}, $self->lock_file, $OS_ERROR);

    truncate $fh, 0
        or croak(sprintf q{Can't truncate "%s": %s}, $self->lock_file, $OS_ERROR);

    autoflush $fh 1;

    $fh->print($self->_lock_message())
        or croak(sprintf q{Can't write message to file: %s}, $OS_ERROR);

    return $self->_set_fh($fh)->_set_is_locked(1);
}

# Or just return undef
sub try_lock {
    my $self = shift;

    # Re-locking changes nothing
    return $self if $self->is_locked;

    my $fh = IO::File->new($self->lock_file, O_RDWR|O_CREAT);

    if ($fh and flock $fh, LOCK_EX|LOCK_NB) {
        truncate $fh, 0
            or croak(sprintf q{Can't truncate "%s": %s}, $self->lock_file, $OS_ERROR);

        autoflush $fh 1;

        $fh->print($self->_lock_message())
            or croak(sprintf q{Can't write message to file: %s}, $OS_ERROR);

        return $self->_set_fh($fh)->_set_is_locked(1);
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

    # Close filehandle before file removing
    unlink $self->_set_fh(undef)->lock_file
        or croak(sprintf q{Can't unlink "%s": %s}, $self->lock_file, $OS_ERROR);

    return $self->_set_is_locked(0);
}

# unlocking on scope exit
sub DESTROY {
    my $self = shift;

    return $self->unlock;
}

sub _lock_message {
    return sprintf q[{"pid":"%s","executable_name":"%s"}],
        $PROCESS_ID,
        $EXECUTABLE_NAME;
}

1;

__END__

=head1 NAME

JIP::LockFile - application lock/mutex based on files

=head1 VERSION

This document describes C<JIP::LockFile> version C<0.051>.

=head1 SYNOPSIS

    use JIP::LockFile;

    my $lock_file = '/path/to/pid_file';

    my $foo = JIP::LockFile->new(lock_file => $lock_file);
    my $wtf = JIP::LockFile->new(lock_file => $lock_file);

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

L<Lock::File>, L<Lock::Socket> and L<JIP::LockSocket>.

=head1 AUTHOR

Vladimir Zhavoronkov, C<< <flyweight at yandex.ru> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015-2018 Vladimir Zhavoronkov.

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

