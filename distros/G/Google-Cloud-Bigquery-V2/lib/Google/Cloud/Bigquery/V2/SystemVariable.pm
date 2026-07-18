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

package Google::Cloud::Bigquery::V2::SystemVariable;

use strict;
use warnings;
use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Inclusion };
    eval { require Google::Cloud::Bigquery::V2::StandardSql };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvc3lzdGVtX3ZhcmlhYmxlLnByb3RvEhhnb29n
bGUuY2xvdWQuYmlncXVlcnkudjIaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8a
Gmdvb2dsZS9hcGkvaW5jbHVzaW9uLnByb3RvGitnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIv
c3RhbmRhcmRfc3FsLnByb3RvGhxnb29nbGUvcHJvdG9idWYvc3RydWN0LnByb3RvIoECCg9T
eXN0ZW1WYXJpYWJsZXMSTwoFdHlwZXMYASADKAsyNC5nb29nbGUuY2xvdWQuYmlncXVlcnku
djIuU3lzdGVtVmFyaWFibGVzLlR5cGVzRW50cnlCA+BBA1IFdHlwZXMSNAoGdmFsdWVzGAIg
ASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdEID4EEDUgZ2YWx1ZXMaZwoKVHlwZXNFbnRy
eRIQCgNrZXkYASABKAlSA2tleRJDCgV2YWx1ZRgCIAEoCzItLmdvb2dsZS5jbG91ZC5iaWdx
dWVyeS52Mi5TdGFuZGFyZFNxbERhdGFUeXBlUgV2YWx1ZToCOAFCvAEKHGNvbS5nb29nbGUu
Y2xvdWQuYmlncXVlcnkudjJCE1N5c3RlbVZhcmlhYmxlUHJvdG9QAVo7Y2xvdWQuZ29vZ2xl
LmNvbS9nby9iaWdxdWVyeS92Mi9hcGl2Mi9iaWdxdWVyeXBiO2JpZ3F1ZXJ5cGKK1dvSD0QK
QnBhY2thZ2U6dGhpcmRfcGFydHkvamF2YS9jZWwvdG9vbHMvc3JjL3Rlc3QvamF2YS9kZXYv
Y2VsL3Rvb2xzL21jcEqwBAoGEgQBABoBCkwKAQwSAwEAEhpCICgtLSBhcGktbGludGVyOiBj
b3JlOjowMTkxOjpmaWxlLW9wdGlvbi1jb25zaXN0ZW5jeT1kaXNhYmxlZCAtLSkKCggKAQIS
AwMAIQoJCgIDABIDBQApCgkKAgMBEgMGACQKCQoCAwISAwcANQoJCgIDAxIDCAAmCggKAQgS
AwoAUgoJCgIICxIDCgBSCggKAQgSAwsAIgoJCgIIChIDCwAiCggKAQgSAwwANQoJCgIIARID
DAA1CggKAQgSAw0ANAoJCgIICBIDDQA0CgkKAQgSBA4AEAIKDgoGCNG6q/oBEgQOABACCjAK
AgQAEgQTABoBGiQgU3lzdGVtIHZhcmlhYmxlcyBnaXZlbiB0byBhIHF1ZXJ5LgoKCgoDBAAB
EgMTCBcKMwoEBAACABIEFQIWMholIERhdGEgdHlwZSBmb3IgZWFjaCBzeXN0ZW0gdmFyaWFi
bGUuCgoMCgUEAAIABhIDFQIiCgwKBQQAAgABEgMVIygKDAoFBAACAAMSAxUrLAoMCgUEAAIA
CBIDFgYxCg8KCAQAAgAInAgAEgMWBzAKLgoEBAACARIDGQJQGiEgVmFsdWUgZm9yIGVhY2gg
c3lzdGVtIHZhcmlhYmxlLgoKDAoFBAACAQYSAxkCGAoMCgUEAAIBARIDGRkfCgwKBQQAAgED
EgMZIiMKDAoFBAACAQgSAxkkTwoPCggEAAIBCJwIABIDGSVOYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::SystemVariable::SystemVariables ===
    # Fields for SystemVariables
    # Field: types Type: 11 (.google.cloud.bigquery.v2.SystemVariables.TypesEntry)
    # Field: values Type: 11 (.google.protobuf.Struct)

1;
