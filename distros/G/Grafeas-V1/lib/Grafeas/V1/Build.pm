package Grafeas::V1::Build;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Grafeas::V1::IntotoProvenance };
    eval { require Grafeas::V1::IntotoStatement };
    eval { require Grafeas::V1::Provenance };
    my $descriptor_b64 = <<'EOF';
ChZncmFmZWFzL3YxL2J1aWxkLnByb3RvEgpncmFmZWFzLnYxGiJncmFmZWFzL3YxL2ludG90
b19wcm92ZW5hbmNlLnByb3RvGiFncmFmZWFzL3YxL2ludG90b19zdGF0ZW1lbnQucHJvdG8a
G2dyYWZlYXMvdjEvcHJvdmVuYW5jZS5wcm90byI0CglCdWlsZE5vdGUSJwoPYnVpbGRlcl92
ZXJzaW9uGAEgASgJUg5idWlsZGVyVmVyc2lvbiLsAgoPQnVpbGRPY2N1cnJlbmNlEjsKCnBy
b3ZlbmFuY2UYASABKAsyGy5ncmFmZWFzLnYxLkJ1aWxkUHJvdmVuYW5jZVIKcHJvdmVuYW5j
ZRIpChBwcm92ZW5hbmNlX2J5dGVzGAIgASgJUg9wcm92ZW5hbmNlQnl0ZXMSSQoRaW50b3Rv
X3Byb3ZlbmFuY2UYAyABKAsyHC5ncmFmZWFzLnYxLkluVG90b1Byb3ZlbmFuY2VSEGludG90
b1Byb3ZlbmFuY2USRgoQaW50b3RvX3N0YXRlbWVudBgEIAEoCzIbLmdyYWZlYXMudjEuSW5U
b3RvU3RhdGVtZW50Ug9pbnRvdG9TdGF0ZW1lbnQSXgoaaW5fdG90b19zbHNhX3Byb3ZlbmFu
Y2VfdjEYBSABKAsyIi5ncmFmZWFzLnYxLkluVG90b1Nsc2FQcm92ZW5hbmNlVjFSFmluVG90
b1Nsc2FQcm92ZW5hbmNlVjFCUQoNaW8uZ3JhZmVhcy52MVABWjhnb29nbGUuZ29sYW5nLm9y
Zy9nZW5wcm90by9nb29nbGVhcGlzL2dyYWZlYXMvdjE7Z3JhZmVhc6ICA0dSQUr/EwoGEgQO
AEMBCtoECgEMEgMOABIyzwQgQ29weXJpZ2h0IDIwMTkgVGhlIEdyYWZlYXMgQXV0aG9ycy4g
QWxsIHJpZ2h0cyByZXNlcnZlZC4KCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAATCgkKAgMAEgMSACwKCQoCAwESAxMAKwoJCgIDAhID
FAAlCggKAQgSAxYATwoJCgIICxIDFgBPCggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgA
JgoJCgIIARIDGAAmCggKAQgSAxkAIQoJCgIIJBIDGQAhCo8BCgIEABIEHQAgARqCASBOb3Rl
IGhvbGRpbmcgdGhlIHZlcnNpb24gb2YgdGhlIHByb3ZpZGVyJ3MgYnVpbGRlciBhbmQgdGhl
IHNpZ25hdHVyZSBvZiB0aGUKIHByb3ZlbmFuY2UgbWVzc2FnZSBpbiB0aGUgYnVpbGQgZGV0
YWlscyBvY2N1cnJlbmNlLgoKCgoDBAABEgMdCBEKVQoEBAACABIDHwIdGkggUmVxdWlyZWQu
IEltbXV0YWJsZS4gVmVyc2lvbiBvZiB0aGUgYnVpbGRlciB3aGljaCBwcm9kdWNlZCB0aGlz
IGJ1aWxkLgoKDAoFBAACAAUSAx8CCAoMCgUEAAIAARIDHwkYCgwKBQQAAgADEgMfGxwKLAoC
BAESBCMAQwEaICBEZXRhaWxzIG9mIGEgYnVpbGQgb2NjdXJyZW5jZS4KCgoKAwQBARIDIwgX
CjMKBAQBAgASAyUCLBomIFRoZSBhY3R1YWwgcHJvdmVuYW5jZSBmb3IgdGhlIGJ1aWxkLgoK
DAoFBAECAAYSAyUCHAoMCgUEAQIAARIDJR0nCgwKBQQBAgADEgMlKisK7AQKBAQBAgESAzIC
HhreBCBTZXJpYWxpemVkIEpTT04gcmVwcmVzZW50YXRpb24gb2YgdGhlIHByb3ZlbmFuY2Us
IHVzZWQgaW4gZ2VuZXJhdGluZyB0aGUKIGJ1aWxkIHNpZ25hdHVyZSBpbiB0aGUgY29ycmVz
cG9uZGluZyBidWlsZCBub3RlLiBBZnRlciB2ZXJpZnlpbmcgdGhlCiBzaWduYXR1cmUsIGBw
cm92ZW5hbmNlX2J5dGVzYCBjYW4gYmUgdW5tYXJzaGFsbGVkIGFuZCBjb21wYXJlZCB0byB0
aGUKIHByb3ZlbmFuY2UgdG8gY29uZmlybSB0aGF0IGl0IGlzIHVuY2hhbmdlZC4gQSBiYXNl
NjQtZW5jb2RlZCBzdHJpbmcKIHJlcHJlc2VudGF0aW9uIG9mIHRoZSBwcm92ZW5hbmNlIGJ5
dGVzIGlzIHVzZWQgZm9yIHRoZSBzaWduYXR1cmUgaW4gb3JkZXIKIHRvIGludGVyb3BlcmF0
ZSB3aXRoIG9wZW5zc2wgd2hpY2ggZXhwZWN0cyB0aGlzIGZvcm1hdCBmb3Igc2lnbmF0dXJl
CiB2ZXJpZmljYXRpb24uCgogVGhlIHNlcmlhbGl6ZWQgZm9ybSBpcyBjYXB0dXJlZCBib3Ro
IHRvIGF2b2lkIGFtYmlndWl0eSBpbiBob3cgdGhlCiBwcm92ZW5hbmNlIGlzIG1hcnNoYWxs
ZWQgdG8ganNvbiBhcyB3ZWxsIHRvIHByZXZlbnQgaW5jb21wYXRpYmlsaXRpZXMgd2l0aAog
ZnV0dXJlIGNoYW5nZXMuCgoMCgUEAQIBBRIDMgIICgwKBQQBAgEBEgMyCRkKDAoFBAECAQMS
AzIcHQp6CgQEAQICEgM2AikabSBEZXByZWNhdGVkLiBTZWUgSW5Ub3RvU3RhdGVtZW50IGZv
ciB0aGUgcmVwbGFjZW1lbnQuCiBJbi10b3RvIFByb3ZlbmFuY2UgcmVwcmVzZW50YXRpb24g
YXMgZGVmaW5lZCBpbiBzcGVjLgoKDAoFBAECAgYSAzYCEgoMCgUEAQICARIDNhMkCgwKBQQB
AgIDEgM2JygK3wEKBAQBAgMSAzwCJxrRASBJbi10b3RvIFN0YXRlbWVudCByZXByZXNlbnRh
dGlvbiBhcyBkZWZpbmVkIGluIHNwZWMuCiBUaGUgaW50b3RvX3N0YXRlbWVudCBjYW4gY29u
dGFpbiBhbnkgdHlwZSBvZiBwcm92ZW5hbmNlLiBUaGUgc2VyaWFsaXplZAogcGF5bG9hZCBv
ZiB0aGUgc3RhdGVtZW50IGNhbiBiZSBzdG9yZWQgYW5kIHNpZ25lZCBpbiB0aGUgT2NjdXJy
ZW5jZSdzCiBlbnZlbG9wZS4KCgwKBQQBAgMGEgM8AhEKDAoFBAECAwESAzwSIgoMCgUEAQID
AxIDPCUmCusBCgQEAQIEEgNCAjga3QEgSW4tVG90byBTbHNhIFByb3ZlbmFuY2UgVjEgcmVw
cmVzZW50cyBhIHNsc2EgcHJvdmVuYW5jZSBtZWV0aW5nIHRoZSBzbHNhCiBzcGVjLCB3cmFw
cGVkIGluIGFuIGluLXRvdG8gc3RhdGVtZW50LiBUaGlzIGFsbG93cyBmb3IgZGlyZWN0CiBq
c29uaWZpY2F0aW9uIG9mIGEgdG8tc3BlYyBpbi10b3RvIHNsc2Egc3RhdGVtZW50IHdpdGgg
YSB0by1zcGVjCiBzbHNhIHByb3ZlbmFuY2UuCgoMCgUEAQIEBhIDQgIYCgwKBQQBAgQBEgNC
GTMKDAoFBAECBAMSA0I2N2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Grafeas::V1::Build::BuildNote ===
    # Fields for BuildNote
    # Field: builder_version Type: 9 ()

# === Message: Grafeas::V1::Build::BuildOccurrence ===
    # Fields for BuildOccurrence
    # Field: provenance Type: 11 (.grafeas.v1.BuildProvenance)
    # Field: provenance_bytes Type: 9 ()
    # Field: intoto_provenance Type: 11 (.grafeas.v1.InTotoProvenance)
    # Field: intoto_statement Type: 11 (.grafeas.v1.InTotoStatement)
    # Field: in_toto_slsa_provenance_v1 Type: 11 (.grafeas.v1.InTotoSlsaProvenanceV1)

1;

__END__

=encoding UTF-8

=head1 NAME

Grafeas::V1::Build - Compiled Protocol Buffers messages for grafeas/v1/build.proto

=head1 SYNOPSIS

    use Grafeas::V1::Build;

    my $msg = Grafeas::V1::Build::BuildNote->new({
        builder_version => $builder_version,
    });

    # Read or update a field
    my $val = $msg->builder_version();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Grafeas::V1::Build::BuildNote->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<grafeas/v1/build.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Grafeas::V1::Build::BuildNote

Note holding the version of the provider's builder and the signature of the
provenance message in the build details occurrence.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->builder_version() >> / C<< $msg->builder_version($value) >>

Type: C<String>

Required. Immutable. Version of the builder which produced this build.

=back

=head2 Grafeas::V1::Build::BuildOccurrence

Details of a build occurrence.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->provenance() >> / C<< $msg->provenance($value) >>

Type: C<Message> (L<Grafeas::V1::Provenance::BuildProvenance>)

The actual provenance for the build.

=item * C<< $msg->provenance_bytes() >> / C<< $msg->provenance_bytes($value) >>

Type: C<String>

Serialized JSON representation of the provenance, used in generating the
build signature in the corresponding build note. After verifying the
signature, `provenance_bytes` can be unmarshalled and compared to the
provenance to confirm that it is unchanged. A base64-encoded string
representation of the provenance bytes is used for the signature in order
to interoperate with openssl which expects this format for signature
verification.

The serialized form is captured both to avoid ambiguity in how the
provenance is marshalled to json as well to prevent incompatibilities with
future changes.

=item * C<< $msg->intoto_provenance() >> / C<< $msg->intoto_provenance($value) >>

Type: C<Message> (L<Grafeas::V1::IntotoProvenance::InTotoProvenance>)

Deprecated. See InTotoStatement for the replacement.
In-toto Provenance representation as defined in spec.

=item * C<< $msg->intoto_statement() >> / C<< $msg->intoto_statement($value) >>

Type: C<Message> (L<Grafeas::V1::IntotoStatement::InTotoStatement>)

In-toto Statement representation as defined in spec.
The intoto_statement can contain any type of provenance. The serialized
payload of the statement can be stored and signed in the Occurrence's
envelope.

=item * C<< $msg->in_toto_slsa_provenance_v1() >> / C<< $msg->in_toto_slsa_provenance_v1($value) >>

Type: C<Message> (L<Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1>)

In-Toto Slsa Provenance V1 represents a slsa provenance meeting the slsa
spec, wrapped in an in-toto statement. This allows for direct
jsonification of a to-spec in-toto slsa statement with a to-spec
slsa provenance.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Grafeas::V1::Build::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
