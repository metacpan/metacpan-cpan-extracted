package Google::Cloud::Notebooks::V1::DiagnosticConfig;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvbm90ZWJvb2tzL3YxL2RpYWdub3N0aWNfY29uZmlnLnByb3RvEhln
b29nbGUuY2xvdWQubm90ZWJvb2tzLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvIp4CChBEaWFnbm9zdGljQ29uZmlnEiIKCmdjc19idWNrZXQYASABKAlCA+BBAlIJZ2Nz
QnVja2V0EigKDXJlbGF0aXZlX3BhdGgYAiABKAlCA+BBAVIMcmVsYXRpdmVQYXRoEjMKE3Jl
cGFpcl9mbGFnX2VuYWJsZWQYAyABKAhCA+BBAVIRcmVwYWlyRmxhZ0VuYWJsZWQSQgobcGFj
a2V0X2NhcHR1cmVfZmxhZ19lbmFibGVkGAQgASgIQgPgQQFSGHBhY2tldENhcHR1cmVGbGFn
RW5hYmxlZBJDChxjb3B5X2hvbWVfZmlsZXNfZmxhZ19lbmFibGVkGAUgASgIQgPgQQFSGGNv
cHlIb21lRmlsZXNGbGFnRW5hYmxlZEJ1Ch1jb20uZ29vZ2xlLmNsb3VkLm5vdGVib29rcy52
MUIVRGlhZ25vc3RpY0NvbmZpZ1Byb3RvUAFaO2Nsb3VkLmdvb2dsZS5jb20vZ28vbm90ZWJv
b2tzL2FwaXYxL25vdGVib29rc3BiO25vdGVib29rc3BiStURCgYSBA4AOwEKvAQKAQwSAw4A
EjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACIKCQoCAwASAxIAKQoICgEIEgMU
AFIKCQoCCAsSAxQAUgoICgEIEgMVACIKCQoCCAoSAxUAIgoICgEIEgMWADYKCQoCCAgSAxYA
NgoICgEIEgMXADYKCQoCCAESAxcANgpECgIEABIEGgA7ARo4IERlZmluZXMgZmxhZ3MgdGhh
dCBhcmUgdXNlZCB0byBydW4gdGhlIGRpYWdub3N0aWMgdG9vbAoKCgoDBAABEgMaCBgKoAQK
BAQAAgASAygCQRqSBCBSZXF1aXJlZC4gVXNlciBDbG91ZCBTdG9yYWdlIGJ1Y2tldCBsb2Nh
dGlvbiAoUkVRVUlSRUQpLgogTXVzdCBiZSBmb3JtYXR0ZWQgd2l0aCBwYXRoIHByZWZpeCAo
YGdzOi8vJEdDU19CVUNLRVRgKS4KCiBQZXJtaXNzaW9uczoKIFVzZXIgTWFuYWdlZCBOb3Rl
Ym9va3M6CiAtIHN0b3JhZ2UuYnVja2V0cy53cml0ZXI6IE11c3QgYmUgZ2l2ZW4gdG8gdGhl
IHByb2plY3QncyBzZXJ2aWNlIGFjY291bnQKICAgYXR0YWNoZWQgdG8gVk0uCiBHb29nbGUg
TWFuYWdlZCBOb3RlYm9va3M6CiAtIHN0b3JhZ2UuYnVja2V0cy53cml0ZXI6IE11c3QgYmUg
Z2l2ZW4gdG8gdGhlIHByb2plY3QncyBzZXJ2aWNlIGFjY291bnQgb3IKICAgdXNlciBjcmVk
ZW50aWFscyBhdHRhY2hlZCB0byBWTSBkZXBlbmRpbmcgb24gYXV0aGVudGljYXRpb24gbW9k
ZS4KCiBDbG91ZCBTdG9yYWdlIGJ1Y2tldCBMb2cgZmlsZSB3aWxsIGJlIHdyaXR0ZW4gdG8K
IGBnczovLyRHQ1NfQlVDS0VULyRSRUxBVElWRV9QQVRILyRWTV9EQVRFXyRUSU1FLnRhci5n
emAKCgwKBQQAAgAFEgMoAggKDAoFBAACAAESAygJEwoMCgUEAAIAAxIDKBYXCgwKBQQAAgAI
EgMoGEAKDwoIBAACAAicCAASAygZPwrLAgoEBAACARIDMAJEGr0CIE9wdGlvbmFsLiBEZWZp
bmVzIHRoZSByZWxhdGl2ZSBzdG9yYWdlIHBhdGggaW4gdGhlIENsb3VkIFN0b3JhZ2UgYnVj
a2V0CiB3aGVyZSB0aGUgZGlhZ25vc3RpYyBsb2dzIHdpbGwgYmUgd3JpdHRlbjogRGVmYXVs
dCBwYXRoIHdpbGwgYmUgdGhlIHJvb3QKIGRpcmVjdG9yeSBvZiB0aGUgQ2xvdWQgU3RvcmFn
ZSBidWNrZXQKIChgZ3M6Ly8kR0NTX0JVQ0tFVC8kREFURV8kVElNRS50YXIuZ3pgKQogRXhh
bXBsZSBvZiBmdWxsIHBhdGggd2hlcmUgTG9nIGZpbGUgd2lsbCBiZSB3cml0dGVuOgogYGdz
Oi8vJEdDU19CVUNLRVQvJFJFTEFUSVZFX1BBVEgvYAoKDAoFBAACAQUSAzACCAoMCgUEAAIB
ARIDMAkWCgwKBQQAAgEDEgMwGRoKDAoFBAACAQgSAzAbQwoPCggEAAIBCJwIABIDMBxCCkQK
BAQAAgISAzMCSBo3IE9wdGlvbmFsLiBFbmFibGVzIGZsYWcgdG8gcmVwYWlyIHNlcnZpY2Ug
Zm9yIGluc3RhbmNlCgoMCgUEAAICBRIDMwIGCgwKBQQAAgIBEgMzBxoKDAoFBAACAgMSAzMd
HgoMCgUEAAICCBIDMx9HCg8KCAQAAgIInAgAEgMzIEYKWQoEBAACAxIDNgJQGkwgT3B0aW9u
YWwuIEVuYWJsZXMgZmxhZyB0byBjYXB0dXJlIHBhY2tldHMgZnJvbSB0aGUgaW5zdGFuY2Ug
Zm9yIDMwIHNlY29uZHMKCgwKBQQAAgMFEgM2AgYKDAoFBAACAwESAzYHIgoMCgUEAAIDAxID
NiUmCgwKBQQAAgMIEgM2J08KDwoIBAACAwicCAASAzYoTgpSCgQEAAIEEgQ5AjovGkQgT3B0
aW9uYWwuIEVuYWJsZXMgZmxhZyB0byBjb3B5IGFsbCBgL2hvbWUvanVweXRlcmAgZm9sZGVy
IGNvbnRlbnRzCgoMCgUEAAIEBRIDOQIGCgwKBQQAAgQBEgM5ByMKDAoFBAACBAMSAzkmJwoM
CgUEAAIECBIDOgYuCg8KCAQAAgQInAgAEgM6By1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Notebooks::V1::DiagnosticConfig::DiagnosticConfig ===
    # Fields for DiagnosticConfig
    # Field: gcs_bucket Type: 9 ()
    # Field: relative_path Type: 9 ()
    # Field: repair_flag_enabled Type: 8 ()
    # Field: packet_capture_flag_enabled Type: 8 ()
    # Field: copy_home_files_flag_enabled Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Notebooks::V1::DiagnosticConfig - Compiled Protocol Buffers messages for google/cloud/notebooks/v1/diagnostic_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Notebooks::V1::DiagnosticConfig;

    my $msg = Google::Cloud::Notebooks::V1::DiagnosticConfig::DiagnosticConfig->new({
        gcs_bucket => $gcs_bucket,
        relative_path => $relative_path,
        repair_flag_enabled => $repair_flag_enabled,
        packet_capture_flag_enabled => $packet_capture_flag_enabled,
    });

    # Read or update a field
    my $val = $msg->gcs_bucket();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Notebooks::V1::DiagnosticConfig::DiagnosticConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/notebooks/v1/diagnostic_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Notebooks::V1::DiagnosticConfig::DiagnosticConfig

Defines flags that are used to run the diagnostic tool

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->gcs_bucket() >> / C<< $msg->gcs_bucket($value) >>

Type: C<String>

Required. User Cloud Storage bucket location (REQUIRED).
Must be formatted with path prefix (`gs://$GCS_BUCKET`).

Permissions:
User Managed Notebooks:
- storage.buckets.writer: Must be given to the project's service account
  attached to VM.
Google Managed Notebooks:
- storage.buckets.writer: Must be given to the project's service account or
  user credentials attached to VM depending on authentication mode.

Cloud Storage bucket Log file will be written to
`gs://$GCS_BUCKET/$RELATIVE_PATH/$VM_DATE_$TIME.tar.gz`

=item * C<< $msg->relative_path() >> / C<< $msg->relative_path($value) >>

Type: C<String>

Optional. Defines the relative storage path in the Cloud Storage bucket
where the diagnostic logs will be written: Default path will be the root
directory of the Cloud Storage bucket
(`gs://$GCS_BUCKET/$DATE_$TIME.tar.gz`)
Example of full path where Log file will be written:
`gs://$GCS_BUCKET/$RELATIVE_PATH/`

=item * C<< $msg->repair_flag_enabled() >> / C<< $msg->repair_flag_enabled($value) >>

Type: C<Bool>

Optional. Enables flag to repair service for instance

=item * C<< $msg->packet_capture_flag_enabled() >> / C<< $msg->packet_capture_flag_enabled($value) >>

Type: C<Bool>

Optional. Enables flag to capture packets from the instance for 30 seconds

=item * C<< $msg->copy_home_files_flag_enabled() >> / C<< $msg->copy_home_files_flag_enabled($value) >>

Type: C<Bool>

Optional. Enables flag to copy all `/home/jupyter` folder contents

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Notebooks::V1::DiagnosticConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
