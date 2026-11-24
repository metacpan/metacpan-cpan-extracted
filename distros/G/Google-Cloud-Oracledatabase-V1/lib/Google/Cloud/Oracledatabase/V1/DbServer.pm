package Google::Cloud::Oracledatabase::V1::DbServer;

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
Ci5nb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvZGJfc2VydmVyLnByb3RvEh5nb29n
bGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8i4gIKCERiU2VydmVyEhcKBG5hbWUY
ASABKAlCA+BBCFIEbmFtZRImCgxkaXNwbGF5X25hbWUYAiABKAlCA+BBAVILZGlzcGxheU5h
bWUSVwoKcHJvcGVydGllcxgDIAEoCzIyLmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52
MS5EYlNlcnZlclByb3BlcnRpZXNCA+BBAVIKcHJvcGVydGllczq7AepBtwEKJm9yYWNsZWRh
dGFiYXNlLmdvb2dsZWFwaXMuY29tL0RiU2VydmVyEnhwcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vY2xvdWRFeGFkYXRhSW5mcmFzdHJ1Y3R1cmVzL3tjbG91ZF9l
eGFkYXRhX2luZnJhc3RydWN0dXJlfS9kYlNlcnZlcnMve2RiX3NlcnZlcn0qCWRiU2VydmVy
czIIZGJTZXJ2ZXIi2QQKEkRiU2VydmVyUHJvcGVydGllcxIXCgRvY2lkGAEgASgJQgPgQQNS
BG9jaWQSIgoKb2NwdV9jb3VudBgCIAEoBUID4EEBUglvY3B1Q291bnQSKQoObWF4X29jcHVf
Y291bnQYAyABKAVCA+BBAVIMbWF4T2NwdUNvdW50EikKDm1lbW9yeV9zaXplX2diGAQgASgF
QgPgQQFSDG1lbW9yeVNpemVHYhIwChJtYXhfbWVtb3J5X3NpemVfZ2IYBSABKAVCA+BBAVIP
bWF4TWVtb3J5U2l6ZUdiEjkKF2RiX25vZGVfc3RvcmFnZV9zaXplX2diGAYgASgFQgPgQQFS
E2RiTm9kZVN0b3JhZ2VTaXplR2ISQAobbWF4X2RiX25vZGVfc3RvcmFnZV9zaXplX2diGAcg
ASgFQgPgQQFSFm1heERiTm9kZVN0b3JhZ2VTaXplR2ISHgoIdm1fY291bnQYCCABKAVCA+BB
AVIHdm1Db3VudBJTCgVzdGF0ZRgJIAEoDjI4Lmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFz
ZS52MS5EYlNlcnZlclByb3BlcnRpZXMuU3RhdGVCA+BBA1IFc3RhdGUSIwoLZGJfbm9kZV9p
ZHMYCiADKAlCA+BBA1IJZGJOb2RlSWRzImcKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVE
EAASDAoIQ1JFQVRJTkcQARINCglBVkFJTEFCTEUQAhIPCgtVTkFWQUlMQUJMRRADEgwKCERF
TEVUSU5HEAQSCwoHREVMRVRFRBAFQucBCiJjb20uZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFi
YXNlLnYxQg1EYlNlcnZlclByb3RvUAFaSmNsb3VkLmdvb2dsZS5jb20vZ28vb3JhY2xlZGF0
YWJhc2UvYXBpdjEvb3JhY2xlZGF0YWJhc2VwYjtvcmFjbGVkYXRhYmFzZXBiqgIeR29vZ2xl
LkNsb3VkLk9yYWNsZURhdGFiYXNlLlYxygIeR29vZ2xlXENsb3VkXE9yYWNsZURhdGFiYXNl
XFYx6gIhR29vZ2xlOjpDbG91ZDo6T3JhY2xlRGF0YWJhc2U6OlYxSvkbCgYSBA4AZwEKvAQK
AQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIg
dGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3Ug
bWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExp
Y2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAg
aHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJl
cXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0
d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24g
YW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9G
IEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNl
IGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAog
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIAKQoJ
CgIDARIDEwAjCggKAQgSAxUAOwoJCgIIJRIDFQA7CggKAQgSAxYAYQoJCgIICxIDFgBhCggK
AQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgALgoJCgIICBIDGAAuCggKAQgSAxkAOwoJCgII
ARIDGQA7CggKAQgSAxoAOwoJCgIIKRIDGgA7CggKAQgSAxsAOgoJCgIILRIDGwA6Cn8KAgQA
EgQfADABGnMgRGV0YWlscyBvZiB0aGUgZGF0YWJhc2Ugc2VydmVyIHJlc291cmNlLgogaHR0
cHM6Ly9kb2NzLm9yYWNsZS5jb20vZW4tdXMvaWFhcy9hcGkvIy9lbi9kYXRhYmFzZS8yMDE2
MDkxOC9EYlNlcnZlci8KCgoKAwQAARIDHwgQCgsKAwQABxIEIAIlBAoNCgUEAAedCBIEIAIl
BArPAQoEBAACABIDKQI9GsEBIElkZW50aWZpZXIuIFRoZSBuYW1lIG9mIHRoZSBkYXRhYmFz
ZSBzZXJ2ZXIgcmVzb3VyY2Ugd2l0aCB0aGUgZm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L2Nsb3VkRXhhZGF0YUluZnJhc3RydWN0dXJlcy97Y2xv
dWRfZXhhZGF0YV9pbmZyYXN0cnVjdHVyZX0vZGJTZXJ2ZXJzL3tkYl9zZXJ2ZXJ9CgoMCgUE
AAIABRIDKQIICgwKBQQAAgABEgMpCQ0KDAoFBAACAAMSAykQEQoMCgUEAAIACBIDKRI8Cg8K
CAQAAgAInAgAEgMpEzsKPgoEBAACARIDLAJDGjEgT3B0aW9uYWwuIFVzZXIgZnJpZW5kbHkg
bmFtZSBmb3IgdGhpcyByZXNvdXJjZS4KCgwKBQQAAgEFEgMsAggKDAoFBAACAQESAywJFQoM
CgUEAAIBAxIDLBgZCgwKBQQAAgEIEgMsGkIKDwoIBAACAQicCAASAywbQQpDCgQEAAICEgMv
Ak0aNiBPcHRpb25hbC4gVmFyaW91cyBwcm9wZXJ0aWVzIG9mIHRoZSBkYXRhYmFzZSBzZXJ2
ZXIuCgoMCgUEAAICBhIDLwIUCgwKBQQAAgIBEgMvFR8KDAoFBAACAgMSAy8iIwoMCgUEAAIC
CBIDLyRMCg8KCAQAAgIInAgAEgMvJUsKVgoCBAESBDMAZwEaSiBWYXJpb3VzIHByb3BlcnRp
ZXMgYW5kIHNldHRpbmdzIGFzc29jaWF0ZWQgd2l0aCBFeGFkYXRhIGRhdGFiYXNlIHNlcnZl
ci4KCgoKAwQBARIDMwgaCkQKBAQBBAASBDUCRwMaNiBUaGUgdmFyaW91cyBsaWZlY3ljbGUg
c3RhdGVzIG9mIHRoZSBkYXRhYmFzZSBzZXJ2ZXIuCgoMCgUEAQQAARIDNQcMCisKBgQBBAAC
ABIDNwQaGhwgRGVmYXVsdCB1bnNwZWNpZmllZCB2YWx1ZS4KCg4KBwQBBAACAAESAzcEFQoO
CgcEAQQAAgACEgM3GBkKQgoGBAEEAAIBEgM6BBEaMyBJbmRpY2F0ZXMgdGhhdCB0aGUgcmVz
b3VyY2UgaXMgaW4gY3JlYXRpbmcgc3RhdGUuCgoOCgcEAQQAAgEBEgM6BAwKDgoHBAEEAAIB
AhIDOg8QCkMKBgQBBAACAhIDPQQSGjQgSW5kaWNhdGVzIHRoYXQgdGhlIHJlc291cmNlIGlz
IGluIGF2YWlsYWJsZSBzdGF0ZS4KCg4KBwQBBAACAgESAz0EDQoOCgcEAQQAAgICEgM9EBEK
RQoGBAEEAAIDEgNABBQaNiBJbmRpY2F0ZXMgdGhhdCB0aGUgcmVzb3VyY2UgaXMgaW4gdW5h
dmFpbGFibGUgc3RhdGUuCgoOCgcEAQQAAgMBEgNABA8KDgoHBAEEAAIDAhIDQBITCkIKBgQB
BAACBBIDQwQRGjMgSW5kaWNhdGVzIHRoYXQgdGhlIHJlc291cmNlIGlzIGluIGRlbGV0aW5n
IHN0YXRlLgoKDgoHBAEEAAIEARIDQwQMCg4KBwQBBAACBAISA0MPEApBCgYEAQQAAgUSA0YE
EBoyIEluZGljYXRlcyB0aGF0IHRoZSByZXNvdXJjZSBpcyBpbiBkZWxldGVkIHN0YXRlLgoK
DgoHBAEEAAIFARIDRgQLCg4KBwQBBAACBQISA0YODwo0CgQEAQIAEgNKAj4aJyBPdXRwdXQg
b25seS4gT0NJRCBvZiBkYXRhYmFzZSBzZXJ2ZXIuCgoMCgUEAQIABRIDSgIICgwKBQQBAgAB
EgNKCQ0KDAoFBAECAAMSA0oQEQoMCgUEAQIACBIDShI9Cg8KCAQBAgAInAgAEgNKEzwKMQoE
BAECARIDTQJAGiQgT3B0aW9uYWwuIE9DUFUgY291bnQgcGVyIGRhdGFiYXNlLgoKDAoFBAEC
AQUSA00CBwoMCgUEAQIBARIDTQgSCgwKBQQBAgEDEgNNFRYKDAoFBAECAQgSA00XPwoPCggE
AQIBCJwIABIDTRg+CjkKBAQBAgISA1ACRBosIE9wdGlvbmFsLiBNYXhpbXVtIE9DUFUgY291
bnQgcGVyIGRhdGFiYXNlLgoKDAoFBAECAgUSA1ACBwoMCgUEAQICARIDUAgWCgwKBQQBAgID
EgNQGRoKDAoFBAECAggSA1AbQwoPCggEAQICCJwIABIDUBxCCjEKBAQBAgMSA1MCRBokIE9w
dGlvbmFsLiBNZW1vcnkgYWxsb2NhdGVkIGluIEdCcy4KCgwKBQQBAgMFEgNTAgcKDAoFBAEC
AwESA1MIFgoMCgUEAQIDAxIDUxkaCgwKBQQBAgMIEgNTG0MKDwoIBAECAwicCAASA1McQgo5
CgQEAQIEEgNWAkgaLCBPcHRpb25hbC4gTWF4aW11bSBtZW1vcnkgYWxsb2NhdGVkIGluIEdC
cy4KCgwKBQQBAgQFEgNWAgcKDAoFBAECBAESA1YIGgoMCgUEAQIEAxIDVh0eCgwKBQQBAgQI
EgNWH0cKDwoIBAECBAicCAASA1YgRgouCgQEAQIFEgNZAk0aISBPcHRpb25hbC4gTG9jYWwg
c3RvcmFnZSBwZXIgVk0uCgoMCgUEAQIFBRIDWQIHCgwKBQQBAgUBEgNZCB8KDAoFBAECBQMS
A1kiIwoMCgUEAQIFCBIDWSRMCg8KCAQBAgUInAgAEgNZJUsKNwoEBAECBhIEXAJdLxopIE9w
dGlvbmFsLiBNYXhpbXVtIGxvY2FsIHN0b3JhZ2UgcGVyIFZNLgoKDAoFBAECBgUSA1wCBwoM
CgUEAQIGARIDXAgjCgwKBQQBAgYDEgNcJicKDAoFBAECBggSA10GLgoPCggEAQIGCJwIABID
XQctCi8KBAQBAgcSA2ACPhoiIE9wdGlvbmFsLiBWbSBjb3VudCBwZXIgZGF0YWJhc2UuCgoM
CgUEAQIHBRIDYAIHCgwKBQQBAgcBEgNgCBAKDAoFBAECBwMSA2ATFAoMCgUEAQIHCBIDYBU9
Cg8KCAQBAgcInAgAEgNgFjwKOQoEBAECCBIDYwI+GiwgT3V0cHV0IG9ubHkuIFN0YXRlIG9m
IHRoZSBkYXRhYmFzZSBzZXJ2ZXIuCgoMCgUEAQIIBhIDYwIHCgwKBQQBAggBEgNjCA0KDAoF
BAECCAMSA2MQEQoMCgUEAQIICBIDYxI9Cg8KCAQBAggInAgAEgNjEzwKVwoEBAECCRIDZgJP
GkogT3V0cHV0IG9ubHkuIE9DSUQgb2YgZGF0YWJhc2Ugbm9kZXMgYXNzb2NpYXRlZCB3aXRo
IHRoZSBkYXRhYmFzZSBzZXJ2ZXIuCgoMCgUEAQIJBBIDZgIKCgwKBQQBAgkFEgNmCxEKDAoF
BAECCQESA2YSHQoMCgUEAQIJAxIDZiAiCgwKBQQBAgkIEgNmI04KDwoIBAECCQicCAASA2Yk
TWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::DbServer::DbServer ===
    # Fields for DbServer
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: properties Type: 11 (.google.cloud.oracledatabase.v1.DbServerProperties)

# === Message: Google::Cloud::Oracledatabase::V1::DbServer::DbServerProperties ===
    # Fields for DbServerProperties
    # Field: ocid Type: 9 ()
    # Field: ocpu_count Type: 5 ()
    # Field: max_ocpu_count Type: 5 ()
    # Field: memory_size_gb Type: 5 ()
    # Field: max_memory_size_gb Type: 5 ()
    # Field: db_node_storage_size_gb Type: 5 ()
    # Field: max_db_node_storage_size_gb Type: 5 ()
    # Field: vm_count Type: 5 ()
    # Field: state Type: 14 (.google.cloud.oracledatabase.v1.DbServerProperties.State)
    # Field: db_node_ids Type: 9 ()

# Enum: DbServerProperties::State
our $DbServerProperties_STATE_UNSPECIFIED = 0;
our $DbServerProperties_CREATING = 1;
our $DbServerProperties_AVAILABLE = 2;
our $DbServerProperties_UNAVAILABLE = 3;
our $DbServerProperties_DELETING = 4;
our $DbServerProperties_DELETED = 5;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::DbServer - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/db_server.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::DbServer;

    my $msg = Google::Cloud::Oracledatabase::V1::DbServer::DbServer->new({
        name => $name,
        display_name => $display_name,
        properties => $properties,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::DbServer::DbServer->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/db_server.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::DbServer::DbServer

Details of the database server resource.
https://docs.oracle.com/en-us/iaas/api/#/en/database/20160918/DbServer/

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the database server resource with the format:
projects/{project}/locations/{location}/cloudExadataInfrastructures/{cloud_exadata_infrastructure}/dbServers/{db_server}

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. User friendly name for this resource.

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::DbServer::DbServerProperties>)

Optional. Various properties of the database server.

=back

=head2 Google::Cloud::Oracledatabase::V1::DbServer::DbServerProperties

Various properties and settings associated with Exadata database server.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ocid() >> / C<< $msg->ocid($value) >>

Type: C<String>

Output only. OCID of database server.

=item * C<< $msg->ocpu_count() >> / C<< $msg->ocpu_count($value) >>

Type: C<Int32>

Optional. OCPU count per database.

=item * C<< $msg->max_ocpu_count() >> / C<< $msg->max_ocpu_count($value) >>

Type: C<Int32>

Optional. Maximum OCPU count per database.

=item * C<< $msg->memory_size_gb() >> / C<< $msg->memory_size_gb($value) >>

Type: C<Int32>

Optional. Memory allocated in GBs.

=item * C<< $msg->max_memory_size_gb() >> / C<< $msg->max_memory_size_gb($value) >>

Type: C<Int32>

Optional. Maximum memory allocated in GBs.

=item * C<< $msg->db_node_storage_size_gb() >> / C<< $msg->db_node_storage_size_gb($value) >>

Type: C<Int32>

Optional. Local storage per VM.

=item * C<< $msg->max_db_node_storage_size_gb() >> / C<< $msg->max_db_node_storage_size_gb($value) >>

Type: C<Int32>

Optional. Maximum local storage per VM.

=item * C<< $msg->vm_count() >> / C<< $msg->vm_count($value) >>

Type: C<Int32>

Optional. Vm count per database.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::DbServerProperties::State>)

Output only. State of the database server.

=item * C<< $msg->db_node_ids() >> / C<< $msg->db_node_ids($value) >>

Type: C<String>

Output only. OCID of database nodes associated with the database server.

=back

=head3 Enum: DbServerProperties::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<AVAILABLE> => C<2>

=item * C<UNAVAILABLE> => C<3>

=item * C<DELETING> => C<4>

=item * C<DELETED> => C<5>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::DbServer::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
