package Google::Cloud::Notebooks::V2::GceSetup;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvbm90ZWJvb2tzL3YyL2djZV9zZXR1cC5wcm90bxIZZ29vZ2xlLmNs
b3VkLm5vdGVib29rcy52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90byLjAQoQ
TmV0d29ya0ludGVyZmFjZRIdCgduZXR3b3JrGAEgASgJQgPgQQFSB25ldHdvcmsSGwoGc3Vi
bmV0GAIgASgJQgPgQQFSBnN1Ym5ldBJTCghuaWNfdHlwZRgDIAEoDjIzLmdvb2dsZS5jbG91
ZC5ub3RlYm9va3MudjIuTmV0d29ya0ludGVyZmFjZS5OaWNUeXBlQgPgQQFSB25pY1R5cGUi
PgoHTmljVHlwZRIYChROSUNfVFlQRV9VTlNQRUNJRklFRBAAEg4KClZJUlRJT19ORVQQARIJ
CgVHVk5JQxACImsKB1ZtSW1hZ2USHQoHcHJvamVjdBgBIAEoCUID4EECUgdwcm9qZWN0EhkK
BG5hbWUYAiABKAlCA+BBAUgAUgRuYW1lEh0KBmZhbWlseRgDIAEoCUID4EEBSABSBmZhbWls
eUIHCgVpbWFnZSJMCg5Db250YWluZXJJbWFnZRIjCgpyZXBvc2l0b3J5GAEgASgJQgPgQQJS
CnJlcG9zaXRvcnkSFQoDdGFnGAIgASgJQgPgQQFSA3RhZyKlAwoRQWNjZWxlcmF0b3JDb25m
aWcSVQoEdHlwZRgBIAEoDjI8Lmdvb2dsZS5jbG91ZC5ub3RlYm9va3MudjIuQWNjZWxlcmF0
b3JDb25maWcuQWNjZWxlcmF0b3JUeXBlQgPgQQFSBHR5cGUSIgoKY29yZV9jb3VudBgCIAEo
A0ID4EEBUgljb3JlQ291bnQilAIKD0FjY2VsZXJhdG9yVHlwZRIgChxBQ0NFTEVSQVRPUl9U
WVBFX1VOU1BFQ0lGSUVEEAASFQoRTlZJRElBX1RFU0xBX1AxMDAQAhIVChFOVklESUFfVEVT
TEFfVjEwMBADEhMKD05WSURJQV9URVNMQV9QNBAEEhMKD05WSURJQV9URVNMQV9UNBAFEhUK
EU5WSURJQV9URVNMQV9BMTAwEAsSFAoQTlZJRElBX0ExMDBfODBHQhAMEg0KCU5WSURJQV9M
NBANEhcKE05WSURJQV9URVNMQV9UNF9WV1MQCBIZChVOVklESUFfVEVTTEFfUDEwMF9WV1MQ
CRIXChNOVklESUFfVEVTTEFfUDRfVldTEAoitgEKFlNoaWVsZGVkSW5zdGFuY2VDb25maWcS
MQoSZW5hYmxlX3NlY3VyZV9ib290GAEgASgIQgPgQQFSEGVuYWJsZVNlY3VyZUJvb3QSJAoL
ZW5hYmxlX3Z0cG0YAiABKAhCA+BBAVIKZW5hYmxlVnRwbRJDChtlbmFibGVfaW50ZWdyaXR5
X21vbml0b3JpbmcYAyABKAhCA+BBAVIZZW5hYmxlSW50ZWdyaXR5TW9uaXRvcmluZyJ8Cg9H
UFVEcml2ZXJDb25maWcSLwoRZW5hYmxlX2dwdV9kcml2ZXIYASABKAhCA+BBAVIPZW5hYmxl
R3B1RHJpdmVyEjgKFmN1c3RvbV9ncHVfZHJpdmVyX3BhdGgYAiABKAlCA+BBAVITY3VzdG9t
R3B1RHJpdmVyUGF0aCL4AQoIRGF0YURpc2sSJQoMZGlza19zaXplX2diGAEgASgDQgPgQQFS
CmRpc2tTaXplR2ISSAoJZGlza190eXBlGAIgASgOMiMuZ29vZ2xlLmNsb3VkLm5vdGVib29r
cy52Mi5EaXNrVHlwZUIG4EEE4EEBUghkaXNrVHlwZRJaCg9kaXNrX2VuY3J5cHRpb24YBSAB
KA4yKS5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYyLkRpc2tFbmNyeXB0aW9uQgbgQQTgQQFS
DmRpc2tFbmNyeXB0aW9uEh8KB2ttc19rZXkYBiABKAlCBuBBBOBBAVIGa21zS2V5IvUBCghC
b290RGlzaxIlCgxkaXNrX3NpemVfZ2IYASABKANCA+BBAVIKZGlza1NpemVHYhJFCglkaXNr
X3R5cGUYAiABKA4yIy5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYyLkRpc2tUeXBlQgPgQQFS
CGRpc2tUeXBlEloKD2Rpc2tfZW5jcnlwdGlvbhgDIAEoDjIpLmdvb2dsZS5jbG91ZC5ub3Rl
Ym9va3MudjIuRGlza0VuY3J5cHRpb25CBuBBBOBBAVIOZGlza0VuY3J5cHRpb24SHwoHa21z
X2tleRgEIAEoCUIG4EEE4EEBUgZrbXNLZXkiSAoOU2VydmljZUFjY291bnQSGQoFZW1haWwY
ASABKAlCA+BBAVIFZW1haWwSGwoGc2NvcGVzGAIgAygJQgPgQQNSBnNjb3BlcyLtCAoIR2Nl
U2V0dXASJgoMbWFjaGluZV90eXBlGAEgASgJQgPgQQFSC21hY2hpbmVUeXBlEmIKE2FjY2Vs
ZXJhdG9yX2NvbmZpZ3MYAiADKAsyLC5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYyLkFjY2Vs
ZXJhdG9yQ29uZmlnQgPgQQFSEmFjY2VsZXJhdG9yQ29uZmlncxJZChBzZXJ2aWNlX2FjY291
bnRzGAMgAygLMikuZ29vZ2xlLmNsb3VkLm5vdGVib29rcy52Mi5TZXJ2aWNlQWNjb3VudEID
4EEBUg9zZXJ2aWNlQWNjb3VudHMSRAoIdm1faW1hZ2UYBCABKAsyIi5nb29nbGUuY2xvdWQu
bm90ZWJvb2tzLnYyLlZtSW1hZ2VCA+BBAUgAUgd2bUltYWdlElkKD2NvbnRhaW5lcl9pbWFn
ZRgFIAEoCzIpLmdvb2dsZS5jbG91ZC5ub3RlYm9va3MudjIuQ29udGFpbmVySW1hZ2VCA+BB
AUgAUg5jb250YWluZXJJbWFnZRJFCglib290X2Rpc2sYBiABKAsyIy5nb29nbGUuY2xvdWQu
bm90ZWJvb2tzLnYyLkJvb3REaXNrQgPgQQFSCGJvb3REaXNrEkcKCmRhdGFfZGlza3MYByAD
KAsyIy5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYyLkRhdGFEaXNrQgPgQQFSCWRhdGFEaXNr
cxJwChhzaGllbGRlZF9pbnN0YW5jZV9jb25maWcYCCABKAsyMS5nb29nbGUuY2xvdWQubm90
ZWJvb2tzLnYyLlNoaWVsZGVkSW5zdGFuY2VDb25maWdCA+BBAVIWc2hpZWxkZWRJbnN0YW5j
ZUNvbmZpZxJfChJuZXR3b3JrX2ludGVyZmFjZXMYCSADKAsyKy5nb29nbGUuY2xvdWQubm90
ZWJvb2tzLnYyLk5ldHdvcmtJbnRlcmZhY2VCA+BBAVIRbmV0d29ya0ludGVyZmFjZXMSLwoR
ZGlzYWJsZV9wdWJsaWNfaXAYCiABKAhCA+BBAVIPZGlzYWJsZVB1YmxpY0lwEhcKBHRhZ3MY
CyADKAlCA+BBAVIEdGFncxJSCghtZXRhZGF0YRgMIAMoCzIxLmdvb2dsZS5jbG91ZC5ub3Rl
Ym9va3MudjIuR2NlU2V0dXAuTWV0YWRhdGFFbnRyeUID4EEBUghtZXRhZGF0YRI1ChRlbmFi
bGVfaXBfZm9yd2FyZGluZxgNIAEoCEID4EEBUhJlbmFibGVJcEZvcndhcmRpbmcSWwoRZ3B1
X2RyaXZlcl9jb25maWcYDiABKAsyKi5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYyLkdQVURy
aXZlckNvbmZpZ0ID4EEBUg9ncHVEcml2ZXJDb25maWcaOwoNTWV0YWRhdGFFbnRyeRIQCgNr
ZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBQgcKBWltYWdlKkUKDkRp
c2tFbmNyeXB0aW9uEh8KG0RJU0tfRU5DUllQVElPTl9VTlNQRUNJRklFRBAAEggKBEdNRUsQ
ARIICgRDTUVLEAIqYwoIRGlza1R5cGUSGQoVRElTS19UWVBFX1VOU1BFQ0lGSUVEEAASDwoL
UERfU1RBTkRBUkQQARIKCgZQRF9TU0QQAhIPCgtQRF9CQUxBTkNFRBADEg4KClBEX0VYVFJF
TUUQBELEAQodY29tLmdvb2dsZS5jbG91ZC5ub3RlYm9va3MudjJCDUdjZVNldHVwUHJvdG9Q
AVo7Y2xvdWQuZ29vZ2xlLmNvbS9nby9ub3RlYm9va3MvYXBpdjIvbm90ZWJvb2tzcGI7bm90
ZWJvb2tzcGKqAhlHb29nbGUuQ2xvdWQuTm90ZWJvb2tzLlYyygIZR29vZ2xlXENsb3VkXE5v
dGVib29rc1xWMuoCHEdvb2dsZTo6Q2xvdWQ6Ok5vdGVib29rczo6VjJK3mYKBxIFDgDTAgEK
vAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5k
ZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5
b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhl
IExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAg
ICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNz
IHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBz
b2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQg
b24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05T
IE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNl
bnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFu
ZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACIKCQoCAwASAxIA
KQoICgEIEgMUADYKCQoCCCUSAxQANgoICgEIEgMVAFIKCQoCCAsSAxUAUgoICgEIEgMWACIK
CQoCCAoSAxYAIgoICgEIEgMXAC4KCQoCCAgSAxcALgoICgEIEgMYADYKCQoCCAESAxgANgoI
CgEIEgMZADYKCQoCCCkSAxkANgoICgEIEgMaADUKCQoCCC0SAxoANQpOCgIEABIEHQA4ARpC
IFRoZSBkZWZpbml0aW9uIG9mIGEgbmV0d29yayBpbnRlcmZhY2UgcmVzb3VyY2UgYXR0YWNo
ZWQgdG8gYSBWTS4KCgoKAwQAARIDHQgYClEKBAQABAASBCACKQMaQyBUaGUgdHlwZSBvZiB2
TklDIGRyaXZlci4KIERlZmF1bHQgc2hvdWxkIGJlIE5JQ19UWVBFX1VOU1BFQ0lGSUVELgoK
DAoFBAAEAAESAyAHDgojCgYEAAQAAgASAyIEHRoUIE5vIHR5cGUgc3BlY2lmaWVkLgoKDgoH
BAAEAAIAARIDIgQYCg4KBwQABAACAAISAyIbHAoXCgYEAAQAAgESAyUEExoIIFZJUlRJTwoK
DgoHBAAEAAIBARIDJQQOCg4KBwQABAACAQISAyUREgoWCgYEAAQAAgISAygEDhoHIEdWTklD
CgoOCgcEAAQAAgIBEgMoBAkKDgoHBAAEAAICAhIDKAwNCogBCgQEAAIAEgMuAj4aeyBPcHRp
b25hbC4gVGhlIG5hbWUgb2YgdGhlIFZQQyB0aGF0IHRoaXMgVk0gaW5zdGFuY2UgaXMgaW4u
CiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2dsb2JhbC9uZXR3b3Jrcy97bmV0
d29ya19pZH1gCgoMCgUEAAIABRIDLgIICgwKBQQAAgABEgMuCRAKDAoFBAACAAMSAy4TFAoM
CgUEAAIACBIDLhU9Cg8KCAQAAgAInAgAEgMuFjwKnAEKBAQAAgESAzMCPRqOASBPcHRpb25h
bC4gVGhlIG5hbWUgb2YgdGhlIHN1Ym5ldCB0aGF0IHRoaXMgVk0gaW5zdGFuY2UgaXMgaW4u
CiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L3JlZ2lvbnMve3JlZ2lvbn0vc3Vi
bmV0d29ya3Mve3N1Ym5ldHdvcmtfaWR9YAoKDAoFBAACAQUSAzMCCAoMCgUEAAIBARIDMwkP
CgwKBQQAAgEDEgMzEhMKDAoFBAACAQgSAzMUPAoPCggEAAIBCJwIABIDMxU7CmgKBAQAAgIS
AzcCQBpbIE9wdGlvbmFsLiBUaGUgdHlwZSBvZiB2TklDIHRvIGJlIHVzZWQgb24gdGhpcyBp
bnRlcmZhY2UuIFRoaXMgbWF5IGJlIGdWTklDCiBvciBWaXJ0aW9OZXQuCgoMCgUEAAICBhID
NwIJCgwKBQQAAgIBEgM3ChIKDAoFBAACAgMSAzcVFgoMCgUEAAICCBIDNxc/Cg8KCAQAAgII
nAgAEgM3GD4KnwEKAgQBEgQ8AEoBGpIBIERlZmluaXRpb24gb2YgYSBjdXN0b20gQ29tcHV0
ZSBFbmdpbmUgdmlydHVhbCBtYWNoaW5lIGltYWdlIGZvciBzdGFydGluZyBhCiBub3RlYm9v
ayBpbnN0YW5jZSB3aXRoIHRoZSBlbnZpcm9ubWVudCBpbnN0YWxsZWQgZGlyZWN0bHkgb24g
dGhlIFZNLgoKCgoDBAEBEgM8CA8KdAoEBAECABIDPwI+GmcgUmVxdWlyZWQuIFRoZSBuYW1l
IG9mIHRoZSBHb29nbGUgQ2xvdWQgcHJvamVjdCB0aGF0IHRoaXMgVk0gaW1hZ2UgYmVsb25n
cwogdG8uIEZvcm1hdDogYHtwcm9qZWN0X2lkfWAKCgwKBQQBAgAFEgM/AggKDAoFBAECAAES
Az8JEAoMCgUEAQIAAxIDPxMUCgwKBQQBAgAIEgM/FT0KDwoIBAECAAicCAASAz8WPApFCgQE
AQgAEgRCAkkDGjcgVGhlIHJlZmVyZW5jZSB0byBhbiBleHRlcm5hbCBDb21wdXRlIEVuZ2lu
ZSBWTSBpbWFnZS4KCgwKBQQBCAABEgNCCA0KPQoEBAECARIDRAQ9GjAgT3B0aW9uYWwuIFVz
ZSBWTSBpbWFnZSBuYW1lIHRvIGZpbmQgdGhlIGltYWdlLgoKDAoFBAECAQUSA0QECgoMCgUE
AQIBARIDRAsPCgwKBQQBAgEDEgNEEhMKDAoFBAECAQgSA0QUPAoPCggEAQIBCJwIABIDRBU7
CnMKBAQBAgISA0gEPxpmIE9wdGlvbmFsLiBVc2UgdGhpcyBWTSBpbWFnZSBmYW1pbHkgdG8g
ZmluZCB0aGUgaW1hZ2U7IHRoZSBuZXdlc3QgaW1hZ2UgaW4KIHRoaXMgZmFtaWx5IHdpbGwg
YmUgdXNlZC4KCgwKBQQBAgIFEgNIBAoKDAoFBAECAgESA0gLEQoMCgUEAQICAxIDSBQVCgwK
BQQBAgIIEgNIFj4KDwoIBAECAgicCAASA0gXPQp+CgIEAhIETgBWARpyIERlZmluaXRpb24g
b2YgYSBjb250YWluZXIgaW1hZ2UgZm9yIHN0YXJ0aW5nIGEgbm90ZWJvb2sgaW5zdGFuY2Ug
d2l0aCB0aGUKIGVudmlyb25tZW50IGluc3RhbGxlZCBpbiBhIGNvbnRhaW5lci4KCgoKAwQC
ARIDTggWCnUKBAQCAgASA1ECQRpoIFJlcXVpcmVkLiBUaGUgcGF0aCB0byB0aGUgY29udGFp
bmVyIGltYWdlIHJlcG9zaXRvcnkuIEZvciBleGFtcGxlOgogYGdjci5pby97cHJvamVjdF9p
ZH0ve2ltYWdlX25hbWV9YAoKDAoFBAICAAUSA1ECCAoMCgUEAgIAARIDUQkTCgwKBQQCAgAD
EgNRFhcKDAoFBAICAAgSA1EYQAoPCggEAgIACJwIABIDURk/CmwKBAQCAgESA1UCOhpfIE9w
dGlvbmFsLiBUaGUgdGFnIG9mIHRoZSBjb250YWluZXIgaW1hZ2UuIElmIG5vdCBzcGVjaWZp
ZWQsIHRoaXMgZGVmYXVsdHMKIHRvIHRoZSBsYXRlc3QgdGFnLgoKDAoFBAICAQUSA1UCCAoM
CgUEAgIBARIDVQkMCgwKBQQCAgEDEgNVDxAKDAoFBAICAQgSA1UROQoPCggEAgIBCJwIABID
VRI4CrcCCgIEAxIFXgCJAQEaqQIgQW4gYWNjZWxlcmF0b3IgY29uZmlndXJhdGlvbiBmb3Ig
YSBWTSBpbnN0YW5jZQogRGVmaW5pdGlvbiBvZiBhIGhhcmR3YXJlIGFjY2VsZXJhdG9yLiBO
b3RlIHRoYXQgdGhlcmUgaXMgbm8gY2hlY2sgb24gYHR5cGVgCiBhbmQgYGNvcmVfY291bnRg
IGNvbWJpbmF0aW9ucy4gVFBVcyBhcmUgbm90IHN1cHBvcnRlZC4KIFNlZSBbR1BVcyBvbiBD
b21wdXRlCiBFbmdpbmVdKGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9jb21wdXRlL2RvY3Mv
Z3B1cy8jZ3B1cy1saXN0KSB0byBmaW5kIGEKIHZhbGlkIGNvbWJpbmF0aW9uLgoKCgoDBAMB
EgNeCBkKZQoEBAMEABIFYQKCAQMaViBEZWZpbml0aW9uIG9mIHRoZSB0eXBlcyBvZiBoYXJk
d2FyZSBhY2NlbGVyYXRvcnMgdGhhdCBjYW4gYmUgdXNlZCBvbgogdGhpcyBpbnN0YW5jZS4K
CgwKBQQDBAABEgNhBxYKMwoGBAMEAAIAEgNjBCUaJCBBY2NlbGVyYXRvciB0eXBlIGlzIG5v
dCBzcGVjaWZpZWQuCgoOCgcEAwQAAgABEgNjBCAKDgoHBAMEAAIAAhIDYyMkCjcKBgQDBAAC
ARIDZgQaGiggQWNjZWxlcmF0b3IgdHlwZSBpcyBOdmlkaWEgVGVzbGEgUDEwMC4KCg4KBwQD
BAACAQESA2YEFQoOCgcEAwQAAgECEgNmGBkKNwoGBAMEAAICEgNpBBoaKCBBY2NlbGVyYXRv
ciB0eXBlIGlzIE52aWRpYSBUZXNsYSBWMTAwLgoKDgoHBAMEAAICARIDaQQVCg4KBwQDBAAC
AgISA2kYGQo1CgYEAwQAAgMSA2wEGBomIEFjY2VsZXJhdG9yIHR5cGUgaXMgTnZpZGlhIFRl
c2xhIFA0LgoKDgoHBAMEAAIDARIDbAQTCg4KBwQDBAACAwISA2wWFwo1CgYEAwQAAgQSA28E
GBomIEFjY2VsZXJhdG9yIHR5cGUgaXMgTnZpZGlhIFRlc2xhIFQ0LgoKDgoHBAMEAAIEARID
bwQTCg4KBwQDBAACBAISA28WFwo+CgYEAwQAAgUSA3IEGxovIEFjY2VsZXJhdG9yIHR5cGUg
aXMgTnZpZGlhIFRlc2xhIEExMDAgLSA0MEdCLgoKDgoHBAMEAAIFARIDcgQVCg4KBwQDBAAC
BQISA3IYGgo+CgYEAwQAAgYSA3UEGhovIEFjY2VsZXJhdG9yIHR5cGUgaXMgTnZpZGlhIFRl
c2xhIEExMDAgLSA4MEdCLgoKDgoHBAMEAAIGARIDdQQUCg4KBwQDBAACBgISA3UXGQo1CgYE
AwQAAgcSA3gEExomIEFjY2VsZXJhdG9yIHR5cGUgaXMgTnZpZGlhIFRlc2xhIEw0LgoKDgoH
BAMEAAIHARIDeAQNCg4KBwQDBAACBwISA3gQEgpKCgYEAwQAAggSA3sEHBo7IEFjY2VsZXJh
dG9yIHR5cGUgaXMgTlZJRElBIFRlc2xhIFQ0IFZpcnR1YWwgV29ya3N0YXRpb25zLgoKDgoH
BAMEAAIIARIDewQXCg4KBwQDBAACCAISA3saGwpMCgYEAwQAAgkSA34EHho9IEFjY2VsZXJh
dG9yIHR5cGUgaXMgTlZJRElBIFRlc2xhIFAxMDAgVmlydHVhbCBXb3Jrc3RhdGlvbnMuCgoO
CgcEAwQAAgkBEgN+BBkKDgoHBAMEAAIJAhIDfhwdCksKBgQDBAACChIEgQEEHRo7IEFjY2Vs
ZXJhdG9yIHR5cGUgaXMgTlZJRElBIFRlc2xhIFA0IFZpcnR1YWwgV29ya3N0YXRpb25zLgoK
DwoHBAMEAAIKARIEgQEEFwoPCgcEAwQAAgoCEgSBARocCjMKBAQDAgASBIUBAkQaJSBPcHRp
b25hbC4gVHlwZSBvZiB0aGlzIGFjY2VsZXJhdG9yLgoKDQoFBAMCAAYSBIUBAhEKDQoFBAMC
AAESBIUBEhYKDQoFBAMCAAMSBIUBGRoKDQoFBAMCAAgSBIUBG0MKEAoIBAMCAAicCAASBIUB
HEIKPQoEBAMCARIEiAECQBovIE9wdGlvbmFsLiBDb3VudCBvZiBjb3JlcyBvZiB0aGlzIGFj
Y2VsZXJhdG9yLgoKDQoFBAMCAQUSBIgBAgcKDQoFBAMCAQESBIgBCBIKDQoFBAMCAQMSBIgB
FRYKDQoFBAMCAQgSBIgBFz8KEAoIBAMCAQicCAASBIgBGD4K0QEKAgQEEgaPAQCiAQEawgEg
QSBzZXQgb2YgU2hpZWxkZWQgSW5zdGFuY2Ugb3B0aW9ucy4KIFNlZSBbSW1hZ2VzIHVzaW5n
IHN1cHBvcnRlZCBTaGllbGRlZCBWTQogZmVhdHVyZXNdKGh0dHBzOi8vY2xvdWQuZ29vZ2xl
LmNvbS9jb21wdXRlL2RvY3MvaW5zdGFuY2VzL21vZGlmeWluZy1zaGllbGRlZC12bSkuCiBO
b3QgYWxsIGNvbWJpbmF0aW9ucyBhcmUgdmFsaWQuCgoLCgMEBAESBI8BCB4KqwIKBAQEAgAS
BJUBAkcanAIgT3B0aW9uYWwuIERlZmluZXMgd2hldGhlciB0aGUgVk0gaW5zdGFuY2UgaGFz
IFNlY3VyZSBCb290IGVuYWJsZWQuCgogU2VjdXJlIEJvb3QgaGVscHMgZW5zdXJlIHRoYXQg
dGhlIHN5c3RlbSBvbmx5IHJ1bnMgYXV0aGVudGljIHNvZnR3YXJlIGJ5CiB2ZXJpZnlpbmcg
dGhlIGRpZ2l0YWwgc2lnbmF0dXJlIG9mIGFsbCBib290IGNvbXBvbmVudHMsIGFuZCBoYWx0
aW5nIHRoZQogYm9vdCBwcm9jZXNzIGlmIHNpZ25hdHVyZSB2ZXJpZmljYXRpb24gZmFpbHMu
IERpc2FibGVkIGJ5IGRlZmF1bHQuCgoNCgUEBAIABRIElQECBgoNCgUEBAIAARIElQEHGQoN
CgUEBAIAAxIElQEcHQoNCgUEBAIACBIElQEeRgoQCggEBAIACJwIABIElQEfRQpkCgQEBAIB
EgSZAQJAGlYgT3B0aW9uYWwuIERlZmluZXMgd2hldGhlciB0aGUgVk0gaW5zdGFuY2UgaGFz
IHRoZSB2VFBNIGVuYWJsZWQuIEVuYWJsZWQgYnkKIGRlZmF1bHQuCgoNCgUEBAIBBRIEmQEC
BgoNCgUEBAIBARIEmQEHEgoNCgUEBAIBAxIEmQEVFgoNCgUEBAIBCBIEmQEXPwoQCggEBAIB
CJwIABIEmQEYPgrxAgoEBAQCAhIEoQECUBriAiBPcHRpb25hbC4gRGVmaW5lcyB3aGV0aGVy
IHRoZSBWTSBpbnN0YW5jZSBoYXMgaW50ZWdyaXR5IG1vbml0b3JpbmcgZW5hYmxlZC4KCiBF
bmFibGVzIG1vbml0b3JpbmcgYW5kIGF0dGVzdGF0aW9uIG9mIHRoZSBib290IGludGVncml0
eSBvZiB0aGUgVk0KIGluc3RhbmNlLiBUaGUgYXR0ZXN0YXRpb24gaXMgcGVyZm9ybWVkIGFn
YWluc3QgdGhlIGludGVncml0eSBwb2xpY3kKIGJhc2VsaW5lLiBUaGlzIGJhc2VsaW5lIGlz
IGluaXRpYWxseSBkZXJpdmVkIGZyb20gdGhlIGltcGxpY2l0bHkgdHJ1c3RlZAogYm9vdCBp
bWFnZSB3aGVuIHRoZSBWTSBpbnN0YW5jZSBpcyBjcmVhdGVkLiBFbmFibGVkIGJ5IGRlZmF1
bHQuCgoNCgUEBAICBRIEoQECBgoNCgUEBAICARIEoQEHIgoNCgUEBAICAxIEoQElJgoNCgUE
BAICCBIEoQEnTwoQCggEBAICCJwIABIEoQEoTgoqCgIEBRIGpQEArwEBGhwgQSBHUFUgZHJp
dmVyIGNvbmZpZ3VyYXRpb24KCgsKAwQFARIEpQEIFwrnAQoEBAUCABIEqQECRhrYASBPcHRp
b25hbC4gV2hldGhlciB0aGUgZW5kIHVzZXIgYXV0aG9yaXplcyBHb29nbGUgQ2xvdWQgdG8g
aW5zdGFsbCBHUFUKIGRyaXZlciBvbiB0aGlzIFZNIGluc3RhbmNlLiBJZiB0aGlzIGZpZWxk
IGlzIGVtcHR5IG9yIHNldCB0byBmYWxzZSwgdGhlIEdQVQogZHJpdmVyIHdvbid0IGJlIGlu
c3RhbGxlZC4gT25seSBhcHBsaWNhYmxlIHRvIGluc3RhbmNlcyB3aXRoIEdQVXMuCgoNCgUE
BQIABRIEqQECBgoNCgUEBQIAARIEqQEHGAoNCgUEBQIAAxIEqQEbHAoNCgUEBQIACBIEqQEd
RQoQCggEBQIACJwIABIEqQEeRAqoAQoEBAUCARIErgECTRqZASBPcHRpb25hbC4gU3BlY2lm
eSBhIGN1c3RvbSBDbG91ZCBTdG9yYWdlIHBhdGggd2hlcmUgdGhlIEdQVSBkcml2ZXIgaXMK
IHN0b3JlZC4gSWYgbm90IHNwZWNpZmllZCwgd2UnbGwgYXV0b21hdGljYWxseSBjaG9vc2Ug
ZnJvbSBvZmZpY2lhbCBHUFUKIGRyaXZlcnMuCgoNCgUEBQIBBRIErgECCAoNCgUEBQIBARIE
rgEJHwoNCgUEBQIBAxIErgEiIwoNCgUEBQIBCBIErgEkTAoQCggEBQIBCJwIABIErgElSwoz
CgIEBhIGsgEAzQEBGiUgQW4gaW5zdGFuY2UtYXR0YWNoZWQgZGlzayByZXNvdXJjZS4KCgsK
AwQGARIEsgEIEAqhAQoEBAYCABIEtQECQhqSASBPcHRpb25hbC4gVGhlIHNpemUgb2YgdGhl
IGRpc2sgaW4gR0IgYXR0YWNoZWQgdG8gdGhpcyBWTSBpbnN0YW5jZSwgdXAgdG8gYQogbWF4
aW11bSBvZiA2NDAwMCBHQiAoNjQgVEIpLiBJZiBub3Qgc3BlY2lmaWVkLCB0aGlzIGRlZmF1
bHRzIHRvIDEwMC4KCg0KBQQGAgAFEgS1AQIHCg0KBQQGAgABEgS1AQgUCg0KBQQGAgADEgS1
ARcYCg0KBQQGAgAIEgS1ARlBChAKCAQGAgAInAgAEgS1ARpACkcKBAQGAgESBrgBArsBBBo3
IE9wdGlvbmFsLiBJbnB1dCBvbmx5LiBJbmRpY2F0ZXMgdGhlIHR5cGUgb2YgdGhlIGRpc2su
CgoNCgUEBgIBBhIEuAECCgoNCgUEBgIBARIEuAELFAoNCgUEBgIBAxIEuAEXGAoPCgUEBgIB
CBIGuAEZuwEDChAKCAQGAgEInAgAEgS5AQQsChAKCAQGAgEInAgBEgS6AQQqCnIKBAQGAgIS
Br8BAsIBBBpiIE9wdGlvbmFsLiBJbnB1dCBvbmx5LiBEaXNrIGVuY3J5cHRpb24gbWV0aG9k
IHVzZWQgb24gdGhlIGJvb3QgYW5kIGRhdGEKIGRpc2tzLCBkZWZhdWx0cyB0byBHTUVLLgoK
DQoFBAYCAgYSBL8BAhAKDQoFBAYCAgESBL8BESAKDQoFBAYCAgMSBL8BIyQKDwoFBAYCAggS
Br8BJcIBAwoQCggEBgICCJwIABIEwAEELAoQCggEBgICCJwIARIEwQEEKgqQAgoEBAYCAxIG
yQECzAEEGv8BIE9wdGlvbmFsLiBJbnB1dCBvbmx5LiBUaGUgS01TIGtleSB1c2VkIHRvIGVu
Y3J5cHQgdGhlIGRpc2tzLCBvbmx5CiBhcHBsaWNhYmxlIGlmIGRpc2tfZW5jcnlwdGlvbiBp
cyBDTUVLLiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9j
YXRpb259L2tleVJpbmdzL3trZXlfcmluZ19pZH0vY3J5cHRvS2V5cy97a2V5X2lkfWAKCiBM
ZWFybiBtb3JlIGFib3V0IHVzaW5nIHlvdXIgb3duIGVuY3J5cHRpb24ga2V5cy4KCg0KBQQG
AgMFEgTJAQIICg0KBQQGAgMBEgTJAQkQCg0KBQQGAgMDEgTJARMUCg8KBQQGAgMIEgbJARXM
AQMKEAoIBAYCAwicCAASBMoBBCwKEAoIBAYCAwicCAESBMsBBCoKLgoCBAcSBtABAOkBARog
IFRoZSBkZWZpbml0aW9uIG9mIGEgYm9vdCBkaXNrLgoKCwoDBAcBEgTQAQgQCr8BCgQEBwIA
EgTUAQJCGrABIE9wdGlvbmFsLiBUaGUgc2l6ZSBvZiB0aGUgYm9vdCBkaXNrIGluIEdCIGF0
dGFjaGVkIHRvIHRoaXMgaW5zdGFuY2UsIHVwIHRvCiBhIG1heGltdW0gb2YgNjQwMDAgR0Ig
KDY0IFRCKS4gSWYgbm90IHNwZWNpZmllZCwgdGhpcyBkZWZhdWx0cyB0byB0aGUKIHJlY29t
bWVuZGVkIHZhbHVlIG9mIDE1MEdCLgoKDQoFBAcCAAUSBNQBAgcKDQoFBAcCAAESBNQBCBQK
DQoFBAcCAAMSBNQBFxgKDQoFBAcCAAgSBNQBGUEKEAoIBAcCAAicCAASBNQBGkAKOQoEBAcC
ARIE1wECQhorIE9wdGlvbmFsLiBJbmRpY2F0ZXMgdGhlIHR5cGUgb2YgdGhlIGRpc2suCgoN
CgUEBwIBBhIE1wECCgoNCgUEBwIBARIE1wELFAoNCgUEBwIBAxIE1wEXGAoNCgUEBwIBCBIE
1wEZQQoQCggEBwIBCJwIABIE1wEaQApyCgQEBwICEgbbAQLeAQQaYiBPcHRpb25hbC4gSW5w
dXQgb25seS4gRGlzayBlbmNyeXB0aW9uIG1ldGhvZCB1c2VkIG9uIHRoZSBib290IGFuZCBk
YXRhCiBkaXNrcywgZGVmYXVsdHMgdG8gR01FSy4KCg0KBQQHAgIGEgTbAQIQCg0KBQQHAgIB
EgTbAREgCg0KBQQHAgIDEgTbASMkCg8KBQQHAgIIEgbbASXeAQMKEAoIBAcCAgicCAASBNwB
BCwKEAoIBAcCAgicCAESBN0BBCoKkAIKBAQHAgMSBuUBAugBBBr/ASBPcHRpb25hbC4gSW5w
dXQgb25seS4gVGhlIEtNUyBrZXkgdXNlZCB0byBlbmNyeXB0IHRoZSBkaXNrcywgb25seQog
YXBwbGljYWJsZSBpZiBkaXNrX2VuY3J5cHRpb24gaXMgQ01FSy4gRm9ybWF0OgogYHByb2pl
Y3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9ufS9rZXlSaW5ncy97a2V5X3Jp
bmdfaWR9L2NyeXB0b0tleXMve2tleV9pZH1gCgogTGVhcm4gbW9yZSBhYm91dCB1c2luZyB5
b3VyIG93biBlbmNyeXB0aW9uIGtleXMuCgoNCgUEBwIDBRIE5QECCAoNCgUEBwIDARIE5QEJ
EAoNCgUEBwIDAxIE5QETFAoPCgUEBwIDCBIG5QEV6AEDChAKCAQHAgMInAgAEgTmAQQsChAK
CAQHAgMInAgBEgTnAQQqCjsKAgQIEgbsAQDzAQEaLSBBIHNlcnZpY2UgYWNjb3VudCB0aGF0
IGFjdHMgYXMgYW4gaWRlbnRpdHkuCgoLCgMECAESBOwBCBYKPwoEBAgCABIE7gECPBoxIE9w
dGlvbmFsLiBFbWFpbCBhZGRyZXNzIG9mIHRoZSBzZXJ2aWNlIGFjY291bnQuCgoNCgUECAIA
BRIE7gECCAoNCgUECAIAARIE7gEJDgoNCgUECAIAAxIE7gEREgoNCgUECAIACBIE7gETOwoQ
CggECAIACJwIABIE7gEUOgqhAQoEBAgCARIE8gECSRqSASBPdXRwdXQgb25seS4gVGhlIGxp
c3Qgb2Ygc2NvcGVzIHRvIGJlIG1hZGUgYXZhaWxhYmxlIGZvciB0aGlzIHNlcnZpY2UKIGFj
Y291bnQuIFNldCBieSB0aGUgQ0xIIHRvIGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1
dGgvY2xvdWQtcGxhdGZvcm0KCg0KBQQIAgEEEgTyAQIKCg0KBQQIAgEFEgTyAQsRCg0KBQQI
AgEBEgTyARIYCg0KBQQIAgEDEgTyARscCg0KBQQIAgEIEgTyAR1IChAKCAQIAgEInAgAEgTy
AR5HCmQKAgQJEgb3AQC1AgEaViBUaGUgZGVmaW5pdGlvbiBvZiBob3cgdG8gY29uZmlndXJl
IGEgVk0gaW5zdGFuY2Ugb3V0c2lkZSBvZiBSZXNvdXJjZXMgYW5kCiBJZGVudGl0eS4KCgsK
AwQJARIE9wEIEAp2CgQECQIAEgT6AQJDGmggT3B0aW9uYWwuIFRoZSBtYWNoaW5lIHR5cGUg
b2YgdGhlIFZNIGluc3RhbmNlLgogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2NvbXB1dGUv
ZG9jcy9tYWNoaW5lLXJlc291cmNlCgoNCgUECQIABRIE+gECCAoNCgUECQIAARIE+gEJFQoN
CgUECQIAAxIE+gEYGQoNCgUECQIACBIE+gEaQgoQCggECQIACJwIABIE+gEbQQrJAgoEBAkC
ARIGgQICggIvGrgCIE9wdGlvbmFsLiBUaGUgaGFyZHdhcmUgYWNjZWxlcmF0b3JzIHVzZWQg
b24gdGhpcyBpbnN0YW5jZS4gSWYgeW91IHVzZQogYWNjZWxlcmF0b3JzLCBtYWtlIHN1cmUg
dGhhdCB5b3VyIGNvbmZpZ3VyYXRpb24gaGFzCiBbZW5vdWdoIHZDUFVzIGFuZCBtZW1vcnkg
dG8gc3VwcG9ydCB0aGUgYG1hY2hpbmVfdHlwZWAgeW91IGhhdmUKIHNlbGVjdGVkXShodHRw
czovL2Nsb3VkLmdvb2dsZS5jb20vY29tcHV0ZS9kb2NzL2dwdXMvI2dwdXMtbGlzdCkuCiBD
dXJyZW50bHkgc3VwcG9ydHMgb25seSBvbmUgYWNjZWxlcmF0b3IgY29uZmlndXJhdGlvbi4K
Cg0KBQQJAgEEEgSBAgIKCg0KBQQJAgEGEgSBAgscCg0KBQQJAgEBEgSBAh0wCg0KBQQJAgED
EgSBAjM0Cg0KBQQJAgEIEgSCAgYuChAKCAQJAgEInAgAEgSCAgctCo0BCgQECQICEgaGAgKH
Ai8afSBPcHRpb25hbC4gVGhlIHNlcnZpY2UgYWNjb3VudCB0aGF0IHNlcnZlcyBhcyBhbiBp
ZGVudGl0eSBmb3IgdGhlIFZNCiBpbnN0YW5jZS4gQ3VycmVudGx5IHN1cHBvcnRzIG9ubHkg
b25lIHNlcnZpY2UgYWNjb3VudC4KCg0KBQQJAgIEEgSGAgIKCg0KBQQJAgIGEgSGAgsZCg0K
BQQJAgIBEgSGAhoqCg0KBQQJAgIDEgSGAi0uCg0KBQQJAgIIEgSHAgYuChAKCAQJAgIInAgA
EgSHAgctClAKBAQJCAASBooCApACAxpAIFR5cGUgb2YgdGhlIGltYWdlOyBjYW4gYmUgb25l
IG9mIFZNIGltYWdlLCBvciBjb250YWluZXIgaW1hZ2UuCgoNCgUECQgAARIEigIIDQpXCgQE
CQIDEgSMAgRCGkkgT3B0aW9uYWwuIFVzZSBhIENvbXB1dGUgRW5naW5lIFZNIGltYWdlIHRv
IHN0YXJ0IHRoZSBub3RlYm9vayBpbnN0YW5jZS4KCg0KBQQJAgMGEgSMAgQLCg0KBQQJAgMB
EgSMAgwUCg0KBQQJAgMDEgSMAhcYCg0KBQQJAgMIEgSMAhlBChAKCAQJAgMInAgAEgSMAhpA
Ck8KBAQJAgQSBI8CBFAaQSBPcHRpb25hbC4gVXNlIGEgY29udGFpbmVyIGltYWdlIHRvIHN0
YXJ0IHRoZSBub3RlYm9vayBpbnN0YW5jZS4KCg0KBQQJAgQGEgSPAgQSCg0KBQQJAgQBEgSP
AhMiCg0KBQQJAgQDEgSPAiUmCg0KBQQJAgQIEgSPAidPChAKCAQJAgQInAgAEgSPAihOCjMK
BAQJAgUSBJMCAkIaJSBPcHRpb25hbC4gVGhlIGJvb3QgZGlzayBmb3IgdGhlIFZNLgoKDQoF
BAkCBQYSBJMCAgoKDQoFBAkCBQESBJMCCxQKDQoFBAkCBQMSBJMCFxgKDQoFBAkCBQgSBJMC
GUEKEAoIBAkCBQicCAASBJMCGkAKaQoEBAkCBhIElwICTBpbIE9wdGlvbmFsLiBEYXRhIGRp
c2tzIGF0dGFjaGVkIHRvIHRoZSBWTSBpbnN0YW5jZS4KIEN1cnJlbnRseSBzdXBwb3J0cyBv
bmx5IG9uZSBkYXRhIGRpc2suCgoNCgUECQIGBBIElwICCgoNCgUECQIGBhIElwILEwoNCgUE
CQIGARIElwIUHgoNCgUECQIGAxIElwIhIgoNCgUECQIGCBIElwIjSwoQCggECQIGCJwIABIE
lwIkSgqvAQoEBAkCBxIGnAICnQIvGp4BIE9wdGlvbmFsLiBTaGllbGRlZCBWTSBjb25maWd1
cmF0aW9uLgogW0ltYWdlcyB1c2luZyBzdXBwb3J0ZWQgU2hpZWxkZWQgVk0KIGZlYXR1cmVz
XShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vY29tcHV0ZS9kb2NzL2luc3RhbmNlcy9tb2Rp
Znlpbmctc2hpZWxkZWQtdm0pLgoKDQoFBAkCBwYSBJwCAhgKDQoFBAkCBwESBJwCGTEKDQoF
BAkCBwMSBJwCNDUKDQoFBAkCBwgSBJ0CBi4KEAoIBAkCBwicCAASBJ0CBy0KXAoEBAkCCBIG
oQICogIvGkwgT3B0aW9uYWwuIFRoZSBuZXR3b3JrIGludGVyZmFjZXMgZm9yIHRoZSBWTS4K
IFN1cHBvcnRzIG9ubHkgb25lIGludGVyZmFjZS4KCg0KBQQJAggEEgShAgIKCg0KBQQJAggG
EgShAgsbCg0KBQQJAggBEgShAhwuCg0KBQQJAggDEgShAjEyCg0KBQQJAggIEgSiAgYuChAK
CAQJAggInAgAEgSiAgctClcKBAQJAgkSBKUCAkcaSSBPcHRpb25hbC4gSWYgdHJ1ZSwgbm8g
ZXh0ZXJuYWwgSVAgd2lsbCBiZSBhc3NpZ25lZCB0byB0aGlzIFZNIGluc3RhbmNlLgoKDQoF
BAkCCQUSBKUCAgYKDQoFBAkCCQESBKUCBxgKDQoFBAkCCQMSBKUCGx0KDQoFBAkCCQgSBKUC
HkYKEAoIBAkCCQicCAASBKUCH0UKowEKBAQJAgoSBKkCAkUalAEgT3B0aW9uYWwuIFRoZSBD
b21wdXRlIEVuZ2luZSB0YWdzIHRvIGFkZCB0byBydW50aW1lIChzZWUgW1RhZ2dpbmcKIGlu
c3RhbmNlc10oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2NvbXB1dGUvZG9jcy9sYWJlbC1v
ci10YWctcmVzb3VyY2VzI3RhZ3MpKS4KCg0KBQQJAgoEEgSpAgIKCg0KBQQJAgoFEgSpAgsR
Cg0KBQQJAgoBEgSpAhIWCg0KBQQJAgoDEgSpAhkbCg0KBQQJAgoIEgSpAhxEChAKCAQJAgoI
nAgAEgSpAh1DCkQKBAQJAgsSBKwCAk0aNiBPcHRpb25hbC4gQ3VzdG9tIG1ldGFkYXRhIHRv
IGFwcGx5IHRvIHRoaXMgaW5zdGFuY2UuCgoNCgUECQILBhIErAICFQoNCgUECQILARIErAIW
HgoNCgUECQILAxIErAIhIwoNCgUECQILCBIErAIkTAoQCggECQILCJwIABIErAIlSwqPAQoE
BAkCDBIEsAICShqAASBPcHRpb25hbC4gRmxhZyB0byBlbmFibGUgaXAgZm9yd2FyZGluZyBv
ciBub3QsIGRlZmF1bHQgZmFsc2Uvb2ZmLgogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3Zw
Yy9kb2NzL3VzaW5nLXJvdXRlcyNjYW5pcGZvcndhcmQKCg0KBQQJAgwFEgSwAgIGCg0KBQQJ
AgwBEgSwAgcbCg0KBQQJAgwDEgSwAh4gCg0KBQQJAgwIEgSwAiFJChAKCAQJAgwInAgAEgSw
AiJICjoKBAQJAg0SBrMCArQCLxoqIE9wdGlvbmFsLiBDb25maWd1cmF0aW9uIGZvciBHUFUg
ZHJpdmVycy4KCg0KBQQJAg0GEgSzAgIRCg0KBQQJAg0BEgSzAhIjCg0KBQQJAg0DEgSzAiYo
Cg0KBQQJAg0IEgS0AgYuChAKCAQJAg0InAgAEgS0AgctCjoKAgUAEga4AgDBAgEaLCBEZWZp
bml0aW9uIG9mIHRoZSBkaXNrIGVuY3J5cHRpb24gb3B0aW9ucy4KCgsKAwUAARIEuAIFEwox
CgQFAAIAEgS6AgIiGiMgRGlzayBlbmNyeXB0aW9uIGlzIG5vdCBzcGVjaWZpZWQuCgoNCgUF
AAIAARIEugICHQoNCgUFAAIAAhIEugIgIQpMCgQFAAIBEgS9AgILGj4gVXNlIEdvb2dsZSBt
YW5hZ2VkIGVuY3J5cHRpb24ga2V5cyB0byBlbmNyeXB0IHRoZSBib290IGRpc2suCgoNCgUF
AAIBARIEvQICBgoNCgUFAAIBAhIEvQIJCgpOCgQFAAICEgTAAgILGkAgVXNlIGN1c3RvbWVy
IG1hbmFnZWQgZW5jcnlwdGlvbiBrZXlzIHRvIGVuY3J5cHQgdGhlIGJvb3QgZGlzay4KCg0K
BQUAAgIBEgTAAgIGCg0KBQUAAgICEgTAAgkKCiQKAgUBEgbEAgDTAgEaFiBQb3NzaWJsZSBk
aXNrIHR5cGVzLgoKCwoDBQEBEgTEAgUNCiIKBAUBAgASBMYCAhwaFCBEaXNrIHR5cGUgbm90
IHNldC4KCg0KBQUBAgABEgTGAgIXCg0KBQUBAgACEgTGAhobCi4KBAUBAgESBMkCAhIaICBT
dGFuZGFyZCBwZXJzaXN0ZW50IGRpc2sgdHlwZS4KCg0KBQUBAgEBEgTJAgINCg0KBQUBAgEC
EgTJAhARCikKBAUBAgISBMwCAg0aGyBTU0QgcGVyc2lzdGVudCBkaXNrIHR5cGUuCgoNCgUF
AQICARIEzAICCAoNCgUFAQICAhIEzAILDAouCgQFAQIDEgTPAgISGiAgQmFsYW5jZWQgcGVy
c2lzdGVudCBkaXNrIHR5cGUuCgoNCgUFAQIDARIEzwICDQoNCgUFAQIDAhIEzwIQEQotCgQF
AQIEEgTSAgIRGh8gRXh0cmVtZSBwZXJzaXN0ZW50IGRpc2sgdHlwZS4KCg0KBQUBAgQBEgTS
AgIMCg0KBQUBAgQCEgTSAg8QYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Notebooks::V2::GceSetup::NetworkInterface ===
    # Fields for NetworkInterface
    # Field: network Type: 9 ()
    # Field: subnet Type: 9 ()
    # Field: nic_type Type: 14 (.google.cloud.notebooks.v2.NetworkInterface.NicType)

# Enum: NetworkInterface::NicType
our $NetworkInterface_NIC_TYPE_UNSPECIFIED = 0;
our $NetworkInterface_VIRTIO_NET = 1;
our $NetworkInterface_GVNIC = 2;

# === Message: Google::Cloud::Notebooks::V2::GceSetup::VmImage ===
    # Fields for VmImage
    # Field: project Type: 9 ()
    # Field: name Type: 9 ()
    # Field: family Type: 9 ()

# === Message: Google::Cloud::Notebooks::V2::GceSetup::ContainerImage ===
    # Fields for ContainerImage
    # Field: repository Type: 9 ()
    # Field: tag Type: 9 ()

# === Message: Google::Cloud::Notebooks::V2::GceSetup::AcceleratorConfig ===
    # Fields for AcceleratorConfig
    # Field: type Type: 14 (.google.cloud.notebooks.v2.AcceleratorConfig.AcceleratorType)
    # Field: core_count Type: 3 ()

# Enum: AcceleratorConfig::AcceleratorType
our $AcceleratorConfig_ACCELERATOR_TYPE_UNSPECIFIED = 0;
our $AcceleratorConfig_NVIDIA_TESLA_P100 = 2;
our $AcceleratorConfig_NVIDIA_TESLA_V100 = 3;
our $AcceleratorConfig_NVIDIA_TESLA_P4 = 4;
our $AcceleratorConfig_NVIDIA_TESLA_T4 = 5;
our $AcceleratorConfig_NVIDIA_TESLA_A100 = 11;
our $AcceleratorConfig_NVIDIA_A100_80GB = 12;
our $AcceleratorConfig_NVIDIA_L4 = 13;
our $AcceleratorConfig_NVIDIA_TESLA_T4_VWS = 8;
our $AcceleratorConfig_NVIDIA_TESLA_P100_VWS = 9;
our $AcceleratorConfig_NVIDIA_TESLA_P4_VWS = 10;

# === Message: Google::Cloud::Notebooks::V2::GceSetup::ShieldedInstanceConfig ===
    # Fields for ShieldedInstanceConfig
    # Field: enable_secure_boot Type: 8 ()
    # Field: enable_vtpm Type: 8 ()
    # Field: enable_integrity_monitoring Type: 8 ()

# === Message: Google::Cloud::Notebooks::V2::GceSetup::GPUDriverConfig ===
    # Fields for GPUDriverConfig
    # Field: enable_gpu_driver Type: 8 ()
    # Field: custom_gpu_driver_path Type: 9 ()

# === Message: Google::Cloud::Notebooks::V2::GceSetup::DataDisk ===
    # Fields for DataDisk
    # Field: disk_size_gb Type: 3 ()
    # Field: disk_type Type: 14 (.google.cloud.notebooks.v2.DiskType)
    # Field: disk_encryption Type: 14 (.google.cloud.notebooks.v2.DiskEncryption)
    # Field: kms_key Type: 9 ()

# === Message: Google::Cloud::Notebooks::V2::GceSetup::BootDisk ===
    # Fields for BootDisk
    # Field: disk_size_gb Type: 3 ()
    # Field: disk_type Type: 14 (.google.cloud.notebooks.v2.DiskType)
    # Field: disk_encryption Type: 14 (.google.cloud.notebooks.v2.DiskEncryption)
    # Field: kms_key Type: 9 ()

# === Message: Google::Cloud::Notebooks::V2::GceSetup::ServiceAccount ===
    # Fields for ServiceAccount
    # Field: email Type: 9 ()
    # Field: scopes Type: 9 ()

# === Message: Google::Cloud::Notebooks::V2::GceSetup::GceSetup ===
    # Fields for GceSetup
    # Field: machine_type Type: 9 ()
    # Field: accelerator_configs Type: 11 (.google.cloud.notebooks.v2.AcceleratorConfig)
    # Field: service_accounts Type: 11 (.google.cloud.notebooks.v2.ServiceAccount)
    # Field: vm_image Type: 11 (.google.cloud.notebooks.v2.VmImage)
    # Field: container_image Type: 11 (.google.cloud.notebooks.v2.ContainerImage)
    # Field: boot_disk Type: 11 (.google.cloud.notebooks.v2.BootDisk)
    # Field: data_disks Type: 11 (.google.cloud.notebooks.v2.DataDisk)
    # Field: shielded_instance_config Type: 11 (.google.cloud.notebooks.v2.ShieldedInstanceConfig)
    # Field: network_interfaces Type: 11 (.google.cloud.notebooks.v2.NetworkInterface)
    # Field: disable_public_ip Type: 8 ()
    # Field: tags Type: 9 ()
    # Field: metadata Type: 11 (.google.cloud.notebooks.v2.GceSetup.MetadataEntry)
    # Field: enable_ip_forwarding Type: 8 ()
    # Field: gpu_driver_config Type: 11 (.google.cloud.notebooks.v2.GPUDriverConfig)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Notebooks::V2::GceSetup - Compiled Protocol Buffers messages for google/cloud/notebooks/v2/gce_setup.proto

=head1 SYNOPSIS

    use Google::Cloud::Notebooks::V2::GceSetup;

    my $msg = Google::Cloud::Notebooks::V2::GceSetup::NetworkInterface->new({
        network => $network,
        subnet => $subnet,
        nic_type => $nic_type,
    });

    # Read or update a field
    my $val = $msg->network();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Notebooks::V2::GceSetup::NetworkInterface->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/notebooks/v2/gce_setup.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Notebooks::V2::GceSetup::NetworkInterface

The definition of a network interface resource attached to a VM.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->network() >> / C<< $msg->network($value) >>

Type: C<String>

Optional. The name of the VPC that this VM instance is in.
Format:
`projects/{project_id}/global/networks/{network_id}`

=item * C<< $msg->subnet() >> / C<< $msg->subnet($value) >>

Type: C<String>

Optional. The name of the subnet that this VM instance is in.
Format:
`projects/{project_id}/regions/{region}/subnetworks/{subnetwork_id}`

=item * C<< $msg->nic_type() >> / C<< $msg->nic_type($value) >>

Type: C<Enum> (L<Google::Cloud::Notebooks::V2::NetworkInterface::NicType>)

Optional. The type of vNIC to be used on this interface. This may be gVNIC
or VirtioNet.

=back

=head3 Enum: NetworkInterface::NicType

=over 4

=item * C<NIC_TYPE_UNSPECIFIED> => C<0>

=item * C<VIRTIO_NET> => C<1>

=item * C<GVNIC> => C<2>

=back

=head2 Google::Cloud::Notebooks::V2::GceSetup::VmImage

Definition of a custom Compute Engine virtual machine image for starting a
notebook instance with the environment installed directly on the VM.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Required. The name of the Google Cloud project that this VM image belongs
to. Format: `{project_id}`

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Optional. Use VM image name to find the image.

=item * C<< $msg->family() >> / C<< $msg->family($value) >>

Type: C<String>

Optional. Use this VM image family to find the image; the newest image in
this family will be used.

=back

=head2 Google::Cloud::Notebooks::V2::GceSetup::ContainerImage

Definition of a container image for starting a notebook instance with the
environment installed in a container.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->repository() >> / C<< $msg->repository($value) >>

Type: C<String>

Required. The path to the container image repository. For example:
`gcr.io/{project_id}/{image_name}`

=item * C<< $msg->tag() >> / C<< $msg->tag($value) >>

Type: C<String>

Optional. The tag of the container image. If not specified, this defaults
to the latest tag.

=back

=head2 Google::Cloud::Notebooks::V2::GceSetup::AcceleratorConfig

An accelerator configuration for a VM instance
Definition of a hardware accelerator. Note that there is no check on `type`
and `core_count` combinations. TPUs are not supported.
See [GPUs on Compute
Engine](https://cloud.google.com/compute/docs/gpus/#gpus-list) to find a
valid combination.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Notebooks::V2::AcceleratorConfig::AcceleratorType>)

Optional. Type of this accelerator.

=item * C<< $msg->core_count() >> / C<< $msg->core_count($value) >>

Type: C<Int64>

Optional. Count of cores of this accelerator.

=back

=head3 Enum: AcceleratorConfig::AcceleratorType

=over 4

=item * C<ACCELERATOR_TYPE_UNSPECIFIED> => C<0>

=item * C<NVIDIA_TESLA_P100> => C<2>

=item * C<NVIDIA_TESLA_V100> => C<3>

=item * C<NVIDIA_TESLA_P4> => C<4>

=item * C<NVIDIA_TESLA_T4> => C<5>

=item * C<NVIDIA_TESLA_A100> => C<11>

=item * C<NVIDIA_A100_80GB> => C<12>

=item * C<NVIDIA_L4> => C<13>

=item * C<NVIDIA_TESLA_T4_VWS> => C<8>

=item * C<NVIDIA_TESLA_P100_VWS> => C<9>

=item * C<NVIDIA_TESLA_P4_VWS> => C<10>

=back

=head2 Google::Cloud::Notebooks::V2::GceSetup::ShieldedInstanceConfig

A set of Shielded Instance options.
See [Images using supported Shielded VM
features](https://cloud.google.com/compute/docs/instances/modifying-shielded-vm).
Not all combinations are valid.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enable_secure_boot() >> / C<< $msg->enable_secure_boot($value) >>

Type: C<Bool>

Optional. Defines whether the VM instance has Secure Boot enabled.

Secure Boot helps ensure that the system only runs authentic software by
verifying the digital signature of all boot components, and halting the
boot process if signature verification fails. Disabled by default.

=item * C<< $msg->enable_vtpm() >> / C<< $msg->enable_vtpm($value) >>

Type: C<Bool>

Optional. Defines whether the VM instance has the vTPM enabled. Enabled by
default.

=item * C<< $msg->enable_integrity_monitoring() >> / C<< $msg->enable_integrity_monitoring($value) >>

Type: C<Bool>

Optional. Defines whether the VM instance has integrity monitoring enabled.

Enables monitoring and attestation of the boot integrity of the VM
instance. The attestation is performed against the integrity policy
baseline. This baseline is initially derived from the implicitly trusted
boot image when the VM instance is created. Enabled by default.

=back

=head2 Google::Cloud::Notebooks::V2::GceSetup::GPUDriverConfig

A GPU driver configuration

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->enable_gpu_driver() >> / C<< $msg->enable_gpu_driver($value) >>

Type: C<Bool>

Optional. Whether the end user authorizes Google Cloud to install GPU
driver on this VM instance. If this field is empty or set to false, the GPU
driver won't be installed. Only applicable to instances with GPUs.

=item * C<< $msg->custom_gpu_driver_path() >> / C<< $msg->custom_gpu_driver_path($value) >>

Type: C<String>

Optional. Specify a custom Cloud Storage path where the GPU driver is
stored. If not specified, we'll automatically choose from official GPU
drivers.

=back

=head2 Google::Cloud::Notebooks::V2::GceSetup::DataDisk

An instance-attached disk resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->disk_size_gb() >> / C<< $msg->disk_size_gb($value) >>

Type: C<Int64>

Optional. The size of the disk in GB attached to this VM instance, up to a
maximum of 64000 GB (64 TB). If not specified, this defaults to 100.

=item * C<< $msg->disk_type() >> / C<< $msg->disk_type($value) >>

Type: C<Enum> (L<Google::Cloud::Notebooks::V2::DiskType>)

Optional. Input only. Indicates the type of the disk.

=item * C<< $msg->disk_encryption() >> / C<< $msg->disk_encryption($value) >>

Type: C<Enum> (L<Google::Cloud::Notebooks::V2::DiskEncryption>)

Optional. Input only. Disk encryption method used on the boot and data
disks, defaults to GMEK.

=item * C<< $msg->kms_key() >> / C<< $msg->kms_key($value) >>

Type: C<String>

Optional. Input only. The KMS key used to encrypt the disks, only
applicable if disk_encryption is CMEK. Format:
`projects/{project_id}/locations/{location}/keyRings/{key_ring_id}/cryptoKeys/{key_id}`

Learn more about using your own encryption keys.

=back

=head2 Google::Cloud::Notebooks::V2::GceSetup::BootDisk

The definition of a boot disk.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->disk_size_gb() >> / C<< $msg->disk_size_gb($value) >>

Type: C<Int64>

Optional. The size of the boot disk in GB attached to this instance, up to
a maximum of 64000 GB (64 TB). If not specified, this defaults to the
recommended value of 150GB.

=item * C<< $msg->disk_type() >> / C<< $msg->disk_type($value) >>

Type: C<Enum> (L<Google::Cloud::Notebooks::V2::DiskType>)

Optional. Indicates the type of the disk.

=item * C<< $msg->disk_encryption() >> / C<< $msg->disk_encryption($value) >>

Type: C<Enum> (L<Google::Cloud::Notebooks::V2::DiskEncryption>)

Optional. Input only. Disk encryption method used on the boot and data
disks, defaults to GMEK.

=item * C<< $msg->kms_key() >> / C<< $msg->kms_key($value) >>

Type: C<String>

Optional. Input only. The KMS key used to encrypt the disks, only
applicable if disk_encryption is CMEK. Format:
`projects/{project_id}/locations/{location}/keyRings/{key_ring_id}/cryptoKeys/{key_id}`

Learn more about using your own encryption keys.

=back

=head2 Google::Cloud::Notebooks::V2::GceSetup::ServiceAccount

A service account that acts as an identity.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->email() >> / C<< $msg->email($value) >>

Type: C<String>

Optional. Email address of the service account.

=item * C<< $msg->scopes() >> / C<< $msg->scopes($value) >>

Type: C<String>

Output only. The list of scopes to be made available for this service
account. Set by the CLH to https://www.googleapis.com/auth/cloud-platform

=back

=head2 Google::Cloud::Notebooks::V2::GceSetup::GceSetup

The definition of how to configure a VM instance outside of Resources and
Identity.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->machine_type() >> / C<< $msg->machine_type($value) >>

Type: C<String>

Optional. The machine type of the VM instance.
https://cloud.google.com/compute/docs/machine-resource

=item * C<< $msg->accelerator_configs() >> / C<< $msg->accelerator_configs($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V2::GceSetup::AcceleratorConfig>)

Optional. The hardware accelerators used on this instance. If you use
accelerators, make sure that your configuration has
[enough vCPUs and memory to support the `machine_type` you have
selected](https://cloud.google.com/compute/docs/gpus/#gpus-list).
Currently supports only one accelerator configuration.

=item * C<< $msg->service_accounts() >> / C<< $msg->service_accounts($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V2::GceSetup::ServiceAccount>)

Optional. The service account that serves as an identity for the VM
instance. Currently supports only one service account.

=item * C<< $msg->vm_image() >> / C<< $msg->vm_image($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V2::GceSetup::VmImage>)

Optional. Use a Compute Engine VM image to start the notebook instance.

=item * C<< $msg->container_image() >> / C<< $msg->container_image($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V2::GceSetup::ContainerImage>)

Optional. Use a container image to start the notebook instance.

=item * C<< $msg->boot_disk() >> / C<< $msg->boot_disk($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V2::GceSetup::BootDisk>)

Optional. The boot disk for the VM.

=item * C<< $msg->data_disks() >> / C<< $msg->data_disks($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V2::GceSetup::DataDisk>)

Optional. Data disks attached to the VM instance.
Currently supports only one data disk.

=item * C<< $msg->shielded_instance_config() >> / C<< $msg->shielded_instance_config($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V2::GceSetup::ShieldedInstanceConfig>)

Optional. Shielded VM configuration.
[Images using supported Shielded VM
features](https://cloud.google.com/compute/docs/instances/modifying-shielded-vm).

=item * C<< $msg->network_interfaces() >> / C<< $msg->network_interfaces($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V2::GceSetup::NetworkInterface>)

Optional. The network interfaces for the VM.
Supports only one interface.

=item * C<< $msg->disable_public_ip() >> / C<< $msg->disable_public_ip($value) >>

Type: C<Bool>

Optional. If true, no external IP will be assigned to this VM instance.

=item * C<< $msg->tags() >> / C<< $msg->tags($value) >>

Type: C<String>

Optional. The Compute Engine tags to add to runtime (see [Tagging
instances](https://cloud.google.com/compute/docs/label-or-tag-resources#tags)).

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V2::GceSetup::GceSetup::MetadataEntry>)

Optional. Custom metadata to apply to this instance.

=item * C<< $msg->enable_ip_forwarding() >> / C<< $msg->enable_ip_forwarding($value) >>

Type: C<Bool>

Optional. Flag to enable ip forwarding or not, default false/off.
https://cloud.google.com/vpc/docs/using-routes#canipforward

=item * C<< $msg->gpu_driver_config() >> / C<< $msg->gpu_driver_config($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V2::GceSetup::GPUDriverConfig>)

Optional. Configuration for GPU drivers.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Notebooks::V2::GceSetup::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
