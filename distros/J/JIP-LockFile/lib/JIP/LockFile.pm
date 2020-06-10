package JIP::LockFile;

use 5.006;
use strict;
use warnings;

use IO::File;
use Carp qw(croak);
use Fcntl qw(LOCK_EX LOCK_NB);
use English qw(-no_match_vars);

our $VERSION = '0.062';

sub new {
    my ($class, %param) = @ARG;

    # Mandatory options
    if (!exists $param{'lock_file'}) {
        croak q{Mandatory argument "lock_file" is missing};
    }

    # Check "lock_file"
    my $lock_file = $param{'lock_file'};
    if (!length $lock_file) {
        croak q{Bad argument "lock_file"};
    }

    # Class to object
    return bless(
        {
            is_locked => 0,
            fh        => undef,
            error     => undef,
            lock_file => $lock_file,
        },
        $class,
    );
}

sub is_locked {
    my ($self) = @ARG;

    return $self->{'is_locked'};
}

sub lock_file {
    my ($self) = @ARG;

    return $self->{'lock_file'};
}

sub error {
    my ($self) = @ARG;

    return $self->{'error'};
}

# Lock or raise an exception
sub lock {
    my ($self) = @ARG;

    return $self->_lock();
}

# Or just return undef
sub try_lock {
    my ($self) = @ARG;

    return $self->_lock(try => 1);
}

# You can manually unlock
sub unlock {
    my ($self) = @ARG;

    # Re-unlocking changes nothing
    return $self if !$self->is_locked;

    # Close filehandle before file removing
    $self->_set_fh(undef);

    if (!unlink $self->lock_file) {
        $self->_set_error($OS_ERROR);

        croak sprintf(q{Can't unlink "%s": %s}, $self->lock_file, $self->error);
    }

    return $self->_set_is_locked(0);
}

sub get_lock_data {
    my ($self) = @_;

    my $line;
    {
        my $fh
            = $self->is_locked
            ? $self->_fh
            : $self->_init_file_handle;

        return if !$fh;

        $fh->seek(0, 0);

        $line = $fh->getline();
    }

    return if !$line;

    chomp $line;

    my ($pid, $executable_name) = $line =~ m{
        ^
        {
            "pid":"(\d+)"
            ,
            "executable_name":"( [^""]+ )"
        }
        $
    }x;

    return {
        pid             => $pid,
        executable_name => $executable_name,
    };
}

# unlocking on scope exit
sub DESTROY {
    my ($self) = @ARG;

    return $self->unlock;
}

sub _init_file_handle {
    my ($self) = @ARG;

    my $fh = IO::File->new($self->lock_file, O_RDWR | O_CREAT);

    if (!$fh) {
        $self->_set_error($OS_ERROR);
    }

    return $fh;
}

sub _lock {
    my ($self, %param) = @_;

    # Re-locking changes nothing
    return $self if $self->is_locked;

    my $fh = $self->_init_file_handle;

    if (!$fh) {
        croak sprintf(q{Can't open "%s": %s}, $self->lock_file, $self->error);
    }

    if (!flock $fh, LOCK_EX | LOCK_NB) {
        $self->_set_error($OS_ERROR);

        return if $param{'try'};

        croak sprintf(q{Can't lock "%s": %s}, $self->lock_file, $self->error);
    }

    if (!truncate $fh, 0) {
        $self->_set_error($OS_ERROR);

        croak sprintf(q{Can't truncate "%s": %s}, $self->lock_file, $self->error);
    }

    autoflush $fh 1;

    if (!$fh->print($self->_lock_message)) {
        $self->_set_error($OS_ERROR);

        croak sprintf(q{Can't write message to file: %s}, $self->error);
    }

    return $self->_set_fh($fh)->_set_is_locked(1);
}

sub _lock_message {
    return sprintf(
        q[{"pid":"%s","executable_name":"%s"}],
        $PROCESS_ID,
        $EXECUTABLE_NAME,
    );
}

sub _set_is_locked {
    my ($self, $is_locked) = @ARG;

    $self->{'is_locked'} = $is_locked;

    return $self;
}

sub _fh {
    my ($self) = @ARG;

    return $self->{'fh'};
}

sub _set_fh {
    my ($self, $fh) = @ARG;

    $self->{'fh'} = $fh;

    return $self;
}

sub _set_error {
    my ($self, $error) = @ARG;

    $self->{'error'} = $error || '<unknown_error>';

    return $self;
}

1;

__END__

=head1 NAME

JIP::LockFile - application lock/mutex based on files

=head1 VERSION

This document describes C<JIP::LockFile> version C<0.062>.

=head1 SYNOPSIS

    use JIP::LockFile;

    my $lock_file = '/path/to/pid_file';

    my $foo = JIP::LockFile->new(lock_file => $lock_file);
    my $wtf = JIP::LockFile->new(lock_file => $foo->lock_file);

    $foo->lock;           # lock
    eval { $wtf->lock; }; # or raise exception

    # Can check its status in case you forgot
    $foo->is_locked; # 1
    $wtf->is_locked; # 0

    $foo->lock; # Re-locking changes nothing

    # But trying to get a lock is ok
    $wtf->try_lock;  # 0
    $wtf->is_locked; # 0

    # Data from lock-file
    $foo->get_lock_data->{pid};             # $PROCESS_ID
    $foo->get_lock_data->{executable_name}; # $EXECUTABLE_NAME

    # You can manually unlock
    $foo->unlock;

    # Re-unlocking changes nothing
    $foo->unlock;

    # ... or unlocking is automatic on scope exit
    undef $foo;

=head1 ATTRIBUTES

L<JIP::LockFile> implements the following attributes.

=head2 lock_file

    my $object = JIP::LockFile->new(lock_file => '/path/to/pid_file');

    $object->lock_file; # /path/to/pid_file

=head2 is_locked

    my $object = JIP::LockFile->new(lock_file => '/path/to/pid_file');

    $object->is_locked; # 0

    $object->lock->is_locked; # 1

=head2 error

    my $object = JIP::LockFile->new(lock_file => '/path/to/pid_file');

    $object->lock;

    my $concurrent = JIP::LockFile->new(lock_file => $object->lock_file);

    $concurrent->try_lock->error; # Resource temporarily unavailable

=head1 SEE ALSO

L<Lock::File>, L<Lock::Socket> and L<JIP::LockSocket>.

=head1 AUTHOR

Vladimir Zhavoronkov, C<< <flyweight at yandex.ru> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015-2020 Vladimir Zhavoronkov.

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

