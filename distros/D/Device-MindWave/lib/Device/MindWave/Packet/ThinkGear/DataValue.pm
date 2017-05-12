package Device::MindWave::Packet::ThinkGear::DataValue;

use strict;
use warnings;

sub new
{
    die "Abstract method 'new' not implemented.";
}

sub as_string
{
    die "Abstract method 'as_string' not implemented.";
}

sub as_hashref
{
    die "Abstract method 'as_hashref' not implemented.";
}

sub as_bytes
{
    die "Abstract method 'as_bytes' not implemented.";
}

1;

__END__

=head1 NAME

Device::MindWave::Packet::ThinkGear::DataValue

=head1 DESCRIPTION

Interface module for MindWave ThinkGear data values.

=head1 PUBLIC METHODS

=over 4

=item B<new>

Takes a byte arrayref and an index into that arrayref as its
arguments, representing the payload of the data value. Returns a new
instance of the relevant data value. Dies on error.

=item B<as_string>

Returns the data value's details as a human-readable string.

=item B<as_hashref>

Returns the actual data value(s) from the data value as a hashref.
(Most data values only have one actual data value, but at least one
has multiple, hence this method.)

For a given module, the key(s) in this hashref will begin with the
final segment of the module's name.

=item B<as_bytes>

Returns the data value's payload as an arrayref of bytes.

=item B<length>

Returns the number of bytes in the data value's payload.

=back

=cut
