package Google::Cloud::Securitycenter::V2::AffectedResources;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvYWZmZWN0ZWRfcmVzb3VyY2VzLnBy
b3RvEh5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIiKQoRQWZmZWN0ZWRSZXNvdXJj
ZXMSFAoFY291bnQYASABKANSBWNvdW50QvABCiJjb20uZ29vZ2xlLmNsb3VkLnNlY3VyaXR5
Y2VudGVyLnYyQhZBZmZlY3RlZFJlc291cmNlc1Byb3RvUAFaSmNsb3VkLmdvb2dsZS5jb20v
Z28vc2VjdXJpdHljZW50ZXIvYXBpdjIvc2VjdXJpdHljZW50ZXJwYjtzZWN1cml0eWNlbnRl
cnBiqgIeR29vZ2xlLkNsb3VkLlNlY3VyaXR5Q2VudGVyLlYyygIeR29vZ2xlXENsb3VkXFNl
Y3VyaXR5Q2VudGVyXFYy6gIhR29vZ2xlOjpDbG91ZDo6U2VjdXJpdHlDZW50ZXI6OlYySpsH
CgYSBA4AHgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcK
CAoBCBIDEgA7CgkKAgglEgMSADsKCAoBCBIDEwBhCgkKAggLEgMTAGEKCAoBCBIDFAAiCgkK
AggKEgMUACIKCAoBCBIDFQA3CgkKAggIEgMVADcKCAoBCBIDFgA7CgkKAggBEgMWADsKCAoB
CBIDFwA7CgkKAggpEgMXADsKCAoBCBIDGAA6CgkKAggtEgMYADoKPwoCBAASBBsAHgEaMyBE
ZXRhaWxzIGFib3V0IHJlc291cmNlcyBhZmZlY3RlZCBieSB0aGlzIGZpbmRpbmcuCgoKCgME
AAESAxsIGQo+CgQEAAIAEgMdAhIaMSBUaGUgY291bnQgb2YgcmVzb3VyY2VzIGFmZmVjdGVk
IGJ5IHRoZSBmaW5kaW5nLgoKDAoFBAACAAUSAx0CBwoMCgUEAAIAARIDHQgNCgwKBQQAAgAD
EgMdEBFiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::AffectedResources::AffectedResources ===
    # Fields for AffectedResources
    # Field: count Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::AffectedResources - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/affected_resources.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::AffectedResources;

    my $msg = Google::Cloud::Securitycenter::V2::AffectedResources::AffectedResources->new({
        count => $count,
    });

    # Read or update a field
    my $val = $msg->count();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::AffectedResources::AffectedResources->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/affected_resources.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::AffectedResources::AffectedResources

Details about resources affected by this finding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->count() >> / C<< $msg->count($value) >>

Type: C<Int64>

The count of resources affected by the finding.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::AffectedResources::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
