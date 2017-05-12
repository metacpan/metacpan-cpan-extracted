# Copyright (c) 2015,  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are 
# met:
# 
#     * Redistributions of source code must retain the above copyright 
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in 
#       the documentation and/or other materials provided with the 
#       distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS 
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED 
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A 
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
package Device::Spektrum;
$Device::Spektrum::VERSION = '0.498225878299312';
use v5.14;
use warnings;
use Moose;
use namespace::autoclean;

# ABSTRACT: Send packets compatible with the Spektrum RC protoocol


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  Device::Spektrum - Send packets compatible with the Spektrum RC protocol

=head1 SYNOPSIS

    use Device::Spektrum::Packet;
    my $packet = Device::Spektrum::Packet->new({
        throttle => 170,
        aileron => 200,
        elevator => 250,
        rudder => 800,
        gear => SPEKTRUM_LOW,
        aux1 => SPEKTRUM_MIDDLE,
        aux2 => SPEKTRUM_HIGH,

        # Optional; may correct problems with buggy implementations
        field_order => [qw(
            throttle
            aileron
            elevator
            rudder
            gear
            aux1
            aux2
        )],
    });
    
    my $encoded_packet = $packet->encode_packet;

=head1 DESCRIPTION

Spektrum is a serial protocol that is compatible with many RC flight controllers. Using 
this module allows you to craft output packets compatible with these flight controllers. It 
supports up to 7 channels.

Data is sent over a serial connection with one start bit, 8 data bits, LSB, no parity, 
and one stop bit, all at 115.2Kbps. A 22 millisecond delay may be needed in between packets;
I had trouble getting the Naze32 to behave when the program sent data as fast as possible.

The C<field_order> parameter shouldn't be necessary, because the protocol uses a few 
identifier bits for each channel. However, some implementations out there hardcode the 
channel order to what common Spektrum recievers put out, so you may need to work around 
them with this parameter.

Most of the interesting parts of the API is in L<Device::Spektrum::Packet>, so read those 
docs for details.

=head1 SEE ALSO

Protocol description: L<http://www.desertrc.com/spektrum_protocol.htm>

=head1 LICENSE

Copyright (c) 2015,  Timm Murray
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are 
permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of 
      conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of 
      conditions and the following disclaimer in the documentation and/or other materials 
      provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS 
OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR 
TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
