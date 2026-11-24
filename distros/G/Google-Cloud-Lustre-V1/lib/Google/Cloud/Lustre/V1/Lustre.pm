package Google::Cloud::Lustre::V1::Lustre;

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
    eval { require Google::Cloud::Lustre::V1::DirectoryPolicy };
    eval { require Google::Cloud::Lustre::V1::Instance };
    eval { require Google::Cloud::Lustre::V1::Mirror };
    eval { require Google::Cloud::Lustre::V1::Transfer };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
CiNnb29nbGUvY2xvdWQvbHVzdHJlL3YxL2x1c3RyZS5wcm90bxIWZ29vZ2xlLmNsb3VkLmx1
c3RyZS52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGll
bnQucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aLWdvb2dsZS9jbG91ZC9sdXN0
cmUvdjEvZGlyZWN0b3J5X3BvbGljeS5wcm90bxolZ29vZ2xlL2Nsb3VkL2x1c3RyZS92MS9p
bnN0YW5jZS5wcm90bxojZ29vZ2xlL2Nsb3VkL2x1c3RyZS92MS9taXJyb3IucHJvdG8aJWdv
b2dsZS9jbG91ZC9sdXN0cmUvdjEvdHJhbnNmZXIucHJvdG8aI2dvb2dsZS9sb25ncnVubmlu
Zy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8yzxwKBkx1
c3RyZRKsAQoNTGlzdEluc3RhbmNlcxIsLmdvb2dsZS5jbG91ZC5sdXN0cmUudjEuTGlzdElu
c3RhbmNlc1JlcXVlc3QaLS5nb29nbGUuY2xvdWQubHVzdHJlLnYxLkxpc3RJbnN0YW5jZXNS
ZXNwb25zZSI+gtPkkwIvEi0vdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9p
bnN0YW5jZXPaQQZwYXJlbnQSmQEKC0dldEluc3RhbmNlEiouZ29vZ2xlLmNsb3VkLmx1c3Ry
ZS52MS5HZXRJbnN0YW5jZVJlcXVlc3QaIC5nb29nbGUuY2xvdWQubHVzdHJlLnYxLkluc3Rh
bmNlIjyC0+STAi8SLS92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2luc3RhbmNl
cy8qfdpBBG5hbWUS3QEKDkNyZWF0ZUluc3RhbmNlEi0uZ29vZ2xlLmNsb3VkLmx1c3RyZS52
MS5DcmVhdGVJbnN0YW5jZVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9u
In2C0+STAjkiLS92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L2luc3RhbmNl
czoIaW5zdGFuY2XaQRtwYXJlbnQsaW5zdGFuY2UsaW5zdGFuY2VfaWTKQR0KCEluc3RhbmNl
EhFPcGVyYXRpb25NZXRhZGF0YRLfAQoOVXBkYXRlSW5zdGFuY2USLS5nb29nbGUuY2xvdWQu
bHVzdHJlLnYxLlVwZGF0ZUluc3RhbmNlUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5P
cGVyYXRpb24if4LT5JMCQjI2L3YxL3tpbnN0YW5jZS5uYW1lPXByb2plY3RzLyovbG9jYXRp
b25zLyovaW5zdGFuY2VzLyp9OghpbnN0YW5jZdpBFGluc3RhbmNlLHVwZGF0ZV9tYXNrykEd
CghJbnN0YW5jZRIRT3BlcmF0aW9uTWV0YWRhdGESyQEKDkRlbGV0ZUluc3RhbmNlEi0uZ29v
Z2xlLmNsb3VkLmx1c3RyZS52MS5EZWxldGVJbnN0YW5jZVJlcXVlc3QaHS5nb29nbGUubG9u
Z3J1bm5pbmcuT3BlcmF0aW9uImmC0+STAi8qLS92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL2luc3RhbmNlcy8qfdpBBG5hbWXKQSoKFWdvb2dsZS5wcm90b2J1Zi5FbXB0eRIR
T3BlcmF0aW9uTWV0YWRhdGES7wEKFVJlc2NoZWR1bGVNYWludGVuYW5jZRI0Lmdvb2dsZS5j
bG91ZC5sdXN0cmUudjEuUmVzY2hlZHVsZU1haW50ZW5hbmNlUmVxdWVzdBodLmdvb2dsZS5s
b25ncnVubmluZy5PcGVyYXRpb24igAGC0+STAkgiQy92MS97bmFtZT1wcm9qZWN0cy8qL2xv
Y2F0aW9ucy8qL2luc3RhbmNlcy8qfTpyZXNjaGVkdWxlTWFpbnRlbmFuY2U6ASraQQ9uYW1l
LHJlc2NoZWR1bGXKQR0KCEluc3RhbmNlEhFPcGVyYXRpb25NZXRhZGF0YRLNAQoKSW1wb3J0
RGF0YRIpLmdvb2dsZS5jbG91ZC5sdXN0cmUudjEuSW1wb3J0RGF0YVJlcXVlc3QaHS5nb29n
bGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uInWC0+STAj0iOC92MS97bmFtZT1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL2luc3RhbmNlcy8qfTppbXBvcnREYXRhOgEq2kEEbmFtZcpBKAoSSW1w
b3J0RGF0YVJlc3BvbnNlEhJJbXBvcnREYXRhTWV0YWRhdGESxgEKCkV4cG9ydERhdGESKS5n
b29nbGUuY2xvdWQubHVzdHJlLnYxLkV4cG9ydERhdGFSZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdy
dW5uaW5nLk9wZXJhdGlvbiJugtPkkwI9IjgvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKi9pbnN0YW5jZXMvKn06ZXhwb3J0RGF0YToBKspBKAoSRXhwb3J0RGF0YVJlc3BvbnNl
EhJFeHBvcnREYXRhTWV0YWRhdGES3wEKDENyZWF0ZU1pcnJvchIrLmdvb2dsZS5jbG91ZC5s
dXN0cmUudjEuQ3JlYXRlTWlycm9yUmVxdWVzdBodLmdvb2dsZS5sb25ncnVubmluZy5PcGVy
YXRpb24iggGC0+STAkEiNy92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovaW5z
dGFuY2VzLyp9L21pcnJvcnM6Bm1pcnJvctpBF3BhcmVudCxtaXJyb3IsbWlycm9yX2lkykEe
CgZNaXJyb3ISFENyZWF0ZU1pcnJvck1ldGFkYXRhEt4BCgxVcGRhdGVNaXJyb3ISKy5nb29n
bGUuY2xvdWQubHVzdHJlLnYxLlVwZGF0ZU1pcnJvclJlcXVlc3QaHS5nb29nbGUubG9uZ3J1
bm5pbmcuT3BlcmF0aW9uIoEBgtPkkwJIMj4vdjEve21pcnJvci5uYW1lPXByb2plY3RzLyov
bG9jYXRpb25zLyovaW5zdGFuY2VzLyovbWlycm9ycy8qfToGbWlycm9y2kESbWlycm9yLHVw
ZGF0ZV9tYXNrykEbCgZNaXJyb3ISEU9wZXJhdGlvbk1ldGFkYXRhEs8BCgxEZWxldGVNaXJy
b3ISKy5nb29nbGUuY2xvdWQubHVzdHJlLnYxLkRlbGV0ZU1pcnJvclJlcXVlc3QaHS5nb29n
bGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uInOC0+STAjkqNy92MS97bmFtZT1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL2luc3RhbmNlcy8qL21pcnJvcnMvKn3aQQRuYW1lykEqChVnb29nbGUu
cHJvdG9idWYuRW1wdHkSEU9wZXJhdGlvbk1ldGFkYXRhEp0BCglHZXRNaXJyb3ISKC5nb29n
bGUuY2xvdWQubHVzdHJlLnYxLkdldE1pcnJvclJlcXVlc3QaHi5nb29nbGUuY2xvdWQubHVz
dHJlLnYxLk1pcnJvciJGgtPkkwI5EjcvdjEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMv
Ki9pbnN0YW5jZXMvKi9taXJyb3JzLyp92kEEbmFtZRKwAQoLTGlzdE1pcnJvcnMSKi5nb29n
bGUuY2xvdWQubHVzdHJlLnYxLkxpc3RNaXJyb3JzUmVxdWVzdBorLmdvb2dsZS5jbG91ZC5s
dXN0cmUudjEuTGlzdE1pcnJvcnNSZXNwb25zZSJIgtPkkwI5EjcvdjEve3BhcmVudD1wcm9q
ZWN0cy8qL2xvY2F0aW9ucy8qL2luc3RhbmNlcy8qfS9taXJyb3Jz2kEGcGFyZW50Ep8CChVD
cmVhdGVEaXJlY3RvcnlQb2xpY3kSNC5nb29nbGUuY2xvdWQubHVzdHJlLnYxLkNyZWF0ZURp
cmVjdG9yeVBvbGljeVJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIrAB
gtPkkwJVIkEvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2luc3RhbmNlcy8q
fS9kaXJlY3RvcnlQb2xpY2llczoQZGlyZWN0b3J5X3BvbGljedpBK3BhcmVudCxkaXJlY3Rv
cnlfcG9saWN5LGRpcmVjdG9yeV9wb2xpY3lfaWTKQSQKD0RpcmVjdG9yeVBvbGljeRIRT3Bl
cmF0aW9uTWV0YWRhdGES6wEKFURlbGV0ZURpcmVjdG9yeVBvbGljeRI0Lmdvb2dsZS5jbG91
ZC5sdXN0cmUudjEuRGVsZXRlRGlyZWN0b3J5UG9saWN5UmVxdWVzdBodLmdvb2dsZS5sb25n
cnVubmluZy5PcGVyYXRpb24ifYLT5JMCQypBL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRp
b25zLyovaW5zdGFuY2VzLyovZGlyZWN0b3J5UG9saWNpZXMvKn3aQQRuYW1lykEqChVnb29n
bGUucHJvdG9idWYuRW1wdHkSEU9wZXJhdGlvbk1ldGFkYXRhEsIBChJHZXREaXJlY3RvcnlQ
b2xpY3kSMS5nb29nbGUuY2xvdWQubHVzdHJlLnYxLkdldERpcmVjdG9yeVBvbGljeVJlcXVl
c3QaJy5nb29nbGUuY2xvdWQubHVzdHJlLnYxLkRpcmVjdG9yeVBvbGljeSJQgtPkkwJDEkEv
djEve25hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9pbnN0YW5jZXMvKi9kaXJlY3RvcnlQ
b2xpY2llcy8qfdpBBG5hbWUS2AEKFUxpc3REaXJlY3RvcnlQb2xpY2llcxI0Lmdvb2dsZS5j
bG91ZC5sdXN0cmUudjEuTGlzdERpcmVjdG9yeVBvbGljaWVzUmVxdWVzdBo1Lmdvb2dsZS5j
bG91ZC5sdXN0cmUudjEuTGlzdERpcmVjdG9yeVBvbGljaWVzUmVzcG9uc2UiUoLT5JMCQxJB
L3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9pbnN0YW5jZXMvKn0vZGlyZWN0
b3J5UG9saWNpZXPaQQZwYXJlbnQaScpBFWx1c3RyZS5nb29nbGVhcGlzLmNvbdJBLmh0dHBz
Oi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1CxgQKGmNvbS5nb29n
bGUuY2xvdWQubHVzdHJlLnYxQgtMdXN0cmVQcm90b1ABWjJjbG91ZC5nb29nbGUuY29tL2dv
L2x1c3RyZS9hcGl2MS9sdXN0cmVwYjtsdXN0cmVwYupBWQohaWFtLmdvb2dsZWFwaXMuY29t
L1NlcnZpY2VBY2NvdW50EjRwcm9qZWN0cy97cHJvamVjdH0vc2VydmljZUFjY291bnRzL3tz
ZXJ2aWNlX2FjY291bnR96kFOCh5jb21wdXRlLmdvb2dsZWFwaXMuY29tL05ldHdvcmsSLHBy
b2plY3RzL3twcm9qZWN0fS9nbG9iYWwvbmV0d29ya3Mve25ldHdvcmt96kF4CiFjbG91ZGtt
cy5nb29nbGVhcGlzLmNvbS9DcnlwdG9LZXkSU3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9rZXlSaW5ncy97a2V5X3Jpbmd9L2NyeXB0b0tleXMve2NyeXB0b19r
ZXl96kG7AQolY29tcHV0ZS5nb29nbGVhcGlzLmNvbS9SZXNvdXJjZVBvbGljeRJGcHJvamVj
dHMve3Byb2plY3R9L3JlZ2lvbnMve3JlZ2lvbn0vcmVzb3VyY2VQb2xpY2llcy97cmVzb3Vy
Y2VfcG9saWN5fRJKcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3Jl
c291cmNlUG9saWNpZXMve3Jlc291cmNlX3BvbGljeX1KjyIKBxIFDgD6AQEKvAQKAQwSAw4A
EjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB8KCQoCAwASAxIAJgoJCgIDARID
EwAhCgkKAgMCEgMUACMKCQoCAwMSAxUANwoJCgIDBBIDFgAvCgkKAgMFEgMXAC0KCQoCAwYS
AxgALwoJCgIDBxIDGQAtCgkKAgMIEgMaACUKCAoBCBIDHABJCgkKAggLEgMcAEkKCAoBCBID
HQAiCgkKAggKEgMdACIKCAoBCBIDHgAsCgkKAggIEgMeACwKCAoBCBIDHwAzCgkKAggBEgMf
ADMKCQoBCBIEIAAjAgoMCgQInQgAEgQgACMCCgkKAQgSBCQAJwIKDAoECJ0IARIEJAAnAgoJ
CgEIEgQoACsCCgwKBAidCAISBCgAKwIKCQoBCBIELAAwAgoMCgQInQgDEgQsADACCjgKAgYA
EgUzAPoBARorIFNlcnZpY2UgZGVzY3JpYmluZyBoYW5kbGVycyBmb3IgcmVzb3VyY2VzCgoK
CgMGAAESAzMIDgoKCgMGAAMSAzQCPQoMCgUGAAOZCBIDNAI9CgsKAwYAAxIENQI2NwoNCgUG
AAOaCBIENQI2NwpACgQGAAIAEgQ5Aj4DGjIgTGlzdHMgaW5zdGFuY2VzIGluIGEgZ2l2ZW4g
cHJvamVjdCBhbmQgbG9jYXRpb24uCgoMCgUGAAIAARIDOQYTCgwKBQYAAgACEgM5FCgKDAoF
BgACAAMSAzkzSAoNCgUGAAIABBIEOgQ8BgoRCgkGAAIABLDKvCISBDoEPAYKDAoFBgACAAQS
Az0ENAoPCggGAAIABJsIABIDPQQ0CjIKBAYAAgESBEECRgMaJCBHZXRzIGRldGFpbHMgb2Yg
YSBzaW5nbGUgaW5zdGFuY2UuCgoMCgUGAAIBARIDQQYRCgwKBQYAAgECEgNBEiQKDAoFBgAC
AQMSA0EvNwoNCgUGAAIBBBIEQgREBgoRCgkGAAIBBLDKvCISBEIERAYKDAoFBgACAQQSA0UE
MgoPCggGAAIBBJsIABIDRQQyCkcKBAYAAgISBEkCVAMaOSBDcmVhdGVzIGEgbmV3IGluc3Rh
bmNlIGluIGEgZ2l2ZW4gcHJvamVjdCBhbmQgbG9jYXRpb24uCgoMCgUGAAICARIDSQYUCgwK
BQYAAgICEgNJFSoKDAoFBgACAgMSA0oPKwoNCgUGAAICBBIESwROBgoRCgkGAAICBLDKvCIS
BEsETgYKDAoFBgACAgQSA08ESQoPCggGAAICBJsIABIDTwRJCg0KBQYAAgIEEgRQBFMGCg8K
BwYAAgIEmQgSBFAEUwYKPAoEBgACAxIEVwJiAxouIFVwZGF0ZXMgdGhlIHBhcmFtZXRlcnMg
b2YgYSBzaW5nbGUgaW5zdGFuY2UuCgoMCgUGAAIDARIDVwYUCgwKBQYAAgMCEgNXFSoKDAoF
BgACAwMSA1gPKwoNCgUGAAIDBBIEWQRcBgoRCgkGAAIDBLDKvCISBFkEXAYKDAoFBgACAwQS
A10EQgoPCggGAAIDBJsIABIDXQRCCg0KBQYAAgMEEgReBGEGCg8KBwYAAgMEmQgSBF4EYQYK
KgoEBgACBBIEZQJvAxocIERlbGV0ZXMgYSBzaW5nbGUgaW5zdGFuY2UuCgoMCgUGAAIEARID
ZQYUCgwKBQYAAgQCEgNlFSoKDAoFBgACBAMSA2YPKwoNCgUGAAIEBBIEZwRpBgoRCgkGAAIE
BLDKvCISBGcEaQYKDAoFBgACBAQSA2oEMgoPCggGAAIEBJsIABIDagQyCg0KBQYAAgQEEgRr
BG4GCg8KBwYAAgQEmQgSBGsEbgYKUAoEBgACBRIEcgJ9AxpCIFJlc2NoZWR1bGVzIGEgcGxh
bm5lZCBtYWludGVuYW5jZSBldmVudCBmb3IgYSBzcGVjaWZpYyBpbnN0YW5jZS4KCgwKBQYA
AgUBEgNyBhsKDAoFBgACBQISA3IcOAoMCgUGAAIFAxIDcw8rCg0KBQYAAgUEEgR0BHcGChEK
CQYAAgUEsMq8IhIEdAR3BgoMCgUGAAIFBBIDeAQ9Cg8KCAYAAgUEmwgAEgN4BD0KDQoFBgAC
BQQSBHkEfAYKDwoHBgACBQSZCBIEeQR8BgpPCgQGAAIGEgaAAQKKAQMaPyBJbXBvcnRzIGRh
dGEgZnJvbSBDbG91ZCBTdG9yYWdlIHRvIGEgTWFuYWdlZCBMdXN0cmUgaW5zdGFuY2UuCgoN
CgUGAAIGARIEgAEGEAoNCgUGAAIGAhIEgAERIgoNCgUGAAIGAxIEgAEtSQoPCgUGAAIGBBIG
gQEEhAEGChMKCQYAAgYEsMq8IhIGgQEEhAEGCg0KBQYAAgYEEgSFAQQyChAKCAYAAgYEmwgA
EgSFAQQyCg8KBQYAAgYEEgaGAQSJAQYKEQoHBgACBgSZCBIGhgEEiQEGCk8KBAYAAgcSBo0B
ApYBAxo/IEV4cG9ydHMgZGF0YSBmcm9tIGEgTWFuYWdlZCBMdXN0cmUgaW5zdGFuY2UgdG8g
Q2xvdWQgU3RvcmFnZS4KCg0KBQYAAgcBEgSNAQYQCg0KBQYAAgcCEgSNAREiCg0KBQYAAgcD
EgSNAS1JCg8KBQYAAgcEEgaOAQSRAQYKEwoJBgACBwSwyrwiEgaOAQSRAQYKDwoFBgACBwQS
BpIBBJUBBgoRCgcGAAIHBJkIEgaSAQSVAQYKOwoEBgACCBIGmQECowEDGisgQ3JlYXRlcyBh
IG5ldyBtaXJyb3IgaW4gYSBnaXZlbiBpbnN0YW5jZS4KCg0KBQYAAggBEgSZAQYSCg0KBQYA
AggCEgSZARMmCg0KBQYAAggDEgSZATFNCg8KBQYAAggEEgaaAQSdAQYKEwoJBgACCASwyrwi
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
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Lustre::V1::Lustre::LustreClient ===
package Google::Cloud::Lustre::V1::Lustre::LustreClient;

=pod

=head2 Service Client: Google::Cloud::Lustre::V1::Lustre::LustreClient

Client stub representing the remote C<Lustre> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<lustre.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'lustre.googleapis.com:443' );

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

sub list_instances {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Lustre::V1::Instance::ListInstancesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.lustre.v1.Lustre',
        method         => 'ListInstances',
        request        => $req,
        response_class => 'Google::Cloud::Lustre::V1::Instance::ListInstancesResponse',
    });
}

sub get_instance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Lustre::V1::Instance::GetInstanceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.lustre.v1.Lustre',
        method         => 'GetInstance',
        request        => $req,
        response_class => 'Google::Cloud::Lustre::V1::Instance::Instance',
    });
}

sub create_instance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Lustre::V1::Instance::CreateInstanceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.lustre.v1.Lustre',
        method         => 'CreateInstance',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_instance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Lustre::V1::Instance::UpdateInstanceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.lustre.v1.Lustre',
        method         => 'UpdateInstance',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_instance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Lustre::V1::Instance::DeleteInstanceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.lustre.v1.Lustre',
        method         => 'DeleteInstance',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub reschedule_maintenance {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Lustre::V1::Instance::RescheduleMaintenanceRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.lustre.v1.Lustre',
        method         => 'RescheduleMaintenance',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub import_data {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Lustre::V1::Transfer::ImportDataRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.lustre.v1.Lustre',
        method         => 'ImportData',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub export_data {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Lustre::V1::Transfer::ExportDataRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.lustre.v1.Lustre',
        method         => 'ExportData',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub create_mirror {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Lustre::V1::Mirror::CreateMirrorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.lustre.v1.Lustre',
        method         => 'CreateMirror',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_mirror {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Lustre::V1::Mirror::UpdateMirrorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.lustre.v1.Lustre',
        method         => 'UpdateMirror',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_mirror {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Lustre::V1::Mirror::DeleteMirrorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.lustre.v1.Lustre',
        method         => 'DeleteMirror',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_mirror {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Lustre::V1::Mirror::GetMirrorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.lustre.v1.Lustre',
        method         => 'GetMirror',
        request        => $req,
        response_class => 'Google::Cloud::Lustre::V1::Mirror::Mirror',
    });
}

sub list_mirrors {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Lustre::V1::Mirror::ListMirrorsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.lustre.v1.Lustre',
        method         => 'ListMirrors',
        request        => $req,
        response_class => 'Google::Cloud::Lustre::V1::Mirror::ListMirrorsResponse',
    });
}

sub create_directory_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Lustre::V1::DirectoryPolicy::CreateDirectoryPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.lustre.v1.Lustre',
        method         => 'CreateDirectoryPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_directory_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Lustre::V1::DirectoryPolicy::DeleteDirectoryPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.lustre.v1.Lustre',
        method         => 'DeleteDirectoryPolicy',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_directory_policy {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Lustre::V1::DirectoryPolicy::GetDirectoryPolicyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.lustre.v1.Lustre',
        method         => 'GetDirectoryPolicy',
        request        => $req,
        response_class => 'Google::Cloud::Lustre::V1::DirectoryPolicy::DirectoryPolicy',
    });
}

sub list_directory_policies {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Lustre::V1::DirectoryPolicy::ListDirectoryPoliciesRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.lustre.v1.Lustre',
        method         => 'ListDirectoryPolicies',
        request        => $req,
        response_class => 'Google::Cloud::Lustre::V1::DirectoryPolicy::ListDirectoryPoliciesResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Lustre::V1::Lustre - Compiled Protocol Buffers messages for google/cloud/lustre/v1/lustre.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/lustre/v1/lustre.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Lustre::V1::Lustre::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
