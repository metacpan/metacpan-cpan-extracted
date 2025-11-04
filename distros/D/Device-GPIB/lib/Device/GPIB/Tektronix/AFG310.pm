# AFG310.pm
# Perl module to control a Tektronix AFG310 by GPIB
# Implements commands from 071017550.pdf
# AFG310 and AFG320
# Arbitrary Function generator
# 071-0175-50
#
# audio sweep generator:
# perl -I lib bin/gpib.pl -address 1 'freq:mode sweep'
# perl -I lib bin/gpib.pl -address 1 'freq:start 10hz'
# perl -I lib bin/gpib.pl -address 1 'freq:stop  100khz'
# perl -I lib bin/gpib.pl -address 1 'sweep:time 4s'
# perl -I lib bin/gpib.pl -address 1 'sweep:spacing log'
#
# Author: Mike McCauley (mikem@airspayce.com),
# Copyright (C) AirSpayce Pty Ltd
# $Id: $

package Device::GPIB::Tektronix::AFG310;
@ISA = qw(Device::GPIB::Tektronix);
use Device::GPIB::Tektronix;
use strict;

sub new($$$)
{
    my ($class, $device, $address) = @_;

    my $self = $class->SUPER::new($device, $address);

    $self->{Id} = $self->sendAndRead('*IDN?'); # IEEE-488.2 Command COmmand
    if ($self->{Id} !~ /AFG310/ and $self->{Id} !~ /AFG320/)
    {
	warn "Not a Tek AFG310/320 at $self->{Address}: $self->{Id}";
	return;
    }
    # Device specific error and Spoll strings
    # from page 3-40
    $self->{ErrorStrings} = {
	0   => 'No errors or events',
	-100   => 'Command error',
	-101   => 'Invalid character',
	-102   => 'Syntax error',
	-103   => 'Invalid separator',
	-104   => 'Data type error',
	-105   => 'GET not allowed',
	-108   => 'Parameter not allowed',
	-109   => 'Missing parameter',
	
	-110   => 'Command header error',
	-111   => 'Header separator error',
	-112   => 'Program mnemonic too long',
	-113   => 'Undefined header',
	-114   => 'Header suffix out of range',
	
	-120   => 'Numeric data error',
	-121   => 'Invalid character in number',
	-123   => 'Exponent too large',
	-124   => 'Too many digits',
	-128   => 'Numeric daat not allowed',
	
	-130   => 'Suffix error',
	-131   => 'Invalid suffix',
	-134   => 'Suffix too long',
	-138   => 'Suffix not allowed',
	
	-140   => 'Character data error',
	-141   => 'Invalid character data',
	-144   => 'Character data too long',
	-148   => 'Character data not allowed',
	
	-150   => 'String data error',
	-151   => 'Invalid string data',
	-158   => 'String data not allowed',
	
	-160   => 'Block data error',
	-161   => 'Invalid block data',
	-168   => 'Block data not allowed',
	
	-170   => 'Expression error',
	-171   => 'Invalid expression',
	-178   => 'Expression data not allowed',
	
	-180   => 'Macro error',
	-181   => 'Invalid outside macro definition',
	-183   => 'Invalid inside macro definition',
	-184   => 'Macro parameter error',
	# Table 5-8 Execution errors
	-200   => 'Execution error',
	-201   => 'Invalid while in local',
	-202   => 'Settings lost due to RTL',
	-203   => 'Command protected',
	
	-210   => 'Trigger error',
	-211   => 'Trigger ignored',
	-212   => 'Arm ignored',
	-213   => 'Init ignored',
	-214   => 'Trigger deadlock',
	-215   => 'Arm deadlock',
	
	-220   => 'Parameter error',
	-221   => 'Settings conflict',
	-222   => 'Data out of range',
	-223   => 'Too much data',
	-224   => 'Illegal parameter value',
	-225   => 'Out of memory',
	-226   => 'Lists not same length',
	
	-230   => 'Data corrupt or stale',
	-231   => 'Data questionable',
	-232   => 'Invalid format',
	-233   => 'Invlaid version',
	
	-240   => 'Hardware error',
	-241   => 'Hardware missing',
	
	-250   => 'Mass storage error',
	-251   => 'Missing mass storage',
	-252   => 'Missing media',
	-253   => 'corrupt media',
	-254   => 'Media full',
	-255   => 'Directory full',
	-256   => 'File name not found',
	-257   => 'File name error',
	-258   => 'Media protected',
	
	-260   => 'Expression error',
	-261   => 'Math error in expression',
	
	-270   => 'Macro error',
	-271   => 'Macro syntax error',
	-272   => 'Macro execution error',
	-273   => 'Illegal macro label',
	-274   => 'Macro parameter error',
	-275   => 'Macro definition too long',
	-276   => 'Macro recursion error',
	-277   => 'Macro rejuvenation not allowed',
	-278   => 'Macro header not found',
	
	-280   => 'Program error',
	-281   => 'Cannot create program',
	-282   => 'Illegal program name',
	-283   => 'Illegal variable name',
	-284   => 'Program currently running',
	-285   => 'Program syntax error',
	-286   => 'Program run time error',
	
	-290   => 'Memory use error',
	-291   => 'Out of memory',
	-292   => 'Referenced name does not exist',
	-293   => 'Referenced name already exists',
	-294   => 'Incompatible type',
	
	# Table 5-9 Internal device errors
	-300   => 'Device specific error',
	
	-310   => 'System error',
	-311   => 'Memory error',
	-312   => 'PUD memory lost',
	-313   => 'Calibration memory losr',
	-314   => 'Save/recall memory lost',
	-315   => 'Configuraiotn memory lost',
	
	-330   => 'Self test failed',
	
	-350   => 'Queue overflow',
	
	# Table 5-10 Query errors
	-400   => 'Query error',
	-410   => 'Query INTERRUPTED',
	-420   => 'Query UNTERMINATED',
	-430   => 'Query DEADLOCKED',
	-440   => 'Query UNTERMINATED after indefinite response',
	
	# Table 5-11 Device Dependednt Errors
	500   => 'Self test error',
	501   => 'Flash memory error',
	502   => 'Control memory error',
	503   => 'Waveform memory error',
	504   => 'GPIB interface error',

	# Table 5-12 Device Dependent Device Errors
	600   => 'Calibration error',
	601   => 'Offset calibration error',
	602   => 'Arbitrary gain calibration error',
	603   => 'Sine gain calibration error',
	604   => 'Square gain calibration error',
	605   => 'AM offset calibration error',
	606   => 'Sine flatnesscalibration error',
	607   => 'Output attenuator calibration error',

	# Table 5-13 Device Dependent Device Errors
	700   => 'Trace data error',
	701   => 'User waveform locked',
	702   => 'Trace data byte count error',
	703   => 'Too much trace data',
	704   => 'Not enough trace data',
    };

    return $self;
}

# Print the error queue
# Different to the on in Tektronix.pm since the error text strings are already included
sub getErrorsAsStrings($)
{
     my ($self) = @_;

     my @ret;
     while (1)
     {
	 my $error = $self->sendAndRead('SYST:ERR?');
	 return @ret if $error == 0;
	 push(@ret, $error);
     }
}

1;
