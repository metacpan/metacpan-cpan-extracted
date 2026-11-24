package Google::Bigtable::V2::FeatureFlags;

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
CiZnb29nbGUvYmlndGFibGUvdjIvZmVhdHVyZV9mbGFncy5wcm90bxISZ29vZ2xlLmJpZ3Rh
YmxlLnYyGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvIogFCgxGZWF0dXJlRmxh
Z3MSIwoNcmV2ZXJzZV9zY2FucxgBIAEoCFIMcmV2ZXJzZVNjYW5zEjMKFm11dGF0ZV9yb3dz
X3JhdGVfbGltaXQYAyABKAhSE211dGF0ZVJvd3NSYXRlTGltaXQSNQoXbXV0YXRlX3Jvd3Nf
cmF0ZV9saW1pdDIYBSABKAhSFG11dGF0ZVJvd3NSYXRlTGltaXQyEjsKGmxhc3Rfc2Nhbm5l
ZF9yb3dfcmVzcG9uc2VzGAQgASgIUhdsYXN0U2Nhbm5lZFJvd1Jlc3BvbnNlcxIlCg5yb3V0
aW5nX2Nvb2tpZRgGIAEoCFINcm91dGluZ0Nvb2tpZRIdCgpyZXRyeV9pbmZvGAcgASgIUgly
ZXRyeUluZm8SPQobY2xpZW50X3NpZGVfbWV0cmljc19lbmFibGVkGAggASgIUhhjbGllbnRT
aWRlTWV0cmljc0VuYWJsZWQSOAoYdHJhZmZpY19kaXJlY3Rvcl9lbmFibGVkGAkgASgIUhZ0
cmFmZmljRGlyZWN0b3JFbmFibGVkEjYKF2RpcmVjdF9hY2Nlc3NfcmVxdWVzdGVkGAogASgI
UhVkaXJlY3RBY2Nlc3NSZXF1ZXN0ZWQSGwoJcGVlcl9pbmZvGAsgASgIUghwZWVySW5mbxIv
ChNzZXNzaW9uc19jb21wYXRpYmxlGAwgASgIUhJzZXNzaW9uc0NvbXBhdGlibGUSKwoRc2Vz
c2lvbnNfcmVxdWlyZWQYDSABKAhSEHNlc3Npb25zUmVxdWlyZWQSOAoVbWljcm9zZWNvbmRf
dGltZXN0YW1wGA4gASgIQgPgQQFSFG1pY3Jvc2Vjb25kVGltZXN0YW1wQrsBChZjb20uZ29v
Z2xlLmJpZ3RhYmxlLnYyQhFGZWF0dXJlRmxhZ3NQcm90b1ABWjhjbG91ZC5nb29nbGUuY29t
L2dvL2JpZ3RhYmxlL2FwaXYyL2JpZ3RhYmxlcGI7YmlndGFibGVwYqoCGEdvb2dsZS5DbG91
ZC5CaWd0YWJsZS5WMsoCGEdvb2dsZVxDbG91ZFxCaWd0YWJsZVxWMuoCG0dvb2dsZTo6Q2xv
dWQ6OkJpZ3RhYmxlOjpWMkqIGgoGEgQOAFQBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAbCgkKAgMAEgMSACkKCAoBCBIDFAA1CgkKAgglEgMUADUKCAoB
CBIDFQBPCgkKAggLEgMVAE8KCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAyCgkKAggI
EgMXADIKCAoBCBIDGAAvCgkKAggBEgMYAC8KCAoBCBIDGQA1CgkKAggpEgMZADUKCAoBCBID
GgA0CgkKAggtEgMaADQKhgQKAgQAEgQkAFQBGvkDIEZlYXR1cmUgZmxhZ3Mgc3VwcG9ydGVk
IG9yIGVuYWJsZWQgYnkgYSBjbGllbnQuCiBUaGlzIGlzIGludGVuZGVkIHRvIGJlIHNlbnQg
YXMgcGFydCBvZiByZXF1ZXN0IG1ldGFkYXRhIHRvIGFzc3VyZSB0aGUgc2VydmVyCiB0aGF0
IGNlcnRhaW4gYmVoYXZpb3JzIGFyZSBzYWZlIHRvIGVuYWJsZS4gVGhpcyBwcm90byBpcyBt
ZWFudCB0byBiZQogc2VyaWFsaXplZCBhbmQgd2Vic2FmZS1iYXNlNjQgZW5jb2RlZCB1bmRl
ciB0aGUgYGJpZ3RhYmxlLWZlYXR1cmVzYCBtZXRhZGF0YQoga2V5LiBUaGUgdmFsdWUgd2ls
bCByZW1haW4gY29uc3RhbnQgZm9yIHRoZSBsaWZldGltZSBvZiBhIGNsaWVudCBhbmQgZHVl
IHRvCiBIVFRQMidzIEhQQUNLIGNvbXByZXNzaW9uLCB0aGUgcmVxdWVzdCBvdmVyaGVhZCB3
aWxsIGJlIHRpbnkuCiBUaGlzIGlzIGFuIGludGVybmFsIGltcGxlbWVudGF0aW9uIGRldGFp
bCBhbmQgc2hvdWxkIG5vdCBiZSB1c2VkIGJ5IGVuZCB1c2VycwogZGlyZWN0bHkuCgoKCgME
AAESAyQIFAqgAQoEBAACABIDJwIZGpIBIE5vdGlmeSB0aGUgc2VydmVyIHRoYXQgdGhlIGNs
aWVudCBzdXBwb3J0cyByZXZlcnNlIHNjYW5zLiBUaGUgc2VydmVyIHdpbGwKIHJlamVjdCBS
ZWFkUm93c1JlcXVlc3RzIHdpdGggdGhlIHJldmVyc2UgYml0IHNldCB3aGVuIHRoaXMgaXMg
YWJzZW50LgoKDAoFBAACAAUSAycCBgoMCgUEAAIAARIDJwcUCgwKBQQAAgADEgMnFxgKwgEK
BAQAAgESAywCIhq0ASBOb3RpZnkgdGhlIHNlcnZlciB0aGF0IHRoZSBjbGllbnQgZW5hYmxl
cyBiYXRjaCB3cml0ZSBmbG93IGNvbnRyb2wgYnkKIHJlcXVlc3RpbmcgUmF0ZUxpbWl0SW5m
byBmcm9tIE11dGF0ZVJvd3NSZXNwb25zZS4gRHVlIHRvIHRlY2huaWNhbCByZWFzb25zLAog
dGhpcyBkaXNhYmxlcyBwYXJ0aWFsIHJldHJpZXMuCgoMCgUEAAIBBRIDLAIGCgwKBQQAAgEB
EgMsBx0KDAoFBAACAQMSAywgIQqnAQoEBAACAhIDMQIjGpkBIE5vdGlmeSB0aGUgc2VydmVy
IHRoYXQgdGhlIGNsaWVudCBlbmFibGVzIGJhdGNoIHdyaXRlIGZsb3cgY29udHJvbCBieQog
cmVxdWVzdGluZyBSYXRlTGltaXRJbmZvIGZyb20gTXV0YXRlUm93c1Jlc3BvbnNlLiBXaXRo
IHBhcnRpYWwgcmV0cmllcwogZW5hYmxlZC4KCgwKBQQAAgIFEgMxAgYKDAoFBAACAgESAzEH
HgoMCgUEAAICAxIDMSEiCoEBCgQEAAIDEgM1AiYadCBOb3RpZnkgdGhlIHNlcnZlciB0aGF0
IHRoZSBjbGllbnQgc3VwcG9ydHMgdGhlIGxhc3Rfc2Nhbm5lZF9yb3cgZmllbGQKIGluIFJl
YWRSb3dzUmVzcG9uc2UgZm9yIGxvbmctcnVubmluZyBzY2Fucy4KCgwKBQQAAgMFEgM1AgYK
DAoFBAACAwESAzUHIQoMCgUEAAIDAxIDNSQlCncKBAQAAgQSAzkCGhpqIE5vdGlmeSB0aGUg
c2VydmVyIHRoYXQgdGhlIGNsaWVudCBzdXBwb3J0cyB1c2luZyBlbmNvZGVkIHJvdXRpbmcg
Y29va2llCiBzdHJpbmdzIHRvIHJldHJ5IHJlcXVlc3RzIHdpdGguCgoMCgUEAAIEBRIDOQIG
CgwKBQQAAgQBEgM5BxUKDAoFBAACBAMSAzkYGQp2CgQEAAIFEgM9AhYaaSBOb3RpZnkgdGhl
IHNlcnZlciB0aGF0IHRoZSBjbGllbnQgc3VwcG9ydHMgdXNpbmcgcmV0cnkgaW5mbyBiYWNr
IG9mZgogZHVyYXRpb25zIHRvIHJldHJ5IHJlcXVlc3RzIHdpdGguCgoMCgUEAAIFBRIDPQIG
CgwKBQQAAgUBEgM9BxEKDAoFBAACBQMSAz0UFQpRCgQEAAIGEgNAAicaRCBOb3RpZnkgdGhl
IHNlcnZlciB0aGF0IHRoZSBjbGllbnQgaGFzIGNsaWVudCBzaWRlIG1ldHJpY3MgZW5hYmxl
ZC4KCgwKBQQAAgYFEgNAAgYKDAoFBAACBgESA0AHIgoMCgUEAAIGAxIDQCUmClEKBAQAAgcS
A0MCJBpEIE5vdGlmeSB0aGUgc2VydmVyIHRoYXQgdGhlIGNsaWVudCB1c2luZyBUcmFmZmlj
IERpcmVjdG9yIGVuZHBvaW50LgoKDAoFBAACBwUSA0MCBgoMCgUEAAIHARIDQwcfCgwKBQQA
AgcDEgNDIiMKVwoEBAACCBIDRgIkGkogTm90aWZ5IHRoZSBzZXJ2ZXIgdGhhdCB0aGUgY2xp
ZW50IGV4cGxpY2l0bHkgb3B0ZWQgaW4gZm9yIERpcmVjdCBBY2Nlc3MuCgoMCgUEAAIIBRID
RgIGCgwKBQQAAggBEgNGBx4KDAoFBAACCAMSA0YhIwpACgQEAAIJEgNJAhYaMyBJZiB0aGUg
Y2xpZW50IGNhbiBzdXBwb3J0IHVzaW5nIEJpZ3RhYmxlUGVlckluZm8uCgoMCgUEAAIJBRID
SQIGCgwKBQQAAgkBEgNJBxAKDAoFBAACCQMSA0kTFQpPCgQEAAIKEgNMAiAaQiBJbmRpY2F0
ZXMgd2hldGhlciB0aGUgY2xpZW50IHN1cHBvcnRzIHRoZSBCaWd0YWJsZSBTZXNzaW9ucyBB
UEkuCgoMCgUEAAIKBRIDTAIGCgwKBQQAAgoBEgNMBxoKDAoFBAACCgMSA0wdHwpFCgQEAAIL
EgNPAh4aOCBJbnRlcm5hbCBmbGFnIHRvIGZvcmNlIHNlc3Npb25zIGZvciBpbnRlcm5hbCBw
cm9qZWN0cy4KCgwKBQQAAgsFEgNPAgYKDAoFBAACCwESA08HGAoMCgUEAAILAxIDTxsdCmEK
BAQAAgwSA1MCSxpUIE9wdGlvbmFsLiBJbmRpY2F0ZXMgd2hldGhlciB0aGUgY2xpZW50IHN1
cHBvcnRzIG1pY3Jvc2Vjb25kIHByZWNpc2lvbgogdGltZXN0YW1wcy4KCgwKBQQAAgwFEgNT
AgYKDAoFBAACDAESA1MHHAoMCgUEAAIMAxIDUx8hCgwKBQQAAgwIEgNTIkoKDwoIBAACDAic
CAASA1MjSWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Bigtable::V2::FeatureFlags::FeatureFlags ===
    # Fields for FeatureFlags
    # Field: reverse_scans Type: 8 ()
    # Field: mutate_rows_rate_limit Type: 8 ()
    # Field: mutate_rows_rate_limit2 Type: 8 ()
    # Field: last_scanned_row_responses Type: 8 ()
    # Field: routing_cookie Type: 8 ()
    # Field: retry_info Type: 8 ()
    # Field: client_side_metrics_enabled Type: 8 ()
    # Field: traffic_director_enabled Type: 8 ()
    # Field: direct_access_requested Type: 8 ()
    # Field: peer_info Type: 8 ()
    # Field: sessions_compatible Type: 8 ()
    # Field: sessions_required Type: 8 ()
    # Field: microsecond_timestamp Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Bigtable::V2::FeatureFlags - Compiled Protocol Buffers messages for google/bigtable/v2/feature_flags.proto

=head1 SYNOPSIS

    use Google::Bigtable::V2::FeatureFlags;

    my $msg = Google::Bigtable::V2::FeatureFlags::FeatureFlags->new({
        reverse_scans => $reverse_scans,
        mutate_rows_rate_limit => $mutate_rows_rate_limit,
        mutate_rows_rate_limit2 => $mutate_rows_rate_limit2,
        last_scanned_row_responses => $last_scanned_row_responses,
    });

    # Read or update a field
    my $val = $msg->reverse_scans();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Bigtable::V2::FeatureFlags::FeatureFlags->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/bigtable/v2/feature_flags.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Bigtable::V2::FeatureFlags::FeatureFlags

Feature flags supported or enabled by a client.
This is intended to be sent as part of request metadata to assure the server
that certain behaviors are safe to enable. This proto is meant to be
serialized and websafe-base64 encoded under the `bigtable-features` metadata
key. The value will remain constant for the lifetime of a client and due to
HTTP2's HPACK compression, the request overhead will be tiny.
This is an internal implementation detail and should not be used by end users
directly.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->reverse_scans() >> / C<< $msg->reverse_scans($value) >>

Type: C<Bool>

Notify the server that the client supports reverse scans. The server will
reject ReadRowsRequests with the reverse bit set when this is absent.

=item * C<< $msg->mutate_rows_rate_limit() >> / C<< $msg->mutate_rows_rate_limit($value) >>

Type: C<Bool>

Notify the server that the client enables batch write flow control by
requesting RateLimitInfo from MutateRowsResponse. Due to technical reasons,
this disables partial retries.

=item * C<< $msg->mutate_rows_rate_limit2() >> / C<< $msg->mutate_rows_rate_limit2($value) >>

Type: C<Bool>

Notify the server that the client enables batch write flow control by
requesting RateLimitInfo from MutateRowsResponse. With partial retries
enabled.

=item * C<< $msg->last_scanned_row_responses() >> / C<< $msg->last_scanned_row_responses($value) >>

Type: C<Bool>

Notify the server that the client supports the last_scanned_row field
in ReadRowsResponse for long-running scans.

=item * C<< $msg->routing_cookie() >> / C<< $msg->routing_cookie($value) >>

Type: C<Bool>

Notify the server that the client supports using encoded routing cookie
strings to retry requests with.

=item * C<< $msg->retry_info() >> / C<< $msg->retry_info($value) >>

Type: C<Bool>

Notify the server that the client supports using retry info back off
durations to retry requests with.

=item * C<< $msg->client_side_metrics_enabled() >> / C<< $msg->client_side_metrics_enabled($value) >>

Type: C<Bool>

Notify the server that the client has client side metrics enabled.

=item * C<< $msg->traffic_director_enabled() >> / C<< $msg->traffic_director_enabled($value) >>

Type: C<Bool>

Notify the server that the client using Traffic Director endpoint.

=item * C<< $msg->direct_access_requested() >> / C<< $msg->direct_access_requested($value) >>

Type: C<Bool>

Notify the server that the client explicitly opted in for Direct Access.

=item * C<< $msg->peer_info() >> / C<< $msg->peer_info($value) >>

Type: C<Bool>

If the client can support using BigtablePeerInfo.

=item * C<< $msg->sessions_compatible() >> / C<< $msg->sessions_compatible($value) >>

Type: C<Bool>

Indicates whether the client supports the Bigtable Sessions API.

=item * C<< $msg->sessions_required() >> / C<< $msg->sessions_required($value) >>

Type: C<Bool>

Internal flag to force sessions for internal projects.

=item * C<< $msg->microsecond_timestamp() >> / C<< $msg->microsecond_timestamp($value) >>

Type: C<Bool>

Optional. Indicates whether the client supports microsecond precision
timestamps.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Bigtable::V2::FeatureFlags::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
