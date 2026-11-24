package Google::Cloud::Cloudcontrolspartner::V1::EkmConnections;

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
Cjpnb29nbGUvY2xvdWQvY2xvdWRjb250cm9sc3BhcnRuZXIvdjEvZWttX2Nvbm5lY3Rpb25z
LnByb3RvEiRnb29nbGUuY2xvdWQuY2xvdWRjb250cm9sc3BhcnRuZXIudjEaH2dvb2dsZS9h
cGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8irgIK
DkVrbUNvbm5lY3Rpb25zEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRJcCg9la21fY29ubmVj
dGlvbnMYAiADKAsyMy5nb29nbGUuY2xvdWQuY2xvdWRjb250cm9sc3BhcnRuZXIudjEuRWtt
Q29ubmVjdGlvblIOZWttQ29ubmVjdGlvbnM6pAHqQaABCjJjbG91ZGNvbnRyb2xzcGFydG5l
ci5nb29nbGVhcGlzLmNvbS9Fa21Db25uZWN0aW9ucxJqb3JnYW5pemF0aW9ucy97b3JnYW5p
emF0aW9ufS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jdXN0b21lcnMve2N1c3RvbWVyfS93b3Jr
bG9hZHMve3dvcmtsb2FkfS9la21Db25uZWN0aW9ucyJqChhHZXRFa21Db25uZWN0aW9uc1Jl
cXVlc3QSTgoEbmFtZRgBIAEoCUI64EEC+kE0CjJjbG91ZGNvbnRyb2xzcGFydG5lci5nb29n
bGVhcGlzLmNvbS9Fa21Db25uZWN0aW9uc1IEbmFtZSLxAwoNRWttQ29ubmVjdGlvbhInCg9j
b25uZWN0aW9uX25hbWUYASABKAlSDmNvbm5lY3Rpb25OYW1lEnMKEGNvbm5lY3Rpb25fc3Rh
dGUYAiABKA4yQy5nb29nbGUuY2xvdWQuY2xvdWRjb250cm9sc3BhcnRuZXIudjEuRWttQ29u
bmVjdGlvbi5Db25uZWN0aW9uU3RhdGVCA+BBA1IPY29ubmVjdGlvblN0YXRlEm4KEGNvbm5l
Y3Rpb25fZXJyb3IYAyABKAsyQy5nb29nbGUuY2xvdWQuY2xvdWRjb250cm9sc3BhcnRuZXIu
djEuRWttQ29ubmVjdGlvbi5Db25uZWN0aW9uRXJyb3JSD2Nvbm5lY3Rpb25FcnJvchpZCg9D
b25uZWN0aW9uRXJyb3ISIQoMZXJyb3JfZG9tYWluGAEgASgJUgtlcnJvckRvbWFpbhIjCg1l
cnJvcl9tZXNzYWdlGAIgASgJUgxlcnJvck1lc3NhZ2UidwoPQ29ubmVjdGlvblN0YXRlEiAK
HENPTk5FQ1RJT05fU1RBVEVfVU5TUEVDSUZJRUQQABINCglBVkFJTEFCTEUQARIRCg1OT1Rf
QVZBSUxBQkxFEAISCQoFRVJST1IQAxIVChFQRVJNSVNTSU9OX0RFTklFRBAEQpcCCihjb20u
Z29vZ2xlLmNsb3VkLmNsb3VkY29udHJvbHNwYXJ0bmVyLnYxQhNFa21Db25uZWN0aW9uc1By
b3RvUAFaXGNsb3VkLmdvb2dsZS5jb20vZ28vY2xvdWRjb250cm9sc3BhcnRuZXIvYXBpdjEv
Y2xvdWRjb250cm9sc3BhcnRuZXJwYjtjbG91ZGNvbnRyb2xzcGFydG5lcnBiqgIkR29vZ2xl
LkNsb3VkLkNsb3VkQ29udHJvbHNQYXJ0bmVyLlYxygIkR29vZ2xlXENsb3VkXENsb3VkQ29u
dHJvbHNQYXJ0bmVyXFYx6gInR29vZ2xlOjpDbG91ZDo6Q2xvdWRDb250cm9sc1BhcnRuZXI6
OlYxSoQWCgYSBA4AYAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQAC0KCQoCAwASAxIAKQoJCgIDARIDEwAjCggKAQgSAxUAQQoJCgIIJRIDFQBBCggKAQgS
AxYAcwoJCgIICxIDFgBzCggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgANAoJCgIICBID
GAA0CggKAQgSAxkAQQoJCgIIARIDGQBBCggKAQgSAxoAQQoJCgIIKRIDGgBBCggKAQgSAxsA
QAoJCgIILRIDGwBACjwKAgQAEgQeACoBGjAgVGhlIEVLTSBjb25uZWN0aW9ucyBhc3NvY2lh
dGVkIHdpdGggYSB3b3JrbG9hZAoKCgoDBAABEgMeCBYKCwoDBAAHEgQfAiIECg0KBQQAB50I
EgQfAiIECpEBCgQEAAIAEgMmAj0agwEgSWRlbnRpZmllci4gRm9ybWF0OgogYG9yZ2FuaXph
dGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY3VzdG9tZXJzL3tj
dXN0b21lcn0vd29ya2xvYWRzL3t3b3JrbG9hZH0vZWttQ29ubmVjdGlvbnNgCgoMCgUEAAIA
BRIDJgIICgwKBQQAAgABEgMmCQ0KDAoFBAACAAMSAyYQEQoMCgUEAAIACBIDJhI8Cg8KCAQA
AgAInAgAEgMmEzsKPwoEBAACARIDKQItGjIgVGhlIEVLTSBjb25uZWN0aW9ucyBhc3NvY2lh
dGVkIHdpdGggdGhlIHdvcmtsb2FkCgoMCgUEAAIBBBIDKQIKCgwKBQQAAgEGEgMpCxgKDAoF
BAACAQESAykZKAoMCgUEAAIBAxIDKSssClAKAgQBEgQtADYBGkQgUmVxdWVzdCBmb3IgZ2V0
dGluZyB0aGUgRUtNIGNvbm5lY3Rpb25zIGFzc29jaWF0ZWQgd2l0aCBhIHdvcmtsb2FkCgoK
CgMEAQESAy0IIAqQAQoEBAECABIEMAI1BBqBASBSZXF1aXJlZC4gRm9ybWF0OgogYG9yZ2Fu
aXphdGlvbnMve29yZ2FuaXphdGlvbn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY3VzdG9tZXJz
L3tjdXN0b21lcn0vd29ya2xvYWRzL3t3b3JrbG9hZH0vZWttQ29ubmVjdGlvbnNgCgoMCgUE
AQIABRIDMAIICgwKBQQBAgABEgMwCQ0KDAoFBAECAAMSAzAQEQoNCgUEAQIACBIEMBI1AwoP
CggEAQIACJwIABIDMQQqCg8KBwQBAgAInwgSBDIENAUKLgoCBAISBDkAYAEaIiBEZXRhaWxz
IGFib3V0IHRoZSBFS00gY29ubmVjdGlvbgoKCgoDBAIBEgM5CBUKgwEKBAQCAwASBDwCQgMa
dSBJbmZvcm1hdGlvbiBhcm91bmQgdGhlIGVycm9yIHRoYXQgb2NjdXJyZWQgaWYgdGhlIGNv
bm5lY3Rpb24gc3RhdGUgaXMKIGFueXRoaW5nIG90aGVyIHRoYW4gYXZhaWxhYmxlIG9yIHVu
c3BlY2lmaWVkCgoMCgUEAgMAARIDPAoZCi8KBgQCAwACABIDPgQcGiAgVGhlIGVycm9yIGRv
bWFpbiBmb3IgdGhlIGVycm9yCgoOCgcEAgMAAgAFEgM+BAoKDgoHBAIDAAIAARIDPgsXCg4K
BwQCAwACAAMSAz4aGwowCgYEAgMAAgESA0EEHRohIFRoZSBlcnJvciBtZXNzYWdlIGZvciB0
aGUgZXJyb3IKCg4KBwQCAwACAQUSA0EECgoOCgcEAgMAAgEBEgNBCxgKDgoHBAIDAAIBAxID
QRscCikKBAQCBAASBEUCVAMaGyBUaGUgRUtNIGNvbm5lY3Rpb24gc3RhdGUuCgoMCgUEAgQA
ARIDRQcWCjEKBgQCBAACABIDRwQlGiIgVW5zcGVjaWZpZWQgRUtNIGNvbm5lY3Rpb24gc3Rh
dGUKCg4KBwQCBAACAAESA0cEIAoOCgcEAgQAAgACEgNHIyQKLwoGBAIEAAIBEgNKBBIaICBB
dmFpbGFibGUgRUtNIGNvbm5lY3Rpb24gc3RhdGUKCg4KBwQCBAACAQESA0oEDQoOCgcEAgQA
AgECEgNKEBEKMwoGBAIEAAICEgNNBBYaJCBOb3QgYXZhaWxhYmxlIEVLTSBjb25uZWN0aW9u
IHN0YXRlCgoOCgcEAgQAAgIBEgNNBBEKDgoHBAIEAAICAhIDTRQVCisKBgQCBAACAxIDUAQO
GhwgRXJyb3IgRUtNIGNvbm5lY3Rpb24gc3RhdGUKCg4KBwQCBAACAwESA1AECQoOCgcEAgQA
AgMCEgNQDA0KNwoGBAIEAAIEEgNTBBoaKCBQZXJtaXNzaW9uIGRlbmllZCBFS00gY29ubmVj
dGlvbiBzdGF0ZQoKDgoHBAIEAAIEARIDUwQVCg4KBwQCBAACBAISA1MYGQqKAQoEBAICABID
WAIdGn0gUmVzb3VyY2UgbmFtZSBvZiB0aGUgRUtNIGNvbm5lY3Rpb24gaW4gdGhlIGZvcm1h
dDoKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9la21Db25uZWN0
aW9ucy97ZWttX2Nvbm5lY3Rpb259CgoMCgUEAgIABRIDWAIICgwKBQQCAgABEgNYCRgKDAoF
BAICAAMSA1gbHAoxCgQEAgIBEgRbAlwyGiMgT3V0cHV0IG9ubHkuIFRoZSBjb25uZWN0aW9u
IHN0YXRlCgoMCgUEAgIBBhIDWwIRCgwKBQQCAgEBEgNbEiIKDAoFBAICAQMSA1slJgoMCgUE
AgIBCBIDXAYxCg8KCAQCAgEInAgAEgNcBzAKOAoEBAICAhIDXwInGisgVGhlIGNvbm5lY3Rp
b24gZXJyb3IgdGhhdCBvY2N1cnJlZCBpZiBhbnkKCgwKBQQCAgIGEgNfAhEKDAoFBAICAgES
A18SIgoMCgUEAgICAxIDXyUmYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::EkmConnections ===
    # Fields for EkmConnections
    # Field: name Type: 9 ()
    # Field: ekm_connections Type: 11 (.google.cloud.cloudcontrolspartner.v1.EkmConnection)

# === Message: Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::GetEkmConnectionsRequest ===
    # Fields for GetEkmConnectionsRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::EkmConnection ===
    # Fields for EkmConnection
    # Field: connection_name Type: 9 ()
    # Field: connection_state Type: 14 (.google.cloud.cloudcontrolspartner.v1.EkmConnection.ConnectionState)
    # Field: connection_error Type: 11 (.google.cloud.cloudcontrolspartner.v1.EkmConnection.ConnectionError)

# Enum: EkmConnection::ConnectionState
our $EkmConnection_CONNECTION_STATE_UNSPECIFIED = 0;
our $EkmConnection_AVAILABLE = 1;
our $EkmConnection_NOT_AVAILABLE = 2;
our $EkmConnection_ERROR = 3;
our $EkmConnection_PERMISSION_DENIED = 4;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Cloudcontrolspartner::V1::EkmConnections - Compiled Protocol Buffers messages for google/cloud/cloudcontrolspartner/v1/ekm_connections.proto

=head1 SYNOPSIS

    use Google::Cloud::Cloudcontrolspartner::V1::EkmConnections;

    my $msg = Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::EkmConnections->new({
        name => $name,
        ekm_connections => $ekm_connections,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::EkmConnections->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/cloudcontrolspartner/v1/ekm_connections.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::EkmConnections

The EKM connections associated with a workload

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Format:
`organizations/{organization}/locations/{location}/customers/{customer}/workloads/{workload}/ekmConnections`

=item * C<< $msg->ekm_connections() >> / C<< $msg->ekm_connections($value) >>

Type: C<Message> (L<Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::EkmConnection>)

The EKM connections associated with the workload

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::GetEkmConnectionsRequest

Request for getting the EKM connections associated with a workload

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Format:
`organizations/{organization}/locations/{location}/customers/{customer}/workloads/{workload}/ekmConnections`

=back

=head2 Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::EkmConnection

Details about the EKM connection

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->connection_name() >> / C<< $msg->connection_name($value) >>

Type: C<String>

Resource name of the EKM connection in the format:
projects/{project}/locations/{location}/ekmConnections/{ekm_connection}

=item * C<< $msg->connection_state() >> / C<< $msg->connection_state($value) >>

Type: C<Enum> (L<Google::Cloud::Cloudcontrolspartner::V1::EkmConnection::ConnectionState>)

Output only. The connection state

=item * C<< $msg->connection_error() >> / C<< $msg->connection_error($value) >>

Type: C<Message> (L<Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::EkmConnection::ConnectionError>)

The connection error that occurred if any

=back

=head3 Enum: EkmConnection::ConnectionState

=over 4

=item * C<CONNECTION_STATE_UNSPECIFIED> => C<0>

=item * C<AVAILABLE> => C<1>

=item * C<NOT_AVAILABLE> => C<2>

=item * C<ERROR> => C<3>

=item * C<PERMISSION_DENIED> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Cloudcontrolspartner::V1::EkmConnections::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
