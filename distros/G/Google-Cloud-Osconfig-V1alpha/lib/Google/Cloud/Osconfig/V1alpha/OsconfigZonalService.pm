package Google::Cloud::Osconfig::V1alpha::OsconfigZonalService;

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
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance };
    eval { require Google::Cloud::Osconfig::V1alpha::Inventory };
    eval { require Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports };
    eval { require Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments };
    eval { require Google::Cloud::Osconfig::V1alpha::Vulnerability };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvb3Njb25maWcvdjFhbHBoYS9vc2NvbmZpZ196b25hbF9zZXJ2aWNl
LnByb3RvEh1nb29nbGUuY2xvdWQub3Njb25maWcudjFhbHBoYRocZ29vZ2xlL2FwaS9hbm5v
dGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aGWdvb2dsZS9hcGkvcmVz
b3VyY2UucHJvdG8aQ2dvb2dsZS9jbG91ZC9vc2NvbmZpZy92MWFscGhhL2luc3RhbmNlX29z
X3BvbGljaWVzX2NvbXBsaWFuY2UucHJvdG8aLWdvb2dsZS9jbG91ZC9vc2NvbmZpZy92MWFs
cGhhL2ludmVudG9yeS5wcm90bxpAZ29vZ2xlL2Nsb3VkL29zY29uZmlnL3YxYWxwaGEvb3Nf
cG9saWN5X2Fzc2lnbm1lbnRfcmVwb3J0cy5wcm90bxo5Z29vZ2xlL2Nsb3VkL29zY29uZmln
L3YxYWxwaGEvb3NfcG9saWN5X2Fzc2lnbm1lbnRzLnByb3RvGjFnb29nbGUvY2xvdWQvb3Nj
b25maWcvdjFhbHBoYS92dWxuZXJhYmlsaXR5LnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcv
b3BlcmF0aW9ucy5wcm90bzLoHAoUT3NDb25maWdab25hbFNlcnZpY2USyAIKGENyZWF0ZU9T
UG9saWN5QXNzaWdubWVudBI+Lmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MWFscGhhLkNyZWF0
ZU9TUG9saWN5QXNzaWdubWVudFJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0
aW9uIswBgtPkkwJUIjwvdjFhbHBoYS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9
L29zUG9saWN5QXNzaWdubWVudHM6FG9zX3BvbGljeV9hc3NpZ25tZW502kEzcGFyZW50LG9z
X3BvbGljeV9hc3NpZ25tZW50LG9zX3BvbGljeV9hc3NpZ25tZW50X2lkykE5ChJPU1BvbGlj
eUFzc2lnbm1lbnQSI09TUG9saWN5QXNzaWdubWVudE9wZXJhdGlvbk1ldGFkYXRhEsoCChhV
cGRhdGVPU1BvbGljeUFzc2lnbm1lbnQSPi5nb29nbGUuY2xvdWQub3Njb25maWcudjFhbHBo
YS5VcGRhdGVPU1BvbGljeUFzc2lnbm1lbnRSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5n
Lk9wZXJhdGlvbiLOAYLT5JMCaTJRL3YxYWxwaGEve29zX3BvbGljeV9hc3NpZ25tZW50Lm5h
bWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9vc1BvbGljeUFzc2lnbm1lbnRzLyp9OhRvc19w
b2xpY3lfYXNzaWdubWVudNpBIG9zX3BvbGljeV9hc3NpZ25tZW50LHVwZGF0ZV9tYXNrykE5
ChJPU1BvbGljeUFzc2lnbm1lbnQSI09TUG9saWN5QXNzaWdubWVudE9wZXJhdGlvbk1ldGFk
YXRhEtQBChVHZXRPU1BvbGljeUFzc2lnbm1lbnQSOy5nb29nbGUuY2xvdWQub3Njb25maWcu
djFhbHBoYS5HZXRPU1BvbGljeUFzc2lnbm1lbnRSZXF1ZXN0GjEuZ29vZ2xlLmNsb3VkLm9z
Y29uZmlnLnYxYWxwaGEuT1NQb2xpY3lBc3NpZ25tZW50IkuC0+STAj4SPC92MWFscGhhL3tu
YW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovb3NQb2xpY3lBc3NpZ25tZW50cy8qfdpBBG5h
bWUS5wEKF0xpc3RPU1BvbGljeUFzc2lnbm1lbnRzEj0uZ29vZ2xlLmNsb3VkLm9zY29uZmln
LnYxYWxwaGEuTGlzdE9TUG9saWN5QXNzaWdubWVudHNSZXF1ZXN0Gj4uZ29vZ2xlLmNsb3Vk
Lm9zY29uZmlnLnYxYWxwaGEuTGlzdE9TUG9saWN5QXNzaWdubWVudHNSZXNwb25zZSJNgtPk
kwI+EjwvdjFhbHBoYS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L29zUG9saWN5
QXNzaWdubWVudHPaQQZwYXJlbnQSiwIKH0xpc3RPU1BvbGljeUFzc2lnbm1lbnRSZXZpc2lv
bnMSRS5nb29nbGUuY2xvdWQub3Njb25maWcudjFhbHBoYS5MaXN0T1NQb2xpY3lBc3NpZ25t
ZW50UmV2aXNpb25zUmVxdWVzdBpGLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MWFscGhhLkxp
c3RPU1BvbGljeUFzc2lnbm1lbnRSZXZpc2lvbnNSZXNwb25zZSJZgtPkkwJMEkovdjFhbHBo
YS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL29zUG9saWN5QXNzaWdubWVudHMvKn06
bGlzdFJldmlzaW9uc9pBBG5hbWUShgIKGERlbGV0ZU9TUG9saWN5QXNzaWdubWVudBI+Lmdv
b2dsZS5jbG91ZC5vc2NvbmZpZy52MWFscGhhLkRlbGV0ZU9TUG9saWN5QXNzaWdubWVudFJl
cXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIooBgtPkkwI+KjwvdjFhbHBo
YS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL29zUG9saWN5QXNzaWdubWVudHMvKn3a
QQRuYW1lykE8ChVnb29nbGUucHJvdG9idWYuRW1wdHkSI09TUG9saWN5QXNzaWdubWVudE9w
ZXJhdGlvbk1ldGFkYXRhEv8BCh9HZXRJbnN0YW5jZU9TUG9saWNpZXNDb21wbGlhbmNlEkUu
Z29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxYWxwaGEuR2V0SW5zdGFuY2VPU1BvbGljaWVzQ29t
cGxpYW5jZVJlcXVlc3QaOy5nb29nbGUuY2xvdWQub3Njb25maWcudjFhbHBoYS5JbnN0YW5j
ZU9TUG9saWNpZXNDb21wbGlhbmNlIliIAgGC0+STAkgSRi92MWFscGhhL3tuYW1lPXByb2pl
Y3RzLyovbG9jYXRpb25zLyovaW5zdGFuY2VPU1BvbGljaWVzQ29tcGxpYW5jZXMvKn3aQQRu
YW1lEpICCiFMaXN0SW5zdGFuY2VPU1BvbGljaWVzQ29tcGxpYW5jZXMSRy5nb29nbGUuY2xv
dWQub3Njb25maWcudjFhbHBoYS5MaXN0SW5zdGFuY2VPU1BvbGljaWVzQ29tcGxpYW5jZXNS
ZXF1ZXN0GkguZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxYWxwaGEuTGlzdEluc3RhbmNlT1NQ
b2xpY2llc0NvbXBsaWFuY2VzUmVzcG9uc2UiWogCAYLT5JMCSBJGL3YxYWxwaGEve3BhcmVu
dD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9pbnN0YW5jZU9TUG9saWNpZXNDb21wbGlhbmNl
c9pBBnBhcmVudBL5AQobR2V0T1NQb2xpY3lBc3NpZ25tZW50UmVwb3J0EkEuZ29vZ2xlLmNs
b3VkLm9zY29uZmlnLnYxYWxwaGEuR2V0T1NQb2xpY3lBc3NpZ25tZW50UmVwb3J0UmVxdWVz
dBo3Lmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MWFscGhhLk9TUG9saWN5QXNzaWdubWVudFJl
cG9ydCJegtPkkwJREk8vdjFhbHBoYS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2lu
c3RhbmNlcy8qL29zUG9saWN5QXNzaWdubWVudHMvKi9yZXBvcnR92kEEbmFtZRKPAgodTGlz
dE9TUG9saWN5QXNzaWdubWVudFJlcG9ydHMSQy5nb29nbGUuY2xvdWQub3Njb25maWcudjFh
bHBoYS5MaXN0T1NQb2xpY3lBc3NpZ25tZW50UmVwb3J0c1JlcXVlc3QaRC5nb29nbGUuY2xv
dWQub3Njb25maWcudjFhbHBoYS5MaXN0T1NQb2xpY3lBc3NpZ25tZW50UmVwb3J0c1Jlc3Bv
bnNlImOC0+STAlQSUi92MWFscGhhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9p
bnN0YW5jZXMvKi9vc1BvbGljeUFzc2lnbm1lbnRzLyp9L3JlcG9ydHPaQQZwYXJlbnQSuQEK
DEdldEludmVudG9yeRIyLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MWFscGhhLkdldEludmVu
dG9yeVJlcXVlc3QaKC5nb29nbGUuY2xvdWQub3Njb25maWcudjFhbHBoYS5JbnZlbnRvcnki
S4LT5JMCPhI8L3YxYWxwaGEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9pbnN0YW5j
ZXMvKi9pbnZlbnRvcnl92kEEbmFtZRLTAQoPTGlzdEludmVudG9yaWVzEjUuZ29vZ2xlLmNs
b3VkLm9zY29uZmlnLnYxYWxwaGEuTGlzdEludmVudG9yaWVzUmVxdWVzdBo2Lmdvb2dsZS5j
bG91ZC5vc2NvbmZpZy52MWFscGhhLkxpc3RJbnZlbnRvcmllc1Jlc3BvbnNlIlGC0+STAkIS
QC92MWFscGhhL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9pbnN0YW5jZXMvKn0v
aW52ZW50b3JpZXPaQQZwYXJlbnQS4QEKFkdldFZ1bG5lcmFiaWxpdHlSZXBvcnQSPC5nb29n
bGUuY2xvdWQub3Njb25maWcudjFhbHBoYS5HZXRWdWxuZXJhYmlsaXR5UmVwb3J0UmVxdWVz
dBoyLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MWFscGhhLlZ1bG5lcmFiaWxpdHlSZXBvcnQi
VYLT5JMCSBJGL3YxYWxwaGEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9pbnN0YW5j
ZXMvKi92dWxuZXJhYmlsaXR5UmVwb3J0fdpBBG5hbWUS9wEKGExpc3RWdWxuZXJhYmlsaXR5
UmVwb3J0cxI+Lmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MWFscGhhLkxpc3RWdWxuZXJhYmls
aXR5UmVwb3J0c1JlcXVlc3QaPy5nb29nbGUuY2xvdWQub3Njb25maWcudjFhbHBoYS5MaXN0
VnVsbmVyYWJpbGl0eVJlcG9ydHNSZXNwb25zZSJagtPkkwJLEkkvdjFhbHBoYS97cGFyZW50
PXByb2plY3RzLyovbG9jYXRpb25zLyovaW5zdGFuY2VzLyp9L3Z1bG5lcmFiaWxpdHlSZXBv
cnRz2kEGcGFyZW50GkvKQRdvc2NvbmZpZy5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3
Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1CxAIKIWNvbS5nb29nbGUuY2xv
dWQub3Njb25maWcudjFhbHBoYUIZT3NDb25maWdab25hbFNlcnZpY2VQcm90b1ABWj1jbG91
ZC5nb29nbGUuY29tL2dvL29zY29uZmlnL2FwaXYxYWxwaGEvb3Njb25maWdwYjtvc2NvbmZp
Z3BiqgIdR29vZ2xlLkNsb3VkLk9zQ29uZmlnLlYxQWxwaGHKAh1Hb29nbGVcQ2xvdWRcT3ND
b25maWdcVjFhbHBoYeoCIEdvb2dsZTo6Q2xvdWQ6Ok9zQ29uZmlnOjpWMWFscGhh6kFfCh9j
b21wdXRlLmdvb2dsZWFwaXMuY29tL0luc3RhbmNlEjxwcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vaW5zdGFuY2VzL3tpbnN0YW5jZX1KmS0KBxIFDgDWAQEKvAQK
AQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIg
dGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3Ug
bWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExp
Y2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAg
aHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJl
cXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0
d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24g
YW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9G
IEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNl
IGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAog
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACYKCQoCAwASAxIAJgoJ
CgIDARIDEwAhCgkKAgMCEgMUACMKCQoCAwMSAxUATQoJCgIDBBIDFgA3CgkKAgMFEgMXAEoK
CQoCAwYSAxgAQwoJCgIDBxIDGQA7CgkKAgMIEgMaAC0KCAoBCBIDHAA6CgkKAgglEgMcADoK
CAoBCBIDHQBUCgkKAggLEgMdAFQKCAoBCBIDHgAiCgkKAggKEgMeACIKCAoBCBIDHwA6CgkK
AggIEgMfADoKCAoBCBIDIAA6CgkKAggBEgMgADoKCAoBCBIDIQA6CgkKAggpEgMhADoKCAoB
CBIDIgA5CgkKAggtEgMiADkKCQoBCBIEIwAmAgoMCgQInQgAEgQjACYCCrsBCgIGABIFLADW
AQEarQEgWm9uYWwgT1MgQ29uZmlnIEFQSQoKIFRoZSBPUyBDb25maWcgc2VydmljZSBpcyB0
aGUgc2VydmVyLXNpZGUgY29tcG9uZW50IHRoYXQgYWxsb3dzIHVzZXJzIHRvCiBtYW5hZ2Ug
cGFja2FnZSBpbnN0YWxsYXRpb25zIGFuZCBwYXRjaCBqb2JzIGZvciBDb21wdXRlIEVuZ2lu
ZSBWTSBpbnN0YW5jZXMuCgoKCgMGAAESAywIHAoKCgMGAAMSAy0CPwoMCgUGAAOZCBIDLQI/
CgoKAwYAAxIDLgJWCgwKBQYAA5oIEgMuAlYK3wMKBAYAAgASBDkCQwMa0AMgQ3JlYXRlIGFu
IE9TIHBvbGljeSBhc3NpZ25tZW50LgoKIFRoaXMgbWV0aG9kIGFsc28gY3JlYXRlcyB0aGUg
Zmlyc3QgcmV2aXNpb24gb2YgdGhlIE9TIHBvbGljeSBhc3NpZ25tZW50LgoKIFRoaXMgbWV0
aG9kIHJldHVybnMgYSBsb25nIHJ1bm5pbmcgb3BlcmF0aW9uIChMUk8pIHRoYXQgY29udGFp
bnMgdGhlCiByb2xsb3V0IGRldGFpbHMuIFRoZSByb2xsb3V0IGNhbiBiZSBjYW5jZWxsZWQg
YnkgY2FuY2VsbGluZyB0aGUgTFJPLgoKIEZvciBtb3JlIGluZm9ybWF0aW9uLCBzZWUgW01l
dGhvZDoKIHByb2plY3RzLmxvY2F0aW9ucy5vc1BvbGljeUFzc2lnbm1lbnRzLm9wZXJhdGlv
bnMuY2FuY2VsXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vY29tcHV0ZS9kb2NzL29zY29u
ZmlnL3Jlc3QvdjFhbHBoYS9wcm9qZWN0cy5sb2NhdGlvbnMub3NQb2xpY3lBc3NpZ25tZW50
cy5vcGVyYXRpb25zL2NhbmNlbCkuCgoMCgUGAAIAARIDOQYeCgwKBQYAAgACEgM5Hz4KDAoF
BgACAAMSAzlJZQoNCgUGAAIABBIEOgQ9BgoRCgkGAAIABLDKvCISBDoEPQYKDAoFBgACAAQS
Az4EYQoPCggGAAIABJsIABIDPgRhCg0KBQYAAgAEEgQ/BEIGCg8KBwYAAgAEmQgSBD8EQgYK
3wMKBAYAAgESBE4CWAMa0AMgVXBkYXRlIGFuIGV4aXN0aW5nIE9TIHBvbGljeSBhc3NpZ25t
ZW50LgoKIFRoaXMgbWV0aG9kIGNyZWF0ZXMgYSBuZXcgcmV2aXNpb24gb2YgdGhlIE9TIHBv
bGljeSBhc3NpZ25tZW50LgoKIFRoaXMgbWV0aG9kIHJldHVybnMgYSBsb25nIHJ1bm5pbmcg
b3BlcmF0aW9uIChMUk8pIHRoYXQgY29udGFpbnMgdGhlCiByb2xsb3V0IGRldGFpbHMuIFRo
ZSByb2xsb3V0IGNhbiBiZSBjYW5jZWxsZWQgYnkgY2FuY2VsbGluZyB0aGUgTFJPLgoKIEZv
ciBtb3JlIGluZm9ybWF0aW9uLCBzZWUgW01ldGhvZDoKIHByb2plY3RzLmxvY2F0aW9ucy5v
c1BvbGljeUFzc2lnbm1lbnRzLm9wZXJhdGlvbnMuY2FuY2VsXShodHRwczovL2Nsb3VkLmdv
b2dsZS5jb20vY29tcHV0ZS9kb2NzL29zY29uZmlnL3Jlc3QvdjFhbHBoYS9wcm9qZWN0cy5s
b2NhdGlvbnMub3NQb2xpY3lBc3NpZ25tZW50cy5vcGVyYXRpb25zL2NhbmNlbCkuCgoMCgUG
AAIBARIDTgYeCgwKBQYAAgECEgNOHz4KDAoFBgACAQMSA05JZQoNCgUGAAIBBBIETwRSBgoR
CgkGAAIBBLDKvCISBE8EUgYKDAoFBgACAQQSA1METgoPCggGAAIBBJsIABIDUwROCg0KBQYA
AgEEEgRUBFcGCg8KBwYAAgEEmQgSBFQEVwYK4QEKBAYAAgISBF8CZAMa0gEgUmV0cmlldmUg
YW4gZXhpc3RpbmcgT1MgcG9saWN5IGFzc2lnbm1lbnQuCgogVGhpcyBtZXRob2QgYWx3YXlz
IHJldHVybnMgdGhlIGxhdGVzdCByZXZpc2lvbi4gSW4gb3JkZXIgdG8gcmV0cmlldmUgYQog
cHJldmlvdXMgcmV2aXNpb24gb2YgdGhlIGFzc2lnbm1lbnQsIGFsc28gcHJvdmlkZSB0aGUg
cmV2aXNpb24gSUQgaW4gdGhlCiBgbmFtZWAgcGFyYW1ldGVyLgoKDAoFBgACAgESA18GGwoM
CgUGAAICAhIDXxw4CgwKBQYAAgIDEgNfQ1UKDQoFBgACAgQSBGAEYgYKEQoJBgACAgSwyrwi
EgRgBGIGCgwKBQYAAgIEEgNjBDIKDwoIBgACAgSbCAASA2MEMgqLAQoEBgACAxIEaQJuAxp9
IExpc3QgdGhlIE9TIHBvbGljeSBhc3NpZ25tZW50cyB1bmRlciB0aGUgcGFyZW50IHJlc291
cmNlLgoKIEZvciBlYWNoIE9TIHBvbGljeSBhc3NpZ25tZW50LCB0aGUgbGF0ZXN0IHJldmlz
aW9uIGlzIHJldHVybmVkLgoKDAoFBgACAwESA2kGHQoMCgUGAAIDAhIDaR48CgwKBQYAAgMD
EgNpR2YKDQoFBgACAwQSBGoEbAYKEQoJBgACAwSwyrwiEgRqBGwGCgwKBQYAAgMEEgNtBDQK
DwoIBgACAwSbCAASA20ENApZCgQGAAIEEgRxAnYDGksgTGlzdCB0aGUgT1MgcG9saWN5IGFz
c2lnbm1lbnQgcmV2aXNpb25zIGZvciBhIGdpdmVuIE9TIHBvbGljeSBhc3NpZ25tZW50LgoK
DAoFBgACBAESA3EGJQoMCgUGAAIEAhIDcSZMCgwKBQYAAgQDEgNxV34KDQoFBgACBAQSBHIE
dAYKEQoJBgACBASwyrwiEgRyBHQGCgwKBQYAAgQEEgN1BDIKDwoIBgACBASbCAASA3UEMgrL
BAoEBgACBRIGhAECjQEDGroEIERlbGV0ZSB0aGUgT1MgcG9saWN5IGFzc2lnbm1lbnQuCgog
VGhpcyBtZXRob2QgY3JlYXRlcyBhIG5ldyByZXZpc2lvbiBvZiB0aGUgT1MgcG9saWN5IGFz
c2lnbm1lbnQuCgogVGhpcyBtZXRob2QgcmV0dXJucyBhIGxvbmcgcnVubmluZyBvcGVyYXRp
b24gKExSTykgdGhhdCBjb250YWlucyB0aGUKIHJvbGxvdXQgZGV0YWlscy4gVGhlIHJvbGxv
dXQgY2FuIGJlIGNhbmNlbGxlZCBieSBjYW5jZWxsaW5nIHRoZSBMUk8uCgogSWYgdGhlIExS
TyBjb21wbGV0ZXMgYW5kIGlzIG5vdCBjYW5jZWxsZWQsIGFsbCByZXZpc2lvbnMgYXNzb2Np
YXRlZCB3aXRoCiB0aGUgT1MgcG9saWN5IGFzc2lnbm1lbnQgYXJlIGRlbGV0ZWQuCgogRm9y
IG1vcmUgaW5mb3JtYXRpb24sIHNlZSBbTWV0aG9kOgogcHJvamVjdHMubG9jYXRpb25zLm9z
UG9saWN5QXNzaWdubWVudHMub3BlcmF0aW9ucy5jYW5jZWxdKGh0dHBzOi8vY2xvdWQuZ29v
Z2xlLmNvbS9jb21wdXRlL2RvY3Mvb3Njb25maWcvcmVzdC92MWFscGhhL3Byb2plY3RzLmxv
Y2F0aW9ucy5vc1BvbGljeUFzc2lnbm1lbnRzLm9wZXJhdGlvbnMvY2FuY2VsKS4KCg0KBQYA
AgUBEgSEAQYeCg0KBQYAAgUCEgSEAR8+Cg0KBQYAAgUDEgSEAUllCg8KBQYAAgUEEgaFAQSH
AQYKEwoJBgACBQSwyrwiEgaFAQSHAQYKDQoFBgACBQQSBIgBBDIKEAoIBgACBQSbCAASBIgB
BDIKDwoFBgACBQQSBokBBIwBBgoRCgcGAAIFBJkIEgaJAQSMAQYKYAoEBgACBhIGkQEClwED
GlAgR2V0IE9TIHBvbGljaWVzIGNvbXBsaWFuY2UgZGF0YSBmb3IgdGhlIHNwZWNpZmllZCBD
b21wdXRlIEVuZ2luZSBWTQogaW5zdGFuY2UuCgoNCgUGAAIGARIEkQEGJQoNCgUGAAIGAhIE
kQEmTAoNCgUGAAIGAxIEkQFXcwoNCgUGAAIGBBIEkgEEHQoOCgYGAAIGBCESBJIBBB0KDwoF
BgACBgQSBpMBBJUBBgoTCgkGAAIGBLDKvCISBpMBBJUBBgoNCgUGAAIGBBIElgEEMgoQCggG
AAIGBJsIABIElgEEMgpuCgQGAAIHEgabAQKhAQMaXiBMaXN0IE9TIHBvbGljaWVzIGNvbXBs
aWFuY2UgZGF0YSBmb3IgYWxsIENvbXB1dGUgRW5naW5lIFZNIGluc3RhbmNlcyBpbiB0aGUK
IHNwZWNpZmllZCB6b25lLgoKDQoFBgACBwESBJsBBicKDQoFBgACBwISBJsBKFAKDgoFBgAC
BwMSBZsBW4QBCg0KBQYAAgcEEgScAQQdCg4KBgYAAgcEIRIEnAEEHQoPCgUGAAIHBBIGnQEE
nwEGChMKCQYAAgcEsMq8IhIGnQEEnwEGCg0KBQYAAgcEEgSgAQQ0ChAKCAYAAgcEmwgAEgSg
AQQ0CmUKBAYAAggSBqUBAqoBAxpVIEdldCB0aGUgT1MgcG9saWN5IGFzc3NpZ25tZW50IHJl
cG9ydCBmb3IgdGhlIHNwZWNpZmllZCBDb21wdXRlIEVuZ2luZSBWTQogaW5zdGFuY2UuCgoN
CgUGAAIIARIEpQEGIQoNCgUGAAIIAhIEpQEiRAoNCgUGAAIIAxIEpQFPZwoPCgUGAAIIBBIG
pgEEqAEGChMKCQYAAggEsMq8IhIGpgEEqAEGCg0KBQYAAggEEgSpAQQyChAKCAYAAggEmwgA
EgSpAQQyCnAKBAYAAgkSBq4BArMBAxpgIExpc3QgT1MgcG9saWN5IGFzc3NpZ25tZW50IHJl
cG9ydHMgZm9yIGFsbCBDb21wdXRlIEVuZ2luZSBWTSBpbnN0YW5jZXMgaW4KIHRoZSBzcGVj
aWZpZWQgem9uZS4KCg0KBQYAAgkBEgSuAQYjCg0KBQYAAgkCEgSuASRICg0KBQYAAgkDEgSu
AVN4Cg8KBQYAAgkEEgavAQSxAQYKEwoJBgACCQSwyrwiEgavAQSxAQYKDQoFBgACCQQSBLIB
BDQKEAoIBgACCQSbCAASBLIBBDQKkQEKBAYAAgoSBrcBArwBAxqAASBHZXQgaW52ZW50b3J5
IGRhdGEgZm9yIHRoZSBzcGVjaWZpZWQgVk0gaW5zdGFuY2UuIElmIHRoZSBWTSBoYXMgbm8K
IGFzc29jaWF0ZWQgaW52ZW50b3J5LCB0aGUgbWVzc2FnZSBgTk9UX0ZPVU5EYCBpcyByZXR1
cm5lZC4KCg0KBQYAAgoBEgS3AQYSCg0KBQYAAgoCEgS3ARMmCg0KBQYAAgoDEgS3ATE6Cg8K
BQYAAgoEEga4AQS6AQYKEwoJBgACCgSwyrwiEga4AQS6AQYKDQoFBgACCgQSBLsBBDIKEAoI
BgACCgSbCAASBLsBBDIKUQoEBgACCxIGvwECxAEDGkEgTGlzdCBpbnZlbnRvcnkgZGF0YSBm
b3IgYWxsIFZNIGluc3RhbmNlcyBpbiB0aGUgc3BlY2lmaWVkIHpvbmUuCgoNCgUGAAILARIE
vwEGFQoNCgUGAAILAhIEvwEWLAoNCgUGAAILAxIEvwE3TgoPCgUGAAILBBIGwAEEwgEGChMK
CQYAAgsEsMq8IhIGwAEEwgEGCg0KBQYAAgsEEgTDAQQ0ChAKCAYAAgsEmwgAEgTDAQQ0Cp4B
CgQGAAIMEgbIAQLNAQMajQEgR2V0cyB0aGUgdnVsbmVyYWJpbGl0eSByZXBvcnQgZm9yIHRo
ZSBzcGVjaWZpZWQgVk0gaW5zdGFuY2UuIE9ubHkgVk1zIHdpdGgKIGludmVudG9yeSBkYXRh
IGhhdmUgdnVsbmVyYWJpbGl0eSByZXBvcnRzIGFzc29jaWF0ZWQgd2l0aCB0aGVtLgoKDQoF
BgACDAESBMgBBhwKDQoFBgACDAISBMgBHToKDQoFBgACDAMSBMgBRVgKDwoFBgACDAQSBskB
BMsBBgoTCgkGAAIMBLDKvCISBskBBMsBBgoNCgUGAAIMBBIEzAEEMgoQCggGAAIMBJsIABIE
zAEEMgpYCgQGAAINEgbQAQLVAQMaSCBMaXN0IHZ1bG5lcmFiaWxpdHkgcmVwb3J0cyBmb3Ig
YWxsIFZNIGluc3RhbmNlcyBpbiB0aGUgc3BlY2lmaWVkIHpvbmUuCgoNCgUGAAINARIE0AEG
HgoNCgUGAAINAhIE0AEfPgoNCgUGAAINAxIE0AFJaQoPCgUGAAINBBIG0QEE0wEGChMKCQYA
Ag0EsMq8IhIG0QEE0wEGCg0KBQYAAg0EEgTUAQQ0ChAKCAYAAg0EmwgAEgTUAQQ0YgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Osconfig::V1alpha::OsconfigZonalService::OsConfigZonalServiceClient ===
package Google::Cloud::Osconfig::V1alpha::OsconfigZonalService::OsConfigZonalServiceClient;

=pod

=head2 Service Client: Google::Cloud::Osconfig::V1alpha::OsconfigZonalService::OsConfigZonalServiceClient

Client stub representing the remote C<OsConfigZonalService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<osconfig.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'osconfig.googleapis.com:443' );

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

sub create_o_s_policy_assignment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::CreateOSPolicyAssignmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1alpha.OsConfigZonalService',
        method         => 'CreateOSPolicyAssignment',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_o_s_policy_assignment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::UpdateOSPolicyAssignmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1alpha.OsConfigZonalService',
        method         => 'UpdateOSPolicyAssignment',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_o_s_policy_assignment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::GetOSPolicyAssignmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1alpha.OsConfigZonalService',
        method         => 'GetOSPolicyAssignment',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::OSPolicyAssignment',
    });
}

sub list_o_s_policy_assignments {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::ListOSPolicyAssignmentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1alpha.OsConfigZonalService',
        method         => 'ListOSPolicyAssignments',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::ListOSPolicyAssignmentsResponse',
    });
}

sub list_o_s_policy_assignment_revisions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::ListOSPolicyAssignmentRevisionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1alpha.OsConfigZonalService',
        method         => 'ListOSPolicyAssignmentRevisions',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::ListOSPolicyAssignmentRevisionsResponse',
    });
}

sub delete_o_s_policy_assignment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1alpha::OsPolicyAssignments::DeleteOSPolicyAssignmentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1alpha.OsConfigZonalService',
        method         => 'DeleteOSPolicyAssignment',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_instance_o_s_policies_compliance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::GetInstanceOSPoliciesComplianceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1alpha.OsConfigZonalService',
        method         => 'GetInstanceOSPoliciesCompliance',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::InstanceOSPoliciesCompliance',
    });
}

sub list_instance_o_s_policies_compliances {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::ListInstanceOSPoliciesCompliancesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1alpha.OsConfigZonalService',
        method         => 'ListInstanceOSPoliciesCompliances',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1alpha::InstanceOsPoliciesCompliance::ListInstanceOSPoliciesCompliancesResponse',
    });
}

sub get_o_s_policy_assignment_report {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::GetOSPolicyAssignmentReportRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1alpha.OsConfigZonalService',
        method         => 'GetOSPolicyAssignmentReport',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::OSPolicyAssignmentReport',
    });
}

sub list_o_s_policy_assignment_reports {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::ListOSPolicyAssignmentReportsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1alpha.OsConfigZonalService',
        method         => 'ListOSPolicyAssignmentReports',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1alpha::OsPolicyAssignmentReports::ListOSPolicyAssignmentReportsResponse',
    });
}

sub get_inventory {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1alpha::Inventory::GetInventoryRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1alpha.OsConfigZonalService',
        method         => 'GetInventory',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1alpha::Inventory::Inventory',
    });
}

sub list_inventories {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1alpha::Inventory::ListInventoriesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1alpha.OsConfigZonalService',
        method         => 'ListInventories',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1alpha::Inventory::ListInventoriesResponse',
    });
}

sub get_vulnerability_report {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1alpha::Vulnerability::GetVulnerabilityReportRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1alpha.OsConfigZonalService',
        method         => 'GetVulnerabilityReport',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1alpha::Vulnerability::VulnerabilityReport',
    });
}

sub list_vulnerability_reports {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Osconfig::V1alpha::Vulnerability::ListVulnerabilityReportsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.osconfig.v1alpha.OsConfigZonalService',
        method         => 'ListVulnerabilityReports',
        request        => $req,
        response_class => 'Google::Cloud::Osconfig::V1alpha::Vulnerability::ListVulnerabilityReportsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Osconfig::V1alpha::OsconfigZonalService - Compiled Protocol Buffers messages for google/cloud/osconfig/v1alpha/osconfig_zonal_service.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/osconfig/v1alpha/osconfig_zonal_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Osconfig::V1alpha::OsconfigZonalService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
