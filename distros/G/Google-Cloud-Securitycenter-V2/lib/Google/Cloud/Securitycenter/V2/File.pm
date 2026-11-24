package Google::Cloud::Securitycenter::V2::File;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvZmlsZS5wcm90bxIeZ29vZ2xlLmNs
b3VkLnNlY3VyaXR5Y2VudGVyLnYyIvcECgRGaWxlEhIKBHBhdGgYASABKAlSBHBhdGgSEgoE
c2l6ZRgCIAEoA1IEc2l6ZRIWCgZzaGEyNTYYAyABKAlSBnNoYTI1NhIfCgtoYXNoZWRfc2l6
ZRgEIAEoA1IKaGFzaGVkU2l6ZRIpChBwYXJ0aWFsbHlfaGFzaGVkGAUgASgIUg9wYXJ0aWFs
bHlIYXNoZWQSGgoIY29udGVudHMYBiABKAlSCGNvbnRlbnRzEkoKCWRpc2tfcGF0aBgHIAEo
CzItLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52Mi5GaWxlLkRpc2tQYXRoUghkaXNr
UGF0aBJSCgpvcGVyYXRpb25zGAggAygLMjIuZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVy
LnYyLkZpbGUuRmlsZU9wZXJhdGlvblIKb3BlcmF0aW9ucxpWCghEaXNrUGF0aBIlCg5wYXJ0
aXRpb25fdXVpZBgBIAEoCVINcGFydGl0aW9uVXVpZBIjCg1yZWxhdGl2ZV9wYXRoGAIgASgJ
UgxyZWxhdGl2ZVBhdGgazgEKDUZpbGVPcGVyYXRpb24SVAoEdHlwZRgBIAEoDjJALmdvb2ds
ZS5jbG91ZC5zZWN1cml0eWNlbnRlci52Mi5GaWxlLkZpbGVPcGVyYXRpb24uT3BlcmF0aW9u
VHlwZVIEdHlwZSJnCg1PcGVyYXRpb25UeXBlEh4KGk9QRVJBVElPTl9UWVBFX1VOU1BFQ0lG
SUVEEAASCAoET1BFThABEggKBFJFQUQQAhIKCgZSRU5BTUUQAxIJCgVXUklURRAEEgsKB0VY
RUNVVEUQBULjAQoiY29tLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MkIJRmlsZVBy
b3RvUAFaSmNsb3VkLmdvb2dsZS5jb20vZ28vc2VjdXJpdHljZW50ZXIvYXBpdjIvc2VjdXJp
dHljZW50ZXJwYjtzZWN1cml0eWNlbnRlcnBiqgIeR29vZ2xlLkNsb3VkLlNlY3VyaXR5Q2Vu
dGVyLlYyygIeR29vZ2xlXENsb3VkXFNlY3VyaXR5Q2VudGVyXFYy6gIhR29vZ2xlOjpDbG91
ZDo6U2VjdXJpdHlDZW50ZXI6OlYySrgYCgYSBA4AXgEKvAQKAQwSAw4AEjKxBCBDb3B5cmln
aHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNl
LCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBm
aWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9i
dGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUu
b3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2Fi
bGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQg
dW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywK
IFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIg
ZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMg
bGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIg
dGhlIExpY2Vuc2UuCgoICgECEgMQACcKCAoBCBIDEgA7CgkKAgglEgMSADsKCAoBCBIDEwBh
CgkKAggLEgMTAGEKCAoBCBIDFAAiCgkKAggKEgMUACIKCAoBCBIDFQAqCgkKAggIEgMVACoK
CAoBCBIDFgA7CgkKAggBEgMWADsKCAoBCBIDFwA7CgkKAggpEgMXADsKCAoBCBIDGAA6CgkK
AggtEgMYADoKggEKAgQAEgQcAF4BGnYgRmlsZSBpbmZvcm1hdGlvbiBhYm91dCB0aGUgcmVs
YXRlZCBiaW5hcnkvbGlicmFyeSB1c2VkIGJ5IGFuIGV4ZWN1dGFibGUsIG9yCiB0aGUgc2Ny
aXB0IHVzZWQgYnkgYSBzY3JpcHQgaW50ZXJwcmV0ZXIKCgoKAwQAARIDHAgMClMKBAQAAwAS
BB4CJgMaRSBQYXRoIG9mIHRoZSBmaWxlIGluIHRlcm1zIG9mIHVuZGVybHlpbmcgZGlzay9w
YXJ0aXRpb24gaWRlbnRpZmllcnMuCgoMCgUEAAMAARIDHgoSCngKBgQAAwACABIDIQQeGmkg
VVVJRCBvZiB0aGUgcGFydGl0aW9uIChmb3JtYXQKIGh0dHBzOi8vd2lraS5hcmNobGludXgu
b3JnL3RpdGxlL3BlcnNpc3RlbnRfYmxvY2tfZGV2aWNlX25hbWluZyNieS11dWlkKQoKDgoH
BAADAAIABRIDIQQKCg4KBwQAAwACAAESAyELGQoOCgcEAAMAAgADEgMhHB0KfgoGBAADAAIB
EgMlBB0abyBSZWxhdGl2ZSBwYXRoIG9mIHRoZSBmaWxlIGluIHRoZSBwYXJ0aXRpb24gYXMg
YSBKU09OIGVuY29kZWQgc3RyaW5nLgogRXhhbXBsZTogL2hvbWUvdXNlcjEvZXhlY3V0YWJs
ZV9maWxlLnNoCgoOCgcEAAMAAgEFEgMlBAoKDgoHBAADAAIBARIDJQsYCg4KBwQAAwACAQMS
AyUbHAoxCgQEAAMBEgQpAkEDGiMgT3BlcmF0aW9uKHMpIHBlcmZvcm1lZCBvbiBhIGZpbGUu
CgoMCgUEAAMBARIDKQoXCisKBgQAAwEEABIEKwQ9BRobIFRoZSB0eXBlIG9mIHRoZSBvcGVy
YXRpb24KCg4KBwQAAwEEAAESAysJFgowCggEAAMBBAACABIDLQYlGh8gVGhlIG9wZXJhdGlv
biBpcyB1bnNwZWNpZmllZC4KChAKCQQAAwEEAAIAARIDLQYgChAKCQQAAwEEAAIAAhIDLSMk
CjAKCAQAAwEEAAIBEgMwBg8aHyBSZXByZXNlbnRzIGFuIG9wZW4gb3BlcmF0aW9uLgoKEAoJ
BAADAQQAAgEBEgMwBgoKEAoJBAADAQQAAgECEgMwDQ4KLwoIBAADAQQAAgISAzMGDxoeIFJl
cHJlc2VudHMgYSByZWFkIG9wZXJhdGlvbi4KChAKCQQAAwEEAAICARIDMwYKChAKCQQAAwEE
AAICAhIDMw0OCjEKCAQAAwEEAAIDEgM2BhEaICBSZXByZXNlbnRzIGEgcmVuYW1lIG9wZXJh
dGlvbi4KChAKCQQAAwEEAAIDARIDNgYMChAKCQQAAwEEAAIDAhIDNg8QCjAKCAQAAwEEAAIE
EgM5BhAaHyBSZXByZXNlbnRzIGEgd3JpdGUgb3BlcmF0aW9uLgoKEAoJBAADAQQAAgQBEgM5
BgsKEAoJBAADAQQAAgQCEgM5Dg8KMwoIBAADAQQAAgUSAzwGEhoiIFJlcHJlc2VudHMgYW4g
ZXhlY3V0ZSBvcGVyYXRpb24uCgoQCgkEAAMBBAACBQESAzwGDQoQCgkEAAMBBAACBQISAzwQ
EQoqCgYEAAMBAgASA0AEGxobIFRoZSB0eXBlIG9mIHRoZSBvcGVyYXRpb24KCg4KBwQAAwEC
AAYSA0AEEQoOCgcEAAMBAgABEgNAEhYKDgoHBAADAQIAAxIDQBkaCkIKBAQAAgASA0QCEho1
IEFic29sdXRlIHBhdGggb2YgdGhlIGZpbGUgYXMgYSBKU09OIGVuY29kZWQgc3RyaW5nLgoK
DAoFBAACAAUSA0QCCAoMCgUEAAIAARIDRAkNCgwKBQQAAgADEgNEEBEKKQoEBAACARIDRwIR
GhwgU2l6ZSBvZiB0aGUgZmlsZSBpbiBieXRlcy4KCgwKBQQAAgEFEgNHAgcKDAoFBAACAQES
A0cIDAoMCgUEAAIBAxIDRw8QCrABCgQEAAICEgNMAhQaogEgU0hBMjU2IGhhc2ggb2YgdGhl
IGZpcnN0IGhhc2hlZF9zaXplIGJ5dGVzIG9mIHRoZSBmaWxlIGVuY29kZWQgYXMgYQogaGV4
IHN0cmluZy4gIElmIGhhc2hlZF9zaXplID09IHNpemUsIHNoYTI1NiByZXByZXNlbnRzIHRo
ZSBTSEEyNTYgaGFzaAogb2YgdGhlIGVudGlyZSBmaWxlLgoKDAoFBAACAgUSA0wCCAoMCgUE
AAICARIDTAkPCgwKBQQAAgIDEgNMEhMKkQEKBAQAAgMSA1ECGBqDASBUaGUgbGVuZ3RoIGlu
IGJ5dGVzIG9mIHRoZSBmaWxlIHByZWZpeCB0aGF0IHdhcyBoYXNoZWQuICBJZgogaGFzaGVk
X3NpemUgPT0gc2l6ZSwgYW55IGhhc2hlcyByZXBvcnRlZCByZXByZXNlbnQgdGhlIGVudGly
ZQogZmlsZS4KCgwKBQQAAgMFEgNRAgcKDAoFBAACAwESA1EIEwoMCgUEAAIDAxIDURYXCkMK
BAQAAgQSA1QCHBo2IFRydWUgd2hlbiB0aGUgaGFzaCBjb3ZlcnMgb25seSBhIHByZWZpeCBv
ZiB0aGUgZmlsZS4KCgwKBQQAAgQFEgNUAgYKDAoFBAACBAESA1QHFwoMCgUEAAIEAxIDVBob
CkQKBAQAAgUSA1cCFho3IFByZWZpeCBvZiB0aGUgZmlsZSBjb250ZW50cyBhcyBhIEpTT04t
ZW5jb2RlZCBzdHJpbmcuCgoMCgUEAAIFBRIDVwIICgwKBQQAAgUBEgNXCREKDAoFBAACBQMS
A1cUFQpSCgQEAAIGEgNaAhkaRSBQYXRoIG9mIHRoZSBmaWxlIGluIHRlcm1zIG9mIHVuZGVy
bHlpbmcgZGlzay9wYXJ0aXRpb24gaWRlbnRpZmllcnMuCgoMCgUEAAIGBhIDWgIKCgwKBQQA
AgYBEgNaCxQKDAoFBAACBgMSA1oXGAowCgQEAAIHEgNdAigaIyBPcGVyYXRpb24ocykgcGVy
Zm9ybWVkIG9uIGEgZmlsZS4KCgwKBQQAAgcEEgNdAgoKDAoFBAACBwYSA10LGAoMCgUEAAIH
ARIDXRkjCgwKBQQAAgcDEgNdJidiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::File::File ===
    # Fields for File
    # Field: path Type: 9 ()
    # Field: size Type: 3 ()
    # Field: sha256 Type: 9 ()
    # Field: hashed_size Type: 3 ()
    # Field: partially_hashed Type: 8 ()
    # Field: contents Type: 9 ()
    # Field: disk_path Type: 11 (.google.cloud.securitycenter.v2.File.DiskPath)
    # Field: operations Type: 11 (.google.cloud.securitycenter.v2.File.FileOperation)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::File - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/file.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::File;

    my $msg = Google::Cloud::Securitycenter::V2::File::File->new({
        path => $path,
        size => $size,
        sha256 => $sha256,
        hashed_size => $hashed_size,
    });

    # Read or update a field
    my $val = $msg->path();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::File::File->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/file.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::File::File

File information about the related binary/library used by an executable, or
the script used by a script interpreter

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->path() >> / C<< $msg->path($value) >>

Type: C<String>

Absolute path of the file as a JSON encoded string.

=item * C<< $msg->size() >> / C<< $msg->size($value) >>

Type: C<Int64>

Size of the file in bytes.

=item * C<< $msg->sha256() >> / C<< $msg->sha256($value) >>

Type: C<String>

SHA256 hash of the first hashed_size bytes of the file encoded as a
hex string.  If hashed_size == size, sha256 represents the SHA256 hash
of the entire file.

=item * C<< $msg->hashed_size() >> / C<< $msg->hashed_size($value) >>

Type: C<Int64>

The length in bytes of the file prefix that was hashed.  If
hashed_size == size, any hashes reported represent the entire
file.

=item * C<< $msg->partially_hashed() >> / C<< $msg->partially_hashed($value) >>

Type: C<Bool>

True when the hash covers only a prefix of the file.

=item * C<< $msg->contents() >> / C<< $msg->contents($value) >>

Type: C<String>

Prefix of the file contents as a JSON-encoded string.

=item * C<< $msg->disk_path() >> / C<< $msg->disk_path($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::File::File::DiskPath>)

Path of the file in terms of underlying disk/partition identifiers.

=item * C<< $msg->operations() >> / C<< $msg->operations($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::File::File::FileOperation>)

Operation(s) performed on a file.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::File::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
