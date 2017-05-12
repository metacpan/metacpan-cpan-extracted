package Device::MindWave::Packet::ThinkGear::DataValue::PoorSignal;

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

    return [ 0x02, $self->{'value'} ];
}

sub length
{
    return 2;
}

sub as_string
{
    my ($self) = @_;

    return "Poor signal (".$self->{'value'}."/200)".
           (($self->{'value'} == 200) ? " (no signal found)" : "");
}

sub as_hashref
{
    my ($self) = @_;

    return { PoorSignal => $self->{'value'} };
}

1;

__END__

=head1 NAME

Device::MindWave::Packet::ThinkGear::DataValue::PoorSignal

=head1 DESCRIPTION

Implementation of the 'Poor Signal' data value. This is a single-byte
value in the range 0-200, where zero denotes a perfect signal and 200
that no signal can be found.

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
