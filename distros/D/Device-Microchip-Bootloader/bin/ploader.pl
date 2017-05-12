#! /usr/bin/env perl

use strict;
use warnings;
use 5.012;
use autodie;
use Pod::Help qw(-h --help);
use Getopt::Std;
use Device::Microchip::Bootloader;

my %opts;

# Extract the power and area file options if they are passed.
getopt( 'dfvb', \%opts );

#Pod::Help->help() if ( !defined $opts{d} && !defined $opts{h} );

# Create the object
my $loader;

if (defined $opts{b}) {
    $loader = Device::Microchip::Bootloader->new(
        firmware => $opts{f},
        device   => $opts{d},
        verbose  => $opts{v} || 0,
        baudrate => $opts{b}
    );
} else {
    $loader = Device::Microchip::Bootloader->new(
        firmware => $opts{f},
        device   => $opts{d},
        verbose  => $opts{v} || 0,
    );
}

# Connect to the target device over the specified connection
$loader->connect_target();

my $response;

# Load the bootloader goto that is located at the beginning of the flash.
# TODO check this is EF01F07E for 18F46J11
$response = $loader->read_flash( 0, 4 );

# Rewrite the entry point for the application and the bootloader in the memory that will be programmed.
$loader->_rewrite_entrypoints($response);

# Erase the device in 1k blocks, so 64 pages are required
$loader->erase_flash( 0xFC00, 64 );

# Write pages, ensure we try to write up to the bootloader (that starts a block 1008)
my $block = 0;
while ( $block < 1008 ) {
    my $data = $loader->_get_writeblock($block);
    if ( $data ne "" ) {
        say("Writing block $block");
        $loader->write_flash( $block * 64, $data );
    }
    $block++;
}

# Fire in dze hall!
$loader->launch_app();

# ABSTRACT: Bootloader for Microchip PIC devices
# PODNAME: ploader.pl

__END__

=pod

=head1 NAME

ploader.pl - Bootloader for Microchip PIC devices

=head1 VERSION

version 0.7

=head1 DESCRIPTION

This scripts implements a Microchip bootloader interface over serial port or over a TCP socket.
The PIC needs to be pre-programmed with a bootloader that meets the spec of AN1310A.

=head1 SYNOPSYS

Usage:
ploader.pl -d <device> -f <hexfile>

Where C<device> is either a serial port or a TCP socket (format host:portnumber)
and C<hexfile> is the Intel hex file to be loaded into the PIC.

When using a serial port, the default baudrate used is 115200 bps. To override, pass
the parameter 'b' with the required baudrate when invoking the script.

Optionally, a parameter -v <verboselevel> can be passed to modify the verbosity
of the Device::Microchip::Bootloader module. Defaults to '0', set to '3' for useful
debugging.

=head1 AUTHOR

Lieven Hollevoet <hollie@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Lieven Hollevoet.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
