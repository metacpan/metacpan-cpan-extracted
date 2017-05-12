package Linux::LVM2::Snapshot;
{
  $Linux::LVM2::Snapshot::VERSION = '0.14';
}
BEGIN {
  $Linux::LVM2::Snapshot::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: a class representing a LV snapshot in an Linux LVM2

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

use Carp;
use File::Temp;

use Sys::FS;
use Sys::Run;

has 'name' => (
    'is'      => 'ro',
    'isa'     => 'Str',
    'lazy'    => 1,
    'builder' => '_init_name',
);

has 'logger' => (
    'is'       => 'rw',
    'isa'      => 'Log::Tree',
    'required' => 1,
);

has 'lv' => (
    'is'  => 'ro',
    'isa' => 'Linux::LVM2::LV',
);

has 'source' => (
    'is'       => 'ro',
    'isa'      => 'Linux::LVM2::LV',
    'required' => 1,
);

has 'parent' => (
    'is'       => 'ro',
    'isa'      => 'Linux::LVM2',
    'required' => 1,
);

has 'clear_caches' => (
    'is'      => 'ro',
    'isa'     => 'Bool',
    'default' => 0,
);

has 'snapspace' => (
    'is'      => 'rw',
    'isa'     => 'Int',
    'default' => '5',     # GB
);

has 'mount_point' => (
    'is'  => 'ro',
    'isa' => 'Str',
);

has 'verbose' => (
    'is'      => 'rw',
    'isa'     => 'Int',    # Bool
    'default' => 0,
);

has 'sys' => (
    'is'      => 'rw',
    'isa'     => 'Sys::Run',
    'lazy'    => 1,
    'builder' => '_init_sys',
);

has 'fs' => (
    'is'      => 'rw',
    'isa'     => 'Sys::FS',
    'lazy'    => 1,
    'builder' => '_init_fs',
);

has '_created_mount_point' => (
    'is'    => 'rw',
    'isa'   => 'Bool',
    'default' => 0,
);

sub _init_sys {
    my $self = shift;

    my $Sys = Sys::Run::->new( { 'logger' => $self->logger(), } );

    return $Sys;
}

sub _init_fs {
    my $self = shift;

    my $FS = Sys::FS::->new(
        {
            'logger' => $self->logger(),
            'sys'    => $self->sys(),
        }
    );

    return $FS;
}

sub full_path {
    my $self = shift;

    return $self->lv()->full_path();
}

sub mapper_path {
    my $self = shift;

    return $self->lv()->mapper_path();
}

sub BUILD {
    my $self = shift;

    # clear caches, free pagecache, dentries and inodes
    $self->sys()->clear_caches() if $self->clear_caches();

    # sync; sync; sync; lvcreate ...
    my $cmd =
        'sync; lvcreate -L'
      . $self->snapspace()
      . 'G --snapshot --name '
      . $self->name()
      . ' /dev/'
      . $self->source()->vg()->name() . '/'
      . $self->source()->name();
    if ( !$self->sys()->run_cmd( $cmd, { RaiseError => 1, Verbose => 1, } ) ) {
        my $msg = 'lvcreate failed. Could not create snapshot!';
        $self->logger()->log( message => $msg, level => 'error' );
        return;
    }

    # set our lv object
    $self->source()->vg()->update();
    if ( $self->source()->vg()->lvs()->{ $self->name() } && $self->source()->vg()->lvs()->{ $self->name() }->isa('Linux::LVM2::LV') ) {
        $self->{'lv'} = $self->source()->vg()->lvs()->{ $self->name() };
        $self->lv()->fs_type( $self->source()->fs_type() );
        $self->lv()->fs_options( $self->source()->fs_options() );
        return 1;
    }
    else {
        my $msg = 'LV ' . $self->name() . ' not found!';
        $self->logger()->log( message => $msg, level => 'error' );
        return;
    }
}

sub _init_name {
    my $self = shift;

    # finds a free replisnapname
    my $basename = 'replisnap';
    my $try      = 0;
    while ( $self->parent()->is_lv( $self->source()->vg()->name(), $basename . $try ) ) {
        $try++;

        # safety guard
        if ( $try > 1024 ) {
            my $msg = 'Could not find a free replisnap name within $try tries! Giving up.';
            $self->logger()->log( message => $msg, level => 'error' );
            return;
        }
    }

    # found an unused name for the
    # snapshot
    return $basename . $try;
}

sub mount {
    my $self        = shift;
    my $mount_point = shift;

    if ( !$mount_point || !-d $mount_point ) {
        $mount_point = File::Temp::tempdir( CLEANUP => 0 );
        $self->_created_mount_point(1);
    }

    if ( $self->fs()->mount( $self->full_path(), $mount_point, $self->lv()->fs_type(), 'ro,noatime', { Verbose => $self->verbose(), } ) ) {
        $self->{'mount_point'} = $mount_point;
        return $mount_point;
    }
    else {
        my $msg = 'Could not mount ' . $self->full_path() . ' at '.$mount_point;
        $self->logger()->log( message => $msg, level => 'error' );
        return;
    }
}

sub umount {
    my $self = shift;

    my $mounted_dev = $self->mapper_path();
    if ( !$self->fs()->is_mounted($mounted_dev) ) {
        $mounted_dev = $self->full_path();
        if ( !$self->fs()->is_mounted($mounted_dev) ) {
            my $msg = 'Tried to unmount snapshot (' . $self->full_path() . ') which does not appear to be mounted.';
            $self->logger()->log( message => $msg, level => 'warning' );
        }
    }
    else {
        my $msg = 'Trying to unmount device ' . $mounted_dev;
        $self->logger()->log( message => $msg, level => 'debug' );
        if ( $self->fs()->umount( $mounted_dev, ) ) {
            if($self->_created_mount_point()) {
                $self->sys()->run_cmd( 'rm -rf ' . $self->mount_point() );
            }
            $msg = 'Unmounted snapshot ' . $mounted_dev . ' from ' . $self->mount_point();
            $self->logger()->log( message => $msg, level => 'debug' );
            return 1;
        }
        else {
            $msg = 'Could not unmount ' . $mounted_dev;
            $self->logger()->log( message => $msg, level => 'error' );
        }
    }

    return;
}

sub remove {
    my $self = shift;

    $self->umount()
      or return;

    # remove it
    my $cmd = '/sbin/lvremove -f ' . $self->full_path();
    if ( $self->sys()->run_cmd( $cmd, { Verbose => $self->verbose(), } ) ) {
        my $msg = 'Removed snapshot LV ' . $self->full_path();
        $self->logger()->log( message => $msg, level => 'debug' );
        return 1;
    }
    else {
        my $msg = 'Failed to remove snapshot LV ' . $self->full_path();
        $self->logger()->log( message => $msg, level => 'debug' );
        return;
    }
}

sub DEMOLISH {
    my $self = shift;

    return $self->remove();
}

sub valid {
    my $self = shift;
    return $self->lv()->valid();
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding utf-8

=head1 NAME

Linux::LVM2::Snapshot - a class representing a LV snapshot in an Linux LVM2

=head1 SYNOPSIS

    use Linux::LVM2::Snapshot;
    my $Mod = Linux::LVM2::Snapshot::->new();

=head1 DESCRIPTION

This class models a snapshoted LV from an Linux LVM2 LV.

=head1 ATTRIBUTES

=head2 name

The name of this snapshot LV

=head2 logger

An instance of Log::Tree

=head2 lv

The snapshot LV

=head2 source

The snapshoted LV

=head2 parent

Our parent, must be an instance of Linux::LVM2

=head2 clear_caches

UNDOCUMENTED

=head2 snapspace

Use this much GB for the snapshot

=head2 mount_point

UNDOCUMENTED

=head2 verbose

UNDOCUMENTED

=head2 sys

UNDOCUMENTED

=head2 fs

UNDOCUMENTED

=head1 METHODS

=head2 BUILD

Invoked by Moose on instantiation. Create the snapshot.

=head2 DEMOLISH

Invoked by Moose on destruction. Removes the snapshot.

=head2 full_path

Return the full path to this LV.

=head2 mapper_path

Return the dev-mapper path to this LV.

=head2 mount

Try to mount this LV snapshot to the given mount point.

=head2 remove

Try to unmount this LV, if mounted, and remove the LV afterwards.

=head2 umount

Try to unmount this LV.

=head2 valid

Returns true unless the snapshot is 100% full.

=head1 NAME

Linux::LVM2::Snapshot - Model a Snapshot LV.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


1; # End of Linux::LVM2::Snapshot
