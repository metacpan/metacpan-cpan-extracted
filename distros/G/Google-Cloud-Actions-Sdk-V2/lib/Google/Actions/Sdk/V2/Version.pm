package Google::Actions::Sdk::V2::Version;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiNnb29nbGUvYWN0aW9ucy9zZGsvdjIvdmVyc2lvbi5wcm90bxIVZ29vZ2xlLmFjdGlvbnMu
c2RrLnYyGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGlt
ZXN0YW1wLnByb3RvItIECgdWZXJzaW9uEhIKBG5hbWUYASABKAlSBG5hbWUSUAoNdmVyc2lv
bl9zdGF0ZRgCIAEoCzIrLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5WZXJzaW9uLlZlcnNpb25T
dGF0ZVIMdmVyc2lvblN0YXRlEhgKB2NyZWF0b3IYAyABKAlSB2NyZWF0b3ISOwoLdXBkYXRl
X3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgp1cGRhdGVUaW1lGr0C
CgxWZXJzaW9uU3RhdGUSRwoFc3RhdGUYASABKA4yMS5nb29nbGUuYWN0aW9ucy5zZGsudjIu
VmVyc2lvbi5WZXJzaW9uU3RhdGUuU3RhdGVSBXN0YXRlEhgKB21lc3NhZ2UYAiABKAlSB21l
c3NhZ2UiyQEKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASGAoUQ1JFQVRJT05fSU5f
UFJPR1JFU1MQARITCg9DUkVBVElPTl9GQUlMRUQQAhILCgdDUkVBVEVEEAMSFgoSUkVWSUVX
X0lOX1BST0dSRVNTEAQSDAoIQVBQUk9WRUQQBRIaChZDT05ESVRJT05BTExZX0FQUFJPVkVE
EAYSCgoGREVOSUVEEAcSEgoOVU5ERVJfVEFLRURPV04QCBILCgdERUxFVEVEEAk6SupBRwoe
YWN0aW9ucy5nb29nbGVhcGlzLmNvbS9WZXJzaW9uEiVwcm9qZWN0cy97cHJvamVjdH0vdmVy
c2lvbnMve3ZlcnNpb259QmUKGWNvbS5nb29nbGUuYWN0aW9ucy5zZGsudjJCDFZlcnNpb25Q
cm90b1ABWjhnb29nbGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2FjdGlvbnMv
c2RrL3YyO3Nka0rhFQoGEgQOAFoBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAeCgkKAgMAEgMSACMKCQoCAwESAxMAKQoICgEIEgMVAE8KCQoCCAsSAxUA
TwoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXAC0KCQoCCAgSAxcALQoICgEIEgMYADIK
CQoCCAESAxgAMgotCgIEABIEGwBaARohIERlZmluaXRpb24gb2YgdmVyc2lvbiByZXNvdXJj
ZS4KCgoKAwQAARIDGwgPCgsKAwQABxIEHAIfBAoNCgUEAAedCBIEHAIfBAo8CgQEAAMAEgQi
AkwDGi4gUmVwcmVzZW50cyB0aGUgY3VycmVudCBzdGF0ZSBvZiB0aGUgdmVyc2lvbi4KCgwK
BQQAAwABEgMiChYKgAEKBgQAAwAEABIEJQRFBRpwIEVudW0gaW5kaWNhdGluZyB0aGUgc3Rh
dGVzIHRoYXQgYSBWZXJzaW9uIGNhbiB0YWtlLiBUaGlzIGVudW0gaXMgbm90IHlldAogZnJv
emVuIGFuZCB2YWx1ZXMgbWF5YmUgYWRkZWQgbGF0ZXIuCgoOCgcEAAMABAABEgMlCQ4KKgoI
BAADAAQAAgASAycGHBoZIERlZmF1bHQgdmFsdWUgb2YgU3RhdGUuCgoQCgkEAAMABAACAAES
AycGFwoQCgkEAAMABAACAAISAycaGwo3CggEAAMABAACARIDKgYfGiYgVGhlIHZlcnNpb24g
Y3JlYXRpb24gaXMgaW4gcHJvZ3Jlc3MuCgoQCgkEAAMABAACAQESAyoGGgoQCgkEAAMABAAC
AQISAyodHgovCggEAAMABAACAhIDLQYaGh4gVGhlIHZlcnNpb24gY3JlYXRpb24gZmFpbGVk
LgoKEAoJBAADAAQAAgIBEgMtBhUKEAoJBAADAAQAAgICEgMtGBkKPQoIBAADAAQAAgMSAzAG
EhosIFRoZSB2ZXJzaW9uIGhhcyBiZWVuIHN1Y2Nlc3NmdWxseSBjcmVhdGVkLgoKEAoJBAAD
AAQAAgMBEgMwBg0KEAoJBAADAAQAAgMCEgMwEBEKRQoIBAADAAQAAgQSAzMGHRo0IFRoZSB2
ZXJzaW9uIGlzIHVuZGVyIHBvbGljeSByZXZpZXcgKGFrYSBBcHByb3ZhbCkuCgoQCgkEAAMA
BAACBAESAzMGGAoQCgkEAAMABAACBAISAzMbHApXCggEAAMABAACBRIDNgYTGkYgVGhlIHZl
cnNpb24gaGFzIGJlZW4gYXBwcm92ZWQgZm9yIHBvbGljeSByZXZpZXcgYW5kIGNhbiBiZSBk
ZXBsb3llZC4KChAKCQQAAwAEAAIFARIDNgYOChAKCQQAAwAEAAIFAhIDNhESCo0BCggEAAMA
BAACBhIDOgYhGnwgVGhlIHZlcnNpb24gaGFzIGJlZW4gY29uZGl0aW9uYWxseSBhcHByb3Zl
ZCBidXQgaXMgcGVuZGluZyBmaW5hbAogcmV2aWV3LiBJdCBtYXkgYmUgcm9sbGVkIGJhY2sg
aWYgZmluYWwgcmV2aWV3IGlzIGRlbmllZC4KChAKCQQAAwAEAAIGARIDOgYcChAKCQQAAwAE
AAIGAhIDOh8gCkEKCAQAAwAEAAIHEgM9BhEaMCBUaGUgdmVyc2lvbiBoYXMgYmVlbiBkZW5p
ZWQgZm9yIHBvbGljeSByZXZpZXcuCgoQCgkEAAMABAACBwESAz0GDAoQCgkEAAMABAACBwIS
Az0PEApeCggEAAMABAACCBIDQQYZGk0gVGhlIHZlcnNpb24gaXMgdGFrZW4gZG93biBhcyBl
bnRpcmUgYWdlbnQgYW5kIGFsbCB2ZXJzaW9ucyBhcmUgdGFrZW4KIGRvd24uCgoQCgkEAAMA
BAACCAESA0EGFAoQCgkEAAMABAACCAISA0EXGAowCggEAAMABAACCRIDRAYSGh8gVGhlIHZl
cnNpb24gaGFzIGJlZW4gZGVsZXRlZC4KChAKCQQAAwAEAAIJARIDRAYNChAKCQQAAwAEAAIJ
AhIDRBARCjIKBgQAAwACABIDSAQUGiMgVGhlIGN1cnJlbnQgc3RhdGUgb2YgdGhlIHZlcnNp
b24uCgoOCgcEAAMAAgAGEgNIBAkKDgoHBAADAAIAARIDSAoPCg4KBwQAAwACAAMSA0gSEwpM
CgYEAAMAAgESA0sEFxo9IFVzZXItZnJpZW5kbHkgbWVzc2FnZSBmb3IgdGhlIGN1cnJlbnQg
c3RhdGUgb2YgdGhlIHZlcnNpb24uCgoOCgcEAAMAAgEFEgNLBAoKDgoHBAADAAIBARIDSwsS
Cg4KBwQAAwACAQMSA0sVFgp2CgQEAAIAEgNQAhIaaSBUaGUgdW5pcXVlIGlkZW50aWZpZXIg
b2YgdGhlIHZlcnNpb24gaW4gdGhlIGZvbGxvd2luZyBmb3JtYXQuCiBgcHJvamVjdHMve3By
b2plY3R9L3ZlcnNpb25zL3t2ZXJzaW9ufWAuCgoMCgUEAAIABRIDUAIICgwKBQQAAgABEgNQ
CQ0KDAoFBAACAAMSA1AQEQowCgQEAAIBEgNTAiEaIyBUaGUgY3VycmVudCBzdGF0ZSBvZiB0
aGUgdmVyc2lvbi4KCgwKBQQAAgEGEgNTAg4KDAoFBAACAQESA1MPHAoMCgUEAAIBAxIDUx8g
CjoKBAQAAgISA1YCFRotIEVtYWlsIG9mIHRoZSB1c2VyIHdobyBjcmVhdGVkIHRoaXMgdmVy
c2lvbi4KCgwKBQQAAgIFEgNWAggKDAoFBAACAgESA1YJEAoMCgUEAAICAxIDVhMUCjwKBAQA
AgMSA1kCLBovIFRpbWVzdGFtcCBvZiB0aGUgbGFzdCBjaGFuZ2UgdG8gdGhpcyB2ZXJzaW9u
LgoKDAoFBAACAwYSA1kCGwoMCgUEAAIDARIDWRwnCgwKBQQAAgMDEgNZKitiBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Version::Version ===
    # Fields for Version
    # Field: name Type: 9 ()
    # Field: version_state Type: 11 (.google.actions.sdk.v2.Version.VersionState)
    # Field: creator Type: 9 ()
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Version - Compiled Protocol Buffers messages for google/actions/sdk/v2/version.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Version;

    my $msg = Google::Actions::Sdk::V2::Version::Version->new({
        name => $name,
        version_state => $version_state,
        creator => $creator,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Version::Version->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/version.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Version::Version

Definition of version resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The unique identifier of the version in the following format.
`projects/{project}/versions/{version}`.

=item * C<< $msg->version_state() >> / C<< $msg->version_state($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Version::Version::VersionState>)

The current state of the version.

=item * C<< $msg->creator() >> / C<< $msg->creator($value) >>

Type: C<String>

Email of the user who created this version.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp of the last change to this version.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Version::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
