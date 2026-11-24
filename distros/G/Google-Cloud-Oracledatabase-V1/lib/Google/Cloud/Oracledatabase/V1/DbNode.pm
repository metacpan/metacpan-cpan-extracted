package Google::Cloud::Oracledatabase::V1::DbNode;

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
Cixnb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvZGJfbm9kZS5wcm90bxIeZ29vZ2xl
LmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0
YW1wLnByb3RvIvICCgZEYk5vZGUSFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lElUKCnByb3Bl
cnRpZXMYAyABKAsyMC5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEuRGJOb2RlUHJv
cGVydGllc0ID4EEBUgpwcm9wZXJ0aWVzOvcB6kHzAQokb3JhY2xlZGF0YWJhc2UuZ29vZ2xl
YXBpcy5jb20vRGJOb2RlElxwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vY2xvdWRWbUNsdXN0ZXJzL3tjbG91ZF92bV9jbHVzdGVyfS9kYk5vZGVzL3tkYl9ub2Rl
fRJccHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2V4YWRiVm1DbHVz
dGVycy97ZXhhZGJfdm1fY2x1c3Rlcn0vZGJOb2Rlcy97ZGJfbm9kZX0qB2RiTm9kZXMyBmRi
Tm9kZSLoBAoQRGJOb2RlUHJvcGVydGllcxIXCgRvY2lkGAEgASgJQgPgQQNSBG9jaWQSIgoK
b2NwdV9jb3VudBgCIAEoBUID4EEBUglvY3B1Q291bnQSJAoObWVtb3J5X3NpemVfZ2IYAyAB
KAVSDG1lbW9yeVNpemVHYhI5ChdkYl9ub2RlX3N0b3JhZ2Vfc2l6ZV9nYhgEIAEoBUID4EEB
UhNkYk5vZGVTdG9yYWdlU2l6ZUdiEikKDmRiX3NlcnZlcl9vY2lkGAUgASgJQgPgQQFSDGRi
U2VydmVyT2NpZBIfCghob3N0bmFtZRgIIAEoCUID4EEBUghob3N0bmFtZRJRCgVzdGF0ZRgJ
IAEoDjI2Lmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MS5EYk5vZGVQcm9wZXJ0aWVz
LlN0YXRlQgPgQQNSBXN0YXRlEi8KFHRvdGFsX2NwdV9jb3JlX2NvdW50GAogASgFUhF0b3Rh
bENwdUNvcmVDb3VudBJACgtjcmVhdGVfdGltZRgLIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZSKjAQoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJ
RUQQABIQCgxQUk9WSVNJT05JTkcQARINCglBVkFJTEFCTEUQAhIMCghVUERBVElORxADEgwK
CFNUT1BQSU5HEAQSCwoHU1RPUFBFRBAFEgwKCFNUQVJUSU5HEAYSDwoLVEVSTUlOQVRJTkcQ
BxIOCgpURVJNSU5BVEVEEAgSCgoGRkFJTEVEEAlC5QEKImNvbS5nb29nbGUuY2xvdWQub3Jh
Y2xlZGF0YWJhc2UudjFCC0RiTm9kZVByb3RvUAFaSmNsb3VkLmdvb2dsZS5jb20vZ28vb3Jh
Y2xlZGF0YWJhc2UvYXBpdjEvb3JhY2xlZGF0YWJhc2VwYjtvcmFjbGVkYXRhYmFzZXBiqgIe
R29vZ2xlLkNsb3VkLk9yYWNsZURhdGFiYXNlLlYxygIeR29vZ2xlXENsb3VkXE9yYWNsZURh
dGFiYXNlXFYx6gIhR29vZ2xlOjpDbG91ZDo6T3JhY2xlRGF0YWJhc2U6OlYxSvIbCgYSBA4A
bwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwAS
AxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACkKCAoBCBIDFgA7CgkKAgglEgMWADsKCAoBCBID
FwBhCgkKAggLEgMXAGEKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQAsCgkKAggIEgMZ
ACwKCAoBCBIDGgA7CgkKAggBEgMaADsKCAoBCBIDGwA7CgkKAggpEgMbADsKCAoBCBIDHAA6
CgkKAggtEgMcADoKewoCBAASBCAALwEabyBEZXRhaWxzIG9mIHRoZSBkYXRhYmFzZSBub2Rl
IHJlc291cmNlLgogaHR0cHM6Ly9kb2NzLm9yYWNsZS5jb20vZW4tdXMvaWFhcy9hcGkvIy9l
bi9kYXRhYmFzZS8yMDE2MDkxOC9EYk5vZGUvCgoKCgMEAAESAyAIDgoLCgMEAAcSBCECJwQK
DQoFBAAHnQgSBCECJwQKuQEKBAQAAgASAysCPRqrASBJZGVudGlmaWVyLiBUaGUgbmFtZSBv
ZiB0aGUgZGF0YWJhc2Ugbm9kZSByZXNvdXJjZSBpbiB0aGUgZm9sbG93aW5nIGZvcm1hdDoK
IHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jbG91ZFZtQ2x1c3Rl
cnMve2Nsb3VkX3ZtX2NsdXN0ZXJ9L2RiTm9kZXMve2RiX25vZGV9CgoMCgUEAAIABRIDKwII
CgwKBQQAAgABEgMrCQ0KDAoFBAACAAMSAysQEQoMCgUEAAIACBIDKxI8Cg8KCAQAAgAInAgA
EgMrEzsKQQoEBAACARIDLgJLGjQgT3B0aW9uYWwuIFZhcmlvdXMgcHJvcGVydGllcyBvZiB0
aGUgZGF0YWJhc2Ugbm9kZS4KCgwKBQQAAgEGEgMuAhIKDAoFBAACAQESAy4THQoMCgUEAAIB
AxIDLiAhCgwKBQQAAgEIEgMuIkoKDwoIBAACAQicCAASAy4jSQpGCgIEARIEMgBvARo6IFZh
cmlvdXMgcHJvcGVydGllcyBhbmQgc2V0dGluZ3MgYXNzb2NpYXRlZCB3aXRoIERiIG5vZGUu
CgoKCgMEAQESAzIIGApCCgQEAQQAEgQ0AlIDGjQgVGhlIHZhcmlvdXMgbGlmZWN5Y2xlIHN0
YXRlcyBvZiB0aGUgZGF0YWJhc2Ugbm9kZS4KCgwKBQQBBAABEgM0BwwKKwoGBAEEAAIAEgM2
BBoaHCBEZWZhdWx0IHVuc3BlY2lmaWVkIHZhbHVlLgoKDgoHBAEEAAIAARIDNgQVCg4KBwQB
BAACAAISAzYYGQpGCgYEAQQAAgESAzkEFRo3IEluZGljYXRlcyB0aGF0IHRoZSByZXNvdXJj
ZSBpcyBpbiBwcm92aXNpb25pbmcgc3RhdGUuCgoOCgcEAQQAAgEBEgM5BBAKDgoHBAEEAAIB
AhIDORMUCkMKBgQBBAACAhIDPAQSGjQgSW5kaWNhdGVzIHRoYXQgdGhlIHJlc291cmNlIGlz
IGluIGF2YWlsYWJsZSBzdGF0ZS4KCg4KBwQBBAACAgESAzwEDQoOCgcEAQQAAgICEgM8EBEK
QgoGBAEEAAIDEgM/BBEaMyBJbmRpY2F0ZXMgdGhhdCB0aGUgcmVzb3VyY2UgaXMgaW4gdXBk
YXRpbmcgc3RhdGUuCgoOCgcEAQQAAgMBEgM/BAwKDgoHBAEEAAIDAhIDPw8QCkIKBgQBBAAC
BBIDQgQRGjMgSW5kaWNhdGVzIHRoYXQgdGhlIHJlc291cmNlIGlzIGluIHN0b3BwaW5nIHN0
YXRlLgoKDgoHBAEEAAIEARIDQgQMCg4KBwQBBAACBAISA0IPEApBCgYEAQQAAgUSA0UEEBoy
IEluZGljYXRlcyB0aGF0IHRoZSByZXNvdXJjZSBpcyBpbiBzdG9wcGVkIHN0YXRlLgoKDgoH
BAEEAAIFARIDRQQLCg4KBwQBBAACBQISA0UODwpCCgYEAQQAAgYSA0gEERozIEluZGljYXRl
cyB0aGF0IHRoZSByZXNvdXJjZSBpcyBpbiBzdGFydGluZyBzdGF0ZS4KCg4KBwQBBAACBgES
A0gEDAoOCgcEAQQAAgYCEgNIDxAKRQoGBAEEAAIHEgNLBBQaNiBJbmRpY2F0ZXMgdGhhdCB0
aGUgcmVzb3VyY2UgaXMgaW4gdGVybWluYXRpbmcgc3RhdGUuCgoOCgcEAQQAAgcBEgNLBA8K
DgoHBAEEAAIHAhIDSxITCkQKBgQBBAACCBIDTgQTGjUgSW5kaWNhdGVzIHRoYXQgdGhlIHJl
c291cmNlIGlzIGluIHRlcm1pbmF0ZWQgc3RhdGUuCgoOCgcEAQQAAggBEgNOBA4KDgoHBAEE
AAIIAhIDThESCkAKBgQBBAACCRIDUQQPGjEgSW5kaWNhdGVzIHRoYXQgdGhlIHJlc291cmNl
IGlzIGluIGZhaWxlZCBzdGF0ZS4KCg4KBwQBBAACCQESA1EECgoOCgcEAQQAAgkCEgNRDQ4K
MgoEBAECABIDVQI+GiUgT3V0cHV0IG9ubHkuIE9DSUQgb2YgZGF0YWJhc2Ugbm9kZS4KCgwK
BQQBAgAFEgNVAggKDAoFBAECAAESA1UJDQoMCgUEAQIAAxIDVRARCgwKBQQBAgAIEgNVEj0K
DwoIBAECAAicCAASA1UTPAo2CgQEAQIBEgNYAkAaKSBPcHRpb25hbC4gT0NQVSBjb3VudCBw
ZXIgZGF0YWJhc2Ugbm9kZS4KCgwKBQQBAgEFEgNYAgcKDAoFBAECAQESA1gIEgoMCgUEAQIB
AxIDWBUWCgwKBQQBAgEIEgNYFz8KDwoIBAECAQicCAASA1gYPgonCgQEAQICEgNbAhsaGiBN
ZW1vcnkgYWxsb2NhdGVkIGluIEdCcy4KCgwKBQQBAgIFEgNbAgcKDAoFBAECAgESA1sIFgoM
CgUEAQICAxIDWxkaCjkKBAQBAgMSA14CTRosIE9wdGlvbmFsLiBMb2NhbCBzdG9yYWdlIHBl
ciBkYXRhYmFzZSBub2RlLgoKDAoFBAECAwUSA14CBwoMCgUEAQIDARIDXggfCgwKBQQBAgMD
EgNeIiMKDAoFBAECAwgSA14kTAoPCggEAQIDCJwIABIDXiVLCi4KBAQBAgQSA2ECRRohIE9w
dGlvbmFsLiBEYXRhYmFzZSBzZXJ2ZXIgT0NJRC4KCgwKBQQBAgQFEgNhAggKDAoFBAECBAES
A2EJFwoMCgUEAQIEAxIDYRobCgwKBQQBAgQIEgNhHEQKDwoIBAECBAicCAASA2EdQwocCgQE
AQIFEgNkAj8aDyBPcHRpb25hbC4gRE5TCgoMCgUEAQIFBRIDZAIICgwKBQQBAgUBEgNkCREK
DAoFBAECBQMSA2QUFQoMCgUEAQIFCBIDZBY+Cg8KCAQBAgUInAgAEgNkFz0KNwoEBAECBhID
ZwI+GiogT3V0cHV0IG9ubHkuIFN0YXRlIG9mIHRoZSBkYXRhYmFzZSBub2RlLgoKDAoFBAEC
BgYSA2cCBwoMCgUEAQIGARIDZwgNCgwKBQQBAgYDEgNnEBEKDAoFBAECBggSA2cSPQoPCggE
AQIGCJwIABIDZxM8CjkKBAQBAgcSA2oCIhosIFRvdGFsIENQVSBjb3JlIGNvdW50IG9mIHRo
ZSBkYXRhYmFzZSBub2RlLgoKDAoFBAECBwUSA2oCBwoMCgUEAQIHARIDaggcCgwKBQQBAgcD
EgNqHyEKUgoEBAECCBIEbQJuMhpEIE91dHB1dCBvbmx5LiBUaGUgZGF0ZSBhbmQgdGltZSB0
aGF0IHRoZSBkYXRhYmFzZSBub2RlIHdhcyBjcmVhdGVkLgoKDAoFBAECCAYSA20CGwoMCgUE
AQIIARIDbRwnCgwKBQQBAggDEgNtKiwKDAoFBAECCAgSA24GMQoPCggEAQIICJwIABIDbgcw
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::DbNode::DbNode ===
    # Fields for DbNode
    # Field: name Type: 9 ()
    # Field: properties Type: 11 (.google.cloud.oracledatabase.v1.DbNodeProperties)

# === Message: Google::Cloud::Oracledatabase::V1::DbNode::DbNodeProperties ===
    # Fields for DbNodeProperties
    # Field: ocid Type: 9 ()
    # Field: ocpu_count Type: 5 ()
    # Field: memory_size_gb Type: 5 ()
    # Field: db_node_storage_size_gb Type: 5 ()
    # Field: db_server_ocid Type: 9 ()
    # Field: hostname Type: 9 ()
    # Field: state Type: 14 (.google.cloud.oracledatabase.v1.DbNodeProperties.State)
    # Field: total_cpu_core_count Type: 5 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)

# Enum: DbNodeProperties::State
our $DbNodeProperties_STATE_UNSPECIFIED = 0;
our $DbNodeProperties_PROVISIONING = 1;
our $DbNodeProperties_AVAILABLE = 2;
our $DbNodeProperties_UPDATING = 3;
our $DbNodeProperties_STOPPING = 4;
our $DbNodeProperties_STOPPED = 5;
our $DbNodeProperties_STARTING = 6;
our $DbNodeProperties_TERMINATING = 7;
our $DbNodeProperties_TERMINATED = 8;
our $DbNodeProperties_FAILED = 9;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::DbNode - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/db_node.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::DbNode;

    my $msg = Google::Cloud::Oracledatabase::V1::DbNode::DbNode->new({
        name => $name,
        properties => $properties,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::DbNode::DbNode->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/db_node.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::DbNode::DbNode

Details of the database node resource.
https://docs.oracle.com/en-us/iaas/api/#/en/database/20160918/DbNode/

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the database node resource in the following format:
projects/{project}/locations/{location}/cloudVmClusters/{cloud_vm_cluster}/dbNodes/{db_node}

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::DbNode::DbNodeProperties>)

Optional. Various properties of the database node.

=back

=head2 Google::Cloud::Oracledatabase::V1::DbNode::DbNodeProperties

Various properties and settings associated with Db node.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ocid() >> / C<< $msg->ocid($value) >>

Type: C<String>

Output only. OCID of database node.

=item * C<< $msg->ocpu_count() >> / C<< $msg->ocpu_count($value) >>

Type: C<Int32>

Optional. OCPU count per database node.

=item * C<< $msg->memory_size_gb() >> / C<< $msg->memory_size_gb($value) >>

Type: C<Int32>

Memory allocated in GBs.

=item * C<< $msg->db_node_storage_size_gb() >> / C<< $msg->db_node_storage_size_gb($value) >>

Type: C<Int32>

Optional. Local storage per database node.

=item * C<< $msg->db_server_ocid() >> / C<< $msg->db_server_ocid($value) >>

Type: C<String>

Optional. Database server OCID.

=item * C<< $msg->hostname() >> / C<< $msg->hostname($value) >>

Type: C<String>

Optional. DNS

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::DbNodeProperties::State>)

Output only. State of the database node.

=item * C<< $msg->total_cpu_core_count() >> / C<< $msg->total_cpu_core_count($value) >>

Type: C<Int32>

Total CPU core count of the database node.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The date and time that the database node was created.

=back

=head3 Enum: DbNodeProperties::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<PROVISIONING> => C<1>

=item * C<AVAILABLE> => C<2>

=item * C<UPDATING> => C<3>

=item * C<STOPPING> => C<4>

=item * C<STOPPED> => C<5>

=item * C<STARTING> => C<6>

=item * C<TERMINATING> => C<7>

=item * C<TERMINATED> => C<8>

=item * C<FAILED> => C<9>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::DbNode::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
