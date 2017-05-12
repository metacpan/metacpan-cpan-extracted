package Device::ParallelPort::drv::win32;
use strict;
use Carp;

=head1 NAME

Device::ParallelPort::drv::win32 - Windows 32 Drivers Version

=head1 DESCRIPTION

This module uses the inpout32.dll common to Windows users to read and write to
the Parallel Port.  For futher details see L<Device::ParallelPort>

=head1 INSTALLATION

Standard installation, but you also need "inpout32.dll" which may require
either putting into your windows System directory, or at the location of your
executable.

=head1 inpout32.dll

inpout32.dll actually comes from a 3rd party source and is freely available.

http://www.logix4u.net/inpout32.htm

It apparently works on Win95, Win98, WinNT, Win2K and WinXP. The XP and other
ptoected mode systems has been solved by the DLL automatically loading a Kernel
Mode driver at initalisation. 

NOTE - Although this is not mentioned on this web site, it may be necessary to
have administration privs to load this DLL.

=head1 COPYRIGHT

Copyright (c) 2002,2004 Scott Penrose. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Scott Penrose L<scottp@dd.com.au>, L<http://linux.dd.com.au/>

=head1 SEE ALSO

L<Device::ParallelPort>

=cut

use Win32::API;
# NOTE - Have not considered pre Perl 5.6 support - may need to
use base qw/Device::ParallelPort::drv/;
use vars qw/$VERSION/;
$VERSION = '1.3';

# Standard function to return information from this driver
sub INFO {
	return {
		'os' => 'win32',
		'ver' => '>= 95',
		'type' => 'byte',
	};
}

sub init {
	my ($this, $str, @params) = @_;

	# Accept a HEX address - else convert lpt1 -> 0 and then 0 -> 0x378
	if ($str =~ /^0x/) {
		$this->{DATA}{BASE} = $str * 1;
	} else {
		$this->{DATA}{BASE} = $this->num_to_hardware($this->address_to_num($str));
	}
	croak "Invalid BASE address to Device::ParallelPort::drv::win32 ($str)" unless (($this->{DATA}{BASE} * 1) > 1);

	$this->{DATA}{GET} = Win32::API->new("inpout32", "Inp32", ['I'], 'I')
		or die "Failed to load inpout32.dll - Can't create Inp32 2 - $!"; #import Inp32 from DLL
        $this->{DATA}{SET} = Win32::API->new("inpout32", "Out32", ['I', 'I'], 'I')
		or die "Failed to load inpout32.dll - Can't create Out32 - $!"; #import Out32 from DLL
}

sub set_byte {
	my ($this, $byte, $val) = @_;
	croak "Invalid byte" unless ($byte >=0 && $byte <= 2);
	$this->{DATA}{SET}->Call($this->{DATA}{BASE} + $byte, ord($val));
}

sub get_byte {
	my ($this, $byte, $val) = @_;
	croak "Invalid byte" unless ($byte >=0 && $byte <= 2);
	return chr($this->{DATA}{GET}->Call($this->{DATA}{BASE} + $byte));
}

1;

