package Google::Cloud::Oracledatabase::V1::DbSystemShape;

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
CjRnb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvZGJfc3lzdGVtX3NoYXBlLnByb3Rv
Eh5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8iwgcKDURiU3lzdGVtU2hh
cGUSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEhkKBXNoYXBlGAIgASgJQgPgQQFSBXNoYXBl
EikKDm1pbl9ub2RlX2NvdW50GAMgASgFQgPgQQFSDG1pbk5vZGVDb3VudBIpCg5tYXhfbm9k
ZV9jb3VudBgEIAEoBUID4EEBUgxtYXhOb2RlQ291bnQSLwoRbWluX3N0b3JhZ2VfY291bnQY
BSABKAVCA+BBAVIPbWluU3RvcmFnZUNvdW50Ei8KEW1heF9zdG9yYWdlX2NvdW50GAYgASgF
QgPgQQFSD21heFN0b3JhZ2VDb3VudBJFCh1hdmFpbGFibGVfY29yZV9jb3VudF9wZXJfbm9k
ZRgHIAEoBUID4EEBUhlhdmFpbGFibGVDb3JlQ291bnRQZXJOb2RlEkMKHGF2YWlsYWJsZV9t
ZW1vcnlfcGVyX25vZGVfZ2IYCCABKAVCA+BBAVIYYXZhaWxhYmxlTWVtb3J5UGVyTm9kZUdi
Ej4KGWF2YWlsYWJsZV9kYXRhX3N0b3JhZ2VfdGIYCSABKAVCA+BBAVIWYXZhaWxhYmxlRGF0
YVN0b3JhZ2VUYhI5ChdtaW5fY29yZV9jb3VudF9wZXJfbm9kZRgKIAEoBUID4EEBUhNtaW5D
b3JlQ291bnRQZXJOb2RlEjcKFm1pbl9tZW1vcnlfcGVyX25vZGVfZ2IYCyABKAVCA+BBAVIS
bWluTWVtb3J5UGVyTm9kZUdiEkcKH21pbl9kYl9ub2RlX3N0b3JhZ2VfcGVyX25vZGVfZ2IY
DCABKAVCA+BBAVIZbWluRGJOb2RlU3RvcmFnZVBlck5vZGVHYhIxChJtaW5pbXVtX2NvcmVf
Y291bnQYDSABKAVCA+BBAVIQbWluaW11bUNvcmVDb3VudBI1ChRhdmFpbGFibGVfY29yZV9j
b3VudBgOIAEoBUID4EEBUhJhdmFpbGFibGVDb3JlQ291bnQSNQoUY29yZV9jb3VudF9pbmNy
ZW1lbnQYDyABKAVCA+BBAVISY29yZUNvdW50SW5jcmVtZW50OpoB6kGWAQorb3JhY2xlZGF0
YWJhc2UuZ29vZ2xlYXBpcy5jb20vRGJTeXN0ZW1TaGFwZRJIcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L2RiU3lzdGVtU2hhcGVzL3tkYl9zeXN0ZW1fc2hhcGV9
Kg5kYlN5c3RlbVNoYXBlczINZGJTeXN0ZW1TaGFwZULsAQoiY29tLmdvb2dsZS5jbG91ZC5v
cmFjbGVkYXRhYmFzZS52MUISRGJTeXN0ZW1TaGFwZVByb3RvUAFaSmNsb3VkLmdvb2dsZS5j
b20vZ28vb3JhY2xlZGF0YWJhc2UvYXBpdjEvb3JhY2xlZGF0YWJhc2VwYjtvcmFjbGVkYXRh
YmFzZXBiqgIeR29vZ2xlLkNsb3VkLk9yYWNsZURhdGFiYXNlLlYxygIeR29vZ2xlXENsb3Vk
XE9yYWNsZURhdGFiYXNlXFYx6gIhR29vZ2xlOjpDbG91ZDo6T3JhY2xlRGF0YWJhc2U6OlYx
StwXCgYSBA4AVwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQ
ACcKCQoCAwASAxIAKQoJCgIDARIDEwAjCggKAQgSAxUAOwoJCgIIJRIDFQA7CggKAQgSAxYA
YQoJCgIICxIDFgBhCggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgAMwoJCgIICBIDGAAz
CggKAQgSAxkAOwoJCgIIARIDGQA7CggKAQgSAxoAOwoJCgIIKRIDGgA7CggKAQgSAxsAOgoJ
CgIILRIDGwA6CpMBCgIEABIEHwBXARqGASBEZXRhaWxzIG9mIHRoZSBEYXRhYmFzZSBTeXN0
ZW0gU2hhcGVzIHJlc291cmNlLgogaHR0cHM6Ly9kb2NzLm9yYWNsZS5jb20vZW4tdXMvaWFh
cy9hcGkvIy9lbi9kYXRhYmFzZS8yMDE2MDkxOC9EYlN5c3RlbVNoYXBlU3VtbWFyeS8KCgoK
AwQAARIDHwgVCgsKAwQABxIEIAIlBAoNCgUEAAedCBIEIAIlBAqjAQoEBAACABIDKQI9GpUB
IElkZW50aWZpZXIuIFRoZSBuYW1lIG9mIHRoZSBEYXRhYmFzZSBTeXN0ZW0gU2hhcGUgcmVz
b3VyY2Ugd2l0aCB0aGUgZm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97
cmVnaW9ufS9kYlN5c3RlbVNoYXBlcy97ZGJfc3lzdGVtX3NoYXBlfQoKDAoFBAACAAUSAykC
CAoMCgUEAAIAARIDKQkNCgwKBQQAAgADEgMpEBEKDAoFBAACAAgSAykSPAoPCggEAAIACJwI
ABIDKRM7Ch4KBAQAAgESAywCPBoRIE9wdGlvbmFsLiBzaGFwZQoKDAoFBAACAQUSAywCCAoM
CgUEAAIBARIDLAkOCgwKBQQAAgEDEgMsERIKDAoFBAACAQgSAywTOwoPCggEAAIBCJwIABID
LBQ6CjwKBAQAAgISAy8CRBovIE9wdGlvbmFsLiBNaW5pbXVtIG51bWJlciBvZiBkYXRhYmFz
ZSBzZXJ2ZXJzLgoKDAoFBAACAgUSAy8CBwoMCgUEAAICARIDLwgWCgwKBQQAAgIDEgMvGRoK
DAoFBAACAggSAy8bQwoPCggEAAICCJwIABIDLxxCCjwKBAQAAgMSAzICRBovIE9wdGlvbmFs
LiBNYXhpbXVtIG51bWJlciBvZiBkYXRhYmFzZSBzZXJ2ZXJzLgoKDAoFBAACAwUSAzICBwoM
CgUEAAIDARIDMggWCgwKBQQAAgMDEgMyGRoKDAoFBAACAwgSAzIbQwoPCggEAAIDCJwIABID
MhxCCjsKBAQAAgQSAzUCRxouIE9wdGlvbmFsLiBNaW5pbXVtIG51bWJlciBvZiBzdG9yYWdl
IHNlcnZlcnMuCgoMCgUEAAIEBRIDNQIHCgwKBQQAAgQBEgM1CBkKDAoFBAACBAMSAzUcHQoM
CgUEAAIECBIDNR5GCg8KCAQAAgQInAgAEgM1H0UKOwoEBAACBRIDOAJHGi4gT3B0aW9uYWwu
IE1heGltdW0gbnVtYmVyIG9mIHN0b3JhZ2Ugc2VydmVycy4KCgwKBQQAAgUFEgM4AgcKDAoF
BAACBQESAzgIGQoMCgUEAAIFAxIDOBwdCgwKBQQAAgUIEgM4HkYKDwoIBAACBQicCAASAzgf
RQozCgQEAAIGEgQ7AjwvGiUgT3B0aW9uYWwuIE51bWJlciBvZiBjb3JlcyBwZXIgbm9kZS4K
CgwKBQQAAgYFEgM7AgcKDAoFBAACBgESAzsIJQoMCgUEAAIGAxIDOygpCgwKBQQAAgYIEgM8
Bi4KDwoIBAACBgicCAASAzwHLQpHCgQEAAIHEgQ/AkAvGjkgT3B0aW9uYWwuIE1lbW9yeSBw
ZXIgZGF0YWJhc2Ugc2VydmVyIG5vZGUgaW4gZ2lnYWJ5dGVzLgoKDAoFBAACBwUSAz8CBwoM
CgUEAAIHARIDPwgkCgwKBQQAAgcDEgM/JygKDAoFBAACBwgSA0AGLgoPCggEAAIHCJwIABID
QActCkEKBAQAAggSA0MCTxo0IE9wdGlvbmFsLiBTdG9yYWdlIHBlciBzdG9yYWdlIHNlcnZl
ciBpbiB0ZXJhYnl0ZXMuCgoMCgUEAAIIBRIDQwIHCgwKBQQAAggBEgNDCCEKDAoFBAACCAMS
A0MkJQoMCgUEAAIICBIDQyZOCg8KCAQAAggInAgAEgNDJ00KNQoEBAACCRIDRgJOGiggT3B0
aW9uYWwuIE1pbmltdW0gY29yZSBjb3VudCBwZXIgbm9kZS4KCgwKBQQAAgkFEgNGAgcKDAoF
BAACCQESA0YIHwoMCgUEAAIJAxIDRiIkCgwKBQQAAgkIEgNGJU0KDwoIBAACCQicCAASA0Ym
TAo+CgQEAAIKEgNJAk0aMSBPcHRpb25hbC4gTWluaW11bSBtZW1vcnkgcGVyIG5vZGUgaW4g
Z2lnYWJ5dGVzLgoKDAoFBAACCgUSA0kCBwoMCgUEAAIKARIDSQgeCgwKBQQAAgoDEgNJISMK
DAoFBAACCggSA0kkTAoPCggEAAIKCJwIABIDSSVLClAKBAQAAgsSBEwCTS8aQiBPcHRpb25h
bC4gTWluaW11bSBub2RlIHN0b3JhZ2UgcGVyIGRhdGFiYXNlIHNlcnZlciBpbiBnaWdhYnl0
ZXMuCgoMCgUEAAILBRIDTAIHCgwKBQQAAgsBEgNMCCcKDAoFBAACCwMSA0wqLAoMCgUEAAIL
CBIDTQYuCg8KCAQAAgsInAgAEgNNBy0KNQoEBAACDBIDUAJJGiggT3B0aW9uYWwuIE1pbmlt
dW0gY29yZSBjb3VudCBwZXIgbm9kZS4KCgwKBQQAAgwFEgNQAgcKDAoFBAACDAESA1AIGgoM
CgUEAAIMAxIDUB0fCgwKBQQAAgwIEgNQIEgKDwoIBAACDAicCAASA1AhRwouCgQEAAINEgNT
AksaISBPcHRpb25hbC4gQXZhaWxhYmxlIGNvcmUgY291bnQuCgoMCgUEAAINBRIDUwIHCgwK
BQQAAg0BEgNTCBwKDAoFBAACDQMSA1MfIQoMCgUEAAINCBIDUyJKCg8KCAQAAg0InAgAEgNT
I0kKLgoEBAACDhIDVgJLGiEgT3B0aW9uYWwuIENvcmUgY291bnQgaW5jcmVtZW50LgoKDAoF
BAACDgUSA1YCBwoMCgUEAAIOARIDVggcCgwKBQQAAg4DEgNWHyEKDAoFBAACDggSA1YiSgoP
CggEAAIOCJwIABIDViNJYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::DbSystemShape::DbSystemShape ===
    # Fields for DbSystemShape
    # Field: name Type: 9 ()
    # Field: shape Type: 9 ()
    # Field: min_node_count Type: 5 ()
    # Field: max_node_count Type: 5 ()
    # Field: min_storage_count Type: 5 ()
    # Field: max_storage_count Type: 5 ()
    # Field: available_core_count_per_node Type: 5 ()
    # Field: available_memory_per_node_gb Type: 5 ()
    # Field: available_data_storage_tb Type: 5 ()
    # Field: min_core_count_per_node Type: 5 ()
    # Field: min_memory_per_node_gb Type: 5 ()
    # Field: min_db_node_storage_per_node_gb Type: 5 ()
    # Field: minimum_core_count Type: 5 ()
    # Field: available_core_count Type: 5 ()
    # Field: core_count_increment Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::DbSystemShape - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/db_system_shape.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::DbSystemShape;

    my $msg = Google::Cloud::Oracledatabase::V1::DbSystemShape::DbSystemShape->new({
        name => $name,
        shape => $shape,
        min_node_count => $min_node_count,
        max_node_count => $max_node_count,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::DbSystemShape::DbSystemShape->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/db_system_shape.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::DbSystemShape::DbSystemShape

Details of the Database System Shapes resource.
https://docs.oracle.com/en-us/iaas/api/#/en/database/20160918/DbSystemShapeSummary/

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the Database System Shape resource with the format:
projects/{project}/locations/{region}/dbSystemShapes/{db_system_shape}

=item * C<< $msg->shape() >> / C<< $msg->shape($value) >>

Type: C<String>

Optional. shape

=item * C<< $msg->min_node_count() >> / C<< $msg->min_node_count($value) >>

Type: C<Int32>

Optional. Minimum number of database servers.

=item * C<< $msg->max_node_count() >> / C<< $msg->max_node_count($value) >>

Type: C<Int32>

Optional. Maximum number of database servers.

=item * C<< $msg->min_storage_count() >> / C<< $msg->min_storage_count($value) >>

Type: C<Int32>

Optional. Minimum number of storage servers.

=item * C<< $msg->max_storage_count() >> / C<< $msg->max_storage_count($value) >>

Type: C<Int32>

Optional. Maximum number of storage servers.

=item * C<< $msg->available_core_count_per_node() >> / C<< $msg->available_core_count_per_node($value) >>

Type: C<Int32>

Optional. Number of cores per node.

=item * C<< $msg->available_memory_per_node_gb() >> / C<< $msg->available_memory_per_node_gb($value) >>

Type: C<Int32>

Optional. Memory per database server node in gigabytes.

=item * C<< $msg->available_data_storage_tb() >> / C<< $msg->available_data_storage_tb($value) >>

Type: C<Int32>

Optional. Storage per storage server in terabytes.

=item * C<< $msg->min_core_count_per_node() >> / C<< $msg->min_core_count_per_node($value) >>

Type: C<Int32>

Optional. Minimum core count per node.

=item * C<< $msg->min_memory_per_node_gb() >> / C<< $msg->min_memory_per_node_gb($value) >>

Type: C<Int32>

Optional. Minimum memory per node in gigabytes.

=item * C<< $msg->min_db_node_storage_per_node_gb() >> / C<< $msg->min_db_node_storage_per_node_gb($value) >>

Type: C<Int32>

Optional. Minimum node storage per database server in gigabytes.

=item * C<< $msg->minimum_core_count() >> / C<< $msg->minimum_core_count($value) >>

Type: C<Int32>

Optional. Minimum core count per node.

=item * C<< $msg->available_core_count() >> / C<< $msg->available_core_count($value) >>

Type: C<Int32>

Optional. Available core count.

=item * C<< $msg->core_count_increment() >> / C<< $msg->core_count_increment($value) >>

Type: C<Int32>

Optional. Core count increment.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::DbSystemShape::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
