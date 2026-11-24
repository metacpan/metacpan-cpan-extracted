package Google::Cloud::Securitycenter::V2::AttackExposure;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvYXR0YWNrX2V4cG9zdXJlLnByb3Rv
Eh5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIaH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iqwQKDkF0dGFj
a0V4cG9zdXJlEhQKBXNjb3JlGAEgASgBUgVzY29yZRJSChdsYXRlc3RfY2FsY3VsYXRpb25f
dGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSFWxhdGVzdENhbGN1bGF0
aW9uVGltZRI0ChZhdHRhY2tfZXhwb3N1cmVfcmVzdWx0GAMgASgJUhRhdHRhY2tFeHBvc3Vy
ZVJlc3VsdBJPCgVzdGF0ZRgEIAEoDjI0Lmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52
Mi5BdHRhY2tFeHBvc3VyZS5TdGF0ZUID4EEDUgVzdGF0ZRJKCiJleHBvc2VkX2hpZ2hfdmFs
dWVfcmVzb3VyY2VzX2NvdW50GAUgASgFUh5leHBvc2VkSGlnaFZhbHVlUmVzb3VyY2VzQ291
bnQSTgokZXhwb3NlZF9tZWRpdW1fdmFsdWVfcmVzb3VyY2VzX2NvdW50GAYgASgFUiBleHBv
c2VkTWVkaXVtVmFsdWVSZXNvdXJjZXNDb3VudBJICiFleHBvc2VkX2xvd192YWx1ZV9yZXNv
dXJjZXNfY291bnQYByABKAVSHWV4cG9zZWRMb3dWYWx1ZVJlc291cmNlc0NvdW50IkIKBVN0
YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVEEAASDgoKQ0FMQ1VMQVRFRBABEhIKDk5PVF9DQUxD
VUxBVEVEEAJC7QEKImNvbS5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjJCE0F0dGFj
a0V4cG9zdXJlUHJvdG9QAVpKY2xvdWQuZ29vZ2xlLmNvbS9nby9zZWN1cml0eWNlbnRlci9h
cGl2Mi9zZWN1cml0eWNlbnRlcnBiO3NlY3VyaXR5Y2VudGVycGKqAh5Hb29nbGUuQ2xvdWQu
U2VjdXJpdHlDZW50ZXIuVjLKAh5Hb29nbGVcQ2xvdWRcU2VjdXJpdHlDZW50ZXJcVjLqAiFH
b29nbGU6OkNsb3VkOjpTZWN1cml0eUNlbnRlcjo6VjJKqBMKBhIEDgBHAQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgApCgkKAgMBEgMT
ACkKCAoBCBIDFQA7CgkKAgglEgMVADsKCAoBCBIDFgBhCgkKAggLEgMWAGEKCAoBCBIDFwAi
CgkKAggKEgMXACIKCAoBCBIDGAA0CgkKAggIEgMYADQKCAoBCBIDGQA7CgkKAggBEgMZADsK
CAoBCBIDGgA7CgkKAggpEgMaADsKCAoBCBIDGwA6CgkKAggtEgMbADoKVwoCBAASBB4ARwEa
SyBBbiBhdHRhY2sgZXhwb3N1cmUgY29udGFpbnMgdGhlIHJlc3VsdHMgb2YgYW4gYXR0YWNr
IHBhdGggc2ltdWxhdGlvbiBydW4uCgoKCgMEAAESAx4IFgpRCgQEAAQAEgQgAikDGkMgVGhp
cyBlbnVtIGRlZmluZXMgdGhlIHZhcmlvdXMgc3RhdGVzIGFuIEF0dGFja0V4cG9zdXJlIGNh
biBiZSBpbi4KCgwKBQQABAABEgMgBwwKLAoGBAAEAAIAEgMiBBoaHSBUaGUgc3RhdGUgaXMg
bm90IHNwZWNpZmllZC4KCg4KBwQABAACAAESAyIEFQoOCgcEAAQAAgACEgMiGBkKOQoGBAAE
AAIBEgMlBBMaKiBUaGUgYXR0YWNrIGV4cG9zdXJlIGhhcyBiZWVuIGNhbGN1bGF0ZWQuCgoO
CgcEAAQAAgEBEgMlBA4KDgoHBAAEAAIBAhIDJRESCj0KBgQABAACAhIDKAQXGi4gVGhlIGF0
dGFjayBleHBvc3VyZSBoYXMgbm90IGJlZW4gY2FsY3VsYXRlZC4KCg4KBwQABAACAgESAygE
EgoOCgcEAAQAAgICEgMoFRYKtgEKBAQAAgASAy4CExqoASBBIG51bWJlciBiZXR3ZWVuIDAg
KGluY2x1c2l2ZSkgYW5kIGluZmluaXR5IHRoYXQgcmVwcmVzZW50cyBob3cgaW1wb3J0YW50
CiB0aGlzIGZpbmRpbmcgaXMgdG8gcmVtZWRpYXRlLiBUaGUgaGlnaGVyIHRoZSBzY29yZSwg
dGhlIG1vcmUgaW1wb3J0YW50IGl0CiBpcyB0byByZW1lZGlhdGUuCgoMCgUEAAIABRIDLgII
CgwKBQQAAgABEgMuCQ4KDAoFBAACAAMSAy4REgpUCgQEAAIBEgMxAjgaRyBUaGUgbW9zdCBy
ZWNlbnQgdGltZSB0aGUgYXR0YWNrIGV4cG9zdXJlIHdhcyB1cGRhdGVkIG9uIHRoaXMgZmlu
ZGluZy4KCgwKBQQAAgEGEgMxAhsKDAoFBAACAQESAzEcMwoMCgUEAAIBAxIDMTY3Cs8BCgQE
AAICEgM2AiQawQEgVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGF0dGFjayBwYXRoIHNpbXVs
YXRpb24gcmVzdWx0IHRoYXQgY29udGFpbnMgdGhlCiBkZXRhaWxzIHJlZ2FyZGluZyB0aGlz
IGF0dGFjayBleHBvc3VyZSBzY29yZS4KIEV4YW1wbGU6IGBvcmdhbml6YXRpb25zLzEyMy9z
aW11bGF0aW9ucy80NTYvYXR0YWNrRXhwb3N1cmVSZXN1bHRzLzc4OWAKCgwKBQQAAgIFEgM2
AggKDAoFBAACAgESAzYJHwoMCgUEAAICAxIDNiIjCo8BCgQEAAIDEgM6Aj4agQEgT3V0cHV0
IG9ubHkuIFdoYXQgc3RhdGUgdGhpcyBBdHRhY2tFeHBvc3VyZSBpcyBpbi4gVGhpcyBjYXB0
dXJlcyB3aGV0aGVyIG9yCiBub3QgYW4gYXR0YWNrIGV4cG9zdXJlIGhhcyBiZWVuIGNhbGN1
bGF0ZWQgb3Igbm90LgoKDAoFBAACAwYSAzoCBwoMCgUEAAIDARIDOggNCgwKBQQAAgMDEgM6
EBEKDAoFBAACAwgSAzoSPQoPCggEAAIDCJwIABIDOhM8CmAKBAQAAgQSAz4CLxpTIFRoZSBu
dW1iZXIgb2YgaGlnaCB2YWx1ZSByZXNvdXJjZXMgdGhhdCBhcmUgZXhwb3NlZCBhcyBhIHJl
c3VsdCBvZiB0aGlzCiBmaW5kaW5nLgoKDAoFBAACBAUSAz4CBwoMCgUEAAIEARIDPggqCgwK
BQQAAgQDEgM+LS4KYgoEBAACBRIDQgIxGlUgVGhlIG51bWJlciBvZiBtZWRpdW0gdmFsdWUg
cmVzb3VyY2VzIHRoYXQgYXJlIGV4cG9zZWQgYXMgYSByZXN1bHQgb2YgdGhpcwogZmluZGlu
Zy4KCgwKBQQAAgUFEgNCAgcKDAoFBAACBQESA0IILAoMCgUEAAIFAxIDQi8wCmAKBAQAAgYS
A0YCLhpTIFRoZSBudW1iZXIgb2YgaGlnaCB2YWx1ZSByZXNvdXJjZXMgdGhhdCBhcmUgZXhw
b3NlZCBhcyBhIHJlc3VsdCBvZiB0aGlzCiBmaW5kaW5nLgoKDAoFBAACBgUSA0YCBwoMCgUE
AAIGARIDRggpCgwKBQQAAgYDEgNGLC1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::AttackExposure::AttackExposure ===
    # Fields for AttackExposure
    # Field: score Type: 1 ()
    # Field: latest_calculation_time Type: 11 (.google.protobuf.Timestamp)
    # Field: attack_exposure_result Type: 9 ()
    # Field: state Type: 14 (.google.cloud.securitycenter.v2.AttackExposure.State)
    # Field: exposed_high_value_resources_count Type: 5 ()
    # Field: exposed_medium_value_resources_count Type: 5 ()
    # Field: exposed_low_value_resources_count Type: 5 ()

# Enum: AttackExposure::State
our $AttackExposure_STATE_UNSPECIFIED = 0;
our $AttackExposure_CALCULATED = 1;
our $AttackExposure_NOT_CALCULATED = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::AttackExposure - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/attack_exposure.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::AttackExposure;

    my $msg = Google::Cloud::Securitycenter::V2::AttackExposure::AttackExposure->new({
        score => $score,
        latest_calculation_time => $latest_calculation_time,
        attack_exposure_result => $attack_exposure_result,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->score();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::AttackExposure::AttackExposure->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/attack_exposure.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::AttackExposure::AttackExposure

An attack exposure contains the results of an attack path simulation run.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->score() >> / C<< $msg->score($value) >>

Type: C<Double>

A number between 0 (inclusive) and infinity that represents how important
this finding is to remediate. The higher the score, the more important it
is to remediate.

=item * C<< $msg->latest_calculation_time() >> / C<< $msg->latest_calculation_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The most recent time the attack exposure was updated on this finding.

=item * C<< $msg->attack_exposure_result() >> / C<< $msg->attack_exposure_result($value) >>

Type: C<String>

The resource name of the attack path simulation result that contains the
details regarding this attack exposure score.
Example: `organizations/123/simulations/456/attackExposureResults/789`

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V2::AttackExposure::State>)

Output only. What state this AttackExposure is in. This captures whether or
not an attack exposure has been calculated or not.

=item * C<< $msg->exposed_high_value_resources_count() >> / C<< $msg->exposed_high_value_resources_count($value) >>

Type: C<Int32>

The number of high value resources that are exposed as a result of this
finding.

=item * C<< $msg->exposed_medium_value_resources_count() >> / C<< $msg->exposed_medium_value_resources_count($value) >>

Type: C<Int32>

The number of medium value resources that are exposed as a result of this
finding.

=item * C<< $msg->exposed_low_value_resources_count() >> / C<< $msg->exposed_low_value_resources_count($value) >>

Type: C<Int32>

The number of high value resources that are exposed as a result of this
finding.

=back

=head3 Enum: AttackExposure::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CALCULATED> => C<1>

=item * C<NOT_CALCULATED> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::AttackExposure::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
