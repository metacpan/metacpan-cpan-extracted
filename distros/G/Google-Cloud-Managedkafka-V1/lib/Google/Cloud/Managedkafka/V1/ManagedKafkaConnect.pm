package Google::Cloud::Managedkafka::V1::ManagedKafkaConnect;

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
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Managedkafka::V1::Resources };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Empty };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
Cjhnb29nbGUvY2xvdWQvbWFuYWdlZGthZmthL3YxL21hbmFnZWRfa2Fma2FfY29ubmVjdC5w
cm90bxIcZ29vZ2xlLmNsb3VkLm1hbmFnZWRrYWZrYS52MRocZ29vZ2xlL2FwaS9hbm5vdGF0
aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8aG2dvb2dsZS9hcGkvZmllbGRfaW5mby5wcm90bxoZZ29vZ2xlL2Fw
aS9yZXNvdXJjZS5wcm90bxosZ29vZ2xlL2Nsb3VkL21hbmFnZWRrYWZrYS92MS9yZXNvdXJj
ZXMucHJvdG8aI2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvGhtnb29nbGUv
cHJvdG9idWYvZW1wdHkucHJvdG8aIGdvb2dsZS9wcm90b2J1Zi9maWVsZF9tYXNrLnByb3Rv
ImIKGEdldENvbm5lY3RDbHVzdGVyUmVxdWVzdBJGCgRuYW1lGAEgASgJQjLgQQL6QSwKKm1h
bmFnZWRrYWZrYS5nb29nbGVhcGlzLmNvbS9Db25uZWN0Q2x1c3RlclIEbmFtZSKkAgobQ3Jl
YXRlQ29ubmVjdENsdXN0ZXJSZXF1ZXN0EkoKBnBhcmVudBgBIAEoCUIy4EEC+kEsEiptYW5h
Z2Vka2Fma2EuZ29vZ2xlYXBpcy5jb20vQ29ubmVjdENsdXN0ZXJSBnBhcmVudBIxChJjb25u
ZWN0X2NsdXN0ZXJfaWQYAiABKAlCA+BBAlIQY29ubmVjdENsdXN0ZXJJZBJaCg9jb25uZWN0
X2NsdXN0ZXIYAyABKAsyLC5nb29nbGUuY2xvdWQubWFuYWdlZGthZmthLnYxLkNvbm5lY3RD
bHVzdGVyQgPgQQJSDmNvbm5lY3RDbHVzdGVyEioKCnJlcXVlc3RfaWQYBCABKAlCC+KMz9cI
AggB4EEBUglyZXF1ZXN0SWQi5wEKG1VwZGF0ZUNvbm5lY3RDbHVzdGVyUmVxdWVzdBJACgt1
cGRhdGVfbWFzaxgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tCA+BBAlIKdXBk
YXRlTWFzaxJaCg9jb25uZWN0X2NsdXN0ZXIYAiABKAsyLC5nb29nbGUuY2xvdWQubWFuYWdl
ZGthZmthLnYxLkNvbm5lY3RDbHVzdGVyQgPgQQJSDmNvbm5lY3RDbHVzdGVyEioKCnJlcXVl
c3RfaWQYAyABKAlCC+KMz9cIAggB4EEBUglyZXF1ZXN0SWQikQEKG0RlbGV0ZUNvbm5lY3RD
bHVzdGVyUmVxdWVzdBJGCgRuYW1lGAEgASgJQjLgQQL6QSwKKm1hbmFnZWRrYWZrYS5nb29n
bGVhcGlzLmNvbS9Db25uZWN0Q2x1c3RlclIEbmFtZRIqCgpyZXF1ZXN0X2lkGAIgASgJQgvi
jM/XCAIIAeBBAVIJcmVxdWVzdElkIusBChpMaXN0Q29ubmVjdENsdXN0ZXJzUmVxdWVzdBJK
CgZwYXJlbnQYASABKAlCMuBBAvpBLBIqbWFuYWdlZGthZmthLmdvb2dsZWFwaXMuY29tL0Nv
bm5lY3RDbHVzdGVyUgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXpl
EiIKCnBhZ2VfdG9rZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID
4EEBUgZmaWx0ZXISHgoIb3JkZXJfYnkYBSABKAlCA+BBAVIHb3JkZXJCeSLAAQobTGlzdENv
bm5lY3RDbHVzdGVyc1Jlc3BvbnNlElcKEGNvbm5lY3RfY2x1c3RlcnMYASADKAsyLC5nb29n
bGUuY2xvdWQubWFuYWdlZGthZmthLnYxLkNvbm5lY3RDbHVzdGVyUg9jb25uZWN0Q2x1c3Rl
cnMSJgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuEiAKC3VucmVhY2hh
YmxlGAMgAygJUgt1bnJlYWNoYWJsZSJYChNHZXRDb25uZWN0b3JSZXF1ZXN0EkEKBG5hbWUY
ASABKAlCLeBBAvpBJwolbWFuYWdlZGthZmthLmdvb2dsZWFwaXMuY29tL0Nvbm5lY3RvclIE
bmFtZSLTAQoWQ3JlYXRlQ29ubmVjdG9yUmVxdWVzdBJFCgZwYXJlbnQYASABKAlCLeBBAvpB
JxIlbWFuYWdlZGthZmthLmdvb2dsZWFwaXMuY29tL0Nvbm5lY3RvclIGcGFyZW50EiYKDGNv
bm5lY3Rvcl9pZBgCIAEoCUID4EECUgtjb25uZWN0b3JJZBJKCgljb25uZWN0b3IYAyABKAsy
Jy5nb29nbGUuY2xvdWQubWFuYWdlZGthZmthLnYxLkNvbm5lY3RvckID4EECUgljb25uZWN0
b3IipgEKFlVwZGF0ZUNvbm5lY3RvclJlcXVlc3QSQAoLdXBkYXRlX21hc2sYASABKAsyGi5n
b29nbGUucHJvdG9idWYuRmllbGRNYXNrQgPgQQJSCnVwZGF0ZU1hc2sSSgoJY29ubmVjdG9y
GAIgASgLMicuZ29vZ2xlLmNsb3VkLm1hbmFnZWRrYWZrYS52MS5Db25uZWN0b3JCA+BBAlIJ
Y29ubmVjdG9yIlsKFkRlbGV0ZUNvbm5lY3RvclJlcXVlc3QSQQoEbmFtZRgBIAEoCUIt4EEC
+kEnCiVtYW5hZ2Vka2Fma2EuZ29vZ2xlYXBpcy5jb20vQ29ubmVjdG9yUgRuYW1lIqQBChVM
aXN0Q29ubmVjdG9yc1JlcXVlc3QSRQoGcGFyZW50GAEgASgJQi3gQQL6QScSJW1hbmFnZWRr
YWZrYS5nb29nbGVhcGlzLmNvbS9Db25uZWN0b3JSBnBhcmVudBIgCglwYWdlX3NpemUYAiAB
KAVCA+BBAVIIcGFnZVNpemUSIgoKcGFnZV90b2tlbhgDIAEoCUID4EEBUglwYWdlVG9rZW4i
iQEKFkxpc3RDb25uZWN0b3JzUmVzcG9uc2USRwoKY29ubmVjdG9ycxgBIAMoCzInLmdvb2ds
ZS5jbG91ZC5tYW5hZ2Vka2Fma2EudjEuQ29ubmVjdG9yUgpjb25uZWN0b3JzEiYKD25leHRf
cGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiJaChVQYXVzZUNvbm5lY3RvclJlcXVl
c3QSQQoEbmFtZRgBIAEoCUIt4EEC+kEnCiVtYW5hZ2Vka2Fma2EuZ29vZ2xlYXBpcy5jb20v
Q29ubmVjdG9yUgRuYW1lIhgKFlBhdXNlQ29ubmVjdG9yUmVzcG9uc2UiWwoWUmVzdW1lQ29u
bmVjdG9yUmVxdWVzdBJBCgRuYW1lGAEgASgJQi3gQQL6QScKJW1hbmFnZWRrYWZrYS5nb29n
bGVhcGlzLmNvbS9Db25uZWN0b3JSBG5hbWUiGQoXUmVzdW1lQ29ubmVjdG9yUmVzcG9uc2Ui
XAoXUmVzdGFydENvbm5lY3RvclJlcXVlc3QSQQoEbmFtZRgBIAEoCUIt4EEC+kEnCiVtYW5h
Z2Vka2Fma2EuZ29vZ2xlYXBpcy5jb20vQ29ubmVjdG9yUgRuYW1lIhoKGFJlc3RhcnRDb25u
ZWN0b3JSZXNwb25zZSJZChRTdG9wQ29ubmVjdG9yUmVxdWVzdBJBCgRuYW1lGAEgASgJQi3g
QQL6QScKJW1hbmFnZWRrYWZrYS5nb29nbGVhcGlzLmNvbS9Db25uZWN0b3JSBG5hbWUiFwoV
U3RvcENvbm5lY3RvclJlc3BvbnNlMoMZChNNYW5hZ2VkS2Fma2FDb25uZWN0EtABChNMaXN0
Q29ubmVjdENsdXN0ZXJzEjguZ29vZ2xlLmNsb3VkLm1hbmFnZWRrYWZrYS52MS5MaXN0Q29u
bmVjdENsdXN0ZXJzUmVxdWVzdBo5Lmdvb2dsZS5jbG91ZC5tYW5hZ2Vka2Fma2EudjEuTGlz
dENvbm5lY3RDbHVzdGVyc1Jlc3BvbnNlIkSC0+STAjUSMy92MS97cGFyZW50PXByb2plY3Rz
LyovbG9jYXRpb25zLyp9L2Nvbm5lY3RDbHVzdGVyc9pBBnBhcmVudBK9AQoRR2V0Q29ubmVj
dENsdXN0ZXISNi5nb29nbGUuY2xvdWQubWFuYWdlZGthZmthLnYxLkdldENvbm5lY3RDbHVz
dGVyUmVxdWVzdBosLmdvb2dsZS5jbG91ZC5tYW5hZ2Vka2Fma2EudjEuQ29ubmVjdENsdXN0
ZXIiQoLT5JMCNRIzL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovY29ubmVjdENs
dXN0ZXJzLyp92kEEbmFtZRKRAgoUQ3JlYXRlQ29ubmVjdENsdXN0ZXISOS5nb29nbGUuY2xv
dWQubWFuYWdlZGthZmthLnYxLkNyZWF0ZUNvbm5lY3RDbHVzdGVyUmVxdWVzdBodLmdvb2ds
ZS5sb25ncnVubmluZy5PcGVyYXRpb24ingGC0+STAkYiMy92MS97cGFyZW50PXByb2plY3Rz
LyovbG9jYXRpb25zLyp9L2Nvbm5lY3RDbHVzdGVyczoPY29ubmVjdF9jbHVzdGVy2kEpcGFy
ZW50LGNvbm5lY3RfY2x1c3Rlcixjb25uZWN0X2NsdXN0ZXJfaWTKQSMKDkNvbm5lY3RDbHVz
dGVyEhFPcGVyYXRpb25NZXRhZGF0YRKTAgoUVXBkYXRlQ29ubmVjdENsdXN0ZXISOS5nb29n
bGUuY2xvdWQubWFuYWdlZGthZmthLnYxLlVwZGF0ZUNvbm5lY3RDbHVzdGVyUmVxdWVzdBod
Lmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24ioAGC0+STAlYyQy92MS97Y29ubmVjdF9j
bHVzdGVyLm5hbWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb25uZWN0Q2x1c3RlcnMvKn06
D2Nvbm5lY3RfY2x1c3RlctpBG2Nvbm5lY3RfY2x1c3Rlcix1cGRhdGVfbWFza8pBIwoOQ29u
bmVjdENsdXN0ZXISEU9wZXJhdGlvbk1ldGFkYXRhEuEBChREZWxldGVDb25uZWN0Q2x1c3Rl
chI5Lmdvb2dsZS5jbG91ZC5tYW5hZ2Vka2Fma2EudjEuRGVsZXRlQ29ubmVjdENsdXN0ZXJS
ZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJvgtPkkwI1KjMvdjEve25h
bWU9cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb25uZWN0Q2x1c3RlcnMvKn3aQQRuYW1lykEq
ChVnb29nbGUucHJvdG9idWYuRW1wdHkSEU9wZXJhdGlvbk1ldGFkYXRhEs4BCg5MaXN0Q29u
bmVjdG9ycxIzLmdvb2dsZS5jbG91ZC5tYW5hZ2Vka2Fma2EudjEuTGlzdENvbm5lY3RvcnNS
ZXF1ZXN0GjQuZ29vZ2xlLmNsb3VkLm1hbmFnZWRrYWZrYS52MS5MaXN0Q29ubmVjdG9yc1Jl
c3BvbnNlIlGC0+STAkISQC92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyovY29u
bmVjdENsdXN0ZXJzLyp9L2Nvbm5lY3RvcnPaQQZwYXJlbnQSuwEKDEdldENvbm5lY3RvchIx
Lmdvb2dsZS5jbG91ZC5tYW5hZ2Vka2Fma2EudjEuR2V0Q29ubmVjdG9yUmVxdWVzdBonLmdv
b2dsZS5jbG91ZC5tYW5hZ2Vka2Fma2EudjEuQ29ubmVjdG9yIk+C0+STAkISQC92MS97bmFt
ZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Nvbm5lY3RDbHVzdGVycy8qL2Nvbm5lY3RvcnMv
Kn3aQQRuYW1lEuUBCg9DcmVhdGVDb25uZWN0b3ISNC5nb29nbGUuY2xvdWQubWFuYWdlZGth
ZmthLnYxLkNyZWF0ZUNvbm5lY3RvclJlcXVlc3QaJy5nb29nbGUuY2xvdWQubWFuYWdlZGth
ZmthLnYxLkNvbm5lY3RvciJzgtPkkwJNIkAvdjEve3BhcmVudD1wcm9qZWN0cy8qL2xvY2F0
aW9ucy8qL2Nvbm5lY3RDbHVzdGVycy8qfS9jb25uZWN0b3JzOgljb25uZWN0b3LaQR1wYXJl
bnQsY29ubmVjdG9yLGNvbm5lY3Rvcl9pZBLnAQoPVXBkYXRlQ29ubmVjdG9yEjQuZ29vZ2xl
LmNsb3VkLm1hbmFnZWRrYWZrYS52MS5VcGRhdGVDb25uZWN0b3JSZXF1ZXN0GicuZ29vZ2xl
LmNsb3VkLm1hbmFnZWRrYWZrYS52MS5Db25uZWN0b3IidYLT5JMCVzJKL3YxL3tjb25uZWN0
b3IubmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Nvbm5lY3RDbHVzdGVycy8qL2Nvbm5l
Y3RvcnMvKn06CWNvbm5lY3RvctpBFWNvbm5lY3Rvcix1cGRhdGVfbWFzaxKwAQoPRGVsZXRl
Q29ubmVjdG9yEjQuZ29vZ2xlLmNsb3VkLm1hbmFnZWRrYWZrYS52MS5EZWxldGVDb25uZWN0
b3JSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5Ik+C0+STAkIqQC92MS97bmFtZT1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Nvbm5lY3RDbHVzdGVycy8qL2Nvbm5lY3RvcnMvKn3a
QQRuYW1lEtUBCg5QYXVzZUNvbm5lY3RvchIzLmdvb2dsZS5jbG91ZC5tYW5hZ2Vka2Fma2Eu
djEuUGF1c2VDb25uZWN0b3JSZXF1ZXN0GjQuZ29vZ2xlLmNsb3VkLm1hbmFnZWRrYWZrYS52
MS5QYXVzZUNvbm5lY3RvclJlc3BvbnNlIliC0+STAksiRi92MS97bmFtZT1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qL2Nvbm5lY3RDbHVzdGVycy8qL2Nvbm5lY3RvcnMvKn06cGF1c2U6ASra
QQRuYW1lEtkBCg9SZXN1bWVDb25uZWN0b3ISNC5nb29nbGUuY2xvdWQubWFuYWdlZGthZmth
LnYxLlJlc3VtZUNvbm5lY3RvclJlcXVlc3QaNS5nb29nbGUuY2xvdWQubWFuYWdlZGthZmth
LnYxLlJlc3VtZUNvbm5lY3RvclJlc3BvbnNlIlmC0+STAkwiRy92MS97bmFtZT1wcm9qZWN0
cy8qL2xvY2F0aW9ucy8qL2Nvbm5lY3RDbHVzdGVycy8qL2Nvbm5lY3RvcnMvKn06cmVzdW1l
OgEq2kEEbmFtZRLdAQoQUmVzdGFydENvbm5lY3RvchI1Lmdvb2dsZS5jbG91ZC5tYW5hZ2Vk
a2Fma2EudjEuUmVzdGFydENvbm5lY3RvclJlcXVlc3QaNi5nb29nbGUuY2xvdWQubWFuYWdl
ZGthZmthLnYxLlJlc3RhcnRDb25uZWN0b3JSZXNwb25zZSJagtPkkwJNIkgvdjEve25hbWU9
cHJvamVjdHMvKi9sb2NhdGlvbnMvKi9jb25uZWN0Q2x1c3RlcnMvKi9jb25uZWN0b3JzLyp9
OnJlc3RhcnQ6ASraQQRuYW1lEtEBCg1TdG9wQ29ubmVjdG9yEjIuZ29vZ2xlLmNsb3VkLm1h
bmFnZWRrYWZrYS52MS5TdG9wQ29ubmVjdG9yUmVxdWVzdBozLmdvb2dsZS5jbG91ZC5tYW5h
Z2Vka2Fma2EudjEuU3RvcENvbm5lY3RvclJlc3BvbnNlIleC0+STAkoiRS92MS97bmFtZT1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Nvbm5lY3RDbHVzdGVycy8qL2Nvbm5lY3RvcnMvKn06
c3RvcDoBKtpBBG5hbWUaT8pBG21hbmFnZWRrYWZrYS5nb29nbGVhcGlzLmNvbdJBLmh0dHBz
Oi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1C5AEKIGNvbS5nb29n
bGUuY2xvdWQubWFuYWdlZGthZmthLnYxQhhNYW5hZ2VkS2Fma2FDb25uZWN0UHJvdG9QAVpE
Y2xvdWQuZ29vZ2xlLmNvbS9nby9tYW5hZ2Vka2Fma2EvYXBpdjEvbWFuYWdlZGthZmthcGI7
bWFuYWdlZGthZmthcGKqAhxHb29nbGUuQ2xvdWQuTWFuYWdlZEthZmthLlYxygIcR29vZ2xl
XENsb3VkXE1hbmFnZWRLYWZrYVxWMeoCH0dvb2dsZTo6Q2xvdWQ6Ok1hbmFnZWRLYWZrYTo6
VjFK+nYKBxIFDgD+AyAKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQACUKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAJQoJCgID
BBIDFgAjCgkKAgMFEgMXADYKCQoCAwYSAxgALQoJCgIDBxIDGQAlCgkKAgMIEgMaACoKCAoB
CBIDHAA5CgkKAgglEgMcADkKCAoBCBIDHQBbCgkKAggLEgMdAFsKCAoBCBIDHgAiCgkKAggK
EgMeACIKCAoBCBIDHwA5CgkKAggIEgMfADkKCAoBCBIDIAA5CgkKAggBEgMgADkKCAoBCBID
IQA5CgkKAggpEgMhADkKCAoBCBIDIgA4CgkKAggtEgMiADgKcgoCBgASBSYAtQEBGmUgVGhl
IHNlcnZpY2UgdGhhdCBhIGNsaWVudCBhcHBsaWNhdGlvbiB1c2VzIHRvIG1hbmFnZSBBcGFj
aGUgS2Fma2EgQ29ubmVjdAogY2x1c3RlcnMgYW5kIGNvbm5lY3RvcnMuCgoKCgMGAAESAyYI
GwoKCgMGAAMSAycCQwoMCgUGAAOZCBIDJwJDCgsKAwYAAxIEKAIpNwoNCgUGAAOaCBIEKAIp
NwpRCgQGAAIAEgQsAjIDGkMgTGlzdHMgdGhlIEthZmthIENvbm5lY3QgY2x1c3RlcnMgaW4g
YSBnaXZlbiBwcm9qZWN0IGFuZCBsb2NhdGlvbi4KCgwKBQYAAgABEgMsBhkKDAoFBgACAAIS
AywaNAoMCgUGAAIAAxIDLQ8qCg0KBQYAAgAEEgQuBDAGChEKCQYAAgAEsMq8IhIELgQwBgoM
CgUGAAIABBIDMQQ0Cg8KCAYAAgAEmwgAEgMxBDQKSQoEBgACARIENQI6Axo7IFJldHVybnMg
dGhlIHByb3BlcnRpZXMgb2YgYSBzaW5nbGUgS2Fma2EgQ29ubmVjdCBjbHVzdGVyLgoKDAoF
BgACAQESAzUGFwoMCgUGAAIBAhIDNRgwCgwKBQYAAgEDEgM1O0kKDQoFBgACAQQSBDYEOAYK
EQoJBgACAQSwyrwiEgQ2BDgGCgwKBQYAAgEEEgM5BDIKDwoIBgACAQSbCAASAzkEMgpUCgQG
AAICEgQ9AkkDGkYgQ3JlYXRlcyBhIG5ldyBLYWZrYSBDb25uZWN0IGNsdXN0ZXIgaW4gYSBn
aXZlbiBwcm9qZWN0IGFuZCBsb2NhdGlvbi4KCgwKBQYAAgIBEgM9BhoKDAoFBgACAgISAz0b
NgoMCgUGAAICAxIDPg8rCg0KBQYAAgIEEgQ/BEIGChEKCQYAAgIEsMq8IhIEPwRCBgoNCgUG
AAICBBIEQwRENAoQCggGAAICBJsIABIEQwRENAoNCgUGAAICBBIERQRIBgoPCgcGAAICBJkI
EgRFBEgGCkkKBAYAAgMSBEwCVwMaOyBVcGRhdGVzIHRoZSBwcm9wZXJ0aWVzIG9mIGEgc2lu
Z2xlIEthZmthIENvbm5lY3QgY2x1c3Rlci4KCgwKBQYAAgMBEgNMBhoKDAoFBgACAwISA0wb
NgoMCgUGAAIDAxIDTQ8rCg0KBQYAAgMEEgROBFEGChEKCQYAAgMEsMq8IhIETgRRBgoMCgUG
AAIDBBIDUgRJCg8KCAYAAgMEmwgAEgNSBEkKDQoFBgACAwQSBFMEVgYKDwoHBgACAwSZCBIE
UwRWBgoxCgQGAAIEEgRaAmQDGiMgRGVsZXRlcyBhIHNpbmdsZSBDb25uZWN0IGNsdXN0ZXIu
CgoMCgUGAAIEARIDWgYaCgwKBQYAAgQCEgNaGzYKDAoFBgACBAMSA1sPKwoNCgUGAAIEBBIE
XAReBgoRCgkGAAIEBLDKvCISBFwEXgYKDAoFBgACBAQSA18EMgoPCggGAAIEBJsIABIDXwQy
Cg0KBQYAAgQEEgRgBGMGCg8KBwYAAgQEmQgSBGAEYwYKQAoEBgACBRIEZwJsAxoyIExpc3Rz
IHRoZSBjb25uZWN0b3JzIGluIGEgZ2l2ZW4gQ29ubmVjdCBjbHVzdGVyLgoKDAoFBgACBQES
A2cGFAoMCgUGAAIFAhIDZxUqCgwKBQYAAgUDEgNnNUsKDQoFBgACBQQSBGgEagYKEQoJBgAC
BQSwyrwiEgRoBGoGCgwKBQYAAgUEEgNrBDQKDwoIBgACBQSbCAASA2sENAo9CgQGAAIGEgRv
AnQDGi8gUmV0dXJucyB0aGUgcHJvcGVydGllcyBvZiBhIHNpbmdsZSBjb25uZWN0b3IuCgoM
CgUGAAIGARIDbwYSCgwKBQYAAgYCEgNvEyYKDAoFBgACBgMSA28xOgoNCgUGAAIGBBIEcARy
BgoRCgkGAAIGBLDKvCISBHAEcgYKDAoFBgACBgQSA3MEMgoPCggGAAIGBJsIABIDcwQyCkMK
BAYAAgcSBHcCfQMaNSBDcmVhdGVzIGEgbmV3IGNvbm5lY3RvciBpbiBhIGdpdmVuIENvbm5l
Y3QgY2x1c3Rlci4KCgwKBQYAAgcBEgN3BhUKDAoFBgACBwISA3cWLAoMCgUGAAIHAxIDdzdA
Cg0KBQYAAgcEEgR4BHsGChEKCQYAAgcEsMq8IhIEeAR7BgoMCgUGAAIHBBIDfARLCg8KCAYA
AgcEmwgAEgN8BEsKOAoEBgACCBIGgAEChgEDGiggVXBkYXRlcyB0aGUgcHJvcGVydGllcyBv
ZiBhIGNvbm5lY3Rvci4KCg0KBQYAAggBEgSAAQYVCg0KBQYAAggCEgSAARYsCg0KBQYAAggD
EgSAATdACg8KBQYAAggEEgaBAQSEAQYKEwoJBgACCASwyrwiEgaBAQSEAQYKDQoFBgACCAQS
BIUBBEMKEAoIBgACCASbCAASBIUBBEMKJgoEBgACCRIGiQECjgEDGhYgRGVsZXRlcyBhIGNv
bm5lY3Rvci4KCg0KBQYAAgkBEgSJAQYVCg0KBQYAAgkCEgSJARYsCg0KBQYAAgkDEgSJATdM
Cg8KBQYAAgkEEgaKAQSMAQYKEwoJBgACCQSwyrwiEgaKAQSMAQYKDQoFBgACCQQSBI0BBDIK
EAoIBgACCQSbCAASBI0BBDIKNQoEBgACChIGkQEClwEDGiUgUGF1c2VzIHRoZSBjb25uZWN0
b3IgYW5kIGl0cyB0YXNrcy4KCg0KBQYAAgoBEgSRAQYUCg0KBQYAAgoCEgSRARUqCg0KBQYA
AgoDEgSRATVLCg8KBQYAAgoEEgaSAQSVAQYKEwoJBgACCgSwyrwiEgaSAQSVAQYKDQoFBgAC
CgQSBJYBBDIKEAoIBgACCgSbCAASBJYBBDIKNgoEBgACCxIGmgECoQEDGiYgUmVzdW1lcyB0
aGUgY29ubmVjdG9yIGFuZCBpdHMgdGFza3MuCgoNCgUGAAILARIEmgEGFQoNCgUGAAILAhIE
mgEWLAoNCgUGAAILAxIEmwEPJgoPCgUGAAILBBIGnAEEnwEGChMKCQYAAgsEsMq8IhIGnAEE
nwEGCg0KBQYAAgsEEgSgAQQyChAKCAYAAgsEmwgAEgSgAQQyCikKBAYAAgwSBqQBAqsBAxoZ
IFJlc3RhcnRzIHRoZSBjb25uZWN0b3IuCgoNCgUGAAIMARIEpAEGFgoNCgUGAAIMAhIEpAEX
LgoNCgUGAAIMAxIEpQEPJwoPCgUGAAIMBBIGpgEEqQEGChMKCQYAAgwEsMq8IhIGpgEEqQEG
Cg0KBQYAAgwEEgSqAQQyChAKCAYAAgwEmwgAEgSqAQQyCiYKBAYAAg0SBq4BArQBAxoWIFN0
b3BzIHRoZSBjb25uZWN0b3IuCgoNCgUGAAINARIErgEGEwoNCgUGAAINAhIErgEUKAoNCgUG
AAINAxIErgEzSAoPCgUGAAINBBIGrwEEsgEGChMKCQYAAg0EsMq8IhIGrwEEsgEGCg0KBQYA
Ag0EEgSzAQQyChAKCAYAAg0EmwgAEgSzAQQyCi4KAgQAEga4AQDCAQEaICBSZXF1ZXN0IGZv
ciBHZXRDb25uZWN0Q2x1c3Rlci4KCgsKAwQAARIEuAEIIArDAQoEBAACABIGvAECwQEEGrIB
IFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgS2Fma2EgQ29ubmVjdCBjbHVzdGVyIHdob3Nl
IGNvbmZpZ3VyYXRpb24gdG8KIHJldHVybi4gU3RydWN0dXJlZCBsaWtlCiBgcHJvamVjdHMv
e3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2Nvbm5lY3RDbHVzdGVycy97Y29ubmVj
dF9jbHVzdGVyX2lkfWAuCgoNCgUEAAIABRIEvAECCAoNCgUEAAIAARIEvAEJDQoNCgUEAAIA
AxIEvAEQEQoPCgUEAAIACBIGvAESwQEDChAKCAQAAgAInAgAEgS9AQQqChEKBwQAAgAInwgS
Br4BBMABBQoxCgIEARIGxQEA7gEBGiMgUmVxdWVzdCBmb3IgQ3JlYXRlQ29ubmVjdENsdXN0
ZXIuCgoLCgMEAQESBMUBCCMKpAEKBAQBAgASBskBAs4BBBqTASBSZXF1aXJlZC4gVGhlIHBh
cmVudCBwcm9qZWN0L2xvY2F0aW9uIGluIHdoaWNoIHRvIGNyZWF0ZSB0aGUgS2Fma2EgQ29u
bmVjdAogY2x1c3Rlci4gU3RydWN0dXJlZCBsaWtlCiBgcHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97bG9jYXRpb259L2AuCgoNCgUEAQIABRIEyQECCAoNCgUEAQIAARIEyQEJDwoN
CgUEAQIAAxIEyQESEwoPCgUEAQIACBIGyQEUzgEDChAKCAQBAgAInAgAEgTKAQQqChEKBwQB
AgAInwgSBssBBM0BBQqvAgoEBAECARIE1gECSRqgAiBSZXF1aXJlZC4gVGhlIElEIHRvIHVz
ZSBmb3IgdGhlIENvbm5lY3QgY2x1c3Rlciwgd2hpY2ggd2lsbCBiZWNvbWUgdGhlCiBmaW5h
bCBjb21wb25lbnQgb2YgdGhlIGNsdXN0ZXIncyBuYW1lLiBUaGUgSUQgbXVzdCBiZSAxLTYz
IGNoYXJhY3RlcnMgbG9uZywKIGFuZCBtYXRjaCB0aGUgcmVndWxhciBleHByZXNzaW9uIGBb
YS16XShbLWEtejAtOV0qW2EtejAtOV0pP2AgdG8gY29tcGx5CiB3aXRoIFJGQyAxMDM1LgoK
IFRoaXMgdmFsdWUgaXMgc3RydWN0dXJlZCBsaWtlOiBgbXktY2x1c3Rlci1pZGAuCgoNCgUE
AQIBBRIE1gECCAoNCgUEAQIBARIE1gEJGwoNCgUEAQIBAxIE1gEeHwoNCgUEAQIBCBIE1gEg
SAoQCggEAQIBCJwIABIE1gEhRwptCgQEAQICEgTaAQJOGl8gUmVxdWlyZWQuIENvbmZpZ3Vy
YXRpb24gb2YgdGhlIEthZmthIENvbm5lY3QgY2x1c3RlciB0byBjcmVhdGUuIEl0cyBgbmFt
ZWAKIGZpZWxkIGlzIGlnbm9yZWQuCgoNCgUEAQICBhIE2gECEAoNCgUEAQICARIE2gERIAoN
CgUEAQICAxIE2gEjJAoNCgUEAQICCBIE2gElTQoQCggEAQICCJwIABIE2gEmTAr/BQoEBAEC
AxIG6gEC7QEEGu4FIE9wdGlvbmFsLiBBbiBvcHRpb25hbCByZXF1ZXN0IElEIHRvIGlkZW50
aWZ5IHJlcXVlc3RzLiBTcGVjaWZ5IGEgdW5pcXVlCiByZXF1ZXN0IElEIHRvIGF2b2lkIGR1
cGxpY2F0aW9uIG9mIHJlcXVlc3RzLiBJZiBhIHJlcXVlc3QgdGltZXMgb3V0IG9yCiBmYWls
cywgcmV0cnlpbmcgd2l0aCB0aGUgc2FtZSBJRCBhbGxvd3MgdGhlIHNlcnZlciB0byByZWNv
Z25pemUgdGhlCiBwcmV2aW91cyBhdHRlbXB0LiBGb3IgYXQgbGVhc3QgNjAgbWludXRlcywg
dGhlIHNlcnZlciBpZ25vcmVzIGR1cGxpY2F0ZQogcmVxdWVzdHMgYmVhcmluZyB0aGUgc2Ft
ZSBJRC4KCiBGb3IgZXhhbXBsZSwgY29uc2lkZXIgYSBzaXR1YXRpb24gd2hlcmUgeW91IG1h
a2UgYW4gaW5pdGlhbCByZXF1ZXN0IGFuZCB0aGUKIHJlcXVlc3QgdGltZXMgb3V0LiBJZiB5
b3UgbWFrZSB0aGUgcmVxdWVzdCBhZ2FpbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QgSUQKIHdp
dGhpbiA2MCBtaW51dGVzIG9mIHRoZSBsYXN0IHJlcXVlc3QsIHRoZSBzZXJ2ZXIgY2hlY2tz
IGlmIGFuIG9yaWdpbmFsCiBvcGVyYXRpb24gd2l0aCB0aGUgc2FtZSByZXF1ZXN0IElEIHdh
cyByZWNlaXZlZC4gSWYgc28sIHRoZSBzZXJ2ZXIgaWdub3JlcwogdGhlIHNlY29uZCByZXF1
ZXN0LgoKIFRoZSByZXF1ZXN0IElEIG11c3QgYmUgYSB2YWxpZCBVVUlELiBBIHplcm8gVVVJ
RCBpcyBub3Qgc3VwcG9ydGVkCiAoMDAwMDAwMDAtMDAwMC0wMDAwLTAwMDAtMDAwMDAwMDAw
MDAwKS4KCg0KBQQBAgMFEgTqAQIICg0KBQQBAgMBEgTqAQkTCg0KBQQBAgMDEgTqARYXCg8K
BQQBAgMIEgbqARjtAQMKEwoLBAECAwjM8fmKAQESBOsBBCoKEAoIBAECAwicCAASBOwBBCoK
MQoCBAISBvEBAJACARojIFJlcXVlc3QgZm9yIFVwZGF0ZUNvbm5lY3RDbHVzdGVyLgoKCwoD
BAIBEgTxAQgjCs4CCgQEAgIAEgb3AQL4AS8avQIgUmVxdWlyZWQuIEZpZWxkIG1hc2sgaXMg
dXNlZCB0byBzcGVjaWZ5IHRoZSBmaWVsZHMgdG8gYmUgb3ZlcndyaXR0ZW4gaW4gdGhlCiBj
bHVzdGVyIHJlc291cmNlIGJ5IHRoZSB1cGRhdGUuIFRoZSBmaWVsZHMgc3BlY2lmaWVkIGlu
IHRoZSB1cGRhdGVfbWFzayBhcmUKIHJlbGF0aXZlIHRvIHRoZSByZXNvdXJjZSwgbm90IHRo
ZSBmdWxsIHJlcXVlc3QuIEEgZmllbGQgd2lsbCBiZSBvdmVyd3JpdHRlbgogaWYgaXQgaXMg
aW4gdGhlIG1hc2suIFRoZSBtYXNrIGlzIHJlcXVpcmVkIGFuZCBhIHZhbHVlIG9mICogd2ls
bCB1cGRhdGUgYWxsCiBmaWVsZHMuCgoNCgUEAgIABhIE9wECGwoNCgUEAgIAARIE9wEcJwoN
CgUEAgIAAxIE9wEqKwoNCgUEAgIACBIE+AEGLgoQCggEAgIACJwIABIE+AEHLQpjCgQEAgIB
EgT8AQJOGlUgUmVxdWlyZWQuIFRoZSBLYWZrYSBDb25uZWN0IGNsdXN0ZXIgdG8gdXBkYXRl
LiBJdHMgYG5hbWVgIGZpZWxkIG11c3QgYmUKIHBvcHVsYXRlZC4KCg0KBQQCAgEGEgT8AQIQ
Cg0KBQQCAgEBEgT8AREgCg0KBQQCAgEDEgT8ASMkCg0KBQQCAgEIEgT8ASVNChAKCAQCAgEI
nAgAEgT8ASZMCv8FCgQEAgICEgaMAgKPAgQa7gUgT3B0aW9uYWwuIEFuIG9wdGlvbmFsIHJl
cXVlc3QgSUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMuIFNwZWNpZnkgYSB1bmlxdWUKIHJlcXVl
c3QgSUQgdG8gYXZvaWQgZHVwbGljYXRpb24gb2YgcmVxdWVzdHMuIElmIGEgcmVxdWVzdCB0
aW1lcyBvdXQgb3IKIGZhaWxzLCByZXRyeWluZyB3aXRoIHRoZSBzYW1lIElEIGFsbG93cyB0
aGUgc2VydmVyIHRvIHJlY29nbml6ZSB0aGUKIHByZXZpb3VzIGF0dGVtcHQuIEZvciBhdCBs
ZWFzdCA2MCBtaW51dGVzLCB0aGUgc2VydmVyIGlnbm9yZXMgZHVwbGljYXRlCiByZXF1ZXN0
cyBiZWFyaW5nIHRoZSBzYW1lIElELgoKIEZvciBleGFtcGxlLCBjb25zaWRlciBhIHNpdHVh
dGlvbiB3aGVyZSB5b3UgbWFrZSBhbiBpbml0aWFsIHJlcXVlc3QgYW5kIHRoZQogcmVxdWVz
dCB0aW1lcyBvdXQuIElmIHlvdSBtYWtlIHRoZSByZXF1ZXN0IGFnYWluIHdpdGggdGhlIHNh
bWUgcmVxdWVzdCBJRAogd2l0aGluIDYwIG1pbnV0ZXMgb2YgdGhlIGxhc3QgcmVxdWVzdCwg
dGhlIHNlcnZlciBjaGVja3MgaWYgYW4gb3JpZ2luYWwKIG9wZXJhdGlvbiB3aXRoIHRoZSBz
YW1lIHJlcXVlc3QgSUQgd2FzIHJlY2VpdmVkLiBJZiBzbywgdGhlIHNlcnZlciBpZ25vcmVz
CiB0aGUgc2Vjb25kIHJlcXVlc3QuCgogVGhlIHJlcXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlk
IFVVSUQuIEEgemVybyBVVUlEIGlzIG5vdCBzdXBwb3J0ZWQKICgwMDAwMDAwMC0wMDAwLTAw
MDAtMDAwMC0wMDAwMDAwMDAwMDApLgoKDQoFBAICAgUSBIwCAggKDQoFBAICAgESBIwCCRMK
DQoFBAICAgMSBIwCFhcKDwoFBAICAggSBowCGI8CAwoTCgsEAgICCMzx+YoBARIEjQIEKgoQ
CggEAgICCJwIABIEjgIEKgoxCgIEAxIGkwIAsAIBGiMgUmVxdWVzdCBmb3IgRGVsZXRlQ29u
bmVjdENsdXN0ZXIuCgoLCgMEAwESBJMCCCMKrwEKBAQDAgASBpcCApwCBBqeASBSZXF1aXJl
ZC4gVGhlIG5hbWUgb2YgdGhlIEthZmthIENvbm5lY3QgY2x1c3RlciB0byBkZWxldGUuCiBT
dHJ1Y3R1cmVkIGxpa2UKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vY29ubmVjdENsdXN0ZXJzL3tjb25uZWN0X2NsdXN0ZXJfaWR9YC4KCg0KBQQDAgAFEgSX
AgIICg0KBQQDAgABEgSXAgkNCg0KBQQDAgADEgSXAhARCg8KBQQDAgAIEgaXAhKcAgMKEAoI
BAMCAAicCAASBJgCBCoKEQoHBAMCAAifCBIGmQIEmwIFCv8FCgQEAwIBEgasAgKvAgQa7gUg
T3B0aW9uYWwuIEFuIG9wdGlvbmFsIHJlcXVlc3QgSUQgdG8gaWRlbnRpZnkgcmVxdWVzdHMu
IFNwZWNpZnkgYSB1bmlxdWUKIHJlcXVlc3QgSUQgdG8gYXZvaWQgZHVwbGljYXRpb24gb2Yg
cmVxdWVzdHMuIElmIGEgcmVxdWVzdCB0aW1lcyBvdXQgb3IKIGZhaWxzLCByZXRyeWluZyB3
aXRoIHRoZSBzYW1lIElEIGFsbG93cyB0aGUgc2VydmVyIHRvIHJlY29nbml6ZSB0aGUKIHBy
ZXZpb3VzIGF0dGVtcHQuIEZvciBhdCBsZWFzdCA2MCBtaW51dGVzLCB0aGUgc2VydmVyIGln
bm9yZXMgZHVwbGljYXRlCiByZXF1ZXN0cyBiZWFyaW5nIHRoZSBzYW1lIElELgoKIEZvciBl
eGFtcGxlLCBjb25zaWRlciBhIHNpdHVhdGlvbiB3aGVyZSB5b3UgbWFrZSBhbiBpbml0aWFs
IHJlcXVlc3QgYW5kIHRoZQogcmVxdWVzdCB0aW1lcyBvdXQuIElmIHlvdSBtYWtlIHRoZSBy
ZXF1ZXN0IGFnYWluIHdpdGggdGhlIHNhbWUgcmVxdWVzdCBJRAogd2l0aGluIDYwIG1pbnV0
ZXMgb2YgdGhlIGxhc3QgcmVxdWVzdCwgdGhlIHNlcnZlciBjaGVja3MgaWYgYW4gb3JpZ2lu
YWwKIG9wZXJhdGlvbiB3aXRoIHRoZSBzYW1lIHJlcXVlc3QgSUQgd2FzIHJlY2VpdmVkLiBJ
ZiBzbywgdGhlIHNlcnZlciBpZ25vcmVzCiB0aGUgc2Vjb25kIHJlcXVlc3QuCgogVGhlIHJl
cXVlc3QgSUQgbXVzdCBiZSBhIHZhbGlkIFVVSUQuIEEgemVybyBVVUlEIGlzIG5vdCBzdXBw
b3J0ZWQKICgwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDApLgoKDQoFBAMC
AQUSBKwCAggKDQoFBAMCAQESBKwCCRMKDQoFBAMCAQMSBKwCFhcKDwoFBAMCAQgSBqwCGK8C
AwoTCgsEAwIBCMzx+YoBARIErQIEKgoQCggEAwIBCJwIABIErgIEKgowCgIEBBIGswIAzgIB
GiIgUmVxdWVzdCBmb3IgTGlzdENvbm5lY3RDbHVzdGVycy4KCgsKAwQEARIEswIIIgqdAQoE
BAQCABIGtgICuwIEGowBIFJlcXVpcmVkLiBUaGUgcGFyZW50IHByb2plY3QvbG9jYXRpb24g
d2hvc2UgQ29ubmVjdCBjbHVzdGVycyBhcmUgdG8gYmUKIGxpc3RlZC4gU3RydWN0dXJlZCBs
aWtlIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn1gLgoKDQoFBAQC
AAUSBLYCAggKDQoFBAQCAAESBLYCCQ8KDQoFBAQCAAMSBLYCEhMKDwoFBAQCAAgSBrYCFLsC
AwoQCggEBAIACJwIABIEtwIEKgoRCgcEBAIACJ8IEga4AgS6AgUKtQEKBAQEAgESBMACAj8a
pgEgT3B0aW9uYWwuIFRoZSBtYXhpbXVtIG51bWJlciBvZiBDb25uZWN0IGNsdXN0ZXJzIHRv
IHJldHVybi4gVGhlIHNlcnZpY2UgbWF5CiByZXR1cm4gZmV3ZXIgdGhhbiB0aGlzIHZhbHVl
LiBJZiB1bnNwZWNpZmllZCwgc2VydmVyIHdpbGwgcGljayBhbgogYXBwcm9wcmlhdGUgZGVm
YXVsdC4KCg0KBQQEAgEFEgTAAgIHCg0KBQQEAgEBEgTAAggRCg0KBQQEAgEDEgTAAhQVCg0K
BQQEAgEIEgTAAhY+ChAKCAQEAgEInAgAEgTAAhc9CokCCgQEBAICEgTHAgJBGvoBIE9wdGlv
bmFsLiBBIHBhZ2UgdG9rZW4sIHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cyBgTGlzdENvbm5l
Y3RDbHVzdGVyc2AKIGNhbGwuIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2Vx
dWVudCBwYWdlLgoKIFdoZW4gcGFnaW5hdGluZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgcHJv
dmlkZWQgdG8gYExpc3RDb25uZWN0Q2x1c3RlcnNgCiBtdXN0IG1hdGNoIHRoZSBjYWxsIHRo
YXQgcHJvdmlkZWQgdGhlIHBhZ2UgdG9rZW4uCgoNCgUEBAICBRIExwICCAoNCgUEBAICARIE
xwIJEwoNCgUEBAICAxIExwIWFwoNCgUEBAICCBIExwIYQAoQCggEBAICCJwIABIExwIZPwo7
CgQEBAIDEgTKAgI9Gi0gT3B0aW9uYWwuIEZpbHRlciBleHByZXNzaW9uIGZvciB0aGUgcmVz
dWx0LgoKDQoFBAQCAwUSBMoCAggKDQoFBAQCAwESBMoCCQ8KDQoFBAQCAwMSBMoCEhMKDQoF
BAQCAwgSBMoCFDwKEAoIBAQCAwicCAASBMoCFTsKOQoEBAQCBBIEzQICPxorIE9wdGlvbmFs
LiBPcmRlciBieSBmaWVsZHMgZm9yIHRoZSByZXN1bHQuCgoNCgUEBAIEBRIEzQICCAoNCgUE
BAIEARIEzQIJEQoNCgUEBAIEAxIEzQIUFQoNCgUEBAIECBIEzQIWPgoQCggEBAIECJwIABIE
zQIXPQoxCgIEBRIG0QIA2wIBGiMgUmVzcG9uc2UgZm9yIExpc3RDb25uZWN0Q2x1c3RlcnMu
CgoLCgMEBQESBNECCCMKRQoEBAUCABIE0wICLxo3IFRoZSBsaXN0IG9mIENvbm5lY3QgY2x1
c3RlcnMgaW4gdGhlIHJlcXVlc3RlZCBwYXJlbnQuCgoNCgUEBQIABBIE0wICCgoNCgUEBQIA
BhIE0wILGQoNCgUEBQIAARIE0wIaKgoNCgUEBQIAAxIE0wItLgqVAQoEBAUCARIE1wICHRqG
ASBBIHRva2VuIHRoYXQgY2FuIGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZl
IHRoZSBuZXh0IHBhZ2Ugb2YKIHJlc3VsdHMuIElmIHRoaXMgZmllbGQgaXMgb21pdHRlZCwg
dGhlcmUgYXJlIG5vIG1vcmUgcmVzdWx0cy4KCg0KBQQFAgEFEgTXAgIICg0KBQQFAgEBEgTX
AgkYCg0KBQQFAgEDEgTXAhscCjQKBAQFAgISBNoCAiIaJiBMb2NhdGlvbnMgdGhhdCBjb3Vs
ZCBub3QgYmUgcmVhY2hlZC4KCg0KBQQFAgIEEgTaAgIKCg0KBQQFAgIFEgTaAgsRCg0KBQQF
AgIBEgTaAhIdCg0KBQQFAgIDEgTaAiAhCikKAgQGEgbeAgDoAgEaGyBSZXF1ZXN0IGZvciBH
ZXRDb25uZWN0b3IuCgoLCgMEBgESBN4CCBsKyAEKBAQGAgASBuICAucCBBq3ASBSZXF1aXJl
ZC4gVGhlIG5hbWUgb2YgdGhlIGNvbm5lY3RvciB3aG9zZSBjb25maWd1cmF0aW9uIHRvIHJl
dHVybi4KIFN0cnVjdHVyZWQgbGlrZToKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9jb25uZWN0Q2x1c3RlcnMve2Nvbm5lY3RDbHVzdGVyfS9jb25uZWN0b3Jz
L3tjb25uZWN0b3J9CgoNCgUEBgIABRIE4gICCAoNCgUEBgIAARIE4gIJDQoNCgUEBgIAAxIE
4gIQEQoPCgUEBgIACBIG4gIS5wIDChAKCAQGAgAInAgAEgTjAgQqChEKBwQGAgAInwgSBuQC
BOYCBQosCgIEBxIG6wIAgAMBGh4gUmVxdWVzdCBmb3IgQ3JlYXRlQ29ubmVjdG9yLgoKCwoD
BAcBEgTrAggeCrsBCgQEBwIAEgbvAgL0AgQaqgEgUmVxdWlyZWQuIFRoZSBwYXJlbnQgQ29u
bmVjdCBjbHVzdGVyIGluIHdoaWNoIHRvIGNyZWF0ZSB0aGUgY29ubmVjdG9yLgogU3RydWN0
dXJlZCBsaWtlCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2Nv
bm5lY3RDbHVzdGVycy97Y29ubmVjdF9jbHVzdGVyX2lkfWAuCgoNCgUEBwIABRIE7wICCAoN
CgUEBwIAARIE7wIJDwoNCgUEBwIAAxIE7wISEwoPCgUEBwIACBIG7wIU9AIDChAKCAQHAgAI
nAgAEgTwAgQqChEKBwQHAgAInwgSBvECBPMCBQqtAgoEBAcCARIE/AICQxqeAiBSZXF1aXJl
ZC4gVGhlIElEIHRvIHVzZSBmb3IgdGhlIGNvbm5lY3Rvciwgd2hpY2ggd2lsbCBiZWNvbWUg
dGhlIGZpbmFsCiBjb21wb25lbnQgb2YgdGhlIGNvbm5lY3RvcidzIG5hbWUuIFRoZSBJRCBt
dXN0IGJlIDEtNjMgY2hhcmFjdGVycyBsb25nLCBhbmQKIG1hdGNoIHRoZSByZWd1bGFyIGV4
cHJlc3Npb24gYFthLXpdKFstYS16MC05XSpbYS16MC05XSk/YCB0byBjb21wbHkgd2l0aAog
UkZDIDEwMzUuCgogVGhpcyB2YWx1ZSBpcyBzdHJ1Y3R1cmVkIGxpa2U6IGBteS1jb25uZWN0
b3ItaWRgLgoKDQoFBAcCAQUSBPwCAggKDQoFBAcCAQESBPwCCRUKDQoFBAcCAQMSBPwCGBkK
DQoFBAcCAQgSBPwCGkIKEAoIBAcCAQicCAASBPwCG0EKMgoEBAcCAhIE/wICQxokIFJlcXVp
cmVkLiBUaGUgY29ubmVjdG9yIHRvIGNyZWF0ZS4KCg0KBQQHAgIGEgT/AgILCg0KBQQHAgIB
EgT/AgwVCg0KBQQHAgIDEgT/AhgZCg0KBQQHAgIIEgT/AhpCChAKCAQHAgIInAgAEgT/AhtB
CiwKAgQIEgaDAwCOAwEaHiBSZXF1ZXN0IGZvciBVcGRhdGVDb25uZWN0b3IuCgoLCgMECAES
BIMDCB4KzgIKBAQIAgASBokDAooDLxq9AiBSZXF1aXJlZC4gRmllbGQgbWFzayBpcyB1c2Vk
IHRvIHNwZWNpZnkgdGhlIGZpZWxkcyB0byBiZSBvdmVyd3JpdHRlbiBpbiB0aGUKIGNsdXN0
ZXIgcmVzb3VyY2UgYnkgdGhlIHVwZGF0ZS4gVGhlIGZpZWxkcyBzcGVjaWZpZWQgaW4gdGhl
IHVwZGF0ZV9tYXNrIGFyZQogcmVsYXRpdmUgdG8gdGhlIHJlc291cmNlLCBub3QgdGhlIGZ1
bGwgcmVxdWVzdC4gQSBmaWVsZCB3aWxsIGJlIG92ZXJ3cml0dGVuCiBpZiBpdCBpcyBpbiB0
aGUgbWFzay4gVGhlIG1hc2sgaXMgcmVxdWlyZWQgYW5kIGEgdmFsdWUgb2YgKiB3aWxsIHVw
ZGF0ZSBhbGwKIGZpZWxkcy4KCg0KBQQIAgAGEgSJAwIbCg0KBQQIAgABEgSJAxwnCg0KBQQI
AgADEgSJAyorCg0KBQQIAgAIEgSKAwYuChAKCAQIAgAInAgAEgSKAwctClYKBAQIAgESBI0D
AkMaSCBSZXF1aXJlZC4gVGhlIGNvbm5lY3RvciB0byB1cGRhdGUuIEl0cyBgbmFtZWAgZmll
bGQgbXVzdCBiZSBwb3B1bGF0ZWQuCgoNCgUECAIBBhIEjQMCCwoNCgUECAIBARIEjQMMFQoN
CgUECAIBAxIEjQMYGQoNCgUECAIBCBIEjQMaQgoQCggECAIBCJwIABIEjQMbQQosCgIECRIG
kQMAmwMBGh4gUmVxdWVzdCBmb3IgRGVsZXRlQ29ubmVjdG9yLgoKCwoDBAkBEgSRAwgeCrQB
CgQECQIAEgaVAwKaAwQaowEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBjb25uZWN0b3Ig
dG8gZGVsZXRlLgogU3RydWN0dXJlZCBsaWtlOgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0
aW9ucy97bG9jYXRpb259L2Nvbm5lY3RDbHVzdGVycy97Y29ubmVjdENsdXN0ZXJ9L2Nvbm5l
Y3RvcnMve2Nvbm5lY3Rvcn0KCg0KBQQJAgAFEgSVAwIICg0KBQQJAgABEgSVAwkNCg0KBQQJ
AgADEgSVAxARCg8KBQQJAgAIEgaVAxKaAwMKEAoIBAkCAAicCAASBJYDBCoKEQoHBAkCAAif
CBIGlwMEmQMFCisKAgQKEgaeAwC0AwEaHSBSZXF1ZXN0IGZvciBMaXN0Q29ubmVjdG9ycy4K
CgsKAwQKARIEngMIHQq8AQoEBAoCABIGogMCpwMEGqsBIFJlcXVpcmVkLiBUaGUgcGFyZW50
IENvbm5lY3QgY2x1c3RlciB3aG9zZSBjb25uZWN0b3JzIGFyZSB0byBiZSBsaXN0ZWQuCiBT
dHJ1Y3R1cmVkIGxpa2UKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vY29ubmVjdENsdXN0ZXJzL3tjb25uZWN0X2NsdXN0ZXJfaWR9YC4KCg0KBQQKAgAFEgSi
AwIICg0KBQQKAgABEgSiAwkPCg0KBQQKAgADEgSiAxITCg8KBQQKAgAIEgaiAxSnAwMKEAoI
BAoCAAicCAASBKMDBCoKEQoHBAoCAAifCBIGpAMEpgMFCq8BCgQECgIBEgSsAwI/GqABIE9w
dGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgY29ubmVjdG9ycyB0byByZXR1cm4uIFRo
ZSBzZXJ2aWNlIG1heQogcmV0dXJuIGZld2VyIHRoYW4gdGhpcyB2YWx1ZS4gSWYgdW5zcGVj
aWZpZWQsIHNlcnZlciB3aWxsIHBpY2sgYW4KIGFwcHJvcHJpYXRlIGRlZmF1bHQuCgoNCgUE
CgIBBRIErAMCBwoNCgUECgIBARIErAMIEQoNCgUECgIBAxIErAMUFQoNCgUECgIBCBIErAMW
PgoQCggECgIBCJwIABIErAMXPQr/AQoEBAoCAhIEswMCQRrwASBPcHRpb25hbC4gQSBwYWdl
IHRva2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RDb25uZWN0b3JzYCBjYWxs
LgogUHJvdmlkZSB0aGlzIHRvIHJldHJpZXZlIHRoZSBzdWJzZXF1ZW50IHBhZ2UuCgogV2hl
biBwYWdpbmF0aW5nLCBhbGwgb3RoZXIgcGFyYW1ldGVycyBwcm92aWRlZCB0byBgTGlzdENv
bm5lY3RvcnNgCiBtdXN0IG1hdGNoIHRoZSBjYWxsIHRoYXQgcHJvdmlkZWQgdGhlIHBhZ2Ug
dG9rZW4uCgoNCgUECgICBRIEswMCCAoNCgUECgICARIEswMJEwoNCgUECgICAxIEswMWFwoN
CgUECgICCBIEswMYQAoQCggECgICCJwIABIEswMZPwosCgIECxIGtwMAvgMBGh4gUmVzcG9u
c2UgZm9yIExpc3RDb25uZWN0b3JzLgoKCwoDBAsBEgS3AwgeCj8KBAQLAgASBLkDAiQaMSBU
aGUgbGlzdCBvZiBjb25uZWN0b3JzIGluIHRoZSByZXF1ZXN0ZWQgcGFyZW50LgoKDQoFBAsC
AAQSBLkDAgoKDQoFBAsCAAYSBLkDCxQKDQoFBAsCAAESBLkDFR8KDQoFBAsCAAMSBLkDIiMK
lQEKBAQLAgESBL0DAh0ahgEgQSB0b2tlbiB0aGF0IGNhbiBiZSBzZW50IGFzIGBwYWdlX3Rv
a2VuYCB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mCiByZXN1bHRzLiBJZiB0aGlzIGZp
ZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBtb3JlIHJlc3VsdHMuCgoNCgUECwIBBRIE
vQMCCAoNCgUECwIBARIEvQMJGAoNCgUECwIBAxIEvQMbHAorCgIEDBIGwQMAywMBGh0gUmVx
dWVzdCBmb3IgUGF1c2VDb25uZWN0b3IuCgoLCgMEDAESBMEDCB0KswEKBAQMAgASBsUDAsoD
BBqiASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGNvbm5lY3RvciB0byBwYXVzZS4KIFN0
cnVjdHVyZWQgbGlrZToKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9u
fS9jb25uZWN0Q2x1c3RlcnMve2Nvbm5lY3RDbHVzdGVyfS9jb25uZWN0b3JzL3tjb25uZWN0
b3J9CgoNCgUEDAIABRIExQMCCAoNCgUEDAIAARIExQMJDQoNCgUEDAIAAxIExQMQEQoPCgUE
DAIACBIGxQMSygMDChAKCAQMAgAInAgAEgTGAwQqChEKBwQMAgAInwgSBscDBMkDBQoqCgIE
DRIEzgMAIRoeIFJlc3BvbnNlIGZvciBQYXVzZUNvbm5lY3Rvci4KCgsKAwQNARIEzgMIHgos
CgIEDhIG0QMA2wMBGh4gUmVxdWVzdCBmb3IgUmVzdW1lQ29ubmVjdG9yLgoKCwoDBA4BEgTR
AwgeCrMBCgQEDgIAEgbVAwLaAwQaogEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBjb25u
ZWN0b3IgdG8gcGF1c2UuCiBTdHJ1Y3R1cmVkIGxpa2U6CiBwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vY29ubmVjdENsdXN0ZXJzL3tjb25uZWN0Q2x1c3Rlcn0v
Y29ubmVjdG9ycy97Y29ubmVjdG9yfQoKDQoFBA4CAAUSBNUDAggKDQoFBA4CAAESBNUDCQ0K
DQoFBA4CAAMSBNUDEBEKDwoFBA4CAAgSBtUDEtoDAwoQCggEDgIACJwIABIE1gMEKgoRCgcE
DgIACJ8IEgbXAwTZAwUKKwoCBA8SBN4DACIaHyBSZXNwb25zZSBmb3IgUmVzdW1lQ29ubmVj
dG9yLgoKCwoDBA8BEgTeAwgfCi0KAgQQEgbhAwDrAwEaHyBSZXF1ZXN0IGZvciBSZXN0YXJ0
Q29ubmVjdG9yLgoKCwoDBBABEgThAwgfCrUBCgQEEAIAEgblAwLqAwQapAEgUmVxdWlyZWQu
IFRoZSBuYW1lIG9mIHRoZSBjb25uZWN0b3IgdG8gcmVzdGFydC4KIFN0cnVjdHVyZWQgbGlr
ZToKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9jb25uZWN0Q2x1
c3RlcnMve2Nvbm5lY3RDbHVzdGVyfS9jb25uZWN0b3JzL3tjb25uZWN0b3J9CgoNCgUEEAIA
BRIE5QMCCAoNCgUEEAIAARIE5QMJDQoNCgUEEAIAAxIE5QMQEQoPCgUEEAIACBIG5QMS6gMD
ChAKCAQQAgAInAgAEgTmAwQqChEKBwQQAgAInwgSBucDBOkDBQosCgIEERIE7gMAIxogIFJl
c3BvbnNlIGZvciBSZXN0YXJ0Q29ubmVjdG9yLgoKCwoDBBEBEgTuAwggCioKAgQSEgbxAwD7
AwEaHCBSZXF1ZXN0IGZvciBTdG9wQ29ubmVjdG9yLgoKCwoDBBIBEgTxAwgcCrIBCgQEEgIA
Egb1AwL6AwQaoQEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBjb25uZWN0b3IgdG8gc3Rv
cC4KIFN0cnVjdHVyZWQgbGlrZToKIHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9jb25uZWN0Q2x1c3RlcnMve2Nvbm5lY3RDbHVzdGVyfS9jb25uZWN0b3JzL3tj
b25uZWN0b3J9CgoNCgUEEgIABRIE9QMCCAoNCgUEEgIAARIE9QMJDQoNCgUEEgIAAxIE9QMQ
EQoPCgUEEgIACBIG9QMS+gMDChAKCAQSAgAInAgAEgT2AwQqChEKBwQSAgAInwgSBvcDBPkD
BQopCgIEExIE/gMAIBodIFJlc3BvbnNlIGZvciBTdG9wQ29ubmVjdG9yLgoKCwoDBBMBEgT+
AwgdYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::GetConnectClusterRequest ===
    # Fields for GetConnectClusterRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::CreateConnectClusterRequest ===
    # Fields for CreateConnectClusterRequest
    # Field: parent Type: 9 ()
    # Field: connect_cluster_id Type: 9 ()
    # Field: connect_cluster Type: 11 (.google.cloud.managedkafka.v1.ConnectCluster)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::UpdateConnectClusterRequest ===
    # Fields for UpdateConnectClusterRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: connect_cluster Type: 11 (.google.cloud.managedkafka.v1.ConnectCluster)
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::DeleteConnectClusterRequest ===
    # Fields for DeleteConnectClusterRequest
    # Field: name Type: 9 ()
    # Field: request_id Type: 9 ()

# === Message: Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ListConnectClustersRequest ===
    # Fields for ListConnectClustersRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: order_by Type: 9 ()

# === Message: Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ListConnectClustersResponse ===
    # Fields for ListConnectClustersResponse
    # Field: connect_clusters Type: 11 (.google.cloud.managedkafka.v1.ConnectCluster)
    # Field: next_page_token Type: 9 ()
    # Field: unreachable Type: 9 ()

# === Message: Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::GetConnectorRequest ===
    # Fields for GetConnectorRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::CreateConnectorRequest ===
    # Fields for CreateConnectorRequest
    # Field: parent Type: 9 ()
    # Field: connector_id Type: 9 ()
    # Field: connector Type: 11 (.google.cloud.managedkafka.v1.Connector)

# === Message: Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::UpdateConnectorRequest ===
    # Fields for UpdateConnectorRequest
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)
    # Field: connector Type: 11 (.google.cloud.managedkafka.v1.Connector)

# === Message: Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::DeleteConnectorRequest ===
    # Fields for DeleteConnectorRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ListConnectorsRequest ===
    # Fields for ListConnectorsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ListConnectorsResponse ===
    # Fields for ListConnectorsResponse
    # Field: connectors Type: 11 (.google.cloud.managedkafka.v1.Connector)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::PauseConnectorRequest ===
    # Fields for PauseConnectorRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::PauseConnectorResponse ===
    # Fields for PauseConnectorResponse

# === Message: Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ResumeConnectorRequest ===
    # Fields for ResumeConnectorRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ResumeConnectorResponse ===
    # Fields for ResumeConnectorResponse

# === Message: Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::RestartConnectorRequest ===
    # Fields for RestartConnectorRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::RestartConnectorResponse ===
    # Fields for RestartConnectorResponse

# === Message: Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::StopConnectorRequest ===
    # Fields for StopConnectorRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::StopConnectorResponse ===
    # Fields for StopConnectorResponse

# === Service Client: Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ManagedKafkaConnectClient ===
package Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ManagedKafkaConnectClient;

=pod

=head2 Service Client: Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ManagedKafkaConnectClient

Client stub representing the remote C<ManagedKafkaConnect> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<managedkafka.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'managedkafka.googleapis.com:443' );

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

sub list_connect_clusters {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ListConnectClustersRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedkafka.v1.ManagedKafkaConnect',
        method         => 'ListConnectClusters',
        request        => $req,
        response_class => 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ListConnectClustersResponse',
    });
}

sub get_connect_cluster {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::GetConnectClusterRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedkafka.v1.ManagedKafkaConnect',
        method         => 'GetConnectCluster',
        request        => $req,
        response_class => 'Google::Cloud::Managedkafka::V1::Resources::ConnectCluster',
    });
}

sub create_connect_cluster {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::CreateConnectClusterRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedkafka.v1.ManagedKafkaConnect',
        method         => 'CreateConnectCluster',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub update_connect_cluster {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::UpdateConnectClusterRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedkafka.v1.ManagedKafkaConnect',
        method         => 'UpdateConnectCluster',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub delete_connect_cluster {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::DeleteConnectClusterRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedkafka.v1.ManagedKafkaConnect',
        method         => 'DeleteConnectCluster',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub list_connectors {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ListConnectorsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedkafka.v1.ManagedKafkaConnect',
        method         => 'ListConnectors',
        request        => $req,
        response_class => 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ListConnectorsResponse',
    });
}

sub get_connector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::GetConnectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedkafka.v1.ManagedKafkaConnect',
        method         => 'GetConnector',
        request        => $req,
        response_class => 'Google::Cloud::Managedkafka::V1::Resources::Connector',
    });
}

sub create_connector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::CreateConnectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedkafka.v1.ManagedKafkaConnect',
        method         => 'CreateConnector',
        request        => $req,
        response_class => 'Google::Cloud::Managedkafka::V1::Resources::Connector',
    });
}

sub update_connector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::UpdateConnectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedkafka.v1.ManagedKafkaConnect',
        method         => 'UpdateConnector',
        request        => $req,
        response_class => 'Google::Cloud::Managedkafka::V1::Resources::Connector',
    });
}

sub delete_connector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::DeleteConnectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedkafka.v1.ManagedKafkaConnect',
        method         => 'DeleteConnector',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub pause_connector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::PauseConnectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedkafka.v1.ManagedKafkaConnect',
        method         => 'PauseConnector',
        request        => $req,
        response_class => 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::PauseConnectorResponse',
    });
}

sub resume_connector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ResumeConnectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedkafka.v1.ManagedKafkaConnect',
        method         => 'ResumeConnector',
        request        => $req,
        response_class => 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ResumeConnectorResponse',
    });
}

sub restart_connector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::RestartConnectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedkafka.v1.ManagedKafkaConnect',
        method         => 'RestartConnector',
        request        => $req,
        response_class => 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::RestartConnectorResponse',
    });
}

sub stop_connector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::StopConnectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.managedkafka.v1.ManagedKafkaConnect',
        method         => 'StopConnector',
        request        => $req,
        response_class => 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::StopConnectorResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Managedkafka::V1::ManagedKafkaConnect - Compiled Protocol Buffers messages for google/cloud/managedkafka/v1/managed_kafka_connect.proto

=head1 SYNOPSIS

    use Google::Cloud::Managedkafka::V1::ManagedKafkaConnect;

    my $msg = Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::GetConnectClusterRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::GetConnectClusterRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/managedkafka/v1/managed_kafka_connect.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::GetConnectClusterRequest

Request for GetConnectCluster.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the Kafka Connect cluster whose configuration to
return. Structured like
`projects/{project}/locations/{location}/connectClusters/{connect_cluster_id}`.

=back

=head2 Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::CreateConnectClusterRequest

Request for CreateConnectCluster.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent project/location in which to create the Kafka Connect
cluster. Structured like
`projects/{project}/locations/{location}/`.

=item * C<< $msg->connect_cluster_id() >> / C<< $msg->connect_cluster_id($value) >>

Type: C<String>

Required. The ID to use for the Connect cluster, which will become the
final component of the cluster's name. The ID must be 1-63 characters long,
and match the regular expression `[a-z]([-a-z0-9]*[a-z0-9])?` to comply
with RFC 1035.

This value is structured like: `my-cluster-id`.

=item * C<< $msg->connect_cluster() >> / C<< $msg->connect_cluster($value) >>

Type: C<Message> (L<Google::Cloud::Managedkafka::V1::Resources::ConnectCluster>)

Required. Configuration of the Kafka Connect cluster to create. Its `name`
field is ignored.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID to avoid duplication of requests. If a request times out or
fails, retrying with the same ID allows the server to recognize the
previous attempt. For at least 60 minutes, the server ignores duplicate
requests bearing the same ID.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request ID
within 60 minutes of the last request, the server checks if an original
operation with the same request ID was received. If so, the server ignores
the second request.

The request ID must be a valid UUID. A zero UUID is not supported
(00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::UpdateConnectClusterRequest

Request for UpdateConnectCluster.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. Field mask is used to specify the fields to be overwritten in the
cluster resource by the update. The fields specified in the update_mask are
relative to the resource, not the full request. A field will be overwritten
if it is in the mask. The mask is required and a value of * will update all
fields.

=item * C<< $msg->connect_cluster() >> / C<< $msg->connect_cluster($value) >>

Type: C<Message> (L<Google::Cloud::Managedkafka::V1::Resources::ConnectCluster>)

Required. The Kafka Connect cluster to update. Its `name` field must be
populated.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID to avoid duplication of requests. If a request times out or
fails, retrying with the same ID allows the server to recognize the
previous attempt. For at least 60 minutes, the server ignores duplicate
requests bearing the same ID.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request ID
within 60 minutes of the last request, the server checks if an original
operation with the same request ID was received. If so, the server ignores
the second request.

The request ID must be a valid UUID. A zero UUID is not supported
(00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::DeleteConnectClusterRequest

Request for DeleteConnectCluster.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the Kafka Connect cluster to delete.
Structured like
`projects/{project}/locations/{location}/connectClusters/{connect_cluster_id}`.

=item * C<< $msg->request_id() >> / C<< $msg->request_id($value) >>

Type: C<String>

Optional. An optional request ID to identify requests. Specify a unique
request ID to avoid duplication of requests. If a request times out or
fails, retrying with the same ID allows the server to recognize the
previous attempt. For at least 60 minutes, the server ignores duplicate
requests bearing the same ID.

For example, consider a situation where you make an initial request and the
request times out. If you make the request again with the same request ID
within 60 minutes of the last request, the server checks if an original
operation with the same request ID was received. If so, the server ignores
the second request.

The request ID must be a valid UUID. A zero UUID is not supported
(00000000-0000-0000-0000-000000000000).

=back

=head2 Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ListConnectClustersRequest

Request for ListConnectClusters.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent project/location whose Connect clusters are to be
listed. Structured like `projects/{project}/locations/{location}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of Connect clusters to return. The service may
return fewer than this value. If unspecified, server will pick an
appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListConnectClusters`
call. Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListConnectClusters`
must match the call that provided the page token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. Filter expression for the result.

=item * C<< $msg->order_by() >> / C<< $msg->order_by($value) >>

Type: C<String>

Optional. Order by fields for the result.

=back

=head2 Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ListConnectClustersResponse

Response for ListConnectClusters.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->connect_clusters() >> / C<< $msg->connect_clusters($value) >>

Type: C<Message> (L<Google::Cloud::Managedkafka::V1::Resources::ConnectCluster>)

The list of Connect clusters in the requested parent.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as `page_token` to retrieve the next page of
results. If this field is omitted, there are no more results.

=item * C<< $msg->unreachable() >> / C<< $msg->unreachable($value) >>

Type: C<String>

Locations that could not be reached.

=back

=head2 Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::GetConnectorRequest

Request for GetConnector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the connector whose configuration to return.
Structured like:
projects/{project}/locations/{location}/connectClusters/{connectCluster}/connectors/{connector}

=back

=head2 Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::CreateConnectorRequest

Request for CreateConnector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent Connect cluster in which to create the connector.
Structured like
`projects/{project}/locations/{location}/connectClusters/{connect_cluster_id}`.

=item * C<< $msg->connector_id() >> / C<< $msg->connector_id($value) >>

Type: C<String>

Required. The ID to use for the connector, which will become the final
component of the connector's name. The ID must be 1-63 characters long, and
match the regular expression `[a-z]([-a-z0-9]*[a-z0-9])?` to comply with
RFC 1035.

This value is structured like: `my-connector-id`.

=item * C<< $msg->connector() >> / C<< $msg->connector($value) >>

Type: C<Message> (L<Google::Cloud::Managedkafka::V1::Resources::Connector>)

Required. The connector to create.

=back

=head2 Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::UpdateConnectorRequest

Request for UpdateConnector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

Required. Field mask is used to specify the fields to be overwritten in the
cluster resource by the update. The fields specified in the update_mask are
relative to the resource, not the full request. A field will be overwritten
if it is in the mask. The mask is required and a value of * will update all
fields.

=item * C<< $msg->connector() >> / C<< $msg->connector($value) >>

Type: C<Message> (L<Google::Cloud::Managedkafka::V1::Resources::Connector>)

Required. The connector to update. Its `name` field must be populated.

=back

=head2 Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::DeleteConnectorRequest

Request for DeleteConnector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the connector to delete.
Structured like:
projects/{project}/locations/{location}/connectClusters/{connectCluster}/connectors/{connector}

=back

=head2 Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ListConnectorsRequest

Request for ListConnectors.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent Connect cluster whose connectors are to be listed.
Structured like
`projects/{project}/locations/{location}/connectClusters/{connect_cluster_id}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of connectors to return. The service may
return fewer than this value. If unspecified, server will pick an
appropriate default.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous `ListConnectors` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListConnectors`
must match the call that provided the page token.

=back

=head2 Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ListConnectorsResponse

Response for ListConnectors.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->connectors() >> / C<< $msg->connectors($value) >>

Type: C<Message> (L<Google::Cloud::Managedkafka::V1::Resources::Connector>)

The list of connectors in the requested parent.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as `page_token` to retrieve the next page of
results. If this field is omitted, there are no more results.

=back

=head2 Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::PauseConnectorRequest

Request for PauseConnector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the connector to pause.
Structured like:
projects/{project}/locations/{location}/connectClusters/{connectCluster}/connectors/{connector}

=back

=head2 Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::PauseConnectorResponse

Response for PauseConnector.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ResumeConnectorRequest

Request for ResumeConnector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the connector to pause.
Structured like:
projects/{project}/locations/{location}/connectClusters/{connectCluster}/connectors/{connector}

=back

=head2 Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ResumeConnectorResponse

Response for ResumeConnector.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::RestartConnectorRequest

Request for RestartConnector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the connector to restart.
Structured like:
projects/{project}/locations/{location}/connectClusters/{connectCluster}/connectors/{connector}

=back

=head2 Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::RestartConnectorResponse

Response for RestartConnector.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::StopConnectorRequest

Request for StopConnector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the connector to stop.
Structured like:
projects/{project}/locations/{location}/connectClusters/{connectCluster}/connectors/{connector}

=back

=head2 Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::StopConnectorResponse

Response for StopConnector.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
