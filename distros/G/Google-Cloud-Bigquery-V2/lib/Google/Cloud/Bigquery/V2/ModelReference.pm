package Google::Cloud::Bigquery::V2::ModelReference;

use strict;
use warnings;

our $VERSION = '0.05';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Auditing };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Inclusion };
    eval { require Google::Api::Policy };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvbW9kZWxfcmVmZXJlbmNlLnByb3RvEhhnb29n
bGUuY2xvdWQuYmlncXVlcnkudjIaGWdvb2dsZS9hcGkvYXVkaXRpbmcucHJvdG8aH2dvb2ds
ZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGmdvb2dsZS9hcGkvaW5jbHVzaW9uLnByb3Rv
Ghdnb29nbGUvYXBpL3BvbGljeS5wcm90byK6AQoOTW9kZWxSZWZlcmVuY2USOAoKcHJvamVj
dF9pZBgBIAEoCUIZ4EEC6uqArAMHEgVBVURJVML2jNwEA4ABAVIJcHJvamVjdElkEjgKCmRh
dGFzZXRfaWQYAiABKAlCGeBBAurqgKwDBxIFQVVESVTC9ozcBAOAAQFSCWRhdGFzZXRJZBI0
Cghtb2RlbF9pZBgDIAEoCUIZ4EEC6uqArAMHEgVBVURJVML2jNwEA4ABAVIHbW9kZWxJZEJ7
Chxjb20uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyQhNNb2RlbFJlZmVyZW5jZVByb3RvWjtj
bG91ZC5nb29nbGUuY29tL2dvL2JpZ3F1ZXJ5L3YyL2FwaXYyL2JpZ3F1ZXJ5cGI7YmlncXVl
cnlwYorV29IPBQoDYWxsSr8GCgYSBAAAJAEKCAoBDBIDAAASCggKAQISAwIAIQoJCgIDABID
BAAjCgkKAgMBEgMFACkKCQoCAwISAwYAJAoJCgIDAxIDBwAhCggKAQgSAwkAUgoJCgIICxID
CQBSCggKAQgSAwoANQoJCgIIARIDCgA1CggKAQgSAwsANAoJCgIICBIDCwA0CggKAQgSAwwA
LQoPCggI0bqr+gEBABIDDAAtCiEKAgQAEgQPACQBGhUgSWQgcGF0aCBvZiBhIG1vZGVsLgoK
CgoDBAABEgMPCBYKPAoEBAACABIEEQIVBBouIFRoZSBJRCBvZiB0aGUgcHJvamVjdCBjb250
YWluaW5nIHRoaXMgbW9kZWwuCgoMCgUEAAIABRIDEQIICgwKBQQAAgABEgMRCRMKDAoFBAAC
AAMSAxEWFwoNCgUEAAIACBIEERgVAwoPCggEAAIACJwIABIDEgQqChEKCgQAAgAIrY3ANQIS
AxMEMwoRCgoEAAIACOjOwUsQEgMUBEYKPAoEBAACARIEFwIbBBouIFRoZSBJRCBvZiB0aGUg
ZGF0YXNldCBjb250YWluaW5nIHRoaXMgbW9kZWwuCgoMCgUEAAIBBRIDFwIICgwKBQQAAgEB
EgMXCRMKDAoFBAACAQMSAxcWFwoNCgUEAAIBCBIEFxgbAwoPCggEAAIBCJwIABIDGAQqChEK
CgQAAgEIrY3ANQISAxkEMwoRCgoEAAIBCOjOwUsQEgMaBEYKnwEKBAQAAgISBB8CIwQakAEg
VGhlIElEIG9mIHRoZSBtb2RlbC4gVGhlIElEIG11c3QgY29udGFpbiBvbmx5CiBsZXR0ZXJz
IChhLXosIEEtWiksIG51bWJlcnMgKDAtOSksIG9yIHVuZGVyc2NvcmVzIChfKS4gVGhlIG1h
eGltdW0KIGxlbmd0aCBpcyAxLDAyNCBjaGFyYWN0ZXJzLgoKDAoFBAACAgUSAx8CCAoMCgUE
AAICARIDHwkRCgwKBQQAAgIDEgMfFBUKDQoFBAACAggSBB8WIwMKDwoIBAACAgicCAASAyAE
KgoRCgoEAAICCK2NwDUCEgMhBDMKEQoKBAACAgjozsFLEBIDIgRGYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::ModelReference::ModelReference ===
    # Fields for ModelReference
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: model_id Type: 9 ()

1;
