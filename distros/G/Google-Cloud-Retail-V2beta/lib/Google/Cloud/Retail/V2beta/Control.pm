package Google::Cloud::Retail::V2beta::Control;

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
    eval { require Google::Cloud::Retail::V2beta::Common };
    eval { require Google::Cloud::Retail::V2beta::SearchService };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvcmV0YWlsL3YyYmV0YS9jb250cm9sLnByb3RvEhpnb29nbGUuY2xv
dWQucmV0YWlsLnYyYmV0YRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29v
Z2xlL2FwaS9yZXNvdXJjZS5wcm90bxonZ29vZ2xlL2Nsb3VkL3JldGFpbC92MmJldGEvY29t
bW9uLnByb3RvGi9nb29nbGUvY2xvdWQvcmV0YWlsL3YyYmV0YS9zZWFyY2hfc2VydmljZS5w
cm90byLnBAoHQ29udHJvbBJYCgpmYWNldF9zcGVjGAMgASgLMjMuZ29vZ2xlLmNsb3VkLnJl
dGFpbC52MmJldGEuU2VhcmNoUmVxdWVzdC5GYWNldFNwZWNCAhgBSABSCWZhY2V0U3BlYxI2
CgRydWxlGAQgASgLMiAuZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuUnVsZUgAUgRydWxl
EhcKBG5hbWUYASABKAlCA+BBBVIEbmFtZRImCgxkaXNwbGF5X25hbWUYAiABKAlCA+BBAlIL
ZGlzcGxheU5hbWUSRgodYXNzb2NpYXRlZF9zZXJ2aW5nX2NvbmZpZ19pZHMYBSADKAlCA+BB
A1IaYXNzb2NpYXRlZFNlcnZpbmdDb25maWdJZHMSVwoOc29sdXRpb25fdHlwZXMYBiADKA4y
KC5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5Tb2x1dGlvblR5cGVCBuBBAuBBBVINc29s
dXRpb25UeXBlcxJqChhzZWFyY2hfc29sdXRpb25fdXNlX2Nhc2UYByADKA4yMS5nb29nbGUu
Y2xvdWQucmV0YWlsLnYyYmV0YS5TZWFyY2hTb2x1dGlvblVzZUNhc2VSFXNlYXJjaFNvbHV0
aW9uVXNlQ2FzZTpx6kFuCh1yZXRhaWwuZ29vZ2xlYXBpcy5jb20vQ29udHJvbBJNcHJvamVj
dHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NhdGFsb2dzL3tjYXRhbG9nfS9j
b250cm9scy97Y29udHJvbH1CCQoHY29udHJvbELLAQoeY29tLmdvb2dsZS5jbG91ZC5yZXRh
aWwudjJiZXRhQgxDb250cm9sUHJvdG9QAVo2Y2xvdWQuZ29vZ2xlLmNvbS9nby9yZXRhaWwv
YXBpdjJiZXRhL3JldGFpbHBiO3JldGFpbHBiogIGUkVUQUlMqgIaR29vZ2xlLkNsb3VkLlJl
dGFpbC5WMkJldGHKAhpHb29nbGVcQ2xvdWRcUmV0YWlsXFYyYmV0YeoCHUdvb2dsZTo6Q2xv
dWQ6OlJldGFpbDo6VjJiZXRhSvcbCgYSBA4AYwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
MjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBW
ZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxl
IGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFp
biBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQACMKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADEK
CQoCAwMSAxUAOQoICgEIEgMXADcKCQoCCCUSAxcANwoICgEIEgMYAE0KCQoCCAsSAxgATQoI
CgEIEgMZACIKCQoCCAoSAxkAIgoICgEIEgMaAC0KCQoCCAgSAxoALQoICgEIEgMbADcKCQoC
CAESAxsANwoICgEIEgMcACQKCQoCCCQSAxwAJAoICgEIEgMdADcKCQoCCCkSAx0ANwoICgEI
EgMeADYKCQoCCC0SAx4ANgq7AQoCBAASBCMAYwEargEgQ29uZmlndXJlcyBkeW5hbWljIG1l
dGFkYXRhIHRoYXQgY2FuIGJlIGxpbmtlZCB0byBhCiBbU2VydmluZ0NvbmZpZ11bZ29vZ2xl
LmNsb3VkLnJldGFpbC52MmJldGEuU2VydmluZ0NvbmZpZ10gYW5kIGFmZmVjdCBzZWFyY2gK
IG9yIHJlY29tbWVuZGF0aW9uIHJlc3VsdHMgYXQgc2VydmluZyB0aW1lLgoKCgoDBAABEgMj
CA8KCwoDBAAHEgQkAicECg0KBQQAB50IEgQkAicECoYCCgQEAAgAEgQuAjkDGvcBIFRoZSBi
ZWhhdmlvci90eXBlIG9mIHRoZSBjb250cm9sCgogQSBiZWhhdmlvci90eXBlIG11c3QgYmUg
c3BlY2lmaWVkIG9uIGNyZWF0aW9uLiBUeXBlIGNhbm5vdCBiZSBjaGFuZ2VkIG9uY2UKIHNw
ZWNpZmllZCAoZS5nLiBBIFJ1bGUgY29udHJvbCB3aWxsIGFsd2F5cyBiZSBhIFJ1bGUgY29u
dHJvbC4pLiBBbgogSU5WQUxJRF9BUkdVTUVOVCB3aWxsIGJlIHJldHVybmVkIGlmIGVpdGhl
ciBjb25kaXRpb24gaXMgdmlvbGF0ZWQuCgoMCgUEAAgAARIDLggPCqUBCgQEAAIAEgMzBD8a
lwEgQSBmYWNldCBzcGVjaWZpY2F0aW9uIHRvIHBlcmZvcm0gZmFjZXRlZCBzZWFyY2guCgog
Tm90ZSB0aGF0IHRoaXMgZmllbGQgaXMgZGVwcmVjYXRlZCBhbmQgd2lsbCB0aHJvdyBOT1Rf
SU1QTEVNRU5URUQgaWYKIHVzZWQgZm9yIGNyZWF0aW5nIGEgY29udHJvbC4KCgwKBQQAAgAG
EgMzBBsKDAoFBAACAAESAzMcJgoMCgUEAAIAAxIDMykqCgwKBQQAAgAIEgMzKz4KDQoGBAAC
AAgDEgMzLD0KtAEKBAQAAgESAzgEEhqmASBBIHJ1bGUgY29udHJvbCAtIGEgY29uZGl0aW9u
LWFjdGlvbiBwYWlyLgogRW5hY3RzIGEgc2V0IGFjdGlvbiB3aGVuIHRoZSBjb25kaXRpb24g
aXMgdHJpZ2dlcmVkLgogRm9yIGV4YW1wbGU6IEJvb3N0ICJnU2hvZSIgd2hlbiBxdWVyeSBm
dWxsIG1hdGNoZXMgIlJ1bm5pbmcgU2hvZXMiLgoKDAoFBAACAQYSAzgECAoMCgUEAAIBARID
OAkNCgwKBQQAAgEDEgM4EBEKYwoEBAACAhIDPQI8GlYgSW1tdXRhYmxlLiBGdWxseSBxdWFs
aWZpZWQgbmFtZQogYHByb2plY3RzLyovbG9jYXRpb25zL2dsb2JhbC9jYXRhbG9ncy8qL2Nv
bnRyb2xzLypgCgoMCgUEAAICBRIDPQIICgwKBQQAAgIBEgM9CQ0KDAoFBAACAgMSAz0QEQoM
CgUEAAICCBIDPRI7Cg8KCAQAAgIInAgAEgM9EzoK2QEKBAQAAgMSA0MCQxrLASBSZXF1aXJl
ZC4gVGhlIGh1bWFuIHJlYWRhYmxlIGNvbnRyb2wgZGlzcGxheSBuYW1lLiBVc2VkIGluIFJl
dGFpbCBVSS4KCiBUaGlzIGZpZWxkIG11c3QgYmUgYSBVVEYtOCBlbmNvZGVkIHN0cmluZyB3
aXRoIGEgbGVuZ3RoIGxpbWl0IG9mIDEyOAogY2hhcmFjdGVycy4gT3RoZXJ3aXNlLCBhbiBJ
TlZBTElEX0FSR1VNRU5UIGVycm9yIGlzIHRocm93bi4KCgwKBQQAAgMFEgNDAggKDAoFBAAC
AwESA0MJFQoMCgUEAAIDAxIDQxgZCgwKBQQAAgMIEgNDGkIKDwoIBAACAwicCAASA0MbQQrZ
AgoEBAACBBIETQJOMhrKAiBPdXRwdXQgb25seS4gTGlzdCBvZiBbc2VydmluZwogY29uZmln
XVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5TZXJ2aW5nQ29uZmlnXSBpZHMgdGhhdCBh
cmUgYXNzb2NpYXRlZAogd2l0aCB0aGlzIGNvbnRyb2wgaW4gdGhlIHNhbWUKIFtDYXRhbG9n
XVtnb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5DYXRhbG9nXS4KCiBOb3RlIHRoZSBhc3Nv
Y2lhdGlvbiBpcyBtYW5hZ2VkIHZpYSB0aGUKIFtTZXJ2aW5nQ29uZmlnXVtnb29nbGUuY2xv
dWQucmV0YWlsLnYyYmV0YS5TZXJ2aW5nQ29uZmlnXSwgdGhpcyBpcyBhbgogb3V0cHV0IG9u
bHkgZGVub3JtYWxpemVkIHZpZXcuCgoMCgUEAAIEBBIDTQIKCgwKBQQAAgQFEgNNCxEKDAoF
BAACBAESA00SLwoMCgUEAAIEAxIDTTIzCgwKBQQAAgQIEgNOBjEKDwoIBAACBAicCAASA04H
MAr6AgoEBAACBRIEVgJZBBrrAiBSZXF1aXJlZC4gSW1tdXRhYmxlLiBUaGUgc29sdXRpb24g
dHlwZXMgdGhhdCB0aGUgY29udHJvbCBpcyB1c2VkIGZvci4KIEN1cnJlbnRseSB3ZSBzdXBw
b3J0IHNldHRpbmcgb25seSBvbmUgdHlwZSBvZiBzb2x1dGlvbiBhdCBjcmVhdGlvbiB0aW1l
LgoKIE9ubHkgYFNPTFVUSU9OX1RZUEVfU0VBUkNIYCB2YWx1ZSBpcyBzdXBwb3J0ZWQgYXQg
dGhlIG1vbWVudC4KIElmIG5vIHNvbHV0aW9uIHR5cGUgaXMgcHJvdmlkZWQgYXQgY3JlYXRp
b24gdGltZSwgd2lsbCBkZWZhdWx0IHRvCiBbU09MVVRJT05fVFlQRV9TRUFSQ0hdW2dvb2ds
ZS5jbG91ZC5yZXRhaWwudjJiZXRhLlNvbHV0aW9uVHlwZS5TT0xVVElPTl9UWVBFX1NFQVJD
SF0uCgoMCgUEAAIFBBIDVgIKCgwKBQQAAgUGEgNWCxcKDAoFBAACBQESA1YYJgoMCgUEAAIF
AxIDVikqCg0KBQQAAgUIEgRWK1kDCg8KCAQAAgUInAgAEgNXBCoKDwoIBAACBQicCAESA1gE
KwreAgoEBAACBhIDYgI+GtACIFNwZWNpZmllcyB0aGUgdXNlIGNhc2UgZm9yIHRoZSBjb250
cm9sLgogQWZmZWN0cyB3aGF0IGNvbmRpdGlvbiBmaWVsZHMgY2FuIGJlIHNldC4KIE9ubHkg
c2V0dGFibGUgYnkgc2VhcmNoIGNvbnRyb2xzLgogV2lsbCBkZWZhdWx0IHRvCiBbU0VBUkNI
X1NPTFVUSU9OX1VTRV9DQVNFX1NFQVJDSF1bZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEu
U2VhcmNoU29sdXRpb25Vc2VDYXNlLlNFQVJDSF9TT0xVVElPTl9VU0VfQ0FTRV9TRUFSQ0hd
CiBpZiBub3Qgc3BlY2lmaWVkLiBDdXJyZW50bHkgb25seSBhbGxvdyBvbmUgc2VhcmNoX3Nv
bHV0aW9uX3VzZV9jYXNlIHBlcgogY29udHJvbC4KCgwKBQQAAgYEEgNiAgoKDAoFBAACBgYS
A2ILIAoMCgUEAAIGARIDYiE5CgwKBQQAAgYDEgNiPD1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2beta::Control::Control ===
    # Fields for Control
    # Field: facet_spec Type: 11 (.google.cloud.retail.v2beta.SearchRequest.FacetSpec)
    # Field: rule Type: 11 (.google.cloud.retail.v2beta.Rule)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: associated_serving_config_ids Type: 9 ()
    # Field: solution_types Type: 14 (.google.cloud.retail.v2beta.SolutionType)
    # Field: search_solution_use_case Type: 14 (.google.cloud.retail.v2beta.SearchSolutionUseCase)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2beta::Control - Compiled Protocol Buffers messages for google/cloud/retail/v2beta/control.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2beta::Control;

    my $msg = Google::Cloud::Retail::V2beta::Control::Control->new({
        facet_spec => $facet_spec,
        rule => $rule,
        name => $name,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->facet_spec();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2beta::Control::Control->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2beta/control.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2beta::Control::Control

Configures dynamic metadata that can be linked to a
[ServingConfig][google.cloud.retail.v2beta.ServingConfig] and affect search
or recommendation results at serving time.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->facet_spec() >> / C<< $msg->facet_spec($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::SearchService::SearchRequest::FacetSpec>)

A facet specification to perform faceted search.

Note that this field is deprecated and will throw NOT_IMPLEMENTED if
used for creating a control.

=item * C<< $msg->rule() >> / C<< $msg->rule($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::Common::Rule>)

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
config][google.cloud.retail.v2beta.ServingConfig] ids that are associated
with this control in the same
[Catalog][google.cloud.retail.v2beta.Catalog].

Note the association is managed via the
[ServingConfig][google.cloud.retail.v2beta.ServingConfig], this is an
output only denormalized view.

=item * C<< $msg->solution_types() >> / C<< $msg->solution_types($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2beta::SolutionType>)

Required. Immutable. The solution types that the control is used for.
Currently we support setting only one type of solution at creation time.

Only `SOLUTION_TYPE_SEARCH` value is supported at the moment.
If no solution type is provided at creation time, will default to
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2beta.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->search_solution_use_case() >> / C<< $msg->search_solution_use_case($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2beta::SearchSolutionUseCase>)

Specifies the use case for the control.
Affects what condition fields can be set.
Only settable by search controls.
Will default to
[SEARCH_SOLUTION_USE_CASE_SEARCH][google.cloud.retail.v2beta.SearchSolutionUseCase.SEARCH_SOLUTION_USE_CASE_SEARCH]
if not specified. Currently only allow one search_solution_use_case per
control.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2beta::Control::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
