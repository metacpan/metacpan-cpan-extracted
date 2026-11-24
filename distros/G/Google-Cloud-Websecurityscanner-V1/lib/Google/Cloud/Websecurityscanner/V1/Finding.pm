package Google::Cloud::Websecurityscanner::V1::Finding;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Websecurityscanner::V1::FindingAddon };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxL2ZpbmRpbmcucHJvdG8SImdv
b2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aNmdvb2dsZS9jbG91ZC93
ZWJzZWN1cml0eXNjYW5uZXIvdjEvZmluZGluZ19hZGRvbi5wcm90byLBCQoHRmluZGluZxIS
CgRuYW1lGAEgASgJUgRuYW1lEiEKDGZpbmRpbmdfdHlwZRgCIAEoCVILZmluZGluZ1R5cGUS
VQoIc2V2ZXJpdHkYESABKA4yNC5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYx
LkZpbmRpbmcuU2V2ZXJpdHlCA+BBA1IIc2V2ZXJpdHkSHwoLaHR0cF9tZXRob2QYAyABKAlS
Cmh0dHBNZXRob2QSHQoKZnV6emVkX3VybBgEIAEoCVIJZnV6emVkVXJsEhIKBGJvZHkYBSAB
KAlSBGJvZHkSIAoLZGVzY3JpcHRpb24YBiABKAlSC2Rlc2NyaXB0aW9uEikKEHJlcHJvZHVj
dGlvbl91cmwYByABKAlSD3JlcHJvZHVjdGlvblVybBIbCglmcmFtZV91cmwYCCABKAlSCGZy
YW1lVXJsEhsKCWZpbmFsX3VybBgJIAEoCVIIZmluYWxVcmwSHwoLdHJhY2tpbmdfaWQYCiAB
KAlSCnRyYWNraW5nSWQSPAoEZm9ybRgQIAEoCzIoLmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0
eXNjYW5uZXIudjEuRm9ybVIEZm9ybRJeChBvdXRkYXRlZF9saWJyYXJ5GAsgASgLMjMuZ29v
Z2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MS5PdXRkYXRlZExpYnJhcnlSD291dGRh
dGVkTGlicmFyeRJkChJ2aW9sYXRpbmdfcmVzb3VyY2UYDCABKAsyNS5nb29nbGUuY2xvdWQu
d2Vic2VjdXJpdHlzY2FubmVyLnYxLlZpb2xhdGluZ1Jlc291cmNlUhF2aW9sYXRpbmdSZXNv
dXJjZRJkChJ2dWxuZXJhYmxlX2hlYWRlcnMYDyABKAsyNS5nb29nbGUuY2xvdWQud2Vic2Vj
dXJpdHlzY2FubmVyLnYxLlZ1bG5lcmFibGVIZWFkZXJzUhF2dWxuZXJhYmxlSGVhZGVycxJt
ChV2dWxuZXJhYmxlX3BhcmFtZXRlcnMYDSABKAsyOC5nb29nbGUuY2xvdWQud2Vic2VjdXJp
dHlzY2FubmVyLnYxLlZ1bG5lcmFibGVQYXJhbWV0ZXJzUhR2dWxuZXJhYmxlUGFyYW1ldGVy
cxI5CgN4c3MYDiABKAsyJy5nb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxLlhz
c1IDeHNzEj4KA3h4ZRgSIAEoCzInLmdvb2dsZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIu
djEuWHhlQgPgQQNSA3h4ZSJRCghTZXZlcml0eRIYChRTRVZFUklUWV9VTlNQRUNJRklFRBAA
EgwKCENSSVRJQ0FMEAESCAoESElHSBACEgoKBk1FRElVTRADEgcKA0xPVxAEOoQB6kGAAQop
d2Vic2VjdXJpdHlzY2FubmVyLmdvb2dsZWFwaXMuY29tL0ZpbmRpbmcSU3Byb2plY3RzL3tw
cm9qZWN0fS9zY2FuQ29uZmlncy97c2Nhbl9jb25maWd9L3NjYW5SdW5zL3tzY2FuX3J1bn0v
ZmluZGluZ3Mve2ZpbmRpbmd9QoICCiZjb20uZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nh
bm5lci52MUIMRmluZGluZ1Byb3RvUAFaVmNsb3VkLmdvb2dsZS5jb20vZ28vd2Vic2VjdXJp
dHlzY2FubmVyL2FwaXYxL3dlYnNlY3VyaXR5c2Nhbm5lcnBiO3dlYnNlY3VyaXR5c2Nhbm5l
cnBiqgIiR29vZ2xlLkNsb3VkLldlYlNlY3VyaXR5U2Nhbm5lci5WMcoCIkdvb2dsZVxDbG91
ZFxXZWJTZWN1cml0eVNjYW5uZXJcVjHqAiVHb29nbGU6OkNsb3VkOjpXZWJTZWN1cml0eVNj
YW5uZXI6OlYxSvshCgYSBA4AeQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29n
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
CgoICgECEgMQACsKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUAEAKCAoBCBIDFgA/
CgkKAgglEgMWAD8KCAoBCBIDFwBtCgkKAggLEgMXAG0KCAoBCBIDGAAiCgkKAggKEgMYACIK
CAoBCBIDGQAtCgkKAggIEgMZAC0KCAoBCBIDGgA/CgkKAggBEgMaAD8KCAoBCBIDGwA/CgkK
AggpEgMbAD8KCAoBCBIDHAA+CgkKAggtEgMcAD4KYgoCBAASBCAAeQEaViBBIEZpbmRpbmcg
cmVzb3VyY2UgcmVwcmVzZW50cyBhIHZ1bG5lcmFiaWxpdHkgaW5zdGFuY2UgaWRlbnRpZmll
ZCBkdXJpbmcgYQogU2NhblJ1bi4KCgoKAwQAARIDIAgPCgsKAwQABxIEIQIkBAoNCgUEAAed
CBIEIQIkBAo2CgQEAAQAEgQnAjYDGiggVGhlIHNldmVyaXR5IGxldmVsIG9mIGEgdnVsbmVy
YWJpbGl0eS4KCgwKBQQABAABEgMnBw8KOgoGBAAEAAIAEgMpBB0aKyBObyBzZXZlcml0eSBz
cGVjaWZpZWQuIFRoZSBkZWZhdWx0IHZhbHVlLgoKDgoHBAAEAAIAARIDKQQYCg4KBwQABAAC
AAISAykbHAojCgYEAAQAAgESAywEERoUIENyaXRpY2FsIHNldmVyaXR5LgoKDgoHBAAEAAIB
ARIDLAQMCg4KBwQABAACAQISAywPEAofCgYEAAQAAgISAy8EDRoQIEhpZ2ggc2V2ZXJpdHku
CgoOCgcEAAQAAgIBEgMvBAgKDgoHBAAEAAICAhIDLwsMCiEKBgQABAACAxIDMgQPGhIgTWVk
aXVtIHNldmVyaXR5LgoKDgoHBAAEAAIDARIDMgQKCg4KBwQABAACAwISAzINDgoeCgYEAAQA
AgQSAzUEDBoPIExvdyBzZXZlcml0eS4KCg4KBwQABAACBAESAzUEBwoOCgcEAAQAAgQCEgM1
CgsK6QEKBAQAAgASAzsCEhrbASBPdXRwdXQgb25seS4gVGhlIHJlc291cmNlIG5hbWUgb2Yg
dGhlIEZpbmRpbmcuIFRoZSBuYW1lIGZvbGxvd3MgdGhlIGZvcm1hdCBvZgogJ3Byb2plY3Rz
L3twcm9qZWN0SWR9L3NjYW5Db25maWdzL3tzY2FuQ29uZmlnSWR9L3NjYW5ydW5zL3tzY2Fu
UnVuSWR9L2ZpbmRpbmdzL3tmaW5kaW5nSWR9Jy4KIFRoZSBmaW5kaW5nIElEcyBhcmUgZ2Vu
ZXJhdGVkIGJ5IHRoZSBzeXN0ZW0uCgoMCgUEAAIABRIDOwIICgwKBQQAAgABEgM7CQ0KDAoF
BAACAAMSAzsQEQrfAQoEBAACARIDQAIaGtEBIE91dHB1dCBvbmx5LiBUaGUgdHlwZSBvZiB0
aGUgRmluZGluZy4KIERldGFpbGVkIGFuZCB1cC10by1kYXRlIGluZm9ybWF0aW9uIG9uIGZp
bmRpbmdzIGNhbiBiZSBmb3VuZCBoZXJlOgogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3Nl
Y3VyaXR5LWNvbW1hbmQtY2VudGVyL2RvY3MvaG93LXRvLXJlbWVkaWF0ZS13ZWItc2VjdXJp
dHktc2Nhbm5lci1maW5kaW5ncwoKDAoFBAACAQUSA0ACCAoMCgUEAAIBARIDQAkVCgwKBQQA
AgEDEgNAGBkKTQoEBAACAhIDQwJFGkAgT3V0cHV0IG9ubHkuIFRoZSBzZXZlcml0eSBsZXZl
bCBvZiB0aGUgcmVwb3J0ZWQgdnVsbmVyYWJpbGl0eS4KCgwKBQQAAgIGEgNDAgoKDAoFBAAC
AgESA0MLEwoMCgUEAAICAxIDQxYYCgwKBQQAAgIIEgNDGUQKDwoIBAACAgicCAASA0MaQwpr
CgQEAAIDEgNHAhkaXiBPdXRwdXQgb25seS4gVGhlIGh0dHAgbWV0aG9kIG9mIHRoZSByZXF1
ZXN0IHRoYXQgdHJpZ2dlcmVkIHRoZSB2dWxuZXJhYmlsaXR5LCBpbgogdXBwZXJjYXNlLgoK
DAoFBAACAwUSA0cCCAoMCgUEAAIDARIDRwkUCgwKBQQAAgMDEgNHFxgKgQEKBAQAAgQSA0sC
GBp0IE91dHB1dCBvbmx5LiBUaGUgVVJMIHByb2R1Y2VkIGJ5IHRoZSBzZXJ2ZXItc2lkZSBm
dXp6ZXIgYW5kIHVzZWQgaW4gdGhlIHJlcXVlc3QgdGhhdAogdHJpZ2dlcmVkIHRoZSB2dWxu
ZXJhYmlsaXR5LgoKDAoFBAACBAUSA0sCCAoMCgUEAAIEARIDSwkTCgwKBQQAAgQDEgNLFhcK
VQoEBAACBRIDTgISGkggT3V0cHV0IG9ubHkuIFRoZSBib2R5IG9mIHRoZSByZXF1ZXN0IHRo
YXQgdHJpZ2dlcmVkIHRoZSB2dWxuZXJhYmlsaXR5LgoKDAoFBAACBQUSA04CCAoMCgUEAAIF
ARIDTgkNCgwKBQQAAgUDEgNOEBEKQQoEBAACBhIDUQIZGjQgT3V0cHV0IG9ubHkuIFRoZSBk
ZXNjcmlwdGlvbiBvZiB0aGUgdnVsbmVyYWJpbGl0eS4KCgwKBQQAAgYFEgNRAggKDAoFBAAC
BgESA1EJFAoMCgUEAAIGAxIDURcYCn0KBAQAAgcSA1UCHhpwIE91dHB1dCBvbmx5LiBUaGUg
VVJMIGNvbnRhaW5pbmcgaHVtYW4tcmVhZGFibGUgcGF5bG9hZCB0aGF0IHVzZXIgY2FuIGxl
dmVyYWdlIHRvCiByZXByb2R1Y2UgdGhlIHZ1bG5lcmFiaWxpdHkuCgoMCgUEAAIHBRIDVQII
CgwKBQQAAgcBEgNVCRkKDAoFBAACBwMSA1UcHQp9CgQEAAIIEgNZAhcacCBPdXRwdXQgb25s
eS4gSWYgdGhlIHZ1bG5lcmFiaWxpdHkgd2FzIG9yaWdpbmF0ZWQgZnJvbSBuZXN0ZWQgSUZy
YW1lLCB0aGUgaW1tZWRpYXRlCiBwYXJlbnQgSUZyYW1lIGlzIHJlcG9ydGVkLgoKDAoFBAAC
CAUSA1kCCAoMCgUEAAIIARIDWQkSCgwKBQQAAggDEgNZFRYKXwoEBAACCRIDXAIXGlIgT3V0
cHV0IG9ubHkuIFRoZSBVUkwgd2hlcmUgdGhlIGJyb3dzZXIgbGFuZHMgd2hlbiB0aGUgdnVs
bmVyYWJpbGl0eSBpcyBkZXRlY3RlZC4KCgwKBQQAAgkFEgNcAggKDAoFBAACCQESA1wJEgoM
CgUEAAIJAxIDXBUWCnMKBAQAAgoSA2ACGhpmIE91dHB1dCBvbmx5LiBUaGUgdHJhY2tpbmcg
SUQgdW5pcXVlbHkgaWRlbnRpZmllcyBhIHZ1bG5lcmFiaWxpdHkgaW5zdGFuY2UgYWNyb3Nz
CiBtdWx0aXBsZSBTY2FuUnVucy4KCgwKBQQAAgoFEgNgAggKDAoFBAACCgESA2AJFAoMCgUE
AAIKAxIDYBcZCnQKBAQAAgsSA2QCERpnIE91dHB1dCBvbmx5LiBBbiBhZGRvbiBjb250YWlu
aW5nIGluZm9ybWF0aW9uIHJlcG9ydGVkIGZvciBhIHZ1bG5lcmFiaWxpdHkgd2l0aCBhbiBI
VE1MCiBmb3JtLCBpZiBhbnkuCgoMCgUEAAILBhIDZAIGCgwKBQQAAgsBEgNkBwsKDAoFBAAC
CwMSA2QOEApVCgQEAAIMEgNnAigaSCBPdXRwdXQgb25seS4gQW4gYWRkb24gY29udGFpbmlu
ZyBpbmZvcm1hdGlvbiBhYm91dCBvdXRkYXRlZCBsaWJyYXJpZXMuCgoMCgUEAAIMBhIDZwIR
CgwKBQQAAgwBEgNnEiIKDAoFBAACDAMSA2clJwqsAQoEBAACDRIDawIsGp4BIE91dHB1dCBv
bmx5LiBBbiBhZGRvbiBjb250YWluaW5nIGRldGFpbGVkIGluZm9ybWF0aW9uIHJlZ2FyZGlu
ZyBhbnkgcmVzb3VyY2UgY2F1c2luZyB0aGUKIHZ1bG5lcmFiaWxpdHkgc3VjaCBhcyBKYXZh
U2NyaXB0IHNvdXJjZXMsIGltYWdlLCBhdWRpbyBmaWxlcywgZXRjLgoKDAoFBAACDQYSA2sC
EwoMCgUEAAINARIDaxQmCgwKBQQAAg0DEgNrKSsKZQoEBAACDhIDbgIsGlggT3V0cHV0IG9u
bHkuIEFuIGFkZG9uIGNvbnRhaW5pbmcgaW5mb3JtYXRpb24gYWJvdXQgdnVsbmVyYWJsZSBv
ciBtaXNzaW5nIEhUVFAgaGVhZGVycy4KCgwKBQQAAg4GEgNuAhMKDAoFBAACDgESA24UJgoM
CgUEAAIOAxIDbikrCngKBAQAAg8SA3ICMhprIE91dHB1dCBvbmx5LiBBbiBhZGRvbiBjb250
YWluaW5nIGluZm9ybWF0aW9uIGFib3V0IHJlcXVlc3QgcGFyYW1ldGVycyB3aGljaCB3ZXJl
IGZvdW5kCiB0byBiZSB2dWxuZXJhYmxlLgoKDAoFBAACDwYSA3ICFgoMCgUEAAIPARIDchcs
CgwKBQQAAg8DEgNyLzEKWAoEBAACEBIDdQIPGksgT3V0cHV0IG9ubHkuIEFuIGFkZG9uIGNv
bnRhaW5pbmcgaW5mb3JtYXRpb24gcmVwb3J0ZWQgZm9yIGFuIFhTUywgaWYgYW55LgoKDAoF
BAACEAYSA3UCBQoMCgUEAAIQARIDdQYJCgwKBQQAAhADEgN1DA4KWAoEBAACERIDeAI7Gksg
T3V0cHV0IG9ubHkuIEFuIGFkZG9uIGNvbnRhaW5pbmcgaW5mb3JtYXRpb24gcmVwb3J0ZWQg
Zm9yIGFuIFhYRSwgaWYgYW55LgoKDAoFBAACEQYSA3gCBQoMCgUEAAIRARIDeAYJCgwKBQQA
AhEDEgN4DA4KDAoFBAACEQgSA3gPOgoPCggEAAIRCJwIABIDeBA5YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1::Finding::Finding ===
    # Fields for Finding
    # Field: name Type: 9 ()
    # Field: finding_type Type: 9 ()
    # Field: severity Type: 14 (.google.cloud.websecurityscanner.v1.Finding.Severity)
    # Field: http_method Type: 9 ()
    # Field: fuzzed_url Type: 9 ()
    # Field: body Type: 9 ()
    # Field: description Type: 9 ()
    # Field: reproduction_url Type: 9 ()
    # Field: frame_url Type: 9 ()
    # Field: final_url Type: 9 ()
    # Field: tracking_id Type: 9 ()
    # Field: form Type: 11 (.google.cloud.websecurityscanner.v1.Form)
    # Field: outdated_library Type: 11 (.google.cloud.websecurityscanner.v1.OutdatedLibrary)
    # Field: violating_resource Type: 11 (.google.cloud.websecurityscanner.v1.ViolatingResource)
    # Field: vulnerable_headers Type: 11 (.google.cloud.websecurityscanner.v1.VulnerableHeaders)
    # Field: vulnerable_parameters Type: 11 (.google.cloud.websecurityscanner.v1.VulnerableParameters)
    # Field: xss Type: 11 (.google.cloud.websecurityscanner.v1.Xss)
    # Field: xxe Type: 11 (.google.cloud.websecurityscanner.v1.Xxe)

# Enum: Finding::Severity
our $Finding_SEVERITY_UNSPECIFIED = 0;
our $Finding_CRITICAL = 1;
our $Finding_HIGH = 2;
our $Finding_MEDIUM = 3;
our $Finding_LOW = 4;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Websecurityscanner::V1::Finding - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1/finding.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1::Finding;

    my $msg = Google::Cloud::Websecurityscanner::V1::Finding::Finding->new({
        name => $name,
        finding_type => $finding_type,
        severity => $severity,
        http_method => $http_method,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1::Finding::Finding->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1/finding.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1::Finding::Finding

A Finding resource represents a vulnerability instance identified during a
ScanRun.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of the Finding. The name follows the format of
'projects/{projectId}/scanConfigs/{scanConfigId}/scanruns/{scanRunId}/findings/{findingId}'.
The finding IDs are generated by the system.

=item * C<< $msg->finding_type() >> / C<< $msg->finding_type($value) >>

Type: C<String>

Output only. The type of the Finding.
Detailed and up-to-date information on findings can be found here:
https://cloud.google.com/security-command-center/docs/how-to-remediate-web-security-scanner-findings

=item * C<< $msg->severity() >> / C<< $msg->severity($value) >>

Type: C<Enum> (L<Google::Cloud::Websecurityscanner::V1::Finding::Severity>)

Output only. The severity level of the reported vulnerability.

=item * C<< $msg->http_method() >> / C<< $msg->http_method($value) >>

Type: C<String>

Output only. The http method of the request that triggered the vulnerability, in
uppercase.

=item * C<< $msg->fuzzed_url() >> / C<< $msg->fuzzed_url($value) >>

Type: C<String>

Output only. The URL produced by the server-side fuzzer and used in the request that
triggered the vulnerability.

=item * C<< $msg->body() >> / C<< $msg->body($value) >>

Type: C<String>

Output only. The body of the request that triggered the vulnerability.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Output only. The description of the vulnerability.

=item * C<< $msg->reproduction_url() >> / C<< $msg->reproduction_url($value) >>

Type: C<String>

Output only. The URL containing human-readable payload that user can leverage to
reproduce the vulnerability.

=item * C<< $msg->frame_url() >> / C<< $msg->frame_url($value) >>

Type: C<String>

Output only. If the vulnerability was originated from nested IFrame, the immediate
parent IFrame is reported.

=item * C<< $msg->final_url() >> / C<< $msg->final_url($value) >>

Type: C<String>

Output only. The URL where the browser lands when the vulnerability is detected.

=item * C<< $msg->tracking_id() >> / C<< $msg->tracking_id($value) >>

Type: C<String>

Output only. The tracking ID uniquely identifies a vulnerability instance across
multiple ScanRuns.

=item * C<< $msg->form() >> / C<< $msg->form($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1::FindingAddon::Form>)

Output only. An addon containing information reported for a vulnerability with an HTML
form, if any.

=item * C<< $msg->outdated_library() >> / C<< $msg->outdated_library($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1::FindingAddon::OutdatedLibrary>)

Output only. An addon containing information about outdated libraries.

=item * C<< $msg->violating_resource() >> / C<< $msg->violating_resource($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1::FindingAddon::ViolatingResource>)

Output only. An addon containing detailed information regarding any resource causing the
vulnerability such as JavaScript sources, image, audio files, etc.

=item * C<< $msg->vulnerable_headers() >> / C<< $msg->vulnerable_headers($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1::FindingAddon::VulnerableHeaders>)

Output only. An addon containing information about vulnerable or missing HTTP headers.

=item * C<< $msg->vulnerable_parameters() >> / C<< $msg->vulnerable_parameters($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1::FindingAddon::VulnerableParameters>)

Output only. An addon containing information about request parameters which were found
to be vulnerable.

=item * C<< $msg->xss() >> / C<< $msg->xss($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1::FindingAddon::Xss>)

Output only. An addon containing information reported for an XSS, if any.

=item * C<< $msg->xxe() >> / C<< $msg->xxe($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1::FindingAddon::Xxe>)

Output only. An addon containing information reported for an XXE, if any.

=back

=head3 Enum: Finding::Severity

=over 4

=item * C<SEVERITY_UNSPECIFIED> => C<0>

=item * C<CRITICAL> => C<1>

=item * C<HIGH> => C<2>

=item * C<MEDIUM> => C<3>

=item * C<LOW> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1::Finding::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
