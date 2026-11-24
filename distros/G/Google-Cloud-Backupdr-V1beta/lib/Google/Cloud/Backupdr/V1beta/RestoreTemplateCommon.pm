package Google::Cloud::Backupdr::V1beta::RestoreTemplateCommon;

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
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvYmFja3VwZHIvdjFiZXRhL3Jlc3RvcmVfdGVtcGxhdGVfY29tbW9u
LnByb3RvEhxnb29nbGUuY2xvdWQuYmFja3VwZHIudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh5nb29nbGUvcHJv
dG9idWYvZHVyYXRpb24ucHJvdG8icwoVQmFja3VwU2VsZWN0aW9uQ29uZmlnElAKC2RhdGFf
c291cmNlGAEgASgJQi3gQQLgQQX6QSQKImJhY2t1cGRyLmdvb2dsZWFwaXMuY29tL0RhdGFT
b3VyY2VIAFIKZGF0YVNvdXJjZUIICgZzb3VyY2UipQEKEFByZVJlc3RvcmVDb25maWcSQQoN
Y2xvdWRfcnVuX2pvYhgCIAEoCUIb+kEYChZydW4uZ29vZ2xlYXBpcy5jb20vSm9iSABSC2Ns
b3VkUnVuSm9iEjgKB3RpbWVvdXQYASABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25C
A+BBAVIHdGltZW91dEIUChJwcmVfcmVzdG9yZV9hY3Rpb24ipwEKEVBvc3RSZXN0b3JlQ29u
ZmlnEkEKDWNsb3VkX3J1bl9qb2IYAiABKAlCG/pBGAoWcnVuLmdvb2dsZWFwaXMuY29tL0pv
YkgAUgtjbG91ZFJ1bkpvYhI4Cgd0aW1lb3V0GAEgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1
cmF0aW9uQgPgQQFSB3RpbWVvdXRCFQoTcG9zdF9yZXN0b3JlX2FjdGlvbiKoAQoSVmVyaWZp
Y2F0aW9uQ29uZmlnEkEKDWNsb3VkX3J1bl9qb2IYAiABKAlCG/pBGAoWcnVuLmdvb2dsZWFw
aXMuY29tL0pvYkgAUgtjbG91ZFJ1bkpvYhI4Cgd0aW1lb3V0GAEgASgLMhkuZ29vZ2xlLnBy
b3RvYnVmLkR1cmF0aW9uQgPgQQFSB3RpbWVvdXRCFQoTdmVyaWZpY2F0aW9uX2FjdGlvbkKt
AgogY29tLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGFCGlJlc3RvcmVUZW1wbGF0ZUNv
bW1vblByb3RvUAFaPGNsb3VkLmdvb2dsZS5jb20vZ28vYmFja3VwZHIvYXBpdjFiZXRhL2Jh
Y2t1cGRycGI7YmFja3VwZHJwYqoCHEdvb2dsZS5DbG91ZC5CYWNrdXBEUi5WMUJldGHKAhxH
b29nbGVcQ2xvdWRcQmFja3VwRFJcVjFiZXRh6gIfR29vZ2xlOjpDbG91ZDo6QmFja3VwRFI6
OlYxYmV0YepBTAoWcnVuLmdvb2dsZWFwaXMuY29tL0pvYhIycHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L2pvYnMve2pvYn1KgBUKBhIEDgBfAQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJQoJCgIDABIDEgApCgkKAgMBEgMT
ACMKCQoCAwISAxQAKAoICgEIEgMWADkKCQoCCCUSAxYAOQoICgEIEgMXAFMKCQoCCAsSAxcA
UwoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADsKCQoCCAgSAxkAOwoICgEIEgMaADkK
CQoCCAESAxoAOQoICgEIEgMbADkKCQoCCCkSAxsAOQoICgEIEgMcADgKCQoCCC0SAxwAOAoJ
CgEIEgQdACACCgwKBAidCAASBB0AIAIKMwoCBAASBCMALwEaJyBDb25maWd1cmF0aW9uIGZv
ciBzZWxlY3RpbmcgYSBiYWNrdXAuCgoKCgMEAAESAyMIHQo2CgQEAAgAEgQlAi4DGiggVGhl
IGZ1bGx5IHF1YWxpZmllZCBVUkkgb2YgdGhlIHNvdXJjZS4KCgwKBQQACAABEgMlCA4KWQoE
BAACABIEJwQtBhpLIFJlcXVpcmVkLiBJbW11dGFibGUuIFRoZSBmdWxseSBxdWFsaWZpZWQg
VVJJIG9mIHRoZSBiYWNrdXBkciBkYXRhIHNvdXJjZS4KCgwKBQQAAgAFEgMnBAoKDAoFBAAC
AAESAycLFgoMCgUEAAIAAxIDJxkaCg0KBQQAAgAIEgQnGy0FCg8KCAQAAgAInAgAEgMoBiwK
DwoIBAACAAicCAESAykGLQoPCgcEAAIACJ8IEgQqBiwHCiwKAgQBEgQyAD8BGiAgQ29uZmln
dXJhdGlvbiBmb3IgUHJlLVJlc3RvcmUuCgoKCgMEAQESAzIIGAowCgQEAQgAEgQ0AjkDGiIg
UmVxdWlyZWQuIFRoZSBhY3Rpb24gdG8gZXhlY3V0ZS4KCgwKBQQBCAABEgM0CBoKbgoEBAEC
ABIENwQ4TxpgIENsb3VkIFJ1biBqb2IgYWN0aW9uIHRvIGV4ZWN1dGUuCiBGb3JtYXQ6IGBw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vam9icy97am9ifWAKCgwK
BQQBAgAFEgM3BAoKDAoFBAECAAESAzcLGAoMCgUEAQIAAxIDNxscCgwKBQQBAgAIEgM4CE4K
DgoHBAECAAifCBIDOAlNCogBCgQEAQIBEgM+AlAaeyBPcHRpb25hbC4gVGhlIHRpbWVvdXQg
Zm9yIHRoaXMgcGhhc2UuCiBJZiBzZXQsIHRoZSB0aW1lb3V0IG11c3QgYmUgcG9zaXRpdmUg
YW5kIGxlc3MgdGhhbiBvciBlcXVhbCB0byAyNCBob3VycwogKDg2NDAwcykuCgoMCgUEAQIB
BhIDPgIaCgwKBQQBAgEBEgM+GyIKDAoFBAECAQMSAz4lJgoMCgUEAQIBCBIDPidPCg8KCAQB
AgEInAgAEgM+KE4KLQoCBAISBEIATwEaISBDb25maWd1cmF0aW9uIGZvciBQb3N0LVJlc3Rv
cmUuCgoKCgMEAgESA0IIGQowCgQEAggAEgREAkkDGiIgUmVxdWlyZWQuIFRoZSBhY3Rpb24g
dG8gZXhlY3V0ZS4KCgwKBQQCCAABEgNECBsKbgoEBAICABIERwRITxpgIENsb3VkIFJ1biBq
b2IgYWN0aW9uIHRvIGV4ZWN1dGUuCiBGb3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vam9icy97am9ifWAKCgwKBQQCAgAFEgNHBAoKDAoFBAICAAES
A0cLGAoMCgUEAgIAAxIDRxscCgwKBQQCAgAIEgNICE4KDgoHBAICAAifCBIDSAlNCogBCgQE
AgIBEgNOAlAaeyBPcHRpb25hbC4gVGhlIHRpbWVvdXQgZm9yIHRoaXMgcGhhc2UuCiBJZiBz
ZXQsIHRoZSB0aW1lb3V0IG11c3QgYmUgcG9zaXRpdmUgYW5kIGxlc3MgdGhhbiBvciBlcXVh
bCB0byAyNCBob3VycwogKDg2NDAwcykuCgoMCgUEAgIBBhIDTgIaCgwKBQQCAgEBEgNOGyIK
DAoFBAICAQMSA04lJgoMCgUEAgIBCBIDTidPCg8KCAQCAgEInAgAEgNOKE4KLQoCBAMSBFIA
XwEaISBDb25maWd1cmF0aW9uIGZvciBWZXJpZmljYXRpb24uCgoKCgMEAwESA1IIGgowCgQE
AwgAEgRUAlkDGiIgUmVxdWlyZWQuIFRoZSBhY3Rpb24gdG8gZXhlY3V0ZS4KCgwKBQQDCAAB
EgNUCBsKbgoEBAMCABIEVwRYTxpgIENsb3VkIFJ1biBqb2IgYWN0aW9uIHRvIGV4ZWN1dGUu
CiBGb3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vam9i
cy97am9ifWAKCgwKBQQDAgAFEgNXBAoKDAoFBAMCAAESA1cLGAoMCgUEAwIAAxIDVxscCgwK
BQQDAgAIEgNYCE4KDgoHBAMCAAifCBIDWAlNCogBCgQEAwIBEgNeAlAaeyBPcHRpb25hbC4g
VGhlIHRpbWVvdXQgZm9yIHRoaXMgcGhhc2UuCiBJZiBzZXQsIHRoZSB0aW1lb3V0IG11c3Qg
YmUgcG9zaXRpdmUgYW5kIGxlc3MgdGhhbiBvciBlcXVhbCB0byAyNCBob3VycwogKDg2NDAw
cykuCgoMCgUEAwIBBhIDXgIaCgwKBQQDAgEBEgNeGyIKDAoFBAMCAQMSA14lJgoMCgUEAwIB
CBIDXidPCg8KCAQDAgEInAgAEgNeKE5iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1beta::RestoreTemplateCommon::BackupSelectionConfig ===
    # Fields for BackupSelectionConfig
    # Field: data_source Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1beta::RestoreTemplateCommon::PreRestoreConfig ===
    # Fields for PreRestoreConfig
    # Field: cloud_run_job Type: 9 ()
    # Field: timeout Type: 11 (.google.protobuf.Duration)

# === Message: Google::Cloud::Backupdr::V1beta::RestoreTemplateCommon::PostRestoreConfig ===
    # Fields for PostRestoreConfig
    # Field: cloud_run_job Type: 9 ()
    # Field: timeout Type: 11 (.google.protobuf.Duration)

# === Message: Google::Cloud::Backupdr::V1beta::RestoreTemplateCommon::VerificationConfig ===
    # Fields for VerificationConfig
    # Field: cloud_run_job Type: 9 ()
    # Field: timeout Type: 11 (.google.protobuf.Duration)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1beta::RestoreTemplateCommon - Compiled Protocol Buffers messages for google/cloud/backupdr/v1beta/restore_template_common.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1beta::RestoreTemplateCommon;

    my $msg = Google::Cloud::Backupdr::V1beta::RestoreTemplateCommon::BackupSelectionConfig->new({
        data_source => $data_source,
    });

    # Read or update a field
    my $val = $msg->data_source();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1beta::RestoreTemplateCommon::BackupSelectionConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1beta/restore_template_common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1beta::RestoreTemplateCommon::BackupSelectionConfig

Configuration for selecting a backup.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_source() >> / C<< $msg->data_source($value) >>

Type: C<String>

Required. Immutable. The fully qualified URI of the backupdr data source.

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreTemplateCommon::PreRestoreConfig

Configuration for Pre-Restore.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cloud_run_job() >> / C<< $msg->cloud_run_job($value) >>

Type: C<String>

Cloud Run job action to execute.
Format: `projects/{project}/locations/{location}/jobs/{job}`

=item * C<< $msg->timeout() >> / C<< $msg->timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. The timeout for this phase.
If set, the timeout must be positive and less than or equal to 24 hours
(86400s).

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreTemplateCommon::PostRestoreConfig

Configuration for Post-Restore.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cloud_run_job() >> / C<< $msg->cloud_run_job($value) >>

Type: C<String>

Cloud Run job action to execute.
Format: `projects/{project}/locations/{location}/jobs/{job}`

=item * C<< $msg->timeout() >> / C<< $msg->timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. The timeout for this phase.
If set, the timeout must be positive and less than or equal to 24 hours
(86400s).

=back

=head2 Google::Cloud::Backupdr::V1beta::RestoreTemplateCommon::VerificationConfig

Configuration for Verification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cloud_run_job() >> / C<< $msg->cloud_run_job($value) >>

Type: C<String>

Cloud Run job action to execute.
Format: `projects/{project}/locations/{location}/jobs/{job}`

=item * C<< $msg->timeout() >> / C<< $msg->timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. The timeout for this phase.
If set, the timeout must be positive and less than or equal to 24 hours
(86400s).

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1beta::RestoreTemplateCommon::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
