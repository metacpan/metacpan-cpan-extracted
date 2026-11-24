package Google::Cloud::Servicedirectory::V1::Namespace;

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
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvc2VydmljZWRpcmVjdG9yeS92MS9uYW1lc3BhY2UucHJvdG8SIGdv
b2dsZS5jbG91ZC5zZXJ2aWNlZGlyZWN0b3J5LnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2
aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvIrwCCglOYW1lc3BhY2USFwoE
bmFtZRgBIAEoCUID4EEFUgRuYW1lElQKBmxhYmVscxgCIAMoCzI3Lmdvb2dsZS5jbG91ZC5z
ZXJ2aWNlZGlyZWN0b3J5LnYxLk5hbWVzcGFjZS5MYWJlbHNFbnRyeUID4EEBUgZsYWJlbHMS
FQoDdWlkGAUgASgJQgPgQQNSA3VpZBo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tl
eRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBOm7qQWsKKXNlcnZpY2VkaXJlY3RvcnkuZ29v
Z2xlYXBpcy5jb20vTmFtZXNwYWNlEj5wcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3ts
b2NhdGlvbn0vbmFtZXNwYWNlcy97bmFtZXNwYWNlfUL2AQokY29tLmdvb2dsZS5jbG91ZC5z
ZXJ2aWNlZGlyZWN0b3J5LnYxQg5OYW1lc3BhY2VQcm90b1ABWlBjbG91ZC5nb29nbGUuY29t
L2dvL3NlcnZpY2VkaXJlY3RvcnkvYXBpdjEvc2VydmljZWRpcmVjdG9yeXBiO3NlcnZpY2Vk
aXJlY3RvcnlwYqoCIEdvb2dsZS5DbG91ZC5TZXJ2aWNlRGlyZWN0b3J5LlYxygIgR29vZ2xl
XENsb3VkXFNlcnZpY2VEaXJlY3RvcnlcVjHqAiNHb29nbGU6OkNsb3VkOjpTZXJ2aWNlRGly
ZWN0b3J5OjpWMUrsDAoGEgQOADIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29v
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
LgoKCAoBAhIDEAApCgkKAgMAEgMSACkKCQoCAwESAxMAIwoICgEIEgMVAD0KCQoCCCUSAxUA
PQoICgEIEgMWAGcKCQoCCAsSAxYAZwoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYAC8K
CQoCCAgSAxgALwoICgEIEgMZAD0KCQoCCAESAxkAPQoICgEIEgMaAD0KCQoCCCkSAxoAPQoI
CgEIEgMbADwKCQoCCC0SAxsAPArGAQoCBAASBCAAMgEauQEgQSBjb250YWluZXIgZm9yIFtz
ZXJ2aWNlc11bZ29vZ2xlLmNsb3VkLnNlcnZpY2VkaXJlY3RvcnkudjEuU2VydmljZV0uCiBO
YW1lc3BhY2VzIGFsbG93IGFkbWluaXN0cmF0b3JzIHRvIGdyb3VwIHNlcnZpY2VzIHRvZ2V0
aGVyIGFuZCBkZWZpbmUKIHBlcm1pc3Npb25zIGZvciBhIGNvbGxlY3Rpb24gb2Ygc2Vydmlj
ZXMuCgoKCgMEAAESAyAIEQoLCgMEAAcSBCECJAQKDQoFBAAHnQgSBCECJAQKcwoEBAACABID
KAI8GmYgSW1tdXRhYmxlLiBUaGUgcmVzb3VyY2UgbmFtZSBmb3IgdGhlIG5hbWVzcGFjZSBp
biB0aGUgZm9ybWF0CiBgcHJvamVjdHMvKi9sb2NhdGlvbnMvKi9uYW1lc3BhY2VzLypgLgoK
DAoFBAACAAUSAygCCAoMCgUEAAIAARIDKAkNCgwKBQQAAgADEgMoEBEKDAoFBAACAAgSAygS
OwoPCggEAAIACJwIABIDKBM6CssBCgQEAAIBEgMtAkoavQEgT3B0aW9uYWwuIFJlc291cmNl
IGxhYmVscyBhc3NvY2lhdGVkIHdpdGggdGhpcyBuYW1lc3BhY2UuCiBObyBtb3JlIHRoYW4g
NjQgdXNlciBsYWJlbHMgY2FuIGJlIGFzc29jaWF0ZWQgd2l0aCBhIGdpdmVuIHJlc291cmNl
LiBMYWJlbAoga2V5cyBhbmQgdmFsdWVzIGNhbiBiZSBubyBsb25nZXIgdGhhbiA2MyBjaGFy
YWN0ZXJzLgoKDAoFBAACAQYSAy0CFQoMCgUEAAIBARIDLRYcCgwKBQQAAgEDEgMtHyAKDAoF
BAACAQgSAy0hSQoPCggEAAIBCJwIABIDLSJICmEKBAQAAgISAzECPRpUIE91dHB1dCBvbmx5
LiBUaGUgZ2xvYmFsbHkgdW5pcXVlIGlkZW50aWZpZXIgb2YgdGhlIG5hbWVzcGFjZSBpbiB0
aGUgVVVJRDQKIGZvcm1hdC4KCgwKBQQAAgIFEgMxAggKDAoFBAACAgESAzEJDAoMCgUEAAIC
AxIDMQ8QCgwKBQQAAgIIEgMxETwKDwoIBAACAgicCAASAzESO2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Servicedirectory::V1::Namespace::Namespace ===
    # Fields for Namespace
    # Field: name Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.servicedirectory.v1.Namespace.LabelsEntry)
    # Field: uid Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Servicedirectory::V1::Namespace - Compiled Protocol Buffers messages for google/cloud/servicedirectory/v1/namespace.proto

=head1 SYNOPSIS

    use Google::Cloud::Servicedirectory::V1::Namespace;

    my $msg = Google::Cloud::Servicedirectory::V1::Namespace::Namespace->new({
        name => $name,
        labels => $labels,
        uid => $uid,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Servicedirectory::V1::Namespace::Namespace->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/servicedirectory/v1/namespace.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Servicedirectory::V1::Namespace::Namespace

A container for [services][google.cloud.servicedirectory.v1.Service].
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

Type: C<Message> (L<Google::Cloud::Servicedirectory::V1::Namespace::Namespace::LabelsEntry>)

Optional. Resource labels associated with this namespace.
No more than 64 user labels can be associated with a given resource. Label
keys and values can be no longer than 63 characters.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. The globally unique identifier of the namespace in the UUID4
format.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Servicedirectory::V1::Namespace::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
