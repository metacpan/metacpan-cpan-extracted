package Google::Appengine::V1::Service;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Appengine::V1::NetworkSettings };
    my $descriptor_b64 = <<'EOF';
CiFnb29nbGUvYXBwZW5naW5lL3YxL3NlcnZpY2UucHJvdG8SE2dvb2dsZS5hcHBlbmdpbmUu
djEaKmdvb2dsZS9hcHBlbmdpbmUvdjEvbmV0d29ya19zZXR0aW5ncy5wcm90byK0AgoHU2Vy
dmljZRISCgRuYW1lGAEgASgJUgRuYW1lEg4KAmlkGAIgASgJUgJpZBI3CgVzcGxpdBgDIAEo
CzIhLmdvb2dsZS5hcHBlbmdpbmUudjEuVHJhZmZpY1NwbGl0UgVzcGxpdBJACgZsYWJlbHMY
BCADKAsyKC5nb29nbGUuYXBwZW5naW5lLnYxLlNlcnZpY2UuTGFiZWxzRW50cnlSBmxhYmVs
cxJPChBuZXR3b3JrX3NldHRpbmdzGAYgASgLMiQuZ29vZ2xlLmFwcGVuZ2luZS52MS5OZXR3
b3JrU2V0dGluZ3NSD25ldHdvcmtTZXR0aW5ncxo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASAB
KAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIqYCCgxUcmFmZmljU3BsaXQSRAoI
c2hhcmRfYnkYASABKA4yKS5nb29nbGUuYXBwZW5naW5lLnYxLlRyYWZmaWNTcGxpdC5TaGFy
ZEJ5UgdzaGFyZEJ5ElQKC2FsbG9jYXRpb25zGAIgAygLMjIuZ29vZ2xlLmFwcGVuZ2luZS52
MS5UcmFmZmljU3BsaXQuQWxsb2NhdGlvbnNFbnRyeVILYWxsb2NhdGlvbnMaPgoQQWxsb2Nh
dGlvbnNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoAVIFdmFsdWU6AjgB
IjoKB1NoYXJkQnkSDwoLVU5TUEVDSUZJRUQQABIKCgZDT09LSUUQARIGCgJJUBACEgoKBlJB
TkRPTRADQr0BChdjb20uZ29vZ2xlLmFwcGVuZ2luZS52MUIMU2VydmljZVByb3RvUAFaO2Ns
b3VkLmdvb2dsZS5jb20vZ28vYXBwZW5naW5lL2FwaXYxL2FwcGVuZ2luZXBiO2FwcGVuZ2lu
ZXBiqgIZR29vZ2xlLkNsb3VkLkFwcEVuZ2luZS5WMcoCGUdvb2dsZVxDbG91ZFxBcHBFbmdp
bmVcVjHqAhxHb29nbGU6OkNsb3VkOjpBcHBFbmdpbmU6OlYxSqohCgYSBA4AaQEKvAQKAQwS
Aw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhl
IEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5
IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vu
c2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0
cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVp
cmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2Fy
ZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4g
IkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFO
WSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZv
ciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGlt
aXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABwKCQoCAwASAxIANAoICgEI
EgMUADYKCQoCCCUSAxQANgoICgEIEgMVAFIKCQoCCAsSAxUAUgoICgEIEgMWACIKCQoCCAoS
AxYAIgoICgEIEgMXAC0KCQoCCAgSAxcALQoICgEIEgMYADAKCQoCCAESAxgAMAoICgEIEgMZ
ADYKCQoCCCkSAxkANgoICgEIEgMaADUKCQoCCC0SAxoANQrOAwoCBAASBCMAQwEawQMgQSBT
ZXJ2aWNlIHJlc291cmNlIGlzIGEgbG9naWNhbCBjb21wb25lbnQgb2YgYW4gYXBwbGljYXRp
b24gdGhhdCBjYW4gc2hhcmUKIHN0YXRlIGFuZCBjb21tdW5pY2F0ZSBpbiBhIHNlY3VyZSBm
YXNoaW9uIHdpdGggb3RoZXIgc2VydmljZXMuCiBGb3IgZXhhbXBsZSwgYW4gYXBwbGljYXRp
b24gdGhhdCBoYW5kbGVzIGN1c3RvbWVyIHJlcXVlc3RzIG1pZ2h0CiBpbmNsdWRlIHNlcGFy
YXRlIHNlcnZpY2VzIHRvIGhhbmRsZSB0YXNrcyBzdWNoIGFzIGJhY2tlbmQgZGF0YQogYW5h
bHlzaXMgb3IgQVBJIHJlcXVlc3RzIGZyb20gbW9iaWxlIGRldmljZXMuIEVhY2ggc2Vydmlj
ZSBoYXMgYQogY29sbGVjdGlvbiBvZiB2ZXJzaW9ucyB0aGF0IGRlZmluZSBhIHNwZWNpZmlj
IHNldCBvZiBjb2RlIHVzZWQgdG8KIGltcGxlbWVudCB0aGUgZnVuY3Rpb25hbGl0eSBvZiB0
aGF0IHNlcnZpY2UuCgoKCgMEAAESAyMIDwpzCgQEAAIAEgMoAhIaZiBGdWxsIHBhdGggdG8g
dGhlIFNlcnZpY2UgcmVzb3VyY2UgaW4gdGhlIEFQSS4KIEV4YW1wbGU6IGBhcHBzL215YXBw
L3NlcnZpY2VzL2RlZmF1bHRgLgoKIEBPdXRwdXRPbmx5CgoMCgUEAAIABRIDKAIICgwKBQQA
AgABEgMoCQ0KDAoFBAACAAMSAygQEQpmCgQEAAIBEgMuAhAaWSBSZWxhdGl2ZSBuYW1lIG9m
IHRoZSBzZXJ2aWNlIHdpdGhpbiB0aGUgYXBwbGljYXRpb24uCiBFeGFtcGxlOiBgZGVmYXVs
dGAuCgogQE91dHB1dE9ubHkKCgwKBQQAAgEFEgMuAggKDAoFBAACAQESAy4JCwoMCgUEAAIB
AxIDLg4PCnAKBAQAAgISAzICGRpjIE1hcHBpbmcgdGhhdCBkZWZpbmVzIGZyYWN0aW9uYWwg
SFRUUCB0cmFmZmljIGRpdmVyc2lvbiB0bwogZGlmZmVyZW50IHZlcnNpb25zIHdpdGhpbiB0
aGUgc2VydmljZS4KCgwKBQQAAgIGEgMyAg4KDAoFBAACAgESAzIPFAoMCgUEAAICAxIDMhcY
CtMFCgQEAAIDEgM/AiEaxQUgQSBzZXQgb2YgbGFiZWxzIHRvIGFwcGx5IHRvIHRoaXMgc2Vy
dmljZS4gTGFiZWxzIGFyZSBrZXkvdmFsdWUgcGFpcnMgdGhhdAogZGVzY3JpYmUgdGhlIHNl
cnZpY2UgYW5kIGFsbCByZXNvdXJjZXMgdGhhdCBiZWxvbmcgdG8gaXQgKGUuZy4sCiB2ZXJz
aW9ucykuIFRoZSBsYWJlbHMgY2FuIGJlIHVzZWQgdG8gc2VhcmNoIGFuZCBncm91cCByZXNv
dXJjZXMsIGFuZCBhcmUKIHByb3BhZ2F0ZWQgdG8gdGhlIHVzYWdlIGFuZCBiaWxsaW5nIHJl
cG9ydHMsIGVuYWJsaW5nIGZpbmUtZ3JhaW4gYW5hbHlzaXMKIG9mIGNvc3RzLiBBbiBleGFt
cGxlIG9mIHVzaW5nIGxhYmVscyBpcyB0byB0YWcgcmVzb3VyY2VzIGJlbG9uZ2luZyB0bwog
ZGlmZmVyZW50IGVudmlyb25tZW50cyAoZS5nLiwgImVudj1wcm9kIiwgImVudj1xYSIpLgoK
IDxwPkxhYmVsIGtleXMgYW5kIHZhbHVlcyBjYW4gYmUgbm8gbG9uZ2VyIHRoYW4gNjMgY2hh
cmFjdGVycyBhbmQgY2FuIG9ubHkKIGNvbnRhaW4gbG93ZXJjYXNlIGxldHRlcnMsIG51bWVy
aWMgY2hhcmFjdGVycywgdW5kZXJzY29yZXMsIGRhc2hlcywgYW5kCiBpbnRlcm5hdGlvbmFs
IGNoYXJhY3RlcnMuIExhYmVsIGtleXMgbXVzdCBzdGFydCB3aXRoIGEgbG93ZXJjYXNlIGxl
dHRlcgogb3IgYW4gaW50ZXJuYXRpb25hbCBjaGFyYWN0ZXIuIEVhY2ggc2VydmljZSBjYW4g
aGF2ZSBhdCBtb3N0IDMyIGxhYmVscy4KCgwKBQQAAgMGEgM/AhUKDAoFBAACAwESAz8WHAoM
CgUEAAIDAxIDPx8gCk0KBAQAAgQSA0ICJxpAIEluZ3Jlc3Mgc2V0dGluZ3MgZm9yIHRoaXMg
c2VydmljZS4gV2lsbCBhcHBseSB0byBhbGwgdmVyc2lvbnMuCgoMCgUEAAIEBhIDQgIRCgwK
BQQAAgQBEgNCEiIKDAoFBAACBAMSA0IlJgqmAQoCBAESBEcAaQEamQEgVHJhZmZpYyByb3V0
aW5nIGNvbmZpZ3VyYXRpb24gZm9yIHZlcnNpb25zIHdpdGhpbiBhIHNpbmdsZSBzZXJ2aWNl
LiBUcmFmZmljCiBzcGxpdHMgZGVmaW5lIGhvdyB0cmFmZmljIGRpcmVjdGVkIHRvIHRoZSBz
ZXJ2aWNlIGlzIGFzc2lnbmVkIHRvIHZlcnNpb25zLgoKCgoDBAEBEgNHCBQKLgoEBAEEABIE
SQJZAxogIEF2YWlsYWJsZSBzaGFyZGluZyBtZWNoYW5pc21zLgoKDAoFBAEEAAESA0kHDgou
CgYEAQQAAgASA0sEFBofIERpdmVyc2lvbiBtZXRob2QgdW5zcGVjaWZpZWQuCgoOCgcEAQQA
AgABEgNLBA8KDgoHBAEEAAIAAhIDSxITCpoBCgYEAQQAAgESA08EDxqKASBEaXZlcnNpb24g
YmFzZWQgb24gYSBzcGVjaWFsbHkgbmFtZWQgY29va2llLCAiR09PR0FQUFVJRC4iIFRoZSBj
b29raWUKIG11c3QgYmUgc2V0IGJ5IHRoZSBhcHBsaWNhdGlvbiBpdHNlbGYgb3Igbm8gZGl2
ZXJzaW9uIHdpbGwgb2NjdXIuCgoOCgcEAQQAAgEBEgNPBAoKDgoHBAEEAAIBAhIDTw0OCmcK
BgQBBAACAhIDUwQLGlggRGl2ZXJzaW9uIGJhc2VkIG9uIGFwcGx5aW5nIHRoZSBtb2R1bHVz
IG9wZXJhdGlvbiB0byBhIGZpbmdlcnByaW50CiBvZiB0aGUgSVAgYWRkcmVzcy4KCg4KBwQB
BAACAgESA1MEBgoOCgcEAQQAAgICEgNTCQoKygEKBgQBBAACAxIDWAQPGroBIERpdmVyc2lv
biBiYXNlZCBvbiB3ZWlnaHRlZCByYW5kb20gYXNzaWdubWVudC4gQW4gaW5jb21pbmcgcmVx
dWVzdCBpcwogcmFuZG9tbHkgcm91dGVkIHRvIGEgdmVyc2lvbiBpbiB0aGUgdHJhZmZpYyBz
cGxpdCwgd2l0aCBwcm9iYWJpbGl0eQogcHJvcG9ydGlvbmFsIHRvIHRoZSB2ZXJzaW9uJ3Mg
dHJhZmZpYyBzaGFyZS4KCg4KBwQBBAACAwESA1gECgoOCgcEAQQAAgMCEgNYDQ4KrwEKBAQB
AgASA14CFxqhASBNZWNoYW5pc20gdXNlZCB0byBkZXRlcm1pbmUgd2hpY2ggdmVyc2lvbiBh
IHJlcXVlc3QgaXMgc2VudCB0by4KIFRoZSB0cmFmZmljIHNlbGVjdGlvbiBhbGdvcml0aG0g
d2lsbAogYmUgc3RhYmxlIGZvciBlaXRoZXIgdHlwZSB1bnRpbCBhbGxvY2F0aW9ucyBhcmUg
Y2hhbmdlZC4KCgwKBQQBAgAGEgNeAgkKDAoFBAECAAESA14KEgoMCgUEAQIAAxIDXhUWCpkE
CgQEAQIBEgNoAiYaiwQgTWFwcGluZyBmcm9tIHZlcnNpb24gSURzIHdpdGhpbiB0aGUgc2Vy
dmljZSB0byBmcmFjdGlvbmFsCiAoMC4wMDAsIDFdIGFsbG9jYXRpb25zIG9mIHRyYWZmaWMg
Zm9yIHRoYXQgdmVyc2lvbi4gRWFjaCB2ZXJzaW9uIGNhbgogYmUgc3BlY2lmaWVkIG9ubHkg
b25jZSwgYnV0IHNvbWUgdmVyc2lvbnMgaW4gdGhlIHNlcnZpY2UgbWF5IG5vdAogaGF2ZSBh
bnkgdHJhZmZpYyBhbGxvY2F0aW9uLiBTZXJ2aWNlcyB0aGF0IGhhdmUgdHJhZmZpYyBhbGxv
Y2F0ZWQKIGNhbm5vdCBiZSBkZWxldGVkIHVudGlsIGVpdGhlciB0aGUgc2VydmljZSBpcyBk
ZWxldGVkIG9yCiB0aGVpciB0cmFmZmljIGFsbG9jYXRpb24gaXMgcmVtb3ZlZC4gQWxsb2Nh
dGlvbnMgbXVzdCBzdW0gdG8gMS4KIFVwIHRvIHR3byBkZWNpbWFsIHBsYWNlIHByZWNpc2lv
biBpcyBzdXBwb3J0ZWQgZm9yIElQLWJhc2VkIHNwbGl0cyBhbmQKIHVwIHRvIHRocmVlIGRl
Y2ltYWwgcGxhY2VzIGlzIHN1cHBvcnRlZCBmb3IgY29va2llLWJhc2VkIHNwbGl0cy4KCgwK
BQQBAgEGEgNoAhUKDAoFBAECAQESA2gWIQoMCgUEAQIBAxIDaCQlYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1::Service::Service ===
    # Fields for Service
    # Field: name Type: 9 ()
    # Field: id Type: 9 ()
    # Field: split Type: 11 (.google.appengine.v1.TrafficSplit)
    # Field: labels Type: 11 (.google.appengine.v1.Service.LabelsEntry)
    # Field: network_settings Type: 11 (.google.appengine.v1.NetworkSettings)

# === Message: Google::Appengine::V1::Service::TrafficSplit ===
    # Fields for TrafficSplit
    # Field: shard_by Type: 14 (.google.appengine.v1.TrafficSplit.ShardBy)
    # Field: allocations Type: 11 (.google.appengine.v1.TrafficSplit.AllocationsEntry)

# Enum: TrafficSplit::ShardBy
our $TrafficSplit_UNSPECIFIED = 0;
our $TrafficSplit_COOKIE = 1;
our $TrafficSplit_IP = 2;
our $TrafficSplit_RANDOM = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1::Service - Compiled Protocol Buffers messages for google/appengine/v1/service.proto

=head1 SYNOPSIS

    use Google::Appengine::V1::Service;

    my $msg = Google::Appengine::V1::Service::Service->new({
        name => $name,
        id => $id,
        split => $split,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1::Service::Service->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1::Service::Service

A Service resource is a logical component of an application that can share
state and communicate in a secure fashion with other services.
For example, an application that handles customer requests might
include separate services to handle tasks such as backend data
analysis or API requests from mobile devices. Each service has a
collection of versions that define a specific set of code used to
implement the functionality of that service.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Full path to the Service resource in the API.
Example: `apps/myapp/services/default`.

@OutputOnly

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Relative name of the service within the application.
Example: `default`.

@OutputOnly

=item * C<< $msg->split() >> / C<< $msg->split($value) >>

Type: C<Message> (L<Google::Appengine::V1::Service::TrafficSplit>)

Mapping that defines fractional HTTP traffic diversion to
different versions within the service.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Appengine::V1::Service::Service::LabelsEntry>)

A set of labels to apply to this service. Labels are key/value pairs that
describe the service and all resources that belong to it (e.g.,
versions). The labels can be used to search and group resources, and are
propagated to the usage and billing reports, enabling fine-grain analysis
of costs. An example of using labels is to tag resources belonging to
different environments (e.g., "env=prod", "env=qa").

<p>Label keys and values can be no longer than 63 characters and can only
contain lowercase letters, numeric characters, underscores, dashes, and
international characters. Label keys must start with a lowercase letter
or an international character. Each service can have at most 32 labels.

=item * C<< $msg->network_settings() >> / C<< $msg->network_settings($value) >>

Type: C<Message> (L<Google::Appengine::V1::NetworkSettings::NetworkSettings>)

Ingress settings for this service. Will apply to all versions.

=back

=head2 Google::Appengine::V1::Service::TrafficSplit

Traffic routing configuration for versions within a single service. Traffic
splits define how traffic directed to the service is assigned to versions.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->shard_by() >> / C<< $msg->shard_by($value) >>

Type: C<Enum> (L<Google::Appengine::V1::TrafficSplit::ShardBy>)

Mechanism used to determine which version a request is sent to.
The traffic selection algorithm will
be stable for either type until allocations are changed.

=item * C<< $msg->allocations() >> / C<< $msg->allocations($value) >>

Type: C<Message> (L<Google::Appengine::V1::Service::TrafficSplit::AllocationsEntry>)

Mapping from version IDs within the service to fractional
(0.000, 1] allocations of traffic for that version. Each version can
be specified only once, but some versions in the service may not
have any traffic allocation. Services that have traffic allocated
cannot be deleted until either the service is deleted or
their traffic allocation is removed. Allocations must sum to 1.
Up to two decimal place precision is supported for IP-based splits and
up to three decimal places is supported for cookie-based splits.

=back

=head3 Enum: TrafficSplit::ShardBy

=over 4

=item * C<UNSPECIFIED> => C<0>

=item * C<COOKIE> => C<1>

=item * C<IP> => C<2>

=item * C<RANDOM> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
