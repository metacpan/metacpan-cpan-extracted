package Google::Cloud::Talent::V4beta1::Tenant;

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
Cihnb29nbGUvY2xvdWQvdGFsZW50L3Y0YmV0YTEvdGVuYW50LnByb3RvEhtnb29nbGUuY2xv
dWQudGFsZW50LnY0YmV0YTEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdv
b2dsZS9hcGkvcmVzb3VyY2UucHJvdG8iigMKBlRlbmFudBISCgRuYW1lGAEgASgJUgRuYW1l
EiQKC2V4dGVybmFsX2lkGAIgASgJQgPgQQJSCmV4dGVybmFsSWQSUAoKdXNhZ2VfdHlwZRgD
IAEoDjIxLmdvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5UZW5hbnQuRGF0YVVzYWdlVHlw
ZVIJdXNhZ2VUeXBlEl4KLGtleXdvcmRfc2VhcmNoYWJsZV9wcm9maWxlX2N1c3RvbV9hdHRy
aWJ1dGVzGAQgAygJUihrZXl3b3JkU2VhcmNoYWJsZVByb2ZpbGVDdXN0b21BdHRyaWJ1dGVz
Ik4KDURhdGFVc2FnZVR5cGUSHwobREFUQV9VU0FHRV9UWVBFX1VOU1BFQ0lGSUVEEAASDgoK
QUdHUkVHQVRFRBABEgwKCElTT0xBVEVEEAI6ROpBQQoaam9icy5nb29nbGVhcGlzLmNvbS9U
ZW5hbnQSI3Byb2plY3RzL3twcm9qZWN0fS90ZW5hbnRzL3t0ZW5hbnR9QncKH2NvbS5nb29n
bGUuY2xvdWQudGFsZW50LnY0YmV0YTFCE1RlbmFudFJlc291cmNlUHJvdG9QAVo3Y2xvdWQu
Z29vZ2xlLmNvbS9nby90YWxlbnQvYXBpdjRiZXRhMS90YWxlbnRwYjt0YWxlbnRwYqICA0NU
U0rpFQoGEgQOAFIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAkCgkKAgMAEgMSACkKCQoCAwESAxMAIwoICgEIEgMVAE4KCQoCCAsSAxUATgoICgEIEgMW
ACIKCQoCCAoSAxYAIgoICgEIEgMXADQKCQoCCAgSAxcANAoICgEIEgMYADgKCQoCCAESAxgA
OAoICgEIEgMZACEKCQoCCCQSAxkAIQqKAgoCBAASBB8AUgEa/QEgQSBUZW5hbnQgcmVzb3Vy
Y2UgcmVwcmVzZW50cyBhIHRlbmFudCBpbiB0aGUgc2VydmljZS4gQSB0ZW5hbnQgaXMgYSBn
cm91cCBvcgogZW50aXR5IHRoYXQgc2hhcmVzIGNvbW1vbiBhY2Nlc3Mgd2l0aCBzcGVjaWZp
YyBwcml2aWxlZ2VzIGZvciByZXNvdXJjZXMgbGlrZQogcHJvZmlsZXMuIEN1c3RvbWVyIG1h
eSBjcmVhdGUgbXVsdGlwbGUgdGVuYW50cyB0byBwcm92aWRlIGRhdGEgaXNvbGF0aW9uIGZv
cgogZGlmZmVyZW50IGdyb3Vwcy4KCgoKAwQAARIDHwgOCgsKAwQABxIEIAIjBAoNCgUEAAed
CBIEIAIjBApPCgQEAAQAEgQmAjEDGkEgRW51bSB0aGF0IHJlcHJlc2VudHMgaG93IHVzZXIg
ZGF0YSBvd25lZCBieSB0aGUgdGVuYW50IGlzIHVzZWQuCgoMCgUEAAQAARIDJgcUCh8KBgQA
BAACABIDKAQkGhAgRGVmYXVsdCB2YWx1ZS4KCg4KBwQABAACAAESAygEHwoOCgcEAAQAAgAC
EgMoIiMKbAoGBAAEAAIBEgMsBBMaXSBEYXRhIG93bmVkIGJ5IHRoaXMgdGVuYW50IGlzIHVz
ZWQgdG8gaW1wcm92ZSBzZWFyY2gvcmVjb21tZW5kYXRpb24KIHF1YWxpdHkgYWNyb3NzIHRl
bmFudHMuCgoOCgcEAAQAAgEBEgMsBA4KDgoHBAAEAAIBAhIDLBESCnIKBgQABAACAhIDMAQR
GmMgRGF0YSBvd25lZCBieSB0aGlzIHRlbmFudCBpcyB1c2VkIHRvIGltcHJvdmUgc2VhcmNo
L3JlY29tbWVuZGF0aW9uCiBxdWFsaXR5IGZvciB0aGlzIHRlbmFudCBvbmx5LgoKDgoHBAAE
AAICARIDMAQMCg4KBwQABAACAgISAzAPEArzAQoEBAACABIDOgISGuUBIFJlcXVpcmVkIGR1
cmluZyB0ZW5hbnQgdXBkYXRlLgoKIFRoZSByZXNvdXJjZSBuYW1lIGZvciBhIHRlbmFudC4g
VGhpcyBpcyBnZW5lcmF0ZWQgYnkgdGhlIHNlcnZpY2Ugd2hlbiBhCiB0ZW5hbnQgaXMgY3Jl
YXRlZC4KCiBUaGUgZm9ybWF0IGlzICJwcm9qZWN0cy97cHJvamVjdF9pZH0vdGVuYW50cy97
dGVuYW50X2lkfSIsIGZvciBleGFtcGxlLAogInByb2plY3RzL2Zvby90ZW5hbnRzL2JhciIu
CgoMCgUEAAIABRIDOgIICgwKBQQAAgABEgM6CQ0KDAoFBAACAAMSAzoQEQqSAQoEBAACARID
QAJCGoQBIFJlcXVpcmVkLiBDbGllbnQgc2lkZSB0ZW5hbnQgaWRlbnRpZmllciwgdXNlZCB0
byB1bmlxdWVseSBpZGVudGlmeSB0aGUKIHRlbmFudC4KCiBUaGUgbWF4aW11bSBudW1iZXIg
b2YgYWxsb3dlZCBjaGFyYWN0ZXJzIGlzIDI1NS4KCgwKBQQAAgEFEgNAAggKDAoFBAACAQES
A0AJFAoMCgUEAAIBAxIDQBcYCgwKBQQAAgEIEgNAGUEKDwoIBAACAQicCAASA0AaQAr6AQoE
BAACAhIDSAIfGuwBIEluZGljYXRlcyB3aGV0aGVyIGRhdGEgb3duZWQgYnkgdGhpcyB0ZW5h
bnQgbWF5IGJlIHVzZWQgdG8gcHJvdmlkZSBwcm9kdWN0CiBpbXByb3ZlbWVudHMgYWNyb3Nz
IG90aGVyIHRlbmFudHMuCgogRGVmYXVsdHMgYmVoYXZpb3IgaXMKIFtEYXRhVXNhZ2VUeXBl
LklTT0xBVEVEXVtnb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuVGVuYW50LkRhdGFVc2Fn
ZVR5cGUuSVNPTEFURURdCiBpZiBpdCdzIHVuc2V0LgoKDAoFBAACAgYSA0gCDwoMCgUEAAIC
ARIDSBAaCgwKBQQAAgIDEgNIHR4KwgMKBAQAAgMSA1ECQxq0AyBBIGxpc3Qgb2Yga2V5cyBv
ZiBmaWx0ZXJhYmxlCiBbUHJvZmlsZS5jdXN0b21fYXR0cmlidXRlc11bZ29vZ2xlLmNsb3Vk
LnRhbGVudC52NGJldGExLlByb2ZpbGUuY3VzdG9tX2F0dHJpYnV0ZXNdLAogd2hvc2UgY29y
cmVzcG9uZGluZyBgc3RyaW5nX3ZhbHVlc2AgYXJlIHVzZWQgaW4ga2V5d29yZCBzZWFyY2hl
cy4gUHJvZmlsZXMKIHdpdGggYHN0cmluZ192YWx1ZXNgIHVuZGVyIHRoZXNlIHNwZWNpZmll
ZCBmaWVsZCBrZXlzIGFyZSByZXR1cm5lZCBpZiBhbnkKIG9mIHRoZSB2YWx1ZXMgbWF0Y2gg
dGhlIHNlYXJjaCBrZXl3b3JkLiBDdXN0b20gZmllbGQgdmFsdWVzIHdpdGgKIHBhcmVudGhl
c2lzLCBicmFja2V0cyBhbmQgc3BlY2lhbCBzeW1ib2xzIGFyZSBub3Qgc2VhcmNoYWJsZSBh
cy1pcywKIGFuZCBtdXN0IGJlIHN1cnJvdW5kZWQgYnkgcXVvdGVzLgoKDAoFBAACAwQSA1EC
CgoMCgUEAAIDBRIDUQsRCgwKBQQAAgMBEgNREj4KDAoFBAACAwMSA1FBQmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Talent::V4beta1::Tenant::Tenant ===
    # Fields for Tenant
    # Field: name Type: 9 ()
    # Field: external_id Type: 9 ()
    # Field: usage_type Type: 14 (.google.cloud.talent.v4beta1.Tenant.DataUsageType)
    # Field: keyword_searchable_profile_custom_attributes Type: 9 ()

# Enum: Tenant::DataUsageType
our $Tenant_DATA_USAGE_TYPE_UNSPECIFIED = 0;
our $Tenant_AGGREGATED = 1;
our $Tenant_ISOLATED = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Talent::V4beta1::Tenant - Compiled Protocol Buffers messages for google/cloud/talent/v4beta1/tenant.proto

=head1 SYNOPSIS

    use Google::Cloud::Talent::V4beta1::Tenant;

    my $msg = Google::Cloud::Talent::V4beta1::Tenant::Tenant->new({
        name => $name,
        external_id => $external_id,
        usage_type => $usage_type,
        keyword_searchable_profile_custom_attributes => $keyword_searchable_profile_custom_attributes,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Talent::V4beta1::Tenant::Tenant->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/talent/v4beta1/tenant.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Talent::V4beta1::Tenant::Tenant

A Tenant resource represents a tenant in the service. A tenant is a group or
entity that shares common access with specific privileges for resources like
profiles. Customer may create multiple tenants to provide data isolation for
different groups.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required during tenant update.

The resource name for a tenant. This is generated by the service when a
tenant is created.

The format is "projects/{project_id}/tenants/{tenant_id}", for example,
"projects/foo/tenants/bar".

=item * C<< $msg->external_id() >> / C<< $msg->external_id($value) >>

Type: C<String>

Required. Client side tenant identifier, used to uniquely identify the
tenant.

The maximum number of allowed characters is 255.

=item * C<< $msg->usage_type() >> / C<< $msg->usage_type($value) >>

Type: C<Enum> (L<Google::Cloud::Talent::V4beta1::Tenant::DataUsageType>)

Indicates whether data owned by this tenant may be used to provide product
improvements across other tenants.

Defaults behavior is
[DataUsageType.ISOLATED][google.cloud.talent.v4beta1.Tenant.DataUsageType.ISOLATED]
if it's unset.

=item * C<< $msg->keyword_searchable_profile_custom_attributes() >> / C<< $msg->keyword_searchable_profile_custom_attributes($value) >>

Type: C<String>

A list of keys of filterable
[Profile.custom_attributes][google.cloud.talent.v4beta1.Profile.custom_attributes],
whose corresponding `string_values` are used in keyword searches. Profiles
with `string_values` under these specified field keys are returned if any
of the values match the search keyword. Custom field values with
parenthesis, brackets and special symbols are not searchable as-is,
and must be surrounded by quotes.

=back

=head3 Enum: Tenant::DataUsageType

=over 4

=item * C<DATA_USAGE_TYPE_UNSPECIFIED> => C<0>

=item * C<AGGREGATED> => C<1>

=item * C<ISOLATED> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Talent::V4beta1::Tenant::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
