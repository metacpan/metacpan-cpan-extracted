package Google::Cloud::Integrations::V1alpha::CloudLoggingDetails;

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
Cj1nb29nbGUvY2xvdWQvaW50ZWdyYXRpb25zL3YxYWxwaGEvY2xvdWRfbG9nZ2luZ19kZXRh
aWxzLnByb3RvEiFnb29nbGUuY2xvdWQuaW50ZWdyYXRpb25zLnYxYWxwaGEaH2dvb2dsZS9h
cGkvZmllbGRfYmVoYXZpb3IucHJvdG8i9QIKE0Nsb3VkTG9nZ2luZ0RldGFpbHMSiwEKFmNs
b3VkX2xvZ2dpbmdfc2V2ZXJpdHkYASABKA4ySy5nb29nbGUuY2xvdWQuaW50ZWdyYXRpb25z
LnYxYWxwaGEuQ2xvdWRMb2dnaW5nRGV0YWlscy5DbG91ZExvZ2dpbmdTZXZlcml0eUID4EEB
SABSFGNsb3VkTG9nZ2luZ1NldmVyaXR5iAEBEjoKFGVuYWJsZV9jbG91ZF9sb2dnaW5nGAIg
ASgIQgPgQQFIAVISZW5hYmxlQ2xvdWRMb2dnaW5niAEBImAKFENsb3VkTG9nZ2luZ1NldmVy
aXR5EiYKIkNMT1VEX0xPR0dJTkdfU0VWRVJJVFlfVU5TUEVDSUZJRUQQABIICgRJTkZPEAIS
CQoFRVJST1IQAxILCgdXQVJOSU5HEARCGQoXX2Nsb3VkX2xvZ2dpbmdfc2V2ZXJpdHlCFwoV
X2VuYWJsZV9jbG91ZF9sb2dnaW5nQrIBCiVjb20uZ29vZ2xlLmNsb3VkLmludGVncmF0aW9u
cy52MWFscGhhQhhDbG91ZExvZ2dpbmdEZXRhaWxzUHJvdG9QAVpJY2xvdWQuZ29vZ2xlLmNv
bS9nby9pbnRlZ3JhdGlvbnMvYXBpdjFhbHBoYS9pbnRlZ3JhdGlvbnNwYjtpbnRlZ3JhdGlv
bnNwYqoCIUdvb2dsZS5DbG91ZC5JbnRlZ3JhdGlvbnMuVjFBbHBoYUrVDwoGEgQOADgBCrwE
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
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAqCgkKAgMAEgMSACkK
CAoBCBIDFAA+CgkKAgglEgMUAD4KCAoBCBIDFQBgCgkKAggLEgMVAGAKCAoBCBIDFgAiCgkK
AggKEgMWACIKCAoBCBIDFwA5CgkKAggIEgMXADkKCAoBCBIDGAA+CgkKAggBEgMYAD4KNgoC
BAASBBsAOAEaKiBDbG91ZCBMb2dnaW5nIGRldGFpbHMgZm9yIGV4ZWN1dGlvbiBpbmZvCgoK
CgMEAAESAxsIGwpPCgQEAAQAEgQdAi0DGkEgVGhlIHNldmVyaXR5IHdpbGwgYmUgbWFwcGVk
IHRvIHRoZSBJbnRlZ3JhdGlvbiBFeGVjdXRpb24gU3RhdGUuCgoMCgUEAAQAARIDHQcbChwK
BgQABAACABIDHwQrGg0gVW5zcGVjaWZpZWQKCg4KBwQABAACAAESAx8EJgoOCgcEAAQAAgAC
EgMfKSoKxgEKBgQABAACARIDJAQNGrYBIElmIFNldmVyaXR5IHNlbGVjdGVkIGlzIGBJTkZP
YCwgdGhlbiBhbGwgdGhlIEludGVncmF0aW9uIEV4ZWN1dGlvbiBTdGF0ZXMKIChgSU5fUFJP
Q0VTU2AsIGBPTl9IT0xEYCwgYFNVQ0NFRURFRGAsIGBTVVNQRU5ERURgLCBgRVJST1JgLCBg
Q0FOQ0VMTEVEYCkKIHdpbGwgYmUgc2VudCB0byBDbG91ZCBMb2dnaW5nLgoKDgoHBAAEAAIB
ARIDJAQICg4KBwQABAACAQISAyQLDAqeAQoGBAAEAAICEgMoBA4ajgEgSWYgU2V2ZXJpdHkg
c2VsZWN0ZWQgaXMgYEVSUk9SYCwgdGhlbiBvbmx5IHRoZSBmb2xsb3dpbmcgSW50ZWdyYXRp
b24KIEV4ZWN1dGlvbiBTdGF0ZXMgKGBFUlJPUmAsIGBDQU5DRUxMRURgKSB3aWxsIGJlIHNl
bnQgdG8gQ2xvdWQgTG9nZ2luZy4KCg4KBwQABAACAgESAygECQoOCgcEAAQAAgICEgMoDA0K
oAEKBgQABAACAxIDLAQQGpABIElmIFNldmVyaXR5IHNlbGVjdGVkIGlzIGBXQVJOSU5HYCwg
dGhlbiBvbmx5IHRoZSBmb2xsb3dpbmcgSW50ZWdyYXRpb24KIEV4ZWN1dGlvbiBTdGF0ZXMg
KGBFUlJPUmAsIGBDQU5DRUxMRURgKSB3aWxsIGJlIHNlbnQgdG8gQ2xvdWQgTG9nZ2luZy4K
Cg4KBwQABAACAwESAywECwoOCgcEAAQAAgMCEgMsDg8KlQEKBAQAAgASBDECMi8ahgEgT3B0
aW9uYWwuIFNldmVyaXR5IHNlbGVjdGVkIGJ5IHRoZSBjdXN0b21lciBmb3IgdGhlIGxvZ3Mg
dG8gYmUgc2VudCB0bwogQ2xvdWQgTG9nZ2luZywgZm9yIHRoZSBpbnRlZ3JhdGlvbiB2ZXJz
aW9uIGdldHRpbmcgZXhlY3V0ZWQuCgoMCgUEAAIABBIDMQIKCgwKBQQAAgAGEgMxCx8KDAoF
BAACAAESAzEgNgoMCgUEAAIAAxIDMTk6CgwKBQQAAgAIEgMyBi4KDwoIBAACAAicCAASAzIH
LQp6CgQEAAIBEgQ2AjcvGmwgT3B0aW9uYWwuIFN0YXR1cyBvZiB3aGV0aGVyIENsb3VkIExv
Z2dpbmcgaXMgZW5hYmxlZCBvciBub3QgZm9yIHRoZQogaW50ZWdyYXRpb24gdmVyc2lvbiBn
ZXR0aW5nIGV4ZWN1dGVkLgoKDAoFBAACAQQSAzYCCgoMCgUEAAIBBRIDNgsPCgwKBQQAAgEB
EgM2ECQKDAoFBAACAQMSAzYnKAoMCgUEAAIBCBIDNwYuCg8KCAQAAgEInAgAEgM3By1iBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Integrations::V1alpha::CloudLoggingDetails::CloudLoggingDetails ===
    # Fields for CloudLoggingDetails
    # Field: cloud_logging_severity Type: 14 (.google.cloud.integrations.v1alpha.CloudLoggingDetails.CloudLoggingSeverity)
    # Field: enable_cloud_logging Type: 8 ()

# Enum: CloudLoggingDetails::CloudLoggingSeverity
our $CloudLoggingDetails_CLOUD_LOGGING_SEVERITY_UNSPECIFIED = 0;
our $CloudLoggingDetails_INFO = 2;
our $CloudLoggingDetails_ERROR = 3;
our $CloudLoggingDetails_WARNING = 4;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Integrations::V1alpha::CloudLoggingDetails - Compiled Protocol Buffers messages for google/cloud/integrations/v1alpha/cloud_logging_details.proto

=head1 SYNOPSIS

    use Google::Cloud::Integrations::V1alpha::CloudLoggingDetails;

    my $msg = Google::Cloud::Integrations::V1alpha::CloudLoggingDetails::CloudLoggingDetails->new({
        cloud_logging_severity => $cloud_logging_severity,
        enable_cloud_logging => $enable_cloud_logging,
    });

    # Read or update a field
    my $val = $msg->cloud_logging_severity();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Integrations::V1alpha::CloudLoggingDetails::CloudLoggingDetails->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/integrations/v1alpha/cloud_logging_details.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Integrations::V1alpha::CloudLoggingDetails::CloudLoggingDetails

Cloud Logging details for execution info

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cloud_logging_severity() >> / C<< $msg->cloud_logging_severity($value) >>

Type: C<Enum> (L<Google::Cloud::Integrations::V1alpha::CloudLoggingDetails::CloudLoggingSeverity>)

Optional. Severity selected by the customer for the logs to be sent to
Cloud Logging, for the integration version getting executed.

=item * C<< $msg->enable_cloud_logging() >> / C<< $msg->enable_cloud_logging($value) >>

Type: C<Bool>

Optional. Status of whether Cloud Logging is enabled or not for the
integration version getting executed.

=back

=head3 Enum: CloudLoggingDetails::CloudLoggingSeverity

=over 4

=item * C<CLOUD_LOGGING_SEVERITY_UNSPECIFIED> => C<0>

=item * C<INFO> => C<2>

=item * C<ERROR> => C<3>

=item * C<WARNING> => C<4>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Integrations::V1alpha::CloudLoggingDetails::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
