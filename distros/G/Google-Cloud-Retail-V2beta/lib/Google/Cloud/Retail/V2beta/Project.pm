package Google::Cloud::Retail::V2beta::Project;

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
Cihnb29nbGUvY2xvdWQvcmV0YWlsL3YyYmV0YS9wcm9qZWN0LnByb3RvEhpnb29nbGUuY2xv
dWQucmV0YWlsLnYyYmV0YRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29v
Z2xlL2FwaS9yZXNvdXJjZS5wcm90byLBBAoLQWxlcnRDb25maWcSGgoEbmFtZRgBIAEoCUIG
4EEC4EEFUgRuYW1lEloKDmFsZXJ0X3BvbGljaWVzGAIgAygLMjMuZ29vZ2xlLmNsb3VkLnJl
dGFpbC52MmJldGEuQWxlcnRDb25maWcuQWxlcnRQb2xpY3lSDWFsZXJ0UG9saWNpZXMa8QIK
C0FsZXJ0UG9saWN5Eh8KC2FsZXJ0X2dyb3VwGAEgASgJUgphbGVydEdyb3VwEmUKDWVucm9s
bF9zdGF0dXMYAiABKA4yQC5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YS5BbGVydENvbmZp
Zy5BbGVydFBvbGljeS5FbnJvbGxTdGF0dXNSDGVucm9sbFN0YXR1cxJdCgpyZWNpcGllbnRz
GAMgAygLMj0uZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGEuQWxlcnRDb25maWcuQWxlcnRQ
b2xpY3kuUmVjaXBpZW50UgpyZWNpcGllbnRzGjAKCVJlY2lwaWVudBIjCg1lbWFpbF9hZGRy
ZXNzGAEgASgJUgxlbWFpbEFkZHJlc3MiSQoMRW5yb2xsU3RhdHVzEh0KGUVOUk9MTF9TVEFU
VVNfVU5TUEVDSUZJRUQQABIMCghFTlJPTExFRBABEgwKCERFQ0xJTkVEEAI6RupBQwohcmV0
YWlsLmdvb2dsZWFwaXMuY29tL0FsZXJ0Q29uZmlnEh5wcm9qZWN0cy97cHJvamVjdH0vYWxl
cnRDb25maWdCywEKHmNvbS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYmV0YUIMUHJvamVjdFBy
b3RvUAFaNmNsb3VkLmdvb2dsZS5jb20vZ28vcmV0YWlsL2FwaXYyYmV0YS9yZXRhaWxwYjty
ZXRhaWxwYqICBlJFVEFJTKoCGkdvb2dsZS5DbG91ZC5SZXRhaWwuVjJCZXRhygIaR29vZ2xl
XENsb3VkXFJldGFpbFxWMmJldGHqAh1Hb29nbGU6OkNsb3VkOjpSZXRhaWw6OlYyYmV0YUrB
EgoGEgQOAFIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAj
CgkKAgMAEgMSACkKCQoCAwESAxMAIwoICgEIEgMVADcKCQoCCCUSAxUANwoICgEIEgMWAE0K
CQoCCAsSAxYATQoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYAC0KCQoCCAgSAxgALQoI
CgEIEgMZADcKCQoCCAESAxkANwoICgEIEgMaACQKCQoCCCQSAxoAJAoICgEIEgMbADcKCQoC
CCkSAxsANwoICgEIEgMcADYKCQoCCC0SAxwANgopCgIEABIEHwBSARodIFByb2plY3QgbGV2
ZWwgYWxlcnQgY29uZmlnLgoKCgoDBAABEgMfCBMKCwoDBAAHEgQgAiMECg0KBQQAB50IEgQg
AiMECiwKBAQAAwASBCYCRgMaHiBBbGVydCBwb2xpY3kgZm9yIGEgY3VzdG9tZXIuCgoMCgUE
AAMAARIDJgoVCjAKBgQAAwADABIEKAQrBRogIFJlY2lwaWVudCBjb250YWN0IGluZm9ybWF0
aW9uLgoKDgoHBAADAAMAARIDKAwVCjIKCAQAAwADAAIAEgMqBh8aISBFbWFpbCBhZGRyZXNz
IG9mIHRoZSByZWNpcGllbnQuCgoQCgkEAAMAAwACAAUSAyoGDAoQCgkEAAMAAwACAAESAyoN
GgoQCgkEAAMAAwACAAMSAyodHgo+CgYEAAMABAASBC4EOAUaLiBUaGUgZW5yb2xsbWVudCBz
dGF0dXMgZW51bSBmb3IgYWxlcnQgcG9saWN5LgoKDgoHBAADAAQAARIDLgkVCmEKCAQAAwAE
AAIAEgMxBiQaUCBEZWZhdWx0IHZhbHVlLiBVc2VkIGZvciBjdXN0b21lcnMgd2hvIGhhdmUg
bm90IHJlc3BvbmRlZCB0byB0aGUKIGFsZXJ0IHBvbGljeS4KChAKCQQAAwAEAAIAARIDMQYf
ChAKCQQAAwAEAAIAAhIDMSIjCjcKCAQAAwAEAAIBEgM0BhMaJiBDdXN0b21lciBpcyBlbnJv
bGxlZCBpbiB0aGlzIHBvbGljeS4KChAKCQQAAwAEAAIBARIDNAYOChAKCQQAAwAEAAIBAhID
NBESCjEKCAQAAwAEAAICEgM3BhMaICBDdXN0b21lciBkZWNsaW5lZCB0aGlzIHBvbGljeS4K
ChAKCQQAAwAEAAICARIDNwYOChAKCQQAAwAEAAICAhIDNxESCsIBCgYEAAMAAgASAz4EGxqy
ASBUaGUgZmVhdHVyZSB0aGF0IHByb3ZpZGVzIGFsZXJ0aW5nIGNhcGFiaWxpdHkuCiBTdXBw
b3J0ZWQgdmFsdWU6CiAtIGBzZWFyY2gtZGF0YS1xdWFsaXR5YCBmb3IgcmV0YWlsIHNlYXJj
aCBjdXN0b21lcnMuCiAtIGBjb252LWRhdGEtcXVhbGl0eWAgZm9yIHJldGFpbCBjb252ZXJz
YXRpb24gY3VzdG9tZXJzLgoKDgoHBAADAAIABRIDPgQKCg4KBwQAAwACAAESAz4LFgoOCgcE
AAMAAgADEgM+GRoKNQoGBAADAAIBEgNBBCMaJiBUaGUgZW5yb2xsbWVudCBzdGF0dXMgb2Yg
YSBjdXN0b21lci4KCg4KBwQAAwACAQYSA0EEEAoOCgcEAAMAAgEBEgNBER4KDgoHBAADAAIB
AxIDQSEiCmQKBgQAAwACAhIDRQQmGlUgUmVjaXBpZW50cyBmb3IgdGhlIGFsZXJ0IHBvbGlj
eS4KIE9uZSBhbGVydCBwb2xpY3kgc2hvdWxkIG5vdCBleGNlZWQgMjAgcmVjaXBpZW50cy4K
Cg4KBwQAAwACAgQSA0UEDAoOCgcEAAMAAgIGEgNFDRYKDgoHBAADAAICARIDRRchCg4KBwQA
AwACAgMSA0UkJQp0CgQEAAIAEgRKAk0EGmYgUmVxdWlyZWQuIEltbXV0YWJsZS4gVGhlIG5h
bWUgb2YgdGhlIEFsZXJ0Q29uZmlnIHNpbmdsZXRvbiByZXNvdXJjZS4KIEZvcm1hdDogcHJv
amVjdHMvKi9hbGVydENvbmZpZwoKDAoFBAACAAUSA0oCCAoMCgUEAAIAARIDSgkNCgwKBQQA
AgADEgNKEBEKDQoFBAACAAgSBEoSTQMKDwoIBAACAAicCAASA0sEKgoPCggEAAIACJwIARID
TAQrCl8KBAQAAgESA1ECKhpSIEFsZXJ0IHBvbGljaWVzIGZvciBhIGN1c3RvbWVyLgogVGhl
eSBtdXN0IGJlIHVuaXF1ZSBieSBbQWxlcnRQb2xpY3kuYWxlcnRfZ3JvdXBdCgoMCgUEAAIB
BBIDUQIKCgwKBQQAAgEGEgNRCxYKDAoFBAACAQESA1EXJQoMCgUEAAIBAxIDUSgpYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2beta::Project::AlertConfig ===
    # Fields for AlertConfig
    # Field: name Type: 9 ()
    # Field: alert_policies Type: 11 (.google.cloud.retail.v2beta.AlertConfig.AlertPolicy)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2beta::Project - Compiled Protocol Buffers messages for google/cloud/retail/v2beta/project.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2beta::Project;

    my $msg = Google::Cloud::Retail::V2beta::Project::AlertConfig->new({
        name => $name,
        alert_policies => $alert_policies,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2beta::Project::AlertConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2beta/project.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2beta::Project::AlertConfig

Project level alert config.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Immutable. The name of the AlertConfig singleton resource.
Format: projects/*/alertConfig

=item * C<< $msg->alert_policies() >> / C<< $msg->alert_policies($value) >>

Type: C<Message> (L<Google::Cloud::Retail::V2beta::Project::AlertConfig::AlertPolicy>)

Alert policies for a customer.
They must be unique by [AlertPolicy.alert_group]

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2beta::Project::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
