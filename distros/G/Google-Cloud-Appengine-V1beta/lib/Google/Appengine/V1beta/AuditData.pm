package Google::Appengine::V1beta::AuditData;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Appengine::V1beta::Appengine };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvYXBwZW5naW5lL3YxYmV0YS9hdWRpdF9kYXRhLnByb3RvEhdnb29nbGUuYXBw
ZW5naW5lLnYxYmV0YRonZ29vZ2xlL2FwcGVuZ2luZS92MWJldGEvYXBwZW5naW5lLnByb3Rv
IsMBCglBdWRpdERhdGESVQoOdXBkYXRlX3NlcnZpY2UYASABKAsyLC5nb29nbGUuYXBwZW5n
aW5lLnYxYmV0YS5VcGRhdGVTZXJ2aWNlTWV0aG9kSABSDXVwZGF0ZVNlcnZpY2USVQoOY3Jl
YXRlX3ZlcnNpb24YAiABKAsyLC5nb29nbGUuYXBwZW5naW5lLnYxYmV0YS5DcmVhdGVWZXJz
aW9uTWV0aG9kSABSDWNyZWF0ZVZlcnNpb25CCAoGbWV0aG9kIl4KE1VwZGF0ZVNlcnZpY2VN
ZXRob2QSRwoHcmVxdWVzdBgBIAEoCzItLmdvb2dsZS5hcHBlbmdpbmUudjFiZXRhLlVwZGF0
ZVNlcnZpY2VSZXF1ZXN0UgdyZXF1ZXN0Il4KE0NyZWF0ZVZlcnNpb25NZXRob2QSRwoHcmVx
dWVzdBgBIAEoCzItLmdvb2dsZS5hcHBlbmdpbmUudjFiZXRhLkNyZWF0ZVZlcnNpb25SZXF1
ZXN0UgdyZXF1ZXN0QtQBChtjb20uZ29vZ2xlLmFwcGVuZ2luZS52MWJldGFCDkF1ZGl0RGF0
YVByb3RvUAFaQGdvb2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvYXBwZW5n
aW5lL3YxYmV0YTthcHBlbmdpbmWqAh1Hb29nbGUuQ2xvdWQuQXBwRW5naW5lLlYxQmV0YcoC
HUdvb2dsZVxDbG91ZFxBcHBFbmdpbmVcVjFiZXRh6gIgR29vZ2xlOjpDbG91ZDo6QXBwRW5n
aW5lOjpWMWJldGFK2gwKBhIEDgA1AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAIAoJCgIDABIDEgAxCggKAQgSAxQAOgoJCgIIJRIDFAA6CggKAQgSAxUA
VwoJCgIICxIDFQBXCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcALwoJCgIICBIDFwAv
CggKAQgSAxgANAoJCgIIARIDGAA0CggKAQgSAxkAOgoJCgIIKRIDGQA6CggKAQgSAxoAOQoJ
CgIILRIDGgA5CjEKAgQAEgQdACkBGiUgQXBwIEVuZ2luZSBhZG1pbiBzZXJ2aWNlIGF1ZGl0
IGxvZy4KCgoKAwQAARIDHQgRCpECCgQEAAgAEgQiAigDGoICIERldGFpbGVkIGluZm9ybWF0
aW9uIGFib3V0IG1ldGhvZHMgdGhhdCByZXF1aXJlIGl0LiBEb2VzIG5vdCBpbmNsdWRlCiBz
aW1wbGUgR2V0LCBMaXN0IG9yIERlbGV0ZSBtZXRob2RzIGJlY2F1c2UgYWxsIHNpZ25pZmlj
YW50IGluZm9ybWF0aW9uCiAocmVzb3VyY2UgbmFtZSwgbnVtYmVyIG9mIHJldHVybmVkIGVs
ZW1lbnRzIGZvciBMaXN0IG9wZXJhdGlvbnMpIGlzIGFscmVhZHkKIGluY2x1ZGVkIGluIHBh
cmVudCBhdWRpdCBsb2cgbWVzc2FnZS4KCgwKBQQACAABEgMiCA4KPQoEBAACABIDJAQrGjAg
RGV0YWlsZWQgaW5mb3JtYXRpb24gYWJvdXQgVXBkYXRlU2VydmljZSBjYWxsLgoKDAoFBAAC
AAYSAyQEFwoMCgUEAAIAARIDJBgmCgwKBQQAAgADEgMkKSoKPQoEBAACARIDJwQrGjAgRGV0
YWlsZWQgaW5mb3JtYXRpb24gYWJvdXQgQ3JlYXRlVmVyc2lvbiBjYWxsLgoKDAoFBAACAQYS
AycEFwoMCgUEAAIBARIDJxgmCgwKBQQAAgEDEgMnKSoKPAoCBAESBCwALwEaMCBEZXRhaWxl
ZCBpbmZvcm1hdGlvbiBhYm91dCBVcGRhdGVTZXJ2aWNlIGNhbGwuCgoKCgMEAQESAywIGwom
CgQEAQIAEgMuAiMaGSBVcGRhdGUgc2VydmljZSByZXF1ZXN0LgoKDAoFBAECAAYSAy4CFgoM
CgUEAQIAARIDLhceCgwKBQQBAgADEgMuISIKPAoCBAISBDIANQEaMCBEZXRhaWxlZCBpbmZv
cm1hdGlvbiBhYm91dCBDcmVhdGVWZXJzaW9uIGNhbGwuCgoKCgMEAgESAzIIGwomCgQEAgIA
EgM0AiMaGSBDcmVhdGUgdmVyc2lvbiByZXF1ZXN0LgoKDAoFBAICAAYSAzQCFgoMCgUEAgIA
ARIDNBceCgwKBQQCAgADEgM0ISJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1beta::AuditData::AuditData ===
    # Fields for AuditData
    # Field: update_service Type: 11 (.google.appengine.v1beta.UpdateServiceMethod)
    # Field: create_version Type: 11 (.google.appengine.v1beta.CreateVersionMethod)

# === Message: Google::Appengine::V1beta::AuditData::UpdateServiceMethod ===
    # Fields for UpdateServiceMethod
    # Field: request Type: 11 (.google.appengine.v1beta.UpdateServiceRequest)

# === Message: Google::Appengine::V1beta::AuditData::CreateVersionMethod ===
    # Fields for CreateVersionMethod
    # Field: request Type: 11 (.google.appengine.v1beta.CreateVersionRequest)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1beta::AuditData - Compiled Protocol Buffers messages for google/appengine/v1beta/audit_data.proto

=head1 SYNOPSIS

    use Google::Appengine::V1beta::AuditData;

    my $msg = Google::Appengine::V1beta::AuditData::AuditData->new({
        update_service => $update_service,
        create_version => $create_version,
    });

    # Read or update a field
    my $val = $msg->update_service();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1beta::AuditData::AuditData->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1beta/audit_data.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1beta::AuditData::AuditData

App Engine admin service audit log.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_service() >> / C<< $msg->update_service($value) >>

Type: C<Message> (L<Google::Appengine::V1beta::AuditData::UpdateServiceMethod>)

Detailed information about UpdateService call.

=item * C<< $msg->create_version() >> / C<< $msg->create_version($value) >>

Type: C<Message> (L<Google::Appengine::V1beta::AuditData::CreateVersionMethod>)

Detailed information about CreateVersion call.

=back

=head2 Google::Appengine::V1beta::AuditData::UpdateServiceMethod

Detailed information about UpdateService call.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->request() >> / C<< $msg->request($value) >>

Type: C<Message> (L<Google::Appengine::V1beta::Appengine::UpdateServiceRequest>)

Update service request.

=back

=head2 Google::Appengine::V1beta::AuditData::CreateVersionMethod

Detailed information about CreateVersion call.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->request() >> / C<< $msg->request($value) >>

Type: C<Message> (L<Google::Appengine::V1beta::Appengine::CreateVersionRequest>)

Create version request.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1beta::AuditData::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
