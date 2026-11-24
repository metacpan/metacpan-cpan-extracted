package Google::Cloud::Universalledger::V1::Common;

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
Cixnb29nbGUvY2xvdWQvdW5pdmVyc2FsbGVkZ2VyL3YxL2NvbW1vbi5wcm90bxIfZ29vZ2xl
LmNsb3VkLnVuaXZlcnNhbGxlZGdlci52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90byIqCg1DdXJyZW5jeVZhbHVlEhkKBXZhbHVlGAEgASgDQgPgQQJSBXZhbHVlIj4KFlF1
YWxpZmllZEN1cnJlbmN5VmFsdWUSJAoLb3BlcmF0b3JfaWQYASABKAlCA+BBAlIKb3BlcmF0
b3JJZCKPAQoLQW1vdW50VmFsdWUSWAoIY3VycmVuY3kYASABKAsyNy5nb29nbGUuY2xvdWQu
dW5pdmVyc2FsbGVkZ2VyLnYxLlF1YWxpZmllZEN1cnJlbmN5VmFsdWVCA+BBAlIIY3VycmVu
Y3kSJgoMYW1vdW50X3ZhbHVlGAIgASgDQgPgQQJSC2Ftb3VudFZhbHVlIikKClN0cmluZ0xp
c3QSGwoGdmFsdWVzGAEgAygJQgPgQQFSBnZhbHVlcyIoCglJbnQ2NExpc3QSGwoGdmFsdWVz
GAEgAygDQgPgQQFSBnZhbHVlcyIyCgxBY2NvdW50VmFsdWUSIgoKYWNjb3VudF9pZBgBIAEo
CUID4EECUglhY2NvdW50SWQiJwoIQm9vbExpc3QSGwoGdmFsdWVzGAEgAygIQgPgQQFSBnZh
bHVlcyI1Cg1Db250cmFjdFZhbHVlEiQKC2NvbnRyYWN0X2lkGAEgASgJQgPgQQJSCmNvbnRy
YWN0SWQizQUKCURpY3RWYWx1ZRJNCglib29sX2tleXMYASABKAsyKS5nb29nbGUuY2xvdWQu
dW5pdmVyc2FsbGVkZ2VyLnYxLkJvb2xMaXN0QgPgQQFIAFIIYm9vbEtleXMSUwoLc3RyaW5n
X2tleXMYAiABKAsyKy5nb29nbGUuY2xvdWQudW5pdmVyc2FsbGVkZ2VyLnYxLlN0cmluZ0xp
c3RCA+BBAUgAUgpzdHJpbmdLZXlzElAKCmludDY0X2tleXMYAyABKAsyKi5nb29nbGUuY2xv
dWQudW5pdmVyc2FsbGVkZ2VyLnYxLkludDY0TGlzdEID4EEBSABSCWludDY0S2V5cxJYCgxn
ZW5lcmljX2tleXMYDSABKAsyLi5nb29nbGUuY2xvdWQudW5pdmVyc2FsbGVkZ2VyLnYxLlJl
cGVhdGVkVmFsdWVCA+BBAUgAUgtnZW5lcmljS2V5cxJRCgtib29sX3ZhbHVlcxgEIAEoCzIp
Lmdvb2dsZS5jbG91ZC51bml2ZXJzYWxsZWRnZXIudjEuQm9vbExpc3RCA+BBAUgBUgpib29s
VmFsdWVzElcKDXN0cmluZ192YWx1ZXMYBSABKAsyKy5nb29nbGUuY2xvdWQudW5pdmVyc2Fs
bGVkZ2VyLnYxLlN0cmluZ0xpc3RCA+BBAUgBUgxzdHJpbmdWYWx1ZXMSVAoMaW50NjRfdmFs
dWVzGAYgASgLMiouZ29vZ2xlLmNsb3VkLnVuaXZlcnNhbGxlZGdlci52MS5JbnQ2NExpc3RC
A+BBAUgBUgtpbnQ2NFZhbHVlcxJcCg5nZW5lcmljX3ZhbHVlcxgOIAEoCzIuLmdvb2dsZS5j
bG91ZC51bml2ZXJzYWxsZWRnZXIudjEuUmVwZWF0ZWRWYWx1ZUID4EEBSAFSDWdlbmVyaWNW
YWx1ZXNCBgoEa2V5c0IICgZ2YWx1ZXMi9QIKCUxpc3RWYWx1ZRJRCgtib29sX3ZhbHVlcxgB
IAEoCzIpLmdvb2dsZS5jbG91ZC51bml2ZXJzYWxsZWRnZXIudjEuQm9vbExpc3RCA+BBAUgA
Ugpib29sVmFsdWVzElcKDXN0cmluZ192YWx1ZXMYAiABKAsyKy5nb29nbGUuY2xvdWQudW5p
dmVyc2FsbGVkZ2VyLnYxLlN0cmluZ0xpc3RCA+BBAUgAUgxzdHJpbmdWYWx1ZXMSVAoMaW50
NjRfdmFsdWVzGAMgASgLMiouZ29vZ2xlLmNsb3VkLnVuaXZlcnNhbGxlZGdlci52MS5JbnQ2
NExpc3RCA+BBAUgAUgtpbnQ2NFZhbHVlcxJcCg5nZW5lcmljX3ZhbHVlcxgIIAEoCzIuLmdv
b2dsZS5jbG91ZC51bml2ZXJzYWxsZWRnZXIudjEuUmVwZWF0ZWRWYWx1ZUID4EEBSABSDWdl
bmVyaWNWYWx1ZXNCCAoGdmFsdWVzIlQKDVJlcGVhdGVkVmFsdWUSQwoGdmFsdWVzGAEgAygL
MiYuZ29vZ2xlLmNsb3VkLnVuaXZlcnNhbGxlZGdlci52MS5WYWx1ZUID4EEBUgZ2YWx1ZXMi
iQYKBVZhbHVlElAKCm5vbmVfdmFsdWUYASABKA4yKi5nb29nbGUuY2xvdWQudW5pdmVyc2Fs
bGVkZ2VyLnYxLk5vbmVWYWx1ZUID4EEBSABSCW5vbmVWYWx1ZRIkCgpib29sX3ZhbHVlGAIg
ASgIQgPgQQFIAFIJYm9vbFZhbHVlEiYKC2ludDY0X3ZhbHVlGAMgASgDQgPgQQFIAFIKaW50
NjRWYWx1ZRIoCgxzdHJpbmdfdmFsdWUYBCABKAlCA+BBAUgAUgtzdHJpbmdWYWx1ZRJQCgpk
aWN0X3ZhbHVlGAYgASgLMiouZ29vZ2xlLmNsb3VkLnVuaXZlcnNhbGxlZGdlci52MS5EaWN0
VmFsdWVCA+BBAUgAUglkaWN0VmFsdWUSXAoOY29udHJhY3RfdmFsdWUYByABKAsyLi5nb29n
bGUuY2xvdWQudW5pdmVyc2FsbGVkZ2VyLnYxLkNvbnRyYWN0VmFsdWVCA+BBAUgAUg1jb250
cmFjdFZhbHVlElAKCmxpc3RfdmFsdWUYCCABKAsyKi5nb29nbGUuY2xvdWQudW5pdmVyc2Fs
bGVkZ2VyLnYxLkxpc3RWYWx1ZUID4EEBSABSCWxpc3RWYWx1ZRJ4ChhxdWFsaWZpZWRfY3Vy
cmVuY3lfdmFsdWUYCSABKAsyNy5nb29nbGUuY2xvdWQudW5pdmVyc2FsbGVkZ2VyLnYxLlF1
YWxpZmllZEN1cnJlbmN5VmFsdWVCA+BBAUgAUhZxdWFsaWZpZWRDdXJyZW5jeVZhbHVlElkK
DWFjY291bnRfdmFsdWUYCiABKAsyLS5nb29nbGUuY2xvdWQudW5pdmVyc2FsbGVkZ2VyLnYx
LkFjY291bnRWYWx1ZUID4EEBSABSDGFjY291bnRWYWx1ZRJWCgxhbW91bnRfdmFsdWUYCyAB
KAsyLC5nb29nbGUuY2xvdWQudW5pdmVyc2FsbGVkZ2VyLnYxLkFtb3VudFZhbHVlQgPgQQFI
AFILYW1vdW50VmFsdWVCBwoFdmFsdWUqJwoJTm9uZVZhbHVlEhoKFk5PTkVfVkFMVUVfVU5T
UEVDSUZJRUQQACpRCgdLZXlTbG90EhgKFEtFWV9TTE9UX1VOU1BFQ0lGSUVEEAASFAoQS0VZ
X1NMT1RfUFJJTUFSWRABEhYKEktFWV9TTE9UX0FMVEVSTkFURRACQuwBCiNjb20uZ29vZ2xl
LmNsb3VkLnVuaXZlcnNhbGxlZGdlci52MUILQ29tbW9uUHJvdG9QAVpNY2xvdWQuZ29vZ2xl
LmNvbS9nby91bml2ZXJzYWxsZWRnZXIvYXBpdjEvdW5pdmVyc2FsbGVkZ2VycGI7dW5pdmVy
c2FsbGVkZ2VycGKqAh9Hb29nbGUuQ2xvdWQuVW5pdmVyc2FsTGVkZ2VyLlYxygIfR29vZ2xl
XENsb3VkXFVuaXZlcnNhbExlZGdlclxWMeoCIkdvb2dsZTo6Q2xvdWQ6OlVuaXZlcnNhbExl
ZGdlcjo6VjFKjjgKBxIFDgDNAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQACgKCQoCAwASAxIAKQoICgEIEgMUADwKCQoCCCUSAxQAPAoICgEIEgMVAGQK
CQoCCAsSAxUAZAoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXACwKCQoCCAgSAxcALAoI
CgEIEgMYADwKCQoCCAESAxgAPAoICgEIEgMZADwKCQoCCCkSAxkAPAoICgEIEgMaADsKCQoC
CC0SAxoAOwpCCgIFABIEHQAgARo2IEEgc2luZ2xldG9uIGVudW1lcmF0aW9uIHRvIHJlcHJl
c2VudCB0aGUgTm9uZSB2YWx1ZS4KCgoKAwUAARIDHQUOCh4KBAUAAgASAx8CHRoRIFRoZSBO
b25lIHZhbHVlLgoKDAoFBQACAAESAx8CGAoMCgUFAAIAAhIDHxscCksKAgUBEgQjACwBGj8g
QW4gaWRlbnRpZmllciBvZiB0aGUgc2xvdHMgd2hpY2ggY2FuIGhvbGQga2V5cyBvbiBhbiBh
Y2NvdW50LgoKCgoDBQEBEgMjBQwKKwoEBQECABIDJQIbGh4gVGhlIGtleSBzbG90IGlzIHVu
c3BlY2lmaWVkLgoKDAoFBQECAAESAyUCFgoMCgUFAQIAAhIDJRkaCiQKBAUBAgESAygCFxoX
IFRoZSBwcmltYXJ5IGtleSBzbG90LgoKDAoFBQECAQESAygCEgoMCgUFAQIBAhIDKBUWCiYK
BAUBAgISAysCGRoZIFRoZSBhbHRlcm5hdGUga2V5IHNsb3QuCgoMCgUFAQICARIDKwIUCgwK
BQUBAgICEgMrFxgKjwIKAgQAEgQyADwBGoICIFJlcHJlc2VudHMgYW4gYW1vdW50IG9mIGN1
cnJlbmN5IChpLmUuIG1vbmV5KS4gTm90ZSB0aGF0IHRoZSBkZW5vbWluYXRlZAogY3VycmVu
Y3kgaXMgbm90IGluY2x1ZGVkIGluIHRoaXMgbWVzc2FnZS4gVGhlIHJlbGV2YW50IGN1cnJl
bmN5IGlzIGRlY2lkZWQgYnkKIHRoZSBhY2NvdW50IHRoYXQgc2VuZHMgdGhlIHRyYW5zYWN0
aW9uLiBFYWNoIGFjY291bnQgaGFzIGEgdW5pcXVlIGltbXV0YWJsZQogY3VycmVuY3kgYXNz
b2NpYXRlZCB0byBpdC4KCgoKAwQAARIDMggVCp0DCgQEAAIAEgM7AjsajwMgUmVxdWlyZWQu
IFRoZSBudW1iZXIgb2YgbWlub3IgdW5pdHMgb2YgdGhlIGN1cnJlbmN5LgoKCiBUaGlzIHNt
YWxsZXN0IHZhbGlkIGRlbm9taW5hdGlvbiBpcyByZWZlcnJlZCB0byBhcyAibWlub3IgdW5p
dHMiIGFuZCBpcwogc3BlY2lmaWVkIGluIFtJU08gNDIxN10oaHR0cHM6Ly93d3cuaXNvLm9y
Zy9pc28tNDIxNy1jdXJyZW5jeS1jb2Rlcy5odG1sKS4KIEFzIGFuIGV4YW1wbGUsIGZvciBV
U0QsIHRoZSB2YWx1ZSB3aWxsIGJlIHRoZSBudW1iZXIgb2YgY2VudHMgYW5kIGZvciBHQlAK
IGl0IHdpbGwgYmUgdGhlIG51bWJlciBvZiBwZW5jZS4gRm9yIHRoZSBKYXBhbmVzZSBZZW4g
d2hpY2ggZG9lcyBub3QgaGF2ZSBhCiBtaW5vciB1bml0LCBpdCB3aWxsIGJlIHRoZSBudW1i
ZXIgb2YgWWVuLgoKDAoFBAACAAUSAzsCBwoMCgUEAAIAARIDOwgNCgwKBQQAAgADEgM7EBEK
DAoFBAACAAgSAzsSOgoPCggEAAIACJwIABIDOxM5CmAKAgQBEgRAAEMBGlQgUmVwcmVzZW50
cyBhIGN1cnJlbmN5IG9uIHRoZSBsZWRnZXIsIHdoaWNoIGlzIHF1YWxpZmllZCBieSBpdHMg
Q3VycmVuY3kKIE9wZXJhdG9yLgoKCgoDBAEBEgNACB4KTQoEBAECABIDQgJCGkAgUmVxdWly
ZWQuIFRoZSBDdXJyZW5jeSBPcGVyYXRvciBJRCBhZG1pbmlzdGVyaW5nIHRoZSBjdXJyZW5j
eS4KCgwKBQQBAgAFEgNCAggKDAoFBAECAAESA0IJFAoMCgUEAQIAAxIDQhcYCgwKBQQBAgAI
EgNCGUEKDwoIBAECAAicCAASA0IaQAo8CgIEAhIERgBMARowIFJlcHJlc2VudHMgYSBkZW5v
bWluYXRlZCBhbW91bnQgaW4gYSBjdXJyZW5jeS4KCgoKAwQCARIDRggTCjQKBAQCAgASA0gC
TxonIFJlcXVpcmVkLiBUaGUgY3VycmVuY3kgb2YgdGhlIGFtb3VudC4KCgwKBQQCAgAGEgNI
AhgKDAoFBAICAAESA0gZIQoMCgUEAgIAAxIDSCQlCgwKBQQCAgAIEgNIJk4KDwoIBAICAAic
CAASA0gnTQpDCgQEAgIBEgNLAkIaNiBSZXF1aXJlZC4gVGhlIG51bWJlciBvZiBtaW5vciB1
bml0cyBvZiB0aGUgY3VycmVuY3kuCgoMCgUEAgIBBRIDSwIHCgwKBQQCAgEBEgNLCBQKDAoF
BAICAQMSA0sXGAoMCgUEAgIBCBIDSxlBCg8KCAQCAgEInAgAEgNLGkAKIAoCBAMSBE8AUgEa
FCBBIGxpc3Qgb2Ygc3RyaW5ncy4KCgoKAwQDARIDTwgSCisKBAQDAgASA1ECRhoeIE9wdGlv
bmFsLiBUaGUgc3RyaW5nIHZhbHVlcy4KCgwKBQQDAgAEEgNRAgoKDAoFBAMCAAUSA1ELEQoM
CgUEAwIAARIDURIYCgwKBQQDAgADEgNRGxwKDAoFBAMCAAgSA1EdRQoPCggEAwIACJwIABID
UR5ECh8KAgQEEgRVAFgBGhMgQSBsaXN0IG9mIGludDY0cy4KCgoKAwQEARIDVQgRCioKBAQE
AgASA1cCRRodIE9wdGlvbmFsLiBUaGUgaW50NjQgdmFsdWVzLgoKDAoFBAQCAAQSA1cCCgoM
CgUEBAIABRIDVwsQCgwKBQQEAgABEgNXERcKDAoFBAQCAAMSA1caGwoMCgUEBAIACBIDVxxE
Cg8KCAQEAgAInAgAEgNXHUMKvwIKAgQFEgRgAGMBGrICIEEgcmVmZXJlbmNlIHRvIGFuIGFj
Y291bnQgb24gdGhlIGxlZGdlci4KCiBUaGlzIHJlZmVyZW5jZSBpcyBzd2FwcGVkIG91dCBm
b3IgYSBmdWxsIGBnY3VsLkFjY291bnRgIG9iamVjdCBieSB0aGUKIGxlZGdlcidzIHJ1bnRp
bWUuIEZvciBtb3JlIGRldGFpbHMsIHNlZSB0aGUgW2BnY3VsLkFjY291bnRgCiBjbGFzc10o
aHR0cHM6Ly9kb2NzLmNsb3VkLmdvb2dsZS5jb20vdW5pdmVyc2FsLWxlZGdlci9yZWZlcmVu
Y2UvZ2N1bHB5LWxhbmd1YWdlI2FjY291bnQtY2xhc3MpCiBpbiB0aGUgR0NVTHB5IGxhbmd1
YWdlIHJlZmVyZW5jZS4KCgoKAwQFARIDYAgUCigKBAQFAgASA2ICQRobIFJlcXVpcmVkLiBU
aGUgYWNjb3VudCBJRC4KCgwKBQQFAgAFEgNiAggKDAoFBAUCAAESA2IJEwoMCgUEBQIAAxID
YhYXCgwKBQQFAgAIEgNiGEAKDwoIBAUCAAicCAASA2IZPwohCgIEBhIEZgBpARoVIEEgbGlz
dCBvZiBib29sZWFucy4KCgoKAwQGARIDZggQCiwKBAQGAgASA2gCRBofIE9wdGlvbmFsLiBU
aGUgYm9vbGVhbiB2YWx1ZXMuCgoMCgUEBgIABBIDaAIKCgwKBQQGAgAFEgNoCw8KDAoFBAYC
AAESA2gQFgoMCgUEBgIAAxIDaBkaCgwKBQQGAgAIEgNoG0MKDwoIBAYCAAicCAASA2gcQgou
CgIEBxIEbABvARoiIFJlcHJlc2VudHMgYSBjb250cmFjdCByZWZlcmVuY2UuCgoKCgMEBwES
A2wIFQopCgQEBwIAEgNuAkIaHCBSZXF1aXJlZC4gVGhlIGNvbnRyYWN0IElELgoKDAoFBAcC
AAUSA24CCAoMCgUEBwIAARIDbgkUCgwKBQQHAgADEgNuFxgKDAoFBAcCAAgSA24ZQQoPCggE
BwIACJwIABIDbhpAClgKAgQIEgVyAJABARpLIEluZGljZXMgbWFwIGtleSB0byB2YWx1ZS4g
Rm9yIGV4YW1wbGUsIGBrZXlzWzBdYCBrZXkgbWFwcyB0byBgdmFsdWVzWzBdYC4KCgoKAwQI
ARIDcggRCjIKBAQICAASBXQCgAEDGiMgRWFjaCBrZXkgY2FuIGJlIGV4YWN0bHkgb25lIGtp
bmQuCgoMCgUECAgAARIDdAgMCjAKBAQIAgASA3YERBojIE9wdGlvbmFsLiBBIGxpc3Qgb2Yg
Ym9vbGVhbiBrZXlzLgoKDAoFBAgCAAYSA3YEDAoMCgUECAIAARIDdg0WCgwKBQQIAgADEgN2
GRoKDAoFBAgCAAgSA3YbQwoPCggECAIACJwIABIDdhxCCi8KBAQIAgESA3kESBoiIE9wdGlv
bmFsLiBBIGxpc3Qgb2Ygc3RyaW5nIGtleXMuCgoMCgUECAIBBhIDeQQOCgwKBQQIAgEBEgN5
DxoKDAoFBAgCAQMSA3kdHgoMCgUECAIBCBIDeR9HCg8KCAQIAgEInAgAEgN5IEYKLgoEBAgC
AhIDfARGGiEgT3B0aW9uYWwuIEEgbGlzdCBvZiBpbnQ2NCBrZXlzLgoKDAoFBAgCAgYSA3wE
DQoMCgUECAICARIDfA4YCgwKBQQIAgIDEgN8GxwKDAoFBAgCAggSA3wdRQoPCggECAICCJwI
ABIDfB5ECjAKBAQIAgMSA38ETRojIE9wdGlvbmFsLiBBIGdlbmVyaWMgbGlzdCBvZiBrZXlz
LgoKDAoFBAgCAwYSA38EEQoMCgUECAIDARIDfxIeCgwKBQQIAgMDEgN/ISMKDAoFBAgCAwgS
A38kTAoPCggECAIDCJwIABIDfyVLCjUKBAQICAESBoMBAo8BAxolIEVhY2ggdmFsdWUgY2Fu
IGJlIGV4YWN0bHkgb25lIGtpbmQuCgoNCgUECAgBARIEgwEIDgozCgQECAIEEgSFAQRGGiUg
T3B0aW9uYWwuIEEgbGlzdCBvZiBib29sZWFuIHZhbHVlcy4KCg0KBQQIAgQGEgSFAQQMCg0K
BQQIAgQBEgSFAQ0YCg0KBQQIAgQDEgSFARscCg0KBQQIAgQIEgSFAR1FChAKCAQIAgQInAgA
EgSFAR5ECjIKBAQIAgUSBIgBBEoaJCBPcHRpb25hbC4gQSBsaXN0IG9mIHN0cmluZyB2YWx1
ZXMuCgoNCgUECAIFBhIEiAEEDgoNCgUECAIFARIEiAEPHAoNCgUECAIFAxIEiAEfIAoNCgUE
CAIFCBIEiAEhSQoQCggECAIFCJwIABIEiAEiSAoxCgQECAIGEgSLAQRIGiMgT3B0aW9uYWwu
IEEgbGlzdCBvZiBpbnQ2NCB2YWx1ZXMuCgoNCgUECAIGBhIEiwEEDQoNCgUECAIGARIEiwEO
GgoNCgUECAIGAxIEiwEdHgoNCgUECAIGCBIEiwEfRwoQCggECAIGCJwIABIEiwEgRgo9CgQE
CAIHEgSOAQRPGi8gT3B0aW9uYWwuIEEgZ2VuZXJpYyBsaXN0IG9mIHZhbHVlcyBhcyB2YWx1
ZXMuCgoNCgUECAIHBhIEjgEEEQoNCgUECAIHARIEjgESIAoNCgUECAIHAxIEjgEjJQoNCgUE
CAIHCBIEjgEmTgoQCggECAIHCJwIABIEjgEnTQohCgIECRIGkwEAogEBGhMgQSBsaXN0IG9m
IHZhbHVlcy4KCgsKAwQJARIEkwEIEQo1CgQECQgAEgaVAQKhAQMaJSBFYWNoIHZhbHVlIGNh
biBiZSBleGFjdGx5IG9uZSBraW5kLgoKDQoFBAkIAAESBJUBCA4KMwoEBAkCABIElwEERhol
IE9wdGlvbmFsLiBBIGxpc3Qgb2YgYm9vbGVhbiB2YWx1ZXMuCgoNCgUECQIABhIElwEEDAoN
CgUECQIAARIElwENGAoNCgUECQIAAxIElwEbHAoNCgUECQIACBIElwEdRQoQCggECQIACJwI
ABIElwEeRAoyCgQECQIBEgSaAQRKGiQgT3B0aW9uYWwuIEEgbGlzdCBvZiBzdHJpbmcgdmFs
dWVzLgoKDQoFBAkCAQYSBJoBBA4KDQoFBAkCAQESBJoBDxwKDQoFBAkCAQMSBJoBHyAKDQoF
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
CQicCAASBMsBI0liBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Universalledger::V1::Common::CurrencyValue ===
    # Fields for CurrencyValue
    # Field: value Type: 3 ()

# === Message: Google::Cloud::Universalledger::V1::Common::QualifiedCurrencyValue ===
    # Fields for QualifiedCurrencyValue
    # Field: operator_id Type: 9 ()

# === Message: Google::Cloud::Universalledger::V1::Common::AmountValue ===
    # Fields for AmountValue
    # Field: currency Type: 11 (.google.cloud.universalledger.v1.QualifiedCurrencyValue)
    # Field: amount_value Type: 3 ()

# === Message: Google::Cloud::Universalledger::V1::Common::StringList ===
    # Fields for StringList
    # Field: values Type: 9 ()

# === Message: Google::Cloud::Universalledger::V1::Common::Int64List ===
    # Fields for Int64List
    # Field: values Type: 3 ()

# === Message: Google::Cloud::Universalledger::V1::Common::AccountValue ===
    # Fields for AccountValue
    # Field: account_id Type: 9 ()

# === Message: Google::Cloud::Universalledger::V1::Common::BoolList ===
    # Fields for BoolList
    # Field: values Type: 8 ()

# === Message: Google::Cloud::Universalledger::V1::Common::ContractValue ===
    # Fields for ContractValue
    # Field: contract_id Type: 9 ()

# === Message: Google::Cloud::Universalledger::V1::Common::DictValue ===
    # Fields for DictValue
    # Field: bool_keys Type: 11 (.google.cloud.universalledger.v1.BoolList)
    # Field: string_keys Type: 11 (.google.cloud.universalledger.v1.StringList)
    # Field: int64_keys Type: 11 (.google.cloud.universalledger.v1.Int64List)
    # Field: generic_keys Type: 11 (.google.cloud.universalledger.v1.RepeatedValue)
    # Field: bool_values Type: 11 (.google.cloud.universalledger.v1.BoolList)
    # Field: string_values Type: 11 (.google.cloud.universalledger.v1.StringList)
    # Field: int64_values Type: 11 (.google.cloud.universalledger.v1.Int64List)
    # Field: generic_values Type: 11 (.google.cloud.universalledger.v1.RepeatedValue)

# === Message: Google::Cloud::Universalledger::V1::Common::ListValue ===
    # Fields for ListValue
    # Field: bool_values Type: 11 (.google.cloud.universalledger.v1.BoolList)
    # Field: string_values Type: 11 (.google.cloud.universalledger.v1.StringList)
    # Field: int64_values Type: 11 (.google.cloud.universalledger.v1.Int64List)
    # Field: generic_values Type: 11 (.google.cloud.universalledger.v1.RepeatedValue)

# === Message: Google::Cloud::Universalledger::V1::Common::RepeatedValue ===
    # Fields for RepeatedValue
    # Field: values Type: 11 (.google.cloud.universalledger.v1.Value)

# === Message: Google::Cloud::Universalledger::V1::Common::Value ===
    # Fields for Value
    # Field: none_value Type: 14 (.google.cloud.universalledger.v1.NoneValue)
    # Field: bool_value Type: 8 ()
    # Field: int64_value Type: 3 ()
    # Field: string_value Type: 9 ()
    # Field: dict_value Type: 11 (.google.cloud.universalledger.v1.DictValue)
    # Field: contract_value Type: 11 (.google.cloud.universalledger.v1.ContractValue)
    # Field: list_value Type: 11 (.google.cloud.universalledger.v1.ListValue)
    # Field: qualified_currency_value Type: 11 (.google.cloud.universalledger.v1.QualifiedCurrencyValue)
    # Field: account_value Type: 11 (.google.cloud.universalledger.v1.AccountValue)
    # Field: amount_value Type: 11 (.google.cloud.universalledger.v1.AmountValue)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Universalledger::V1::Common - Compiled Protocol Buffers messages for google/cloud/universalledger/v1/common.proto

=head1 SYNOPSIS

    use Google::Cloud::Universalledger::V1::Common;

    my $msg = Google::Cloud::Universalledger::V1::Common::CurrencyValue->new({
        value => $value,
    });

    # Read or update a field
    my $val = $msg->value();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Universalledger::V1::Common::CurrencyValue->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/universalledger/v1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Universalledger::V1::Common::CurrencyValue

Represents an amount of currency (i.e. money). Note that the denominated
currency is not included in this message. The relevant currency is decided by
the account that sends the transaction. Each account has a unique immutable
currency associated to it.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Int64>

Required. The number of minor units of the currency.


This smallest valid denomination is referred to as "minor units" and is
specified in [ISO 4217](https://www.iso.org/iso-4217-currency-codes.html).
As an example, for USD, the value will be the number of cents and for GBP
it will be the number of pence. For the Japanese Yen which does not have a
minor unit, it will be the number of Yen.

=back

=head2 Google::Cloud::Universalledger::V1::Common::QualifiedCurrencyValue

Represents a currency on the ledger, which is qualified by its Currency
Operator.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->operator_id() >> / C<< $msg->operator_id($value) >>

Type: C<String>

Required. The Currency Operator ID administering the currency.

=back

=head2 Google::Cloud::Universalledger::V1::Common::AmountValue

Represents a denominated amount in a currency.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->currency() >> / C<< $msg->currency($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::QualifiedCurrencyValue>)

Required. The currency of the amount.

=item * C<< $msg->amount_value() >> / C<< $msg->amount_value($value) >>

Type: C<Int64>

Required. The number of minor units of the currency.

=back

=head2 Google::Cloud::Universalledger::V1::Common::StringList

A list of strings.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<String>

Optional. The string values.

=back

=head2 Google::Cloud::Universalledger::V1::Common::Int64List

A list of int64s.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<Int64>

Optional. The int64 values.

=back

=head2 Google::Cloud::Universalledger::V1::Common::AccountValue

A reference to an account on the ledger.

This reference is swapped out for a full `gcul.Account` object by the
ledger's runtime. For more details, see the [`gcul.Account`
class](https://docs.cloud.google.com/universal-ledger/reference/gculpy-language#account-class)
in the GCULpy language reference.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->account_id() >> / C<< $msg->account_id($value) >>

Type: C<String>

Required. The account ID.

=back

=head2 Google::Cloud::Universalledger::V1::Common::BoolList

A list of booleans.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<Bool>

Optional. The boolean values.

=back

=head2 Google::Cloud::Universalledger::V1::Common::ContractValue

Represents a contract reference.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->contract_id() >> / C<< $msg->contract_id($value) >>

Type: C<String>

Required. The contract ID.

=back

=head2 Google::Cloud::Universalledger::V1::Common::DictValue

Indices map key to value. For example, `keys[0]` key maps to `values[0]`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bool_keys() >> / C<< $msg->bool_keys($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::BoolList>)

Optional. A list of boolean keys.

=item * C<< $msg->string_keys() >> / C<< $msg->string_keys($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::StringList>)

Optional. A list of string keys.

=item * C<< $msg->int64_keys() >> / C<< $msg->int64_keys($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::Int64List>)

Optional. A list of int64 keys.

=item * C<< $msg->generic_keys() >> / C<< $msg->generic_keys($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::RepeatedValue>)

Optional. A generic list of keys.

=item * C<< $msg->bool_values() >> / C<< $msg->bool_values($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::BoolList>)

Optional. A list of boolean values.

=item * C<< $msg->string_values() >> / C<< $msg->string_values($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::StringList>)

Optional. A list of string values.

=item * C<< $msg->int64_values() >> / C<< $msg->int64_values($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::Int64List>)

Optional. A list of int64 values.

=item * C<< $msg->generic_values() >> / C<< $msg->generic_values($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::RepeatedValue>)

Optional. A generic list of values as values.

=back

=head2 Google::Cloud::Universalledger::V1::Common::ListValue

A list of values.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bool_values() >> / C<< $msg->bool_values($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::BoolList>)

Optional. A list of boolean values.

=item * C<< $msg->string_values() >> / C<< $msg->string_values($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::StringList>)

Optional. A list of string values.

=item * C<< $msg->int64_values() >> / C<< $msg->int64_values($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::Int64List>)

Optional. A list of int64 values.

=item * C<< $msg->generic_values() >> / C<< $msg->generic_values($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::RepeatedValue>)

Optional. A generic list of values.

=back

=head2 Google::Cloud::Universalledger::V1::Common::RepeatedValue

A generic list of values.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->values() >> / C<< $msg->values($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::Value>)

Optional. The values in the list.

=back

=head2 Google::Cloud::Universalledger::V1::Common::Value

A concrete value of some type.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->none_value() >> / C<< $msg->none_value($value) >>

Type: C<Enum> (L<Google::Cloud::Universalledger::V1::NoneValue>)

Optional. Represents a None value.

=item * C<< $msg->bool_value() >> / C<< $msg->bool_value($value) >>

Type: C<Bool>

Optional. A boolean value.

=item * C<< $msg->int64_value() >> / C<< $msg->int64_value($value) >>

Type: C<Int64>

Optional. An int64 value.

=item * C<< $msg->string_value() >> / C<< $msg->string_value($value) >>

Type: C<String>

Optional. A string value.

=item * C<< $msg->dict_value() >> / C<< $msg->dict_value($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::DictValue>)

Optional. A dictionary value.

=item * C<< $msg->contract_value() >> / C<< $msg->contract_value($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::ContractValue>)

Optional. A contract reference.

=item * C<< $msg->list_value() >> / C<< $msg->list_value($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::ListValue>)

Optional. A list value.

=item * C<< $msg->qualified_currency_value() >> / C<< $msg->qualified_currency_value($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::QualifiedCurrencyValue>)

Optional. A qualified currency value.

=item * C<< $msg->account_value() >> / C<< $msg->account_value($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::AccountValue>)

Optional. An account value.

=item * C<< $msg->amount_value() >> / C<< $msg->amount_value($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::Common::AmountValue>)

Optional. An amount value.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Universalledger::V1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
