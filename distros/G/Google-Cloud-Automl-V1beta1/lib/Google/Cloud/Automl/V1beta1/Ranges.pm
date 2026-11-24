package Google::Cloud::Automl::V1beta1::Ranges;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvcmFuZ2VzLnByb3RvEhtnb29nbGUuY2xv
dWQuYXV0b21sLnYxYmV0YTEiNQoLRG91YmxlUmFuZ2USFAoFc3RhcnQYASABKAFSBXN0YXJ0
EhAKA2VuZBgCIAEoAVIDZW5kQqgBCh9jb20uZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGEx
QgtSYW5nZXNQcm90b1ABWjdjbG91ZC5nb29nbGUuY29tL2dvL2F1dG9tbC9hcGl2MWJldGEx
L2F1dG9tbHBiO2F1dG9tbHBiygIbR29vZ2xlXENsb3VkXEF1dG9NbFxWMWJldGEx6gIeR29v
Z2xlOjpDbG91ZDo6QXV0b01MOjpWMWJldGExSr4HCgYSBA4AIQEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACQKCAoBCBIDEwBOCgkKAggLEgMTAE4KCAoB
CBIDFAAiCgkKAggKEgMUACIKCAoBCBIDFQAsCgkKAggIEgMVACwKCAoBCBIDFgA4CgkKAggB
EgMWADgKCAoBCBIDFwA4CgkKAggpEgMXADgKCAoBCBIDGAA3CgkKAggtEgMYADcKMQoCBAAS
BBsAIQEaJSBBIHJhbmdlIGJldHdlZW4gdHdvIGRvdWJsZSBudW1iZXJzLgoKCgoDBAABEgMb
CBMKLQoEBAACABIDHQITGiAgU3RhcnQgb2YgdGhlIHJhbmdlLCBpbmNsdXNpdmUuCgoMCgUE
AAIABRIDHQIICgwKBQQAAgABEgMdCQ4KDAoFBAACAAMSAx0REgorCgQEAAIBEgMgAhEaHiBF
bmQgb2YgdGhlIHJhbmdlLCBleGNsdXNpdmUuCgoMCgUEAAIBBRIDIAIICgwKBQQAAgEBEgMg
CQwKDAoFBAACAQMSAyAPEGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::Ranges::DoubleRange ===
    # Fields for DoubleRange
    # Field: start Type: 1 ()
    # Field: end Type: 1 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::Ranges - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/ranges.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::Ranges;

    my $msg = Google::Cloud::Automl::V1beta1::Ranges::DoubleRange->new({
        start => $start,
        end => $end,
    });

    # Read or update a field
    my $val = $msg->start();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::Ranges::DoubleRange->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/ranges.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::Ranges::DoubleRange

A range between two double numbers.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start() >> / C<< $msg->start($value) >>

Type: C<Double>

Start of the range, inclusive.

=item * C<< $msg->end() >> / C<< $msg->end($value) >>

Type: C<Double>

End of the range, exclusive.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::Ranges::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
