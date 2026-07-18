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

package Google::Cloud::Bigquery::V2::LocationMetadata;

use strict;
use warnings;
use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvbG9jYXRpb25fbWV0YWRhdGEucHJvdG8SGGdv
b2dsZS5jbG91ZC5iaWdxdWVyeS52MiJAChBMb2NhdGlvbk1ldGFkYXRhEiwKEmxlZ2FjeV9s
b2NhdGlvbl9pZBgBIAEoCVIQbGVnYWN5TG9jYXRpb25JZEJyChxjb20uZ29vZ2xlLmNsb3Vk
LmJpZ3F1ZXJ5LnYyQhVMb2NhdGlvbk1ldGFkYXRhUHJvdG9aO2Nsb3VkLmdvb2dsZS5jb20v
Z28vYmlncXVlcnkvdjIvYXBpdjIvYmlncXVlcnlwYjtiaWdxdWVyeXBiSuMDCgYSBAAADwEK
CAoBDBIDAAASCggKAQISAwIAIQoICgEIEgMEAFIKCQoCCAsSAwQAUgoICgEIEgMFADUKCQoC
CAESAwUANQoICgEIEgMGADYKCQoCCAgSAwYANgqaAQoCBAASBAsADwEajQEgQmlnUXVlcnkt
c3BlY2lmaWMgbWV0YWRhdGEgYWJvdXQgYSBsb2NhdGlvbi4gVGhpcyB3aWxsIGJlIHNldCBv
bgogZ29vZ2xlLmNsb3VkLmxvY2F0aW9uLkxvY2F0aW9uLm1ldGFkYXRhIGluIENsb3VkIExv
Y2F0aW9uIEFQSQogcmVzcG9uc2VzLgoKCgoDBAABEgMLCBgKsgEKBAQAAgASAw4CIBqkASBU
aGUgbGVnYWN5IEJpZ1F1ZXJ5IGxvY2F0aW9uIElELCBlLmcuIOKAnEVV4oCdIGZvciB0aGUg
4oCcZXVyb3Bl4oCdIGxvY2F0aW9uLgogVGhpcyBpcyBmb3IgYW55IEFQSSBjb25zdW1lcnMg
dGhhdCBuZWVkIHRoZSBsZWdhY3kg4oCcVVPigJ0gYW5kIOKAnEVV4oCdIGxvY2F0aW9ucy4K
CgwKBQQAAgAFEgMOAggKDAoFBAACAAESAw4JGwoMCgUEAAIAAxIDDh4fYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::LocationMetadata::LocationMetadata ===
    # Fields for LocationMetadata
    # Field: legacy_location_id Type: 9 ()

1;
