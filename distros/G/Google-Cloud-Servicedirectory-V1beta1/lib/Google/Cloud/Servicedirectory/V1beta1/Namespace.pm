package Google::Cloud::Servicedirectory::V1beta1::Namespace;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvc2VydmljZWRpcmVjdG9yeS92MWJldGExL25hbWVzcGFjZS5wcm90
bxIlZ29vZ2xlLmNsb3VkLnNlcnZpY2VkaXJlY3RvcnkudjFiZXRhMRofZ29vZ2xlL2FwaS9m
aWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xl
L3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLFAwoJTmFtZXNwYWNlEhcKBG5hbWUYASABKAlC
A+BBBVIEbmFtZRJZCgZsYWJlbHMYAiADKAsyPC5nb29nbGUuY2xvdWQuc2VydmljZWRpcmVj
dG9yeS52MWJldGExLk5hbWVzcGFjZS5MYWJlbHNFbnRyeUID4EEBUgZsYWJlbHMSQAoLY3Jl
YXRlX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0
ZVRpbWUSQAoLdXBkYXRlX3RpbWUYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1w
QgPgQQNSCnVwZGF0ZVRpbWUSFQoDdWlkGAYgASgJQgPgQQNSA3VpZBo5CgtMYWJlbHNFbnRy
eRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBOm7qQWsKKXNl
cnZpY2VkaXJlY3RvcnkuZ29vZ2xlYXBpcy5jb20vTmFtZXNwYWNlEj5wcm9qZWN0cy97cHJv
amVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vbmFtZXNwYWNlcy97bmFtZXNwYWNlfUKPAgop
Y29tLmdvb2dsZS5jbG91ZC5zZXJ2aWNlZGlyZWN0b3J5LnYxYmV0YTFCDk5hbWVzcGFjZVBy
b3RvUAFaVWNsb3VkLmdvb2dsZS5jb20vZ28vc2VydmljZWRpcmVjdG9yeS9hcGl2MWJldGEx
L3NlcnZpY2VkaXJlY3RvcnlwYjtzZXJ2aWNlZGlyZWN0b3J5cGKqAiVHb29nbGUuQ2xvdWQu
U2VydmljZURpcmVjdG9yeS5WMUJldGExygIlR29vZ2xlXENsb3VkXFNlcnZpY2VEaXJlY3Rv
cnlcVjFiZXRhMeoCKEdvb2dsZTo6Q2xvdWQ6OlNlcnZpY2VEaXJlY3Rvcnk6OlYxYmV0YTFK
qQ8KBhIEDgA7AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
LgoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAKQoICgEIEgMWAEIKCQoCCCUSAxYA
QgoICgEIEgMXAGwKCQoCCAsSAxcAbAoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZAC8K
CQoCCAgSAxkALwoICgEIEgMaAEIKCQoCCAESAxoAQgoICgEIEgMbAEIKCQoCCCkSAxsAQgoI
CgEIEgMcAEEKCQoCCC0SAxwAQQrLAQoCBAASBCEAOwEavgEgQSBjb250YWluZXIgZm9yIFtz
ZXJ2aWNlc11bZ29vZ2xlLmNsb3VkLnNlcnZpY2VkaXJlY3RvcnkudjFiZXRhMS5TZXJ2aWNl
XS4KIE5hbWVzcGFjZXMgYWxsb3cgYWRtaW5pc3RyYXRvcnMgdG8gZ3JvdXAgc2VydmljZXMg
dG9nZXRoZXIgYW5kIGRlZmluZQogcGVybWlzc2lvbnMgZm9yIGEgY29sbGVjdGlvbiBvZiBz
ZXJ2aWNlcy4KCgoKAwQAARIDIQgRCgsKAwQABxIEIgIlBAoNCgUEAAedCBIEIgIlBApzCgQE
AAIAEgMpAjwaZiBJbW11dGFibGUuIFRoZSByZXNvdXJjZSBuYW1lIGZvciB0aGUgbmFtZXNw
YWNlIGluIHRoZSBmb3JtYXQKIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy8qL25hbWVzcGFjZXMv
KmAuCgoMCgUEAAIABRIDKQIICgwKBQQAAgABEgMpCQ0KDAoFBAACAAMSAykQEQoMCgUEAAIA
CBIDKRI7Cg8KCAQAAgAInAgAEgMpEzoKywEKBAQAAgESAy4CShq9ASBPcHRpb25hbC4gUmVz
b3VyY2UgbGFiZWxzIGFzc29jaWF0ZWQgd2l0aCB0aGlzIG5hbWVzcGFjZS4KIE5vIG1vcmUg
dGhhbiA2NCB1c2VyIGxhYmVscyBjYW4gYmUgYXNzb2NpYXRlZCB3aXRoIGEgZ2l2ZW4gcmVz
b3VyY2UuIExhYmVsCiBrZXlzIGFuZCB2YWx1ZXMgY2FuIGJlIG5vIGxvbmdlciB0aGFuIDYz
IGNoYXJhY3RlcnMuCgoMCgUEAAIBBhIDLgIVCgwKBQQAAgEBEgMuFhwKDAoFBAACAQMSAy4f
IAoMCgUEAAIBCBIDLiFJCg8KCAQAAgEInAgAEgMuIkgKSgoEBAACAhIEMQIyMho8IE91dHB1
dCBvbmx5LiBUaGUgdGltZXN0YW1wIHdoZW4gdGhlIG5hbWVzcGFjZSB3YXMgY3JlYXRlZC4K
CgwKBQQAAgIGEgMxAhsKDAoFBAACAgESAzEcJwoMCgUEAAICAxIDMSorCgwKBQQAAgIIEgMy
BjEKDwoIBAACAgicCAASAzIHMApPCgQEAAIDEgQ1AjYyGkEgT3V0cHV0IG9ubHkuIFRoZSB0
aW1lc3RhbXAgd2hlbiB0aGUgbmFtZXNwYWNlIHdhcyBsYXN0IHVwZGF0ZWQuCgoMCgUEAAID
BhIDNQIbCgwKBQQAAgMBEgM1HCcKDAoFBAACAwMSAzUqKwoMCgUEAAIDCBIDNgYxCg8KCAQA
AgMInAgAEgM2BzAKXwoEBAACBBIDOgI9GlIgT3V0cHV0IG9ubHkuIEEgZ2xvYmFsbHkgdW5p
cXVlIGlkZW50aWZpZXIgKGluIFVVSUQ0IGZvcm1hdCkgZm9yIHRoaXMKIG5hbWVzcGFjZS4K
CgwKBQQAAgQFEgM6AggKDAoFBAACBAESAzoJDAoMCgUEAAIEAxIDOg8QCgwKBQQAAgQIEgM6
ETwKDwoIBAACBAicCAASAzoSO2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Servicedirectory::V1beta1::Namespace::Namespace ===
    # Fields for Namespace
    # Field: name Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.servicedirectory.v1beta1.Namespace.LabelsEntry)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: uid Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Servicedirectory::V1beta1::Namespace - Compiled Protocol Buffers messages for google/cloud/servicedirectory/v1beta1/namespace.proto

=head1 SYNOPSIS

    use Google::Cloud::Servicedirectory::V1beta1::Namespace;

    my $msg = Google::Cloud::Servicedirectory::V1beta1::Namespace::Namespace->new({
        name => $name,
        labels => $labels,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Servicedirectory::V1beta1::Namespace::Namespace->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/servicedirectory/v1beta1/namespace.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Servicedirectory::V1beta1::Namespace::Namespace

A container for [services][google.cloud.servicedirectory.v1beta1.Service].
Namespaces allow administrators to group services together and define
permissions for a collection of services.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. The resource name for the namespace in the format
`projects/*/locations/*/namespaces/*`.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Servicedirectory::V1beta1::Namespace::Namespace::LabelsEntry>)

Optional. Resource labels associated with this namespace.
No more than 64 user labels can be associated with a given resource. Label
keys and values can be no longer than 63 characters.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the namespace was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when the namespace was last updated.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. A globally unique identifier (in UUID4 format) for this
namespace.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Servicedirectory::V1beta1::Namespace::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
