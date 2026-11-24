package Google::Cloud::Capacityplanner::V1beta::Resource;

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
CjJnb29nbGUvY2xvdWQvY2FwYWNpdHlwbGFubmVyL3YxYmV0YS9yZXNvdXJjZS5wcm90bxIj
Z29vZ2xlLmNsb3VkLmNhcGFjaXR5cGxhbm5lci52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8iuQEKEVJlc291cmNlQ29udGFpbmVyEk8KBHR5cGUYASABKA4yOy5n
b29nbGUuY2xvdWQuY2FwYWNpdHlwbGFubmVyLnYxYmV0YS5SZXNvdXJjZUNvbnRhaW5lci5U
eXBlUgR0eXBlEhMKAmlkGAIgASgJQgPgQQJSAmlkIj4KBFR5cGUSFAoQVFlQRV9VTlNQRUNJ
RklFRBAAEgsKB1BST0pFQ1QQARIKCgZGT0xERVIQAhIHCgNPUkcQAyKrAQoNUmVzb3VyY2VJ
ZEtleRIqCg1yZXNvdXJjZV9jb2RlGAIgASgJQgPgQQJIAFIMcmVzb3VyY2VDb2RlEl0KC3Jl
c291cmNlX2lkGAEgASgLMjcuZ29vZ2xlLmNsb3VkLmNhcGFjaXR5cGxhbm5lci52MWJldGEu
UmVzb3VyY2VJZGVudGlmaWVyQgPgQQJSCnJlc291cmNlSWRCDwoNZGVtYW5kX2ZpZWxkcyLF
AQoSUmVzb3VyY2VJZGVudGlmaWVyEiEKDHNlcnZpY2VfbmFtZRgBIAEoCVILc2VydmljZU5h
bWUSIwoNcmVzb3VyY2VfbmFtZRgCIAEoCVIMcmVzb3VyY2VOYW1lEmcKE3Jlc291cmNlX2F0
dHJpYnV0ZXMYAyADKAsyNi5nb29nbGUuY2xvdWQuY2FwYWNpdHlwbGFubmVyLnYxYmV0YS5S
ZXNvdXJjZUF0dHJpYnV0ZVIScmVzb3VyY2VBdHRyaWJ1dGVzIm8KEVJlc291cmNlQXR0cmli
dXRlEhAKA2tleRgBIAEoCVIDa2V5EkgKBXZhbHVlGAIgASgLMjIuZ29vZ2xlLmNsb3VkLmNh
cGFjaXR5cGxhbm5lci52MWJldGEuUmVzb3VyY2VWYWx1ZVIFdmFsdWUikAEKDVJlc291cmNl
VmFsdWUSPQoEdW5pdBgBIAEoDjIpLmdvb2dsZS5jbG91ZC5jYXBhY2l0eXBsYW5uZXIudjFi
ZXRhLlVuaXRSBHVuaXQSQAoFdmFsdWUYAiABKAsyKi5nb29nbGUuY2xvdWQuY2FwYWNpdHlw
bGFubmVyLnYxYmV0YS5WYWx1ZVIFdmFsdWUingEKBVZhbHVlEiEKC2ludDY0X3ZhbHVlGAEg
ASgDSABSCmludDY0VmFsdWUSIwoMc3RyaW5nX3ZhbHVlGAIgASgJSABSC3N0cmluZ1ZhbHVl
EiMKDGRvdWJsZV92YWx1ZRgDIAEoAUgAUgtkb3VibGVWYWx1ZRIfCgpib29sX3ZhbHVlGAQg
ASgISABSCWJvb2xWYWx1ZUIHCgV2YWx1ZSrsAQoEVW5pdBIUChBVTklUX1VOU1BFQ0lGSUVE
EAASDgoKVU5JVF9DT1VOVBABEgYKAktCEAISBgoCR0IQAxIGCgJUQhAEEgcKA01JQhAREgcK
A0dJQhAFEgcKA1RJQhAGEgcKA1FQUxAHEgYKAk1CEAgSBwoDUElCEAkSDAoEVEJQUxAKGgII
ARINCglHQlBTX0JJVFMQCxIMCghHSUJfQklUUxAMEg0KCU1CUFNfQklUUxANEg4KCk1CUFNf
QllURVMQDhINCglUQlBTX0JJVFMQDxIOCgpUQlBTX0JZVEVTEBASCAoES09QUxASQoICCidj
b20uZ29vZ2xlLmNsb3VkLmNhcGFjaXR5cGxhbm5lci52MWJldGFCDVJlc291cmNlUHJvdG9Q
AVpRY2xvdWQuZ29vZ2xlLmNvbS9nby9jYXBhY2l0eXBsYW5uZXIvYXBpdjFiZXRhL2NhcGFj
aXR5cGxhbm5lcnBiO2NhcGFjaXR5cGxhbm5lcnBiqgIjR29vZ2xlLkNsb3VkLkNhcGFjaXR5
UGxhbm5lci5WMUJldGHKAiNHb29nbGVcQ2xvdWRcQ2FwYWNpdHlQbGFubmVyXFYxYmV0YeoC
Jkdvb2dsZTo6Q2xvdWQ6OkNhcGFjaXR5UGxhbm5lcjo6VjFiZXRhSrcdCgcSBQ4AjgEBCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAsCgkKAgMAEgMSACkK
CAoBCBIDFABACgkKAgglEgMUAEAKCAoBCBIDFQBoCgkKAggLEgMVAGgKCAoBCBIDFgAiCgkK
AggKEgMWACIKCAoBCBIDFwAuCgkKAggIEgMXAC4KCAoBCBIDGABACgkKAggBEgMYAEAKCAoB
CBIDGQBACgkKAggpEgMZAEAKCAoBCBIDGgA/CgkKAggtEgMaAD8KCgoCBQASBBwATAEKCgoD
BQABEgMcBQkKCwoEBQACABIDHQIXCgwKBQUAAgABEgMdAhIKDAoFBQACAAISAx0VFgoLCgQF
AAIBEgMfAhEKDAoFBQACAQESAx8CDAoMCgUFAAIBAhIDHw8QCiUKBAUAAgISAyICCRoYIEtp
bG9ieXRlcyAoMTBeMyBieXRlcykKCgwKBQUAAgIBEgMiAgQKDAoFBQACAgISAyIHCAolCgQF
AAIDEgMlAgkaGCBHaWdhYnl0ZXMgKDEwXjkgYnl0ZXMpCgoMCgUFAAIDARIDJQIECgwKBQUA
AgMCEgMlBwgKJgoEBQACBBIDKAIJGhkgVGVyYWJ5dGVzICgxMF4xMiBieXRlcykKCgwKBQUA
AgQBEgMoAgQKDAoFBQACBAISAygHCAolCgQFAAIFEgMrAgsaGCBNZWJpYnl0ZXMgKDJeMjAg
Ynl0ZXMpCgoMCgUFAAIFARIDKwIFCgwKBQUAAgUCEgMrCAoKJQoEBQACBhIDLgIKGhggR2li
aWJ5dGVzICgyXjMwIGJ5dGVzKQoKDAoFBQACBgESAy4CBQoMCgUFAAIGAhIDLggJCiUKBAUA
AgcSAzECChoYIFRlYmlieXRlcyAoMl40MCBieXRlcykKCgwKBQUAAgcBEgMxAgUKDAoFBQAC
BwISAzEICQohCgQFAAIIEgM0AgoaFCBRdWVyaWVzIHBlciBzZWNvbmQKCgwKBQUAAggBEgM0
AgUKDAoFBQACCAISAzQICQolCgQFAAIJEgM3AgkaGCBNZWdhYnl0ZXMgKDEwXjYgYnl0ZXMp
CgoMCgUFAAIJARIDNwIECgwKBQUAAgkCEgM3BwgKJQoEBQACChIDOgIKGhggUGViaWJ5dGVz
ICgyXjUwIGJ5dGVzKQoKDAoFBQACCgESAzoCBQoMCgUFAAIKAhIDOggJCi8KBAUAAgsSAz0C
IBoiIFRlcmFiaXRzICgxMF4xMiBiaXRzKSBwZXIgc2Vjb25kCgoMCgUFAAILARIDPQIGCgwK
BQUAAgsCEgM9CQsKDAoFBQACCwMSAz0MHwoNCgYFAAILAwESAz0NHgoLCgQFAAIMEgM/AhEK
DAoFBQACDAESAz8CCwoMCgUFAAIMAhIDPw4QCgsKBAUAAg0SA0ECEAoMCgUFAAINARIDQQIK
CgwKBQUAAg0CEgNBDQ8KCwoEBQACDhIDQwIRCgwKBQUAAg4BEgNDAgsKDAoFBQACDgISA0MO
EAoLCgQFAAIPEgNFAhIKDAoFBQACDwESA0UCDAoMCgUFAAIPAhIDRQ8RCgsKBAUAAhASA0cC
EQoMCgUFAAIQARIDRwILCgwKBQUAAhACEgNHDhAKCwoEBQACERIDSQISCgwKBQUAAhEBEgNJ
AgwKDAoFBQACEQISA0kPEQoLCgQFAAISEgNLAgwKDAoFBQACEgESA0sCBgoMCgUFAAISAhID
SwkLCloKAgQAEgRPAF8BGk4gVGhlIHJlc291cmNlIGNvbnRhaW5lciBvZiBHb29nbGUgQ2xv
dWQgUGxhdGZvcm0gaGllcmFyY2h5IHN1Y2ggYXMgYSBwcm9qZWN0LgoKCgoDBAABEgNPCBkK
DAoEBAAEABIEUAJYAwoMCgUEAAQAARIDUAcLCg0KBgQABAACABIDUQQZCg4KBwQABAACAAES
A1EEFAoOCgcEAAQAAgACEgNRFxgKDQoGBAAEAAIBEgNTBBAKDgoHBAAEAAIBARIDUwQLCg4K
BwQABAACAQISA1MODwoNCgYEAAQAAgISA1UEDwoOCgcEAAQAAgIBEgNVBAoKDgoHBAAEAAIC
AhIDVQ0OCg0KBgQABAACAxIDVwQMCg4KBwQABAACAwESA1cEBwoOCgcEAAQAAgMCEgNXCgsK
CwoEBAACABIDWgIQCgwKBQQAAgAGEgNaAgYKDAoFBAACAAESA1oHCwoMCgUEAAIAAxIDWg4P
Cm0KBAQAAgESA14CORpgIFJlcXVpcmVkLiBJZGVudGlmaWVyIG9mIHRoZSByZXNvdXJjZSBj
b250YWluZXIuIEZvciBleGFtcGxlLCBwcm9qZWN0IG51bWJlcgogZm9yIHByb2plY3QgdHlw
ZS4KCgwKBQQAAgEFEgNeAggKDAoFBAACAQESA14JCwoMCgUEAAIBAxIDXg4PCgwKBQQAAgEI
EgNeEDgKDwoIBAACAQicCAASA14RNwo+CgIEARIEYgBsARoyIFRoZSBpZCBmb3IgYSBHb29n
bGUgQ2xvdWQgUGxhdGZvcm0gcmVzb3VyY2Uga2V5LgoKCgoDBAEBEgNiCBUKLwoEBAEIABIE
ZAJoAxohIERlbWFuZCBmaWVsZHMgZm9yIHRoZSByZXNvdXJjZS4KCgwKBQQBCAABEgNkCBUK
kAEKBAQBAgASA2cERhqCASBSZXF1aXJlZC4gcmVzb3VyY2VfY29kZSBmb3IgdGhlIHJlc291
cmNlLiBlZzogZ2NlLXJhbSwgZ2NlLXZjcHVzLAogZ2NlLWdwdSwgZ2NlLXRwdSwgZ2NlLXZt
LCBnY2UtcGVyc2lzdGVudC1kaXNrLCBnY2UtbG9jYWwtc3NkLgoKDAoFBAECAAUSA2cECgoM
CgUEAQIAARIDZwsYCgwKBQQBAgADEgNnGxwKDAoFBAECAAgSA2cdRQoPCggEAQIACJwIABID
Zx5ECiwKBAQBAgESA2sCThofIFJlcXVpcmVkLiBJZCBvZiB0aGUgcmVzb3VyY2UuCgoMCgUE
AQIBBhIDawIUCgwKBQQBAgEBEgNrFSAKDAoFBAECAQMSA2sjJAoMCgUEAQIBCBIDayVNCg8K
CAQBAgEInAgAEgNrJkwKQgoCBAISBG8AdQEaNiBUaGUgaWRlbnRpZmllciBmb3IgYSBHb29n
bGUgQ2xvdWQgUGxhdGZvcm0gcmVzb3VyY2UuCgoKCgMEAgESA28IGgoLCgQEAgIAEgNwAhoK
DAoFBAICAAUSA3ACCAoMCgUEAgIAARIDcAkVCgwKBQQCAgADEgNwGBkKCwoEBAICARIDcgIb
CgwKBQQCAgEFEgNyAggKDAoFBAICAQESA3IJFgoMCgUEAgIBAxIDchkaCgsKBAQCAgISA3QC
NQoMCgUEAgICBBIDdAIKCgwKBQQCAgIGEgN0CxwKDAoFBAICAgESA3QdMAoMCgUEAgICAxID
dDM0Cj8KAgQDEgR4AHwBGjMgQW4gYXR0cmlidXRlIG9mIGEgR29vZ2xlIENsb3VkIFBsYXRm
b3JtIHJlc291cmNlLgoKCgoDBAMBEgN4CBkKCwoEBAMCABIDeQIRCgwKBQQDAgAFEgN5AggK
DAoFBAMCAAESA3kJDAoMCgUEAwIAAxIDeQ8QCgsKBAQDAgESA3sCGgoMCgUEAwIBBhIDewIP
CgwKBQQDAgEBEgN7EBUKDAoFBAMCAQMSA3sYGQoLCgIEBBIFfgCCAQEKCgoDBAQBEgN+CBUK
CwoEBAQCABIDfwIQCgwKBQQEAgAGEgN/AgYKDAoFBAQCAAESA38HCwoMCgUEBAIAAxIDfw4P
CgwKBAQEAgESBIEBAhIKDQoFBAQCAQYSBIEBAgcKDQoFBAQCAQESBIEBCA0KDQoFBAQCAQMS
BIEBEBEKDAoCBAUSBoQBAI4BAQoLCgMEBQESBIQBCA0KDgoEBAUIABIGhQECjQEDCg0KBQQF
CAABEgSFAQgNCgwKBAQFAgASBIYBBBoKDQoFBAUCAAUSBIYBBAkKDQoFBAUCAAESBIYBChUK
DQoFBAUCAAMSBIYBGBkKDAoEBAUCARIEiAEEHAoNCgUEBQIBBRIEiAEECgoNCgUEBQIBARIE
iAELFwoNCgUEBQIBAxIEiAEaGwoMCgQEBQICEgSKAQQcCg0KBQQFAgIFEgSKAQQKCg0KBQQF
AgIBEgSKAQsXCg0KBQQFAgIDEgSKARobCgwKBAQFAgMSBIwBBBgKDQoFBAUCAwUSBIwBBAgK
DQoFBAUCAwESBIwBCRMKDQoFBAUCAwMSBIwBFhdiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Capacityplanner::V1beta::Resource::ResourceContainer ===
    # Fields for ResourceContainer
    # Field: type Type: 14 (.google.cloud.capacityplanner.v1beta.ResourceContainer.Type)
    # Field: id Type: 9 ()

# Enum: ResourceContainer::Type
our $ResourceContainer_TYPE_UNSPECIFIED = 0;
our $ResourceContainer_PROJECT = 1;
our $ResourceContainer_FOLDER = 2;
our $ResourceContainer_ORG = 3;

# === Message: Google::Cloud::Capacityplanner::V1beta::Resource::ResourceIdKey ===
    # Fields for ResourceIdKey
    # Field: resource_code Type: 9 ()
    # Field: resource_id Type: 11 (.google.cloud.capacityplanner.v1beta.ResourceIdentifier)

# === Message: Google::Cloud::Capacityplanner::V1beta::Resource::ResourceIdentifier ===
    # Fields for ResourceIdentifier
    # Field: service_name Type: 9 ()
    # Field: resource_name Type: 9 ()
    # Field: resource_attributes Type: 11 (.google.cloud.capacityplanner.v1beta.ResourceAttribute)

# === Message: Google::Cloud::Capacityplanner::V1beta::Resource::ResourceAttribute ===
    # Fields for ResourceAttribute
    # Field: key Type: 9 ()
    # Field: value Type: 11 (.google.cloud.capacityplanner.v1beta.ResourceValue)

# === Message: Google::Cloud::Capacityplanner::V1beta::Resource::ResourceValue ===
    # Fields for ResourceValue
    # Field: unit Type: 14 (.google.cloud.capacityplanner.v1beta.Unit)
    # Field: value Type: 11 (.google.cloud.capacityplanner.v1beta.Value)

# === Message: Google::Cloud::Capacityplanner::V1beta::Resource::Value ===
    # Fields for Value
    # Field: int64_value Type: 3 ()
    # Field: string_value Type: 9 ()
    # Field: double_value Type: 1 ()
    # Field: bool_value Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Capacityplanner::V1beta::Resource - Compiled Protocol Buffers messages for google/cloud/capacityplanner/v1beta/resource.proto

=head1 SYNOPSIS

    use Google::Cloud::Capacityplanner::V1beta::Resource;

    my $msg = Google::Cloud::Capacityplanner::V1beta::Resource::ResourceContainer->new({
        type => $type,
        id => $id,
    });

    # Read or update a field
    my $val = $msg->type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Capacityplanner::V1beta::Resource::ResourceContainer->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/capacityplanner/v1beta/resource.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Capacityplanner::V1beta::Resource::ResourceContainer

The resource container of Google Cloud Platform hierarchy such as a project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Capacityplanner::V1beta::ResourceContainer::Type>)

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Required. Identifier of the resource container. For example, project number
for project type.

=back

=head3 Enum: ResourceContainer::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<PROJECT> => C<1>

=item * C<FOLDER> => C<2>

=item * C<ORG> => C<3>

=back

=head2 Google::Cloud::Capacityplanner::V1beta::Resource::ResourceIdKey

The id for a Google Cloud Platform resource key.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resource_code() >> / C<< $msg->resource_code($value) >>

Type: C<String>

Required. resource_code for the resource. eg: gce-ram, gce-vcpus,
gce-gpu, gce-tpu, gce-vm, gce-persistent-disk, gce-local-ssd.

=item * C<< $msg->resource_id() >> / C<< $msg->resource_id($value) >>

Type: C<Message> (L<Google::Cloud::Capacityplanner::V1beta::Resource::ResourceIdentifier>)

Required. Id of the resource.

=back

=head2 Google::Cloud::Capacityplanner::V1beta::Resource::ResourceIdentifier

The identifier for a Google Cloud Platform resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->service_name() >> / C<< $msg->service_name($value) >>

Type: C<String>

=item * C<< $msg->resource_name() >> / C<< $msg->resource_name($value) >>

Type: C<String>

=item * C<< $msg->resource_attributes() >> / C<< $msg->resource_attributes($value) >>

Type: C<Message> (L<Google::Cloud::Capacityplanner::V1beta::Resource::ResourceAttribute>)

=back

=head2 Google::Cloud::Capacityplanner::V1beta::Resource::ResourceAttribute

An attribute of a Google Cloud Platform resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<String>

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Message> (L<Google::Cloud::Capacityplanner::V1beta::Resource::ResourceValue>)

=back

=head2 Google::Cloud::Capacityplanner::V1beta::Resource::ResourceValue

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->unit() >> / C<< $msg->unit($value) >>

Type: C<Enum> (L<Google::Cloud::Capacityplanner::V1beta::Unit>)

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Message> (L<Google::Cloud::Capacityplanner::V1beta::Resource::Value>)

=back

=head2 Google::Cloud::Capacityplanner::V1beta::Resource::Value

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->int64_value() >> / C<< $msg->int64_value($value) >>

Type: C<Int64>

=item * C<< $msg->string_value() >> / C<< $msg->string_value($value) >>

Type: C<String>

=item * C<< $msg->double_value() >> / C<< $msg->double_value($value) >>

Type: C<Double>

=item * C<< $msg->bool_value() >> / C<< $msg->bool_value($value) >>

Type: C<Bool>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Capacityplanner::V1beta::Resource::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
