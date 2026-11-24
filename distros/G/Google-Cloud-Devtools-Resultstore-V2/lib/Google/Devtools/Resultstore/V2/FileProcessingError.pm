package Google::Devtools::Resultstore::V2::FileProcessingError;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvZGV2dG9vbHMvcmVzdWx0c3RvcmUvdjIvZmlsZV9wcm9jZXNzaW5nX2Vycm9y
LnByb3RvEh5nb29nbGUuZGV2dG9vbHMucmVzdWx0c3RvcmUudjIinAEKFEZpbGVQcm9jZXNz
aW5nRXJyb3JzEhkKCGZpbGVfdWlkGAEgASgJUgdmaWxlVWlkEmkKFmZpbGVfcHJvY2Vzc2lu
Z19lcnJvcnMYAyADKAsyMy5nb29nbGUuZGV2dG9vbHMucmVzdWx0c3RvcmUudjIuRmlsZVBy
b2Nlc3NpbmdFcnJvclIUZmlsZVByb2Nlc3NpbmdFcnJvcnMifAoTRmlsZVByb2Nlc3NpbmdF
cnJvchJLCgR0eXBlGAEgASgOMjcuZ29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyLkZp
bGVQcm9jZXNzaW5nRXJyb3JUeXBlUgR0eXBlEhgKB21lc3NhZ2UYAiABKAlSB21lc3NhZ2Uq
6QEKF0ZpbGVQcm9jZXNzaW5nRXJyb3JUeXBlEioKJkZJTEVfUFJPQ0VTU0lOR19FUlJPUl9U
WVBFX1VOU1BFQ0lGSUVEEAASFgoSR0VORVJJQ19SRUFEX0VSUk9SEAESFwoTR0VORVJJQ19Q
QVJTRV9FUlJPUhACEhIKDkZJTEVfVE9PX0xBUkdFEAMSFAoQT1VUUFVUX1RPT19MQVJHRRAE
EhEKDUFDQ0VTU19ERU5JRUQQBRIVChFERUFETElORV9FWENFRURFRBAGEg0KCU5PVF9GT1VO
RBAHEg4KCkZJTEVfRU1QVFkQCEKLAQoiY29tLmdvb2dsZS5kZXZ0b29scy5yZXN1bHRzdG9y
ZS52MkIYRmlsZVByb2Nlc3NpbmdFcnJvclByb3RvUAFaSWdvb2dsZS5nb2xhbmcub3JnL2dl
bnByb3RvL2dvb2dsZWFwaXMvZGV2dG9vbHMvcmVzdWx0c3RvcmUvdjI7cmVzdWx0c3RvcmVK
qxAKBhIEDgBFAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBM
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
JwoICgEIEgMSAGAKCQoCCAsSAxIAYAoICgEIEgMTACIKCQoCCAoSAxMAIgoICgEIEgMUADkK
CQoCCAgSAxQAOQoICgEIEgMVADsKCQoCCAESAxUAOwpNCgIEABIEGAAeARpBIFN0b3JlcyBl
cnJvcnMgcmVhZGluZyBvciBwYXJzaW5nIGEgZmlsZSBkdXJpbmcgcG9zdC1wcm9jZXNzaW5n
LgoKCgoDBAABEgMYCBwKOAoEBAACABIDGgIWGisgVGhlIHVpZCBvZiB0aGUgRmlsZSBiZWlu
ZyByZWFkIG9yIHBhcnNlZC4KCgwKBQQAAgAFEgMaAggKDAoFBAACAAESAxoJEQoMCgUEAAIA
AxIDGhQVCh8KBAQAAgESAx0COhoSIFdoYXQgd2VudCB3cm9uZy4KCgwKBQQAAgEEEgMdAgoK
DAoFBAACAQYSAx0LHgoMCgUEAAIBARIDHR81CgwKBQQAAgEDEgMdODkKTwoCBAESBCEAJwEa
QyBTdG9yZXMgYW4gZXJyb3IgcmVhZGluZyBvciBwYXJzaW5nIGEgZmlsZSBkdXJpbmcgcG9z
dC1wcm9jZXNzaW5nLgoKCgoDBAEBEgMhCBsKLwoEBAECABIDIwIjGiIgVGhlIHR5cGUgb2Yg
ZXJyb3IgdGhhdCBvY2N1cnJlZC4KCgwKBQQBAgAGEgMjAhkKDAoFBAECAAESAyMaHgoMCgUE
AQIAAxIDIyEiCjQKBAQBAgESAyYCFRonIEVycm9yIG1lc3NhZ2UgZGVzY3JpYmluZyB0aGUg
cHJvYmxlbS4KCgwKBQQBAgEFEgMmAggKDAoFBAECAQESAyYJEAoMCgUEAQIBAxIDJhMUCk0K
AgUAEgQqAEUBGkEgRXJyb3JzIGluIGZpbGUgcG9zdC1wcm9jZXNzaW5nIGFyZSBjYXRlZ29y
aXplZCB1c2luZyB0aGlzIGVudW0uCgoKCgMFAAESAyoFHAozCgQFAAIAEgMsAi0aJiBUeXBl
IHVuc3BlY2lmaWVkIG9yIG5vdCBsaXN0ZWQgaGVyZS4KCgwKBQUAAgABEgMsAigKDAoFBQAC
AAISAywrLAo9CgQFAAIBEgMvAhkaMCBBIHJlYWQgZXJyb3Igb2NjdXJyZWQgdHJ5aW5nIHRv
IHJlYWQgdGhlIGZpbGUuCgoMCgUFAAIBARIDLwIUCgwKBQUAAgECEgMvFxgKOwoEBQACAhID
MgIaGi4gVGhlcmUgd2FzIGFuIGVycm9yIHRyeWluZyB0byBwYXJzZSB0aGUgZmlsZS4KCgwK
BQUAAgIBEgMyAhUKDAoFBQACAgISAzIYGQoqCgQFAAIDEgM1AhUaHSBGaWxlIGlzIGV4Y2Vl
ZHMgc2l6ZSBsaW1pdC4KCgwKBQUAAgMBEgM1AhAKDAoFBQACAwISAzUTFApCCgQFAAIEEgM4
AhcaNSBUaGUgcmVzdWx0IG9mIHBhcnNpbmcgdGhlIGZpbGUgZXhjZWVkZWQgc2l6ZSBsaW1p
dC4KCgwKBQUAAgQBEgM4AhIKDAoFBQACBAISAzgVFgpBCgQFAAIFEgM7AhQaNCBSZWFkIGFj
Y2VzcyB0byB0aGUgZmlsZSB3YXMgZGVuaWVkIGJ5IGZpbGUgc3lzdGVtLgoKDAoFBQACBQES
AzsCDwoMCgUFAAIFAhIDOxITCjkKBAUAAgYSAz4CGBosIERlYWRsaW5lIGV4Y2VlZGVkIHRy
eWluZyB0byByZWFkIHRoZSBmaWxlLgoKDAoFBQACBgESAz4CEwoMCgUFAAIGAhIDPhYXCh4K
BAUAAgcSA0ECEBoRIEZpbGUgbm90IGZvdW5kLgoKDAoFBQACBwESA0ECCwoMCgUFAAIHAhID
QQ4PCj4KBAUAAggSA0QCERoxIEZpbGUgaXMgZW1wdHkgYnV0IHdhcyBleHBlY3RlZCB0byBo
YXZlIGNvbnRlbnQuCgoMCgUFAAIIARIDRAIMCgwKBQUAAggCEgNEDxBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Resultstore::V2::FileProcessingError::FileProcessingErrors ===
    # Fields for FileProcessingErrors
    # Field: file_uid Type: 9 ()
    # Field: file_processing_errors Type: 11 (.google.devtools.resultstore.v2.FileProcessingError)

# === Message: Google::Devtools::Resultstore::V2::FileProcessingError::FileProcessingError ===
    # Fields for FileProcessingError
    # Field: type Type: 14 (.google.devtools.resultstore.v2.FileProcessingErrorType)
    # Field: message Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Resultstore::V2::FileProcessingError - Compiled Protocol Buffers messages for google/devtools/resultstore/v2/file_processing_error.proto

=head1 SYNOPSIS

    use Google::Devtools::Resultstore::V2::FileProcessingError;

    my $msg = Google::Devtools::Resultstore::V2::FileProcessingError::FileProcessingErrors->new({
        file_uid => $file_uid,
        file_processing_errors => $file_processing_errors,
    });

    # Read or update a field
    my $val = $msg->file_uid();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Resultstore::V2::FileProcessingError::FileProcessingErrors->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/resultstore/v2/file_processing_error.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Resultstore::V2::FileProcessingError::FileProcessingErrors

Stores errors reading or parsing a file during post-processing.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->file_uid() >> / C<< $msg->file_uid($value) >>

Type: C<String>

The uid of the File being read or parsed.

=item * C<< $msg->file_processing_errors() >> / C<< $msg->file_processing_errors($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::FileProcessingError::FileProcessingError>)

What went wrong.

=back

=head2 Google::Devtools::Resultstore::V2::FileProcessingError::FileProcessingError

Stores an error reading or parsing a file during post-processing.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Devtools::Resultstore::V2::FileProcessingErrorType>)

The type of error that occurred.

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Error message describing the problem.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Resultstore::V2::FileProcessingError::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
