package Google::Devtools::Artifactregistry::V1beta2::Service;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Devtools::Artifactregistry::V1beta2::AptArtifact };
    eval { require Google::Devtools::Artifactregistry::V1beta2::File };
    eval { require Google::Devtools::Artifactregistry::V1beta2::Package };
    eval { require Google::Devtools::Artifactregistry::V1beta2::Repository };
    eval { require Google::Devtools::Artifactregistry::V1beta2::Settings };
    eval { require Google::Devtools::Artifactregistry::V1beta2::Tag };
    eval { require Google::Devtools::Artifactregistry::V1beta2::Version };
    eval { require Google::Devtools::Artifactregistry::V1beta2::YumArtifact };
    eval { require Google::Iam::V1::IamPolicy };
    eval { require Google::Iam::V1::Policy };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MWJldGEyL3NlcnZpY2UucHJv
dG8SKGdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIaHGdvb2dsZS9h
cGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGjtnb29nbGUv
ZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MWJldGEyL2FwdF9hcnRpZmFjdC5wcm90bxoz
Z29vZ2xlL2RldnRvb2xzL2FydGlmYWN0cmVnaXN0cnkvdjFiZXRhMi9maWxlLnByb3RvGjZn
b29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MWJldGEyL3BhY2thZ2UucHJvdG8a
OWdvb2dsZS9kZXZ0b29scy9hcnRpZmFjdHJlZ2lzdHJ5L3YxYmV0YTIvcmVwb3NpdG9yeS5w
cm90bxo3Z29vZ2xlL2RldnRvb2xzL2FydGlmYWN0cmVnaXN0cnkvdjFiZXRhMi9zZXR0aW5n
cy5wcm90bxoyZ29vZ2xlL2RldnRvb2xzL2FydGlmYWN0cmVnaXN0cnkvdjFiZXRhMi90YWcu
cHJvdG8aNmdvb2dsZS9kZXZ0b29scy9hcnRpZmFjdHJlZ2lzdHJ5L3YxYmV0YTIvdmVyc2lv
bi5wcm90bxo7Z29vZ2xlL2RldnRvb2xzL2FydGlmYWN0cmVnaXN0cnkvdjFiZXRhMi95dW1f
YXJ0aWZhY3QucHJvdG8aHmdvb2dsZS9pYW0vdjEvaWFtX3BvbGljeS5wcm90bxoaZ29vZ2xl
L2lhbS92MS9wb2xpY3kucHJvdG8aI2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnBy
b3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8iEwoRT3BlcmF0aW9uTWV0YWRhdGEy
5i8KEEFydGlmYWN0UmVnaXN0cnkS3wIKEkltcG9ydEFwdEFydGlmYWN0cxJDLmdvb2dsZS5k
ZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIuSW1wb3J0QXB0QXJ0aWZhY3RzUmVx
dWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24i5AGC0+STAlAiSy92MWJldGEy
L3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9yZXBvc2l0b3JpZXMvKn0vYXB0QXJ0
aWZhY3RzOmltcG9ydDoBKspBigEKQ2dvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5
LnYxYmV0YTIuSW1wb3J0QXB0QXJ0aWZhY3RzUmVzcG9uc2USQ2dvb2dsZS5kZXZ0b29scy5h
cnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIuSW1wb3J0QXB0QXJ0aWZhY3RzTWV0YWRhdGES3wIK
EkltcG9ydFl1bUFydGlmYWN0cxJDLmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5
LnYxYmV0YTIuSW1wb3J0WXVtQXJ0aWZhY3RzUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmlu
Zy5PcGVyYXRpb24i5AGC0+STAlAiSy92MWJldGEyL3twYXJlbnQ9cHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9yZXBvc2l0b3JpZXMvKn0veXVtQXJ0aWZhY3RzOmltcG9ydDoBKspBigEKQ2dv
b2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIuSW1wb3J0WXVtQXJ0aWZh
Y3RzUmVzcG9uc2USQ2dvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIu
SW1wb3J0WXVtQXJ0aWZhY3RzTWV0YWRhdGES4QEKEExpc3RSZXBvc2l0b3JpZXMSQS5nb29n
bGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MWJldGEyLkxpc3RSZXBvc2l0b3JpZXNS
ZXF1ZXN0GkIuZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjFiZXRhMi5MaXN0
UmVwb3NpdG9yaWVzUmVzcG9uc2UiRoLT5JMCNxI1L3YxYmV0YTIve3BhcmVudD1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qfS9yZXBvc2l0b3JpZXPaQQZwYXJlbnQSywEKDUdldFJlcG9zaXRv
cnkSPi5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MWJldGEyLkdldFJlcG9z
aXRvcnlSZXF1ZXN0GjQuZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjFiZXRh
Mi5SZXBvc2l0b3J5IkSC0+STAjcSNS92MWJldGEyL3tuYW1lPXByb2plY3RzLyovbG9jYXRp
b25zLyovcmVwb3NpdG9yaWVzLyp92kEEbmFtZRLWAgoQQ3JlYXRlUmVwb3NpdG9yeRJBLmdv
b2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIuQ3JlYXRlUmVwb3NpdG9y
eVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIt8BgtPkkwJDIjUvdjFi
ZXRhMi97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L3JlcG9zaXRvcmllczoKcmVw
b3NpdG9yedpBH3BhcmVudCxyZXBvc2l0b3J5LHJlcG9zaXRvcnlfaWTKQXEKM2dvb2dsZS5k
ZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIuUmVwb3NpdG9yeRI6Z29vZ2xlLmRl
dnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjFiZXRhMi5PcGVyYXRpb25NZXRhZGF0YRL6AQoQ
VXBkYXRlUmVwb3NpdG9yeRJBLmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYx
YmV0YTIuVXBkYXRlUmVwb3NpdG9yeVJlcXVlc3QaNC5nb29nbGUuZGV2dG9vbHMuYXJ0aWZh
Y3RyZWdpc3RyeS52MWJldGEyLlJlcG9zaXRvcnkibYLT5JMCTjJAL3YxYmV0YTIve3JlcG9z
aXRvcnkubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3JlcG9zaXRvcmllcy8qfToKcmVw
b3NpdG9yedpBFnJlcG9zaXRvcnksdXBkYXRlX21hc2sSkQIKEERlbGV0ZVJlcG9zaXRvcnkS
QS5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MWJldGEyLkRlbGV0ZVJlcG9z
aXRvcnlSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiKaAYLT5JMCNyo1
L3YxYmV0YTIve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9yZXBvc2l0b3JpZXMvKn3a
QQRuYW1lykFTChVnb29nbGUucHJvdG9idWYuRW1wdHkSOmdvb2dsZS5kZXZ0b29scy5hcnRp
ZmFjdHJlZ2lzdHJ5LnYxYmV0YTIuT3BlcmF0aW9uTWV0YWRhdGES4AEKDExpc3RQYWNrYWdl
cxI9Lmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIuTGlzdFBhY2th
Z2VzUmVxdWVzdBo+Lmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIu
TGlzdFBhY2thZ2VzUmVzcG9uc2UiUYLT5JMCQhJAL3YxYmV0YTIve3BhcmVudD1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL3JlcG9zaXRvcmllcy8qfS9wYWNrYWdlc9pBBnBhcmVudBLNAQoK
R2V0UGFja2FnZRI7Lmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIu
R2V0UGFja2FnZVJlcXVlc3QaMS5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52
MWJldGEyLlBhY2thZ2UiT4LT5JMCQhJAL3YxYmV0YTIve25hbWU9cHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9yZXBvc2l0b3JpZXMvKi9wYWNrYWdlcy8qfdpBBG5hbWUSlgIKDURlbGV0ZVBh
Y2thZ2USPi5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MWJldGEyLkRlbGV0
ZVBhY2thZ2VSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiKlAYLT5JMC
QipAL3YxYmV0YTIve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9yZXBvc2l0b3JpZXMv
Ki9wYWNrYWdlcy8qfdpBBG5hbWXKQVMKFWdvb2dsZS5wcm90b2J1Zi5FbXB0eRI6Z29vZ2xl
LmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjFiZXRhMi5PcGVyYXRpb25NZXRhZGF0YRLr
AQoMTGlzdFZlcnNpb25zEj0uZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjFi
ZXRhMi5MaXN0VmVyc2lvbnNSZXF1ZXN0Gj4uZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVn
aXN0cnkudjFiZXRhMi5MaXN0VmVyc2lvbnNSZXNwb25zZSJcgtPkkwJNEksvdjFiZXRhMi97
cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovcmVwb3NpdG9yaWVzLyovcGFja2FnZXMv
Kn0vdmVyc2lvbnPaQQZwYXJlbnQS2AEKCkdldFZlcnNpb24SOy5nb29nbGUuZGV2dG9vbHMu
YXJ0aWZhY3RyZWdpc3RyeS52MWJldGEyLkdldFZlcnNpb25SZXF1ZXN0GjEuZ29vZ2xlLmRl
dnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjFiZXRhMi5WZXJzaW9uIlqC0+STAk0SSy92MWJl
dGEyL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovcmVwb3NpdG9yaWVzLyovcGFja2Fn
ZXMvKi92ZXJzaW9ucy8qfdpBBG5hbWUSoQIKDURlbGV0ZVZlcnNpb24SPi5nb29nbGUuZGV2
dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MWJldGEyLkRlbGV0ZVZlcnNpb25SZXF1ZXN0Gh0u
Z29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiKwAYLT5JMCTSpLL3YxYmV0YTIve25hbWU9
cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9yZXBvc2l0b3JpZXMvKi9wYWNrYWdlcy8qL3ZlcnNp
b25zLyp92kEEbmFtZcpBUwoVZ29vZ2xlLnByb3RvYnVmLkVtcHR5Ejpnb29nbGUuZGV2dG9v
bHMuYXJ0aWZhY3RyZWdpc3RyeS52MWJldGEyLk9wZXJhdGlvbk1ldGFkYXRhEtQBCglMaXN0
RmlsZXMSOi5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MWJldGEyLkxpc3RG
aWxlc1JlcXVlc3QaOy5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MWJldGEy
Lkxpc3RGaWxlc1Jlc3BvbnNlIk6C0+STAj8SPS92MWJldGEyL3twYXJlbnQ9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9yZXBvc2l0b3JpZXMvKn0vZmlsZXPaQQZwYXJlbnQSwgEKB0dldEZp
bGUSOC5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MWJldGEyLkdldEZpbGVS
ZXF1ZXN0Gi4uZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjFiZXRhMi5GaWxl
Ik2C0+STAkASPi92MWJldGEyL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovcmVwb3Np
dG9yaWVzLyovZmlsZXMvKip92kEEbmFtZRLbAQoITGlzdFRhZ3MSOS5nb29nbGUuZGV2dG9v
bHMuYXJ0aWZhY3RyZWdpc3RyeS52MWJldGEyLkxpc3RUYWdzUmVxdWVzdBo6Lmdvb2dsZS5k
ZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIuTGlzdFRhZ3NSZXNwb25zZSJYgtPk
kwJJEkcvdjFiZXRhMi97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovcmVwb3NpdG9y
aWVzLyovcGFja2FnZXMvKn0vdGFnc9pBBnBhcmVudBLIAQoGR2V0VGFnEjcuZ29vZ2xlLmRl
dnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjFiZXRhMi5HZXRUYWdSZXF1ZXN0Gi0uZ29vZ2xl
LmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjFiZXRhMi5UYWciVoLT5JMCSRJHL3YxYmV0
YTIve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9yZXBvc2l0b3JpZXMvKi9wYWNrYWdl
cy8qL3RhZ3MvKn3aQQRuYW1lEuABCglDcmVhdGVUYWcSOi5nb29nbGUuZGV2dG9vbHMuYXJ0
aWZhY3RyZWdpc3RyeS52MWJldGEyLkNyZWF0ZVRhZ1JlcXVlc3QaLS5nb29nbGUuZGV2dG9v
bHMuYXJ0aWZhY3RyZWdpc3RyeS52MWJldGEyLlRhZyJogtPkkwJOIkcvdjFiZXRhMi97cGFy
ZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovcmVwb3NpdG9yaWVzLyovcGFja2FnZXMvKn0v
dGFnczoDdGFn2kERcGFyZW50LHRhZyx0YWdfaWQS4gEKCVVwZGF0ZVRhZxI6Lmdvb2dsZS5k
ZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIuVXBkYXRlVGFnUmVxdWVzdBotLmdv
b2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIuVGFnImqC0+STAlIySy92
MWJldGEyL3t0YWcubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3JlcG9zaXRvcmllcy8q
L3BhY2thZ2VzLyovdGFncy8qfToDdGFn2kEPdGFnLHVwZGF0ZV9tYXNrErcBCglEZWxldGVU
YWcSOi5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS52MWJldGEyLkRlbGV0ZVRh
Z1JlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkiVoLT5JMCSSpHL3YxYmV0YTIve25h
bWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9yZXBvc2l0b3JpZXMvKi9wYWNrYWdlcy8qL3Rh
Z3MvKn3aQQRuYW1lEpwBCgxTZXRJYW1Qb2xpY3kSIi5nb29nbGUuaWFtLnYxLlNldElhbVBv
bGljeVJlcXVlc3QaFS5nb29nbGUuaWFtLnYxLlBvbGljeSJRgtPkkwJLIkYvdjFiZXRhMi97
cmVzb3VyY2U9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9yZXBvc2l0b3JpZXMvKn06c2V0SWFt
UG9saWN5OgEqEpkBCgxHZXRJYW1Qb2xpY3kSIi5nb29nbGUuaWFtLnYxLkdldElhbVBvbGlj
eVJlcXVlc3QaFS5nb29nbGUuaWFtLnYxLlBvbGljeSJOgtPkkwJIEkYvdjFiZXRhMi97cmVz
b3VyY2U9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9yZXBvc2l0b3JpZXMvKn06Z2V0SWFtUG9s
aWN5EsIBChJUZXN0SWFtUGVybWlzc2lvbnMSKC5nb29nbGUuaWFtLnYxLlRlc3RJYW1QZXJt
aXNzaW9uc1JlcXVlc3QaKS5nb29nbGUuaWFtLnYxLlRlc3RJYW1QZXJtaXNzaW9uc1Jlc3Bv
bnNlIleC0+STAlEiTC92MWJldGEyL3tyZXNvdXJjZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8q
L3JlcG9zaXRvcmllcy8qfTp0ZXN0SWFtUGVybWlzc2lvbnM6ASoSzwEKEkdldFByb2plY3RT
ZXR0aW5ncxJDLmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIuR2V0
UHJvamVjdFNldHRpbmdzUmVxdWVzdBo5Lmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lz
dHJ5LnYxYmV0YTIuUHJvamVjdFNldHRpbmdzIjmC0+STAiwSKi92MWJldGEyL3tuYW1lPXBy
b2plY3RzLyovcHJvamVjdFNldHRpbmdzfdpBBG5hbWUSkAIKFVVwZGF0ZVByb2plY3RTZXR0
aW5ncxJGLmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIuVXBkYXRl
UHJvamVjdFNldHRpbmdzUmVxdWVzdBo5Lmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lz
dHJ5LnYxYmV0YTIuUHJvamVjdFNldHRpbmdzInSC0+STAk8yOy92MWJldGEyL3twcm9qZWN0
X3NldHRpbmdzLm5hbWU9cHJvamVjdHMvKi9wcm9qZWN0U2V0dGluZ3N9OhBwcm9qZWN0X3Nl
dHRpbmdz2kEccHJvamVjdF9zZXR0aW5ncyx1cGRhdGVfbWFzaxqMAcpBH2FydGlmYWN0cmVn
aXN0cnkuZ29vZ2xlYXBpcy5jb23SQWdodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRo
L2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQt
cGxhdGZvcm0ucmVhZC1vbmx5QpACCixjb20uZ29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVn
aXN0cnkudjFiZXRhMkIMU2VydmljZVByb3RvUAFaVWNsb3VkLmdvb2dsZS5jb20vZ28vYXJ0
aWZhY3RyZWdpc3RyeS9hcGl2MWJldGEyL2FydGlmYWN0cmVnaXN0cnlwYjthcnRpZmFjdHJl
Z2lzdHJ5cGKqAiVHb29nbGUuQ2xvdWQuQXJ0aWZhY3RSZWdpc3RyeS5WMUJldGEyygIlR29v
Z2xlXENsb3VkXEFydGlmYWN0UmVnaXN0cnlcVjFiZXRhMuoCKEdvb2dsZTo6Q2xvdWQ6OkFy
dGlmYWN0UmVnaXN0cnk6OlYxYmV0YTJKxjIKBxIFDgCvAgEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQADEKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMC
EgMUAEUKCQoCAwMSAxUAPQoJCgIDBBIDFgBACgkKAgMFEgMXAEMKCQoCAwYSAxgAQQoJCgID
BxIDGQA8CgkKAgMIEgMaAEAKCQoCAwkSAxsARQoJCgIDChIDHAAoCgkKAgMLEgMdACQKCQoC
AwwSAx4ALQoJCgIDDRIDHwAlCggKAQgSAyEAQgoJCgIIJRIDIQBCCggKAQgSAyIAbAoJCgII
CxIDIgBsCggKAQgSAyMAIgoJCgIIChIDIwAiCggKAQgSAyQALQoJCgIICBIDJAAtCggKAQgS
AyUARQoJCgIIARIDJQBFCggKAQgSAyYAQgoJCgIIKRIDJgBCCggKAQgSAycAQQoJCgIILRID
JwBBCoQECgIGABIFNgCqAgEa9gMgVGhlIEFydGlmYWN0IFJlZ2lzdHJ5IEFQSSBzZXJ2aWNl
LgoKIEFydGlmYWN0IFJlZ2lzdHJ5IGlzIGFuIGFydGlmYWN0IG1hbmFnZW1lbnQgc3lzdGVt
IGZvciBzdG9yaW5nIGFydGlmYWN0cwogZnJvbSBkaWZmZXJlbnQgcGFja2FnZSBtYW5hZ2Vt
ZW50IHN5c3RlbXMuCgogVGhlIHJlc291cmNlcyBtYW5hZ2VkIGJ5IHRoaXMgQVBJIGFyZToK
CiAqIFJlcG9zaXRvcmllcywgd2hpY2ggZ3JvdXAgcGFja2FnZXMgYW5kIHRoZWlyIGRhdGEu
CiAqIFBhY2thZ2VzLCB3aGljaCBncm91cCB2ZXJzaW9ucyBhbmQgdGhlaXIgdGFncy4KICog
VmVyc2lvbnMsIHdoaWNoIGFyZSBzcGVjaWZpYyBmb3JtcyBvZiBhIHBhY2thZ2UuCiAqIFRh
Z3MsIHdoaWNoIHJlcHJlc2VudCBhbHRlcm5hdGl2ZSBuYW1lcyBmb3IgdmVyc2lvbnMuCiAq
IEZpbGVzLCB3aGljaCBjb250YWluIGNvbnRlbnQgYW5kIGFyZSBvcHRpb25hbGx5IGFzc29j
aWF0ZWQgd2l0aCBhIFBhY2thZ2UKICAgb3IgVmVyc2lvbi4KCgoKAwYAARIDNggYCgoKAwYA
AxIDNwJHCgwKBQYAA5kIEgM3AkcKCwoDBgADEgQ4AjpBCg0KBQYAA5oIEgQ4AjpBCogCCgQG
AAIAEgRAAkkDGvkBIEltcG9ydHMgQXB0IGFydGlmYWN0cy4gVGhlIHJldHVybmVkIE9wZXJh
dGlvbiB3aWxsIGNvbXBsZXRlIG9uY2UgdGhlCiByZXNvdXJjZXMgYXJlIGltcG9ydGVkLiBQ
YWNrYWdlLCBWZXJzaW9uLCBhbmQgRmlsZSByZXNvdXJjZXMgYXJlIGNyZWF0ZWQKIGJhc2Vk
IG9uIHRoZSBpbXBvcnRlZCBhcnRpZmFjdHMuIEltcG9ydGVkIGFydGlmYWN0cyB0aGF0IGNv
bmZsaWN0IHdpdGgKIGV4aXN0aW5nIHJlc291cmNlcyBhcmUgaWdub3JlZC4KCgwKBQYAAgAB
EgNABhgKDAoFBgACAAISA0AZMgoMCgUGAAIAAxIDQD1ZCg0KBQYAAgAEEgRBBEQGChEKCQYA
AgAEsMq8IhIEQQREBgoNCgUGAAIABBIERQRIBgoPCgcGAAIABJkIEgRFBEgGCo4CCgQGAAIB
EgRPAlgDGv8BIEltcG9ydHMgWXVtIChSUE0pIGFydGlmYWN0cy4gVGhlIHJldHVybmVkIE9w
ZXJhdGlvbiB3aWxsIGNvbXBsZXRlIG9uY2UgdGhlCiByZXNvdXJjZXMgYXJlIGltcG9ydGVk
LiBQYWNrYWdlLCBWZXJzaW9uLCBhbmQgRmlsZSByZXNvdXJjZXMgYXJlIGNyZWF0ZWQKIGJh
c2VkIG9uIHRoZSBpbXBvcnRlZCBhcnRpZmFjdHMuIEltcG9ydGVkIGFydGlmYWN0cyB0aGF0
IGNvbmZsaWN0IHdpdGgKIGV4aXN0aW5nIHJlc291cmNlcyBhcmUgaWdub3JlZC4KCgwKBQYA
AgEBEgNPBhgKDAoFBgACAQISA08ZMgoMCgUGAAIBAxIDTz1ZCg0KBQYAAgEEEgRQBFMGChEK
CQYAAgEEsMq8IhIEUARTBgoNCgUGAAIBBBIEVARXBgoPCgcGAAIBBJkIEgRUBFcGCiMKBAYA
AgISBFsCYAMaFSBMaXN0cyByZXBvc2l0b3JpZXMuCgoMCgUGAAICARIDWwYWCgwKBQYAAgIC
EgNbFy4KDAoFBgACAgMSA1s5UQoNCgUGAAICBBIEXAReBgoRCgkGAAICBLDKvCISBFwEXgYK
DAoFBgACAgQSA18ENAoPCggGAAICBJsIABIDXwQ0CiIKBAYAAgMSBGMCaAMaFCBHZXRzIGEg
cmVwb3NpdG9yeS4KCgwKBQYAAgMBEgNjBhMKDAoFBgACAwISA2MUKAoMCgUGAAIDAxIDYzM9
Cg0KBQYAAgMEEgRkBGYGChEKCQYAAgMEsMq8IhIEZARmBgoMCgUGAAIDBBIDZwQyCg8KCAYA
AgMEmwgAEgNnBDIKnQEKBAYAAgQSBGwCdgMajgEgQ3JlYXRlcyBhIHJlcG9zaXRvcnkuIFRo
ZSByZXR1cm5lZCBPcGVyYXRpb24gd2lsbCBmaW5pc2ggb25jZSB0aGUKIHJlcG9zaXRvcnkg
aGFzIGJlZW4gY3JlYXRlZC4gSXRzIHJlc3BvbnNlIHdpbGwgYmUgdGhlIGNyZWF0ZWQgUmVw
b3NpdG9yeS4KCgwKBQYAAgQBEgNsBhYKDAoFBgACBAISA2wXLgoMCgUGAAIEAxIDbDlVCg0K
BQYAAgQEEgRtBHAGChEKCQYAAgQEsMq8IhIEbQRwBgoMCgUGAAIEBBIDcQRNCg8KCAYAAgQE
mwgAEgNxBE0KDQoFBgACBAQSBHIEdQYKDwoHBgACBASZCBIEcgR1BgolCgQGAAIFEgR5An8D
GhcgVXBkYXRlcyBhIHJlcG9zaXRvcnkuCgoMCgUGAAIFARIDeQYWCgwKBQYAAgUCEgN5Fy4K
DAoFBgACBQMSA3k5QwoNCgUGAAIFBBIEegR9BgoRCgkGAAIFBLDKvCISBHoEfQYKDAoFBgAC
BQQSA34ERAoPCggGAAIFBJsIABIDfgRECuUBCgQGAAIGEgaEAQKNAQMa1AEgRGVsZXRlcyBh
IHJlcG9zaXRvcnkgYW5kIGFsbCBvZiBpdHMgY29udGVudHMuIFRoZSByZXR1cm5lZCBPcGVy
YXRpb24gd2lsbAogZmluaXNoIG9uY2UgdGhlIHJlcG9zaXRvcnkgaGFzIGJlZW4gZGVsZXRl
ZC4gSXQgd2lsbCBub3QgaGF2ZSBhbnkgT3BlcmF0aW9uCiBtZXRhZGF0YSBhbmQgd2lsbCBy
ZXR1cm4gYSBnb29nbGUucHJvdG9idWYuRW1wdHkgcmVzcG9uc2UuCgoNCgUGAAIGARIEhAEG
FgoNCgUGAAIGAhIEhAEXLgoNCgUGAAIGAxIEhAE5VQoPCgUGAAIGBBIGhQEEhwEGChMKCQYA
AgYEsMq8IhIGhQEEhwEGCg0KBQYAAgYEEgSIAQQyChAKCAYAAgYEmwgAEgSIAQQyCg8KBQYA
AgYEEgaJAQSMAQYKEQoHBgACBgSZCBIGiQEEjAEGCiEKBAYAAgcSBpABApUBAxoRIExpc3Rz
IHBhY2thZ2VzLgoKDQoFBgACBwESBJABBhIKDQoFBgACBwISBJABEyYKDQoFBgACBwMSBJAB
MUUKDwoFBgACBwQSBpEBBJMBBgoTCgkGAAIHBLDKvCISBpEBBJMBBgoNCgUGAAIHBBIElAEE
NAoQCggGAAIHBJsIABIElAEENAohCgQGAAIIEgaYAQKdAQMaESBHZXRzIGEgcGFja2FnZS4K
Cg0KBQYAAggBEgSYAQYQCg0KBQYAAggCEgSYAREiCg0KBQYAAggDEgSYAS00Cg8KBQYAAggE
EgaZAQSbAQYKEwoJBgACCASwyrwiEgaZAQSbAQYKDQoFBgACCAQSBJwBBDIKEAoIBgACCASb
CAASBJwBBDIKjgEKBAYAAgkSBqEBAqoBAxp+IERlbGV0ZXMgYSBwYWNrYWdlIGFuZCBhbGwg
b2YgaXRzIHZlcnNpb25zIGFuZCB0YWdzLiBUaGUgcmV0dXJuZWQgb3BlcmF0aW9uCiB3aWxs
IGNvbXBsZXRlIG9uY2UgdGhlIHBhY2thZ2UgaGFzIGJlZW4gZGVsZXRlZC4KCg0KBQYAAgkB
EgShAQYTCg0KBQYAAgkCEgShARQoCg0KBQYAAgkDEgShATNPCg8KBQYAAgkEEgaiAQSkAQYK
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
eS4KCgsKAwQAARIErQIIGWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::V1beta2::Service::OperationMetadata ===
    # Fields for OperationMetadata

# === Service Client: Google::Devtools::Artifactregistry::V1beta2::Service::ArtifactRegistryClient ===
package Google::Devtools::Artifactregistry::V1beta2::Service::ArtifactRegistryClient;

=pod

=head2 Service Client: Google::Devtools::Artifactregistry::V1beta2::Service::ArtifactRegistryClient

Client stub representing the remote C<ArtifactRegistry> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<devtools.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'devtools.googleapis.com:443' );

has _grpc_client => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Google::gRPC::Client->new(
            target     => $self->target,
            auth_token => $self->credentials->get_token(),
        );
    }
);

sub import_apt_artifacts {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Artifactregistry::V1beta2::AptArtifact::ImportAptArtifactsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'ImportAptArtifacts',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub import_yum_artifacts {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Artifactregistry::V1beta2::YumArtifact::ImportYumArtifactsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'ImportYumArtifacts',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_repositories {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Artifactregistry::V1beta2::Repository::ListRepositoriesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'ListRepositories',
        request        => $req,
        response_class => 'Google::Devtools::Artifactregistry::V1beta2::Repository::ListRepositoriesResponse',
    });
}

sub get_repository {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Artifactregistry::V1beta2::Repository::GetRepositoryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'GetRepository',
        request        => $req,
        response_class => 'Google::Devtools::Artifactregistry::V1beta2::Repository::Repository',
    });
}

sub create_repository {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Artifactregistry::V1beta2::Repository::CreateRepositoryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'CreateRepository',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_repository {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Artifactregistry::V1beta2::Repository::UpdateRepositoryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'UpdateRepository',
        request        => $req,
        response_class => 'Google::Devtools::Artifactregistry::V1beta2::Repository::Repository',
    });
}

sub delete_repository {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Artifactregistry::V1beta2::Repository::DeleteRepositoryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'DeleteRepository',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_packages {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Artifactregistry::V1beta2::Package::ListPackagesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'ListPackages',
        request        => $req,
        response_class => 'Google::Devtools::Artifactregistry::V1beta2::Package::ListPackagesResponse',
    });
}

sub get_package {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Artifactregistry::V1beta2::Package::GetPackageRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'GetPackage',
        request        => $req,
        response_class => 'Google::Devtools::Artifactregistry::V1beta2::Package::Package',
    });
}

sub delete_package {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Artifactregistry::V1beta2::Package::DeletePackageRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'DeletePackage',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_versions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Artifactregistry::V1beta2::Version::ListVersionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'ListVersions',
        request        => $req,
        response_class => 'Google::Devtools::Artifactregistry::V1beta2::Version::ListVersionsResponse',
    });
}

sub get_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Artifactregistry::V1beta2::Version::GetVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'GetVersion',
        request        => $req,
        response_class => 'Google::Devtools::Artifactregistry::V1beta2::Version::Version',
    });
}

sub delete_version {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Artifactregistry::V1beta2::Version::DeleteVersionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'DeleteVersion',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_files {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Artifactregistry::V1beta2::File::ListFilesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'ListFiles',
        request        => $req,
        response_class => 'Google::Devtools::Artifactregistry::V1beta2::File::ListFilesResponse',
    });
}

sub get_file {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Artifactregistry::V1beta2::File::GetFileRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'GetFile',
        request        => $req,
        response_class => 'Google::Devtools::Artifactregistry::V1beta2::File::File',
    });
}

sub list_tags {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Artifactregistry::V1beta2::Tag::ListTagsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'ListTags',
        request        => $req,
        response_class => 'Google::Devtools::Artifactregistry::V1beta2::Tag::ListTagsResponse',
    });
}

sub get_tag {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Artifactregistry::V1beta2::Tag::GetTagRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'GetTag',
        request        => $req,
        response_class => 'Google::Devtools::Artifactregistry::V1beta2::Tag::Tag',
    });
}

sub create_tag {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Artifactregistry::V1beta2::Tag::CreateTagRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'CreateTag',
        request        => $req,
        response_class => 'Google::Devtools::Artifactregistry::V1beta2::Tag::Tag',
    });
}

sub update_tag {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Artifactregistry::V1beta2::Tag::UpdateTagRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'UpdateTag',
        request        => $req,
        response_class => 'Google::Devtools::Artifactregistry::V1beta2::Tag::Tag',
    });
}

sub delete_tag {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Artifactregistry::V1beta2::Tag::DeleteTagRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'DeleteTag',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub set_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::SetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'SetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub get_iam_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::GetIamPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'GetIamPolicy',
        request        => $req,
        response_class => 'Google::Iam::V1::Policy::Policy',
    });
}

sub test_iam_permissions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Iam::V1::IamPolicy::TestIamPermissionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'TestIamPermissions',
        request        => $req,
        response_class => 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse',
    });
}

sub get_project_settings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Artifactregistry::V1beta2::Settings::GetProjectSettingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'GetProjectSettings',
        request        => $req,
        response_class => 'Google::Devtools::Artifactregistry::V1beta2::Settings::ProjectSettings',
    });
}

sub update_project_settings {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Artifactregistry::V1beta2::Settings::UpdateProjectSettingsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.artifactregistry.v1beta2.ArtifactRegistry',
        method         => 'UpdateProjectSettings',
        request        => $req,
        response_class => 'Google::Devtools::Artifactregistry::V1beta2::Settings::ProjectSettings',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::V1beta2::Service - Compiled Protocol Buffers messages for google/devtools/artifactregistry/v1beta2/service.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::V1beta2::Service;

    my $msg = Google::Devtools::Artifactregistry::V1beta2::Service::OperationMetadata->new({
    });

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::V1beta2::Service::OperationMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/v1beta2/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::V1beta2::Service::OperationMetadata

Metadata type for longrunning-operations, currently empty.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::V1beta2::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
