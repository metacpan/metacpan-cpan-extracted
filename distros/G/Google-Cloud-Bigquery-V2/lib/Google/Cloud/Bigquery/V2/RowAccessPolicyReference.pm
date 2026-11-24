package Google::Cloud::Bigquery::V2::RowAccessPolicyReference;

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
Cjpnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvcm93X2FjY2Vzc19wb2xpY3lfcmVmZXJlbmNl
LnByb3RvEhhnb29nbGUuY2xvdWQuYmlncXVlcnkudjIaH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8ipAEKGFJvd0FjY2Vzc1BvbGljeVJlZmVyZW5jZRIiCgpwcm9qZWN0X2lk
GAEgASgJQgPgQQJSCXByb2plY3RJZBIiCgpkYXRhc2V0X2lkGAIgASgJQgPgQQJSCWRhdGFz
ZXRJZBIeCgh0YWJsZV9pZBgDIAEoCUID4EECUgd0YWJsZUlkEiAKCXBvbGljeV9pZBgEIAEo
CUID4EECUghwb2xpY3lJZEJ8Chxjb20uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyQh1Sb3dB
Y2Nlc3NQb2xpY3lSZWZlcmVuY2VQcm90b1ABWjtjbG91ZC5nb29nbGUuY29tL2dvL2JpZ3F1
ZXJ5L3YyL2FwaXYyL2JpZ3F1ZXJ5cGI7YmlncXVlcnlwYkq7CwoGEgQOACgBCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAhCgkKAgMAEgMSACkKCAoBCBID
FABSCgkKAggLEgMUAFIKCAoBCBIDFQAiCgkKAggKEgMVACIKCAoBCBIDFgA+CgkKAggIEgMW
AD4KCAoBCBIDFwA1CgkKAggBEgMXADUKLQoCBAASBBoAKAEaISBJZCBwYXRoIG9mIGEgcm93
IGFjY2VzcyBwb2xpY3kuCgoKCgMEAAESAxoIIApRCgQEAAIAEgMcAkEaRCBSZXF1aXJlZC4g
VGhlIElEIG9mIHRoZSBwcm9qZWN0IGNvbnRhaW5pbmcgdGhpcyByb3cgYWNjZXNzIHBvbGlj
eS4KCgwKBQQAAgAFEgMcAggKDAoFBAACAAESAxwJEwoMCgUEAAIAAxIDHBYXCgwKBQQAAgAI
EgMcGEAKDwoIBAACAAicCAASAxwZPwpRCgQEAAIBEgMfAkEaRCBSZXF1aXJlZC4gVGhlIElE
IG9mIHRoZSBkYXRhc2V0IGNvbnRhaW5pbmcgdGhpcyByb3cgYWNjZXNzIHBvbGljeS4KCgwK
BQQAAgEFEgMfAggKDAoFBAACAQESAx8JEwoMCgUEAAIBAxIDHxYXCgwKBQQAAgEIEgMfGEAK
DwoIBAACAQicCAASAx8ZPwpPCgQEAAICEgMiAj8aQiBSZXF1aXJlZC4gVGhlIElEIG9mIHRo
ZSB0YWJsZSBjb250YWluaW5nIHRoaXMgcm93IGFjY2VzcyBwb2xpY3kuCgoMCgUEAAICBRID
IgIICgwKBQQAAgIBEgMiCREKDAoFBAACAgMSAyIUFQoMCgUEAAICCBIDIhY+Cg8KCAQAAgII
nAgAEgMiFz0KsgEKBAQAAgMSAycCQBqkASBSZXF1aXJlZC4gVGhlIElEIG9mIHRoZSByb3cg
YWNjZXNzIHBvbGljeS4gVGhlIElEIG11c3QgY29udGFpbiBvbmx5CiBsZXR0ZXJzIChhLXos
IEEtWiksIG51bWJlcnMgKDAtOSksIG9yIHVuZGVyc2NvcmVzIChfKS4gVGhlIG1heGltdW0K
IGxlbmd0aCBpcyAyNTYgY2hhcmFjdGVycy4KCgwKBQQAAgMFEgMnAggKDAoFBAACAwESAycJ
EgoMCgUEAAIDAxIDJxUWCgwKBQQAAgMIEgMnFz8KDwoIBAACAwicCAASAycYPmIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::RowAccessPolicyReference::RowAccessPolicyReference ===
    # Fields for RowAccessPolicyReference
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: table_id Type: 9 ()
    # Field: policy_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::V2::RowAccessPolicyReference - Compiled Protocol Buffers messages for google/cloud/bigquery/v2/row_access_policy_reference.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::RowAccessPolicyReference;

    my $msg = Google::Cloud::Bigquery::V2::RowAccessPolicyReference::RowAccessPolicyReference->new({
        project_id => $project_id,
        dataset_id => $dataset_id,
        table_id => $table_id,
        policy_id => $policy_id,
    });

    # Read or update a field
    my $val = $msg->project_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::V2::RowAccessPolicyReference::RowAccessPolicyReference->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/v2/row_access_policy_reference.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::V2::RowAccessPolicyReference::RowAccessPolicyReference

Id path of a row access policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. The ID of the project containing this row access policy.

=item * C<< $msg->dataset_id() >> / C<< $msg->dataset_id($value) >>

Type: C<String>

Required. The ID of the dataset containing this row access policy.

=item * C<< $msg->table_id() >> / C<< $msg->table_id($value) >>

Type: C<String>

Required. The ID of the table containing this row access policy.

=item * C<< $msg->policy_id() >> / C<< $msg->policy_id($value) >>

Type: C<String>

Required. The ID of the row access policy. The ID must contain only
letters (a-z, A-Z), numbers (0-9), or underscores (_). The maximum
length is 256 characters.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::V2::RowAccessPolicyReference::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
