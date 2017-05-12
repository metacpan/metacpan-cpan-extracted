package Device::MindWave::Packet::Dongle::ScanMode;

use strict;
use warnings;

use base qw(Device::MindWave::Packet::Dongle);

sub new
{
    my ($class) = @_;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub code
{
    return 0xD5;
}

sub as_bytes
{
    my ($self) = @_;

    return [ 0xD4, 0x01, 0x01 ];
}

sub length
{
    return 3;
}

sub as_string
{
    return "Scanning";
}

1;

__END__

=head1 NAME

Device::MindWave::Packet::Dongle::ScanMode

=head1 DESCRIPTION

Implementation of the 'Dongle is Trying to find a headset' packet
(number 6 in the documentation).

=head1 CONSTRUCTOR

=over 4

=item B<new>

=back

=head1 PUBLIC METHODS

=over 4

=item B<code>

=item B<as_bytes>

=item B<length>

=item B<as_string>

=back

=cut
