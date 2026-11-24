package Google::Appengine::V1::AuditData;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Appengine::V1::Appengine };
    my $descriptor_b64 = <<'EOF';
CiRnb29nbGUvYXBwZW5naW5lL3YxL2F1ZGl0X2RhdGEucHJvdG8SE2dvb2dsZS5hcHBlbmdp
bmUudjEaI2dvb2dsZS9hcHBlbmdpbmUvdjEvYXBwZW5naW5lLnByb3RvIrsBCglBdWRpdERh
dGESUQoOdXBkYXRlX3NlcnZpY2UYASABKAsyKC5nb29nbGUuYXBwZW5naW5lLnYxLlVwZGF0
ZVNlcnZpY2VNZXRob2RIAFINdXBkYXRlU2VydmljZRJRCg5jcmVhdGVfdmVyc2lvbhgCIAEo
CzIoLmdvb2dsZS5hcHBlbmdpbmUudjEuQ3JlYXRlVmVyc2lvbk1ldGhvZEgAUg1jcmVhdGVW
ZXJzaW9uQggKBm1ldGhvZCJaChNVcGRhdGVTZXJ2aWNlTWV0aG9kEkMKB3JlcXVlc3QYASAB
KAsyKS5nb29nbGUuYXBwZW5naW5lLnYxLlVwZGF0ZVNlcnZpY2VSZXF1ZXN0UgdyZXF1ZXN0
IloKE0NyZWF0ZVZlcnNpb25NZXRob2QSQwoHcmVxdWVzdBgBIAEoCzIpLmdvb2dsZS5hcHBl
bmdpbmUudjEuQ3JlYXRlVmVyc2lvblJlcXVlc3RSB3JlcXVlc3RCvwEKF2NvbS5nb29nbGUu
YXBwZW5naW5lLnYxQg5BdWRpdERhdGFQcm90b1ABWjtjbG91ZC5nb29nbGUuY29tL2dvL2Fw
cGVuZ2luZS9hcGl2MS9hcHBlbmdpbmVwYjthcHBlbmdpbmVwYqoCGUdvb2dsZS5DbG91ZC5B
cHBFbmdpbmUuVjHKAhlHb29nbGVcQ2xvdWRcQXBwRW5naW5lXFYx6gIcR29vZ2xlOjpDbG91
ZDo6QXBwRW5naW5lOjpWMUraDAoGEgQOADUBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAcCgkKAgMAEgMSAC0KCAoBCBIDFAA2CgkKAgglEgMUADYKCAoB
CBIDFQBSCgkKAggLEgMVAFIKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAvCgkKAggI
EgMXAC8KCAoBCBIDGAAwCgkKAggBEgMYADAKCAoBCBIDGQA2CgkKAggpEgMZADYKCAoBCBID
GgA1CgkKAggtEgMaADUKMQoCBAASBB0AKQEaJSBBcHAgRW5naW5lIGFkbWluIHNlcnZpY2Ug
YXVkaXQgbG9nLgoKCgoDBAABEgMdCBEKkQIKBAQACAASBCICKAMaggIgRGV0YWlsZWQgaW5m
b3JtYXRpb24gYWJvdXQgbWV0aG9kcyB0aGF0IHJlcXVpcmUgaXQuIERvZXMgbm90IGluY2x1
ZGUKIHNpbXBsZSBHZXQsIExpc3Qgb3IgRGVsZXRlIG1ldGhvZHMgYmVjYXVzZSBhbGwgc2ln
bmlmaWNhbnQgaW5mb3JtYXRpb24KIChyZXNvdXJjZSBuYW1lLCBudW1iZXIgb2YgcmV0dXJu
ZWQgZWxlbWVudHMgZm9yIExpc3Qgb3BlcmF0aW9ucykgaXMgYWxyZWFkeQogaW5jbHVkZWQg
aW4gcGFyZW50IGF1ZGl0IGxvZyBtZXNzYWdlLgoKDAoFBAAIAAESAyIIDgo9CgQEAAIAEgMk
BCsaMCBEZXRhaWxlZCBpbmZvcm1hdGlvbiBhYm91dCBVcGRhdGVTZXJ2aWNlIGNhbGwuCgoM
CgUEAAIABhIDJAQXCgwKBQQAAgABEgMkGCYKDAoFBAACAAMSAyQpKgo9CgQEAAIBEgMnBCsa
MCBEZXRhaWxlZCBpbmZvcm1hdGlvbiBhYm91dCBDcmVhdGVWZXJzaW9uIGNhbGwuCgoMCgUE
AAIBBhIDJwQXCgwKBQQAAgEBEgMnGCYKDAoFBAACAQMSAycpKgo8CgIEARIELAAvARowIERl
dGFpbGVkIGluZm9ybWF0aW9uIGFib3V0IFVwZGF0ZVNlcnZpY2UgY2FsbC4KCgoKAwQBARID
LAgbCiYKBAQBAgASAy4CIxoZIFVwZGF0ZSBzZXJ2aWNlIHJlcXVlc3QuCgoMCgUEAQIABhID
LgIWCgwKBQQBAgABEgMuFx4KDAoFBAECAAMSAy4hIgo8CgIEAhIEMgA1ARowIERldGFpbGVk
IGluZm9ybWF0aW9uIGFib3V0IENyZWF0ZVZlcnNpb24gY2FsbC4KCgoKAwQCARIDMggbCiYK
BAQCAgASAzQCIxoZIENyZWF0ZSB2ZXJzaW9uIHJlcXVlc3QuCgoMCgUEAgIABhIDNAIWCgwK
BQQCAgABEgM0Fx4KDAoFBAICAAMSAzQhImIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1::AuditData::AuditData ===
    # Fields for AuditData
    # Field: update_service Type: 11 (.google.appengine.v1.UpdateServiceMethod)
    # Field: create_version Type: 11 (.google.appengine.v1.CreateVersionMethod)

# === Message: Google::Appengine::V1::AuditData::UpdateServiceMethod ===
    # Fields for UpdateServiceMethod
    # Field: request Type: 11 (.google.appengine.v1.UpdateServiceRequest)

# === Message: Google::Appengine::V1::AuditData::CreateVersionMethod ===
    # Fields for CreateVersionMethod
    # Field: request Type: 11 (.google.appengine.v1.CreateVersionRequest)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1::AuditData - Compiled Protocol Buffers messages for google/appengine/v1/audit_data.proto

=head1 SYNOPSIS

    use Google::Appengine::V1::AuditData;

    my $msg = Google::Appengine::V1::AuditData::AuditData->new({
        update_service => $update_service,
        create_version => $create_version,
    });

    # Read or update a field
    my $val = $msg->update_service();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1::AuditData::AuditData->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1/audit_data.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1::AuditData::AuditData

App Engine admin service audit log.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_service() >> / C<< $msg->update_service($value) >>

Type: C<Message> (L<Google::Appengine::V1::AuditData::UpdateServiceMethod>)

Detailed information about UpdateService call.

=item * C<< $msg->create_version() >> / C<< $msg->create_version($value) >>

Type: C<Message> (L<Google::Appengine::V1::AuditData::CreateVersionMethod>)

Detailed information about CreateVersion call.

=back

=head2 Google::Appengine::V1::AuditData::UpdateServiceMethod

Detailed information about UpdateService call.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->request() >> / C<< $msg->request($value) >>

Type: C<Message> (L<Google::Appengine::V1::Appengine::UpdateServiceRequest>)

Update service request.

=back

=head2 Google::Appengine::V1::AuditData::CreateVersionMethod

Detailed information about CreateVersion call.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->request() >> / C<< $msg->request($value) >>

Type: C<Message> (L<Google::Appengine::V1::Appengine::CreateVersionRequest>)

Create version request.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1::AuditData::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
