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

package Google::Cloud::Bigquery::V2::MapTargetType;

use strict;
use warnings;
use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Inclusion };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvbWFwX3RhcmdldF90eXBlLnByb3RvEhhnb29n
bGUuY2xvdWQuYmlncXVlcnkudjIaGmdvb2dsZS9hcGkvaW5jbHVzaW9uLnByb3RvKkUKDU1h
cFRhcmdldFR5cGUSHwobTUFQX1RBUkdFVF9UWVBFX1VOU1BFQ0lGSUVEEAASEwoPQVJSQVlf
T0ZfU1RSVUNUEAFCfAocY29tLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS52MkISTWFwVGFyZ2V0
VHlwZVByb3RvUAFaO2Nsb3VkLmdvb2dsZS5jb20vZ28vYmlncXVlcnkvdjIvYXBpdjIvYmln
cXVlcnlwYjtiaWdxdWVyeXBiitXb0g8FCgNhbGxKrAQKBhIEAAAUAQoICgEMEgMAABIKCAoB
AhIDAgAhCgkKAgMAEgMEACQKCAoBCBIDBgBSCgkKAggLEgMGAFIKCAoBCBIDBwAiCgkKAggK
EgMHACIKCAoBCBIDCAA1CgkKAggBEgMIADUKCAoBCBIDCQAzCgkKAggIEgMJADMKCAoBCBID
CgAtCg8KCAjRuqv6AQEAEgMKAC0KSgoCBQASBA0AFAEaPiBJbmRpY2F0ZXMgdGhlIG1hcCB0
YXJnZXQgdHlwZS4gT25seSBhcHBsaWVzIHRvIHBhcnF1ZXQgbWFwcy4KCgoKAwUAARIDDQUS
CowBCgQFAAIAEgMQAiIafyBJbiB0aGlzIG1vZGUsIHRoZSBtYXAgd2lsbCBoYXZlIHRoZSBm
b2xsb3dpbmcgc2NoZW1hOgogc3RydWN0IG1hcF9maWVsZF9uYW1lIHsgIHJlcGVhdGVkIHN0
cnVjdCBrZXlfdmFsdWUgeyAga2V5ICB2YWx1ZSAgfSB9LgoKDAoFBQACAAESAxACHQoMCgUF
AAIAAhIDECAhCnUKBAUAAgESAxMCFhpoIEluIHRoaXMgbW9kZSwgdGhlIG1hcCB3aWxsIGhh
dmUgdGhlIGZvbGxvd2luZyBzY2hlbWE6CiByZXBlYXRlZCBzdHJ1Y3QgbWFwX2ZpZWxkX25h
bWUgeyAga2V5ICB2YWx1ZSB9LgoKDAoFBQACAQESAxMCEQoMCgUFAAIBAhIDExQVYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

1;
