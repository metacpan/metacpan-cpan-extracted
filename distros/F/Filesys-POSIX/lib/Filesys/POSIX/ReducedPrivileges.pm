package Filesys::POSIX::ReducedPrivileges;

# Copyright (c) 2016, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use Filesys::POSIX::Error qw(throw);
use Filesys::POSIX::ReducedPrivileges::Inode ();
use Filesys::POSIX::Real;
use Carp  ();
use Errno ();

our @ISA = qw(Filesys::POSIX::Real);

=head1 NAME

Filesys::POSIX::ReducedPrivileges - Portal to actual underlying filesystem as seen by a particular UID/GID.

=head1 SYNOPSIS

    use Filesys::POSIX;
    use Filesys::POSIX::Real;

    my $fs = Filesys::POSIX->new(Filesys::POSIX::ReducedPrivileges->new,
        'path'    => '/home/foo/test',
        'noatime' => 1,
        'uid'     => 99,
        'gid'     => 99,
    );

=head1 DESCRIPTION

This module wraps the L<Filesys::POSIX::Real> filesystem type with entry and
exit functions that switch the effective UID and GID whenever the filesystem
is accessed.

=head1 MOUNT OPTIONS

The following values are mandatory:

=over

=item C<path>

The path, in the real filesystem, upon which the new filesystem to be mounted
will be based.

=item C<uid>

The numeric UID to use when accessing the real filesystem.

=item C<gid>

The numeric GID to use when accessing the real filesystem. The suppelemental
group list is also limited to this GID.

=back

=cut

sub new {
    my ( $class, %opts ) = @_;
    my $self = $class->SUPER::new();

    bless $self, $class;

    return $self;
}

sub init {
    my ( $self, %opts ) = @_;
    my $path = $opts{'path'} or throw &Errno::EINVAL;

    $self->{_uid}                = $opts{uid};
    $self->{_gid}                = "$opts{gid} $opts{gid}";
    $self->{_privileges_reduced} = 0;

    my $root = Filesys::POSIX::ReducedPrivileges::Inode->from_disk( $path, 'dev' => $self );

    throw &Errno::ENOTDIR unless $root->dir;

    $self->{'flags'} = \%opts;
    $self->{'path'}  = Filesys::POSIX::Path->full($path);
    $self->{'root'}  = $root;

    return $sel;
}

sub enter_filesystem {
    my $self = shift;
    $self->{_privileges_reduced}++;
    return unless ( $self->{_privileges_reduced} == 1 );
    $self->{_original_uid} = $>;
    $self->{_original_gid} = $);
    $)                     = $self->{_gid};
    $>                     = $self->{_uid};
    no warnings 'numeric';

    unless ( $> == $self->{_uid} && int($)) eq int( $self->{_gid} ) ) {
        Carp::confess("failed to reduce privileges: $!");
    }
    return;
}

sub exit_filesystem {
    my $self = shift;
    $self->{_privileges_reduced}--;
    return unless ( $self->{_privileges_reduced} == 0 );
    $> = $self->{_original_uid};
    $) = $self->{_original_gid};
    no warnings 'numeric';
    unless ( $> == $self->{_original_uid} && int($)) eq int( $self->{_original_gid} ) ) {
        Carp::confess("failed to restore privileges: $!");
    }
    return;
}

1;

__END__

=head1 AUTHOR

Written by John Lightsey <jd@cpanel.net>

=head1 COPYRIGHT

Copyright (c) 2016, cPanel, Inc.  Distributed under the terms of the Perl
Artistic license.
