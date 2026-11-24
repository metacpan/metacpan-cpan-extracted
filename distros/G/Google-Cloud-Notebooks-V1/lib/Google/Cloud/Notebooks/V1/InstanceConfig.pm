package Google::Cloud::Notebooks::V1::InstanceConfig;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvbm90ZWJvb2tzL3YxL2luc3RhbmNlX2NvbmZpZy5wcm90bxIZZ29v
Z2xlLmNsb3VkLm5vdGVib29rcy52MSKGAQoOSW5zdGFuY2VDb25maWcSOgoZbm90ZWJvb2tf
dXBncmFkZV9zY2hlZHVsZRgBIAEoCVIXbm90ZWJvb2tVcGdyYWRlU2NoZWR1bGUSOAoYZW5h
YmxlX2hlYWx0aF9tb25pdG9yaW5nGAIgASgIUhZlbmFibGVIZWFsdGhNb25pdG9yaW5nQsoB
Ch1jb20uZ29vZ2xlLmNsb3VkLm5vdGVib29rcy52MUITSW5zdGFuY2VDb25maWdQcm90b1AB
WjtjbG91ZC5nb29nbGUuY29tL2dvL25vdGVib29rcy9hcGl2MS9ub3RlYm9va3NwYjtub3Rl
Ym9va3NwYqoCGUdvb2dsZS5DbG91ZC5Ob3RlYm9va3MuVjHKAhlHb29nbGVcQ2xvdWRcTm90
ZWJvb2tzXFYx6gIcR29vZ2xlOjpDbG91ZDo6Tm90ZWJvb2tzOjpWMUrnCAoGEgQOACIBCrwE
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
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAiCggKAQgSAxIANgoJ
CgIIJRIDEgA2CggKAQgSAxMAUgoJCgIICxIDEwBSCggKAQgSAxQAIgoJCgIIChIDFAAiCggK
AQgSAxUANAoJCgIICBIDFQA0CggKAQgSAxYANgoJCgIIARIDFgA2CggKAQgSAxcANgoJCgII
KRIDFwA2CggKAQgSAxgANQoJCgIILRIDGAA1CkMKAgQAEgQbACIBGjcgTm90ZWJvb2sgaW5z
dGFuY2UgY29uZmlndXJhdGlvbnMgdGhhdCBjYW4gYmUgdXBkYXRlZC4KCgoKAwQAARIDGwgW
Cp4BCgQEAAIAEgMeAicakAEgQ3JvbiBleHByZXNzaW9uIGluIFVUQyB0aW1lem9uZSwgdXNl
ZCB0byBzY2hlZHVsZSBpbnN0YW5jZSBhdXRvIHVwZ3JhZGUuCiBQbGVhc2UgZm9sbG93IHRo
ZSBbY3JvbiBmb3JtYXRdKGh0dHBzOi8vZW4ud2lraXBlZGlhLm9yZy93aWtpL0Nyb24pLgoK
DAoFBAACAAUSAx4CCAoMCgUEAAIAARIDHgkiCgwKBQQAAgADEgMeJSYKOwoEBAACARIDIQIk
Gi4gVmVyaWZpZXMgY29yZSBpbnRlcm5hbCBzZXJ2aWNlcyBhcmUgcnVubmluZy4KCgwKBQQA
AgEFEgMhAgYKDAoFBAACAQESAyEHHwoMCgUEAAIBAxIDISIjYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Notebooks::V1::InstanceConfig::InstanceConfig ===
    # Fields for InstanceConfig
    # Field: notebook_upgrade_schedule Type: 9 ()
    # Field: enable_health_monitoring Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Notebooks::V1::InstanceConfig - Compiled Protocol Buffers messages for google/cloud/notebooks/v1/instance_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Notebooks::V1::InstanceConfig;

    my $msg = Google::Cloud::Notebooks::V1::InstanceConfig::InstanceConfig->new({
        notebook_upgrade_schedule => $notebook_upgrade_schedule,
        enable_health_monitoring => $enable_health_monitoring,
    });

    # Read or update a field
    my $val = $msg->notebook_upgrade_schedule();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Notebooks::V1::InstanceConfig::InstanceConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/notebooks/v1/instance_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Notebooks::V1::InstanceConfig::InstanceConfig

Notebook instance configurations that can be updated.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->notebook_upgrade_schedule() >> / C<< $msg->notebook_upgrade_schedule($value) >>

Type: C<String>

Cron expression in UTC timezone, used to schedule instance auto upgrade.
Please follow the [cron format](https://en.wikipedia.org/wiki/Cron).

=item * C<< $msg->enable_health_monitoring() >> / C<< $msg->enable_health_monitoring($value) >>

Type: C<Bool>

Verifies core internal services are running.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Notebooks::V1::InstanceConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
