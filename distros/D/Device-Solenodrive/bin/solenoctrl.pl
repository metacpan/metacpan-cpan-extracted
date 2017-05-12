#! /usr/bin/env perl

use strict;
use warnings;
use 5.012;
use autodie;
use Pod::Help qw(-h --help);
use Getopt::Std;
use Device::Solenodrive;
use Data::Dumper;

my %opts;

# Extract the power and area file options if they are passed.
getopt( 'dvbci', \%opts );

Pod::Help->help()
    if ( !defined $opts{d} || !defined $opts{c} || !defined $opts{i} );

# Create the object
my $soleno = Device::Solenodrive->new(
    device   => $opts{d},
    verbose  => $opts{v} || 0,
    baudrate => $opts{b} || 57600
);

# Connect to the target device over the specified connection
$soleno->connect_target();

$soleno->set( $opts{i}, $opts{c} );

sleep(1);

$soleno->disconnect_target();

# ABSTRACT: Control software for Solenodrive devices over RS485
# PODNAME: solenoctrl.pl

__END__

=pod

=head1 NAME

solenoctrl.pl - Control software for Solenodrive devices over RS485

=head1 VERSION

version 0.1

=head1 DESCRIPTION

This scripts implements the control protocol to Solenodrive hardware. Solenodrive is an 8 channel solenoid controller with RS485 interface, 8 digital inputs and 8 user buttons.

=head1 SYNOPSYS

Usage:
solenoctrl.pl -d <device> -i <ID> -c <channel>

Where C<device> is either a serial port or a TCP socket (format host:portnumber) that provides the interface to the RS485 bus.

When using a serial port, the default baudrate used is 57600 bps. To override, pass
the parameter 'b' with the required baudrate when invoking the script.

C<ID> is the ID of the Solenodrive you target on the RS485 bus.

C<channel> is the channel to set.

Optionally, a parameter -v <verboselevel> can be passed to modify the verbosity
of the Device::Solenodrive module. Defaults to '0', set to '3' for useful
debugging.

=head1 AUTHOR

Lieven Hollevoet <hollie@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Lieven Hollevoet.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
