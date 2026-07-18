# Copyright (C) 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package Google::Cloud::Bigquery::V2::SessionInfo;

use strict;
use warnings;
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
