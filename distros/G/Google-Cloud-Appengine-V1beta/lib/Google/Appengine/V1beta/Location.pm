package Google::Appengine::V1beta::Location;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvYXBwZW5naW5lL3YxYmV0YS9sb2NhdGlvbi5wcm90bxIXZ29vZ2xlLmFwcGVu
Z2luZS52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8i1QEKEExvY2F0
aW9uTWV0YWRhdGESRAoec3RhbmRhcmRfZW52aXJvbm1lbnRfYXZhaWxhYmxlGAIgASgIUhxz
dGFuZGFyZEVudmlyb25tZW50QXZhaWxhYmxlEkQKHmZsZXhpYmxlX2Vudmlyb25tZW50X2F2
YWlsYWJsZRgEIAEoCFIcZmxleGlibGVFbnZpcm9ubWVudEF2YWlsYWJsZRI1ChRzZWFyY2hf
YXBpX2F2YWlsYWJsZRgGIAEoCEID4EEDUhJzZWFyY2hBcGlBdmFpbGFibGVC0wEKG2NvbS5n
b29nbGUuYXBwZW5naW5lLnYxYmV0YUINTG9jYXRpb25Qcm90b1ABWkBnb29nbGUuZ29sYW5n
Lm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2FwcGVuZ2luZS92MWJldGE7YXBwZW5naW5lqgId
R29vZ2xlLkNsb3VkLkFwcEVuZ2luZS5WMUJldGHKAh1Hb29nbGVcQ2xvdWRcQXBwRW5naW5l
XFYxYmV0YeoCIEdvb2dsZTo6Q2xvdWQ6OkFwcEVuZ2luZTo6VjFiZXRhStUKCgYSBA4AKwEK
vAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5k
ZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5
b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhl
IExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAg
ICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNz
IHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBz
b2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQg
b24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05T
IE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNl
bnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFu
ZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACAKCQoCAwASAxIA
KQoICgEIEgMUADoKCQoCCCUSAxQAOgoICgEIEgMVAFcKCQoCCAsSAxUAVwoICgEIEgMWACIK
CQoCCAoSAxYAIgoICgEIEgMXAC4KCQoCCAgSAxcALgoICgEIEgMYADQKCQoCCAESAxgANAoI
CgEIEgMZADoKCQoCCCkSAxkAOgoICgEIEgMaADkKCQoCCC0SAxoAOQpmCgIEABIEHQArARpa
IE1ldGFkYXRhIGZvciB0aGUgZ2l2ZW4gW2dvb2dsZS5jbG91ZC5sb2NhdGlvbi5Mb2NhdGlv
bl1bZ29vZ2xlLmNsb3VkLmxvY2F0aW9uLkxvY2F0aW9uXS4KCgoKAwQAARIDHQgYCmAKBAQA
AgASAyECKhpTIEFwcCBFbmdpbmUgc3RhbmRhcmQgZW52aXJvbm1lbnQgaXMgYXZhaWxhYmxl
IGluIHRoZSBnaXZlbiBsb2NhdGlvbi4KCiBAT3V0cHV0T25seQoKDAoFBAACAAUSAyECBgoM
CgUEAAIAARIDIQclCgwKBQQAAgADEgMhKCkKYAoEBAACARIDJgIqGlMgQXBwIEVuZ2luZSBm
bGV4aWJsZSBlbnZpcm9ubWVudCBpcyBhdmFpbGFibGUgaW4gdGhlIGdpdmVuIGxvY2F0aW9u
LgoKIEBPdXRwdXRPbmx5CgoMCgUEAAIBBRIDJgIGCgwKBQQAAgEBEgMmByUKDAoFBAACAQMS
AyYoKQqOAQoEBAACAhIDKgJMGoABIE91dHB1dCBvbmx5LiBbU2VhcmNoIEFQSV0oaHR0cHM6
Ly9jbG91ZC5nb29nbGUuY29tL2FwcGVuZ2luZS9kb2NzL3N0YW5kYXJkL3B5dGhvbi9zZWFy
Y2gpCiBpcyBhdmFpbGFibGUgaW4gdGhlIGdpdmVuIGxvY2F0aW9uLgoKDAoFBAACAgUSAyoC
BgoMCgUEAAICARIDKgcbCgwKBQQAAgIDEgMqHh8KDAoFBAACAggSAyogSwoPCggEAAICCJwI
ABIDKiFKYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1beta::Location::LocationMetadata ===
    # Fields for LocationMetadata
    # Field: standard_environment_available Type: 8 ()
    # Field: flexible_environment_available Type: 8 ()
    # Field: search_api_available Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1beta::Location - Compiled Protocol Buffers messages for google/appengine/v1beta/location.proto

=head1 SYNOPSIS

    use Google::Appengine::V1beta::Location;

    my $msg = Google::Appengine::V1beta::Location::LocationMetadata->new({
        standard_environment_available => $standard_environment_available,
        flexible_environment_available => $flexible_environment_available,
        search_api_available => $search_api_available,
    });

    # Read or update a field
    my $val = $msg->standard_environment_available();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1beta::Location::LocationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1beta/location.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1beta::Location::LocationMetadata

Metadata for the given [google.cloud.location.Location][google.cloud.location.Location].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->standard_environment_available() >> / C<< $msg->standard_environment_available($value) >>

Type: C<Bool>

App Engine standard environment is available in the given location.

@OutputOnly

=item * C<< $msg->flexible_environment_available() >> / C<< $msg->flexible_environment_available($value) >>

Type: C<Bool>

App Engine flexible environment is available in the given location.

@OutputOnly

=item * C<< $msg->search_api_available() >> / C<< $msg->search_api_available($value) >>

Type: C<Bool>

Output only. [Search API](https://cloud.google.com/appengine/docs/standard/python/search)
is available in the given location.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1beta::Location::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
