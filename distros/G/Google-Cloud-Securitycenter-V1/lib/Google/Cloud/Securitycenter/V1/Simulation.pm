package Google::Cloud::Securitycenter::V1::Simulation;

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
    eval { require Google::Cloud::Securitycenter::V1::Resource };
    eval { require Google::Cloud::Securitycenter::V1::ValuedResource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvc2ltdWxhdGlvbi5wcm90bxIeZ29v
Z2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGi1nb29nbGUvY2xvdWQvc2VjdXJp
dHljZW50ZXIvdjEvcmVzb3VyY2UucHJvdG8aNGdvb2dsZS9jbG91ZC9zZWN1cml0eWNlbnRl
ci92MS92YWx1ZWRfcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAu
cHJvdG8ivAMKClNpbXVsYXRpb24SEgoEbmFtZRgBIAEoCVIEbmFtZRJACgtjcmVhdGVfdGlt
ZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRKC
AQofcmVzb3VyY2VfdmFsdWVfY29uZmlnc19tZXRhZGF0YRgDIAMoCzI7Lmdvb2dsZS5jbG91
ZC5zZWN1cml0eWNlbnRlci52MS5SZXNvdXJjZVZhbHVlQ29uZmlnTWV0YWRhdGFSHHJlc291
cmNlVmFsdWVDb25maWdzTWV0YWRhdGESVAoOY2xvdWRfcHJvdmlkZXIYBCABKA4yLS5nb29n
bGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEuQ2xvdWRQcm92aWRlclINY2xvdWRQcm92aWRl
cjp96kF6CihzZWN1cml0eWNlbnRlci5nb29nbGVhcGlzLmNvbS9TaW11bGF0aW9uEjVvcmdh
bml6YXRpb25zL3tvcmdhbml6YXRpb259L3NpbXVsYXRpb25zL3tzaW11bGF0aW9ufSoLc2lt
dWxhdGlvbnMyCnNpbXVsYXRpb25C6QEKImNvbS5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50
ZXIudjFCD1NpbXVsYXRpb25Qcm90b1ABWkpjbG91ZC5nb29nbGUuY29tL2dvL3NlY3VyaXR5
Y2VudGVyL2FwaXYxL3NlY3VyaXR5Y2VudGVycGI7c2VjdXJpdHljZW50ZXJwYqoCHkdvb2ds
ZS5DbG91ZC5TZWN1cml0eUNlbnRlci5WMcoCHkdvb2dsZVxDbG91ZFxTZWN1cml0eUNlbnRl
clxWMeoCIUdvb2dsZTo6Q2xvdWQ6OlNlY3VyaXR5Q2VudGVyOjpWMUqBCwoGEgQOADcBCrwE
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
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAnCgkKAgMAEgMSACkK
CQoCAwESAxMAIwoJCgIDAhIDFAA3CgkKAgMDEgMVAD4KCQoCAwQSAxYAKQoICgEIEgMYADsK
CQoCCCUSAxgAOwoICgEIEgMZAGEKCQoCCAsSAxkAYQoICgEIEgMaACIKCQoCCAoSAxoAIgoI
CgEIEgMbADAKCQoCCAgSAxsAMAoICgEIEgMcADsKCQoCCAESAxwAOwoICgEIEgMdADsKCQoC
CCkSAx0AOwoICgEIEgMeADoKCQoCCC0SAx4AOgokCgIEABIEIQA3ARoYIEF0dGFjayBwYXRo
IHNpbXVsYXRpb24KCgoKAwQAARIDIQgSCgsKAwQABxIEIgInBAoNCgUEAAedCBIEIgInBApZ
CgQEAAIAEgMrAhIaTCBGdWxsIHJlc291cmNlIG5hbWUgb2YgdGhlIFNpbXVsYXRpb246CiBg
b3JnYW5pemF0aW9ucy8xMjMvc2ltdWxhdGlvbnMvNDU2YAoKDAoFBAACAAUSAysCCAoMCgUE
AAIAARIDKwkNCgwKBQQAAgADEgMrEBEKOAoEBAACARIELgIvMhoqIE91dHB1dCBvbmx5LiBU
aW1lIHNpbXVsYXRpb24gd2FzIGNyZWF0ZWQKCgwKBQQAAgEGEgMuAhsKDAoFBAACAQESAy4c
JwoMCgUEAAIBAxIDLiorCgwKBQQAAgEIEgMvBjEKDwoIBAACAQicCAASAy8HMApgCgQEAAIC
EgMzAksaUyBSZXNvdXJjZSB2YWx1ZSBjb25maWd1cmF0aW9ucycgbWV0YWRhdGEgdXNlZCBp
biB0aGlzIHNpbXVsYXRpb24uIE1heGltdW0gb2YKIDEwMC4KCgwKBQQAAgIEEgMzAgoKDAoF
BAACAgYSAzMLJgoMCgUEAAICARIDMydGCgwKBQQAAgIDEgMzSUoKSgoEBAACAxIDNgIjGj0g
SW5kaWNhdGVzIHdoaWNoIGNsb3VkIHByb3ZpZGVyIHdhcyB1c2VkIGluIHRoaXMgc2ltdWxh
dGlvbi4KCgwKBQQAAgMGEgM2Ag8KDAoFBAACAwESAzYQHgoMCgUEAAIDAxIDNiEiYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::Simulation::Simulation ===
    # Fields for Simulation
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: resource_value_configs_metadata Type: 11 (.google.cloud.securitycenter.v1.ResourceValueConfigMetadata)
    # Field: cloud_provider Type: 14 (.google.cloud.securitycenter.v1.CloudProvider)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::Simulation - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/simulation.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::Simulation;

    my $msg = Google::Cloud::Securitycenter::V1::Simulation::Simulation->new({
        name => $name,
        create_time => $create_time,
        resource_value_configs_metadata => $resource_value_configs_metadata,
        cloud_provider => $cloud_provider,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::Simulation::Simulation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/simulation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::Simulation::Simulation

Attack path simulation

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Full resource name of the Simulation:
`organizations/123/simulations/456`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time simulation was created

=item * C<< $msg->resource_value_configs_metadata() >> / C<< $msg->resource_value_configs_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::ValuedResource::ResourceValueConfigMetadata>)

Resource value configurations' metadata used in this simulation. Maximum of
100.

=item * C<< $msg->cloud_provider() >> / C<< $msg->cloud_provider($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V1::CloudProvider>)

Indicates which cloud provider was used in this simulation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::Simulation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
