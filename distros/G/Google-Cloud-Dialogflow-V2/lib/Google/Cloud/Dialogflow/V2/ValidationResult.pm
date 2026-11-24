package Google::Cloud::Dialogflow::V2::ValidationResult;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi92YWxpZGF0aW9uX3Jlc3VsdC5wcm90bxIa
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIi+AEKD1ZhbGlkYXRpb25FcnJvchJQCghzZXZl
cml0eRgBIAEoDjI0Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLlZhbGlkYXRpb25FcnJv
ci5TZXZlcml0eVIIc2V2ZXJpdHkSGAoHZW50cmllcxgDIAMoCVIHZW50cmllcxIjCg1lcnJv
cl9tZXNzYWdlGAQgASgJUgxlcnJvck1lc3NhZ2UiVAoIU2V2ZXJpdHkSGAoUU0VWRVJJVFlf
VU5TUEVDSUZJRUQQABIICgRJTkZPEAESCwoHV0FSTklORxACEgkKBUVSUk9SEAMSDAoIQ1JJ
VElDQUwQBCJsChBWYWxpZGF0aW9uUmVzdWx0ElgKEXZhbGlkYXRpb25fZXJyb3JzGAEgAygL
MisuZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuVmFsaWRhdGlvbkVycm9yUhB2YWxpZGF0
aW9uRXJyb3JzQpsBCh5jb20uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjJCFVZhbGlkYXRp
b25SZXN1bHRQcm90b1ABWj5jbG91ZC5nb29nbGUuY29tL2dvL2RpYWxvZ2Zsb3cvYXBpdjIv
ZGlhbG9nZmxvd3BiO2RpYWxvZ2Zsb3dwYqICAkRGqgIaR29vZ2xlLkNsb3VkLkRpYWxvZ2Zs
b3cuVjJK1xIKBhIEDgBIAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAAIwoICgEIEgMSADcKCQoCCCUSAxIANwoICgEIEgMTAFUKCQoCCAsSAxMAVQoICgEI
EgMUACIKCQoCCAoSAxQAIgoICgEIEgMVADYKCQoCCAgSAxUANgoICgEIEgMWADcKCQoCCAES
AxYANwoICgEIEgMXACAKCQoCCCQSAxcAIAozCgIEABIEGgBCARonIFJlcHJlc2VudHMgYSBz
aW5nbGUgdmFsaWRhdGlvbiBlcnJvci4KCgoKAwQAARIDGggXCi8KBAQABAASBBwCKwMaISBS
ZXByZXNlbnRzIGEgbGV2ZWwgb2Ygc2V2ZXJpdHkuCgoMCgUEAAQAARIDHAcPCkAKBgQABAAC
ABIDHgQdGjEgTm90IHNwZWNpZmllZC4gVGhpcyB2YWx1ZSBzaG91bGQgbmV2ZXIgYmUgdXNl
ZC4KCg4KBwQABAACAAESAx4EGAoOCgcEAAQAAgACEgMeGxwKRAoGBAAEAAIBEgMhBA0aNSBU
aGUgYWdlbnQgZG9lc24ndCBmb2xsb3cgRGlhbG9nZmxvdyBiZXN0IHByYWN0aWNlcy4KCg4K
BwQABAACAQESAyEECAoOCgcEAAQAAgECEgMhCwwKNgoGBAAEAAICEgMkBBAaJyBUaGUgYWdl
bnQgbWF5IG5vdCBiZWhhdmUgYXMgZXhwZWN0ZWQuCgoOCgcEAAQAAgIBEgMkBAsKDgoHBAAE
AAICAhIDJA4PCjsKBgQABAACAxIDJwQOGiwgVGhlIGFnZW50IG1heSBleHBlcmllbmNlIHBh
cnRpYWwgZmFpbHVyZXMuCgoOCgcEAAQAAgMBEgMnBAkKDgoHBAAEAAIDAhIDJwwNCi8KBgQA
BAACBBIDKgQRGiAgVGhlIGFnZW50IG1heSBjb21wbGV0ZWx5IGZhaWwuCgoOCgcEAAQAAgQB
EgMqBAwKDgoHBAAEAAIEAhIDKg8QCikKBAQAAgASAy4CGBocIFRoZSBzZXZlcml0eSBvZiB0
aGUgZXJyb3IuCgoMCgUEAAIABhIDLgIKCgwKBQQAAgABEgMuCxMKDAoFBAACAAMSAy4WFwqm
BQoEBAACARIDPgIeGpgFIFRoZSBuYW1lcyBvZiB0aGUgZW50cmllcyB0aGF0IHRoZSBlcnJv
ciBpcyBhc3NvY2lhdGVkIHdpdGguCiBGb3JtYXQ6CgogLSBgcHJvamVjdHMvPFByb2plY3Qg
SUQ+L2FnZW50YCwgaWYgdGhlIGVycm9yIGlzIGFzc29jaWF0ZWQgd2l0aCB0aGUgZW50aXJl
CiBhZ2VudC4KIC0gYHByb2plY3RzLzxQcm9qZWN0IElEPi9hZ2VudC9pbnRlbnRzLzxJbnRl
bnQgSUQ+YCwgaWYgdGhlIGVycm9yIGlzCiBhc3NvY2lhdGVkIHdpdGggY2VydGFpbiBpbnRl
bnRzLgogLSBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2FnZW50L2ludGVudHMvPEludGVudAog
SWQ+L3RyYWluaW5nUGhyYXNlcy88VHJhaW5pbmcgUGhyYXNlIElEPmAsIGlmIHRoZSBlcnJv
ciBpcyBhc3NvY2lhdGVkIHdpdGgKIGNlcnRhaW4gaW50ZW50IHRyYWluaW5nIHBocmFzZXMu
CiAtIGBwcm9qZWN0cy88UHJvamVjdCBJRD4vYWdlbnQvaW50ZW50cy88SW50ZW50IElkPi9w
YXJhbWV0ZXJzLzxQYXJhbWV0ZXIKIElEPmAsIGlmIHRoZSBlcnJvciBpcyBhc3NvY2lhdGVk
IHdpdGggY2VydGFpbiBpbnRlbnQgcGFyYW1ldGVycy4KIC0gYHByb2plY3RzLzxQcm9qZWN0
IElEPi9hZ2VudC9lbnRpdGllcy88RW50aXR5IElEPmAsIGlmIHRoZSBlcnJvciBpcwogYXNz
b2NpYXRlZCB3aXRoIGNlcnRhaW4gZW50aXRpZXMuCgoMCgUEAAIBBBIDPgIKCgwKBQQAAgEF
EgM+CxEKDAoFBAACAQESAz4SGQoMCgUEAAIBAxIDPhwdCioKBAQAAgISA0ECGxodIFRoZSBk
ZXRhaWxlZCBlcnJvciBtZXNzYWdlLgoKDAoFBAACAgUSA0ECCAoMCgUEAAICARIDQQkWCgwK
BQQAAgIDEgNBGRoKOAoCBAESBEUASAEaLCBSZXByZXNlbnRzIHRoZSBvdXRwdXQgb2YgYWdl
bnQgdmFsaWRhdGlvbi4KCgoKAwQBARIDRQgYCi4KBAQBAgASA0cCMRohIENvbnRhaW5zIGFs
bCB2YWxpZGF0aW9uIGVycm9ycy4KCgwKBQQBAgAEEgNHAgoKDAoFBAECAAYSA0cLGgoMCgUE
AQIAARIDRxssCgwKBQQBAgADEgNHLzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2::ValidationResult::ValidationError ===
    # Fields for ValidationError
    # Field: severity Type: 14 (.google.cloud.dialogflow.v2.ValidationError.Severity)
    # Field: entries Type: 9 ()
    # Field: error_message Type: 9 ()

# Enum: ValidationError::Severity
our $ValidationError_SEVERITY_UNSPECIFIED = 0;
our $ValidationError_INFO = 1;
our $ValidationError_WARNING = 2;
our $ValidationError_ERROR = 3;
our $ValidationError_CRITICAL = 4;

# === Message: Google::Cloud::Dialogflow::V2::ValidationResult::ValidationResult ===
    # Fields for ValidationResult
    # Field: validation_errors Type: 11 (.google.cloud.dialogflow.v2.ValidationError)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2::ValidationResult - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2/validation_result.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2::ValidationResult;

    my $msg = Google::Cloud::Dialogflow::V2::ValidationResult::ValidationError->new({
        severity => $severity,
        entries => $entries,
        error_message => $error_message,
    });

    # Read or update a field
    my $val = $msg->severity();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2::ValidationResult::ValidationError->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2/validation_result.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2::ValidationResult::ValidationError

Represents a single validation error.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->severity() >> / C<< $msg->severity($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2::ValidationError::Severity>)

The severity of the error.

=item * C<< $msg->entries() >> / C<< $msg->entries($value) >>

Type: C<String>

The names of the entries that the error is associated with.
Format:

- `projects/<Project ID>/agent`, if the error is associated with the entire
agent.
- `projects/<Project ID>/agent/intents/<Intent ID>`, if the error is
associated with certain intents.
- `projects/<Project ID>/agent/intents/<Intent
Id>/trainingPhrases/<Training Phrase ID>`, if the error is associated with
certain intent training phrases.
- `projects/<Project ID>/agent/intents/<Intent Id>/parameters/<Parameter
ID>`, if the error is associated with certain intent parameters.
- `projects/<Project ID>/agent/entities/<Entity ID>`, if the error is
associated with certain entities.

=item * C<< $msg->error_message() >> / C<< $msg->error_message($value) >>

Type: C<String>

The detailed error message.

=back

=head3 Enum: ValidationError::Severity

=over 4

=item * C<SEVERITY_UNSPECIFIED> => C<0>

=item * C<INFO> => C<1>

=item * C<WARNING> => C<2>

=item * C<ERROR> => C<3>

=item * C<CRITICAL> => C<4>

=back

=head2 Google::Cloud::Dialogflow::V2::ValidationResult::ValidationResult

Represents the output of agent validation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->validation_errors() >> / C<< $msg->validation_errors($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::V2::ValidationResult::ValidationError>)

Contains all validation errors.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2::ValidationResult::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
