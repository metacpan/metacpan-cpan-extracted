package Google::Cloud::Retail::V2alpha::Control;

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
    eval { require Google::Cloud::Retail::V2alpha::Common };
    eval { require Google::Cloud::Retail::V2alpha::SearchService };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvY29udHJvbC5wcm90bxIbZ29vZ2xlLmNs
b3VkLnJldGFpbC52MmFscGhhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhln
b29nbGUvYXBpL3Jlc291cmNlLnByb3RvGihnb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEv
Y29tbW9uLnByb3RvGjBnb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvc2VhcmNoX3NlcnZp
Y2UucHJvdG8i6wQKB0NvbnRyb2wSWQoKZmFjZXRfc3BlYxgDIAEoCzI0Lmdvb2dsZS5jbG91
ZC5yZXRhaWwudjJhbHBoYS5TZWFyY2hSZXF1ZXN0LkZhY2V0U3BlY0ICGAFIAFIJZmFjZXRT
cGVjEjcKBHJ1bGUYBCABKAsyIS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuUnVsZUgA
UgRydWxlEhcKBG5hbWUYASABKAlCA+BBBVIEbmFtZRImCgxkaXNwbGF5X25hbWUYAiABKAlC
A+BBAlILZGlzcGxheU5hbWUSRgodYXNzb2NpYXRlZF9zZXJ2aW5nX2NvbmZpZ19pZHMYBSAD
KAlCA+BBA1IaYXNzb2NpYXRlZFNlcnZpbmdDb25maWdJZHMSWAoOc29sdXRpb25fdHlwZXMY
BiADKA4yKS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuU29sdXRpb25UeXBlQgbgQQLg
QQVSDXNvbHV0aW9uVHlwZXMSawoYc2VhcmNoX3NvbHV0aW9uX3VzZV9jYXNlGAcgAygOMjIu
Z29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlNlYXJjaFNvbHV0aW9uVXNlQ2FzZVIVc2Vh
cmNoU29sdXRpb25Vc2VDYXNlOnHqQW4KHXJldGFpbC5nb29nbGVhcGlzLmNvbS9Db250cm9s
Ek1wcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY2F0YWxvZ3Mve2Nh
dGFsb2d9L2NvbnRyb2xzL3tjb250cm9sfUIJCgdjb250cm9sQtABCh9jb20uZ29vZ2xlLmNs
b3VkLnJldGFpbC52MmFscGhhQgxDb250cm9sUHJvdG9QAVo3Y2xvdWQuZ29vZ2xlLmNvbS9n
by9yZXRhaWwvYXBpdjJhbHBoYS9yZXRhaWxwYjtyZXRhaWxwYqICBlJFVEFJTKoCG0dvb2ds
ZS5DbG91ZC5SZXRhaWwuVjJBbHBoYcoCG0dvb2dsZVxDbG91ZFxSZXRhaWxcVjJhbHBoYeoC
Hkdvb2dsZTo6Q2xvdWQ6OlJldGFpbDo6VjJhbHBoYUr9GwoGEgQOAGMBCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAkCgkKAgMAEgMSACkKCQoCAwESAxMA
IwoJCgIDAhIDFAAyCgkKAgMDEgMVADoKCAoBCBIDFwA4CgkKAgglEgMXADgKCAoBCBIDGABO
CgkKAggLEgMYAE4KCAoBCBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgAtCgkKAggIEgMaAC0K
CAoBCBIDGwA4CgkKAggBEgMbADgKCAoBCBIDHAAkCgkKAggkEgMcACQKCAoBCBIDHQA4CgkK
AggpEgMdADgKCAoBCBIDHgA3CgkKAggtEgMeADcKvAEKAgQAEgQjAGMBGq8BIENvbmZpZ3Vy
ZXMgZHluYW1pYyBtZXRhZGF0YSB0aGF0IGNhbiBiZSBsaW5rZWQgdG8gYQogW1NlcnZpbmdD
b25maWddW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5TZXJ2aW5nQ29uZmlnXSBhbmQg
YWZmZWN0IHNlYXJjaAogb3IgcmVjb21tZW5kYXRpb24gcmVzdWx0cyBhdCBzZXJ2aW5nIHRp
bWUuCgoKCgMEAAESAyMIDwoLCgMEAAcSBCQCJwQKDQoFBAAHnQgSBCQCJwQKhgIKBAQACAAS
BC4COQMa9wEgVGhlIGJlaGF2aW9yL3R5cGUgb2YgdGhlIGNvbnRyb2wKCiBBIGJlaGF2aW9y
L3R5cGUgbXVzdCBiZSBzcGVjaWZpZWQgb24gY3JlYXRpb24uIFR5cGUgY2Fubm90IGJlIGNo
YW5nZWQgb25jZQogc3BlY2lmaWVkIChlLmcuIEEgUnVsZSBjb250cm9sIHdpbGwgYWx3YXlz
IGJlIGEgUnVsZSBjb250cm9sLikuIEFuCiBJTlZBTElEX0FSR1VNRU5UIHdpbGwgYmUgcmV0
dXJuZWQgaWYgZWl0aGVyIGNvbmRpdGlvbiBpcyB2aW9sYXRlZC4KCgwKBQQACAABEgMuCA8K
pQEKBAQAAgASAzMEPxqXASBBIGZhY2V0IHNwZWNpZmljYXRpb24gdG8gcGVyZm9ybSBmYWNl
dGVkIHNlYXJjaC4KCiBOb3RlIHRoYXQgdGhpcyBmaWVsZCBpcyBkZXByZWNhdGVkIGFuZCB3
aWxsIHRocm93IE5PVF9JTVBMRU1FTlRFRCBpZgogdXNlZCBmb3IgY3JlYXRpbmcgYSBjb250
cm9sLgoKDAoFBAACAAYSAzMEGwoMCgUEAAIAARIDMxwmCgwKBQQAAgADEgMzKSoKDAoFBAAC
AAgSAzMrPgoNCgYEAAIACAMSAzMsPQq0AQoEBAACARIDOAQSGqYBIEEgcnVsZSBjb250cm9s
IC0gYSBjb25kaXRpb24tYWN0aW9uIHBhaXIuCiBFbmFjdHMgYSBzZXQgYWN0aW9uIHdoZW4g
dGhlIGNvbmRpdGlvbiBpcyB0cmlnZ2VyZWQuCiBGb3IgZXhhbXBsZTogQm9vc3QgImdTaG9l
IiB3aGVuIHF1ZXJ5IGZ1bGwgbWF0Y2hlcyAiUnVubmluZyBTaG9lcyIuCgoMCgUEAAIBBhID
OAQICgwKBQQAAgEBEgM4CQ0KDAoFBAACAQMSAzgQEQpjCgQEAAICEgM9AjwaViBJbW11dGFi
bGUuIEZ1bGx5IHF1YWxpZmllZCBuYW1lCiBgcHJvamVjdHMvKi9sb2NhdGlvbnMvZ2xvYmFs
L2NhdGFsb2dzLyovY29udHJvbHMvKmAKCgwKBQQAAgIFEgM9AggKDAoFBAACAgESAz0JDQoM
CgUEAAICAxIDPRARCgwKBQQAAgIIEgM9EjsKDwoIBAACAgicCAASAz0TOgrZAQoEBAACAxID
QwJDGssBIFJlcXVpcmVkLiBUaGUgaHVtYW4gcmVhZGFibGUgY29udHJvbCBkaXNwbGF5IG5h
bWUuIFVzZWQgaW4gUmV0YWlsIFVJLgoKIFRoaXMgZmllbGQgbXVzdCBiZSBhIFVURi04IGVu
Y29kZWQgc3RyaW5nIHdpdGggYSBsZW5ndGggbGltaXQgb2YgMTI4CiBjaGFyYWN0ZXJzLiBP
dGhlcndpc2UsIGFuIElOVkFMSURfQVJHVU1FTlQgZXJyb3IgaXMgdGhyb3duLgoKDAoFBAAC
AwUSA0MCCAoMCgUEAAIDARIDQwkVCgwKBQQAAgMDEgNDGBkKDAoFBAACAwgSA0MaQgoPCggE
AAIDCJwIABIDQxtBCtwCCgQEAAIEEgRNAk4yGs0CIE91dHB1dCBvbmx5LiBMaXN0IG9mIFtz
ZXJ2aW5nCiBjb25maWddW2dvb2dsZS5jbG91ZC5yZXRhaWwudjJhbHBoYS5TZXJ2aW5nQ29u
ZmlnXSBpZHMgdGhhdCBhcmUgYXNzb2NpYXRlZAogd2l0aCB0aGlzIGNvbnRyb2wgaW4gdGhl
IHNhbWUKIFtDYXRhbG9nXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuQ2F0YWxvZ10u
CgogTm90ZSB0aGUgYXNzb2NpYXRpb24gaXMgbWFuYWdlZCB2aWEgdGhlCiBbU2VydmluZ0Nv
bmZpZ11bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlNlcnZpbmdDb25maWddLCB0aGlz
IGlzIGFuCiBvdXRwdXQgb25seSBkZW5vcm1hbGl6ZWQgdmlldy4KCgwKBQQAAgQEEgNNAgoK
DAoFBAACBAUSA00LEQoMCgUEAAIEARIDTRIvCgwKBQQAAgQDEgNNMjMKDAoFBAACBAgSA04G
MQoPCggEAAIECJwIABIDTgcwCvsCCgQEAAIFEgRWAlkEGuwCIFJlcXVpcmVkLiBJbW11dGFi
bGUuIFRoZSBzb2x1dGlvbiB0eXBlcyB0aGF0IHRoZSBjb250cm9sIGlzIHVzZWQgZm9yLgog
Q3VycmVudGx5IHdlIHN1cHBvcnQgc2V0dGluZyBvbmx5IG9uZSB0eXBlIG9mIHNvbHV0aW9u
IGF0IGNyZWF0aW9uIHRpbWUuCgogT25seSBgU09MVVRJT05fVFlQRV9TRUFSQ0hgIHZhbHVl
IGlzIHN1cHBvcnRlZCBhdCB0aGUgbW9tZW50LgogSWYgbm8gc29sdXRpb24gdHlwZSBpcyBw
cm92aWRlZCBhdCBjcmVhdGlvbiB0aW1lLCB3aWxsIGRlZmF1bHQgdG8KIFtTT0xVVElPTl9U
WVBFX1NFQVJDSF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmFscGhhLlNvbHV0aW9uVHlwZS5T
T0xVVElPTl9UWVBFX1NFQVJDSF0uCgoMCgUEAAIFBBIDVgIKCgwKBQQAAgUGEgNWCxcKDAoF
BAACBQESA1YYJgoMCgUEAAIFAxIDVikqCg0KBQQAAgUIEgRWK1kDCg8KCAQAAgUInAgAEgNX
BCoKDwoIBAACBQicCAESA1gEKwrfAgoEBAACBhIDYgI+GtECIFNwZWNpZmllcyB0aGUgdXNl
IGNhc2UgZm9yIHRoZSBjb250cm9sLgogQWZmZWN0cyB3aGF0IGNvbmRpdGlvbiBmaWVsZHMg
Y2FuIGJlIHNldC4KIE9ubHkgc2V0dGFibGUgYnkgc2VhcmNoIGNvbnRyb2xzLgogV2lsbCBk
ZWZhdWx0IHRvCiBbU0VBUkNIX1NPTFVUSU9OX1VTRV9DQVNFX1NFQVJDSF1bZ29vZ2xlLmNs
b3VkLnJldGFpbC52MmFscGhhLlNlYXJjaFNvbHV0aW9uVXNlQ2FzZS5TRUFSQ0hfU09MVVRJ
T05fVVNFX0NBU0VfU0VBUkNIXQogaWYgbm90IHNwZWNpZmllZC4gQ3VycmVudGx5IG9ubHkg
YWxsb3cgb25lIHNlYXJjaF9zb2x1dGlvbl91c2VfY2FzZSBwZXIKIGNvbnRyb2wuCgoMCgUE
AAIGBBIDYgIKCgwKBQQAAgYGEgNiCyAKDAoFBAACBgESA2IhOQoMCgUEAAIGAxIDYjw9YgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2alpha::Control::Control ===
    # Fields for Control
    # Field: facet_spec Type: 11 (.google.cloud.retail.v2alpha.SearchRequest.FacetSpec)
    # Field: rule Type: 11 (.google.cloud.retail.v2alpha.Rule)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: associated_serving_config_ids Type: 9 ()
    # Field: solution_types Type: 14 (.google.cloud.retail.v2alpha.SolutionType)
    # Field: search_solution_use_case Type: 14 (.google.cloud.retail.v2alpha.SearchSolutionUseCase)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2alpha::Control - Compiled Protocol Buffers messages for google/cloud/retail/v2alpha/control.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2alpha::Control;

    my $msg = Google::Cloud::Retail::V2alpha::Control::Control->new({
        facet_spec => $facet_spec,
        rule => $rule,
        name => $name,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->facet_spec();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2alpha::Control::Control->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2alpha/control.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2alpha::Control::Control

Configures dynamic metadata that can be linked to a
[ServingConfig][google.cloud.retail.v2alpha.ServingConfig] and affect search
or recommendation results at serving time.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->facet_spec() >> / C<< $msg->facet_spec($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::FacetSpec>)

A facet specification to perform faceted search.

Note that this field is deprecated and will throw NOT_IMPLEMENTED if
used for creating a control.

=item * C<< $msg->rule() >> / C<< $msg->rule($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2alpha::Common::Rule>)

A rule control - a condition-action pair.
Enacts a set action when the condition is triggered.
For example: Boost "gShoe" when query full matches "Running Shoes".

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. Fully qualified name
`projects/*/locations/global/catalogs/*/controls/*`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The human readable control display name. Used in Retail UI.

This field must be a UTF-8 encoded string with a length limit of 128
characters. Otherwise, an INVALID_ARGUMENT error is thrown.

=item * C<< $msg->associated_serving_config_ids() >> / C<< $msg->associated_serving_config_ids($value) >>

Type: C<String>

Output only. List of [serving
config][google.cloud.retail.v2alpha.ServingConfig] ids that are associated
with this control in the same
[Catalog][google.cloud.retail.v2alpha.Catalog].

Note the association is managed via the
[ServingConfig][google.cloud.retail.v2alpha.ServingConfig], this is an
output only denormalized view.

=item * C<< $msg->solution_types() >> / C<< $msg->solution_types($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2alpha::SolutionType>)

Required. Immutable. The solution types that the control is used for.
Currently we support setting only one type of solution at creation time.

Only `SOLUTION_TYPE_SEARCH` value is supported at the moment.
If no solution type is provided at creation time, will default to
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2alpha.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->search_solution_use_case() >> / C<< $msg->search_solution_use_case($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2alpha::SearchSolutionUseCase>)

Specifies the use case for the control.
Affects what condition fields can be set.
Only settable by search controls.
Will default to
[SEARCH_SOLUTION_USE_CASE_SEARCH][google.cloud.retail.v2alpha.SearchSolutionUseCase.SEARCH_SOLUTION_USE_CASE_SEARCH]
if not specified. Currently only allow one search_solution_use_case per
control.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2alpha::Control::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
