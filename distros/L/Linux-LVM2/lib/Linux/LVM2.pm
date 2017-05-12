package Linux::LVM2;
{
  $Linux::LVM2::VERSION = '0.14';
}
BEGIN {
  $Linux::LVM2::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: a Linux LVM2 wrapper.

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

use Carp;
use Try::Tiny;

use Linux::LVM2::VG;
use Linux::LVM2::PV;
use Linux::LVM2::LV;
use Linux::LVM2::Utils;
use Sys::FS;
use Sys::Run;

has 'vgs' => (
    'is'      => 'ro',
    'isa'     => 'HashRef[Linux::LVM2::VG]',
    'lazy'    => 1,
    'builder' => '_find_vgs',
);

has 'verbose' => (
    'is'      => 'rw',
    'isa'     => 'Bool',
    'default' => 0,
);

has 'logger' => (
    'is'       => 'ro',
    'isa'      => 'Log::Tree',
    'required' => 1,
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

sub _find_vgs {
    my $self = shift;
    my $vg_ref = shift || {};

    my %sbin = ();
    $sbin{'vgdisplay'} = '/sbin/vgdisplay';
    $sbin{'lvdisplay'} = '/sbin/lvdisplay';
    $sbin{'lvs'}       = '/sbin/lvs';
    $sbin{'pvdisplay'} = '/sbin/pvdisplay';

    foreach my $key ( keys %sbin ) {
        if ( !-x $sbin{$key} ) {
            croak( 'Binary not executeable: ' . $sbin{$key} );
        }
    }

    # read in the command output in a batch,
    # keep the disabled warnings and output redirect as contained
    # and brief as possible.
    my ( @vgdisplay, @lvdisplay, @lvs, @pvdisplay );
    {

        # redirect stderr, to get rid of those useless lvm warnings
        ## no critic (ProhibitTwoArgOpen ProhibitBarewordFileHandles ProhibitNoWarnings RequireCheckedOpen RequireBriefOpen)
        no warnings 'once';
        open( OLDSTDERR, '>&STDERR' ) unless $self->verbose();
        use warnings 'once';
        open( STDERR, '/dev/null' ) unless $self->verbose();
        ## use critic

        ## no critic (RequireCheckedClose ProhibitPunctuationVars)
        local $ENV{LANG} = q{C};
        open( my $VGS, '-|', $sbin{'vgdisplay'} . ' -c' )
          or confess('Could not execute '.$sbin{'vgdisplay'}.'! Is LVM2 installed?: '.$!."\n");
        @vgdisplay = <$VGS>;
        close($VGS);
        open( my $PVS, '-|', $sbin{'pvdisplay'} . ' -c' )
          or confess('Could not execute '.$sbin{'pvdisplay'}.'! Is LVM2 installed?: '.$!."\n");
        @pvdisplay = <$PVS>;
        close($PVS);
        open( my $LVD, '-|', $sbin{'lvdisplay'} . ' -c' )
          or confess('Could not execute '.$sbin{'lvdisplay'}.'! Is LVM2 installed?: '.$!."\n");
        @lvdisplay = <$LVD>;
        close($LVD);
        open( my $LVS, '-|', $sbin{'lvs'} . ' --separator=: --units=b' )
          or confess('Could not execute '.$sbin{'lvs'}.'! Is LVM2 installed?: '.$!."\n");
        @lvs = <$LVS>;
        close($LVS);
        ## use critic

        ## no critic (ProhibitTwoArgOpen)
        open( STDERR, '>&OLDSTDERR' ) unless $self->verbose();
        ## use critic
    }

    # Process all VGs
    foreach my $line (@vgdisplay) {
        next unless $line;
        chomp($line);
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        next unless $line;
        my %h;
        @h{qw(name access status vgid maxlvs curlvs openlvs maxlvsize maxpvs curpvs numpvs vgsize pesize totalpe allocpe freepe uuid)} = split( /:/, $line );
        $h{'parent'} = $self;

        # if the object exists, just update it
        if ( $vg_ref->{ $h{'name'} } && $vg_ref->{ $h{'name'} }->isa('Linux::LVM2::VG') ) {

            # some attrs are read-only, just update those which are rw
            foreach my $attr ( keys %h ) {
                try {
                    $vg_ref->{ $h{'name'} }->$attr( $h{$attr} );
                };
            }
        }
        else {
            $vg_ref->{ $h{'name'} } = Linux::LVM2::VG::->new( \%h );
        }
    }

    # Process all PVs
    foreach my $line (@pvdisplay) {
        next unless $line;
        chomp($line);
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        next unless $line;
        my %h;
        @h{qw(name vg size pesize totalpe freepe allocpe uuid)} = split( /:/, $line );
        if ( $h{'vg'} && $vg_ref->{ $h{'vg'} } && $vg_ref->{ $h{'vg'} }->isa('Linux::LVM2::VG') ) {

            if ( $vg_ref->{ $h{'vg'} }->pvs()->{ $h{'name'} } && $vg_ref->{ $h{'vg'} }->pvs()->{ $h{'name'} }->isa('Linux::LVM2::PV') ) {
                foreach my $attr ( keys %h ) {
                    try {
                        $vg_ref->{ $h{'vg'} }->pvs()->{ $h{'name'} }->$attr( $h{$attr} );
                    };
                }
            }
            else {
                $h{'vg'} = $vg_ref->{ $h{'vg'} };
                my $PV = Linux::LVM2::PV::->new( \%h );

                # no need to do anything with $PV, its constructor will attach itself
                # to the vg passed it will be reachable via the associated VG
            }
        }
        else {
            next;
        }

    }

    # Process each LV (from lvdisplay)
    foreach my $line (@lvdisplay) {
        next unless $line;
        chomp($line);
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        next unless $line;
        my %h;
        @h{qw(name vg access status intlvnum opencount lvsize leassoc lealloc allocpol rasect majornum minornum)} = split( /:/, $line );
        $h{'name'} =~ s#^/dev/##;
        $h{'name'} =~ s#^$h{'vg'}/##;

        if ( $h{'vg'} && $vg_ref->{ $h{'vg'} } ) {
            if ( $vg_ref->{ $h{'vg'} }->lvs()->{ $h{'name'} } && $vg_ref->{ $h{'vg'} }->lvs()->{ $h{'name'} }->isa('Linux::LVM2::LV') ) {
                foreach my $attr ( keys %h ) {

                    # some attrs are read-only, just update those which are rw
                    try {
                        $vg_ref->{ $h{'vg'} }->lvs()->{ $h{'name'} }->$attr( $h{$attr} );
                    };
                }
            }
            else {
                $h{'vg'} = $vg_ref->{ $h{'vg'} };
                my $VG = Linux::LVM2::LV::->new( \%h );

                # no need to do anything with $VG, its constructor will attach itself
                # to the vg passed it will be reachable via the associated VG
            }
        }
        else {
            next;
        }
    }

    # Try to get mount points for mounted devices
    my $mounts = $self->fs()->mounts( { 'DevAsKey' => 1, } );

    # Process each LV (from LVs, provides additional information about Snapshot and Copy Progress)
    foreach my $line (@lvs) {
        next unless $line;
        next if $line =~ m/\s*LV:VG:Attr/;
        chomp($line);
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        next unless $line;
        my %h;
        @h{qw(name vg attr lsize origin snap_pc move log copy_pc convert)} = split( /:/, $line );

        if ( $h{'vg'} && $h{'name'} && $vg_ref->{ $h{'vg'} } && $vg_ref->{ $h{'vg'} }->lvs()->{ $h{'name'} } ) {
            my $lv = $vg_ref->{ $h{'vg'} }->lvs()->{ $h{'name'} };

            # convert percent
            foreach my $key (qw(snap_pc copy_pc)) {
                $h{$key} ||= 0;
                $h{$key} = int( $h{$key} * 100 );
            }

            # set parameters
            foreach my $attr (qw(snap_pc move log copy_pc convert)) {
                try {
                    $h{$attr} ||= q{};
                    $lv->$attr( $h{$attr} );
                };
            }

            # set origin of the new LV
            if ( $h{'origin'} && $vg_ref->{ $h{'vg'} }->lvs()->{ $h{'origin'} } && $vg_ref->{ $h{'vg'} }->lvs()->{ $h{'origin'} }->isa('Linux::LVM2::LV') ) {
                $lv->origin( $vg_ref->{ $h{'vg'} }->lvs()->{ $h{'origin'} } );
            }
            elsif ( $h{'origin'} ) {
                confess("Did not find origin ($h{'origin'}) of LV $h{'name'}. This is impossible!");
            }

            # set mount point
            if ( $mounts->{ $lv->mapper_path() } ) {
                $lv->mount_point( $mounts->{ $lv->mapper_path() }{'mount_point'} );
            }
            elsif ( $mounts->{ $lv->full_path() } ) {
                $lv->mount_point( $mounts->{ $lv->full_path() }{'mount_point'} );
            }
            else {
                warn 'No mount point found for LV ' . $lv->full_path() . "\n" if $self->verbose();
            }
        }
    }

    return $vg_ref;
}

sub is_lv {
    my $self    = shift;
    my $vg_name = shift;
    my $lv_name = shift;

    foreach my $vg ( keys %{ $self->vgs() } ) {
        next if $vg_name && $vg ne $vg_name;
        if ( $self->vgs()->{$vg}->lvs()->{$lv_name} ) {
            return 1;
        }
    }
    return;
}

sub is_vg {
    my $self    = shift;
    my $vg_name = shift;

    if ( $self->vgs()->{$vg_name} ) {
        return 1;
    }
    else {
        return;
    }
}

sub lv_from_path {
    my $self = shift;
    my $path = shift;

    # find out which device $path is located
    my ( $device, $fs_type, $fs_options, $mount_point ) = $self->fs()->get_mounted_device($path);

    my $LV = $self->lv_from_dev($device);
    if ($LV) {
        $LV->fs_type($fs_type);
        $LV->fs_options($fs_options);
        $LV->mount_point($mount_point);
        return $LV;
    }
    else {
        carp "Did not find lv from given path $path\n" if $self->verbose();
    }
    return;
}

sub lv_from_dev {
    my $self = shift;
    my $dev  = shift;

    if ( $dev =~ m#/mapper/# ) {
        warn "Trying to translate dev-mapper name to lvm name $dev\n" if $self->verbose();
        $dev = Linux::LVM2::Utils::translate_lvm_name($dev);
        warn "Translated to $dev\n" if $self->verbose();
    }
    $dev =~ s#^/dev/##;
    $dev =~ s#/$##;

    my ( $vg, $lv ) = split /\//, $dev;

    if ( $vg && $lv && $self->is_lv( $vg, $lv ) ) {
        return $self->vgs()->{$vg}->lvs()->{$lv};
    }

    # no lv found
    return;
}

sub update {
    my $self = shift;
    $self->_find_vgs( $self->vgs() );
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Linux::LVM2 - a Linux LVM2 wrapper.

=head1 SYNOPSIS

    use Linux::LVM2;
    my $LVM = Linux::LVM2::->new();

=head1 DESCRIPTION

This class wraps the Linux LVM2 subsystem into handy perl classes.

=head1 ATTRIBUTES

=head2 vgs

Contains all VGs present at the last update.

=head2 verbose

When true, be more verbose.

=head2 logger

An instance of Log::Tree.

=head2 sys

An instance of Sys::Run.

=head2 fs

An instance of Sys::FS.

=head1 METHODS

=head2 _find_vgs

Detect all available VGs w/ containing PVs and contained LVs.

=head2 is_lv

Returns true if the given vg/lv is a known LV.

=head2 is_vg

Returns true if the given vg is a known VG.

=head2 lv_from_dev

Translate the given /dev/mapper/... path to a LV object.

=head2 lv_from_path

Translate the given fs path to a LV object.

=head2 update

Update the internal LVM data-structures.

=head1 NAME

Linux::LVM2 - Linux LVM2 wrapper.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
