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

package Google::Cloud::Bigquery::V2::ManagedTableType;

use strict;
use warnings;
use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Inclusion };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvbWFuYWdlZF90YWJsZV90eXBlLnByb3RvEhhn
b29nbGUuY2xvdWQuYmlncXVlcnkudjIaGmdvb2dsZS9hcGkvaW5jbHVzaW9uLnByb3RvKk8K
EE1hbmFnZWRUYWJsZVR5cGUSIgoeTUFOQUdFRF9UQUJMRV9UWVBFX1VOU1BFQ0lGSUVEEAAS
CgoGTkFUSVZFEAESCwoHQklHTEFLRRACQn8KHGNvbS5nb29nbGUuY2xvdWQuYmlncXVlcnku
djJCFU1hbmFnZWRUYWJsZVR5cGVQcm90b1ABWjtjbG91ZC5nb29nbGUuY29tL2dvL2JpZ3F1
ZXJ5L3YyL2FwaXYyL2JpZ3F1ZXJ5cGI7YmlncXVlcnlwYorV29IPBQoDYWxsSogECgYSBAAA
FAEKCAoBDBIDAAASCggKAQISAwIAIQoJCgIDABIDBAAkCggKAQgSAwYAUgoJCgIICxIDBgBS
CggKAQgSAwcAIgoJCgIIChIDBwAiCggKAQgSAwgANQoJCgIIARIDCAA1CggKAQgSAwkANgoJ
CgIICBIDCQA2CggKAQgSAwoALQoPCggI0bqr+gEBABIDCgAtCkwKAgUAEgQNABQBGkAgVGhl
IGNsYXNzaWZpY2F0aW9uIG9mIG1hbmFnZWQgdGFibGUgdHlwZXMgdGhhdCBjYW4gYmUgY3Jl
YXRlZC4KCgoKAwUAARIDDQUVCi8KBAUAAgASAw8CJRoiIE5vIG1hbmFnZWQgdGFibGUgdHlw
ZSBzcGVjaWZpZWQuCgoMCgUFAAIAARIDDwIgCgwKBQUAAgACEgMPIyQKPAoEBQACARIDEQIN
Gi8gVGhlIG1hbmFnZWQgdGFibGUgaXMgYSBuYXRpdmUgQmlnUXVlcnkgdGFibGUuCgoMCgUF
AAIBARIDEQIICgwKBQUAAgECEgMRCwwKUwoEBQACAhIDEwIOGkYgVGhlIG1hbmFnZWQgdGFi
bGUgaXMgYSBCaWdMYWtlIHRhYmxlIGZvciBBcGFjaGUgSWNlYmVyZyBpbiBCaWdRdWVyeS4K
CgwKBQUAAgIBEgMTAgkKDAoFBQACAgISAxMMDWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

1;
