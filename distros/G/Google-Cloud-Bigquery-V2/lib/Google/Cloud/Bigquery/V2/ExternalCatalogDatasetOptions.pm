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

package Google::Cloud::Bigquery::V2::ExternalCatalogDatasetOptions;

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
Cj9nb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvZXh0ZXJuYWxfY2F0YWxvZ19kYXRhc2V0X29w
dGlvbnMucHJvdG8SGGdvb2dsZS5jbG91ZC5iaWdxdWVyeS52MhofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoaZ29vZ2xlL2FwaS9pbmNsdXNpb24ucHJvdG8aF2dvb2dsZS9h
cGkvcG9saWN5LnByb3RvIqQCCh1FeHRlcm5hbENhdGFsb2dEYXRhc2V0T3B0aW9ucxJ1Cgpw
YXJhbWV0ZXJzGAEgAygLMkcuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyLkV4dGVybmFsQ2F0
YWxvZ0RhdGFzZXRPcHRpb25zLlBhcmFtZXRlcnNFbnRyeUIM4EEBwvaM3AQDgAEBUgpwYXJh
bWV0ZXJzEk0KHGRlZmF1bHRfc3RvcmFnZV9sb2NhdGlvbl91cmkYAiABKAlCDOBBAcL2jNwE
A4ABAVIZZGVmYXVsdFN0b3JhZ2VMb2NhdGlvblVyaRo9Cg9QYXJhbWV0ZXJzRW50cnkSEAoD
a2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4AUKMAQocY29tLmdvb2ds
ZS5jbG91ZC5iaWdxdWVyeS52MkIiRXh0ZXJuYWxDYXRhbG9nRGF0YXNldE9wdGlvbnNQcm90
b1ABWjtjbG91ZC5nb29nbGUuY29tL2dvL2JpZ3F1ZXJ5L3YyL2FwaXYyL2JpZ3F1ZXJ5cGI7
YmlncXVlcnlwYorV29IPBQoDYWxsSuIGCgYSBAAAHwEKCAoBDBIDAAASCggKAQISAwIAIQoJ
CgIDABIDBAApCgkKAgMBEgMFACQKCQoCAwISAwYAIQoICgEIEgMIAFIKCQoCCAsSAwgAUgoI
CgEIEgMJADUKCQoCCAESAwkANQoICgEIEgMKACIKCQoCCAoSAwoAIgoICgEIEgMLAEMKCQoC
CAgSAwsAQwoICgEIEgMMAC0KDwoICNG6q/oBAQASAwwALQrFAQoCBAASBBEAHwEauAEgT3B0
aW9ucyBkZWZpbmluZyBvcGVuIHNvdXJjZSBjb21wYXRpYmxlIGRhdGFzZXRzIGxpdmluZyBp
biB0aGUgQmlnUXVlcnkKIGNhdGFsb2cuIENvbnRhaW5zIG1ldGFkYXRhIG9mIG9wZW4gc291
cmNlIGRhdGFiYXNlLCBzY2hlbWEsCiBvciBuYW1lc3BhY2UgcmVwcmVzZW50ZWQgYnkgdGhl
IGN1cnJlbnQgZGF0YXNldC4KCgoKAwQAARIDEQglCoEBCgQEAAIAEgQUAhcEGnMgQSBtYXAg
b2Yga2V5IHZhbHVlIHBhaXJzIGRlZmluaW5nIHRoZSBwYXJhbWV0ZXJzIGFuZCBwcm9wZXJ0
aWVzIG9mIHRoZQogb3BlbiBzb3VyY2Ugc2NoZW1hLiBNYXhpbXVtIHNpemUgb2YgMk1pQi4K
CgwKBQQAAgAGEgMUAhUKDAoFBAACAAESAxQWIAoMCgUEAAIAAxIDFCMkCg0KBQQAAgAIEgQU
JRcDCg8KCAQAAgAInAgAEgMVBCoKEQoKBAACAAjozsFLEBIDFgRGCqEBCgQEAAIBEgQbAh4E
GpIBIFRoZSBzdG9yYWdlIGxvY2F0aW9uIFVSSSBmb3IgYWxsIHRhYmxlcyBpbiB0aGUgZGF0
YXNldC4gRXF1aXZhbGVudCB0byBoaXZlCiBtZXRhc3RvcmUncyBkYXRhYmFzZSBsb2NhdGlv
blVyaS4gTWF4aW11bSBsZW5ndGggb2YgMTAyNCBjaGFyYWN0ZXJzLgoKDAoFBAACAQUSAxsC
CAoMCgUEAAIBARIDGwklCgwKBQQAAgEDEgMbKCkKDQoFBAACAQgSBBsqHgMKDwoIBAACAQic
CAASAxwEKgoRCgoEAAIBCOjOwUsQEgMdBEZiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::ExternalCatalogDatasetOptions::ExternalCatalogDatasetOptions ===
    # Fields for ExternalCatalogDatasetOptions
    # Field: parameters Type: 11 (.google.cloud.bigquery.v2.ExternalCatalogDatasetOptions.ParametersEntry)
    # Field: default_storage_location_uri Type: 9 ()

1;
