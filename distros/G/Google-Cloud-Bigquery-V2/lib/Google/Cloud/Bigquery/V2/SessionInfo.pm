package Google::Cloud::Bigquery::V2::SessionInfo;

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
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvc2Vzc2lvbl9pbmZvLnByb3RvEhhnb29nbGUu
Y2xvdWQuYmlncXVlcnkudjIaGWdvb2dsZS9hcGkvYXVkaXRpbmcucHJvdG8aH2dvb2dsZS9h
cGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGmdvb2dsZS9hcGkvaW5jbHVzaW9uLnByb3RvIj4K
C1Nlc3Npb25JbmZvEi8KCnNlc3Npb25faWQYASABKAlCEOBBA+rqgKwDBxIFQVVESVRSCXNl
c3Npb25JZEJ6Chxjb20uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyQhBTZXNzaW9uSW5mb1By
b3RvUAFaO2Nsb3VkLmdvb2dsZS5jb20vZ28vYmlncXVlcnkvdjIvYXBpdjIvYmlncXVlcnlw
YjtiaWdxdWVyeXBiitXb0g8FCgNhbGxK9wIKBhIEAAAVAQoICgEMEgMAABIKCAoBAhIDAgAh
CgkKAgMAEgMEACMKCQoCAwESAwUAKQoJCgIDAhIDBgAkCggKAQgSAwgAUgoJCgIICxIDCABS
CggKAQgSAwkANQoJCgIIARIDCQA1CggKAQgSAwoAIgoJCgIIChIDCgAiCggKAQgSAwsAMQoJ
CgIICBIDCwAxCggKAQgSAwwALQoPCggI0bqr+gEBABIDDAAtCjgKAgQAEgQPABUBGiwgW1By
ZXZpZXddIEluZm9ybWF0aW9uIHJlbGF0ZWQgdG8gc2Vzc2lvbnMuCgoKCgMEAAESAw8IEwom
CgQEAAIAEgQRAhQEGhggVGhlIGlkIG9mIHRoZSBzZXNzaW9uLgoKDAoFBAACAAUSAxECCAoM
CgUEAAIAARIDEQkTCgwKBQQAAgADEgMRFhcKDQoFBAACAAgSBBEYFAMKDwoIBAACAAicCAAS
AxIELQoRCgoEAAIACK2NwDUCEgMTBDNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::SessionInfo::SessionInfo ===
    # Fields for SessionInfo
    # Field: session_id Type: 9 ()

1;
