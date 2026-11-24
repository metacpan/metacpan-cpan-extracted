package Google::Cloud::Connectors::V1::Runtime;

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
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvY29ubmVjdG9ycy92MS9ydW50aW1lLnByb3RvEhpnb29nbGUuY2xv
dWQuY29ubmVjdG9ycy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29v
Z2xlL2FwaS9yZXNvdXJjZS5wcm90byJeChdHZXRSdW50aW1lQ29uZmlnUmVxdWVzdBJDCgRu
YW1lGAEgASgJQi/gQQL6QSkKJ2Nvbm5lY3RvcnMuZ29vZ2xlYXBpcy5jb20vUnVudGltZUNv
bmZpZ1IEbmFtZSLgBQoNUnVudGltZUNvbmZpZxIkCgtsb2NhdGlvbl9pZBgBIAEoCUID4EED
Ugpsb2NhdGlvbklkEiQKC2Nvbm5kX3RvcGljGAIgASgJQgPgQQNSCmNvbm5kVG9waWMSMgoS
Y29ubmRfc3Vic2NyaXB0aW9uGAMgASgJQgPgQQNSEWNvbm5kU3Vic2NyaXB0aW9uEjMKE2Nv
bnRyb2xfcGxhbmVfdG9waWMYBCABKAlCA+BBA1IRY29udHJvbFBsYW5lVG9waWMSQQoaY29u
dHJvbF9wbGFuZV9zdWJzY3JpcHRpb24YBSABKAlCA+BBA1IYY29udHJvbFBsYW5lU3Vic2Ny
aXB0aW9uEi4KEHJ1bnRpbWVfZW5kcG9pbnQYBiABKAlCA+BBA1IPcnVudGltZUVuZHBvaW50
EkoKBXN0YXRlGAcgASgOMi8uZ29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMudjEuUnVudGltZUNv
bmZpZy5TdGF0ZUID4EEDUgVzdGF0ZRIvChFzY2hlbWFfZ2NzX2J1Y2tldBgIIAEoCUID4EED
Ug9zY2hlbWFHY3NCdWNrZXQSMAoRc2VydmljZV9kaXJlY3RvcnkYCSABKAlCA+BBA1IQc2Vy
dmljZURpcmVjdG9yeRIXCgRuYW1lGAsgASgJQgPgQQNSBG5hbWUiegoFU3RhdGUSFQoRU1RB
VEVfVU5TUEVDSUZJRUQQABIQCghJTkFDVElWRRABGgIIARISCgpBQ1RJVkFUSU5HEAIaAggB
EgoKBkFDVElWRRADEgwKCENSRUFUSU5HEAQSDAoIREVMRVRJTkcQBRIMCghVUERBVElORxAG
OmPqQWAKJ2Nvbm5lY3RvcnMuZ29vZ2xlYXBpcy5jb20vUnVudGltZUNvbmZpZxI1cHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3J1bnRpbWVDb25maWdCcAoeY29t
Lmdvb2dsZS5jbG91ZC5jb25uZWN0b3JzLnYxQgxSdW50aW1lUHJvdG9QAVo+Y2xvdWQuZ29v
Z2xlLmNvbS9nby9jb25uZWN0b3JzL2FwaXYxL2Nvbm5lY3RvcnNwYjtjb25uZWN0b3JzcGJK
+hsKBhIEDgBtAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
IwoJCgIDABIDEgApCgkKAgMBEgMTACMKCAoBCBIDFQBVCgkKAggLEgMVAFUKCAoBCBIDFgAi
CgkKAggKEgMWACIKCAoBCBIDFwAtCgkKAggIEgMXAC0KCAoBCBIDGAA3CgkKAggBEgMYADcK
PgoCBAASBBsAJAEaMiBSZXF1ZXN0IG1lc3NhZ2UgZm9yIENvbm5lY3RvcnMuR2V0UnVudGlt
ZUNvbmZpZy4KCgoKAwQAARIDGwgfClwKBAQAAgASBB4CIwQaTiBSZXF1aXJlZC4gUmVzb3Vy
Y2UgbmFtZSBvZiB0aGUgZm9ybToKIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy8qL3J1bnRpbWVD
b25maWdgCgoMCgUEAAIABRIDHgIICgwKBQQAAgABEgMeCQ0KDAoFBAACAAMSAx4QEQoNCgUE
AAIACBIEHhIjAwoPCggEAAIACJwIABIDHwQqCg8KBwQAAgAInwgSBCAEIgUK9wEKAgQBEgQq
AG0BGuoBIFJ1bnRpbWVDb25maWcgaXMgdGhlIHNpbmdsZXRvbiByZXNvdXJjZSBvZiBlYWNo
IGxvY2F0aW9uLgogSXQgaW5jbHVkZXMgZ2VuZXJpYyByZXNvdXJjZSBjb25maWdzIGNvbnN1
bWVkIGJ5IGNvbnRyb2wgcGxhbmUgYW5kIHJ1bnRpbWUKIHBsYW5lIGxpa2U6IHB1Yi9zdWIg
dG9waWMvc3Vic2NyaXB0aW9uIHJlc291cmNlIG5hbWUsIENsb3VkIFN0b3JhZ2UgbG9jYXRp
b24KIHN0b3Jpbmcgc2NoZW1hIGV0Yy4KCgoKAwQBARIDKggVCgsKAwQBBxIEKwIuBAoNCgUE
AQedCBIEKwIuBAomCgQEAQQAEgQxAkYDGhggU3RhdGUgb2YgdGhlIGxvY2F0aW9uLgoKDAoF
BAEEAAESAzEHDAojCgYEAQQAAgASAzMEGhoUIFNUQVRFX1VOU1BFQ0lGSUVELgoKDgoHBAEE
AAIAARIDMwQVCg4KBwQBBAACAAISAzMYGQoaCgYEAQQAAgESAzYEJRoLIElOQUNUSVZFLgoK
DgoHBAEEAAIBARIDNgQMCg4KBwQBBAACAQISAzYPEAoOCgcEAQQAAgEDEgM2ESQKDwoIBAEE
AAIBAwESAzYSIwocCgYEAQQAAgISAzkEJxoNIEFDVElWQVRJTkcuCgoOCgcEAQQAAgIBEgM5
BA4KDgoHBAEEAAICAhIDORESCg4KBwQBBAACAgMSAzkTJgoPCggEAQQAAgIDARIDORQlChgK
BgQBBAACAxIDPAQPGgkgQUNUSVZFLgoKDgoHBAEEAAIDARIDPAQKCg4KBwQBBAACAwISAzwN
DgoaCgYEAQQAAgQSAz8EERoLIENSRUFUSU5HLgoKDgoHBAEEAAIEARIDPwQMCg4KBwQBBAAC
BAISAz8PEAoaCgYEAQQAAgUSA0IEERoLIERFTEVUSU5HLgoKDgoHBAEEAAIFARIDQgQMCg4K
BwQBBAACBQISA0IPEAoaCgYEAQQAAgYSA0UEERoLIFVQREFUSU5HLgoKDgoHBAEEAAIGARID
RQQMCg4KBwQBBAACBgISA0UPEApRCgQEAQIAEgNJAkUaRCBPdXRwdXQgb25seS4gbG9jYXRp
b25faWQgb2YgdGhlIHJ1bnRpbWUgbG9jYXRpb24uIEUuZy4gInVzLXdlc3QxIi4KCgwKBQQB
AgAFEgNJAggKDAoFBAECAAESA0kJFAoMCgUEAQIAAxIDSRcYCgwKBQQBAgAIEgNJGUQKDwoI
BAECAAicCAASA0kaQwpyCgQEAQIBEgNNAkUaZSBPdXRwdXQgb25seS4gUHViL1N1YiB0b3Bp
YyBmb3IgY29ubmQgdG8gc2VuZCBtZXNzYWdlLgogRS5nLiBwcm9qZWN0cy97cHJvamVjdC1p
ZH0vdG9waWNzL3t0b3BpYy1pZH0KCgwKBQQBAgEFEgNNAggKDAoFBAECAQESA00JFAoMCgUE
AQIBAxIDTRcYCgwKBQQBAgEIEgNNGUQKDwoIBAECAQicCAASA00aQwqDAQoEBAECAhIDUQJM
GnYgT3V0cHV0IG9ubHkuIFB1Yi9TdWIgc3Vic2NyaXB0aW9uIGZvciBjb25uZCB0byByZWNl
aXZlIG1lc3NhZ2UuCiBFLmcuIHByb2plY3RzL3twcm9qZWN0LWlkfS9zdWJzY3JpcHRpb25z
L3t0b3BpYy1pZH0KCgwKBQQBAgIFEgNRAggKDAoFBAECAgESA1EJGwoMCgUEAQICAxIDUR4f
CgwKBQQBAgIIEgNRIEsKDwoIBAECAgicCAASA1EhSgqJAQoEBAECAxIDVgJNGnwgT3V0cHV0
IG9ubHkuIFB1Yi9TdWIgdG9waWMgZm9yIGNvbnRyb2wgcGxuZSB0byBzZW5kIG1lc3NhZ2Uu
CiBjb21tdW5pY2F0aW9uLgogRS5nLiBwcm9qZWN0cy97cHJvamVjdC1pZH0vdG9waWNzL3t0
b3BpYy1pZH0KCgwKBQQBAgMFEgNWAggKDAoFBAECAwESA1YJHAoMCgUEAQIDAxIDVh8gCgwK
BQQBAgMIEgNWIUwKDwoIBAECAwicCAASA1YiSwqMAQoEBAECBBIEWgJbMhp+IE91dHB1dCBv
bmx5LiBQdWIvU3ViIHN1YnNjcmlwdGlvbiBmb3IgY29udHJvbCBwbGFuZSB0byByZWNlaXZl
IG1lc3NhZ2UuCiBFLmcuIHByb2plY3RzL3twcm9qZWN0LWlkfS9zdWJzY3JpcHRpb25zL3t0
b3BpYy1pZH0KCgwKBQQBAgQFEgNaAggKDAoFBAECBAESA1oJIwoMCgUEAQIEAxIDWiYnCgwK
BQQBAgQIEgNbBjEKDwoIBAECBAicCAASA1sHMApLCgQEAQIFEgNeAkoaPiBPdXRwdXQgb25s
eS4gVGhlIGVuZHBvaW50IG9mIHRoZSBjb25uZWN0b3JzIHJ1bnRpbWUgaW5ncmVzcy4KCgwK
BQQBAgUFEgNeAggKDAoFBAECBQESA14JGQoMCgUEAQIFAxIDXhwdCgwKBQQBAgUIEgNeHkkK
DwoIBAECBQicCAASA14fSAo2CgQEAQIGEgNhAj4aKSBPdXRwdXQgb25seS4gVGhlIHN0YXRl
IG9mIHRoZSBsb2NhdGlvbi4KCgwKBQQBAgYGEgNhAgcKDAoFBAECBgESA2EIDQoMCgUEAQIG
AxIDYRARCgwKBQQBAgYIEgNhEj0KDwoIBAECBgicCAASA2ETPApdCgQEAQIHEgNlAksaUCBP
dXRwdXQgb25seS4gVGhlIENsb3VkIFN0b3JhZ2UgYnVja2V0IHRoYXQgc3RvcmVzIGNvbm5l
Y3RvcidzIHNjaGVtYQogcmVwb3J0cy4KCgwKBQQBAgcFEgNlAggKDAoFBAECBwESA2UJGgoM
CgUEAQIHAxIDZR0eCgwKBQQBAgcIEgNlH0oKDwoIBAECBwicCAASA2UgSQpLCgQEAQIIEgNo
AksaPiBPdXRwdXQgb25seS4gVGhlIG5hbWUgb2YgdGhlIFNlcnZpY2UgRGlyZWN0b3J5IHNl
cnZpY2UgbmFtZS4KCgwKBQQBAggFEgNoAggKDAoFBAECCAESA2gJGgoMCgUEAQIIAxIDaB0e
CgwKBQQBAggIEgNoH0oKDwoIBAECCAicCAASA2ggSQp+CgQEAQIJEgNsAj8acSBPdXRwdXQg
b25seS4gTmFtZSBvZiB0aGUgcnVudGltZUNvbmZpZyByZXNvdXJjZS4KIEZvcm1hdDogcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3J1bnRpbWVDb25maWcKCgwK
BQQBAgkFEgNsAggKDAoFBAECCQESA2wJDQoMCgUEAQIJAxIDbBASCgwKBQQBAgkIEgNsEz4K
DwoIBAECCQicCAASA2wUPWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Connectors::V1::Runtime::GetRuntimeConfigRequest ===
    # Fields for GetRuntimeConfigRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Connectors::V1::Runtime::RuntimeConfig ===
    # Fields for RuntimeConfig
    # Field: location_id Type: 9 ()
    # Field: connd_topic Type: 9 ()
    # Field: connd_subscription Type: 9 ()
    # Field: control_plane_topic Type: 9 ()
    # Field: control_plane_subscription Type: 9 ()
    # Field: runtime_endpoint Type: 9 ()
    # Field: state Type: 14 (.google.cloud.connectors.v1.RuntimeConfig.State)
    # Field: schema_gcs_bucket Type: 9 ()
    # Field: service_directory Type: 9 ()
    # Field: name Type: 9 ()

# Enum: RuntimeConfig::State
our $RuntimeConfig_STATE_UNSPECIFIED = 0;
our $RuntimeConfig_INACTIVE = 1;
our $RuntimeConfig_ACTIVATING = 2;
our $RuntimeConfig_ACTIVE = 3;
our $RuntimeConfig_CREATING = 4;
our $RuntimeConfig_DELETING = 5;
our $RuntimeConfig_UPDATING = 6;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Connectors::V1::Runtime - Compiled Protocol Buffers messages for google/cloud/connectors/v1/runtime.proto

=head1 SYNOPSIS

    use Google::Cloud::Connectors::V1::Runtime;

    my $msg = Google::Cloud::Connectors::V1::Runtime::GetRuntimeConfigRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Connectors::V1::Runtime::GetRuntimeConfigRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/connectors/v1/runtime.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Connectors::V1::Runtime::GetRuntimeConfigRequest

Request message for Connectors.GetRuntimeConfig.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Resource name of the form:
`projects/*/locations/*/runtimeConfig`

=back

=head2 Google::Cloud::Connectors::V1::Runtime::RuntimeConfig

RuntimeConfig is the singleton resource of each location.
It includes generic resource configs consumed by control plane and runtime
plane like: pub/sub topic/subscription resource name, Cloud Storage location
storing schema etc.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->location_id() >> / C<< $msg->location_id($value) >>

Type: C<String>

Output only. location_id of the runtime location. E.g. "us-west1".

=item * C<< $msg->connd_topic() >> / C<< $msg->connd_topic($value) >>

Type: C<String>

Output only. Pub/Sub topic for connd to send message.
E.g. projects/{project-id}/topics/{topic-id}

=item * C<< $msg->connd_subscription() >> / C<< $msg->connd_subscription($value) >>

Type: C<String>

Output only. Pub/Sub subscription for connd to receive message.
E.g. projects/{project-id}/subscriptions/{topic-id}

=item * C<< $msg->control_plane_topic() >> / C<< $msg->control_plane_topic($value) >>

Type: C<String>

Output only. Pub/Sub topic for control plne to send message.
communication.
E.g. projects/{project-id}/topics/{topic-id}

=item * C<< $msg->control_plane_subscription() >> / C<< $msg->control_plane_subscription($value) >>

Type: C<String>

Output only. Pub/Sub subscription for control plane to receive message.
E.g. projects/{project-id}/subscriptions/{topic-id}

=item * C<< $msg->runtime_endpoint() >> / C<< $msg->runtime_endpoint($value) >>

Type: C<String>

Output only. The endpoint of the connectors runtime ingress.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Connectors::V1::RuntimeConfig::State>)

Output only. The state of the location.

=item * C<< $msg->schema_gcs_bucket() >> / C<< $msg->schema_gcs_bucket($value) >>

Type: C<String>

Output only. The Cloud Storage bucket that stores connector's schema
reports.

=item * C<< $msg->service_directory() >> / C<< $msg->service_directory($value) >>

Type: C<String>

Output only. The name of the Service Directory service name.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Name of the runtimeConfig resource.
Format: projects/{project}/locations/{location}/runtimeConfig

=back

=head3 Enum: RuntimeConfig::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<INACTIVE> => C<1>

=item * C<ACTIVATING> => C<2>

=item * C<ACTIVE> => C<3>

=item * C<CREATING> => C<4>

=item * C<DELETING> => C<5>

=item * C<UPDATING> => C<6>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Connectors::V1::Runtime::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
