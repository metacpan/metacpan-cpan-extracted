package Google::Iam::V1::Policy;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Type::Expr };
    my $descriptor_b64 = <<'EOF';
Chpnb29nbGUvaWFtL3YxL3BvbGljeS5wcm90bxINZ29vZ2xlLmlhbS52MRoWZ29vZ2xlL3R5
cGUvZXhwci5wcm90byKrAQoGUG9saWN5EhgKB3ZlcnNpb24YASABKAVSB3ZlcnNpb24SMgoI
YmluZGluZ3MYBCADKAsyFi5nb29nbGUuaWFtLnYxLkJpbmRpbmdSCGJpbmRpbmdzEj8KDWF1
ZGl0X2NvbmZpZ3MYBiADKAsyGi5nb29nbGUuaWFtLnYxLkF1ZGl0Q29uZmlnUgxhdWRpdENv
bmZpZ3MSEgoEZXRhZxgDIAEoDFIEZXRhZyJoCgdCaW5kaW5nEhIKBHJvbGUYASABKAlSBHJv
bGUSGAoHbWVtYmVycxgCIAMoCVIHbWVtYmVycxIvCgljb25kaXRpb24YAyABKAsyES5nb29n
bGUudHlwZS5FeHByUgljb25kaXRpb24icgoLQXVkaXRDb25maWcSGAoHc2VydmljZRgBIAEo
CVIHc2VydmljZRJJChFhdWRpdF9sb2dfY29uZmlncxgDIAMoCzIdLmdvb2dsZS5pYW0udjEu
QXVkaXRMb2dDb25maWdSD2F1ZGl0TG9nQ29uZmlncyLRAQoOQXVkaXRMb2dDb25maWcSQAoI
bG9nX3R5cGUYASABKA4yJS5nb29nbGUuaWFtLnYxLkF1ZGl0TG9nQ29uZmlnLkxvZ1R5cGVS
B2xvZ1R5cGUSKQoQZXhlbXB0ZWRfbWVtYmVycxgCIAMoCVIPZXhlbXB0ZWRNZW1iZXJzIlIK
B0xvZ1R5cGUSGAoUTE9HX1RZUEVfVU5TUEVDSUZJRUQQABIOCgpBRE1JTl9SRUFEEAESDgoK
REFUQV9XUklURRACEg0KCURBVEFfUkVBRBADIqIBCgtQb2xpY3lEZWx0YRJCCg5iaW5kaW5n
X2RlbHRhcxgBIAMoCzIbLmdvb2dsZS5pYW0udjEuQmluZGluZ0RlbHRhUg1iaW5kaW5nRGVs
dGFzEk8KE2F1ZGl0X2NvbmZpZ19kZWx0YXMYAiADKAsyHy5nb29nbGUuaWFtLnYxLkF1ZGl0
Q29uZmlnRGVsdGFSEWF1ZGl0Q29uZmlnRGVsdGFzIt4BCgxCaW5kaW5nRGVsdGESOgoGYWN0
aW9uGAEgASgOMiIuZ29vZ2xlLmlhbS52MS5CaW5kaW5nRGVsdGEuQWN0aW9uUgZhY3Rpb24S
EgoEcm9sZRgCIAEoCVIEcm9sZRIWCgZtZW1iZXIYAyABKAlSBm1lbWJlchIvCgljb25kaXRp
b24YBCABKAsyES5nb29nbGUudHlwZS5FeHByUgljb25kaXRpb24iNQoGQWN0aW9uEhYKEkFD
VElPTl9VTlNQRUNJRklFRBAAEgcKA0FERBABEgoKBlJFTU9WRRACIucBChBBdWRpdENvbmZp
Z0RlbHRhEj4KBmFjdGlvbhgBIAEoDjImLmdvb2dsZS5pYW0udjEuQXVkaXRDb25maWdEZWx0
YS5BY3Rpb25SBmFjdGlvbhIYCgdzZXJ2aWNlGAIgASgJUgdzZXJ2aWNlEicKD2V4ZW1wdGVk
X21lbWJlchgDIAEoCVIOZXhlbXB0ZWRNZW1iZXISGQoIbG9nX3R5cGUYBCABKAlSB2xvZ1R5
cGUiNQoGQWN0aW9uEhYKEkFDVElPTl9VTlNQRUNJRklFRBAAEgcKA0FERBABEgoKBlJFTU9W
RRACQnwKEWNvbS5nb29nbGUuaWFtLnYxQgtQb2xpY3lQcm90b1ABWiljbG91ZC5nb29nbGUu
Y29tL2dvL2lhbS9hcGl2MS9pYW1wYjtpYW1wYvgBAaoCE0dvb2dsZS5DbG91ZC5JYW0uVjHK
AhNHb29nbGVcQ2xvdWRcSWFtXFYxSpp1CgcSBQ4AmQMBCrwECgEMEgMOABIysQQgQ29weXJp
Z2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5z
ZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMg
ZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBv
YnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAWCgkKAgMAEgMSACAKCAoBCBIDFAAfCgkKAggfEgMU
AB8KCAoBCBIDFQAwCgkKAgglEgMVADAKCAoBCBIDFgBACgkKAggLEgMWAEAKCAoBCBIDFwAi
CgkKAggKEgMXACIKCAoBCBIDGAAsCgkKAggIEgMYACwKCAoBCBIDGQAqCgkKAggBEgMZACoK
CAoBCBIDGgAwCgkKAggpEgMaADAKmhMKAgQAEgVlAJ0BARqMEyBBbiBJZGVudGl0eSBhbmQg
QWNjZXNzIE1hbmFnZW1lbnQgKElBTSkgcG9saWN5LCB3aGljaCBzcGVjaWZpZXMgYWNjZXNz
CiBjb250cm9scyBmb3IgR29vZ2xlIENsb3VkIHJlc291cmNlcy4KCgogQSBgUG9saWN5YCBp
cyBhIGNvbGxlY3Rpb24gb2YgYGJpbmRpbmdzYC4gQSBgYmluZGluZ2AgYmluZHMgb25lIG9y
IG1vcmUKIGBtZW1iZXJzYCwgb3IgcHJpbmNpcGFscywgdG8gYSBzaW5nbGUgYHJvbGVgLiBQ
cmluY2lwYWxzIGNhbiBiZSB1c2VyCiBhY2NvdW50cywgc2VydmljZSBhY2NvdW50cywgR29v
Z2xlIGdyb3VwcywgYW5kIGRvbWFpbnMgKHN1Y2ggYXMgRyBTdWl0ZSkuIEEKIGByb2xlYCBp
cyBhIG5hbWVkIGxpc3Qgb2YgcGVybWlzc2lvbnM7IGVhY2ggYHJvbGVgIGNhbiBiZSBhbiBJ
QU0gcHJlZGVmaW5lZAogcm9sZSBvciBhIHVzZXItY3JlYXRlZCBjdXN0b20gcm9sZS4KCiBG
b3Igc29tZSB0eXBlcyBvZiBHb29nbGUgQ2xvdWQgcmVzb3VyY2VzLCBhIGBiaW5kaW5nYCBj
YW4gYWxzbyBzcGVjaWZ5IGEKIGBjb25kaXRpb25gLCB3aGljaCBpcyBhIGxvZ2ljYWwgZXhw
cmVzc2lvbiB0aGF0IGFsbG93cyBhY2Nlc3MgdG8gYSByZXNvdXJjZQogb25seSBpZiB0aGUg
ZXhwcmVzc2lvbiBldmFsdWF0ZXMgdG8gYHRydWVgLiBBIGNvbmRpdGlvbiBjYW4gYWRkIGNv
bnN0cmFpbnRzCiBiYXNlZCBvbiBhdHRyaWJ1dGVzIG9mIHRoZSByZXF1ZXN0LCB0aGUgcmVz
b3VyY2UsIG9yIGJvdGguIFRvIGxlYXJuIHdoaWNoCiByZXNvdXJjZXMgc3VwcG9ydCBjb25k
aXRpb25zIGluIHRoZWlyIElBTSBwb2xpY2llcywgc2VlIHRoZQogW0lBTQogZG9jdW1lbnRh
dGlvbl0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2lhbS9oZWxwL2NvbmRpdGlvbnMvcmVz
b3VyY2UtcG9saWNpZXMpLgoKICoqSlNPTiBleGFtcGxlOioqCgogYGBgCiAgICAgewogICAg
ICAgImJpbmRpbmdzIjogWwogICAgICAgICB7CiAgICAgICAgICAgInJvbGUiOiAicm9sZXMv
cmVzb3VyY2VtYW5hZ2VyLm9yZ2FuaXphdGlvbkFkbWluIiwKICAgICAgICAgICAibWVtYmVy
cyI6IFsKICAgICAgICAgICAgICJ1c2VyOm1pa2VAZXhhbXBsZS5jb20iLAogICAgICAgICAg
ICAgImdyb3VwOmFkbWluc0BleGFtcGxlLmNvbSIsCiAgICAgICAgICAgICAiZG9tYWluOmdv
b2dsZS5jb20iLAogICAgICAgICAgICAgInNlcnZpY2VBY2NvdW50Om15LXByb2plY3QtaWRA
YXBwc3BvdC5nc2VydmljZWFjY291bnQuY29tIgogICAgICAgICAgIF0KICAgICAgICAgfSwK
ICAgICAgICAgewogICAgICAgICAgICJyb2xlIjogInJvbGVzL3Jlc291cmNlbWFuYWdlci5v
cmdhbml6YXRpb25WaWV3ZXIiLAogICAgICAgICAgICJtZW1iZXJzIjogWwogICAgICAgICAg
ICAgInVzZXI6ZXZlQGV4YW1wbGUuY29tIgogICAgICAgICAgIF0sCiAgICAgICAgICAgImNv
bmRpdGlvbiI6IHsKICAgICAgICAgICAgICJ0aXRsZSI6ICJleHBpcmFibGUgYWNjZXNzIiwK
ICAgICAgICAgICAgICJkZXNjcmlwdGlvbiI6ICJEb2VzIG5vdCBncmFudCBhY2Nlc3MgYWZ0
ZXIgU2VwIDIwMjAiLAogICAgICAgICAgICAgImV4cHJlc3Npb24iOiAicmVxdWVzdC50aW1l
IDwKICAgICAgICAgICAgIHRpbWVzdGFtcCgnMjAyMC0xMC0wMVQwMDowMDowMC4wMDBaJyki
LAogICAgICAgICAgIH0KICAgICAgICAgfQogICAgICAgXSwKICAgICAgICJldGFnIjogIkJ3
V1dqYTBZZkpBPSIsCiAgICAgICAidmVyc2lvbiI6IDMKICAgICB9CiBgYGAKCiAqKllBTUwg
ZXhhbXBsZToqKgoKIGBgYAogICAgIGJpbmRpbmdzOgogICAgIC0gbWVtYmVyczoKICAgICAg
IC0gdXNlcjptaWtlQGV4YW1wbGUuY29tCiAgICAgICAtIGdyb3VwOmFkbWluc0BleGFtcGxl
LmNvbQogICAgICAgLSBkb21haW46Z29vZ2xlLmNvbQogICAgICAgLSBzZXJ2aWNlQWNjb3Vu
dDpteS1wcm9qZWN0LWlkQGFwcHNwb3QuZ3NlcnZpY2VhY2NvdW50LmNvbQogICAgICAgcm9s
ZTogcm9sZXMvcmVzb3VyY2VtYW5hZ2VyLm9yZ2FuaXphdGlvbkFkbWluCiAgICAgLSBtZW1i
ZXJzOgogICAgICAgLSB1c2VyOmV2ZUBleGFtcGxlLmNvbQogICAgICAgcm9sZTogcm9sZXMv
cmVzb3VyY2VtYW5hZ2VyLm9yZ2FuaXphdGlvblZpZXdlcgogICAgICAgY29uZGl0aW9uOgog
ICAgICAgICB0aXRsZTogZXhwaXJhYmxlIGFjY2VzcwogICAgICAgICBkZXNjcmlwdGlvbjog
RG9lcyBub3QgZ3JhbnQgYWNjZXNzIGFmdGVyIFNlcCAyMDIwCiAgICAgICAgIGV4cHJlc3Np
b246IHJlcXVlc3QudGltZSA8IHRpbWVzdGFtcCgnMjAyMC0xMC0wMVQwMDowMDowMC4wMDBa
JykKICAgICBldGFnOiBCd1dXamEwWWZKQT0KICAgICB2ZXJzaW9uOiAzCiBgYGAKCiBGb3Ig
YSBkZXNjcmlwdGlvbiBvZiBJQU0gYW5kIGl0cyBmZWF0dXJlcywgc2VlIHRoZQogW0lBTSBk
b2N1bWVudGF0aW9uXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vaWFtL2RvY3MvKS4KCgoK
AwQAARIDZQgOCt4ICgQEAAIAEgN/AhQa0AggU3BlY2lmaWVzIHRoZSBmb3JtYXQgb2YgdGhl
IHBvbGljeS4KCiBWYWxpZCB2YWx1ZXMgYXJlIGAwYCwgYDFgLCBhbmQgYDNgLiBSZXF1ZXN0
cyB0aGF0IHNwZWNpZnkgYW4gaW52YWxpZCB2YWx1ZQogYXJlIHJlamVjdGVkLgoKIEFueSBv
cGVyYXRpb24gdGhhdCBhZmZlY3RzIGNvbmRpdGlvbmFsIHJvbGUgYmluZGluZ3MgbXVzdCBz
cGVjaWZ5IHZlcnNpb24KIGAzYC4gVGhpcyByZXF1aXJlbWVudCBhcHBsaWVzIHRvIHRoZSBm
b2xsb3dpbmcgb3BlcmF0aW9uczoKCiAqIEdldHRpbmcgYSBwb2xpY3kgdGhhdCBpbmNsdWRl
cyBhIGNvbmRpdGlvbmFsIHJvbGUgYmluZGluZwogKiBBZGRpbmcgYSBjb25kaXRpb25hbCBy
b2xlIGJpbmRpbmcgdG8gYSBwb2xpY3kKICogQ2hhbmdpbmcgYSBjb25kaXRpb25hbCByb2xl
IGJpbmRpbmcgaW4gYSBwb2xpY3kKICogUmVtb3ZpbmcgYW55IHJvbGUgYmluZGluZywgd2l0
aCBvciB3aXRob3V0IGEgY29uZGl0aW9uLCBmcm9tIGEgcG9saWN5CiAgIHRoYXQgaW5jbHVk
ZXMgY29uZGl0aW9ucwoKICoqSW1wb3J0YW50OioqIElmIHlvdSB1c2UgSUFNIENvbmRpdGlv
bnMsIHlvdSBtdXN0IGluY2x1ZGUgdGhlIGBldGFnYCBmaWVsZAogd2hlbmV2ZXIgeW91IGNh
bGwgYHNldElhbVBvbGljeWAuIElmIHlvdSBvbWl0IHRoaXMgZmllbGQsIHRoZW4gSUFNIGFs
bG93cwogeW91IHRvIG92ZXJ3cml0ZSBhIHZlcnNpb24gYDNgIHBvbGljeSB3aXRoIGEgdmVy
c2lvbiBgMWAgcG9saWN5LCBhbmQgYWxsIG9mCiB0aGUgY29uZGl0aW9ucyBpbiB0aGUgdmVy
c2lvbiBgM2AgcG9saWN5IGFyZSBsb3N0LgoKIElmIGEgcG9saWN5IGRvZXMgbm90IGluY2x1
ZGUgYW55IGNvbmRpdGlvbnMsIG9wZXJhdGlvbnMgb24gdGhhdCBwb2xpY3kgbWF5CiBzcGVj
aWZ5IGFueSB2YWxpZCB2ZXJzaW9uIG9yIGxlYXZlIHRoZSBmaWVsZCB1bnNldC4KCiBUbyBs
ZWFybiB3aGljaCByZXNvdXJjZXMgc3VwcG9ydCBjb25kaXRpb25zIGluIHRoZWlyIElBTSBw
b2xpY2llcywgc2VlIHRoZQogW0lBTQogZG9jdW1lbnRhdGlvbl0oaHR0cHM6Ly9jbG91ZC5n
b29nbGUuY29tL2lhbS9oZWxwL2NvbmRpdGlvbnMvcmVzb3VyY2UtcG9saWNpZXMpLgoKDAoF
BAACAAUSA38CBwoMCgUEAAIAARIDfwgPCgwKBQQAAgADEgN/EhMK5gQKBAQAAgESBIsBAiAa
1wQgQXNzb2NpYXRlcyBhIGxpc3Qgb2YgYG1lbWJlcnNgLCBvciBwcmluY2lwYWxzLCB3aXRo
IGEgYHJvbGVgLiBPcHRpb25hbGx5LAogbWF5IHNwZWNpZnkgYSBgY29uZGl0aW9uYCB0aGF0
IGRldGVybWluZXMgaG93IGFuZCB3aGVuIHRoZSBgYmluZGluZ3NgIGFyZQogYXBwbGllZC4g
RWFjaCBvZiB0aGUgYGJpbmRpbmdzYCBtdXN0IGNvbnRhaW4gYXQgbGVhc3Qgb25lIHByaW5j
aXBhbC4KCiBUaGUgYGJpbmRpbmdzYCBpbiBhIGBQb2xpY3lgIGNhbiByZWZlciB0byB1cCB0
byAxLDUwMCBwcmluY2lwYWxzOyB1cCB0byAyNTAKIG9mIHRoZXNlIHByaW5jaXBhbHMgY2Fu
IGJlIEdvb2dsZSBncm91cHMuIEVhY2ggb2NjdXJyZW5jZSBvZiBhIHByaW5jaXBhbAogY291
bnRzIHRvd2FyZHMgdGhlc2UgbGltaXRzLiBGb3IgZXhhbXBsZSwgaWYgdGhlIGBiaW5kaW5n
c2AgZ3JhbnQgNTAKIGRpZmZlcmVudCByb2xlcyB0byBgdXNlcjphbGljZUBleGFtcGxlLmNv
bWAsIGFuZCBub3QgdG8gYW55IG90aGVyCiBwcmluY2lwYWwsIHRoZW4geW91IGNhbiBhZGQg
YW5vdGhlciAxLDQ1MCBwcmluY2lwYWxzIHRvIHRoZSBgYmluZGluZ3NgIGluCiB0aGUgYFBv
bGljeWAuCgoNCgUEAAIBBBIEiwECCgoNCgUEAAIBBhIEiwELEgoNCgUEAAIBARIEiwETGwoN
CgUEAAIBAxIEiwEeHwpMCgQEAAICEgSOAQIpGj4gU3BlY2lmaWVzIGNsb3VkIGF1ZGl0IGxv
Z2dpbmcgY29uZmlndXJhdGlvbiBmb3IgdGhpcyBwb2xpY3kuCgoNCgUEAAICBBIEjgECCgoN
CgUEAAICBhIEjgELFgoNCgUEAAICARIEjgEXJAoNCgUEAAICAxIEjgEnKAqlBgoEBAACAxIE
nAECERqWBiBgZXRhZ2AgaXMgdXNlZCBmb3Igb3B0aW1pc3RpYyBjb25jdXJyZW5jeSBjb250
cm9sIGFzIGEgd2F5IHRvIGhlbHAKIHByZXZlbnQgc2ltdWx0YW5lb3VzIHVwZGF0ZXMgb2Yg
YSBwb2xpY3kgZnJvbSBvdmVyd3JpdGluZyBlYWNoIG90aGVyLgogSXQgaXMgc3Ryb25nbHkg
c3VnZ2VzdGVkIHRoYXQgc3lzdGVtcyBtYWtlIHVzZSBvZiB0aGUgYGV0YWdgIGluIHRoZQog
cmVhZC1tb2RpZnktd3JpdGUgY3ljbGUgdG8gcGVyZm9ybSBwb2xpY3kgdXBkYXRlcyBpbiBv
cmRlciB0byBhdm9pZCByYWNlCiBjb25kaXRpb25zOiBBbiBgZXRhZ2AgaXMgcmV0dXJuZWQg
aW4gdGhlIHJlc3BvbnNlIHRvIGBnZXRJYW1Qb2xpY3lgLCBhbmQKIHN5c3RlbXMgYXJlIGV4
cGVjdGVkIHRvIHB1dCB0aGF0IGV0YWcgaW4gdGhlIHJlcXVlc3QgdG8gYHNldElhbVBvbGlj
eWAgdG8KIGVuc3VyZSB0aGF0IHRoZWlyIGNoYW5nZSB3aWxsIGJlIGFwcGxpZWQgdG8gdGhl
IHNhbWUgdmVyc2lvbiBvZiB0aGUgcG9saWN5LgoKICoqSW1wb3J0YW50OioqIElmIHlvdSB1
c2UgSUFNIENvbmRpdGlvbnMsIHlvdSBtdXN0IGluY2x1ZGUgdGhlIGBldGFnYCBmaWVsZAog
d2hlbmV2ZXIgeW91IGNhbGwgYHNldElhbVBvbGljeWAuIElmIHlvdSBvbWl0IHRoaXMgZmll
bGQsIHRoZW4gSUFNIGFsbG93cwogeW91IHRvIG92ZXJ3cml0ZSBhIHZlcnNpb24gYDNgIHBv
bGljeSB3aXRoIGEgdmVyc2lvbiBgMWAgcG9saWN5LCBhbmQgYWxsIG9mCiB0aGUgY29uZGl0
aW9ucyBpbiB0aGUgdmVyc2lvbiBgM2AgcG9saWN5IGFyZSBsb3N0LgoKDQoFBAACAwUSBJwB
AgcKDQoFBAACAwESBJwBCAwKDQoFBAACAwMSBJwBDxAKQwoCBAESBqABAOABARo1IEFzc29j
aWF0ZXMgYG1lbWJlcnNgLCBvciBwcmluY2lwYWxzLCB3aXRoIGEgYHJvbGVgLgoKCwoDBAEB
EgSgAQgPCo8BCgQEAQIAEgSjAQISGoABIFJvbGUgdGhhdCBpcyBhc3NpZ25lZCB0byB0aGUg
bGlzdCBvZiBgbWVtYmVyc2AsIG9yIHByaW5jaXBhbHMuCiBGb3IgZXhhbXBsZSwgYHJvbGVz
L3ZpZXdlcmAsIGByb2xlcy9lZGl0b3JgLCBvciBgcm9sZXMvb3duZXJgLgoKDQoFBAECAAUS
BKMBAggKDQoFBAECAAESBKMBCQ0KDQoFBAECAAMSBKMBEBEK6g8KBAQBAgESBNEBAh4a2w8g
U3BlY2lmaWVzIHRoZSBwcmluY2lwYWxzIHJlcXVlc3RpbmcgYWNjZXNzIGZvciBhIEdvb2ds
ZSBDbG91ZCByZXNvdXJjZS4KIGBtZW1iZXJzYCBjYW4gaGF2ZSB0aGUgZm9sbG93aW5nIHZh
bHVlczoKCiAqIGBhbGxVc2Vyc2A6IEEgc3BlY2lhbCBpZGVudGlmaWVyIHRoYXQgcmVwcmVz
ZW50cyBhbnlvbmUgd2hvIGlzCiAgICBvbiB0aGUgaW50ZXJuZXQ7IHdpdGggb3Igd2l0aG91
dCBhIEdvb2dsZSBhY2NvdW50LgoKICogYGFsbEF1dGhlbnRpY2F0ZWRVc2Vyc2A6IEEgc3Bl
Y2lhbCBpZGVudGlmaWVyIHRoYXQgcmVwcmVzZW50cyBhbnlvbmUKICAgIHdobyBpcyBhdXRo
ZW50aWNhdGVkIHdpdGggYSBHb29nbGUgYWNjb3VudCBvciBhIHNlcnZpY2UgYWNjb3VudC4K
CiAqIGB1c2VyOntlbWFpbGlkfWA6IEFuIGVtYWlsIGFkZHJlc3MgdGhhdCByZXByZXNlbnRz
IGEgc3BlY2lmaWMgR29vZ2xlCiAgICBhY2NvdW50LiBGb3IgZXhhbXBsZSwgYGFsaWNlQGV4
YW1wbGUuY29tYCAuCgoKICogYHNlcnZpY2VBY2NvdW50OntlbWFpbGlkfWA6IEFuIGVtYWls
IGFkZHJlc3MgdGhhdCByZXByZXNlbnRzIGEgc2VydmljZQogICAgYWNjb3VudC4gRm9yIGV4
YW1wbGUsIGBteS1vdGhlci1hcHBAYXBwc3BvdC5nc2VydmljZWFjY291bnQuY29tYC4KCiAq
IGBncm91cDp7ZW1haWxpZH1gOiBBbiBlbWFpbCBhZGRyZXNzIHRoYXQgcmVwcmVzZW50cyBh
IEdvb2dsZSBncm91cC4KICAgIEZvciBleGFtcGxlLCBgYWRtaW5zQGV4YW1wbGUuY29tYC4K
CiAqIGBkZWxldGVkOnVzZXI6e2VtYWlsaWR9P3VpZD17dW5pcXVlaWR9YDogQW4gZW1haWwg
YWRkcmVzcyAocGx1cyB1bmlxdWUKICAgIGlkZW50aWZpZXIpIHJlcHJlc2VudGluZyBhIHVz
ZXIgdGhhdCBoYXMgYmVlbiByZWNlbnRseSBkZWxldGVkLiBGb3IKICAgIGV4YW1wbGUsIGBh
bGljZUBleGFtcGxlLmNvbT91aWQ9MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxYC4gSWYgdGhlIHVz
ZXIgaXMKICAgIHJlY292ZXJlZCwgdGhpcyB2YWx1ZSByZXZlcnRzIHRvIGB1c2VyOntlbWFp
bGlkfWAgYW5kIHRoZSByZWNvdmVyZWQgdXNlcgogICAgcmV0YWlucyB0aGUgcm9sZSBpbiB0
aGUgYmluZGluZy4KCiAqIGBkZWxldGVkOnNlcnZpY2VBY2NvdW50OntlbWFpbGlkfT91aWQ9
e3VuaXF1ZWlkfWA6IEFuIGVtYWlsIGFkZHJlc3MgKHBsdXMKICAgIHVuaXF1ZSBpZGVudGlm
aWVyKSByZXByZXNlbnRpbmcgYSBzZXJ2aWNlIGFjY291bnQgdGhhdCBoYXMgYmVlbiByZWNl
bnRseQogICAgZGVsZXRlZC4gRm9yIGV4YW1wbGUsCiAgICBgbXktb3RoZXItYXBwQGFwcHNw
b3QuZ3NlcnZpY2VhY2NvdW50LmNvbT91aWQ9MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxYC4KICAg
IElmIHRoZSBzZXJ2aWNlIGFjY291bnQgaXMgdW5kZWxldGVkLCB0aGlzIHZhbHVlIHJldmVy
dHMgdG8KICAgIGBzZXJ2aWNlQWNjb3VudDp7ZW1haWxpZH1gIGFuZCB0aGUgdW5kZWxldGVk
IHNlcnZpY2UgYWNjb3VudCByZXRhaW5zIHRoZQogICAgcm9sZSBpbiB0aGUgYmluZGluZy4K
CiAqIGBkZWxldGVkOmdyb3VwOntlbWFpbGlkfT91aWQ9e3VuaXF1ZWlkfWA6IEFuIGVtYWls
IGFkZHJlc3MgKHBsdXMgdW5pcXVlCiAgICBpZGVudGlmaWVyKSByZXByZXNlbnRpbmcgYSBH
b29nbGUgZ3JvdXAgdGhhdCBoYXMgYmVlbiByZWNlbnRseQogICAgZGVsZXRlZC4gRm9yIGV4
YW1wbGUsIGBhZG1pbnNAZXhhbXBsZS5jb20/dWlkPTEyMzQ1Njc4OTAxMjM0NTY3ODkwMWAu
IElmCiAgICB0aGUgZ3JvdXAgaXMgcmVjb3ZlcmVkLCB0aGlzIHZhbHVlIHJldmVydHMgdG8g
YGdyb3VwOntlbWFpbGlkfWAgYW5kIHRoZQogICAgcmVjb3ZlcmVkIGdyb3VwIHJldGFpbnMg
dGhlIHJvbGUgaW4gdGhlIGJpbmRpbmcuCgoKICogYGRvbWFpbjp7ZG9tYWlufWA6IFRoZSBH
IFN1aXRlIGRvbWFpbiAocHJpbWFyeSkgdGhhdCByZXByZXNlbnRzIGFsbCB0aGUKICAgIHVz
ZXJzIG9mIHRoYXQgZG9tYWluLiBGb3IgZXhhbXBsZSwgYGdvb2dsZS5jb21gIG9yIGBleGFt
cGxlLmNvbWAuCgoKCg0KBQQBAgEEEgTRAQIKCg0KBQQBAgEFEgTRAQsRCg0KBQQBAgEBEgTR
ARIZCg0KBQQBAgEDEgTRARwdCpUECgQEAQICEgTfAQIhGoYEIFRoZSBjb25kaXRpb24gdGhh
dCBpcyBhc3NvY2lhdGVkIHdpdGggdGhpcyBiaW5kaW5nLgoKIElmIHRoZSBjb25kaXRpb24g
ZXZhbHVhdGVzIHRvIGB0cnVlYCwgdGhlbiB0aGlzIGJpbmRpbmcgYXBwbGllcyB0byB0aGUK
IGN1cnJlbnQgcmVxdWVzdC4KCiBJZiB0aGUgY29uZGl0aW9uIGV2YWx1YXRlcyB0byBgZmFs
c2VgLCB0aGVuIHRoaXMgYmluZGluZyBkb2VzIG5vdCBhcHBseSB0bwogdGhlIGN1cnJlbnQg
cmVxdWVzdC4gSG93ZXZlciwgYSBkaWZmZXJlbnQgcm9sZSBiaW5kaW5nIG1pZ2h0IGdyYW50
IHRoZSBzYW1lCiByb2xlIHRvIG9uZSBvciBtb3JlIG9mIHRoZSBwcmluY2lwYWxzIGluIHRo
aXMgYmluZGluZy4KCiBUbyBsZWFybiB3aGljaCByZXNvdXJjZXMgc3VwcG9ydCBjb25kaXRp
b25zIGluIHRoZWlyIElBTSBwb2xpY2llcywgc2VlIHRoZQogW0lBTQogZG9jdW1lbnRhdGlv
bl0oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2lhbS9oZWxwL2NvbmRpdGlvbnMvcmVzb3Vy
Y2UtcG9saWNpZXMpLgoKDQoFBAECAgYSBN8BAhIKDQoFBAECAgESBN8BExwKDQoFBAECAgMS
BN8BHyAKnQwKAgQCEgaVAgCdAgEajgwgU3BlY2lmaWVzIHRoZSBhdWRpdCBjb25maWd1cmF0
aW9uIGZvciBhIHNlcnZpY2UuCiBUaGUgY29uZmlndXJhdGlvbiBkZXRlcm1pbmVzIHdoaWNo
IHBlcm1pc3Npb24gdHlwZXMgYXJlIGxvZ2dlZCwgYW5kIHdoYXQKIGlkZW50aXRpZXMsIGlm
IGFueSwgYXJlIGV4ZW1wdGVkIGZyb20gbG9nZ2luZy4KIEFuIEF1ZGl0Q29uZmlnIG11c3Qg
aGF2ZSBvbmUgb3IgbW9yZSBBdWRpdExvZ0NvbmZpZ3MuCgogSWYgdGhlcmUgYXJlIEF1ZGl0
Q29uZmlncyBmb3IgYm90aCBgYWxsU2VydmljZXNgIGFuZCBhIHNwZWNpZmljIHNlcnZpY2Us
CiB0aGUgdW5pb24gb2YgdGhlIHR3byBBdWRpdENvbmZpZ3MgaXMgdXNlZCBmb3IgdGhhdCBz
ZXJ2aWNlOiB0aGUgbG9nX3R5cGVzCiBzcGVjaWZpZWQgaW4gZWFjaCBBdWRpdENvbmZpZyBh
cmUgZW5hYmxlZCwgYW5kIHRoZSBleGVtcHRlZF9tZW1iZXJzIGluIGVhY2gKIEF1ZGl0TG9n
Q29uZmlnIGFyZSBleGVtcHRlZC4KCiBFeGFtcGxlIFBvbGljeSB3aXRoIG11bHRpcGxlIEF1
ZGl0Q29uZmlnczoKCiAgICAgewogICAgICAgImF1ZGl0X2NvbmZpZ3MiOiBbCiAgICAgICAg
IHsKICAgICAgICAgICAic2VydmljZSI6ICJhbGxTZXJ2aWNlcyIsCiAgICAgICAgICAgImF1
ZGl0X2xvZ19jb25maWdzIjogWwogICAgICAgICAgICAgewogICAgICAgICAgICAgICAibG9n
X3R5cGUiOiAiREFUQV9SRUFEIiwKICAgICAgICAgICAgICAgImV4ZW1wdGVkX21lbWJlcnMi
OiBbCiAgICAgICAgICAgICAgICAgInVzZXI6am9zZUBleGFtcGxlLmNvbSIKICAgICAgICAg
ICAgICAgXQogICAgICAgICAgICAgfSwKICAgICAgICAgICAgIHsKICAgICAgICAgICAgICAg
ImxvZ190eXBlIjogIkRBVEFfV1JJVEUiCiAgICAgICAgICAgICB9LAogICAgICAgICAgICAg
ewogICAgICAgICAgICAgICAibG9nX3R5cGUiOiAiQURNSU5fUkVBRCIKICAgICAgICAgICAg
IH0KICAgICAgICAgICBdCiAgICAgICAgIH0sCiAgICAgICAgIHsKICAgICAgICAgICAic2Vy
dmljZSI6ICJzYW1wbGVzZXJ2aWNlLmdvb2dsZWFwaXMuY29tIiwKICAgICAgICAgICAiYXVk
aXRfbG9nX2NvbmZpZ3MiOiBbCiAgICAgICAgICAgICB7CiAgICAgICAgICAgICAgICJsb2df
dHlwZSI6ICJEQVRBX1JFQUQiCiAgICAgICAgICAgICB9LAogICAgICAgICAgICAgewogICAg
ICAgICAgICAgICAibG9nX3R5cGUiOiAiREFUQV9XUklURSIsCiAgICAgICAgICAgICAgICJl
eGVtcHRlZF9tZW1iZXJzIjogWwogICAgICAgICAgICAgICAgICJ1c2VyOmFsaXlhQGV4YW1w
bGUuY29tIgogICAgICAgICAgICAgICBdCiAgICAgICAgICAgICB9CiAgICAgICAgICAgXQog
ICAgICAgICB9CiAgICAgICBdCiAgICAgfQoKIEZvciBzYW1wbGVzZXJ2aWNlLCB0aGlzIHBv
bGljeSBlbmFibGVzIERBVEFfUkVBRCwgREFUQV9XUklURSBhbmQgQURNSU5fUkVBRAogbG9n
Z2luZy4gSXQgYWxzbyBleGVtcHRzIGBqb3NlQGV4YW1wbGUuY29tYCBmcm9tIERBVEFfUkVB
RCBsb2dnaW5nLCBhbmQKIGBhbGl5YUBleGFtcGxlLmNvbWAgZnJvbSBEQVRBX1dSSVRFIGxv
Z2dpbmcuCgoLCgMEAgESBJUCCBMKywEKBAQCAgASBJkCAhUavAEgU3BlY2lmaWVzIGEgc2Vy
dmljZSB0aGF0IHdpbGwgYmUgZW5hYmxlZCBmb3IgYXVkaXQgbG9nZ2luZy4KIEZvciBleGFt
cGxlLCBgc3RvcmFnZS5nb29nbGVhcGlzLmNvbWAsIGBjbG91ZHNxbC5nb29nbGVhcGlzLmNv
bWAuCiBgYWxsU2VydmljZXNgIGlzIGEgc3BlY2lhbCB2YWx1ZSB0aGF0IGNvdmVycyBhbGwg
c2VydmljZXMuCgoNCgUEAgIABRIEmQICCAoNCgUEAgIAARIEmQIJEAoNCgUEAgIAAxIEmQIT
FApJCgQEAgIBEgScAgIwGjsgVGhlIGNvbmZpZ3VyYXRpb24gZm9yIGxvZ2dpbmcgb2YgZWFj
aCB0eXBlIG9mIHBlcm1pc3Npb24uCgoNCgUEAgIBBBIEnAICCgoNCgUEAgIBBhIEnAILGQoN
CgUEAgIBARIEnAIaKwoNCgUEAgIBAxIEnAIuLwrFAwoCBAMSBrICAMsCARq2AyBQcm92aWRl
cyB0aGUgY29uZmlndXJhdGlvbiBmb3IgbG9nZ2luZyBhIHR5cGUgb2YgcGVybWlzc2lvbnMu
CiBFeGFtcGxlOgoKICAgICB7CiAgICAgICAiYXVkaXRfbG9nX2NvbmZpZ3MiOiBbCiAgICAg
ICAgIHsKICAgICAgICAgICAibG9nX3R5cGUiOiAiREFUQV9SRUFEIiwKICAgICAgICAgICAi
ZXhlbXB0ZWRfbWVtYmVycyI6IFsKICAgICAgICAgICAgICJ1c2VyOmpvc2VAZXhhbXBsZS5j
b20iCiAgICAgICAgICAgXQogICAgICAgICB9LAogICAgICAgICB7CiAgICAgICAgICAgImxv
Z190eXBlIjogIkRBVEFfV1JJVEUiCiAgICAgICAgIH0KICAgICAgIF0KICAgICB9CgogVGhp
cyBlbmFibGVzICdEQVRBX1JFQUQnIGFuZCAnREFUQV9XUklURScgbG9nZ2luZywgd2hpbGUg
ZXhlbXB0aW5nCiBqb3NlQGV4YW1wbGUuY29tIGZyb20gREFUQV9SRUFEIGxvZ2dpbmcuCgoL
CgMEAwESBLICCBYKlQEKBAQDBAASBrUCAsECAxqEASBUaGUgbGlzdCBvZiB2YWxpZCBwZXJt
aXNzaW9uIHR5cGVzIGZvciB3aGljaCBsb2dnaW5nIGNhbiBiZSBjb25maWd1cmVkLgogQWRt
aW4gd3JpdGVzIGFyZSBhbHdheXMgbG9nZ2VkLCBhbmQgYXJlIG5vdCBjb25maWd1cmFibGUu
CgoNCgUEAwQAARIEtQIHDgo1CgYEAwQAAgASBLcCBB0aJSBEZWZhdWx0IGNhc2UuIFNob3Vs
ZCBuZXZlciBiZSB0aGlzLgoKDwoHBAMEAAIAARIEtwIEGAoPCgcEAwQAAgACEgS3AhscCj0K
BgQDBAACARIEugIEExotIEFkbWluIHJlYWRzLiBFeGFtcGxlOiBDbG91ZElBTSBnZXRJYW1Q
b2xpY3kKCg8KBwQDBAACAQESBLoCBA4KDwoHBAMEAAIBAhIEugIREgo9CgYEAwQAAgISBL0C
BBMaLSBEYXRhIHdyaXRlcy4gRXhhbXBsZTogQ2xvdWRTUUwgVXNlcnMgY3JlYXRlCgoPCgcE
AwQAAgIBEgS9AgQOCg8KBwQDBAACAgISBL0CERIKOgoGBAMEAAIDEgTAAgQSGiogRGF0YSBy
ZWFkcy4gRXhhbXBsZTogQ2xvdWRTUUwgVXNlcnMgbGlzdAoKDwoHBAMEAAIDARIEwAIEDQoP
CgcEAwQAAgMCEgTAAhARCjYKBAQDAgASBMQCAhcaKCBUaGUgbG9nIHR5cGUgdGhhdCB0aGlz
IGNvbmZpZyBlbmFibGVzLgoKDQoFBAMCAAYSBMQCAgkKDQoFBAMCAAESBMQCChIKDQoFBAMC
AAMSBMQCFRYKsAEKBAQDAgESBMoCAicaoQEgU3BlY2lmaWVzIHRoZSBpZGVudGl0aWVzIHRo
YXQgZG8gbm90IGNhdXNlIGxvZ2dpbmcgZm9yIHRoaXMgdHlwZSBvZgogcGVybWlzc2lvbi4K
IEZvbGxvd3MgdGhlIHNhbWUgZm9ybWF0IG9mCiBbQmluZGluZy5tZW1iZXJzXVtnb29nbGUu
aWFtLnYxLkJpbmRpbmcubWVtYmVyc10uCgoNCgUEAwIBBBIEygICCgoNCgUEAwIBBRIEygIL
EQoNCgUEAwIBARIEygISIgoNCgUEAwIBAxIEygIlJgo6CgIEBBIGzgIA1AIBGiwgVGhlIGRp
ZmZlcmVuY2UgZGVsdGEgYmV0d2VlbiB0d28gcG9saWNpZXMuCgoLCgMEBAESBM4CCBMKPAoE
BAQCABIE0AICKxouIFRoZSBkZWx0YSBmb3IgQmluZGluZ3MgYmV0d2VlbiB0d28gcG9saWNp
ZXMuCgoNCgUEBAIABBIE0AICCgoNCgUEBAIABhIE0AILFwoNCgUEBAIAARIE0AIYJgoNCgUE
BAIAAxIE0AIpKgpACgQEBAIBEgTTAgI0GjIgVGhlIGRlbHRhIGZvciBBdWRpdENvbmZpZ3Mg
YmV0d2VlbiB0d28gcG9saWNpZXMuCgoNCgUEBAIBBBIE0wICCgoNCgUEBAIBBhIE0wILGwoN
CgUEBAIBARIE0wIcLwoNCgUEBAIBAxIE0wIyMwqLAQoCBAUSBtgCAPUCARp9IE9uZSBkZWx0
YSBlbnRyeSBmb3IgQmluZGluZy4gRWFjaCBpbmRpdmlkdWFsIGNoYW5nZSAob25seSBvbmUg
bWVtYmVyIGluIGVhY2gKIGVudHJ5KSB0byBhIGJpbmRpbmcgd2lsbCBiZSBhIHNlcGFyYXRl
IGVudHJ5LgoKCwoDBAUBEgTYAggUCkgKBAQFBAASBtoCAuMCAxo4IFRoZSB0eXBlIG9mIGFj
dGlvbiBwZXJmb3JtZWQgb24gYSBCaW5kaW5nIGluIGEgcG9saWN5LgoKDQoFBAUEAAESBNoC
Bw0KHgoGBAUEAAIAEgTcAgQbGg4gVW5zcGVjaWZpZWQuCgoPCgcEBQQAAgABEgTcAgQWCg8K
BwQFBAACAAISBNwCGRoKKAoGBAUEAAIBEgTfAgQMGhggQWRkaXRpb24gb2YgYSBCaW5kaW5n
LgoKDwoHBAUEAAIBARIE3wIEBwoPCgcEBQQAAgECEgTfAgoLCicKBgQFBAACAhIE4gIEDxoX
IFJlbW92YWwgb2YgYSBCaW5kaW5nLgoKDwoHBAUEAAICARIE4gIECgoPCgcEBQQAAgICEgTi
Ag0OCkUKBAQFAgASBOcCAhQaNyBUaGUgYWN0aW9uIHRoYXQgd2FzIHBlcmZvcm1lZCBvbiBh
IEJpbmRpbmcuCiBSZXF1aXJlZAoKDQoFBAUCAAYSBOcCAggKDQoFBAUCAAESBOcCCQ8KDQoF
BAUCAAMSBOcCEhMKfQoEBAUCARIE7AICEhpvIFJvbGUgdGhhdCBpcyBhc3NpZ25lZCB0byBg
bWVtYmVyc2AuCiBGb3IgZXhhbXBsZSwgYHJvbGVzL3ZpZXdlcmAsIGByb2xlcy9lZGl0b3Jg
LCBvciBgcm9sZXMvb3duZXJgLgogUmVxdWlyZWQKCg0KBQQFAgEFEgTsAgIICg0KBQQFAgEB
EgTsAgkNCg0KBQQFAgEDEgTsAhARCocBCgQEBQICEgTxAgIUGnkgQSBzaW5nbGUgaWRlbnRp
dHkgcmVxdWVzdGluZyBhY2Nlc3MgZm9yIGEgR29vZ2xlIENsb3VkIHJlc291cmNlLgogRm9s
bG93cyB0aGUgc2FtZSBmb3JtYXQgb2YgQmluZGluZy5tZW1iZXJzLgogUmVxdWlyZWQKCg0K
BQQFAgIFEgTxAgIICg0KBQQFAgIBEgTxAgkPCg0KBQQFAgIDEgTxAhITCkMKBAQFAgMSBPQC
AiEaNSBUaGUgY29uZGl0aW9uIHRoYXQgaXMgYXNzb2NpYXRlZCB3aXRoIHRoaXMgYmluZGlu
Zy4KCg0KBQQFAgMGEgT0AgISCg0KBQQFAgMBEgT0AhMcCg0KBQQFAgMDEgT0Ah8gCp0BCgIE
BhIG+QIAmQMBGo4BIE9uZSBkZWx0YSBlbnRyeSBmb3IgQXVkaXRDb25maWcuIEVhY2ggaW5k
aXZpZHVhbCBjaGFuZ2UgKG9ubHkgb25lCiBleGVtcHRlZF9tZW1iZXIgaW4gZWFjaCBlbnRy
eSkgdG8gYSBBdWRpdENvbmZpZyB3aWxsIGJlIGEgc2VwYXJhdGUgZW50cnkuCgoLCgMEBgES
BPkCCBgKVQoEBAYEABIG+wIChAMDGkUgVGhlIHR5cGUgb2YgYWN0aW9uIHBlcmZvcm1lZCBv
biBhbiBhdWRpdCBjb25maWd1cmF0aW9uIGluIGEgcG9saWN5LgoKDQoFBAYEAAESBPsCBw0K
HgoGBAYEAAIAEgT9AgQbGg4gVW5zcGVjaWZpZWQuCgoPCgcEBgQAAgABEgT9AgQWCg8KBwQG
BAACAAISBP0CGRoKNQoGBAYEAAIBEgSAAwQMGiUgQWRkaXRpb24gb2YgYW4gYXVkaXQgY29u
ZmlndXJhdGlvbi4KCg8KBwQGBAACAQESBIADBAcKDwoHBAYEAAIBAhIEgAMKCwo0CgYEBgQA
AgISBIMDBA8aJCBSZW1vdmFsIG9mIGFuIGF1ZGl0IGNvbmZpZ3VyYXRpb24uCgoPCgcEBgQA
AgIBEgSDAwQKCg8KBwQGBAACAgISBIMDDQ4KXgoEBAYCABIEiAMCFBpQIFRoZSBhY3Rpb24g
dGhhdCB3YXMgcGVyZm9ybWVkIG9uIGFuIGF1ZGl0IGNvbmZpZ3VyYXRpb24gaW4gYSBwb2xp
Y3kuCiBSZXF1aXJlZAoKDQoFBAYCAAYSBIgDAggKDQoFBAYCAAESBIgDCQ8KDQoFBAYCAAMS
BIgDEhMK2gEKBAQGAgESBI4DAhUaywEgU3BlY2lmaWVzIGEgc2VydmljZSB0aGF0IHdhcyBj
b25maWd1cmVkIGZvciBDbG91ZCBBdWRpdCBMb2dnaW5nLgogRm9yIGV4YW1wbGUsIGBzdG9y
YWdlLmdvb2dsZWFwaXMuY29tYCwgYGNsb3Vkc3FsLmdvb2dsZWFwaXMuY29tYC4KIGBhbGxT
ZXJ2aWNlc2AgaXMgYSBzcGVjaWFsIHZhbHVlIHRoYXQgY292ZXJzIGFsbCBzZXJ2aWNlcy4K
IFJlcXVpcmVkCgoNCgUEBgIBBRIEjgMCCAoNCgUEBgIBARIEjgMJEAoNCgUEBgIBAxIEjgMT
FAqlAQoEBAYCAhIEkwMCHRqWASBBIHNpbmdsZSBpZGVudGl0eSB0aGF0IGlzIGV4ZW1wdGVk
IGZyb20gImRhdGEgYWNjZXNzIiBhdWRpdAogbG9nZ2luZyBmb3IgdGhlIGBzZXJ2aWNlYCBz
cGVjaWZpZWQgYWJvdmUuCiBGb2xsb3dzIHRoZSBzYW1lIGZvcm1hdCBvZiBCaW5kaW5nLm1l
bWJlcnMuCgoNCgUEBgICBRIEkwMCCAoNCgUEBgICARIEkwMJGAoNCgUEBgICAxIEkwMbHAqC
AQoEBAYCAxIEmAMCFhp0IFNwZWNpZmllcyB0aGUgbG9nX3R5cGUgdGhhdCB3YXMgYmUgZW5h
YmxlZC4gQURNSU5fQUNUSVZJVFkgaXMgYWx3YXlzCiBlbmFibGVkLCBhbmQgY2Fubm90IGJl
IGNvbmZpZ3VyZWQuCiBSZXF1aXJlZAoKDQoFBAYCAwUSBJgDAggKDQoFBAYCAwESBJgDCREK
DQoFBAYCAwMSBJgDFBViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Iam::V1::Policy::Policy ===
    # Fields for Policy
    # Field: version Type: 5 ()
    # Field: bindings Type: 11 (.google.iam.v1.Binding)
    # Field: audit_configs Type: 11 (.google.iam.v1.AuditConfig)
    # Field: etag Type: 12 ()

# === Message: Google::Iam::V1::Policy::Binding ===
    # Fields for Binding
    # Field: role Type: 9 ()
    # Field: members Type: 9 ()
    # Field: condition Type: 11 (.google.type.Expr)

# === Message: Google::Iam::V1::Policy::AuditConfig ===
    # Fields for AuditConfig
    # Field: service Type: 9 ()
    # Field: audit_log_configs Type: 11 (.google.iam.v1.AuditLogConfig)

# === Message: Google::Iam::V1::Policy::AuditLogConfig ===
    # Fields for AuditLogConfig
    # Field: log_type Type: 14 (.google.iam.v1.AuditLogConfig.LogType)
    # Field: exempted_members Type: 9 ()

# Enum: AuditLogConfig::LogType
our $AuditLogConfig_LOG_TYPE_UNSPECIFIED = 0;
our $AuditLogConfig_ADMIN_READ = 1;
our $AuditLogConfig_DATA_WRITE = 2;
our $AuditLogConfig_DATA_READ = 3;

# === Message: Google::Iam::V1::Policy::PolicyDelta ===
    # Fields for PolicyDelta
    # Field: binding_deltas Type: 11 (.google.iam.v1.BindingDelta)
    # Field: audit_config_deltas Type: 11 (.google.iam.v1.AuditConfigDelta)

# === Message: Google::Iam::V1::Policy::BindingDelta ===
    # Fields for BindingDelta
    # Field: action Type: 14 (.google.iam.v1.BindingDelta.Action)
    # Field: role Type: 9 ()
    # Field: member Type: 9 ()
    # Field: condition Type: 11 (.google.type.Expr)

# Enum: BindingDelta::Action
our $BindingDelta_ACTION_UNSPECIFIED = 0;
our $BindingDelta_ADD = 1;
our $BindingDelta_REMOVE = 2;

# === Message: Google::Iam::V1::Policy::AuditConfigDelta ===
    # Fields for AuditConfigDelta
    # Field: action Type: 14 (.google.iam.v1.AuditConfigDelta.Action)
    # Field: service Type: 9 ()
    # Field: exempted_member Type: 9 ()
    # Field: log_type Type: 9 ()

# Enum: AuditConfigDelta::Action
our $AuditConfigDelta_ACTION_UNSPECIFIED = 0;
our $AuditConfigDelta_ADD = 1;
our $AuditConfigDelta_REMOVE = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Iam::V1::Policy - Compiled Protocol Buffers messages for google/iam/v1/policy.proto

=head1 SYNOPSIS

    use Google::Iam::V1::Policy;

    my $msg = Google::Iam::V1::Policy::Policy->new({
        version => $version,
        bindings => $bindings,
        audit_configs => $audit_configs,
        etag => $etag,
    });

    # Read or update a field
    my $val = $msg->version();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Iam::V1::Policy::Policy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/iam/v1/policy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Iam::V1::Policy::Policy

An Identity and Access Management (IAM) policy, which specifies access
controls for Google Cloud resources.


A `Policy` is a collection of `bindings`. A `binding` binds one or more
`members`, or principals, to a single `role`. Principals can be user
accounts, service accounts, Google groups, and domains (such as G Suite). A
`role` is a named list of permissions; each `role` can be an IAM predefined
role or a user-created custom role.

For some types of Google Cloud resources, a `binding` can also specify a
`condition`, which is a logical expression that allows access to a resource
only if the expression evaluates to `true`. A condition can add constraints
based on attributes of the request, the resource, or both. To learn which
resources support conditions in their IAM policies, see the
[IAM
documentation](https://cloud.google.com/iam/help/conditions/resource-policies).

B<JSON example:>

```
    {
      "bindings": [
        {
          "role": "roles/resourcemanager.organizationAdmin",
          "members": [
            "user:mike@example.com",
            "group:admins@example.com",
            "domain:google.com",
            "serviceAccount:my-project-id@appspot.gserviceaccount.com"
          ]
        },
        {
          "role": "roles/resourcemanager.organizationViewer",
          "members": [
            "user:eve@example.com"
          ],
          "condition": {
            "title": "expirable access",
            "description": "Does not grant access after Sep 2020",
            "expression": "request.time <
            timestamp('2020-10-01T00:00:00.000Z')",
          }
        }
      ],
      "etag": "BwWWja0YfJA=",
      "version": 3
    }
```

B<YAML example:>

```
    bindings:
    - members:
      - user:mike@example.com
      - group:admins@example.com
      - domain:google.com
      - serviceAccount:my-project-id@appspot.gserviceaccount.com
      role: roles/resourcemanager.organizationAdmin
    - members:
      - user:eve@example.com
      role: roles/resourcemanager.organizationViewer
      condition:
        title: expirable access
        description: Does not grant access after Sep 2020
        expression: request.time < timestamp('2020-10-01T00:00:00.000Z')
    etag: BwWWja0YfJA=
    version: 3
```

For a description of IAM and its features, see the
[IAM documentation](https://cloud.google.com/iam/docs/).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<Int32>

Specifies the format of the policy.

Valid values are `0`, `1`, and `3`. Requests that specify an invalid value
are rejected.

Any operation that affects conditional role bindings must specify version
`3`. This requirement applies to the following operations:

* Getting a policy that includes a conditional role binding
* Adding a conditional role binding to a policy
* Changing a conditional role binding in a policy
* Removing any role binding, with or without a condition, from a policy
  that includes conditions

B<Important:> If you use IAM Conditions, you must include the `etag` field
whenever you call `setIamPolicy`. If you omit this field, then IAM allows
you to overwrite a version `3` policy with a version `1` policy, and all of
the conditions in the version `3` policy are lost.

If a policy does not include any conditions, operations on that policy may
specify any valid version or leave the field unset.

To learn which resources support conditions in their IAM policies, see the
[IAM
documentation](https://cloud.google.com/iam/help/conditions/resource-policies).

=item * C<< $msg->bindings() >> / C<< $msg->bindings($value) >>

Type: C<Message> (L<Google::Iam::V1::Policy::Binding>)

Associates a list of `members`, or principals, with a `role`. Optionally,
may specify a `condition` that determines how and when the `bindings` are
applied. Each of the `bindings` must contain at least one principal.

The `bindings` in a `Policy` can refer to up to 1,500 principals; up to 250
of these principals can be Google groups. Each occurrence of a principal
counts towards these limits. For example, if the `bindings` grant 50
different roles to `user:alice@example.com`, and not to any other
principal, then you can add another 1,450 principals to the `bindings` in
the `Policy`.

=item * C<< $msg->audit_configs() >> / C<< $msg->audit_configs($value) >>

Type: C<Message> (L<Google::Iam::V1::Policy::AuditConfig>)

Specifies cloud audit logging configuration for this policy.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<Bytes>

`etag` is used for optimistic concurrency control as a way to help
prevent simultaneous updates of a policy from overwriting each other.
It is strongly suggested that systems make use of the `etag` in the
read-modify-write cycle to perform policy updates in order to avoid race
conditions: An `etag` is returned in the response to `getIamPolicy`, and
systems are expected to put that etag in the request to `setIamPolicy` to
ensure that their change will be applied to the same version of the policy.

B<Important:> If you use IAM Conditions, you must include the `etag` field
whenever you call `setIamPolicy`. If you omit this field, then IAM allows
you to overwrite a version `3` policy with a version `1` policy, and all of
the conditions in the version `3` policy are lost.

=back

=head2 Google::Iam::V1::Policy::Binding

Associates `members`, or principals, with a `role`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->role() >> / C<< $msg->role($value) >>

Type: C<String>

Role that is assigned to the list of `members`, or principals.
For example, `roles/viewer`, `roles/editor`, or `roles/owner`.

=item * C<< $msg->members() >> / C<< $msg->members($value) >>

Type: C<String>

Specifies the principals requesting access for a Google Cloud resource.
`members` can have the following values:

* `allUsers`: A special identifier that represents anyone who is
   on the internet; with or without a Google account.

* `allAuthenticatedUsers`: A special identifier that represents anyone
   who is authenticated with a Google account or a service account.

* `user:{emailid}`: An email address that represents a specific Google
   account. For example, `alice@example.com` .


* `serviceAccount:{emailid}`: An email address that represents a service
   account. For example, `my-other-app@appspot.gserviceaccount.com`.

* `group:{emailid}`: An email address that represents a Google group.
   For example, `admins@example.com`.

* `deleted:user:{emailid}?uid={uniqueid}`: An email address (plus unique
   identifier) representing a user that has been recently deleted. For
   example, `alice@example.com?uid=123456789012345678901`. If the user is
   recovered, this value reverts to `user:{emailid}` and the recovered user
   retains the role in the binding.

* `deleted:serviceAccount:{emailid}?uid={uniqueid}`: An email address (plus
   unique identifier) representing a service account that has been recently
   deleted. For example,
   `my-other-app@appspot.gserviceaccount.com?uid=123456789012345678901`.
   If the service account is undeleted, this value reverts to
   `serviceAccount:{emailid}` and the undeleted service account retains the
   role in the binding.

* `deleted:group:{emailid}?uid={uniqueid}`: An email address (plus unique
   identifier) representing a Google group that has been recently
   deleted. For example, `admins@example.com?uid=123456789012345678901`. If
   the group is recovered, this value reverts to `group:{emailid}` and the
   recovered group retains the role in the binding.


* `domain:{domain}`: The G Suite domain (primary) that represents all the
   users of that domain. For example, `google.com` or `example.com`.



=item * C<< $msg->condition() >> / C<< $msg->condition($value) >>

Type: C<Message> (L<Google::Type::Expr::Expr>)

The condition that is associated with this binding.

If the condition evaluates to `true`, then this binding applies to the
current request.

If the condition evaluates to `false`, then this binding does not apply to
the current request. However, a different role binding might grant the same
role to one or more of the principals in this binding.

To learn which resources support conditions in their IAM policies, see the
[IAM
documentation](https://cloud.google.com/iam/help/conditions/resource-policies).

=back

=head2 Google::Iam::V1::Policy::AuditConfig

Specifies the audit configuration for a service.
The configuration determines which permission types are logged, and what
identities, if any, are exempted from logging.
An AuditConfig must have one or more AuditLogConfigs.

If there are AuditConfigs for both `allServices` and a specific service,
the union of the two AuditConfigs is used for that service: the log_types
specified in each AuditConfig are enabled, and the exempted_members in each
AuditLogConfig are exempted.

Example Policy with multiple AuditConfigs:

    {
      "audit_configs": [
        {
          "service": "allServices",
          "audit_log_configs": [
            {
              "log_type": "DATA_READ",
              "exempted_members": [
                "user:jose@example.com"
              ]
            },
            {
              "log_type": "DATA_WRITE"
            },
            {
              "log_type": "ADMIN_READ"
            }
          ]
        },
        {
          "service": "sampleservice.googleapis.com",
          "audit_log_configs": [
            {
              "log_type": "DATA_READ"
            },
            {
              "log_type": "DATA_WRITE",
              "exempted_members": [
                "user:aliya@example.com"
              ]
            }
          ]
        }
      ]
    }

For sampleservice, this policy enables DATA_READ, DATA_WRITE and ADMIN_READ
logging. It also exempts `jose@example.com` from DATA_READ logging, and
`aliya@example.com` from DATA_WRITE logging.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service() >> / C<< $msg->service($value) >>

Type: C<String>

Specifies a service that will be enabled for audit logging.
For example, `storage.googleapis.com`, `cloudsql.googleapis.com`.
`allServices` is a special value that covers all services.

=item * C<< $msg->audit_log_configs() >> / C<< $msg->audit_log_configs($value) >>

Type: C<Message> (L<Google::Iam::V1::Policy::AuditLogConfig>)

The configuration for logging of each type of permission.

=back

=head2 Google::Iam::V1::Policy::AuditLogConfig

Provides the configuration for logging a type of permissions.
Example:

    {
      "audit_log_configs": [
        {
          "log_type": "DATA_READ",
          "exempted_members": [
            "user:jose@example.com"
          ]
        },
        {
          "log_type": "DATA_WRITE"
        }
      ]
    }

This enables 'DATA_READ' and 'DATA_WRITE' logging, while exempting
jose@example.com from DATA_READ logging.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->log_type() >> / C<< $msg->log_type($value) >>

Type: C<Enum> (L<Google::Iam::V1::AuditLogConfig::LogType>)

The log type that this config enables.

=item * C<< $msg->exempted_members() >> / C<< $msg->exempted_members($value) >>

Type: C<String>

Specifies the identities that do not cause logging for this type of
permission.
Follows the same format of
[Binding.members][google.iam.v1.Binding.members].

=back

=head3 Enum: AuditLogConfig::LogType

=over 4

=item * C<LOG_TYPE_UNSPECIFIED> => C<0>

=item * C<ADMIN_READ> => C<1>

=item * C<DATA_WRITE> => C<2>

=item * C<DATA_READ> => C<3>

=back

=head2 Google::Iam::V1::Policy::PolicyDelta

The difference delta between two policies.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->binding_deltas() >> / C<< $msg->binding_deltas($value) >>

Type: C<Message> (L<Google::Iam::V1::Policy::BindingDelta>)

The delta for Bindings between two policies.

=item * C<< $msg->audit_config_deltas() >> / C<< $msg->audit_config_deltas($value) >>

Type: C<Message> (L<Google::Iam::V1::Policy::AuditConfigDelta>)

The delta for AuditConfigs between two policies.

=back

=head2 Google::Iam::V1::Policy::BindingDelta

One delta entry for Binding. Each individual change (only one member in each
entry) to a binding will be a separate entry.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<Enum> (L<Google::Iam::V1::BindingDelta::Action>)

The action that was performed on a Binding.
Required

=item * C<< $msg->role() >> / C<< $msg->role($value) >>

Type: C<String>

Role that is assigned to `members`.
For example, `roles/viewer`, `roles/editor`, or `roles/owner`.
Required

=item * C<< $msg->member() >> / C<< $msg->member($value) >>

Type: C<String>

A single identity requesting access for a Google Cloud resource.
Follows the same format of Binding.members.
Required

=item * C<< $msg->condition() >> / C<< $msg->condition($value) >>

Type: C<Message> (L<Google::Type::Expr::Expr>)

The condition that is associated with this binding.

=back

=head3 Enum: BindingDelta::Action

=over 4

=item * C<ACTION_UNSPECIFIED> => C<0>

=item * C<ADD> => C<1>

=item * C<REMOVE> => C<2>

=back

=head2 Google::Iam::V1::Policy::AuditConfigDelta

One delta entry for AuditConfig. Each individual change (only one
exempted_member in each entry) to a AuditConfig will be a separate entry.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<Enum> (L<Google::Iam::V1::AuditConfigDelta::Action>)

The action that was performed on an audit configuration in a policy.
Required

=item * C<< $msg->service() >> / C<< $msg->service($value) >>

Type: C<String>

Specifies a service that was configured for Cloud Audit Logging.
For example, `storage.googleapis.com`, `cloudsql.googleapis.com`.
`allServices` is a special value that covers all services.
Required

=item * C<< $msg->exempted_member() >> / C<< $msg->exempted_member($value) >>

Type: C<String>

A single identity that is exempted from "data access" audit
logging for the `service` specified above.
Follows the same format of Binding.members.

=item * C<< $msg->log_type() >> / C<< $msg->log_type($value) >>

Type: C<String>

Specifies the log_type that was be enabled. ADMIN_ACTIVITY is always
enabled, and cannot be configured.
Required

=back

=head3 Enum: AuditConfigDelta::Action

=over 4

=item * C<ACTION_UNSPECIFIED> => C<0>

=item * C<ADD> => C<1>

=item * C<REMOVE> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Iam::V1::Policy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
