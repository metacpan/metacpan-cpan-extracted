package Google::Cloud::Ces::V1beta::AppVersion;

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
    eval { require Google::Cloud::Ces::V1beta::Agent };
    eval { require Google::Cloud::Ces::V1beta::App };
    eval { require Google::Cloud::Ces::V1beta::Example };
    eval { require Google::Cloud::Ces::V1beta::Guardrail };
    eval { require Google::Cloud::Ces::V1beta::Tool };
    eval { require Google::Cloud::Ces::V1beta::Toolset };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9hcHBfdmVyc2lvbi5wcm90bxIXZ29vZ2xlLmNs
b3VkLmNlcy52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2ds
ZS9hcGkvcmVzb3VyY2UucHJvdG8aI2dvb2dsZS9jbG91ZC9jZXMvdjFiZXRhL2FnZW50LnBy
b3RvGiFnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9hcHAucHJvdG8aJWdvb2dsZS9jbG91ZC9j
ZXMvdjFiZXRhL2V4YW1wbGUucHJvdG8aJ2dvb2dsZS9jbG91ZC9jZXMvdjFiZXRhL2d1YXJk
cmFpbC5wcm90bxoiZ29vZ2xlL2Nsb3VkL2Nlcy92MWJldGEvdG9vbC5wcm90bxolZ29vZ2xl
L2Nsb3VkL2Nlcy92MWJldGEvdG9vbHNldC5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVz
dGFtcC5wcm90byKIAwoLQXBwU25hcHNob3QSMwoDYXBwGAEgASgLMhwuZ29vZ2xlLmNsb3Vk
LmNlcy52MWJldGEuQXBwQgPgQQFSA2FwcBI7CgZhZ2VudHMYAiADKAsyHi5nb29nbGUuY2xv
dWQuY2VzLnYxYmV0YS5BZ2VudEID4EEBUgZhZ2VudHMSOAoFdG9vbHMYAyADKAsyHS5nb29n
bGUuY2xvdWQuY2VzLnYxYmV0YS5Ub29sQgPgQQFSBXRvb2xzEkEKCGV4YW1wbGVzGAQgAygL
MiAuZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEuRXhhbXBsZUID4EEBUghleGFtcGxlcxJHCgpn
dWFyZHJhaWxzGAUgAygLMiIuZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEuR3VhcmRyYWlsQgPg
QQFSCmd1YXJkcmFpbHMSQQoIdG9vbHNldHMYBiADKAsyIC5nb29nbGUuY2xvdWQuY2VzLnYx
YmV0YS5Ub29sc2V0QgPgQQFSCHRvb2xzZXRzIvwDCgpBcHBWZXJzaW9uEhcKBG5hbWUYASAB
KAlCA+BBCFIEbmFtZRImCgxkaXNwbGF5X25hbWUYAiABKAlCA+BBAVILZGlzcGxheU5hbWUS
JQoLZGVzY3JpcHRpb24YAyABKAlCA+BBAVILZGVzY3JpcHRpb24SHQoHY3JlYXRvchgEIAEo
CUID4EEDUgdjcmVhdG9yEkAKC2NyZWF0ZV90aW1lGAUgASgLMhouZ29vZ2xlLnByb3RvYnVm
LlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAkgASgLMhouZ29v
Z2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEkUKCHNuYXBzaG90GAgg
ASgLMiQuZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEuQXBwU25hcHNob3RCA+BBA1IIc25hcHNo
b3QSFwoEZXRhZxgHIAEoCUID4EEDUgRldGFnOoIB6kF/Ch1jZXMuZ29vZ2xlYXBpcy5jb20v
QXBwVmVyc2lvbhJFcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2Fw
cHMve2FwcH0vdmVyc2lvbnMve3ZlcnNpb259KgthcHBWZXJzaW9uczIKYXBwVmVyc2lvbkJf
Chtjb20uZ29vZ2xlLmNsb3VkLmNlcy52MWJldGFCD0FwcFZlcnNpb25Qcm90b1ABWi1jbG91
ZC5nb29nbGUuY29tL2dvL2Nlcy9hcGl2MWJldGEvY2VzcGI7Y2VzcGJKrBkKBhIEDgBeAQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIAoJCgIDABIDEgAp
CgkKAgMBEgMTACMKCQoCAwISAxQALQoJCgIDAxIDFQArCgkKAgMEEgMWAC8KCQoCAwUSAxcA
MQoJCgIDBhIDGAAsCgkKAgMHEgMZAC8KCQoCAwgSAxoAKQoICgEIEgMcAEQKCQoCCAsSAxwA
RAoICgEIEgMdACIKCQoCCAoSAx0AIgoICgEIEgMeADAKCQoCCAgSAx4AMAoICgEIEgMfADQK
CQoCCAESAx8ANAokCgIEABIEIgA0ARoYIEEgc25hcHNob3Qgb2YgdGhlIGFwcC4KCgoKAwQA
ARIDIggTCjgKBAQAAgASAyQCNxorIE9wdGlvbmFsLiBUaGUgYmFzaWMgc2V0dGluZ3MgZm9y
IHRoZSBhcHAuCgoMCgUEAAIABhIDJAIFCgwKBQQAAgABEgMkBgkKDAoFBAACAAMSAyQMDQoM
CgUEAAIACBIDJA42Cg8KCAQAAgAInAgAEgMkDzUKMwoEBAACARIDJwJFGiYgT3B0aW9uYWwu
IExpc3Qgb2YgYWdlbnRzIGluIHRoZSBhcHAuCgoMCgUEAAIBBBIDJwIKCgwKBQQAAgEGEgMn
CxAKDAoFBAACAQESAycRFwoMCgUEAAIBAxIDJxobCgwKBQQAAgEIEgMnHEQKDwoIBAACAQic
CAASAycdQwoyCgQEAAICEgMqAkMaJSBPcHRpb25hbC4gTGlzdCBvZiB0b29scyBpbiB0aGUg
YXBwLgoKDAoFBAACAgQSAyoCCgoMCgUEAAICBhIDKgsPCgwKBQQAAgIBEgMqEBUKDAoFBAAC
AgMSAyoYGQoMCgUEAAICCBIDKhpCCg8KCAQAAgIInAgAEgMqG0EKNQoEBAACAxIDLQJJGigg
T3B0aW9uYWwuIExpc3Qgb2YgZXhhbXBsZXMgaW4gdGhlIGFwcC4KCgwKBQQAAgMEEgMtAgoK
DAoFBAACAwYSAy0LEgoMCgUEAAIDARIDLRMbCgwKBQQAAgMDEgMtHh8KDAoFBAACAwgSAy0g
SAoPCggEAAIDCJwIABIDLSFHCjcKBAQAAgQSAzACTRoqIE9wdGlvbmFsLiBMaXN0IG9mIGd1
YXJkcmFpbHMgaW4gdGhlIGFwcC4KCgwKBQQAAgQEEgMwAgoKDAoFBAACBAYSAzALFAoMCgUE
AAIEARIDMBUfCgwKBQQAAgQDEgMwIiMKDAoFBAACBAgSAzAkTAoPCggEAAIECJwIABIDMCVL
CjUKBAQAAgUSAzMCSRooIE9wdGlvbmFsLiBMaXN0IG9mIHRvb2xzZXRzIGluIHRoZSBhcHAu
CgoMCgUEAAIFBBIDMwIKCgwKBQQAAgUGEgMzCxIKDAoFBAACBQESAzMTGwoMCgUEAAIFAxID
Mx4fCgwKBQQAAgUIEgMzIEgKDwoIBAACBQicCAASAzMhRwquAQoCBAESBDkAXgEaoQEgSW4g
Q3VzdG9tZXIgRW5nYWdlbWVudCBTdWl0ZSAoQ0VTKSwgYW4gYXBwIHZlcnNpb24gaXMgYSBz
bmFwc2hvdCBvZiB0aGUgYXBwCiBhdCBhIHNwZWNpZmljIHBvaW50IGluIHRpbWUuIEl0IGlz
IGltbXV0YWJsZSBhbmQgY2Fubm90IGJlIG1vZGlmaWVkIG9uY2UKIGNyZWF0ZWQuCgoKCgME
AQESAzkIEgoLCgMEAQcSBDoCPwQKDQoFBAEHnQgSBDoCPwQKlwEKBAQBAgASA0QCPRqJASBJ
ZGVudGlmaWVyLiBUaGUgdW5pcXVlIGlkZW50aWZpZXIgb2YgdGhlIGFwcCB2ZXJzaW9uLgog
Rm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hcHBz
L3thcHB9L3ZlcnNpb25zL3t2ZXJzaW9ufWAKCgwKBQQBAgAFEgNEAggKDAoFBAECAAESA0QJ
DQoMCgUEAQIAAxIDRBARCgwKBQQBAgAIEgNEEjwKDwoIBAECAAicCAASA0QTOwo9CgQEAQIB
EgNHAkMaMCBPcHRpb25hbC4gVGhlIGRpc3BsYXkgbmFtZSBvZiB0aGUgYXBwIHZlcnNpb24u
CgoMCgUEAQIBBRIDRwIICgwKBQQBAgEBEgNHCRUKDAoFBAECAQMSA0cYGQoMCgUEAQIBCBID
RxpCCg8KCAQBAgEInAgAEgNHG0EKPAoEBAECAhIDSgJCGi8gT3B0aW9uYWwuIFRoZSBkZXNj
cmlwdGlvbiBvZiB0aGUgYXBwIHZlcnNpb24uCgoMCgUEAQICBRIDSgIICgwKBQQBAgIBEgNK
CRQKDAoFBAECAgMSA0oXGAoMCgUEAQICCBIDShlBCg8KCAQBAgIInAgAEgNKGkAKSgoEBAEC
AxIDTQJBGj0gT3V0cHV0IG9ubHkuIEVtYWlsIG9mIHRoZSB1c2VyIHdobyBjcmVhdGVkIHRo
ZSBhcHAgdmVyc2lvbi4KCgwKBQQBAgMFEgNNAggKDAoFBAECAwESA00JEAoMCgUEAQIDAxID
TRMUCgwKBQQBAgMIEgNNFUAKDwoIBAECAwicCAASA00WPwpICgQEAQIEEgRQAlEyGjogT3V0
cHV0IG9ubHkuIFRpbWVzdGFtcCB3aGVuIHRoZSBhcHAgdmVyc2lvbiB3YXMgY3JlYXRlZC4K
CgwKBQQBAgQGEgNQAhsKDAoFBAECBAESA1AcJwoMCgUEAQIEAxIDUCorCgwKBQQBAgQIEgNR
BjEKDwoIBAECBAicCAASA1EHMApNCgQEAQIFEgRUAlUyGj8gT3V0cHV0IG9ubHkuIFRpbWVz
dGFtcCB3aGVuIHRoZSBhcHAgdmVyc2lvbiB3YXMgbGFzdCB1cGRhdGVkLgoKDAoFBAECBQYS
A1QCGwoMCgUEAQIFARIDVBwnCgwKBQQBAgUDEgNUKisKDAoFBAECBQgSA1UGMQoPCggEAQIF
CJwIABIDVQcwClAKBAQBAgYSA1gCRxpDIE91dHB1dCBvbmx5LiBUaGUgc25hcHNob3Qgb2Yg
dGhlIGFwcCB3aGVuIHRoZSB2ZXJzaW9uIGlzIGNyZWF0ZWQuCgoMCgUEAQIGBhIDWAINCgwK
BQQBAgYBEgNYDhYKDAoFBAECBgMSA1gZGgoMCgUEAQIGCBIDWBtGCg8KCAQBAgYInAgAEgNY
HEUKugEKBAQBAgcSA10CPhqsASBPdXRwdXQgb25seS4gRXRhZyB1c2VkIHRvIGVuc3VyZSB0
aGUgb2JqZWN0IGhhc24ndCBjaGFuZ2VkIGR1cmluZyBhCiByZWFkLW1vZGlmeS13cml0ZSBv
cGVyYXRpb24uIElmIHRoZSBldGFnIGlzIGVtcHR5LCB0aGUgdXBkYXRlIHdpbGwKIG92ZXJ3
cml0ZSBhbnkgY29uY3VycmVudCBjaGFuZ2VzLgoKDAoFBAECBwUSA10CCAoMCgUEAQIHARID
XQkNCgwKBQQBAgcDEgNdEBEKDAoFBAECBwgSA10SPQoPCggEAQIHCJwIABIDXRM8YgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::AppVersion::AppSnapshot ===
    # Fields for AppSnapshot
    # Field: app Type: 11 (.google.cloud.ces.v1beta.App)
    # Field: agents Type: 11 (.google.cloud.ces.v1beta.Agent)
    # Field: tools Type: 11 (.google.cloud.ces.v1beta.Tool)
    # Field: examples Type: 11 (.google.cloud.ces.v1beta.Example)
    # Field: guardrails Type: 11 (.google.cloud.ces.v1beta.Guardrail)
    # Field: toolsets Type: 11 (.google.cloud.ces.v1beta.Toolset)

# === Message: Google::Cloud::Ces::V1beta::AppVersion::AppVersion ===
    # Fields for AppVersion
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: creator Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: snapshot Type: 11 (.google.cloud.ces.v1beta.AppSnapshot)
    # Field: etag Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::AppVersion - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/app_version.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::AppVersion;

    my $msg = Google::Cloud::Ces::V1beta::AppVersion::AppSnapshot->new({
        app => $app,
        agents => $agents,
        tools => $tools,
        examples => $examples,
    });

    # Read or update a field
    my $val = $msg->app();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::AppVersion::AppSnapshot->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/app_version.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::AppVersion::AppSnapshot

A snapshot of the app.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->app() >> / C<< $msg->app($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::App::App>)

Optional. The basic settings for the app.

=item * C<< $msg->agents() >> / C<< $msg->agents($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Agent::Agent>)

Optional. List of agents in the app.

=item * C<< $msg->tools() >> / C<< $msg->tools($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Tool::Tool>)

Optional. List of tools in the app.

=item * C<< $msg->examples() >> / C<< $msg->examples($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Example::Example>)

Optional. List of examples in the app.

=item * C<< $msg->guardrails() >> / C<< $msg->guardrails($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Guardrail::Guardrail>)

Optional. List of guardrails in the app.

=item * C<< $msg->toolsets() >> / C<< $msg->toolsets($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Toolset::Toolset>)

Optional. List of toolsets in the app.

=back

=head2 Google::Cloud::Ces::V1beta::AppVersion::AppVersion

In Customer Engagement Suite (CES), an app version is a snapshot of the app
at a specific point in time. It is immutable and cannot be modified once
created.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The unique identifier of the app version.
Format:
`projects/{project}/locations/{location}/apps/{app}/versions/{version}`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. The display name of the app version.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The description of the app version.

=item * C<< $msg->creator() >> / C<< $msg->creator($value) >>

Type: C<String>

Output only. Email of the user who created the app version.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the app version was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the app version was last updated.

=item * C<< $msg->snapshot() >> / C<< $msg->snapshot($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::AppVersion::AppSnapshot>)

Output only. The snapshot of the app when the version is created.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. Etag used to ensure the object hasn't changed during a
read-modify-write operation. If the etag is empty, the update will
overwrite any concurrent changes.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::AppVersion::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
