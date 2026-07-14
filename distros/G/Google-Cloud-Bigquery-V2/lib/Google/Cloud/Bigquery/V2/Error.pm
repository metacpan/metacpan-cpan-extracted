package Google::Cloud::Bigquery::V2::Error;

use strict;
use warnings;

our $VERSION = '0.05';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Auditing };
    eval { require Google::Api::Inclusion };
    my $descriptor_b64 = <<'EOF';
CiRnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvZXJyb3IucHJvdG8SGGdvb2dsZS5jbG91ZC5i
aWdxdWVyeS52MhoZZ29vZ2xlL2FwaS9hdWRpdGluZy5wcm90bxoaZ29vZ2xlL2FwaS9pbmNs
dXNpb24ucHJvdG8itQEKCkVycm9yUHJvdG8SJQoGcmVhc29uGAEgASgJQg3q6oCsAwcSBUFV
RElUUgZyZWFzb24SKQoIbG9jYXRpb24YAiABKAlCDerqgKwDBxIFQVVESVRSCGxvY2F0aW9u
EiwKCmRlYnVnX2luZm8YAyABKAlCDerqgKwDBxIFQVVESVRSCWRlYnVnSW5mbxInCgdtZXNz
YWdlGAQgASgJQg3q6oCsAwcSBUFVRElUUgdtZXNzYWdlQmYKHGNvbS5nb29nbGUuY2xvdWQu
YmlncXVlcnkudjJaO2Nsb3VkLmdvb2dsZS5jb20vZ28vYmlncXVlcnkvdjIvYXBpdjIvYmln
cXVlcnlwYjtiaWdxdWVyeXBiitXb0g8FCgNhbGxKiQcKBhIEAAAfAQoICgEMEgMAABIKCAoB
AhIDAgAhCgkKAgMAEgMEACMKCQoCAwESAwUAJAoICgEIEgMHAFIKCQoCCAsSAwcAUgoICgEI
EgMIADUKCQoCCAESAwgANQoICgEIEgMJAC0KDwoICNG6q/oBAQASAwkALQq6AQoCBAASBBIA
HwEarQEgRXJyb3IgZGV0YWlscy4KCiAoLS0KIE1pcnJvcnMgQXBpYXJ5IGRlZmluaXRpb24g
YXQKIGdvb2dsZWRhdGEvYXBpc2VydmluZy9jb25maWcvY2xvdWQvaGVsaXgvdjIvdGVtcGxh
dGVzL2Vycm9yUHJvdG8uanNvbnQKIEl0IGNhbiBiZSBzaGFyZWQgYW1vbmcgZGlmZmVyZW50
IHNlcnZpY2VzLgogLS0pCgoKCgMEAAESAxIIEgo8CgQEAAIAEgMUAkYaLyBBIHNob3J0IGVy
cm9yIGNvZGUgdGhhdCBzdW1tYXJpemVzIHRoZSBlcnJvci4KCgwKBQQAAgAFEgMUAggKDAoF
BAACAAESAxQJDwoMCgUEAAIAAxIDFBITCgwKBQQAAgAIEgMUFEUKEQoKBAACAAitjcA1AhID
FBVECj4KBAQAAgESAxcCSBoxIFNwZWNpZmllcyB3aGVyZSB0aGUgZXJyb3Igb2NjdXJyZWQs
IGlmIHByZXNlbnQuCgoMCgUEAAIBBRIDFwIICgwKBQQAAgEBEgMXCREKDAoFBAACAQMSAxcU
FQoMCgUEAAIBCBIDFxZHChEKCgQAAgEIrY3ANQISAxcXRgpiCgQEAAICEgMbAkoaVSBEZWJ1
Z2dpbmcgaW5mb3JtYXRpb24uIFRoaXMgcHJvcGVydHkgaXMgaW50ZXJuYWwgdG8gR29vZ2xl
IGFuZCBzaG91bGQgbm90CiBiZSB1c2VkLgoKDAoFBAACAgUSAxsCCAoMCgUEAAICARIDGwkT
CgwKBQQAAgIDEgMbFhcKDAoFBAACAggSAxsYSQoRCgoEAAICCK2NwDUCEgMbGUgKOQoEBAAC
AxIDHgJHGiwgQSBodW1hbi1yZWFkYWJsZSBkZXNjcmlwdGlvbiBvZiB0aGUgZXJyb3IuCgoM
CgUEAAIDBRIDHgIICgwKBQQAAgMBEgMeCRAKDAoFBAACAwMSAx4TFAoMCgUEAAIDCBIDHhVG
ChEKCgQAAgMIrY3ANQISAx4WRWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::Error::ErrorProto ===
    # Fields for ErrorProto
    # Field: reason Type: 9 ()
    # Field: location Type: 9 ()
    # Field: debug_info Type: 9 ()
    # Field: message Type: 9 ()

1;
