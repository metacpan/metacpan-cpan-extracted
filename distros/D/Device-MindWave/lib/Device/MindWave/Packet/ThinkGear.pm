package Device::MindWave::Packet::ThinkGear;

use strict;
use warnings;

use Device::MindWave::Packet::ThinkGear::DataValue::PoorSignal;
use Device::MindWave::Packet::ThinkGear::DataValue::Attention;
use Device::MindWave::Packet::ThinkGear::DataValue::Meditation;
use Device::MindWave::Packet::ThinkGear::DataValue::BlinkStrength;
use Device::MindWave::Packet::ThinkGear::DataValue::RawWave;
use Device::MindWave::Packet::ThinkGear::DataValue::EEG;

use List::Util qw(sum);

use base qw(Device::MindWave::Packet);

my %SB_CODE_MAP = (
    0x02 => 'PoorSignal',
    0x04 => 'Attention',
    0x05 => 'Meditation',
    0x16 => 'BlinkStrength',
);

my %MB_CODE_MAP = (
    0x80 => 'RawWave',
    0x83 => 'EEG',
);

sub new
{
    my ($class, $bytes, $index) = @_;

    my $dvs = _parse($bytes, $index);
    my $self = { data_values => $dvs, index => 0 };
    bless $self, $class;
    return $self;
}

sub _parse_data_value
{
    my ($bytes, $index) = @_;

    my $excode = 0;
    for (; $index < @{$bytes}; $index++) {
        if ($bytes->[$index] == 0x55) {
            $excode++;
        } else {
            last;
        }
    }

    if ($excode != 0) {
        warn "Unhandled data value (uses extended codes).";
    }

    my $code = $bytes->[$index];
    if ($code < 0x80) {
        if (exists $SB_CODE_MAP{$code}) {
            my $pkg = "Device::MindWave::Packet::ThinkGear::DataValue::".
                      $SB_CODE_MAP{$code};
            my $datavalue = $pkg->new($bytes, $index);
            return ($datavalue, $index + $datavalue->length());
        } else {
            warn "Unhandled single-byte value code: $code";
            return (undef, ($index + 2));
        }
    } else {
        if (exists $MB_CODE_MAP{$code}) {
            my $pkg = "Device::MindWave::Packet::ThinkGear::DataValue::".
                      $MB_CODE_MAP{$code};
            my $datavalue = $pkg->new($bytes, $index);
            return ($datavalue, $index + $datavalue->length());
        } else {
            my $length = $bytes->[$index + 1];
            $index += (2 + $length);
            warn "Unhandled multi-byte value code: $code";
            return (undef, $index);
        }
    }
}

sub _parse
{
    my ($bytes, $index) = @_;

    my $length = @{$bytes};
    my @dvs;
    my $dv;
    while ($index < $length) {
        ($dv, $index) = _parse_data_value($bytes, $index);
        if (defined $dv) {
            push @dvs, $dv;
        }
    }

    return \@dvs;
}

sub next_data_value
{
    my ($self) = @_;

    return $self->{'data_values'}->[$self->{'index'}++];
}

sub as_bytes
{
    my ($self) = @_;

    return [ map { @{$_->as_bytes()} } @{$self->{'data_values'}} ];
}

sub length
{
    my ($self) = @_;

    return (sum 0, map { $_->length() } @{$self->{'data_values'}});
}

sub as_string
{
    my ($self) = @_;

    return join '; ', map { $_->as_string() } @{$self->{'data_values'}};
}

sub as_hashref
{
    my ($self) = @_;

    return { map { %{$_->as_hashref()} } @{$self->{'data_values'}} };
}

1;

__END__

=head1 NAME

Device::MindWave::Packet::ThinkGear

=head1 DESCRIPTION

Implementation of the ThinkGear packet. See
L<http://wearcam.org/ece516/mindset_communications_protocol.pdf> for
documentation on this type of packet.

The C<ThinkGear::DataValue> modules are used to store the 'actual'
data: this module simply provides an iterator over those data values.

=head1 CONSTRUCTOR

=over 4

=item B<new>

=back

=head1 PUBLIC METHODS

=over 4

=item B<next_data_value>

Return the next C<ThinkGear::DataValue> from the packet. Returns
the undefined value if no data values remain.

=item B<as_hashref>

Aggregates the hashrefs of the packet's constituent
C<ThinkGear::DataValue>s, and returns that hashref.

=item B<as_bytes>

=item B<length>

=item B<as_string>

=back

=cut
