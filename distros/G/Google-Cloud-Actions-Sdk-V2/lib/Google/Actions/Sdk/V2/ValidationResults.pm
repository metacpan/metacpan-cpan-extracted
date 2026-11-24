package Google::Actions::Sdk::V2::ValidationResults;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvYWN0aW9ucy9zZGsvdjIvdmFsaWRhdGlvbl9yZXN1bHRzLnByb3RvEhVnb29n
bGUuYWN0aW9ucy5zZGsudjIiVgoRVmFsaWRhdGlvblJlc3VsdHMSQQoHcmVzdWx0cxgBIAMo
CzInLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5WYWxpZGF0aW9uUmVzdWx0UgdyZXN1bHRzIuUB
ChBWYWxpZGF0aW9uUmVzdWx0Ei0KEnZhbGlkYXRpb25fbWVzc2FnZRgBIAEoCVIRdmFsaWRh
dGlvbk1lc3NhZ2USaAoSdmFsaWRhdGlvbl9jb250ZXh0GAIgASgLMjkuZ29vZ2xlLmFjdGlv
bnMuc2RrLnYyLlZhbGlkYXRpb25SZXN1bHQuVmFsaWRhdGlvbkNvbnRleHRSEXZhbGlkYXRp
b25Db250ZXh0GjgKEVZhbGlkYXRpb25Db250ZXh0EiMKDWxhbmd1YWdlX2NvZGUYASABKAlS
DGxhbmd1YWdlQ29kZUJvChljb20uZ29vZ2xlLmFjdGlvbnMuc2RrLnYyQhZWYWxpZGF0aW9u
UmVzdWx0c1Byb3RvUAFaOGdvb2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMv
YWN0aW9ucy9zZGsvdjI7c2RrSuwLCgYSBA4ALQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
MjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBW
ZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxl
IGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFp
biBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQAB4KCAoBCBIDEgBPCgkKAggLEgMSAE8KCAoBCBIDEwAiCgkK
AggKEgMTACIKCAoBCBIDFAA3CgkKAggIEgMUADcKCAoBCBIDFQAyCgkKAggBEgMVADIKNQoC
BAASBBgAGwEaKSBXcmFwcGVyIGZvciByZXBlYXRlZCB2YWxpZGF0aW9uIHJlc3VsdC4KCgoK
AwQAARIDGAgZCisKBAQAAgASAxoCKBoeIE11bHRpcGxlIHZhbGlkYXRpb24gcmVzdWx0cy4K
CgwKBQQAAgAEEgMaAgoKDAoFBAACAAYSAxoLGwoMCgUEAAIAARIDGhwjCgwKBQQAAgADEgMa
JicKTQoCBAESBB4ALQEaQSBSZXByZXNlbnRzIGEgdmFsaWRhdGlvbiByZXN1bHQgYXNzb2Np
YXRlZCB3aXRoIHRoZSBhcHAgY29udGVudC4KCgoKAwQBARIDHggYClMKBAQBAwASBCACJgMa
RSBDb250ZXh0IHRvIGlkZW50aWZ5IHRoZSByZXNvdXJjZSB0aGUgdmFsaWRhdGlvbiBtZXNz
YWdlIHJlbGF0ZXMgdG8uCgoMCgUEAQMAARIDIAobCtgBCgYEAQMAAgASAyUEHRrIASBMYW5n
dWFnZSBjb2RlIG9mIHRoZSBsb3phbGl6ZWQgcmVzb3VyY2UuCiBFbXB0eSBpZiB0aGUgZXJy
b3IgaXMgZm9yIG5vbi1sb2NhbGl6ZWQgcmVzb3VyY2UuCiBTZWUgdGhlIGxpc3Qgb2Ygc3Vw
cG9ydGVkIGxhbmd1YWdlcyBpbgogaHR0cHM6Ly9kZXZlbG9wZXJzLmdvb2dsZS5jb20vYXNz
aXN0YW50L2NvbnNvbGUvbGFuZ3VhZ2VzLWxvY2FsZXMKCg4KBwQBAwACAAUSAyUECgoOCgcE
AQMAAgABEgMlCxgKDgoHBAEDAAIAAxIDJRscCiwKBAQBAgASAykCIBofIEhvbGRzIHRoZSB2
YWxpZGF0aW9uIG1lc3NhZ2UuCgoMCgUEAQIABRIDKQIICgwKBQQBAgABEgMpCRsKDAoFBAEC
AAMSAykeHwpSCgQEAQIBEgMsAisaRSBDb250ZXh0IHRvIGlkZW50aWZ5IHRoZSByZXNvdXJj
ZSB0aGUgdmFsaWRhdGlvbiBtZXNzYWdlIHJlbGF0ZXMgdG8uCgoMCgUEAQIBBhIDLAITCgwK
BQQBAgEBEgMsFCYKDAoFBAECAQMSAywpKmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::ValidationResults::ValidationResults ===
    # Fields for ValidationResults
    # Field: results Type: 11 (.google.actions.sdk.v2.ValidationResult)

# === Message: Google::Actions::Sdk::V2::ValidationResults::ValidationResult ===
    # Fields for ValidationResult
    # Field: validation_message Type: 9 ()
    # Field: validation_context Type: 11 (.google.actions.sdk.v2.ValidationResult.ValidationContext)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::ValidationResults - Compiled Protocol Buffers messages for google/actions/sdk/v2/validation_results.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::ValidationResults;

    my $msg = Google::Actions::Sdk::V2::ValidationResults::ValidationResults->new({
        results => $results,
    });

    # Read or update a field
    my $val = $msg->results();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::ValidationResults::ValidationResults->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/validation_results.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::ValidationResults::ValidationResults

Wrapper for repeated validation result.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->results() >> / C<< $msg->results($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::ValidationResults::ValidationResult>)

Multiple validation results.

=back

=head2 Google::Actions::Sdk::V2::ValidationResults::ValidationResult

Represents a validation result associated with the app content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->validation_message() >> / C<< $msg->validation_message($value) >>

Type: C<String>

Holds the validation message.

=item * C<< $msg->validation_context() >> / C<< $msg->validation_context($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::ValidationResults::ValidationResult::ValidationContext>)

Context to identify the resource the validation message relates to.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::ValidationResults::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
