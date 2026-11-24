package Google::Cloud::Bigquery::Migration::V2::TranslationUsability;

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
Cj5nb29nbGUvY2xvdWQvYmlncXVlcnkvbWlncmF0aW9uL3YyL3RyYW5zbGF0aW9uX3VzYWJp
bGl0eS5wcm90bxIiZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52MhofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byL4
AgoTR2NzUmVwb3J0TG9nTWVzc2FnZRIaCghzZXZlcml0eRgBIAEoCVIIc2V2ZXJpdHkSGgoI
Y2F0ZWdvcnkYAiABKAlSCGNhdGVnb3J5EhsKCWZpbGVfcGF0aBgDIAEoCVIIZmlsZVBhdGgS
GgoIZmlsZW5hbWUYBCABKAlSCGZpbGVuYW1lEiwKEnNvdXJjZV9zY3JpcHRfbGluZRgFIAEo
BVIQc291cmNlU2NyaXB0TGluZRIwChRzb3VyY2Vfc2NyaXB0X2NvbHVtbhgGIAEoBVISc291
cmNlU2NyaXB0Q29sdW1uEhgKB21lc3NhZ2UYByABKAlSB21lc3NhZ2USJQoOc2NyaXB0X2Nv
bnRleHQYCCABKAlSDXNjcmlwdENvbnRleHQSFgoGYWN0aW9uGAkgASgJUgZhY3Rpb24SFgoG
ZWZmZWN0GAogASgJUgZlZmZlY3QSHwoLb2JqZWN0X25hbWUYCyABKAlSCm9iamVjdE5hbWVC
1QEKJmNvbS5nb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyQhlUcmFuc2xhdGlv
blVzYWJpbGl0eVByb3RvUAFaRGNsb3VkLmdvb2dsZS5jb20vZ28vYmlncXVlcnkvbWlncmF0
aW9uL2FwaXYyL21pZ3JhdGlvbnBiO21pZ3JhdGlvbnBiqgIiR29vZ2xlLkNsb3VkLkJpZ1F1
ZXJ5Lk1pZ3JhdGlvbi5WMsoCIkdvb2dsZVxDbG91ZFxCaWdRdWVyeVxNaWdyYXRpb25cVjJK
4RAKBhIEDgBAAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
KwoJCgIDABIDEgApCgkKAgMBEgMTACMKCAoBCBIDFQA/CgkKAgglEgMVAD8KCAoBCBIDFgBb
CgkKAggLEgMWAFsKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAA6CgkKAggIEgMYADoK
CAoBCBIDGQA/CgkKAggBEgMZAD8KCAoBCBIDGgBACgkKAggpEgMaAEAKSwoCBAASBB0AQAEa
PyBBIHJlY29yZCBpbiB0aGUgYWdncmVnYXRlIENTViByZXBvcnQgZm9yIGEgbWlncmF0aW9u
IHdvcmtmbG93CgoKCgMEAAESAx0IGwoyCgQEAAIAEgMfAhYaJSBTZXZlcml0eSBvZiB0aGUg
dHJhbnNsYXRpb24gcmVjb3JkLgoKDAoFBAACAAUSAx8CCAoMCgUEAAIAARIDHwkRCgwKBQQA
AgADEgMfFBUKQgoEBAACARIDIgIWGjUgQ2F0ZWdvcnkgb2YgdGhlIGVycm9yL3dhcm5pbmcu
IEV4YW1wbGU6IFN5bnRheEVycm9yCgoMCgUEAAIBBRIDIgIICgwKBQQAAgEBEgMiCREKDAoF
BAACAQMSAyIUFQo4CgQEAAICEgMlAhcaKyBUaGUgZmlsZSBwYXRoIGluIHdoaWNoIHRoZSBl
cnJvciBvY2N1cnJlZAoKDAoFBAACAgUSAyUCCAoMCgUEAAICARIDJQkSCgwKBQQAAgIDEgMl
FRYKOAoEBAACAxIDKAIWGisgVGhlIGZpbGUgbmFtZSBpbiB3aGljaCB0aGUgZXJyb3Igb2Nj
dXJyZWQKCgwKBQQAAgMFEgMoAggKDAoFBAACAwESAygJEQoMCgUEAAIDAxIDKBQVCowBCgQE
AAIEEgMsAh8afyBTcGVjaWZpZXMgdGhlIHJvdyBmcm9tIHRoZSBzb3VyY2UgdGV4dCB3aGVy
ZSB0aGUgZXJyb3Igb2NjdXJyZWQgKDAgYmFzZWQsCiAtMSBmb3IgbWVzc2FnZXMgd2l0aG91
dCBsaW5lIGxvY2F0aW9uKS4gRXhhbXBsZTogMgoKDAoFBAACBAUSAywCBwoMCgUEAAIEARID
LAgaCgwKBQQAAgQDEgMsHR4KkwEKBAQAAgUSAzACIRqFASBTcGVjaWZpZXMgdGhlIGNvbHVt
biBmcm9tIHRoZSBzb3VyY2UgdGV4dHMgd2hlcmUgdGhlIGVycm9yIG9jY3VycmVkLiAoMAog
YmFzZWQsIC0xIGZvciBtZXNzYWdlcyB3aXRob3V0IGNvbHVtbiBsb2NhdGlvbikgZXhhbXBs
ZTogNgoKDAoFBAACBQUSAzACBwoMCgUEAAIFARIDMAgcCgwKBQQAAgUDEgMwHyAKLgoEBAAC
BhIDMwIVGiEgRGV0YWlsZWQgbWVzc2FnZSBvZiB0aGUgcmVjb3JkLgoKDAoFBAACBgUSAzMC
CAoMCgUEAAIGARIDMwkQCgwKBQQAAgYDEgMzExQKSgoEBAACBxIDNgIcGj0gVGhlIHNjcmlw
dCBjb250ZXh0IChvYmZ1c2NhdGVkKSBpbiB3aGljaCB0aGUgZXJyb3Igb2NjdXJyZWQKCgwK
BQQAAgcFEgM2AggKDAoFBAACBwESAzYJFwoMCgUEAAIHAxIDNhobCkIKBAQAAggSAzkCFBo1
IENhdGVnb3J5IG9mIHRoZSBlcnJvci93YXJuaW5nLiBFeGFtcGxlOiBTeW50YXhFcnJvcgoK
DAoFBAACCAUSAzkCCAoMCgUEAAIIARIDOQkPCgwKBQQAAggDEgM5EhMKQgoEBAACCRIDPAIV
GjUgRWZmZWN0IG9mIHRoZSBlcnJvci93YXJuaW5nLiBFeGFtcGxlOiBDT01QQVRJQklMSVRZ
CgoMCgUEAAIJBRIDPAIICgwKBQQAAgkBEgM8CQ8KDAoFBAACCQMSAzwSFAo+CgQEAAIKEgM/
AhoaMSBOYW1lIG9mIHRoZSBhZmZlY3RlZCBvYmplY3QgaW4gdGhlIGxvZyBtZXNzYWdlLgoK
DAoFBAACCgUSAz8CCAoMCgUEAAIKARIDPwkUCgwKBQQAAgoDEgM/FxliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationUsability::GcsReportLogMessage ===
    # Fields for GcsReportLogMessage
    # Field: severity Type: 9 ()
    # Field: category Type: 9 ()
    # Field: file_path Type: 9 ()
    # Field: filename Type: 9 ()
    # Field: source_script_line Type: 5 ()
    # Field: source_script_column Type: 5 ()
    # Field: message Type: 9 ()
    # Field: script_context Type: 9 ()
    # Field: action Type: 9 ()
    # Field: effect Type: 9 ()
    # Field: object_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Migration::V2::TranslationUsability - Compiled Protocol Buffers messages for google/cloud/bigquery/migration/v2/translation_usability.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Migration::V2::TranslationUsability;

    my $msg = Google::Cloud::Bigquery::Migration::V2::TranslationUsability::GcsReportLogMessage->new({
        severity => $severity,
        category => $category,
        file_path => $file_path,
        filename => $filename,
    });

    # Read or update a field
    my $val = $msg->severity();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Migration::V2::TranslationUsability::GcsReportLogMessage->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/migration/v2/translation_usability.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationUsability::GcsReportLogMessage

A record in the aggregate CSV report for a migration workflow

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->severity() >> / C<< $msg->severity($value) >>

Type: C<String>

Severity of the translation record.

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<String>

Category of the error/warning. Example: SyntaxError

=item * C<< $msg->file_path() >> / C<< $msg->file_path($value) >>

Type: C<String>

The file path in which the error occurred

=item * C<< $msg->filename() >> / C<< $msg->filename($value) >>

Type: C<String>

The file name in which the error occurred

=item * C<< $msg->source_script_line() >> / C<< $msg->source_script_line($value) >>

Type: C<Int32>

Specifies the row from the source text where the error occurred (0 based,
-1 for messages without line location). Example: 2

=item * C<< $msg->source_script_column() >> / C<< $msg->source_script_column($value) >>

Type: C<Int32>

Specifies the column from the source texts where the error occurred. (0
based, -1 for messages without column location) example: 6

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Detailed message of the record.

=item * C<< $msg->script_context() >> / C<< $msg->script_context($value) >>

Type: C<String>

The script context (obfuscated) in which the error occurred

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<String>

Category of the error/warning. Example: SyntaxError

=item * C<< $msg->effect() >> / C<< $msg->effect($value) >>

Type: C<String>

Effect of the error/warning. Example: COMPATIBILITY

=item * C<< $msg->object_name() >> / C<< $msg->object_name($value) >>

Type: C<String>

Name of the affected object in the log message.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Migration::V2::TranslationUsability::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
