package Device::Jtag::PP;

#use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration   use Device::Jtag::PP ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.02';


# Preloaded methods go here.

use Device::ParallelPort;

###################################################################################################
# Construct the new JTAG object by specifying port and pin mapping
###################################################################################################
sub new {
  my $self  = {};
  $self->{PORT}        = Device::ParallelPort->new();
  $self->{PINMAP}      = {TDI    => 0,                   # this is the parallel port pin mapping
                          TCK    => 1,                   # for the Digilent Parallel Cable 3
                          TMS    => 2,
                          TDO    => 12};

  bless($self);
  return $self;
}


###################################################################################################
# Set TMS to specified value by driving TMS port/pin specified in configuration
###################################################################################################
sub set_tms {
  my $self = shift;
  my $data = shift;
  $self->{PORT} -> set_bit($self->{PINMAP}->{TMS},$data);
}
###################################################################################################
# Set TDI to specified value by driving TDI port/pin specified in configuration
###################################################################################################
sub set_tdi {
  my $self = shift;
  my $data = shift;
  $self->{PORT} -> set_bit($self->{PINMAP}->{TDI},$data);
}
###################################################################################################
# Toggle clock ->1->0 by driving TCK port/pin specified in configuration
###################################################################################################
sub tog_tck {
  my $self    = shift;
  my $ncycles = shift;
  foreach my $c (1..$ncycles) {
    $self->{PORT} -> set_bit($self->{PINMAP}->{TCK},1);
    $self->{PORT} -> set_bit($self->{PINMAP}->{TCK},0);
  }
}
###################################################################################################
# Read TDO from port/pin specified in configuration
###################################################################################################
sub get_tdo {
  my $self = shift;
  return $self->{PORT} -> get_bit($self->{PINMAP}->{TDO});
}

###################################################################################################
# Convert string of binary numbers to string of hex numbers
###################################################################################################
sub convert_hex {
  my $str    = shift;
  my $nbits  = length($str);
  my $hexstr = '';

  # if length of string is not a multiple of 4, add preceeding 0's
  while (length($str)%4 ne 0) {
    $str = '0'.$str;
  }
  # convert each nibble from binary to hex
  foreach my $nibble (0..(length($str)/4)-1) {
    $hexstr .= sprintf("%x", oct('0b'.substr($str,4*$nibble,4)));
  }
  return $hexstr;
}
###################################################################################################
# Instruction register shift to/from specified device in chain
# Required initial state : RTI
# Final state            : RTI
###################################################################################################
sub shiftir {
  my $self        = shift;
  my $device      = shift;
  my $instruction = shift;

  # assumes RTI is beginning state
  # Go to the SELECT-IR state
  set_tms($self,1);
  tog_tck($self,2);

  # Go to the SHIFT-IR state
  set_tms($self,0);
  tog_tck($self,2);

  # Find the number of devices on the scan chain
  my $numdev = scalar(@{$self->{CHAIN}});

  # Start with the last device in the chain, working backwards to device 0.
  # All but the selected device receive the BYPASS instruction.
  # The selected device receives the instruction designated by $instruction.
  for (my $d=$numdev-1;$d>=0;$d--) {
    my $irlen = $self->{CHAIN}->[$d]->{IRLEN};
    my $instr = ($d eq $device)? $instruction : 'BYPASS';
    my $data = $self->{CHAIN}->[$d]->{IRCMDS}->{$instr};

    #print "Sending $instr ($data) to device $d\n";
    for (my $b=length($data)-1;$b>=0;$b--) {
      my $tms = ($d eq 0 and $b eq 0)? 1 : 0; #set TMS=1 on the very last shift to go to the EXIT1-IR state
      set_tms($self,$tms);
      set_tdi($self,substr($data,$b,1));
      tog_tck($self,1);
    }
  }

  # Return to RTI state
  set_tms($self,1);
  tog_tck($self,1);

  set_tms($self,0);
  tog_tck($self,1);

}

###################################################################################################
# Data register shift to/from specified device in chain
# Required initial state : RTI
# Final state            : RTI
###################################################################################################
sub shiftdr {
  my $self    = shift;
  my $device  = shift;
  my $data    = shift;
  my $tdo     = undef;

  #print "Sending data $data to device $device...\n";

  # assumes RTI is beginning state
  # Go to the SELECT-DR state
  set_tms($self,1);
  tog_tck($self,1);

  # Go to the SHIFT-DR state
  set_tms($self,0);
  tog_tck($self,2);

  # The first bit of data we want is now sitting on TDO of the selected
  # device.  If there are any devices in the chain after the selected
  # device, the data we want must get through the each subsequent
  # device's BYPASS register, which is 1 bit long.  This means that if
  # there are N devices in the chain after the selected device, and the
  # number of bits of data being shifted is M, the total number of shifts
  # must be N+M.  Additionally, the first N bits of data received on
  # TDO should be discarded.
  $tdo = get_tdo($self);

  # Shift data, the rightmost bit goes first
  for ($b=length($data)-1;$b>=0;$b--) {
    set_tdi($self,substr($data,$b,1));
    my $tms = $b eq 0? 1 : 0;  #set TMS=1 on the last shift to go to the EXIT1-IR state
    set_tms($self,$tms);
    tog_tck($self,1);
    $tdo = get_tdo($self) . $tdo; # get tdo, build word from right to left
  }

  # Return to RTI state
  set_tms($self,1);
  tog_tck($self,1);

  set_tms($self,0);
  tog_tck($self,1);

  # Find the number of devices on the scan chain
  my $numdev = scalar(@{$self->{CHAIN}});

  # Find the number of subsequent devices on the chain following the selected device
  my $subdev = ($numdev-1)-$device;

  # Return tdo as hex string
  return convert_hex(substr($tdo, -1*(32+$subdev), 32));
}

###################################################################################################
# Initialize the JTAG chain to the RTI state.
# Required initial state : none
# Final state            : RTI
###################################################################################################
sub initialize {
  my $self = shift;

  #print "Initializing JTAG scan chain to RTI state...\n";
  # Put device(s) into TLR state
  set_tms($self,1);
  set_tdi($self,0);
  tog_tck($self,6);

  # Go to the RTI state
  set_tms($self,0);
  tog_tck($self,1);
}
###################################################################################################
# Autodetect devices in the JTAG chain and assign configuration information for each device.
# Required initial state : none
# Final state            : RTI
###################################################################################################
sub autodetect {
  my $self    = shift;
  my $tdo     = '';
  my $ndevs   = 0;
  my @idcodes = ();

  # Initialize the chain to ensure we start from the RTI state
  initialize($self);

  # Go to the SELECT-DR state
  set_tms($self,1);
  tog_tck($self,1);

  # Go to the SHIFT-DR state
  set_tms($self,0);
  tog_tck($self,2);

  print "Beginning scan chain auto-detection\n";

  # Collect 32 bits of data from each device's IDCODE register.  It would
  # seem that the JTAG spec requires that each device select its IDCODE register
  # for shifting out on TDO after device reset (probably during the TLR state).
  # I say this because empirically I see that this is the case.  This is a good
  # thing, because otherwise it would be impossible to autodetect the devices in
  # the chain since different devices have different binary codes for the IDCODE
  # instruction.
  #
  # All 0's are shifted in on TDI, so when the 32 bits collected is all 0's, we
  # know all the devices in the chain have been identified.
  while ($tdo ne '0'x32) {
    $tdo = '';                       # reset TDO for each new set of 32 bits
    for my $b (0..31) {                 # shift 32 bits of data
      $tdo = get_tdo($self) . $tdo;     # collect 32 bits of TDO data; build word from right to left
      set_tdi($self,0);                 # shift in 0s on TDI
      set_tms($self,0);
      tog_tck($self,1);
    }
    if ($tdo ne '0'x32) {
      push(@idcodes, $tdo);             # push idcodes onto stack, last device in the chain goes in first
      $ndevs++
    }
  }

  # Now reorder the device numbers so the that the last device in the
  # chain has the highest number.  The first device in the chain (closest
  # to the TDI signal from the PC) must be device 0.
  foreach my $d (0..$ndevs-1) {
    my $idcode = convert_hex(pop(@idcodes));
    idcode_lookup($self, $idcode, $d);
    printf("Device %d : IDCODE %s : %s\n", $d, $idcode, $self->{CHAIN}->[$d]->{NAME});
  }

  # Return to RTI state
  initialize($self);

  print "Auto-detect complete\n";

}

###################################################################################################
# Assign JTAG chain configuration information based upon the IDCODE.
###################################################################################################
sub idcode_lookup {
  my $self   = shift;
  my $idcode = shift;
  my $devnum = shift;

  $self->{CHAIN}->[$devnum]  =

    ($idcode =~ /^.14..093/i) ? {NAME   => 'Spartan-3 FPGA',         # device name
                                 IRLEN  => 6,                        # device instruction register length
                                 IRCMDS => {IDCODE => '001001',      # device instructions (length must match IRLEN)
                                            USER1  => '000010',
                                            USER2  => '000011',
                                            BYPASS => '111111'}}:

    ($idcode =~ /^.1c2e093/i) ? {NAME   => 'XC3S12O0E FPGA',         # device name
                                 IRLEN  => 6,                        # device instruction register length
                                 IRCMDS => {IDCODE => '001001',      # device instructions (length must match IRLEN)
                                            USER1  => '000010',
                                            USER2  => '000011',
                                            BYPASS => '111111'}}:

    ($idcode =~ /^.504.093/i) ? {NAME   => 'XCF0xS Platform Flash',  # device name
                                 IRLEN  => 8,                        # device instruction register length
                                 IRCMDS => {IDCODE => '11111110',    # device instructions (length must match IRLEN)
                                            BYPASS => '11111111'}}:

                                {NAME   => 'Unknown device',         # device name
                                 IRLEN  => 0,                        # device instruction register length
                                 IRCMDS => {}};                      # device instructions (length must match IRLEN)
}
###################################################################################################
# Read the IDCODE register for a pre-configured device in the chain.
# Required initial state : none
# Final state            : RTI
###################################################################################################
sub identify {
  my $self   = shift;
  my $device = shift;

  # Initialize the chain to ensure we start from the RTI state
  initialize($self);

  # Get the number of devices on the scan chain from the chain configuration
  my $ndevices = scalar(@{$self->{CHAIN}});

  # Ensure selected device is in range
  if ($device >= $ndevices) {
    die("Selected device to identify ($device) is not defined in scan chain\n") ;
  }

  shiftir($self, $device, 'IDCODE');
  print "Identifying Device $device: IDCODE = 0x". shiftdr($self, $device, '0'x32) . "\n";

}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Device::Jtag::PP - Perl extension for communicating with JTAG devices via PC parallel port.

=head1 SYNOPSIS

  use Device::Jtag::PP;
  my $jtag = Device::Jtag::PP->new();
  $jtag->autodetect();
  $jtag->shiftir($device_number, $binary_string);
  $jtag->shiftdr($device_number, $binary_string);

=head1 DESCRIPTION

Facilitates communication with JTAG devices using the Windows parallel port driving a
Digilent Parallel Cable 3 (commonly shipped with Xilinx Spartan-3 FPGA evaluation boards).


=head2 EXPORT

None by default.

=head1 PREREQUISITES
One must install the Perl module Device-Parallel port, which in turn requires that the file
inpout32.dll available from L<http://www.logix4u.net/inpout32.htm> be copied to the
Windows\sytem32 folder.

=head1 CONSTRUCTOR
=head2 new
=over 4
=item new()
Creates a C<Device::Jtag::PP>
=back

=head1 METHODS
=over 4
=item initialize()
Initializes the devices on the JTAG chain to the RTI state.

=item autodetect()
Auto detects devices on the JTAG scan chain by shiting out 32-bit IDCODE register values for each
device on the chain.  The subroutine idcode_lookup is called for each 32 bit value to assign
information for that device.  Currently, only the IDCODEs for Spartan-3 and XCF0xS Flash PROMs
are available, but the user can easily add his own.

=item shiftir(DEVICE, BIT_STRING)
Shift BIT_STRING (a simple string of 0's and 1's) to the instruction register of device number
DEVICE (integer) on the JTAG chain.  All other devices on the chain get the BYPASS instruction.
The device closest to the PC's outgoing serial data is defined as device 0.  The length of
BIT_STRING must match the number of bits defined for that device's instruction register.

= item shiftdr(DEVICE, BIT_STRING)
Shift BIT_STRING (a simple string of 0's and 1's) to the data register of device number
DEVICE (integer) on the JTAG chain. The device closest to the PC's outgoing serial data is
defined as device 0.  The length of BIT_STRING must match the number of bits defined for that
device's instruction register.  Returns a hexadecimal string of the data received on TDO from
device number DEVICE.

=head1 HISTORY
=over
=item 0.1 - First release
Basic first release. IDCODE support for Spartan-3 and XCF0xS Flash PROM devices only.
=back

=head1 SEE ALSO

L<www.xilinx.com/bvdocs/appnotes/xapp139.pdf> for information on JTAG tap controllers.

=head1 AUTHOR

Toby Deitrich, E<lt>tdeitrich@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Toby Deitrich

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
