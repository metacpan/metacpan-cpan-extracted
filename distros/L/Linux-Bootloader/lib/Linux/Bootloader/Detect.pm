package Linux::Bootloader::Detect;

=head1 NAME

Linux::Bootloader::Detect - detects the bootloader and architecture of the system.

=head1 SYNOPSIS

Attempts to determine the bootloader by checking for configuration files
for grub, lilo, elilo and yaboot then searching the master boot record
for GRUB, LILO, ELILO and YABOOT.

Determines the architecture by running uname -m.

=head1 DESCRIPTION

To attempt to discover the bootloader being used by the system
detect_bootloader first calls detect_bootloader_from_conf attempts to locate
/boot/grub/menu.lst, /etc/lilo.conf, /boot/efi/elilo.conf and
/etc/yaboot.conf and returns the corresponding bootloader name. If
either undef of multiple are returned because no configuration files or
multiple configuration files were found detect_bootloader calls
detect_bootloader_from_mbr which generates a list of all devices accessable from
the /dev directory reading in the first 512 bytes from each hd and sd
device using head then redirects the output to grep to determine if
"GRUB", "LILO", "ELILO" or "YABOOT" is present returning the
corresponding value if exactly one mbr on the system contained a
bootloader or multiple if more than one was found and undef if none were
found. detect_bootloader returns either grub, lilo, elilo, yaboot or
undef.

To attempt to discover the architecture of the system
detect_architecture makes a uname -m system call returning x86, ppc,
ia64 or undef.

=head1 FUNCTIONS

=cut

use strict;
use warnings;

use vars qw( $VERSION );
our $VERSION = '1.2';

=head3 detect_architecture([style])

Input:
Output: string

This function determines the architecture by calling uname -m.  By
default it will report back exactly what uname -m reports, but if you
specify a "style", detect_architecture will do some mappings.  Possible
styles include:

 Style    Example return values (not an exhaustive list...)
 [none]   i386, i686, sparc, sun4u, ppc64, s390x, x86_64, parisc64
 linux    i386, i386, sparc, sparc, ppc64, s390,  x86_64, parisc
 gentoo    x86,  x86, sparc, sparc, ppc64,         amd64, hppa

Returns undef on error.

=cut

sub detect_architecture {
    my $arch_style = shift || 'uname';

    my $arch;
    if ($arch_style eq 'linux') {
        $arch = `uname -m | sed -e s/i.86/i386/ -e s/sun4u/sparc64/ -e s/arm.*/arm/ -e s/sa110/arm/ -e s/s390x/s390/ -e s/parisc64/parisc/`;
        chomp $arch;
    } elsif ($arch_style eq 'gentoo') {
        $arch = `uname -m | sed -e s/i.86/x86/ -e s/sun4u/sparc/ -e s/arm.*/arm/ -e s/sa110/arm/ -e s/x86_64/amd64/ -e s/sparc.*/sparc/ -e s/parisc.*/hppa/`;
        chomp $arch;
    } else {
        $arch = `uname -m`;
        chomp $arch;
    }
    return $arch;
}

=head3 detect_bootloader(['device1', 'device2', ...])

Input:  devices to detect against (optional)
Output: string

This function attempts to determine the bootloader being used on the
system by first checking for conf files and then falling back to check
the master boot record.

Possible return values:     

    grub        grub was determined to be the bootloader in use
    lilo        lilo was determined to be is the bootloader in use
    elilo       elilo was determined to be the bootloader in use
    yaboot      yaboot was determined to be the bootloader in use
    undef       it was impossible to determine which bootloader was being used
                due either to configuration files for multiple bootloaders or
                bootloader on multiple hard disks

=cut

sub detect_bootloader {
    return detect_bootloader_from_conf(@_) 
        || detect_bootloader_from_mbr(@_);
}

=head2 detect_bootloader_from_conf()

Detects bootloaders by the presence of config files.  This is not as
reliable of a mechanism as looking in the MBR, but tends to be
significantly faster.  

If called in list context, it will return a list of the bootloaders that
it found.

If called in scalar context and only a single bootloader config file is
present it will return the name of that bootloader.  Otherwise, if
multiple (or no) bootloaders are detected, it will return undef.

=cut

sub detect_bootloader_from_conf {
    my @boot_loader = ();

    my %boot_list = ( grub   => '/boot/grub/menu.lst', 
                      lilo   => '/etc/lilo.conf', 
                      elilo  => '/etc/elilo.conf', 
                      yaboot => '/etc/yaboot.conf' 
                      );

    foreach my $key ( sort keys %boot_list ) {
        if ( -f $boot_list{$key} ) {
            push ( @boot_loader, $key ); 
        }
    }

    if (wantarray()) {
        return @boot_loader;
    } elsif (@boot_loader == 1) {
        return pop( @boot_loader );
    } else {
        return undef;
    }
}

=head2 detect_bootloader_from_mbr([@devices])

Detects the bootloader by scanning the master boot record (MBR) of the
specified devices (or all devices if not indicated).  

The device arguments must be relative to the /dev/ directory.  I.e.,
('hda', 'sdb', 'cdroms/cdrom0', etc.)

=cut

sub detect_bootloader_from_mbr {
    my @filelist = @_;
    my @boot_loader = ();

    my %map = (
        "GRUB"   => 'grub',
        "LILO"   => 'lilo',
        "EFI"    => 'elilo',
        "yaboot" => 'yaboot',
    );

    if ( ! @filelist && opendir( DIRH, "/sys/block" ) ) {
        @filelist = grep { /^[sh]d.$/ } readdir(DIRH);
        closedir(DIRH);
    }

    foreach ( @filelist ) {
        if ( -b "/dev/$_" ) {
            my $strings = `dd if=/dev/$_ bs=512 count=1 2>/dev/null | strings`;
            foreach my $loader (keys %map) {
                if ($strings =~ /$loader/ms) {
                    push @boot_loader, $map{$loader};
                }
            }
        }
    }
    
    if (wantarray()) {
        # Show them all
        return @boot_loader;
    } elsif (@boot_loader == 1) {
        # Found exactly one
        return pop @boot_loader;
    } elsif (@boot_loader == 2) {
        # This is the Lilo/Grub exception
        # Grub on MBR with previous Lilo install
        # Are they lilo and grub in that order?
        if ($boot_loader[0] eq 'lilo' and $boot_loader[1] eq 'grub'){
            warn "Warning:  Grub appears to be used currently, but Lilo was in pasti.\n";
            return $boot_loader[1];
        }
    }

    # Either none or too many to choose from
    return undef;
}

1;

=head1 AUTHOR

Open Source Development Labs, Engineering Department <eng@osdl.org>

=head1 COPYRIGHT

Copyright (C) 2006 Open Source Development Labs
All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Linux::Bootloader>

=cut

