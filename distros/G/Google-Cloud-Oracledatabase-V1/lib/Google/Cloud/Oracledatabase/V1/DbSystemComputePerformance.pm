package Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance;

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
    eval { require Google::Cloud::Oracledatabase::V1::Common };
    my $descriptor_b64 = <<'EOF';
CkJnb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvZGJfc3lzdGVtX2NvbXB1dGVfcGVy
Zm9ybWFuY2UucHJvdG8SHmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MRofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxor
Z29vZ2xlL2Nsb3VkL29yYWNsZWRhdGFiYXNlL3YxL2NvbW1vbi5wcm90byKbAwoaRGJTeXN0
ZW1Db21wdXRlUGVyZm9ybWFuY2USFwoEbmFtZRgBIAEoCUID4EEIUgRuYW1lEhkKBXNoYXBl
GAIgASgJQgPgQQNSBXNoYXBlEmoKFGNvbXB1dGVfcGVyZm9ybWFuY2VzGAMgAygLMjIuZ29v
Z2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLkNvbXB1dGVQZXJmb3JtYW5jZUID4EEDUhNj
b21wdXRlUGVyZm9ybWFuY2VzOtwB6kHYAQo4b3JhY2xlZGF0YWJhc2UuZ29vZ2xlYXBpcy5j
b20vRGJTeXN0ZW1Db21wdXRlUGVyZm9ybWFuY2USY3Byb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9kYlN5c3RlbUNvbXB1dGVQZXJmb3JtYW5jZXMve2RiX3N5c3Rl
bV9jb21wdXRlX3BlcmZvcm1hbmNlfSobZGJTeXN0ZW1Db21wdXRlUGVyZm9ybWFuY2VzMhpk
YlN5c3RlbUNvbXB1dGVQZXJmb3JtYW5jZSLqAQoSQ29tcHV0ZVBlcmZvcm1hbmNlEikKDmNw
dV9jb3JlX2NvdW50GAEgASgFQgPgQQNSDGNwdUNvcmVDb3VudBJWCg1jb21wdXRlX21vZGVs
GAIgASgOMiwuZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLkNvbXB1dGVNb2RlbEID
4EEDUgxjb21wdXRlTW9kZWwSKAoNY29tcHV0ZV9jb3VudBgDIAEoBUID4EEDUgxjb21wdXRl
Q291bnQSJwoNbWVtb3J5X2luX2dicxgEIAEoAUID4EEDUgttZW1vcnlJbkdicyLlAQomTGlz
dERiU3lzdGVtQ29tcHV0ZVBlcmZvcm1hbmNlc1JlcXVlc3QSWAoGcGFyZW50GAEgASgJQkDg
QQL6QToSOG9yYWNsZWRhdGFiYXNlLmdvb2dsZWFwaXMuY29tL0RiU3lzdGVtQ29tcHV0ZVBl
cmZvcm1hbmNlUgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIK
CnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEB
UgZmaWx0ZXIi+QEKJ0xpc3REYlN5c3RlbUNvbXB1dGVQZXJmb3JtYW5jZXNSZXNwb25zZRJ/
Ch5kYl9zeXN0ZW1fY29tcHV0ZV9wZXJmb3JtYW5jZXMYASADKAsyOi5nb29nbGUuY2xvdWQu
b3JhY2xlZGF0YWJhc2UudjEuRGJTeXN0ZW1Db21wdXRlUGVyZm9ybWFuY2VSG2RiU3lzdGVt
Q29tcHV0ZVBlcmZvcm1hbmNlcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdl
VG9rZW4SJQoLdW5yZWFjaGFibGUYAyADKAlCA+BBBlILdW5yZWFjaGFibGVC+QEKImNvbS5n
b29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjFCH0RiU3lzdGVtQ29tcHV0ZVBlcmZvcm1h
bmNlUHJvdG9QAVpKY2xvdWQuZ29vZ2xlLmNvbS9nby9vcmFjbGVkYXRhYmFzZS9hcGl2MS9v
cmFjbGVkYXRhYmFzZXBiO29yYWNsZWRhdGFiYXNlcGKqAh5Hb29nbGUuQ2xvdWQuT3JhY2xl
RGF0YWJhc2UuVjHKAh5Hb29nbGVcQ2xvdWRcT3JhY2xlRGF0YWJhc2VcVjHqAiFHb29nbGU6
OkNsb3VkOjpPcmFjbGVEYXRhYmFzZTo6VjFK3hwKBhIEDgBoAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoC
AwISAxQANQoICgEIEgMWADsKCQoCCCUSAxYAOwoICgEIEgMXAGEKCQoCCAsSAxcAYQoICgEI
EgMYACIKCQoCCAoSAxgAIgoICgEIEgMZAEAKCQoCCAgSAxkAQAoICgEIEgMaADsKCQoCCAES
AxoAOwoICgEIEgMbADsKCQoCCCkSAxsAOwoICgEIEgMcADoKCQoCCC0SAxwAOgpDCgIEABIE
HwAzARo3IERldGFpbHMgb2YgdGhlIERiU3lzdGVtIGNvbXB1dGUgcGVyZm9ybWFuY2UgcmVz
b3VyY2UuCgoKCgMEAAESAx8IIgoLCgMEAAcSBCACJQQKDQoFBAAHnQgSBCACJQQKxgEKBAQA
AgASAyoCPRq4ASBJZGVudGlmaWVyLiBUaGUgbmFtZSBvZiB0aGUgRGJTeXN0ZW1Db21wdXRl
UGVyZm9ybWFuY2UgcmVzb3VyY2Ugd2l0aCB0aGUKIGZvcm1hdDoKIHByb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9kYlN5c3RlbUNvbXB1dGVQZXJmb3JtYW5jZXMv
e2RiX3N5c3RlbV9jb21wdXRlX3BlcmZvcm1hbmNlfQoKDAoFBAACAAUSAyoCCAoMCgUEAAIA
ARIDKgkNCgwKBQQAAgADEgMqEBEKDAoFBAACAAgSAyoSPAoPCggEAAIACJwIABIDKhM7CjcK
BAQAAgESAy0CPxoqIE91dHB1dCBvbmx5LiBUaGUgc2hhcGUgb2YgdGhlIERCIHN5c3RlbS4K
CgwKBQQAAgEFEgMtAggKDAoFBAACAQESAy0JDgoMCgUEAAIBAxIDLRESCgwKBQQAAgEIEgMt
Ez4KDwoIBAACAQicCAASAy0UPQpkCgQEAAICEgQxAjIyGlYgT3V0cHV0IG9ubHkuIExpc3Qg
b2YgQ29tcHV0ZSBwZXJmb3JtYW5jZSBkZXRhaWxzIGZvciB0aGUgc3BlY2lmaWVkIERCCiBz
eXN0ZW0gc2hhcGUuCgoMCgUEAAICBBIDMQIKCgwKBQQAAgIGEgMxCx0KDAoFBAACAgESAzEe
MgoMCgUEAAICAxIDMTU2CgwKBQQAAgIIEgMyBjEKDwoIBAACAgicCAASAzIHMApbCgIEARIE
NgBCARpPIFBhcmFtZXRlcnMgZGV0YWlsaW5nIHRoZSBjb21wdXRlIHBlcmZvcm1hbmNlIGZv
ciBhIHNwZWNpZmllZCBEQiBzeXN0ZW0gc2hhcGUuCgoKCgMEAQESAzYIGgo+CgQEAQIAEgM4
AkcaMSBPdXRwdXQgb25seS4gVGhlIG51bWJlciBvZiBDUFUgY29yZXMgYXZhaWxhYmxlLgoK
DAoFBAECAAUSAzgCBwoMCgUEAQIAARIDOAgWCgwKBQQBAgADEgM4GRoKDAoFBAECAAgSAzgb
RgoPCggEAQIACJwIABIDOBxFCkgKBAQBAgESAzsCTRo7IE91dHB1dCBvbmx5LiBUaGUgY29t
cHV0ZSBtb2RlbCBmb3IgQmFzZSBEYXRhYmFzZSBTZXJ2aWNlLgoKDAoFBAECAQYSAzsCDgoM
CgUEAQIBARIDOw8cCgwKBQQBAgEDEgM7HyAKDAoFBAECAQgSAzshTAoPCggEAQIBCJwIABID
OyJLCkwKBAQBAgISAz4CRho/IE91dHB1dCBvbmx5LiBUaGUgbnVtYmVyIG9mIGNvbXB1dGUg
c2VydmVycyBmb3IgdGhlIERCIHN5c3RlbS4KCgwKBQQBAgIFEgM+AgcKDAoFBAECAgESAz4I
FQoMCgUEAQICAxIDPhgZCgwKBQQBAgIIEgM+GkUKDwoIBAECAgicCAASAz4bRApWCgQEAQID
EgNBAkcaSSBPdXRwdXQgb25seS4gVGhlIGFtb3VudCBvZiBtZW1vcnkgYWxsb2NhdGVkIGZv
ciB0aGUgVk1EQiBTeXN0ZW0gaW4gR0JzLgoKDAoFBAECAwUSA0ECCAoMCgUEAQIDARIDQQkW
CgwKBQQBAgMDEgNBGRoKDAoFBAECAwgSA0EbRgoPCggEAQIDCJwIABIDQRxFCj4KAgQCEgRF
AFoBGjIgTWVzc2FnZSBmb3IgbGlzdGluZyBEYlN5c3RlbUNvbXB1dGVQZXJmb3JtYW5jZXMu
CgoKCgMEAgESA0UILgqCAQoEBAICABIESAJNBBp0IFJlcXVpcmVkLiBQYXJlbnQgdmFsdWUg
Zm9yIExpc3REYlN5c3RlbUNvbXB1dGVQZXJmb3JtYW5jZXNSZXF1ZXN0CiBGb3JtYXQ6IHBy
b2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufQoKDAoFBAICAAUSA0gCCAoM
CgUEAgIAARIDSAkPCgwKBQQCAgADEgNIEhMKDQoFBAICAAgSBEgUTQMKDwoIBAICAAicCAAS
A0kEKgoPCgcEAgIACJ8IEgRKBEwFCpYBCgQEAgIBEgNRAj8aiAEgT3B0aW9uYWwuIFJlcXVl
c3RlZCBwYWdlIHNpemUuIFNlcnZlciBtYXkgcmV0dXJuIGZld2VyIGl0ZW1zIHRoYW4KIHJl
cXVlc3RlZC4gSWYgdW5zcGVjaWZpZWQsIHNlcnZlciB3aWxsIHBpY2sgYW4gYXBwcm9wcmlh
dGUgZGVmYXVsdC4KCgwKBQQCAgEFEgNRAgcKDAoFBAICAQESA1EIEQoMCgUEAgIBAxIDURQV
CgwKBQQCAgEIEgNRFj4KDwoIBAICAQicCAASA1EXPQpYCgQEAgICEgNUAkEaSyBPcHRpb25h
bC4gQSB0b2tlbiBpZGVudGlmeWluZyBhIHBhZ2Ugb2YgcmVzdWx0cyB0aGUgc2VydmVyIHNo
b3VsZCByZXR1cm4uCgoMCgUEAgICBRIDVAIICgwKBQQCAgIBEgNUCRMKDAoFBAICAgMSA1QW
FwoMCgUEAgICCBIDVBhACg8KCAQCAgIInAgAEgNUGT8KwQEKBAQCAgMSA1kCPRqzASBPcHRp
b25hbC4gQW4gZXhwcmVzc2lvbiBmb3IgZmlsdGVyaW5nIHRoZSByZXN1bHRzIG9mIHRoZSBy
ZXF1ZXN0LiBPbmx5IHRoZQogYGRiX3N5c3RlbV9zaGFwZWAgZmllbGQgaXMgc3VwcG9ydGVk
IGluIHRoZSBmb2xsb3dpbmcgZm9ybWF0OgogYGRiX3N5c3RlbV9zaGFwZT0ie2RiX3N5c3Rl
bV9zaGFwZX0iYC4KCgwKBQQCAgMFEgNZAggKDAoFBAICAwESA1kJDwoMCgUEAgIDAxIDWRIT
CgwKBQQCAgMIEgNZFDwKDwoIBAICAwicCAASA1kVOwpJCgIEAxIEXQBoARo9IE1lc3NhZ2Ug
Zm9yIHJlc3BvbnNlIHRvIGxpc3RpbmcgRGJTeXN0ZW1Db21wdXRlUGVyZm9ybWFuY2VzCgoK
CgMEAwESA10ILwo2CgQEAwIAEgNfAkkaKSBUaGUgbGlzdCBvZiBEYlN5c3RlbUNvbXB1dGVQ
ZXJmb3JtYW5jZS4KCgwKBQQDAgAEEgNfAgoKDAoFBAMCAAYSA18LJQoMCgUEAwIAARIDXyZE
CgwKBQQDAgADEgNfR0gKjwEKBAQDAgESA2MCHRqBASBBIHRva2VuLCB3aGljaCBjYW4gYmUg
c2VudCBhcyBgcGFnZV90b2tlbmAgdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZS4KIElmIHRo
aXMgZmllbGQgaXMgb21pdHRlZCwgdGhlcmUgYXJlIG5vIHN1YnNlcXVlbnQgcGFnZXMuCgoM
CgUEAwIBBRIDYwIICgwKBQQDAgEBEgNjCRgKDAoFBAMCAQMSA2MbHApECgQEAwICEgRmAmc1
GjYgVW5vcmRlcmVkIGxpc3QuIExvY2F0aW9ucyB0aGF0IGNvdWxkIG5vdCBiZSByZWFjaGVk
LgoKDAoFBAMCAgQSA2YCCgoMCgUEAwICBRIDZgsRCgwKBQQDAgIBEgNmEh0KDAoFBAMCAgMS
A2YgIQoMCgUEAwICCBIDZwY0Cg8KCAQDAgIInAgAEgNnBzNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::DbSystemComputePerformance ===
    # Fields for DbSystemComputePerformance
    # Field: name Type: 9 ()
    # Field: shape Type: 9 ()
    # Field: compute_performances Type: 11 (.google.cloud.oracledatabase.v1.ComputePerformance)

# === Message: Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::ComputePerformance ===
    # Fields for ComputePerformance
    # Field: cpu_core_count Type: 5 ()
    # Field: compute_model Type: 14 (.google.cloud.oracledatabase.v1.ComputeModel)
    # Field: compute_count Type: 5 ()
    # Field: memory_in_gbs Type: 1 ()

# === Message: Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::ListDbSystemComputePerformancesRequest ===
    # Fields for ListDbSystemComputePerformancesRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::ListDbSystemComputePerformancesResponse ===
    # Fields for ListDbSystemComputePerformancesResponse
    # Field: db_system_compute_performances Type: 11 (.google.cloud.oracledatabase.v1.DbSystemComputePerformance)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/db_system_compute_performance.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance;

    my $msg = Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::DbSystemComputePerformance->new({
        name => $name,
        shape => $shape,
        compute_performances => $compute_performances,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::DbSystemComputePerformance->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/db_system_compute_performance.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::DbSystemComputePerformance

Details of the DbSystem compute performance resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the DbSystemComputePerformance resource with the
format:
projects/{project}/locations/{location}/dbSystemComputePerformances/{db_system_compute_performance}

=item * C<< $msg->shape() >> / C<< $msg->shape($value) >>

Type: C<String>

Output only. The shape of the DB system.

=item * C<< $msg->compute_performances() >> / C<< $msg->compute_performances($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::ComputePerformance>)

Output only. List of Compute performance details for the specified DB
system shape.

=back

=head2 Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::ComputePerformance

Parameters detailing the compute performance for a specified DB system shape.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cpu_core_count() >> / C<< $msg->cpu_core_count($value) >>

Type: C<Int32>

Output only. The number of CPU cores available.

=item * C<< $msg->compute_model() >> / C<< $msg->compute_model($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::ComputeModel>)

Output only. The compute model for Base Database Service.

=item * C<< $msg->compute_count() >> / C<< $msg->compute_count($value) >>

Type: C<Int32>

Output only. The number of compute servers for the DB system.

=item * C<< $msg->memory_in_gbs() >> / C<< $msg->memory_in_gbs($value) >>

Type: C<Double>

Output only. The amount of memory allocated for the VMDB System in GBs.

=back

=head2 Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::ListDbSystemComputePerformancesRequest

Message for listing DbSystemComputePerformances.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent value for ListDbSystemComputePerformancesRequest
Format: projects/{project}/locations/{location}

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. Requested page size. Server may return fewer items than
requested. If unspecified, server will pick an appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A token identifying a page of results the server should return.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. An expression for filtering the results of the request. Only the
`db_system_shape` field is supported in the following format:
`db_system_shape="{db_system_shape}"`.

=back

=head2 Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::ListDbSystemComputePerformancesResponse

Message for response to listing DbSystemComputePerformances

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->db_system_compute_performances() >> / C<< $msg->db_system_compute_performances($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::DbSystemComputePerformance>)

The list of DbSystemComputePerformance.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token, which can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Unordered list. Locations that could not be reached.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
