package Google::Cloud::Backupdr::V1::RestoreTemplateCommon;

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
CjZnb29nbGUvY2xvdWQvYmFja3VwZHIvdjEvcmVzdG9yZV90ZW1wbGF0ZV9jb21tb24ucHJv
dG8SGGdvb2dsZS5jbG91ZC5iYWNrdXBkci52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL2R1
cmF0aW9uLnByb3RvInMKFUJhY2t1cFNlbGVjdGlvbkNvbmZpZxJQCgtkYXRhX3NvdXJjZRgB
IAEoCUIt4EEC4EEF+kEkCiJiYWNrdXBkci5nb29nbGVhcGlzLmNvbS9EYXRhU291cmNlSABS
CmRhdGFTb3VyY2VCCAoGc291cmNlIqUBChBQcmVSZXN0b3JlQ29uZmlnEjgKB3RpbWVvdXQY
ASABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25CA+BBAVIHdGltZW91dBJBCg1jbG91
ZF9ydW5fam9iGAIgASgJQhv6QRgKFnJ1bi5nb29nbGVhcGlzLmNvbS9Kb2JIAFILY2xvdWRS
dW5Kb2JCFAoScHJlX3Jlc3RvcmVfYWN0aW9uIqcBChFQb3N0UmVzdG9yZUNvbmZpZxI4Cgd0
aW1lb3V0GAEgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uQgPgQQFSB3RpbWVvdXQS
QQoNY2xvdWRfcnVuX2pvYhgCIAEoCUIb+kEYChZydW4uZ29vZ2xlYXBpcy5jb20vSm9iSABS
C2Nsb3VkUnVuSm9iQhUKE3Bvc3RfcmVzdG9yZV9hY3Rpb24iqAEKElZlcmlmaWNhdGlvbkNv
bmZpZxI4Cgd0aW1lb3V0GAEgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uQgPgQQFS
B3RpbWVvdXQSQQoNY2xvdWRfcnVuX2pvYhgCIAEoCUIb+kEYChZydW4uZ29vZ2xlYXBpcy5j
b20vSm9iSABSC2Nsb3VkUnVuSm9iQhUKE3ZlcmlmaWNhdGlvbl9hY3Rpb25CmQIKHGNvbS5n
b29nbGUuY2xvdWQuYmFja3VwZHIudjFCGlJlc3RvcmVUZW1wbGF0ZUNvbW1vblByb3RvUAFa
OGNsb3VkLmdvb2dsZS5jb20vZ28vYmFja3VwZHIvYXBpdjEvYmFja3VwZHJwYjtiYWNrdXBk
cnBiqgIYR29vZ2xlLkNsb3VkLkJhY2t1cERSLlYxygIYR29vZ2xlXENsb3VkXEJhY2t1cERS
XFYx6gIbR29vZ2xlOjpDbG91ZDo6QmFja3VwRFI6OlYx6kFMChZydW4uZ29vZ2xlYXBpcy5j
b20vSm9iEjJwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vam9icy97
am9ifUqMFQoGEgQOAF8BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExM
QwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRo
ZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29t
cGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRo
ZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNF
TlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQg
dG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNl
IGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJ
RVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGll
ZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmlu
ZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoB
AhIDEAAhCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAoCggKAQgSAxYANQoJCgII
JRIDFgA1CggKAQgSAxcATwoJCgIICxIDFwBPCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgS
AxkAOwoJCgIICBIDGQA7CggKAQgSAxoANQoJCgIIARIDGgA1CggKAQgSAxsANQoJCgIIKRID
GwA1CggKAQgSAxwANAoJCgIILRIDHAA0CgkKAQgSBB0AIAIKDAoECJ0IABIEHQAgAgozCgIE
ABIEIwAvARonIENvbmZpZ3VyYXRpb24gZm9yIHNlbGVjdGluZyBhIGJhY2t1cC4KCgoKAwQA
ARIDIwgdCjYKBAQACAASBCUCLgMaKCBUaGUgZnVsbHkgcXVhbGlmaWVkIFVSSSBvZiB0aGUg
c291cmNlLgoKDAoFBAAIAAESAyUIDgpZCgQEAAIAEgQnBC0GGksgUmVxdWlyZWQuIEltbXV0
YWJsZS4gVGhlIGZ1bGx5IHF1YWxpZmllZCBVUkkgb2YgdGhlIGJhY2t1cGRyIGRhdGEgc291
cmNlLgoKDAoFBAACAAUSAycECgoMCgUEAAIAARIDJwsWCgwKBQQAAgADEgMnGRoKDQoFBAAC
AAgSBCcbLQUKDwoIBAACAAicCAASAygGLAoPCggEAAIACJwIARIDKQYtCg8KBwQAAgAInwgS
BCoGLAcKLAoCBAESBDIAPwEaICBDb25maWd1cmF0aW9uIGZvciBQcmUtUmVzdG9yZS4KCgoK
AwQBARIDMggYCowBCgQEAQIAEgM2AlAafyBPcHRpb25hbC4gVGhlIGB0aW1lb3V0YCBmb3Ig
dGhpcyBwaGFzZS4KIElmIHNldCwgdGhlIGB0aW1lb3V0YCBtdXN0IGJlIHBvc2l0aXZlIGFu
ZCBsZXNzIHRoYW4gb3IgZXF1YWwgdG8gMjQgaG91cnMKICg4NjQwMHMpLgoKDAoFBAECAAYS
AzYCGgoMCgUEAQIAARIDNhsiCgwKBQQBAgADEgM2JSYKDAoFBAECAAgSAzYnTwoPCggEAQIA
CJwIABIDNihOCjAKBAQBCAASBDkCPgMaIiBSZXF1aXJlZC4gVGhlIGFjdGlvbiB0byBleGVj
dXRlLgoKDAoFBAEIAAESAzkIGgpuCgQEAQIBEgQ8BD1PGmAgQ2xvdWQgUnVuIGpvYiBhY3Rp
b24gdG8gZXhlY3V0ZS4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9qb2JzL3tqb2J9YAoKDAoFBAECAQUSAzwECgoMCgUEAQIBARIDPAsYCgwK
BQQBAgEDEgM8GxwKDAoFBAECAQgSAz0ITgoOCgcEAQIBCJ8IEgM9CU0KLQoCBAISBEIATwEa
ISBDb25maWd1cmF0aW9uIGZvciBQb3N0LVJlc3RvcmUuCgoKCgMEAgESA0IIGQqMAQoEBAIC
ABIDRgJQGn8gT3B0aW9uYWwuIFRoZSBgdGltZW91dGAgZm9yIHRoaXMgcGhhc2UuCiBJZiBz
ZXQsIHRoZSBgdGltZW91dGAgbXVzdCBiZSBwb3NpdGl2ZSBhbmQgbGVzcyB0aGFuIG9yIGVx
dWFsIHRvIDI0IGhvdXJzCiAoODY0MDBzKS4KCgwKBQQCAgAGEgNGAhoKDAoFBAICAAESA0Yb
IgoMCgUEAgIAAxIDRiUmCgwKBQQCAgAIEgNGJ08KDwoIBAICAAicCAASA0YoTgowCgQEAggA
EgRJAk4DGiIgUmVxdWlyZWQuIFRoZSBhY3Rpb24gdG8gZXhlY3V0ZS4KCgwKBQQCCAABEgNJ
CBsKbgoEBAICARIETARNTxpgIENsb3VkIFJ1biBqb2IgYWN0aW9uIHRvIGV4ZWN1dGUuCiBG
b3JtYXQ6IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vam9icy97
am9ifWAKCgwKBQQCAgEFEgNMBAoKDAoFBAICAQESA0wLGAoMCgUEAgIBAxIDTBscCgwKBQQC
AgEIEgNNCE4KDgoHBAICAQifCBIDTQlNCi0KAgQDEgRSAF8BGiEgQ29uZmlndXJhdGlvbiBm
b3IgVmVyaWZpY2F0aW9uLgoKCgoDBAMBEgNSCBoKjAEKBAQDAgASA1YCUBp/IE9wdGlvbmFs
LiBUaGUgYHRpbWVvdXRgIGZvciB0aGlzIHBoYXNlLgogSWYgc2V0LCB0aGUgYHRpbWVvdXRg
IG11c3QgYmUgcG9zaXRpdmUgYW5kIGxlc3MgdGhhbiBvciBlcXVhbCB0byAyNCBob3Vycwog
KDg2NDAwcykuCgoMCgUEAwIABhIDVgIaCgwKBQQDAgABEgNWGyIKDAoFBAMCAAMSA1YlJgoM
CgUEAwIACBIDVidPCg8KCAQDAgAInAgAEgNWKE4KMAoEBAMIABIEWQJeAxoiIFJlcXVpcmVk
LiBUaGUgYWN0aW9uIHRvIGV4ZWN1dGUuCgoMCgUEAwgAARIDWQgbCm4KBAQDAgESBFwEXU8a
YCBDbG91ZCBSdW4gam9iIGFjdGlvbiB0byBleGVjdXRlLgogRm9ybWF0OiBgcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2pvYnMve2pvYn1gCgoMCgUEAwIBBRID
XAQKCgwKBQQDAgEBEgNcCxgKDAoFBAMCAQMSA1wbHAoMCgUEAwIBCBIDXQhOCg4KBwQDAgEI
nwgSA10JTWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1::RestoreTemplateCommon::BackupSelectionConfig ===
    # Fields for BackupSelectionConfig
    # Field: data_source Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::RestoreTemplateCommon::PreRestoreConfig ===
    # Fields for PreRestoreConfig
    # Field: timeout Type: 11 (.google.protobuf.Duration)
    # Field: cloud_run_job Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::RestoreTemplateCommon::PostRestoreConfig ===
    # Fields for PostRestoreConfig
    # Field: timeout Type: 11 (.google.protobuf.Duration)
    # Field: cloud_run_job Type: 9 ()

# === Message: Google::Cloud::Backupdr::V1::RestoreTemplateCommon::VerificationConfig ===
    # Fields for VerificationConfig
    # Field: timeout Type: 11 (.google.protobuf.Duration)
    # Field: cloud_run_job Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1::RestoreTemplateCommon - Compiled Protocol Buffers messages for google/cloud/backupdr/v1/restore_template_common.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1::RestoreTemplateCommon;

    my $msg = Google::Cloud::Backupdr::V1::RestoreTemplateCommon::BackupSelectionConfig->new({
        data_source => $data_source,
    });

    # Read or update a field
    my $val = $msg->data_source();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1::RestoreTemplateCommon::BackupSelectionConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1/restore_template_common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1::RestoreTemplateCommon::BackupSelectionConfig

Configuration for selecting a backup.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_source() >> / C<< $msg->data_source($value) >>

Type: C<String>

Required. Immutable. The fully qualified URI of the backupdr data source.

=back

=head2 Google::Cloud::Backupdr::V1::RestoreTemplateCommon::PreRestoreConfig

Configuration for Pre-Restore.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->timeout() >> / C<< $msg->timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. The `timeout` for this phase.
If set, the `timeout` must be positive and less than or equal to 24 hours
(86400s).

=item * C<< $msg->cloud_run_job() >> / C<< $msg->cloud_run_job($value) >>

Type: C<String>

Cloud Run job action to execute.
Format: `projects/{project}/locations/{location}/jobs/{job}`

=back

=head2 Google::Cloud::Backupdr::V1::RestoreTemplateCommon::PostRestoreConfig

Configuration for Post-Restore.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->timeout() >> / C<< $msg->timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. The `timeout` for this phase.
If set, the `timeout` must be positive and less than or equal to 24 hours
(86400s).

=item * C<< $msg->cloud_run_job() >> / C<< $msg->cloud_run_job($value) >>

Type: C<String>

Cloud Run job action to execute.
Format: `projects/{project}/locations/{location}/jobs/{job}`

=back

=head2 Google::Cloud::Backupdr::V1::RestoreTemplateCommon::VerificationConfig

Configuration for Verification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->timeout() >> / C<< $msg->timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. The `timeout` for this phase.
If set, the `timeout` must be positive and less than or equal to 24 hours
(86400s).

=item * C<< $msg->cloud_run_job() >> / C<< $msg->cloud_run_job($value) >>

Type: C<String>

Cloud Run job action to execute.
Format: `projects/{project}/locations/{location}/jobs/{job}`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1::RestoreTemplateCommon::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
