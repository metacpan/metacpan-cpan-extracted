package Google::Cloud::Bigquery::V2::SecureContext;

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
    eval { require Google::Api::Visibility };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvc2VjdXJlX2NvbnRleHQucHJvdG8SGGdvb2ds
ZS5jbG91ZC5iaWdxdWVyeS52MhoZZ29vZ2xlL2FwaS9hdWRpdGluZy5wcm90bxofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoaZ29vZ2xlL2FwaS9pbmNsdXNpb24ucHJvdG8a
G2dvb2dsZS9hcGkvdmlzaWJpbGl0eS5wcm90bxocZ29vZ2xlL3Byb3RvYnVmL3N0cnVjdC5w
cm90byKkAQoNU2VjdXJlQ29udGV4dBJ6ChhzZWN1cmVfcGFyYW1ldGVyX2VudHJpZXMYASAB
KAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0QifgQQH60uSTAhESD0dPT0dMRV9JTlRFUk5B
TOrqgKwDBxIFQVVESVRSFnNlY3VyZVBhcmFtZXRlckVudHJpZXM6F/rS5JMCERIPR09PR0xF
X0lOVEVSTkFMQnwKHGNvbS5nb29nbGUuY2xvdWQuYmlncXVlcnkudjJCElNlY3VyZUNvbnRl
eHRQcm90b1ABWjtjbG91ZC5nb29nbGUuY29tL2dvL2JpZ3F1ZXJ5L3YyL2FwaXYyL2JpZ3F1
ZXJ5cGI7YmlncXVlcnlwYorV29IPBQoDYWxsSokFCgYSBAMAHwEKKAoBDBIDAwASGh4gKC0t
CiBMSU5UOiBMRUdBQ1lfTkFNRVMKIC0tKQoKCAoBAhIDBQAhCgkKAgMAEgMHACMKCQoCAwES
AwgAKQoJCgIDAhIDCQAkCgkKAgMDEgMKACUKCQoCAwQSAwsAJgoICgEIEgMNAFIKCQoCCAsS
Aw0AUgoICgEIEgMOADUKCQoCCAESAw4ANQoICgEIEgMPADMKCQoCCAgSAw8AMwoICgEIEgMQ
ACIKCQoCCAoSAxAAIgoICgEIEgMRAC0KDwoICNG6q/oBAQASAxEALQpHCgIEABIEFAAfARo7
IEEgc2V0IG9mIGtleS12YWx1ZSBwYWlycyByZXByZXNlbnRpbmcgdGhlIHNlY3VyZSBjb250
ZXh0LgoKCgoDBAABEgMUCBUKCgoDBAAHEgMVAkkKDwoIBAAHr8q8IgISAxUCSQrCAQoEBAAC
ABIEGgIeBBqzASBBIHNldCBvZiBrZXktdmFsdWUgcGFpcnMgcmVwcmVzZW50aW5nIHRoZSBz
ZWN1cmUgcGFyYW1ldGVyIHZhbHVlcy4gVGhleSBjYW4KIGJlIHJldHJpZXZlZCB2aWEgdGhl
IFNFQ1VSRV9DT05URVhUKCkgZnVuY3Rpb24gYW5kIHVzZWQgdG8gbW9kaWZ5IHRoZQogcnVu
LXRpbWUgYmVoYXZpb3Igb2YgYSBxdWVyeS4KCgwKBQQAAgAGEgMaAhgKDAoFBAACAAESAxoZ
MQoMCgUEAAIAAxIDGjQ1Cg0KBQQAAgAIEgQaNh4DChEKCgQAAgAIrY3ANQISAxsEMwoPCggE
AAIACJwIABIDHAQqChEKCgQAAgAIr8q8IgISAx0EQWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::SecureContext::SecureContext ===
    # Fields for SecureContext
    # Field: secure_parameter_entries Type: 11 (.google.protobuf.Struct)

1;
