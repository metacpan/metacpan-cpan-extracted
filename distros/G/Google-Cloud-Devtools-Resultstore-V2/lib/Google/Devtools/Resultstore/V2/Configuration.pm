package Google::Devtools::Resultstore::V2::Configuration;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Devtools::Resultstore::V2::Common };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvZGV2dG9vbHMvcmVzdWx0c3RvcmUvdjIvY29uZmlndXJhdGlvbi5wcm90bxIe
Z29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyGhlnb29nbGUvYXBpL3Jlc291cmNlLnBy
b3RvGitnb29nbGUvZGV2dG9vbHMvcmVzdWx0c3RvcmUvdjIvY29tbW9uLnByb3RvItUECg1D
b25maWd1cmF0aW9uEhIKBG5hbWUYASABKAlSBG5hbWUSQAoCaWQYAiABKAsyMC5nb29nbGUu
ZGV2dG9vbHMucmVzdWx0c3RvcmUudjIuQ29uZmlndXJhdGlvbi5JZFICaWQSXQoRc3RhdHVz
X2F0dHJpYnV0ZXMYAyABKAsyMC5nb29nbGUuZGV2dG9vbHMucmVzdWx0c3RvcmUudjIuU3Rh
dHVzQXR0cmlidXRlc1IQc3RhdHVzQXR0cmlidXRlcxJyChhjb25maWd1cmF0aW9uX2F0dHJp
YnV0ZXMYBSABKAsyNy5nb29nbGUuZGV2dG9vbHMucmVzdWx0c3RvcmUudjIuQ29uZmlndXJh
dGlvbkF0dHJpYnV0ZXNSF2NvbmZpZ3VyYXRpb25BdHRyaWJ1dGVzEkgKCnByb3BlcnRpZXMY
BiADKAsyKC5nb29nbGUuZGV2dG9vbHMucmVzdWx0c3RvcmUudjIuUHJvcGVydHlSCnByb3Bl
cnRpZXMSIQoMZGlzcGxheV9uYW1lGAggASgJUgtkaXNwbGF5TmFtZRpUCgJJZBIjCg1pbnZv
Y2F0aW9uX2lkGAEgASgJUgxpbnZvY2F0aW9uSWQSKQoQY29uZmlndXJhdGlvbl9pZBgCIAEo
CVIPY29uZmlndXJhdGlvbklkOljqQVUKKHJlc3VsdHN0b3JlLmdvb2dsZWFwaXMuY29tL0Nv
bmZpZ3VyYXRpb24SKWludm9jYXRpb25zL3tpbnZvY2F0aW9ufS9jb25maWdzL3tjb25maWd9
IisKF0NvbmZpZ3VyYXRpb25BdHRyaWJ1dGVzEhAKA2NwdRgBIAEoCVIDY3B1QoUBCiJjb20u
Z29vZ2xlLmRldnRvb2xzLnJlc3VsdHN0b3JlLnYyQhJDb25maWd1cmF0aW9uUHJvdG9QAVpJ
Z29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9kZXZ0b29scy9yZXN1bHRz
dG9yZS92MjtyZXN1bHRzdG9yZUq2EwoGEgQOAEsBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0
IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwg
VmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmls
ZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRh
aW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9y
Zy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxl
IGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVu
ZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBX
SVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4
cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxh
bmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRo
ZSBMaWNlbnNlLgoKCAoBAhIDEAAnCgkKAgMAEgMSACMKCQoCAwESAxMANQoICgEIEgMVAGAK
CQoCCAsSAxUAYAoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXADMKCQoCCAgSAxcAMwoI
CgEIEgMYADsKCQoCCAESAxgAOwquAQoCBAASBB0ARQEaoQEgUmVwcmVzZW50cyBhIGNvbmZp
Z3VyYXRpb24gd2l0aGluIGFuIEludm9jYXRpb24gYXNzb2NpYXRlZCB3aXRoIG9uZSBvciBt
b3JlCiBDb25maWd1cmVkVGFyZ2V0cy4gSXQgY2FwdHVyZXMgdGhlIGVudmlyb25tZW50IGFu
ZCBvdGhlciBzZXR0aW5ncyB0aGF0CiB3ZXJlIHVzZWQuCgoKCgMEAAESAx0IFQoLCgMEAAcS
BB4CIQQKDQoFBAAHnQgSBB4CIQQKSwoEBAADABIEJAIqAxo9IFRoZSByZXNvdXJjZSBJRCBj
b21wb25lbnRzIHRoYXQgaWRlbnRpZnkgdGhlIENvbmZpZ3VyYXRpb24uCgoMCgUEAAMAARID
JAoMCiMKBgQAAwACABIDJgQdGhQgVGhlIEludm9jYXRpb24gSUQuCgoOCgcEAAMAAgAFEgMm
BAoKDgoHBAADAAIAARIDJgsYCg4KBwQAAwACAAMSAyYbHAomCgYEAAMAAgESAykEIBoXIFRo
ZSBDb25maWd1cmF0aW9uIElELgoKDgoHBAADAAIBBRIDKQQKCg4KBwQAAwACAQESAykLGwoO
CgcEAAMAAgEDEgMpHh8K7wEKBAQAAgASAzACEhrhASBUaGUgZm9ybWF0IG9mIHRoaXMgQ29u
ZmlndXJhdGlvbiByZXNvdXJjZSBuYW1lIG11c3QgYmU6CiBpbnZvY2F0aW9ucy8ke0lOVk9D
QVRJT05fSUR9L2NvbmZpZ3MvJHtDT05GSUdfSUR9CiBUaGUgY29uZmlndXJhdGlvbiBJRCBv
ZiAiZGVmYXVsdCIgc2hvdWxkIGJlIHByZWZlcnJlZCBmb3IgdGhlIGRlZmF1bHQKIGNvbmZp
Z3VyYXRpb24gaW4gYSBzaW5nbGUtY29uZmlnIGludm9jYXRpb24uCgoMCgUEAAIABRIDMAII
CgwKBQQAAgABEgMwCQ0KDAoFBAACAAMSAzAQEQqEAQoEBAACARIDNAIMGncgVGhlIHJlc291
cmNlIElEIGNvbXBvbmVudHMgdGhhdCBpZGVudGlmeSB0aGUgQ29uZmlndXJhdGlvbi4gVGhl
eSBtdXN0IG1hdGNoCiB0aGUgcmVzb3VyY2UgbmFtZSBhZnRlciBwcm9wZXIgZW5jb2Rpbmcu
CgoMCgUEAAIBBhIDNAIECgwKBQQAAgEBEgM0BQcKDAoFBAACAQMSAzQKCwo7CgQEAAICEgM3
AikaLiBUaGUgYWdncmVnYXRlIHN0YXR1cyBmb3IgdGhpcyBjb25maWd1cmF0aW9uLgoKDAoF
BAACAgYSAzcCEgoMCgUEAAICARIDNxMkCgwKBQQAAgIDEgM3JygKQAoEBAACAxIDOgI3GjMg
QXR0cmlidXRlcyB0aGF0IGFwcGx5IG9ubHkgdG8gdGhpcyBjb25maWd1cmF0aW9uLgoKDAoF
BAACAwYSAzoCGQoMCgUEAAIDARIDOhoyCgwKBQQAAgMDEgM6NTYKwQEKBAQAAgQSAz8CIxqz
ASBBcmJpdHJhcnkgbmFtZS12YWx1ZSBwYWlycy4KIFRoaXMgaXMgaW1wbGVtZW50ZWQgYXMg
YSBtdWx0aS1tYXAuIE11bHRpcGxlIHByb3BlcnRpZXMgYXJlIGFsbG93ZWQgd2l0aAogdGhl
IHNhbWUga2V5LiBQcm9wZXJ0aWVzIHdpbGwgYmUgcmV0dXJuZWQgaW4gbGV4aWNvZ3JhcGhp
Y2FsIG9yZGVyIGJ5IGtleS4KCgwKBQQAAgQEEgM/AgoKDAoFBAACBAYSAz8LEwoMCgUEAAIE
ARIDPxQeCgwKBQQAAgQDEgM/ISIKogEKBAQAAgUSA0QCGhqUASBBIGh1bWFuLXJlYWRhYmxl
IG5hbWUgZm9yIENvbmZpZ3VyYXRpb24gZm9yIFVJcy4KIEl0IGlzIHJlY29tbWVuZGVkIHRo
YXQgdGhpcyBuYW1lIGJlIHVuaXF1ZS4KIElmIG9taXR0ZWQsIFVJcyBzaG91bGQgZGVmYXVs
dCB0byBjb25maWd1cmF0aW9uX2lkLgoKDAoFBAACBQUSA0QCCAoMCgUEAAIFARIDRAkVCgwK
BQQAAgUDEgNEGBkKPgoCBAESBEgASwEaMiBBdHRyaWJ1dGVzIHRoYXQgYXBwbHkgb25seSB0
byB0aGUgY29uZmlndXJhdGlvbi4KCgoKAwQBARIDSAgfCjcKBAQBAgASA0oCERoqIFRoZSB0
eXBlIG9mIGNwdS4gKGUuZy4gIng4NiIsICJwb3dlcnBjIikKCgwKBQQBAgAFEgNKAggKDAoF
BAECAAESA0oJDAoMCgUEAQIAAxIDSg8QYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Resultstore::V2::Configuration::Configuration ===
    # Fields for Configuration
    # Field: name Type: 9 ()
    # Field: id Type: 11 (.google.devtools.resultstore.v2.Configuration.Id)
    # Field: status_attributes Type: 11 (.google.devtools.resultstore.v2.StatusAttributes)
    # Field: configuration_attributes Type: 11 (.google.devtools.resultstore.v2.ConfigurationAttributes)
    # Field: properties Type: 11 (.google.devtools.resultstore.v2.Property)
    # Field: display_name Type: 9 ()

# === Message: Google::Devtools::Resultstore::V2::Configuration::ConfigurationAttributes ===
    # Fields for ConfigurationAttributes
    # Field: cpu Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Resultstore::V2::Configuration - Compiled Protocol Buffers messages for google/devtools/resultstore/v2/configuration.proto

=head1 SYNOPSIS

    use Google::Devtools::Resultstore::V2::Configuration;

    my $msg = Google::Devtools::Resultstore::V2::Configuration::Configuration->new({
        name => $name,
        id => $id,
        status_attributes => $status_attributes,
        configuration_attributes => $configuration_attributes,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Resultstore::V2::Configuration::Configuration->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/resultstore/v2/configuration.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Resultstore::V2::Configuration::Configuration

Represents a configuration within an Invocation associated with one or more
ConfiguredTargets. It captures the environment and other settings that
were used.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The format of this Configuration resource name must be:
invocations/${INVOCATION_ID}/configs/${CONFIG_ID}
The configuration ID of "default" should be preferred for the default
configuration in a single-config invocation.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Configuration::Configuration::Id>)

The resource ID components that identify the Configuration. They must match
the resource name after proper encoding.

=item * C<< $msg->status_attributes() >> / C<< $msg->status_attributes($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Common::StatusAttributes>)

The aggregate status for this configuration.

=item * C<< $msg->configuration_attributes() >> / C<< $msg->configuration_attributes($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Configuration::ConfigurationAttributes>)

Attributes that apply only to this configuration.

=item * C<< $msg->properties() >> / C<< $msg->properties($value) >>

Type: C<Message> (L<Google::Devtools::Resultstore::V2::Common::Property>)

Arbitrary name-value pairs.
This is implemented as a multi-map. Multiple properties are allowed with
the same key. Properties will be returned in lexicographical order by key.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

A human-readable name for Configuration for UIs.
It is recommended that this name be unique.
If omitted, UIs should default to configuration_id.

=back

=head2 Google::Devtools::Resultstore::V2::Configuration::ConfigurationAttributes

Attributes that apply only to the configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cpu() >> / C<< $msg->cpu($value) >>

Type: C<String>

The type of cpu. (e.g. "x86", "powerpc")

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Resultstore::V2::Configuration::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
