package Google::Cloud::Securitycenter::V2::Simulation;

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
    eval { require Google::Cloud::Securitycenter::V2::Resource };
    eval { require Google::Cloud::Securitycenter::V2::ValuedResource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvc2ltdWxhdGlvbi5wcm90bxIeZ29v
Z2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGi1nb29nbGUvY2xvdWQvc2VjdXJp
dHljZW50ZXIvdjIvcmVzb3VyY2UucHJvdG8aNGdvb2dsZS9jbG91ZC9zZWN1cml0eWNlbnRl
ci92Mi92YWx1ZWRfcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAu
cHJvdG8iigQKClNpbXVsYXRpb24SEgoEbmFtZRgBIAEoCVIEbmFtZRJACgtjcmVhdGVfdGlt
ZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRKC
AQofcmVzb3VyY2VfdmFsdWVfY29uZmlnc19tZXRhZGF0YRgDIAMoCzI7Lmdvb2dsZS5jbG91
ZC5zZWN1cml0eWNlbnRlci52Mi5SZXNvdXJjZVZhbHVlQ29uZmlnTWV0YWRhdGFSHHJlc291
cmNlVmFsdWVDb25maWdzTWV0YWRhdGESVAoOY2xvdWRfcHJvdmlkZXIYBCABKA4yLS5nb29n
bGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIuQ2xvdWRQcm92aWRlclINY2xvdWRQcm92aWRl
cjrKAepBxgEKKHNlY3VyaXR5Y2VudGVyLmdvb2dsZWFwaXMuY29tL1NpbXVsYXRpb24SNW9y
Z2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vc2ltdWxhdGlvbnMve3NpbXVsYXRpb259Ekpv
cmdhbml6YXRpb25zL3tvcmdhbml6YXRpb259L2xvY2F0aW9ucy97bG9jYXRpb259L3NpbXVs
YXRpb25zL3tzaW1sdWF0aW9ufSoLc2ltdWxhdGlvbnMyCnNpbXVsYXRpb25C6QEKImNvbS5n
b29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjJCD1NpbXVsYXRpb25Qcm90b1ABWkpjbG91
ZC5nb29nbGUuY29tL2dvL3NlY3VyaXR5Y2VudGVyL2FwaXYyL3NlY3VyaXR5Y2VudGVycGI7
c2VjdXJpdHljZW50ZXJwYqoCHkdvb2dsZS5DbG91ZC5TZWN1cml0eUNlbnRlci5WMsoCHkdv
b2dsZVxDbG91ZFxTZWN1cml0eUNlbnRlclxWMuoCIUdvb2dsZTo6Q2xvdWQ6OlNlY3VyaXR5
Q2VudGVyOjpWMkqBCwoGEgQOADgBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAnCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAA3CgkKAgMDEgMV
AD4KCQoCAwQSAxYAKQoICgEIEgMYADsKCQoCCCUSAxgAOwoICgEIEgMZAGEKCQoCCAsSAxkA
YQoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbADAKCQoCCAgSAxsAMAoICgEIEgMcADsK
CQoCCAESAxwAOwoICgEIEgMdADsKCQoCCCkSAx0AOwoICgEIEgMeADoKCQoCCC0SAx4AOgok
CgIEABIEIQA4ARoYIEF0dGFjayBwYXRoIHNpbXVsYXRpb24KCgoKAwQAARIDIQgSCgsKAwQA
BxIEIgIoBAoNCgUEAAedCBIEIgIoBApZCgQEAAIAEgMsAhIaTCBGdWxsIHJlc291cmNlIG5h
bWUgb2YgdGhlIFNpbXVsYXRpb246CiBgb3JnYW5pemF0aW9ucy8xMjMvc2ltdWxhdGlvbnMv
NDU2YAoKDAoFBAACAAUSAywCCAoMCgUEAAIAARIDLAkNCgwKBQQAAgADEgMsEBEKOAoEBAAC
ARIELwIwMhoqIE91dHB1dCBvbmx5LiBUaW1lIHNpbXVsYXRpb24gd2FzIGNyZWF0ZWQKCgwK
BQQAAgEGEgMvAhsKDAoFBAACAQESAy8cJwoMCgUEAAIBAxIDLyorCgwKBQQAAgEIEgMwBjEK
DwoIBAACAQicCAASAzAHMApgCgQEAAICEgM0AksaUyBSZXNvdXJjZSB2YWx1ZSBjb25maWd1
cmF0aW9ucycgbWV0YWRhdGEgdXNlZCBpbiB0aGlzIHNpbXVsYXRpb24uIE1heGltdW0gb2YK
IDEwMC4KCgwKBQQAAgIEEgM0AgoKDAoFBAACAgYSAzQLJgoMCgUEAAICARIDNCdGCgwKBQQA
AgIDEgM0SUoKSgoEBAACAxIDNwIjGj0gSW5kaWNhdGVzIHdoaWNoIGNsb3VkIHByb3ZpZGVy
IHdhcyB1c2VkIGluIHRoaXMgc2ltdWxhdGlvbi4KCgwKBQQAAgMGEgM3Ag8KDAoFBAACAwES
AzcQHgoMCgUEAAIDAxIDNyEiYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::Simulation::Simulation ===
    # Fields for Simulation
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: resource_value_configs_metadata Type: 11 (.google.cloud.securitycenter.v2.ResourceValueConfigMetadata)
    # Field: cloud_provider Type: 14 (.google.cloud.securitycenter.v2.CloudProvider)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::Simulation - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/simulation.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::Simulation;

    my $msg = Google::Cloud::Securitycenter::V2::Simulation::Simulation->new({
        name => $name,
        create_time => $create_time,
        resource_value_configs_metadata => $resource_value_configs_metadata,
        cloud_provider => $cloud_provider,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::Simulation::Simulation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/simulation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::Simulation::Simulation

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

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::ValuedResource::ResourceValueConfigMetadata>)

Resource value configurations' metadata used in this simulation. Maximum of
100.

=item * C<< $msg->cloud_provider() >> / C<< $msg->cloud_provider($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V2::CloudProvider>)

Indicates which cloud provider was used in this simulation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::Simulation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
