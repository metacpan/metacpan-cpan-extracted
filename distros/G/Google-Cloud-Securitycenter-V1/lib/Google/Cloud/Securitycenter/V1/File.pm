package Google::Cloud::Securitycenter::V1::File;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvZmlsZS5wcm90bxIeZ29vZ2xlLmNs
b3VkLnNlY3VyaXR5Y2VudGVyLnYxItICCgRGaWxlEhIKBHBhdGgYASABKAlSBHBhdGgSEgoE
c2l6ZRgCIAEoA1IEc2l6ZRIWCgZzaGEyNTYYAyABKAlSBnNoYTI1NhIfCgtoYXNoZWRfc2l6
ZRgEIAEoA1IKaGFzaGVkU2l6ZRIpChBwYXJ0aWFsbHlfaGFzaGVkGAUgASgIUg9wYXJ0aWFs
bHlIYXNoZWQSGgoIY29udGVudHMYBiABKAlSCGNvbnRlbnRzEkoKCWRpc2tfcGF0aBgHIAEo
CzItLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MS5GaWxlLkRpc2tQYXRoUghkaXNr
UGF0aBpWCghEaXNrUGF0aBIlCg5wYXJ0aXRpb25fdXVpZBgBIAEoCVINcGFydGl0aW9uVXVp
ZBIjCg1yZWxhdGl2ZV9wYXRoGAIgASgJUgxyZWxhdGl2ZVBhdGhC4wEKImNvbS5nb29nbGUu
Y2xvdWQuc2VjdXJpdHljZW50ZXIudjFCCUZpbGVQcm90b1ABWkpjbG91ZC5nb29nbGUuY29t
L2dvL3NlY3VyaXR5Y2VudGVyL2FwaXYxL3NlY3VyaXR5Y2VudGVycGI7c2VjdXJpdHljZW50
ZXJwYqoCHkdvb2dsZS5DbG91ZC5TZWN1cml0eUNlbnRlci5WMcoCHkdvb2dsZVxDbG91ZFxT
ZWN1cml0eUNlbnRlclxWMeoCIUdvb2dsZTo6Q2xvdWQ6OlNlY3VyaXR5Q2VudGVyOjpWMUrt
EQoGEgQOAEABCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAn
CggKAQgSAxIAOwoJCgIIJRIDEgA7CggKAQgSAxMAYQoJCgIICxIDEwBhCggKAQgSAxQAIgoJ
CgIIChIDFAAiCggKAQgSAxUAKgoJCgIICBIDFQAqCggKAQgSAxYAOwoJCgIIARIDFgA7CggK
AQgSAxcAOwoJCgIIKRIDFwA7CggKAQgSAxgAOgoJCgIILRIDGAA6CoIBCgIEABIEHABAARp2
IEZpbGUgaW5mb3JtYXRpb24gYWJvdXQgdGhlIHJlbGF0ZWQgYmluYXJ5L2xpYnJhcnkgdXNl
ZCBieSBhbiBleGVjdXRhYmxlLCBvcgogdGhlIHNjcmlwdCB1c2VkIGJ5IGEgc2NyaXB0IGlu
dGVycHJldGVyCgoKCgMEAAESAxwIDApTCgQEAAMAEgQeAiYDGkUgUGF0aCBvZiB0aGUgZmls
ZSBpbiB0ZXJtcyBvZiB1bmRlcmx5aW5nIGRpc2svcGFydGl0aW9uIGlkZW50aWZpZXJzLgoK
DAoFBAADAAESAx4KEgp4CgYEAAMAAgASAyEEHhppIFVVSUQgb2YgdGhlIHBhcnRpdGlvbiAo
Zm9ybWF0CiBodHRwczovL3dpa2kuYXJjaGxpbnV4Lm9yZy90aXRsZS9wZXJzaXN0ZW50X2Js
b2NrX2RldmljZV9uYW1pbmcjYnktdXVpZCkKCg4KBwQAAwACAAUSAyEECgoOCgcEAAMAAgAB
EgMhCxkKDgoHBAADAAIAAxIDIRwdCn4KBgQAAwACARIDJQQdGm8gUmVsYXRpdmUgcGF0aCBv
ZiB0aGUgZmlsZSBpbiB0aGUgcGFydGl0aW9uIGFzIGEgSlNPTiBlbmNvZGVkIHN0cmluZy4K
IEV4YW1wbGU6IC9ob21lL3VzZXIxL2V4ZWN1dGFibGVfZmlsZS5zaAoKDgoHBAADAAIBBRID
JQQKCg4KBwQAAwACAQESAyULGAoOCgcEAAMAAgEDEgMlGxwKQgoEBAACABIDKQISGjUgQWJz
b2x1dGUgcGF0aCBvZiB0aGUgZmlsZSBhcyBhIEpTT04gZW5jb2RlZCBzdHJpbmcuCgoMCgUE
AAIABRIDKQIICgwKBQQAAgABEgMpCQ0KDAoFBAACAAMSAykQEQopCgQEAAIBEgMsAhEaHCBT
aXplIG9mIHRoZSBmaWxlIGluIGJ5dGVzLgoKDAoFBAACAQUSAywCBwoMCgUEAAIBARIDLAgM
CgwKBQQAAgEDEgMsDxAKsAEKBAQAAgISAzECFBqiASBTSEEyNTYgaGFzaCBvZiB0aGUgZmly
c3QgaGFzaGVkX3NpemUgYnl0ZXMgb2YgdGhlIGZpbGUgZW5jb2RlZCBhcyBhCiBoZXggc3Ry
aW5nLiAgSWYgaGFzaGVkX3NpemUgPT0gc2l6ZSwgc2hhMjU2IHJlcHJlc2VudHMgdGhlIFNI
QTI1NiBoYXNoCiBvZiB0aGUgZW50aXJlIGZpbGUuCgoMCgUEAAICBRIDMQIICgwKBQQAAgIB
EgMxCQ8KDAoFBAACAgMSAzESEwqRAQoEBAACAxIDNgIYGoMBIFRoZSBsZW5ndGggaW4gYnl0
ZXMgb2YgdGhlIGZpbGUgcHJlZml4IHRoYXQgd2FzIGhhc2hlZC4gIElmCiBoYXNoZWRfc2l6
ZSA9PSBzaXplLCBhbnkgaGFzaGVzIHJlcG9ydGVkIHJlcHJlc2VudCB0aGUgZW50aXJlCiBm
aWxlLgoKDAoFBAACAwUSAzYCBwoMCgUEAAIDARIDNggTCgwKBQQAAgMDEgM2FhcKQwoEBAAC
BBIDOQIcGjYgVHJ1ZSB3aGVuIHRoZSBoYXNoIGNvdmVycyBvbmx5IGEgcHJlZml4IG9mIHRo
ZSBmaWxlLgoKDAoFBAACBAUSAzkCBgoMCgUEAAIEARIDOQcXCgwKBQQAAgQDEgM5GhsKRAoE
BAACBRIDPAIWGjcgUHJlZml4IG9mIHRoZSBmaWxlIGNvbnRlbnRzIGFzIGEgSlNPTi1lbmNv
ZGVkIHN0cmluZy4KCgwKBQQAAgUFEgM8AggKDAoFBAACBQESAzwJEQoMCgUEAAIFAxIDPBQV
ClIKBAQAAgYSAz8CGRpFIFBhdGggb2YgdGhlIGZpbGUgaW4gdGVybXMgb2YgdW5kZXJseWlu
ZyBkaXNrL3BhcnRpdGlvbiBpZGVudGlmaWVycy4KCgwKBQQAAgYGEgM/AgoKDAoFBAACBgES
Az8LFAoMCgUEAAIGAxIDPxcYYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::File::File ===
    # Fields for File
    # Field: path Type: 9 ()
    # Field: size Type: 3 ()
    # Field: sha256 Type: 9 ()
    # Field: hashed_size Type: 3 ()
    # Field: partially_hashed Type: 8 ()
    # Field: contents Type: 9 ()
    # Field: disk_path Type: 11 (.google.cloud.securitycenter.v1.File.DiskPath)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::File - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/file.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::File;

    my $msg = Google::Cloud::Securitycenter::V1::File::File->new({
        path => $path,
        size => $size,
        sha256 => $sha256,
        hashed_size => $hashed_size,
    });

    # Read or update a field
    my $val = $msg->path();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::File::File->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/file.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::File::File

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

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::File::File::DiskPath>)

Path of the file in terms of underlying disk/partition identifiers.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::File::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
