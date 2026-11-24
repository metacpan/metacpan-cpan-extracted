package Google::Cloud::Ces::V1::AppVersion;

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
    eval { require Google::Cloud::Ces::V1::Agent };
    eval { require Google::Cloud::Ces::V1::App };
    eval { require Google::Cloud::Ces::V1::Example };
    eval { require Google::Cloud::Ces::V1::Guardrail };
    eval { require Google::Cloud::Ces::V1::Tool };
    eval { require Google::Cloud::Ces::V1::Toolset };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvY2xvdWQvY2VzL3YxL2FwcF92ZXJzaW9uLnByb3RvEhNnb29nbGUuY2xvdWQu
Y2VzLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jl
c291cmNlLnByb3RvGh9nb29nbGUvY2xvdWQvY2VzL3YxL2FnZW50LnByb3RvGh1nb29nbGUv
Y2xvdWQvY2VzL3YxL2FwcC5wcm90bxohZ29vZ2xlL2Nsb3VkL2Nlcy92MS9leGFtcGxlLnBy
b3RvGiNnb29nbGUvY2xvdWQvY2VzL3YxL2d1YXJkcmFpbC5wcm90bxoeZ29vZ2xlL2Nsb3Vk
L2Nlcy92MS90b29sLnByb3RvGiFnb29nbGUvY2xvdWQvY2VzL3YxL3Rvb2xzZXQucHJvdG8a
H2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8i8AIKC0FwcFNuYXBzaG90Ei8KA2Fw
cBgBIAEoCzIYLmdvb2dsZS5jbG91ZC5jZXMudjEuQXBwQgPgQQFSA2FwcBI3CgZhZ2VudHMY
AiADKAsyGi5nb29nbGUuY2xvdWQuY2VzLnYxLkFnZW50QgPgQQFSBmFnZW50cxI0CgV0b29s
cxgDIAMoCzIZLmdvb2dsZS5jbG91ZC5jZXMudjEuVG9vbEID4EEBUgV0b29scxI9CghleGFt
cGxlcxgEIAMoCzIcLmdvb2dsZS5jbG91ZC5jZXMudjEuRXhhbXBsZUID4EEBUghleGFtcGxl
cxJDCgpndWFyZHJhaWxzGAUgAygLMh4uZ29vZ2xlLmNsb3VkLmNlcy52MS5HdWFyZHJhaWxC
A+BBAVIKZ3VhcmRyYWlscxI9Cgh0b29sc2V0cxgGIAMoCzIcLmdvb2dsZS5jbG91ZC5jZXMu
djEuVG9vbHNldEID4EEBUgh0b29sc2V0cyK2AwoKQXBwVmVyc2lvbhIXCgRuYW1lGAEgASgJ
QgPgQQhSBG5hbWUSJgoMZGlzcGxheV9uYW1lGAIgASgJQgPgQQFSC2Rpc3BsYXlOYW1lEiUK
C2Rlc2NyaXB0aW9uGAMgASgJQgPgQQFSC2Rlc2NyaXB0aW9uEh0KB2NyZWF0b3IYBCABKAlC
A+BBA1IHY3JlYXRvchJACgtjcmVhdGVfdGltZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJBCghzbmFwc2hvdBgIIAEoCzIgLmdvb2dsZS5j
bG91ZC5jZXMudjEuQXBwU25hcHNob3RCA+BBA1IIc25hcHNob3QSFwoEZXRhZxgHIAEoCUID
4EEDUgRldGFnOoIB6kF/Ch1jZXMuZ29vZ2xlYXBpcy5jb20vQXBwVmVyc2lvbhJFcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FwcHMve2FwcH0vdmVyc2lvbnMv
e3ZlcnNpb259KgthcHBWZXJzaW9uczIKYXBwVmVyc2lvbkJXChdjb20uZ29vZ2xlLmNsb3Vk
LmNlcy52MUIPQXBwVmVyc2lvblByb3RvUAFaKWNsb3VkLmdvb2dsZS5jb20vZ28vY2VzL2Fw
aXYxL2Nlc3BiO2Nlc3BiSpQYCgYSBA4AWgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAy
NiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJz
aW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4
Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBh
IGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xp
Y2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3
IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIg
dGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhP
VVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVz
cyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3Vh
Z2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExp
Y2Vuc2UuCgoICgECEgMQABwKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACkKCQoC
AwMSAxUAJwoJCgIDBBIDFgArCgkKAgMFEgMXAC0KCQoCAwYSAxgAKAoJCgIDBxIDGQArCgkK
AgMIEgMaACkKCAoBCBIDHABACgkKAggLEgMcAEAKCAoBCBIDHQAiCgkKAggKEgMdACIKCAoB
CBIDHgAwCgkKAggIEgMeADAKCAoBCBIDHwAwCgkKAggBEgMfADAKJAoCBAASBCIANAEaGCBB
IHNuYXBzaG90IG9mIHRoZSBhcHAuCgoKCgMEAAESAyIIEwo4CgQEAAIAEgMkAjcaKyBPcHRp
b25hbC4gVGhlIGJhc2ljIHNldHRpbmdzIGZvciB0aGUgYXBwLgoKDAoFBAACAAYSAyQCBQoM
CgUEAAIAARIDJAYJCgwKBQQAAgADEgMkDA0KDAoFBAACAAgSAyQONgoPCggEAAIACJwIABID
JA81CjMKBAQAAgESAycCRRomIE9wdGlvbmFsLiBMaXN0IG9mIGFnZW50cyBpbiB0aGUgYXBw
LgoKDAoFBAACAQQSAycCCgoMCgUEAAIBBhIDJwsQCgwKBQQAAgEBEgMnERcKDAoFBAACAQMS
AycaGwoMCgUEAAIBCBIDJxxECg8KCAQAAgEInAgAEgMnHUMKMgoEBAACAhIDKgJDGiUgT3B0
aW9uYWwuIExpc3Qgb2YgdG9vbHMgaW4gdGhlIGFwcC4KCgwKBQQAAgIEEgMqAgoKDAoFBAAC
AgYSAyoLDwoMCgUEAAICARIDKhAVCgwKBQQAAgIDEgMqGBkKDAoFBAACAggSAyoaQgoPCggE
AAICCJwIABIDKhtBCjUKBAQAAgMSAy0CSRooIE9wdGlvbmFsLiBMaXN0IG9mIGV4YW1wbGVz
IGluIHRoZSBhcHAuCgoMCgUEAAIDBBIDLQIKCgwKBQQAAgMGEgMtCxIKDAoFBAACAwESAy0T
GwoMCgUEAAIDAxIDLR4fCgwKBQQAAgMIEgMtIEgKDwoIBAACAwicCAASAy0hRwo3CgQEAAIE
EgMwAk0aKiBPcHRpb25hbC4gTGlzdCBvZiBndWFyZHJhaWxzIGluIHRoZSBhcHAuCgoMCgUE
AAIEBBIDMAIKCgwKBQQAAgQGEgMwCxQKDAoFBAACBAESAzAVHwoMCgUEAAIEAxIDMCIjCgwK
BQQAAgQIEgMwJEwKDwoIBAACBAicCAASAzAlSwo1CgQEAAIFEgMzAkkaKCBPcHRpb25hbC4g
TGlzdCBvZiB0b29sc2V0cyBpbiB0aGUgYXBwLgoKDAoFBAACBQQSAzMCCgoMCgUEAAIFBhID
MwsSCgwKBQQAAgUBEgMzExsKDAoFBAACBQMSAzMeHwoMCgUEAAIFCBIDMyBICg8KCAQAAgUI
nAgAEgMzIUcKrgEKAgQBEgQ5AFoBGqEBIEluIEN1c3RvbWVyIEVuZ2FnZW1lbnQgU3VpdGUg
KENFUyksIGFuIGFwcCB2ZXJzaW9uIGlzIGEgc25hcHNob3Qgb2YgdGhlIGFwcAogYXQgYSBz
cGVjaWZpYyBwb2ludCBpbiB0aW1lLiBJdCBpcyBpbW11dGFibGUgYW5kIGNhbm5vdCBiZSBt
b2RpZmllZCBvbmNlCiBjcmVhdGVkLgoKCgoDBAEBEgM5CBIKCwoDBAEHEgQ6Aj8ECg0KBQQB
B50IEgQ6Aj8ECpcBCgQEAQIAEgNEAj0aiQEgSWRlbnRpZmllci4gVGhlIHVuaXF1ZSBpZGVu
dGlmaWVyIG9mIHRoZSBhcHAgdmVyc2lvbi4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVj
dH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXBwcy97YXBwfS92ZXJzaW9ucy97dmVyc2lvbn1g
CgoMCgUEAQIABRIDRAIICgwKBQQBAgABEgNECQ0KDAoFBAECAAMSA0QQEQoMCgUEAQIACBID
RBI8Cg8KCAQBAgAInAgAEgNEEzsKPQoEBAECARIDRwJDGjAgT3B0aW9uYWwuIFRoZSBkaXNw
bGF5IG5hbWUgb2YgdGhlIGFwcCB2ZXJzaW9uLgoKDAoFBAECAQUSA0cCCAoMCgUEAQIBARID
RwkVCgwKBQQBAgEDEgNHGBkKDAoFBAECAQgSA0caQgoPCggEAQIBCJwIABIDRxtBCjwKBAQB
AgISA0oCQhovIE9wdGlvbmFsLiBUaGUgZGVzY3JpcHRpb24gb2YgdGhlIGFwcCB2ZXJzaW9u
LgoKDAoFBAECAgUSA0oCCAoMCgUEAQICARIDSgkUCgwKBQQBAgIDEgNKFxgKDAoFBAECAggS
A0oZQQoPCggEAQICCJwIABIDShpACkoKBAQBAgMSA00CQRo9IE91dHB1dCBvbmx5LiBFbWFp
bCBvZiB0aGUgdXNlciB3aG8gY3JlYXRlZCB0aGUgYXBwIHZlcnNpb24uCgoMCgUEAQIDBRID
TQIICgwKBQQBAgMBEgNNCRAKDAoFBAECAwMSA00TFAoMCgUEAQIDCBIDTRVACg8KCAQBAgMI
nAgAEgNNFj8KSAoEBAECBBIEUAJRMho6IE91dHB1dCBvbmx5LiBUaW1lc3RhbXAgd2hlbiB0
aGUgYXBwIHZlcnNpb24gd2FzIGNyZWF0ZWQuCgoMCgUEAQIEBhIDUAIbCgwKBQQBAgQBEgNQ
HCcKDAoFBAECBAMSA1AqKwoMCgUEAQIECBIDUQYxCg8KCAQBAgQInAgAEgNRBzAKUAoEBAEC
BRIDVAJHGkMgT3V0cHV0IG9ubHkuIFRoZSBzbmFwc2hvdCBvZiB0aGUgYXBwIHdoZW4gdGhl
IHZlcnNpb24gaXMgY3JlYXRlZC4KCgwKBQQBAgUGEgNUAg0KDAoFBAECBQESA1QOFgoMCgUE
AQIFAxIDVBkaCgwKBQQBAgUIEgNUG0YKDwoIBAECBQicCAASA1QcRQq6AQoEBAECBhIDWQI+
GqwBIE91dHB1dCBvbmx5LiBFdGFnIHVzZWQgdG8gZW5zdXJlIHRoZSBvYmplY3QgaGFzbid0
IGNoYW5nZWQgZHVyaW5nIGEKIHJlYWQtbW9kaWZ5LXdyaXRlIG9wZXJhdGlvbi4gSWYgdGhl
IGV0YWcgaXMgZW1wdHksIHRoZSB1cGRhdGUgd2lsbAogb3ZlcndyaXRlIGFueSBjb25jdXJy
ZW50IGNoYW5nZXMuCgoMCgUEAQIGBRIDWQIICgwKBQQBAgYBEgNZCQ0KDAoFBAECBgMSA1kQ
EQoMCgUEAQIGCBIDWRI9Cg8KCAQBAgYInAgAEgNZEzxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::AppVersion::AppSnapshot ===
    # Fields for AppSnapshot
    # Field: app Type: 11 (.google.cloud.ces.v1.App)
    # Field: agents Type: 11 (.google.cloud.ces.v1.Agent)
    # Field: tools Type: 11 (.google.cloud.ces.v1.Tool)
    # Field: examples Type: 11 (.google.cloud.ces.v1.Example)
    # Field: guardrails Type: 11 (.google.cloud.ces.v1.Guardrail)
    # Field: toolsets Type: 11 (.google.cloud.ces.v1.Toolset)

# === Message: Google::Cloud::Ces::V1::AppVersion::AppVersion ===
    # Fields for AppVersion
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: creator Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: snapshot Type: 11 (.google.cloud.ces.v1.AppSnapshot)
    # Field: etag Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::AppVersion - Compiled Protocol Buffers messages for google/cloud/ces/v1/app_version.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::AppVersion;

    my $msg = Google::Cloud::Ces::V1::AppVersion::AppSnapshot->new({
        app => $app,
        agents => $agents,
        tools => $tools,
        examples => $examples,
    });

    # Read or update a field
    my $val = $msg->app();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::AppVersion::AppSnapshot->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/app_version.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::AppVersion::AppSnapshot

A snapshot of the app.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->app() >> / C<< $msg->app($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::App::App>)

Optional. The basic settings for the app.

=item * C<< $msg->agents() >> / C<< $msg->agents($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Agent::Agent>)

Optional. List of agents in the app.

=item * C<< $msg->tools() >> / C<< $msg->tools($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Tool::Tool>)

Optional. List of tools in the app.

=item * C<< $msg->examples() >> / C<< $msg->examples($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Example::Example>)

Optional. List of examples in the app.

=item * C<< $msg->guardrails() >> / C<< $msg->guardrails($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Guardrail::Guardrail>)

Optional. List of guardrails in the app.

=item * C<< $msg->toolsets() >> / C<< $msg->toolsets($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Toolset::Toolset>)

Optional. List of toolsets in the app.

=back

=head2 Google::Cloud::Ces::V1::AppVersion::AppVersion

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

=item * C<< $msg->snapshot() >> / C<< $msg->snapshot($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::AppVersion::AppSnapshot>)

Output only. The snapshot of the app when the version is created.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. Etag used to ensure the object hasn't changed during a
read-modify-write operation. If the etag is empty, the update will
overwrite any concurrent changes.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::AppVersion::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
