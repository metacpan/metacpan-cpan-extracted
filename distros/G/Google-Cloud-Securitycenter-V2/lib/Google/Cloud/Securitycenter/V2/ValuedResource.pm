package Google::Cloud::Securitycenter::V2::ValuedResource;

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
CjRnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvdmFsdWVkX3Jlc291cmNlLnByb3Rv
Eh5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIaGWdvb2dsZS9hcGkvcmVzb3VyY2Uu
cHJvdG8iqAYKDlZhbHVlZFJlc291cmNlEhIKBG5hbWUYASABKAlSBG5hbWUSGgoIcmVzb3Vy
Y2UYAiABKAlSCHJlc291cmNlEiMKDXJlc291cmNlX3R5cGUYAyABKAlSDHJlc291cmNlVHlw
ZRIhCgxkaXNwbGF5X25hbWUYBCABKAlSC2Rpc3BsYXlOYW1lEmMKDnJlc291cmNlX3ZhbHVl
GAUgASgOMjwuZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyLlZhbHVlZFJlc291cmNl
LlJlc291cmNlVmFsdWVSDXJlc291cmNlVmFsdWUSIwoNZXhwb3NlZF9zY29yZRgGIAEoAVIM
ZXhwb3NlZFNjb3JlEnoKG3Jlc291cmNlX3ZhbHVlX2NvbmZpZ3NfdXNlZBgHIAMoCzI7Lmdv
b2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52Mi5SZXNvdXJjZVZhbHVlQ29uZmlnTWV0YWRh
dGFSGHJlc291cmNlVmFsdWVDb25maWdzVXNlZCJ7Cg1SZXNvdXJjZVZhbHVlEh4KGlJFU09V
UkNFX1ZBTFVFX1VOU1BFQ0lGSUVEEAASFgoSUkVTT1VSQ0VfVkFMVUVfTE9XEAESGQoVUkVT
T1VSQ0VfVkFMVUVfTUVESVVNEAISFwoTUkVTT1VSQ0VfVkFMVUVfSElHSBADOpoC6kGWAgos
c2VjdXJpdHljZW50ZXIuZ29vZ2xlYXBpcy5jb20vVmFsdWVkUmVzb3VyY2USV29yZ2FuaXph
dGlvbnMve29yZ2FuaXphdGlvbn0vc2ltdWxhdGlvbnMve3NpbXVsYXRpb259L3ZhbHVlZFJl
c291cmNlcy97dmFsdWVkX3Jlc291cmNlfRJsb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9u
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9zaW11bGF0aW9ucy97c2ltbHVhdGlvbn0vdmFsdWVk
UmVzb3VyY2VzL3t2YWx1ZWRfcmVzb3VyY2V9Kg92YWx1ZWRSZXNvdXJjZXMyDnZhbHVlZFJl
c291cmNlIjEKG1Jlc291cmNlVmFsdWVDb25maWdNZXRhZGF0YRISCgRuYW1lGAEgASgJUgRu
YW1lQu0BCiJjb20uZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyQhNWYWx1ZWRSZXNv
dXJjZVByb3RvUAFaSmNsb3VkLmdvb2dsZS5jb20vZ28vc2VjdXJpdHljZW50ZXIvYXBpdjIv
c2VjdXJpdHljZW50ZXJwYjtzZWN1cml0eWNlbnRlcnBiqgIeR29vZ2xlLkNsb3VkLlNlY3Vy
aXR5Q2VudGVyLlYyygIeR29vZ2xlXENsb3VkXFNlY3VyaXR5Q2VudGVyXFYy6gIhR29vZ2xl
OjpDbG91ZDo6U2VjdXJpdHlDZW50ZXI6OlYySq8TCgYSBA4AWAEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIAIwoICgEIEgMUADsKCQoC
CCUSAxQAOwoICgEIEgMVAGEKCQoCCAsSAxUAYQoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEI
EgMXADQKCQoCCAgSAxcANAoICgEIEgMYADsKCQoCCAESAxgAOwoICgEIEgMZADsKCQoCCCkS
AxkAOwoICgEIEgMaADoKCQoCCC0SAxoAOgpMCgIEABIEHQBSARpAIEEgcmVzb3VyY2UgdGhh
dCBpcyBkZXRlcm1pbmVkIHRvIGhhdmUgdmFsdWUgdG8gYSB1c2VyJ3Mgc3lzdGVtCgoKCgME
AAESAx0IFgoLCgMEAAcSBB4CJAQKDQoFBAAHnQgSBB4CJAQKLQoEBAAEABIEJwIzAxofIEhv
dyB2YWx1YWJsZSB0aGUgcmVzb3VyY2UgaXMuCgoMCgUEAAQAARIDJwcUCjQKBgQABAACABID
KQQjGiUgVGhlIHJlc291cmNlIHZhbHVlIGlzbid0IHNwZWNpZmllZC4KCg4KBwQABAACAAES
AykEHgoOCgcEAAQAAgACEgMpISIKLgoGBAAEAAIBEgMsBBsaHyBUaGlzIGlzIGEgbG93LXZh
bHVlIHJlc291cmNlLgoKDgoHBAAEAAIBARIDLAQWCg4KBwQABAACAQISAywZGgoxCgYEAAQA
AgISAy8EHhoiIFRoaXMgaXMgYSBtZWRpdW0tdmFsdWUgcmVzb3VyY2UuCgoOCgcEAAQAAgIB
EgMvBBkKDgoHBAAEAAICAhIDLxwdCi8KBgQABAACAxIDMgQcGiAgVGhpcyBpcyBhIGhpZ2gt
dmFsdWUgcmVzb3VyY2UuCgoOCgcEAAQAAgMBEgMyBBcKDgoHBAAEAAIDAhIDMhobCnMKBAQA
AgASAzgCEhpmIFZhbHVlZCByZXNvdXJjZSBuYW1lLCBmb3IgZXhhbXBsZSwKICBlLmcuOgog
IGBvcmdhbml6YXRpb25zLzEyMy9zaW11bGF0aW9ucy80NTYvdmFsdWVkUmVzb3VyY2VzLzc4
OWAKCgwKBQQAAgAFEgM4AggKDAoFBAACAAESAzgJDQoMCgUEAAIAAxIDOBARCooBCgQEAAIB
EgM+AhYafSBUaGUKIFtmdWxsIHJlc291cmNlCiBuYW1lXShodHRwczovL2Nsb3VkLmdvb2ds
ZS5jb20vYXBpcy9kZXNpZ24vcmVzb3VyY2VfbmFtZXMjZnVsbF9yZXNvdXJjZV9uYW1lKQog
b2YgdGhlIHZhbHVlZCByZXNvdXJjZS4KCgwKBQQAAgEFEgM+AggKDAoFBAACAQESAz4JEQoM
CgUEAAIBAxIDPhQVCoEBCgQEAAICEgNDAhsadCBUaGUgW3Jlc291cmNlCiB0eXBlXShodHRw
czovL2Nsb3VkLmdvb2dsZS5jb20vYXNzZXQtaW52ZW50b3J5L2RvY3Mvc3VwcG9ydGVkLWFz
c2V0LXR5cGVzKQogb2YgdGhlIHZhbHVlZCByZXNvdXJjZS4KCgwKBQQAAgIFEgNDAggKDAoF
BAACAgESA0MJFgoMCgUEAAICAxIDQxkaCjoKBAQAAgMSA0YCGhotIEh1bWFuLXJlYWRhYmxl
IG5hbWUgb2YgdGhlIHZhbHVlZCByZXNvdXJjZS4KCgwKBQQAAgMFEgNGAggKDAoFBAACAwES
A0YJFQoMCgUEAAIDAxIDRhgZCi0KBAQAAgQSA0kCIxogIEhvdyB2YWx1YWJsZSB0aGlzIHJl
c291cmNlIGlzLgoKDAoFBAACBAYSA0kCDwoMCgUEAAIEARIDSRAeCgwKBQQAAgQDEgNJISIK
bQoEBAACBRIDTQIbGmAgRXhwb3NlZCBzY29yZSBmb3IgdGhpcyB2YWx1ZWQgcmVzb3VyY2Uu
IEEgdmFsdWUgb2YgMCBtZWFucyBubyBleHBvc3VyZSB3YXMKIGRldGVjdGVkIGV4cG9zdXJl
LgoKDAoFBAACBQUSA00CCAoMCgUEAAIFARIDTQkWCgwKBQQAAgUDEgNNGRoKfQoEBAACBhID
UQJHGnAgTGlzdCBvZiByZXNvdXJjZSB2YWx1ZSBjb25maWd1cmF0aW9ucycgbWV0YWRhdGEg
dXNlZCB0byBkZXRlcm1pbmUgdGhlIHZhbHVlCiBvZiB0aGlzIHJlc291cmNlLiBNYXhpbXVt
IG9mIDEwMC4KCgwKBQQAAgYEEgNRAgoKDAoFBAACBgYSA1ELJgoMCgUEAAIGARIDUSdCCgwK
BQQAAgYDEgNRRUYKTQoCBAESBFUAWAEaQSBNZXRhZGF0YSBhYm91dCBhIFJlc291cmNlVmFs
dWVDb25maWcuIEZvciBleGFtcGxlLCBpZCBhbmQgbmFtZS4KCgoKAwQBARIDVQgjCikKBAQB
AgASA1cCEhocIFJlc291cmNlIHZhbHVlIGNvbmZpZyBuYW1lCgoMCgUEAQIABRIDVwIICgwK
BQQBAgABEgNXCQ0KDAoFBAECAAMSA1cQEWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::ValuedResource::ValuedResource ===
    # Fields for ValuedResource
    # Field: name Type: 9 ()
    # Field: resource Type: 9 ()
    # Field: resource_type Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: resource_value Type: 14 (.google.cloud.securitycenter.v2.ValuedResource.ResourceValue)
    # Field: exposed_score Type: 1 ()
    # Field: resource_value_configs_used Type: 11 (.google.cloud.securitycenter.v2.ResourceValueConfigMetadata)

# Enum: ValuedResource::ResourceValue
our $ValuedResource_RESOURCE_VALUE_UNSPECIFIED = 0;
our $ValuedResource_RESOURCE_VALUE_LOW = 1;
our $ValuedResource_RESOURCE_VALUE_MEDIUM = 2;
our $ValuedResource_RESOURCE_VALUE_HIGH = 3;

# === Message: Google::Cloud::Securitycenter::V2::ValuedResource::ResourceValueConfigMetadata ===
    # Fields for ResourceValueConfigMetadata
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::ValuedResource - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/valued_resource.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::ValuedResource;

    my $msg = Google::Cloud::Securitycenter::V2::ValuedResource::ValuedResource->new({
        name => $name,
        resource => $resource,
        resource_type => $resource_type,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::ValuedResource::ValuedResource->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/valued_resource.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::ValuedResource::ValuedResource

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

Type: C<Enum> (L<Google::Cloud::Securitycenter::V2::ValuedResource::ResourceValue>)

How valuable this resource is.

=item * C<< $msg->exposed_score() >> / C<< $msg->exposed_score($value) >>

Type: C<Double>

Exposed score for this valued resource. A value of 0 means no exposure was
detected exposure.

=item * C<< $msg->resource_value_configs_used() >> / C<< $msg->resource_value_configs_used($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::ValuedResource::ResourceValueConfigMetadata>)

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

=head2 Google::Cloud::Securitycenter::V2::ValuedResource::ResourceValueConfigMetadata

Metadata about a ResourceValueConfig. For example, id and name.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Resource value config name

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::ValuedResource::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
