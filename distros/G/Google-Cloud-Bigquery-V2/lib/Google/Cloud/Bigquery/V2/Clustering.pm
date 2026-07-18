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

package Google::Cloud::Bigquery::V2::Clustering;

use strict;
use warnings;
use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Auditing };
    eval { require Google::Api::Inclusion };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvY2x1c3RlcmluZy5wcm90bxIYZ29vZ2xlLmNs
b3VkLmJpZ3F1ZXJ5LnYyGhlnb29nbGUvYXBpL2F1ZGl0aW5nLnByb3RvGhpnb29nbGUvYXBp
L2luY2x1c2lvbi5wcm90byIzCgpDbHVzdGVyaW5nEiUKBmZpZWxkcxgBIAMoCUIN6uqArAMH
EgVBVURJVFIGZmllbGRzQncKHGNvbS5nb29nbGUuY2xvdWQuYmlncXVlcnkudjJCD0NsdXN0
ZXJpbmdQcm90b1o7Y2xvdWQuZ29vZ2xlLmNvbS9nby9iaWdxdWVyeS92Mi9hcGl2Mi9iaWdx
dWVyeXBiO2JpZ3F1ZXJ5cGKK1dvSDwUKA2FsbEqmBQoGEgQAABcBCggKAQwSAwAAEgoICgEC
EgMCACEKCQoCAwASAwQAIwoJCgIDARIDBQAkCggKAQgSAwcAUgoJCgIICxIDBwBSCggKAQgS
AwgANQoJCgIIARIDCAA1CggKAQgSAwkAMAoJCgIICBIDCQAwCggKAQgSAwoALQoPCggI0bqr
+gEBABIDCgAtCioKAgQAEgQNABcBGh4gQ29uZmlndXJlcyB0YWJsZSBjbHVzdGVyaW5nLgoK
CgoDBAABEgMNCBIKhgMKBAQAAgASAxYCTxr4AiBPbmUgb3IgbW9yZSBmaWVsZHMgb24gd2hp
Y2ggZGF0YSBzaG91bGQgYmUgY2x1c3RlcmVkLiBPbmx5IHRvcC1sZXZlbCwKIG5vbi1yZXBl
YXRlZCwgc2ltcGxlLXR5cGUgZmllbGRzIGFyZSBzdXBwb3J0ZWQuIFRoZSBvcmRlcmluZyBv
ZiB0aGUKIGNsdXN0ZXJpbmcgZmllbGRzIHNob3VsZCBiZSBwcmlvcml0aXplZCBmcm9tIG1v
c3QgdG8gbGVhc3QgaW1wb3J0YW50CiBmb3IgZmlsdGVyaW5nIHB1cnBvc2VzLgoKIEZvciBh
ZGRpdGlvbmFsIGluZm9ybWF0aW9uLCBzZWUKIFtJbnRyb2R1Y3Rpb24gdG8gY2x1c3RlcmVk
CiB0YWJsZXNdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9iaWdxdWVyeS9kb2NzL2NsdXN0
ZXJlZC10YWJsZXMjbGltaXRhdGlvbnMpLgoKDAoFBAACAAQSAxYCCgoMCgUEAAIABRIDFgsR
CgwKBQQAAgABEgMWEhgKDAoFBAACAAMSAxYbHAoMCgUEAAIACBIDFh1OChEKCgQAAgAIrY3A
NQISAxYeTWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::Clustering::Clustering ===
    # Fields for Clustering
    # Field: fields Type: 9 ()

1;
