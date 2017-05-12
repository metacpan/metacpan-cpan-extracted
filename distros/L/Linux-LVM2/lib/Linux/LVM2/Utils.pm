package Linux::LVM2::Utils;
{
  $Linux::LVM2::Utils::VERSION = '0.14';
}
BEGIN {
  $Linux::LVM2::Utils::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Linux LVM2 helper

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use strict;
use warnings;

# use IO::Handle;
# use autodie;

use Carp;
use File::Basename;
use POSIX qw();

# translate_devmapper_name
# inspired by translate_devicemapper_name from the munin diskstats plugin
# which was written by Michael Renner <michael.renner@amd.co.at>
sub translate_devmapper_name {
    my $device = shift;

    my $want_minor;

    if($device =~ m/^dm-(\d+)$/) {
        $want_minor = $1;
    }

    if(!$want_minor) {
        carp "No devicemapper id found\n";
        return;
    }

    my $dm_major = find_dm_major();

    if(!$dm_major) {
        carp "No devicemapper major id found\n";
        return;
    }

    foreach my $dirent ( glob('/dev/mapper/*')) {
        my $rdev = (stat($dirent))[6];
        my $major = POSIX::floor($rdev / 256 );
        my $minor = $rdev % 256;

        if( $major == $dm_major && $minor == $want_minor) {
            my $display_name = translate_lvm_name($dirent);
            $dirent =~ s#/dev/##;

            if(defined($display_name)) {
                return $display_name;
            } else {
                return $dirent;
            }
        }
    }

    # fallback in case our search was fruitless
    return $device;
}

# translate_lvm_name
# inspired by translate_lvm_name from the munin diskstats plugin
# which was written by Michael Renner <michael.renner@amd.co.at>
sub translate_lvm_name {
    my $device = shift;
    my $no_stat = shift || 0;

    my $device_name = File::Basename::basename($device);

    # search for single dashes as this suggests for a lvm devmapper dev
    if ( $device_name =~ m/(?<!-)-(?!-)/ ) {
        # split into vg and lv parts
        my ( $vg, $lv ) = split /(?<!-)-(?!-)/, $device_name, 2;

        # remove superflous dashes from vg and lv names
        $vg =~ s/--/-/g;
        $lv =~ s/--/-/g;

        $device_name = '/dev/'.$vg.'/'.$lv;

        # assert that the assembled device name actually exists
        if($no_stat) {
           return $device_name;
        }
        elsif( stat($device_name)) {
            return $device_name;
        }
    }

    return;
}

# translate_mapper_name
sub translate_mapper_name {
    my $entry = shift;
    my $no_stat = shift || 0;

    if ( $entry =~ m#^/dev/([^/]+)/(.*)$# ) {
        my $vg = $1;
        my $lv = $2;

        # add extraneous dashes to vg and lv names
        $vg =~ s/-/--/g;
        $lv =~ s/-/--/g;

        my $device_name = '/dev/mapper/'.$vg.'-'.$lv;

        # Sanity check - does the constructed device name exist?
        # Breaks unless we are root.
        if( $no_stat) {
           return $device_name;
        }
        elsif ( stat($device_name) ) {
            return $device_name;
        }
    }

    return $entry;
}

# find_devicemapper_major
# inspired by find_devicemapper_major from the munin diskstats plugin
# which was written by Michael Renner <michael.renner@amd.co.at>
sub find_devicemapper_major {
    my $dm_major;

    if(open(my $fh, '<', '/proc/devices')) {
        my @lines = <$fh>;
        ## no critic (RequireCheckedClose)
        close($fh);
        ## use critic
        chomp(@lines);
        foreach my $line ( @lines ) {

            my ($major, $name ) = split /\s+/, $line, 2;

            next unless defined $name;

            if ( $name eq 'device-mapper' ) {
                $dm_major = $major;
                last;
            }
        }
    }

    return $dm_major;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Linux::LVM2::Utils - Linux LVM2 helper

=head1 SYNOPSIS

    use Linux::LVM2::Utils

=head1 DESCRIPTION

This class provides some helper methods that aid in handling of Linux LVM2 devices.

=head1 FUNCTIONS

=head2 find_devicemapper_major

Searches for the major number of the devicemapper device

=head2 translate_devmapper_name

This method tries to find a device mapper name based on the dm minor number.

It will return either the resolved device mapper name or the original device.

=head2 translate_lvm_name

This method tries to translate an dev-mapper device name to
its LVM counterpart, e.g. /dev/mapper/vg-lv -> /dev/vg/lv

=head2 translate_mapper_name

Translates LVM names to their ugly devicemapper names
e.g. /dev/VGfoo/LVbar -> /dev/mapper/VGfoo-LVbar

=head1 NAME

Linux::LVM2::Utils - LVM2 helper methods.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
