# This is the Yaesu FT-817 Command Library Module
# Written by Jordan Rubin (KJ4TLB)
# For use with the FT-817 Serial Interface
#
# $Id: FT817COMM.pm 2014-23-4 12:00:00Z JRUBIN $
#
# Copyright (C) 2014, Jordan Rubin
# jrubin@cpan.org 

package Ham::Device::FT817COMM;

use strict;
use 5.14.0;
use Digest::MD5 qw(md5);
our $VERSION = '0.9.9';

BEGIN {
	use Exporter ();
	use vars qw($OS_win $VERSION $debug $verbose $agreewithwarning $writeallow  
		%SMETER %SMETERLIN %PMETER %AGCMODES %TXPWR %OPMODES %VFOBANDS %VFOABASE %VFOBBASE 
		%HOMEBASE %MEMMODES %FMSTEP %AMSTEP %CTCSSTONES %DCSCODES %VFOMEMOPTS %RESTOREAREAS 
		%BITWATCHER %BOUNDRIES %MEMORYBASE %MEMORYOPTS %FREQRANGE %CWID @NEWMEM $output
		$vfo $bitwatch $bitcheck $txpow $toggled $writestatus $charger);

my $ft817;
my $output;

our %RESTOREAREAS = ('0055' => '00', '0057' => '00', '0058' => '00', '0059' => '45', '005B' => '86', '005C' => 'B2', 
		     '005D' => '42', '005E' => '08', '005F' => 'E5', '0060' => '19', '0061' => '32', '0062' => '48', 
		     '0063' => 'B2', '0064' => '05', '0065' => '00', '0066' => '00', '0067' => 'B2', '0068' => '32',
		     '0069' => '32', '006A' => '32', '006B' => '32', '006C' => '32', '006D' => '00', '006E' => '00',
		     '006F' => '00', '0070' => '00', '0071' => '00', '0072' => '00', '0073' => '00', '0074' => '00',
		     '0079' => '03', '007A' => '0F', '007B' => '08', '044F' => '00');

our %AGCMODES = (AUTO => '00', FAST => '01', SLOW => '10', OFF => '11');

our %MEMMODES = (LSB => '000', USB => '001', CW => '010', CWR => '011', AM => '100', 
		FM => '101', DIG => '110', PKT => '111');

our %VFOMEMOPTS =  (MODE => '1', NARFM => '2', NARCWDIG => '3', RPTOFFSET  => '4', TONEDCS => '5',
                ATT => '6', IPO => '7', FMSTEP => '8', AMSTEP => '9', SSBSTEP => '10', CTCSSTONE => '11',
		DCSCODE => '12', CLARIFIER => '13', CLAROFFSET => '14', RXFREQ => '15', RPTOFFSETFREQ  => '16');

our %MEMORYOPTS =  (MODE => '1', HFVHF => '2', TAG => '3', FREQRANGE  => '4', NARFM => '5',
                NARCWDIG => '6', UHF => '7', RPTOFFSET => '8', TONEDCS => '9', ATT => '10', IPO => '11',
                MEMSKIP => '12', FMSTEP => '13', AMSTEP => '14', SSBSTEP => '15', CTCSSTONE  => '16',
		DCSCODE => '17', CLARIFIER => '18', CLAROFFSET => '19', RXFREQ => '20', RPTOFFSETFREQ => '21',
		LABEL => '22', READY => '23');

our %FMSTEP = ('5.0' => '000', '6.25' => '001', '10.0' => '010', '12.5' => '011', '15.0' => '100',
               '20.0' => '101', '25.0' => '110', '50.0' => '111');

our %CWID = ('0' => '0', '1' => '1', '2' => '2', '3' => '3', '4' => '4', '5' => '5', '6' => '6', '7' => '7',
	     '8' => '8', '9' => '9', 'A' => 'A', 'B' => 'B', 'C' => 'C', 'D' => 'D', 'E' => 'E', 'F' => 'F',  
	     '10' => 'G', '11' => 'H', '12' => 'I', '13' => 'J', '14' => 'K', '15' => 'L', '16' => 'M', '17' => 'N',
	     '18' => 'O', '19' => 'P', '1A' => 'Q', '1B' => 'R', '1C' => 'S', '1D' => 'T', '1E' => 'U', '1F' => 'V',
	     '20' => 'W', '21' => 'X', '22' => 'Y', '23' => 'Z', '24' =>' ');

our %AMSTEP = ('2.5' => '000', '5.0' => '001', '9.0' => '010', '10.0' => '011', '12.5' => '100',
               '25.0' => '101');

our %CTCSSTONES = ('000000' => '67.0', '000001' => '69.3', '000010' => '71.9', '000011' => '74.4',
                   '000100' => '77.0', '000101' => '79.7', '000110' => '82.5', '000111' => '85.4',
                   '001000' => '88.5', '001001' => '91.5', '001010' => '94.8', '001011' => '97.4',
                   '001100' => '100.0', '001101' => '103.5', '001110' => '107.2', '001111' => '110.9', 
	           '010000' => '114.8', '010001' => '118.8', '010010' => '123.0', '010011' => '127.3',
	           '010100' => '131.8', '010101' => '136.5', '010110' => '141.3', '010111' => '146.2', 
	           '011000' => '151.4', '011001' => '156.7', '011010' => '159.8', '011011' => '162.2', 
                   '011100' => '165.5', '011101' => '167.9', '011110' => '171.3', '011111' => '173.8',
	           '100000' => '177.3', '100001' => '179.9', '100010' => '183.5', '100011' => '186.2',
                   '100100' => '189.6', '100101' => '192.8', '100110' => '196.6', '100111' => '199.5',
                   '101000' => '203.5', '101001' => '206.5', '101010' => '210.7', '101011' => '218.1',
                   '101100' => '225.7', '101101' => '229.1', '101110' => '233.6', '101111' => '241.8',
                   '110000' => '250.3', '110001' => '254.1');

our %DCSCODES =   ('0000000' => '023', '0000001' => '025', '0000010' => '026', '0000011' => '031',
                   '0000100' => '032', '0000101' => '036', '0000110' => '043', '0000111' => '047',
                   '0001000' => '051', '0001001' => '053', '0001010' => '054', '0001011' => '065',
                   '0001100' => '071', '0001101' => '072', '0001110' => '073', '0001111' => '074',
                   '0010000' => '114', '0010001' => '115', '0010010' => '116', '0010011' => '122',
                   '0010100' => '125', '0010101' => '131', '0010110' => '132', '0010111' => '134',
                   '0011000' => '143', '0011001' => '145', '0011010' => '152', '0011011' => '155',
                   '0011100' => '156', '0011101' => '162', '0011110' => '165', '0011111' => '172',
                   '0100000' => '174', '0100001' => '205', '0100010' => '212', '0100011' => '223',
                   '0100100' => '225', '0100101' => '226', '0100110' => '243', '0100111' => '244',
                   '0101000' => '245', '0101001' => '246', '0101010' => '251', '0101011' => '252',
                   '0101100' => '255', '0101101' => '261', '0101110' => '263', '0101111' => '265',
                   '0110000' => '266', '0110001' => '271', '0110010' => '274', '0110011' => '306',
		   '0110100' => '311', '0110101' => '315', '0110110' => '325', '0110111' => '331',
		   '0111000' => '332', '0111001' => '343', '0111010' => '346', '0111011' => '351',
		   '0111100' => '356', '0111101' => '364', '0111110' => '365', '0111111' => '371',
		   '1000000' => '411', '1000001' => '412', '1000010' => '413', '1000011' => '423',
		   '1000100' => '431', '1000101' => '432', '1000110' => '445', '1000111' => '446',
		   '1001000' => '452', '1001001' => '454', '1001010' => '455', '1001011' => '462',
		   '1001100' => '464', '1001101' => '465', '1001110' => '466', '1001111' => '503',
		   '1010000' => '506', '1010001' => '516', '1010010' => '523', '1010011' => '526',
		   '1010100' => '532', '1010101' => '546', '1010110' => '565', '1010111' => '606',
		   '1011000' => '612', '1011001' => '624', '1011010' => '627', '1011011' => '631',
		   '1011100' => '632', '1011101' => '654', '1011110' => '662', '1011111' => '664',
		   '1100000' => '703', '1100001' => '712', '1100010' => '723', '1100011' => '731',
		   '1100100' => '732', '1100101' => '734', '1100110' => '743', '1100111' => '754');

# Convention is ..... BYTE [76543210] 
#
# BIT 7 -> 0 , 6 -> 1, 5 -> 2, 4 -> 3, 3 -> 4, 2 -> 5, 1 -> 6, 0 -> 7 
#
# USE ALL => 76543210 for whole BYTE
#
# 'address' =>   {
#                     'bit' => 'value'
#                } 
our %BITWATCHER = (
    '0006' =>   {'ALL' => '10100101'},
    '0055' =>   {'4' => '0','1' => '0'},
    '0055' =>   {'4' => '0'},
    '0056' =>   {'ALL' => '10000010'},
    '0057' =>   {'4' => '0'},
    '0058' =>   {'4' => '0'},
    '005A' =>   {'ALL' => '01110001'},
    '005B' =>   {'2' => '0'},
    '0061' =>   {'0' => '0'},
    '0065' =>   {'4' => '0'},
    '0066' =>   {'2' => '0'},
    '0069' =>   {'0' => '0'},
    '006A' =>   {'0' => '0'},
    '006C' =>   {'0' => '0'},
    '0075' =>   {'0' => '0','1' => '0'},
    '0076' =>   {'0' => '0','1' => '0','2' => '0','3' => '0'},
    '0077' =>   {'ALL' => '00000000'},
    '0078' =>   {'ALL' => '00000000'},
    '0079' =>   {'5' => '0'},
    '007A' =>   {'1' => '0'},
    '007B' =>   {'0' => '0','1' => '0','2' => '0'},

    '017A' =>   {'ALL' => '01001000'},
    '017B' =>   {'ALL' => '00101101'},
    '017C' =>   {'ALL' => '00110000'},
    '017D' =>   {'ALL' => '00110000'},
    '017E' =>   {'ALL' => '00110010'},
    '017F' =>   {'ALL' => '00100000'},
    '0180' =>   {'ALL' => '00100000'},

    '03B5' =>   {'ALL' => '00110011'},
    '03B6' =>   {'ALL' => '00110011'},
    '03B7' =>   {'ALL' => '00110011'},
    '03B8' =>   {'ALL' => '00100000'},
    '03B9' =>   {'ALL' => '00100000'},
    '03BA' =>   {'ALL' => '00100000'},
    '03BB' =>   {'ALL' => '00100000'},
    '03BC' =>   {'ALL' => '00100000'},

    '03CF' =>   {'ALL' => '01001000'},
    '03D0' =>   {'ALL' => '01001111'},
    '03D1' =>   {'ALL' => '01001101'},
    '03D2' =>   {'ALL' => '01000101'},
    '03D3' =>   {'ALL' => '00101101'},
    '03D4' =>   {'ALL' => '00110010'},
    '03D5' =>   {'ALL' => '01001101'},
    '03D6' =>   {'ALL' => '00100000'},

    '0437' =>   {'ALL' => '11111111'},
    '0438' =>   {'ALL' => '11111111'},
    '0439' =>   {'ALL' => '11111111'},
    '043A' =>   {'ALL' => '11111111'},
    '043B' =>   {'ALL' => '11111111'},
    '043C' =>   {'ALL' => '11111111'},
    '043D' =>   {'ALL' => '11111111'},
    '043E' =>   {'ALL' => '11111111'},
    '043F' =>   {'ALL' => '00000000'},
    '0440' =>   {'ALL' => '00000010'},
    '0441' =>   {'ALL' => '10111111'},
    '0442' =>   {'ALL' => '00100000'},
    '0443' =>   {'ALL' => '00000000'},
    '0444' =>   {'ALL' => '00000011'},
    '0445' =>   {'ALL' => '00001101'},
    '0446' =>   {'ALL' => '01000000'},
    '0447' =>   {'ALL' => '00000000'},
    '0448' =>   {'ALL' => '01001100'},
    '0449' =>   {'ALL' => '01001011'},
    '044A' =>   {'ALL' => '01000000'},
    '044B' =>   {'ALL' => '00000000'},
    '044C' =>   {'ALL' => '01010010'},
    '044D' =>   {'ALL' => '01100101'},
    '044E' =>   {'ALL' => '11000000'},

    '046B' =>   {'ALL' => '00000000'},
    '046C' =>   {'ALL' => '00000000'},
    '046D' =>   {'ALL' => '00000000'},
    '046E' =>   {'ALL' => '00000000'},
    '046F' =>   {'ALL' => '00000000'},
    '0470' =>   {'ALL' => '00000000'},
    '0471' =>   {'ALL' => '00000000'},
    '0472' =>   {'ALL' => '00000000'},
    '0473' =>   {'ALL' => '00000000'},
    '0474' =>   {'ALL' => '00000000'},
    '0475' =>   {'ALL' => '00000000'},
    '0476' =>   {'ALL' => '00000000'},
    '0477' =>   {'ALL' => '00000000'},
    '0478' =>   {'ALL' => '00000000'},
    '0479' =>   {'ALL' => '00000000'},
    '047A' =>   {'ALL' => '00000000'},
    '047B' =>   {'ALL' => '00000000'},
    '047C' =>   {'ALL' => '00000000'},
    '047D' =>   {'ALL' => '00000000'},
    '047E' =>   {'ALL' => '00000000'},
    '047F' =>   {'ALL' => '00000000'},
    '0480' =>   {'ALL' => '00000000'},
    '0481' =>   {'ALL' => '00000000'},
    '0482' =>   {'ALL' => '10000000'},
    '0483' =>   {'ALL' => '00000000'},

    '1908' =>   {'ALL' => '01100001'},
    '1909' =>   {'ALL' => '00000000'},
    '190A' =>   {'ALL' => '00000000'},    
    '190B' =>   {'ALL' => '01001000'},
    '190C' =>   {'ALL' => '00000000'},
    '190D' =>   {'ALL' => '00000000'},
    '190E' =>   {'ALL' => '00001000'},
    '190F' =>   {'ALL' => '00000000'},
    '1910' =>   {'ALL' => '00000000'},
    '1911' =>   {'ALL' => '00000000'},
    '1912' =>   {'ALL' => '00000000'},
    '1913' =>   {'ALL' => '00000111'},
    '1914' =>   {'ALL' => '11100010'},
    '1915' =>   {'ALL' => '10001110'},
    '1916' =>   {'ALL' => '00000000'},
    '1917' =>   {'ALL' => '00000000'},
    '1918' =>   {'ALL' => '00100111'},
    '1919' =>   {'ALL' => '00010000'},
    '191A' =>   {'ALL' => '11111111'},
    '191B' =>   {'ALL' => '11111111'},
    '191C' =>   {'ALL' => '11111111'},
    '191D' =>   {'ALL' => '11111111'},
    '191E' =>   {'ALL' => '11111111'},
    '191F' =>   {'ALL' => '11111111'},
    '1920' =>   {'ALL' => '11111111'},
    '1921' =>   {'ALL' => '11111111'},
	      );

our %BOUNDRIES = (
    '160M'  =>   {'LOW' => '1.800.00',  'HIGH' => '2.000.00'},
    '80M'   =>   {'LOW' => '3.500.00',  'HIGH' => '4.000.00'},
    '60M'   =>   {'LOW' => '5.330.50',  'HIGH' => '5.403.50'},	
    '40M'   =>   {'LOW' => '7.000.00',  'HIGH' => '7.300.00'},
    '30M'   =>   {'LOW' => '10.100.00', 'HIGH' => '10.150.00'},
    '20M'   =>   {'LOW' => '14.000.00', 'HIGH' => '14.350.00'},
    '15M'   =>   {'LOW' => '21.000.00', 'HIGH' => '21.450.00'},
    '12M'   =>   {'LOW' => '24.890.00', 'HIGH' => '24.990.00'},
    '10M'   =>   {'LOW' => '28.000.00', 'HIGH' => '29.700.00'},
    '6M'    =>   {'LOW' => '50.000.00', 'HIGH' => '54.000.00'},
    'FMBC'  =>   {'LOW' => '76.000.00', 'HIGH' => '107.999.99'},
    'AIR'   =>   {'LOW' => '108.000.00','HIGH' => '137.000.00'},
    '2M'    =>   {'LOW' => '137.000.00','HIGH' => '154.000.00'},
    '70CM'  =>   {'LOW' => '420.000.00','HIGH' => '450.000.00'},
    'UHF'  =>    {'LOW' => '420.000.00','HIGH' => '450.000.00'},
    'PHAN'  =>   {'LOW' => '1.000.00'  ,'HIGH' => '477.000.00'},
    'MTQMB' =>   {'LOW' => '1.000.00'  ,'HIGH' => '477.000.00'}
	         );

our %FREQRANGE = (
    'HF'   => {'LOW' => '180000',  'HIGH' => '4999999'},
    '6M'   => {'LOW' => '5000000', 'HIGH' => '5400000'},
    'FMBC' => {'LOW' => '7600000', 'HIGH' => '10799999'},
    'AIR'  => {'LOW' => '10800000','HIGH' => '13700000'},
    '2M'   => {'LOW' => '13700000','HIGH' => '15400000'},
    'UHF'  => {'LOW' => '42000000','HIGH' => '45000000'}
		 );

our %TXPWR = (HIGH => '00', LOW3 => '01', LOW2 => '10', LOW1 => '11');

our @NEWMEM = ('A0','0','3F','48','FF','FF','CD','82','0','0','0','A','AE','60','FF','0','0','0');

our %VFOBANDS = ('160M' => '0000', '75M' => '0001', '40M' => '0010', '30M' => '0011',
             '20M' => '0100', '17M' => '0101', '15M' => '0110', '12M' => '0111',
             '10M' => '1000', '6M' => '1001', 'FMBC' => '1010', 'AIR' => '1011',
             '2M' => '1100', '70CM' => '1101', 'PHAN' => '1110');

our %VFOABASE = ('160M' => '007D', '80M' => '0097', '40M' => '00B1', '30M' => '00CB',
             '20M' => '00E5', '17M' => '00FF', '15M' => '0119', '12M' => '0133',
             '10M' => '014D', '6M' => '0167', 'FMBC' => '0181', 'AIR' => '019B',
             '2M' => '01B5', '70CM' => '01CF', 'PHAN' => '01E9', 'MTQMB' => '040B', 'MTUNE' => '0425');

our %VFOBBASE = ('160M' => '0203', '80M' => '021D', '40M' => '0237', '30M' => '0251',
             '20M' => '026B', '17M' => '0285', '15M' => '029F', '12M' => '02B9',
             '10M' => '02D3', '6M' => '02ED', 'FMBC' => '0307', 'AIR' => '0321',
             '2M' => '033B', '70CM' => '0355', 'PHAN' => '036F');

our %HOMEBASE = ('HF' => '0389', '6M' => '03A3', '2M' => '03BD', 'UHF' => '03D7');

our %MEMORYBASE = ('QMB' => '03F1', 'MEM' => '0484');

our %OPMODES =  (LSB => '00', USB => '01', CW => '02',
             CWR => '03', AM => '04', FM => '08',
             DIG => '0A', PKT => '0C', FMN => '88',
             WFM => '06');

our %SMETER = ('S0' => '0000', 'S1' => '0001', 'S2' => '0010', 'S3' => '0011',
             'S4' => '0100', 'S5' => '0101', 'S6' => '0110', 'S7' => '0111',
             'S8' => '1000', 'S9' => '1001', '10+' => '1010', '20+' => '1011',
             '30+' => '1100', '40+' => '1101', '50+' => '1110', '60+' => '1111');

our %SMETERLIN = ('0' => '0000', '1' => '0001', '2' => '0010', '3' => '0011',
             '4' => '0100', '5' => '0101', '6' => '0110', '7' => '0111',
             '8' => '1000', '9' => '1001', '10' => '1010', '11' => '1011',
             '12' => '1100', '13' => '1101', '14' => '1110', '15' => '1111');

our %PMETER = ('0' => '0000', '1' => '0001', '2' => '0010', '3' => '0011',
             '4' => '0100', '5' => '0101', '6' => '0110', '7' => '0111',
             '8' => '1000', '9' => '1001', '10' => '1010', '11' => '1011',
             '12' => '1100', '13' => '1101', '14' => '1110', '15' => '1111');


	$OS_win = ($^O eq "MSWin32") ? 1 : 0;
	if ($OS_win) {
		eval "use Win32::SerialPort";
		die "$@\n" if ($@);
     		     }
	else {
		eval "use Device::SerialPort";
		die "$@\n" if ($@);
             } 
    
}#END BEGIN

sub new {
	my($device,%options) = @_;
	my $ob = bless \%options, $device;
	if ($OS_win) {
		$ob->{'port'} = Win32::SerialPort->new ($options{'serialport'});
		if($verbose){print "WIN32 DETECTED\n";}
          	     }
	else {
		$ob->{'port'} = Device::SerialPort->new ($options{'serialport'},'true',$options{'lockfile'});
		if($verbose){print "POSIX DETECTED\n";}
  	     }
	die "Can't open serial port $options{'serialport'}: $^E\n" unless (ref $ob->{'port'});
	$ob->{'port'}->baudrate(9600) unless ($options{'baud'});
	$ob->{'port'}->databits (8);
	$ob->{'port'}->baudrate ($options{'baud'});
	$ob->{'port'}->parity  ("none");
	$ob->{'port'}->stopbits (2);
	$ob->{'port'}->handshake("none");
	$ob->{'port'}->read_char_time(0);
	$ob->{'port'}->read_const_time(1000);
        $ob->{'port'}->alias ($options{'name'});
return $ob;
	}

#### Closes the port and deconstructs method

sub moduleVersion {
        my $self = shift;
return $VERSION;
                  }

sub closePort {
	my $self  = shift;
	die "\nCan't close the port $self->{'serialport'}....\n" unless $self->{'port'}->close;
	warn "\nPort $self->{'serialport'} has been closed.\n\n";
undef $self;
              }

#### sets debugflag if a value exists
sub setDebug {
	my $self = shift;
	my $debugflag = shift;
	if($debugflag == '1') {our $debug = $debugflag;}
	if($debugflag == '0') {our $debug = undef;}
	if($debug && $verbose){print "DEBUGGER IS ON\n";}
        if(!$debug && $verbose){print "DEBUGGER IS OFF\n";}
return $debug;
             }

#### sets bitwatcherflag if a value exists
sub setBitwatch {
        my $self = shift;
        my $bitwatcherflag = shift;
        if($bitwatcherflag == '1') {our $bitwatch = $bitwatcherflag;}
        if($bitwatcherflag == '0') {our $bitwatch = undef;}
        if($bitwatch && $verbose){print "BIT WATCH IS ON\n";}
        if(!$bitwatch && $verbose){print "BIT WATCH IS OFF\n";}
return $bitwatch;
                }

#### sets output of a set command
sub setVerbose {
	my $self = shift;
	my $verboseflag = shift;
	if($verboseflag == '1') {our $verbose = $verboseflag;}
	if($verboseflag == '0') {$verbose = undef;}
return $verbose;
               }

#### sets output of a set command
sub setWriteallow {
        my $self = shift;
        my $writeflag = shift;
        if($writeflag == '1') {our $writeallow = $writeflag;}
        if($writeflag == '0') {our $writeallow = undef;}
if ($writeallow && $verbose){print "WRITING TO EEPROM ACTIVATED\n";}
if (!$writeallow && $verbose){print "WRITING TO EEPROM DEACTIVATED\n";}
if (!$agreewithwarning && $writeallow && $verbose){print "
\n*****NOTICE****** *****NOTICE****** *****NOTICE****** *****NOTICE****** *****NOTICE******
\nYou have enabled the option setWriteallow!!!!\n 
\tWhile the program does its best to ensure that data does not get corrupted, there is always 
the chance that an error can be written to or received by the radio.  This radio has no checksum
feature with regard to writing to the EEprom. The user of this program assumes all risk associated
with using this software.\n
\tIt is recommended that the software calibration settings be backed up to your computer in the event
that the radio needs to be reset to factory default.  You should have done this anyway, to avoid
sending the radio back to Yaesu to be recalibrated. FT817OS will automatically provide a calibration
file on first startup.  You can also, within this library create a backup of the calibration using

\$FT817->getSoftcal\(\"file\",\"filename\.txt\"\)\;

You can also use software such as \'FT-817 commander\' to backup your software calibration. 
Check the site http://wb8nut.com/downloads/ or google it.  The program is for windows but 
functions fine on Ubuntu linux and other possible variants under wine.\n

Have a look at restoreEeprom\(\) in the documentation to see how to set a memory address back to
default in the event of a problem. 

\tHaving said that, If you accept this risk and have backed up your software calibration, you
can use the following command agreewithwarning(1) before the command setWriteallow(1) in your 
software to get rid of this message and have the ability to write to the eeprom.
";					}
	  
		 }
#### sets output of a set command
sub agreeWithwarning {
        my $self = shift;
        my $agreeflag = shift;
        if($agreeflag == '1') {our $agreewithwarning = $agreeflag;}
return $agreewithwarning;
                     }

sub getFlags {
        my $self = shift;
	my $value = shift;
	my $flags;
	if ($value eq 'DEBUG'){$flags = "$debug";}
        if ($value eq 'VERBOSE'){$flags = "$verbose";}
        if ($value eq 'BITWATCH'){$flags = "$bitwatch";}
        if ($value eq 'WRITEALLOW'){$flags = "$writeallow";}
	if ($value eq 'WARNED'){$flags = "$agreewithwarning";}
	if (!$value){$flags = "DEBUG\:$debug \/ VERBOSE\:$verbose \/ WRITE ALLOW:$writeallow \/ \/ BITWATCH:$bitwatch \/ WARNED\:$agreewithwarning";}
        if($verbose){
                printf "\n%-11s %-11s\n", 'FLAG','VALUE';
                print "_________________";
                printf "\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n\n", 'DEBUG', "$debug", 'VERBOSE', "$verbose", 'BITWATCH', "$bitwatch", 'WRITE', "$writeallow", 'WARNED', "$agreewithwarning";
                    }
return $flags;
             }
#### Convert a decimal to a binary
sub dec2bin {
	my $str = unpack("B32", pack("N", shift));
	$str = substr $str, -8;
return $str;
            }

#### Convert Hex to a binary
sub hex2bin {
	my $h = shift;
	my $hlen = length($h);
	my $blen = $hlen * 4;
return unpack("B$blen", pack("H$hlen", $h));
            }

#### Add a HEX VALUE AND RETURN MSB/LSB
sub hexAdder {
        my $self  = shift;
        my $offset = shift;
	my $base = shift;
        if ($debug){print "\n(hexAdder:DEBUG) - RECEIVED BASE [$base] AND OFFSET [$offset]\n";}
        my $basehex = join("",'0x',"$base");
        if ($debug){print "\n(hexAdder:DEBUG) - CONVERT  BASE [$basehex]\n";}
        $basehex = hex($basehex);
        if ($debug){print "\n(hexAdder:DEBUG) - OCT   BASEHEX [$basehex]\n";}
        my $startaddress = sprintf("0%X",$basehex + $offset);
        if(length($startaddress) < 4) {
                if ($debug){print "\n(hexAdder:DEBUG) - TOO SMALL, ADDING LEADING 0 ---> [$startaddress]\n";}
		$startaddress = join("",'0',"$startaddress");
	        if ($debug){print "\n(hexAdder:DEBUG) - PADDING WITH 0 ---> [$startaddress]\n";}
				      }
	 if(length($startaddress) == 5) {
                if ($debug){print "\n(hexAdder:DEBUG) - TOO BIG, DROPPING LEADING 0 ---> [$startaddress]\n";}
		$startaddress = substr("$startaddress",'1','4');
                if ($debug){print "\n(hexAdder:DEBUG) - DROPPED LEADING 0 ---> [$startaddress]\n";}
					}
        if ($debug){print "\n(hexAdder:DEBUG) - ADDED OFFSET [$startaddress]\n";}
        if ($debug){print "\n(hexAdder:DEBUG) - PRODUCED [$startaddress]\n\n";}
return $startaddress;
	     }

sub hexDiff {
        my $self  = shift;
        my $ADDRESS1 = shift;
	my $ADDRESS2 = shift;
        if ($debug){print "\n(hexDiff:DEBUG) - RECEIVED HEX1 [$ADDRESS1] AND HEX2 [$ADDRESS2]\n";}
        if ($debug){print "\n(hexDiff:DEBUG) - COMPUTING DECIMAL DIFFERENCE\n";}
        $ADDRESS1 = hex($ADDRESS1);
	$ADDRESS2 = hex($ADDRESS2);
	my $difference = $ADDRESS2 - $ADDRESS1;
        if ($debug){print "\n(hexDiff:DEBUG) - GOT $difference\n\n";}
return $difference;
             }

#### Does a toggle with no output
sub quietToggle{
        my $self  = shift;
        $self->setVerbose(0);
        $self->catvfoToggle();
        $self->setVerbose(1);
return 0;
               }

#### Does a toggle between MEMORY and VFO with no output
sub quietTunetoggle{
        my $self  = shift;
        $self->setVerbose(0);
        my $tuner = $self->getTuner();
        $self->setVerbose(0);
        if($tuner eq 'MEMORY'){$writestatus = $self->writeEeprom('0055','1','0');}
        if($tuner eq 'VFO'){$writestatus = $self->writeEeprom('0055','1','1');}
        $self->setVerbose(1);
return 0;
                   }

#### Does a toggle between MEMORY and VFO with no output
sub quietHometoggle{
        my $self  = shift;
        $self->setVerbose(0);
        my $tuner = $self->getHome();
        $self->setVerbose(0);
        if($tuner eq 'Y'){$writestatus = $self->writeEeprom('0055','3','0');}
        if($tuner eq 'N'){$writestatus = $self->writeEeprom('0055','3','1');}
        $self->setVerbose(1);
return 0;
                   }

#### Function for checking boundries
sub boundryCheck {
        my $self  = shift;
        my $band  = shift;
        my $frequency  = shift;
	my $freqlabel = $frequency;
        $frequency =~ tr/.//d;
        my $status = 'OK';
        my $low = $BOUNDRIES{$band}{'LOW'};
        my $high = $BOUNDRIES{$band}{'HIGH'};
        my $lowlabel = $low;
        my $highlabel = $high;
        $low =~ tr/.//d;
        $high =~ tr/.//d;
        if ($frequency < $low || $frequency > $high){
                if($verbose){print "Frequency $freqlabel out of range for $band [$lowlabel \- $highlabel]\n\n"; }
return 1;
                                                    }
return $status;
		 }

#### Function for checking what range frequency is in
sub rangeCheck {
        my $self  = shift;
        my $frequency  = shift;
        $frequency =~ tr/.//d;
        foreach my $key ( keys %FREQRANGE)  {
        my $low = $FREQRANGE{"$key"}{'LOW'};
        my $high = $FREQRANGE{"$key"}{'HIGH'};
        if ($frequency >= $low && $frequency <= $high){
                if($verbose){print "RANGE is $key\n\n";}
return $key;					    
						      }
					    }
        if($verbose){print "NOT FOUND!!! ERROR!!\n\n";}
return 1;
	      }

#### Function for checking the BITWATCHER hash
sub bitCheck {
        my $self  = shift;
        my $lastaction = shift;
	my $bit;
	my $testbit;
	my $status = 'OK';
	foreach my $key ( sort keys %BITWATCHER)  {
		if ($debug){print "\n(bitCheck:DEBUG) - Monitors in address $key are: \n";}
		my $memarea = $self->eepromDecode("$key");
		foreach $bit (sort keys $BITWATCHER{$key}) {
			if ($bit ne 'ALL') {$testbit = substr($memarea,"$bit",1);}
			else {$testbit = $memarea;}
			my $value = $BITWATCHER{$key}{$bit};
                        if ($debug){print "(bitCheck:DEBUG) - $key: \[$memarea\]\n\n";}
			if ($debug){print "(bitCheck:DEBUG) - AREA: $key BIT: $bit ---> VALUE: $value TESTBIT: $testbit\n\n";}
			if ($value != $testbit){
				if ($verbose){print "CHANGE FOUND IN MEMORY AREA [$key]: BIT $bit is $testbit, WAS $value\n";}			
                                if ($verbose && $value){print "LAST MODIFICATION WAS [$lastaction]\n";}
		                $status = 'CHANGE';
				               }
                                                     }
                                           }
                if ($verbose && $status eq 'CHANGE'){print "\n";}
	if ($status eq 'OK'){if ($debug){print "(bitCheck:DEBUG) - NO CHANGES FOUND\n";}}
return $status;
	     }

#### Send a CAT command and set the return byte size
sub sendCat {
	my $self  = shift;
	my $caller = ( caller(1) )[3];
	my ($data1, $data2, $data3, $data4, $command, $outputsize) = @_;
	if ($debug){print "\n(sendCat:DEBUG) - DATA OUT ------> $data1 $data2 $data3 $data4 $command\n";}
	my $data = join("","$data1","$data2","$data3","$data4","$command");
	our $lastaction = "sendCat: $data from $caller";
	if ($debug){print "\n(sendCat:DEBUG) - BUILT PACKET --> $data\n";}
	$data = pack( 'H[10]', "$data" );
	$self->{'port'}->write($data);
	$output = $self->{'port'}->read($outputsize);
	$output = unpack("H*", $output);
	if ($debug) {print "\n(sendCat:DEBUG) - DATA IN <------- $output\n\n";}
	if ($bitwatch){$self->bitCheck("$lastaction");}
return $output;
            }

#### Decodes eeprom values from a given address and stips off second byte
sub eepromDecode {
	my $self  = shift;
	my $address = shift;
	if ($debug){print "\n(eepromDecode:DEBUG) - READING FROM ------> [$address]\n";}
        my $data = join("","$address",'0000BB');
        if ($debug){print "\n(eepromDecode:DEBUG) - PACKET BUILT ------> [$data]\n";}
	$data = pack( 'H[10]', "$data" );
	$self->{'port'}->write($data);
	$output = $self->{'port'}->read(2);
        my $test = $output;
	$output = unpack("H*", substr($output,0,1));
        my $output2 = unpack("H*", substr($test,1,1));
        if ($debug){print "\n(eepromDecode:DEBUG) - OUTPUT HEX  -------> [$output]\n";}
        if ($debug){print "\n(eepromDecode:DEBUG) - NEXTBYTE HEX  -----> [$output2]\n";}
	$output = hex2bin($output);
        $output2 = hex2bin($output2);
        if ($debug){print "\n(eepromDecode:DEBUG) - OUTPUT BIN  -------> [$output]\n";}
        if ($debug){print "\n(eepromDecode:DEBUG) - NEXTBYTE BIN ------> [$output2]\n\n";}
return $output;
                 }

#### Decodes eeprom values from a given address and stips off second byte
sub eepromDoubledecode {
        my $self  = shift;
        my $address = shift;
        if ($debug){print "\n(eepromDecode:DEBUG) - READING FROM ------> [$address]\n";}
        my $data = join("","$address",'0000BB');
        if ($debug){print "\n(eepromDecode:DEBUG) - PACKET BUILT ------> [$data]\n";}
        $data = pack( 'H[10]', "$data" );
        $self->{'port'}->write($data);
        $output = $self->{'port'}->read(2);
        my $test = $output;
        $output = unpack("H*", substr($output,0,1));
        my $output2 = unpack("H*", substr($test,1,1));
        if ($debug){print "\n(eepromDecode:DEBUG) - OUTPUT HEX  -------> [$output]\n";}
        if ($debug){print "\n(eepromDecode:DEBUG) - NEXTBYTE HEX  -----> [$output2]\n";}
        $output = hex2bin($output);
        $output2 = hex2bin($output2);
        if ($debug){print "\n(eepromDecode:DEBUG) - OUTPUT BIN  -------> [$output]\n";}
        if ($debug){print "\n(eepromDecode:DEBUG) - NEXTBYTE BIN ------> [$output2]\n\n";}
return ("$output","$output2");
                 }

#### Decodes eeprom values from a given address and stips off second byte
sub eepromDecodenext {
        my $self  = shift;
	my $address = shift;
        if ($debug){print "\n(eepromDecodenext:DEBUG) - READING FROM from -> [$address]\n";}
        my $data = join("","$address",'0000BB');
	if ($debug){print "\n(eepromDecodenext:DEBUG) - PACKET BUILT ------> [$data]\n";}
	$data = pack( 'H[10]', "$data" );
	$self->{'port'}->write($data);
        $output = $self->{'port'}->read(2);
        $output = unpack("H*", substr($output,1,1));
	if ($debug){print "\n(eepromDecodenext:DEBUG) - OUTPUT HEX --------> [$output]\n\n";}
return $output;
                     }

#### Writes data to the eeprom MSB,LSB,BIT# and VALUE,  REWRITES NEXT MEMORY ADDRESS
sub writeEeprom {
        my $self=shift;
        my $address = shift;
	my ($writestatus) = @_;
	my $BIT=shift;
	my $VALUE=shift;
        my $caller = ( caller(1) )[3];
	my $NEWHEX1;
	my $NEWHEX2;
	if ($writeallow != '1' and $agreewithwarning != '1') {
		if($debug || $verbose){print"Writing to EEPROM disabled, use setWriteallow(1) to enable\n";}
		$writestatus = "Write Disabled";
return $writestatus;
			  }
	if ($debug){print "\n(writeEeprom:DEBUG) - OUTPUT FROM [$address]\n";}
        my $data = join("","$address",'0000BB');
        if ($debug){print "\n(writeEeprom:DEBUG) - PACKET BUILT ------> [$data]\n";}
        $data = pack( 'H[10]', "$data" );
        $self->{'port'}->write($data);
	my $output = $self->{'port'}->read(2);
	my $BYTE1 = unpack("H*", substr($output,0,1));
	my $BYTE2 = unpack("H*", substr($output,1,1));
	my $OLDBYTE1 = $BYTE1;
	my $OLDBYTE2 = $BYTE2;
	if ($debug){print "\n(writeEeprom:DEBUG) - BYTE1 ($BYTE1) BYTE2 ($BYTE2) from [$address]\n";}
	$BYTE1 = hex2bin($BYTE1);
	my $HEX1 = sprintf("%X", oct( "0b$BYTE1" ) );
	if ($debug){print "\n(writeEeprom:DEBUG) - BYTE1 BINARY IS [$BYTE1]\n";}
	if ($debug){print "\n(writeEeprom:DEBUG) - CHANGING BIT($BIT) to ($VALUE)\n";}
	substr($BYTE1, $BIT, 1) = "$VALUE";
	if ($debug){print "\n(writeEeprom:DEBUG) - BYTE1: BINARY IS [$BYTE1] AFTER CHANGE\n";}
	$NEWHEX1 = sprintf("%X", oct( "0b$BYTE1" ) );
        if ($debug){print "\n(writeEeprom:DEBUG) - CHECKING IF [$NEWHEX1] needs padding\n";}
        if (length($NEWHEX1) < 2) {
                   $NEWHEX1 = join("",'0', "$NEWHEX1");
                if ($debug){print "\n(writeEeprom:DEBUG) - Padded to [$NEWHEX1]\n";}
                                }
        else {if ($debug){print "\n(writeEeprom:DEBUG) - No padding of [$NEWHEX1] needed\n";}}
	if ($debug){print "\n(writeEeprom:DEBUG) - BYTE1 ($NEWHEX1) BYTE2 ($BYTE2) to [$address]\n";}
	if ($debug){print "\n(writeEeprom:DEBUG) - WRITING  ----------> ($NEWHEX1) ($BYTE2)\n";}
        my $data2 = join("","$address","$NEWHEX1","$BYTE2",'BC');
        our $lastaction = "writeEeprom: $data2 from $caller";
	if ($debug){print "\n(writeEeprom:DEBUG) - PACKET BUILT ------> [$data2]\n";}
	$data2 = pack( 'H[10]', "$data2" );
        $self->{'port'}->write($data2);
        $output = $self->{'port'}->read(2);
	if ($debug){print "\n(writeEeprom:DEBUG) - VALUES WRITTEN, CHECKING...\n";}
        $self->{'port'}->write($data);
        my $output2 = $self->{'port'}->read(2);
        $BYTE1 = unpack("H*", substr($output2,0,1));
        $BYTE2 = unpack("H*", substr($output2,1,1));
        if ($debug){print "\n(writeEeprom:DEBUG) - SHOULD BE: ($NEWHEX1) ($OLDBYTE2)\n";}
        if ($debug){print "\n(writeEeprom:DEBUG) - IS: -----> ($BYTE1) ($BYTE2)\n";}

# We make an exception for setTuner because 0056 bit 0 changes automatically when MEM/VFO is toggled

                if ($address == '0055' && $BIT == '1'){
                	if($debug){print "\n(writeEeprom:DEBUG) - TUNER EXEMPTION OK\n\n";}
			$writestatus = 'OK';
						      }
		else {
        if (($NEWHEX1 == $BYTE1) && ($OLDBYTE2 == $BYTE2)) {
		$writestatus = "OK";
		if($debug){print "\n(writeEeprom:DEBUG) - VALUES MATCH!!!\n\n";}
		          }
        else {
		$writestatus = "1";
		if($debug){print "\n(writeEeprom:DEBUG) - NO MATCH!!!\n\n";}
			  }
        if ($bitwatch){$self->bitCheck("$lastaction");}
                     }
return $writestatus;
               }

#### Writes an entire byte of data to the eeprom, MSB LSB VALUE
sub writeBlock {
        my $self=shift;
        my ($writestatus) = @_;
	my $address=shift;
        my $VALUE=shift;
        my $caller = ( caller(1) )[3];
        if ($writeallow != '1' and $agreewithwarning != '1') {
                if($debug || $verbose){print"Writing to EEPROM disabled, use setWriteallow(1) to enable\n";}
                $writestatus = "Write Disabled";
return $writestatus;
				                             }

if ($debug){print "\n(writeBlock:DEBUG) - OUTPUT FROM [$address]\n";}
        my $data = join("","$address",'0000BB');
        if ($debug){print "\n(writeBlock:DEBUG) - PACKET BUILT ------> [$data]\n";}
        $data = pack( 'H[10]', "$data" );
        $self->{'port'}->write($data);
        my $output = $self->{'port'}->read(2);
        my $BYTE2 = unpack("H*", substr($output,1,1));
        my $OLDBYTE2 = $BYTE2;
        if ($debug){print "\n(writeBlock:DEBUG) - BYTE2 ($BYTE2) from [$address]\n";}
        if ($debug){print "\n(writeBlock:DEBUG) - BYTE1 ($VALUE) BYTE2 ($BYTE2) to   [$address]\n";}
	if ($debug){print "\n(writeBlock:DEBUG) - CHECKING IF [$VALUE] needs padding\n";}
	if (length($VALUE) < 2) {
		   $VALUE = join("",'0', "$VALUE");
		if ($debug){print "\n(writeBlock:DEBUG) - Padded to [$VALUE]\n";}
			        }
	else {if ($debug){print "\n(writeBlock:DEBUG) - No padding of [$VALUE] needed\n";}}
        if ($debug){print "\n(writeBlock:DEBUG) - WRITING  ----------> [$VALUE] [$BYTE2]\n";}
        my $data2 = join("","$address","$VALUE","$BYTE2",'BC');
        if ($debug){print "\n(writeBlock:DEBUG) - PACKET BUILT ------> [$data2]\n";}
        our $lastaction = "writeBlock: $data2 from $caller";
        $data2 = pack( 'H[10]', "$data2" );
        $self->{'port'}->write($data2);
	$output = $self->{'port'}->read(2);
        if ($debug){print "\n(writeBlock:DEBUG) - VALUES WRITTEN, CHECKING...\n";}
        $self->{'port'}->write($data);
        my $output2 = $self->{'port'}->read(2);
        my $BYTE1 = unpack("H*", substr($output2,0,1));
        $BYTE2 = unpack("H*", substr($output2,1,1));
        if ($debug){print "\n(writeBlock:DEBUG) - SHOULD BE: ($VALUE) ($OLDBYTE2)\n";}
        if ($debug){print "\n(writeBlock:DEBUG) - IS: -----> ($BYTE1) ($BYTE2)\n";}
        if (($VALUE == $BYTE1) && ($OLDBYTE2 == $BYTE2)) {
                $writestatus = "OK";
                if($debug){print "\n(writeBlock:DEBUG) - VALUES MATCH!!!\n\n";}
                                                         }
        else {
                $writestatus = "1";
                if($debug){print "\n(writeBlock:DEBUG) - NO MATCH!!!\n\n";}
                          }
        if ($bitwatch){$self->bitCheck("$lastaction");}
return $writestatus;
               }

#### Writes an entire byte of data to the eeprom, MSB LSB VALUE
sub writeDoubleblock {
        my $self=shift;
        my ($writestatus) = @_;
        my $address=shift;
        my $VALUE=shift;
	my $VALUE2=shift;
        my $caller = ( caller(1) )[3];
        if ($writeallow != '1' and $agreewithwarning != '1') {
                if($debug || $verbose){print"Writing to EEPROM disabled, use setWriteallow(1) to enable\n";}
                $writestatus = "Write Disabled";
return $writestatus;
                                                             }

        my $data = join("","$address",'0000BB');
        if ($debug){print "\n(writeDoubleblock:DEBUG) - PACKET BUILT ------> [$data]\n";}
        $data = pack( 'H[10]', "$data" );
        $self->{'port'}->write($data);
        my $output = $self->{'port'}->read(2);
        my $BYTE1 = unpack("H*", substr($output,0,1));
        my $BYTE2 = unpack("H*", substr($output,1,1));
	 if ($debug){print "\n(writeDoubleblock:DEBUG) - CHECKING IF [$VALUE] needs padding\n";}
        if (length($VALUE) < 2) {
                   $VALUE = join("",'0', "$VALUE");
                   if ($debug){print "\n(writeBlock:DEBUG) - Padded to [$VALUE]\n";}
                                }
 	if ($debug){print "\n(writeDoubleblock:DEBUG) - CHECKING IF [$VALUE2] needs padding\n";}
        if (length($VALUE2) < 2) {
                   $VALUE2 = join("",'0', "$VALUE2");
                   if ($debug){print "\n(writeDoubleblock:DEBUG) - Padded to [$VALUE2]\n";}
                                 }
        if ($debug){print "\n(writeDoubleblock:DEBUG) - WRITING  ----------> [$VALUE] [$VALUE2]\n";}
        my $data2 = join("","$address","$VALUE","$VALUE2",'BC');
        if ($debug){print "\n(writeBlock:DEBUG) - PACKET BUILT ------> [$data2]\n";}
        our $lastaction = "writeDoubleblock: $data2 from $caller";
	$data2 = pack( 'H[10]', "$data2" );
        $self->{'port'}->write($data2);
        $output = $self->{'port'}->read(2);
        if ($debug){print "\n(writeDoubleblock:DEBUG) - VALUES WRITTEN, CHECKING...\n";}
        $self->{'port'}->write($data);
        my $output2 = $self->{'port'}->read(2);
        my $NEWBYTE1 = unpack("H*", substr($output2,0,1));
        my $NEWBYTE2 = unpack("H*", substr($output2,1,1));
        if ($debug){print "\n(writeDoubleblock:DEBUG) - SHOULD BE: ($VALUE) ($VALUE2)\n";}
        if ($debug){print "\n(writeDoubleblock:DEBUG) - IS: -----> ($NEWBYTE1) ($NEWBYTE2)\n";}
        if (($VALUE == $NEWBYTE1) && ($VALUE2 == $NEWBYTE2)) {
                $writestatus = "OK";
                if($debug){print "\n(writeDoubleblock:DEBUG) - VALUES MATCH!!!\n\n";}
                                                         }
        else {
                $writestatus = "1";
                if($debug){print "\n(writeDoubleblock:DEBUG) - NO MATCH!!!\n\n";}
                          }
        if ($bitwatch){$self->bitCheck("$lastaction");}
return $writestatus;

		     }

#### Restores eprom memory address to pre written default value in case there was an error

sub restoreEeprom {
        my $self=shift;
	my $area=shift;
        my ($writestatus,$test,$restorevalue,$restorearea,$address) = @_;
        if ($writeallow != '1' and $agreewithwarning != '1') {
                if($debug || $verbose){print"Writing to EEPROM disabled, use setWriteallow(1) to enable\n";}
                $writestatus = "Write Disabled";
return $writestatus;
                                                             }
                if(!$RESTOREAREAS{$area}){
		if ($verbose){print "Address ($area) not supported for restore...\n";}
                $writestatus = "Invalid memory address ($area)";
return $writestatus;
		   		         }
	if ($verbose){
                        print "\nDEFAULTS LOADED FOR $area\n________________________\n";
        if ($area eq '0055'){printf "%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n\n", 'VFO','A', 'MTQMB','NO', 'QMB','NO', 'MEM/VFO', 'VFO';}
        if ($area eq '0057'){printf "%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n\n", 'AGC','AUTO', 'DSP','OFF', 'PBT','OFF', 'NB', 'OFF', 'LOCK','OFF', 'FASTTUNE','OFF';}
        if ($area eq '0058'){printf "%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n\n", 'PWR METER','PWR', 'CW PADDLE','NORMAL', 'KEYER','OFF', 'BK', 'OFF', 'VLT','OFF', 'VOX','OFF';}
        if ($area eq '0059'){printf "%-11s %-11s\n%-11s %-11s\n\n", 'VFO A','2M', 'VFO B','20M';}
        if ($area eq '005B'){printf "%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n\n", 'Contrast','5', 'Color','Blue', 'Backlight','Auto';}
        if ($area eq '005C'){printf "%-11s %-11s\n%-11s %-11s\n\n", 'Beep Volume','50', 'Beep Frequency','880 hz';}
        if ($area eq '005D'){printf "%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n\n", 'Resume Scan','5 SEC', 'PKT Rate','1200', 'Scope','CONT', 'CW-ID', 'OFF', 'Main STEP','FINE', 'ARTS','RANGE';}
        if ($area eq '005E'){printf "%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n\n", 'CW Pitch','700 Hz', 'Lock Mode','Dial', 'OP Filter','OFF';}
        if ($area eq '005F'){printf "%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n\n", 'CW Weight','1:3', '430 ARS','ON', '144 ARS','ON', 'SQL-RFG', 'SQUELCH';}
        if ($area eq '0060'){printf "%-11s %-11s\n%-11s %-11s\n\n", 'CW Delay','250';}
        if ($area eq '0061'){printf "%-11s %-11s\n%-11s %-11s\n\n", 'Sidetone Volume','50';}
        if ($area eq '0062'){printf "%-11s %-11s\n%-11s %-11s\n\n", 'CW Speed','12wpm', 'Chargetime','8hrs';}
        if ($area eq '0063'){printf "%-11s %-11s\n%-11s %-11s\n\n", 'VOX Gain','50', 'AM\&FM DL','DISABLED';}
        if ($area eq '0064'){printf "%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n\n", 'Vox Delay','500 msec', 'Emergency','OFF', 'Cat rate','4800';}
        if ($area eq '0065'){printf "%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n\n", 'APO Time','OFF', 'MEM Groups','OFF', 'DIG Mode','RTTY';}
        if ($area eq '0066'){printf "%-11s %-11s\n%-11s %-11s\n\n", 'TOT Time','OFF', 'DCS INV','TN-RN';}
        if ($area eq '0067'){printf "%-11s %-11s\n %-11s %-11s\n\n", 'SSB MIC','50' , 'MIC SCAN','ON';}
        if ($area eq '0068'){printf "%-11s %-11s\n%-11s %-11s\n\n", 'AM MIC','50', 'MIC KEY','OFF';}
        if ($area eq '0069'){printf "%-11s %-11s\n\n", 'FM MIC','50';}
        if ($area eq '006A'){printf "%-11s %-11s\n\n", 'DIG MIC','50';}
        if ($area eq '006B'){printf "%-11s %-11s\n%-11s %-11s\n\n", 'PKT MIC','50','EXT MENU','OFF';}
        if ($area eq '006C'){printf "%-11s %-11s\n\n", '9600 MIC','50';}
        if ($area eq '006D'){printf "%-11s %-11s\n\n", 'DIG SHIFT MSB','0';}
        if ($area eq '006E'){printf "%-11s %-11s\n\n", 'DIG SHIFT LSB','0';}
        if ($area eq '006F'){printf "%-11s %-11s\n\n", 'DIG DISP MSB','0';}
        if ($area eq '0070'){printf "%-11s %-11s\n\n", 'DIG DISP LSB','0';}
        if ($area eq '0071'){printf "%-11s %-11s\n\n", 'R LSB CAR','0';}
        if ($area eq '0072'){printf "%-11s %-11s\n\n", 'R USB CAR','0';}
        if ($area eq '0073'){printf "%-11s %-11s\n\n", 'T LSB CAR','0';}
        if ($area eq '0074'){printf "%-11s %-11s\n\n", 'T USB CAR','0';}
        if ($area eq '0079'){printf "%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n\n", 'TX Power','LOW1', 'PRI','OFF', 'DUAL-WATCH', 'OFF', 'SCAN', 'OFF', 'ARTS', 'OFF';}
        if ($area eq '007A'){printf "%-11s %-11s\n%-11s %-11s\n\n", 'Antennas','All Rear except VHF and UHF', 'SPL','OFF';}
        if ($area eq '007B'){printf "%-11s %-11s\n%-11s %-11s\n\n", 'Chargetime','8hrs', 'Charger','OFF';}
        if ($area eq '044F'){printf "%-11s %-11s\n\n", 'Current Memory Channel','0';}
		     }
$writestatus = $self->writeBlock("$area","$RESTOREAREAS{$area}");
return $writestatus;
		  }

###############################
#CAT COMMANDS IN ORDER BY BOOK#
###############################


#### ENABLE/DISABLE LOCK VIA CAT
sub catLock {
        my ($data) = @_;
	my $self=shift;
	my $lock = shift;
        $data = undef;
	$self->setVerbose(0);
	$output=$self->getLock();
	$self->setVerbose(1);
        if ($output eq $lock) {
                if($verbose){print "\nLock is already set to $lock\n\n"; }
return 1;
                              }

        if ($lock ne 'ON' && $lock ne 'OFF') {
                if($verbose){print "\nChoose valid option: ON/OFF\n\n"; }
return 1;
                                             }
	if ($lock eq 'ON') {$data = "00";}
	if ($lock eq 'OFF') {$data = "80";}
	$output = $self->sendCat('00','00','00','00',"$data",1);
	if ($verbose){
		print "Set Lock ($lock) Sucessfull.\n" if ($output eq '00');
		print "Set Lock ($lock) Failed.\n" if ($output eq 'f0');
           	     }
return $output;
            }

#### ENABLE/DISABLE PTT VIA CAT
sub catPtt {
        my ($data) = @_;
	my $self=shift;
	my $ptt = shift;
	$data = undef;

        if ($ptt ne 'ON' && $ptt ne 'OFF') {
                if($verbose){print "\nChoose valid option: ON/OFF\n\n"; }
return 1;
                                           }

	if ($ptt eq 'ON') {$data = "08";}
	if ($ptt eq 'OFF') {$data = "88";}
	$output = $self->sendCat('00','00','00','00',"$data",1);
	if ($verbose){
		print "Set PTT ($ptt) Sucessfull.\n" if ($output eq '00');
		print "Set PTT ($ptt) Failed. Already set to $ptt\?\n" if ($output eq 'f0');
            	     }
return $output;
           }

#### SET CURRENT FREQ USING CAT
sub catsetFrequency {
	my ($badf,$f1,$f2,$f3,$f4) = @_;
	my $self=shift;
	my $newfrequency = shift;

        $self->setVerbose(0);
        $output=$self->catgetFrequency();
        $self->setVerbose(1);
        if ($output eq $newfrequency) {
                if($verbose){print "\nFrequency is already set to $newfrequency\n\n"; }
return 1;
                                      }

        if ($newfrequency!~ /\D/ && length($newfrequency)=='8') {
		$f1 = substr($newfrequency, 0,2);
		$f2 = substr($newfrequency, 2,2);
		$f3 = substr($newfrequency, 4,2);
		$f4 = substr($newfrequency, 6,2);
							        }
	else {
		$badf = $newfrequency;
		$newfrequency = undef;
return 1;
	     }
	$output = $self->sendCat("$f1","$f2","$f3","$f4",'01',1);
	if ($verbose){
		print "Set Frequency ($newfrequency) Sucessfull.\n" if ($output eq '00');
		print "Set Frequency ($newfrequency) Failed. $newfrequency invalid or out of range\?\n" if ($output eq 'f0');
            	     }
return $output;
                 }

#### SET MODE VIA CAT
sub catsetMode {
	my $self=shift;
	my $newmode = shift;
        $self->setVerbose(0);
        $output=$self->catgetMode();
        $self->setVerbose(1);
        if ($output eq $newmode) {
                if($verbose){print "\nMode is already set to $newmode\n\n"; }
return 1;
                                 }

        my %newhash = reverse %OPMODES;
        my ($mode) = grep { $newhash{$_} eq $newmode } keys %newhash;
        if ($mode eq'') {
                if($verbose){print "\nChoose valid mode: USB/LSB/FM etc etc\n\n"; }
return 1;
                        }
	$output = $self->sendCat("$mode","00","00","00",'07',1);
	if ($verbose){
		print "Set Mode ($newmode) Sucessfull.\n" if ($output eq '00');
		print "Set Mode ($newmode) Failed.\n" if (! $mode || $output ne '00');
            	     }
return $output;
         }

#### ENABLE/DISABLE CLARIFIER VIA CAT
sub catClarifier {
	my ($data) = @_;
	my $self=shift;
	my $clarifier = shift;
	$data = undef;

        if ($clarifier ne 'ON' && $clarifier ne 'OFF') {
                if($verbose){print "\nChoose valid option: ON/OFF\n\n"; }
return 1;
                                                       }

	if ($clarifier eq 'ON') {$data = "05";}
	if ($clarifier eq 'OFF') {$data = "85";}
        $output = $self->sendCat('00','00','00','00',"$data",1);
        if ($verbose){
                print "Set Clarifier ($clarifier) Sucessfull.\n" if ($output eq '00');
                print "Set Clarifier ($clarifier) Failed. Already set to $clarifier\?\n" if ($output eq 'f0');
                     }
return $output;
                 }

#### SET CLARIFIER FREQ AND POLARITY USING CAT
sub catClarifierfreq {
	my ($badf,$f1,$f2,$p) = @_;
	my $self=shift;
	my $polarity = shift;
	my $frequency = shift;
        if ($polarity ne 'POS' && $polarity ne 'NEG') {
                if($verbose){print "\nChoose valid option: POS/NEG\n\n"; }
return 1;
                                                      }
	$p = undef;
	$badf = undef;
	if ($frequency!~ /\D/ && length($frequency)=='4') {
                         $f1 = substr($frequency, 0,2);
                         $f2 = substr($frequency, 2,2);
							  }
		else {
			$badf = $frequency;
			$frequency = undef;
		     }  
	if ($polarity eq 'POS') {$p = '00';}
	if ($polarity eq 'NEG') {$p = '11';}
	if($frequency){if($p){
			$output = $self->sendCat("$p",'00',"$f1","$f2",'f5',1)}};

        if ($verbose){
                print "Set Clarifier Frequency ($polarity:$badf) Failed. Must contain 4 digits 0000-0999.\n" if (! $frequency);
		print "Set Clarifier Frequency ($polarity:$frequency) Sucessfull.\n" if ($output eq '00');
		print "Set Clarifier Frequency ($polarity:$frequency) Failed. $frequency out of range? POS / NEG 0000 to 0999\n" if ($output eq 'f0');
                     }
return $output;
                     }

#### TOGGLE VFO A/B VIA CAT
sub catvfoToggle {
	my $self=shift;
	$output = $self->sendCat('00','00','00','00','81',1);
        if ($verbose){
                print "VFO toggle Sucessfull.\n" if ($output eq '00');
                print "VFO toggle Failed\n" if ($output eq 'f0');
                     }
return $output;
              }

#### ENABLE/DISABLE SPLIT FREQUENCY VIA CAT
sub catSplitfreq {
	my ($data) = @_;
	my $self=shift;
	my $split = shift;
	$data = undef;

        if ($split ne 'ON' && $split ne 'OFF') {
                if($verbose){print "\nChoose valid option: ON/OFF\n\n"; }
return 1;
                                               }
	if ($split eq 'ON') {$data = "02";}
	if ($split eq 'OFF') {$data = "82";}


	$output = $self->sendCat('00','00','00','00',"$data",1);
        if ($verbose){
                print "Set Split Frequency ($split) Sucessfull.\n" if ($output eq '00');
                print "Set Split Frequency ($split) Failed. Already set to $split\?\n" if ($output eq 'f0');
                     }
return $output;
              }

#### POS/NEG/SIMPLEX REPEATER OFFSET MODE VIA CAT
sub catOffsetmode {
	my ($datablock) = @_;
	my $self=shift;
	my $offsetmode = shift;
	$datablock = undef;

        if ($offsetmode ne 'POS' && $offsetmode ne 'NEG' && $offsetmode ne 'SIMPLEX') {
                if($verbose){print "\nChoose valid option: POS/NEG/SIMPLEX\n\n"; }
return 1;
                                                                                      }

	if ($offsetmode eq 'POS'){$datablock = '49';}
	if ($offsetmode eq 'NEG') {$datablock = '09';}
	if ($offsetmode eq 'SIMPLEX') {$datablock = '89';}
	$output = $self->sendCat("$datablock",'00','00','00','09',1);
        if ($verbose){
                print "Set Offset Mode ($offsetmode) Sucessfull.\n" if ($datablock);
                print "Set Offset Mode ($offsetmode) Failed. Option:$offsetmode invalid\.\n" if (! $datablock);
                     }
return $output;
                }

#### SET REPEATER OFFSET FREQ USING CAT
sub catOffsetfreq {
	my ($badf,$f1,$f2,$f3,$f4) = @_;
        my $self=shift;
        my $frequency = shift;
        if ($frequency!~ /\D/ && length($frequency)=='8') {
		$f1 = substr($frequency, 0,2);
		$f2 = substr($frequency, 2,2);
		$f3 = substr($frequency, 4,2);
		$f4 = substr($frequency, 6,2);
							  }
        else {
                $badf = $frequency;
                $frequency = undef;
             }
	$output = $self->sendCat("$f1","$f2","$f3","$f4",'F9',1);
        if($verbose){
                print "Set Offset Frequency ($badf) Failed. Must contain 8 digits 0000-9999.\n" if (! $frequency);
                print "Set Offset Frequency ($frequency) Sucessfull.\n" if ($output eq '00');
                print "Set Offset Frequency ($frequency) Failed. $frequency invalid or out of range or split frequency on\?\n" if ($output eq 'f0');
                    }
return $output;
                 }

#### SETS CTCSS/DCS MODE VIA CAT
sub catCtcssdcs {
	my ($split,$data) = @_;
        my $self=shift;
        my $ctcssdcs = shift;
	$data = undef;

        if ($ctcssdcs ne 'DCS' && $ctcssdcs ne 'CTCSS' && $ctcssdcs ne 'ON' && $ctcssdcs ne 'OFF') {
                if($verbose){print "\nChoose valid option: DCS/CTCSS/ON/OFF\n\n"; }
return 1;
                                                                                                        }

	if ($ctcssdcs eq 'DCS'){$data = "0A";}
	if ($ctcssdcs eq 'CTCSS'){$data = "2A";}
	if ($ctcssdcs eq 'ON'){$data = "4A";}
	if ($ctcssdcs eq 'OFF'){$data = "8A";}
        $output = $self->sendCat("$data",'00','00','00','0A',1);
        if ($verbose){
                print "Set Encoder Type ($ctcssdcs) Sucessfull.\n" if ($data);
                print "Set Encoder Type ($ctcssdcs) Failed. Option:$ctcssdcs invalid\.\n" if (! $data);
                     }
return $output;
                }

#### SETS CTCSS TONE FREQUENCY
sub catCtcsstone {
	my ($badf,$f1,$f2) = @_;
	my $self=shift;
	my $tonefreq = shift;
        if ($tonefreq!~ /\D/ && length($tonefreq)=='4') {
		$f1 = substr($tonefreq, 0,2);
		$f2 = substr($tonefreq, 2,2);
							}
	 else {
		$badf = $tonefreq;
		$tonefreq = undef;
                print "Set CTCSS Tone ($badf) Failed. Must contain 4 digits 0-9.\n" if (! $tonefreq);
return 1;
	      }
	if($tonefreq){$output = $self->sendCat("$f1","$f2",'00','00','0B',1);}
        if ($verbose){
                print "Set CTCSS Tone ($badf) Failed. Must contain 4 digits 0-9.\n" if (! $tonefreq);
                print "Set CTCSS Tone ($tonefreq) Sucessfull.\n" if ($output eq '00');

	if ($output eq 'f0'){
		print "Set CTCSS ($tonefreq) Failed. $tonefreq is not a valid tone frequency. Leading zero if necessary\n\n";
		my $columns = 1;
		foreach my $tones (sort keys %CTCSSTONES) {
    		printf "%-15s %s",$CTCSSTONES{$tones};
		$columns++;
		if ($columns == 7){print "\n\n"; $columns = 1;}
 			  			          }
		print "\n\n";	       
				}
                     }
return $output;
                 }

#### SET DCS CODE USING CAT######
sub catDcscode {
	my ($badf,$f1,$f2) = @_;
        my $self=shift;
        my $code = shift;
        if ($code!~ /\D/ && length($code)=='4') {
		$f1 = substr($code, 0,2);
		$f2 = substr($code, 2,2);
						}
         else {
                $badf = $code;
                $code = undef;
                if (!$code && $verbose){print "Set DCS Code ($badf) Failed. Must contain 4 digits 0-9. Leading zero if necessary\n";}
return 1;
              }
	if($code){$output = $self->sendCat("$f1","$f2",'00','00','0C',1);}
        if ($verbose){
                print "Set DCS Code ($badf) Failed. Must contain 4 digits 0-9.\n" if (! $code);
                print "Set DCS Code ($code) Sucessfull.\n" if ($output eq '00');
	if ($output eq 'f0') {
                print "Set DCS Code ($code) Failed. $code is not a valid DCS Code\.\n\n";
		my $columns = 1;
                foreach my $codes (sort keys %DCSCODES) {
                printf "%-15s %s",$DCSCODES{$codes};
                $columns++;
                if ($columns == 7){print "\n\n"; $columns = 1;}
                                                          }
                print "\n\n";

				}
                     }
return $output;
                 }

#### GET MULTIPLE VALUES OF RX STATUS RETURN AS variables OR hash
sub catRxstatus {
        my ($match,$desc,$squelch) = @_;
        my $self=shift;
        my $option = shift;
	if (!$option){$option = 'HASH';} 
        $output = $self->sendCat('00','00','00','00','E7',1);
	my $values = hex2bin($output);
	my $sq = substr($values,0,1);
	my $smeter = substr($values,4,4);
	my $smeterlin = substr($values,4,4);
	my $ctcssmatch = substr($values,2,1);
	my $descriminator = substr($values,3,1);
	($smeter) = grep { $SMETER{$_} eq $smeter } keys %SMETER;
	($smeterlin) = grep { $SMETERLIN{$_} eq $smeterlin } keys %SMETERLIN;
	if ($sq == 0) {$squelch = 'OFF';}
	if ($sq == 1) {$squelch = 'ON';}
	if ($ctcssmatch == 0) {$match = 'MATCHED/OFF';}
	if ($ctcssmatch == 1) {$match = 'UNMATCHED';}
	if ($descriminator == 0) {$desc = 'CENTERED';}
	if ($descriminator == 1) {$desc = 'OFF-CENTER';}
	if ($verbose) {
                print "\nReceive status:\n\n";
                printf "%-18s %-11s\n", 'FUNCTION','VALUE';
                print "________________________";
                printf "\n%-18s %-11s\n%-18s %-11s\n%-18s %-11s\n%-18s %-11s\n\n", 'Squelch', "$squelch", 'S-METER', "$smeter \/ $smeterlin", 'Tone Match', "$match", 'Descriminator', "$desc";
		      }
	if ($option eq'VARIABLES'){
return ("$squelch","$smeter","$smeterlin" ,"$match", "$desc");
				  }
        if ($option eq 'HASH') {
		my %rxstatus = ('squelch' => "$squelch", 'smeterdb' => "$smeter", 'smeterlinear' => "$smeterlin",
		'descriminator' => "$desc", 'ctcssmatch' => "$match");
return %rxstatus;
                               }
		}

#### GET MULTIPLE VALUES OF TX STATUS RETURN AS variables OR hash
sub catTxstatus {
        my ($match,$desc,$ptt,$highswr,$split) = @_;
        my $self=shift;
        my $option = shift;
        if (!$option){$option = 'HASH';}
        $output = $self->sendCat('00','00','00','00','F7',1);
        my $values = hex2bin($output);
        my $pttvalue = substr($values,0,1);
        my $pometer = substr($values,4,4);
        my $pometerlin = substr($values,4,4);
        my $highswrvalue = substr($values,2,1);
        my $splitvalue = substr($values,3,1);
        ($pometer) = grep { $PMETER{$_} eq $pometer } keys %PMETER;
        if ($pttvalue == 0) {$ptt = 'OFF';}
        if ($pttvalue == 1) {$ptt = 'ON';}
        if ($highswrvalue == 0) {$highswr = 'OFF';}
        if ($highswrvalue == 1) {$highswr = 'ON';}
        if ($splitvalue == 0) {$split = 'ON';}
        if ($splitvalue == 1) {$split = 'OFF';}
        if ($verbose) {
               print "\nTransmit status:\n\n";
                printf "%-18s %-11s\n", 'FUNCTION','VALUE';
                print "________________________";
                printf "\n%-18s %-11s\n%-18s %-11s\n%-18s %-11s\n%-18s %-11s\n\n", 'Power Meter', "$pometer", 'PTT', "$ptt", 'High SWR', "$highswr", 'Split', "$split";
                      }
        if ($option eq'VARIABLES'){
return ("$ptt","$pometer","$highswr" ,"$split");
                                  }
        if ($option eq 'HASH') {
                my %txstatus = ('ptt' => "$ptt", 'pometer' => "$pometer",
                'highswr' => "$highswr", 'split' => "$split");
return %txstatus;
                               }
                  }

#### GET CURRENT FREQ USING CAT######
sub catgetFrequency {
	my ($freq) = @_;
	my $self=shift;
	my $formatted = shift;
	$output = $self->sendCat('00','00','00','00','03',5);
	$freq = substr($output,0,8);
	$freq =~ s/^0+//;
	if ($formatted == 1)    {
		substr($freq,-2,0) = '.';
		substr($freq,-6,0) = '.';
		$freq .= " MHZ";
				}
        if ($verbose){print "Frequency is $freq\n";}
return $freq;
                    }

#### GET CURRENT MODE USING CAT######
sub catgetMode {
	my $self=shift;
	my $currentmode;
	my $formatted = shift;
	$output = $self->sendCat('00','00','00','00','03',5);
	$currentmode = substr($output,8,2);
	my ($mode) = grep { $OPMODES{$_} eq $currentmode } keys %OPMODES;
        if ($verbose){print "Mode is $mode\n";}
return $mode;
               }

#### SETS RADIO POWER ON OR OFF VIA CAT
sub catPower {
        my ($data) = @_;
	my $self=shift;
	my $powerset = shift;
	$data = undef;
        if ($powerset ne 'ON' && $powerset ne 'OFF') {
                if($verbose){print "\nChoose valid option: ON/OFF\n\n"; }
return 1;
                                                     }
		    

	if ($powerset eq 'ON'){$data = "0F";}
	if ($powerset eq 'OFF') {$data = "8F";}
	$self->sendCat('00','00','00','00','00',1);
	$output = $self->sendCat('00','00','00','00',"$data",1);
	if($verbose){
                print "Set Power ($powerset) Sucessfull.\n" if ($output eq '00');
                print "Set Power ($powerset) Failed. Already $powerset\?\n" if (!$output);
		    }

return $output;
	     }

###############################
#     END OF CAT COMMANDS     #
###############################


################################
# READ VALUES FROM EEPROM ADDR #
################################

# X ################################# GET VALUES OF EEPROM ADDRESS VIA EEPROMDECODE
###################################### READ ADDRESS GIVEN
sub getEeprom {
        my ($times,$valuehex,%valuehash) = @_;
        my $self=shift;
	my $address1 =shift;
	my $address2 = shift;
	my $base = $address1;
	if (!$address2) {$address2 = $address1;}
        if ($verbose){
		if (!$address1 || length($address1) != 4) {
                print "Get EEPROM ($address1 $address2) Failed. Must contain  hex value 0-9 a-f. i.e. [005F] or  [005F 006A] for a range\n"; 
return 1;
 			 			          }
                if ($address2 && length($address2) != 4) {
                print "Get EEPROM ($address1 $address2) Failed. Must contain  hex value 0-9 a-f. i.e. [005F] or  [005F 006A] for a range\n";
return 1;
                                                          }
		$times=$self->hexDiff("$address1","$address2");
                if ($times < 0) {
                print "The Secondary value [$address2] must be greater than the first [$address1]";
return 1;
                                }
                     }
                print "\n";
                printf "%-11s %-15s %-11s %-11s\n", 'ADDRESS', 'BINARY', 'DECIMAL', 'VALUE';
                print "___________________________________________________\n";

		$times++;
		my $cycles = 0;
	do {
		my $valuebin = $self->eepromDecode("$address1");
                my $valuehex = sprintf("%X", oct( "0b$valuebin" ) );
                $valuehash{"$address1"} = $valuehex;
                my $valuedec = hex($valuehex);
                printf "%-11s %-15s %-11s %-11s\n", "$address1", "$valuebin", "$valuedec", "$valuehex";
		$cycles++;
                $address1 = $self->hexAdder("$cycles","$base");
  	   }
	        while ($cycles < $times);
		print "\n";
	if ($times == 1){
return $valuehex;
			}

	else {
return %valuehash;
	     }
              }

# 0-3 ################################# GET EEPROM CHECKSUM
###################################### READ ADDRESS 0X0 AND 0X3
sub getChecksum {
        my ($checksumhex0,$checksumhex1,$checksumhex2,$checksumhex3) = @_;
        my $self=shift;
        my $type=shift;
	my ($output0,$output1) = $self->eepromDoubledecode('0000');
        my ($output2,$output3) = $self->eepromDoubledecode('0002');
        $checksumhex0 = sprintf("%X", oct( "0b$output0" ) );
        $checksumhex1 = sprintf("%X", oct( "0b$output1" ) );
        $checksumhex2 = sprintf("%X", oct( "0b$output2" ) );
        $checksumhex3 = sprintf("%X", oct( "0b$output3" ) );
        my $configoutput = "[$checksumhex0][$checksumhex1][$checksumhex2][$checksumhex3]";
        if($verbose){
                print "\nCHECKSUM VALUES ARE:\n\n";
                printf "%-11s %-11s\n", 'ADDRESS','HEX';
                print "_______________";
                printf "\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n%-11s %-11s\n\n", '0x00', "$checksumhex0", '0x01', "$checksumhex1", '0x02', "$checksumhex2", '0x03', "$checksumhex3";
                    }
return $configoutput;
           }

# 4-5 ################################# GET RADIO VERSION VIA EEPROMDECODE
###################################### READ ADDRESS 0X4 AND 0X5
sub getConfig {
        my ($confighex4,$confighex5) = @_;
        my $self=shift;
	my $type=shift;
        my($output4,$output5) = $self->eepromDoubledecode('0004');
	$confighex4 = sprintf("%x", oct( "0b$output4" ) );
        $confighex5 = sprintf("%x", oct( "0b$output5" ) );
	my $configoutput = "[$confighex4][$confighex5]";
        if($verbose){
                print "\nHardware Jumpers created value of\n\n";
		printf "%-11s %-11s %-15s\n", 'ADDRESS','BINARY','HEX';
		print "___________________________"; 
                printf "\n%-11s %-11s %-15s\n%-11s %-11s %-15s\n\n", '0x04', "$output4", "$confighex4", '0x05', "$output5", "$confighex5";
	            }
return $configoutput;
           }


# 7-53 ################################ GET SOFTWARE CAL VALUES EEPROMDECODE
###################################### READ ADDRESS 0X4 AND 0X5

sub getSoftcal {
        my $self=shift;
	my $option=shift;
	my $filename=shift;
	my $localtime = localtime();
	my $buildfile;
	if (!$option){$option = 'CONSOLE';}
	my $block = 1;
	my $startaddress = "07";
	my $digestdata = undef;
	my $memoryaddress;
	if ($option eq 'CONSOLE') {
		if ($verbose){
		print "\n";
		printf "%-11s %-15s %-11s %-11s\n", 'ADDRESS', 'BINARY', 'DECIMAL', 'VALUE';
		print "___________________________________________________\n";
			     }
	                          }
        if ($verbose && $option eq 'DIGEST'){
                print "Generated an MD5 hash from software calibration values ";
                     }
        if ($option eq 'FILE'){
		if (!$filename) {print"\nFilename required.     eg. /home/user/softcal.txt\n";return 0;}
		if (-e $filename) {
			print "\nFile exists. Backup/rename old file before creating new one.\n";
			return 0;
				  }
		else {
			$buildfile = '1';
			if ($verbose){print "\nCreating calibration backup to $filename........\n";}
			open  FILE , ">>", "$filename" or print"Can't open $filename. error\n";
			print FILE "FT817 Software Calibration Backup\nUsing FT817COMM.pm version $VERSION\n";
			print FILE "Created $localtime\n";
                        print FILE "Using FT817OS Format, Do not modify this file\n\n";
			printf FILE "%-11s %-15s %-11s %-11s\n", 'ADDRESS', 'BINARY', 'DECIMAL', 'VALUE';
                	print FILE "___________________________________________________\n";
		     }
                              }
	if ($option eq 'DIGEST') {
        do {
                $memoryaddress = sprintf("%x",$startaddress);
                my $size = length($memoryaddress);
                if ($size < 2){$memoryaddress = join("",'0',"$memoryaddress");}
		$memoryaddress = join("",'00',"$memoryaddress");
                my $valuebin = $self->eepromDecode("$memoryaddress");
                my $valuehex = sprintf("%x", oct( "0b$valuebin" ) );
		$digestdata .="$valuehex";
                $block++;
                $startaddress ++;
           }
        while ($block < '77');
		my $digest = md5($digestdata);
		if ($verbose) {print "DIGEST: ---->$digest<----\n";}
return $digest;
      			 }
	else {
	do {
		$memoryaddress = sprintf("%x",$startaddress);
		my $size = length($memoryaddress);
		if ($size < 2){$memoryaddress = join("",'0',"$memoryaddress");}	
                $memoryaddress = join("",'00',"$memoryaddress");
		my $valuebin = $self->eepromDecode("$memoryaddress");
		my $valuehex = sprintf("%x", oct( "0b$valuebin" ) );
                my $hexsize = length($valuehex);
                if ($hexsize < 2){$valuehex = join("",'0',"$valuehex");}
		my $valuedec = hex($valuehex);
	if ($option eq 'CONSOLE' || $verbose) {
		printf "\n%-11s %-15s %-11s %-11s\n", "$memoryaddress", "$valuebin", "$valuedec", "$valuehex";
				  }
	if ($buildfile == '1'){
               printf FILE "%-11s %-15s %-11s %-11s\n", "$memoryaddress", "$valuebin", "$valuedec", "$valuehex";
			      }
		$block++;
		$startaddress ++;
	   }
	while ($block < '77');
           }
        if ($buildfile == '1'){
                print FILE "\n\n---END OF Software Calibration Settings---\n";
                close FILE;
		return 0;
                              }
return $output;
                }

# 55 ################################# GET MTQMB, QMB, VFO A/B , HOME VFO OR MEMORY  VIA EEPROMDECODE
###################################### READ BIT 0,1,2,4 AND 8 FROM ADDRESS 0X55

sub getMtqmb {
        my $self=shift;
	my $mtqmb;
        $output = $self->eepromDecode('0055');
        my @block55 = split("",$output);
        if ($block55[6] == '0') {$mtqmb = "OFF";}
        if ($block55[6] == '1') {$mtqmb = "ON";}
        if($verbose){print "MTQMB is $mtqmb\n";}
return $mtqmb;
             }

sub getQmb {
        my $self=shift;
        my $qmb;
        $output = $self->eepromDecode('0055');
        my @block55 = split("",$output);
        if ($block55[5] == '0') {$qmb = "OFF";}
        if ($block55[5] == '1') {$qmb = "ON";}
        if($verbose){print "QMB is $qmb\n";}
return $qmb;
           }

sub getMtune {
        my $self=shift;
        my $mtune;
        $output = $self->eepromDecode('0055');
        my @block55 = split("",$output);
        if ($block55[2] == '0') {$mtune = "MEMORY";}
        if ($block55[2] == '1') {$mtune = "MTUNE";}
        if($verbose){print "MTUNE is $mtune\n";}
return $mtune;
             }

sub getVfo {
	my $self=shift;
	$output = $self->eepromDecode('0055');
	my @block55 = split("",$output);
	if ($block55[7] == '0') {$vfo = "A";}
	if ($block55[7] == '1') {$vfo = "B";}
        if($verbose){print "VFO is $vfo\n";}
return $vfo;
           }

sub getHome {
        my $self=shift;
	my $home;
        $output = $self->eepromDecode('0055');
	my @block55 = split("",$output);
	if ($block55[3] == '1') {$home = "Y";}
	if ($block55[3] == '0') {$home = "N";}
        if($verbose){
		if($home eq'Y'){print "At Home Frequency.\n";}
		if($home eq 'N'){print "Not at Home Frequency\n";}
                    }
return $home;
            }

sub getTuner {
	my $self=shift;
	my $tuneselect;
	$output = $self->eepromDecode('0055');
	my @block55 = split("",$output);
	if ($block55[1] == '0') {$tuneselect = "VFO";}
	if ($block55[1] == '1') {$tuneselect = "MEMORY";}
        if($verbose){print "Tuner is $tuneselect\n";}
return $tuneselect;
             }

# 57 ################################# GET AGC MODE, NOISE BLOCK, FASTTUNE ,PASSBAND Tuning, DSP AND LOCK ######
###################################### READ BITS 0-1 , 2, 4 ,5 AND 6 FROM 0X57

sub getAgc {
	my $self=shift;
	$output = $self->eepromDecode('0057');
	my $agcvalue = substr($output,6,2);
	my ($agc) = grep { $AGCMODES{$_} eq $agcvalue } keys %AGCMODES;
        if($verbose){print "AGC is $agc\n";}
return $agc;
           }

sub getDsp {
        my $self=shift;
	my $dsp;
        $output = $self->eepromDecode('0057');
        my @block55 = split("",$output);
        if ($block55[5] == '0') {$dsp = "OFF";}
        if ($block55[5] == '1') {$dsp = "ON";}
        if($verbose){print "DSP is $dsp\n";}
return $dsp;
           }

sub getPbt {
        my $self=shift;
	my $pbt;
        $output = $self->eepromDecode('0057');
        my @block55 = split("",$output);
        if ($block55[3] == '0') {$pbt = "OFF";}
        if ($block55[3] == '1') {$pbt = "ON";}
        if($verbose){print "Passband Tuning is $pbt\n";}
return $pbt;
           }

sub getNb {
	my $self=shift;
	my $nb;
	$output = $self->eepromDecode('0057');
	my @block55 = split("",$output);
	if ($block55[2] == '0') {$nb = "OFF";}
	if ($block55[2] == '1') {$nb = "ON";}
        if($verbose){print "Noise Blocker is $nb\n";}
return $nb;
          }

sub getLock {
	my $self=shift;
	my $lock;
	$output = $self->eepromDecode('0057');
	my @block55 = split("",$output);
	if ($block55[1] == '1') {$lock = "OFF";}
	if ($block55[1] == '0') {$lock = "ON";}
        if($verbose){print "Lock is $lock\n";}
return $lock;
            }

sub getFasttuning {
        my $self=shift;
	my $fasttuning;
        $output = $self->eepromDecode('0057');
        my @block55 = split("",$output);
        if ($block55[0] == '1') {$fasttuning = "OFF";}
        if ($block55[0] == '0') {$fasttuning = "ON";}
        if($verbose){print "Fast Tuning is $fasttuning\n";}
return $fasttuning;
                  }

# 58 ################################# GET POWER METER MODE, CW PADDLE, KYR, BK, VLT, VOX ######
###################################### READ BIT 0-1,2,4,5,6,7 FROM 0X58

sub getPwrmtr {
        my ($pwrmtr) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0058');
        $pwrmtr = substr($output,6,2);
        if ($pwrmtr == '00'){$pwrmtr = 'PWR'};
        if ($pwrmtr == '01'){$pwrmtr = 'ALC'};
        if ($pwrmtr == '10'){$pwrmtr = 'SWR'};
        if ($pwrmtr == '11'){$pwrmtr = 'MOD'};
        if($verbose){print "Power Meter set to $pwrmtr\n";}
return $pwrmtr;
   	      }

sub getCwpaddle {
        my ($cwpaddle) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0058');
        $cwpaddle = substr($output,5,1);
        if ($cwpaddle == '0'){$cwpaddle = 'NORMAL'};
        if ($cwpaddle == '1'){$cwpaddle = 'REVERSE'};
        if($verbose){print "CW Paddle set to $cwpaddle\n";}
return $cwpaddle;
                }

sub getKyr {
        my ($kyr) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0058');
        $kyr = substr($output,3,1);
        if ($kyr == '0'){$kyr = 'OFF'};
        if ($kyr == '1'){$kyr = 'ON'};
        if($verbose){print "Keyer (KYR) set to $kyr\n";}
return $kyr;
           }

sub getBk {
        my ($bk) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0058');
        $bk = substr($output,2,1);
        if ($bk == '0'){$bk = 'OFF'};
        if ($bk == '1'){$bk = 'ON'};
        if($verbose){print "Break in (BK) set to $bk\n";}
return $bk;
           }

sub getVlt {
        my ($vlt) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0058');
        $vlt = substr($output,1,1);
        if ($vlt == '0'){$vlt = 'OFF'};
        if ($vlt == '1'){$vlt = 'ON'};
        if($verbose){print "Voltage display set to $vlt\n";}
return $vlt;
           }

sub getVox {
        my ($vox) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0058');
        my @block55 = split("",$output);
        if ($block55[0] == '0') {$vox = "OFF";}
        if ($block55[0] == '1') {$vox = "ON";}
        if($verbose){print "VOX is $vox\n";}
return $vox;
           }

# 59 ################################# GET VFO BANDS ######
###################################### READ  ALL BITS FROM 0X59

sub getVfoband {
        my ($vfoband, $vfobandvalue) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'A' && $value ne 'B'){
                if($verbose){print "Value invalid: Choose A/B\n\n";}
return 1;
                                           }
        $output = $self->eepromDecode('0059');
	if ($value eq 'A'){$vfobandvalue = substr($output,4,4);}
	if ($value eq 'B'){$vfobandvalue = substr($output,0,4);}
        ($vfoband) = grep { $VFOBANDS{$_} eq $vfobandvalue } keys %VFOBANDS;
        if($verbose){print "VFO Band is $vfoband\n";}
return $vfoband;
               }

# 5B ################################# GET CONTRAST, COLOR, BACKLIGHT ######
###################################### READ BIT 0-3, 4, 6-7  FROM 0X5B

sub getContrast {
        my ($contrast) = @_;
        my $self=shift;
        $output = $self->eepromDecode('005B');
        $contrast = substr($output,4,4);
        my $HEX1 = sprintf("%X", oct( "0b$contrast" ) );
        $contrast = hex($HEX1);
	$contrast = $contrast - 1;
        if($verbose){print "CONTRAST is $contrast\n";}
return $contrast;
                 }

sub getColor {
        my ($color) = @_;
        my $self=shift;
        $output = $self->eepromDecode('005B');
        $color = substr($output,3,1);
        if ($color == '1'){$color = 'AMBER';}
        else{$color = 'BLUE';}
        if($verbose){print "COLOR is $color\n";}
return $color;
             }

sub getBacklight {
        my ($backlight) = @_;
        my $self=shift;
        $output = $self->eepromDecode('005B');
        $backlight = substr($output,0,2);
        if ($backlight == '00'){$backlight = 'OFF';}
        if ($backlight == '01'){$backlight = 'ON';}
        if ($backlight == '10'){$backlight = 'AUTO';}
        if($verbose){print "BACKLIGHT is set to $backlight\n";}
return $backlight;
                 }

# 5C ################################# GET BEEP VOL, BEEP FREQ ######
###################################### READ BIT 6-0, 7 FROM 0X5C

sub getBeepvol {
        my ($beepvol) = @_;
        my $self=shift;
        $output = $self->eepromDecode('005C');
        $beepvol = substr($output,1,7);
        my $HEX1 = sprintf("%X", oct( "0b$beepvol" ) );
        $beepvol = hex($HEX1);
        if($verbose){print "BEEP VOLUME is $beepvol\n";}
return $beepvol;
               }

sub getBeepfreq {
        my ($beepfreq) = @_;
        my $self=shift;
        $output = $self->eepromDecode('005C');
        $beepfreq = substr($output,0,1);
        if ($beepfreq == '1'){$beepfreq = '880'};
        if ($beepfreq == '0'){$beepfreq = '440'};
        if($verbose){print "BEEP Frequency is $beepfreq hz\n";}
return $beepfreq;
                }

# 5d ################################# GET RESUME SCAN, PKT RATE, SCOPE, CW ID, MAIN STEP, ARTS BEEP MODE ######
###################################### READ BIT 0-1, 2, 3, 4, 5, 6-7 FROM 0X5d

sub getResumescan {
        my ($resumescan) = @_;
        my $self=shift;
        $output = $self->eepromDecode('005D');
        $resumescan = substr($output,6,2);
        if ($resumescan == '00'){$resumescan = 'OFF'};
        if ($resumescan == '01'){$resumescan = '3'};
        if ($resumescan == '10'){$resumescan = '5'};
        if ($resumescan == '11'){$resumescan = '10'};
        if($verbose){print "RESUME SCAN is ($resumescan) sec\n";}
return $resumescan;
                }

sub getPktrate {
        my ($pktrate) = @_;
        my $self=shift;
        $output = $self->eepromDecode('005D');
        $pktrate = substr($output,5,1);
        if ($pktrate == '0'){$pktrate = '1200'};
        if ($pktrate == '1'){$pktrate = '9600'};
        if($verbose){print "PACKET RATE is ($pktrate)\n";}
return $pktrate;
               }

sub getScope {
        my ($scope) = @_;
        my $self=shift;
        $output = $self->eepromDecode('005D');
        $scope = substr($output,4,1);
        if ($scope == '0'){$scope = 'CONT'};
        if ($scope == '1'){$scope = 'CHK'};
        if($verbose){print "SCOPE is ($scope)\n";}
return $scope;
             }

sub getCwid {
        my ($cwid) = @_;
        my $self=shift;
        $output = $self->eepromDecode('005D');
        $cwid = substr($output,3,1);
        if ($cwid == '0'){$cwid = 'OFF'};
        if ($cwid == '1'){$cwid = 'ON'};
        if($verbose){print "CW ID is ($cwid)\n";}
return $cwid;
            }

sub getMainstep {
        my ($mainstep) = @_;
        my $self=shift;
        $output = $self->eepromDecode('005D');
        $mainstep = substr($output,2,1);
        if ($mainstep == '0'){$mainstep = 'FINE'};
        if ($mainstep == '1'){$mainstep = 'COURSE'};
        if($verbose){print "MAIN STEP is ($mainstep)\n";}
return $mainstep;
                }

sub getArtsmode {
        my ($artsmode) = @_;
        my $self=shift;
        $output = $self->eepromDecode('005D');
        $artsmode = substr($output,0,2);
        if ($artsmode == '00'){$artsmode = 'OFF'};
        if ($artsmode == '01'){$artsmode = 'RANGE'};
        if ($artsmode == '10'){$artsmode = 'ALL'};
        if($verbose){print "ARTS BEEP is ($artsmode)\n";}
return $artsmode;
		}

# 5E ################################# GET CW PITCH ,LOCK MODE, OP FILTER######
###################################### READ BIT 0-3, 4-5, 6-7  FROM 0X5E

sub getCwpitch {
        my ($pitch) = @_;
        my $self=shift;
        $output = $self->eepromDecode('005E');
        $pitch = substr($output,4,4);
        my $HEX1 = sprintf("%X", oct( "0b$pitch" ) );
        $pitch = hex($HEX1);
	$pitch = $pitch * 50;
	$pitch = $pitch + 300;
        if($verbose){print "CW PITCH is $pitch\n";}
return $pitch;
               }

sub getLockmode {
        my ($lockmode) = @_;
        my $self=shift;
        $output = $self->eepromDecode('005E');
        $lockmode = substr($output,2,2);
        if ($lockmode == '00'){$lockmode = 'DIAL'};
        if ($lockmode == '01'){$lockmode = 'FREQ'};
        if ($lockmode == '10'){$lockmode = 'PANEL'};
        if($verbose){print "LOCK MODE is $lockmode\n";}
return $lockmode;
                }

sub getOpfilter {
        my ($opfilter) = @_;
        my $self=shift;
        $output = $self->eepromDecode('005E');
        $opfilter = substr($output,0,2);
        if ($opfilter == '00'){$opfilter = 'OFF'};
        if ($opfilter == '01'){$opfilter = 'SSB'};
        if ($opfilter == '10'){$opfilter = 'CW'};
        if($verbose){print "OP FILTER is $opfilter\n";}
return $opfilter;
                }

# 5F ################################# GET CW WEIGHT, 420 ARS, 144 ARS, RFGAIN/SQUELCH ######
###################################### READ BIT 0-4, 5, 6, 7 FROM 0X5F

sub getCwweight {
        my ($cwweight) = @_;
        my $self=shift;
	my $option=shift;
        $output = $self->eepromDecode('005F');
        $cwweight = substr($output,3,5);
        my $HEX1 = sprintf("%X", oct( "0b$cwweight" ) );
        $cwweight = hex($HEX1);
	$cwweight = $cwweight + 25;
        substr($cwweight, -1, 0) = '.';
	if (!$option){$cwweight = join("",'1:',"$cwweight");}	
        if($verbose){print "CW WEIGHT is $cwweight\n";}
return $cwweight;
                 }

sub getArs144 {
        my ($ars144,$value) = @_;
        my $self=shift;
        $output = $self->eepromDecode('005F');
        $ars144 = substr($output,1,1);
        if($ars144 == '0'){$value = 'OFF';}
        else {$value = 'ON';}
        if($verbose){print "144 ARS is set to $value\n";}
return $value;
              }

sub getArs430 {
        my ($ars430,$value) = @_;
        my $self=shift;
        $output = $self->eepromDecode('005F');
        $ars430 = substr($output,2,1);
        if($ars430 == '0'){$value = 'OFF';}
        else {$value = 'ON';}
        if($verbose){print "430 ARS is set to $value\n";}
return $value;
              }

sub getRfknob {
        my ($sqlbit,$value) = @_;
	my $self=shift;
        $output = $self->eepromDecode('005F');
	$sqlbit = substr($output,0,1);
        if($sqlbit == '0'){$value = 'RFGAIN';}
        else {$value = 'SQUELCH';}
        if($verbose){print "RF-KNOB is set to $value\n";}
return $value; 
              }

# 60 ################################# GET CWDELAY ######
###################################### READ BIT 0-7 FROM 0X60

sub getCwdelay {
        my ($cwdelay) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0060');
        $cwdelay = substr($output,0,8);
        my $HEX1 = sprintf("%X", oct( "0b$cwdelay" ) );
        $cwdelay = hex($HEX1);
	$cwdelay = $cwdelay * 10;
        if($verbose){print "CW DELAY is $cwdelay\n";}
return $cwdelay;
                }

# 61 ################################# GET SIDETONE VOLUME ######
###################################### READ BIT 0-6 FROM 0X61

sub getSidetonevol {
        my ($sidetonevol) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0061');
        $sidetonevol = substr($output,1,7);
        my $HEX1 = sprintf("%X", oct( "0b$sidetonevol" ) );
        $sidetonevol = hex($HEX1);
        if($verbose){print "SIDETONE VOLUME is $sidetonevol\n";}
return $sidetonevol;
                    }

# 62 ################################# GET CWSPEED, CHARGETIME ######
###################################### READ BIT 0-5, 6-7 FROM 0X62

sub getChargetime {
        my ($chargetime) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0062');
        $chargetime = substr($output,0,2);
        if ($chargetime == '00'){$chargetime = '6'};
        if ($chargetime == '01'){$chargetime = '8'};
        if ($chargetime == '10'){$chargetime = '10'};
        if($verbose){ print "CHARGETIME is $chargetime\n";}
return $chargetime;
		  }

sub getCwspeed {
        my ($cwspeed) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0062');
        $cwspeed = substr($output,2,6);
        my $HEX1 = sprintf("%X", oct( "0b$cwspeed" ) );
	$cwspeed = hex($HEX1);
	$cwspeed = $cwspeed +4;
        if($verbose){print "CW-SPEED is $cwspeed\n";}
return $cwspeed;
	       }

# 63 ################################# GET VOX GAIN, DISABLE AM/FM DIAL ######
###################################### READ BIT 0-6, 7 FROM 0X63

sub getVoxgain {
        my ($voxgain) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0063');
        $voxgain = substr($output,1,7);
        my $HEX1 = sprintf("%X", oct( "0b$voxgain" ) );
        $voxgain = hex($HEX1);
        if($verbose){print "VOX GAIN is $voxgain\n";}
return $voxgain;
               }

sub getAmfmdial {
        my ($disabledial, $value) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0063');
        $disabledial = substr($output,0,1);
        if($disabledial == '0'){$value = 'ENABLE';}
        else {$value = 'DISABLE';}
        if($verbose){print "DISABLE AM/FM DIAL is set to $value\n";}
return $value;
                }

# 64 ################################# GET VOX DELAY, EMERGENCY, CAT RATE ######
###################################### READ BIT 0-4, 5, 6-7 FROM 0X64

sub getVoxdelay {
        my ($voxdelay) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0064');
        $voxdelay = substr($output,3,5);
        my $HEX1 = sprintf("%X", oct( "0b$voxdelay" ) );
        $voxdelay = hex($HEX1);
        $voxdelay = $voxdelay * 100;
        if($verbose){print "VOX DELAY is $voxdelay msec\n";}
return $voxdelay;
                }

sub getEmergency {
        my ($emergency) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0064');
        $emergency = substr($output,2,1);
        if ($emergency == '0'){$emergency = 'OFF'};
        if ($emergency == '1'){$emergency = 'ON'};
        if($verbose){print "EMERGENCY is $emergency\n";}
return $emergency;
                 }

sub getCatrate {
        my ($catrate) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0064');
        $catrate = substr($output,0,2);
        if ($catrate == '00'){$catrate = '4800'};
        if ($catrate == '01'){$catrate = '9600'};
        if ($catrate == '10'){$catrate = '38400'};
        if($verbose){print "CAT RATE is $catrate\n";}
return $catrate;
               }

# 65 ################################# GET APO TIME, MEM GROUP, DIG MODE ######
###################################### READ BIT 0-2, 4, 5-7 FROM 0X65

sub getApotime {
        my ($apotime) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0065');
        $apotime = substr($output,5,3);
        my $HEX1 = sprintf("%X", oct( "0b$apotime" ) );
        $apotime = hex($HEX1);
	if ($apotime == '0'){$apotime = 'OFF';}
        if($verbose){print "APO TIME is $apotime\n";}
return $apotime;
               }

sub getMemgroup {
        my ($memgroup) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0065');
        $memgroup = substr($output,3,1);
        if ($memgroup == '0'){$memgroup = 'OFF'};
        if ($memgroup == '1'){$memgroup = 'ON'};
        if($verbose){print "MEMORY GROUPS is $memgroup\n";}
return $memgroup;
                 }

sub getDigmode {
        my ($digmode) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0065');
        $digmode = substr($output,0,3);
        if ($digmode == '000'){$digmode = 'RTTY'};
        if ($digmode == '001'){$digmode = 'PSK31-L'};
        if ($digmode == '010'){$digmode = 'PSK31-U'};
        if ($digmode == '011'){$digmode = 'USER-L'};
        if ($digmode == '100'){$digmode = 'USER-U'};
        if($verbose){print "DIGITAL MODE is $digmode\n";}
return $digmode;
                 }

# 66 ################################# GET  TOT TIME , DCS INV######
###################################### READ BIT 0-4, 6-7 FROM 0X66

sub getTottime {
        my ($tottime) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0066');
        $tottime = substr($output,3,5);
        my $HEX1 = sprintf("%X", oct( "0b$tottime" ) );
        $tottime = hex($HEX1);
	if ($tottime == 0){$tottime = 'OFF';}
        if($verbose){print "TIME OUT TIMER Time is $tottime\n";}
return $tottime;
               }

sub getDcsinv {
        my ($dcsinv) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0066');
        $dcsinv = substr($output,0,2);
        if ($dcsinv == '00'){$dcsinv = 'TN-RN'};
        if ($dcsinv == '01'){$dcsinv = 'TN-RIV'};
        if ($dcsinv == '10'){$dcsinv = 'TIV-RN'};
        if ($dcsinv == '11'){$dcsinv = 'TIV-RIV'};
        if($verbose){print "DCS INVERSION is $dcsinv\n";}
return $dcsinv;
              }

# 67 ################################# GET SSB MIC, MIC SCAN  ######
###################################### READ BIT 0-6, 7 FROM 0X67

sub getSsbmic {
        my ($ssbmic) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0067');
        $ssbmic = substr($output,1,7);
        my $HEX1 = sprintf("%X", oct( "0b$ssbmic" ) );
        $ssbmic = hex($HEX1);
        if($verbose){print "SSB MIC is $ssbmic\n";}
return $ssbmic;
              }

sub getMicscan {
        my ($micscan) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0067');
        $micscan = substr($output,0,1);
        if ($micscan == '0'){$micscan = 'OFF'};
        if ($micscan == '1'){$micscan = 'ON'};
        if($verbose){print "MIC SCAN is $micscan\n";}
return $micscan;
               }

# 68 ################################# GET AM MIC , MIC KEY ######
###################################### READ BIT 0-6 AND 7 FROM 0X68

sub getAmmic {
        my ($ammic) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0068');
        $ammic = substr($output,1,7);
        my $HEX1 = sprintf("%X", oct( "0b$ammic" ) );
        $ammic = hex($HEX1);
        if($verbose){print "AM MIC is $ammic\n";}
return $ammic;
             }

sub getMickey {
        my ($mickey) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0068');
        $mickey = substr($output,0,1);
        if ($mickey == '0'){$mickey = 'OFF'};
        if ($mickey == '1'){$mickey = 'ON'};
        if($verbose){print "MIC KEY is $mickey\n";}
return $mickey;
               }

# 69 ################################# GET FM MIC , ######
###################################### READ BIT 0-6 FROM 0X69

sub getFmmic {
        my ($fmmic) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0069');
        $fmmic = substr($output,1,7);
        my $HEX1 = sprintf("%X", oct( "0b$fmmic" ) );
        $fmmic = hex($HEX1);
        if($verbose){print "FM MIC is $fmmic\n";}
return $fmmic;
             }

# 6A ################################# GET DIG MIC , ######
###################################### READ BIT 0-6 FROM 0X6A

sub getDigmic {
        my ($digmic) = @_;
        my $self=shift;
        $output = $self->eepromDecode('006A');
        $digmic = substr($output,1,7);
        my $HEX1 = sprintf("%X", oct( "0b$digmic" ) );
        $digmic = hex($HEX1);
        if($verbose){print "DIG MIC is $digmic\n";}
return $digmic;
              }

# 6B ################################# GET PKT MIC ,EXT MENU ######
###################################### READ BIT 0-6,7 FROM 0X6B

sub getPktmic {
        my ($pktmic) = @_;
        my $self=shift;
        $output = $self->eepromDecode('006B');
        $pktmic = substr($output,1,7);
        my $HEX1 = sprintf("%X", oct( "0b$pktmic" ) );
        $pktmic = hex($HEX1);
        if($verbose){print "PKT MIC is $pktmic\n";}
return $pktmic;
              }

sub getExtmenu {
        my ($extmenu) = @_;
        my $self=shift;
        $output = $self->eepromDecode('006B');
        $extmenu = substr($output,0,1);
        if ($extmenu == '0'){$extmenu = 'OFF'};
        if ($extmenu == '1'){$extmenu = 'ON'};
        if($verbose){print "EXT MENU is $extmenu\n";}
return $extmenu;
               }

# 6C ################################# GET 9600 MIC , ######
###################################### READ BIT 0-6 FROM 0X6C

sub get9600mic {
        my ($b9600mic) = @_;
        my $self=shift;
        $output = $self->eepromDecode('006C');
        $b9600mic = substr($output,1,7);
        my $HEX1 = sprintf("%X", oct( "0b$b9600mic" ) );
        $b9600mic = hex($HEX1);
        if($verbose){print "9600 MIC is $b9600mic\n";}
return $b9600mic;
               }

# 6D-6E ################################# GET DIG SHIFT ######
###################################### READ ALL BITS FROM 0X6D AND 0X6E

sub getDigshift{
        my ($newvalue,$polarity) = @_;
        my $self=shift;
        my $MSB = $self->eepromDecode('006D');
        my $LSB = $self->eepromDecode('006E');
        my $binvalue = join("","$MSB","$LSB");
        my $decvalue = oct("0b".$binvalue);
        if ($decvalue >= 0 && $decvalue <= 300) {$newvalue = $decvalue; $polarity = '+';}
        if ($decvalue > 65235) {$newvalue = 65536 - $decvalue; $polarity = '-';}
	$newvalue = $newvalue * 10;
        if($newvalue != '0'){$newvalue = join("","$polarity","$newvalue");}
        if($verbose){print "DIG SHIFT is $newvalue\n";}
return $newvalue;
	       }

# 6F-70 ################################# GET DIG SHIFT ######
###################################### READ ALL BITS FROM 0X6F AND 0X70

sub getDigdisp{
        my ($newvalue,$polarity) = @_;
        my $self=shift;
        my ($MSB,$LSB) = $self->eepromDoubledecode('006F');
        my $binvalue = join("","$MSB","$LSB");
        my $decvalue = oct("0b".$binvalue);
        if ($decvalue >= 0 && $decvalue <= 300) {$newvalue = $decvalue; $polarity = '+';}
        if ($decvalue > 65235) {$newvalue = 65536 - $decvalue; $polarity = '-';}
        $newvalue = $newvalue * 10;
        if($newvalue != '0'){$newvalue = join("","$polarity","$newvalue");}
        if($verbose){print "DIG DISP is $newvalue\n";}
return $newvalue;
              }

# 71 ################################# GET R-LSB CAR ######
###################################### READ ALL BITS FROM 0X71

sub getRlsbcar{
        my ($newvalue,$polarity) = @_;
        my $self=shift;
        my $binvalue = $self->eepromDecode('0071');
        my $decvalue = oct("0b".$binvalue);
        if ($decvalue >= 0 && $decvalue <= 30) {$newvalue = $decvalue; $polarity = '+';}
        if ($decvalue > 224) {$newvalue = 256 - $decvalue; $polarity = '-';}
        $newvalue = $newvalue * 10;
        if($newvalue != '0'){$newvalue = join("","$polarity","$newvalue");}
        if($verbose){print "R-LSB CAR is $newvalue\n";}
return $newvalue;
              }

# 72 ################################# GET R-USB CAR ######
###################################### READ ALL BITS FROM 0X72

sub getRusbcar{
        my ($newvalue,$polarity) = @_;
        my $self=shift;
        my $binvalue = $self->eepromDecode('0072');
        my $decvalue = oct("0b".$binvalue);
        if ($decvalue >= 0 && $decvalue <= 30) {$newvalue = $decvalue; $polarity = '+';}
        if ($decvalue > 224) {$newvalue = 256 - $decvalue; $polarity = '-';}
        $newvalue = $newvalue * 10;
        if($newvalue != '0'){$newvalue = join("","$polarity","$newvalue");}
        if($verbose){print "R-USB CAR is $newvalue\n";}
return $newvalue;
              }

# 73 ################################# GET T-LSB CAR ######
###################################### READ ALL BITS FROM 0X73

sub getTlsbcar{
        my ($newvalue,$polarity) = @_;
        my $self=shift;
        my $binvalue = $self->eepromDecode('0073');
        my $decvalue = oct("0b".$binvalue);
        if ($decvalue >= 0 && $decvalue <= 30) {$newvalue = $decvalue; $polarity = '+';}
        if ($decvalue > 224) {$newvalue = 256 - $decvalue; $polarity = '-';}
        $newvalue = $newvalue * 10;
        if($newvalue != '0'){$newvalue = join("","$polarity","$newvalue");}
        if($verbose){print "T-LSB CAR is $newvalue\n";}
return $newvalue;
              }

# 74 ################################# GET T-USB CAR ######
###################################### READ ALL BITS FROM 0X74

sub getTusbcar{
        my ($newvalue,$polarity) = @_;
        my $self=shift;
        my $binvalue = $self->eepromDecode('0074');
        my $decvalue = oct("0b".$binvalue);
        if ($decvalue >= 0 && $decvalue <= 30) {$newvalue = $decvalue; $polarity = '+';}
        if ($decvalue > 224) {$newvalue = 256 - $decvalue; $polarity = '-';}
        $newvalue = $newvalue * 10;
        if($newvalue != '0'){$newvalue = join("","$polarity","$newvalue");}
        if($verbose){print "T-USB CAR is $newvalue\n";}
return $newvalue;
              }

# 79 ################################# GET TX POWER, PRI, DW, SCN AND ARTS ######
###################################### READ BIT 0-1, 3, 4, 5-6, AND 7 FROM 0X79

sub getTxpower {
	my $self=shift;
	$output = $self->eepromDecode('0079');
	my $txpower = substr($output,6,2);
	($txpow) = grep { $TXPWR{$_} eq $txpower } keys %TXPWR;
        if($verbose){print "TRANSMIT POWER is $txpow\n";}
return $txpow;
               }

sub getPri {
        my ($pri) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0079');
        $pri = substr($output,3,1);
        if ($pri == '0'){$pri = 'OFF'};
        if ($pri == '1'){$pri = 'ON'};
        if($verbose){print "PRIORITY SCANNING is $pri\n";}
return $pri;
           }

sub getDw {
        my ($dw) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0079');
        $dw = substr($output,4,1);
        if ($dw == '0'){$dw = 'OFF'};
        if ($dw == '1'){$dw = 'ON'};
        if($verbose){print "DUAL WATCH is $dw\n";}
return $dw;
          }

sub getScn {
        my ($scn) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0079');
        $scn = substr($output,1,2);
        if ($scn == '00'){$scn = 'OFF'};
        if ($scn == '10'){$scn = 'UP'};
        if ($scn == '11'){$scn = 'DOWN'};
        if($verbose){print "SCANNING is $scn\n";}
return $scn;
           }

sub getArts {
        my ($artsis) = @_;
        my $self=shift;
        $output = $self->eepromDecode('0079');
        my $arts = substr($output,0,1);
	if ($arts == '0'){$artsis = 'OFF'};
        if ($arts == '1'){$artsis = 'ON'};
        if($verbose){print "ARTS is $artsis\n";}
return $artsis;
            }

# 7A ################################# GET ANTENNA STATUS, SPL ######
###################################### READ 0-5, 7 BITS FROM 0X7A

sub getAntenna {
        my ($antenna, %antennas, %returnant) = @_;
        my $self=shift;
	my $value=shift;
	my $ant;
        $output = $self->eepromDecode('007A');
        if ($value eq 'HF'){$antenna = substr($output,7,1);}
        if ($value eq '6M'){$antenna = substr($output,6,1);}
        if ($value eq 'FMBCB'){$antenna = substr($output,5,1);}
        if ($value eq 'AIR'){$antenna = substr($output,4,1);}
        if ($value eq 'VHF'){$antenna = substr($output,3,1);}
        if ($value eq 'UHF'){$antenna = substr($output,2,1);}
	if ($antenna == 0){$ant = 'FRONT';}
        if ($antenna == 1){$ant = 'BACK';}
	if ($value && $value ne 'ALL'){
        if($verbose){print "ANTENNA [$value] is set to $ant\n";}
			              }
	if (!$value || $value eq 'ALL'){
	%antennas = ('HF', 7, '6M', 6, 'FMBCB', 5, 'AIR', 4, 'VHF', 3, 'UHF', 2);
	my $key;
	print "\n";
foreach $key (sort keys %antennas) {
	$antenna = substr($output,$antennas{$key},1);
        if ($antenna == 0){$ant = 'FRONT';}
        if ($antenna == 1){$ant = 'BACK';}
	printf "%-11s %-11s %-11s %-11s\n", 'Antenna', "$key", "set to", "$ant";
	$returnant{$key} = $ant;
 				   }
	print "\n";
return %returnant;
				       }
return $ant;
               }

sub getSpl {
        my ($spl) = @_;
        my $self=shift;
        $output = $self->eepromDecode('007A');
        $spl = substr($output,0,1);
        if ($spl == '0'){$spl = 'OFF'};
        if ($spl == '1'){$spl = 'ON'};
        if($verbose){print "SPLIT FREQUENCY is $spl\n";}
return $spl;
           }

# 7b ################################# GET BATTERY CHARGE STATUS ######
###################################### READ BIT 0-3 and 4 FROM 0X7B

sub getCharger {
        my $self=shift;
        $output = $self->eepromDecode('007B');
	my $test = substr($output,3,1);
	my $time = substr($output,4,4);
        my $timehex = sprintf("%X", oct( "0b$time" ) );
	$time = hex($timehex);
        if ($test == '0') {$charger = "OFF";}
        if ($test == '1') {$charger = "ON";}
	if ($charger eq 'OFF'){
        if($verbose){print "CHARGER is [$charger]: Timer configured for $time hours\n";}
			      }
	        if ($charger eq 'ON'){
        if($verbose){print "CHARGING is [$charger]: Set for $time hours\n";}
                                     }
return $charger;
                 }

# 7D - 388 / 40B - 44E ################################# GET VFO MEM INFO ######
###################################### 

sub readMemvfo {
        my ($testvfoband, $address, $testoptions, $base, %baseaddress, $offset, $startaddress, $fmstep, $amstep, $ctcsstone, $dcscode, $polarity, $newvalue) = @_;
        my $self=shift;
        my $vfo=shift;
        my $band=shift;
        my $value=shift;
	my %memvfohash = ();
	if (!$value) {$value = 'ALL';}
        if ($vfo ne 'A' && $vfo ne 'B' && $vfo ne 'MTQMB' && $vfo ne 'MTUNE'){
                if($verbose){print "Value invalid: Choose A / B / MTQMB / MTUNE\n\n";}
return 1;

	                                                                     }
        if ($vfo eq 'MTQMB') {$vfo = 'A'; $band = 'MTQMB';}
	if ($vfo eq 'MTUNE') {$vfo = 'A'; $band = 'MTUNE';}
        my %newhash = reverse %VFOBANDS;
        ($testvfoband) = grep { $newhash{$_} eq $band } keys %newhash;
        if ($testvfoband eq'') {
		if ($band ne 'MTQMB' && $band ne 'MTUNE'){
                if($verbose){print "\nChoose valid Band : [160M/75M/40M/30M/20M/17M/15M/12M/10M/6M/2M/70CM/FMBC/AIR/PHAN]\n\n";}
return 1;
                                                                           }
			       }
        my %testhash = reverse %VFOMEMOPTS;
        ($testoptions) = grep { $testhash{$_} eq $value } keys %testhash;
        if (!$testoptions && $value ne 'ALL'){
                if($verbose){
                print "Choose a valid option, or no option for ALL\.\n\n";
                my $columns = 1;
                foreach my $options (sort keys %testhash) {
                printf "%-15s %s",$testhash{$options};
                $columns++;
                if ($columns == 7){print "\n\n"; $columns = 1;}
                                                          }
                print "\n\n";
                            }
return 1;
                                           }
	if ($vfo eq 'A'){%baseaddress = reverse %VFOABASE;}
        if ($vfo eq 'B'){%baseaddress = reverse %VFOBBASE;}
	($base) = grep { $baseaddress{$_} eq $band } keys %baseaddress;
	if ($value eq 'MODE' || $value eq 'ALL'){
		$offset=0x00;
		$address = $self->hexAdder("$offset","$base");
       		my $mode;
       		$output = $self->eepromDecode("$address");
       		$output = substr($output,5,3);
       		($mode) = grep { $MEMMODES{$_} eq $output } keys %MEMMODES;
		if($verbose){print "VFO $vfo\[$band\] - MODE is $mode\n"};
		if ($value eq 'ALL'){$memvfohash{'MODE'} = "$mode";}
		else {
return $mode;
     		     }
                                        }


if ($value eq 'NARFM' || $value eq 'ALL'){
	$offset=0x01;
        $address = $self->hexAdder("$offset","$base");
        my $narfm;
        $output = $self->eepromDecode("$address");
        $output = substr($output,4,1);
        if ($output == '0') {$narfm = "OFF";}
        if ($output == '1') {$narfm = "ON";}
        if($verbose){print "VFO $vfo\[$band\] - NARROW FM is $narfm\n"};
	if ($value eq 'ALL'){$memvfohash{'NARFM'} = "$narfm";}
	else {
return $narfm;
	     }
		      			 }

if ($value eq 'NARCWDIG' || $value eq 'ALL'){
        $offset=0x01;
        $address = $self->hexAdder("$offset","$base");
        my $narcw;
        $output = $self->eepromDecode("$address");
        $output = substr($output,3,1);
        if ($output == '0') {$narcw = "OFF";}
        if ($output == '1') {$narcw = "ON";}
        if($verbose){print "VFO $vfo\[$band\] - NARROW CW/DIG is $narcw\n"};
	if ($value eq 'ALL'){$memvfohash{'NARCWDIG'} = "$narcw";}
	else {
return $narcw;
     	     }
                      			    }

if ($value eq 'RPTOFFSET' || $value eq 'ALL'){
        $offset=0x01;
        $address = $self->hexAdder("$offset","$base");
        my $rptoffset;
        $output = $self->eepromDecode("$address");
        $output = substr($output,0,2);
        if ($output == '00') {$rptoffset = "SIMPLEX";}
        if ($output == '01') {$rptoffset = "MINUS";}
        if ($output == '10') {$rptoffset = "PLUS";}
        if ($output == '11') {$rptoffset = "NON-STANDARD";}
        if($verbose){print "VFO $vfo\[$band\] - REPEATER OFFSET is $rptoffset\n"};
	if ($value eq 'ALL'){$memvfohash{'RPTOFFSET'} = "$rptoffset";}
	else {
return $rptoffset;
     	     }
                      			    }

if ($value eq 'TONEDCS' || $value eq 'ALL'){
        $offset=0x04;
        $address = $self->hexAdder("$offset","$base");
        my $tonedcs;
        $output = $self->eepromDecode("$address");
        $output = substr($output,6,2);
        if ($output == '00') {$tonedcs = "OFF";}
        if ($output == '01') {$tonedcs = "TONE";}
        if ($output == '10') {$tonedcs = "TONETSQ";}
        if ($output == '11') {$tonedcs = "DCS";}
        if($verbose){print "VFO $vfo\[$band\] - TONE/DCS SELECT is $tonedcs\n"};
	if ($value eq 'ALL'){$memvfohash{'TONEDCS'} = "$tonedcs";}
	else {
return $tonedcs;
     	     }
                      			   }

if ($value eq 'ATT' || $value eq 'ALL'){
        $offset=0x02;
        $address = $self->hexAdder("$offset","$base");
        my $att;
        $output = $self->eepromDecode("$address");
        $output = substr($output,3,1);
        if ($output == '0') {$att = "OFF";}
        if ($output == '1') {$att = "ON";}
        if($verbose){print "VFO $vfo\[$band\] - ATT is $att\n"};
	if ($value eq 'ALL'){$memvfohash{'ATT'} = "$att";}
	else {
return $att;
     	     }
                     		       }

if ($value eq 'IPO' || $value eq 'ALL'){
        $offset=0x02;
        $address = $self->hexAdder("$offset","$base");
        my $ipo;
        $output = $self->eepromDecode("$address");
        $output = substr($output,2,1);
        if ($output == '0') {$ipo = "OFF";}
        if ($output == '1') {$ipo = "ON";}
        if($verbose){print "VFO $vfo\[$band\] - IPO is $ipo\n"};
	if ($value eq 'ALL'){$memvfohash{'IPO'} = "$ipo";}
	else {
return $ipo;
     	     }
                      		       }

if ($value eq 'FMSTEP' || $value eq 'ALL'){
        $offset=0x03;
        $address = $self->hexAdder("$offset","$base");
        $output = $self->eepromDecode("$address");
        $output = substr($output,5,3);
        ($fmstep) = grep { $FMSTEP{$_} eq $output } keys %FMSTEP;
        if($verbose){print "VFO $vfo\[$band\] - FM STEP is $fmstep\n"};
	if ($value eq 'ALL'){$memvfohash{'FMSTEP'} = "$fmstep";}
	else {
return $fmstep;
     	     }
                      			  }

if ($value eq 'AMSTEP' || $value eq 'ALL'){
        $offset=0x03;
        $address = $self->hexAdder("$offset","$base");
        $output = $self->eepromDecode("$address");
        $output = substr($output,2,3);
        ($amstep) = grep { $AMSTEP{$_} eq $output } keys %AMSTEP;
        if($verbose){print "VFO $vfo\[$band\] - AM STEP is $amstep\n"};
	if ($value eq 'ALL'){$memvfohash{'AMSTEP'} = "$amstep";}
	else {
return $amstep;
     	     }
	   			          }

if ($value eq 'SSBSTEP' || $value eq 'ALL'){
        $offset=0x03;
        $address = $self->hexAdder("$offset","$base");
        my $ssbstep;
        $output = $self->eepromDecode("$address");
        $output = substr($output,0,2);
        if ($output == '00') {$ssbstep = '1.0';}
        if ($output == '01') {$ssbstep = '2.5';}
	if ($output == '10') {$ssbstep = '5.0';}
        if($verbose){print "VFO $vfo\[$band\] - SSB STEP is $ssbstep\n"};
	if ($value eq 'ALL'){$memvfohash{'SSBSTEP'} = "$ssbstep";}
	else {
return $ssbstep;
     	     }
		                           }

if ($value eq 'CTCSSTONE' || $value eq 'ALL'){
        $offset=0x06;
        my ($MSB, $LSB) = $self->hexAdder("$offset","$base");
        $output = $self->eepromDecode("$MSB","$LSB");
        $output = substr($output,2,6);
        my %newhash = reverse %CTCSSTONES;
        ($ctcsstone) = grep { $newhash{$_} eq $output } keys %newhash;
        if($verbose){print "VFO $vfo\[$band\] - CTCSS TONE is $ctcsstone\n"};
	if ($value eq 'ALL'){$memvfohash{'CTCSSTONE'} = "$ctcsstone";}
	else {
return $ctcsstone;
     	     }
		                             }

if ($value eq 'DCSCODE' || $value eq 'ALL'){
        $offset=0x07;
        $address = $self->hexAdder("$offset","$base");
        $output = $self->eepromDecode("$address");
        $output = substr($output,1,7);
        my %newhash = reverse %DCSCODES;
        ($dcscode) = grep { $newhash{$_} eq $output } keys %newhash;
        if($verbose){print "VFO $vfo\[$band\] - DCSCODE is $dcscode\n"};
	if ($value eq 'ALL'){$memvfohash{'DCSCODE'} = "$dcscode";}
	else {
return $dcscode;
     	     }
			                   }

if ($value eq 'CLARIFIER' || $value eq 'ALL'){
        $offset=0x02;
        $address = $self->hexAdder("$offset","$base");
        my $clarifier;
        $output = $self->eepromDecode("$address");
        $output = substr($output,1,1);
        if ($output == '1') {$clarifier = 'ON';}
        if ($output == '0') {$clarifier = 'OFF';}
        if($verbose){print "VFO $vfo\[$band\] - CLARIFIER is $clarifier\n"};
	if ($value eq 'ALL'){$memvfohash{'CLARIFIER'} = "$clarifier";}
	else {
return $clarifier;
     	     }
			                     }

if ($value eq 'CLAROFFSET' || $value eq 'ALL'){

        $offset=0x08;
        $address = $self->hexAdder("$offset","$base");
        my ($MSB,$LSB) = $self->eepromDoubledecode("$address");
	my $binvalue = join("","$MSB","$LSB");
	my $decvalue = oct("0b".$binvalue);
	my $newvalue;
        if ($decvalue > 999) {$newvalue = 65536 - $decvalue; $polarity = '-';}
        if ($decvalue >= 0 && $decvalue <= 999) {$newvalue = $decvalue; $polarity = '+';}
	my $vallength = length($newvalue);
		if ($vallength == 1) {$newvalue = join("","0.0","$newvalue");}
                       if ($vallength == 2) {$newvalue = join("","0.","$newvalue");}
		if ($vallength == 3) {
       			my $part1 = substr($newvalue,0,1);
			my $part2 = substr($newvalue,1,2);
			$newvalue = join("","$part1",".","$part2");
				     }
                if ($vallength == 4) {
                        my $part1 = substr($newvalue,0,2);
                        my $part2 = substr($newvalue,2,2);
                        $newvalue = join("","$part1",".","$part2");
                                     }
		$newvalue = join("","$polarity","$newvalue");
        if($verbose){print "VFO $vfo\[$band\] - CLARIFIER OFFSET is $newvalue Khz\n";}
	if ($value eq 'ALL'){$memvfohash{'CLAROFFSET'} = "$newvalue";}
	else {
return $newvalue;
     	     }
		 		            }                       

if ($value eq 'RXFREQ' || $value eq 'ALL'){
        $offset=0x0A;
        $address = $self->hexAdder("$offset","$base");
	 my ($ADD1,$ADD2) = $self->eepromDoubledecode("$address");
        $offset=0x0C;
        $address = $self->hexAdder("$offset","$base");
         my ($ADD3,$ADD4) = $self->eepromDoubledecode("$address");
        my $binvalue = join("","$ADD1","$ADD2","$ADD3","$ADD4");
        my $decvalue = oct("0b".$binvalue);
	substr($decvalue, -2, 0) = '.';
        substr($decvalue, -6, 0) = '.';
        if($verbose){print "VFO $vfo\[$band\] - RECEIVE FREQUENCY is $decvalue Mhz\n";}
	if ($value eq 'ALL'){$memvfohash{'RXFREQ'} = "$decvalue";}
	else {
return $decvalue;
     	     }
		     	   	         }	

if ($value eq 'RPTOFFSETFREQ' || $value eq 'ALL'){
        $offset=0x0F;
        $address = $self->hexAdder("$offset","$base");
        my ($ADD1,$ADD2) = $self->eepromDoubledecode("$address");
        $offset=0x11;
        my $address = $self->hexAdder("$offset","$base");
        my $ADD3 = $self->eepromDecode("$address");
        my $binvalue = join("","$ADD1","$ADD2","$ADD3");
        my $decvalue = oct("0b".$binvalue);
	$decvalue = $decvalue / 100000;
        if($verbose){print "VFO $vfo\[$band\] - REPEATER OFFSET is $decvalue Mhz\n";}
	if ($value eq 'ALL'){$memvfohash{'RPTOFFSETFREQ'} = "$decvalue";}
	else {
return $decvalue;
     	     }
			                         }
if ($value eq 'ALL'){ 
return %memvfohash;
		    }

               }

# 044F ################################# GET CURRENT MEMORY CHANNEL ######
###################################### READ ALL BITS FROM 0X44F

sub getCurrentmem {
        my ($currentmem) = @_;
        my $self=shift;
        $output = $self->eepromDecode('044F');
        my $HEX1 = sprintf("%X", oct( "0b$output" ) );
        $output = hex($HEX1);
	$output ++;
	if ($output == '201'){$output = 'M-PL';}
        if ($output == '202'){$output = 'M-PU';}
        if($verbose){print "Current Memory Channel is $output\n";}
return $output;
                  }

# 0450 - 046A############################## GET MEMORY MAP ######
###################################### READ ALL BITS FROM 0X44F

sub getMemmap {
        my $self=shift;
	my $number = shift;
	my $startaddress = '0450';
	my $label = $number;
	if ($number eq 'M-PL'){$number = 201;}
        if ($number eq 'M-PU'){$number = 202;}
	if ($number < 1 || $number > 202){
        if($verbose){print "Memory [$number] invalid. Must be between 1 and 200 or M-PL / M-PU\n"};
return 1;
					 }
 	my $register = int(($number - 1) / 8);
 	my $checkbit = ($number - (8 * ($register + 1))) * -1;
        my $address = $self->hexAdder("$register","$startaddress");
	$output = $self->eepromDecode("$address");
        my $test = substr($output,$checkbit,1);
        if ($test == '0'){$output = 'INACTIVE';}
        if ($test == '1'){$output = 'ACTIVE';}
        if($verbose){print "Memory Channel $label is $output\n";}
return $output;
                  }

sub getActivelist {
        my $self=shift;
	my $currentmem = 1;
	my $memtag;
	if($verbose){ 
                print "\nACTIVE MEMORY AREAS\n___________________\n\n";
                printf "%-5s %-10s %-10s %-6s %-6s %-12s %-9s %-9s %-9s %-9s\n\n", '#','LABEL','READY','SKIP', 'MODE','RXFREQ','ENCODER','TONE/DCS','SHIFT','RPTOFFSET'; 
		    }
        do {
        $self->setVerbose(0);
	$output = $self->getMemmap("$currentmem");
        $self->setVerbose(1);
	if ($output eq 'ACTIVE'){
        $self->setVerbose(0);
	my $label = $self->readMemory('MEM',"$currentmem",'LABEL');
        my $mode = $self->readMemory('MEM',"$currentmem",'MODE');
        my $rxfreq = $self->readMemory('MEM',"$currentmem",'RXFREQ');
        my $memskip = $self->readMemory('MEM',"$currentmem",'MEMSKIP');
        my $encoder = $self->readMemory('MEM',"$currentmem",'TONEDCS');
        my $rptoffset = $self->readMemory('MEM',"$currentmem",'RPTOFFSET');
        my $rptoffsetfreq = $self->readMemory('MEM',"$currentmem",'RPTOFFSETFREQ');
	my $ready = $self->readMemory('MEM',"$currentmem",'READY');
	my $encoderval;
	if ($encoder eq 'TONE' || $encoder eq 'TONETSQ'){
		        $encoderval = $self->readMemory('MEM',"$currentmem",'CTCSSTONE');
			       }
        elsif ($encoder eq 'DCS'){
                        $encoderval = $self->readMemory('MEM',"$currentmem",'DCSCODE');
                               }
	else {$encoderval = 'OFF';}
	$memtag = $currentmem;
	if ($currentmem == '201'){$memtag = 'M-PL'};
        if ($currentmem == '202'){$memtag = 'M-PU'};
        $self->setVerbose(1);
        if($verbose){
        	printf "%-5s %-10s %-10s %-6s %-6s %-12s %-9s %-9s %-9s %-9s\n","$memtag","$label","$ready","$memskip","$mode","$rxfreq","$encoder","$encoderval","$rptoffsetfreq Mhz","$rptoffset";
		    }
				}
	$currentmem++;
           }
        while ($currentmem < '202');
        if($verbose){print "\n";}
return 0;
		  }

# 389 - 40A / 484 - 1907 ################################# GET MEMORY INFO ######
###################################### 

sub readMemory {
        my ($testvfoband, $address, $testoptions, $base, %baseaddress, $offset, $startaddress, $fmstep, $amstep, $ctcsstone, $dcscode, $polarity, $newvalue) = @_;
        my $self=shift;
        my $type=shift;
        my $subtype=shift;
	if ($subtype eq 'M-PL') {$subtype = '201';}
        if ($subtype eq 'M-PU') {$subtype = '202';}
	my $memnum = $subtype;
        my $multiple;
	my $value=shift;
        my %memoryhash = ();
        if (!$value) {$value = 'ALL';}
        if ($type ne 'HOME' && $type ne 'QMB' && $type ne 'M-PL' && $type ne 'M-PU' && $type ne 'MEM') {
                if($verbose){print "Value invalid: Choose HOME / QMB / M-PL / M-PU / MEM\n\n";}
return 1;
                                                                                                       }
        my %testhash = reverse %MEMORYOPTS;
        ($testoptions) = grep { $testhash{$_} eq $value } keys %testhash;
        if (!$testoptions && $value ne 'ALL'){
                if($verbose){
                print "Choose a valid option, or no option for ALL\.\n\n";
                my $columns = 1;
                foreach my $options (sort keys %testhash) {
                printf "%-15s %s",$testhash{$options};
                $columns++;
                if ($columns == 7){print "\n\n"; $columns = 1;}
                                                          }
                print "\n\n";
                            }
return 1;
					     }
        if ($type eq 'HOME'){%baseaddress = reverse %HOMEBASE;}
        if ($type eq 'QMB'){%baseaddress = reverse %MEMORYBASE; $subtype = 'QMB';}
        if ($type eq 'MEM'){%baseaddress = reverse %MEMORYBASE; $subtype = 'MEM';}
        ($base) = grep { $baseaddress{$_} eq $subtype } keys %baseaddress;
	if ($type eq 'MEM'){
		if ($memnum > 1) {
			$multiple = ($memnum - 1) * 26;
			$base = $self->hexAdder("$multiple","$base");		     
		                 }
		            }

if ($value eq 'READY' || $value eq 'ALL'){
        $offset=0x00;
        $address = $self->hexAdder("$offset","$base");
        my $ready;
        $output = $self->eepromDecode("$address");
        $output = substr($output,1,1);
	if ($output == '0'){$ready = 'YES'};
        if ($output == '1'){$ready = 'NO'};        
        if($verbose){print "MEMORY $type\[$subtype\] - READY is $ready\n"};
return $ready;
                                        }

if ($value eq 'MODE' || $value eq 'ALL'){
        $offset=0x00;
        $address = $self->hexAdder("$offset","$base");
        my $mode;
        $output = $self->eepromDecode("$address");
        $output = substr($output,5,3);
        ($mode) = grep { $MEMMODES{$_} eq $output } keys %MEMMODES;
        if($verbose){print "MEMORY $type\[$subtype\] - MODE is $mode\n"};
        if ($value eq 'ALL'){$memoryhash{'MODE'} = "$mode";}
        else {
return $mode;
             }
                                        }

if ($value eq 'HFVHF' || $value eq 'ALL'){
        $offset=0x00;
        $address = $self->hexAdder("$offset","$base");
        my $hfvhf;
        $output = $self->eepromDecode("$address");
        $output = substr($output,2,1);
        if ($output == '0') {$hfvhf = "VHF";}
        if ($output == '1') {$hfvhf = "HF";}
        if($verbose){print "MEMORY $type\[$subtype\] - HF\/VHF is $hfvhf\n"};
        if ($value eq 'ALL'){$memoryhash{'HFVHF'} = "$hfvhf";}
        else {
return $hfvhf;
             }
					 }

if ($value eq 'TAG' || $value eq 'ALL'){
        $offset=0x00;
        $address = $self->hexAdder("$offset","$base");
        my $tag;
        $output = $self->eepromDecode("$address");
        $output = substr($output,0,1);
        if ($output == '0') {$tag = "FREQUENCY";}
        if ($output == '1') {$tag = "LABEL";}
        if($verbose){print "MEMORY $type\[$subtype\] - Display Tag is $tag\n"};
        if ($value eq 'ALL'){$memoryhash{'TAG'} = "$tag";}
        else {
return $tag;
             }
                                       }

if ($value eq 'FREQRANGE' || $value eq 'ALL'){
        $offset=0x01;
        $address = $self->hexAdder("$offset","$base");
        my $freqrange;
        $output = $self->eepromDecode("$address");
        $output = substr($output,5,3);
        if ($output == '000') {$freqrange = "HF";}
        if ($output == '001') {$freqrange = "6M";}
        if ($output == '010') {$freqrange = "FM-BCB";}
        if ($output == '011') {$freqrange = "AIR";}
        if ($output == '100') {$freqrange = "2M";}
        if ($output == '101') {$freqrange = "UHF";}
        if($verbose){print "MEMORY $type\[$subtype\] - Frequency range is $freqrange\n"};
        if ($value eq 'ALL'){$memoryhash{'FREQRANGE'} = "$freqrange";}
        else {
return $freqrange;
             }
                                             }

if ($value eq 'NARFM' || $value eq 'ALL'){
        $offset=0x01;
        $address = $self->hexAdder("$offset","$base");
        my $narfm;
        $output = $self->eepromDecode("$address");
        $output = substr($output,4,1);
        if ($output == '0') {$narfm = "OFF";}
        if ($output == '1') {$narfm = "ON";}
        if($verbose){print "MEMORY $type\[$subtype\] - NARROW FM is $narfm\n"};
        if ($value eq 'ALL'){$memoryhash{'NARFM'} = "$narfm";}
        else {
return $narfm;
             }
                                         }

if ($value eq 'NARCWDIG' || $value eq 'ALL'){
        $offset=0x01;
        $address = $self->hexAdder("$offset","$base");
        my $narcw;
        $output = $self->eepromDecode("$address");
        $output = substr($output,3,1);
        if ($output == '0') {$narcw = "OFF";}
        if ($output == '1') {$narcw = "ON";}
        if($verbose){print "MEMORY $type\[$subtype\] - NARROW CW/DIG is $narcw\n"};
        if ($value eq 'ALL'){$memoryhash{'NARCWDIG'} = "$narcw";}
        else {
return $narcw;
             }
                                            }

if ($value eq 'UHF' || $value eq 'ALL'){
        $offset=0x01;
        $address = $self->hexAdder("$offset","$base");
        my $uhf;
        $output = $self->eepromDecode("$address");
        $output = substr($output,2,1);
        if ($output == '0') {$uhf = "NO";}
        if ($output == '1') {$uhf = "YES";}
        if($verbose){print "MEMORY $type\[$subtype\] - UHF $uhf\n"};
        if ($value eq 'ALL'){$memoryhash{'UHF'} = "$uhf";}
        else {
return $uhf;
             }
                                      }

if ($value eq 'RPTOFFSET' || $value eq 'ALL'){
        $offset=0x01;
        $address = $self->hexAdder("$offset","$base");
        my $rptoffset;
        $output = $self->eepromDecode("$address");
        $output = substr($output,0,2);
        if ($output == '00') {$rptoffset = "SIMPLEX";}
        if ($output == '01') {$rptoffset = "MINUS";}
        if ($output == '10') {$rptoffset = "PLUS";}
        if ($output == '11') {$rptoffset = "NON-STANDARD";}
        if($verbose){print "MEMORY $type\[$subtype\] - REPEATER OFFSET is $rptoffset\n"};
        if ($value eq 'ALL'){$memoryhash{'RPTOFFSET'} = "$rptoffset";}
        else {
return $rptoffset;
             }
                                            }

if ($value eq 'TONEDCS' || $value eq 'ALL'){
        $offset=0x04;
        $address = $self->hexAdder("$offset","$base");
        my $tonedcs;
        $output = $self->eepromDecode("$address");
        $output = substr($output,6,2);
        if ($output == '00') {$tonedcs = "OFF";}
        if ($output == '01') {$tonedcs = "TONE";}
        if ($output == '10') {$tonedcs = "TONETSQ";}
        if ($output == '11') {$tonedcs = "DCS";}
        if($verbose){print "MEMORY $type\[$subtype\] - TONE/DCS SELECT is $tonedcs\n"};
        if ($value eq 'ALL'){$memoryhash{'TONEDCS'} = "$tonedcs";}
        else {
return $tonedcs;
             }
                                           }

if ($value eq 'ATT' || $value eq 'ALL'){
        $offset=0x02;
        $address = $self->hexAdder("$offset","$base");
        my $att;
        $output = $self->eepromDecode("$address");
        $output = substr($output,3,1);
        if ($output == '0') {$att = "OFF";}
        if ($output == '1') {$att = "ON";}
        if($verbose){print "MEMORY $type\[$subtype\] - ATT is $att\n"};
        if ($value eq 'ALL'){$memoryhash{'ATT'} = "$att";}
        else {
return $att;
             }
                                      }

if ($value eq 'IPO' || $value eq 'ALL'){
        $offset=0x02;
        $address = $self->hexAdder("$offset","$base");
        my $ipo;
        $output = $self->eepromDecode("$address");
        $output = substr($output,2,1);
        if ($output == '0') {$ipo = "OFF";}
        if ($output == '1') {$ipo = "ON";}
        if($verbose){print "MEMORY $type\[$subtype\] - IPO is $ipo\n"};
        if ($value eq 'ALL'){$memoryhash{'IPO'} = "$ipo";}
        else {
return $ipo;
             }
                                      }

if ($value eq 'MEMSKIP' || $value eq 'ALL'){
        $offset=0x02;
        $address = $self->hexAdder("$offset","$base");
        my $memskip;
        $output = $self->eepromDecode("$address");
        $output = substr($output,0,1);
        if ($output == '0') {$memskip = "NO";}
        if ($output == '1') {$memskip = "YES";}
        if($verbose){print "MEMORY $type\[$subtype\] - MEMORY SKIP $memskip\n"};
        if ($value eq 'ALL'){$memoryhash{'MEMSKIP'} = "$memskip";}
        else {
return $memskip;
             }
                                           }

if ($value eq 'FMSTEP' || $value eq 'ALL'){
        $offset=0x03;
        $address = $self->hexAdder("$offset","$base");
        $output = $self->eepromDecode("$address");
        $output = substr($output,5,3);
        ($fmstep) = grep { $FMSTEP{$_} eq $output } keys %FMSTEP;
        if($verbose){print "MEMORY $type\[$subtype\] - FM STEP is $fmstep\n"};
        if ($value eq 'ALL'){$memoryhash{'FMSTEP'} = "$fmstep";}
        else {
return $fmstep;
             }
                                          }

if ($value eq 'AMSTEP' || $value eq 'ALL'){
        $offset=0x03;
        $address = $self->hexAdder("$offset","$base");
        $output = $self->eepromDecode("$address");
        $output = substr($output,2,3);
        ($amstep) = grep { $AMSTEP{$_} eq $output } keys %AMSTEP;
        if($verbose){print "MEMORY $type\[$subtype\] - AM STEP is $amstep\n"};
        if ($value eq 'ALL'){$memoryhash{'AMSTEP'} = "$amstep";}
        else {
return $amstep;
             }
                                          }

if ($value eq 'SSBSTEP' || $value eq 'ALL'){
        $offset=0x03;
        $address = $self->hexAdder("$offset","$base");
        my $ssbstep;
        $output = $self->eepromDecode("$address");
        $output = substr($output,0,2);
        if ($output == '00') {$ssbstep = '1.0';}
        if ($output == '01') {$ssbstep = '2.5';}
        if ($output == '10') {$ssbstep = '5.0';}
        if($verbose){print "MEMORY $type\[$subtype\] - SSB STEP is $ssbstep\n"};
        if ($value eq 'ALL'){$memoryhash{'SSBSTEP'} = "$ssbstep";}
        else {
return $ssbstep;
             }
                                           }

if ($value eq 'CTCSSTONE' || $value eq 'ALL'){
        $offset=0x06;
        my ($MSB, $LSB) = $self->hexAdder("$offset","$base");
        $output = $self->eepromDecode("$MSB","$LSB");
        $output = substr($output,2,6);
        my %newhash = reverse %CTCSSTONES;
        ($ctcsstone) = grep { $newhash{$_} eq $output } keys %newhash;
        if($verbose){print "MEMORY $type\[$subtype\] - CTCSS TONE is $ctcsstone\n"};
        if ($value eq 'ALL'){$memoryhash{'CTCSSTONE'} = "$ctcsstone";}
        else {
return $ctcsstone;
             }
                                             }

if ($value eq 'DCSCODE' || $value eq 'ALL'){
        $offset=0x07;
        $address = $self->hexAdder("$offset","$base");
        $output = $self->eepromDecode("$address");
        $output = substr($output,1,7);
        my %newhash = reverse %DCSCODES;
        ($dcscode) = grep { $newhash{$_} eq $output } keys %newhash;
        if($verbose){print "MEMORY $type\[$subtype\] - DCSCODE is $dcscode\n"};
        if ($value eq 'ALL'){$memoryhash{'DCSCODE'} = "$dcscode";}
        else {
return $dcscode;
             }
                                           }

if ($value eq 'CLARIFIER' || $value eq 'ALL'){
        $offset=0x02;
        $address = $self->hexAdder("$offset","$base");
        my $clarifier;
        $output = $self->eepromDecode("$address");
        $output = substr($output,1,1);
        if ($output == '1') {$clarifier = 'ON';}
        if ($output == '0') {$clarifier = 'OFF';}
        if($verbose){print "MEMORY $type\[$subtype\] - CLARIFIER is $clarifier\n"};
        if ($value eq 'ALL'){$memoryhash{'CLARIFIER'} = "$clarifier";}
        else {
return $clarifier;
             }
                                             }

if ($value eq 'CLAROFFSET' || $value eq 'ALL'){
        $offset=0x08;
        $address = $self->hexAdder("$offset","$base");
        my ($MSB,$LSB) = $self->eepromDoubledecode("$address");
        my $binvalue = join("","$MSB","$LSB");
        my $decvalue = oct("0b".$binvalue);
        my $newvalue;
        if ($decvalue > 999) {$newvalue = 65536 - $decvalue; $polarity = '-';}
        if ($decvalue >= 0 && $decvalue <= 999) {$newvalue = $decvalue; $polarity = '+';}
        my $vallength = length($newvalue);
                if ($vallength == 1) {$newvalue = join("","0.0","$newvalue");}
                       if ($vallength == 2) {$newvalue = join("","0.","$newvalue");}
                if ($vallength == 3) {
                        my $part1 = substr($newvalue,0,1);
                        my $part2 = substr($newvalue,1,2);
                        $newvalue = join("","$part1",".","$part2");
                                     }
                if ($vallength == 4) {
                        my $part1 = substr($newvalue,0,2);
                        my $part2 = substr($newvalue,2,2);
                        $newvalue = join("","$part1",".","$part2");
                                     }
                $newvalue = join("","$polarity","$newvalue");
        if($verbose){print "MEMORY $type\[$subtype\] - CLARIFIER OFFSET is $newvalue Khz\n";}
        if ($value eq 'ALL'){$memoryhash{'CLAROFFSET'} = "$newvalue";}
        else {
return $newvalue;
             }
                                            }

if ($value eq 'RXFREQ' || $value eq 'ALL'){
        $offset=0x0A;
        $address = $self->hexAdder("$offset","$base");
        my ($ADD1,$ADD2) = $self->eepromDoubledecode("$address");
        $offset=0x0C;
        $address = $self->hexAdder("$offset","$base");
        my ($ADD3,$ADD4) = $self->eepromDoubledecode("$address");
        my $binvalue = join("","$ADD1","$ADD2","$ADD3","$ADD4");
        my $decvalue = oct("0b".$binvalue);
        substr($decvalue, -2, 0) = '.';
        substr($decvalue, -6, 0) = '.';
        if($verbose){print "MEMORY $type\[$subtype\] - RECEIVE FREQUENCY is $decvalue Mhz\n";}
        if ($value eq 'ALL'){$memoryhash{'RXFREQ'} = "$decvalue";}
        else {
return $decvalue;
             }
                                         }

if ($value eq 'RPTOFFSETFREQ' || $value eq 'ALL'){
        $offset=0x0F;
        $address = $self->hexAdder("$offset","$base");
        my ($ADD1,$ADD2) = $self->eepromDoubledecode("$address");
        $offset=0x11;
        my $address = $self->hexAdder("$offset","$base");
        my $ADD3 = $self->eepromDecode("$address");
        my $binvalue = join("","$ADD1","$ADD2","$ADD3");
        my $decvalue = oct("0b".$binvalue);
        $decvalue = $decvalue / 100000;
       if($verbose){print "MEMORY $type\[$subtype\] - REPEATER OFFSET is $decvalue Mhz\n";}
        if ($value eq 'ALL'){$memoryhash{'RPTOFFSETFREQ'} = "$decvalue";}
        else {
return $decvalue;
             }
                                                 }

if ($value eq 'LABEL' || $value eq 'ALL'){
	my $cycles = 0x00;
	my $offset = 0x12;
	my $newaddress;
	my $label;
        $address = $self->hexAdder("$offset","$base");
    do {
        $newaddress = $self->hexAdder("$cycles","$address");
        my ($ADD,$ADD2) = $self->eepromDoubledecode("$newaddress");
        my $decvalue = oct("0b".$ADD);
	my $decvalue2 = oct("0b".$ADD2);
	my $letter = chr($decvalue);
	my $letter2 = chr($decvalue2);
	$cycles = $cycles + 2;
	$label .= "$letter"."$letter2";
        }
    while ($cycles < 8);
	if (!$label){$label = '\-BLANK\-';} 
        if($verbose){print "MEMORY $type\[$subtype\] - LABEL is $label\n";}
        if ($value eq 'ALL'){$memoryhash{'LABEL'} = "$label";}
        else {
return $label;
             }
                                         }
if ($value eq 'ALL'){
return %memoryhash;
                    }
   	       }

# 1922 - 1927 ################################# GET ID for CWID ######
###################################### 
sub getId {
        my $self=shift;
	my $address = 1922; 
	my $cycles = 0x00;
	my $cycles2;
	my $id;
	my $letter;
	my $letter2;
	my $hexvalue;
	my $hexvalue2;
	my %newhash = reverse %CWID;
    do {
        my $newaddress = $self->hexAdder("$cycles","$address");
        my ($ADD,$ADD2) = $self->eepromDoubledecode("$newaddress");
        my $hexvalue = sprintf("%X", oct( "0b$ADD" ) );
        my $hexvalue2 = sprintf("%X", oct( "0b$ADD2" ) );
        ($letter) = grep { $newhash{$_} eq $hexvalue } keys %newhash;
        ($letter2) = grep { $newhash{$_} eq $hexvalue2 } keys %newhash;
        $cycles = $cycles + 2;
        $id .= "$letter"."$letter2";
        }
    while ($cycles < 6);
        my ($ADD,$ADD2) = $self->eepromDoubledecode('1927');		
        $hexvalue2 = sprintf("%X", oct( "0b$ADD2" ) );
        ($letter2) = grep { $newhash{$_} eq $hexvalue2 } keys %newhash;
        $id .= "$letter2";
        if($verbose){print "CW ID is $id\n";}
return $id;
          }

#################################
# WRITE VALUES FROM EEPROM ADDR #
#################################

# 07-52 ################################# RESTORES SOFTCAL ######
###################################### ALL BITS

sub rebuildSoftcal {
	my $self=shift;        
	my $calfile=shift;
	my ($cal_line) =@_;
	my $error;
        if ($writeallow != '1' and $agreewithwarning != '1') {
                if($debug || $verbose){print"Writing to EEPROM disabled, use setWriteallow(1) to enable\n";}
return 1;
							     }

	if (!$calfile) {
		if ($verbose){print "No filename given, using default (FT817.cal)\n";}
		$calfile = 'FT817.cal';	
		       }
        open(CALFILE, "$calfile") or $error = '1';
	if ($error){
                if ($verbose){print "Failed to open file($calfile)\n";}
return 1;
		   }
	else {
	print "\n";
	my @caldata = <CALFILE>;
	my $linecount = 1;
	$error = undef;
	my @ln;
	our $writestatus = undef;
        my $cal_value = "$cal_line";
	if ($verbose){print "Validating file [$calfile]: ";}
	foreach $cal_line (@caldata) {
	my $test = substr($cal_line,0,2);
		if ($test ne '00'){next;}
                @ln=split(" ",$cal_line);
	if (length($ln[0]) + length($ln[3]) != 6){if($verbose){print "Error on line $linecount\n";} $error = 1;} 
                $linecount++;
                                     } 
	if ($linecount != '77'){$error = 1;}
	if ($error){
		if($verbose){print"Errors were found in the CAL file $calfile. Will not Process it!";}
return 1;
		   }
	else {
		my $skip = 0;
		my @line1;
		my @line2;
		if($verbose){print "---> [OK]\n\n";}
		$linecount = 1;
		$error = undef;
		if($verbose){print "Writing out 38 blocks to the radio. Do not power the unit off!!!!\n";}
        	foreach $cal_line (@caldata) {
        	my $test = substr($cal_line,0,2);
                if ($test ne '00'){next;}
                if ($skip == 0){@line1=split(" ",$cal_line);$skip = 1; next;}
		if ($skip == 1){@line2=split(" ",$cal_line);$skip = 0;}
		if($verbose){printf "%-2s %-8s %-5s %-5s", "$linecount",'of 38  WRITING',"\[$line1[3]\] --> $line1[0] \&","\[$line2[3]\] --> $line2[0] ";
		print " [OK]\n";}
                $writestatus = $self->writeDoubleblock("$line1[0]","$line1[3]","$line2[3]");		
		if ($writestatus ne 'OK'){$error = 1;}
                $linecount++;
                                             }
	     }
        if(!$error){
		if($verbose){print "\nSoftware calibration Loaded from $calfile sucessfull.\n";}
return 0;
	           }
	else { if($verbose){print "\nSoftware calibration Loaded from $calfile failed.\n";}
return 1;
                   }
            }
               }

##########################################################TEMPORARY LOCATION LOADCONFIG
sub loadConfig {

        my $self=shift;
        my $cfgfile=shift;
        my ($cfg_line) =@_;
        my $error;
        if ($writeallow != '1' and $agreewithwarning != '1') {
                if($debug || $verbose){print"Writing to EEPROM disabled, use setWriteallow(1) to enable\n";}
return 1;
                                                             }
        if (!$cfgfile) {
                if ($verbose){print "No filename given, using default (FT817.cfg)\n";}
                $cfgfile = 'FT817.cfg';
                       }
        open(CFGFILE, "$cfgfile") or $error = '1';
        if ($error){
                if ($verbose){print "Failed to open file($cfgfile)\n";}
return 1;
                   }

        else {
        print "\n";
        my @cfgdata = <CFGFILE>;
        my $linecount = 1;
        $error = undef;
        my @ln;
        our $writestatus = undef;
        my $cfg_value = "$cfg_line";
        if ($verbose){print "Validating file [$cfgfile]: ";}
        foreach $cfg_line (@cfgdata) {
	        my $test = substr($cfg_line,0,2);
        	if ($test < 1){next;}
        	@ln=split(" ",$cfg_line);
        	if (!$ln[0] && !$ln[1] && !$ln[2]){if($verbose){print "Error on line $linecount\n";} $error = 1;}
                $linecount++;
                                     }
        if ($linecount != '50'){$error = 1;}
        if ($error){
                if($verbose){print"Errors were found in the CFG file $cfgfile. Will not Process it!";}
return 1;
                   }
       else {
                if($verbose){print "---> [OK]\n\n";}
                $linecount = 1;
                $error = undef;
                if($verbose){print "Writing out 50 configurations to the radio. Do not power the unit off!!!!\n\n";}
                foreach $cfg_line (@cfgdata) {
                my $test = substr($cfg_line,0,2);
                if ($test < 1){next;}
                @ln=split(" ",$cfg_line);
		$ln[1] = substr("$ln[1]",3);
                if($verbose){printf "%-2s %-11s %-12s %-9s %-11s %-1s", "\[$ln[0]\]",'to 57  WRITING',"\[$ln[2]\]", "TO -->", "$ln[1]"," ";
                print " [OK]\n";}
		$ln[1] = join("",'set',"$ln[1]");
		my $command = $ln[1];
		my $value = $ln[2];
                $self->setVerbose(0);
                $self->$command("$value");
                $self->setVerbose(1);
		print "\n";
                $linecount++;
                                             }
             }
                if($verbose){print "\nConfiguration Loaded from $cfgfile sucessfull.\n";}
return 0;
            }
	       }

##########################################################TEMPORARY LOCATION SAVEMEMORY

sub saveMemory {
        my $self=shift;
        my $value=shift;
        my $localtime = localtime();
	my $currentmem = 1;
        if (!$value) {if($verbose){print"\nNo filename given using default filename FT817.mem\n";}$value = 'FT817.mem';}
        if (-e $value) {unlink $value;}
        open  FILE , ">>", "$value" or print"Can't open $value. error\n";
        print FILE "FT817 Memory Backup\nUsing FT817COMM.pm version $VERSION\n";
        print FILE "Created $localtime\n";
        print FILE "Using FT817OS Format, Do not modify this file\n\n";
        printf FILE "%-11s %-2s\n", 'ADDRESS', 'VALUE';
        if($verbose){print"Saving Memory....\n";}

        $self->setVerbose(0);
   do {
	my $ready = $self->readMemory('MEM',"$currentmem",'READY');
	if ($ready eq 'YES'){
	       my %baseaddress;
	       my $base;
	       my $multiple;
	       %baseaddress = reverse %MEMORYBASE;
	       ($base) = grep { $baseaddress{$_} eq 'MEM' } keys %baseaddress;
	       if ($currentmem > 1) {
               $multiple = ($currentmem - 1) * 26;
               $base = $self->hexAdder("$multiple","$base");
              		            }
		my $cycles = 0x00;
		my $offset = 0x00;
        	my $address = $self->hexAdder("$offset","$base");
                printf FILE "%-11s", "$currentmem";
   do {
		my $newaddress;
        	my $HEXVALUE = $NEWMEM["$cycles"];
        	if($verbose){print $cycles + 1;print " of 26 BYTES READ\n";}
        	$newaddress = $self->hexAdder("$cycles","$address");
                my ($val,$val2) = $self->eepromDoubledecode("$newaddress");
		my $valuehex = sprintf("%X", oct( "0b$val" ) );
                my $valuehex2 = sprintf("%X", oct( "0b$val2" ) );
                my $size = length($valuehex);
                if ($size < 2){$valuehex = join("",'0',"$valuehex");}
                $size = length($valuehex2);
                if ($size < 2){$valuehex2 = join("",'0',"$valuehex2");}
                printf FILE "%-2s", "$valuehex:$valuehex2:";
        	$cycles = $cycles + 2;
      } while ($cycles < 26);
		print FILE "\n";
					    }	
 	        $currentmem ++;	
      } while ($currentmem != 203);
                print FILE "\n\n---END OF Memory Settings---\n";
                close FILE;
        $self->setVerbose(1);
	if($verbose){print"Memory Saved to $value\n";}
return 0;
               }

##########################################################TEMPORARY LOCATION LOADMEMORY

sub loadMemory {
        my $self=shift;
        my $memfile=shift;
        my ($mem_line) =@_;
        my $error;
	my $linecount = 1;
	my $totallines;
        if ($writeallow != '1' and $agreewithwarning != '1') {
                if($debug || $verbose){print"Writing to EEPROM disabled, use setWriteallow(1) to enable\n";}
return 1;
                                                             }
        if (!$memfile) {
                if ($verbose){print "No filename given, using default (FT817.mem)\n";}
                $memfile = 'FT817.mem';
                       }
        open(MEMFILE, "$memfile") or $error = '1';
        if ($error){
                if ($verbose){print "Failed to open file($memfile)\n";}
return 1;
                   }

        else {
        print "\n";
        my @memdata = <MEMFILE>;
        $error = undef;
        my @ln;
	my @hexvalues;
        our $writestatus = undef;
        my $mem_value = "$mem_line";
        if ($verbose){print "Validating file [$memfile]: ";}
        foreach $mem_line (@memdata) {
		my $testnumber;
                my $test = substr($mem_line,0,3);
                if ($test < 1){next;}
                @ln=split(" ",$mem_line);
                if (!$ln[0] && !$ln[1]){if($verbose){print "Error on line $linecount\n";} $error = 1;}
                @hexvalues=split(':',$ln[1]);
		$testnumber = scalar @hexvalues;
		if ($testnumber != '26'){if($verbose){print "Error on line $linecount\n";} $error = 1;}
                $linecount++;
                                     }
        if ($error){
                if($verbose){print"Errors were found in the MEM file $memfile. Will not Process it!";}
return 1;
                   }
		 if($verbose){print "---> \[OK\]\n";}
		$totallines = $linecount - 1;
                if($verbose){print "Writing out $totallines memory areas to the radio. Do not power the unit off!!!!\n\n";}
                my %baseaddress;
                my $multiple;
		my $base;
                %baseaddress = reverse %MEMORYBASE;
                ($base) = grep { $baseaddress{$_} eq 'MEM' } keys %baseaddress;
			my $newbase = $base;
        		foreach $mem_line (@memdata) {
                	my $test = substr($mem_line,0,3);
                	if ($test < 1){next;}
                	@ln=split(" ",$mem_line);
                	if ($ln[0] > 1) {
                		$multiple = ($ln[0] - 1) * 26;
                		$newbase = $self->hexAdder("$multiple","$base");
                                	}
		my $cycles = 0x00;
		my $cycles2 = $cycles + 1;
                my $offset = 0x00;
		my $data_line;
		my $error = undef;
                my $address = $self->hexAdder("$offset","$newbase");
		if($verbose){print "Writing memory area \[$ln[0]\]  ";}
		my @memorydata = split(':',$ln[1]);
   do {
			my $newaddress;
			$newaddress = $self->hexAdder("$cycles","$address");
			$writestatus = $self->writeDoubleblock("$newaddress","$memorydata[$cycles]","$memorydata[$cycles2]");			     
			if ($writestatus ne 'OK'){if($verbose){print "---> FAILED"; $error = 1;}}
		$cycles = $cycles + 2;
		$cycles2 = $cycles + 1;
      } while ($cycles < 26);
		if (!$error) {if($verbose){print "---> \[OK\]";}}
		print "\n";
						     }
        if(!$error){
                if($verbose){print "\nMemory Loaded from $memfile sucessfull.\n";}
return 0;
                   }
       else { if($verbose){print "\nMemory Loaded from $memfile failed.\n";}
return 1;
                   }

             }

return 0;
	       }
##########################################################TEMPORARY LOCATION SAVECONFIG

sub saveConfig {
        my $self=shift;
        my $value=shift;
        my $localtime = localtime();
        if (!$value) {if($verbose){print"\nNo filename given using default filename FT817.cfg\n";}$value = 'FT817.cfg';}
        $localtime = localtime();
        if (-e $value) {unlink $value;}
        	open  FILE , ">>", "$value" or print"Can't open $value. error\n";
                print FILE "FT817 Config Backup\nUsing FT817COMM.pm version $VERSION\n";
                print FILE "Created $localtime\n";
                print FILE "Using FT817OS Format, Do not modify this file\n\n";
                printf FILE "%-11s %-15s %-15s\n", 'NUMBER', 'TYPE', 'VALUE';
         	$self->setVerbose(0);
                printf FILE  "%-11s %-15s %-7s\n", '1', 'getArs144', $self->getArs144();
                printf FILE  "%-11s %-15s %-7s\n", '2', 'getArs430', $self->getArs430();
		printf FILE  "%-11s %-15s %-7s\n", '3', 'get9600mic', $self->get9600mic();
		printf FILE  "%-11s %-15s %-7s\n", '4', 'getAmfmdial', $self->getAmfmdial();
                printf FILE  "%-11s %-15s %-7s\n", '5', 'getAmmic', $self->getAmmic();
                printf FILE  "%-11s %-15s %-7s\n", '8', 'getApotime', $self->getApotime();
                printf FILE  "%-11s %-15s %-7s\n", '9', 'getArtsmode', $self->getArtsmode();
                printf FILE  "%-11s %-15s %-7s\n", '10', 'getBacklight', $self->getBacklight();
                printf FILE  "%-11s %-15s %-7s\n", '11', 'getChargetime', $self->getChargetime();
                printf FILE  "%-11s %-15s %-7s\n", '12', 'getBeepfreq', $self->getBeepfreq();
                printf FILE  "%-11s %-15s %-7s\n", '13', 'getBeepvol', $self->getBeepvol();
                printf FILE  "%-11s %-15s %-7s\n", '14', 'getCatrate', $self->getCatrate();
                printf FILE  "%-11s %-15s %-7s\n", '15', 'getColor', $self->getColor();
                printf FILE  "%-11s %-15s %-7s\n", '16', 'getContrast', $self->getContrast();
                printf FILE  "%-11s %-15s %-7s\n", '17', 'getCwdelay', $self->getCwdelay();
                printf FILE  "%-11s %-15s %-7s\n", '18', 'getCwid', $self->getCwid();
                printf FILE  "%-11s %-15s %-7s\n", '19', 'getCwpaddle', $self->getCwpaddle();
                printf FILE  "%-11s %-15s %-7s\n", '20', 'getCwpitch', $self->getCwpitch();
                printf FILE  "%-11s %-15s %-7s\n", '21', 'getCwspeed', $self->getCwspeed();
                printf FILE  "%-11s %-15s %-7s\n", '22', 'getCwweight', $self->getCwweight('1');
                printf FILE  "%-11s %-15s %-7s\n", '24', 'getDigdisp', $self->getDigdisp();
                printf FILE  "%-11s %-15s %-7s\n", '25', 'getDigmic', $self->getDigmic();
                printf FILE  "%-11s %-15s %-7s\n", '26', 'getDigmode', $self->getDigmode();
                printf FILE  "%-11s %-15s %-7s\n", '27', 'getDigshift', $self->getDigshift();
                printf FILE  "%-11s %-15s %-7s\n", '28', 'getEmergency', $self->getEmergency();
                printf FILE  "%-11s %-15s %-7s\n", '29', 'getFmmic', $self->getFmmic();
                printf FILE  "%-11s %-15s %-7s\n", '31', 'getId', $self->getId();
                printf FILE  "%-11s %-15s %-7s\n", '32', 'getLockmode', $self->getLockmode();
                printf FILE  "%-11s %-15s %-7s\n", '33', 'getMainstep', $self->getMainstep();
                printf FILE  "%-11s %-15s %-7s\n", '34', 'getMemgroup', $self->getMemgroup();
		printf FILE  "%-11s %-15s %-7s\n", '36', 'getMickey', $self->getMickey();
		printf FILE  "%-11s %-15s %-7s\n", '37', 'getMicscan', $self->getMicscan();
		printf FILE  "%-11s %-15s %-7s\n", '38', 'getOpfilter', $self->getOpfilter();
		printf FILE  "%-11s %-15s %-7s\n", '39', 'getPktmic', $self->getPktmic();
		printf FILE  "%-11s %-15s %-7s\n", '40', 'getPktrate', $self->getPktrate();
                printf FILE  "%-11s %-15s %-7s\n", '41', 'getResumescan', $self->getResumescan();
                printf FILE  "%-11s %-15s %-7s\n", '43', 'getScope', $self->getScope();
                printf FILE  "%-11s %-15s %-7s\n", '44', 'getSidetonevol', $self->getSidetonevol();
                printf FILE  "%-11s %-15s %-7s\n", '45', 'getRfknob', $self->getRfknob();
                printf FILE  "%-11s %-15s %-7s\n", '46', 'getSsbmic', $self->getSsbmic();
                printf FILE  "%-11s %-15s %-7s\n", '49', 'getTottime', $self->getTottime();
		printf FILE  "%-11s %-15s %-7s\n", '50', 'getVoxdelay', $self->getVoxdelay();
                printf FILE  "%-11s %-15s %-7s\n", '51', 'getVoxgain', $self->getVoxgain();
                printf FILE  "%-11s %-15s %-7s\n", '52', 'getExtmenu', $self->getExtmenu();
		printf FILE  "%-11s %-15s %-7s\n", '53', 'getDcsinv', $self->getDcsinv();
                printf FILE  "%-11s %-15s %-7s\n", '54', 'getRlsbcar', $self->getRlsbcar();
                printf FILE  "%-11s %-15s %-7s\n", '55', 'getRusbcar', $self->getRusbcar();
                printf FILE  "%-11s %-15s %-7s\n", '56', 'getTlsbcar', $self->getTlsbcar();
                printf FILE  "%-11s %-15s %-7s\n", '57', 'getTusbcar', $self->getTusbcar();
                print FILE "\n\n---END OF Config Settings---\n";
                close FILE;
        $self->setVerbose(1);
        if($verbose){print"Config Saved to $value\n";}
return 0;
	       }

# 55 ################################# SET VFO A/B , MEM OR VFO, MTUNE OR MEMORY,MTQMB, QMB, HOME ######
###################################### SET BITS 0,1,2,4,5 AND 7 FROM 0X55

sub setMtune {
        my $self=shift;
        my $value=shift;
        if ($value ne 'MTUNE' && $value ne 'MEMORY'){
                if($verbose){print "Value invalid: Choose MTUNE/MEMORY\n\n";}
return 1;
                                                    }
        $self->setVerbose(0);
        my $currentmtune = $self->getMtune();
        $self->setVerbose(1);
        if ($value eq $currentmtune){
                if($verbose){print "Value $currentmtune already selected.\n\n";}
return 1;
                                    }
        if($value eq 'MTUNE'){$writestatus = $self->writeEeprom('0055','2','1');}
        if($value eq 'MEMORY'){$writestatus = $self->writeEeprom('0055','2','0');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"MTUNE set to $value sucessfull!\n";}
                else {print"MTUNE set to $value failed!!!\n";}
                     }
return $writestatus;
            }

####################

sub setMtqmb {
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        my $currentmtqmb = $self->getMtqmb();
        $self->setVerbose(1);
        if ($value eq $currentmtqmb){
                if($verbose){print "Value $currentmtqmb already selected.\n\n"; }
return 1;
                                    }
        if($value eq 'ON'){$writestatus = $self->writeEeprom('0055','6','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0055','6','0');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"MTQMB set to $value sucessfull!\n";}
                else {print"MTQMB set to $value failed!!!\n";}
                     }
return $writestatus;
            }

####################

sub setQmb {
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        my $currentqmb = $self->getQmb();
        $self->setVerbose(1);
        if ($value eq $currentqmb){
                if($verbose){print "Value $currentqmb already selected.\n\n";}
return 1;
                                  }
        if($value eq 'ON'){$writestatus = $self->writeEeprom('0055','5','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0055','5','0');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"QMB set to $value sucessfull!\n";}
                else {print"QMB set to $value failed!!!\n";}
                     }
return $writestatus;
            }

####################

sub setHome {
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        my $currenthome = $self->getHome();
        $self->setVerbose(1);
        if ($value eq $currenthome){
                if($verbose){print "Value $currenthome already selected.\n\n"; }
return 1;
                                   }
        if($value eq 'ON'){$writestatus = $self->writeEeprom('0055','3','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0055','3','0');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"HOME set to $value sucessfull!\n";}
                else {print"HOME set to $value failed!!!\n";}
                     }
return $writestatus;
	    }

####################

sub setVfo {
        my $self=shift;
        my $value=shift;
        if ($value ne 'A' && $value ne 'B'){
                if($verbose){print "Value invalid: Choose A/B\n\n";}
return 1;
					   }
        $self->setVerbose(0);
        my $currentvfo = $self->getVfo();
        $self->setVerbose(1);
        if ($value eq $currentvfo){
                if($verbose){print "Value $currentvfo already selected.\n\n"; }
return 1;
				  }
        if($value eq 'A'){$writestatus = $self->writeEeprom('0055','7','0');}
        if($value eq 'B'){$writestatus = $self->writeEeprom('0055','7','1');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"VFO set to $value sucessfull!\n";}
                else {print"VFO set to $value failed!!!\n";}
                     }
return $writestatus;
	   }

####################

sub setTuner {
        my $self=shift;
        my $value=shift;
        if ($value ne 'MEMORY' && $value ne 'VFO'){
                if($verbose){print "Value invalid: Choose MEMORY/VFO\n\n";}
return 1;
    					  	  }
        $self->setVerbose(0);
        my $currenttuner = $self->getTuner();
        $self->setVerbose(1);
        if ($value eq $currenttuner){
                if($verbose){print "Value $currenttuner already selected.\n\n"; }
return 1;
                                    }
        if($value eq 'MEMORY'){$writestatus = $self->writeEeprom('0055','1','1');}
        if($value eq 'VFO'){$writestatus = $self->writeEeprom('0055','1','0');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"TUNER set to $value sucessfull!\n";}
		else {print"TUNER set to $value failed!!!\n";}
                     }
return $writestatus;
	 }

# 57 ################################# SET AGC MODE, NOISE BLOCK, FASTTUNE , DSP AND LOCK ######
###################################### READ BITS 0-1 , 2, 5 AND 6 FROM 0X57

sub setAgc {
        my $self=shift;
	my $value=shift;
        if ($value ne 'AUTO' && $value ne 'SLOW' && $value ne 'FAST' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose AUTO/SLOW/FAST/OFF\n\n";}
return 1;
                                                                                        }
        $self->setVerbose(0);
        my $currentagc = $self->getAgc();
        $self->setVerbose(1);
        if ($value eq $currentagc){
                if($verbose){print "Value $currentagc already selected.\n\n";}
return 1;
                                  }
        my $BYTE1 = $self->eepromDecode('0057');
        if ($value eq 'OFF'){substr ($BYTE1, 6, 2, '11');}
        if ($value eq 'SLOW'){substr ($BYTE1, 6, 2, '10');}
        if ($value eq 'FAST'){substr ($BYTE1, 6, 2, '01');}
        if ($value eq 'AUTO'){substr ($BYTE1, 6, 2, '00');}
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('0057',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"AGC Set to $value sucessfull!\n";}
                else {print"AGC set failed: $writestatus\n";}
                    }
return $writestatus;
           }

####################

sub setNb {
        my ($currentnb) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        $currentnb = $self->getNb();
        $self->setVerbose(1);
        if ($value eq $currentnb){
                if($verbose){print "Value $currentnb already selected.\n\n";}
return 1;
                                 }
        if($value eq 'ON'){$writestatus = $self->writeEeprom('0057','2','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0057','2','0');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"Noise Block set to $value sucessfull!\n";}
                else {print"Noise Block set to $value failed!!!\n";}
                     }
return $writestatus;
           }

####################

sub setDsp {
        my ($currentdsp) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        $currentdsp = $self->getDsp();
        $self->setVerbose(1);
        if ($value eq $currentdsp){
                if($verbose){print "Value $currentdsp already selected.\n\n";}
return 1;
                                  }
        if($value eq 'ON'){$writestatus = $self->writeEeprom('0057','5','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0057','5','0');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"DSP set to $value sucessfull!\n";}
                else {print"DSP set to $value failed!!!\n";}
                     }
return $writestatus;
           }

####################

sub setPbt {
        my ($currentpbt) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        $currentpbt = $self->getPbt();
        $self->setVerbose(1);
        if ($value eq $currentpbt){
                if($verbose){print "Value $currentpbt already selected.\n\n";}
return 1;
                                  }
        if($value eq 'ON'){$writestatus = $self->writeEeprom('0057','3','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0057','3','0');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"Pass Band Tuning set to $value sucessfull!\n";}
                else {print"Pass Band Tuning set to $value failed!!!\n";}
                     }
return $writestatus;
           }

####################

sub setLock {
        my ($currentlock) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        $currentlock = $self->getLock();
        $self->setVerbose(1);
        if ($value eq $currentlock){
                if($verbose){print "Value $currentlock already selected.\n\n";}
return 1;
                                   }
        if($value eq 'ON'){$writestatus = $self->writeEeprom('0057','1','0');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0057','1','1');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"Lock set to $value sucessfull!\n";}
                else {print"Lock set to $value failed!!!\n";}
                     }
return $writestatus;
           }

####################

sub setFasttuning {
        my ($currenttuning) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        $currenttuning = $self->getFasttuning();
        $self->setVerbose(1);
        if ($value eq $currenttuning){
                if($verbose){print "Value $currenttuning already selected.\n\n";}
return 1;
                                     }
        if($value eq 'ON'){$writestatus = $self->writeEeprom('0057','0','0');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0057','0','1');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"Fast Tuning set to $value sucessfull!\n";}
                else {print"Fast Tuning set to $value failed!!!\n";}
                     }
return $writestatus;
           }

# 58 ################################# SET PWR MTR MODE, CW PADDLE, KYR, BK, VLT, VOX ######
###################################### CHANGE BIT 0-1,2,4,5,6,7 FROM 0X58

sub setPwrmtr {
        my $self=shift;
        my $value=shift;
        if ($value ne 'PWR' && $value ne 'ALC' && $value ne 'SWR' && $value ne 'MOD'){
                if($verbose){print "Value invalid: Choose PWR/ALC/SWR/MOD\n\n"; }
return 1;
                                                                                     }
        $self->setVerbose(0);
        my $currentpwrmtr = $self->getPwrmtr();
        $self->setVerbose(1);
        if ($value eq $currentpwrmtr){
                if($verbose){print "Value $currentpwrmtr already selected.\n\n";}
return 1;
                                     }
        my $BYTE1 = $self->eepromDecode('0058');
        if ($value eq 'PWR'){substr ($BYTE1, 6, 2, '00');}
        if ($value eq 'ALC'){substr ($BYTE1, 6, 2, '01');}
        if ($value eq 'SWR'){substr ($BYTE1, 6, 2, '10');}
        if ($value eq 'MOD'){substr ($BYTE1, 6, 2, '11');}
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('0058',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"Power Meter set to $value sucessfull!\n";}
                else {print"Power Meter set failed: $writestatus\n";}
                    }
return $writestatus;
               }

########################

sub setCwpaddle {
        my ($currentcwpaddle) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'NORMAL' && $value ne 'REVERSE'){
                if($verbose){print "Value invalid: Choose NORMAL/REVERSE\n\n";}
return 1;
                                                      }
        $self->setVerbose(0);
        $currentcwpaddle = $self->getCwpaddle();
        $self->setVerbose(1);
        if ($value eq $currentcwpaddle){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                       }
        if($value eq 'NORMAL'){$writestatus = $self->writeEeprom('0058','5','0');}
        if($value eq 'REVERSE'){$writestatus = $self->writeEeprom('0058','5','1');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"CW Paddle set to $value sucessfull!\n";}
                else {print"CW Paddle set to $value failed!!!\n";}
                     }
return $writestatus;
           }

########################

sub setKyr {
        my ($currentkyr) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        $currentkyr = $self->getKyr();
        $self->setVerbose(1);
        if ($value eq $currentkyr){
                if($verbose){print "Value $value already selected.\n\n"; }
return 1;
                                  }
        if($value eq 'ON'){$writestatus = $self->writeEeprom('0058','3','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0058','3','0');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"Keyer (KYR) set to $value sucessfull!\n";}
                else {print"Keyer (KYR) set to $value failed!!!\n";}
                     }
return $writestatus;
           }

########################

sub setBk {
        my ($currentbk) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        $currentbk = $self->getBk();
        $self->setVerbose(1);
        if ($value eq $currentbk){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                 }
        if($value eq 'ON'){$writestatus = $self->writeEeprom('0058','2','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0058','2','0');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"Break-in (BK) set to $value sucessfull!\n";}
                else {print"Break-in (BK) set to $value failed!!!\n";}
                     }
return $writestatus;
           }

########################

sub setVlt {
        my ($currentvlt) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        $currentvlt = $self->getVlt();
        $self->setVerbose(1);
        if ($value eq $currentvlt){
                if($verbose){print "Value $value already selected.\n\n"; }
return 1;
                                  }
        if($value eq 'ON'){$writestatus = $self->writeEeprom('0058','1','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0058','1','0');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"Voltage readout set to $value sucessfull!\n";}
                else {print"Voltage readout set to $value failed!!!\n";}
                     }
return $writestatus;
          }

########################

sub setVox {
        my ($currentvox) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        $currentvox = $self->getVox();
        $self->setVerbose(1);
        if ($value eq $currentvox){
                if($verbose){print "Value $currentvox already selected.\n\n";}
return 1;
                                  }
        if($value eq 'ON'){$writestatus = $self->writeEeprom('0058','0','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0058','0','0');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"VOX set to $value sucessfull!\n";}
                else {print"VOX set to $value failed!!!\n";}
                     }
return $writestatus;
           }

# 59 ################################# SET VFOBAND ######
###################################### CHANGE ALL BITS FROM 0X59

sub setVfoband {
        my ($currentband, $writestatus, $vfoband, $testvfoband) = @_;
        my $self=shift;
        my $vfo=shift;
        my $value=shift;
        if ($vfo ne 'A' && $vfo ne 'B'){
                if($verbose){print "Value invalid: Choose VFO A/B\n\n";}
return 1;
                                       }
        my %newhash = reverse %VFOBANDS;
        ($testvfoband) = grep { $newhash{$_} eq $value } keys %newhash;
        if ($testvfoband eq'') {
                if($verbose){print "\nChoose valid Band : [160M/75M/40M/30M/20M/17M/15M/12M/10M/6M/2M/70CM/FMBC/AIR/PHAN]\n\n";}
return 1;
                               }
        $self->setVerbose(0);
        $currentband = $self->getVfoband("$vfo");
        $self->setVerbose(1);
        if ($currentband eq $value) {
                if($verbose){print "\nBand $currentband already selected for VFO $vfo\n\n";}
return 1;
                                    }
        my $BYTE1 = $self->eepromDecode('0059');
        if ($vfo eq 'A'){substr ($BYTE1, 4, 4, "$testvfoband");}
        if ($vfo eq 'B'){substr ($BYTE1, 0, 4, "$testvfoband");}
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
         $writestatus = $self->writeBlock('0059',"$NEWHEX");
        if ($verbose){
                if ($writestatus eq 'OK') {print"BAND $currentband on VFO $vfo set sucessfull!\n";}
                else {print"BAND $currentband on VFO $vfo set failed!!!\n";}
                     }
return $writestatus;
               }

# 5B ################################# SET CONTRAST, COLOR, BACKLIGHT
######################################  BITS 0-3,4, 6-7 FROM ADDRESS 0X5B
 
sub setContrast {
        my ($currentcontrast) = @_;
        my $self=shift;
        my $value=shift;
        if ($value < 1 || $value > 12){
                if($verbose){print "Value invalid: Choose a number between 1 and 12\n\n"; }
return 1;
                                      }
        $self->setVerbose(0);
        $currentcontrast = $self->getContrast();
        $self->setVerbose(1);
        if ($value eq $currentcontrast){
                if($verbose){print "Value $currentcontrast already selected.\n\n"; }
return 1;
                                       }
	my $firstvalue = $value;
	$value++;
	my $binvalue = dec2bin($value);
        my $BYTE1 = $self->eepromDecode('005B');
	$binvalue = substr("$binvalue", 4);
        substr ($BYTE1, 4, 4, "$binvalue");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('005B',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"Contrast set to $firstvalue sucessfull!\n";}
                else {print"Contrast set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

####################

sub setColor {
        my ($currentcolor) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'BLUE' && $value ne 'AMBER'){
                if($verbose){print "Value invalid: Choose BLUE/AMBER\n\n"; }
return 1;
                                                  }
        $self->setVerbose(0);
        $currentcolor = $self->getColor();
        $self->setVerbose(1);
        if ($currentcolor eq $value) {
                if($verbose){print "Setting $value already selected for Screen Color\n\n";}
return 1;
                                     }
        if($value eq 'BLUE'){$writestatus = $self->writeEeprom('005B','3','0');}
        if($value eq 'AMBER'){$writestatus = $self->writeEeprom('005B','3','1');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"Screen color set to $value sucessfull!\n";}
                else {print"Screen Color set to $value failed!!!\n";}
                     }
return $writestatus;
                  }

####################

sub setBacklight {
        my ($currentbacklight) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'OFF' && $value ne 'ON' && $value ne 'AUTO'){
                if($verbose){print "Value invalid: Choose OFF/ON/AUTO\n\n";}
return 1;
                                                                  }
        $self->setVerbose(0);
        $currentbacklight = $self->getBacklight();
        $self->setVerbose(1);
        if ($value eq $currentbacklight){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                        }
        my $BYTE1 = $self->eepromDecode('005B');
        if ($value eq 'OFF'){substr ($BYTE1, 0, 2, '00');}
        if ($value eq 'ON'){substr ($BYTE1, 0, 2, '01');}
        if ($value eq 'AUTO'){substr ($BYTE1, 0, 2, '10');}
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('005B',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"Back Light Set to $value sucessfull!\n";}
                else {print"Back Light set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

# 5C ################################# SET BEEP VOL , BEEP FREQ ######
######################################  BITS 0-6, 7 FROM 0X5C

sub setBeepvol {
        my ($currentbeepvol) = @_;
        my $self=shift;
        my $value=shift;
        if ($value < 0 || $value > 100){
                if($verbose){print "Value invalid: Choose (0 - 100)\n\n";}
return 1;
                                       }
        $self->setVerbose(0);
        $currentbeepvol = $self->getBeepvol();
        $self->setVerbose(1);
        if ($value eq $currentbeepvol){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                      }
        my $binvalue = dec2bin($value);
        my $BYTE1 = $self->eepromDecode('005C');
        $binvalue = substr("$binvalue", 1);
        substr ($BYTE1, 1, 7, "$binvalue");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('005C',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"Beep Volume Set to $value sucessfull!\n";}
                else {print"Beep Volume set failed: $writestatus\n";}
                $writestatus = 'ERROR';
                    }
return $writestatus;
                 }

####################

sub setBeepfreq {
        my ($currentbeepfreq) = @_;
        my $self=shift;
        my $value=shift;
        if ($value == '440' && $value == '880'){
                if($verbose){print "Value invalid: Choose 440/880\n\n";}
return 1;
                                               }
        $self->setVerbose(0);
        $currentbeepfreq = $self->getBeepfreq();
        $self->setVerbose(1);
        if ($currentbeepfreq eq $value) {
                if($verbose){print "Setting $value already selected for Beep Frequency\n\n";}
return 1;
                                        }
        if($value == '440'){$writestatus = $self->writeEeprom('005C','0','0');}
        if($value == '880'){$writestatus = $self->writeEeprom('005C','0','1');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"Beep Frequency set to $value sucessfull!\n";}
                else {print"Beep Frequency set to $value failed!!!\n";}
                     }
return $writestatus;
                  }

# 5D ################################# SET RESUME SCAN, PKT RATE, SCOPE, CW-ID, MAIN STEP, ARTS MODE
######################################  BIT 0-1, 2, 3, 4, 5, 6-7 FROM ADDRESS 0X5D

sub setResumescan {
        my ($currentresumescan) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'OFF' && $value ne '3' && $value ne '5' && $value ne '10'){
                if($verbose){print "Value invalid: Choose OFF/3/5/10\n\n";}
return 1;
                                                                                }
        $self->setVerbose(0);
        $currentresumescan = $self->getResumescan();
        $self->setVerbose(1);
        if ($value eq $currentresumescan){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                         }
        my $BYTE1 = $self->eepromDecode('005D');
        if ($value eq 'OFF'){substr ($BYTE1, 0, 2, '00');}
        if ($value eq '3'){substr ($BYTE1, 6, 2, '01');}
        if ($value eq '5'){substr ($BYTE1, 6, 2, '10');}
        if ($value eq '10'){substr ($BYTE1, 6, 2, '11');}
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('005D',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"Resume (SCAN) Set to $value sucessfull!\n";}
                else {print"Resume (SCAN) set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

####################

sub setPktrate {
        my ($currentpktrate) = @_;
        my $self=shift;
        my $value=shift;
        if ($value != '1200' && $value != '9600'){
                if($verbose){print "Value invalid: Choose 1200/9600\n\n";}
return 1;
                                                 }
        $self->setVerbose(0);
        $currentpktrate = $self->getPktrate();
        $self->setVerbose(1);
        if ($currentpktrate eq $value) {
                if($verbose){print "Setting $value already selected for PKT Rate\n\n";}
return 1;
                                       }
        if($value == '1200'){$writestatus = $self->writeEeprom('005D','5','0');}
        if($value == '9600'){$writestatus = $self->writeEeprom('005D','5','1');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"PKT RATE set to $value sucessfull!\n";}
                else {print"PKT RATE set to $value failed!!!\n";}
                     }
return $writestatus;
                  }

####################

sub setScope {
        my ($currentscope) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'CONT' && $value ne 'CHK'){
                if($verbose){print "Value invalid: Choose CONT/CHK\n\n";}
return 1;
                                                }
        $self->setVerbose(0);
        $currentscope = $self->getScope();
        $self->setVerbose(1);
        if ($currentscope eq $value) {
                if($verbose){print "Setting $value already selected for Scope\n\n";}
return 1;
                                     }
        if($value eq 'CONT'){$writestatus = $self->writeEeprom('005D','4','0');}
        if($value eq 'CHK'){$writestatus = $self->writeEeprom('005D','4','1');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"Scope set to $value sucessfull!\n";}
                else {print"Scope set to $value failed!!!\n";}
                     }
return $writestatus;
                  }

####################

sub setCwid {
        my ($currentcwid) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        $currentcwid = $self->getCwid();
        $self->setVerbose(1);
        if ($currentcwid eq $value) {
                if($verbose){print "Setting $value already selected for CW-ID\n\n";}
return 1;
                                    }
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('005D','3','0');}
        if($value eq 'ON'){$writestatus = $self->writeEeprom('005D','3','1');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"CW-ID set to $value sucessfull!\n";}
                else {print"CW-ID set to $value failed!!!\n";}
                     }
return $writestatus;
                  }

####################

sub setMainstep {
        my ($currentmainstep) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'COURSE' && $value ne 'FINE'){
                if($verbose){print "Value invalid: Choose COURSE/FINE\n\n";}
return 1;
                                                   }
        $self->setVerbose(0);
        $currentmainstep = $self->getMainstep();
        $self->setVerbose(1);
        if ($currentmainstep eq $value) {
                if($verbose){print "Setting $value already selected for Main Step\n\n";}
return 1;
                                        }
        if($value eq 'FINE'){$writestatus = $self->writeEeprom('005D','2','0');}
        if($value eq 'COURSE'){$writestatus = $self->writeEeprom('005D','2','1');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"Main Step set to $value sucessfull!\n";}
                else {print"Main Step set to $value failed!!!\n";}
                     }
return $writestatus;
                  }

####################

sub setArtsmode {
        my ($chargebits, $currentartsmode) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'OFF' && $value ne 'ALL' && $value ne 'RANGE'){
                if($verbose){print "Value invalid: Choose OFF/ALL/RANGE\n\n";}
return 1;
								    }
        $self->setVerbose(0);
        $currentartsmode = $self->getArtsmode();
        $self->setVerbose(1);
        if ($value eq $currentartsmode){
                if($verbose){print "Value $currentartsmode already selected.\n\n";}
return 1;
                                       }
        my $BYTE1 = $self->eepromDecode('005D');
        if ($value eq 'OFF'){substr ($BYTE1, 0, 2, '00');}
        if ($value eq 'RANGE'){substr ($BYTE1, 0, 2, '01');}
        if ($value eq 'ALL'){substr ($BYTE1, 0, 2, '10');}
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('005D',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"ARTS Mode Set to $value sucessfull!\n";}
                else {print"ARTS Mode set failed: $writestatus\n";}
                $writestatus = 'ERROR';
                    }
return $writestatus;
		 }

# 5E ################################# SET CWPITCH, LOCK MODE, OP FILTER
######################################  BIT 0-3, 4-5 6-7 FROM ADDRESS 0X5E

sub setCwpitch {
        my ($currentcwpitch) = @_;
        my $self=shift;
        my $value=shift;
        if ($value < 300 || $value > 1000){
                if($verbose){print "Value invalid: Choose a number between 300 and 1000\n\n";}
return 1;
                                          }
        my $testvalue =  substr("$value", -2, 2);
        if (($testvalue != '00') && ($testvalue !='50')){
                if($verbose){print "Value invalid: Must be in incriments of 50\n\n";}
return 1;
                                                        }
        $self->setVerbose(0);
        $currentcwpitch = $self->getCwpitch();
        $self->setVerbose(1);
        if ($value eq $currentcwpitch){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                      }
        my $firstvalue = $value;
        $value = $value - 300;
	$value = $value / 50;
        my $binvalue = dec2bin($value);
        my $BYTE1 = $self->eepromDecode('005E');
        $binvalue = substr("$binvalue", 4);
        substr ($BYTE1, 4, 4, "$binvalue");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('005E',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"CW Pitch set to $firstvalue sucessfull!\n";}
                else {print"CW Pitch set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

####################

sub setLockmode {
        my ($currentlockmode) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'DIAL' && $value ne 'FREQ' && $value ne 'PANEL'){
                if($verbose){print "Value invalid: Choose DIAL/FREQ/PANEL\n\n";}
return 1;
                                                                      }
        $self->setVerbose(0);
        $currentlockmode = $self->getLockmode();
        $self->setVerbose(1);
        if ($value eq $currentlockmode){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                       }
        my $BYTE1 = $self->eepromDecode('005E');
        if ($value eq 'DIAL'){substr ($BYTE1, 2, 2, '00');}
        if ($value eq 'FREQ'){substr ($BYTE1, 2, 2, '01');}
        if ($value eq 'PANEL'){substr ($BYTE1, 2, 2, '10');}
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('005E',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"Lock Mode Set to $value sucessfull!\n";}
                else {print"Lock Mode set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

####################

sub setOpfilter {
        my ($currentopfilter) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'OFF' && $value ne 'SSB' && $value ne 'CW'){
                if($verbose){print "Value invalid: Choose OFF/SSB/CW\n\n";}
return 1;
                                                                 }
        $self->setVerbose(0);
        $currentopfilter = $self->getOpfilter();
        $self->setVerbose(1);
        if ($value eq $currentopfilter){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                       }
        my $BYTE1 = $self->eepromDecode('005E');
        if ($value eq 'OFF'){substr ($BYTE1, 0, 2, '00');}
        if ($value eq 'SSB'){substr ($BYTE1, 0, 2, '01');}
        if ($value eq 'CW'){substr ($BYTE1, 0, 2, '10');}
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('005E',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"Optional Filter Set to $value sucessfull!\n";}
                else {print"Optional Filter set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

# 5F ################################# SETS CW WEIGHT, 430 ARS, 144 ARS, RFKNOB FUNCTION
###################################### SETS BIT 0-4, 5, 6, 7 FROM ADDRESS 0X5F

sub setCwweight {
        my ($currentcwweight) = @_;
        my $self=shift;
        my $value=shift;
	my $testvalue = $value; 
	$testvalue =~ tr/.//d;
        if ($testvalue < 25 || $testvalue > 45){
                if($verbose){print "Value invalid: Choose a number between 2.5 and 4.5\n\n";}
return 1;
                                               }
        $self->setVerbose(0);
        $currentcwweight = $self->getCwweight();
        $self->setVerbose(1);
	my $testcwweight = join("",'1:',"$value");
        if ($currentcwweight eq $testcwweight){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                              }
        my $firstvalue = $value;
	$value =~ tr/.//d;
        $value = $value - 25;
        my $binvalue = dec2bin($value);
        my $BYTE1 = $self->eepromDecode('005F');
        $binvalue = substr("$binvalue", 3);
        substr ($BYTE1, 3, 5, "$binvalue");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('005F',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"CW Weight set to $firstvalue sucessfull!\n";}
                else {print"CW Weight set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

####################

sub setArs144 {
        my ($currentars144) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        $currentars144 = $self->getArs144();
        $self->setVerbose(1);
        if ($currentars144 eq $value) {
                if($verbose){print "Setting $value already selected for 144 ARS\n\n";}
return 1;
                                      }
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('005F','1','0');}
        if($value eq 'ON'){$writestatus = $self->writeEeprom('005F','1','1');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"144 ARS set to $value sucessfull!\n";}
                else {print"144 ARS set to $value failed!!!\n";}
                     }
return $writestatus;
                  }

####################

sub setArs430 {
        my ($currentars430) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        $currentars430 = $self->getArs430();
        $self->setVerbose(1);
        if ($currentars430 eq $value) {
                if($verbose){print "Setting $value already selected for 430 ARS\n\n";}
return 1;
                                      }
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('005F','2','0');}
        if($value eq 'ON'){$writestatus = $self->writeEeprom('005F','2','1');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"430 ARS set to $value sucessfull!\n";}
                else {print"430 ARS set to $value failed!!!\n";}
                     }
return $writestatus;
                  }

####################

sub setRfknob {
        my ($sqlbit, $writestatus,$currentknob) = @_;
        my $self=shift;
	my $value=shift;
        if ($value ne 'RFGAIN' && $value ne 'SQUELCH'){
                if($verbose){print "Value invalid: Choose RFGAIN/SQUELCH\n\n";}
return 1;
	                                              }
        $self->setVerbose(0);
        $currentknob = $self->getRfknob();
        $self->setVerbose(1);
        if ($currentknob eq $value) {
                if($verbose){print "Setting $currentknob already selected for RFGAIN Knob\n\n";}
return 1;
                                    }
        if($value eq 'RFGAIN'){$writestatus = $self->writeEeprom('005F','0','0');}
        if($value eq 'SQUELCH'){$writestatus = $self->writeEeprom('005F','0','1');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"RFGAIN Knob set to $value sucessfull!\n";}
                else {print"RFGAIN Knob set to $value failed!!!\n";}
                     }
return $writestatus;
                  }

# 60 ################################# SET CW DELAY
###################################### CHANGE BITS 0-7 FROM ADDRESS 0X60

sub setCwdelay {
        my ($currentcwdelay) = @_;
        my $self=shift;
        my $value=shift;
        if ($value < 10 || $value > 2500){
                if($verbose){print "Value invalid: Choose a number between 10 and 2500\n\n";}
return 1;
                                         }
        my $testvalue =  substr("$value", -1, 1);
        if ($testvalue != '0'){
                if($verbose){print "Value invalid: Must be in incriments of 10\n\n";}
return 1;
                              }
        $self->setVerbose(0);
        $currentcwdelay = $self->getCwdelay();
        $self->setVerbose(1);
        if ($value eq $currentcwdelay){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                      }
        my $firstvalue = $value;
        $value = $value / 10;
        my $binvalue = dec2bin($value);
        my $NEWHEX = sprintf("%X", oct( "0b$binvalue" ) );
        $writestatus = $self->writeBlock('0060',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"CW Delay set to $firstvalue sucessfull!\n";}
                else {print"CW Delay set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

# 61 ################################# SET SIDETONE VOLUME
###################################### CHANGE BITS 0-6 FROM ADDRESS 0X61

sub setSidetonevol {
        my ($currentsidetonevol) = @_;
        my $self=shift;
        my $value=shift;
        if ($value < 0 || $value > 100){
                if($verbose){print "Value invalid: Choose a number between 0 and 100\n\n";}
return 1;
                                       }
        if (length($value) == 0){
                if($verbose){print "Value invalid: Choose a number between 0 and 100\n\n";}
return 1;
                                }
        $self->setVerbose(0);
        $currentsidetonevol = $self->getSidetonevol();
        $self->setVerbose(1);
        if ($value eq $currentsidetonevol){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                          }
        my $firstvalue = $value;
        my $binvalue = dec2bin($value);
        my $BYTE1 = $self->eepromDecode('0061');
        $binvalue = substr("$binvalue", 1);
        substr ($BYTE1, 1, 7, "$binvalue");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('0061',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"Sidetone Volume set to $firstvalue sucessfull!\n";}
                else {print"Sidetone Volume set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

# 62 ################################# SET CW SPEED, CHARGETIME
###################################### CHANGE BITS 0-5, 6-7 FROM ADDRESS 0X62

sub setCwspeed {
        my ($currentcwspeed) = @_;
        my $self=shift;
        my $value=shift;
        if ($value < 4 || $value > 60){
                if($verbose){print "Value invalid: Choose a number between 4 and 60\n\n";}
return 1;
                                      }
        $self->setVerbose(0);
        $currentcwspeed = $self->getCwspeed();
        $self->setVerbose(1);

        if ($value eq $currentcwspeed){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                      }
        my $firstvalue = $value;
        $value = $value - 4;
        my $binvalue = dec2bin($value);
        my $BYTE1 = $self->eepromDecode('0062');
        $binvalue = substr("$binvalue", 2);
        substr ($BYTE1, 2, 6, "$binvalue");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('0062',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"CW Speed set to $firstvalue sucessfull!\n";}
                else {print"CW Speed set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

####################

sub setChargetime {
        my ($chargebits, $writestatus1, $writestatus2, $writestatus3, $writestatus4, $writestatus5, $writestatus6, $changebits, $change7bbit) = @_;
        my $self=shift;
	my $value=shift;
        $output = $self->eepromDecode('0062');
        $chargebits = substr($output,0,2);
	print "Checking : ";
	my $chargerstatus = $self->getCharger();
        if ($chargerstatus eq 'ON'){
                if($verbose){print "Charger is running: You must disable it first before setting an new chargetime.\n\n";}
return 1;
                                   }
        if($debug){print "Currently set at value ($chargebits) at 0x62\n";}
	if ($value != 10 && $value != 6 && $value != 8){
	        if($verbose){print "Time invalid: Use 6 or 8 or 10.\n\n"; }
return 1;
	 					       }
	else {
		my $six = '00'; my $eight = '01'; my $ten = '10';
			if (($value == 6 && $chargebits == $six) || 
		   	    ($value == 8 && $chargebits == $eight) ||
			    ($value == 10 && $chargebits == $ten)) {
				print "Current charge time $value already set.\n";
return 1;
							 	   }
	     }
        if($debug){print "Writing New BYTES to 0x62\n";}
	my $BYTE1 = $self->eepromDecode('0062');
	if ($value == '6'){substr ($BYTE1, 0, 2, '00');}
        if ($value == '8'){substr ($BYTE1, 0, 2, '01');}
        if ($value == '10'){substr ($BYTE1, 0, 2, '10');}
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
	$writestatus = $self->writeBlock('0062',"$NEWHEX");
        if($debug){print "Writing New BYTES to 0x62\n";}
        if($debug){print "Writing New BYTES to 0x7b\n";}
        $BYTE1 = $self->eepromDecode('007B');
        if ($value == '6'){substr ($BYTE1, 4, 4, '0110');}
        if ($value == '8'){substr ($BYTE1, 4, 4, '1000');}
        if ($value == '10'){substr ($BYTE1, 4, 4, '1010');}
        $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );	
        $writestatus2 = $self->writeBlock('007B',"$NEWHEX");
        if($verbose){
                if (($writestatus eq 'OK' && $writestatus2 eq 'OK')) {print"Chargetime Set to $value sucessfull!\n";}
                else {print"Chargetime set failed: $writestatus\n";}
                    }
return $writestatus;
                      }

# 63 ################################# SET VOX GAIN, AM/FM DIAL 
###################################### CHANGE BITS 0-6,7 FROM ADDRESS 0X63

sub setVoxgain {
        my ($currentvoxgain) = @_;
        my $self=shift;
        my $value=shift;
        if ($value < 1 || $value > 100){
                if($verbose){print "Value invalid: Choose a number between 0 and 100\n\n";}
return 1;
                                       }
        $self->setVerbose(0);
        $currentvoxgain = $self->getVoxgain();
        $self->setVerbose(1);
        if ($value eq $currentvoxgain){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                      }
        my $firstvalue = $value;
        my $binvalue = dec2bin($value);
        my $BYTE1 = $self->eepromDecode('0063');
        $binvalue = substr("$binvalue", 1);
        substr ($BYTE1, 1, 7, "$binvalue");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('0063',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"VOX Gain set to $firstvalue sucessfull!\n";}
                else {print"VOX Gain set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

####################

sub setAmfmdial {
        my ($currentdial) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ENABLE' && $value ne 'DISABLE'){
                if($verbose){print "Value invalid: Choose ENABLE/DISABLE\n\n";}
return 1;
                                                      }
        $self->setVerbose(0);
        $currentdial = $self->getAmfmdial();
        $self->setVerbose(1);
        if ($currentdial eq $value) {
                if($verbose){print "Setting $value already selected\n\n";}
return 1;
                                    }
        if($value eq 'ENABLE'){$writestatus = $self->writeEeprom('0063','0','0');}
        if($value eq 'DISABLE'){$writestatus = $self->writeEeprom('0063','0','1');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"AM/FM Dial set to $value sucessfull!\n";}
                else {print"AM/FM Dial set to $value failed!!!\n";}
                     }
return $writestatus;
                  }

# 64 ################################# SET VOX DELAY, EMERGENCY, CAT RATE
###################################### CHANGE BITS 0-4, 5, 6-7 FROM ADDRESS 0X64

sub setVoxdelay {
        my ($currentvoxdelay) = @_;
        my $self=shift;
        my $value=shift;
        if ($value < 100 || $value > 2500){
                if($verbose){print "Value invalid: Choose a number between 100 and 2500\n\n";}
return 1;
                                          }
	my $testvalue =  substr("$value", -2, 2);
        if ($testvalue != '00'){
                if($verbose){print "Value invalid: Must be in incriments of 100\n\n";}
return 1;
                               }
        $self->setVerbose(0);
        $currentvoxdelay = $self->getVoxdelay();
        $self->setVerbose(1);
        if ($value eq $currentvoxdelay){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                       }
        my $firstvalue = $value;
        $value = $value / 100;
        my $binvalue = dec2bin($value);
        my $BYTE1 = $self->eepromDecode('0064');
        $binvalue = substr("$binvalue", 3);
        substr ($BYTE1, 3, 5, "$binvalue");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('0064',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"Vox Delay set to $firstvalue sucessfull!\n";}
                else {print"Vox Delay set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

####################

sub setEmergency {
       my ($currentemergency) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        $currentemergency = $self->getEmergency();
        $self->setVerbose(1);
        if ($value eq $currentemergency){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                   }
        if($value eq 'ON'){$writestatus = $self->writeEeprom('0064','2','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0064','2','0');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"Emergency set to $value sucessfull!\n";}
                else {print"Emergency set to $value failed!!!\n";}
                     }
return $writestatus;
            }

####################

sub setCatrate {
        my ($currentcatrate) = @_;
        my $self=shift;
        my $value=shift;
        if ($value != '4800' && $value != '9600' && $value != '38400'){
                if($verbose){print "Value invalid: Choose 4800/9600/38400\n\n";}
return 1;
                                                                      }
        $self->setVerbose(0);
        $currentcatrate = $self->getCatrate();
        $self->setVerbose(1);
        if ($value eq $currentcatrate){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                      }
        my $BYTE1 = $self->eepromDecode('0064');
        if ($value == '4800'){substr ($BYTE1, 0, 2, '00');}
        if ($value == '9600'){substr ($BYTE1, 0, 2, '01');}
        if ($value == '38400'){substr ($BYTE1, 0, 2, '10');}
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('0064',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"CAT RATE Set to $value sucessfull!\n";}
                else {print"CAT RATE set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

# 65 ################################# SET APO TIME , MEM GROUPS , DIG MODE
###################################### CHANGE BITS 0-2, 4, 5-7 FROM ADDRESS 0X65

sub setApotime {
        my ($currentapotime) = @_;
        my $self=shift;
        my $value=shift;
        if (($value ne 'OFF') && ($value < 1 || $value > 6)){
                if($verbose){print "Value invalid: Choose a OFF or number between 1 and 6\n\n";}
return 1;
                                                            }
        $self->setVerbose(0);
        $currentapotime = $self->getApotime();
        $self->setVerbose(1);
        if ($value eq $currentapotime){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                      }
        my $firstvalue = $value;
        my $binvalue = dec2bin($value);
        my $BYTE1 = $self->eepromDecode('0065');
        $binvalue = substr("$binvalue", 5);
        substr ($BYTE1, 5, 3, "$binvalue");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('0065',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"APO Time set to $firstvalue sucessfull!\n";}
                else {print"APO Time set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

####################

sub setMemgroup {
        my ($currentmemgroup) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        $currentmemgroup = $self->getMemgroup();
        $self->setVerbose(1);
        if ($value eq $currentmemgroup){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                       }
        if($value eq 'ON'){$writestatus = $self->writeEeprom('0065','3','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0065','3','0');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"Memory Groups set to $value sucessfull!\n";}
                else {print"Memory Groups set to $value failed!!!\n";}
                     }
return $writestatus;
            }

####################

sub setDigmode {
        my ($currentdigmode) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'RTTY' && $value ne 'PSK31-L' && $value ne 'PSK31-U' && $value ne 'USER-L' && $value ne 'USER-U'){
                if($verbose){print "Value invalid: Choose RTTY/PSK31-L/PSK31-U/USER-L/USER-U\n\n"; }
return 1;
                                                                  						       }
        $self->setVerbose(0);
        $currentdigmode = $self->getDigmode();
        $self->setVerbose(1);
        if ($value eq $currentdigmode){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                      }
        my $BYTE1 = $self->eepromDecode('0065');
        if ($value eq 'RTTY'){substr ($BYTE1, 0, 3, '000');}
        if ($value eq 'PSK31-L'){substr ($BYTE1, 0, 3, '001');}
        if ($value eq 'PSK31-U'){substr ($BYTE1, 0, 3, '010');}
        if ($value eq 'USER-L'){substr ($BYTE1, 0, 3, '011');}
        if ($value eq 'USER-U'){substr ($BYTE1, 0, 3, '100');}
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('0065',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"Digital Mode Set to $value sucessfull!\n";}
                else {print"Digital Mode set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

# 66 ################################# SET TOT TIME , DCSINV
###################################### CHANGE BITS 0-4 6-7 FROM ADDRESS 0X66

sub setTottime {
        my ($currenttottime) = @_;
        my $self=shift;
        my $value=shift;
        if (($value ne 'OFF') && ($value < 1 || $value > 20)){
                if($verbose){print "Value invalid: Choose OFF or a number between 1 and 20\n\n";}
return 1;
                                                             }
        $self->setVerbose(0);
        $currenttottime = $self->getTottime();
        $self->setVerbose(1);
        if ($value eq $currenttottime){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                      }
	if ($value eq 'OFF'){$value = 0;}
        my $firstvalue = $value;
        my $binvalue = dec2bin($value);
        my $BYTE1 = $self->eepromDecode('0066');
        $binvalue = substr("$binvalue", 3);
        substr ($BYTE1, 3, 5, "$binvalue");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('0066',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"Time out Timer set to $firstvalue sucessfull!\n";}
                else {print"Time out Timer set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

####################

sub setDcsinv {
        my ($currentdcsinv) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'TN-RN' && $value ne 'TN-RIV' && $value ne 'TIV-RN' && $value ne 'TIV-RIV'){
                if($verbose){print "Value invalid: Choose TN-RN/TN-RIV/TIV-RN/TIV-RIV\n\n"; }
return 1;
                                                                                                 }
        $self->setVerbose(0);
        $currentdcsinv = $self->getDcsinv();
        $self->setVerbose(1);
        if ($value eq $currentdcsinv){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                     }
        my $BYTE1 = $self->eepromDecode('0066');
        if ($value eq 'TN-RN'){substr ($BYTE1, 0, 2, '00');}
        if ($value eq 'TN-RIV'){substr ($BYTE1, 0, 2, '01');}
        if ($value eq 'TIV-RN'){substr ($BYTE1, 0, 2, '10');}
        if ($value eq 'TIV-RIV'){substr ($BYTE1, 0, 2, '11');}
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('0066',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"DCS Inversion Set to $value sucessfull!\n";}
                else {print"DCS Inversion set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

# 67 ################################# SET SSB MIC, MIC SCAN
###################################### CHANGE BITS 0-6 , 7 FROM ADDRESS 0X67

sub setSsbmic {
        my ($currentssbmic) = @_;
        my $self=shift;
        my $value=shift;
        if ($value < 0 || $value > 100){
                if($verbose){print "Value invalid: Choose a number between 0 and 100\n\n";}
return 1;
                                       }

        if (length($value) == 0){
                if($verbose){print "Value invalid: Choose a number between 0 and 100\n\n";}
return 1;
                                }

        $self->setVerbose(0);
        $currentssbmic = $self->getSsbmic();
        $self->setVerbose(1);
        if ($value eq $currentssbmic){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                     }
        my $firstvalue = $value;
        my $binvalue = dec2bin($value);
        my $BYTE1 = $self->eepromDecode('0067');
        $binvalue = substr("$binvalue", 1);
        substr ($BYTE1, 1, 7, "$binvalue");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('0067',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"SSB MIC set to $firstvalue sucessfull!\n";}
                else {print"SSB MIC set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

####################

sub setMicscan {
       my ($currentmicscan) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        $currentmicscan = $self->getMicscan();
        $self->setVerbose(1);
        if ($value eq $currentmicscan){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                      }
        if($value eq 'ON'){$writestatus = $self->writeEeprom('0067','0','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0067','0','0');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"MIC SCAN set to $value sucessfull!\n";}
                else {print"MIC SCAN set to $value failed!!!\n";}
                     }
return $writestatus;
            }

# 68 ################################# SET AM MIC, MIC KEY
###################################### CHANGE BITS 0-6 , 7 FROM ADDRESS 0X68

sub setAmmic {
        my ($currentammic) = @_;
        my $self=shift;
        my $value=shift;
        if ($value < 0 || $value > 100){
                if($verbose){print "Value invalid: Choose a number between 0 and 100\n\n";}
return 1;
                                       }

        if (length($value) == 0){
                if($verbose){print "Value invalid: Choose a number between 0 and 100\n\n";}
return 1;
                                }
        $self->setVerbose(0);
        $currentammic = $self->getAmmic();
        $self->setVerbose(1);
        if ($value eq $currentammic){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                    }
        my $firstvalue = $value;
        my $binvalue = dec2bin($value);
        my $BYTE1 = $self->eepromDecode('0068');
        $binvalue = substr("$binvalue", 1);
        substr ($BYTE1, 1, 7, "$binvalue");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('0068',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"AM MIC set to $firstvalue sucessfull!\n";}
                else {print"AM MIC set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

####################

sub setMickey {
       my ($currentmickey) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        $currentmickey = $self->getMickey();
        $self->setVerbose(1);
        if ($value eq $currentmickey){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                     }
        if($value eq 'ON'){$writestatus = $self->writeEeprom('0068','0','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0068','0','0');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"MIC KEY set to $value sucessfull!\n";}
                else {print"MIC KEY set to $value failed!!!\n";}
                     }
return $writestatus;
            }

# 69 ################################# SET FM MIC
###################################### CHANGE BITS 0-6 FROM ADDRESS 0X69

sub setFmmic {
        my ($currentfmmic) = @_;
        my $self=shift;
        my $value=shift;
        if ($value < 0 || $value > 100){
                if($verbose){print "Value invalid: Choose a number between 0 and 100\n\n";}
return 1;
                                       }
        if (length($value) == 0){
                if($verbose){print "Value invalid: Choose a number between 0 and 100\n\n";}
return 1;
                                }
        $self->setVerbose(0);
        $currentfmmic = $self->getFmmic();
        $self->setVerbose(1);
        if ($value eq $currentfmmic){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                    }
        my $firstvalue = $value;
        my $binvalue = dec2bin($value);
        my $BYTE1 = $self->eepromDecode('0069');
        $binvalue = substr("$binvalue", 1);
        substr ($BYTE1, 1, 7, "$binvalue");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('0069',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"FM MIC set to $firstvalue sucessfull!\n";}
                else {print"FM MIC set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

# 6A ################################# SET DIG MIC
###################################### CHANGE BITS 0-6 FROM ADDRESS 0X6A

sub setDigmic {
        my ($currentdigmic) = @_;
        my $self=shift;
        my $value=shift;
        if ($value < 0 || $value > 100){
                if($verbose){print "Value invalid: Choose a number between 0 and 100\n\n";}
return 1;
                                       }
        if (length($value) == 0){
                if($verbose){print "Value invalid: Choose a number between 0 and 100\n\n";}
return 1;
                                }
        $self->setVerbose(0);
        $currentdigmic = $self->getDigmic();
        $self->setVerbose(1);
        if ($value eq $currentdigmic){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                     }
        my $firstvalue = $value;
        my $binvalue = dec2bin($value);
        my $BYTE1 = $self->eepromDecode('006A');
        $binvalue = substr("$binvalue", 1);
        substr ($BYTE1, 1, 7, "$binvalue");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('006A',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"DIG MIC set to $firstvalue sucessfull!\n";}
                else {print"DIG MIC set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

# 6B ################################# SET PKT MIC, EXT MENU
###################################### CHANGE BITS 0-6, 7 FROM ADDRESS 0X6B

sub setPktmic {
        my ($currentpktmic) = @_;
        my $self=shift;
        my $value=shift;
        if ($value < 0 || $value > 100){
                if($verbose){print "Value invalid: Choose a number between 0 and 100\n\n";}
return 1;
                                       }
        if (length($value) == 0){
                if($verbose){print "Value invalid: Choose a number between 0 and 100\n\n";}
return 1;
                                }
        $self->setVerbose(0);
        $currentpktmic = $self->getPktmic();
        $self->setVerbose(1);
        if ($value eq $currentpktmic){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                     }
        my $firstvalue = $value;
        my $binvalue = dec2bin($value);
        my $BYTE1 = $self->eepromDecode('006B');
        $binvalue = substr("$binvalue", 1);
        substr ($BYTE1, 1, 7, "$binvalue");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('006B',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"PKT MIC set to $firstvalue sucessfull!\n";}
                else {print"PKT MIC set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

####################

sub setExtmenu {
       my ($currentextmenu) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        $currentextmenu = $self->getExtmenu();
        $self->setVerbose(1);
        if ($value eq $currentextmenu){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                      }
        if($value eq 'ON'){$writestatus = $self->writeEeprom('006B','0','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('006B','0','0');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"EXT MENU set to $value sucessfull!\n";}
                else {print"EXT MENU set to $value failed!!!\n";}
                     }
return $writestatus;
            }

# 6C ################################# SET 9600 MIC
###################################### CHANGE BITS 0-6 FROM ADDRESS 0X6C

sub set9600mic {
        my ($current9600mic) = @_;
        my $self=shift;
        my $value=shift;
        if ($value < 0 || $value > 100){
                if($verbose){print "Value invalid: Choose a number between 0 and 100\n\n";}
return 1;
                                       }
        if (length($value) == 0){
                if($verbose){print "Value invalid: Choose a number between 0 and 100\n\n";}
return 1;
                                }
        $self->setVerbose(0);
        $current9600mic = $self->get9600mic();
        $self->setVerbose(1);
        if ($value eq $current9600mic){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                      }
        my $firstvalue = $value;
        my $binvalue = dec2bin($value);
        my $BYTE1 = $self->eepromDecode('006C');
        $binvalue = substr("$binvalue", 1);
        substr ($BYTE1, 1, 7, "$binvalue");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('006C',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"9600 MIC set to $firstvalue sucessfull!\n";}
                else {print"9600 MIC set failed: $writestatus\n";}
                    }
return $writestatus;
                 }


# 6D-6E ################################# SET DIG SHIFT
###################################### CHANGE ALL BITS FROM ADDRESS 0X6D, 0X6E

sub setDigshift {
       my ($currentdigshift,$polarity,$newvalue,$endvalue,$binvalue,$bin1,$bin2) = @_;
        my $self=shift;
        my $value=shift;
	$polarity = substr ($value,0,1);
	$newvalue = substr ($value,1);
	$endvalue = substr ($value,-1,1);
        if ($value != '0' && $polarity ne '+' && $polarity ne '-'){
                if($verbose){print "Value invalid: Choose -3000 to +3000 (needs + or - with number)\n\n";}
return 1;
                                                                  }
        if ($endvalue != '0' || ($newvalue < 0 || $newvalue > 3000)){
                if($verbose){print "Value invalid: Choose -3000 to +3000 (Multiple of 10)\n\n";}
return 1;
                                                                    }
        $self->setVerbose(0);
        $currentdigshift = $self->getDigshift();
        $self->setVerbose(1);
        if ($value eq $currentdigshift){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                       }
        $newvalue = $newvalue /10;
        if ($polarity eq '-'){$newvalue = 65536 - $newvalue;}
        $binvalue = unpack("B32", pack("N", $newvalue));
        $binvalue = substr $binvalue, -16;
	$bin1 = substr $binvalue, 0,8;
	$bin2 = substr $binvalue, 8,8;
        my $NEWHEX1 = sprintf("%X", oct( "0b$bin1" ) );
        my $NEWHEX2 = sprintf("%X", oct( "0b$bin2" ) );
        my $writestatus1 = $self->writeDoubleblock('006D',"$NEWHEX1","$NEWHEX2");
		if ($writestatus1 eq 'OK'){if($verbose){print"DIG SHIFT set to $value sucessfull!\n";}}
                else {if($verbose){print"DIG SHIFT set to $value failed!!!\n";}}
return $writestatus;
                } 

# 6F-70 ################################# SET DIG DISP
###################################### CHANGE ALL BITS FROM ADDRESS 0X6F, 0X70

sub setDigdisp {
       my ($currentdigdisp,$polarity,$newvalue,$endvalue,$binvalue,$bin1,$bin2) = @_;
        my $self=shift;
        my $value=shift;
        $polarity = substr ($value,0,1);
        $newvalue = substr ($value,1);
        $endvalue = substr ($value,-1,1);
        if ($value != '0' && $polarity ne '+' && $polarity ne '-'){
                if($verbose){print "Value invalid: Choose -3000 to +3000 (needs + or - with number)\n\n";}
return 1;
                                                                  }
        if ($endvalue != '0' || ($newvalue < 0 || $newvalue > 3000)){
                if($verbose){print "Value invalid: Choose -3000 to +3000 (Multiple of 10)\n\n";}
return 1;
                                                                    }
        $self->setVerbose(0);
        $currentdigdisp = $self->getDigdisp();
        $self->setVerbose(1);
        if ($value eq $currentdigdisp){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                      }
        $newvalue = $newvalue /10;
        if ($polarity eq '-'){$newvalue = 65536 - $newvalue;}
        $binvalue = unpack("B32", pack("N", $newvalue));
        $binvalue = substr $binvalue, -16;
        $bin1 = substr $binvalue, 0,8;
        $bin2 = substr $binvalue, 8,8;
        my $NEWHEX1 = sprintf("%X", oct( "0b$bin1" ) );
        my $NEWHEX2 = sprintf("%X", oct( "0b$bin2" ) );
        my $writestatus1 = $self->writeDoubleblock('006F',"$NEWHEX1","$NEWHEX2");
                if ($writestatus1 eq 'OK'){if($verbose){print"DIG DISP set to $value sucessfull!\n";}}
                else {if($verbose){print"DIG DISP set to $value failed!!!\n";}}
return $writestatus;
                }

# 71 ################################# SET R LSB CAR
###################################### CHANGE ALL BITS FROM ADDRESS 0X71

sub setRlsbcar {
       my ($currentrlsbcar,$polarity,$newvalue,$endvalue,$binvalue,$bin1,$bin2) = @_;
        my $self=shift;
        my $value=shift;
        $polarity = substr ($value,0,1);
        $newvalue = substr ($value,1);
        $endvalue = substr ($value,-1,1);
        if ($value != '0' && $polarity ne '+' && $polarity ne '-'){
                if($verbose){print "Value invalid: Choose -300 to +300 (needs + or - with number)\n\n";}
return 1;
                                                                  }
        if ($endvalue != '0' || ($newvalue < 0 || $newvalue > 300)){
                if($verbose){print "Value invalid: Choose -300 to +300 (Multiple of 10)\n\n";}
return 1;
                                                                   }
        $self->setVerbose(0);
        $currentrlsbcar = $self->getRlsbcar();
        $self->setVerbose(1);
        if ($value eq $currentrlsbcar){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                      }
        $newvalue = $newvalue /10;
        if ($polarity eq '-'){$newvalue = 256 - $newvalue;}
        $binvalue = unpack("B32", pack("N", $newvalue));
        my $NEWHEX1 = sprintf("%X", oct( "0b$binvalue" ) );
        my $writestatus1 = $self->writeBlock('0071',"$NEWHEX1");
        if ($writestatus1 eq 'OK'){if($verbose){print"R LSB CAR set to $value sucessfull!\n";}}
        else {if($verbose){print"R LSB CAR set to $value failed!!!\n";}}
return $writestatus;
                }

# 72 ################################# SET R USB CAR
###################################### CHANGE ALL BITS FROM ADDRESS 0X72

sub setRusbcar {
       my ($currentrusbcar,$polarity,$newvalue,$endvalue,$binvalue,$bin1,$bin2) = @_;
        my $self=shift;
        my $value=shift;
        $polarity = substr ($value,0,1);
        $newvalue = substr ($value,1);
        $endvalue = substr ($value,-1,1);
        if ($value != '0' && $polarity ne '+' && $polarity ne '-'){
                if($verbose){print "Value invalid: Choose -300 to +300 (needs + or - with number)\n\n";}
return 1;
                                                                  }
        if ($endvalue != '0' || ($newvalue < 0 || $newvalue > 300)){
                if($verbose){print "Value invalid: Choose -300 to +300 (Multiple of 10)\n\n";}
return 1;
                                                                   }
        $self->setVerbose(0);
        $currentrusbcar = $self->getRusbcar();
        $self->setVerbose(1);
        if ($value eq $currentrusbcar){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                      }
        $newvalue = $newvalue /10;
        if ($polarity eq '-'){$newvalue = 256 - $newvalue;}
        $binvalue = unpack("B32", pack("N", $newvalue));
        my $NEWHEX1 = sprintf("%X", oct( "0b$binvalue" ) );
        my $writestatus1 = $self->writeBlock('0072',"$NEWHEX1");
        if ($writestatus1 eq 'OK'){if($verbose){print"R USB CAR set to $value sucessfull!\n";}}
        else {if($verbose){print"R USB CAR set to $value failed!!!\n";}}
return $writestatus;
                }

# 73 ################################# SET T LSB CAR
###################################### CHANGE ALL BITS FROM ADDRESS 0X73

sub setTlsbcar {
       my ($currenttlsbcar,$polarity,$newvalue,$endvalue,$binvalue,$bin1,$bin2) = @_;
        my $self=shift;
        my $value=shift;
        $polarity = substr ($value,0,1);
        $newvalue = substr ($value,1);
        $endvalue = substr ($value,-1,1);
        if ($value != '0' && $polarity ne '+' && $polarity ne '-'){
                if($verbose){print "Value invalid: Choose -300 to +300 (needs + or - with number)\n\n";}
return 1;
                                                                  }
        if ($endvalue != '0' || ($newvalue < 0 || $newvalue > 300)){
                if($verbose){print "Value invalid: Choose -300 to +300 (Multiple of 10)\n\n";}
return 1;
                                                                   }
        $self->setVerbose(0);
        $currenttlsbcar = $self->getTlsbcar();
        $self->setVerbose(1);
        if ($value eq $currenttlsbcar){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                      }
        $newvalue = $newvalue /10;
        if ($polarity eq '-'){$newvalue = 256 - $newvalue;}
        $binvalue = unpack("B32", pack("N", $newvalue));
        my $NEWHEX1 = sprintf("%X", oct( "0b$binvalue" ) );
        my $writestatus1 = $self->writeBlock('0073',"$NEWHEX1");
        if ($writestatus1 eq 'OK'){if($verbose){print"T LSB CAR set to $value sucessfull!\n";}}
        else {if($verbose){print"T LSB CAR set to $value failed!!!\n";}}
return $writestatus;
                }

# 74 ################################# SET T USB CAR
###################################### CHANGE ALL BITS FROM ADDRESS 0X74

sub setTusbcar {
       my ($currenttusbcar,$polarity,$newvalue,$endvalue,$binvalue,$bin1,$bin2) = @_;
        my $self=shift;
        my $value=shift;
        $polarity = substr ($value,0,1);
        $newvalue = substr ($value,1);
        $endvalue = substr ($value,-1,1);
        if ($value != '0' && $polarity ne '+' && $polarity ne '-'){
                if($verbose){print "Value invalid: Choose -300 to +300 (needs + or - with number)\n\n";}
return 1;
                                                                  }
        if ($endvalue != '0' || ($newvalue < 0 || $newvalue > 300)){
                if($verbose){print "Value invalid: Choose -300 to +300 (Multiple of 10)\n\n";}
return 1;
                                                                   }
        $self->setVerbose(0);
        $currenttusbcar = $self->getTusbcar();
        $self->setVerbose(1);
        if ($value eq $currenttusbcar){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                      }
        $newvalue = $newvalue /10;
        if ($polarity eq '-'){$newvalue = 256 - $newvalue;}
        $binvalue = unpack("B32", pack("N", $newvalue));
        my $NEWHEX1 = sprintf("%X", oct( "0b$binvalue" ) );
        my $writestatus1 = $self->writeBlock('0074',"$NEWHEX1");
        if ($writestatus1 eq 'OK'){if($verbose){print"T USB CAR set to $value sucessfull!\n";}}
        else {if($verbose){print"T USB CAR set to $value failed!!!\n";}}
return $writestatus;
                }

# 79 ################################# SET TXPOWER, PRI, DW, SCN, ARTS ON/OFF
###################################### CHANGE BITS 0-1, 3, 4, 5-6, 7 FROM ADDRESS 0X79

sub setTxpower {

       my ($currentpower, $testtxpwr) = @_;
        my $self=shift;
        my $value=shift;
        my %newhash = reverse %TXPWR;
        ($testtxpwr) = grep { $newhash{$_} eq $value } keys %newhash;
        if ($testtxpwr eq'') {
                if($verbose){print "\nChoose valid Option : [HIGH/LOW1/LOW2/LOW3]\n\n";}
return 1;
                             }
        $self->setVerbose(0);
        $currentpower = $self->getTxpower();
        $self->setVerbose(1);
        if ($currentpower eq $value) {
                if($verbose){print "\nValue $value already selected for TX POWER\n\n"; }
return 1;
                                     }
        my $BYTE1 = $self->eepromDecode('0079');
        substr ($BYTE1, 6, 2, "$testtxpwr");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
         $writestatus = $self->writeBlock('0079',"$NEWHEX");
        if ($verbose){
                if ($writestatus eq 'OK') {print"TX POWER $value set sucessfull!\n";}
                else {print"TX POWER $value set failed!!!\n";}
                     }
return $writestatus;
               }

####################

sub setPri {
       my ($currentpri) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        $currentpri = $self->getPri();
        $self->setVerbose(1);

        if ($value eq $currentpri){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                  }
        if($value eq 'ON'){$writestatus = $self->writeEeprom('0079','3','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0079','3','0');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"PRI set to $value sucessfull!\n";}
                else {print"PRI set to $value failed!!!\n";}
                     }
return $writestatus;
            }

####################

sub setDw {
       my ($currentdw) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        $currentdw = $self->getDw();
        $self->setVerbose(1);
        if ($value eq $currentdw){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                 }
        if($value eq 'ON'){$writestatus = $self->writeEeprom('0079','4','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0079','4','0');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"DW set to $value sucessfull!\n";}
                else {print"DW set to $value failed!!!\n";}
                     }
return $writestatus;
            }

####################

sub setScn {
        my ($currentscn) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'OFF' && $value ne 'UP' && $value ne 'DOWN'){
                if($verbose){print "Value invalid: Choose OFF/UP/DOWN\n\n";}
return 1;
                                                                  }
        $self->setVerbose(0);
        $currentscn = $self->getScn();
        $self->setVerbose(1);
        if ($value eq $currentscn){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                  }
        my $BYTE1 = $self->eepromDecode('0079');
        if ($value eq 'OFF'){substr ($BYTE1, 1, 2, '00');}
        if ($value eq 'UP'){substr ($BYTE1, 1, 2, '10');}
        if ($value eq 'DOWN'){substr ($BYTE1, 1, 2, '11');}
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        $writestatus = $self->writeBlock('0079',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"SCN Set to $value sucessfull!\n";}
                else {print"SCN Inversion set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

####################

sub setArts {
       my ($currentarts, $writestatus) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
					      }
        $self->setVerbose(0);
        $currentarts = $self->getArts();
        $self->setVerbose(1);

        if ($value eq $currentarts){
                if($verbose){print "Value $currentarts already selected.\n\n";}
return 1;
                                   }
        if($value eq 'ON'){$writestatus = $self->writeEeprom('0079','0','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('0079','0','0');}
	if ($verbose){
                if ($writestatus eq 'OK') {print"ARTS set to $value sucessfull!\n";}
                else {print"ARTS set to $value failed!!!\n";}
		     }
return $writestatus;
            }

# 7a ################################# SET ANTENNA FRONT/BACK, SPL
###################################### CHANGE BITS 0-5, 7 FROM ADDRESS 0X7A

sub setAntenna {
       my ($currentantenna, $antennabit) = @_;
        my $self=shift;
        my $value=shift;
        my $value2=shift;

        if ($value ne 'HF' && $value ne '6M' && $value ne 'FMBCB' && $value ne 'AIR' && $value ne 'VHF' && $value ne 'UHF'){
                if($verbose){print "Value invalid: Choose HF/6M/FMBCB/AIR/VHF/UHV\n\n"; }
return 1;															  
															   }

        if ($value2 ne 'FRONT' && $value2 ne 'BACK'){
                if($verbose){print "Value invalid: Choose FRONT/BACK\n\n"; }
return 1;
                                                                                                                           }
        $self->setVerbose(0);
	$currentantenna = $self->getAntenna("$value");
	$self->setVerbose(1);
	if ($currentantenna eq $value2) {
                if($verbose){print "\nAntenna for $value is already set to $value2\n\n"; }
return 1;
					}
	my $valuelabel = $value2;
	if ($value2 eq 'BACK'){$value2 = 1;}
        if ($value2 eq 'FRONT'){$value2 = 0;}
	if ($value eq 'HF'){$antennabit = 7;}
        if ($value eq '6M'){$antennabit = 6;}
        if ($value eq 'FMBCB'){$antennabit = 5;}
        if ($value eq 'AIR'){$antennabit = 4;}
        if ($value eq 'VHF'){$antennabit = 3;}
        if ($value eq 'UHF'){$antennabit = 2;}
        $writestatus = $self->writeEeprom('007A',"$antennabit","$value2");
        if($verbose && $writestatus eq 'OK'){print "\nAntenna for $value set to $valuelabel: $writestatus\n\n"; }
        if($verbose && $writestatus ne 'OK'){print "\nError setting antenna: $writestatus\n\n"; }
return $writestatus;
 	       }

####################

sub setSpl {
       my ($currentspl) = @_;
        my $self=shift;
        my $value=shift;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n"; }
return 1;
                                              }
        $self->setVerbose(0);
        $currentspl = $self->getSpl();
        $self->setVerbose(1);
        if ($value eq $currentspl){
                if($verbose){print "Value $value already selected.\n\n"; }
return 1;
                                  }
        if($value eq 'ON'){$writestatus = $self->writeEeprom('007A','0','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom('007A','0','0');}
        if ($verbose){
                if ($writestatus eq 'OK') {print"SPL set to $value sucessfull!\n";}
                else {print"SPL set to $value failed!!!\n";}
                     }
return $writestatus;
            }

# 7b ################################# SET CHARGER ON/OFF
###################################### CHANGE BITS 6-7 FROM ADDRESS 0X7b

sub setCharger {
        my $self=shift;
        my $value=shift;
	my $chargerstatus = $self->getCharger();
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Use ON or OFF.\n\n";}

return 1;
                                              }
	if ($chargerstatus eq $value){
		if($verbose){print "Staying $value\n";}
return 1;
				     }
	else {
                if($verbose){print "Turning $value\n";}
	        if ($value eq 'OFF'){$writestatus = $self->writeEeprom('007B','3','0');}
		if ($value eq 'ON'){$writestatus = $self->writeEeprom('007B','3','1');}
return 0;
	     }
return 1;
               }

# 7D - 388, 40B - 44E ################################# SET VFO MEM ######
############################################ 

sub writeMemvfo {
        my ($testvfoband, $address, $address2, $address3, $address4, $testoptions, $base, %baseaddress, $musttoggle ,$offset, $startaddress, $fmstep, $amstep, $ctcsstone, $dcscode, $polarity, $newvalue) = @_;
        my $self=shift;
        my $vfo=shift;
        my $band=shift;
        my $option=shift;
        my $value=shift;
        if($vfo eq 'MTQMB'){$vfo = 'A'; $band = 'MTQMB';}
        if($vfo eq 'MTUNE'){$vfo = 'A'; $band = 'MTUNE';}
        if ($vfo ne 'A' && $vfo ne 'B'){
                if($verbose){print "Value invalid: Choose A/B\n\n";}
return 1;
                                       }
	$band = uc($band);
	$option = uc($option); 
        my %newhash = reverse %VFOBANDS;
        ($testvfoband) = grep { $newhash{$_} eq $band } keys %newhash;
        if ($testvfoband eq'') {
		if ($band ne 'MTQMB' && $band ne 'MTUNE'){
                if($verbose){print "\nChoose valid Band : [160M/75M/40M/30M/20M/17M/15M/12M/10M/6M/2M/70CM/FMBC/AIR/PHAN]\n\n";}
return 1;
              					         }
                               }
        my %testhash = reverse %VFOMEMOPTS;
        ($testoptions) = grep { $testhash{$_} eq $option } keys %testhash;
        if (!$testoptions){
                if($verbose){
                print "Choose a valid option\.\n\n";
                my $columns = 1;
                foreach my $options (sort keys %testhash) {
                printf "%-15s %s",$testhash{$options};
                $columns++;
                if ($columns == 7){print "\n\n"; $columns = 1;}
                                                          }
                print "\n\n";
return 1;
			    }
     		          }
        if ($value != '0' && !$value){
                if($verbose){print "A Value must be given\n\n";}
return 1;
                                     }
        $self->setVerbose(0);
	my $currentvfo = $self->getVfo();
        $self->setVerbose(1);
	if ($currentvfo eq $vfo) {$musttoggle = 'TRUE';}
        if ($vfo eq 'A'){%baseaddress = reverse %VFOABASE;}
        if ($vfo eq 'B'){%baseaddress = reverse %VFOBBASE;}
        ($base) = grep { $baseaddress{$_} eq $band } keys %baseaddress;

############## MODE
        if ($option eq 'MODE') {
        my ($currentmode) = @_;
        $self->setVerbose(0);
        $currentmode = $self->readMemvfo("$vfo","$band","$option");
        $self->setVerbose(1);
        if ($value eq $currentmode){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                   }
	$offset=0x00;
	$address = $self->hexAdder("$offset","$base");
	my $mode;
        my %modehash = reverse %MEMMODES;
	($mode) = grep { $modehash{$_} eq $value } keys %modehash;
        if (!$mode){
                if($verbose){
		print "\nInvalid Option. Choose from the following\n\n";
                my $columns = 1;
                foreach my $codes (sort keys %modehash) {
                printf "%-15s %s",$modehash{$codes};
                $columns++;
                if ($columns == 7){print "\n\n"; $columns = 1;}
                                                        }
                print "\n\n";
                           }
return 1;
                   }
        my $BYTE1 = $self->eepromDecode("$address");
        substr ($BYTE1, 5, 3, "$mode");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
	if ($musttoggle) {$self->quietToggle();}
        $writestatus = $self->writeBlock("$address","$NEWHEX");
        if ($musttoggle) {$self->quietToggle();}
        if($verbose){
                if ($writestatus eq 'OK') {print"MODE Set to $option sucessfull!\n";}
                else {print"MODE set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

############## NARFM

       if ($option eq 'NARFM') {
       my ($currentnarfm) = @_;
       if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                             }
        $self->setVerbose(0);
        $currentnarfm = $self->readMemvfo("$vfo","$band","$option");
        $self->setVerbose(1);
        if ($value eq $currentnarfm){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                    }
	$offset=0x01;
        $address = $self->hexAdder("$offset","$base");
        if ($musttoggle) {$self->quietToggle();}
        if($value eq 'ON'){$writestatus = $self->writeEeprom("$address",'4','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom("$address",'4','0');}
        if ($musttoggle) {$self->quietToggle();}
        if ($verbose){
                if ($writestatus eq 'OK') {print"NAR FM set to $value sucessfull!\n";}
                else {print"NAR FM set to $value failed!!!\n";}
                     }
return $writestatus;
            }

############## NARCWDIG

       if ($option eq 'NARCWDIG') {
       my ($currentnarcwdig) = @_;
       if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                             }
        $self->setVerbose(0);
        $currentnarcwdig = $self->readMemvfo("$vfo","$band","$option");
        $self->setVerbose(1);
        if ($value eq $currentnarcwdig){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                       }
        $offset=0x01;
        $address = $self->hexAdder("$offset","$base");
        if ($musttoggle) {$self->quietToggle();}
        if($value eq 'ON'){$writestatus = $self->writeEeprom("$address",'3','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom("$address",'3','0');}
        if ($musttoggle) {$self->quietToggle();}
        if ($verbose){
                if ($writestatus eq 'OK') {print"NAR CW DIG set to $value sucessfull!\n";}
                else {print"NAR CW DIG set to $value failed!!!\n";}
                     }
return $writestatus;
            }

############## RPTOFFSET

       if ($option eq 'RPTOFFSET') {
       my ($currentrptoffset) = @_;
       if ($value ne 'SIMPLEX' && $value ne 'MINUS'  && $value ne 'PLUS' && $value ne 'NON-STANDARD'){
                if($verbose){print "Value invalid: Choose SIMPLEX/MINUS/PLUS/NON-STANDARD\n\n";}
return 1;
  							                                             }
        $self->setVerbose(0);
        $currentrptoffset = $self->readMemvfo("$vfo","$band","$option");
        $self->setVerbose(1);
        if ($value eq $currentrptoffset){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                        }
        $offset=0x01;
        $address = $self->hexAdder("$offset","$base");
        my $BYTE1 = $self->eepromDecode("$address");
        if ($value eq 'SIMPLEX'){substr ($BYTE1, 0, 2, '00');}
        if ($value eq 'MINUS'){substr ($BYTE1, 0, 2, '01');}
        if ($value eq 'PLUS'){substr ($BYTE1, 0, 2, '10');}
        if ($value eq 'NON-STANDARD'){substr ($BYTE1, 0, 2, '11');}
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        if ($musttoggle) {$self->quietToggle();}
        $writestatus = $self->writeBlock("$address","$NEWHEX");
        if ($musttoggle) {$self->quietToggle();}
        if($verbose){
                if ($writestatus eq 'OK') {print"RPTOFFSET Set to $value sucessfull!\n";}
                else {print"RPT OFFSET set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

############## TONEDCS

       if ($option eq 'TONEDCS') {
       my ($currenttonedcs) = @_;
       if ($value ne 'OFF' && $value ne 'TONE'  && $value ne 'TONETSQ' && $value ne 'DCS'){
                if($verbose){print "Value invalid: Choose OFF/TONE/TONETSQ/DCS\n\n"; }
return 1;
        					                                          }
        $self->setVerbose(0);
        $currenttonedcs = $self->readMemvfo("$vfo","$band","$option");
        $self->setVerbose(1);
        if ($value eq $currenttonedcs){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                      }
        $offset=0x04;
        $address = $self->hexAdder("$offset","$base");
        my $BYTE1 = $self->eepromDecode("$address");
        if ($value eq 'OFF'){substr ($BYTE1, 6, 2, '00');}
        if ($value eq 'TONE'){substr ($BYTE1, 6, 2, '01');}
        if ($value eq 'TONETSQ'){substr ($BYTE1, 6, 2, '10');}
        if ($value eq 'DCS'){substr ($BYTE1, 6, 2, '11');}
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        if ($musttoggle) {$self->quietToggle();}
        $writestatus = $self->writeBlock("$address","$NEWHEX");
        if ($musttoggle) {$self->quietToggle();}
        if($verbose){
                if ($writestatus eq 'OK') {print"TONEDCS Set to $value sucessfull!\n";}
                else {print"TONEDCS set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

############## CLARIFTER

	if ($option eq 'CLARIFIER') {
        my ($currentclarifier) = @_;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        $currentclarifier = $self->readMemvfo("$vfo","$band","$option");
        $self->setVerbose(1);
        if ($value eq $currentclarifier){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                        }
        $offset=0x02;
        $address = $self->hexAdder("$offset","$base");
        if ($musttoggle) {$self->quietToggle();}
        if($value eq 'ON'){$writestatus = $self->writeEeprom("$address",'1','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom("$address",'1','0');}
        if ($musttoggle) {$self->quietToggle();}
        if ($verbose){
                if ($writestatus eq 'OK') {print"CLARIFIER set to $value sucessfull!\n";}
                else {print"CLARIFIER set to $value failed!!!\n";}
                     }
return $writestatus;
            }

############## ATT

        if ($option eq 'ATT'){
        my ($currentatt) = @_;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        $currentatt = $self->readMemvfo("$vfo","$band","$option");
        $self->setVerbose(1);
        if ($value eq $currentatt){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                  }
        $offset=0x02;
        $address = $self->hexAdder("$offset","$base");
        if ($musttoggle) {$self->quietToggle();}
        if($value eq 'ON'){$writestatus = $self->writeEeprom("$address",'3','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom("$address",'3','0');}
        if ($musttoggle) {$self->quietToggle();}
        if ($verbose){
                if ($writestatus eq 'OK') {print"ATT set to $value sucessfull!\n";}
                else {print"ATT set to $value failed!!!\n";}
                     }
return $writestatus;
            }

############## IPO

        if ($option eq 'IPO') {
        my ($currentipo) = @_;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        $currentipo = $self->readMemvfo("$vfo","$band","$option");
        $self->setVerbose(1);
        if ($value eq $currentipo){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                  }
        $offset=0x02;
        $address = $self->hexAdder("$offset","$base");
        if ($musttoggle) {$self->quietToggle();}
        if($value eq 'ON'){$writestatus = $self->writeEeprom("$address",'2','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom("$address",'2','0');}
        if ($musttoggle) {$self->quietToggle();}
        if ($verbose){
                if ($writestatus eq 'OK') {print"IPO set to $value sucessfull!\n";}
                else {print"IPO set to $value failed!!!\n";}
                     }
return $writestatus;
            }

############## FM STEP

        if ($option eq 'FMSTEP') {
        my ($currentfmstep) = @_;
        $self->setVerbose(0);
        $currentfmstep = $self->readMemvfo("$vfo","$band","$option");
        $self->setVerbose(1);
        if ($value eq $currentfmstep){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                     }
        $offset=0x03;
        $address = $self->hexAdder("$offset","$base");
        my $fmstep;
        my %fmstephash = reverse %FMSTEP;
        ($fmstep) = grep { $fmstephash{$_} eq $value } keys %fmstephash;
        if (!$fmstep){
                if($verbose){
		print "\nInvalid Option. Choose from the following\n\n";
                my $columns = 1;
                foreach my $codes (sort keys %fmstephash) {
                printf "%-15s %s",$fmstephash{$codes};
                $columns++;
                if ($columns == 7){print "\n\n"; $columns = 1;}
                                                          }
                print "\n\n";
			    }
return 1;
                     }
        my $BYTE1 = $self->eepromDecode("$address");
        substr ($BYTE1, 5, 3, "$fmstep");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        if ($musttoggle) {$self->quietToggle();}
        $writestatus = $self->writeBlock("$address","$NEWHEX");
        if ($musttoggle) {$self->quietToggle();}
        if($verbose){
                if ($writestatus eq 'OK') {print"FM STEP Set to $option sucessfull!\n";}
                else {print"FM STEP set failed: $writestatus\n";}
                    }
return $writestatus;
                             }

############## AM STEP

        if ($option eq 'AMSTEP') {
        my ($currentamstep) = @_;
        $self->setVerbose(0);
        $currentamstep = $self->readMemvfo("$vfo","$band","$option");
        $self->setVerbose(1);
        if ($value eq $currentamstep){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                     }
         $offset=0x03;
         $address = $self->hexAdder("$offset","$base");
         my $amstep;
         my %amstephash = reverse %AMSTEP;
         ($amstep) = grep { $amstephash{$_} eq $value } keys %amstephash;
         if (!$amstep){
                if($verbose){
		print "\nInvalid Option. Choose from the following\n\n";
                my $columns = 1;
                foreach my $codes (sort keys %amstephash) {
                printf "%-15s %s",$amstephash{$codes};
                $columns++;
                if ($columns == 7){print "\n\n"; $columns = 1;}
                                                          }
                print "\n\n";
                           }
return 1;
                     }
        my $BYTE1 = $self->eepromDecode("$address");
        substr ($BYTE1, 2, 3, "$amstep");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        if ($musttoggle) {$self->quietToggle();}
        $writestatus = $self->writeBlock("$address","$NEWHEX");
        if ($musttoggle) {$self->quietToggle();}
        if($verbose){
                if ($writestatus eq 'OK') {print"AM STEP Set to $option sucessfull!\n";}
                else {print"AM STEP set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

############## SSB STEP

        if ($option eq 'SSBSTEP') {
        my ($currentssbstep) = @_;
        if ($value ne '1.0' && $value ne '2.5' && $value ne '5.0'){
                if($verbose){print "Value invalid: Choose 1.0/2.5/5.0\n\n"; }
return 1;
                                                                  }
        $self->setVerbose(0);
        $currentssbstep = $self->readMemvfo("$vfo","$band","$option");
        $self->setVerbose(1);
        if ($value eq $currentssbstep){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                     }
                $offset=0x03;
                $address = $self->hexAdder("$offset","$base");
        my $BYTE1 = $self->eepromDecode("$address");
        if ($value eq '1.0'){substr ($BYTE1, 0, 2, '00');}
        if ($value eq '2.5'){substr ($BYTE1, 0, 2, '01');}
        if ($value eq '5.0'){substr ($BYTE1, 0, 2, '10');}
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        if ($musttoggle) {$self->quietToggle();}
        $writestatus = $self->writeBlock("$address","$NEWHEX");
        if ($musttoggle) {$self->quietToggle();}
        if($verbose){
                if ($writestatus eq 'OK') {print"SSB STEP Set to $value sucessfull!\n";}
                else {print"SSB STEP set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

############## CTCSSTONE
 
        if ($option eq 'CTCSSTONE') {
        my ($currenttone) = @_;
        $self->setVerbose(0);
        $currenttone = $self->readMemvfo("$vfo","$band","$option");
        $self->setVerbose(1);
        if ($value eq $currenttone){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                     }
        $offset=0x06;
        $address = $self->hexAdder("$offset","$base");
        my $ctcsstone;
        my %tonehash = reverse %CTCSSTONES;
        ($ctcsstone) = grep { $CTCSSTONES{$_} eq $value } keys %CTCSSTONES;
        if (!$ctcsstone){
                if($verbose){
		print "\nInvalid Option. Choose from the following\n\n";
                my $columns = 1;
                foreach my $tones (sort keys %CTCSSTONES) {
                printf "%-15s %s",$CTCSSTONES{$tones};
                $columns++;
                if ($columns == 7){print "\n\n"; $columns = 1;}
                                                          }
                print "\n\n";
                            }
return 1;
                        }
        my $BYTE1 = $self->eepromDecode("$address");
        substr ($BYTE1, 2, 6, "$ctcsstone");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        if ($musttoggle) {$self->quietToggle();}
        $writestatus = $self->writeBlock("$address","$NEWHEX");
        if ($musttoggle) {$self->quietToggle();}
        if($verbose){
                if ($writestatus eq 'OK') {print"CTCSS TONE Set to $option sucessfull!\n";}
                else {print"CTCSS TONE set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

############## DCSCODE

        if ($option eq 'DCSCODE') {
        my ($currentcode) = @_;
        $self->setVerbose(0);
        $currentcode = $self->readMemvfo("$vfo","$band","$option");
        $self->setVerbose(1);
        if ($value eq $currentcode){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                   }
        $offset=0x07;
        $address = $self->hexAdder("$offset","$base");
        my $dcscode;
        my %codehash = reverse %DCSCODES;
        ($dcscode) = grep { $DCSCODES{$_} eq $value } keys %DCSCODES;
        if (!$dcscode){
                if($verbose){
		print "\nInvalid Option. Choose from the following\n\n";
                my $columns = 1;
                foreach my $codes (sort keys %DCSCODES) {
                printf "%-15s %s",$DCSCODES{$codes};
                $columns++;
                if ($columns == 7){print "\n\n"; $columns = 1;}
                                                        }
                print "\n\n";
                           }
return 1;
                     }

        my $BYTE1 = $self->eepromDecode("$address");
        substr ($BYTE1, 1, 7, "$dcscode");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        if ($musttoggle) {$self->quietToggle();}
        $writestatus = $self->writeBlock("$address","$NEWHEX");
        if ($musttoggle) {$self->quietToggle();}
        if($verbose){
                if ($writestatus eq 'OK') {print"DCS CODE Set to $option sucessfull!\n";}
                else {print"DCS CODE set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

############## CLAROFFSET

        if ($option eq 'CLAROFFSET') {
        my ($currentoffset,$polarity,$newvalue,$endvalue,$binvalue,$bin1,$bin2) = @_;
        $polarity = substr ($value,0,1);
        $newvalue = substr ($value,1);
        if ($value != '0' && $polarity ne '+' && $polarity ne '-'){
                if($verbose){print "Value invalid: Choose -9.99 to +9.99 (needs + or - with number)\n\n";}
return 1;
                                                                  }

        if ($newvalue < 0 || $newvalue > 999){
                if($verbose){print "Value invalid: Choose -9.99 to +9.99 (Multiple of 10)\n\n";}
return 1;
                                                                    }
        $self->setVerbose(0);
        $currentoffset = $self->readMemvfo("$vfo","$band","$option");
        $self->setVerbose(1);

        if ($value eq $currentoffset){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                     }
	$offset=0x08;
        $address = $self->hexAdder("$offset","$base");
	$newvalue =~ tr/.//d;
        if ($polarity eq '-'){$newvalue = 65536 - $newvalue;}
        $binvalue = unpack("B32", pack("N", $newvalue));
        $binvalue = substr $binvalue, -16;
        $bin1 = substr $binvalue, 0,8;
        $bin2 = substr $binvalue, 8,8;
        my $NEWHEX1 = sprintf("%X", oct( "0b$bin1" ) );
        my $NEWHEX2 = sprintf("%X", oct( "0b$bin2" ) );
        my $writestatus1 = $self->writeDoubleblock("$address","$NEWHEX1","$NEWHEX2");
                if ($writestatus1 eq 'OK'){if($verbose){print"Clarifier offset set to $value sucessfull!\n";}}
                else {if($verbose){print"Clarifier offset set to $value failed!!!\n";}}
return $writestatus;
                }

############## RXFREQ

       if ($option eq 'RXFREQ') {
       my ($currentrxfreq,$binvalue,$bin1,$bin2,$bin3,$bin4) = @_;
        $self->setVerbose(0);
        $currentrxfreq = $self->readMemvfo("$vfo","$band","$option");
        $self->setVerbose(1);
        if ($value eq $currentrxfreq){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                     }

	my $test = $self->boundryCheck("$band","$value");
        if ($test ne 'OK'){
                if($verbose){print "Our of range\n\n"; }
return 1;
                          }
        $offset=0x0A;
        $address = $self->hexAdder("$offset","$base");
        $offset=0x0C;
        $address3 = $self->hexAdder("$offset","$base");
	my $valuelabel = $value;
        $value =~ tr/.//d;
        $binvalue = unpack("B32", pack("N", $value));
        $bin1 = substr $binvalue, 0,8;
        $bin2 = substr $binvalue, 8,8;
        $bin3 = substr $binvalue, 16,8;
        $bin4 = substr $binvalue, 24,8;
        my $NEWHEX1 = sprintf("%X", oct( "0b$bin1" ) );
        my $NEWHEX2 = sprintf("%X", oct( "0b$bin2" ) );
        my $NEWHEX3 = sprintf("%X", oct( "0b$bin3" ) );
        my $NEWHEX4 = sprintf("%X", oct( "0b$bin4" ) );
        if ($musttoggle) {$self->quietToggle();}
        my $writestatus1 = $self->writeDoubleblock("$address","$NEWHEX1","$NEWHEX2");
        my $writestatus2 = $self->writeDoubleblock("$address3","$NEWHEX3","$NEWHEX4");
        if ($musttoggle) {$self->quietToggle();}
        if ($writestatus1 eq $writestatus2) {
                if ($writestatus1 eq 'OK'){if($verbose){print"RX Frequency set to $valuelabel sucessfull!\n";}}
                                            }
                else {if($verbose){print"RX Frequency set to $valuelabel failed!!!\n";}}
return $writestatus;
                }

############## RPTOFFSETFREQ

       if ($option eq 'RPTOFFSETFREQ') {
       my ($currentoffset,$binvalue,$bin1,$bin2,$bin3) = @_;
       if ($value < 0 || $value > 9999){
                if($verbose){print "Value invalid: Choose 0 to 99.99\n\n";}
return 1;
                                       }
        $self->setVerbose(0);
        $currentoffset = $self->readMemvfo("$vfo","$band","$option");
        $self->setVerbose(1);
        if ($value eq $currentoffset){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                     }
        $offset=0x0F;
        $address = $self->hexAdder("$offset","$base");
        $offset=0x11;
        $address3 = $self->hexAdder("$offset","$base");
        $value =~ tr/.//d;
	$value = $value * 1000;
        $binvalue = unpack("B32", pack("N", $value));
        $bin1 = substr $binvalue, 8,8;
        $bin2 = substr $binvalue, 16,8;
        $bin3 = substr $binvalue, 24,8;
        my $NEWHEX1 = sprintf("%X", oct( "0b$bin1" ) );
        my $NEWHEX2 = sprintf("%X", oct( "0b$bin2" ) );
        my $NEWHEX3 = sprintf("%X", oct( "0b$bin3" ) );
        if ($musttoggle) {$self->quietToggle();}
        my $writestatus1 = $self->writeDoubleblock("$address","$NEWHEX1","$NEWHEX2");
        my $writestatus3 = $self->writeBlock("$address3","$NEWHEX3");
        if ($musttoggle) {$self->quietToggle();}
        if ($writestatus1 eq $writestatus3) {
                if ($writestatus1 eq 'OK'){if($verbose){print"Repeater offset set to $value sucessfull!\n"}}
                                            }
                else {if($verbose){print"Repeater offset set to $value failed!!!\n";}}
return $writestatus;
                }
                }

# 44F ################################# SET CURRENT MEM
###################################### CHANGE ALL BITS FROM ADDRESS 0X44F

sub setCurrentmem {
        my ($currentcurrentmem) = @_;
        my $self=shift;
        my $value=shift;
	my $firstvalue = $value;
	if ($value eq 'M-PL'){$value = '201'};
        if ($value eq 'M-PU'){$value = '202'};	
	$value--;
        if ($value < 0 || $value > 202){
                if($verbose){print "Value invalid: Choose a number between 0 and 200, or M-PL / M-PU\n\n";}
return 1;
                                       }

        if (length($value) == 0){
                if($verbose){print "Value invalid: Choose a number between 0 and 200 or M-PL / M-PU\n\n";}
return 1;
                                }
        $self->setVerbose(0);
        $currentcurrentmem = $self->getCurrentmem();
        $self->setVerbose(1);
        if ($value eq $currentcurrentmem + 1){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                             }
        my $binvalue = dec2bin($value);
        my $NEWHEX = sprintf("%X", oct( "0b$binvalue" ) );
        $writestatus = $self->writeBlock('044F',"$NEWHEX");
        if($verbose){
                if ($writestatus eq 'OK') {print"Current Memory set to $firstvalue sucessfull!\n";}
                else {print"Current Memory set failed: $writestatus\n";}
                    }
return $writestatus;
                 }


# 450 - 46A  ############## ENABLE / DISABLE MEMORY AREA ######
###################################### 

sub setMemarea {
        my $self=shift;
        my $number = shift;
        my $startaddress = '0450';
        my $value = shift;
        if ($writeallow != '1' and $agreewithwarning != '1') {
                if($debug || $verbose){print"Writing to EEPROM disabled, use setWriteallow(1) to enable\n";}
                $writestatus = "Write Disabled";
return $writestatus;
                          }
        if ($number eq 'M-PL'){$number = 201;}
        if ($number eq 'M-PU'){$number = 202;}
        if ($number == 1){
        if($verbose){print "Memory [$number] Cannot be changed, and must remain ACTIVE\n"};
return 1;
                         }
        if ($number < 2 || $number > 202){
        if($verbose){print "Memory [$number] invalid. Must be between 2 and 200 or M-PL / M-PU\n"};
return 1;
                                        }
        if ($value ne 'ACTIVE' && $value ne 'INACTIVE') {
                if($verbose){print "Option [$value] for Memory [$number] invalid. Choose ACTIVE / INACTIVE\n"};
return 1;
                                                        }
        $self->setVerbose(0);
        my $currentvalue = $self->getMemmap("$number");
        $self->setVerbose(1);
        if ($value eq $currentvalue) {
                if($verbose){print "Memory [$number] Already $value\n"};
return 1;
                                     }
	my $valuetag = $value;
        if ($value eq 'ACTIVE'){$value = '1';}
        if ($value eq 'INACTIVE'){$value = '0';}
        my $register = int(($number - 1) / 8);
        my $checkbit = ($number - (8 * ($register + 1))) * -1;
        my $address = $self->hexAdder("$register","$startaddress");
        $writestatus = $self->writeEeprom("$address","$checkbit","$value"); 
        if($verbose){print "Memory area [$number] set to $valuetag\n"};
        $self->setVerbose(0);
        my $isready = $self->readMemory('MEM',"$number",'READY');
	if ($isready eq 'NO'){$self->writeMemory('MEM',"$number",'READY');}
        $self->setVerbose(1);
return $writestatus;
               }

# 389 - 40A / 484 - 1907 ############## WRITE MEMORY INFO ######
###################################### 

sub writeMemory {
        my ($testvfoband, $address, $address2, $address3, $address4, $testoptions, $base, %baseaddress, $musttoggle, $hometoggle, $offset, $startaddress, $fmstep, $amstep, $ctcsstone, $dcscode, $polarity, $newvalue) = @_;
        my $self=shift;
        my $type=shift;
        my $subtype=shift;
	my $option = shift;
	my $value=shift;
        if ($writeallow != '1' and $agreewithwarning != '1') {
                if($debug || $verbose){print"Writing to EEPROM disabled, use setWriteallow(1) to enable\n";}
                $writestatus = "Write Disabled";
return $writestatus;
                          }
        my $newlabel = "CH-$subtype";
	$type = uc($type);
	$subtype = uc($subtype);
        $option = uc($option);
        if ($subtype eq 'M-PL') {$subtype = '201';}
        if ($subtype eq 'M-PU') {$subtype = '202';}
        my $memnum = $subtype;
        my $multiple;
        my %memoryhash = ();
        if (!$value) {$value = 'ALL';}
        if ($type ne 'HOME' && $type ne 'QMB' && $type ne 'M-PL' && $type ne 'M-PU' && $type ne 'MEM') {
                if($verbose){print "Value invalid: Choose HOME / QMB / M-PL / M-PU / MEM\n\n";}
return 1;
                                                                                                       }
        my %testhash = reverse %MEMORYOPTS;
        ($testoptions) = grep { $testhash{$_} eq $option } keys %testhash;
        if (!$testoptions && $value ne 'ALL'){
                if($verbose){
                print "Choose a valid option, or no option for ALL\.\n\n";
                my $columns = 1;
                foreach my $options (sort keys %testhash) {
                printf "%-15s %s",$testhash{$options};
                $columns++;
                if ($columns == 7){print "\n\n"; $columns = 1;}
                                                          }
                print "\n\n";
                            }
return 1;
                                             }
        if ($type eq 'HOME'){%baseaddress = reverse %HOMEBASE;}
        if ($type eq 'QMB'){%baseaddress = reverse %MEMORYBASE; $subtype = 'QMB';}
        if ($type eq 'MEM'){%baseaddress = reverse %MEMORYBASE; $subtype = 'MEM'}
        ($base) = grep { $baseaddress{$_} eq $subtype } keys %baseaddress;
        if ($type eq 'MEM'){
                if ($memnum > 1) {
                        $multiple = ($memnum - 1) * 26;
                        $base = $self->hexAdder("$multiple","$base");
                                 }
                            }
        if (!$base) {
                if($verbose){print "Command is malformed, check your syntax!!!\n\n";}
return 1;
                    }
	if ($type eq 'MEM') {$subtype = "$memnum";}
        $self->setVerbose(0);
        my $currenttuner = $self->getTuner();
        my $ishome =  $self->getHome();
	my $isqmb =  $self->getQmb();
        $self->setVerbose(1);
        if ($type eq 'HOME' && $ishome eq 'Y'){$hometoggle = 'TRUE';}
        if ($currenttuner eq 'MEMORY') {
                if ($type eq 'QMB' && $isqmb eq 'ON'){$musttoggle = 'TRUE';}
                if ($type eq 'MEM'){$musttoggle = 'TRUE';}
				       }

############# Check to format new memory area
        $self->setVerbose(0);
	my $isready = $self->readMemory("$type","$subtype",'READY');
        $self->setVerbose(1);
        if ($isready eq 'NO'){
                if($verbose){print "This memory area has not yet been formatted. Loading default format...\nThis may take a minute....\n";}
         		if ($hometoggle) {$self->quietHometoggle();}
        		if ($musttoggle) {$self->quietTunetoggle();}
        my $cycles = 0x00;
	my $cycles2 = $cycles + 1;
        $offset = 0x00;
        my $address = $self->hexAdder("$offset","$base");
        my $newaddress;
	my $HEXVALUE;
	my $HEXVALUE2;
        if ($verbose){print "Writing: Please Wait....\n";}
        if ($hometoggle) {$self->quietHometoggle();}
        if ($musttoggle) {$self->quietTunetoggle();}
do {
        $HEXVALUE = $NEWMEM["$cycles"];
	$HEXVALUE2 = $NEWMEM["$cycles2"];
	if($verbose){print $cycles2 + 1;print " of 18 BYTES Written\n";}
        $newaddress = $self->hexAdder("$cycles","$address");
        $self->writeDoubleblock("$newaddress","$HEXVALUE","$HEXVALUE2");
        $cycles = $cycles + 2;
	$cycles2 = $cycles +1;
   }
while ($cycles < 18);
	if($verbose){print "\nWriting label $newlabel\n";}
	$self->writeMemory("$type","$subtype","LABEL","$newlabel");
	if ($hometoggle) {$self->quietHometoggle();}
 	if ($musttoggle) {$self->quietTunetoggle();}
                             }

############## MODE
       if ($option eq 'MODE') {
       my ($currentmode) = @_;
        $self->setVerbose(0);
        $currentmode = $self->readMemory("$type","$subtype","$option");
        $self->setVerbose(1);
        if ($value eq $currentmode){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                   }
        $offset=0x00;
        $address = $self->hexAdder("$offset","$base");
        my $mode;
        my %modehash = reverse %MEMMODES;
        ($mode) = grep { $modehash{$_} eq $value } keys %modehash;
        if (!$mode){
                if($verbose){
                print "\nInvalid Option. Choose from the following\n\n";
                my $columns = 1;
                foreach my $codes (sort keys %modehash) {
                printf "%-15s %s",$modehash{$codes};
                $columns++;
                if ($columns == 7){print "\n\n"; $columns = 1;}
                                                        }
                print "\n\n";
                             }
return 1;
                   }
        my $BYTE1 = $self->eepromDecode("$address");
        substr ($BYTE1, 5, 3, "$mode");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        if ($hometoggle) {$self->quietHometoggle();}
        if ($musttoggle) {$self->quietTunetoggle();}
        $writestatus = $self->writeBlock("$address","$NEWHEX");
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($hometoggle) {$self->quietHometoggle();}
        if($verbose){
                if ($writestatus eq 'OK') {print"MODE Set to $option sucessfull!\n";}
                else {print"MODE set failed: $writestatus\n";}
                    }
return $writestatus;
                            }

############## TAG

       if ($option eq 'TAG') {
       my ($currenttag) = @_;

       if ($value ne 'LABEL' && $value ne 'FREQUENCY'){
                if($verbose){print "Value invalid: Choose LABEL/FREQUENCY\n\n";}
return 1;
                                                      }
        $self->setVerbose(0);
        $currenttag = $self->readMemory("$type","$subtype","$option");
        $self->setVerbose(1);
        if ($value eq $currenttag){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                  }
        $offset=0x00;
        $address = $self->hexAdder("$offset","$base");
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($hometoggle) {$self->quietHometoggle();}
        if($value eq 'LABEL'){$writestatus = $self->writeEeprom("$address",'0','1');}
        if($value eq 'FREQUENCY'){$writestatus = $self->writeEeprom("$address",'0','0');}
        if ($hometoggle) {$self->quietHometoggle();}
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($verbose){
                if ($writestatus eq 'OK') {print"TAG set to $value sucessfull!\n";}
                else {print"TAG set to $value failed!!!\n";}
                     }
return $writestatus;
            }

############## NARFM

       if ($option eq 'NARFM') {
       my ($currentnarfm) = @_;

       if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                             }
        $self->setVerbose(0);
        $currentnarfm = $self->readMemory("$type","$subtype","$option");
        $self->setVerbose(1);
        if ($value eq $currentnarfm){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                    }
        $offset=0x01;
        $address = $self->hexAdder("$offset","$base");
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($hometoggle) {$self->quietHometoggle();}
        if($value eq 'ON'){$writestatus = $self->writeEeprom("$address",'4','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom("$address",'4','0');}
        if ($hometoggle) {$self->quietHometoggle();}
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($verbose){
                if ($writestatus eq 'OK') {print"NAR FM set to $value sucessfull!\n";}
                else {print"NAR FM set to $value failed!!!\n";}
                     }
return $writestatus;
            }

############## NARCWDIG

       if ($option eq 'NARCWDIG') {
       my ($currentnarcwdig) = @_;

       if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                             }
        $self->setVerbose(0);
        $currentnarcwdig = $self->readMemory("$type","$subtype","$option");
        $self->setVerbose(1);
        if ($value eq $currentnarcwdig){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                       }
        $offset=0x01;
        $address = $self->hexAdder("$offset","$base");
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($hometoggle) {$self->quietHometoggle();}
        if($value eq 'ON'){$writestatus = $self->writeEeprom("$address",'3','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom("$address",'3','0');}
        if ($hometoggle) {$self->quietHometoggle();}
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($verbose){
                if ($writestatus eq 'OK') {print"NAR CW DIG set to $value sucessfull!\n";}
                else {print"NAR CW DIG set to $value failed!!!\n";}
                     }
return $writestatus;
            }

############## RPTOFFSET

       if ($option eq 'RPTOFFSET') {
       my ($currentrptoffset) = @_;
       if ($value ne 'SIMPLEX' && $value ne 'MINUS'  && $value ne 'PLUS' && $value ne 'NON-STANDARD'){
                if($verbose){print "Value invalid: Choose SIMPLEX/MINUS/PLUS/NON-STANDARD\n\n"; }
return 1;
                                                                                                     }
        $self->setVerbose(0);
        $currentrptoffset = $self->readMemory("$type","$subtype","$option");
        $self->setVerbose(1);
        if ($value eq $currentrptoffset){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                        }
        $offset=0x01;
        $address = $self->hexAdder("$offset","$base");
        my $BYTE1 = $self->eepromDecode("$address");
        if ($value eq 'SIMPLEX'){substr ($BYTE1, 0, 2, '00');}
        if ($value eq 'MINUS'){substr ($BYTE1, 0, 2, '01');}
        if ($value eq 'PLUS'){substr ($BYTE1, 0, 2, '10');}
        if ($value eq 'NON-STANDARD'){substr ($BYTE1, 0, 2, '11');}
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        if ($hometoggle) {$self->quietHometoggle();}
        if ($musttoggle) {$self->quietTunetoggle();}
        $writestatus = $self->writeBlock("$address","$NEWHEX");
        if ($hometoggle) {$self->quietHometoggle();}
        if ($musttoggle) {$self->quietTunetoggle();}
        if($verbose){
                if ($writestatus eq 'OK') {print"RPTOFFSET Set to $value sucessfull!\n";}
                else {print"RPT OFFSET set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

############## TONEDCS

       if ($option eq 'TONEDCS') {
       my ($currenttonedcs) = @_;
       if ($value ne 'OFF' && $value ne 'TONE'  && $value ne 'TONETSQ' && $value ne 'DCS'){
                if($verbose){print "Value invalid: Choose OFF/TONE/TONETSQ/DCS\n\n"; }
return 1;
                                                                                          }
        $self->setVerbose(0);
        $currenttonedcs = $self->readMemory("$type","$subtype","$option");
        $self->setVerbose(1);
        if ($value eq $currenttonedcs){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                      }
        $offset=0x04;
        $address = $self->hexAdder("$offset","$base");
        my $BYTE1 = $self->eepromDecode("$address");
        if ($value eq 'OFF'){substr ($BYTE1, 6, 2, '00');}
        if ($value eq 'TONE'){substr ($BYTE1, 6, 2, '01');}
        if ($value eq 'TONETSQ'){substr ($BYTE1, 6, 2, '10');}
        if ($value eq 'DCS'){substr ($BYTE1, 6, 2, '11');}
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        if ($hometoggle) {$self->quietHometoggle();}
        if ($musttoggle) {$self->quietTunetoggle();}
        $writestatus = $self->writeBlock("$address","$NEWHEX");
        if ($hometoggle) {$self->quietHometoggle();}
        if ($musttoggle) {$self->quietTunetoggle();}
        if($verbose){
                if ($writestatus eq 'OK') {print"TONEDCS Set to $value sucessfull!\n";}
                else {print"TONEDCS set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

############## ATT

       if ($option eq 'ATT') {
       my ($currentatt) = @_;

       if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                             }
        $self->setVerbose(0);
        $currentatt = $self->readMemory("$type","$subtype","$option");
        $self->setVerbose(1);
        if ($value eq $currentatt){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                  }
        $offset=0x02;
        $address = $self->hexAdder("$offset","$base");
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($hometoggle) {$self->quietHometoggle();}
        if($value eq 'ON'){$writestatus = $self->writeEeprom("$address",'3','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom("$address",'3','0');}
        if ($hometoggle) {$self->quietHometoggle();}
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($verbose){
                if ($writestatus eq 'OK') {print"ATT set to $value sucessfull!\n";}
                else {print"ATT set to $value failed!!!\n";}
                     }
return $writestatus;
            }

############## IPO

       if ($option eq 'IPO') {
       my ($currentipo) = @_;

       if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                             }
        $self->setVerbose(0);
        $currentipo = $self->readMemory("$type","$subtype","$option");
        $self->setVerbose(1);
        if ($value eq $currentipo){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                  }
        $offset=0x02;
        $address = $self->hexAdder("$offset","$base");
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($hometoggle) {$self->quietHometoggle();}
        if($value eq 'ON'){$writestatus = $self->writeEeprom("$address",'2','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom("$address",'2','0');}
        if ($hometoggle) {$self->quietHometoggle();}
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($verbose){
                if ($writestatus eq 'OK') {print"IPO set to $value sucessfull!\n";}
                else {print"IPO set to $value failed!!!\n";}
                     }
return $writestatus;
            }

############## FM STEP

        if ($option eq 'FMSTEP') {
        my ($currentfmstep) = @_;
        $self->setVerbose(0);
        $currentfmstep = $self->readMemory("$type","$subtype","$option");
        $self->setVerbose(1);
        if ($value eq $currentfmstep){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                     }
        $offset=0x03;
        $address = $self->hexAdder("$offset","$base");
        my $fmstep;
        my %fmstephash = reverse %FMSTEP;
        ($fmstep) = grep { $fmstephash{$_} eq $value } keys %fmstephash;
        if (!$fmstep){
                if($verbose){
                print "\nInvalid Option. Choose from the following\n\n";
                my $columns = 1;
                foreach my $codes (sort keys %fmstephash) {
                printf "%-15s %s",$fmstephash{$codes};
                $columns++;
                if ($columns == 7){print "\n\n"; $columns = 1;}
                                                          }
                print "\n\n";
                            }
return 1;
                     }
        my $BYTE1 = $self->eepromDecode("$address");
        substr ($BYTE1, 5, 3, "$fmstep");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        if ($hometoggle) {$self->quietHometoggle();}
        if ($musttoggle) {$self->quietTunetoggle();}
        $writestatus = $self->writeBlock("$address","$NEWHEX");
        if ($hometoggle) {$self->quietHometoggle();}
        if ($musttoggle) {$self->quietTunetoggle();}
        if($verbose){
                if ($writestatus eq 'OK') {print"FM STEP Set to $option sucessfull!\n";}
                else {print"FM STEP set failed: $writestatus\n";}
                    }
return $writestatus;
                             }

############## AM STEP

        if ($option eq 'AMSTEP') {
        my ($currentamstep) = @_;
        $self->setVerbose(0);
        $currentamstep = $self->readMemory("$type","$subtype","$option");
        $self->setVerbose(1);
        if ($value eq $currentamstep){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                     }
         $offset=0x03;
         $address = $self->hexAdder("$offset","$base");
         my $amstep;
         my %amstephash = reverse %AMSTEP;
         ($amstep) = grep { $amstephash{$_} eq $value } keys %amstephash;
         if (!$amstep){
                if($verbose){
                print "\nInvalid Option. Choose from the following\n\n";
                my $columns = 1;
                foreach my $codes (sort keys %amstephash) {
                printf "%-15s %s",$amstephash{$codes};
                $columns++;
                if ($columns == 7){print "\n\n"; $columns = 1;}
                                                          }
                print "\n\n";
                           }
return 1;
                     }
        my $BYTE1 = $self->eepromDecode("$address");
        substr ($BYTE1, 2, 3, "$amstep");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        if ($hometoggle) {$self->quietHometoggle();}
        if ($musttoggle) {$self->quietTunetoggle();}
        $writestatus = $self->writeBlock("$address","$NEWHEX");
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($hometoggle) {$self->quietHometoggle();}
       if($verbose){
                if ($writestatus eq 'OK') {print"AM STEP Set to $option sucessfull!\n";}
                else {print"AM STEP set failed: $writestatus\n";}
                   }
return $writestatus;
                 }
        if ($option eq 'SSBSTEP') {
        my ($currentssbstep) = @_;
        if ($value ne '1.0' && $value ne '2.5' && $value ne '5.0'){
                if($verbose){print "Value invalid: Choose 1.0/2.5/5.0\n\n";}
return 1;
                                                                  }
        $self->setVerbose(0);
        $currentssbstep = $self->readMemory("$type","$subtype","$option");
        $self->setVerbose(1);
        if ($value eq $currentssbstep){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                      }
                $offset=0x03;
                $address = $self->hexAdder("$offset","$base");
        my $BYTE1 = $self->eepromDecode("$address");
        if ($value eq '1.0'){substr ($BYTE1, 0, 2, '00');}
        if ($value eq '2.5'){substr ($BYTE1, 0, 2, '01');}
        if ($value eq '5.0'){substr ($BYTE1, 0, 2, '10');}
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($hometoggle) {$self->quietHometoggle();}
        $writestatus = $self->writeBlock("$address","$NEWHEX");
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($hometoggle) {$self->quietHometoggle();}
        if($verbose){
                if ($writestatus eq 'OK') {print"SSB STEP Set to $value sucessfull!\n";}
                else {print"SSB STEP set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

############## CTCSSTONE
 
        if ($option eq 'CTCSSTONE') {
        my ($currenttone) = @_;
        $self->setVerbose(0);
        $currenttone = $self->readMemory("$type","$subtype","$option");
        $self->setVerbose(1);
        if ($value eq $currenttone){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                   }
        $offset=0x06;
        $address = $self->hexAdder("$offset","$base");
        my $ctcsstone;
        my %tonehash = reverse %CTCSSTONES;
        ($ctcsstone) = grep { $CTCSSTONES{$_} eq $value } keys %CTCSSTONES;
        if (!$ctcsstone){
                if($verbose){
                print "\nInvalid Option. Choose from the following\n\n";
                my $columns = 1;
                foreach my $tones (sort keys %CTCSSTONES) {
                printf "%-15s %s",$CTCSSTONES{$tones};
                $columns++;
                if ($columns == 7){print "\n\n"; $columns = 1;}
                                                          }
                print "\n\n";
                            }
return 1;
                        }
        my $BYTE1 = $self->eepromDecode("$address");
        substr ($BYTE1, 2, 6, "$ctcsstone");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($hometoggle) {$self->quietHometoggle();}
        $writestatus = $self->writeBlock("$address","$NEWHEX");
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($hometoggle) {$self->quietHometoggle();}
        if($verbose){
                if ($writestatus eq 'OK') {print"CTCSS TONE Set to $option sucessfull!\n";}
                else {print"CTCSS TONE set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

############## CLARIFTER

        if ($option eq 'CLARIFIER') {
        my ($currentclarifier) = @_;
        if ($value ne 'ON' && $value ne 'OFF'){
                if($verbose){print "Value invalid: Choose ON/OFF\n\n";}
return 1;
                                              }
        $self->setVerbose(0);
        $currentclarifier = $self->readMemory("$type","$subtype","$option");
        $self->setVerbose(1);
        if ($value eq $currentclarifier){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                        }
        $offset=0x02;
        $address = $self->hexAdder("$offset","$base");
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($hometoggle) {$self->quietHometoggle();}
        if($value eq 'ON'){$writestatus = $self->writeEeprom("$address",'1','1');}
        if($value eq 'OFF'){$writestatus = $self->writeEeprom("$address",'1','0');}
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($hometoggle) {$self->quietHometoggle();}
        if ($verbose){
                if ($writestatus eq 'OK') {print"CLARIFIER set to $value sucessfull!\n";}
                else {print"CLARIFIER set to $value failed!!!\n";}
                     }
return $writestatus;
            }

############## CLAROFFSET

        if ($option eq 'CLAROFFSET') {
        my ($currentoffset,$polarity,$newvalue,$endvalue,$binvalue,$bin1,$bin2) = @_;
        $polarity = substr ($value,0,1);
        $newvalue = substr ($value,1);
        if ($value != '0' && $polarity ne '+' && $polarity ne '-'){
                if($verbose){print "Value invalid: Choose -9.99 to +9.99 (needs + or - with number)\n\n";}
return 1;
                                                                  }
        if ($newvalue < 0 || $newvalue > 999){
                if($verbose){print "Value invalid: Choose -9.99 to +9.99 (Multiple of 10)\n\n";}
return 1;
                                             }
        $self->setVerbose(0);
        $currentoffset = $self->readMemory("$type","$subtype","$option");
        $self->setVerbose(1);
        if ($value eq $currentoffset){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                     }
        $offset=0x08;
        $address = $self->hexAdder("$offset","$base");
        $newvalue =~ tr/.//d;
        if ($polarity eq '-'){$newvalue = 65536 - $newvalue;}
        $binvalue = unpack("B32", pack("N", $newvalue));
        $binvalue = substr $binvalue, -16;
        $bin1 = substr $binvalue, 0,8;
        $bin2 = substr $binvalue, 8,8;
        my $NEWHEX1 = sprintf("%X", oct( "0b$bin1" ) );
        my $NEWHEX2 = sprintf("%X", oct( "0b$bin2" ) );
        if ($hometoggle) {$self->quietHometoggle();}
        if ($musttoggle) {$self->quietTunetoggle();}
        my $writestatus1 = $self->writeDoubleblock("$address","$NEWHEX1","$NEWHEX2");
        if ($hometoggle) {$self->quietHometoggle();}
        if ($musttoggle) {$self->quietTunetoggle();}
                if ($writestatus1 eq 'OK'){if($verbose){print"Clarifier offset set to $value sucessfull!\n";}}
                else {if($verbose){print"Clarifier offset set to $value failed!!!\n";}}
return $writestatus;
	   }

############## DCSCODE

        if ($option eq 'DCSCODE') {
        my ($currentcode) = @_;
        $self->setVerbose(0);
        $currentcode = $self->readMemory("$type","$subtype","$option");
        $self->setVerbose(1);
        if ($value eq $currentcode){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                   }
        $offset=0x07;
        $address = $self->hexAdder("$offset","$base");
        my $dcscode;
        my %codehash = reverse %DCSCODES;
        ($dcscode) = grep { $DCSCODES{$_} eq $value } keys %DCSCODES;
        if (!$dcscode){
                if($verbose){
                print "\nInvalid Option. Choose from the following\n\n";
                my $columns = 1;
                foreach my $codes (sort keys %DCSCODES) {
                printf "%-15s %s",$DCSCODES{$codes};
                $columns++;
                if ($columns == 7){print "\n\n"; $columns = 1;}
                                                        }
                print "\n\n";
                           }
return 1;
                     }
        my $BYTE1 = $self->eepromDecode("$address");
        substr ($BYTE1, 1, 7, "$dcscode");
        my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($hometoggle) {$self->quietHometoggle();}
        $writestatus = $self->writeBlock("$address","$NEWHEX");
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($hometoggle) {$self->quietHometoggle();}
        if($verbose){
                if ($writestatus eq 'OK') {print"DCS CODE Set to $option sucessfull!\n";}
                else {print"DCS CODE set failed: $writestatus\n";}
                    }
return $writestatus;
                 }

############## MEMSKIP

       if ($option eq 'MEMSKIP') {
       my ($currentmemskip) = @_;
       if ($value ne 'YES' && $value ne 'NO'){
                if($verbose){print "Value invalid: Choose YES/NO\n\n";}
return 1;
                                             }
        $self->setVerbose(0);
        $currentmemskip = $self->readMemory("$type","$subtype","$option");
        $self->setVerbose(1);
        if ($value eq $currentmemskip){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                      }
        $offset=0x02;
        $address = $self->hexAdder("$offset","$base");
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($hometoggle) {$self->quietHometoggle();}
        if($value eq 'NO'){$writestatus = $self->writeEeprom("$address",'0','0');}
        if($value eq 'YES'){$writestatus = $self->writeEeprom("$address",'0','1');}
        if ($hometoggle) {$self->quietHometoggle();}
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($verbose){
                if ($writestatus eq 'OK') {print"Memory Skip set to $value sucessfull!\n";}
                else {print"Memory Skip set to $value failed!!!\n";}
                     }
return $writestatus;
            }

############## RXFREQ

       if ($option eq 'RXFREQ') {
       my ($currentrxfreq,$binvalue,$bin1,$bin2,$bin3,$bin4) = @_;
        $self->setVerbose(0);
        $currentrxfreq = $self->readMemory("$type","$subtype","$option");
        $self->setVerbose(1);
        if ($value eq $currentrxfreq){
                if($verbose){print "Value $value already selected.\n\n"; }
return 1;
                                     }
	if ($type eq 'HOME'){
        my $test = $self->boundryCheck("$subtype","$value");
        if ($test ne 'OK'){
                if($verbose){print "Our of range\n\n"; }
return 1;
                          }
			    }
        $offset=0x0A;
        $address = $self->hexAdder("$offset","$base");
        $offset=0x0C;
        $address3 = $self->hexAdder("$offset","$base");
        my $valuelabel = $value;
        $value =~ tr/.//d;
        $binvalue = unpack("B32", pack("N", $value));
        $bin1 = substr $binvalue, 0,8;
        $bin2 = substr $binvalue, 8,8;
        $bin3 = substr $binvalue, 16,8;
        $bin4 = substr $binvalue, 24,8;
        my $NEWHEX1 = sprintf("%X", oct( "0b$bin1" ) );
        my $NEWHEX2 = sprintf("%X", oct( "0b$bin2" ) );
        my $NEWHEX3 = sprintf("%X", oct( "0b$bin3" ) );
        my $NEWHEX4 = sprintf("%X", oct( "0b$bin4" ) );
        if ($hometoggle) {$self->quietHometoggle();}
        if ($musttoggle) {$self->quietTunetoggle();}
        my $tempaddress;
        my $tempoffset=0x01;
        $tempaddress = $self->hexAdder("$tempoffset","$base");
	$self->setVerbose(0);
        my $currentuhf = $self->readMemory("$type","$subtype",'UHF');
	my $currenthfvhf = $self->readMemory("$type","$subtype",'HFVHF');
	my $currentrange = $self->readMemory("$type","$subtype",'FREQRANGE');
	my $newrange = $self->rangeCheck("$value");
# sets UHF bit if needed
	if ($value >= 42000000){
		if ($currentuhf ne 'YES') {
			$writestatus = $self->writeEeprom("$tempaddress",'2','1');}
			                  }
	else {
		if ($currentuhf ne 'NO') {
			$writestatus = $self->writeEeprom("$tempaddress",'2','0');}
	     }
#sets the HF/VHF bit if needed
        $tempoffset=0x00;
        $tempaddress = $self->hexAdder("$tempoffset","$base");
        if ($value >= 5000000){
                if ($currenthfvhf ne 'VHF') {$writestatus = $self->writeEeprom("$tempaddress",'2','0');}
                               }

        else {
                if ($currenthfvhf ne 'HF') {$writestatus = $self->writeEeprom("$tempaddress",'2','1');}
             }
#sets the FREQ RANGE bits if needed
        $tempoffset=0x01;
        $tempaddress = $self->hexAdder("$tempoffset","$base");
	if ($currentrange ne $newrange){
		my $datablock;
	        my $BYTE1 = $self->eepromDecode("$tempaddress");
        	if ($newrange eq 'HF'){substr ($BYTE1, 5, 3, '000');}
        	if ($newrange eq '6M'){substr ($BYTE1, 5, 3, '001');}
        	if ($newrange eq 'FM-BCB'){substr ($BYTE1, 5, 3, '010');}
        	if ($newrange eq 'AIR'){substr ($BYTE1,5, 3, '011');}
        	if ($newrange eq '2M'){substr ($BYTE1, 5, 3, '100');}
        	if ($newrange eq 'UHF'){substr ($BYTE1, 5, 3, '101');}
        	my $NEWHEX = sprintf("%X", oct( "0b$BYTE1" ) );
        	$writestatus = $self->writeBlock("$tempaddress","$NEWHEX");
				       }	
	        $self->setVerbose(1);
        my $writestatus1 = $self->writeDoubleblock("$address","$NEWHEX1","$NEWHEX2");
        my $writestatus3 = $self->writeDoubleblock("$address3","$NEWHEX3","$NEWHEX4");
        if ($hometoggle) {$self->quietHometoggle();}
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($writestatus1 eq $writestatus3) {
                if ($writestatus1 eq 'OK'){if($verbose){print"RX Frequency set to $valuelabel sucessfull!\n";}}
                                            }
                else {if($verbose){print"RX Frequency set to $valuelabel failed!!!\n";}}
return $writestatus;
                }
          
############## RPTOFFSETFREQ

       if ($option eq 'RPTOFFSETFREQ') {
       my ($currentoffset,$binvalue,$bin1,$bin2,$bin3) = @_;
       if ($value < 0 || $value > 9999){
                if($verbose){print "Value invalid: Choose 0 to 99.99\n\n";}
return 1;
                                       }
        $self->setVerbose(0);
        $currentoffset = $self->readMemory("$type","$subtype","$option");
        $self->setVerbose(1);
        if ($value eq $currentoffset){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                     }
        $offset=0x0F;
        $address = $self->hexAdder("$offset","$base");
        $offset=0x11;
        $address3 = $self->hexAdder("$offset","$base");
        $value =~ tr/.//d;
        $value = $value * 1000;
        $binvalue = unpack("B32", pack("N", $value));
        $bin1 = substr $binvalue, 8,8;
        $bin2 = substr $binvalue, 16,8;
        $bin3 = substr $binvalue, 24,8;
        my $NEWHEX1 = sprintf("%X", oct( "0b$bin1" ) );
        my $NEWHEX2 = sprintf("%X", oct( "0b$bin2" ) );
        my $NEWHEX3 = sprintf("%X", oct( "0b$bin3" ) );
        if ($hometoggle) {$self->quietHometoggle();}
        if ($musttoggle) {$self->quietTunetoggle();}
        my $writestatus1 = $self->writeDoubleblock("$address","$NEWHEX1","$NEWHEX2");
        my $writestatus3 = $self->writeBlock("$address3","$NEWHEX3");
        if ($hometoggle) {$self->quietHometoggle();}
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($writestatus1 eq $writestatus3) {
                if ($writestatus1 eq 'OK'){
			if ($verbose){print"Repeater offset set to $value sucessfull!\n";}
					  }
                                            }
        	else {
			if($verbose){print"Repeater offset set to $value failed!!!\n";}
		     }
return $writestatus;
                }

############## LABEL

       if ($option eq 'LABEL') {
       my ($currentlabel,$binvalue,$bin1,$bin2,$bin3,$bin4) = @_;
        $self->setVerbose(0);
        $currentlabel = $self->readMemory("$type","$subtype","$option");
	$self->setVerbose(1);
	my $size = length($value);
        if ($value eq $currentlabel){
                if($verbose){print "Value $value already selected.\n\n";}
return 1;
                                    }
	if (length($value) > 11) {
                if($verbose){print "Label is limited to 8 charcters.\n\n";}
return 1;
				 }
	my @labelarray = split //, $value;
        my $cycles = 0x00;
	my $cycles2 = $cycles + 1;
        my $offset = 0x12;
        my $address = $self->hexAdder("$offset","$base");
	my $newaddress;
	my $letter;
	my $letter2;
	if ($verbose){print "Writing: Please Wait....\n";}
        if ($hometoggle) {$self->quietHometoggle();}
        if ($musttoggle) {$self->quietTunetoggle();}
do {
	$letter = ord($labelarray["$cycles"]);
	$letter2 = ord($labelarray["$cycles2"]);
        if ($letter == '0') {$letter = '32';}
        if ($letter2 == '0') {$letter2 = '32';}
        my $letter = dec2bin("$letter");
        my $letter2 = dec2bin("$letter2");
	$letter = sprintf("%X", oct( "0b$letter" ) );
        $letter2 = sprintf("%X", oct( "0b$letter2" ) );
	$newaddress = $self->hexAdder("$cycles","$address");
        my $writestatus1 = $self->writeDoubleblock("$newaddress","$letter","$letter2");
	$cycles = $cycles +2;
	$cycles2 = $cycles + 1;
   }
while ($cycles < 8);
        if ($hometoggle) {$self->quietHometoggle();}
        if ($musttoggle) {$self->quietTunetoggle();}
        if ($verbose){print "DONE!\n";} 
                }
         }

# 1922 - 1928 ################################# SET ID for CWID ######
###################################### 

sub setId {
        my $self=shift;
        my $value=shift;
        $value = uc($value);
        if (length($value) > 10){
                if($verbose){print "Limited to 7 Characters 0-9 A-Z\n\n";}
return 1;
                               }
        $self->setVerbose(0);
        my $currentid = $self->getId();
        $self->setVerbose(1);
        if ($value eq $currentid){
                if($verbose){print "CW ID already set to $value\n\n";}
return 1;
                                 }
        my @labelarray = split //, $value;
        my $address = 1922;
        my $cycles = 0x00;
	my $cycles2 = $cycles + 1;
        my $newaddress;
        my $letter;
	my $letter2;
do {
        $letter = $labelarray["$cycles"];
        $letter2 = $labelarray["$cycles2"];
        ($letter) = grep { $CWID{$_} eq $letter } keys %CWID;
        ($letter2) = grep { $CWID{$_} eq $letter2 } keys %CWID;
        $newaddress = $self->hexAdder("$cycles","$address");
        my $writestatus1 = $self->writeDoubleblock("$newaddress","$letter","$letter2");
        $cycles = $cycles +2;
	$cycles2 = $cycles + 1;
   }
while ($cycles < 6);

#this writes the last two bits again for address 1928
        $letter = $labelarray[5];
        $letter2 = $labelarray[6];
        ($letter) = grep { $CWID{$_} eq $letter } keys %CWID;
        ($letter2) = grep { $CWID{$_} eq $letter2 } keys %CWID;
        my $writestatus1 = $self->writeDoubleblock('1927',"$letter","$letter2");
print "$writestatus1\n";



        if ($verbose){print "DONE!\n";}
return 0;
          }

################################################## FIN


=head1 NAME

Ham::Device::FT817COMM - Library to control the Yaesu FT817 Ham Radio

=head1 VERSION

Version 0.9.9

=head1 SYNOPSIS

use HAM::Device::FT817COMM;

=head2 Constructor and Port Configurations

	my $FT817 = new Ham::Device::FT817COMM (
	serialport => '/dev/ttyUSB0',
	baud => '38400',
	lockfile => '/var/lock/ft817'
				               );

	my $port = $FT817->{'serialport'};
	my $baud = $FT817->{'baud'};
	my $lockfile = $FT817->{'lockfile'};
	my $version = $FT817->moduleVersion;

=head2 Destructor

	$FT817->closePort;

=head2 Lock File

In the event you abruptly end the software or loose connectivity via ssh.  When attempting to reconnect
you will see the following error.

	Can't open serial port /dev/ttyUSB0: File exists

The lock file can be remove simply by 

	rm /var/lock/ft817 


=head2 Initialization

The instance of the device and options are created with the constructor and port configurations shown above.
The variable which is an instance of the device may be named at that point. In this case B<$FT817>.
The serialport must be a valid port and not locked.  You must consider that your login must have 
permission to access the port either being added to the group or giving the user suffucient privilages.
The baudrate 'baud' must match the baudrate of the radio B<CAT RATE> which is menu item B<14>.

Note that you are not limited to one radio.  You can create more than one instance using a different name and serial port


        my $anotherFT817 = new Ham::Device::FT817COMM (
        serialport => '/dev/ttyUSB1',
        baud => '38400',
        lockfile => '/var/lock/ft817-2'
                                                      );

        my $port = $FT817->{'serialport'};
        my $baud = $FT817->{'baud'};
        my $lockfile = $FT817->{'lockfile'};
        my $version = $FT817->moduleVersion;

REMEMBER!!!! Each instance created needs its own destructor.


Finally B<lockfile> is recommended to ensure that no other software may access the port at the same time.
The lockfile is removed as part of the invocation of the destructor method.


=head1 METHODS

=head2 1. Using Return Data From a Module

This allows for complete control of the rig through the sub routines
all done through the cat interface

        $output = 'rigname'->'command'('value');

an example is a follows

	$output = $FT817->catLock('ON');

Using this method, the output which is collected in the varible B<$output> is designed to be minimal for
use in applications that provide an already formatted output.

For example:
	
	$output = $FT817->catLock('ON');
	print "$output";

Would simply return B<F0> if the command failed and B<00> if the command was sucessfull. The outputs vary
from module to module, depending on the function

=head2 2. Using setVerbose()

The module already has pre-formatted outputs for each subroutine.  Using the same example in a different form
and setting B<setVerbose(1)> we have the following

	setVerbose(1);
	$FT817->catLock('ON');

The output would be, for example:
	
	Set Lock (ENABLE) Sucessfull.

Other verbose outputs exist to catch errors.

	setVerbose(1);
	$FT817->catLock('blabla');

The output would be:

	Set Lock (blabla) Failed. Option:blabla invalid.

An example of both is shown below for the command getHome()

	As return data: Y
	As verbose(1) : At Home Frequency

We see that return data will be suitable for a program which needs just a boolean value.

=head2 3. Build a sub-routine into a condition

Another use can be to use a subrouting as a value in a condition statment to test

	if (($FT817->gethome()) eq 'Y') {
		warn "I guess we're home";
			      }

Call all of the modules, one at a time and look at the outputs, from which you can decide how the data can be used.
At this time I have completed a command line front end for this module that makes testing all of the functionality easy.

=head1 DEBUGGER

FT817COMM has a built in robust debugger that makes available to the user all transactions between the software and the rig.
Where verbose gave the outputs to user initiated subroutines, the debugger does very much the same but with internal functions
not designed to be called directly in the userspace.  That being said, you should never directly call these system functions
or you will quickly turn your 817 into a paperweight or door stop. You have been warned.

Feel free to use the debugger to get an idea as to how the module and the radio communicate.

	$FT817->setDebug(1); # Turns on the debugger

The first output of which is:

	DEBUGGER IS ON

Two distinct type of transactions happen with the debugger, they are:

	CAT commands   :	Commands which use the Yaesu CAT protocol
	EPROMM commands:	Commands which read and write to the EEPROM

With the command: B<catgetMode()> we get the regular output expected, with B<verbose(1)>

	Mode is FM

However with the B<setDebug(1)> we will see the following output to the same command:

	[FT817]@/dev/ttyUSB0$ get mode

	(sendCat:DEBUG) - DATA OUT ------> 00 00 00 00 03

	(sendCat:DEBUG) - BUILT PACKET --> 0000000003

	(sendCat:DEBUG) - DATA IN <------- 1471200008

	Mode is FM
	[FT817]@/dev/ttyUSB0$ 

The sendcat:debug shows the request of B<00 00 00 00 0x03> sent to the rig, and the rig
returning B<1471200008>. What were looking at is the last two digits 08 which is parsed from
the block of data.  08 is mode FM.  FT817COMM does all of the parsing and conversion for you.

As you might have guessed, the first 8 digits are the current frequency, which in this case
is 147.120 MHZ.  The catgetFrequency() module would pull the exact same data, but parse it differently

The debugger works differently on read/write to the eeprom. The next example shown below used the function
B<setArts('OFF')>, the function which tunrs arts off.


	[FT817]@/dev/ttyUSB0$ set arts off

	(eepromDecode:DEBUG) - READING FROM ------> [00x79]

	(eepromDecode:DEBUG) - PACKET BUILT ------> [00790000BB]

	(eepromDecode:DEBUG) - OUTPUT HEX  -------> [81]

	(eepromDecode:DEBUG) - OUTPUT BIN  -------> [10000001]


	(writeEeprom:DEBUG) - OUTPUT FROM [00x79]

	(writeEeprom:DEBUG) - PACKET BUILT ------> [00790000BB]

	(writeEeprom:DEBUG) - BYTE1 (81) BYTE2 (1F) from [00x79]

	(writeEeprom:DEBUG) - BYTE1 BINARY IS [10000001]

	(writeEeprom:DEBUG) - CHANGING BIT(0) to (0)

	(writeEeprom:DEBUG) - BYTE1: BINARY IS [00000001] AFTER CHANGE

	(writeEeprom:DEBUG) - CHECKING IF [1] needs padding

	(writeEeprom:DEBUG) - Padded to [01]

	(writeEeprom:DEBUG) - BYTE1 (01) BYTE2 (1F) to   [00x79]

	(writeEeprom:DEBUG) - WRITING  ----------> (01) (1F)

	(writeEeprom:DEBUG) - PACKET BUILT ------> [0079011fBC]

	(writeEeprom:DEBUG) - VALUES WRITTEN, CHECKING...

	(writeEeprom:DEBUG) - SHOULD BE: (01) (1F)

	(writeEeprom:DEBUG) - IS: -----> (01) (1F)

	(writeEeprom:DEBUG) - VALUES MATCH!!!

	ARTS set to OFF sucessfull!

The output shows all of the transactions and modifications conducted by the system functions


=head1 Modules

=over

=item agreeWithwarning()

		$agree = $FT817->agreeWithwarning(#);

	Turns on and off the internal flag that says. You undrstand the risks of writing to the EEPROM
	Activated when any value is in the (). Good practice says () or (1) for OFF and ON.

	Returns the argument sent to it on success.


=item bitCheck()

                $output = $FT817->bitCheck();

	The function that checks the BITWATCHER hash for changes and throws an Alarm if a change is found
	showing what the change is. The BITWATCHER hash is hard coded in FT817COMM.pm as areas are discovered
	they are removed from the hash.  If an alarm is thrown, look at what function was done in the history log
	and output log to figure out why the value was changed

	[FT817]@/dev/ttyUSB0/:$ bitcheck
	CHANGE FOUND IN MEMORY AREA [0055]: BIT 4 is 0, WAS 1


	If it finds no changes, it will return the following
	[FT817]@/dev/ttyUSB0/:$ bitcheck

	NO CHANGES FOUND

	Returns 'OK' when no change found, 'CHANGE' when a change was found


=item boundryCheck()

                $output = $FT817->boundryCheck([BAND],[FREQUENCY]);
		$output = $FT817->boundryCheck('14m','14.070');

	This is an internal function to check if a frequency is in the correct range
	for the Band given. The ranges are listed in a hash of hashes called %BOUNDRIES

	Returns 'OK' when within range, returns 1 on error


=item catClarifier()

                $setclar = $FT817->catClarifier([ON/OFF]);

        Enables or disables the clarifier

        Returns '00' on success or 'f0' on failure


=item catClarifierfreq()

                $clarifierfreq = $FT817->catClarifierfreq([####]);

        Uses 4 digits as an argument to set the Clarifier frequency.  Leading and trailing zeros required where applicable
         1.234 KHZ would be 1234

        Returns '00' on success or 'f0' on failure


=item catCtcssdcs()

                $ctcssdcs = $FT817->catCtcssdcs({DCS/CTCSS/ENCODER/OFF});

        Sets the CTCSS DCS mode of the radio

        Returns 'OK' on success or something else on failure


=item catCtcsstone()

                $ctcsstone = $FT817->catCtcsstone([####]);

        Uses 4 digits as an argument to set the CTCSS tone.  Leading and trailing zeros required where applicable
         192.8 would be 1928 as an argument

        Returns '00' on success or 'f0' on failure
        On 'f0' verbose(1) displays all valid tones


=item catDcscode()

                $dcscode = $FT817->catDcscode([####]);

        Uses 4 digits as an argument to set the DCS code.  Leading and trailing zeros required where applicable
         0546 would be 546 as an argument

        Returns '00' on success or 'f0' on failure
        On 'f0' verbose(1) displays all valid tones


=item catgetFrequency()

                $frequency = $FT817->catgetFrequency([#]);

        Returns the current frequency of the rig eg. B<14712000> with B<catgetFrequency()>
        Returns the current frequency of the rig eg. B<147.120.00> MHZ with B<catgetFrequency(1)>


=item catgetMode()

                $mode = $FT817->catgetMode();

        Returns the current Mode of the Radio : AM / FM / USB / CW etc.......


=item catLock()

                $setlock = $FT817->catLock([ON/OFF]);

        Enables or disables the radio lock.

        Returns '00' on success or 'f0' on failure


=item catOffsetfreq()

                $offsetfreq = $FT817->catOffsetfreq([########]);

        Uses 8 digits as an argument to set the offset frequency.  Leading and trailing zeros required where applicable
        1.230 MHZ would be 00123000

        Returns '00' on success or 'f0' on failure


=item catOffsetmode()

                $setoffsetmode = $FT817->catOffsetmode([POS/NEG/SIMPLEX]);

        Sets the mode of the radio with one of the valid modes.

        Returns '00' on success or 'f0' on failure


=item catPower()

                $setPower = $FT817->catPower([ON/OFF]);

        Sets the power of the radio on or off. Note that this function, as stated in the manual only works
        Correctly when connected to DC power and NO Battery installed

        Returns '00' on success or 'null' on failure


=item catPtt()

                $setptt = $FT817->catPtt([ON/OFF]);

        Sets the Push to talk of the radio on or off.

        Returns '00' on success or 'f0' on failure


=item catRxstatus()

                $rxstatus = $FT817->catRxstatus([VARIABLES/HASH]);

        Retrieves the status of SQUELCH / S-METER / TONEMATCH / DESCRIMINATOR in one
        command and posts the information when verbose(1).

        Returns with variables as argument $squelch $smeter $smeterlin $desc $match
        Returns with hash as argument %rxstatus


=item catsetFrequency()

                $setfreq = $FT817->catsetFrequency([########]);

        Uses 8 digits as an argument to set the frequency.  Leading and trailing zeros required where applicable
        147.120 MHZ would be 14712000
         14.070 MHZ would be 01407000

        Returns '00' on success or 'f0' on failure


=item catsetMode()

                $setmode = $FT817->catsetMode([LSB/USB/CW/CWR/AM/FM/DIG/PKT/FMN/WFM]);

        Sets the mode of the radio with one of the valid modes.

        Returns '00' on success or 'f0' on failure


=item catSplitfreq()

                $setsplit = $FT817->catSplitfreq([ON/OFF]);

        Sets the radio to split the transmit and receive frequencies

        Returns '00' on success or 'f0' on failure


=item catTxstatus()

                $txstatus = $FT817->catTxstatus([VARIABLES/HASH]);

        Retrieves the status of POWERMETER / PTT / HIGHSWR / SPLIT in one
        command and posts the information when verbose(1).

        Returns with variables as argument $pometer $ptt $highswr $split
        Returns with hash as argument %txstatus


=item catvfoToggle()

                $vfotoggle = $FT817->catvfotoggle();

        Togles the VFO between A and B

        Returns '00' on success or 'f0' on failure


=item closePort()

		$FT817->closePort();

	This function should be executed at the end of the program.  This closes the serial port and removed the lock
	file if applicable.  If you do not use this, and exit abnormally, you will need to manually remove the lock 
	file if it was enabled in the settings.


=item dec2bin()

	Simple internal function for converting decimal to binary. Has no use to the end user.


=item eepromDecode()

	An internal function to retrieve code from an address of the eeprom and convert the first byte to 
	binary, dumping the second byte.


=item eepromDecodenext()

        An internal function to retrieve code from an address of the eeprom  returning hex value of the next
	memory address up.


=item eepromDoubledecode()

        An internal function to retrieve code from an address of the eeprom AND the next memory address up 
        memory address up.


=item get9600mic()

                $b9600mic = $FT817->get9600mic();

        MENU ITEM # 3 - Returns the setting of 9600 MIC 0-100


=item getActivelist()

                $agc = $FT817->getActivelist();

        Returns a list of all Active/Visible memory Channels

	[FT817]@/dev/ttyUSB0/MEMORY[MEM]:# list
	
	ACTIVE MEMORY AREAS
	___________________

	#     LABEL      SKIP   MODE   RXFREQ       ENCODER   TONE/DCS  SHIFT     RPTOFFSET   

	1     The Zoo    NO     FM     147.120.00   TONE      103.5     0.5 Mhz   PLUS     
	2     N4FLA      NO     FM     140.000.00   TONE      103.5     0.5 Mhz   PLUS     
	3     20M PSK    YES    USB    14.070.15    OFF       OFF       0 Mhz     SIMPLEX  
	4     20M JT65   YES    USB    14.076.00    OFF       OFF       0 Mhz     SIMPLEX  
	5     MAR MOBL   YES    USB    14.300.00    OFF       OFF       0 Mhz     SIMPLEX  	


=item getAgc()

		$agc = $FT817->getAgc();

	Returns the current setting of the AGC: AUTO / FAST / SLOW / OFF


=item getAmfmdial()

                $amfmdial = $FT817->getAmfmdial();

        MENU ITEM # 4 - Returns the Disable option of the AM/FM dial ENABLE / DISABLE


=item getAmmic()

                $ammic = $FT817->getAmmic();

        MENU ITEM # 5 - Returns the setting of AM MIC 0-100


=item getAntenna ()

                $antenna = $FT817->getAntenna({HF/6M/FMBCB/AIR/VHF/UHF});
                %antenna = $FT817->getAntenna({ALL});
		%antenna = $FT817->getAntenna();

	Returns the FRONT/BACK configuration of the antenna for the different types of
	bands.  Returns one value when an argument is used.  If the argument ALL or no
	argument is used will print a list of the configurations or all bands and returns
	a hash or the configuration


=item getApotime()

                $apotime = $FT817->getApotime();

        MENU ITEM # 8 - Returns the Auto Power Off time as OFF or 1 - 6 hours


=item getArts ()

		$arts = $FT817->getArts();

	Returns the status of ARTS: ON / OFF


=item getArs144 ()

                $ars144 = $FT817->getArs144();

        MENU ITEM # 1 - Returns the status of 144 ARS: OFF / ON


=item getArs430 ()

                $ars430 = $FT817->getArs430();

        MENU ITEM # 2 - Returns the status of 430 ARS: OFF / ON


=item getArtsmode ()

                $artsmode = $FT817->getArtsmode();

        MENU ITEM # 9 - Returns the status of ARTS BEEP: OFF / RANGE /ALL


=item getBacklight ()

                $backlight = $FT817->getBacklight();

        MENU ITEM # 10 - Returns the status of the Backlight: OFF / ON / AUTO


=item getBeepfreq ()

                $beepfreq = $FT817->getBeepfreq();

        MENU ITEM # 12 - Returns the BEEP Frequency of the radio : 440 / 880


=item getBeepvol ()

                $beepvol = $FT817->getBeepvol();

        MENU ITEM # 13 - Returns the BEEP VOLUME of the radio : 0 - 100


=item getBk ()

                $bk = $FT817->getBk();

        Returns the status of Break-in (BK) ON / OFF
 

=item getCatrate()

                $catrate = $FT817->getCatrate();

        MENU ITEM # 14 - Returns the CAT RATE (4800/9600/38400)


=item getCharger()

                $charger = $FT817->getCharger();

        Returns the status of the battery charger.  Verbose will show the status and if the
	status is on, how many hours the battery is set to charge for.


=item getChargetime()

                $chargetime = $FT817->getChargetime();

        MENU ITEM # 11 - Returns how many hours the charger is set for in the config. 6/8/10


=item getChecksum()

                $checksum = $FT817->getChecksum();

	Returns the checksum bits in EEPROM areas 0x00 through 0x03


=item getColor()

                $color = $FT817->getColor();

        MENU ITEM # 15 - Returns the Color of the LCD display (BLUE/AMBER)


=item getConfig()

		$config = $FT817->getConfig();

	Returns the two values that make up the Radio configuration.  This is set by the soldier blobs
	of J4001-J4009 in the radio.


=item getContrast()

                $contrast = $FT817->getContrast();

        MENU ITEM # 16 - Returns the Contrast of the LCD display (1-12)


=item getCurrentmem()

                $currentmem = $FT817->getCurrentmem();

        Returns the currently selected memory area that appears on startup [0-200] or M-PL, M-PU


=item getCwdelay()

                $cwdelay = $FT817->getCwdelay();

        MENU ITEM # 17 - Shows CW Delay 10-2500 ms


=item getCwid()

                $cwid = $FT817->getCwid();

        MENU ITEM # 18 - Shows if CW ID is ON / OFF


=item getCwpaddle()

                $cwpaddle = $FT817->getCwpaddle();

        MENU ITEM # 19 - Shows if CW Paddle is  NORMAL / REVERSE


=item getCwpitch()

                $cwpitch = $FT817->getCwpitch();

        MENU ITEM # 20 - Shows the CW Pitch 300-1000 Hz


=item getCwspeed()

                $cwspeed = $FT817->getCwspeed();

        MENU ITEM # 21 - Returns the speed of CW in WPM


=item getCwweight()

                $cwweight = $FT817->getCwweight();
	        $cwweight = $FT817->getCwweight('1');

        MENU ITEM # 22 - Returns the Weight of CW [1:2.5 - 1:4.5] with no option
			 Returns the Weight of CW [2.5 - 4.5] with no option


=item getDcsinv()

                $dcsinv = $FT817->getDcsinv();

        MENU ITEM # 53 - Returns the Setting DCS encoding, normal or inverted  
                         [TN-RN/TN-RIV/TIV-RN/TIV-RIV]


=item getDigdisp()

                $digdisp = $FT817->getDigdisp();

        MENU ITEM # 24 - Shows the Digital Frequency Offset -3000 to +3000 Hz


=item getDigmic()

                $digmic = $FT817->getDigmic();

        MENU ITEM # 25 - Returns the setting of DIG MIC 0-100


=item getDigmode()

                $digmode = $FT817->getDigmode();

        MENU ITEM # 26 - Returns the Setting of the Digital mode 
			 [RTTY/PSK31-L/PSK31-U/USER-L/USER-U]


=item getDigshift()

                $digshift = $FT817->getDigshift();

        MENU ITEM # 27 - Shows the Digital Shift -3000 to +3000 Hz


=item getDsp()

		$dsp = $FT817->getDsp();

	Returns the current setting of the Digital Signal Processor (if applicable) : ON / OFF


=item getDw()

                $dw = $FT817->getDw();

        Returns the status of Dual Watch (DW) ON / OFF


=item getEeprom()

		$value = $FT817->getEeprom();

	Currently returns just the value you send it. In verbose mode however, it will display a formatted
	output of the memory address specified.

With one argument it will display the information about a memory address 

	[FT817]@/dev/ttyUSB0$ get eeprom 005f

	ADDRESS     BINARY          DECIMAL     VALUE      
	___________________________________________________
	005F        11100101        229         E5    


With two arguments it will display information on a range of addresses

	[FT817]@/dev/ttyUSB0$ get eeprom 005f 0062

	ADDRESS     BINARY          DECIMAL     VALUE      
	___________________________________________________
	005F        11100101        229         E5         
	0060        00011001        25          19         
	0061        00110010        50          32         
	0062        10001000        136         88  


=item getEmergency()

                $emergency = $FT817->getEmergency();

        MENU ITEM # 28 - Shows if Emergency is set to ON / OFF


=item getExtmenu()

                $extmenu = $FT817->getExtmenu();

        MENU ITEM # 52 - Shows the Extended Menu Setting ON /OFF


=item getFasttuning()

		$fasttune = $FT817->getFasttuning();

	Returns the current setting of the Fast Tuning mode : ON / OFF


=item getFlags()

		$flags = $FT817->getFlags();

	Returns the current status of the flags : DEBUG / VERBOSE / WRITE ALLOW / WARNED


=item getFmmic()

                $fmmic = $FT817->getFmmic();

        MENU ITEM # 29 - Returns the setting of FM MIC 0-100


=item getHome()

		$home = $FT817->getHome();

	Returns the current status of the rig being on the Home Frequency : Y/N


=item getId()

                $id = $FT817->getId();

        MENU ITEM # 31 - Returns the charachers for CWID


=item getKyr()

                $kyr = $FT817->getKyr();

        Returns the current status of the Keyer (KYR) : ON/OFF


=item getLock()

                $lock = $FT817->getLock();

        Returns the current status of the Lock : ON/OFF


=item getLockmode()

                $lockmode = $FT817->getLockmode();

        MENU ITEM # 32 - Returns the Lock Mode  DIAL / FREQ / PANEL


=item getMainstep()

                $mainstep = $FT817->getMainstep();

        MENU ITEM # 33 - Returns the Main Step COURSE / FINE


=item getMemgroup()

                $memgroup = $FT817->getMemgroup();

        MENU ITEM # 34 - Returns Status of Memory groups ON / OFF


=item getMemmap()

                $Memory = $FT817->getMemmap([1-200 / M-PL / M-PU]);

        Returns the given memory number as Active or Inactive


=item getMickey()

                $mickey = $FT817->getMickey();

        MENU ITEM # 36 - Returns Status of MIC KEY ON / OFF


=item getMicscan()

                $micscan = $FT817->getMicscan();

        MENU ITEM # 37 - Returns Status of MIC SCAN ON / OFF


=item getMtqmb()

                $mtqmb = $FT817->getMtqmb();

        Returns the current Status of MTQMB : ON / OFF


=item getMtune()

                $mtune = $FT817->getMtune();

        Returns the current Status of MTUNE : MTUNE / MEMORY 


=item getNb()

		$nb = $FT817->getNb();

	Returns the current Status of the Noise Blocker : ON / OFF


=item getOpfilter()

                $opfilter = $FT817->getOpfilter();

        MENU ITEM # 38 - Returns the OP Filter setting OFF / SSB / CW


=item getPktmic()

                $pktmic = $FT817->getPktmic();

        MENU ITEM # 39 - Returns the setting of PKT MIC 0-100


=item getPktrate()

                $pktrate = $FT817->getPktrate();

        MENU ITEM # 40 - Returns the Packet Rate  1200 / 9600 Baud


=item getPbt()

                $pbt = $FT817->getPbt();

        Returns the status of Pass Band Tuning: ON /OFF


=item getPri()

                $pri = $FT817->getPri();

        Returns the status of Priority Scaning Feature: ON /OFF


=item getPwrmtr()

                $pwrmtr = $FT817->getPwrmtr();

        Returns the current Setting of the Power meter : PWR / ALC / SWR / MOD


=item getQmb()

                $qmb = $FT817->getQmb();

        Returns the current Status of QMB : ON / OFF 


=item getResumescan()

                $resumescan = $FT817->getResumescan();

        MENU ITEM # 41 - Returns the RESUME(scan) setting OFF / 3,5,10 SEC


=item getRfknob()

		$rfknob = $FT817->getRfknob();

	MENU ITEM # 45 - Returns the current Functionality of the RF-GAIN Knob : RFGAIN / SQUELCH


=item getRlsbcar()

                $rlsbcar = $FT817->getRlsbcar();

        MENU ITEM # 54 - Shows the Rx Carrier point for LSB -000 to +300 Hz


=item getRusbcar()

                $rusbcar = $FT817->getRlsbcar();

        MENU ITEM # 55 - Shows the Rx Carrier point for USB -000 to +300 Hz


=item getScn()

                $pwrmtr = $FT817->getScn();

        Returns the current function of the Scan Feature : OFF / UP / DOWN


=item getScope()

                $scope = $FT817->getScope();

        MENU ITEM # 43 - Returns the Setting for SCOPE : Continuous / CHK (every 10 sec)


=item getSidetonevol()

                $sidetonevol = $FT817->getSidetonevol();

        MENU ITEM # 44 - Returns the Sidetone Volume 0-100


=item getSpl()

                $spl = $FT817->getSpl();

        Returns the current Status of SPL, Split Frequency : ON / OFF


=item getSsbmic()

                $ssbmic = $FT817->getSsbmic();

        MENU ITEM # 46 - Returns the Value of SSB MIC 0-100


=item getSoftcal()

		$softcal = $FT817->getSoftcal({console/digest/file filename.txt});

	This command currently works with verbose and write to file.  Currently there is no
	usefull return information Except for digest.  With no argument, it defaults to 
	console and dumps the entire 76 software calibration memory areas to the screen. 
	Using digest will return an md5 hash of the calibration settings. Using file along
	with a file name writes the output to a file.  It's a good idea to keep a copy of 
	this in case the eeprom gets corrupted and the radio factory defaults.  If you dont have 
	this information, you will have to send the radio back to the company for recalibration.


=item getTlsbcar()

                $tlsbcar = $FT817->getTlsbcar();

        MENU ITEM # 56 - Shows the Tx Carrier point for LSB -000 to +300 Hz


=item getTusbcar()

                $tusbcar = $FT817->getTusbcar();

        MENU ITEM # 57 - Shows the Tx Carrier point for USB -000 to +300 Hz


=item getTottime()

                $tottime = $FT817->getTottime();

        MENU ITEM # 49 - Returns the Value of the Time out Timer in Minutes


=item getTuner()

		$tuner = $FT817->getTuner();

	Returns the current tuner setting : VFO / MEMORY


=item getTxpower()

		$txpower = $FT817->getTxpower();

	Returns the current Transmit power level : HIGH / LOW3 / LOW2 / LOW1


=item getVfo()

		$vfo = $FT817->getVfo();

	Returns the current VFO : A / B


=item getVfoband()

                $vfoband = $FT817->getVfoband([A/B]);

        Returns the current band of a given VFO 


=item getVlt()

                $vlt = $FT817->getVlt();

        Returns if the voltage display is ON or OFF


=item getVox()

                $vox = $FT817->getVox();

        Returns the status of VOX : ON / OFF


=item getVoxdelay()

                $voxdelay = $FT817->getVoxdelay();

        MENU ITEM # 50 - Returns the VOX Delay (100-2500)ms


=item getVoxgain()

                $voxgain = $FT817->getVoxgain();

        MENU ITEM # 51 - Returns the VOX Gain (1-100)


=item hex2bin()

	Simple internal function for convrting hex to binary. Has no use to the end user.


=item hexAdder()

        Internal function to incriment a given hex value off a base address


=item hexDiff()

        Internal function to return decimal value as the difference between two hex numbers


=item loadConfig()

                $output = $FT817->loadConfig([filename]);

        This will restore the radio configuration from a file using the FT817OS format overwriting 
	the existing radio config

        Without a filename this will load the config from the default file FT817.cfg 


=item loadMemory()

                $output = $FT817->loadMemory([filename]);

        This will restore the radio memory from a file using the FT817OS format overlapping 
        the existing radio memory.  Whichever valid memory areas were saved at the time will
	be the ones overwritten.  If you create, between the last save, other memory areas 
	within the radio they will not be updated.  If you want an accurate reload of the memory
	be sure to use save memory after making changes to memory areas.

        Without a filename this will load the config from the default file FT817.mem  


=item moduleVersion()

		$version = $FT817->moduleVersion();

	Returns the version of FT817COMM.pm to the software calling it.


=item new()

		my $FT817 = new Ham::Device::FT817COMM (
		serialport => '/dev/ttyUSB0',
		baud => '38400',
		lockfile => '/var/lock/ft817'
					               );

	Creates an instance of the device that is the Radio.  Called at the beginning of the program.
	See the Constructors section for more info.


=item quietToggle()

                $output = $FT817->quiettoggle();

        This is an internal function to toggle the vfo with verbose off. To cut down on repetative code

	Returns 0


=item quietHometoggle()

                $output = $FT817->quiettoggle();

        This is an internal function to toggle the HOME with verbose off. To cut down on repetative code

        Returns 0


=item quietTunetoggle()

                $output = $FT817->quiettoggle();

        This is an internal function to toggle the MEMORY / VFO with verbose off. To cut down on repetative code

        Returns 0


=item rangeCheck()

                $band = $FT817->rangeCheck([FREQNENCY]);

        This is an internal function to check the FREQRANGE hash to see what band the given frequency is in

        Returns BAND


=item readMemvfo ()

		my $option = $FT817->readMemvfo('[A/B]', '[BAND]', '[OPTION]');
                my $option = $FT817->readMemvfo('[MTUNE/MTQMB]','[OPTION]');

	Reads and returns information from the VFO memory given a VFO [A/B] and a BAND [20M/40M/70CM] etc..
        Reads and returns information from the VFO for [MTUNE/MTQMB] doesn't take a band argument. 
	This is only for VFO memory's and not the Stored Memories nor Home Memories. Leave OPTION empty to 
	Return a hash with all OPTIONS below

	Returns information based on one of the valid options:

	MODE          - Returns the mode in memory - update only appears after toggling the VFO
	NARFM         - Returns if Narrow FM os ON or OFF
	NARCWDIG      - Returns if the CW or Digital Mode is on Narrow
	RPTOFFSET     - Returns the Repeater offset
	TONEDCS       - Returns type type of tone being used
	ATT           - Returns if ATT is on if applicable, if not shows OFF
	IPO           - Returns if IPO is on if applicable, if not shows OFF
	FMSTEP        - Returns the setting for FM STEP in KHZ
	AMSTEP        - Returns the setting for AM STEP in KHZ
        SSBSTEP       - Returns the setting for SSB STEP in KHZ
	CTCSSTONE     - Returns the currently set CTCSS Tone
	DCSCODE       - Returns the currently set DCS Code
	CLARIFIER     - Returns if the CLARIFIER is on or off
	CLAROFFSET    - Returns the polarity and offset frequency of the clarifier stored on EEPROM
	RXFREQ        - Returns the stored Receive Frequency
	RPTOFFSETFREQ - Returns the stored Repeater offset Frequency

	The CLAROFFSET is the stored value in the VFO not the active one.  The EEPROM doesnt write everytime
	you turn the clarifer adjustment.  When using the CAT command to set the CLARIFIERFREQ this value will
	not update, only when set directly in the VFO mem will it show a live update

	If you have never used the QMB/MTQMB option on the radio, the memory addresses will show garbled data.
	Its simply easier to first send some arbitrary data to the channels in the radio by following the instructions
	on manual page 44.  This is not a requirment, if you dont use QMB or MTQMB you do not need to do this. 


=item readMemory()

                my $option = $FT817->readMemory('[MEM]','[1-200 / M-PL / M-PU]','[OPTION]');
                my $option = $FT817->readMemory('[HOME]','[BAND]','[OPTION]');
                my $option = $FT817->readMemory('[QMB]','[OPTION]');

        Reads and returns information from the Memory given a Memory area [MEM/HOME] and a TYPE [NUM or BAND] etc..
        Reads and returns information from the Memory for [QMB] doesn't take a type argument.
        This is only for Stored Memories not VFO nor Home Memories. Leave OPTION empty to
        Return a hash with all OPTIONS below

        Returns information based on one of the valid options:

	READY         - Returns if the ready bit is set after proper data is set in memory bank
        MODE          - Returns the mode in memory
	HFVHF         - Returns if the memory area is HF or VHF
	TAG           - Returns if set to show Frequency or Label on the Display
	FREQRANGE     - Returns the Frequency range of the memory area HF / 6m / FMBCB / AIR / 2m / UHF 
        NARFM         - Returns if Narrow FM os ON or OFF
        NARCWDIG      - Returns if the CW or Digital Mode is on Narrow
	UHF           - Returns if the memory area is UHF or not
        RPTOFFSET     - Returns the Repeater offset
        TONEDCS       - Returns type type of tone being used
        ATT           - Returns if ATT is on if applicable, if not shows OFF
        IPO           - Returns if IPO is on if applicable, if not shows OFF
	MEMSKIP       - Returns if the memory is skipped on scan or not
        FMSTEP        - Returns the setting for FM STEP in KHZ
        AMSTEP        - Returns the setting for AM STEP in KHZ
        SSBSTEP       - Returns the setting for SSB STEP in KHZ
        CTCSSTONE     - Returns the currently set CTCSS Tone
        DCSCODE       - Returns the currently set DCS Code
        CLARIFIER     - Returns if the CLARIFIER is on or off
        CLAROFFSET    - Returns the polarity and offset frequency of the clarifier stored on EEPROM
        RXFREQ        - Returns the stored Receive Frequency
        RPTOFFSETFREQ - Returns the stored Repeater offset Frequency
	LABEL         - Returns the 8 character label for the memory area or ???????? if empty

        If you have never used the QMB/MTQMB option on the radio, the memory addresses will show garbled data.
        Its simply easier to first send some arbitrary data to the channels in the radio by following the instructions
        on manual page 44.  This is not a requirment, if you dont use QMB or MTQMB you do not need to do this.


=item rebuildSoftcal()

		$status = $FT817->rebuildSoftcal([filename]);

	This command is used to reload all of the software calibration settings for the FT817 in the event
	that either the software calibration had become corrupted, or a master reset was needed for the rig.
	This reload uses the FT817OS 'cal' file format to reload data.  If you did not backup your cal settings
	then this will be of little use and the rig will have to go to the factory to be recalibrated.

	You can call the command without an argument to use the default file name FT817.cal

	The cal file must be in the directory where you are running the program which calls it.  The program will
	ensure the file exists, and the data is correct before it attempts to write it to the Eeprom.  If it finds 
	an error it will tell you what line of the cal file produced the error and stop.

	Note that this will start writing data if the cal file is error free and not provide any user prompt

	Returns 0 on sucessfull write of the 76 bytes
	Returns 1 on Error


=item restoreEeprom()

		$restorearea = $FT817->restoreEeprom();

	This restores a specific memory area of the EEPROM back to a known good default value.
	This is a WRITEEEPROM based function and requires both setWriteallow() and agreeWithwarning()
	to be set to 1.
	This command does not allow for an arbitrary address to be written. 
	
	Currently 
		  [0055] [0057] [0058] [0059] [0060]
		  [005B] [005C] [005D] [005E] [005F] 
		  [0061] [0062] [0063] [0064] [0065]
		  [0066] [0067] [0068] [0069] [006A]
		  [006B] [006C] [006D] [006E] [006F]
		  [0070] [0071] [0072] [0073] [0074]
		  [0079] [007A] [007B] [044F]
	
	 are allowed

	restoreEeprom('005F'); 

	Returns 'OK' on success. Any other output an error.


=item saveConfig()

		$output = $FT817->saveConfig([filename]);

	This will backup the radio configuration to a file using the FT817OS format so that it can
	be restored, if needed.

	Without a filename this will write the config to the default file FT817.cfg and if that file
	already exists, overwrite it.


=item saveMemory()

                $output = $FT817->saveMemory([filename]);

        This will backup the regular memory areas 1-200 and M-PL M-PU to a file using the FT817OS
        format so that it can be restored, if needed.  This will capture both active and inactive
        memory areas provided the memory area is correctly formatted and the READY bit is high.

        Without a filename this will write the memory to the default file FT817.mem and if that file
        already exists, overwrite it.


=item sendCat()

	Internal function, if you try to call it, you may very well end up with a broken radio.
	You have been warned.


=item set9600mic()

                $status = $FT817->set9600mic([0-100]);

        MENU ITEM # 3 Sets the 9600 MIC

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('006C');


=item setAgc()

                $status = $FT817->setAgc([AUTO/FAST/SLOW/OFF];

        Sets the agc

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0057');


=item setAmfmdial()

                $status = $FT817->setAmfmdial([ENABLE/DISABLE]);

        MENU ITEM # 4 Sets the function of the dial when using AM or FM

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0063');


=item setAmmic()

                $status = $FT817->setAmmic([0-100]);

        MENU ITEM # 5 Sets the AM MIC

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0068');


=item setAntenna()

                $status = $FT817->setAntenna([HF/6M/FMBCB/AIR/VHF/UHF] [FRONT/BACK]);

        Sets the antenna for the given band as connected on the FRONT or REAR of the radio

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('007A');


=item setApotime()

                $status = $FT817->setApotime([OFF/1-6]);

        MENU ITEM # 8 Sets the Auto Power Off time to OFF or 1-6 hours

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0065');


=item setArs144()

                $status = $FT817->setArs144([OFF/ON]);

        MENU ITEM # 1 Sets the 144 ARS ON or OFF

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('005F');


=item setArs430()

                $status = $FT817->setArs430([OFF/ON]);

        MENU ITEM # 2 Sets the 430 ARS ON or OFF

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('005F');

=item setArts()

                $arts = $FT817->setArts([ON/OFF]);

	Sets the ARTS function of the radio to ON or OFF

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0079');


=item setArtsmode()

                $artsmode = $FT817->setArts([OFF/RANGE/BEEP]);

        MENU ITEM # 9 Sets the ARTS function of the radio when ARTS is enabled

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('005D');

=item setBacklight()

                $status = $FT817->setBacklight([OFF/ON/AUTO]);

        MENU ITEM # 10 Sets the Backlight of the radio

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('005B');


=item setBeepfreq()

                $status = $FT817->setBeepfreq([440/880]);

        MENU ITEM # 13 Sets the frequency of the radio beep

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('005C');


=item setBeepvol()

                $status = $FT817->setBeepvol([1-100]);

        MENU ITEM # 13 Sets the volume of the radio beep

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('005C');


=item setBitwatch()

                $bitwatch = $FT817->setBitwatch([#]);

        Turns on and off the internal BITWATCHER. Sends an alert when a value in eeprom changed
	from that lister in the BITWATCHER hash.  Will Dramatically slow down the software and is
	there just to help in identifing unknown memory areas.  When in doubt, leave it set to off.

        Activated when any value is in the (). Good practice says () or (1) for OFF and ON.

        Returns the argument sent to it on success.


=item setBk()

                $status = $FT817->setBk([ON/OFF]);

        Sets the CW Break-in (BK) ON or OFF

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0058');


=item setCatrate()

                $status = $FT817->setCatrate([4800/9600/38400]);

        MENU ITEM # 14 Sets the Baud rate of the CAT interface
	
	Takes effect on next radio restart, be sure to update value baud in new().

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0064');


=item setCharger()

                $charger = $FT817->setCharger([ON/OFF]);

        Turns the battery Charger on or off
	This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('007B');


=item setChargetime()

                $chargetime = $FT817->setChargetime([6/8/10]);

	MENU ITEM # 11 

        Sets the Battery charge time to 6, 8 or 10 hours.  If the charger is currently
	on, it will return an error and not allow the change. Charger must be off.
	This is a WRITEEEPROM based function and requires both setWriteallow() and
	agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        commands that also requires both flags previously mentioned set to 1.

        restoreEeprom('0062');
	restoreEeprom('007B');

        Returns 'OK' on success. Any other output an error.


=item setColor()

                $output = $FT817->setColor([BLUE/AMBER]);

        MENU ITEM # 15

        Sets the Color of the LCD screen

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('005B');


=item setContrast()

                $output = $FT817->setContrast([1-12]);

        MENU ITEM # 16

        Sets the Contrast of the LCD screen, this seems to only update the screen
	after a power cycle, either manually, or by CAT command

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('005B');


=item setCurrentmem()

                $output = $FT817->setCurrentmem([0-200] or [M-PU/M-PL]);

        Sets the current memory channel of the radio

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('044F');


=item setCwdelay()

                $output = $FT817->setCwdelay([10-2500]);

        MENU ITEM # 17

        Sets the CW Delay between 10 - 2500 ms in incriments of 10

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0060');


=item setCwid()

                $output = $FT817->setCwid([ON/OFF]);

        MENU ITEM # 18

        Sets the CW ID to ON or OFF

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('005D');


=item setCwpitch()

                $output = $FT817->setCwpitch([300-1000]);

        MENU ITEM # 20

        Sets the CW Pitch from 300 to 1000 hz in incriments of 50

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('005E');


=item setCwpaddle()

                $output = $FT817->setCwpaddle([NORMAL/REVERSE]);

	MENU ITEM # 19

        Sets the CW paddle to NORMAL or REVERSE

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0058');


=item setCwspeed()

                $output = $FT817->setCwpaddle([4-60]);

        MENU ITEM # 21

        Sets the CW Speed

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0062');


=item setCwweight()

                $output = $FT817->setCwweight([2.5-4.5]);

        MENU ITEM # 22

        Sets the CW weight

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('005F');


=item setDcsinv()

                $output = $FT817->setDcsinv([TN-RN/TN-RIV/TIV-RN/TIV-RIV]);

        MENU ITEM # 53

        Sets the DCS Inversion

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0066');


=item setDebug()

		$debug = $FT817->setDebug([#]);

	Turns on and off the internal debugger. Provides information on all serial transactions when on.
	Activated when any value is in the (). Good practice says () or (1) for OFF and ON.

	Returns the argument sent to it on success.


=item setDigdisp()

                $output = $FT817->setDigdisp([0]);
                $output = $FT817->setDigdisp([+/-][0-3000]);

        MENU ITEM # 24

        Sets the digital frequency offset shift in hz, in incriments of 10 takes 0 or +/- 0-3000

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with the following
        commands that also requires both flags previously mentioned set to 1.

        restoreEeprom('006F');
        restoreEeprom('0070');


=item setDigmic()

                $output = $FT817->setDigmic([0-100]);

        MENU ITEM # 25

        Sets the DIG MIC

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('006A');

=item setDigmode()

                $output = $FT817->setDigmode([RTTY/PSK31-L/PSK31-U/USER-L/USER-U]);

        MENU ITEM # 26

        Sets the Digital Mode type

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0065');


=item setDigshift()

                $output = $FT817->setDigshift([0]); 
		$output = $FT817->setDigshift([+/-][0-3000]); 

        MENU ITEM # 27

        Sets the digital shift in hz, in incriments of 10 takes 0 or +/- 0-3000

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with the following
        commands that also requires both flags previously mentioned set to 1.

        restoreEeprom('006D');
        restoreEeprom('006E');


=item setDsp()

                $output = $FT817->setDsp([ON/OFF]);

        Turns the DSP on or off if available

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0057');


=item setDw()

                $status = $FT817->setDw([ON/OFF]);

        Sets the Dual Watch (DW) ON or OFF

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0079');


=item setEmergency()

                $output = $FT817->setEmergency([ON/OFF]);

        MENU ITEM # 28

        Sets the Emergency to ON or OFF

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0064');


=item setExtmenu()

                $output = $FT817->setExtmenu([ON/OFF]);

        MENU ITEM # 52

        Sets the Emergency to ON or OFF

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('006B');


=item setFasttuning()

                $output = $FT817->setFasttuning([ON/OFF]);

        Sets the Fast Tuning of the radio to ON or OFF

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0057');


=item setFmmic()

                $output = $FT817->setFmmic([0-100]);

        MENU ITEM # 29

        Sets the FM MIC

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0069');


=item setHome()

                $output = $FT817->setHome([ON/OFF]);

        Sets the Radio to HOME frequency or back to normal frequencies

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0055');


=item setId()

                $output = $FT817->setId('CCCCCC');

        MENU ITEM # 31 - Sets the charachers for CWID


=item setKyr()

                $output = $FT817->setKyr([ON/OFF]);

        Sets the CW Keyer (KYR) on or off

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0058');


=item setLock()

                $output = $FT817->setLock([ON/OFF]);

        Sets the Radio Lock on or off. Similar to catLock() but calls it directly

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0057');


=item setLockmode()

                $status = $FT817->setLockmode([DIAL/FREQ/PANEL]);

        MENU ITEM # 32 Sets the Radio Lock Mode

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('005E');


=item setMainstep()

                $status = $FT817->setMainstep([COURSE/FINE]);

        MENU ITEM # 33 Sets the Main step

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('005D');


=item setMemarea()

                $status = $FT817->setMemarea([2-200/M-PL/M-PU] [ACTIVE/INACTIVE]);

	Sets the given memory area as active or inactive. You cannot set area 1 which
	is always active. This will check to see if the memory area is formatted and if not call a function
	within writeMemory to format that area and give it a label 


=item setMemgroup()

                $status = $FT817->setMemgroup([ON/OFF]);

        MENU ITEM # 33 Sets the Memory Groups ON or OFF

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0065');


=item setMickey()

                $status = $FT817->setMickey([ON/OFF]);

        MENU ITEM # 36 Sets the MIC KEY ON or OFF

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0068');


=item setMicscan()

                $status = $FT817->setMicscan([ON/OFF]);

        MENU ITEM # 37 Sets the MIC SCAN ON or OFF

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0067');


=item setMtqmb()

                $output = $FT817->setMtqmb([ON/OFF]);

        Sets the MTQMB to ON or OFF

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0055');


=item setMtune()

                $output = $FT817->setMtune([MTUNE/MEMORY]);

        Sets the MTUNE to MTUNE or MEMORY

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0055');


=item setNb()

                $output = $FT817->setNb([ON/OFF]);

	Turns the Noise Blocker on or off

	This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0057');

        Returns 'OK' on success. Any other output an error.


=item setOpfilter()

                $output = $FT817->setOpfilter([OFF/SSB/CW]);

        MENU ITEM # 38

        Sets the Optional Filter

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('005E');


=item setPktmic()

                $output = $FT817->setPktmic([0-100]);

        MENU ITEM # 39

        Sets the PKT MIC

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('006B');


=item setPktrate()

                $output = $FT817->setCwpaddle([NORMAL/REVERSE]);

        MENU ITEM # 40

        Sets the Packet rate

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('005D');


=item setPbt()

                $status = $FT817->setPbt([OFF/ON];

        Enables or disables the Pass Band Tuning

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0057');


=item setPri()

                $output = $FT817->setPri([ON/OFF]);

        Sets the Priority Scanning ON or OFF

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0079');


=item setPwrmtr()

                $status = $FT817->setPwrmtr([PWR/ALC/SWR/MOD];

        Sets the active display of the Power Meter

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0058');

=item setQmb()

                $output = $FT817->setQmb([ON/OFF]);

        Sets the QMB to ON or OFF

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0055');


=item setResumescan()

                $status = $FT817->setResumescan([OFF/3/5/10]);

        MENU ITEM # 41 - SETS THE Resume (scan) functionality.  

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('005D');

        Returns 'OK' on success. Any other output an error.


=item setRfknob()

                $rfknob = $FT817->setRfknob([RFGAIN/SQUELCH]);

        MENU ITEM # 45 - SETS THE RF-GAIN knob functionality.  

	This is a WRITEEEPROM based function and requires both setWriteallow() and 
	agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('005F');

        Returns 'OK' on success. Any other output an error.


=item setRlsbcar()

                $output = $FT817->setRlsbcar([0]);
                $output = $FT817->setRlsbcar([+/-][0-300]);

        MENU ITEM # 54

        Sets the Rx Carrier Point for LSB in hz, in incriments of 10 takes 0 or +/- 0-300

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with the following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0071');


=item setRusbcar()

                $output = $FT817->setRusbcar([0]);
                $output = $FT817->setRusbcar([+/-][0-300]);

        MENU ITEM # 55

        Sets the Rx Carrier Point for USB in hz, in incriments of 10 takes 0 or +/- 0-300

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with the following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0072');


=item setScn()

                $output = $FT817->setScn([OFF/UP/DOWN]);

        Sets the SCN, Scanningn to OFF UP or DOWN

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0079');


=item setScope()

                $output = $FT817->setScope([CONT/CHK]);

        MENU ITEM # 43

        Sets the Scope

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('005D');


=item setSidetonevol()

                $output = $FT817->setSidetonevol([1-100]);

        MENU ITEM # 44

        Sets the Sidetone Volume

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0061');


=item setSpl()

                $status = $FT817->setSpl([ON/OFF]);

        Sets the Split Frequency (SPL) ON or OFF

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('007A');


=item setSsbmic()

                $output = $FT817->setSsbmic([0-100]);

        MENU ITEM # 46

        Sets the SSB MIC

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0067');


=item setTlsbcar()

                $output = $FT817->setTlsbcar([0]);
                $output = $FT817->setTlsbcar([+/-][0-300]);

        MENU ITEM # 56

        Sets the Tx Carrier Point for LSB in hz, in incriments of 10 takes 0 or +/- 0-300

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with the following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0073');


=item setTusbcar()

                $output = $FT817->setTusbcar([0]);
                $output = $FT817->setTusbcar([+/-][0-300]);

        MENU ITEM # 57

        Sets the Tx Carrier Point for USB in hz, in incriments of 10 takes 0 or +/- 0-300

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with the following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0074');


=item setTottime()

                $output = $FT817->setTottime([OFF/1-20]);

        MENU ITEM # 49

        Sets the Time out Timer OFF or in minutes from 1 to 20

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0066');


=item setTuner()

                $output = $FT817->setTuner([VFO/MEMORY]);

        Sets the Tuner to VFO or memory

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0055');

        Returns 'OK' on success. Any other output an error.


=item setTxpower()

                $status = $FT817->setTxpower([HIGH/LOW1/LOW2/LOW3];

        Sets the Transmitter Power

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0079');


=item setVerbose()

                $debug = $FT817->setVerbose([#]);

        Turns on and off the Verbose flag. Provides information where verbose is enabled
        Activated when any value is in the (). Good practice says () or (1) for OFF and ON.

        Returns the argument sent to it on success.


=item setVfo()

                $status = $FT817->setVfo([A/B];

        Sets the VFO to A or B

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0055');


=item setVfoband()

                $setvfoband = $FT817->setVfoband([A/B] [160M/75M/40M/30M/20M/17M/15M/12M/10M/6M/2M/70CM/FMBC/AIR/PHAN]);

        Sets the band of the selected VFO
        Returns 'OK' on success or '1' on failure

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0059');


=item setVlt()

                $status = $FT817->setVlt([ON/OFF];

        Enables or disables the voltage display

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0058');


=item setVox()

                $setvox = $FT817->setVox([ON/OFF]);

        Sets the VOX feature of the radio on or off.
        Returns 'OK' on success or '1' on failure

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0058');


=item setVoxdelay()

                $output = $FT817->setVoxdelay([100-2500]);

        MENU ITEM # 50

        Sets the Vox delay. Done in incriments of 100

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0064');


=item setVoxgain()

                $output = $FT817->setVoxgain([1-100]);

        MENU ITEM # 51

        Sets the Vox Gain.

        This is a WRITEEEPROM based function and requires both setWriteallow() and
        agreeWithwarning() to be set to 1.

        In the event of a failure, the memory area can be restored with. The following
        command that also requires both flags previously mentioned set to 1.

        restoreEeprom('0063');


=item setWriteallow()

		$writeallow = $FT817->setWriteallow([#]);

	Turns on and off the write Flag. Provides a warning about writing to the EEPROM and
	requires the agreeWithwarning()  to also be set to 1 after reading the warning
	Activated when any value is in the (). Good practice says () or (1) for OFF and ON.

	Returns the argument sent to it on success.


=item writeBlock()

	Internal function, if you try to call it, you may very well end up with a broken radio.
        You have been warned.


=item writeDoubleblock()

        Internal function, if you try to call it, you may very well end up with a broken radio.
        You have been warned.


=item writeEeprom()

	Internal function, if you try to call it, you may very well end up with a broken radio.
	You have been warned.


=item writeMemory()

                my $option = $FT817->writeMemory('[HOME]', '[BAND]', '[OPTION]','[VALUE]');
                my $option = $FT817->writeMemory('[MEM]','[1-200/M-PL/M-PU]', '[OPTION]','[VALUE]');
                my $option = $FT817->writeMemory('[QMB]','[OPTION]','[VALUE]');

        Writes settings to the memory area given HOME [BAND] and an Option and value.
        Writes settings to the memory area given MEM [1-200/M-PL/M-PU] and an Option and value.
        Writes settings to the memory area given QMB and an Option and value.
        
	This is only for regular memory's and not the VFO Memories.

        Valid options:

        MODE          - Sets the mode in memory - update only appears after toggling the VFO
        NARFM         - Sets if Narrow FM os ON or OFF
        NARCWDIG      - Sets  if the CW or Digital Mode is on Narrow
        RPTOFFSET     - Sets the Repeater offset
	TAG           - Sets the radio display to show label or frequency
	LABEL         - Sets the 8 character label for memory area
	MEMSKIP       - Sets if the memory area is skipped on scan or not
        TONEDCS       - Sets type type of tone being used
        ATT           - Sets if ATT is on if applicable.
        IPO           - Sets if IPO is on if applicable.
        FMSTEP        - Sets the setting for FM STEP in KHZ
        AMSTEP        - Sets the setting for AM STEP in KHZ
        SSBSTEP       - Sets the setting for SSB STEP in KHZ
        CTCSSTONE     - Sets the CTCSS Tone
        DCSCODE       - Sets the DCS Code
        CLARIFIER     - Sets the CLARIFIER on or off
        CLAROFFSET    - Sets the polarity and offset frequency of the clarifier
        RXFREQ        - Sets the stored Receive Frequency
        RPTOFFSETFREQ - Sets the stored Repeater offset Frequency

        The UHF / HF/VHF and FREQ RANGE options are set automatically by the RXFREQ option and should not be manually set

        If you have never used the QMB/MTQMB option on the radio, the memory addresses will show garbled data.
        Its simply easier to first send some arbitrary data to the channels in the radio by following the instructions
        on manual page 44.  This is not a requirment, if you dont use QMB or MTQMB you do not need to do this.

        Never used memory addresses will be automatically formatted with the correct data when the memory area is activated 
        Using a built in function within writeMem That checks for the ready bit within that area.


=item writeMemvfo ()

                my $option = $FT817->writeMemvfo('[A/B]', '[BAND]', '[OPTION]','[VALUE]');
                my $option = $FT817->writeMemvfo('[MTUNE/MTQMB]', '[OPTION]','[VALUE]');

        Writes settings to the VFO memory given a VFO [A/B] and a BAND [20M/40M/70CM] etc..
        Writes settings to the VFO memory given a VFO [MTUNE/MTQMB] no band required for these.
        This is only for VFO memory's and not the Stored Memories nor Home Memories. 

        Valid options:

        MODE          - Sets the mode in memory - update only appears after toggling the VFO
        NARFM         - Sets if Narrow FM os ON or OFF
        NARCWDIG      - Sets  if the CW or Digital Mode is on Narrow
        RPTOFFSET     - Sets the Repeater offset
        TONEDCS       - Sets type type of tone being used
        ATT           - Sets if ATT is on if applicable.
        IPO           - Sets if IPO is on if applicable.
        FMSTEP        - Sets the setting for FM STEP in KHZ
        AMSTEP        - Sets the setting for AM STEP in KHZ
        SSBSTEP       - Sets the setting for SSB STEP in KHZ
        CTCSSTONE     - Sets the CTCSS Tone
        DCSCODE       - Sets the DCS Code
        CLARIFIER     - Sets the CLARIFIER on or off
        CLAROFFSET    - Sets the polarity and offset frequency of the clarifier
        RXFREQ        - Sets the stored Receive Frequency
        RPTOFFSETFREQ - Sets the stored Repeater offset Frequency

        If you have never used the QMB/MTQMB option on the radio, the memory addresses will show garbled data.
        Its simply easier to first send some arbitrary data to the channels in the radio by following the instructions
        on manual page 44.  This is not a requirment, if you dont use QMB or MTQMB you do not need to do this.

=back

=head1 AUTHOR

Jordan Rubin KJ4TLB, C<< <jrubin at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ham-device-ft817comm at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ham-Device-FT817COMM>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.
    perldoc Ham::Device::FT817COMM

You can also look for information at:

=over 4

=item * Technologically Induced Coma
L<http://technocoma.blogspot.com>

=item * RT: CPAN's request tracker (report bugs here)
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Ham-Device-FT817COMM>

=item * AnnoCPAN: Annotated CPAN documentation
L<http://annocpan.org/dist/Ham-Device-FT817COMM>

=item * CPAN Ratings
L<http://cpanratings.perl.org/d/Ham-Device-FT817COMM>

=item * Search CPAN
L<http://search.cpan.org/dist/Ham-Device-FT817COMM/>

=back

=head1 ACKNOWLEDGEMENTS

Thank you to Clint Turner KA7OEI for his research on the FT817 and discovering the mysteries of the EEprom
FT817 and Yaesu are a registered trademark of Vertex standard Inc.

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Jordan Rubin.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.
This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut


1;  # End of Ham::Device::FT817COMM
