package Device::Jtag::USB::FTCJTAG;

#use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration   use Device::Jtag::USB::FTCJTAG ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.12';


# Preloaded methods go here.

use Win32::API 0.46;
use Bit::Vector 6.4;

###################################################################################################
# Set debug verbosity level
###################################################################################################
my $DEBUG = 1;

###################################################################################################
# Define FTC_STATUS return values
###################################################################################################
my $ftc_status_type_aref;
$ftc_status_type_aref->[ 0] = 'FTC_SUCCESS';
$ftc_status_type_aref->[ 1] = 'FTC_INVALID_HANDLE';
$ftc_status_type_aref->[ 2] = 'FTC_DEVICE_NOT_FOUND';
$ftc_status_type_aref->[ 3] = 'FTC_DEVICE_NOT_OPENED';
$ftc_status_type_aref->[ 4] = 'FTC_IO_ERROR';
$ftc_status_type_aref->[ 5] = 'FTC_INSUFFICIENT_RESOURCES';
$ftc_status_type_aref->[20] = 'FTC_FAILED_TO_COMPLETE_COMMAND';
$ftc_status_type_aref->[21] = 'FTC_FAILED_TO_SYCHRONIZE_DEVICE_MPSSE';
$ftc_status_type_aref->[22] = 'FTC_INVALID_DEVICE_NAME_INDEX';
$ftc_status_type_aref->[23] = 'FTC_NULL_DEVICE_NAME_BUFFER_POINTER';
$ftc_status_type_aref->[24] = 'FTC_DEVICE_NAME_BUFFER_TOO_SMALL';
$ftc_status_type_aref->[25] = 'FTC_INVALID_DEVICE_NAME';
$ftc_status_type_aref->[26] = 'FTC_INVALID_LOCATION_ID';
$ftc_status_type_aref->[27] = 'FTC_DEVICE_IN_USE';
$ftc_status_type_aref->[28] = 'FTC_TOO_MANY_DEVICES';
$ftc_status_type_aref->[29] = 'FTC_INVALID_FREQUENCY_VALUE';
$ftc_status_type_aref->[30] = 'FTC_NULL_INPUT_OUTPUT_BUFFER_POINTER';
$ftc_status_type_aref->[31] = 'FTC_INVALID_NUMBER_BITS';
$ftc_status_type_aref->[32] = 'FTC_NULL_WRITE_DATA_BUFFER_POINTER';
$ftc_status_type_aref->[33] = 'FTC_INVALID_NUMBER_BYTES';
$ftc_status_type_aref->[34] = 'FTC_NUMBER_BYTES_TOO_SMALL';
$ftc_status_type_aref->[35] = 'FTC_INVALID_TAP_CONTROLLER_STATE';
$ftc_status_type_aref->[36] = 'FTC_NULL_READ_DATA_BUFFER_POINTER';
$ftc_status_type_aref->[37] = 'FTC_NULL_DLL_VERSION_BUFFER_POINTER';
$ftc_status_type_aref->[38] = 'FTC_DLL_VERSION_BUFFER_TOO_SMALL';
$ftc_status_type_aref->[39] = 'FTC_NULL_LANGUAGE_CODE_BUFFER_POINTER';
$ftc_status_type_aref->[40] = 'FTC_NULL_ERROR_MESSAGE_BUFFER_POINTER';
$ftc_status_type_aref->[41] = 'FTC_ERROR_MESSAGE_BUFFER_TOO_SMALL';
$ftc_status_type_aref->[42] = 'FTC_INVALID_LANGUAGE_CODE';
$ftc_status_type_aref->[43] = 'FTC_INVALID_STATUS_CODE';

###################################################################################################
# Define JTAG TAP controller states
###################################################################################################
use constant TEST_LOGIC_STATE                 => 1;
use constant RUN_TEST_IDLE_STATE              => 2;
use constant PAUSE_TEST_DATA_REGISTER_STATE   => 3;
use constant PAUSE_INSTRUCTION_REGISTER_STATE => 4;
use constant SHIFT_TEST_DATA_REGISTER_STATE   => 5;
use constant SHIFT_INSTRUCTION_REGISTER_STATE => 6;

###################################################################################################
# Define FTDI chip buffer size (64k bits)
###################################################################################################
my $ftdi_buffer_size = 65535;

###################################################################################################
# Define Instruction Register vs Data Register constants
###################################################################################################
use constant IRSHIFT => 1;
use constant DRSHIFT => 0;

###################################################################################################
# Construct the new object
##################################################################################################
sub new {
  my $self = {};

  debug('new', 1, "Debug level set to $DEBUG");

  # Import API functions and assign to function handles
  debug('new', 1, "Importing APIs");
  foreach my $href (
    {perl_name => 'get_ndev', c_name => 'JTAG_GetNumDevices'      , inputs => 'P'     , outputs => 'N'},
    {perl_name => 'open'    , c_name => 'JTAG_Open'               , inputs => 'P'     , outputs => 'N'},
    {perl_name => 'init'    , c_name => 'JTAG_InitDevice'         , inputs => 'NN'    , outputs => 'N'},
    {perl_name => 'write'   , c_name => 'JTAG_Write'              , inputs => 'NNNPNN', outputs => 'N'},
    {perl_name => 'read'    , c_name => 'JTAG_Read'               , inputs => 'NNNPPN', outputs => 'N'},
    {perl_name => 'gen_clks', c_name => 'JTAG_GenerateClockPulses', inputs => 'NN'    , outputs => 'N'},
    {perl_name => 'get_gpio', c_name => 'JTAG_GetGPIOs'           , inputs => 'NNPNP' , outputs => 'N'},
    {perl_name => 'set_gpio', c_name => 'JTAG_SetGPIOs'           , inputs => 'NNPNP' , outputs => 'N'}) {

    $self->{fh}->{$href->{perl_name}} = Win32::API->new('FTCJTAG', $href->{c_name}, $href->{inputs}, $href->{outputs});
    die(debug('new', 0, sprintf("Unable to import API %s: %s", $href->{c_name}, $!))) if(not defined $self->{fh}->{$href->{perl_name}});
  }


  # Open JTAG key
  debug('new', 1, "Opening JTAGKey");
  my $ftc_handle_lw = ' 'x4; # pre-allocate 4 bytes to long word
  my $ftc_status = $self->{fh}->{open}->Call($ftc_handle_lw);
  die(debug('new', 0, sprintf("Unable to open JTAGKey : %s", $ftc_status_type_aref->[$ftc_status]))) if ($ftc_status);

  # Assign JTAGKey device handle
  $self->{key} = unpack('L', $ftc_handle_lw); # unpack long word

  # Initialize JTAGKey to 6MHz transfer rate
  debug('new', 1, "Setting JTAGKey transfer rate");
  $ftc_status = $self->{fh}->{init}->Call($self->{key},0);
  die(debug('new', 0, sprintf("Unable to initialize JTAGkey : %s", $ftc_status_type_aref->[$ftc_status]))) if ($ftc_status);

  # Read JTAGKey GPIOs to see that VREF is powered
  debug('new', 1, "Checking JTAGKey power");
  my $gpio_lo_lw   = ' 'x16; # pre-allocate 4x4 long words
  my $gpio_hi_lw   = ' 'x16; # pre-allocate 4x4 long words
  $ftc_status      = $self->{fh}->{get_gpio}->Call($self->{key}, 1, $gpio_lo_lw, 1, $gpio_hi_lw);
  die(debug('new', 0, sprintf("Unable to read JTAGkey GPIOs : %s", $ftc_status_type_aref->[$ftc_status]))) if ($ftc_status);
  my $gpio_lo_aref = [unpack('L4', $gpio_lo_lw)]; # unpack 4 long words into array ref
  my $gpio_hi_aref = [unpack('L4', $gpio_hi_lw)]; # unpack 4 long words into array ref

  #foreach $b (0..3) {
  #  printf("GPIOL-%d = %d\n", $b, $gpio_lo_aref->[$b]);
  #}

  # Check JTAGKey VREF (GPIO LO bit 1 low if powered)
  die(debug('new', 0, "JTAGKey VREF not powered")) if ($gpio_lo_aref->[1] eq 1);

  # Set JTAGKey GPIO controlling output enable
  debug('new', 1, "Setting JTAGKey output enable");
  my $gpiol_data = (0,0,0,0,0,0,0,1); # this does not make sense, but happens to work
  my $gpioh_data = (0,0,0,0,0,0,0,0);
  $ftc_status = $self->{fh}->{set_gpio}->Call($self->{key}, 1, pack('L8',$gpiol_data), 0, pack('L8',$gpioh_data));
  die(debug('new', 0, sprintf("[FTCJTAG.PM] Unable to set JTAGkey GPIOs : %s", $ftc_status_type_aref->[$ftc_status]))) if ($ftc_status);

  # Check JTAGKey output enable (GPIO LO bit 0 low)
  #die("ERROR: JTAG_OE_N not driven low\n") if ($gpio_lo_aref->[0] eq 0);

  # Send JTAG devices to TEST LOGIC RESET state
  init_chain($self);

  # Autodetect devices on scan chain
  autodetect($self);

  bless($self);
  return $self;
}

###########################################################################################################
# Initialized scan chain devices to TEST_LOGIC_STATE
###########################################################################################################
sub init_chain {
  my $self = shift;

  debug('init_chain', 1, "Initializing scan chain");

  # Perform the USB operation
  my $data_lw = pack('L', 0);
  my $ftc_status = $self->{fh}->{write}->Call($self->{key}, IRSHIFT, 2, $data_lw, $ftdi_buffer_size, TEST_LOGIC_STATE);

}

###########################################################################################################
# Autodetect the IDCODEs of the devices on the chain and assign info
###########################################################################################################
sub autodetect {
  my $self       = shift;

  # Allocate memory
  my $rbuffer_lw = ' 'x$ftdi_buffer_size; # allocate memory for read string
  my $nbytes_lw  = ' 'x4;                 # allocate memory for number of bytes read

  my $idcode = '';
  my $dev = 0;
  my @idcodes = ();

  debug('autodetect', 1, "Autodetecting devices on scan chain");

  # Read IDCODEs, up to a max of 10 (this is arbitrary), until all zeroes are received
  while ($idcode ne '0'x32 and $dev < 10) {
    # Shift 32 bits through data registers, be sure to end in the PAUSE-DR state.  If we return to the RUN-TEST-IDLE state
    # then each device will reload its IDCODE data register.
    my $ftc_status = $self->{fh}->{read}->Call($self->{key}, DRSHIFT, 32, $rbuffer_lw, $nbytes_lw, PAUSE_TEST_DATA_REGISTER_STATE);

    # Check return status
    die(debug('autodetect', 0, sprintf("Unable to read via JTAGkey : %s",  $ftc_status_type_aref->[$ftc_status]))) if ($ftc_status);

    # Unpack long words into binary string
    $idcode = sprintf("%032b", unpack('L', $rbuffer_lw));

    # Add current IDCODE to array of IDCODEs
    push(@idcodes, $idcode) if $idcode ne '0'x32;
    debug('autodetect', 2, "Read IDCODE = $idcode");

    $dev++;
  }

  # Assign device information and store in object.  The last idcode pushed onto the array is the first one in the chain, which
  # is defined here as device 0.
  $dev = 0;
  while (my $idcode = pop(@idcodes)) {
    debug('autodetect', 2, sprintf("Looking up device information for IDCODE = %s", $idcode));
    $self->{di}->[$dev] = idcode_lookup($idcode);
    debug('autodetect', 1, sprintf("DEVICE %d : %s", $dev, $self->{di}->[$dev]->{name}));
    $dev++;
  }

  return;
}

###########################################################################################################
# Instruction register write to JTAG scan chain device
# Usage: write_dev_ir($self, $devid, $imntr, [$endstate]);
# Return: nothing
###########################################################################################################
sub write_dev_ir {
  my $self = shift;   # jtagusb object
  my $href = shift;   # href containing parameters
  
  my $dev  = $href->{dev};   # integer scan chain position of device to write, beginning with 0
  my $imn  = $href->{imn};   # string containing instruction mnemonic to write to selected device
  my $end  = $href->{end};   # optional state to leave device in

  # Find number of devices in scan chain
  my $nscdevs    = scalar(@{$self->{di}});

  # Construct full binary string to be shifted by padding the non-selected device data with the BYPASS command
  my $data = '';
  foreach my $d (0..$nscdevs-1) {
    # All devices on the chain other than the selected device get the BYPASS instruction
    my $imn_tmp = ($d eq $dev)? $imn : 'bypass';

    # Flag an error if the binary equivalent of the instruction isn't defined
    if (not defined $self->{di}->[$d]->{ircmds}->{$imn_tmp}) {
      die(debug('write_dev_ir', 0, "Instruction $imn_tmp not defined for scan chain device $d"));
    }
    # Get binary equivalent of instruction and add it to the binary string of write data
    my $i0b = $self->{di}->[$d]->{ircmds}->{$imn_tmp};
    $data .= $i0b;
    debug('write_dev_ir', 2, sprintf("Writing %s (0b%s) to device %d", uc($imn_tmp), $i0b, $d));
  }
  
  # Form Bit::Vector object containing binary string
  my $vec = Bit::Vector->new_Bin(length($data), $data);

  # Call write_dev subroutine
  write_dev($self, 
            {vec => $vec, 
             typ => IRSHIFT,
             end => $end});

  return;

}

###########################################################################################################
# Data register write to JTAG scan chain device
# Usage: write_dev_dr($self, $deviceid, $vec, [$end]);
# Return: nothing
###########################################################################################################
sub write_dev_dr {
  my $self = shift;   # jtagusb object
  my $href = shift;   # href containing parameters
  
  my $dev  = $href->{dev};    # integer scan chain position of device to write, beginning with 0
  my $vec  = $href->{vec};    # Bit::Vector object containing data to be written to device
  my $end  = $href->{end};    # optional state to leave device in

  # Pad the data with 0's on the left, depending upon the desired device's position in the scan chain
  # All devices in the scan chain -- other than the one that we're interested in -- are assumed to
  # be in the BYPASS state, representing a single flip flop in the chain.  So, if there are any devices
  # in the chain before the one we're writing to (this would be represented by the $dev of the device
  # we're writing to being nonzero), then pad the end of the write string with a 0 for each device in
  # the chain preceeding the one we're writing to.
  my $pad_vec = Bit::Vector->new_Bin($dev, 0)->Concat($vec); # pad vector with additional 0's on the left

  # Write to device
  write_dev($self,
            {vec => $pad_vec, 
             typ => DRSHIFT,
             end => $end});
  
  return;
}

###########################################################################################################
# Write to JTAG device
# Usage: write_dev($self, $deviceid, $vector, $type (IRSHIFT or DRSHIFT), [$endstate]);
# Return: nothing
###########################################################################################################
sub write_dev {
  my $self = shift;   # jtagusb object
  my $href = shift;   # href containing parameters
  
  my $vec  = $href->{vec};    # Bit::Vector object containing data to be written to device
  my $typ  = $href->{typ};    # shift type: IRSHIFT or DRSHIFT
  my $end  = $href->{end};    # optional state to leave device in

  # Trap unspecified endstate
  if (not $end) {
    $end = RUN_TEST_IDLE_STATE;
  }

  # Convert Data::Vector object to binary string
  my $data = $vec->to_Bin();

  # Determine number of bits to shift
  my $nbits = length($data);

  debug('write_dev', 2, sprintf("Performing %s of 0b$data ($nbits bits)", $typ eq IRSHIFT? 'IRSHIFT' : 'DRSHIFT'));

  # Convert data to integer array @words, must be done 32 bits at a time
  my $nlw = int((length($data)-1)/32) + 1;
  my @words;

  debug('write_dev', 2, "Packing $nlw words");
  for my $i (1..$nlw) {
    my $datalen = length($data);
    debug('write_dev', 2, sprintf("Data: %s (Length %s)", $data, $datalen));
    my $offset  = ($datalen > 32)? -32 : 0;
    my $length  = ($datalen > 32)?  32 : $datalen;
    my $word = substr($data,$offset,$length); # get rightmost 32 bits
    debug('write_dev', 2, sprintf("Long Word $i (%d,%d): %s", $offset,$length, $word));
    substr($data,$offset,$length) = '';
    push(@words, oct('0b'.$word));
  }

  # pack integer data
  my $data_lw = pack('L'x$nlw, @words);
  
  # Perform the USB operation
  my $ftc_status = $self->{fh}->{write}->Call($self->{key}, $typ, $nbits, $data_lw, $ftdi_buffer_size, $end);

  # Check return status
  die(debug('write_dev', 0, "Unable to write")) if ($ftc_status);

  return;
}

###########################################################################################################
# Read from data register of specified JTAG scan chain device
# Usage: read_dev($self, $devid, $nbits, [$endstate]);
# Return: Bit::Vector containing data read from selected device
###########################################################################################################
sub read_dev_dr {
  my $self = shift;   # jtagusb object
  my $href = shift;   # href containing parameters
  
  my $dev   = $href->{dev};    # integer scan chain position of device to read, beginning with 0
  my $nbits = $href->{nbits};  # number of bits to read
  my $end   = $href->{end};    # optional state to leave device in

  my $rbuffer_lw = ' 'x$ftdi_buffer_size;   # allocate memory for read string
  my $nbytes_lw  = ' 'x4;                   # allocate memory for number of bytes read

  # Trap unspecified endstate
  if (not $end) {
    $end = RUN_TEST_IDLE_STATE;
  }

  # The first bit of data we want is sitting on TDO of the selected device.  If there are any devices in
  # the chain after the selected device, the data we want must get through those subsequent devices.
  # If this is a DRSHIFT, we assume each non-selected device has been given the BYPASS command, thus each
  # non-selected device will place the 1-bit BYPASS register on the chain.  This means that if there are 
  # N devices in the chain after the selected device, and the number of bits of data being shifted is M, 
  # the total number of shifts must be 1*N+M. Finally, the first N bits of data received on TDO should be 
  # discarded.
  my $nbits_extra = scalar(@{$self->{di}}) - ($dev+1);  # Num devices on the scan chain after the selected device

  debug('read_dev', 2, sprintf("Reading %d bits from device %d", $nbits, $dev));
  debug('read_dev', 2, sprintf("Reading %d extra bits from device %d", $nbits_extra, $dev));

  # Perform the USB operation
  my $ftc_status = $self->{fh}->{read}->Call($self->{key}, DRSHIFT, $nbits + $nbits_extra, $rbuffer_lw, $nbytes_lw, $end);

  # Check return status
  die(debug('read_dev', 0, sprintf("Unable to read via JTAGkey : %s", $ftc_status_type_aref->[$ftc_status]))) if ($ftc_status);

  # Calculate the number of long words to convert (each long word is 32 bytes)
  my $nlw = int(($nbits+$nbits_extra-1)/32) + 1;

  debug('read_dev', 2, "Converting $nlw long words");

  # Unpack long words into binary string
  my $rdata_bstr = '';
  foreach my $d (unpack('L'x$nlw, $rbuffer_lw)) {
    $rdata_bstr = sprintf("%032b",$d) . $rdata_bstr;
  }
  debug('read_dev', 2, sprintf("Binary read data: %s", $rdata_bstr));

  my $vector = Bit::Vector->new_Bin($nbits, substr($rdata_bstr, -1*($nbits+$nbits_extra), $nbits));
  return($vector);

}

###########################################################################################################
# IDCODE LOOKUP
# This information is lifted from Xilinx BSDL files
###########################################################################################################
sub idcode_lookup {
  my $idcode0b = shift;

  my $bsdl_info_href;

  $bsdl_info_href->{'....0001010000011100000010010011'} =  {name   => 'XC3S400_FT256',
                                                            ircmds => {extest    => '000000', #
                                                                       sample    => '000001', #
                                                                       user1     => '000010', # -- Not available until after configuration
                                                                       user2     => '000011', # -- Not available until after configuration
                                                                       cfg_out   => '000100', # -- Not available during configuration with another mode.
                                                                       cfg_in    => '000101', # -- Not available during configuration with another mode.
                                                                       intest    => '000111', #
                                                                       usercode  => '001000', #
                                                                       idcode    => '001001', #
                                                                       highz     => '001010', #
                                                                       jprogram  => '001011', # -- Not available during configuration with another mode.
                                                                       jstart    => '001100', # -- Not available during configuration with another mode.
                                                                       jshutdown => '001101', # -- Not available during configuration with another mode.
                                                                       bypass    => '111111'  #
                                                                      }};
  
  $bsdl_info_href->{'....0001010000101000000010010011'} =  {name   => 'XC3S1000_FT256',
                                                            ircmds => {extest    => '000000', #
                                                                       sample    => '000001', #
                                                                       user1     => '000010', # -- Not available until after configuration
                                                                       user2     => '000011', # -- Not available until after configuration
                                                                       cfg_out   => '000100', # -- Not available during configuration with another mode.
                                                                       cfg_in    => '000101', # -- Not available during configuration with another mode.
                                                                       intest    => '000111', #
                                                                       usercode  => '001000', #
                                                                       idcode    => '001001', #
                                                                       highz     => '001010', #
                                                                       jprogram  => '001011', # -- Not available during configuration with another mode.
                                                                       jstart    => '001100', # -- Not available during configuration with another mode.
                                                                       jshutdown => '001101', # -- Not available during configuration with another mode.
                                                                       bypass    => '111111'  #
                                                                      }};

  $bsdl_info_href->{'....0101000001000110000010010011'} =  {name   => 'XCF04S_VO20',
                                                            ircmds => {bypass   => '11111111',
                                                                       sample   => '00000001',
                                                                       preload  => '00000001',
                                                                       extest   => '00000000',
                                                                       idcode   => '11111110',
                                                                       usercode => '11111101',
                                                                       highz    => '11111100',
                                                                       clamp    => '11111010',
                                                                       config   => '11101110'}};

  $bsdl_info_href->{'....0001110000100010000010010011'} =  {name   => 'XC3S500E_FT256',
                                                            ircmds => {extest        => '001111', #
                                                                       sample        => '000001', #
                                                                       preload       => '000001', # Not available until after configuration
                                                                       user1         => '000010', # Not available until after configuration
                                                                       user2         => '000011', # Not available during configuration with another mode.
                                                                       cfg_out       => '000100', # Not available during configuration with another mode.
                                                                       cfg_in        => '000101', #
                                                                       intest        => '000111', #
                                                                       usercode      => '001000', #
                                                                       idcode        => '001001', #
                                                                       highz         => '001010', # Not available during configuration with another mode.
                                                                       jprogram      => '001011', # Not available during configuration with another mode.
                                                                       jstart        => '001100', # Not available during configuration with another mode.
                                                                       jshutdown     => '001101', #
                                                                       bypass        => '111111', #
                                                                       isc_enable    => '010000', #
                                                                       isc_program   => '010001', #
                                                                       isc_noop      => '010100', #
                                                                       isc_read      => '010101',
                                                                       isc_disable   => '010110'}}; 
                                                                       
                                                                       
  $bsdl_info_href->{'....0001110000101110000010010011'} =  {name   => 'XC3S1200E_FT256',
                                                            ircmds => {EXTEST        => '001111', #
                                                                       SAMPLE        => '000001', #
                                                                       PRELOAD       => '000001', # Not available until after configuration
                                                                       USER1         => '000010', # Not available until after configuration
                                                                       USER2         => '000011', # Not available during configuration with another mode.
                                                                       CFG_OUT       => '000100', # Not available during configuration with another mode.
                                                                       CFG_IN        => '000101', #
                                                                       INTEST        => '000111', #
                                                                       USERCODE      => '001000', #
                                                                       IDCODE        => '001001', #
                                                                       HIGHZ         => '001010', # Not available during configuration with another mode.
                                                                       JPROGRAM      => '001011', # Not available during configuration with another mode.
                                                                       JSTART        => '001100', # Not available during configuration with another mode.
                                                                       JSHUTDOWN     => '001101', #
                                                                       BYPASS        => '111111', #
                                                                       ISC_ENABLE    => '010000', #
                                                                       ISC_PROGRAM   => '010001', #
                                                                       ISC_NOOP      => '010100', #
                                                                       ISC_READ      => '010101',
                                                                       ISC_DISABLE   => '010110'}};

  foreach my $key (keys %$bsdl_info_href) {
    if ($idcode0b =~ m/$key/) {
      return $bsdl_info_href->{$key};
    }
  }
  die(debug('idcode_lookup', 0, "No IDCODE match for $idcode0b found"));
}

###########################################################################################################
# PRINT DEBUGGING INFORMATION
###########################################################################################################
sub debug {
  my $sub = shift;
  my $print_level = shift;
  my $message = shift;

  if ($DEBUG >= $print_level) {
    printf("[%s][%-12.12s] %s\n", 'FTCJTAG', uc($sub), $message);
  }
}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Device::Jtag::USB::FTCJTAG - Perl extension for communicating with JTAG devices
using the FTDI FTCJTAG driver.

=head1 SYNOPSIS

  use Device::Jtag::USB::FTCJTAG;
  my $jtag = Device::Jtag::USB::FTCJTAG->new();
  $jtag->write_dev_ir({dev => $devnum, imn => 'user1'});
  $jtag->write_dev_dr({dev => $devnum, vec => Bit::Vector->new_Hex(32, "12345678")});
  my $readvec = $jtag->read_dev_dr({dev => $devnum, nbits => 32});
  
=head1 DESCRIPTION

A JTAG device driver for Perl using the FTDI Chip FTCJTAG driver (see
L<http://ftdichip.com/Projects/MPSSE/FTCJTAG.htm>).  The driver is designed
for use with the FTDI Chip FT2232 USB UART/FIFO IC (see
L<http://ftdichip.com/Products/FT2232C.htm>).  A hardware device is required
which incorporates the FT2232 chip in a form that (a) connects to a PC's
USB port on one end and (b) connects to the JTAG interface of a target device
(or devices).  One such device is the Amontec JTAGKey (see
L<http://www.amontec.com/jtagkey.shtml>).


=head2 EXPORT

None by default.

=head2 CONSTRUCTOR

=over 4

=item new()

Creates the JTAGUSB object.  This routine initializes the JTAGKey and then autodetects
the device(s) on the JTAG scan chain.  Currently only the following devices are defined,
others must be added to the idcode_lookup subroutine manually.

Currently supported devices: XC3S1000_FT256, XC3S1200E_FT256, XCF04S_V020.

The values for the IDCODE and the instruction register commands are defined in
the target device's BSDL file.  These are typically available for download
from the manufacturer's website.  For BSDL models from Xilinx, visit
L<http://www.xilinx.com/xlnx/xil_sw_updates_home.jsp#BSDL Models>.  A regular
expression is used for the device's IDCODE because a given devices IDCODE
will vary based upon package type, etc.

=back

=head2 METHODS

=over 4

=item write_dev_ir({dev => DEVICE_NUM, imn => INSTRUCTION_MNEMONIC, [end => ENDSTATE]})

Writes INSTRUCTION_MNEMONIC to JTAG instruction register of device number DEVICE_NUM of the scan chain, leaving that device in ENDSTATE 
when done.  The INSTRUCTION must be the hash key of one of the instructions defined for DEVICE.  If no ENDSTATE is supplied in the 
function call, a default of RUN_TEST_IDLE is assumed.

=item write_dev_dr({dev => DEVICE_NUM, vec => BIT::VECTOR_OBJECT, [end => ENDSTATE]})

Writes data contained in Bit::Vector object to JTAG data register of device number DEVICE_NUM of the scan chain, leaving that device 
in ENDSTATE when done. If no ENDSTATE is supplied in the function call, a default of RUN_TEST_IDLE is assumed.  The Bit::Vector object is
constructed using one of the Bit::Vector constructor methods, such as Bit::Vector->new_Hex(32, "12345678").  See Bit::Vector documenation
for more information.  The length of the Bit::Vector must match the size of the register being written in the JTAG target device.


=item read_dev_dr({dev => DEVICE, nbits => NUMBER_OF_BITS, [end => ENDSTATE]})

Reads NUMBER_OF_BITS bits from JTAG data register from device number DEVICE of the scan chain, leaving that device in ENDSTATE when done.
If no ENDSTATE is supplied in the function call, a default of RUN_TEST_IDLE is assumed.  The read data is returned as a Bit::Vector object.  One can convert the Bit::Vector object to a viewable data value using one of the 
Bit::Vector conversion methods, such as $vector->to_Hex().  See Bit::Vector documenation for more information.

=back


=head1 SEE ALSO

L<http://ftdichip.com/Projects/MPSSE/FTCJTAG.htm> FTDI Chip FTCJTAG driver page.

L<http://ftdichip.com/Products/FT2232C.htm> FTDI Chip FT2232 device page.

L<http://www.amontec.com/jtagkey.shtml> Amontec JTAGKey device page.

L<http://www.xilinx.com/bvdocs/appnotes/xapp139.pdf> Information on JTAG tap controllers.


=head1 TO DO

Add auto-assignment of IDCODE value and INSTRUCTION definitions from BSDL files.

=head1 HISTORY

=over

=item * 0.11 Nov 3, 2008
Added support for Xilinx XC3S400 and XC3S500E devices.

=item * 0.10 Aug 20, 2007
Incorporated Bit::Vector module to allow JTAG reads/writes of arbitary length.
Modified function calls to take a single hash reference parameter, thus v0.10 is not compatible with
previous FTCJTAG.pm versions.

=item * 0.06  June 19 2007
Fixed bug with writing to data register of any device not located at scan chain position 1.
Added debugging report levels 0-2.
Added auto-detection of scan chain devices with auto-assignment of name and instruction register codes.

=item * 0.05  May 27 2007
Removed Perl version requirement... trying to achieve success with PPM distribution.

=item * 0.04  May 27 2007
Changed to .tar.gz archive type... trying to achieve success with PPM distribution.

=item * 0.03  May 25 2007
Fixed prereqs in Makefile.PL... trying to achieve success with PPM distribution.

=item * 0.02  May 21 2007
Removed autoloader from FTCJTAG.pm file... trying to achieve success with PPM distribution.

=item * 0.01  May 20 2007
Original version.

=back

=head1 AUTHOR

Toby Deitrich L<http://toby.deitrich.net/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Toby Deitrich

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
