package Google::Cloud::Agentregistry::V1::Finding;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvYWdlbnRyZWdpc3RyeS92MS9maW5kaW5nLnByb3RvEh1nb29nbGUu
Y2xvdWQuYWdlbnRyZWdpc3RyeS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
bxobZ29vZ2xlL2FwaS9maWVsZF9pbmZvLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnBy
b3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIokGCgdGaW5kaW5nEhcKBG5h
bWUYASABKAlCA+BBCFIEbmFtZRIdCgN1aWQYAiABKAlCC+KMz9cIAggB4EEDUgN1aWQSQAoL
Y3JlYXRlX3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNy
ZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wQgPgQQNSCnVwZGF0ZVRpbWUSSAoIc2V2ZXJpdHkYBiABKA4yJy5nb29nbGUuY2xvdWQu
YWdlbnRyZWdpc3RyeS52MS5TZXZlcml0eUID4EEBUghzZXZlcml0eRJdCg1maW5kaW5nX2Ns
YXNzGAcgASgOMjMuZ29vZ2xlLmNsb3VkLmFnZW50cmVnaXN0cnkudjEuRmluZGluZy5GaW5k
aW5nQ2xhc3NCA+BBAVIMZmluZGluZ0NsYXNzEkYKBWZpbGVzGAggAygLMisuZ29vZ2xlLmNs
b3VkLmFnZW50cmVnaXN0cnkudjEuRmluZGluZy5GaWxlQgPgQQFSBWZpbGVzEhsKBmRldGFp
bBgKIAEoCUID4EEBUgZkZXRhaWwSJQoIcmVzb3VyY2UYCyABKAlCCeBBAfpBAwoBKlIIcmVz
b3VyY2UaRQoERmlsZRIXCgRwYXRoGAEgASgJQgPgQQFSBHBhdGgSJAoLbGluZV9udW1iZXIY
AiABKANCA+BBAVIKbGluZU51bWJlciJMCgxGaW5kaW5nQ2xhc3MSHQoZRklORElOR19DTEFT
U19VTlNQRUNJRklFRBAAEhEKDVZVTE5FUkFCSUxJVFkQARIKCgZTRUNSRVQQAzp46kF1CiRh
Z2VudHJlZ2lzdHJ5Lmdvb2dsZWFwaXMuY29tL0ZpbmRpbmcSOnByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9maW5kaW5ncy97ZmluZGluZ30qCGZpbmRpbmdzMgdm
aW5kaW5nKnUKCFNldmVyaXR5EhgKFFNFVkVSSVRZX1VOU1BFQ0lGSUVEEAASFQoRU0VWRVJJ
VFlfQ1JJVElDQUwQARIRCg1TRVZFUklUWV9ISUdIEAISEwoPU0VWRVJJVFlfTUVESVVNEAMS
EAoMU0VWRVJJVFlfTE9XEARC3wEKIWNvbS5nb29nbGUuY2xvdWQuYWdlbnRyZWdpc3RyeS52
MUIMRmluZGluZ1Byb3RvUAFaR2Nsb3VkLmdvb2dsZS5jb20vZ28vYWdlbnRyZWdpc3RyeS9h
cGl2MS9hZ2VudHJlZ2lzdHJ5cGI7YWdlbnRyZWdpc3RyeXBiqgIdR29vZ2xlLkNsb3VkLkFn
ZW50UmVnaXN0cnkuVjHKAh1Hb29nbGVcQ2xvdWRcQWdlbnRSZWdpc3RyeVxWMeoCIEdvb2ds
ZTo6Q2xvdWQ6OkFnZW50UmVnaXN0cnk6OlYxSpscCgYSBA4AdwEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACYKCQoCAwASAxIAKQoJCgIDARIDEwAlCgkK
AgMCEgMUACMKCQoCAwMSAxUAKQoICgEIEgMXADoKCQoCCCUSAxcAOgoICgEIEgMYAF4KCQoC
CAsSAxgAXgoICgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMaAC0KCQoCCAgSAxoALQoICgEI
EgMbADoKCQoCCAESAxsAOgoICgEIEgMcADoKCQoCCCkSAxwAOgoICgEIEgMdADkKCQoCCC0S
Ax0AOQoqCgIFABIEIAAwARoeIFRoZSBzZXZlcml0eSBvZiB0aGUgZmluZGluZy4KCgoKAwUA
ARIDIAUNCl0KBAUAAgASAyMCGxpQIFRoaXMgdmFsdWUgaXMgdXNlZCBmb3IgZmluZGluZ3Mg
d2hlbiBhIHNvdXJjZSBkb2Vzbid0IHdyaXRlIGEgc2V2ZXJpdHkKIHZhbHVlLgoKDAoFBQAC
AAESAyMCFgoMCgUFAAIAAhIDIxkaCiEKBAUAAgESAyYCGBoUIENyaXRpY2FsIHNldmVyaXR5
LgoKDAoFBQACAQESAyYCEwoMCgUFAAIBAhIDJhYXCh0KBAUAAgISAykCFBoQIEhpZ2ggc2V2
ZXJpdHkuCgoMCgUFAAICARIDKQIPCgwKBQUAAgICEgMpEhMKHwoEBQACAxIDLAIWGhIgTWVk
aXVtIHNldmVyaXR5LgoKDAoFBQACAwESAywCEQoMCgUFAAIDAhIDLBQVChwKBAUAAgQSAy8C
ExoPIExvdyBzZXZlcml0eS4KCgwKBQUAAgQBEgMvAg4KDAoFBQACBAISAy8REgosCgIEABIE
MwB3ARogIFJlcHJlc2VudHMgYSBzZWN1cml0eSBGaW5kaW5nLgoKCgoDBAABEgMzCA8KCwoD
BAAHEgQ0AjkECg0KBQQAB50IEgQ0AjkECi0KBAQAAwASBDwCQgMaHyBGaWxlIGxvY2F0aW9u
IG9mIHRoZSBmaW5kaW5nLgoKDAoFBAADAAESAzwKDgpMCgYEAAMAAgASAz4EPRo9IE9wdGlv
bmFsLiBSZWxhdGl2ZSBwYXRoIG9mIHRoZSBmaWxlIGNvbnRhaW5pbmcgdGhlIGZpbmRpbmcu
CgoOCgcEAAMAAgAFEgM+BAoKDgoHBAADAAIAARIDPgsPCg4KBwQAAwACAAMSAz4SEwoOCgcE
AAMAAgAIEgM+FDwKEQoKBAADAAIACJwIABIDPhU7Ck8KBgQAAwACARIDQQRDGkAgT3B0aW9u
YWwuIExpbmUgbnVtYmVyICgxLWJhc2VkKSwgb3IgMCBpZiB3aG9sZSBGaWxlIC8gdW5rbm93
bi4KCg4KBwQAAwACAQUSA0EECQoOCgcEAAMAAgEBEgNBChUKDgoHBAADAAIBAxIDQRgZCg4K
BwQAAwACAQgSA0EaQgoRCgoEAAMAAgEInAgAEgNBG0EKxwEKBAQABAASBEcCUgMauAEgUmVw
cmVzZW50cyB3aGF0IGtpbmQgb2YgRmluZGluZyBpdCBpcy4KIEZvciBtb3JlIGluZm9ybWF0
aW9uIG9uIGZpbmRpbmcgY2xhc3Nlcywgc2VlCiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20v
c2VjdXJpdHktY29tbWFuZC1jZW50ZXIvZG9jcy9jb25jZXB0cy12dWxuZXJhYmlsaXRpZXMt
ZmluZGluZ3MjY2xhc3Nlcy4KCgwKBQQABAABEgNHBxMKKwoGBAAEAAIAEgNJBCIaHCBVbnNw
ZWNpZmllZCBmaW5kaW5nIGNsYXNzLgoKDgoHBAAEAAIAARIDSQQdCg4KBwQABAACAAISA0kg
IQp/CgYEAAQAAgESA00EFhpwIERlc2NyaWJlcyBhIHBvdGVudGlhbCB3ZWFrbmVzcyBpbiBz
b2Z0d2FyZSB0aGF0IGluY3JlYXNlcyByaXNrIHRvCiBDb25maWRlbnRpYWxpdHkgJiBJbnRl
Z3JpdHkgJiBBdmFpbGFiaWxpdHkuCgoOCgcEAAQAAgEBEgNNBBEKDgoHBAAEAAIBAhIDTRQV
CooBCgYEAAQAAgISA1EEDxp7IERlc2NyaWJlcyBhIHBvdGVudGlhbCBzZWN1cml0eSByaXNr
IGR1ZSB0byBwbGFpbnRleHQgY3JlZGVudGlhbHMsCiBrZXlzLCBvciB0b2tlbnMgYmVpbmcg
ZXhwb3NlZCBpbiBhbiBhc3NldCBvciB3b3JrbG9hZC4KCg4KBwQABAACAgESA1EECgoOCgcE
AAQAAgICEgNRDQ4KfwoEBAACABIDVgI9GnIgSWRlbnRpZmllci4gUmVzb3VyY2UgbmFtZSBv
ZiB0aGUgRmluZGluZy4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9maW5kaW5ncy97ZmluZGluZ31gLgoKDAoFBAACAAUSA1YCCAoMCgUEAAIA
ARIDVgkNCgwKBQQAAgADEgNWEBEKDAoFBAACAAgSA1YSPAoPCggEAAIACJwIABIDVhM7ClMK
BAQAAgESBFkCXAQaRSBPdXRwdXQgb25seS4gVW5pdmVyc2FsbHkgdW5pcXVlIGlkZW50aWZp
ZXIgKFVVSUQ0KSBmb3IgdGhlIEZpbmRpbmcuCgoMCgUEAAIBBRIDWQIICgwKBQQAAgEBEgNZ
CQwKDAoFBAACAQMSA1kPEAoNCgUEAAIBCBIEWRFcAwoSCgsEAAIBCMzx+YoBARIDWgQqCg8K
CAQAAgEInAgAEgNbBC0KKQoEBAACAhIEXwJgMhobIE91dHB1dCBvbmx5LiBDcmVhdGUgdGlt
ZS4KCgwKBQQAAgIGEgNfAhsKDAoFBAACAgESA18cJwoMCgUEAAICAxIDXyorCgwKBQQAAgII
EgNgBjEKDwoIBAACAgicCAASA2AHMAopCgQEAAIDEgRjAmQyGhsgT3V0cHV0IG9ubHkuIFVw
ZGF0ZSB0aW1lLgoKDAoFBAACAwYSA2MCGwoMCgUEAAIDARIDYxwnCgwKBQQAAgMDEgNjKisK
DAoFBAACAwgSA2QGMQoPCggEAAIDCJwIABIDZAcwCjEKBAQAAgQSA2cCQRokIE9wdGlvbmFs
LiBTZXZlcml0eSBvZiB0aGUgZmluZGluZy4KCgwKBQQAAgQGEgNnAgoKDAoFBAACBAESA2cL
EwoMCgUEAAIEAxIDZxYXCgwKBQQAAgQIEgNnGEAKDwoIBAACBAicCAASA2cZPwouCgQEAAIF
EgNqAkoaISBPcHRpb25hbC4gQ2xhc3Mgb2YgdGhlIGZpbmRpbmcuCgoMCgUEAAIFBhIDagIO
CgwKBQQAAgUBEgNqDxwKDAoFBAACBQMSA2ofIAoMCgUEAAIFCBIDaiFJCg8KCAQAAgUInAgA
EgNqIkgKOgoEBAACBhIDbQJDGi0gT3B0aW9uYWwuIEZpbGUgYXNzb2NpYXRlZCB3aXRoIHRo
ZSBmaW5kaW5nLgoKDAoFBAACBgQSA20CCgoMCgUEAAIGBhIDbQsPCgwKBQQAAgYBEgNtEBUK
DAoFBAACBgMSA20YGQoMCgUEAAIGCBIDbRpCCg8KCAQAAgYInAgAEgNtG0EKPQoEBAACBxID
cAI+GjAgT3B0aW9uYWwuIERldGFpbGVkIGRlc2NyaXB0aW9uIG9mIHRoZSBmaW5kaW5nLgoK
DAoFBAACBwUSA3ACCAoMCgUEAAIHARIDcAkPCgwKBQQAAgcDEgNwEhQKDAoFBAACBwgSA3AV
PQoPCggEAAIHCJwIABIDcBY8CksKBAQAAggSBHMCdgQaPSBPcHRpb25hbC4gVGhlIHJlc291
cmNlIHRoYXQgdGhlIGZpbmRpbmcgaXMgYXNzb2NpYXRlZCB3aXRoLgoKDAoFBAACCAUSA3MC
CAoMCgUEAAIIARIDcwkRCgwKBQQAAggDEgNzFBYKDQoFBAACCAgSBHMXdgMKDwoIBAACCAic
CAASA3QEKgoOCgcEAAIICJ8IEgN1BDNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Agentregistry::V1::Finding::Finding ===
    # Fields for Finding
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: severity Type: 14 (.google.cloud.agentregistry.v1.Severity)
    # Field: finding_class Type: 14 (.google.cloud.agentregistry.v1.Finding.FindingClass)
    # Field: files Type: 11 (.google.cloud.agentregistry.v1.Finding.File)
    # Field: detail Type: 9 ()
    # Field: resource Type: 9 ()

# Enum: Finding::FindingClass
our $Finding_FINDING_CLASS_UNSPECIFIED = 0;
our $Finding_VULNERABILITY = 1;
our $Finding_SECRET = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Agentregistry::V1::Finding - Compiled Protocol Buffers messages for google/cloud/agentregistry/v1/finding.proto

=head1 SYNOPSIS

    use Google::Cloud::Agentregistry::V1::Finding;

    my $msg = Google::Cloud::Agentregistry::V1::Finding::Finding->new({
        name => $name,
        uid => $uid,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Agentregistry::V1::Finding::Finding->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/agentregistry/v1/finding.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Agentregistry::V1::Finding::Finding

Represents a security Finding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Resource name of the Finding.
Format: `projects/{project}/locations/{location}/findings/{finding}`.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. Universally unique identifier (UUID4) for the Finding.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Update time.

=item * C<< $msg->severity() >> / C<< $msg->severity($value) >>

Type: C<Enum> (L<Google::Cloud::Agentregistry::V1::Severity>)

Optional. Severity of the finding.

=item * C<< $msg->finding_class() >> / C<< $msg->finding_class($value) >>

Type: C<Enum> (L<Google::Cloud::Agentregistry::V1::Finding::FindingClass>)

Optional. Class of the finding.

=item * C<< $msg->files() >> / C<< $msg->files($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::Finding::Finding::File>)

Optional. File associated with the finding.

=item * C<< $msg->detail() >> / C<< $msg->detail($value) >>

Type: C<String>

Optional. Detailed description of the finding.

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<String>

Optional. The resource that the finding is associated with.

=back

=head3 Enum: Finding::FindingClass

=over 4

=item * C<FINDING_CLASS_UNSPECIFIED> => C<0>

=item * C<VULNERABILITY> => C<1>

=item * C<SECRET> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Agentregistry::V1::Finding::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
