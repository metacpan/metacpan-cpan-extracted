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

package Google::Cloud::Bigquery::V2::RowAccessPolicyReference;

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
Cjpnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvcm93X2FjY2Vzc19wb2xpY3lfcmVmZXJlbmNl
LnByb3RvEhhnb29nbGUuY2xvdWQuYmlncXVlcnkudjIaH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aGmdvb2dsZS9hcGkvaW5jbHVzaW9uLnByb3RvGhdnb29nbGUvYXBpL3Bv
bGljeS5wcm90byLIAQoYUm93QWNjZXNzUG9saWN5UmVmZXJlbmNlEisKCnByb2plY3RfaWQY
ASABKAlCDOBBAsL2jNwEA4ABAVIJcHJvamVjdElkEisKCmRhdGFzZXRfaWQYAiABKAlCDOBB
AsL2jNwEA4ABAVIJZGF0YXNldElkEicKCHRhYmxlX2lkGAMgASgJQgzgQQLC9ozcBAOAAQFS
B3RhYmxlSWQSKQoJcG9saWN5X2lkGAQgASgJQgzgQQLC9ozcBAOAAQFSCHBvbGljeUlkQsYB
Chxjb20uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyQh1Sb3dBY2Nlc3NQb2xpY3lSZWZlcmVu
Y2VQcm90b1ABWjtjbG91ZC5nb29nbGUuY29tL2dvL2JpZ3F1ZXJ5L3YyL2FwaXYyL2JpZ3F1
ZXJ5cGI7YmlncXVlcnlwYorV29IPRApCcGFja2FnZTp0aGlyZF9wYXJ0eS9qYXZhL2NlbC90
b29scy9zcmMvdGVzdC9qYXZhL2Rldi9jZWwvdG9vbHMvbWNwSuMHCgYSBAAAKwEKCAoBDBID
AAASCggKAQISAwIAIQoJCgIDABIDBAApCgkKAgMBEgMFACQKCQoCAwISAwYAIQoICgEIEgMI
AFIKCQoCCAsSAwgAUgoICgEIEgMJACIKCQoCCAoSAwkAIgoICgEIEgMKADUKCQoCCAESAwoA
NQoICgEIEgMLAD4KCQoCCAgSAwsAPgoJCgEIEgQMAA4CCg4KBgjRuqv6ARIEDAAOAgotCgIE
ABIEEQArARohIElkIHBhdGggb2YgYSByb3cgYWNjZXNzIHBvbGljeS4KCgoKAwQAARIDEQgg
CkgKBAQAAgASBBMCFgQaOiBUaGUgSUQgb2YgdGhlIHByb2plY3QgY29udGFpbmluZyB0aGlz
IHJvdyBhY2Nlc3MgcG9saWN5LgoKDAoFBAACAAUSAxMCCAoMCgUEAAIAARIDEwkTCgwKBQQA
AgADEgMTFhcKDQoFBAACAAgSBBMYFgMKDwoIBAACAAicCAASAxQEKgoRCgoEAAIACOjOwUsQ
EgMVBEYKSAoEBAACARIEGQIcBBo6IFRoZSBJRCBvZiB0aGUgZGF0YXNldCBjb250YWluaW5n
IHRoaXMgcm93IGFjY2VzcyBwb2xpY3kuCgoMCgUEAAIBBRIDGQIICgwKBQQAAgEBEgMZCRMK
DAoFBAACAQMSAxkWFwoNCgUEAAIBCBIEGRgcAwoPCggEAAIBCJwIABIDGgQqChEKCgQAAgEI
6M7BSxASAxsERgpGCgQEAAICEgQfAiIEGjggVGhlIElEIG9mIHRoZSB0YWJsZSBjb250YWlu
aW5nIHRoaXMgcm93IGFjY2VzcyBwb2xpY3kuCgoMCgUEAAICBRIDHwIICgwKBQQAAgIBEgMf
CREKDAoFBAACAgMSAx8UFQoNCgUEAAICCBIEHxYiAwoPCggEAAICCJwIABIDIAQqChEKCgQA
AgII6M7BSxASAyEERgqpAQoEBAACAxIEJwIqBBqaASBUaGUgSUQgb2YgdGhlIHJvdyBhY2Nl
c3MgcG9saWN5LiBUaGUgSUQgbXVzdCBjb250YWluIG9ubHkKIGxldHRlcnMgKGEteiwgQS1a
KSwgbnVtYmVycyAoMC05KSwgb3IgdW5kZXJzY29yZXMgKF8pLiBUaGUgbWF4aW11bQogbGVu
Z3RoIGlzIDI1NiBjaGFyYWN0ZXJzLgoKDAoFBAACAwUSAycCCAoMCgUEAAIDARIDJwkSCgwK
BQQAAgMDEgMnFRYKDQoFBAACAwgSBCcXKgMKDwoIBAACAwicCAASAygEKgoRCgoEAAIDCOjO
wUsQEgMpBEZiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::RowAccessPolicyReference::RowAccessPolicyReference ===
    # Fields for RowAccessPolicyReference
    # Field: project_id Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: table_id Type: 9 ()
    # Field: policy_id Type: 9 ()

1;
