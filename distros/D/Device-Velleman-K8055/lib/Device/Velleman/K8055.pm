package Device::Velleman::K8055;

use warnings;
use strict;
use base 'Exporter';

our (@EXPORT_OK, %EXPORT_TAGS);

use Win32::API;
$Win32::API::DEBUG=1;
Win32::API->Import('K8055D.DLL', 'OpenDevice','I','I');
Win32::API->Import('K8055D.DLL', 'CloseDevice','','');
Win32::API->Import('K8055D.DLL', 'ReadAnalogChannel','I','I');
Win32::API->Import('K8055D.DLL', 'ReadAllAnalog','II','');
Win32::API->Import('K8055D.DLL', 'OutputAnalogChannel','II','');
Win32::API->Import('K8055D.DLL', 'OutputAllAnalog','II','');
Win32::API->Import('K8055D.DLL', 'ClearAnalogChannel','I',''); 
Win32::API->Import('K8055D.DLL', 'ClearAllAnalog','','');
Win32::API->Import('K8055D.DLL', 'SetAnalogChannel','I',''); 
Win32::API->Import('K8055D.DLL', 'SetAllAnalog','','');
Win32::API->Import('K8055D.DLL', 'WriteAllDigital','I','');
Win32::API->Import('K8055D.DLL', 'ClearDigitalChannel','I','');
Win32::API->Import('K8055D.DLL', 'ClearAllDigital','','');
Win32::API->Import('K8055D.DLL', 'SetDigitalChannel','I','');
Win32::API->Import('K8055D.DLL', 'SetAllDigital','','');
Win32::API->Import('K8055D.DLL', 'ReadDigitalChannel','I','I');
Win32::API->Import('K8055D.DLL', 'ReadAllDigital','', 'I');
Win32::API->Import('K8055D.DLL', 'ReadCounter','I','I');
Win32::API->Import('K8055D.DLL', 'ResetCounter','I','');
Win32::API->Import('K8055D.DLL', 'SetCounterDebounceTime','II','');

%EXPORT_TAGS = (all => [qw( &OpenDevice                  
                            &CloseDevice                 
                            &ReadAnalogChannel           
                            &ReadAllAnalog               
                            &OutputAnalogChannel         
                            &OutputAllAnalog             
                            &ClearAnalogChannel          
                            &ClearAllAnalog              
                            &SetAnalogChannel            
                            &SetAllAnalog                
                            &WriteAllDigital             
                            &ClearDigitalChannel         
                            &ClearAllDigital             
                            &SetDigitalChannel           
                            &SetAllDigital               
                            &ReadDigitalChannel          
                            &ReadAllDigital              
                            &ReadCounter                 
                            &ResetCounter                
                            &SetCounterDebounceTime)]);

@EXPORT_OK   = qw(  &OpenDevice                  
                    &CloseDevice                 
                    &ReadAnalogChannel           
                    &ReadAllAnalog               
                    &OutputAnalogChannel         
                    &OutputAllAnalog             
                    &ClearAnalogChannel          
                    &ClearAllAnalog              
                    &SetAnalogChannel            
                    &SetAllAnalog                
                    &WriteAllDigital             
                    &ClearDigitalChannel         
                    &ClearAllDigital             
                    &SetDigitalChannel           
                    &SetAllDigital               
                    &ReadDigitalChannel          
                    &ReadAllDigital              
                    &ReadCounter                 
                    &ResetCounter                
                    &SetCounterDebounceTime      );


our $VERSION = '0.02';

1; # End of Device::Velleman::K8055

__END__

=pod

=head1 NAME

Device::Velleman::K8055 - Communication with the Velleman K8055 USB experiment board

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

Currently this module is just a Win32::API wrapper around the DLL that Velleman
supplies with the board. Since that will only work on Win32 systems, I intend
to write something myself that will be portable to other platforms...patches for
this are welcome.

    use Device::Velleman::K8055 qw(:all);

    # Trying to open device 0
    die "Can't open K8055 device" unless OpenDevice(0) == 0;
    
    # let us flicker the Analog output leds three times each
    for (my $i = 0; $i < 3; $i++)
    {
        for (my $j = 1; $j < 3; $j++)
        {
            SetAnalogChannel($j);
            ClearAnalogChannel($j == 1 ? 2 : ($j -1));
            sleep(1);
        }
    }
    # clear the analog output
    ClearAllAnalog();
    # and close the device
    CloseDevice();

=head1 USAGE

This module consists of the functions that the K8055D.dll provides:

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

=head1 AUTHOR

Jouke, C<< <jouke@pvoice.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-device-velleman-k8055@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Device-Velleman-K8055>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks to Yaakov and Hachi from #perl on irc.perl.org for the idea that
eventually lead to buying the K8055 USB experiment board.

Most of the documentation (if not all) was derrived from the "Software manual"
that comes with the K8055 board.

=head1 SEE ALSO

For more information on this board, visit http://www.velleman.be

=head1 COPYRIGHT & LICENSE

Copyright 2005 Jouke, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

