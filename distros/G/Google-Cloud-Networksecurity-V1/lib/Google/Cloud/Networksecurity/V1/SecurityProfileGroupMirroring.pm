package Google::Cloud::Networksecurity::V1::SecurityProfileGroupMirroring;

use strict;
use warnings;

our $VERSION = '0.11';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
CkZnb29nbGUvY2xvdWQvbmV0d29ya3NlY3VyaXR5L3YxL3NlY3VyaXR5X3Byb2ZpbGVfZ3Jv
dXBfbWlycm9yaW5nLnByb3RvEh9nb29nbGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxGh9n
b29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnBy
b3RvIpQBChZDdXN0b21NaXJyb3JpbmdQcm9maWxlEnoKGG1pcnJvcmluZ19lbmRwb2ludF9n
cm91cBgBIAEoCUJA4EEC4EEF+kE3CjVuZXR3b3Jrc2VjdXJpdHkuZ29vZ2xlYXBpcy5jb20v
TWlycm9yaW5nRW5kcG9pbnRHcm91cFIWbWlycm9yaW5nRW5kcG9pbnRHcm91cEKDAgojY29t
Lmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFCIlNlY3VyaXR5UHJvZmlsZUdyb3Vw
TWlycm9yaW5nUHJvdG9QAVpNY2xvdWQuZ29vZ2xlLmNvbS9nby9uZXR3b3Jrc2VjdXJpdHkv
YXBpdjEvbmV0d29ya3NlY3VyaXR5cGI7bmV0d29ya3NlY3VyaXR5cGKqAh9Hb29nbGUuQ2xv
dWQuTmV0d29ya1NlY3VyaXR5LlYxygIfR29vZ2xlXENsb3VkXE5ldHdvcmtTZWN1cml0eVxW
MeoCIkdvb2dsZTo6Q2xvdWQ6Ok5ldHdvcmtTZWN1cml0eTo6VjFK5QkKBhIEDgAqAQq8BAoB
DBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0
aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBt
YXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGlj
ZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBo
dHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVx
dWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3
YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBh
biAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0Yg
QU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2Ug
Zm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBs
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgApCgkK
AgMBEgMTACMKCAoBCBIDFQA8CgkKAgglEgMVADwKCAoBCBIDFgBkCgkKAggLEgMWAGQKCAoB
CBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGABDCgkKAggIEgMYAEMKCAoBCBIDGQA8CgkKAggB
EgMZADwKCAoBCBIDGgA8CgkKAggpEgMaADwKCAoBCBIDGwA7CgkKAggtEgMbADsKkAEKAgQA
EgQfACoBGoMBIEN1c3RvbU1pcnJvcmluZ1Byb2ZpbGUgZGVmaW5lcyBvdXQtb2YtYmFuZCBp
bnRlZ3JhdGlvbiBiZWhhdmlvciAobWlycm9yaW5nKS4KIEl0IGlzIHVzZWQgYnkgbWlycm9y
aW5nIHJ1bGVzIHdpdGggYSBNSVJST1IgYWN0aW9uLgoKCgoDBAABEgMfCB4K3QEKBAQAAgAS
BCMCKQQazgEgUmVxdWlyZWQuIEltbXV0YWJsZS4gVGhlIHRhcmdldCBNaXJyb3JpbmdFbmRw
b2ludEdyb3VwLgogV2hlbiBhIG1pcnJvcmluZyBydWxlIHdpdGggdGhpcyBzZWN1cml0eSBw
cm9maWxlIGF0dGFjaGVkIG1hdGNoZXMgYSBwYWNrZXQsCiBhIHJlcGxpY2Egd2lsbCBiZSBt
aXJyb3JlZCB0byB0aGUgbG9jYXRpb24tbG9jYWwgdGFyZ2V0IGluIHRoaXMgZ3JvdXAuCgoM
CgUEAAIABRIDIwIICgwKBQQAAgABEgMjCSEKDAoFBAACAAMSAyMkJQoNCgUEAAIACBIEIyYp
AwoPCggEAAIACJwIABIDJAQqCg8KCAQAAgAInAgBEgMlBCsKDwoHBAACAAifCBIEJgQoBWIG
cHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networksecurity::V1::SecurityProfileGroupMirroring::CustomMirroringProfile ===
    # Fields for CustomMirroringProfile
    # Field: mirroring_endpoint_group Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Networksecurity::V1::SecurityProfileGroupMirroring::CustomMirroringProfile - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::SecurityProfileGroupMirroring;

    my $msg = Google::Cloud::Networksecurity::V1::SecurityProfileGroupMirroring::CustomMirroringProfile->new(
        mirroring_endpoint_group => $value,
    );

=head1 FIELDS

=over 4

=item * B<mirroring_endpoint_group>

Type: String

=back

=cut

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::SecurityProfileGroupMirroring - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
