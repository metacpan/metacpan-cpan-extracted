package Google::Cloud::Securitycenter::V1::ValuedResource;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvdmFsdWVkX3Jlc291cmNlLnByb3Rv
Eh5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEaGWdvb2dsZS9hcGkvcmVzb3VyY2Uu
cHJvdG8iugUKDlZhbHVlZFJlc291cmNlEhIKBG5hbWUYASABKAlSBG5hbWUSGgoIcmVzb3Vy
Y2UYAiABKAlSCHJlc291cmNlEiMKDXJlc291cmNlX3R5cGUYAyABKAlSDHJlc291cmNlVHlw
ZRIhCgxkaXNwbGF5X25hbWUYBCABKAlSC2Rpc3BsYXlOYW1lEmMKDnJlc291cmNlX3ZhbHVl
GAUgASgOMjwuZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxLlZhbHVlZFJlc291cmNl
LlJlc291cmNlVmFsdWVSDXJlc291cmNlVmFsdWUSIwoNZXhwb3NlZF9zY29yZRgGIAEoAVIM
ZXhwb3NlZFNjb3JlEnoKG3Jlc291cmNlX3ZhbHVlX2NvbmZpZ3NfdXNlZBgHIAMoCzI7Lmdv
b2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MS5SZXNvdXJjZVZhbHVlQ29uZmlnTWV0YWRh
dGFSGHJlc291cmNlVmFsdWVDb25maWdzVXNlZCJ7Cg1SZXNvdXJjZVZhbHVlEh4KGlJFU09V
UkNFX1ZBTFVFX1VOU1BFQ0lGSUVEEAASFgoSUkVTT1VSQ0VfVkFMVUVfTE9XEAESGQoVUkVT
T1VSQ0VfVkFMVUVfTUVESVVNEAISFwoTUkVTT1VSQ0VfVkFMVUVfSElHSBADOqwB6kGoAQos
c2VjdXJpdHljZW50ZXIuZ29vZ2xlYXBpcy5jb20vVmFsdWVkUmVzb3VyY2USV29yZ2FuaXph
dGlvbnMve29yZ2FuaXphdGlvbn0vc2ltdWxhdGlvbnMve3NpbXVsYXRpb259L3ZhbHVlZFJl
c291cmNlcy97dmFsdWVkX3Jlc291cmNlfSoPdmFsdWVkUmVzb3VyY2VzMg52YWx1ZWRSZXNv
dXJjZSIxChtSZXNvdXJjZVZhbHVlQ29uZmlnTWV0YWRhdGESEgoEbmFtZRgBIAEoCVIEbmFt
ZULtAQoiY29tLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MUITVmFsdWVkUmVzb3Vy
Y2VQcm90b1ABWkpjbG91ZC5nb29nbGUuY29tL2dvL3NlY3VyaXR5Y2VudGVyL2FwaXYxL3Nl
Y3VyaXR5Y2VudGVycGI7c2VjdXJpdHljZW50ZXJwYqoCHkdvb2dsZS5DbG91ZC5TZWN1cml0
eUNlbnRlci5WMcoCHkdvb2dsZVxDbG91ZFxTZWN1cml0eUNlbnRlclxWMeoCIUdvb2dsZTo6
Q2xvdWQ6OlNlY3VyaXR5Q2VudGVyOjpWMUqvEwoGEgQOAFcBCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAnCgkKAgMAEgMSACMKCAoBCBIDFAA7CgkKAggl
EgMUADsKCAoBCBIDFQBhCgkKAggLEgMVAGEKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBID
FwA0CgkKAggIEgMXADQKCAoBCBIDGAA7CgkKAggBEgMYADsKCAoBCBIDGQA7CgkKAggpEgMZ
ADsKCAoBCBIDGgA6CgkKAggtEgMaADoKTAoCBAASBB0AUQEaQCBBIHJlc291cmNlIHRoYXQg
aXMgZGV0ZXJtaW5lZCB0byBoYXZlIHZhbHVlIHRvIGEgdXNlcidzIHN5c3RlbQoKCgoDBAAB
EgMdCBYKCwoDBAAHEgQeAiMECg0KBQQAB50IEgQeAiMECi0KBAQABAASBCYCMgMaHyBIb3cg
dmFsdWFibGUgdGhlIHJlc291cmNlIGlzLgoKDAoFBAAEAAESAyYHFAo0CgYEAAQAAgASAygE
IxolIFRoZSByZXNvdXJjZSB2YWx1ZSBpc24ndCBzcGVjaWZpZWQuCgoOCgcEAAQAAgABEgMo
BB4KDgoHBAAEAAIAAhIDKCEiCi4KBgQABAACARIDKwQbGh8gVGhpcyBpcyBhIGxvdy12YWx1
ZSByZXNvdXJjZS4KCg4KBwQABAACAQESAysEFgoOCgcEAAQAAgECEgMrGRoKMQoGBAAEAAIC
EgMuBB4aIiBUaGlzIGlzIGEgbWVkaXVtLXZhbHVlIHJlc291cmNlLgoKDgoHBAAEAAICARID
LgQZCg4KBwQABAACAgISAy4cHQovCgYEAAQAAgMSAzEEHBogIFRoaXMgaXMgYSBoaWdoLXZh
bHVlIHJlc291cmNlLgoKDgoHBAAEAAIDARIDMQQXCg4KBwQABAACAwISAzEaGwpzCgQEAAIA
EgM3AhIaZiBWYWx1ZWQgcmVzb3VyY2UgbmFtZSwgZm9yIGV4YW1wbGUsCiAgZS5nLjoKICBg
b3JnYW5pemF0aW9ucy8xMjMvc2ltdWxhdGlvbnMvNDU2L3ZhbHVlZFJlc291cmNlcy83ODlg
CgoMCgUEAAIABRIDNwIICgwKBQQAAgABEgM3CQ0KDAoFBAACAAMSAzcQEQqKAQoEBAACARID
PQIWGn0gVGhlCiBbZnVsbCByZXNvdXJjZQogbmFtZV0oaHR0cHM6Ly9jbG91ZC5nb29nbGUu
Y29tL2FwaXMvZGVzaWduL3Jlc291cmNlX25hbWVzI2Z1bGxfcmVzb3VyY2VfbmFtZSkKIG9m
IHRoZSB2YWx1ZWQgcmVzb3VyY2UuCgoMCgUEAAIBBRIDPQIICgwKBQQAAgEBEgM9CREKDAoF
BAACAQMSAz0UFQqBAQoEBAACAhIDQgIbGnQgVGhlIFtyZXNvdXJjZQogdHlwZV0oaHR0cHM6
Ly9jbG91ZC5nb29nbGUuY29tL2Fzc2V0LWludmVudG9yeS9kb2NzL3N1cHBvcnRlZC1hc3Nl
dC10eXBlcykKIG9mIHRoZSB2YWx1ZWQgcmVzb3VyY2UuCgoMCgUEAAICBRIDQgIICgwKBQQA
AgIBEgNCCRYKDAoFBAACAgMSA0IZGgo6CgQEAAIDEgNFAhoaLSBIdW1hbi1yZWFkYWJsZSBu
YW1lIG9mIHRoZSB2YWx1ZWQgcmVzb3VyY2UuCgoMCgUEAAIDBRIDRQIICgwKBQQAAgMBEgNF
CRUKDAoFBAACAwMSA0UYGQotCgQEAAIEEgNIAiMaICBIb3cgdmFsdWFibGUgdGhpcyByZXNv
dXJjZSBpcy4KCgwKBQQAAgQGEgNIAg8KDAoFBAACBAESA0gQHgoMCgUEAAIEAxIDSCEiCm0K
BAQAAgUSA0wCGxpgIEV4cG9zZWQgc2NvcmUgZm9yIHRoaXMgdmFsdWVkIHJlc291cmNlLiBB
IHZhbHVlIG9mIDAgbWVhbnMgbm8gZXhwb3N1cmUgd2FzCiBkZXRlY3RlZCBleHBvc3VyZS4K
CgwKBQQAAgUFEgNMAggKDAoFBAACBQESA0wJFgoMCgUEAAIFAxIDTBkaCn0KBAQAAgYSA1AC
RxpwIExpc3Qgb2YgcmVzb3VyY2UgdmFsdWUgY29uZmlndXJhdGlvbnMnIG1ldGFkYXRhIHVz
ZWQgdG8gZGV0ZXJtaW5lIHRoZSB2YWx1ZQogb2YgdGhpcyByZXNvdXJjZS4gTWF4aW11bSBv
ZiAxMDAuCgoMCgUEAAIGBBIDUAIKCgwKBQQAAgYGEgNQCyYKDAoFBAACBgESA1AnQgoMCgUE
AAIGAxIDUEVGCk0KAgQBEgRUAFcBGkEgTWV0YWRhdGEgYWJvdXQgYSBSZXNvdXJjZVZhbHVl
Q29uZmlnLiBGb3IgZXhhbXBsZSwgaWQgYW5kIG5hbWUuCgoKCgMEAQESA1QIIwopCgQEAQIA
EgNWAhIaHCBSZXNvdXJjZSB2YWx1ZSBjb25maWcgbmFtZQoKDAoFBAECAAUSA1YCCAoMCgUE
AQIAARIDVgkNCgwKBQQBAgADEgNWEBFiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::ValuedResource::ValuedResource ===
    # Fields for ValuedResource
    # Field: name Type: 9 ()
    # Field: resource Type: 9 ()
    # Field: resource_type Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: resource_value Type: 14 (.google.cloud.securitycenter.v1.ValuedResource.ResourceValue)
    # Field: exposed_score Type: 1 ()
    # Field: resource_value_configs_used Type: 11 (.google.cloud.securitycenter.v1.ResourceValueConfigMetadata)

# Enum: ValuedResource::ResourceValue
our $ValuedResource_RESOURCE_VALUE_UNSPECIFIED = 0;
our $ValuedResource_RESOURCE_VALUE_LOW = 1;
our $ValuedResource_RESOURCE_VALUE_MEDIUM = 2;
our $ValuedResource_RESOURCE_VALUE_HIGH = 3;

# === Message: Google::Cloud::Securitycenter::V1::ValuedResource::ResourceValueConfigMetadata ===
    # Fields for ResourceValueConfigMetadata
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::ValuedResource - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/valued_resource.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::ValuedResource;

    my $msg = Google::Cloud::Securitycenter::V1::ValuedResource::ValuedResource->new({
        name => $name,
        resource => $resource,
        resource_type => $resource_type,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::ValuedResource::ValuedResource->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/valued_resource.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::ValuedResource::ValuedResource

A resource that is determined to have value to a user's system

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Valued resource name, for example,
 e.g.:
 `organizations/123/simulations/456/valuedResources/789`

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<String>

The
[full resource
name](https://cloud.google.com/apis/design/resource_names#full_resource_name)
of the valued resource.

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<String>

The [resource
type](https://cloud.google.com/asset-inventory/docs/supported-asset-types)
of the valued resource.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Human-readable name of the valued resource.

=item * C<< $msg->resource_value() >> / C<< $msg->resource_value($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V1::ValuedResource::ResourceValue>)

How valuable this resource is.

=item * C<< $msg->exposed_score() >> / C<< $msg->exposed_score($value) >>

Type: C<Double>

Exposed score for this valued resource. A value of 0 means no exposure was
detected exposure.

=item * C<< $msg->resource_value_configs_used() >> / C<< $msg->resource_value_configs_used($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::ValuedResource::ResourceValueConfigMetadata>)

List of resource value configurations' metadata used to determine the value
of this resource. Maximum of 100.

=back

=head3 Enum: ValuedResource::ResourceValue

=over 4

=item * C<RESOURCE_VALUE_UNSPECIFIED> => C<0>

=item * C<RESOURCE_VALUE_LOW> => C<1>

=item * C<RESOURCE_VALUE_MEDIUM> => C<2>

=item * C<RESOURCE_VALUE_HIGH> => C<3>

=back

=head2 Google::Cloud::Securitycenter::V1::ValuedResource::ResourceValueConfigMetadata

Metadata about a ResourceValueConfig. For example, id and name.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Resource value config name

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::ValuedResource::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
