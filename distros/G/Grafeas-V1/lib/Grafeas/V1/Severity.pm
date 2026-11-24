package Grafeas::V1::Severity;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
ChlncmFmZWFzL3YxL3NldmVyaXR5LnByb3RvEgpncmFmZWFzLnYxKl4KCFNldmVyaXR5EhgK
FFNFVkVSSVRZX1VOU1BFQ0lGSUVEEAASCwoHTUlOSU1BTBABEgcKA0xPVxACEgoKBk1FRElV
TRADEggKBEhJR0gQBBIMCghDUklUSUNBTBAFQlEKDWlvLmdyYWZlYXMudjFQAVo4Z29vZ2xl
LmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9ncmFmZWFzL3YxO2dyYWZlYXOiAgNH
UkFK8ggKBhIEDgAlAQraBAoBDBIDDgASMs8EIENvcHlyaWdodCAyMDIxIFRoZSBHcmFmZWFz
IEF1dGhvcnMuIEFsbCByaWdodHMgcmVzZXJ2ZWQuCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAEwoICgEIEgMSAE8KCQoCCAsSAxIA
TwoICgEIEgMTACIKCQoCCAoSAxMAIgoICgEIEgMUACYKCQoCCAESAxQAJgoICgEIEgMVACEK
CQoCCCQSAxUAIQo9CgIFABIEGAAlARoxIE5vdGUgcHJvdmlkZXIgYXNzaWduZWQgc2V2ZXJp
dHkvaW1wYWN0IHJhbmtpbmcuCgoKCgMFAAESAxgFDQoXCgQFAAIAEgMaAhsaCiBVbmtub3du
LgoKDAoFBQACAAESAxoCFgoMCgUFAAIAAhIDGhkaCiAKBAUAAgESAxwCDhoTIE1pbmltYWwg
c2V2ZXJpdHkuCgoMCgUFAAIBARIDHAIJCgwKBQUAAgECEgMcDA0KHAoEBQACAhIDHgIKGg8g
TG93IHNldmVyaXR5LgoKDAoFBQACAgESAx4CBQoMCgUFAAICAhIDHggJCh8KBAUAAgMSAyAC
DRoSIE1lZGl1bSBzZXZlcml0eS4KCgwKBQUAAgMBEgMgAggKDAoFBQACAwISAyALDAodCgQF
AAIEEgMiAgsaECBIaWdoIHNldmVyaXR5LgoKDAoFBQACBAESAyICBgoMCgUFAAIEAhIDIgkK
CiEKBAUAAgUSAyQCDxoUIENyaXRpY2FsIHNldmVyaXR5LgoKDAoFBQACBQESAyQCCgoMCgUF
AAIFAhIDJA0OYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

1;

__END__

=encoding UTF-8

=head1 NAME

Grafeas::V1::Severity - Compiled Protocol Buffers messages for grafeas/v1/severity.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<grafeas/v1/severity.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Grafeas::V1::Severity::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
