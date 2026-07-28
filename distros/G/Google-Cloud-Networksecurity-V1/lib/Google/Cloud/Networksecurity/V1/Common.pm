package Google::Cloud::Networksecurity::V1::Common;

use strict;
use warnings;

our $VERSION = '0.11';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvbmV0d29ya3NlY3VyaXR5L3YxL2NvbW1vbi5wcm90bxIfZ29vZ2xl
LmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLVAgoRT3BlcmF0aW9uTWV0
YWRhdGESQAoLY3JlYXRlX3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1w
QgPgQQNSCmNyZWF0ZVRpbWUSOgoIZW5kX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wQgPgQQNSB2VuZFRpbWUSGwoGdGFyZ2V0GAMgASgJQgPgQQNSBnRhcmdldBIX
CgR2ZXJiGAQgASgJQgPgQQNSBHZlcmISKgoOc3RhdHVzX21lc3NhZ2UYBSABKAlCA+BBA1IN
c3RhdHVzTWVzc2FnZRI6ChZyZXF1ZXN0ZWRfY2FuY2VsbGF0aW9uGAYgASgIQgPgQQNSFXJl
cXVlc3RlZENhbmNlbGxhdGlvbhIkCgthcGlfdmVyc2lvbhgHIAEoCUID4EEDUgphcGlWZXJz
aW9uQuwBCiNjb20uZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MUILQ29tbW9uUHJv
dG9QAVpNY2xvdWQuZ29vZ2xlLmNvbS9nby9uZXR3b3Jrc2VjdXJpdHkvYXBpdjEvbmV0d29y
a3NlY3VyaXR5cGI7bmV0d29ya3NlY3VyaXR5cGKqAh9Hb29nbGUuQ2xvdWQuTmV0d29ya1Nl
Y3VyaXR5LlYxygIfR29vZ2xlXENsb3VkXE5ldHdvcmtTZWN1cml0eVxWMeoCIkdvb2dsZTo6
Q2xvdWQ6Ok5ldHdvcmtTZWN1cml0eTo6VjFKqBAKBhIEDgA5AQq8BAoBDBIDDgASMrEEIENv
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
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgApCgkKAgMBEgMTACkKCAoB
CBIDFQA8CgkKAgglEgMVADwKCAoBCBIDFgBkCgkKAggLEgMWAGQKCAoBCBIDFwAiCgkKAggK
EgMXACIKCAoBCBIDGAAsCgkKAggIEgMYACwKCAoBCBIDGQA8CgkKAggBEgMZADwKCAoBCBID
GgA8CgkKAggpEgMaADwKCAoBCBIDGwA7CgkKAggtEgMbADsKRAoCBAASBB4AOQEaOCBSZXBy
ZXNlbnRzIHRoZSBtZXRhZGF0YSBvZiB0aGUgbG9uZy1ydW5uaW5nIG9wZXJhdGlvbi4KCgoK
AwQAARIDHggZCkAKBAQAAgASBCACITIaMiBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIG9w
ZXJhdGlvbiB3YXMgY3JlYXRlZC4KCgwKBQQAAgAGEgMgAhsKDAoFBAACAAESAyAcJwoMCgUE
AAIAAxIDICorCgwKBQQAAgAIEgMhBjEKDwoIBAACAAicCAASAyEHMApFCgQEAAIBEgQkAiUy
GjcgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gZmluaXNoZWQgcnVubmlu
Zy4KCgwKBQQAAgEGEgMkAhsKDAoFBAACAQESAyQcJAoMCgUEAAIBAxIDJCcoCgwKBQQAAgEI
EgMlBjEKDwoIBAACAQicCAASAyUHMApZCgQEAAICEgMoAkAaTCBPdXRwdXQgb25seS4gU2Vy
dmVyLWRlZmluZWQgcmVzb3VyY2UgcGF0aCBmb3IgdGhlIHRhcmdldCBvZiB0aGUgb3BlcmF0
aW9uLgoKDAoFBAACAgUSAygCCAoMCgUEAAICARIDKAkPCgwKBQQAAgIDEgMoEhMKDAoFBAAC
AggSAygUPwoPCggEAAICCJwIABIDKBU+CkcKBAQAAgMSAysCPho6IE91dHB1dCBvbmx5LiBO
YW1lIG9mIHRoZSB2ZXJiIGV4ZWN1dGVkIGJ5IHRoZSBvcGVyYXRpb24uCgoMCgUEAAIDBRID
KwIICgwKBQQAAgMBEgMrCQ0KDAoFBAACAwMSAysQEQoMCgUEAAIDCBIDKxI9Cg8KCAQAAgMI
nAgAEgMrEzwKSwoEBAACBBIDLgJIGj4gT3V0cHV0IG9ubHkuIEh1bWFuLXJlYWRhYmxlIHN0
YXR1cyBvZiB0aGUgb3BlcmF0aW9uLCBpZiBhbnkuCgoMCgUEAAIEBRIDLgIICgwKBQQAAgQB
EgMuCRcKDAoFBAACBAMSAy4aGwoMCgUEAAIECBIDLhxHCg8KCAQAAgQInAgAEgMuHUYKmgIK
BAQAAgUSAzUCThqMAiBPdXRwdXQgb25seS4gSWRlbnRpZmllcyB3aGV0aGVyIHRoZSB1c2Vy
IGhhcyByZXF1ZXN0ZWQgY2FuY2VsbGF0aW9uCiBvZiB0aGUgb3BlcmF0aW9uLiBPcGVyYXRp
b25zIHRoYXQgaGF2ZSBzdWNjZXNzZnVsbHkgYmVlbiBjYW5jZWxsZWQKIGhhdmUgW09wZXJh
dGlvbi5lcnJvcl1bXSB2YWx1ZSB3aXRoIGEKIFtnb29nbGUucnBjLlN0YXR1cy5jb2RlXVtn
b29nbGUucnBjLlN0YXR1cy5jb2RlXSBvZiAxLCBjb3JyZXNwb25kaW5nIHRvCiBgQ29kZS5D
QU5DRUxMRURgLgoKDAoFBAACBQUSAzUCBgoMCgUEAAIFARIDNQcdCgwKBQQAAgUDEgM1ICEK
DAoFBAACBQgSAzUiTQoPCggEAAIFCJwIABIDNSNMCkQKBAQAAgYSAzgCRRo3IE91dHB1dCBv
bmx5LiBBUEkgdmVyc2lvbiB1c2VkIHRvIHN0YXJ0IHRoZSBvcGVyYXRpb24uCgoMCgUEAAIG
BRIDOAIICgwKBQQAAgYBEgM4CRQKDAoFBAACBgMSAzgXGAoMCgUEAAIGCBIDOBlECg8KCAQA
AgYInAgAEgM4GkNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networksecurity::V1::Common::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::Common::OperationMetadata - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::Common;

    my $msg = Google::Cloud::Networksecurity::V1::Common::OperationMetadata->new(
        create_time => $value,
    );

=head1 FIELDS

=over 4

=item * B<create_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<end_time>

Type: Message (.google.protobuf.Timestamp)

=item * B<target>

Type: String

=item * B<verb>

Type: String

=item * B<status_message>

Type: String

=item * B<requested_cancellation>

Type: Bool

=item * B<api_version>

Type: String

=back

=cut

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::Common - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
