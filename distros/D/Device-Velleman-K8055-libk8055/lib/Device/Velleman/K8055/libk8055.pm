package Device::Velleman::K8055::libk8055;

use 5.008000;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Device::Velleman::K8055::libk8055 ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	ClearAllAnalog
	ClearAllDigital
	ClearAnalogChannel
	ClearDigitalChannel
	CloseDevice
	OpenDevice
	OutputAllAnalog
	OutputAnalogChannel
	ReadAllAnalog
	ReadAllDigital
	ReadAnalogChannel
	ReadCounter
	ReadDigitalChannel
	ResetCounter
	SetAllAnalog
	SetAllDigital
	SetAnalogChannel
	SetCounterDebounceTime
	SetDigitalChannel
	WriteAllDigital
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = ( @{ $EXPORT_TAGS{'all'} } ); 

our $VERSION = '0.04';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Device::Velleman::K8055::libk8055::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Device::Velleman::K8055::libk8055', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Device::Velleman::K8055::libk8055 - Communication with the Velleman K8055 USB experiment board via libk8055 

=head1 SYNOPSIS

Currently this module is just a wrapper around the Linux libk8055 library by Sven Lindberg. The libk8055 library is made from scratch with the same functions as described in Velleman's DLL usermanual.

  use strict;
  use Device::Velleman::K8055::libk8055;

  my $ipid=0;
  my $result;

  die ("K8055 OpenDevice failed") unless (OpenDevice($ipid) == 0);

  # light up each output
  for (my $i=1;$i<256;$i=$i*2) {
    $result=WriteAllDigital($i);
    print "Sent $i\n";
    sleep(1);
  }

  # set all zeros (turn off)
  ClearAllDigital();
  # close device
  CloseDevice();

=head1 DEPENDENCIES

This interface is dependent on the k8055 linux library. Please download and install the latest version at http://libk8055.sourceforge.net/.  

Linux k8055 library MUST be found in your library path when using this module.  k8055 library is defaultly installed in /usr/local/lib -- in this case, be sure that the /usr/local/lib path is in your /etc/ld.so.conf.

=head1 USAGE

This module consists of the functions that the libk8055 library provides:

=head2 OpenDevice($devicenumber);

This opens the device, indicated by $devicenumber, which can be any
value ranging from 0 to 3. The devicenumber is determined by the
jumpers you set on the board. The default setting is 0.

It returns -1 if it's unsuccessful, the devicenumber that has been opened in case of success.

This function can also be used to select the active K8055 card to read and write the data. All the
communication routines after this function call are addressed to this card until the other card is
selected by this function call.

=head2 CloseDevice();

This closes the device. You don't need to call CloseDevice between
switching of the different devicenumbers. Just call it at the end
of your application.

=head2 $value = ReadAnalogChannel($channel);

This reads the value from the analog channel indicated by $channel (1 or 2).
The input voltage of the selected 8-bit Analogue to Digital converter channel is converted to a value
which lies between 0 and 255.

=head2 ReadAllAnalog($data1, $data2);

This reads the values from the two analog ports into $data1 and $data2.

=head2 OutputAnalogChannel($channel, $data);

This outputs $data to the analog channel indicated by $channel.
The indicated 8-bit Digital to Analogue Converter channel is altered according to the new data.
This means that the data corresponds to a specific voltage. The value 0 corresponds to a
minimum output voltage (0 Volt) and the value 255 corresponds to a maximum output voltage (+5V).
A value of $data lying in between these extremes can be translated by the following formula :
$data / 255 * 5V.

=head2 OutputAllAnalog($data1, $data2);

This outputs $data1 to the first analog channel, and $data2 to the
second analog channel. See OutputAnalogChannel for more information.

=head2 ClearAnalogChannel($channel);

This clears the analog channel indicated by $channel. The selected DA-channel is set to
minimum output voltage (0 Volt).

=head2 ClearAllAnalog();

The two DA-channels are set to the minimum output voltage (0 volt).

=head2 SetAnalogChannel($channel);

The selected 8-bit Digital to Analogue Converter channel is set to maximum output voltage.

=head2 SetAllAnalog();

The two DA-channels are set to the maximum output voltage.

=head2 WriteAllDigital($data);

The channels of the digital output port are updated with the status of the corresponding
bits in the $data parameter. A high (1) level means that the microcontroller IC1 output
is set, and a low (0) level means that the output is cleared.
$data is a value between 0 and 255 that is sent to the output port (8 channels).

=head2 ClearDigitalChannel($channel);

This clears the digital channel $channel, which can have a value between 1 and 8
that corresponds to the output channel that is to be cleared.

=head2 ClearAllDigital();

This clears (sets to 0) all digital output channels.

=head2 SetDigitalChannel($channel);

This sets digital channel $channel to 1.

=head2 SetAllDigital();

This sets all digital output channels to 1.

=head2 $value = ReadDigitalChannel($channel);

The status of the selected input $channel is read.
$channel can have a value between 1 and 5 which corresponds to the input channel whose
status is to be read.
The return value will be true if the channel has been set, false otherwise

=head2 $value = ReadAllDigital();

This reads all 5 digital ports at once. The 5 least significant bits correspond to the
status of the input channels. A high (1) means that the
channel is set, a low (0) means that the channel is cleared.

=head2 $value = ReadCounter($counternumber);

The function returns the status of the selected 16 bit pulse counter.
The counter number 1 counts the pulses fed to the input I1 and the counter number 2 counts the
pulses fed to the input I2.
The return value is a 16 bit number.

=head2 $value = ResetCounter($counternumber);

This resets the selected pulse counter.

=head2 SetCounterDebounceTime($counternumber, $debouncetime);

The counter inputs are debounced in the software to prevent false triggering when mechanical
switches or relay inputs are used. The debounce time is equal for both falling and rising edges. The
default debounce time is 2ms. This means the counter input must be stable for at least 2ms before it is
recognised, giving the maximum count rate of about 200 counts per second.
If the debounce time is set to 0, then the maximum counting rate is about 2000 counts per second.

The $deboucetime value corresponds to the debounce time in milliseconds (ms) to be set for the
pulse counter. Debounce time value may vary between 0 and 5000.

=head1 SEE ALSO

Linux k8055 library: http://libk8055.sourceforge.net/
For more information on this board, visit http://www.velleman.be

=head1 REPOSITORY

Repository is available on GitHub: http://github.com/kost/libk8055-perl

=head1 AUTHOR

Vlatko Kosturjak, E<lt>kost@linux.hrE<gt>

=head1 ACKNOWLEDGEMENTS

libk8055 library: Sven Lindberg E<lt>k8055 @ mrbrain.mine.nuE<gt>
Documentation: Jouke, E<lt>jouke@pvoice.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Vlatko Kosturjak

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
