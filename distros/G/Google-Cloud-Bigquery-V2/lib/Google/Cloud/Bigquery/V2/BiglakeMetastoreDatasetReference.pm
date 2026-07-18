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

package Google::Cloud::Bigquery::V2::BiglakeMetastoreDatasetReference;

use strict;
use warnings;
use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Inclusion };
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
CkJnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvYmlnbGFrZV9tZXRhc3RvcmVfZGF0YXNldF9y
ZWZlcmVuY2UucHJvdG8SGGdvb2dsZS5jbG91ZC5iaWdxdWVyeS52MhofZ29vZ2xlL2FwaS9m
aWVsZF9iZWhhdmlvci5wcm90bxoaZ29vZ2xlL2FwaS9pbmNsdXNpb24ucHJvdG8aGWdvb2ds
ZS9hcGkvcmVzb3VyY2UucHJvdG8ijwEKIEJpZ0xha2VNZXRhc3RvcmVEYXRhc2V0UmVmZXJl
bmNlEkMKCGRhdGFiYXNlGAEgASgJQifgQQL6QSEKH2JpZ2xha2UuZ29vZ2xlYXBpcy5jb20v
RGF0YWJhc2VSCGRhdGFiYXNlEiYKDGRhdGFiYXNlX3VpZBgCIAEoCUID4EEDUgtkYXRhYmFz
ZVVpZEKEAgocY29tLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS52MkIlQmlnTGFrZU1ldGFzdG9y
ZURhdGFzZXRSZWZlcmVuY2VQcm90b1ABWjtjbG91ZC5nb29nbGUuY29tL2dvL2JpZ3F1ZXJ5
L3YyL2FwaXYyL2JpZ3F1ZXJ5cGI7YmlncXVlcnlwYupBcgofYmlnbGFrZS5nb29nbGVhcGlz
LmNvbS9EYXRhYmFzZRJPcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L2NhdGFsb2dzL3tjYXRhbG9nfS9kYXRhYmFzZXMve2RhdGFiYXNlfYrV29IPBQoDYWxsSuQF
CgYSBAAAHwEKCAoBDBIDAAASCggKAQISAwIAIQoJCgIDABIDBAApCgkKAgMBEgMFACQKCQoC
AwISAwYAIwoICgEIEgMIAFIKCQoCCAsSAwgAUgoICgEIEgMJADUKCQoCCAESAwkANQoICgEI
EgMKAEYKCQoCCAgSAwoARgoICgEIEgMLACIKCQoCCAoSAwsAIgoJCgEIEgQMAA8CCgwKBAid
CAASBAwADwIKCAoBCBIDEAAtCg8KCAjRuqv6AQEAEgMQAC0KUwoCBAASBBMAHwEaRyBDb25m
aWd1cmVzIGEgZGF0YXNldCB0aGF0IHJlZmVyZW5jZXMgYSBkYXRhYmFzZSBpbiBCaWdMYWtl
IE1ldGFzdG9yZS4KCgoKAwQAARIDEwgoCrEBCgQEAAIAEgQXAhoEGqIBIEZ1bGwgcmVzb3Vy
Y2UgcGF0aCBvZiB0aGUgZGF0YWJhc2UgYmFja2luZyB0aGlzIGRhdGFzZXQuCiBGb3JtYXQ6
CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L2NhdGFs
b2dzL3tjYXRhbG9nX2lkfS9kYXRhYmFzZXMve2RhdGFiYXNlX2lkfWAKCgwKBQQAAgAFEgMX
AggKDAoFBAACAAESAxcJEQoMCgUEAAIAAxIDFxQVCg0KBQQAAgAIEgQXFhoDCg8KCAQAAgAI
nwgBEgMYBEwKDwoIBAACAAicCAASAxkEKgpkCgQEAAIBEgMeAkYaVyBVbmlxdWUgaWRlbnRp
ZmllciBvZiB0aGUgZGF0YWJhc2UgZ2VuZXJhdGVkIGFuZCBhc3NpZ25lZCBieQogQmlnTGFr
ZU1ldGFzdG9yZVNlcnZpY2UuCgoMCgUEAAIBBRIDHgIICgwKBQQAAgEBEgMeCRUKDAoFBAAC
AQMSAx4YGQoMCgUEAAIBCBIDHhpFCg8KCAQAAgEInAgAEgMeG0RiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::BiglakeMetastoreDatasetReference::BigLakeMetastoreDatasetReference ===
    # Fields for BigLakeMetastoreDatasetReference
    # Field: database Type: 9 ()
    # Field: database_uid Type: 9 ()

1;
