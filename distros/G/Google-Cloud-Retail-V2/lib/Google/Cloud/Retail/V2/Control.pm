package Google::Cloud::Retail::V2::Control;

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
    eval { require Google::Cloud::Retail::V2::Common };
    my $descriptor_b64 = <<'EOF';
CiRnb29nbGUvY2xvdWQvcmV0YWlsL3YyL2NvbnRyb2wucHJvdG8SFmdvb2dsZS5jbG91ZC5y
ZXRhaWwudjIaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkv
cmVzb3VyY2UucHJvdG8aI2dvb2dsZS9jbG91ZC9yZXRhaWwvdjIvY29tbW9uLnByb3RvIoEE
CgdDb250cm9sEjIKBHJ1bGUYBCABKAsyHC5nb29nbGUuY2xvdWQucmV0YWlsLnYyLlJ1bGVI
AFIEcnVsZRIXCgRuYW1lGAEgASgJQgPgQQVSBG5hbWUSJgoMZGlzcGxheV9uYW1lGAIgASgJ
QgPgQQJSC2Rpc3BsYXlOYW1lEkYKHWFzc29jaWF0ZWRfc2VydmluZ19jb25maWdfaWRzGAUg
AygJQgPgQQNSGmFzc29jaWF0ZWRTZXJ2aW5nQ29uZmlnSWRzElMKDnNvbHV0aW9uX3R5cGVz
GAYgAygOMiQuZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5Tb2x1dGlvblR5cGVCBuBBAuBBBVIN
c29sdXRpb25UeXBlcxJmChhzZWFyY2hfc29sdXRpb25fdXNlX2Nhc2UYByADKA4yLS5nb29n
bGUuY2xvdWQucmV0YWlsLnYyLlNlYXJjaFNvbHV0aW9uVXNlQ2FzZVIVc2VhcmNoU29sdXRp
b25Vc2VDYXNlOnHqQW4KHXJldGFpbC5nb29nbGVhcGlzLmNvbS9Db250cm9sEk1wcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY2F0YWxvZ3Mve2NhdGFsb2d9L2Nv
bnRyb2xzL3tjb250cm9sfUIJCgdjb250cm9sQrcBChpjb20uZ29vZ2xlLmNsb3VkLnJldGFp
bC52MkIMQ29udHJvbFByb3RvUAFaMmNsb3VkLmdvb2dsZS5jb20vZ28vcmV0YWlsL2FwaXYy
L3JldGFpbHBiO3JldGFpbHBiogIGUkVUQUlMqgIWR29vZ2xlLkNsb3VkLlJldGFpbC5WMsoC
Fkdvb2dsZVxDbG91ZFxSZXRhaWxcVjLqAhlHb29nbGU6OkNsb3VkOjpSZXRhaWw6OlYySuQZ
CgYSBA4AWwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB8K
CQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUAC0KCAoBCBIDFgAzCgkKAgglEgMWADMK
CAoBCBIDFwBJCgkKAggLEgMXAEkKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQAtCgkK
AggIEgMZAC0KCAoBCBIDGgAzCgkKAggBEgMaADMKCAoBCBIDGwAkCgkKAggkEgMbACQKCAoB
CBIDHAAzCgkKAggpEgMcADMKCAoBCBIDHQAyCgkKAggtEgMdADIKtwEKAgQAEgQiAFsBGqoB
IENvbmZpZ3VyZXMgZHluYW1pYyBtZXRhZGF0YSB0aGF0IGNhbiBiZSBsaW5rZWQgdG8gYQog
W1NlcnZpbmdDb25maWddW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIuU2VydmluZ0NvbmZpZ10g
YW5kIGFmZmVjdCBzZWFyY2ggb3IKIHJlY29tbWVuZGF0aW9uIHJlc3VsdHMgYXQgc2Vydmlu
ZyB0aW1lLgoKCgoDBAABEgMiCA8KCwoDBAAHEgQjAiYECg0KBQQAB50IEgQjAiYECoYCCgQE
AAgAEgQtAjIDGvcBIFRoZSBiZWhhdmlvci90eXBlIG9mIHRoZSBjb250cm9sCgogQSBiZWhh
dmlvci90eXBlIG11c3QgYmUgc3BlY2lmaWVkIG9uIGNyZWF0aW9uLiBUeXBlIGNhbm5vdCBi
ZSBjaGFuZ2VkIG9uY2UKIHNwZWNpZmllZCAoZS5nLiBBIFJ1bGUgY29udHJvbCB3aWxsIGFs
d2F5cyBiZSBhIFJ1bGUgY29udHJvbC4pLiBBbgogSU5WQUxJRF9BUkdVTUVOVCB3aWxsIGJl
IHJldHVybmVkIGlmIGVpdGhlciBjb25kaXRpb24gaXMgdmlvbGF0ZWQuCgoMCgUEAAgAARID
LQgPCrQBCgQEAAIAEgMxBBIapgEgQSBydWxlIGNvbnRyb2wgLSBhIGNvbmRpdGlvbi1hY3Rp
b24gcGFpci4KIEVuYWN0cyBhIHNldCBhY3Rpb24gd2hlbiB0aGUgY29uZGl0aW9uIGlzIHRy
aWdnZXJlZC4KIEZvciBleGFtcGxlOiBCb29zdCAiZ1Nob2UiIHdoZW4gcXVlcnkgZnVsbCBt
YXRjaGVzICJSdW5uaW5nIFNob2VzIi4KCgwKBQQAAgAGEgMxBAgKDAoFBAACAAESAzEJDQoM
CgUEAAIAAxIDMRARCmMKBAQAAgESAzYCPBpWIEltbXV0YWJsZS4gRnVsbHkgcXVhbGlmaWVk
IG5hbWUKIGBwcm9qZWN0cy8qL2xvY2F0aW9ucy9nbG9iYWwvY2F0YWxvZ3MvKi9jb250cm9s
cy8qYAoKDAoFBAACAQUSAzYCCAoMCgUEAAIBARIDNgkNCgwKBQQAAgEDEgM2EBEKDAoFBAAC
AQgSAzYSOwoPCggEAAIBCJwIABIDNhM6CtkBCgQEAAICEgM8AkMaywEgUmVxdWlyZWQuIFRo
ZSBodW1hbiByZWFkYWJsZSBjb250cm9sIGRpc3BsYXkgbmFtZS4gVXNlZCBpbiBSZXRhaWwg
VUkuCgogVGhpcyBmaWVsZCBtdXN0IGJlIGEgVVRGLTggZW5jb2RlZCBzdHJpbmcgd2l0aCBh
IGxlbmd0aCBsaW1pdCBvZiAxMjgKIGNoYXJhY3RlcnMuIE90aGVyd2lzZSwgYW4gSU5WQUxJ
RF9BUkdVTUVOVCBlcnJvciBpcyB0aHJvd24uCgoMCgUEAAICBRIDPAIICgwKBQQAAgIBEgM8
CRUKDAoFBAACAgMSAzwYGQoMCgUEAAICCBIDPBpCCg8KCAQAAgIInAgAEgM8G0EKzAIKBAQA
AgMSBEUCRjIavQIgT3V0cHV0IG9ubHkuIExpc3Qgb2YgW3NlcnZpbmcgY29uZmlnXVtnb29n
bGUuY2xvdWQucmV0YWlsLnYyLlNlcnZpbmdDb25maWddCiBpZHMgdGhhdCBhcmUgYXNzb2Np
YXRlZCB3aXRoIHRoaXMgY29udHJvbCBpbiB0aGUgc2FtZQogW0NhdGFsb2ddW2dvb2dsZS5j
bG91ZC5yZXRhaWwudjIuQ2F0YWxvZ10uCgogTm90ZSB0aGUgYXNzb2NpYXRpb24gaXMgbWFu
YWdlZCB2aWEgdGhlCiBbU2VydmluZ0NvbmZpZ11bZ29vZ2xlLmNsb3VkLnJldGFpbC52Mi5T
ZXJ2aW5nQ29uZmlnXSwgdGhpcyBpcyBhbiBvdXRwdXQKIG9ubHkgZGVub3JtYWxpemVkIHZp
ZXcuCgoMCgUEAAIDBBIDRQIKCgwKBQQAAgMFEgNFCxEKDAoFBAACAwESA0USLwoMCgUEAAID
AxIDRTIzCgwKBQQAAgMIEgNGBjEKDwoIBAACAwicCAASA0YHMAr2AgoEBAACBBIETgJRBBrn
AiBSZXF1aXJlZC4gSW1tdXRhYmxlLiBUaGUgc29sdXRpb24gdHlwZXMgdGhhdCB0aGUgY29u
dHJvbCBpcyB1c2VkIGZvci4KIEN1cnJlbnRseSB3ZSBzdXBwb3J0IHNldHRpbmcgb25seSBv
bmUgdHlwZSBvZiBzb2x1dGlvbiBhdCBjcmVhdGlvbiB0aW1lLgoKIE9ubHkgYFNPTFVUSU9O
X1RZUEVfU0VBUkNIYCB2YWx1ZSBpcyBzdXBwb3J0ZWQgYXQgdGhlIG1vbWVudC4KIElmIG5v
IHNvbHV0aW9uIHR5cGUgaXMgcHJvdmlkZWQgYXQgY3JlYXRpb24gdGltZSwgd2lsbCBkZWZh
dWx0IHRvCiBbU09MVVRJT05fVFlQRV9TRUFSQ0hdW2dvb2dsZS5jbG91ZC5yZXRhaWwudjIu
U29sdXRpb25UeXBlLlNPTFVUSU9OX1RZUEVfU0VBUkNIXS4KCgwKBQQAAgQEEgNOAgoKDAoF
BAACBAYSA04LFwoMCgUEAAIEARIDThgmCgwKBQQAAgQDEgNOKSoKDQoFBAACBAgSBE4rUQMK
DwoIBAACBAicCAASA08EKgoPCggEAAIECJwIARIDUAQrCtoCCgQEAAIFEgNaAj4azAIgU3Bl
Y2lmaWVzIHRoZSB1c2UgY2FzZSBmb3IgdGhlIGNvbnRyb2wuCiBBZmZlY3RzIHdoYXQgY29u
ZGl0aW9uIGZpZWxkcyBjYW4gYmUgc2V0LgogT25seSBzZXR0YWJsZSBieSBzZWFyY2ggY29u
dHJvbHMuCiBXaWxsIGRlZmF1bHQgdG8KIFtTRUFSQ0hfU09MVVRJT05fVVNFX0NBU0VfU0VB
UkNIXVtnb29nbGUuY2xvdWQucmV0YWlsLnYyLlNlYXJjaFNvbHV0aW9uVXNlQ2FzZS5TRUFS
Q0hfU09MVVRJT05fVVNFX0NBU0VfU0VBUkNIXQogaWYgbm90IHNwZWNpZmllZC4gQ3VycmVu
dGx5IG9ubHkgYWxsb3cgb25lIHNlYXJjaF9zb2x1dGlvbl91c2VfY2FzZSBwZXIKIGNvbnRy
b2wuCgoMCgUEAAIFBBIDWgIKCgwKBQQAAgUGEgNaCyAKDAoFBAACBQESA1ohOQoMCgUEAAIF
AxIDWjw9YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2::Control::Control ===
    # Fields for Control
    # Field: rule Type: 11 (.google.cloud.retail.v2.Rule)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: associated_serving_config_ids Type: 9 ()
    # Field: solution_types Type: 14 (.google.cloud.retail.v2.SolutionType)
    # Field: search_solution_use_case Type: 14 (.google.cloud.retail.v2.SearchSolutionUseCase)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2::Control - Compiled Protocol Buffers messages for google/cloud/retail/v2/control.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2::Control;

    my $msg = Google::Cloud::Retail::V2::Control::Control->new({
        rule => $rule,
        name => $name,
        display_name => $display_name,
        associated_serving_config_ids => $associated_serving_config_ids,
    });

    # Read or update a field
    my $val = $msg->rule();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2::Control::Control->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2/control.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2::Control::Control

Configures dynamic metadata that can be linked to a
[ServingConfig][google.cloud.retail.v2.ServingConfig] and affect search or
recommendation results at serving time.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rule() >> / C<< $msg->rule($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2::Common::Rule>)

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

Output only. List of [serving config][google.cloud.retail.v2.ServingConfig]
ids that are associated with this control in the same
[Catalog][google.cloud.retail.v2.Catalog].

Note the association is managed via the
[ServingConfig][google.cloud.retail.v2.ServingConfig], this is an output
only denormalized view.

=item * C<< $msg->solution_types() >> / C<< $msg->solution_types($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2::SolutionType>)

Required. Immutable. The solution types that the control is used for.
Currently we support setting only one type of solution at creation time.

Only `SOLUTION_TYPE_SEARCH` value is supported at the moment.
If no solution type is provided at creation time, will default to
[SOLUTION_TYPE_SEARCH][google.cloud.retail.v2.SolutionType.SOLUTION_TYPE_SEARCH].

=item * C<< $msg->search_solution_use_case() >> / C<< $msg->search_solution_use_case($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2::SearchSolutionUseCase>)

Specifies the use case for the control.
Affects what condition fields can be set.
Only settable by search controls.
Will default to
[SEARCH_SOLUTION_USE_CASE_SEARCH][google.cloud.retail.v2.SearchSolutionUseCase.SEARCH_SOLUTION_USE_CASE_SEARCH]
if not specified. Currently only allow one search_solution_use_case per
control.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2::Control::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
