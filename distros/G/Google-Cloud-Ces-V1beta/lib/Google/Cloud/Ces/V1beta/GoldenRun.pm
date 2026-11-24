package Google::Cloud::Ces::V1beta::GoldenRun;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9nb2xkZW5fcnVuLnByb3RvEhdnb29nbGUuY2xv
dWQuY2VzLnYxYmV0YSpLCg9Hb2xkZW5SdW5NZXRob2QSIQodR09MREVOX1JVTl9NRVRIT0Rf
VU5TUEVDSUZJRUQQABIKCgZTVEFCTEUQARIJCgVOQUlWRRACQl4KG2NvbS5nb29nbGUuY2xv
dWQuY2VzLnYxYmV0YUIOR29sZGVuUnVuUHJvdG9QAVotY2xvdWQuZ29vZ2xlLmNvbS9nby9j
ZXMvYXBpdjFiZXRhL2Nlc3BiO2Nlc3BiSusICgYSBA4AIwEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACAKCAoBCBIDEgBECgkKAggLEgMSAEQKCAoBCBID
EwAiCgkKAggKEgMTACIKCAoBCBIDFAAvCgkKAggIEgMUAC8KCAoBCBIDFQA0CgkKAggBEgMV
ADQKNAoCBQASBBgAIwEaKCBUaGUgbWV0aG9kIHVzZWQgdG8gcnVuIHRoZSBldmFsdWF0aW9u
LgoKCgoDBQABEgMYBRQKKwoEBQACABIDGgIkGh4gUnVuIG1ldGhvZCBpcyBub3Qgc3BlY2lm
aWVkLgoKDAoFBQACAAESAxoCHwoMCgUFAAIAAhIDGiIjCo8BCgQFAAIBEgMeAg0agQEgUnVu
IHRoZSBldmFsdWF0aW9uIGFzIHN0YWJsZSByZXBsYXksIHdoZXJlIGVhY2ggdHVybiBpcyBh
IHVuaXF1ZSBzZXNzaW9uCiB3aXRoIHRoZSBwcmV2aW91cyBleHBlY3RlZCB0dXJucyBpbmpl
Y3RlZCBhcyBjb250ZXh0LgoKDAoFBQACAQESAx4CCAoMCgUFAAIBAhIDHgsMCm8KBAUAAgIS
AyICDBpiIFJ1biB0aGUgZXZhbHVhdGlvbiBhcyBuYWl2ZSByZXBsYXksIHdoZXJlIHRoZSBy
dW4gaXMgYSBzaW5nbGUKIHNlc3Npb24gd2l0aCBubyBjb250ZXh0IGluamVjdGVkLgoKDAoF
BQACAgESAyICBwoMCgUFAAICAhIDIgoLYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::GoldenRun - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/golden_run.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/golden_run.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::GoldenRun::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
