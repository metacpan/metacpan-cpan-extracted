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

package Google::Cloud::Bigquery::V2::RoutineReference;

use strict;
use warnings;
use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Inclusion };
    eval { require Google::Api::Policy };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvcm91dGluZV9yZWZlcmVuY2UucHJvdG8SGGdv
b2dsZS5jbG91ZC5iaWdxdWVyeS52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
bxoaZ29vZ2xlL2FwaS9pbmNsdXNpb24ucHJvdG8aF2dvb2dsZS9hcGkvcG9saWN5LnByb3Rv
IpkBChBSb3V0aW5lUmVmZXJlbmNlEisKCnByb2plY3RfaWQYASABKAlCDOBBAsL2jNwEA4AB
AVIJcHJvamVjdElkEisKCmRhdGFzZXRfaWQYAiABKAlCDOBBAsL2jNwEA4ABAVIJZGF0YXNl
dElkEisKCnJvdXRpbmVfaWQYAyABKAlCDOBBAsL2jNwEA4ABAVIJcm91dGluZUlkQn0KHGNv
bS5nb29nbGUuY2xvdWQuYmlncXVlcnkudjJCFVJvdXRpbmVSZWZlcmVuY2VQcm90b1o7Y2xv
dWQuZ29vZ2xlLmNvbS9nby9iaWdxdWVyeS92Mi9hcGl2Mi9iaWdxdWVyeXBiO2JpZ3F1ZXJ5
cGKK1dvSDwUKA2FsbEqBBgoGEgQAACABCggKAQwSAwAAEgoICgECEgMCACEKCQoCAwASAwQA
KQoJCgIDARIDBQAkCgkKAgMCEgMGACEKCAoBCBIDCABSCgkKAggLEgMIAFIKCAoBCBIDCQA1
CgkKAggBEgMJADUKCAoBCBIDCgA2CgkKAggIEgMKADYKCAoBCBIDCwAtCg8KCAjRuqv6AQEA
EgMLAC0KIwoCBAASBA4AIAEaFyBJZCBwYXRoIG9mIGEgcm91dGluZS4KCgoKAwQAARIDDggY
Cj4KBAQAAgASBBACEwQaMCBUaGUgSUQgb2YgdGhlIHByb2plY3QgY29udGFpbmluZyB0aGlz
IHJvdXRpbmUuCgoMCgUEAAIABRIDEAIICgwKBQQAAgABEgMQCRMKDAoFBAACAAMSAxAWFwoN
CgUEAAIACBIEEBgTAwoPCggEAAIACJwIABIDEQQqChEKCgQAAgAI6M7BSxASAxIERgo+CgQE
AAIBEgQVAhgEGjAgVGhlIElEIG9mIHRoZSBkYXRhc2V0IGNvbnRhaW5pbmcgdGhpcyByb3V0
aW5lLgoKDAoFBAACAQUSAxUCCAoMCgUEAAIBARIDFQkTCgwKBQQAAgEDEgMVFhcKDQoFBAAC
AQgSBBUYGAMKDwoIBAACAQicCAASAxYEKgoRCgoEAAIBCOjOwUsQEgMXBEYKnwEKBAQAAgIS
BBwCHwQakAEgVGhlIElEIG9mIHRoZSByb3V0aW5lLiBUaGUgSUQgbXVzdCBjb250YWluIG9u
bHkKIGxldHRlcnMgKGEteiwgQS1aKSwgbnVtYmVycyAoMC05KSwgb3IgdW5kZXJzY29yZXMg
KF8pLiBUaGUgbWF4aW11bQogbGVuZ3RoIGlzIDI1NiBjaGFyYWN0ZXJzLgoKDAoFBAACAgUS
AxwCCAoMCgUEAAICARIDHAkTCgwKBQQAAgIDEgMcFhcKDQoFBAACAggSBBwYHwMKDwoIBAAC
AgicCAASAx0EKgoRCgoEAAICCOjOwUsQEgMeBEZiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::RoutineReference::RoutineReference ===
    # Fields for RoutineReference
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: routine_id Type: 9 ()

1;
