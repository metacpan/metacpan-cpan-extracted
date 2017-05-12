package Device::MindWave::Packet::ThinkGear::DataValue::BlinkStrength;

use strict;
use warnings;

use Device::MindWave::Utils qw(checksum);

use base qw(Device::MindWave::Packet::ThinkGear::DataValue);

sub new
{
    my ($class, $bytes, $index) = @_;

    my $self = { value => $bytes->[$index + 1] };
    bless $self, $class;
    return $self;
}

sub as_bytes
{
    my ($self) = @_;

    return [ 0x16, $self->{'value'} ];
}

sub length
{
    return 2;
}

sub as_string
{
    my ($self) = @_;

    return "Blink strength (".$self->{'value'}."/255)";
}

sub as_hashref
{
    my ($self) = @_;

    return { BlinkStrength => $self->{'value'} };
}

1;

__END__

=head1 NAME

Device::MindWave::Packet::ThinkGear::DataValue::BlinkStrength

=head1 DESCRIPTION

Implementation of the 'Blink Strength' data value. This is a
single-byte value in the range 0-255.

=head1 CONSTRUCTOR

=over 4

=item B<new>

=back

=head1 PUBLIC METHODS

=over 4

=item B<as_string>

=item B<as_bytes>

=item B<length>

=item B<as_hashref>

=back

=cut
