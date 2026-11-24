package Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvZ2tlaHViL3YxYWxwaGEvc2VydmljZW1lc2gvc2VydmljZW1lc2gu
cHJvdG8SJ2dvb2dsZS5jbG91ZC5na2VodWIuc2VydmljZW1lc2gudjFhbHBoYRofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxocZ29vZ2xlL3Byb3RvYnVmL3N0cnVjdC5wcm90
byJ6CgxGZWF0dXJlU3RhdGUSagoRYW5hbHlzaXNfbWVzc2FnZXMYASADKAsyOC5nb29nbGUu
Y2xvdWQuZ2tlaHViLnNlcnZpY2VtZXNoLnYxYWxwaGEuQW5hbHlzaXNNZXNzYWdlQgPgQQNS
EGFuYWx5c2lzTWVzc2FnZXMifQoPTWVtYmVyc2hpcFN0YXRlEmoKEWFuYWx5c2lzX21lc3Nh
Z2VzGAEgAygLMjguZ29vZ2xlLmNsb3VkLmdrZWh1Yi5zZXJ2aWNlbWVzaC52MWFscGhhLkFu
YWx5c2lzTWVzc2FnZUID4EEDUhBhbmFseXNpc01lc3NhZ2VzIvQCChNBbmFseXNpc01lc3Nh
Z2VCYXNlElUKBHR5cGUYASABKAsyQS5nb29nbGUuY2xvdWQuZ2tlaHViLnNlcnZpY2VtZXNo
LnYxYWxwaGEuQW5hbHlzaXNNZXNzYWdlQmFzZS5UeXBlUgR0eXBlElgKBWxldmVsGAIgASgO
MkIuZ29vZ2xlLmNsb3VkLmdrZWh1Yi5zZXJ2aWNlbWVzaC52MWFscGhhLkFuYWx5c2lzTWVz
c2FnZUJhc2UuTGV2ZWxSBWxldmVsEisKEWRvY3VtZW50YXRpb25fdXJsGAMgASgJUhBkb2N1
bWVudGF0aW9uVXJsGj0KBFR5cGUSIQoMZGlzcGxheV9uYW1lGAEgASgJUgtkaXNwbGF5TmFt
ZRISCgRjb2RlGAIgASgJUgRjb2RlIkAKBUxldmVsEhUKEUxFVkVMX1VOU1BFQ0lGSUVEEAAS
CQoFRVJST1IQAxILCgdXQVJOSU5HEAgSCAoESU5GTxAMIugBCg9BbmFseXNpc01lc3NhZ2US
XwoMbWVzc2FnZV9iYXNlGAEgASgLMjwuZ29vZ2xlLmNsb3VkLmdrZWh1Yi5zZXJ2aWNlbWVz
aC52MWFscGhhLkFuYWx5c2lzTWVzc2FnZUJhc2VSC21lc3NhZ2VCYXNlEiAKC2Rlc2NyaXB0
aW9uGAIgASgJUgtkZXNjcmlwdGlvbhIlCg5yZXNvdXJjZV9wYXRocxgDIAMoCVINcmVzb3Vy
Y2VQYXRocxIrCgRhcmdzGAQgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFIEYXJnc0KS
AgorY29tLmdvb2dsZS5jbG91ZC5na2VodWIuc2VydmljZW1lc2gudjFhbHBoYUIQU2Vydmlj
ZU1lc2hQcm90b1ABWk1jbG91ZC5nb29nbGUuY29tL2dvL2drZWh1Yi9zZXJ2aWNlbWVzaC9h
cGl2MWFscGhhL3NlcnZpY2VtZXNocGI7c2VydmljZW1lc2hwYqoCJ0dvb2dsZS5DbG91ZC5H
a2VIdWIuU2VydmljZU1lc2guVjFBbHBoYcoCJ0dvb2dsZVxDbG91ZFxHa2VIdWJcU2Vydmlj
ZU1lc2hcVjFhbHBoYeoCK0dvb2dsZTo6Q2xvdWQ6OkdrZUh1Yjo6U2VydmljZU1lc2g6OlYx
YWxwaGFK3CEKBhIEDgBxAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAAMAoJCgIDABIDEgApCgkKAgMBEgMTACYKCAoBCBIDFQBECgkKAgglEgMVAEQKCAoB
CBIDFgBkCgkKAggLEgMWAGQKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAAxCgkKAggI
EgMYADEKCAoBCBIDGQBECgkKAggBEgMZAEQKCAoBCBIDGgBFCgkKAggpEgMaAEUKCAoBCBID
GwBECgkKAggtEgMbAEQKaQoCBAASBB8AIgEaXSAqKlNlcnZpY2UgTWVzaCoqOiBTdGF0ZSBm
b3IgdGhlIHdob2xlIEh1YiwgYXMgYW5hbHl6ZWQgYnkgdGhlIFNlcnZpY2UgTWVzaAogSHVi
IENvbnRyb2xsZXIuCgoKCgMEAAESAx8IFApGCgQEAAIAEgMhAl0aOSBPdXRwdXQgb25seS4g
UmVzdWx0cyBvZiBydW5uaW5nIFNlcnZpY2UgTWVzaCBhbmFseXplcnMuCgoMCgUEAAIABBID
IQIKCgwKBQQAAgAGEgMhCxoKDAoFBAACAAESAyEbLAoMCgUEAAIAAxIDIS8wCgwKBQQAAgAI
EgMhMVwKDwoIBAACAAicCAASAyEyWwpvCgIEARIEJgApARpjICoqU2VydmljZSBNZXNoKio6
IFN0YXRlIGZvciBhIHNpbmdsZSBNZW1iZXJzaGlwLCBhcyBhbmFseXplZCBieSB0aGUgU2Vy
dmljZQogTWVzaCBIdWIgQ29udHJvbGxlci4KCgoKAwQBARIDJggXCkYKBAQBAgASAygCXRo5
IE91dHB1dCBvbmx5LiBSZXN1bHRzIG9mIHJ1bm5pbmcgU2VydmljZSBNZXNoIGFuYWx5emVy
cy4KCgwKBQQBAgAEEgMoAgoKDAoFBAECAAYSAygLGgoMCgUEAQIAARIDKBssCgwKBQQBAgAD
EgMoLzAKDAoFBAECAAgSAygxXAoPCggEAQIACJwIABIDKDJbCmUKAgQCEgQtAFkBGlkgQW5h
bHlzaXNNZXNzYWdlQmFzZSBkZXNjcmliZXMgc29tZSBjb21tb24gaW5mb3JtYXRpb24gdGhh
dCBpcwogbmVlZGVkIGZvciBhbGwgbWVzc2FnZXMuCgoKCgMEAgESAy0IGwrVAgoEBAIDABIE
MwI9AxrGAiBBIHVuaXF1ZSBpZGVudGlmaWVyIGZvciB0aGUgdHlwZSBvZiBtZXNzYWdlLiBE
aXNwbGF5X25hbWUgaXMgaW50ZW5kZWQgdG8gYmUKIGh1bWFuLXJlYWRhYmxlLCBjb2RlIGlz
IGludGVuZGVkIHRvIGJlIG1hY2hpbmUgcmVhZGFibGUuIFRoZXJlIHNob3VsZCBiZSBhCiBv
bmUtdG8tb25lIG1hcHBpbmcgYmV0d2VlbiBkaXNwbGF5X25hbWUgYW5kIGNvZGUuIChpLmUu
IGRvIG5vdCByZS11c2UKIGRpc3BsYXlfbmFtZXMgb3IgY29kZXMgYmV0d2VlbiBtZXNzYWdl
IHR5cGVzLikKIFNlZSBpc3Rpby5hbmFseXNpcy52MWFscGhhMS5BbmFseXNpc01lc3NhZ2VC
YXNlLlR5cGUKCgwKBQQCAwABEgMzCg4K4AEKBgQCAwACABIDNwQcGtABIEEgaHVtYW4tcmVh
ZGFibGUgbmFtZSBmb3IgdGhlIG1lc3NhZ2UgdHlwZS4gZS5nLiAiSW50ZXJuYWxFcnJvciIs
CiAiUG9kTWlzc2luZ1Byb3h5Ii4gVGhpcyBzaG91bGQgYmUgdGhlIHNhbWUgZm9yIGFsbCBt
ZXNzYWdlcyBvZiB0aGUgc2FtZQogdHlwZS4gKFRoaXMgY29ycmVzcG9uZHMgdG8gdGhlIGBu
YW1lYCBmaWVsZCBpbiBvcGVuLXNvdXJjZSBJc3Rpby4pCgoOCgcEAgMAAgAFEgM3BAoKDgoH
BAIDAAIAARIDNwsXCg4KBwQCAwACAAMSAzcaGwrDAQoGBAIDAAIBEgM8BBQaswEgQSA3IGNo
YXJhY3RlciBjb2RlIG1hdGNoaW5nIGBeSVNUWzAtOV17NH0kYCBvciBgXkFTTVswLTldezR9
JGAsIGludGVuZGVkCiB0byB1bmlxdWVseSBpZGVudGlmeSB0aGUgbWVzc2FnZSB0eXBlLiAo
ZS5nLiAiSVNUMDAwMSIgaXMgbWFwcGVkIHRvIHRoZQogIkludGVybmFsRXJyb3IiIG1lc3Nh
Z2UgdHlwZS4pCgoOCgcEAgMAAgEFEgM8BAoKDgoHBAIDAAIBARIDPAsPCg4KBwQCAwACAQMS
AzwSEwrJAQoEBAIEABIEQgJOAxq6ASBUaGUgdmFsdWVzIGhlcmUgYXJlIGNob3NlbiBzbyB0
aGF0IG1vcmUgc2V2ZXJlIG1lc3NhZ2VzIGdldCBzb3J0ZWQgaGlnaGVyLAogYXMgd2VsbCBh
cyBsZWF2aW5nIHNwYWNlIGluIGJldHdlZW4gdG8gYWRkIG1vcmUgbGF0ZXIKIFNlZSBpc3Rp
by5hbmFseXNpcy52MWFscGhhMS5BbmFseXNpc01lc3NhZ2VCYXNlLkxldmVsCgoMCgUEAgQA
ARIDQgcMClkKBgQCBAACABIDRAQaGkogSWxsZWdhbC4gU2FtZSBpc3Rpby5hbmFseXNpcy52
MWFscGhhMS5BbmFseXNpc01lc3NhZ2VCYXNlLkxldmVsLlVOS05PV04uCgoOCgcEAgQAAgAB
EgNEBBUKDgoHBAIEAAIAAhIDRBgZCkgKBgQCBAACARIDRwQOGjkgRVJST1IgcmVwcmVzZW50
cyBhIG1pc2NvbmZpZ3VyYXRpb24gdGhhdCBtdXN0IGJlIGZpeGVkLgoKDgoHBAIEAAIBARID
RwQJCg4KBwQCBAACAQISA0cMDQpMCgYEAgQAAgISA0oEEBo9IFdBUk5JTkcgcmVwcmVzZW50
cyBhIG1pc2NvbmZpZ3VyYXRpb24gdGhhdCBzaG91bGQgYmUgZml4ZWQuCgoOCgcEAgQAAgIB
EgNKBAsKDgoHBAIEAAICAhIDSg4PCjoKBgQCBAACAxIDTQQOGisgSU5GTyByZXByZXNlbnRz
IGFuIGluZm9ybWF0aW9uYWwgZmluZGluZy4KCg4KBwQCBAACAwESA00ECAoOCgcEAgQAAgMC
EgNNCw0KOQoEBAICABIDUQIQGiwgUmVwcmVzZW50cyB0aGUgc3BlY2lmaWMgdHlwZSBvZiBh
IG1lc3NhZ2UuCgoMCgUEAgIABhIDUQIGCgwKBQQCAgABEgNRBwsKDAoFBAICAAMSA1EODwoy
CgQEAgIBEgNUAhIaJSBSZXByZXNlbnRzIGhvdyBzZXZlcmUgYSBtZXNzYWdlIGlzLgoKDAoF
BAICAQYSA1QCBwoMCgUEAgIBARIDVAgNCgwKBQQCAgEDEgNUEBEKZwoEBAICAhIDWAIfGlog
QSB1cmwgcG9pbnRpbmcgdG8gdGhlIFNlcnZpY2UgTWVzaCBvciBJc3RpbyBkb2N1bWVudGF0
aW9uIGZvciB0aGlzIHNwZWNpZmljCiBlcnJvciB0eXBlLgoKDAoFBAICAgUSA1gCCAoMCgUE
AgICARIDWAkaCgwKBQQCAgIDEgNYHR4KrQEKAgQDEgReAHEBGqABIEFuYWx5c2lzTWVzc2Fn
ZSBpcyBhIHNpbmdsZSBtZXNzYWdlIHByb2R1Y2VkIGJ5IGFuIGFuYWx5emVyLCBhbmQKIGl0
IHVzZWQgdG8gY29tbXVuaWNhdGUgdG8gdGhlIGVuZCB1c2VyIGFib3V0IHRoZSBzdGF0ZSBv
ZiB0aGVpciBTZXJ2aWNlCiBNZXNoIGNvbmZpZ3VyYXRpb24uCgoKCgMEAwESA14IFwpWCgQE
AwIAEgNgAicaSSBEZXRhaWxzIGNvbW1vbiB0byBhbGwgdHlwZXMgb2YgSXN0aW8gYW5kIFNl
cnZpY2VNZXNoIGFuYWx5c2lzIG1lc3NhZ2VzLgoKDAoFBAMCAAYSA2ACFQoMCgUEAwIAARID
YBYiCgwKBQQDAgADEgNgJSYKfwoEBAMCARIDZAIZGnIgQSBodW1hbiByZWFkYWJsZSBkZXNj
cmlwdGlvbiBvZiB3aGF0IHRoZSBlcnJvciBtZWFucy4gSXQgaXMgc3VpdGFibGUgZm9yCiBu
b24taW50ZXJuYXRpb25hbGl6ZSBkaXNwbGF5IHB1cnBvc2VzLgoKDAoFBAMCAQUSA2QCCAoM
CgUEAwIBARIDZAkUCgwKBQQDAgEDEgNkFxgKnQIKBAQDAgISA2wCJRqPAiBBIGxpc3Qgb2Yg
c3RyaW5ncyBzcGVjaWZ5aW5nIHRoZSByZXNvdXJjZSBpZGVudGlmaWVycyB0aGF0IHdlcmUg
dGhlIGNhdXNlCiBvZiBtZXNzYWdlIGdlbmVyYXRpb24uCiBBICJwYXRoIiBoZXJlIG1heSBi
ZToKICogTUVNQkVSU0hJUF9JRCBpZiB0aGUgY2F1c2UgaXMgYSBzcGVjaWZpYyBtZW1iZXIg
Y2x1c3RlcgogKiBNRU1CRVJTSElQX0lELyhOQU1FU1BBQ0VcLyk/UkVTT1VSQ0VUWVBFL05B
TUUgaWYgdGhlIGNhdXNlIGlzIGEgcmVzb3VyY2UKIGluIGEgY2x1c3RlcgoKDAoFBAMCAgQS
A2wCCgoMCgUEAwICBRIDbAsRCgwKBQQDAgIBEgNsEiAKDAoFBAMCAgMSA2wjJAqBAQoEBAMC
AxIDcAIiGnQgQSBVSSBjYW4gY29tYmluZSB0aGVzZSBhcmdzIHdpdGggYSB0ZW1wbGF0ZSAo
YmFzZWQgb24gbWVzc2FnZV9iYXNlLnR5cGUpCiB0byBwcm9kdWNlIGFuIGludGVybmF0aW9u
YWxpemVkIG1lc3NhZ2UuCgoMCgUEAwIDBhIDcAIYCgwKBQQDAgMBEgNwGR0KDAoFBAMCAwMS
A3AgIWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::FeatureState ===
    # Fields for FeatureState
    # Field: analysis_messages Type: 11 (.google.cloud.gkehub.servicemesh.v1alpha.AnalysisMessage)

# === Message: Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::MembershipState ===
    # Fields for MembershipState
    # Field: analysis_messages Type: 11 (.google.cloud.gkehub.servicemesh.v1alpha.AnalysisMessage)

# === Message: Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::AnalysisMessageBase ===
    # Fields for AnalysisMessageBase
    # Field: type Type: 11 (.google.cloud.gkehub.servicemesh.v1alpha.AnalysisMessageBase.Type)
    # Field: level Type: 14 (.google.cloud.gkehub.servicemesh.v1alpha.AnalysisMessageBase.Level)
    # Field: documentation_url Type: 9 ()

# Enum: AnalysisMessageBase::Level
our $AnalysisMessageBase_LEVEL_UNSPECIFIED = 0;
our $AnalysisMessageBase_ERROR = 3;
our $AnalysisMessageBase_WARNING = 8;
our $AnalysisMessageBase_INFO = 12;

# === Message: Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::AnalysisMessage ===
    # Fields for AnalysisMessage
    # Field: message_base Type: 11 (.google.cloud.gkehub.servicemesh.v1alpha.AnalysisMessageBase)
    # Field: description Type: 9 ()
    # Field: resource_paths Type: 9 ()
    # Field: args Type: 11 (.google.protobuf.Struct)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh - Compiled Protocol Buffers messages for google/cloud/gkehub/v1alpha/servicemesh/servicemesh.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh;

    my $msg = Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::FeatureState->new({
        analysis_messages => $analysis_messages,
    });

    # Read or update a field
    my $val = $msg->analysis_messages();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::FeatureState->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkehub/v1alpha/servicemesh/servicemesh.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::FeatureState

B<Service Mesh>: State for the whole Hub, as analyzed by the Service Mesh
Hub Controller.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->analysis_messages() >> / C<< $msg->analysis_messages($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::AnalysisMessage>)

Output only. Results of running Service Mesh analyzers.

=back

=head2 Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::MembershipState

B<Service Mesh>: State for a single Membership, as analyzed by the Service
Mesh Hub Controller.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->analysis_messages() >> / C<< $msg->analysis_messages($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::AnalysisMessage>)

Output only. Results of running Service Mesh analyzers.

=back

=head2 Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::AnalysisMessageBase

AnalysisMessageBase describes some common information that is
needed for all messages.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::AnalysisMessageBase::Type>)

Represents the specific type of a message.

=item * C<< $msg->level() >> / C<< $msg->level($value) >>

Type: C<Enum> (L<Google::Cloud::Gkehub::Servicemesh::V1alpha::AnalysisMessageBase::Level>)

Represents how severe a message is.

=item * C<< $msg->documentation_url() >> / C<< $msg->documentation_url($value) >>

Type: C<String>

A url pointing to the Service Mesh or Istio documentation for this specific
error type.

=back

=head3 Enum: AnalysisMessageBase::Level

=over 4

=item * C<LEVEL_UNSPECIFIED> => C<0>

=item * C<ERROR> => C<3>

=item * C<WARNING> => C<8>

=item * C<INFO> => C<12>

=back

=head2 Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::AnalysisMessage

AnalysisMessage is a single message produced by an analyzer, and
it used to communicate to the end user about the state of their Service
Mesh configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message_base() >> / C<< $msg->message_base($value) >>

Type: C<Message> (L<Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::AnalysisMessageBase>)

Details common to all types of Istio and ServiceMesh analysis messages.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A human readable description of what the error means. It is suitable for
non-internationalize display purposes.

=item * C<< $msg->resource_paths() >> / C<< $msg->resource_paths($value) >>

Type: C<String>

A list of strings specifying the resource identifiers that were the cause
of message generation.
A "path" here may be:
* MEMBERSHIP_ID if the cause is a specific member cluster
* MEMBERSHIP_ID/(NAMESPACE\/)?RESOURCETYPE/NAME if the cause is a resource
in a cluster

=item * C<< $msg->args() >> / C<< $msg->args($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

A UI can combine these args with a template (based on message_base.type)
to produce an internationalized message.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkehub::Servicemesh::V1alpha::Servicemesh::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
