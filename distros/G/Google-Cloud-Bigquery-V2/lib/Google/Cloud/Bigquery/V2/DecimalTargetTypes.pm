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

package Google::Cloud::Bigquery::V2::DecimalTargetTypes;

use strict;
use warnings;
use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Inclusion };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvZGVjaW1hbF90YXJnZXRfdHlwZXMucHJvdG8S
GGdvb2dsZS5jbG91ZC5iaWdxdWVyeS52MhoaZ29vZ2xlL2FwaS9pbmNsdXNpb24ucHJvdG8q
YQoRRGVjaW1hbFRhcmdldFR5cGUSIwofREVDSU1BTF9UQVJHRVRfVFlQRV9VTlNQRUNJRklF
RBAAEgsKB05VTUVSSUMQARIOCgpCSUdOVU1FUklDEAISCgoGU1RSSU5HEANCgQEKHGNvbS5n
b29nbGUuY2xvdWQuYmlncXVlcnkudjJCF0RlY2ltYWxUYXJnZXRUeXBlc1Byb3RvUAFaO2Ns
b3VkLmdvb2dsZS5jb20vZ28vYmlncXVlcnkvdjIvYXBpdjIvYmlncXVlcnlwYjtiaWdxdWVy
eXBiitXb0g8FCgNhbGxK4AQKBhIEAAAZAQoICgEMEgMAABIKCAoBAhIDAgAhCgkKAgMAEgME
ACQKCAoBCBIDBgBSCgkKAggLEgMGAFIKCAoBCBIDBwAiCgkKAggKEgMHACIKCAoBCBIDCAA1
CgkKAggBEgMIADUKCAoBCBIDCQA4CgkKAggIEgMJADgKCAoBCBIDCgAtCg8KCAjRuqv6AQEA
EgMKAC0KYQoCBQASBA4AGQEaVSBUaGUgZGF0YSB0eXBlcyB0aGF0IGNvdWxkIGJlIHVzZWQg
YXMgYSB0YXJnZXQgdHlwZSB3aGVuIGNvbnZlcnRpbmcgZGVjaW1hbAogdmFsdWVzLgoKCgoD
BQABEgMOBRYKHAoEBQACABIDEAImGg8gSW52YWxpZCB0eXBlLgoKDAoFBQACAAESAxACIQoM
CgUFAAIAAhIDECQlCkIKBAUAAgESAxMCDho1IERlY2ltYWwgdmFsdWVzIGNvdWxkIGJlIGNv
bnZlcnRlZCB0byBOVU1FUklDCiB0eXBlLgoKDAoFBQACAQESAxMCCQoMCgUFAAIBAhIDEwwN
CkUKBAUAAgISAxYCERo4IERlY2ltYWwgdmFsdWVzIGNvdWxkIGJlIGNvbnZlcnRlZCB0byBC
SUdOVU1FUklDCiB0eXBlLgoKDAoFBQACAgESAxYCDAoMCgUFAAICAhIDFg8QCkAKBAUAAgMS
AxgCDRozIERlY2ltYWwgdmFsdWVzIGNvdWxkIGJlIGNvbnZlcnRlZCB0byBTVFJJTkcgdHlw
ZS4KCgwKBQUAAgMBEgMYAggKDAoFBQACAwISAxgLDGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

1;
