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

package Google::Cloud::Bigquery::V2::DatasetReference;

use strict;
use warnings;
use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Auditing };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Inclusion };
    eval { require Google::Api::Migration };
    eval { require Google::Api::Policy };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvZGF0YXNldF9yZWZlcmVuY2UucHJvdG8SGGdv
b2dsZS5jbG91ZC5iaWdxdWVyeS52MhoZZ29vZ2xlL2FwaS9hdWRpdGluZy5wcm90bxofZ29v
Z2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoaZ29vZ2xlL2FwaS9pbmNsdXNpb24ucHJv
dG8aGmdvb2dsZS9hcGkvbWlncmF0aW9uLnByb3RvGhdnb29nbGUvYXBpL3BvbGljeS5wcm90
byK5AgoQRGF0YXNldFJlZmVyZW5jZRJWCgpkYXRhc2V0X2lkGAEgASgJQjfgQQLq6oCsAwcS
BUFVRElUmr/k2gQYOhZkYXRhc2V0X2lkX2FsdGVybmF0aXZlwvaM3AQDgAEBUglkYXRhc2V0
SWQSTQoKcHJvamVjdF9pZBgCIAEoCUIu4EEB6uqArAMHEgVBVURJVJq/5NoEGDoWcHJvamVj
dF9pZF9hbHRlcm5hdGl2ZVIJcHJvamVjdElkEj4KFmRhdGFzZXRfaWRfYWx0ZXJuYXRpdmUY
AyADKAlCCJq/5NoEAhgBUhRkYXRhc2V0SWRBbHRlcm5hdGl2ZRI+ChZwcm9qZWN0X2lkX2Fs
dGVybmF0aXZlGAQgAygJQgiav+TaBAIYAVIUcHJvamVjdElkQWx0ZXJuYXRpdmVCfQocY29t
Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS52MkIVRGF0YXNldFJlZmVyZW5jZVByb3RvWjtjbG91
ZC5nb29nbGUuY29tL2dvL2JpZ3F1ZXJ5L3YyL2FwaXYyL2JpZ3F1ZXJ5cGI7YmlncXVlcnlw
YorV29IPBQoDYWxsSvQLCgYSBAAANgEKCAoBDBIDAAASCggKAQISAwIAIQoJCgIDABIDBAAj
CgkKAgMBEgMFACkKCQoCAwISAwYAJAoJCgIDAxIDBwAkCgkKAgMEEgMIACEKCAoBCBIDCgBS
CgkKAggLEgMKAFIKCAoBCBIDCwA1CgkKAggBEgMLADUKCAoBCBIDDAA2CgkKAggIEgMMADYK
CAoBCBIDDQAtCg8KCAjRuqv6AQEAEgMNAC0KsgEKAgQAEgQUADYBGqUBICgtLQogT25lUGxh
dGZvcm0gdmVyc2lvbiBvZiBBcGlhcnkgRGF0YXNldCBSZWZlcmVuY2UuCiBnb29nbGVkYXRh
L2FwaXNlcnZpbmcvY29uZmlnL2Nsb3VkL2hlbGl4L3YyL3RlbXBsYXRlcy9kYXRhc2V0cmVm
ZXJlbmNlLmpzb250CiAtLSkKIElkZW50aWZpZXIgZm9yIGEgZGF0YXNldC4KCgoKAwQAARID
FAgYCsIBCgQEAAIAEgQYAh4EGrMBIEEgdW5pcXVlIElEIGZvciB0aGlzIGRhdGFzZXQsIHdp
dGhvdXQgdGhlIHByb2plY3QgbmFtZS4gVGhlIElECiBtdXN0IGNvbnRhaW4gb25seSBsZXR0
ZXJzIChhLXosIEEtWiksIG51bWJlcnMgKDAtOSksIG9yIHVuZGVyc2NvcmVzIChfKS4KIFRo
ZSBtYXhpbXVtIGxlbmd0aCBpcyAxLDAyNCBjaGFyYWN0ZXJzLgoKDAoFBAACAAUSAxgCCAoM
CgUEAAIAARIDGAkTCgwKBQQAAgADEgMYFhcKDQoFBAACAAgSBBgYHgMKDwoIBAACAAicCAAS
AxkEKgoRCgoEAAIACK2NwDUCEgMaBDMKEgoKBAACAAjzx6xLBxIEGwQcIAoRCgoEAAIACOjO
wUsQEgMdBEYKPgoEBAACARIEIAIlBBowIFRoZSBJRCBvZiB0aGUgcHJvamVjdCBjb250YWlu
aW5nIHRoaXMgZGF0YXNldC4KCgwKBQQAAgEFEgMgAggKDAoFBAACAQESAyAJEwoMCgUEAAIB
AxIDIBYXCg0KBQQAAgEIEgQgGCUDCg8KCAQAAgEInAgAEgMhBCoKEQoKBAACAQitjcA1AhID
IgQzChIKCgQAAgEI88esSwcSBCMEJCAK6gEKBAQAAgISBCwCLUAa2wEgKC0tCiBUaGUgYWx0
ZXJuYXRpdmUgZmllbGQgdGhhdCB3aWxsIGJlIHVzZWQgd2hlbiBFU0YgaXMgbm90IGFibGUg
dG8gdHJhbnNsYXRlCiB0aGUgcmVjZWl2ZWQgZGF0YSB0byB0aGUgZGF0YXNldF9pZCBmaWVs
ZC4gU2VlIGRldGFpbHMgYXQKIGdvL2RlYWxpbmdfd2l0aF9hcGlhcnlfbGF4X2FycmF5X3Bh
cnNpbmcuCiAtLSkKIFRoaXMgZmllbGQgc2hvdWxkIG5vdCBiZSB1c2VkLgoKDAoFBAACAgQS
AywCCgoMCgUEAAICBRIDLAsRCgwKBQQAAgIBEgMsEigKDAoFBAACAgMSAywrLAoMCgUEAAIC
CBIDLQY/ChEKCgQAAgII88esSwMSAy0HPgrqAQoEBAACAxIENAI1QBrbASAoLS0KIFRoZSBh
bHRlcm5hdGl2ZSBmaWVsZCB0aGF0IHdpbGwgYmUgdXNlZCB3aGVuIEVTRiBpcyBub3QgYWJs
ZSB0byB0cmFuc2xhdGUKIHRoZSByZWNlaXZlZCBkYXRhIHRvIHRoZSBwcm9qZWN0X2lkIGZp
ZWxkLiBTZWUgZGV0YWlscyBhdAogZ28vZGVhbGluZ193aXRoX2FwaWFyeV9sYXhfYXJyYXlf
cGFyc2luZy4KIC0tKQogVGhpcyBmaWVsZCBzaG91bGQgbm90IGJlIHVzZWQuCgoMCgUEAAID
BBIDNAIKCgwKBQQAAgMFEgM0CxEKDAoFBAACAwESAzQSKAoMCgUEAAIDAxIDNCssCgwKBQQA
AgMIEgM1Bj8KEQoKBAACAwjzx6xLAxIDNQc+YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::DatasetReference::DatasetReference ===
    # Fields for DatasetReference
    # Field: dataset_id Type: 9 ()
    # Field: project_id Type: 9 ()
    # Field: dataset_id_alternative Type: 9 ()
    # Field: project_id_alternative Type: 9 ()

1;
