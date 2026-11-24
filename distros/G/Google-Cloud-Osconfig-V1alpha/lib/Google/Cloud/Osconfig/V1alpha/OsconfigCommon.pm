package Google::Cloud::Osconfig::V1alpha::OsconfigCommon;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvb3Njb25maWcvdjFhbHBoYS9vc2NvbmZpZ19jb21tb24ucHJvdG8S
HWdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MWFscGhhIkwKDkZpeGVkT3JQZXJjZW50EhYKBWZp
eGVkGAEgASgFSABSBWZpeGVkEhoKB3BlcmNlbnQYAiABKAVIAFIHcGVyY2VudEIGCgRtb2Rl
Qs8BCiFjb20uZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxYWxwaGFCBkNvbW1vblABWj1jbG91
ZC5nb29nbGUuY29tL2dvL29zY29uZmlnL2FwaXYxYWxwaGEvb3Njb25maWdwYjtvc2NvbmZp
Z3BiqgIdR29vZ2xlLkNsb3VkLk9zQ29uZmlnLlYxQWxwaGHKAh1Hb29nbGVcQ2xvdWRcT3ND
b25maWdcVjFhbHBoYeoCIEdvb2dsZTo6Q2xvdWQ6Ok9zQ29uZmlnOjpWMWFscGhhSo0JCgYS
BA4AJwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACYKCAoB
CBIDEwA6CgkKAgglEgMTADoKCAoBCBIDFABUCgkKAggLEgMUAFQKCAoBCBIDFQAiCgkKAggK
EgMVACIKCAoBCBIDFgAnCgkKAggIEgMWACcKCAoBCBIDFwA6CgkKAggBEgMXADoKCAoBCBID
GAA6CgkKAggpEgMYADoKCAoBCBIDGQA5CgkKAggtEgMZADkKdgoCBAASBB0AJwEaaiBNZXNz
YWdlIGVuY2Fwc3VsYXRpbmcgYSB2YWx1ZSB0aGF0IGNhbiBiZSBlaXRoZXIgYWJzb2x1dGUg
KCJmaXhlZCIpIG9yCiByZWxhdGl2ZSAoInBlcmNlbnQiKSB0byBhIHZhbHVlLgoKCgoDBAAB
EgMdCBYKIgoEBAAIABIEHwImAxoUIFR5cGUgb2YgdGhlIHZhbHVlLgoKDAoFBAAIAAESAx8I
DAonCgQEAAIAEgMhBBQaGiBTcGVjaWZpZXMgYSBmaXhlZCB2YWx1ZS4KCgwKBQQAAgAFEgMh
BAkKDAoFBAACAAESAyEKDwoMCgUEAAIAAxIDIRITCnQKBAQAAgESAyUEFhpnIFNwZWNpZmll
cyB0aGUgcmVsYXRpdmUgdmFsdWUgZGVmaW5lZCBhcyBhIHBlcmNlbnRhZ2UsIHdoaWNoIHdp
bGwgYmUKIG11bHRpcGxpZWQgYnkgYSByZWZlcmVuY2UgdmFsdWUuCgoMCgUEAAIBBRIDJQQJ
CgwKBQQAAgEBEgMlChEKDAoFBAACAQMSAyUUFWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Osconfig::V1alpha::OsconfigCommon::FixedOrPercent ===
    # Fields for FixedOrPercent
    # Field: fixed Type: 5 ()
    # Field: percent Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Osconfig::V1alpha::OsconfigCommon - Compiled Protocol Buffers messages for google/cloud/osconfig/v1alpha/osconfig_common.proto

=head1 SYNOPSIS

    use Google::Cloud::Osconfig::V1alpha::OsconfigCommon;

    my $msg = Google::Cloud::Osconfig::V1alpha::OsconfigCommon::FixedOrPercent->new({
        fixed => $fixed,
        percent => $percent,
    });

    # Read or update a field
    my $val = $msg->fixed();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Osconfig::V1alpha::OsconfigCommon::FixedOrPercent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/osconfig/v1alpha/osconfig_common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Osconfig::V1alpha::OsconfigCommon::FixedOrPercent

Message encapsulating a value that can be either absolute ("fixed") or
relative ("percent") to a value.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->fixed() >> / C<< $msg->fixed($value) >>

Type: C<Int32>

Specifies a fixed value.

=item * C<< $msg->percent() >> / C<< $msg->percent($value) >>

Type: C<Int32>

Specifies the relative value defined as a percentage, which will be
multiplied by a reference value.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Osconfig::V1alpha::OsconfigCommon::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
