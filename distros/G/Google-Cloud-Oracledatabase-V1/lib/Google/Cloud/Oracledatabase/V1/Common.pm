package Google::Cloud::Oracledatabase::V1::Common;

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
Citnb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvY29tbW9uLnByb3RvEh5nb29nbGUu
Y2xvdWQub3JhY2xlZGF0YWJhc2UudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8iLAoPQ3VzdG9tZXJDb250YWN0EhkKBWVt
YWlsGAEgASgJQgPgQQJSBWVtYWlsIpQEChFJZGVudGl0eUNvbm5lY3RvchIzChNzZXJ2aWNl
X2FnZW50X2VtYWlsGAEgASgJQgPgQQNSEXNlcnZpY2VBZ2VudEVtYWlsEnEKEGNvbm5lY3Rp
b25fc3RhdGUYAiABKA4yQS5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEuSWRlbnRp
dHlDb25uZWN0b3IuQ29ubmVjdGlvblN0YXRlQgPgQQNSD2Nvbm5lY3Rpb25TdGF0ZRJlChZ3
b3JrbG9hZF9pZGVudGl0eV9wb29sGAMgASgJQi/gQQP6QSkKJ2lhbS5nb29nbGVhcGlzLmNv
bS9Xb3JrbG9hZElkZW50aXR5UG9vbFIUd29ya2xvYWRJZGVudGl0eVBvb2wSNwoVaWRlbnRp
dHlfY29ubmVjdG9yX2lkGAQgASgJQgPgQQNSE2lkZW50aXR5Q29ubmVjdG9ySWQSOwoXbGlm
ZWN5Y2xlX3N0YXRlX2RldGFpbHMYBSABKAlCA+BBA1IVbGlmZWN5Y2xlU3RhdGVEZXRhaWxz
InoKD0Nvbm5lY3Rpb25TdGF0ZRIgChxDT05ORUNUSU9OX1NUQVRFX1VOU1BFQ0lGSUVEEAAS
DQoJQ09OTkVDVEVEEAESFwoTUEFSVElBTExZX0NPTk5FQ1RFRBACEhAKDERJU0NPTk5FQ1RF
RBADEgsKB1VOS05PV04QBCLpAQobRGF0YUNvbGxlY3Rpb25PcHRpb25zQ29tbW9uEkYKHWlz
X2RpYWdub3N0aWNzX2V2ZW50c19lbmFibGVkGAEgASgIQgPgQQFSGmlzRGlhZ25vc3RpY3NF
dmVudHNFbmFibGVkEkQKHGlzX2hlYWx0aF9tb25pdG9yaW5nX2VuYWJsZWQYAiABKAhCA+BB
AVIZaXNIZWFsdGhNb25pdG9yaW5nRW5hYmxlZBI8Chhpc19pbmNpZGVudF9sb2dzX2VuYWJs
ZWQYAyABKAhCA+BBAVIVaXNJbmNpZGVudExvZ3NFbmFibGVkKl0KDENvbXB1dGVNb2RlbBId
ChlDT01QVVRFX01PREVMX1VOU1BFQ0lGSUVEEAASFgoSQ09NUFVURV9NT0RFTF9FQ1BVEAES
FgoSQ09NUFVURV9NT0RFTF9PQ1BVEAJC5QEKImNvbS5nb29nbGUuY2xvdWQub3JhY2xlZGF0
YWJhc2UudjFCC0NvbW1vblByb3RvUAFaSmNsb3VkLmdvb2dsZS5jb20vZ28vb3JhY2xlZGF0
YWJhc2UvYXBpdjEvb3JhY2xlZGF0YWJhc2VwYjtvcmFjbGVkYXRhYmFzZXBiqgIeR29vZ2xl
LkNsb3VkLk9yYWNsZURhdGFiYXNlLlYxygIeR29vZ2xlXENsb3VkXE9yYWNsZURhdGFiYXNl
XFYx6gIhR29vZ2xlOjpDbG91ZDo6T3JhY2xlRGF0YWJhc2U6OlYxSoEiCgYSBA4AdgEKvAQK
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
AQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgALAoJCgIICBIDGAAsCggKAQgSAxkAOwoJCgII
ARIDGQA7CggKAQgSAxoAOwoJCgIIKRIDGgA7CggKAQgSAxsAOgoJCgIILRIDGwA6CmMKAgUA
EgQfACoBGlcgVGhlIGNvbXB1dGUgbW9kZWwgb2YgdGhlIEV4YWRhdGEgSW5mcmFzdHJ1Y3R1
cmUsIFZNIENsdXN0ZXIgYW5kIEF1dG9ub21vdXMKIERhdGFiYXNlLgoKCgoDBQABEgMfBREK
KQoEBQACABIDIQIgGhwgVW5zcGVjaWZpZWQgY29tcHV0ZSBtb2RlbC4KCgwKBQUAAgABEgMh
AhsKDAoFBQACAAISAyEeHwqgAQoEBQACARIDJQIZGpIBIEFic3RyYWN0IG1lYXN1cmUgb2Yg
Y29tcHV0ZSByZXNvdXJjZXMuIEVDUFVzIGFyZSBiYXNlZCBvbiB0aGUgbnVtYmVyIG9mCiBj
b3JlcyBlbGFzdGljYWxseSBhbGxvY2F0ZWQgZnJvbSBhIHBvb2wgb2YgY29tcHV0ZSBhbmQg
c3RvcmFnZSBzZXJ2ZXJzLgoKDAoFBQACAQESAyUCFAoMCgUFAAIBAhIDJRcYCmsKBAUAAgIS
AykCGRpeIFBoeXNpY2FsIG1lYXN1cmUgb2YgY29tcHV0ZSByZXNvdXJjZXMuIE9DUFVzIGFy
ZSBiYXNlZCBvbiB0aGUgcGh5c2ljYWwKIGNvcmUgb2YgYSBwcm9jZXNzb3IuCgoMCgUFAAIC
ARIDKQIUCgwKBQUAAgICEgMpFxgKmwEKAgQAEgQuADIBGo4BIFRoZSBDdXN0b21lckNvbnRh
Y3QgcmVmZXJlbmNlIGFzIGRlZmluZWQgYnkgT3JhY2xlLgogaHR0cHM6Ly9kb2NzLm9yYWNs
ZS5jb20vZW4tdXMvaWFhcy9hcGkvIy9lbi9kYXRhYmFzZS8yMDE2MDkxOC9kYXRhdHlwZXMv
Q3VzdG9tZXJDb250YWN0CgoKCgMEAAESAy4IFwp4CgQEAAIAEgMxAjwaayBSZXF1aXJlZC4g
VGhlIGVtYWlsIGFkZHJlc3MgdXNlZCBieSBPcmFjbGUgdG8gc2VuZCBub3RpZmljYXRpb25z
IHJlZ2FyZGluZwogZGF0YWJhc2VzIGFuZCBpbmZyYXN0cnVjdHVyZS4KCgwKBQQAAgAFEgMx
AggKDAoFBAACAAESAzEJDgoMCgUEAAIAAxIDMRESCgwKBQQAAgAIEgMxEzsKDwoIBAACAAic
CAASAzEUOgp8CgIEARIENgBnARpwIFRoZSBpZGVudGl0eSBjb25uZWN0b3IgZGV0YWlscyB3
aGljaCB3aWxsIGFsbG93IE9DSSB0byBzZWN1cmVseSBhY2Nlc3MKIHRoZSByZXNvdXJjZXMg
aW4gdGhlIGN1c3RvbWVyIHByb2plY3QuCgoKCgMEAQESAzYIGQpUCgQEAQQAEgQ4AkcDGkYg
VGhlIHZhcmlvdXMgY29ubmVjdGlvbiBzdGF0ZXMgb2YgdGhlIFdvcmtsb2FkSWRlbnRpdHlQ
b29sQ29ubmVjdGlvbi4KCgwKBQQBBAABEgM4BxYKKwoGBAEEAAIAEgM6BCUaHCBEZWZhdWx0
IHVuc3BlY2lmaWVkIHZhbHVlLgoKDgoHBAEEAAIAARIDOgQgCg4KBwQBBAACAAISAzojJAo7
CgYEAQQAAgESAz0EEhosIFRoZSBpZGVudGl0eSBwb29sIGNvbm5lY3Rpb24gaXMgY29ubmVj
dGVkLgoKDgoHBAEEAAIBARIDPQQNCg4KBwQBBAACAQISAz0QEQpFCgYEAQQAAgISA0AEHBo2
IFRoZSBpZGVudGl0eSBwb29sIGNvbm5lY3Rpb24gaXMgcGFydGlhbGx5IGNvbm5lY3RlZC4K
Cg4KBwQBBAACAgESA0AEFwoOCgcEAQQAAgICEgNAGhsKPgoGBAEEAAIDEgNDBBUaLyBUaGUg
aWRlbnRpdHkgcG9vbCBjb25uZWN0aW9uIGlzIGRpc2Nvbm5lY3RlZC4KCg4KBwQBBAACAwES
A0MEEAoOCgcEAQQAAgMCEgNDExQKRQoGBAEEAAIEEgNGBBAaNiBUaGUgaWRlbnRpdHkgcG9v
bCBjb25uZWN0aW9uIGlzIGluIGFuIHVua25vd24gc3RhdGUuCgoOCgcEAQQAAgQBEgNGBAsK
DgoHBAEEAAIEAhIDRg4PCtsBCgQEAQIAEgNMAk0azQEgT3V0cHV0IG9ubHkuIEEgZ29vZ2xl
IG1hbmFnZWQgc2VydmljZSBhY2NvdW50IG9uIHdoaWNoIGN1c3RvbWVycyBjYW4gZ3JhbnQK
IHJvbGVzIHRvIGFjY2VzcyByZXNvdXJjZXMgaW4gdGhlIGN1c3RvbWVyIHByb2plY3QuIEV4
YW1wbGU6CiBgcDE3Njk0NDUyNzI1NC01NS03NTExOWQ4N2ZkOGZAZ2NwLXNhLW9jaS5pYW0u
Z3NlcnZpY2VhY2NvdW50LmNvbWAKCgwKBQQBAgAFEgNMAggKDAoFBAECAAESA0wJHAoMCgUE
AQIAAxIDTB8gCgwKBQQBAgAIEgNMIUwKDwoIBAECAAicCAASA0wiSwpMCgQEAQIBEgRPAlAy
Gj4gT3V0cHV0IG9ubHkuIFRoZSBjb25uZWN0aW9uIHN0YXRlIG9mIHRoZSBpZGVudGl0eSBj
b25uZWN0b3IuCgoMCgUEAQIBBhIDTwIRCgwKBQQBAgEBEgNPEiIKDAoFBAECAQMSA08lJgoM
CgUEAQIBCBIDUAYxCg8KCAQBAgEInAgAEgNQBzAKtQIKBAQBAgISBFcCXAQapgIgT3V0cHV0
IG9ubHkuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBXb3JrbG9hZCBJZGVudGl0eSBQb29s
CiBjb25maWd1cmVkIGZvciBpZGVudGl0eSBmZWRlcmF0aW9uIHdpdGggT0NJLiBUaGlzIGV4
YWN0IHBvb2wgbmFtZSBjYW4gYmUKIHVzZWQgdG8gY29uZmlndXJlIFZQQyBTZXJ2aWNlIENv
bnRyb2xzIChWUEMtU0MpIGVncmVzcyBydWxlcy4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJv
amVjdH0vbG9jYXRpb25zL2dsb2JhbC93b3JrbG9hZElkZW50aXR5UG9vbHMve3dvcmtsb2Fk
X2lkZW50aXR5X3Bvb2x9YAoKDAoFBAECAgUSA1cCCAoMCgUEAQICARIDVwkfCgwKBQQBAgID
EgNXIiMKDQoFBAECAggSBFckXAMKDwoIBAECAgicCAASA1gELQoPCgcEAQICCJ8IEgRZBFsF
CpoCCgQEAQIDEgNiAk8ajAIgT3V0cHV0IG9ubHkuIFRoZSB1bmlxdWUgcGFydG5lciBpZGVu
dGlmaWVyIGZvciB0aGUgSWRlbnRpdHkgQ29ubmVjdG9yLAogdXNlZCB0byBlc3RhYmxpc2gg
c2VjdXJlIGNyb3NzLWNsb3VkIGFjY2VzcyBiZXR3ZWVuIEdvb2dsZSBDbG91ZCBhbmQgT0NJ
LgogVGhpcyBjb3JyZXNwb25kcyBkaXJlY3RseSB0byB0aGUgSUQgb2YgdGhlIE9yYWNsZURi
R2NwSWRlbnRpdHlDb25uZWN0b3IKIHJlc291cmNlIGluIE9yYWNsZSBDbG91ZCBJbmZyYXN0
cnVjdHVyZSAoT0NJKS4KCgwKBQQBAgMFEgNiAggKDAoFBAECAwESA2IJHgoMCgUEAQIDAxID
YiEiCgwKBQQBAgMIEgNiI04KDwoIBAECAwicCAASA2IkTQpWCgQEAQIEEgRlAmYyGkggT3V0
cHV0IG9ubHkuIEFkZGl0aW9uYWwgaW5mb3JtYXRpb24gYWJvdXQgdGhlIGN1cnJlbnQgbGlm
ZWN5Y2xlIHN0YXRlLgoKDAoFBAECBAUSA2UCCAoMCgUEAQIEARIDZQkgCgwKBQQBAgQDEgNl
IyQKDAoFBAECBAgSA2YGMQoPCggEAQIECJwIABIDZgcwCpYBCgIEAhIEawB2ARqJASBEYXRh
IGNvbGxlY3Rpb24gb3B0aW9ucyBmb3IgZGlhZ25vc3RpY3MuCiBodHRwczovL2RvY3Mub3Jh
Y2xlLmNvbS9lbi11cy9pYWFzL2FwaS8jL2VuL2RhdGFiYXNlLzIwMTYwOTE4L2RhdGF0eXBl
cy9EYXRhQ29sbGVjdGlvbk9wdGlvbnMKCgoKAwQCARIDawgjClYKBAQCAgASBG0Cbi8aSCBP
cHRpb25hbC4gSW5kaWNhdGVzIHdoZXRoZXIgdG8gZW5hYmxlIGRhdGEgY29sbGVjdGlvbiBm
b3IgZGlhZ25vc3RpY3MuCgoMCgUEAgIABRIDbQIGCgwKBQQCAgABEgNtByQKDAoFBAICAAMS
A20nKAoMCgUEAgIACBIDbgYuCg8KCAQCAgAInAgAEgNuBy0KSAoEBAICARIEcQJyLxo6IE9w
dGlvbmFsLiBJbmRpY2F0ZXMgd2hldGhlciB0byBlbmFibGUgaGVhbHRoIG1vbml0b3Jpbmcu
CgoMCgUEAgIBBRIDcQIGCgwKBQQCAgEBEgNxByMKDAoFBAICAQMSA3EmJwoMCgUEAgIBCBID
cgYuCg8KCAQCAgEInAgAEgNyBy0KWAoEBAICAhIDdQJNGksgT3B0aW9uYWwuIEluZGljYXRl
cyB3aGV0aGVyIHRvIGVuYWJsZSBpbmNpZGVudCBsb2dzIGFuZCB0cmFjZSBjb2xsZWN0aW9u
LgoKDAoFBAICAgUSA3UCBgoMCgUEAgICARIDdQcfCgwKBQQCAgIDEgN1IiMKDAoFBAICAggS
A3UkTAoPCggEAgICCJwIABIDdSVLYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::Common::CustomerContact ===
    # Fields for CustomerContact
    # Field: email Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::Common::IdentityConnector ===
    # Fields for IdentityConnector
    # Field: service_agent_email Type: 9 ()
    # Field: connection_state Type: 14 (.google.cloud.oracledatabase.v1.IdentityConnector.ConnectionState)
    # Field: workload_identity_pool Type: 9 ()
    # Field: identity_connector_id Type: 9 ()
    # Field: lifecycle_state_details Type: 9 ()

# Enum: IdentityConnector::ConnectionState
our $IdentityConnector_CONNECTION_STATE_UNSPECIFIED = 0;
our $IdentityConnector_CONNECTED = 1;
our $IdentityConnector_PARTIALLY_CONNECTED = 2;
our $IdentityConnector_DISCONNECTED = 3;
our $IdentityConnector_UNKNOWN = 4;

# === Message: Google::Cloud::Oracledatabase::V1::Common::DataCollectionOptionsCommon ===
    # Fields for DataCollectionOptionsCommon
    # Field: is_diagnostics_events_enabled Type: 8 ()
    # Field: is_health_monitoring_enabled Type: 8 ()
    # Field: is_incident_logs_enabled Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::Common - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/common.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::Common;

    my $msg = Google::Cloud::Oracledatabase::V1::Common::CustomerContact->new({
        email => $email,
    });

    # Read or update a field
    my $val = $msg->email();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::Common::CustomerContact->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::Common::CustomerContact

The CustomerContact reference as defined by Oracle.
https://docs.oracle.com/en-us/iaas/api/#/en/database/20160918/datatypes/CustomerContact

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->email() >> / C<< $msg->email($value) >>

Type: C<String>

Required. The email address used by Oracle to send notifications regarding
databases and infrastructure.

=back

=head2 Google::Cloud::Oracledatabase::V1::Common::IdentityConnector

The identity connector details which will allow OCI to securely access
the resources in the customer project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service_agent_email() >> / C<< $msg->service_agent_email($value) >>

Type: C<String>

Output only. A google managed service account on which customers can grant
roles to access resources in the customer project. Example:
`p176944527254-55-75119d87fd8f@gcp-sa-oci.iam.gserviceaccount.com`

=item * C<< $msg->connection_state() >> / C<< $msg->connection_state($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::IdentityConnector::ConnectionState>)

Output only. The connection state of the identity connector.

=item * C<< $msg->workload_identity_pool() >> / C<< $msg->workload_identity_pool($value) >>

Type: C<String>

Output only. The resource name of the Workload Identity Pool
configured for identity federation with OCI. This exact pool name can be
used to configure VPC Service Controls (VPC-SC) egress rules.
Format:
`projects/{project}/locations/global/workloadIdentityPools/{workload_identity_pool}`

=item * C<< $msg->identity_connector_id() >> / C<< $msg->identity_connector_id($value) >>

Type: C<String>

Output only. The unique partner identifier for the Identity Connector,
used to establish secure cross-cloud access between Google Cloud and OCI.
This corresponds directly to the ID of the OracleDbGcpIdentityConnector
resource in Oracle Cloud Infrastructure (OCI).

=item * C<< $msg->lifecycle_state_details() >> / C<< $msg->lifecycle_state_details($value) >>

Type: C<String>

Output only. Additional information about the current lifecycle state.

=back

=head3 Enum: IdentityConnector::ConnectionState

=over 4

=item * C<CONNECTION_STATE_UNSPECIFIED> => C<0>

=item * C<CONNECTED> => C<1>

=item * C<PARTIALLY_CONNECTED> => C<2>

=item * C<DISCONNECTED> => C<3>

=item * C<UNKNOWN> => C<4>

=back

=head2 Google::Cloud::Oracledatabase::V1::Common::DataCollectionOptionsCommon

Data collection options for diagnostics.
https://docs.oracle.com/en-us/iaas/api/#/en/database/20160918/datatypes/DataCollectionOptions

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->is_diagnostics_events_enabled() >> / C<< $msg->is_diagnostics_events_enabled($value) >>

Type: C<Bool>

Optional. Indicates whether to enable data collection for diagnostics.

=item * C<< $msg->is_health_monitoring_enabled() >> / C<< $msg->is_health_monitoring_enabled($value) >>

Type: C<Bool>

Optional. Indicates whether to enable health monitoring.

=item * C<< $msg->is_incident_logs_enabled() >> / C<< $msg->is_incident_logs_enabled($value) >>

Type: C<Bool>

Optional. Indicates whether to enable incident logs and trace collection.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
