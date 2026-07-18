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

package Google::Cloud::Bigquery::V2::JobStatus;

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
    eval { require Google::Api::Visibility };
    eval { require Google::Cloud::Bigquery::V2::Error };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvam9iX3N0YXR1cy5wcm90bxIYZ29vZ2xlLmNs
b3VkLmJpZ3F1ZXJ5LnYyGhlnb29nbGUvYXBpL2F1ZGl0aW5nLnByb3RvGh9nb29nbGUvYXBp
L2ZpZWxkX2JlaGF2aW9yLnByb3RvGhpnb29nbGUvYXBpL2luY2x1c2lvbi5wcm90bxobZ29v
Z2xlL2FwaS92aXNpYmlsaXR5LnByb3RvGiRnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvZXJy
b3IucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i6wIKCUpvYlN0YXR1
cxJZCgxlcnJvcl9yZXN1bHQYASABKAsyJC5nb29nbGUuY2xvdWQuYmlncXVlcnkudjIuRXJy
b3JQcm90b0IQ4EED6uqArAMHEgVBVURJVFILZXJyb3JSZXN1bHQSTgoGZXJyb3JzGAIgAygL
MiQuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyLkVycm9yUHJvdG9CEOBBA+rqgKwDBxIFQVVE
SVRSBmVycm9ycxImCgVzdGF0ZRgDIAEoCUIQ4EED6uqArAMHEgVBVURJVFIFc3RhdGUSigEK
FWNvbnRpbnVvdXNfam9iX3N0YXR1cxgEIAEoCzItLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS52
Mi5Db250aW51b3VzSm9iU3RhdHVzQifgQQP60uSTAhESD0dPT0dMRV9JTlRFUk5BTOrqgKwD
BxIFQVVESVRSE2NvbnRpbnVvdXNKb2JTdGF0dXMivwEKE0NvbnRpbnVvdXNKb2JTdGF0dXMS
RgoRYWN0aXZlX2Vycm9yX3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1w
Ug9hY3RpdmVFcnJvclRpbWUSRwoMYWN0aXZlX2Vycm9yGAIgASgLMiQuZ29vZ2xlLmNsb3Vk
LmJpZ3F1ZXJ5LnYyLkVycm9yUHJvdG9SC2FjdGl2ZUVycm9yOhf60uSTAhESD0dPT0dMRV9J
TlRFUk5BTEK1AQocY29tLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS52MkIOSm9iU3RhdHVzUHJv
dG9aO2Nsb3VkLmdvb2dsZS5jb20vZ28vYmlncXVlcnkvdjIvYXBpdjIvYmlncXVlcnlwYjti
aWdxdWVyeXBiitXb0g9ECkJwYWNrYWdlOnRoaXJkX3BhcnR5L2phdmEvY2VsL3Rvb2xzL3Ny
Yy90ZXN0L2phdmEvZGV2L2NlbC90b29scy9tY3BKoA4KBhIEAABDAQoICgEMEgMAABIKCAoB
AhIDAgAhCgkKAgMAEgMEACMKCQoCAwESAwUAKQoJCgIDAhIDBgAkCgkKAgMDEgMHACUKCQoC
AwQSAwgALgoJCgIDBRIDCQApCggKAQgSAwsAUgoJCgIICxIDCwBSCggKAQgSAwwANQoJCgII
ARIDDAA1CggKAQgSAw0ALwoJCgIICBIDDQAvCgkKAQgSBA4AEAIKDgoGCNG6q/oBEgQOABAC
CqcBCgIEABIEFwA2ARqaASAoLS0KIFRoaXMgbWVzc2FnZSBpcyBtaXJyb3JpbmcgYW4gZXhp
c3RpbmcgQXBpYXJ5IHN0cnVjdHVyZS4KIFNlZQogY3MvZ29vZ2xlMy9nb29nbGVkYXRhL2Fw
aXNlcnZpbmcvY29uZmlnL2Nsb3VkL2hlbGl4L3YyL3RlbXBsYXRlcy9qb2JzdGF0dXMuanNv
bnQKIC0tKQoKCgoDBAABEgMXCBEKdgoEBAACABIEGgIdBBpoIEZpbmFsIGVycm9yIHJlc3Vs
dCBvZiB0aGUgam9iLiBJZiBwcmVzZW50LCBpbmRpY2F0ZXMgdGhhdCB0aGUKIGpvYiBoYXMg
Y29tcGxldGVkIGFuZCB3YXMgdW5zdWNjZXNzZnVsLgoKDAoFBAACAAYSAxoCDAoMCgUEAAIA
ARIDGg0ZCgwKBQQAAgADEgMaHB0KDQoFBAACAAgSBBoeHQMKDwoIBAACAAicCAASAxsELQoR
CgoEAAIACK2NwDUCEgMcBDMK+AEKBAQAAgESBCMCJgQa6QEgVGhlIGZpcnN0IGVycm9ycyBl
bmNvdW50ZXJlZCBkdXJpbmcgdGhlIHJ1bm5pbmcgb2YgdGhlIGpvYi4KIFRoZSBmaW5hbCBt
ZXNzYWdlIGluY2x1ZGVzIHRoZSBudW1iZXIgb2YgZXJyb3JzIHRoYXQgY2F1c2VkIHRoZSBw
cm9jZXNzIHRvCiBzdG9wLiBFcnJvcnMgaGVyZSBkbyBub3QgbmVjZXNzYXJpbHkgbWVhbiB0
aGF0IHRoZSBqb2IgaGFzIG5vdCBjb21wbGV0ZWQgb3IKIHdhcyB1bnN1Y2Nlc3NmdWwuCgoM
CgUEAAIBBBIDIwIKCgwKBQQAAgEGEgMjCxUKDAoFBAACAQESAyMWHAoMCgUEAAIBAxIDIx8g
Cg0KBQQAAgEIEgQjISYDCg8KCAQAAgEInAgAEgMkBC0KEQoKBAACAQitjcA1AhIDJQQzCmIK
BAQAAgISBCoCLQQaVCBSdW5uaW5nIHN0YXRlIG9mIHRoZSBqb2IuICBWYWxpZCBzdGF0ZXMg
aW5jbHVkZSAnUEVORElORycsCiAnUlVOTklORycsIGFuZCAnRE9ORScuCgoMCgUEAAICBRID
KgIICgwKBQQAAgIBEgMqCQ4KDAoFBAACAgMSAyoREgoNCgUEAAICCBIEKhMtAwoPCggEAAIC
CJwIABIDKwQtChEKCgQAAgIIrY3ANQISAywEMwpmCgQEAAIDEgQxAjUEGlggQ3VycmVudCBz
dGF0dXMgb2YgdGhlIGNvbnRpbnVvdXMgam9iLCBpZiB0aGlzIGpvYiBzdGF0dXMgaXMgdGhh
dCBvZiBhCiBjb250aW51b3VzIGpvYi4KCgwKBQQAAgMGEgMxAhUKDAoFBAACAwESAzEWKwoM
CgUEAAIDAxIDMS4vCg0KBQQAAgMIEgQxMDUDChEKCgQAAgMIr8q8IgISAzIEQQoPCggEAAID
CJwIABIDMwQtChEKCgQAAgMIrY3ANQISAzQEMwopCgIEARIEOQBDARodIFN0YXR1cyBvZiBh
IGNvbnRpbnVvdXMgam9iLgoKCgoDBAEBEgM5CBsKCgoDBAEHEgM6AkkKDwoIBAEHr8q8IgIS
AzoCSQqYAQoEBAECABIDPgIyGooBIFRoZSB0aW1lc3RhbXAgd2hlbiBqb2IgZXhlY3V0aW9u
IGVuY291bnRlcmVkIHRoZSBhY3RpdmVfZXJyb3IgYmVsb3cuIFRoZQogZmllbGQgd2lsbCBl
dmVudHVhbGx5IGJlIGNsZWFyZWQgYWZ0ZXIgdGhlIGVycm9yIGhhcyBzdWJzaWRlZC4KCgwK
BQQBAgAGEgM+AhsKDAoFBAECAAESAz4cLQoMCgUEAQIAAxIDPjAxCpgBCgQEAQIBEgNCAh4a
igEgVGhlIG1vc3QgcmVjZW50IGVycm9yLCBpZiBhbnksIHRoYXQgaW50ZXJydXB0ZWQgdGhl
IHF1ZXJ5IGV4ZWN1dGlvbi4gVGhlCiBmaWVsZCB3aWxsIGV2ZW50dWFsbHkgYmUgY2xlYXJl
ZCBhZnRlciB0aGUgZXJyb3IgaGFzIHN1YnNpZGVkLgoKDAoFBAECAQYSA0ICDAoMCgUEAQIB
ARIDQg0ZCgwKBQQBAgEDEgNCHB1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::JobStatus::JobStatus ===
    # Fields for JobStatus
    # Field: error_result Type: 11 (.google.cloud.bigquery.v2.ErrorProto)
    # Field: errors Type: 11 (.google.cloud.bigquery.v2.ErrorProto)
    # Field: state Type: 9 ()
    # Field: continuous_job_status Type: 11 (.google.cloud.bigquery.v2.ContinuousJobStatus)

# === Message: Google::Cloud::Bigquery::V2::JobStatus::ContinuousJobStatus ===
    # Fields for ContinuousJobStatus
    # Field: active_error_time Type: 11 (.google.protobuf.Timestamp)
    # Field: active_error Type: 11 (.google.cloud.bigquery.v2.ErrorProto)

1;
