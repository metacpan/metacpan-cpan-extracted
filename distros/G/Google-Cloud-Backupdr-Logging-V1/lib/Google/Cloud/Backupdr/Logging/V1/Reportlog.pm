package Google::Cloud::Backupdr::Logging::V1::Reportlog;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvYmFja3VwZHIvbG9nZ2luZy92MS9yZXBvcnRsb2cucHJvdG8SIGdv
b2dsZS5jbG91ZC5iYWNrdXBkci5sb2dnaW5nLnYxIq0NChpCYWNrdXBSZWNvdmVyeUpvYlJl
cG9ydExvZxIZCghqb2JfbmFtZRgBIAEoCVIHam9iTmFtZRIhCgxqb2JfY2F0ZWdvcnkYAiAB
KAlSC2pvYkNhdGVnb3J5EhkKCGpvYl90eXBlGAMgASgJUgdqb2JUeXBlEh0KCmxvZ19iYWNr
dXAYBCABKAlSCWxvZ0JhY2t1cBIdCgpqb2Jfc3RhdHVzGAUgASgJUglqb2JTdGF0dXMSIwoN
cmVzb3VyY2VfbmFtZRgGIAEoCVIMcmVzb3VyY2VOYW1lEiMKDXJlc291cmNlX3R5cGUYByAB
KAlSDHJlc291cmNlVHlwZRIdCgplcnJvcl9jb2RlGAggASgFUgllcnJvckNvZGUSIwoNZXJy
b3JfbWVzc2FnZRgJIAEoCVIMZXJyb3JNZXNzYWdlEkEKHWpvYl9pbml0aWF0aW9uX2ZhaWx1
cmVfcmVhc29uGAogASgJUhpqb2JJbml0aWF0aW9uRmFpbHVyZVJlYXNvbhIkCg5qb2Jfc3Rh
cnRfdGltZRgLIAEoCVIMam9iU3RhcnRUaW1lEiAKDGpvYl9lbmRfdGltZRgMIAEoCVIKam9i
RW5kVGltZRImCg9qb2JfcXVldWVkX3RpbWUYDSABKAlSDWpvYlF1ZXVlZFRpbWUSMQoVam9i
X2R1cmF0aW9uX2luX2hvdXJzGA4gASgBUhJqb2JEdXJhdGlvbkluSG91cnMSGgoIaG9zdG5h
bWUYDyABKAlSCGhvc3RuYW1lEiUKDmFwcGxpYW5jZV9uYW1lGBAgASgJUg1hcHBsaWFuY2VO
YW1lEjUKF2JhY2t1cF9ydWxlX3BvbGljeV9uYW1lGBEgASgJUhRiYWNrdXBSdWxlUG9saWN5
TmFtZRI9ChtiYWNrdXBfcGxhbl9wb2xpY3lfdGVtcGxhdGUYEiABKAlSGGJhY2t1cFBsYW5Q
b2xpY3lUZW1wbGF0ZRIfCgtiYWNrdXBfdHlwZRgTIAEoCVIKYmFja3VwVHlwZRIlCg5yZWNv
dmVyeV9wb2ludBgUIAEoCVINcmVjb3ZlcnlQb2ludBItChJiYWNrdXBfY29uc2lzdGVuY3kY
FSABKAlSEWJhY2t1cENvbnNpc3RlbmN5EigKEHRhcmdldF9ob3N0X25hbWUYFiABKAlSDnRh
cmdldEhvc3ROYW1lEjIKFXRhcmdldF9hcHBsaWFuY2VfbmFtZRgXIAEoCVITdGFyZ2V0QXBw
bGlhbmNlTmFtZRIoChB0YXJnZXRfcG9vbF9uYW1lGBggASgJUg50YXJnZXRQb29sTmFtZRI4
ChlyZXNvdXJjZV9kYXRhX3NpemVfaW5fZ2liGBkgASgBUhVyZXNvdXJjZURhdGFTaXplSW5H
aWISKwoSZGF0YV9jb3BpZWRfaW5fZ2liGBogASgBUg9kYXRhQ29waWVkSW5HaWISTQokb252
YXVsdF9wb29sX3N0b3JhZ2VfY29uc3VtZWRfaW5fZ2liGBsgASgBUh9vbnZhdWx0UG9vbFN0
b3JhZ2VDb25zdW1lZEluR2liEi0KE3ByZV9jb21wcmVzc19pbl9naWIYHCABKAFSEHByZUNv
bXByZXNzSW5HaWISKwoRY29tcHJlc3Npb25fcmF0aW8YHSABKAFSEGNvbXByZXNzaW9uUmF0
aW8SKAoQZGF0YV9jaGFuZ2VfcmF0ZRgeIAEoAVIOZGF0YUNoYW5nZVJhdGUSOAoZc25hcHNo
b3RfZGlza19zaXplX2luX2dpYhgfIAEoAVIVc25hcHNob3REaXNrU2l6ZUluR2liEi0KE2Rh
dGFfd3JpdHRlbl9pbl9naWIYICABKAFSEGRhdGFXcml0dGVuSW5HaWISJwoQZGF0YV9zZW50
X2luX2dpYhghIAEoAVINZGF0YVNlbnRJbkdpYhIVCgZqb2JfaWQYIiABKAlSBWpvYklkEhcK
B2hvc3RfaWQYIyABKAlSBmhvc3RJZBIxChViYWNrdXBfcnVsZV9wb2xpY3lfaWQYJCABKAlS
EmJhY2t1cFJ1bGVQb2xpY3lJZBIfCgtyZXNvdXJjZV9pZBglIAEoCVIKcmVzb3VyY2VJZBIk
Cg50YXJnZXRfcG9vbF9pZBgmIAEoCVIMdGFyZ2V0UG9vbElkEiQKDnRhcmdldF9ob3N0X2lk
GCcgASgJUgx0YXJnZXRIb3N0SWQSLgoTdGFyZ2V0X2FwcGxpYW5jZV9pZBgoIAEoCVIRdGFy
Z2V0QXBwbGlhbmNlSWQi0QIKHFVucHJvdGVjdGVkUmVzb3VyY2VSZXBvcnRMb2cSGwoJaG9z
dF9uYW1lGAEgASgJUghob3N0TmFtZRIjCg1yZXNvdXJjZV9uYW1lGAIgASgJUgxyZXNvdXJj
ZU5hbWUSIwoNcmVzb3VyY2VfdHlwZRgDIAEoCVIMcmVzb3VyY2VUeXBlEiMKDWluc3RhbmNl
X25hbWUYBCABKAlSDGluc3RhbmNlTmFtZRIjCg1kaXNjb3ZlcmVkX29uGAUgASgJUgxkaXNj
b3ZlcmVkT24SIwoNZGlzY292ZXJlZF9ieRgGIAEoCVIMZGlzY292ZXJlZEJ5EiEKDGFwcGxp
YW5jZV9pZBgHIAEoCVILYXBwbGlhbmNlSWQSHwoLcmVzb3VyY2VfaWQYCCABKAlSCnJlc291
cmNlSWQSFwoHaG9zdF9pZBgJIAEoCVIGaG9zdElkIpQFCiBEYWlseVNjaGVkdWxlQ29tcGxp
YW5jZVJlcG9ydExvZxIjCg1yZXNvdXJjZV9uYW1lGAEgASgJUgxyZXNvdXJjZU5hbWUSIwoN
cmVzb3VyY2VfdHlwZRgCIAEoCVIMcmVzb3VyY2VUeXBlEjUKF2JhY2t1cF9ydWxlX3BvbGlj
eV9uYW1lGAMgASgJUhRiYWNrdXBSdWxlUG9saWN5TmFtZRI9ChtiYWNrdXBfcGxhbl9wb2xp
Y3lfdGVtcGxhdGUYBCABKAlSGGJhY2t1cFBsYW5Qb2xpY3lUZW1wbGF0ZRIbCglob3N0X25h
bWUYBSABKAlSCGhvc3ROYW1lEiUKDmFwcGxpYW5jZV9uYW1lGAYgASgJUg1hcHBsaWFuY2VO
YW1lEhIKBGRhdGUYByABKAlSBGRhdGUSNwoYYmFja3VwX3dpbmRvd19zdGFydF90aW1lGAgg
ASgJUhViYWNrdXBXaW5kb3dTdGFydFRpbWUSGQoIam9iX3R5cGUYCSABKAlSB2pvYlR5cGUS
FgoGc3RhdHVzGAogASgJUgZzdGF0dXMSGAoHY29tbWVudBgLIAEoCVIHY29tbWVudBIfCgty
ZXNvdXJjZV9pZBgMIAEoCVIKcmVzb3VyY2VJZBIXCgdob3N0X2lkGA0gASgJUgZob3N0SWQS
QgoeYmFja3VwX3BsYW5fcG9saWN5X3RlbXBsYXRlX2lkGA4gASgJUhpiYWNrdXBQbGFuUG9s
aWN5VGVtcGxhdGVJZBIxChViYWNrdXBfcnVsZV9wb2xpY3lfaWQYDyABKAlSEmJhY2t1cFJ1
bGVQb2xpY3lJZBIhCgxhcHBsaWFuY2VfaWQYECABKAlSC2FwcGxpYW5jZUlkIsgCCiFCYWNr
dXBTdG9yYWdlVXRpbGl6YXRpb25SZXBvcnRMb2cSJQoOYXBwbGlhbmNlX25hbWUYASABKAlS
DWFwcGxpYW5jZU5hbWUSIQoMc3RvcmFnZV90eXBlGAIgASgJUgtzdG9yYWdlVHlwZRIbCglw
b29sX25hbWUYAyABKAlSCHBvb2xOYW1lEjEKFXRvdGFsX2NhcGFjaXR5X2luX2dpYhgEIAEo
AVISdG90YWxDYXBhY2l0eUluR2liEi8KFHVzZWRfY2FwYWNpdHlfaW5fZ2liGAUgASgBUhF1
c2VkQ2FwYWNpdHlJbkdpYhI1ChZ1dGlsaXphdGlvbl9wZXJjZW50YWdlGAYgASgBUhV1dGls
aXphdGlvblBlcmNlbnRhZ2USIQoMYXBwbGlhbmNlX2lkGAcgASgJUgthcHBsaWFuY2VJZCKZ
BwoRUHJvdGVjdGVkUmVzb3VyY2USIwoNcmVzb3VyY2VfbmFtZRgBIAEoCVIMcmVzb3VyY2VO
YW1lEiMKDXJlc291cmNlX3R5cGUYAiABKAlSDHJlc291cmNlVHlwZRIfCgtyZXNvdXJjZV9p
ZBgDIAEoCVIKcmVzb3VyY2VJZBJBCh1iYWNrdXBfaW5jbHVzaW9uX29yX2V4Y2x1c2lvbhgE
IAEoCVIaYmFja3VwSW5jbHVzaW9uT3JFeGNsdXNpb24SFwoHaG9zdF9pZBgFIAEoCVIGaG9z
dElkEhsKCWhvc3RfbmFtZRgGIAEoCVIIaG9zdE5hbWUSQgoeYmFja3VwX3BsYW5fcG9saWN5
X3RlbXBsYXRlX2lkGAcgASgJUhpiYWNrdXBQbGFuUG9saWN5VGVtcGxhdGVJZBI9ChtiYWNr
dXBfcGxhbl9wb2xpY3lfdGVtcGxhdGUYCCABKAlSGGJhY2t1cFBsYW5Qb2xpY3lUZW1wbGF0
ZRIVCgZzbGFfaWQYCSABKAlSBXNsYUlkEjgKGGJhY2t1cF9wbGFuX3Jlc3RyaWN0aW9ucxgK
IAEoCVIWYmFja3VwUGxhblJlc3RyaWN0aW9ucxIhCgxwcm90ZWN0ZWRfb24YCyABKAlSC3By
b3RlY3RlZE9uEikKEHBvbGljeV9vdmVycmlkZXMYDCABKAlSD3BvbGljeU92ZXJyaWRlcxIp
ChBzb3VyY2VfYXBwbGlhbmNlGA0gASgJUg9zb3VyY2VBcHBsaWFuY2USLgoTc291cmNlX2Fw
cGxpYW5jZV9pZBgOIAEoCVIRc291cmNlQXBwbGlhbmNlSWQSMQoVcHJvdGVjdGVkX2RhdGFf
aW5fZ2liGA8gASgBUhJwcm90ZWN0ZWREYXRhSW5HaWISJAoOb252YXVsdF9pbl9naWIYECAB
KAFSDG9udmF1bHRJbkdpYhIlCg5hcHBsaWFuY2VfbmFtZRgRIAEoCVINYXBwbGlhbmNlTmFt
ZRIhCgxhcHBsaWFuY2VfaWQYEiABKAlSC2FwcGxpYW5jZUlkEikKEHJlbW90ZV9hcHBsaWFu
Y2UYEyABKAlSD3JlbW90ZUFwcGxpYW5jZRIuChNyZW1vdGVfYXBwbGlhbmNlX2lkGBQgASgJ
UhFyZW1vdGVBcHBsaWFuY2VJZBIlCg5yZWNvdmVyeV9wb2ludBgVIAEoCVINcmVjb3ZlcnlQ
b2ludCLGCAoMTW91bnRlZEltYWdlEjAKFHNvdXJjZV9yZXNvdXJjZV9uYW1lGAEgASgJUhJz
b3VyY2VSZXNvdXJjZU5hbWUSLAoSc291cmNlX3Jlc291cmNlX2lkGAIgASgJUhBzb3VyY2VS
ZXNvdXJjZUlkEiUKDmFwcGxpYW5jZV9uYW1lGAMgASgJUg1hcHBsaWFuY2VOYW1lEiEKDGFw
cGxpYW5jZV9pZBgEIAEoCVILYXBwbGlhbmNlSWQSLAoSbW91bnRlZF9pbWFnZV9uYW1lGAUg
ASgJUhBtb3VudGVkSW1hZ2VOYW1lEioKEXNvdXJjZV9pbWFnZV9uYW1lGAYgASgJUg9zb3Vy
Y2VJbWFnZU5hbWUSKgoRc291cmNlX2ltYWdlX3R5cGUYByABKAlSD3NvdXJjZUltYWdlVHlw
ZRIuChNyZWNvdmVyeV9wb2ludF9kYXRlGAggASgJUhFyZWNvdmVyeVBvaW50RGF0ZRImCg9s
YXN0X21vdW50X2RhdGUYCSABKAlSDWxhc3RNb3VudERhdGUSIwoNcmVzb3VyY2VfdHlwZRgK
IAEoCVIMcmVzb3VyY2VUeXBlEigKEHNvdXJjZV9ob3N0X25hbWUYCyABKAlSDnNvdXJjZUhv
c3ROYW1lEiQKDnNvdXJjZV9ob3N0X2lkGAwgASgJUgxzb3VyY2VIb3N0SWQSKgoRbW91bnRl
ZF9ob3N0X25hbWUYDSABKAlSD21vdW50ZWRIb3N0TmFtZRImCg9tb3VudGVkX2hvc3RfaWQY
DiABKAlSDW1vdW50ZWRIb3N0SWQSMgoVbW91bnRlZF9yZXNvdXJjZV9uYW1lGA8gASgJUhNt
b3VudGVkUmVzb3VyY2VOYW1lEj4KHHJlc291cmNlX3ZpcnR1YWxfc2l6ZV9pbl9naWIYECAB
KAFSGHJlc291cmNlVmlydHVhbFNpemVJbkdpYhI1ChdzdG9yYWdlX2NvbnN1bWVkX2luX2dp
YhgRIAEoAVIUc3RvcmFnZUNvbnN1bWVkSW5HaWISNAoWbW91bnRlZF9yZXNvdXJjZV9sYWJl
bBgSIAEoCVIUbW91bnRlZFJlc291cmNlTGFiZWwSKwoRcmVzdG9yYWJsZV9vYmplY3QYEyAB
KAlSEHJlc3RvcmFibGVPYmplY3QSOAoZbW91bnRlZF9pbWFnZV9hZ2VfaW5fZGF5cxgUIAEo
BVIVbW91bnRlZEltYWdlQWdlSW5EYXlzEhsKCXVzZXJfbmFtZRgVIAEoCVIIdXNlck5hbWUS
GwoJcmVhZF9tb2RlGBYgASgJUghyZWFkTW9kZRIvChRyZXNvdXJjZV9zaXplX2luX2dpYhgX
IAEoAVIRcmVzb3VyY2VTaXplSW5HaWISMgoVaW1hZ2VfZXhwaXJhdGlvbl9kYXRlGBggASgJ
UhNpbWFnZUV4cGlyYXRpb25EYXRlItgDChlDb25uZWN0b3JWZXJzaW9uUmVwb3J0TG9nEiUK
DmFwcGxpYW5jZV9uYW1lGAEgASgJUg1hcHBsaWFuY2VOYW1lEiEKDGFwcGxpYW5jZV9pZBgC
IAEoCVILYXBwbGlhbmNlSWQSGwoJaG9zdF9uYW1lGAMgASgJUghob3N0TmFtZRIXCgdob3N0
X2lkGAQgASgJUgZob3N0SWQSIAoMaG9zdF9vc190eXBlGAUgASgJUgpob3N0T3NUeXBlEiYK
D2hvc3RfaXBfYWRkcmVzcxgGIAEoCVINaG9zdElwQWRkcmVzcxIrChFkYl9hdXRoZW50aWNh
dGlvbhgHIAEoCVIQZGJBdXRoZW50aWNhdGlvbhIrChFpbnN0YWxsZWRfdmVyc2lvbhgIIAEo
CVIQaW5zdGFsbGVkVmVyc2lvbhIrChFhdmFpbGFibGVfdmVyc2lvbhgJIAEoCVIQYXZhaWxh
YmxlVmVyc2lvbhIjCg12ZXJzaW9uX2NoZWNrGAogASgJUgx2ZXJzaW9uQ2hlY2sSJwoPZGlz
a19wcmVmZXJlbmNlGAsgASgJUg5kaXNrUHJlZmVyZW5jZRIcCgl0cmFuc3BvcnQYDCABKAlS
CXRyYW5zcG9ydELlAQokY29tLmdvb2dsZS5jbG91ZC5iYWNrdXBkci5sb2dnaW5nLnYxQg5S
ZXBvcnRMb2dQcm90b1ABWj5jbG91ZC5nb29nbGUuY29tL2dvL2JhY2t1cGRyL2xvZ2dpbmcv
YXBpdjEvbG9nZ2luZ3BiO2xvZ2dpbmdwYqoCIEdvb2dsZS5DbG91ZC5CYWNrdXBEUi5Mb2dn
aW5nLlYxygIgR29vZ2xlXENsb3VkXEJhY2t1cERSXExvZ2dpbmdcVjHqAiRHb29nbGU6OkNs
b3VkOjpCYWNrdXBEUjo6TG9nZ2luZzo6VjFKwHYKBxIFDgCYAwEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACkKCAoBCBIDEgBVCgkKAggLEgMSAFUKCAoB
CBIDEwAiCgkKAggKEgMTACIKCAoBCBIDFAAvCgkKAggIEgMUAC8KCAoBCBIDFQA9CgkKAggB
EgMVAD0KCAoBCBIDFgA9CgkKAgglEgMWAD0KCAoBCBIDFwA+CgkKAggpEgMXAD4KCAoBCBID
GAA9CgkKAggtEgMYAD0KWQoCBAASBRsAowEBGkwgVGhpcyBpcyBhIEJhY2t1cFJlY292ZXJ5
Sm9iUmVwb3J0TG9nIHB1Ymxpc2hlZCBhcyBwYXJ0IG9mIEdDQkRSIFJlcG9ydGluZy4KCgoK
AwQAARIDGwgiCk4KBAQAAgASAx0CFhpBIFRoZSBqb2JfbmFtZSBmaWVsZCBkaXNwbGF5cyB0
aGUgbmFtZSBvZiB0aGUgam9iIGJlaW5nIHJlcG9ydGVkLgoKDAoFBAACAAUSAx0CCAoMCgUE
AAIAARIDHQkRCgwKBQQAAgADEgMdFBUKaQoEBAACARIDIQIaGlwgVGhlIGpvYl9uYW1lIGZp
ZWxkIGRpc3BsYXlzIHRoZSBjYXRlZ29yeSBvZiB0aGUgam9iIHdoZXRoZXIgaXQgaXMgQmFj
a3VwIG9yCiBSZWNvdmVyeSBKb2IuCgoMCgUEAAIBBRIDIQIICgwKBQQAAgEBEgMhCRUKDAoF
BAACAQMSAyEYGQo/CgQEAAICEgMkAhYaMiBUaGUgam9iX3R5cGUgZmllbGQgZGlzcGxheXMg
dGhlIHR5cGUgb2YgdGhlIGpvYi4KCgwKBQQAAgIFEgMkAggKDAoFBAACAgESAyQJEQoMCgUE
AAICAxIDJBQVCmQKBAQAAgMSAygCGBpXIFRoZSBsb2dfYmFja3VwIGZpZWxkIGRpc3BsYXlz
IHdoZXRoZXIgdGhlIGJhY2t1cCB0YWtlbiBpcyBvbmx5IGZvciBsb2dzLCBEQgogb3IgYm90
aC4KCgwKBQQAAgMFEgMoAggKDAoFBAACAwESAygJEwoMCgUEAAIDAxIDKBYXCkMKBAQAAgQS
AysCGBo2IFRoZSBqb2Jfc3RhdHVzIGZpZWxkIGRpc3BsYXlzIHRoZSBzdGF0dXMgb2YgdGhl
IGpvYi4KCgwKBQQAAgQFEgMrAggKDAoFBAACBAESAysJEwoMCgUEAAIEAxIDKxYXCkkKBAQA
AgUSAy4CGxo8IFRoZSByZXNvdXJjZV9uYW1lIGZpZWxkIGRpc3BsYXlzIHRoZSBuYW1lIG9m
IHRoZSByZXNvdXJjZS4KCgwKBQQAAgUFEgMuAggKDAoFBAACBQESAy4JFgoMCgUEAAIFAxID
LhkaCkkKBAQAAgYSAzECGxo8IFRoZSByZXNvdXJjZV90eXBlIGZpZWxkIGRpc3BsYXlzIHRo
ZSB0eXBlIG9mIHRoZSByZXNvdXJjZS4KCgwKBQQAAgYFEgMxAggKDAoFBAACBgESAzEJFgoM
CgUEAAIGAxIDMRkaCjwKBAQAAgcSAzQCFxovIFRoZSBlcnJvcl9jb2RlIGZpZWxkIGRpc3Bs
YXlzIHRoZSBlcnJvciBjb2RlLgoKDAoFBAACBwUSAzQCBwoMCgUEAAIHARIDNAgSCgwKBQQA
AgcDEgM0FRYKYAoEBAACCBIDOAIbGlMgVGhlIGVycm9yX21lc3NhZ2UgZmllbGQgZGlzcGxh
eXMgdGhlIGVycm9yIG1lc3NhZ2UgaWYgdGhlIGpvYiBpcyBub3QKIHN1Y2Nlc3NmdWwuCgoM
CgUEAAIIBRIDOAIICgwKBQQAAggBEgM4CRYKDAoFBAACCAMSAzgZGgpwCgQEAAIJEgM8Aiwa
YyBUaGUgam9iX2luaXRpYXRpb25fZmFpbHVyZV9yZWFzb24gZmllbGQgZGlzcGxheXMgdGhl
IHJlYXNvbiBmb3IgZmFpbHVyZSwKIGlmIHRoZSBqb2Igd2FzIG5vdCBydW4uCgoMCgUEAAIJ
BRIDPAIICgwKBQQAAgkBEgM8CSYKDAoFBAACCQMSAzwpKwpUCgQEAAIKEgM/Ah0aRyBUaGUg
am9iX3N0YXJ0X3RpbWUgZmllbGQgZGlzcGxheXMgdGhlIHRpbWVzdGFtcCB3aGVuIHRoZSBq
b2Igc3RhcnRlZC4KCgwKBQQAAgoFEgM/AggKDAoFBAACCgESAz8JFwoMCgUEAAIKAxIDPxoc
ClAKBAQAAgsSA0ICGxpDIFRoZSBqb2JfZW5kX3RpbWUgZmllbGQgZGlzcGxheXMgdGhlIHRp
bWVzdGFtcCB3aGVuIHRoZSBqb2IgZW5kZWQuCgoMCgUEAAILBRIDQgIICgwKBQQAAgsBEgNC
CRUKDAoFBAACCwMSA0IYGgplCgQEAAIMEgNGAh4aWCBUaGUgam9iX3F1ZXVlZF90aW1lIGZp
ZWxkIGRpc3BsYXlzIHRoZSB0aW1lc3RhbXAgd2hlbiB0aGUgam9iIHdhcwogcXVldWVkIGZv
ciBydW5uaW5nLgoKDAoFBAACDAUSA0YCCAoMCgUEAAIMARIDRgkYCgwKBQQAAgwDEgNGGx0K
bgoEBAACDRIDSgIkGmEgVGhlIGpvYl9kdXJhdGlvbl9pbl9ob3VycyBmaWVsZCBkaXNwbGF5
cyB0aGUgZHVyYXRpb24gaW4gaG91cnMgd2hpY2ggdGhlCiBqb2IgdG9vayB0byBjb21wbGV0
ZS4KCgwKBQQAAg0FEgNKAggKDAoFBAACDQESA0oJHgoMCgUEAAINAxIDSiEjCkAKBAQAAg4S
A00CFxozIFRoZSBob3N0bmFtZSBmaWVsZCBkaXNwbGF5cyB0aGUgbmFtZSBvZiB0aGUgaG9z
dC4KCgwKBQQAAg4FEgNNAggKDAoFBAACDgESA00JEQoMCgUEAAIOAxIDTRQWClIKBAQAAg8S
A1ACHRpFIFRoZSBhcHBsaWFuY2VfbmFtZSBmaWVsZCBkaXNwbGF5cyB0aGUgbmFtZSBvZiB0
aGUgYmFja3VwIGFwcGxpYW5jZS4KCgwKBQQAAg8FEgNQAggKDAoFBAACDwESA1AJFwoMCgUE
AAIPAxIDUBocCm0KBAQAAhASA1QCJhpgIFRoZSBiYWNrdXBfcnVsZV9wb2xpY3lfbmFtZSBm
aWVsZCBkaXNwbGF5cyB0aGUgcG9saWN5IG5hbWUgd2hpY2ggaXMKIGFzc29jaWF0ZWQgd2l0
aCB0aGlzIGpvYi4KCgwKBQQAAhAFEgNUAggKDAoFBAACEAESA1QJIAoMCgUEAAIQAxIDVCMl
CnAKBAQAAhESA1gCKhpjIFRoZSBiYWNrdXBfcGxhbl9wb2xpY3lfdGVtcGxhdGUgZmllbGQg
ZGlzcGxheXMgdGhlIG5hbWUgb2YgdGhlIGJhY2t1cCBwbGFuCiBmb3IgdGhpcyBhcHBsaWNh
dGlvbi4KCgwKBQQAAhEFEgNYAggKDAoFBAACEQESA1gJJAoMCgUEAAIRAxIDWCcpCmcKBAQA
AhISA1wCGhpaIFRoZSBiYWNrdXBfdHlwZSBmaWVsZCBkaXNwbGF5cyB0aGUgdHlwZSBvZiBi
YWNrdXAgdGFrZW46IExvZywgSW5jcmVtZW50YWwKIG9yIEZ1bGwgQ29weS4KCgwKBQQAAhIF
EgNcAggKDAoFBAACEgESA1wJFAoMCgUEAAISAxIDXBcZClEKBAQAAhMSA18CHRpEIFRoZSBy
ZWNvdmVyeV9wb2ludCBmaWVsZCBkaXNwbGF5cyB0aGUgdGltZXN0YW1wIG9mIHJlY292ZXJ5
IHBvaW50LgoKDAoFBAACEwUSA18CCAoMCgUEAAITARIDXwkXCgwKBQQAAhMDEgNfGhwKdwoE
BAACFBIDYwIhGmogVGhlIGJhY2t1cF9jb25zaXN0ZW5jeSBmaWVsZCBkaXNwbGF5cyB3aGV0
aGVyIHRoZSBiYWNrdXAgaXMgY3Jhc2gKIGNvbnNpc3RlbnQgb3IgYXBwbGljYXRpb24gY29u
c2lzdGVudC4KCgwKBQQAAhQFEgNjAggKDAoFBAACFAESA2MJGwoMCgUEAAIUAxIDYx4gCkgK
BAQAAhUSA2YCHxo7IFRoZSB0YXJnZXRfaG9zdF9uYW1lIGZpZWxkIGRpc3BsYXlzIHRoZSB0
YXJnZXQgaG9zdCBuYW1lLgoKDAoFBAACFQUSA2YCCAoMCgUEAAIVARIDZgkZCgwKBQQAAhUD
EgNmHB4KUgoEBAACFhIDaQIkGkUgVGhlIHRhcmdldF9hcHBsaWFuY2VfbmFtZSBmaWVsZCBk
aXNwbGF5cyB0aGUgdGFyZ2V0IGFwcGxpYW5jZSBuYW1lLgoKDAoFBAACFgUSA2kCCAoMCgUE
AAIWARIDaQkeCgwKBQQAAhYDEgNpISMKRAoEBAACFxIDbAIfGjcgVGhlIHRhcmdldF9wb29s
X25hbWUgZmllbGQgZGlzcGxheXMgdGFyZ2V0IHBvb2wgbmFtZS4KCgwKBQQAAhcFEgNsAggK
DAoFBAACFwESA2wJGQoMCgUEAAIXAxIDbBweClYKBAQAAhgSA28CKBpJIFRoZSByZXNvdXJj
ZV9kYXRhX3NpemVfaW5fZ2liIGZpZWxkIGRpc3BsYXlzIHJlc291cmNlIGRhdGEgc2l6ZSBp
biBHaWIuCgoMCgUEAAIYBRIDbwIICgwKBQQAAhgBEgNvCSIKDAoFBAACGAMSA28lJwppCgQE
AAIZEgNzAiEaXCBUaGUgZGF0YV9jb3BpZWRfaW5fZ2liIGZpZWxkIGRpc3BsYXlzIHRoZSBh
bW91bnQgb2YgdGhlIGRhdGEgY29waWVkCiBkdXJpbmcgYmFja3VwIGluIEdpYi4KCgwKBQQA
AhkFEgNzAggKDAoFBAACGQESA3MJGwoMCgUEAAIZAxIDcx4gCnsKBAQAAhoSA3cCMxpuIFRo
ZSBvbnZhdWx0X3Bvb2xfc3RvcmFnZV9jb25zdW1lZF9pbl9naWIgZmllbGQgZGlzcGxheXMg
dGhlIGFtb3VudCBvZgogb252YXVsdCBwb29sIHN0b3JhZ2UgY29uc3VtZWQgaW4gR2liLgoK
DAoFBAACGgUSA3cCCAoMCgUEAAIaARIDdwktCgwKBQQAAhoDEgN3MDIKWQoEBAACGxIDegIi
GkwgVGhlIHByZV9jb21wcmVzc19pbl9naWIgZmllbGQgZGlzcGxheXMgdGhlIHNpemUgYmVm
b3JlIGNvbXByZXNzaW9uIGluIEdpYi4KCgwKBQQAAhsFEgN6AggKDAoFBAACGwESA3oJHAoM
CgUEAAIbAxIDeh8hCnAKBAQAAhwSA34CIBpjIFRoZSBjb21wcmVzc2lvbl9yYXRpbyBmaWVs
ZCBkaXNwbGF5cyB0aGUgcmF0aW8gb2YgcG9zdCBjb21wcmVzc2lvbiBzaXplIHRvCiBwcmUg
Y29tcHJlc3Npb24gc2l6ZS4KCgwKBQQAAhwFEgN+AggKDAoFBAACHAESA34JGgoMCgUEAAIc
AxIDfh0fCnUKBAQAAh0SBIIBAh8aZyBUaGUgZGF0YV9jaGFuZ2VfcmF0ZSBmaWVsZCBkaXNw
bGF5cyB0aGUgcGVyY2VudGFnZSBvZiBkYXRhIGNvcGllZCBkdXJpbmcKIGJhY2t1cCB0byBh
cHBsaWNhdGlvbiBzaXplLgoKDQoFBAACHQUSBIIBAggKDQoFBAACHQESBIIBCRkKDQoFBAAC
HQMSBIIBHB4KWwoEBAACHhIEhQECKBpNIFRoZSBzbmFwc2hvdF9kaXNrX3NpemVfaW5fZ2li
IGZpZWxkIGRpc3BsYXlzIHRoZSBzbmFwc2hvdCBkaXNrIHNpemUgaW4gR2liLgoKDQoFBAAC
HgUSBIUBAggKDQoFBAACHgESBIUBCSIKDQoFBAACHgMSBIUBJScKYQoEBAACHxIEiQECIhpT
IFRoZSBkYXRhX3dyaXR0ZW5faW5fZ2liIGZpZWxkIGRpc3BsYXlzIHRoZSBhbW91bnQgb2YK
IHJlbW90ZSBkYXRhIHdyaXR0ZW4gaW4gR2liLgoKDQoFBAACHwUSBIkBAggKDQoFBAACHwES
BIkBCRwKDQoFBAACHwMSBIkBHyEKXAoEBAACIBIEjQECHxpOIFRoZSBkYXRhX3NlbnRfaW5f
Z2liIGZpZWxkIGRpc3BsYXlzIHRoZSBhbW91bnQgb2YKIG5ldHdvcmsgZGF0YSBzZW50IGlu
IEdpYi4KCg0KBQQAAiAFEgSNAQIICg0KBQQAAiABEgSNAQkZCg0KBQQAAiADEgSNARweCksK
BAQAAiESBJABAhUaPSBUaGUgam9iX2lkIGZpZWxkIGRpc3BsYXlzIHRoZSBpZCBvZiB0aGUg
am9iIGJlaW5nIHJlcG9ydGVkLgoKDQoFBAACIQUSBJABAggKDQoFBAACIQESBJABCQ8KDQoF
BAACIQMSBJABEhQKNwoEBAACIhIEkwECFhopIFRoZSBob3N0X2lkIGZpZWxkIGRpc3BsYXlz
IHRoZSBob3N0IGlkLgoKDQoFBAACIgUSBJMBAggKDQoFBAACIgESBJMBCRAKDQoFBAACIgMS
BJMBExUKRwoEBAACIxIElgECJBo5IFRoZSBiYWNrdXBfcnVsZV9wb2xpY3lfaWQgZmllbGQg
ZGlzcGxheXMgdGhlIHBvbGljeSBpZC4KCg0KBQQAAiMFEgSWAQIICg0KBQQAAiMBEgSWAQke
Cg0KBQQAAiMDEgSWASEjCj8KBAQAAiQSBJkBAhoaMSBUaGUgcmVzb3VyY2VfaWQgZmllbGQg
ZGlzcGxheXMgdGhlIHJlc291cmNlIGlkLgoKDQoFBAACJAUSBJkBAggKDQoFBAACJAESBJkB
CRQKDQoFBAACJAMSBJkBFxkKRQoEBAACJRIEnAECHRo3IFRoZSB0YXJnZXRfcG9vbF9pZCBm
aWVsZCBkaXNwbGF5cyB0aGUgdGFyZ2V0IHBvb2wgaWQuCgoNCgUEAAIlBRIEnAECCAoNCgUE
AAIlARIEnAEJFwoNCgUEAAIlAxIEnAEaHApFCgQEAAImEgSfAQIdGjcgVGhlIHRhcmdldF9o
b3N0X2lkIGZpZWxkIGRpc3BsYXlzIHRoZSB0YXJnZXQgaG9zdCBpZC4KCg0KBQQAAiYFEgSf
AQIICg0KBQQAAiYBEgSfAQkXCg0KBQQAAiYDEgSfARocCk8KBAQAAicSBKIBAiIaQSBUaGUg
dGFyZ2V0X2FwcGxpYW5jZV9pZCBmaWVsZCBkaXNwbGF5cyB0aGUgdGFyZ2V0IGFwcGxpYW5j
ZSBpZC4KCg0KBQQAAicFEgSiAQIICg0KBQQAAicBEgSiAQkcCg0KBQQAAicDEgSiAR8hCl0K
AgQBEganAQDCAQEaTyBUaGlzIGlzIGEgVW5wcm90ZWN0ZWRSZXNvdXJjZUxvZ1JlcG9ydCBw
dWJsaXNoZWQgYXMgcGFydCBvZiBHQ0JEUgogUmVwb3J0aW5nLgoKCwoDBAEBEgSnAQgkClIK
BAQBAgASBKkBAhcaRCBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgaG9zdCB3aGVyZSB0aGUgYXBw
bGljYXRpb24vcmVzb3VyY2UgcmVzaWRlcy4KCg0KBQQBAgAFEgSpAQIICg0KBQQBAgABEgSp
AQkSCg0KBQQBAgADEgSpARUWCjsKBAQBAgESBKwBAhsaLSBSZXF1aXJlZC4gTmFtZSBvZiB0
aGUgYXBwbGljYXRpb24vcmVzb3VyY2UuCgoNCgUEAQIBBRIErAECCAoNCgUEAQIBARIErAEJ
FgoNCgUEAQIBAxIErAEZGgo7CgQEAQICEgSvAQIbGi0gUmVxdWlyZWQuIFR5cGUgb2YgdGhl
IGFwcGxpY2F0aW9uL3Jlc291cmNlLgoKDQoFBAECAgUSBK8BAggKDQoFBAECAgESBK8BCRYK
DQoFBAECAgMSBK8BGRoKTQoEBAECAxIEsgECGxo/IE9wdGlvbmFsLiBOYW1lIG9mIHRoZSBk
YXRhYmFzZSBpbnN0YW5jZSBmb3IgaW5zdGFuY2UgbWVtYmVycy4KCg0KBQQBAgMFEgSyAQII
Cg0KBQQBAgMBEgSyAQkWCg0KBQQBAgMDEgSyARkaCkcKBAQBAgQSBLUBAhsaOSBSZXF1aXJl
ZC4gRGF0ZSB3aGVuIHRoZSBBcHBsaWFuY2Ugd2FzIERpc2NvdmVyZWQgZmlyc3QuCgoNCgUE
AQIEBRIEtQECCAoNCgUEAQIEARIEtQEJFgoNCgUEAQIEAxIEtQEZGgpLCgQEAQIFEgS4AQIb
Gj0gUmVxdWlyZWQuIE5hbWUgb2YgdGhlIGFwcGxpYW5jZSBvbiB3aGljaCBpdCB3YXMgZGlz
Y292ZXJlZC4KCg0KBQQBAgUFEgS4AQIICg0KBQQBAgUBEgS4AQkWCg0KBQQBAgUDEgS4ARka
Ci0KBAQBAgYSBLsBAhoaHyBSZXF1aXJlZC4gSWQgb2YgdGhlIEFwcGxpYW5jZQoKDQoFBAEC
BgUSBLsBAggKDQoFBAECBgESBLsBCRUKDQoFBAECBgMSBLsBGBkKOAoEBAECBxIEvgECGRoq
IFJlcXVpcmVkLiBJZCBvZiB0aGUgYXBwbGljYXRpb24vcmVzb3VyY2UKCg0KBQQBAgcFEgS+
AQIICg0KBQQBAgcBEgS+AQkUCg0KBQQBAgcDEgS+ARcYClAKBAQBAggSBMEBAhUaQiBSZXF1
aXJlZC4gSWQgb2YgdGhlIEhvc3Qgd2hlcmUgdGhlIGFwcGxpY2F0aW9uL3Jlc291cmNlIHJl
c2lkZXMuCgoNCgUEAQIIBRIEwQECCAoNCgUEAQIIARIEwQEJEAoNCgUEAQIIAxIEwQETFAph
CgIEAhIGxgEA9gEBGlMgVGhpcyBpcyBhIERhaWx5U2NoZWR1bGVDb21wbGlhbmNlUmVwb3J0
TG9nIHB1Ymxpc2hlZCBhcyBwYXJ0IG9mIEdDQkRSCiBSZXBvcnRpbmcuCgoLCgMEAgESBMYB
CCgKLAoEBAICABIEyAECGxoeIFJlcXVpcmVkLiBSZXNvdXJjZS9BcHAgTmFtZS4KCg0KBQQC
AgAFEgTIAQIICg0KBQQCAgABEgTIAQkWCg0KBQQCAgADEgTIARkaCiwKBAQCAgESBMsBAhsa
HiBSZXF1aXJlZC4gUmVzb3VyY2UvQXBwIFR5cGUuCgoNCgUEAgIBBRIEywECCAoNCgUEAgIB
ARIEywEJFgoNCgUEAgIBAxIEywEZGgomCgQEAgICEgTOAQIlGhggUmVxdWlyZWQuIFBvbGlj
eSBOYW1lLgoKDQoFBAICAgUSBM4BAggKDQoFBAICAgESBM4BCSAKDQoFBAICAgMSBM4BIyQK
LwoEBAICAxIE0QECKRohIFJlcXVpcmVkLiBQb2xpY3kgVGVtcGxhdGUgTmFtZS4KCg0KBQQC
AgMFEgTRAQIICg0KBQQCAgMBEgTRAQkkCg0KBQQCAgMDEgTRAScoCkoKBAQCAgQSBNQBAhca
PCBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgaG9zdCB3aGVyZSB0aGUgYXBwL3Jlc291cmNlIHJl
c2lkZXMuCgoNCgUEAgIEBRIE1AECCAoNCgUEAgIEARIE1AEJEgoNCgUEAgIEAxIE1AEVFgop
CgQEAgIFEgTXAQIcGhsgUmVxdWlyZWQuIEFwcGxpYW5jZSBOYW1lLgoKDQoFBAICBQUSBNcB
AggKDQoFBAICBQESBNcBCRcKDQoFBAICBQMSBNcBGhsKRgoEBAICBhIE2gECEho4IFJlcXVp
cmVkLiBEYXRlIGZvciB3aGljaCBjb21wbGlhbmNlIGlzIGJlaW5nIHJlcG9ydGVkLgoKDQoF
BAICBgUSBNoBAggKDQoFBAICBgESBNoBCQ0KDQoFBAICBgMSBNoBEBEKMwoEBAICBxIE3QEC
JholIFJlcXVpcmVkLiBCYWNrdXAgV2luZG93IFN0YXJ0IHRpbWUuCgoNCgUEAgIHBRIE3QEC
CAoNCgUEAgIHARIE3QEJIQoNCgUEAgIHAxIE3QEkJQowCgQEAgIIEgTgAQIWGiIgUmVxdWly
ZWQuIEpvYlR5cGUgb2YgdGhlIHBvbGljeS4KCg0KBQQCAggFEgTgAQIICg0KBQQCAggBEgTg
AQkRCg0KBQQCAggDEgTgARQVCjsKBAQCAgkSBOMBAhUaLSBSZXF1aXJlZC4gQ29tcGxpYW5j
ZSBzdGF0dXMgZm9yIHRoZSBwb2xpY3kuCgoNCgUEAgIJBRIE4wECCAoNCgUEAgIJARIE4wEJ
DwoNCgUEAgIJAxIE4wESFAo8CgQEAgIKEgTmAQIWGi4gUmVxdWlyZWQuIERlc2NyaXB0aW9u
IGZvciB0aGUgc3RhdHVzIHJlYXNvbi4KCg0KBQQCAgoFEgTmAQIICg0KBQQCAgoBEgTmAQkQ
Cg0KBQQCAgoDEgTmARMVCioKBAQCAgsSBOkBAhoaHCBSZXF1aXJlZC4gUmVzb3VyY2UvQXBw
IElkLgoKDQoFBAICCwUSBOkBAggKDQoFBAICCwESBOkBCRQKDQoFBAICCwMSBOkBFxkKIgoE
BAICDBIE7AECFhoUIFJlcXVpcmVkLiBIb3N0IElkLgoKDQoFBAICDAUSBOwBAggKDQoFBAIC
DAESBOwBCRAKDQoFBAICDAMSBOwBExUKLAoEBAICDRIE7wECLRoeIFJlcXVpcmVkLiBQb2xp
Y3kgVGVtcGxhdGUgSWQKCg0KBQQCAg0FEgTvAQIICg0KBQQCAg0BEgTvAQknCg0KBQQCAg0D
EgTvASosCiQKBAQCAg4SBPIBAiQaFiBSZXF1aXJlZC4gUG9saWN5IElkLgoKDQoFBAICDgUS
BPIBAggKDQoFBAICDgESBPIBCR4KDQoFBAICDgMSBPIBISMKJwoEBAICDxIE9QECGxoZIFJl
cXVpcmVkLiBBcHBsaWFuY2UgSWQuCgoNCgUEAgIPBRIE9QECCAoNCgUEAgIPARIE9QEJFQoN
CgUEAgIPAxIE9QEYGgpiCgIEAxIG+gEAjwIBGlQgVGhpcyBpcyBhIEJhY2t1cFN0b3JhZ2VV
dGlsaXphdGlvblJlcG9ydExvZyBwdWJsaXNoZWQgYXMgcGFydCBvZiBHQ0JEUgogUmVwb3J0
aW5nLgoKCwoDBAMBEgT6AQgpCi0KBAQDAgASBPwBAhwaHyBPcHRpb25hbC4gVGhlIGFwcGxp
YW5jZSBuYW1lLgoKDQoFBAMCAAUSBPwBAggKDQoFBAMCAAESBPwBCRcKDQoFBAMCAAMSBPwB
GhsKNAoEBAMCARIE/wECGhomIFJlcXVpcmVkLiBUaGUgc3RvcmFnZSByZXNvdXJjZSB0eXBl
LgoKDQoFBAMCAQUSBP8BAggKDQoFBAMCAQESBP8BCRUKDQoFBAMCAQMSBP8BGBkKMAoEBAMC
AhIEggICFxoiIFJlcXVpcmVkLiBUaGUgc3RvcmFnZSBwb29sIG5hbWUuCgoNCgUEAwICBRIE
ggICCAoNCgUEAwICARIEggIJEgoNCgUEAwICAxIEggIVFgo8CgQEAwIDEgSFAgIjGi4gUmVx
dWlyZWQuIFRvdGFsIGNhcGFjaXR5IG9mIHRoZSBwb29sIGluIEdpQi4KCg0KBQQDAgMFEgSF
AgIICg0KBQQDAgMBEgSFAgkeCg0KBQQDAgMDEgSFAiEiCjsKBAQDAgQSBIgCAiIaLSBSZXF1
aXJlZC4gVXNlZCBjYXBhY2l0eSBvZiB0aGUgcG9vbCBpbiBHaUIuCgoNCgUEAwIEBRIEiAIC
CAoNCgUEAwIEARIEiAIJHQoNCgUEAwIEAxIEiAIgIQpDCgQEAwIFEgSLAgIkGjUgUmVxdWly
ZWQuIFV0aWxpemF0aW9uIHBlcmNlbnRhZ2Ugb2YgYSBzdG9yYWdlIHBvb2wuCgoNCgUEAwIF
BRIEiwICCAoNCgUEAwIFARIEiwIJHwoNCgUEAwIFAxIEiwIiIwonCgQEAwIGEgSOAgIaGhkg
UmVxdWlyZWQuIEFwcGxpYW5jZSBpZC4KCg0KBQQDAgYFEgSOAgIICg0KBQQDAgYBEgSOAgkV
Cg0KBQQDAgYDEgSOAhgZCjwKAgQEEgaSAgC9AgEaLiBIb2xkcyBpbmZvcm1hdGlvbiBmb3Ig
dGhlIFByb3RlY3RlZCBSZXNvdXJjZQoKCwoDBAQBEgSSAggZCigKBAQEAgASBJQCAhsaGiBS
ZXF1aXJlZC4gUmVzb3VyY2UgbmFtZS4KCg0KBQQEAgAFEgSUAgIICg0KBQQEAgABEgSUAgkW
Cg0KBQQEAgADEgSUAhkaCigKBAQEAgESBJYCAhsaGiBSZXF1aXJlZC4gUmVzb3VyY2UgVHlw
ZS4KCg0KBQQEAgEFEgSWAgIICg0KBQQEAgEBEgSWAgkWCg0KBQQEAgEDEgSWAhkaCiYKBAQE
AgISBJgCAhkaGCBSZXF1aXJlZC4gUmVzb3VyY2UgSUQuCgoNCgUEBAICBRIEmAICCAoNCgUE
BAICARIEmAIJFAoNCgUEBAICAxIEmAIXGAo1CgQEBAIDEgSaAgIrGicgT3B0aW9uYWwuIEJh
Y2t1cCBJbmNsdXNpb24vRXhjbHVzaW9uLgoKDQoFBAQCAwUSBJoCAggKDQoFBAQCAwESBJoC
CSYKDQoFBAQCAwMSBJoCKSoKIgoEBAQCBBIEnAICFRoUIFJlcXVpcmVkLiBIb3N0IElkLgoK
DQoFBAQCBAUSBJwCAggKDQoFBAQCBAESBJwCCRAKDQoFBAQCBAMSBJwCExQKJAoEBAQCBRIE
ngICFxoWIFJlcXVpcmVkLiBIb3N0IE5hbWUuCgoNCgUEBAIFBRIEngICCAoNCgUEBAIFARIE
ngIJEgoNCgUEBAIFAxIEngIVFgotCgQEBAIGEgSgAgIsGh8gUmVxdWlyZWQuIEJhY2t1cCBU
ZW1wbGF0ZSBJRC4KCg0KBQQEAgYFEgSgAgIICg0KBQQEAgYBEgSgAgknCg0KBQQEAgYDEgSg
AiorCioKBAQEAgcSBKICAikaHCBSZXF1aXJlZC4gQmFja3VwIFRlbXBsYXRlLgoKDQoFBAQC
BwUSBKICAggKDQoFBAQCBwESBKICCSQKDQoFBAQCBwMSBKICJygKIQoEBAQCCBIEpAICFBoT
IFJlcXVpcmVkLiBTbGEgSWQuCgoNCgUEBAIIBRIEpAICCAoNCgUEBAIIARIEpAIJDwoNCgUE
BAIIAxIEpAISEwozCgQEBAIJEgSmAgInGiUgUmVxdWlyZWQuIEJhY2t1cCBQbGFuIHJlc3Ry
aWN0aW9ucy4KCg0KBQQEAgkFEgSmAgIICg0KBQQEAgkBEgSmAgkhCg0KBQQEAgkDEgSmAiQm
CicKBAQEAgoSBKgCAhsaGSBSZXF1aXJlZC4gUHJvdGVjdGVkIE9uLgoKDQoFBAQCCgUSBKgC
AggKDQoFBAQCCgESBKgCCRUKDQoFBAQCCgMSBKgCGBoKKwoEBAQCCxIEqgICHxodIE9wdGlv
bmFsLiBQb2xpY3kgT3ZlcnJpZGVzLgoKDQoFBAQCCwUSBKoCAggKDQoFBAQCCwESBKoCCRkK
DQoFBAQCCwMSBKoCHB4KQQoEBAQCDBIErAICHxozIE9wdGlvbmFsLiBTb3VyY2UgQXBwbGlh
bmNlIGluIGNhc2Ugb2Ygc3RyZWFtc25hcC4KCg0KBQQEAgwFEgSsAgIICg0KBQQEAgwBEgSs
AgkZCg0KBQQEAgwDEgSsAhweCkQKBAQEAg0SBK4CAiIaNiBPcHRpb25hbC4gU291cmNlIEFw
cGxpYW5jZSBJZCBpbiBjYXNlIG9mIHN0cmVhbXNuYXAuCgoNCgUEBAINBRIErgICCAoNCgUE
BAINARIErgIJHAoNCgUEBAINAxIErgIfIQovCgQEBAIOEgSwAgIkGiEgUmVxdWlyZWQuIFBy
b3RlY3RlZCBEYXRhIChHaUIpLgoKDQoFBAQCDgUSBLACAggKDQoFBAQCDgESBLACCR4KDQoF
BAQCDgMSBLACISMKKQoEBAQCDxIEsgICHRobIE9wdGlvbmFsLiBPbnZhdWx0IChHaUIpIC4K
Cg0KBQQEAg8FEgSyAgIICg0KBQQEAg8BEgSyAgkXCg0KBQQEAg8DEgSyAhocCkYKBAQEAhAS
BLQCAh0aOCBPcHRpb25hbC4gT3JpZ2luYXRpbmcgQXBwbGlhbmNlIGluIGNhc2Ugb2Ygc3Ry
ZWFtc25hcC4KCg0KBQQEAhAFEgS0AgIICg0KBQQEAhABEgS0AgkXCg0KBQQEAhADEgS0Ahoc
CkkKBAQEAhESBLYCAhsaOyBPcHRpb25hbC4gT3JpZ2luYXRpbmcgQXBwbGlhbmNlIGlkIGlu
IGNhc2Ugb2Ygc3RyZWFtc25hcC4KCg0KBQQEAhEFEgS2AgIICg0KBQQEAhEBEgS2AgkVCg0K
BQQEAhEDEgS2AhgaCkEKBAQEAhISBLgCAh8aMyBPcHRpb25hbC4gUmVtb3RlIEFwcGxpYW5j
ZSBpbiBjYXNlIG9mIHN0cmVhbXNuYXAuCgoNCgUEBAISBRIEuAICCAoNCgUEBAISARIEuAIJ
GQoNCgUEBAISAxIEuAIcHgpECgQEBAITEgS6AgIiGjYgT3B0aW9uYWwuIFJlbW90ZSBBcHBs
aWFuY2UgaWQgaW4gY2FzZSBvZiBzdHJlYW1zbmFwLgoKDQoFBAQCEwUSBLoCAggKDQoFBAQC
EwESBLoCCRwKDQoFBAQCEwMSBLoCHyEKKQoEBAQCFBIEvAICHRobIE9wdGlvbmFsLiBSZWNv
dmVyeSBQb2ludC4KCg0KBQQEAhQFEgS8AgIICg0KBQQEAhQBEgS8AgkXCg0KBQQEAhQDEgS8
AhocCjwKAgQFEgbAAgDxAgEaLiBIb2xkcyBpbmZvcm1hdGlvbiBmb3IgdGhlIE1vdW50ZWQg
SW1hZ2VzIGxvZwoKCwoDBAUBEgTAAggUCi8KBAQFAgASBMICAiIaISBSZXF1aXJlZC4gU291
cmNlIFJlc291cmNlIG5hbWUuCgoNCgUEBQIABRIEwgICCAoNCgUEBQIAARIEwgIJHQoNCgUE
BQIAAxIEwgIgIQotCgQEBQIBEgTEAgIgGh8gUmVxdWlyZWQuIFNvdXJjZSBSZXNvdXJjZSBp
ZC4KCg0KBQQFAgEFEgTEAgIICg0KBQQFAgEBEgTEAgkbCg0KBQQFAgEDEgTEAh4fCicKBAQF
AgISBMYCAhwaGSBSZXF1aXJlZC4gQ2x1c3RlciBOYW1lLgoKDQoFBAUCAgUSBMYCAggKDQoF
BAUCAgESBMYCCRcKDQoFBAUCAgMSBMYCGhsKJQoEBAUCAxIEyAICGhoXIFJlcXVpcmVkLiBD
bHVzdGVyIElkLgoKDQoFBAUCAwUSBMgCAggKDQoFBAUCAwESBMgCCRUKDQoFBAUCAwMSBMgC
GBkKLQoEBAUCBBIEygICIBofIFJlcXVpcmVkLiBNb3VudGVkIEltYWdlIE5hbWUuCgoNCgUE
BQIEBRIEygICCAoNCgUEBQIEARIEygIJGwoNCgUEBQIEAxIEygIeHwosCgQEBQIFEgTMAgIf
Gh4gUmVxdWlyZWQuIFNvdXJjZSBJbWFnZSBOYW1lLgoKDQoFBAUCBQUSBMwCAggKDQoFBAUC
BQESBMwCCRoKDQoFBAUCBQMSBMwCHR4KKwoEBAUCBhIEzgICHxodIFJlcXVpcmVkLlNvdXJj
ZSBJbWFnZSBUeXBlLgoKDQoFBAUCBgUSBM4CAggKDQoFBAUCBgESBM4CCRoKDQoFBAUCBgMS
BM4CHR4KLgoEBAUCBxIE0AICIRogIFJlcXVpcmVkLiBSZWNvdmVyeSBwb2ludCBEYXRlLgoK
DQoFBAUCBwUSBNACAggKDQoFBAUCBwESBNACCRwKDQoFBAUCBwMSBNACHyAKKQoEBAUCCBIE
0gICHRobIFJlcXVpcmVkLiBMYXN0IE1vdW50IERhdGUKCg0KBQQFAggFEgTSAgIICg0KBQQF
AggBEgTSAgkYCg0KBQQFAggDEgTSAhscCigKBAQFAgkSBNQCAhwaGiBSZXF1aXJlZC4gUmVz
b3VyY2UgdHlwZS4KCg0KBQQFAgkFEgTUAgIICg0KBQQFAgkBEgTUAgkWCg0KBQQFAgkDEgTU
AhkbCisKBAQFAgoSBNYCAh8aHSBSZXF1aXJlZC4gU291cmNlIEhvc3QgTmFtZS4KCg0KBQQF
AgoFEgTWAgIICg0KBQQFAgoBEgTWAgkZCg0KBQQFAgoDEgTWAhweCikKBAQFAgsSBNgCAh0a
GyBSZXF1aXJlZC4gU291cmNlIEhvc3QgSWQuCgoNCgUEBQILBRIE2AICCAoNCgUEBQILARIE
2AIJFwoNCgUEBQILAxIE2AIaHAosCgQEBQIMEgTaAgIgGh4gUmVxdWlyZWQuIE1vdW50ZWQg
SG9zdCBOYW1lLgoKDQoFBAUCDAUSBNoCAggKDQoFBAUCDAESBNoCCRoKDQoFBAUCDAMSBNoC
HR8KKgoEBAUCDRIE3AICHhocIFJlcXVpcmVkLiBNb3VudGVkIEhvc3QgSWQuCgoNCgUEBQIN
BRIE3AICCAoNCgUEBQINARIE3AIJGAoNCgUEBQINAxIE3AIbHQowCgQEBQIOEgTeAgIkGiIg
UmVxdWlyZWQuIE1vdW50ZWQgUmVzb3VyY2UgTmFtZS4KCg0KBQQFAg4FEgTeAgIICg0KBQQF
Ag4BEgTeAgkeCg0KBQQFAg4DEgTeAiEjCjcKBAQFAg8SBOACAisaKSBSZXF1aXJlZC4gUmVz
b3VyY2UgVmlydHVhbCBzaXplKGluIEdpQikKCg0KBQQFAg8FEgTgAgIICg0KBQQFAg8BEgTg
AgklCg0KBQQFAg8DEgTgAigqCjMKBAQFAhASBOICAiYaJSBSZXF1aXJlZC4gU3RvcmFnZSBD
b25zdW1lZChpbiBHaUIpLgoKDQoFBAUCEAUSBOICAggKDQoFBAUCEAESBOICCSAKDQoFBAUC
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
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::Logging::V1::Reportlog::BackupRecoveryJobReportLog ===
    # Fields for BackupRecoveryJobReportLog
    # Field: job_name Type: 9 ()
    # Field: job_category Type: 9 ()
    # Field: job_type Type: 9 ()
    # Field: log_backup Type: 9 ()
    # Field: job_status Type: 9 ()
    # Field: resource_name Type: 9 ()
    # Field: resource_type Type: 9 ()
    # Field: error_code Type: 5 ()
    # Field: error_message Type: 9 ()
    # Field: job_initiation_failure_reason Type: 9 ()
    # Field: job_start_time Type: 9 ()
    # Field: job_end_time Type: 9 ()
    # Field: job_queued_time Type: 9 ()
    # Field: job_duration_in_hours Type: 1 ()
    # Field: hostname Type: 9 ()
    # Field: appliance_name Type: 9 ()
    # Field: backup_rule_policy_name Type: 9 ()
    # Field: backup_plan_policy_template Type: 9 ()
    # Field: backup_type Type: 9 ()
    # Field: recovery_point Type: 9 ()
    # Field: backup_consistency Type: 9 ()
    # Field: target_host_name Type: 9 ()
    # Field: target_appliance_name Type: 9 ()
    # Field: target_pool_name Type: 9 ()
    # Field: resource_data_size_in_gib Type: 1 ()
    # Field: data_copied_in_gib Type: 1 ()
    # Field: onvault_pool_storage_consumed_in_gib Type: 1 ()
    # Field: pre_compress_in_gib Type: 1 ()
    # Field: compression_ratio Type: 1 ()
    # Field: data_change_rate Type: 1 ()
    # Field: snapshot_disk_size_in_gib Type: 1 ()
    # Field: data_written_in_gib Type: 1 ()
    # Field: data_sent_in_gib Type: 1 ()
    # Field: job_id Type: 9 ()
    # Field: host_id Type: 9 ()
    # Field: backup_rule_policy_id Type: 9 ()
    # Field: resource_id Type: 9 ()
    # Field: target_pool_id Type: 9 ()
    # Field: target_host_id Type: 9 ()
    # Field: target_appliance_id Type: 9 ()

# === Message: Google::Cloud::Backupdr::Logging::V1::Reportlog::UnprotectedResourceReportLog ===
    # Fields for UnprotectedResourceReportLog
    # Field: host_name Type: 9 ()
    # Field: resource_name Type: 9 ()
    # Field: resource_type Type: 9 ()
    # Field: instance_name Type: 9 ()
    # Field: discovered_on Type: 9 ()
    # Field: discovered_by Type: 9 ()
    # Field: appliance_id Type: 9 ()
    # Field: resource_id Type: 9 ()
    # Field: host_id Type: 9 ()

# === Message: Google::Cloud::Backupdr::Logging::V1::Reportlog::DailyScheduleComplianceReportLog ===
    # Fields for DailyScheduleComplianceReportLog
    # Field: resource_name Type: 9 ()
    # Field: resource_type Type: 9 ()
    # Field: backup_rule_policy_name Type: 9 ()
    # Field: backup_plan_policy_template Type: 9 ()
    # Field: host_name Type: 9 ()
    # Field: appliance_name Type: 9 ()
    # Field: date Type: 9 ()
    # Field: backup_window_start_time Type: 9 ()
    # Field: job_type Type: 9 ()
    # Field: status Type: 9 ()
    # Field: comment Type: 9 ()
    # Field: resource_id Type: 9 ()
    # Field: host_id Type: 9 ()
    # Field: backup_plan_policy_template_id Type: 9 ()
    # Field: backup_rule_policy_id Type: 9 ()
    # Field: appliance_id Type: 9 ()

# === Message: Google::Cloud::Backupdr::Logging::V1::Reportlog::BackupStorageUtilizationReportLog ===
    # Fields for BackupStorageUtilizationReportLog
    # Field: appliance_name Type: 9 ()
    # Field: storage_type Type: 9 ()
    # Field: pool_name Type: 9 ()
    # Field: total_capacity_in_gib Type: 1 ()
    # Field: used_capacity_in_gib Type: 1 ()
    # Field: utilization_percentage Type: 1 ()
    # Field: appliance_id Type: 9 ()

# === Message: Google::Cloud::Backupdr::Logging::V1::Reportlog::ProtectedResource ===
    # Fields for ProtectedResource
    # Field: resource_name Type: 9 ()
    # Field: resource_type Type: 9 ()
    # Field: resource_id Type: 9 ()
    # Field: backup_inclusion_or_exclusion Type: 9 ()
    # Field: host_id Type: 9 ()
    # Field: host_name Type: 9 ()
    # Field: backup_plan_policy_template_id Type: 9 ()
    # Field: backup_plan_policy_template Type: 9 ()
    # Field: sla_id Type: 9 ()
    # Field: backup_plan_restrictions Type: 9 ()
    # Field: protected_on Type: 9 ()
    # Field: policy_overrides Type: 9 ()
    # Field: source_appliance Type: 9 ()
    # Field: source_appliance_id Type: 9 ()
    # Field: protected_data_in_gib Type: 1 ()
    # Field: onvault_in_gib Type: 1 ()
    # Field: appliance_name Type: 9 ()
    # Field: appliance_id Type: 9 ()
    # Field: remote_appliance Type: 9 ()
    # Field: remote_appliance_id Type: 9 ()
    # Field: recovery_point Type: 9 ()

# === Message: Google::Cloud::Backupdr::Logging::V1::Reportlog::MountedImage ===
    # Fields for MountedImage
    # Field: source_resource_name Type: 9 ()
    # Field: source_resource_id Type: 9 ()
    # Field: appliance_name Type: 9 ()
    # Field: appliance_id Type: 9 ()
    # Field: mounted_image_name Type: 9 ()
    # Field: source_image_name Type: 9 ()
    # Field: source_image_type Type: 9 ()
    # Field: recovery_point_date Type: 9 ()
    # Field: last_mount_date Type: 9 ()
    # Field: resource_type Type: 9 ()
    # Field: source_host_name Type: 9 ()
    # Field: source_host_id Type: 9 ()
    # Field: mounted_host_name Type: 9 ()
    # Field: mounted_host_id Type: 9 ()
    # Field: mounted_resource_name Type: 9 ()
    # Field: resource_virtual_size_in_gib Type: 1 ()
    # Field: storage_consumed_in_gib Type: 1 ()
    # Field: mounted_resource_label Type: 9 ()
    # Field: restorable_object Type: 9 ()
    # Field: mounted_image_age_in_days Type: 5 ()
    # Field: user_name Type: 9 ()
    # Field: read_mode Type: 9 ()
    # Field: resource_size_in_gib Type: 1 ()
    # Field: image_expiration_date Type: 9 ()

# === Message: Google::Cloud::Backupdr::Logging::V1::Reportlog::ConnectorVersionReportLog ===
    # Fields for ConnectorVersionReportLog
    # Field: appliance_name Type: 9 ()
    # Field: appliance_id Type: 9 ()
    # Field: host_name Type: 9 ()
    # Field: host_id Type: 9 ()
    # Field: host_os_type Type: 9 ()
    # Field: host_ip_address Type: 9 ()
    # Field: db_authentication Type: 9 ()
    # Field: installed_version Type: 9 ()
    # Field: available_version Type: 9 ()
    # Field: version_check Type: 9 ()
    # Field: disk_preference Type: 9 ()
    # Field: transport Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::Logging::V1::Reportlog - Compiled Protocol Buffers messages for google/cloud/backupdr/logging/v1/reportlog.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::Logging::V1::Reportlog;

    my $msg = Google::Cloud::Backupdr::Logging::V1::Reportlog::BackupRecoveryJobReportLog->new({
        job_name => $job_name,
        job_category => $job_category,
        job_type => $job_type,
        log_backup => $log_backup,
    });

    # Read or update a field
    my $val = $msg->job_name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::Logging::V1::Reportlog::BackupRecoveryJobReportLog->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/logging/v1/reportlog.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::Logging::V1::Reportlog::BackupRecoveryJobReportLog

This is a BackupRecoveryJobReportLog published as part of GCBDR Reporting.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->job_name() >> / C<< $msg->job_name($value) >>

Type: C<String>

The job_name field displays the name of the job being reported.

=item * C<< $msg->job_category() >> / C<< $msg->job_category($value) >>

Type: C<String>

The job_name field displays the category of the job whether it is Backup or
Recovery Job.

=item * C<< $msg->job_type() >> / C<< $msg->job_type($value) >>

Type: C<String>

The job_type field displays the type of the job.

=item * C<< $msg->log_backup() >> / C<< $msg->log_backup($value) >>

Type: C<String>

The log_backup field displays whether the backup taken is only for logs, DB
or both.

=item * C<< $msg->job_status() >> / C<< $msg->job_status($value) >>

Type: C<String>

The job_status field displays the status of the job.

=item * C<< $msg->resource_name() >> / C<< $msg->resource_name($value) >>

Type: C<String>

The resource_name field displays the name of the resource.

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<String>

The resource_type field displays the type of the resource.

=item * C<< $msg->error_code() >> / C<< $msg->error_code($value) >>

Type: C<Int32>

The error_code field displays the error code.

=item * C<< $msg->error_message() >> / C<< $msg->error_message($value) >>

Type: C<String>

The error_message field displays the error message if the job is not
successful.

=item * C<< $msg->job_initiation_failure_reason() >> / C<< $msg->job_initiation_failure_reason($value) >>

Type: C<String>

The job_initiation_failure_reason field displays the reason for failure,
if the job was not run.

=item * C<< $msg->job_start_time() >> / C<< $msg->job_start_time($value) >>

Type: C<String>

The job_start_time field displays the timestamp when the job started.

=item * C<< $msg->job_end_time() >> / C<< $msg->job_end_time($value) >>

Type: C<String>

The job_end_time field displays the timestamp when the job ended.

=item * C<< $msg->job_queued_time() >> / C<< $msg->job_queued_time($value) >>

Type: C<String>

The job_queued_time field displays the timestamp when the job was
queued for running.

=item * C<< $msg->job_duration_in_hours() >> / C<< $msg->job_duration_in_hours($value) >>

Type: C<Double>

The job_duration_in_hours field displays the duration in hours which the
job took to complete.

=item * C<< $msg->hostname() >> / C<< $msg->hostname($value) >>

Type: C<String>

The hostname field displays the name of the host.

=item * C<< $msg->appliance_name() >> / C<< $msg->appliance_name($value) >>

Type: C<String>

The appliance_name field displays the name of the backup appliance.

=item * C<< $msg->backup_rule_policy_name() >> / C<< $msg->backup_rule_policy_name($value) >>

Type: C<String>

The backup_rule_policy_name field displays the policy name which is
associated with this job.

=item * C<< $msg->backup_plan_policy_template() >> / C<< $msg->backup_plan_policy_template($value) >>

Type: C<String>

The backup_plan_policy_template field displays the name of the backup plan
for this application.

=item * C<< $msg->backup_type() >> / C<< $msg->backup_type($value) >>

Type: C<String>

The backup_type field displays the type of backup taken: Log, Incremental
or Full Copy.

=item * C<< $msg->recovery_point() >> / C<< $msg->recovery_point($value) >>

Type: C<String>

The recovery_point field displays the timestamp of recovery point.

=item * C<< $msg->backup_consistency() >> / C<< $msg->backup_consistency($value) >>

Type: C<String>

The backup_consistency field displays whether the backup is crash
consistent or application consistent.

=item * C<< $msg->target_host_name() >> / C<< $msg->target_host_name($value) >>

Type: C<String>

The target_host_name field displays the target host name.

=item * C<< $msg->target_appliance_name() >> / C<< $msg->target_appliance_name($value) >>

Type: C<String>

The target_appliance_name field displays the target appliance name.

=item * C<< $msg->target_pool_name() >> / C<< $msg->target_pool_name($value) >>

Type: C<String>

The target_pool_name field displays target pool name.

=item * C<< $msg->resource_data_size_in_gib() >> / C<< $msg->resource_data_size_in_gib($value) >>

Type: C<Double>

The resource_data_size_in_gib field displays resource data size in Gib.

=item * C<< $msg->data_copied_in_gib() >> / C<< $msg->data_copied_in_gib($value) >>

Type: C<Double>

The data_copied_in_gib field displays the amount of the data copied
during backup in Gib.

=item * C<< $msg->onvault_pool_storage_consumed_in_gib() >> / C<< $msg->onvault_pool_storage_consumed_in_gib($value) >>

Type: C<Double>

The onvault_pool_storage_consumed_in_gib field displays the amount of
onvault pool storage consumed in Gib.

=item * C<< $msg->pre_compress_in_gib() >> / C<< $msg->pre_compress_in_gib($value) >>

Type: C<Double>

The pre_compress_in_gib field displays the size before compression in Gib.

=item * C<< $msg->compression_ratio() >> / C<< $msg->compression_ratio($value) >>

Type: C<Double>

The compression_ratio field displays the ratio of post compression size to
pre compression size.

=item * C<< $msg->data_change_rate() >> / C<< $msg->data_change_rate($value) >>

Type: C<Double>

The data_change_rate field displays the percentage of data copied during
backup to application size.

=item * C<< $msg->snapshot_disk_size_in_gib() >> / C<< $msg->snapshot_disk_size_in_gib($value) >>

Type: C<Double>

The snapshot_disk_size_in_gib field displays the snapshot disk size in Gib.

=item * C<< $msg->data_written_in_gib() >> / C<< $msg->data_written_in_gib($value) >>

Type: C<Double>

The data_written_in_gib field displays the amount of
remote data written in Gib.

=item * C<< $msg->data_sent_in_gib() >> / C<< $msg->data_sent_in_gib($value) >>

Type: C<Double>

The data_sent_in_gib field displays the amount of
network data sent in Gib.

=item * C<< $msg->job_id() >> / C<< $msg->job_id($value) >>

Type: C<String>

The job_id field displays the id of the job being reported.

=item * C<< $msg->host_id() >> / C<< $msg->host_id($value) >>

Type: C<String>

The host_id field displays the host id.

=item * C<< $msg->backup_rule_policy_id() >> / C<< $msg->backup_rule_policy_id($value) >>

Type: C<String>

The backup_rule_policy_id field displays the policy id.

=item * C<< $msg->resource_id() >> / C<< $msg->resource_id($value) >>

Type: C<String>

The resource_id field displays the resource id.

=item * C<< $msg->target_pool_id() >> / C<< $msg->target_pool_id($value) >>

Type: C<String>

The target_pool_id field displays the target pool id.

=item * C<< $msg->target_host_id() >> / C<< $msg->target_host_id($value) >>

Type: C<String>

The target_host_id field displays the target host id.

=item * C<< $msg->target_appliance_id() >> / C<< $msg->target_appliance_id($value) >>

Type: C<String>

The target_appliance_id field displays the target appliance id.

=back

=head2 Google::Cloud::Backupdr::Logging::V1::Reportlog::UnprotectedResourceReportLog

This is a UnprotectedResourceLogReport published as part of GCBDR
Reporting.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->host_name() >> / C<< $msg->host_name($value) >>

Type: C<String>

Required. Name of the host where the application/resource resides.

=item * C<< $msg->resource_name() >> / C<< $msg->resource_name($value) >>

Type: C<String>

Required. Name of the application/resource.

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<String>

Required. Type of the application/resource.

=item * C<< $msg->instance_name() >> / C<< $msg->instance_name($value) >>

Type: C<String>

Optional. Name of the database instance for instance members.

=item * C<< $msg->discovered_on() >> / C<< $msg->discovered_on($value) >>

Type: C<String>

Required. Date when the Appliance was Discovered first.

=item * C<< $msg->discovered_by() >> / C<< $msg->discovered_by($value) >>

Type: C<String>

Required. Name of the appliance on which it was discovered.

=item * C<< $msg->appliance_id() >> / C<< $msg->appliance_id($value) >>

Type: C<String>

Required. Id of the Appliance

=item * C<< $msg->resource_id() >> / C<< $msg->resource_id($value) >>

Type: C<String>

Required. Id of the application/resource

=item * C<< $msg->host_id() >> / C<< $msg->host_id($value) >>

Type: C<String>

Required. Id of the Host where the application/resource resides.

=back

=head2 Google::Cloud::Backupdr::Logging::V1::Reportlog::DailyScheduleComplianceReportLog

This is a DailyScheduleComplianceReportLog published as part of GCBDR
Reporting.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resource_name() >> / C<< $msg->resource_name($value) >>

Type: C<String>

Required. Resource/App Name.

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<String>

Required. Resource/App Type.

=item * C<< $msg->backup_rule_policy_name() >> / C<< $msg->backup_rule_policy_name($value) >>

Type: C<String>

Required. Policy Name.

=item * C<< $msg->backup_plan_policy_template() >> / C<< $msg->backup_plan_policy_template($value) >>

Type: C<String>

Required. Policy Template Name.

=item * C<< $msg->host_name() >> / C<< $msg->host_name($value) >>

Type: C<String>

Required. Name of the host where the app/resource resides.

=item * C<< $msg->appliance_name() >> / C<< $msg->appliance_name($value) >>

Type: C<String>

Required. Appliance Name.

=item * C<< $msg->date() >> / C<< $msg->date($value) >>

Type: C<String>

Required. Date for which compliance is being reported.

=item * C<< $msg->backup_window_start_time() >> / C<< $msg->backup_window_start_time($value) >>

Type: C<String>

Required. Backup Window Start time.

=item * C<< $msg->job_type() >> / C<< $msg->job_type($value) >>

Type: C<String>

Required. JobType of the policy.

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<String>

Required. Compliance status for the policy.

=item * C<< $msg->comment() >> / C<< $msg->comment($value) >>

Type: C<String>

Required. Description for the status reason.

=item * C<< $msg->resource_id() >> / C<< $msg->resource_id($value) >>

Type: C<String>

Required. Resource/App Id.

=item * C<< $msg->host_id() >> / C<< $msg->host_id($value) >>

Type: C<String>

Required. Host Id.

=item * C<< $msg->backup_plan_policy_template_id() >> / C<< $msg->backup_plan_policy_template_id($value) >>

Type: C<String>

Required. Policy Template Id

=item * C<< $msg->backup_rule_policy_id() >> / C<< $msg->backup_rule_policy_id($value) >>

Type: C<String>

Required. Policy Id.

=item * C<< $msg->appliance_id() >> / C<< $msg->appliance_id($value) >>

Type: C<String>

Required. Appliance Id.

=back

=head2 Google::Cloud::Backupdr::Logging::V1::Reportlog::BackupStorageUtilizationReportLog

This is a BackupStorageUtilizationReportLog published as part of GCBDR
Reporting.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->appliance_name() >> / C<< $msg->appliance_name($value) >>

Type: C<String>

Optional. The appliance name.

=item * C<< $msg->storage_type() >> / C<< $msg->storage_type($value) >>

Type: C<String>

Required. The storage resource type.

=item * C<< $msg->pool_name() >> / C<< $msg->pool_name($value) >>

Type: C<String>

Required. The storage pool name.

=item * C<< $msg->total_capacity_in_gib() >> / C<< $msg->total_capacity_in_gib($value) >>

Type: C<Double>

Required. Total capacity of the pool in GiB.

=item * C<< $msg->used_capacity_in_gib() >> / C<< $msg->used_capacity_in_gib($value) >>

Type: C<Double>

Required. Used capacity of the pool in GiB.

=item * C<< $msg->utilization_percentage() >> / C<< $msg->utilization_percentage($value) >>

Type: C<Double>

Required. Utilization percentage of a storage pool.

=item * C<< $msg->appliance_id() >> / C<< $msg->appliance_id($value) >>

Type: C<String>

Required. Appliance id.

=back

=head2 Google::Cloud::Backupdr::Logging::V1::Reportlog::ProtectedResource

Holds information for the Protected Resource

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resource_name() >> / C<< $msg->resource_name($value) >>

Type: C<String>

Required. Resource name.

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<String>

Required. Resource Type.

=item * C<< $msg->resource_id() >> / C<< $msg->resource_id($value) >>

Type: C<String>

Required. Resource ID.

=item * C<< $msg->backup_inclusion_or_exclusion() >> / C<< $msg->backup_inclusion_or_exclusion($value) >>

Type: C<String>

Optional. Backup Inclusion/Exclusion.

=item * C<< $msg->host_id() >> / C<< $msg->host_id($value) >>

Type: C<String>

Required. Host Id.

=item * C<< $msg->host_name() >> / C<< $msg->host_name($value) >>

Type: C<String>

Required. Host Name.

=item * C<< $msg->backup_plan_policy_template_id() >> / C<< $msg->backup_plan_policy_template_id($value) >>

Type: C<String>

Required. Backup Template ID.

=item * C<< $msg->backup_plan_policy_template() >> / C<< $msg->backup_plan_policy_template($value) >>

Type: C<String>

Required. Backup Template.

=item * C<< $msg->sla_id() >> / C<< $msg->sla_id($value) >>

Type: C<String>

Required. Sla Id.

=item * C<< $msg->backup_plan_restrictions() >> / C<< $msg->backup_plan_restrictions($value) >>

Type: C<String>

Required. Backup Plan restrictions.

=item * C<< $msg->protected_on() >> / C<< $msg->protected_on($value) >>

Type: C<String>

Required. Protected On.

=item * C<< $msg->policy_overrides() >> / C<< $msg->policy_overrides($value) >>

Type: C<String>

Optional. Policy Overrides.

=item * C<< $msg->source_appliance() >> / C<< $msg->source_appliance($value) >>

Type: C<String>

Optional. Source Appliance in case of streamsnap.

=item * C<< $msg->source_appliance_id() >> / C<< $msg->source_appliance_id($value) >>

Type: C<String>

Optional. Source Appliance Id in case of streamsnap.

=item * C<< $msg->protected_data_in_gib() >> / C<< $msg->protected_data_in_gib($value) >>

Type: C<Double>

Required. Protected Data (GiB).

=item * C<< $msg->onvault_in_gib() >> / C<< $msg->onvault_in_gib($value) >>

Type: C<Double>

Optional. Onvault (GiB) .

=item * C<< $msg->appliance_name() >> / C<< $msg->appliance_name($value) >>

Type: C<String>

Optional. Originating Appliance in case of streamsnap.

=item * C<< $msg->appliance_id() >> / C<< $msg->appliance_id($value) >>

Type: C<String>

Optional. Originating Appliance id in case of streamsnap.

=item * C<< $msg->remote_appliance() >> / C<< $msg->remote_appliance($value) >>

Type: C<String>

Optional. Remote Appliance in case of streamsnap.

=item * C<< $msg->remote_appliance_id() >> / C<< $msg->remote_appliance_id($value) >>

Type: C<String>

Optional. Remote Appliance id in case of streamsnap.

=item * C<< $msg->recovery_point() >> / C<< $msg->recovery_point($value) >>

Type: C<String>

Optional. Recovery Point.

=back

=head2 Google::Cloud::Backupdr::Logging::V1::Reportlog::MountedImage

Holds information for the Mounted Images log

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->source_resource_name() >> / C<< $msg->source_resource_name($value) >>

Type: C<String>

Required. Source Resource name.

=item * C<< $msg->source_resource_id() >> / C<< $msg->source_resource_id($value) >>

Type: C<String>

Required. Source Resource id.

=item * C<< $msg->appliance_name() >> / C<< $msg->appliance_name($value) >>

Type: C<String>

Required. Cluster Name.

=item * C<< $msg->appliance_id() >> / C<< $msg->appliance_id($value) >>

Type: C<String>

Required. Cluster Id.

=item * C<< $msg->mounted_image_name() >> / C<< $msg->mounted_image_name($value) >>

Type: C<String>

Required. Mounted Image Name.

=item * C<< $msg->source_image_name() >> / C<< $msg->source_image_name($value) >>

Type: C<String>

Required. Source Image Name.

=item * C<< $msg->source_image_type() >> / C<< $msg->source_image_type($value) >>

Type: C<String>

Required.Source Image Type.

=item * C<< $msg->recovery_point_date() >> / C<< $msg->recovery_point_date($value) >>

Type: C<String>

Required. Recovery point Date.

=item * C<< $msg->last_mount_date() >> / C<< $msg->last_mount_date($value) >>

Type: C<String>

Required. Last Mount Date

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<String>

Required. Resource type.

=item * C<< $msg->source_host_name() >> / C<< $msg->source_host_name($value) >>

Type: C<String>

Required. Source Host Name.

=item * C<< $msg->source_host_id() >> / C<< $msg->source_host_id($value) >>

Type: C<String>

Required. Source Host Id.

=item * C<< $msg->mounted_host_name() >> / C<< $msg->mounted_host_name($value) >>

Type: C<String>

Required. Mounted Host Name.

=item * C<< $msg->mounted_host_id() >> / C<< $msg->mounted_host_id($value) >>

Type: C<String>

Required. Mounted Host Id.

=item * C<< $msg->mounted_resource_name() >> / C<< $msg->mounted_resource_name($value) >>

Type: C<String>

Required. Mounted Resource Name.

=item * C<< $msg->resource_virtual_size_in_gib() >> / C<< $msg->resource_virtual_size_in_gib($value) >>

Type: C<Double>

Required. Resource Virtual size(in GiB)

=item * C<< $msg->storage_consumed_in_gib() >> / C<< $msg->storage_consumed_in_gib($value) >>

Type: C<Double>

Required. Storage Consumed(in GiB).

=item * C<< $msg->mounted_resource_label() >> / C<< $msg->mounted_resource_label($value) >>

Type: C<String>

Optional. label.

=item * C<< $msg->restorable_object() >> / C<< $msg->restorable_object($value) >>

Type: C<String>

Optional. Restorable Objects.

=item * C<< $msg->mounted_image_age_in_days() >> / C<< $msg->mounted_image_age_in_days($value) >>

Type: C<Int32>

Required. Mounted Image Age(in days).

=item * C<< $msg->user_name() >> / C<< $msg->user_name($value) >>

Type: C<String>

Required. User Name.

=item * C<< $msg->read_mode() >> / C<< $msg->read_mode($value) >>

Type: C<String>

Optional. Read Mode.

=item * C<< $msg->resource_size_in_gib() >> / C<< $msg->resource_size_in_gib($value) >>

Type: C<Double>

Required. Resource size(in GiB)

=item * C<< $msg->image_expiration_date() >> / C<< $msg->image_expiration_date($value) >>

Type: C<String>

Optional. Image Expiration Date

=back

=head2 Google::Cloud::Backupdr::Logging::V1::Reportlog::ConnectorVersionReportLog

Holds information for the Connector Versions log

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->appliance_name() >> / C<< $msg->appliance_name($value) >>

Type: C<String>

Required. Appliance Name.

=item * C<< $msg->appliance_id() >> / C<< $msg->appliance_id($value) >>

Type: C<String>

Required. Appliance Id.

=item * C<< $msg->host_name() >> / C<< $msg->host_name($value) >>

Type: C<String>

Required. Host Name.

=item * C<< $msg->host_id() >> / C<< $msg->host_id($value) >>

Type: C<String>

Required. Host Id.

=item * C<< $msg->host_os_type() >> / C<< $msg->host_os_type($value) >>

Type: C<String>

Optional. Os Type.

=item * C<< $msg->host_ip_address() >> / C<< $msg->host_ip_address($value) >>

Type: C<String>

Required. Host Ip Address.

=item * C<< $msg->db_authentication() >> / C<< $msg->db_authentication($value) >>

Type: C<String>

Optional. Db Authentication.

=item * C<< $msg->installed_version() >> / C<< $msg->installed_version($value) >>

Type: C<String>

Required. Installed version.

=item * C<< $msg->available_version() >> / C<< $msg->available_version($value) >>

Type: C<String>

Optional. Available version.

=item * C<< $msg->version_check() >> / C<< $msg->version_check($value) >>

Type: C<String>

Required. Version Check.

=item * C<< $msg->disk_preference() >> / C<< $msg->disk_preference($value) >>

Type: C<String>

Required. Disk Preference.

=item * C<< $msg->transport() >> / C<< $msg->transport($value) >>

Type: C<String>

Required. Transport

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::Logging::V1::Reportlog::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
