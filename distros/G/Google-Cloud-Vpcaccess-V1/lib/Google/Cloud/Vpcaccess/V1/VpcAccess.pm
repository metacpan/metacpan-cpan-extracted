package Google::Cloud::Vpcaccess::V1::VpcAccess;

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
    eval { require Google::Api::Resource };
    eval { require Google::Longrunning::Operations };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvdnBjYWNjZXNzL3YxL3ZwY19hY2Nlc3MucHJvdG8SGWdvb2dsZS5j
bG91ZC52cGNhY2Nlc3MudjEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2ds
ZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhln
b29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9u
cy5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLeBQoJQ29ubmVjdG9y
EhIKBG5hbWUYASABKAlSBG5hbWUSGAoHbmV0d29yaxgCIAEoCVIHbmV0d29yaxIiCg1pcF9j
aWRyX3JhbmdlGAMgASgJUgtpcENpZHJSYW5nZRJFCgVzdGF0ZRgEIAEoDjIqLmdvb2dsZS5j
bG91ZC52cGNhY2Nlc3MudjEuQ29ubmVjdG9yLlN0YXRlQgPgQQNSBXN0YXRlEiUKDm1pbl90
aHJvdWdocHV0GAUgASgFUg1taW5UaHJvdWdocHV0EiUKDm1heF90aHJvdWdocHV0GAYgASgF
Ug1tYXhUaHJvdWdocHV0EjIKEmNvbm5lY3RlZF9wcm9qZWN0cxgHIAMoCUID4EEDUhFjb25u
ZWN0ZWRQcm9qZWN0cxJDCgZzdWJuZXQYCCABKAsyKy5nb29nbGUuY2xvdWQudnBjYWNjZXNz
LnYxLkNvbm5lY3Rvci5TdWJuZXRSBnN1Ym5ldBIhCgxtYWNoaW5lX3R5cGUYCiABKAlSC21h
Y2hpbmVUeXBlEiMKDW1pbl9pbnN0YW5jZXMYCyABKAVSDG1pbkluc3RhbmNlcxIjCg1tYXhf
aW5zdGFuY2VzGAwgASgFUgxtYXhJbnN0YW5jZXMaOwoGU3VibmV0EhIKBG5hbWUYASABKAlS
BG5hbWUSHQoKcHJvamVjdF9pZBgCIAEoCVIJcHJvamVjdElkIl4KBVN0YXRlEhUKEVNUQVRF
X1VOU1BFQ0lGSUVEEAASCQoFUkVBRFkQARIMCghDUkVBVElORxACEgwKCERFTEVUSU5HEAMS
CQoFRVJST1IQBBIMCghVUERBVElORxAFOmfqQWQKInZwY2FjY2Vzcy5nb29nbGVhcGlzLmNv
bS9Db25uZWN0b3ISPnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9j
b25uZWN0b3JzL3tjb25uZWN0b3J9IswBChZDcmVhdGVDb25uZWN0b3JSZXF1ZXN0EkEKBnBh
cmVudBgBIAEoCUIp4EEC+kEjCiFsb2NhdGlvbnMuZ29vZ2xlYXBpcy5jb20vTG9jYXRpb25S
BnBhcmVudBImCgxjb25uZWN0b3JfaWQYAiABKAlCA+BBAlILY29ubmVjdG9ySWQSRwoJY29u
bmVjdG9yGAMgASgLMiQuZ29vZ2xlLmNsb3VkLnZwY2FjY2Vzcy52MS5Db25uZWN0b3JCA+BB
AlIJY29ubmVjdG9yIlUKE0dldENvbm5lY3RvclJlcXVlc3QSPgoEbmFtZRgBIAEoCUIq4EEC
+kEkCiJ2cGNhY2Nlc3MuZ29vZ2xlYXBpcy5jb20vQ29ubmVjdG9yUgRuYW1lIpYBChVMaXN0
Q29ubmVjdG9yc1JlcXVlc3QSQQoGcGFyZW50GAEgASgJQingQQL6QSMKIWxvY2F0aW9ucy5n
b29nbGVhcGlzLmNvbS9Mb2NhdGlvblIGcGFyZW50EhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFn
ZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuIoYBChZMaXN0Q29ubmVjdG9y
c1Jlc3BvbnNlEkQKCmNvbm5lY3RvcnMYASADKAsyJC5nb29nbGUuY2xvdWQudnBjYWNjZXNz
LnYxLkNvbm5lY3RvclIKY29ubmVjdG9ycxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5l
eHRQYWdlVG9rZW4iWAoWRGVsZXRlQ29ubmVjdG9yUmVxdWVzdBI+CgRuYW1lGAEgASgJQirg
QQL6QSQKInZwY2FjY2Vzcy5nb29nbGVhcGlzLmNvbS9Db25uZWN0b3JSBG5hbWUi8gEKEU9w
ZXJhdGlvbk1ldGFkYXRhEhsKBm1ldGhvZBgBIAEoCUID4EEDUgZtZXRob2QSQAoLY3JlYXRl
X3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRp
bWUSOgoIZW5kX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNS
B2VuZFRpbWUSQgoGdGFyZ2V0GAUgASgJQirgQQP6QSQKInZwY2FjY2Vzcy5nb29nbGVhcGlz
LmNvbS9Db25uZWN0b3JSBnRhcmdldDL8BgoQVnBjQWNjZXNzU2VydmljZRLoAQoPQ3JlYXRl
Q29ubmVjdG9yEjEuZ29vZ2xlLmNsb3VkLnZwY2FjY2Vzcy52MS5DcmVhdGVDb25uZWN0b3JS
ZXF1ZXN0Gh0uZ29vZ2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiKCAYLT5JMCOyIuL3YxL3tw
YXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlvbnMvKn0vY29ubmVjdG9yczoJY29ubmVjdG9y2kEd
cGFyZW50LGNvbm5lY3Rvcl9pZCxjb25uZWN0b3LKQR4KCUNvbm5lY3RvchIRT3BlcmF0aW9u
TWV0YWRhdGESowEKDEdldENvbm5lY3RvchIuLmdvb2dsZS5jbG91ZC52cGNhY2Nlc3MudjEu
R2V0Q29ubmVjdG9yUmVxdWVzdBokLmdvb2dsZS5jbG91ZC52cGNhY2Nlc3MudjEuQ29ubmVj
dG9yIj2C0+STAjASLi92MS97bmFtZT1wcm9qZWN0cy8qL2xvY2F0aW9ucy8qL2Nvbm5lY3Rv
cnMvKn3aQQRuYW1lErYBCg5MaXN0Q29ubmVjdG9ycxIwLmdvb2dsZS5jbG91ZC52cGNhY2Nl
c3MudjEuTGlzdENvbm5lY3RvcnNSZXF1ZXN0GjEuZ29vZ2xlLmNsb3VkLnZwY2FjY2Vzcy52
MS5MaXN0Q29ubmVjdG9yc1Jlc3BvbnNlIj+C0+STAjASLi92MS97cGFyZW50PXByb2plY3Rz
LyovbG9jYXRpb25zLyp9L2Nvbm5lY3RvcnPaQQZwYXJlbnQSzwEKD0RlbGV0ZUNvbm5lY3Rv
chIxLmdvb2dsZS5jbG91ZC52cGNhY2Nlc3MudjEuRGVsZXRlQ29ubmVjdG9yUmVxdWVzdBod
Lmdvb2dsZS5sb25ncnVubmluZy5PcGVyYXRpb24iaoLT5JMCMCouL3YxL3tuYW1lPXByb2pl
Y3RzLyovbG9jYXRpb25zLyovY29ubmVjdG9ycy8qfdpBBG5hbWXKQSoKFWdvb2dsZS5wcm90
b2J1Zi5FbXB0eRIRT3BlcmF0aW9uTWV0YWRhdGEaTMpBGHZwY2FjY2Vzcy5nb29nbGVhcGlz
LmNvbdJBLmh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1C
xQEKHWNvbS5nb29nbGUuY2xvdWQudnBjYWNjZXNzLnYxQg5WcGNBY2Nlc3NQcm90b1ABWjtj
bG91ZC5nb29nbGUuY29tL2dvL3ZwY2FjY2Vzcy9hcGl2MS92cGNhY2Nlc3NwYjt2cGNhY2Nl
c3NwYqoCGUdvb2dsZS5DbG91ZC5WcGNBY2Nlc3MuVjHKAhlHb29nbGVcQ2xvdWRcVnBjQWNj
ZXNzXFYx6gIcR29vZ2xlOjpDbG91ZDo6VnBjQWNjZXNzOjpWMUr7OQoHEgUOAPcBAQq8BAoB
DBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0
aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBt
YXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGlj
ZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBo
dHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVx
dWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3
YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBh
biAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0Yg
QU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2Ug
Zm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBs
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIgoJCgIDABIDEgAmCgkK
AgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWAC0KCQoCAwUSAxcAKQoI
CgEIEgMZADYKCQoCCCUSAxkANgoICgEIEgMaAFIKCQoCCAsSAxoAUgoICgEIEgMbACIKCQoC
CAoSAxsAIgoICgEIEgMcAC8KCQoCCAgSAxwALwoICgEIEgMdADYKCQoCCAESAx0ANgoICgEI
EgMeADYKCQoCCCkSAx4ANgoICgEIEgMfADUKCQoCCC0SAx8ANQrFAQoCBgASBCQAUgEauAEg
U2VydmVybGVzcyBWUEMgQWNjZXNzIEFQSSBhbGxvd3MgdXNlcnMgdG8gY3JlYXRlIGFuZCBt
YW5hZ2UgY29ubmVjdG9ycyBmb3IKIEFwcCBFbmdpbmUsIENsb3VkIEZ1bmN0aW9ucyBhbmQg
Q2xvdWQgUnVuIHRvIGhhdmUgaW50ZXJuYWwgY29ubmVjdGlvbnMgdG8KIFZpcnR1YWwgUHJp
dmF0ZSBDbG91ZCBuZXR3b3Jrcy4KCgoKAwYAARIDJAgYCgoKAwYAAxIDJQJACgwKBQYAA5kI
EgMlAkAKCgoDBgADEgMmAlYKDAoFBgADmggSAyYCVgpQCgQGAAIAEgQpAjMDGkIgQ3JlYXRl
cyBhIFNlcnZlcmxlc3MgVlBDIEFjY2VzcyBjb25uZWN0b3IsIHJldHVybnMgYW4gb3BlcmF0
aW9uLgoKDAoFBgACAAESAykGFQoMCgUGAAIAAhIDKRYsCgwKBQYAAgADEgMpN1MKDQoFBgAC
AAQSBCoELQYKEQoJBgACAASwyrwiEgQqBC0GCgwKBQYAAgAEEgMuBEsKDwoIBgACAASbCAAS
Ay4ESwoNCgUGAAIABBIELwQyBgoPCgcGAAIABJkIEgQvBDIGCmoKBAYAAgESBDcCPAMaXCBH
ZXRzIGEgU2VydmVybGVzcyBWUEMgQWNjZXNzIGNvbm5lY3Rvci4gUmV0dXJucyBOT1RfRk9V
TkQgaWYgdGhlIHJlc291cmNlCiBkb2VzIG5vdCBleGlzdC4KCgwKBQYAAgEBEgM3BhIKDAoF
BgACAQISAzcTJgoMCgUGAAIBAxIDNzE6Cg0KBQYAAgEEEgQ4BDoGChEKCQYAAgEEsMq8IhIE
OAQ6BgoMCgUGAAIBBBIDOwQyCg8KCAYAAgEEmwgAEgM7BDIKNwoEBgACAhIEPwJEAxopIExp
c3RzIFNlcnZlcmxlc3MgVlBDIEFjY2VzcyBjb25uZWN0b3JzLgoKDAoFBgACAgESAz8GFAoM
CgUGAAICAhIDPxUqCgwKBQYAAgIDEgM/NUsKDQoFBgACAgQSBEAEQgYKEQoJBgACAgSwyrwi
EgRABEIGCgwKBQYAAgIEEgNDBDQKDwoIBgACAgSbCAASA0MENAptCgQGAAIDEgRIAlEDGl8g
RGVsZXRlcyBhIFNlcnZlcmxlc3MgVlBDIEFjY2VzcyBjb25uZWN0b3IuIFJldHVybnMgTk9U
X0ZPVU5EIGlmIHRoZQogcmVzb3VyY2UgZG9lcyBub3QgZXhpc3QuCgoMCgUGAAIDARIDSAYV
CgwKBQYAAgMCEgNIFiwKDAoFBgACAwMSA0g3UwoNCgUGAAIDBBIESQRLBgoRCgkGAAIDBLDK
vCISBEkESwYKDAoFBgACAwQSA0wEMgoPCggGAAIDBJsIABIDTAQyCg0KBQYAAgMEEgRNBFAG
Cg8KBwYAAgMEmQgSBE0EUAYKPwoCBAASBVUAnwEBGjIgRGVmaW5pdGlvbiBvZiBhIFNlcnZl
cmxlc3MgVlBDIEFjY2VzcyBjb25uZWN0b3IuCgoKCgMEAAESA1UIEQoLCgMEAAcSBFYCWQQK
DQoFBAAHnQgSBFYCWQQKJQoEBAAEABIEXAJuAxoXIFN0YXRlIG9mIGEgY29ubmVjdG9yLgoK
DAoFBAAEAAESA1wHDAofCgYEAAQAAgASA14EGhoQIEludmFsaWQgc3RhdGUuCgoOCgcEAAQA
AgABEgNeBBUKDgoHBAAEAAIAAhIDXhgZCkQKBgQABAACARIDYQQOGjUgQ29ubmVjdG9yIGlz
IGRlcGxveWVkIGFuZCByZWFkeSB0byByZWNlaXZlIHRyYWZmaWMuCgoOCgcEAAQAAgEBEgNh
BAkKDgoHBAAEAAIBAhIDYQwNCkkKBgQABAACAhIDZAQRGjogQW4gSW5zZXJ0IG9wZXJhdGlv
biBpcyBpbiBwcm9ncmVzcy4gVHJhbnNpZW50IGNvbmRpdGlvbi4KCg4KBwQABAACAgESA2QE
DAoOCgcEAAQAAgICEgNkDxAKSAoGBAAEAAIDEgNnBBEaOSBBIERlbGV0ZSBvcGVyYXRpb24g
aXMgaW4gcHJvZ3Jlc3MuIFRyYW5zaWVudCBjb25kaXRpb24uCgoOCgcEAAQAAgMBEgNnBAwK
DgoHBAAEAAIDAhIDZw8QCkoKBgQABAACBBIDagQOGjsgQ29ubmVjdG9yIGlzIGluIGEgYmFk
IHN0YXRlLCBtYW51YWwgZGVsZXRpb24gcmVjb21tZW5kZWQuCgoOCgcEAAQAAgQBEgNqBAkK
DgoHBAAEAAIEAhIDagwNCjAKBgQABAACBRIDbQQRGiEgVGhlIGNvbm5lY3RvciBpcyBiZWlu
ZyB1cGRhdGVkLgoKDgoHBAAEAAIFARIDbQQMCg4KBwQABAACBQISA20PEAo6CgQEAAMAEgRx
AnwDGiwgVGhlIHN1Ym5ldCBpbiB3aGljaCB0byBob3VzZSB0aGUgY29ubmVjdG9yCgoMCgUE
AAMAARIDcQoQCoMCCgYEAAMAAgASA3YEFBrzASBTdWJuZXQgbmFtZSAocmVsYXRpdmUsIG5v
dCBmdWxseSBxdWFsaWZpZWQpLgogRS5nLiBpZiB0aGUgZnVsbCBzdWJuZXQgc2VsZkxpbmsg
aXMKIGh0dHBzOi8vY29tcHV0ZS5nb29nbGVhcGlzLmNvbS9jb21wdXRlL3YxL3Byb2plY3Rz
L3twcm9qZWN0fS9yZWdpb25zL3tyZWdpb259L3N1Ym5ldHdvcmtzL3tzdWJuZXROYW1lfQog
dGhlIGNvcnJlY3QgaW5wdXQgZm9yIHRoaXMgZmllbGQgd291bGQgYmUge3N1Ym5ldE5hbWV9
CgoOCgcEAAMAAgAFEgN2BAoKDgoHBAADAAIAARIDdgsPCg4KBwQAAwACAAMSA3YSEwqgAQoG
BAADAAIBEgN7BBoakAEgUHJvamVjdCBpbiB3aGljaCB0aGUgc3VibmV0IGV4aXN0cy4KIElm
IG5vdCBzZXQsIHRoaXMgcHJvamVjdCBpcyBhc3N1bWVkIHRvIGJlIHRoZSBwcm9qZWN0IGZv
ciB3aGljaAogdGhlIGNvbm5lY3RvciBjcmVhdGUgcmVxdWVzdCB3YXMgaXNzdWVkLgoKDgoH
BAADAAIBBRIDewQKCg4KBwQAAwACAQESA3sLFQoOCgcEAAMAAgEDEgN7GBkKVQoEBAACABID
fwISGkggVGhlIHJlc291cmNlIG5hbWUgaW4gdGhlIGZvcm1hdCBgcHJvamVjdHMvKi9sb2Nh
dGlvbnMvKi9jb25uZWN0b3JzLypgLgoKDAoFBAACAAUSA38CCAoMCgUEAAIAARIDfwkNCgwK
BQQAAgADEgN/EBEKJgoEBAACARIEggECFRoYIE5hbWUgb2YgYSBWUEMgbmV0d29yay4KCg0K
BQQAAgEFEgSCAQIICg0KBQQAAgEBEgSCAQkQCg0KBQQAAgEDEgSCARMUCmoKBAQAAgISBIYB
AhsaXCBUaGUgcmFuZ2Ugb2YgaW50ZXJuYWwgYWRkcmVzc2VzIHRoYXQgZm9sbG93cyBSRkMg
NDYzMiBub3RhdGlvbi4KIEV4YW1wbGU6IGAxMC4xMzIuMC4wLzI4YC4KCg0KBQQAAgIFEgSG
AQIICg0KBQQAAgIBEgSGAQkWCg0KBQQAAgIDEgSGARkaCj8KBAQAAgMSBIkBAj4aMSBPdXRw
dXQgb25seS4gU3RhdGUgb2YgdGhlIFZQQyBhY2Nlc3MgY29ubmVjdG9yLgoKDQoFBAACAwYS
BIkBAgcKDQoFBAACAwESBIkBCA0KDQoFBAACAwMSBIkBEBEKDQoFBAACAwgSBIkBEj0KEAoI
BAACAwicCAASBIkBEzwKVAoEBAACBBIEjAECGxpGIE1pbmltdW0gdGhyb3VnaHB1dCBvZiB0
aGUgY29ubmVjdG9yIGluIE1icHMuIERlZmF1bHQgYW5kIG1pbiBpcyAyMDAuCgoNCgUEAAIE
BRIEjAECBwoNCgUEAAIEARIEjAEIFgoNCgUEAAIEAxIEjAEZGgpZCgQEAAIFEgSPAQIbGksg
TWF4aW11bSB0aHJvdWdocHV0IG9mIHRoZSBjb25uZWN0b3IgaW4gTWJwcy4gRGVmYXVsdCBp
cyAzMDAsIG1heCBpcyAxMDAwLgoKDQoFBAACBQUSBI8BAgcKDQoFBAACBQESBI8BCBYKDQoF
BAACBQMSBI8BGRoKQgoEBAACBhIEkgECVRo0IE91dHB1dCBvbmx5LiBMaXN0IG9mIHByb2pl
Y3RzIHVzaW5nIHRoZSBjb25uZWN0b3IuCgoNCgUEAAIGBBIEkgECCgoNCgUEAAIGBRIEkgEL
EQoNCgUEAAIGARIEkgESJAoNCgUEAAIGAxIEkgEnKAoNCgUEAAIGCBIEkgEpVAoQCggEAAIG
CJwIABIEkgEqUwpGCgQEAAIHEgSVAQIUGjggVGhlIHN1Ym5ldCBpbiB3aGljaCB0byBob3Vz
ZSB0aGUgVlBDIEFjY2VzcyBDb25uZWN0b3IuCgoNCgUEAAIHBhIElQECCAoNCgUEAAIHARIE
lQEJDwoNCgUEAAIHAxIElQESEwpVCgQEAAIIEgSYAQIbGkcgTWFjaGluZSB0eXBlIG9mIFZN
IEluc3RhbmNlIHVuZGVybHlpbmcgY29ubmVjdG9yLiBEZWZhdWx0IGlzIGUyLW1pY3JvCgoN
CgUEAAIIBRIEmAECCAoNCgUEAAIIARIEmAEJFQoNCgUEAAIIAxIEmAEYGgpZCgQEAAIJEgSb
AQIbGksgTWluaW11bSB2YWx1ZSBvZiBpbnN0YW5jZXMgaW4gYXV0b3NjYWxpbmcgZ3JvdXAg
dW5kZXJseWluZyB0aGUgY29ubmVjdG9yLgoKDQoFBAACCQUSBJsBAgcKDQoFBAACCQESBJsB
CBUKDQoFBAACCQMSBJsBGBoKWQoEBAACChIEngECGxpLIE1heGltdW0gdmFsdWUgb2YgaW5z
dGFuY2VzIGluIGF1dG9zY2FsaW5nIGdyb3VwIHVuZGVybHlpbmcgdGhlIGNvbm5lY3Rvci4K
Cg0KBQQAAgoFEgSeAQIHCg0KBQQAAgoBEgSeAQgVCg0KBQQAAgoDEgSeARgaCkcKAgQBEgai
AQCxAQEaOSBSZXF1ZXN0IGZvciBjcmVhdGluZyBhIFNlcnZlcmxlc3MgVlBDIEFjY2VzcyBj
b25uZWN0b3IuCgoLCgMEAQESBKIBCB4KlgEKBAQBAgASBqUBAqoBBBqFASBSZXF1aXJlZC4g
VGhlIHByb2plY3QgYW5kIGxvY2F0aW9uIGluIHdoaWNoIHRoZSBjb25maWd1cmF0aW9uIHNo
b3VsZCBiZSBjcmVhdGVkLAogc3BlY2lmaWVkIGluIHRoZSBmb3JtYXQgYHByb2plY3RzLyov
bG9jYXRpb25zLypgLgoKDQoFBAECAAUSBKUBAggKDQoFBAECAAESBKUBCQ8KDQoFBAECAAMS
BKUBEhMKDwoFBAECAAgSBqUBFKoBAwoQCggEAQIACJwIABIEpgEEKgoRCgcEAQIACJ8IEgan
AQSpAQUKOwoEBAECARIErQECQxotIFJlcXVpcmVkLiBUaGUgSUQgdG8gdXNlIGZvciB0aGlz
IGNvbm5lY3Rvci4KCg0KBQQBAgEFEgStAQIICg0KBQQBAgEBEgStAQkVCg0KBQQBAgEDEgSt
ARgZCg0KBQQBAgEIEgStARpCChAKCAQBAgEInAgAEgStARtBCi0KBAQBAgISBLABAkMaHyBS
ZXF1aXJlZC4gUmVzb3VyY2UgdG8gY3JlYXRlLgoKDQoFBAECAgYSBLABAgsKDQoFBAECAgES
BLABDBUKDQoFBAECAgMSBLABGBkKDQoFBAECAggSBLABGkIKEAoIBAECAgicCAASBLABG0EK
RgoCBAISBrQBALwBARo4IFJlcXVlc3QgZm9yIGdldHRpbmcgYSBTZXJ2ZXJsZXNzIFZQQyBB
Y2Nlc3MgY29ubmVjdG9yLgoKCwoDBAIBEgS0AQgbCk0KBAQCAgASBrYBArsBBBo9IFJlcXVp
cmVkLiBOYW1lIG9mIGEgU2VydmVybGVzcyBWUEMgQWNjZXNzIGNvbm5lY3RvciB0byBnZXQu
CgoNCgUEAgIABRIEtgECCAoNCgUEAgIAARIEtgEJDQoNCgUEAgIAAxIEtgEQEQoPCgUEAgIA
CBIGtgESuwEDChAKCAQCAgAInAgAEgS3AQQqChEKBwQCAgAInwgSBrgBBLoBBQpTCgIEAxIG
vwEAzQEBGkUgUmVxdWVzdCBmb3IgbGlzdGluZyBTZXJ2ZXJsZXNzIFZQQyBBY2Nlc3MgY29u
bmVjdG9ycyBpbiBhIGxvY2F0aW9uLgoKCwoDBAMBEgS/AQgdClwKBAQDAgASBsEBAsYBBBpM
IFJlcXVpcmVkLiBUaGUgcHJvamVjdCBhbmQgbG9jYXRpb24gZnJvbSB3aGljaCB0aGUgcm91
dGVzIHNob3VsZCBiZSBsaXN0ZWQuCgoNCgUEAwIABRIEwQECCAoNCgUEAwIAARIEwQEJDwoN
CgUEAwIAAxIEwQESEwoPCgUEAwIACBIGwQEUxgEDChAKCAQDAgAInAgAEgTCAQQqChEKBwQD
AgAInwgSBsMBBMUBBQo/CgQEAwIBEgTJAQIWGjEgTWF4aW11bSBudW1iZXIgb2YgZnVuY3Rp
b25zIHRvIHJldHVybiBwZXIgY2FsbC4KCg0KBQQDAgEFEgTJAQIHCg0KBQQDAgEBEgTJAQgR
Cg0KBQQDAgEDEgTJARQVCiMKBAQDAgISBMwBAhgaFSBDb250aW51YXRpb24gdG9rZW4uCgoN
CgUEAwICBRIEzAECCAoNCgUEAwICARIEzAEJEwoNCgUEAwICAxIEzAEWFwpGCgIEBBIG0AEA
1gEBGjggUmVzcG9uc2UgZm9yIGxpc3RpbmcgU2VydmVybGVzcyBWUEMgQWNjZXNzIGNvbm5l
Y3RvcnMuCgoLCgMEBAESBNABCB4KOQoEBAQCABIE0gECJBorIExpc3Qgb2YgU2VydmVybGVz
cyBWUEMgQWNjZXNzIGNvbm5lY3RvcnMuCgoNCgUEBAIABBIE0gECCgoNCgUEBAIABhIE0gEL
FAoNCgUEBAIAARIE0gEVHwoNCgUEBAIAAxIE0gEiIwojCgQEBAIBEgTVAQIdGhUgQ29udGlu
dWF0aW9uIHRva2VuLgoKDQoFBAQCAQUSBNUBAggKDQoFBAQCAQESBNUBCRgKDQoFBAQCAQMS
BNUBGxwKRwoCBAUSBtkBAOEBARo5IFJlcXVlc3QgZm9yIGRlbGV0aW5nIGEgU2VydmVybGVz
cyBWUEMgQWNjZXNzIGNvbm5lY3Rvci4KCgsKAwQFARIE2QEIHgpQCgQEBQIAEgbbAQLgAQQa
QCBSZXF1aXJlZC4gTmFtZSBvZiBhIFNlcnZlcmxlc3MgVlBDIEFjY2VzcyBjb25uZWN0b3Ig
dG8gZGVsZXRlLgoKDQoFBAUCAAUSBNsBAggKDQoFBAUCAAESBNsBCQ0KDQoFBAUCAAMSBNsB
EBEKDwoFBAUCAAgSBtsBEuABAwoQCggEBQIACJwIABIE3AEEKgoRCgcEBQIACJ8IEgbdAQTf
AQUKOgoCBAYSBuQBAPcBARosIE1ldGFkYXRhIGZvciBnb29nbGUubG9uZ3J1bm5pbmcuT3Bl
cmF0aW9uLgoKCwoDBAYBEgTkAQgZCnwKBAQGAgASBOcBAkAabiBPdXRwdXQgb25seS4gTWV0
aG9kIHRoYXQgaW5pdGlhdGVkIHRoZSBvcGVyYXRpb24gZS5nLgogZ29vZ2xlLmNsb3VkLnZw
Y2FjY2Vzcy52MS5Db25uZWN0b3JzLkNyZWF0ZUNvbm5lY3Rvci4KCg0KBQQGAgAFEgTnAQII
Cg0KBQQGAgABEgTnAQkPCg0KBQQGAgADEgTnARITCg0KBQQGAgAIEgTnARQ/ChAKCAQGAgAI
nAgAEgTnARU+CkEKBAQGAgESBOoBAlgaMyBPdXRwdXQgb25seS4gVGltZSB3aGVuIHRoZSBv
cGVyYXRpb24gd2FzIGNyZWF0ZWQuCgoNCgUEBgIBBhIE6gECGwoNCgUEBgIBARIE6gEcJwoN
CgUEBgIBAxIE6gEqKwoNCgUEBgIBCBIE6gEsVwoQCggEBgIBCJwIABIE6gEtVgo/CgQEBgIC
EgTtAQJVGjEgT3V0cHV0IG9ubHkuIFRpbWUgd2hlbiB0aGUgb3BlcmF0aW9uIGNvbXBsZXRl
ZC4KCg0KBQQGAgIGEgTtAQIbCg0KBQQGAgIBEgTtARwkCg0KBQQGAgIDEgTtAScoCg0KBQQG
AgIIEgTtASlUChAKCAQGAgIInAgAEgTtASpTCpQBCgQEBgIDEgbxAQL2AQQagwEgT3V0cHV0
IG9ubHkuIE5hbWUgb2YgdGhlIHJlc291cmNlIHRoYXQgdGhpcyBvcGVyYXRpb24gaXMgYWN0
aW5nIG9uIGUuZy4KIHByb2plY3RzL215LXByb2plY3QvbG9jYXRpb25zL3VzLWNlbnRyYWwx
L2Nvbm5lY3RvcnMvdjEuCgoNCgUEBgIDBRIE8QECCAoNCgUEBgIDARIE8QEJDwoNCgUEBgID
AxIE8QESEwoPCgUEBgIDCBIG8QEU9gEDChAKCAQGAgMInAgAEgTyAQQtChEKBwQGAgMInwgS
BvMBBPUBBWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Vpcaccess::V1::VpcAccess::Connector ===
    # Fields for Connector
    # Field: name Type: 9 ()
    # Field: network Type: 9 ()
    # Field: ip_cidr_range Type: 9 ()
    # Field: state Type: 14 (.google.cloud.vpcaccess.v1.Connector.State)
    # Field: min_throughput Type: 5 ()
    # Field: max_throughput Type: 5 ()
    # Field: connected_projects Type: 9 ()
    # Field: subnet Type: 11 (.google.cloud.vpcaccess.v1.Connector.Subnet)
    # Field: machine_type Type: 9 ()
    # Field: min_instances Type: 5 ()
    # Field: max_instances Type: 5 ()

# Enum: Connector::State
our $Connector_STATE_UNSPECIFIED = 0;
our $Connector_READY = 1;
our $Connector_CREATING = 2;
our $Connector_DELETING = 3;
our $Connector_ERROR = 4;
our $Connector_UPDATING = 5;

# === Message: Google::Cloud::Vpcaccess::V1::VpcAccess::CreateConnectorRequest ===
    # Fields for CreateConnectorRequest
    # Field: parent Type: 9 ()
    # Field: connector_id Type: 9 ()
    # Field: connector Type: 11 (.google.cloud.vpcaccess.v1.Connector)

# === Message: Google::Cloud::Vpcaccess::V1::VpcAccess::GetConnectorRequest ===
    # Fields for GetConnectorRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Vpcaccess::V1::VpcAccess::ListConnectorsRequest ===
    # Fields for ListConnectorsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Vpcaccess::V1::VpcAccess::ListConnectorsResponse ===
    # Fields for ListConnectorsResponse
    # Field: connectors Type: 11 (.google.cloud.vpcaccess.v1.Connector)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Vpcaccess::V1::VpcAccess::DeleteConnectorRequest ===
    # Fields for DeleteConnectorRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Vpcaccess::V1::VpcAccess::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: method Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()

# === Service Client: Google::Cloud::Vpcaccess::V1::VpcAccess::VpcAccessServiceClient ===
package Google::Cloud::Vpcaccess::V1::VpcAccess::VpcAccessServiceClient;

=pod

=head2 Service Client: Google::Cloud::Vpcaccess::V1::VpcAccess::VpcAccessServiceClient

Client stub representing the remote C<VpcAccessService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<vpcaccess.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'vpcaccess.googleapis.com:443' );

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

sub create_connector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Vpcaccess::V1::VpcAccess::CreateConnectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.vpcaccess.v1.VpcAccessService',
        method         => 'CreateConnector',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

sub get_connector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Vpcaccess::V1::VpcAccess::GetConnectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.vpcaccess.v1.VpcAccessService',
        method         => 'GetConnector',
        request        => $req,
        response_class => 'Google::Cloud::Vpcaccess::V1::VpcAccess::Connector',
    });
}

sub list_connectors {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Vpcaccess::V1::VpcAccess::ListConnectorsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.vpcaccess.v1.VpcAccessService',
        method         => 'ListConnectors',
        request        => $req,
        response_class => 'Google::Cloud::Vpcaccess::V1::VpcAccess::ListConnectorsResponse',
    });
}

sub delete_connector {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Vpcaccess::V1::VpcAccess::DeleteConnectorRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.vpcaccess.v1.VpcAccessService',
        method         => 'DeleteConnector',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Vpcaccess::V1::VpcAccess - Compiled Protocol Buffers messages for google/cloud/vpcaccess/v1/vpc_access.proto

=head1 SYNOPSIS

    use Google::Cloud::Vpcaccess::V1::VpcAccess;

    my $msg = Google::Cloud::Vpcaccess::V1::VpcAccess::Connector->new({
        name => $name,
        network => $network,
        ip_cidr_range => $ip_cidr_range,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Vpcaccess::V1::VpcAccess::Connector->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/vpcaccess/v1/vpc_access.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Vpcaccess::V1::VpcAccess::Connector

Definition of a Serverless VPC Access connector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name in the format `projects/*/locations/*/connectors/*`.

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<String>

Name of a VPC network.

=item * C<< $msg->ip_cidr_range() >> / C<< $msg->ip_cidr_range($value) >>

Type: C<String>

The range of internal addresses that follows RFC 4632 notation.
Example: `10.132.0.0/28`.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Vpcaccess::V1::Connector::State>)

Output only. State of the VPC access connector.

=item * C<< $msg->min_throughput() >> / C<< $msg->min_throughput($value) >>

Type: C<Int32>

Minimum throughput of the connector in Mbps. Default and min is 200.

=item * C<< $msg->max_throughput() >> / C<< $msg->max_throughput($value) >>

Type: C<Int32>

Maximum throughput of the connector in Mbps. Default is 300, max is 1000.

=item * C<< $msg->connected_projects() >> / C<< $msg->connected_projects($value) >>

Type: C<String>

Output only. List of projects using the connector.

=item * C<< $msg->subnet() >> / C<< $msg->subnet($value) >>

Type: C<Message> (L<Google::Cloud::Vpcaccess::V1::VpcAccess::Connector::Subnet>)

The subnet in which to house the VPC Access Connector.

=item * C<< $msg->machine_type() >> / C<< $msg->machine_type($value) >>

Type: C<String>

Machine type of VM Instance underlying connector. Default is e2-micro

=item * C<< $msg->min_instances() >> / C<< $msg->min_instances($value) >>

Type: C<Int32>

Minimum value of instances in autoscaling group underlying the connector.

=item * C<< $msg->max_instances() >> / C<< $msg->max_instances($value) >>

Type: C<Int32>

Maximum value of instances in autoscaling group underlying the connector.

=back

=head3 Enum: Connector::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<READY> => C<1>

=item * C<CREATING> => C<2>

=item * C<DELETING> => C<3>

=item * C<ERROR> => C<4>

=item * C<UPDATING> => C<5>

=back

=head2 Google::Cloud::Vpcaccess::V1::VpcAccess::CreateConnectorRequest

Request for creating a Serverless VPC Access connector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location in which the configuration should be created,
specified in the format `projects/*/locations/*`.

=item * C<< $msg->connector_id() >> / C<< $msg->connector_id($value) >>

Type: C<String>

Required. The ID to use for this connector.

=item * C<< $msg->connector() >> / C<< $msg->connector($value) >>

Type: C<Message> (L<Google::Cloud::Vpcaccess::V1::VpcAccess::Connector>)

Required. Resource to create.

=back

=head2 Google::Cloud::Vpcaccess::V1::VpcAccess::GetConnectorRequest

Request for getting a Serverless VPC Access connector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of a Serverless VPC Access connector to get.

=back

=head2 Google::Cloud::Vpcaccess::V1::VpcAccess::ListConnectorsRequest

Request for listing Serverless VPC Access connectors in a location.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The project and location from which the routes should be listed.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Maximum number of functions to return per call.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Continuation token.

=back

=head2 Google::Cloud::Vpcaccess::V1::VpcAccess::ListConnectorsResponse

Response for listing Serverless VPC Access connectors.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->connectors() >> / C<< $msg->connectors($value) >>

Type: C<Message> (L<Google::Cloud::Vpcaccess::V1::VpcAccess::Connector>)

List of Serverless VPC Access connectors.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

Continuation token.

=back

=head2 Google::Cloud::Vpcaccess::V1::VpcAccess::DeleteConnectorRequest

Request for deleting a Serverless VPC Access connector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of a Serverless VPC Access connector to delete.

=back

=head2 Google::Cloud::Vpcaccess::V1::VpcAccess::OperationMetadata

Metadata for google.longrunning.Operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->method() >> / C<< $msg->method($value) >>

Type: C<String>

Output only. Method that initiated the operation e.g.
google.cloud.vpcaccess.v1.Connectors.CreateConnector.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time when the operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time when the operation completed.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Output only. Name of the resource that this operation is acting on e.g.
projects/my-project/locations/us-central1/connectors/v1.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Vpcaccess::V1::VpcAccess::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
