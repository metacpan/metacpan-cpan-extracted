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

package Google::Cloud::Bigquery::V2::PropertyGraphReference;

use strict;
use warnings;
use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Inclusion };
    eval { require Datapol::SemanticAnnotations };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvcHJvcGVydHlfZ3JhcGhfcmVmZXJlbmNlLnBy
b3RvEhhnb29nbGUuY2xvdWQuYmlncXVlcnkudjIaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aGmdvb2dsZS9hcGkvaW5jbHVzaW9uLnByb3RvGjxzdG9yYWdlL2RhdGFwb2wv
YW5ub3RhdGlvbnMvcHJvdG8vc2VtYW50aWNfYW5ub3RhdGlvbnMucHJvdG8ipgEKFlByb3Bl
cnR5R3JhcGhSZWZlcmVuY2USKQoKcHJvamVjdF9pZBgBIAEoCUIK4EECoKDwmAHXCFIJcHJv
amVjdElkEikKCmRhdGFzZXRfaWQYAiABKAlCCuBBAqCg8JgBzAhSCWRhdGFzZXRJZBI2ChFw
cm9wZXJ0eV9ncmFwaF9pZBgDIAEoCUIK4EECoKDwmAHMCFIPcHJvcGVydHlHcmFwaElkQsQB
Chxjb20uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyQhtQcm9wZXJ0eUdyYXBoUmVmZXJlbmNl
UHJvdG9QAVo7Y2xvdWQuZ29vZ2xlLmNvbS9nby9iaWdxdWVyeS92Mi9hcGl2Mi9iaWdxdWVy
eXBiO2JpZ3F1ZXJ5cGKK1dvSD0QKQnBhY2thZ2U6dGhpcmRfcGFydHkvamF2YS9jZWwvdG9v
bHMvc3JjL3Rlc3QvamF2YS9kZXYvY2VsL3Rvb2xzL21jcEqvBgoGEgQAACUBCggKAQwSAwAA
EgoICgECEgMCACEKCQoCAwASAwQAKQoJCgIDARIDBQAkCgkKAgMCEgMGAEYKCAoBCBIDCABS
CgkKAggLEgMIAFIKCAoBCBIDCQAiCgkKAggKEgMJACIKCAoBCBIDCgA1CgkKAggBEgMKADUK
CAoBCBIDCwA8CgkKAggIEgMLADwKCQoBCBIEDAAOAgoOCgYI0bqr+gESBAwADgIKKgoCBAAS
BBEAJQEaHiBJZCBwYXRoIG9mIGEgcHJvcGVydHkgZ3JhcGguCgoKCgMEAAESAxEIHgpFCgQE
AAIAEgQTAhYEGjcgVGhlIElEIG9mIHRoZSBwcm9qZWN0IGNvbnRhaW5pbmcgdGhpcyBwcm9w
ZXJ0eSBncmFwaC4KCgwKBQQAAgAFEgMTAggKDAoFBAACAAESAxMJEwoMCgUEAAIAAxIDExYX
Cg0KBQQAAgAIEgQTGBYDChAKCQQAAgAIhISOExIDFAQxCg8KCAQAAgAInAgAEgMVBCoKRQoE
BAACARIEGQIcBBo3IFRoZSBJRCBvZiB0aGUgZGF0YXNldCBjb250YWluaW5nIHRoaXMgcHJv
cGVydHkgZ3JhcGguCgoMCgUEAAIBBRIDGQIICgwKBQQAAgEBEgMZCRMKDAoFBAACAQMSAxkW
FwoNCgUEAAIBCBIEGRgcAwoQCgkEAAIBCISEjhMSAxoELwoPCggEAAIBCJwIABIDGwQqCqYB
CgQEAAICEgQhAiQEGpcBIFRoZSBJRCBvZiB0aGUgcHJvcGVydHkgZ3JhcGguIFRoZSBJRCBt
dXN0IGNvbnRhaW4gb25seQogbGV0dGVycyAoYS16LCBBLVopLCBudW1iZXJzICgwLTkpLCBv
ciB1bmRlcnNjb3JlcyAoXykuIFRoZSBtYXhpbXVtCiBsZW5ndGggaXMgMjU2IGNoYXJhY3Rl
cnMuCgoMCgUEAAICBRIDIQIICgwKBQQAAgIBEgMhCRoKDAoFBAACAgMSAyEdHgoNCgUEAAIC
CBIEIR8kAwoQCgkEAAICCISEjhMSAyIELwoPCggEAAICCJwIABIDIwQqYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::PropertyGraphReference::PropertyGraphReference ===
    # Fields for PropertyGraphReference
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: property_graph_id Type: 9 ()

1;
