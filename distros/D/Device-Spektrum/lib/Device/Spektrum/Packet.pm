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
package Device::Spektrum::Packet;
$Device::Spektrum::Packet::VERSION = '0.498225878299312';
use v5.14;
use warnings;
use Moose;
use namespace::autoclean;
use base 'Exporter';

use constant HEADER => 0x039b;
use constant {
    THROTTLE_ID => 0x00,
    AILERON_ID => 0x01,
    ELEVATOR_ID => 0x02,
    RUDDER_ID => 0x03,
    GEAR_ID => 0x04,
    AUX1_ID => 0x05,
    AUX2_ID => 0x06,
};
use constant SPEKTRUM_LOW => 170;
use constant SPEKTRUM_HIGH => 853;
use constant SPEKTRUM_MIDDLE => int( ((SPEKTRUM_HIGH - SPEKTRUM_LOW) / 2)
    + SPEKTRUM_LOW );

my @EXPORT_SYM = qw( SPEKTRUM_LOW SPEKTRUM_MIDDLE SPEKTRUM_HIGH );
our @EXPORT_OK = @EXPORT_SYM;
our @EXPORT = @EXPORT_SYM;


has $_ =>  (
    is => 'ro',
    isa => 'Int',
    required => 1,
) for qw{
    throttle aileron elevator rudder gear aux1 aux2
};

has 'field_order' => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub {[qw{
        throttle
        aileron
        elevator
        rudder
        gear
        aux1
        aux2
    }]},
);
has 'field_id' => (
    is => 'ro',
    isa => 'HashRef[Str]',
    default => sub {{
        throttle => 'THROTTLE_ID',
        aileron => 'AILERON_ID',
        elevator => 'ELEVATOR_ID',
        rudder => 'RUDDER_ID',
        gear => 'GEAR_ID',
        aux1 => 'AUX1_ID',
        aux2 => 'AUX2_ID',
    }},
);


sub encode_packet
{
    my ($self) = @_;
    my $packet = pack( 'n*',
        HEADER,
        map {
            my $field_id = $self->field_id->{$_};
            $self->_encode( $self->$field_id, $self->$_ );
        } @{ $self->field_order },
    );
    return $packet;
}


sub _encode
{
    my ($self, $id, $val) = @_;
    my $encoded_val = 0xFFFF & (($id << 10) | $val);
    return $encoded_val;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  Device::Spektrum::Packet - Represent a packet of Spektrum data

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

Represents a single packet of Spektrum data.

=head1 ATTRIBUTES

=over 4

=item * throttle

=item * aileron

=item * elevator

=item * rudder

=item * gear

=item * aux1

=item * aux2

=back

Each attribute takes an integer. These are typically in between 170 (exported as 
C<SPEKTRUM_LOW>) and 853 (C<SPEKTRUM_HIGH>). The protocol is technically capable of 
values between 0 and 1023, but servos and flight controllers may not be well-behaved outside
the typical range.

There is also a C<field_order> parameter, which shouldn't be necessary, because the 
protocol uses a few identifier bits for each channel. However, some implementations out 
there hardcode the channel order to what common Spektrum recievers put out, so you may need 
to work around them with this parameter.

=head1 METHODS

=head2 encode_packet

Return a byte string containing the encoded packet.

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
