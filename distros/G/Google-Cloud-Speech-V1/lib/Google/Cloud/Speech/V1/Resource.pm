package Google::Cloud::Speech::V1::Resource;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvY2xvdWQvc3BlZWNoL3YxL3Jlc291cmNlLnByb3RvEhZnb29nbGUuY2xvdWQu
c3BlZWNoLnYxGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvIp8CCgtDdXN0b21DbGFzcxIS
CgRuYW1lGAEgASgJUgRuYW1lEiYKD2N1c3RvbV9jbGFzc19pZBgCIAEoCVINY3VzdG9tQ2xh
c3NJZBJDCgVpdGVtcxgDIAMoCzItLmdvb2dsZS5jbG91ZC5zcGVlY2gudjEuQ3VzdG9tQ2xh
c3MuQ2xhc3NJdGVtUgVpdGVtcxohCglDbGFzc0l0ZW0SFAoFdmFsdWUYASABKAlSBXZhbHVl
OmzqQWkKIXNwZWVjaC5nb29nbGVhcGlzLmNvbS9DdXN0b21DbGFzcxJEcHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2N1c3RvbUNsYXNzZXMve2N1c3RvbV9jbGFz
c30ilgIKCVBocmFzZVNldBISCgRuYW1lGAEgASgJUgRuYW1lEkIKB3BocmFzZXMYAiADKAsy
KC5nb29nbGUuY2xvdWQuc3BlZWNoLnYxLlBocmFzZVNldC5QaHJhc2VSB3BocmFzZXMSFAoF
Ym9vc3QYBCABKAJSBWJvb3N0GjQKBlBocmFzZRIUCgV2YWx1ZRgBIAEoCVIFdmFsdWUSFAoF
Ym9vc3QYAiABKAJSBWJvb3N0OmXqQWIKH3NwZWVjaC5nb29nbGVhcGlzLmNvbS9QaHJhc2VT
ZXQSP3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9waHJhc2VTZXRz
L3twaHJhc2Vfc2V0fSKHAwoQU3BlZWNoQWRhcHRhdGlvbhJCCgtwaHJhc2Vfc2V0cxgBIAMo
CzIhLmdvb2dsZS5jbG91ZC5zcGVlY2gudjEuUGhyYXNlU2V0UgpwaHJhc2VTZXRzElgKFXBo
cmFzZV9zZXRfcmVmZXJlbmNlcxgCIAMoCUIk+kEhCh9zcGVlY2guZ29vZ2xlYXBpcy5jb20v
UGhyYXNlU2V0UhNwaHJhc2VTZXRSZWZlcmVuY2VzEkoKDmN1c3RvbV9jbGFzc2VzGAMgAygL
MiMuZ29vZ2xlLmNsb3VkLnNwZWVjaC52MS5DdXN0b21DbGFzc1INY3VzdG9tQ2xhc3NlcxJX
CgxhYm5mX2dyYW1tYXIYBCABKAsyNC5nb29nbGUuY2xvdWQuc3BlZWNoLnYxLlNwZWVjaEFk
YXB0YXRpb24uQUJORkdyYW1tYXJSC2FibmZHcmFtbWFyGjAKC0FCTkZHcmFtbWFyEiEKDGFi
bmZfc3RyaW5ncxgBIAMoCVILYWJuZlN0cmluZ3MizAEKF1RyYW5zY3JpcHROb3JtYWxpemF0
aW9uEk8KB2VudHJpZXMYASADKAsyNS5nb29nbGUuY2xvdWQuc3BlZWNoLnYxLlRyYW5zY3Jp
cHROb3JtYWxpemF0aW9uLkVudHJ5UgdlbnRyaWVzGmAKBUVudHJ5EhYKBnNlYXJjaBgBIAEo
CVIGc2VhcmNoEhgKB3JlcGxhY2UYAiABKAlSB3JlcGxhY2USJQoOY2FzZV9zZW5zaXRpdmUY
AyABKAhSDWNhc2VTZW5zaXRpdmVCcAoaY29tLmdvb2dsZS5jbG91ZC5zcGVlY2gudjFCE1Nw
ZWVjaFJlc291cmNlUHJvdG9QAVoyY2xvdWQuZ29vZ2xlLmNvbS9nby9zcGVlY2gvYXBpdjEv
c3BlZWNocGI7c3BlZWNocGL4AQGiAgNHQ1NKhjkKBxIFDgCsAQEKvAQKAQwSAw4AEjKxBCBD
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
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB8KCQoCAwASAxIAIwoICgEIEgMUAB8KCQoC
CB8SAxQAHwoICgEIEgMVAEkKCQoCCAsSAxUASQoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEI
EgMXADQKCQoCCAgSAxcANAoICgEIEgMYADMKCQoCCAESAxgAMwoICgEIEgMZACEKCQoCCCQS
AxkAIQrxAQoCBAASBB4AMwEa5AEgQSBzZXQgb2Ygd29yZHMgb3IgcGhyYXNlcyB0aGF0IHJl
cHJlc2VudHMgYSBjb21tb24gY29uY2VwdCBsaWtlbHkgdG8gYXBwZWFyCiBpbiB5b3VyIGF1
ZGlvLCBmb3IgZXhhbXBsZSBhIGxpc3Qgb2YgcGFzc2VuZ2VyIHNoaXAgbmFtZXMuIEN1c3Rv
bUNsYXNzIGl0ZW1zCiBjYW4gYmUgc3Vic3RpdHV0ZWQgaW50byBwbGFjZWhvbGRlcnMgdGhh
dCB5b3Ugc2V0IGluIFBocmFzZVNldCBwaHJhc2VzLgoKCgoDBAABEgMeCBMKCwoDBAAHEgQf
AiIECg0KBQQAB50IEgQfAiIECiUKBAQAAwASBCUCKAMaFyBBbiBpdGVtIG9mIHRoZSBjbGFz
cy4KCgwKBQQAAwABEgMlChMKKAoGBAADAAIAEgMnBBUaGSBUaGUgY2xhc3MgaXRlbSdzIHZh
bHVlLgoKDgoHBAADAAIABRIDJwQKCg4KBwQAAwACAAESAycLEAoOCgcEAAMAAgADEgMnExQK
NQoEBAACABIDKwISGiggVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGN1c3RvbSBjbGFzcy4K
CgwKBQQAAgAFEgMrAggKDAoFBAACAAESAysJDQoMCgUEAAIAAxIDKxARCn4KBAQAAgESAy8C
HRpxIElmIHRoaXMgY3VzdG9tIGNsYXNzIGlzIGEgcmVzb3VyY2UsIHRoZSBjdXN0b21fY2xh
c3NfaWQgaXMgdGhlIHJlc291cmNlIGlkCiBvZiB0aGUgQ3VzdG9tQ2xhc3MuIENhc2Ugc2Vu
c2l0aXZlLgoKDAoFBAACAQUSAy8CCAoMCgUEAAIBARIDLwkYCgwKBQQAAgEDEgMvGxwKKwoE
BAACAhIDMgIfGh4gQSBjb2xsZWN0aW9uIG9mIGNsYXNzIGl0ZW1zLgoKDAoFBAACAgQSAzIC
CgoMCgUEAAICBhIDMgsUCgwKBQQAAgIBEgMyFRoKDAoFBAACAgMSAzIdHgpsCgIEARIENwB2
ARpgIFByb3ZpZGVzICJoaW50cyIgdG8gdGhlIHNwZWVjaCByZWNvZ25pemVyIHRvIGZhdm9y
IHNwZWNpZmljIHdvcmRzIGFuZCBwaHJhc2VzCiBpbiB0aGUgcmVzdWx0cy4KCgoKAwQBARID
NwgRCgsKAwQBBxIEOAI7BAoNCgUEAQedCBIEOAI7BArNDAoEBAEDABIEVgJkAxq+DCBBIHBo
cmFzZXMgY29udGFpbmluZyB3b3JkcyBhbmQgcGhyYXNlICJoaW50cyIgc28gdGhhdAogdGhl
IHNwZWVjaCByZWNvZ25pdGlvbiBpcyBtb3JlIGxpa2VseSB0byByZWNvZ25pemUgdGhlbS4g
VGhpcyBjYW4gYmUgdXNlZAogdG8gaW1wcm92ZSB0aGUgYWNjdXJhY3kgZm9yIHNwZWNpZmlj
IHdvcmRzIGFuZCBwaHJhc2VzLCBmb3IgZXhhbXBsZSwgaWYKIHNwZWNpZmljIGNvbW1hbmRz
IGFyZSB0eXBpY2FsbHkgc3Bva2VuIGJ5IHRoZSB1c2VyLiBUaGlzIGNhbiBhbHNvIGJlIHVz
ZWQKIHRvIGFkZCBhZGRpdGlvbmFsIHdvcmRzIHRvIHRoZSB2b2NhYnVsYXJ5IG9mIHRoZSBy
ZWNvZ25pemVyLiBTZWUKIFt1c2FnZSBsaW1pdHNdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNv
bS9zcGVlY2gtdG8tdGV4dC9xdW90YXMjY29udGVudCkuCgogTGlzdCBpdGVtcyBjYW4gYWxz
byBpbmNsdWRlIHByZS1idWlsdCBvciBjdXN0b20gY2xhc3NlcyBjb250YWluaW5nIGdyb3Vw
cwogb2Ygd29yZHMgdGhhdCByZXByZXNlbnQgY29tbW9uIGNvbmNlcHRzIHRoYXQgb2NjdXIg
aW4gbmF0dXJhbCBsYW5ndWFnZS4gRm9yCiBleGFtcGxlLCByYXRoZXIgdGhhbiBwcm92aWRp
bmcgYSBwaHJhc2UgaGludCBmb3IgZXZlcnkgbW9udGggb2YgdGhlCiB5ZWFyIChlLmcuICJp
IHdhcyBib3JuIGluIGphbnVhcnkiLCAiaSB3YXMgYm9ybiBpbiBmZWJ1YXJ5IiwgLi4uKSwg
dXNlIHRoZQogcHJlLWJ1aWx0IGAkTU9OVEhgIGNsYXNzIGltcHJvdmVzIHRoZSBsaWtlbGlo
b29kIG9mIGNvcnJlY3RseSB0cmFuc2NyaWJpbmcKIGF1ZGlvIHRoYXQgaW5jbHVkZXMgbW9u
dGhzIChlLmcuICJpIHdhcyBib3JuIGluICRtb250aCIpLgogVG8gcmVmZXIgdG8gcHJlLWJ1
aWx0IGNsYXNzZXMsIHVzZSB0aGUgY2xhc3MnIHN5bWJvbCBwcmVwZW5kZWQgd2l0aCBgJGAK
IGUuZy4gYCRNT05USGAuIFRvIHJlZmVyIHRvIGN1c3RvbSBjbGFzc2VzIHRoYXQgd2VyZSBk
ZWZpbmVkIGlubGluZSBpbiB0aGUKIHJlcXVlc3QsIHNldCB0aGUgY2xhc3MncyBgY3VzdG9t
X2NsYXNzX2lkYCB0byBhIHN0cmluZyB1bmlxdWUgdG8gYWxsIGNsYXNzCiByZXNvdXJjZXMg
YW5kIGlubGluZSBjbGFzc2VzLiBUaGVuIHVzZSB0aGUgY2xhc3MnIGlkIHdyYXBwZWQgaW4g
JGB7Li4ufWAKIGUuZy4gIiR7bXktbW9udGhzfSIuIFRvIHJlZmVyIHRvIGN1c3RvbSBjbGFz
c2VzIHJlc291cmNlcywgdXNlIHRoZSBjbGFzcycKIGlkIHdyYXBwZWQgaW4gYCR7fWAgKGUu
Zy4gYCR7bXktbW9udGhzfWApLgoKIFNwZWVjaC10by1UZXh0IHN1cHBvcnRzIHRocmVlIGxv
Y2F0aW9uczogYGdsb2JhbGAsIGB1c2AgKFVTIE5vcnRoIEFtZXJpY2EpLAogYW5kIGBldWAg
KEV1cm9wZSkuIElmIHlvdSBhcmUgY2FsbGluZyB0aGUgYHNwZWVjaC5nb29nbGVhcGlzLmNv
bWAKIGVuZHBvaW50LCB1c2UgdGhlIGBnbG9iYWxgIGxvY2F0aW9uLiBUbyBzcGVjaWZ5IGEg
cmVnaW9uLCB1c2UgYQogW3JlZ2lvbmFsIGVuZHBvaW50XShodHRwczovL2Nsb3VkLmdvb2ds
ZS5jb20vc3BlZWNoLXRvLXRleHQvZG9jcy9lbmRwb2ludHMpCiB3aXRoIG1hdGNoaW5nIGB1
c2Agb3IgYGV1YCBsb2NhdGlvbiB2YWx1ZS4KCgwKBQQBAwABEgNWChAKIwoGBAEDAAIAEgNY
BBUaFCBUaGUgcGhyYXNlIGl0c2VsZi4KCg4KBwQBAwACAAUSA1gECgoOCgcEAQMAAgABEgNY
CxAKDgoHBAEDAAIAAxIDWBMUCucECgYEAQMAAgESA2MEFBrXBCBIaW50IEJvb3N0LiBPdmVy
cmlkZXMgdGhlIGJvb3N0IHNldCBhdCB0aGUgcGhyYXNlIHNldCBsZXZlbC4KIFBvc2l0aXZl
IHZhbHVlIHdpbGwgaW5jcmVhc2UgdGhlIHByb2JhYmlsaXR5IHRoYXQgYSBzcGVjaWZpYyBw
aHJhc2Ugd2lsbAogYmUgcmVjb2duaXplZCBvdmVyIG90aGVyIHNpbWlsYXIgc291bmRpbmcg
cGhyYXNlcy4gVGhlIGhpZ2hlciB0aGUgYm9vc3QsCiB0aGUgaGlnaGVyIHRoZSBjaGFuY2Ug
b2YgZmFsc2UgcG9zaXRpdmUgcmVjb2duaXRpb24gYXMgd2VsbC4gTmVnYXRpdmUKIGJvb3N0
IHdpbGwgc2ltcGx5IGJlIGlnbm9yZWQuIFRob3VnaCBgYm9vc3RgIGNhbiBhY2NlcHQgYSB3
aWRlIHJhbmdlIG9mCiBwb3NpdGl2ZSB2YWx1ZXMsIG1vc3QgdXNlIGNhc2VzIGFyZSBiZXN0
IHNlcnZlZAogd2l0aCB2YWx1ZXMgYmV0d2VlbiAwIGFuZCAyMC4gV2UgcmVjb21tZW5kIHVz
aW5nIGEgYmluYXJ5IHNlYXJjaCBhcHByb2FjaAogdG8gZmluZGluZyB0aGUgb3B0aW1hbCB2
YWx1ZSBmb3IgeW91ciB1c2UgY2FzZSBhcyB3ZWxsIGFzIGFkZGluZwogcGhyYXNlcyBib3Ro
IHdpdGggYW5kIHdpdGhvdXQgYm9vc3QgdG8geW91ciByZXF1ZXN0cy4KCg4KBwQBAwACAQUS
A2MECQoOCgcEAQMAAgEBEgNjCg8KDgoHBAEDAAIBAxIDYxITCjMKBAQBAgASA2cCEhomIFRo
ZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBwaHJhc2Ugc2V0LgoKDAoFBAECAAUSA2cCCAoMCgUE
AQIAARIDZwkNCgwKBQQBAgADEgNnEBEKKgoEBAECARIDagIeGh0gQSBsaXN0IG9mIHdvcmQg
YW5kIHBocmFzZXMuCgoMCgUEAQIBBBIDagIKCgwKBQQBAgEGEgNqCxEKDAoFBAECAQESA2oS
GQoMCgUEAQIBAxIDahwdCpgFCgQEAQICEgN1AhIaigUgSGludCBCb29zdC4gUG9zaXRpdmUg
dmFsdWUgd2lsbCBpbmNyZWFzZSB0aGUgcHJvYmFiaWxpdHkgdGhhdCBhIHNwZWNpZmljCiBw
aHJhc2Ugd2lsbCBiZSByZWNvZ25pemVkIG92ZXIgb3RoZXIgc2ltaWxhciBzb3VuZGluZyBw
aHJhc2VzLiBUaGUgaGlnaGVyCiB0aGUgYm9vc3QsIHRoZSBoaWdoZXIgdGhlIGNoYW5jZSBv
ZiBmYWxzZSBwb3NpdGl2ZSByZWNvZ25pdGlvbiBhcyB3ZWxsLgogTmVnYXRpdmUgYm9vc3Qg
dmFsdWVzIHdvdWxkIGNvcnJlc3BvbmQgdG8gYW50aS1iaWFzaW5nLiBBbnRpLWJpYXNpbmcg
aXMgbm90CiBlbmFibGVkLCBzbyBuZWdhdGl2ZSBib29zdCB3aWxsIHNpbXBseSBiZSBpZ25v
cmVkLiBUaG91Z2ggYGJvb3N0YCBjYW4KIGFjY2VwdCBhIHdpZGUgcmFuZ2Ugb2YgcG9zaXRp
dmUgdmFsdWVzLCBtb3N0IHVzZSBjYXNlcyBhcmUgYmVzdCBzZXJ2ZWQgd2l0aAogdmFsdWVz
IGJldHdlZW4gMCAoZXhjbHVzaXZlKSBhbmQgMjAuIFdlIHJlY29tbWVuZCB1c2luZyBhIGJp
bmFyeSBzZWFyY2gKIGFwcHJvYWNoIHRvIGZpbmRpbmcgdGhlIG9wdGltYWwgdmFsdWUgZm9y
IHlvdXIgdXNlIGNhc2UgYXMgd2VsbCBhcyBhZGRpbmcKIHBocmFzZXMgYm90aCB3aXRoIGFu
ZCB3aXRob3V0IGJvb3N0IHRvIHlvdXIgcmVxdWVzdHMuCgoMCgUEAQICBRIDdQIHCgwKBQQB
AgIBEgN1CA0KDAoFBAECAgMSA3UQEQovCgIEAhIFeQCUAQEaIiBTcGVlY2ggYWRhcHRhdGlv
biBjb25maWd1cmF0aW9uLgoKCgoDBAIBEgN5CBgKDAoEBAIDABIEegJ+AwoMCgUEAgMAARID
egoVCn4KBgQCAwACABIDfQQlGm8gQWxsIGRlY2xhcmF0aW9ucyBhbmQgcnVsZXMgb2YgYW4g
QUJORiBncmFtbWFyIGJyb2tlbiB1cCBpbnRvIG11bHRpcGxlCiBzdHJpbmdzIHRoYXQgd2ls
bCBlbmQgdXAgY29uY2F0ZW5hdGVkLgoKDgoHBAIDAAIABBIDfQQMCg4KBwQCAwACAAUSA30N
EwoOCgcEAgMAAgABEgN9FCAKDgoHBAIDAAIAAxIDfSMkCr0BCgQEAgIAEgSDAQIlGq4BIEEg
Y29sbGVjdGlvbiBvZiBwaHJhc2Ugc2V0cy4gVG8gc3BlY2lmeSB0aGUgaGludHMgaW5saW5l
LCBsZWF2ZSB0aGUKIHBocmFzZSBzZXQncyBgbmFtZWAgYmxhbmsgYW5kIGZpbGwgaW4gdGhl
IHJlc3Qgb2YgaXRzIGZpZWxkcy4gQW55CiBwaHJhc2Ugc2V0IGNhbiB1c2UgYW55IGN1c3Rv
bSBjbGFzcy4KCg0KBQQCAgAEEgSDAQIKCg0KBQQCAgAGEgSDAQsUCg0KBQQCAgABEgSDARUg
Cg0KBQQCAgADEgSDASMkCkMKBAQCAgESBoYBAogBBRozIEEgY29sbGVjdGlvbiBvZiBwaHJh
c2Ugc2V0IHJlc291cmNlIG5hbWVzIHRvIHVzZS4KCg0KBQQCAgEEEgSGAQIKCg0KBQQCAgEF
EgSGAQsRCg0KBQQCAgEBEgSGARInCg0KBQQCAgEDEgSGASorCg8KBQQCAgEIEgaGASyIAQQK
EQoHBAICAQifCBIGhgEtiAEDCoYCCgQEAgICEgSOAQIqGvcBIEEgY29sbGVjdGlvbiBvZiBj
dXN0b20gY2xhc3Nlcy4gVG8gc3BlY2lmeSB0aGUgY2xhc3NlcyBpbmxpbmUsIGxlYXZlIHRo
ZQogY2xhc3MnIGBuYW1lYCBibGFuayBhbmQgZmlsbCBpbiB0aGUgcmVzdCBvZiBpdHMgZmll
bGRzLCBnaXZpbmcgaXQgYSB1bmlxdWUKIGBjdXN0b21fY2xhc3NfaWRgLiBSZWZlciB0byB0
aGUgaW5saW5lIGRlZmluZWQgY2xhc3MgaW4gcGhyYXNlIGhpbnRzIGJ5IGl0cwogYGN1c3Rv
bV9jbGFzc19pZGAuCgoNCgUEAgICBBIEjgECCgoNCgUEAgICBhIEjgELFgoNCgUEAgICARIE
jgEXJQoNCgUEAgICAxIEjgEoKQq4AQoEBAICAxIEkwECHxqpASBBdWdtZW50ZWQgQmFja3Vz
LU5hdXIgZm9ybSAoQUJORikgaXMgYSBzdGFuZGFyZGl6ZWQgZ3JhbW1hciBub3RhdGlvbgog
Y29tcHJpc2VkIGJ5IGEgc2V0IG9mIGRlcml2YXRpb24gcnVsZXMuCiBTZWUgc3BlY2lmaWNh
dGlvbnM6IGh0dHBzOi8vd3d3LnczLm9yZy9UUi9zcGVlY2gtZ3JhbW1hcgoKDQoFBAICAwYS
BJMBAg0KDQoFBAICAwESBJMBDhoKDQoFBAICAwMSBJMBHR4KrQIKAgQDEgaaAQCsAQEangIg
VHJhbnNjcmlwdGlvbiBub3JtYWxpemF0aW9uIGNvbmZpZ3VyYXRpb24uIFVzZSB0cmFuc2Ny
aXB0aW9uIG5vcm1hbGl6YXRpb24KIHRvIGF1dG9tYXRpY2FsbHkgcmVwbGFjZSBwYXJ0cyBv
ZiB0aGUgdHJhbnNjcmlwdCB3aXRoIHBocmFzZXMgb2YgeW91cgogY2hvb3NpbmcuIEZvciBT
dHJlYW1pbmdSZWNvZ25pemUsIHRoaXMgbm9ybWFsaXphdGlvbiBvbmx5IGFwcGxpZXMgdG8g
c3RhYmxlCiBwYXJ0aWFsIHRyYW5zY3JpcHRzIChzdGFiaWxpdHkgPiAwLjgpIGFuZCBmaW5h
bCB0cmFuc2NyaXB0cy4KCgsKAwQDARIEmgEIHwo1CgQEAwMAEgacAQKlAQMaJSBBIHNpbmds
ZSByZXBsYWNlbWVudCBjb25maWd1cmF0aW9uLgoKDQoFBAMDAAESBJwBCg8KQAoGBAMDAAIA
EgSeAQQWGjAgV2hhdCB0byByZXBsYWNlLiBNYXggbGVuZ3RoIGlzIDEwMCBjaGFyYWN0ZXJz
LgoKDwoHBAMDAAIABRIEngEECgoPCgcEAwMAAgABEgSeAQsRCg8KBwQDAwACAAMSBJ4BFBUK
RQoGBAMDAAIBEgShAQQXGjUgV2hhdCB0byByZXBsYWNlIHdpdGguIE1heCBsZW5ndGggaXMg
MTAwIGNoYXJhY3RlcnMuCgoPCgcEAwMAAgEFEgShAQQKCg8KBwQDAwACAQESBKEBCxIKDwoH
BAMDAAIBAxIEoQEVFgo3CgYEAwMAAgISBKQBBBwaJyBXaGV0aGVyIHRoZSBzZWFyY2ggaXMg
Y2FzZSBzZW5zaXRpdmUuCgoPCgcEAwMAAgIFEgSkAQQICg8KBwQDAwACAgESBKQBCRcKDwoH
BAMDAAICAxIEpAEaGwqhAgoEBAMCABIEqwECHRqSAiBBIGxpc3Qgb2YgcmVwbGFjZW1lbnQg
ZW50cmllcy4gV2Ugd2lsbCBwZXJmb3JtIHJlcGxhY2VtZW50IHdpdGggb25lIGVudHJ5CiBh
dCBhIHRpbWUuIEZvciBleGFtcGxlLCB0aGUgc2Vjb25kIGVudHJ5IGluIFsiY2F0IiA9PiAi
ZG9nIiwgIm1vdW50YWluIGNhdCIKID0+ICJtb3VudGFpbiBkb2ciXSB3aWxsIG5ldmVyIGJl
IGFwcGxpZWQgYmVjYXVzZSB3ZSB3aWxsIGFsd2F5cyBwcm9jZXNzIHRoZQogZmlyc3QgZW50
cnkgYmVmb3JlIGl0LiBBdCBtb3N0IDEwMCBlbnRyaWVzLgoKDQoFBAMCAAQSBKsBAgoKDQoF
BAMCAAYSBKsBCxAKDQoFBAMCAAESBKsBERgKDQoFBAMCAAMSBKsBGxxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Speech::V1::Resource::CustomClass ===
    # Fields for CustomClass
    # Field: name Type: 9 ()
    # Field: custom_class_id Type: 9 ()
    # Field: items Type: 11 (.google.cloud.speech.v1.CustomClass.ClassItem)

# === Message: Google::Cloud::Speech::V1::Resource::PhraseSet ===
    # Fields for PhraseSet
    # Field: name Type: 9 ()
    # Field: phrases Type: 11 (.google.cloud.speech.v1.PhraseSet.Phrase)
    # Field: boost Type: 2 ()

# === Message: Google::Cloud::Speech::V1::Resource::SpeechAdaptation ===
    # Fields for SpeechAdaptation
    # Field: phrase_sets Type: 11 (.google.cloud.speech.v1.PhraseSet)
    # Field: phrase_set_references Type: 9 ()
    # Field: custom_classes Type: 11 (.google.cloud.speech.v1.CustomClass)
    # Field: abnf_grammar Type: 11 (.google.cloud.speech.v1.SpeechAdaptation.ABNFGrammar)

# === Message: Google::Cloud::Speech::V1::Resource::TranscriptNormalization ===
    # Fields for TranscriptNormalization
    # Field: entries Type: 11 (.google.cloud.speech.v1.TranscriptNormalization.Entry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Speech::V1::Resource - Compiled Protocol Buffers messages for google/cloud/speech/v1/resource.proto

=head1 SYNOPSIS

    use Google::Cloud::Speech::V1::Resource;

    my $msg = Google::Cloud::Speech::V1::Resource::CustomClass->new({
        name => $name,
        custom_class_id => $custom_class_id,
        items => $items,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Speech::V1::Resource::CustomClass->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/speech/v1/resource.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Speech::V1::Resource::CustomClass

A set of words or phrases that represents a common concept likely to appear
in your audio, for example a list of passenger ship names. CustomClass items
can be substituted into placeholders that you set in PhraseSet phrases.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the custom class.

=item * C<< $msg->custom_class_id() >> / C<< $msg->custom_class_id($value) >>

Type: C<String>

If this custom class is a resource, the custom_class_id is the resource id
of the CustomClass. Case sensitive.

=item * C<< $msg->items() >> / C<< $msg->items($value) >>

Type: C<Message> (L<Google::Cloud::Speech::V1::Resource::CustomClass::ClassItem>)

A collection of class items.

=back

=head2 Google::Cloud::Speech::V1::Resource::PhraseSet

Provides "hints" to the speech recognizer to favor specific words and phrases
in the results.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the phrase set.

=item * C<< $msg->phrases() >> / C<< $msg->phrases($value) >>

Type: C<Message> (L<Google::Cloud::Speech::V1::Resource::PhraseSet::Phrase>)

A list of word and phrases.

=item * C<< $msg->boost() >> / C<< $msg->boost($value) >>

Type: C<Float>

Hint Boost. Positive value will increase the probability that a specific
phrase will be recognized over other similar sounding phrases. The higher
the boost, the higher the chance of false positive recognition as well.
Negative boost values would correspond to anti-biasing. Anti-biasing is not
enabled, so negative boost will simply be ignored. Though `boost` can
accept a wide range of positive values, most use cases are best served with
values between 0 (exclusive) and 20. We recommend using a binary search
approach to finding the optimal value for your use case as well as adding
phrases both with and without boost to your requests.

=back

=head2 Google::Cloud::Speech::V1::Resource::SpeechAdaptation

Speech adaptation configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->phrase_sets() >> / C<< $msg->phrase_sets($value) >>

Type: C<Message> (L<Google::Cloud::Speech::V1::Resource::PhraseSet>)

A collection of phrase sets. To specify the hints inline, leave the
phrase set's `name` blank and fill in the rest of its fields. Any
phrase set can use any custom class.

=item * C<< $msg->phrase_set_references() >> / C<< $msg->phrase_set_references($value) >>

Type: C<String>

A collection of phrase set resource names to use.

=item * C<< $msg->custom_classes() >> / C<< $msg->custom_classes($value) >>

Type: C<Message> (L<Google::Cloud::Speech::V1::Resource::CustomClass>)

A collection of custom classes. To specify the classes inline, leave the
class' `name` blank and fill in the rest of its fields, giving it a unique
`custom_class_id`. Refer to the inline defined class in phrase hints by its
`custom_class_id`.

=item * C<< $msg->abnf_grammar() >> / C<< $msg->abnf_grammar($value) >>

Type: C<Message> (L<Google::Cloud::Speech::V1::Resource::SpeechAdaptation::ABNFGrammar>)

Augmented Backus-Naur form (ABNF) is a standardized grammar notation
comprised by a set of derivation rules.
See specifications: https://www.w3.org/TR/speech-grammar

=back

=head2 Google::Cloud::Speech::V1::Resource::TranscriptNormalization

Transcription normalization configuration. Use transcription normalization
to automatically replace parts of the transcript with phrases of your
choosing. For StreamingRecognize, this normalization only applies to stable
partial transcripts (stability > 0.8) and final transcripts.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->entries() >> / C<< $msg->entries($value) >>

Type: C<Message> (L<Google::Cloud::Speech::V1::Resource::TranscriptNormalization::Entry>)

A list of replacement entries. We will perform replacement with one entry
at a time. For example, the second entry in ["cat" => "dog", "mountain cat"
 => "mountain dog"] will never be applied because we will always process the
first entry before it. At most 100 entries.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Speech::V1::Resource::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
