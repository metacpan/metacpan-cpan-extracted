package Google::Cloud::Eventarc::V1::LoggingConfig;

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
Ci1nb29nbGUvY2xvdWQvZXZlbnRhcmMvdjEvbG9nZ2luZ19jb25maWcucHJvdG8SGGdvb2ds
ZS5jbG91ZC5ldmVudGFyYy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90byKF
AgoNTG9nZ2luZ0NvbmZpZxJbCgxsb2dfc2V2ZXJpdHkYASABKA4yMy5nb29nbGUuY2xvdWQu
ZXZlbnRhcmMudjEuTG9nZ2luZ0NvbmZpZy5Mb2dTZXZlcml0eUID4EEBUgtsb2dTZXZlcml0
eSKWAQoLTG9nU2V2ZXJpdHkSHAoYTE9HX1NFVkVSSVRZX1VOU1BFQ0lGSUVEEAASCAoETk9O
RRABEgkKBURFQlVHEAISCAoESU5GTxADEgoKBk5PVElDRRAEEgsKB1dBUk5JTkcQBRIJCgVF
UlJPUhAGEgwKCENSSVRJQ0FMEAcSCQoFQUxFUlQQCBINCglFTUVSR0VOQ1kQCULCAQocY29t
Lmdvb2dsZS5jbG91ZC5ldmVudGFyYy52MUISTG9nZ2luZ0NvbmZpZ1Byb3RvUAFaOGNsb3Vk
Lmdvb2dsZS5jb20vZ28vZXZlbnRhcmMvYXBpdjEvZXZlbnRhcmNwYjtldmVudGFyY3BiqgIY
R29vZ2xlLkNsb3VkLkV2ZW50YXJjLlYxygIYR29vZ2xlXENsb3VkXEV2ZW50YXJjXFYx6gIb
R29vZ2xlOjpDbG91ZDo6RXZlbnRhcmM6OlYxSq8TCgYSBA4ASwEKvAQKAQwSAw4AEjKxBCBD
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
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACEKCQoCAwASAxIAKQoICgEIEgMUADUKCQoC
CCUSAxQANQoICgEIEgMVAE8KCQoCCAsSAxUATwoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEI
EgMXADMKCQoCCAgSAxcAMwoICgEIEgMYADUKCQoCCAESAxgANQoICgEIEgMZADUKCQoCCCkS
AxkANQoICgEIEgMaADQKCQoCCC0SAxoANApgCgIEABIEHgBLARpUIFRoZSBjb25maWd1cmF0
aW9uIGZvciBQbGF0Zm9ybSBUZWxlbWV0cnkgbG9nZ2luZyBmb3IgRXZlbnRhcmMgQWR2YW5j
ZWQKIHJlc291cmNlcy4KCgoKAwQAARIDHggVCskBCgQEAAQAEgQjAkUDGroBIFRoZSBkaWZm
ZXJlbnQgc2V2ZXJpdGllcyBmb3IgbG9nZ2luZyBzdXBwb3J0ZWQgYnkgRXZlbnRhcmMgQWR2
YW5jZWQKIHJlc291cmNlcy4KIFRoaXMgZW51bSBpcyBhbiBleGhhdXN0aXZlIGxpc3Qgb2Yg
bG9nIHNldmVyaXRpZXMgYW5kIGlzIEZST1pFTi4gRG8gbm90CiBleHBlY3QgbmV3IHZhbHVl
cyB0byBiZSBhZGRlZC4KCgwKBQQABAABEgMjBxIKqwEKBgQABAACABIDJwQhGpsBIExvZyBz
ZXZlcml0eSBpcyBub3Qgc3BlY2lmaWVkLiBUaGlzIHZhbHVlIGlzIHRyZWF0ZWQgdGhlIHNh
bWUgYXMgTk9ORSwKIGJ1dCBpcyB1c2VkIHRvIGRpc3Rpbmd1aXNoIGJldHdlZW4gbm8gdXBk
YXRlIGFuZCB1cGRhdGUgdG8gTk9ORSBpbgogdXBkYXRlX21hc2tzLgoKDgoHBAAEAAIAARID
JwQcCg4KBwQABAACAAISAycfIAp7CgYEAAQAAgESAysEDRpsIERlZmF1bHQgdmFsdWUgYXQg
cmVzb3VyY2UgY3JlYXRpb24sIHByZXNlbmNlIG9mIHRoaXMgdmFsdWUgbXVzdCBiZQogdHJl
YXRlZCBhcyBubyBsb2dnaW5nL2Rpc2FibGUgbG9nZ2luZy4KCg4KBwQABAACAQESAysECAoO
CgcEAAQAAgECEgMrCwwKLgoGBAAEAAICEgMuBA4aHyBEZWJ1ZyBvciB0cmFjZSBsZXZlbCBs
b2dnaW5nLgoKDgoHBAAEAAICARIDLgQJCg4KBwQABAACAgISAy4MDQpMCgYEAAQAAgMSAzEE
DRo9IFJvdXRpbmUgaW5mb3JtYXRpb24sIHN1Y2ggYXMgb25nb2luZyBzdGF0dXMgb3IgcGVy
Zm9ybWFuY2UuCgoOCgcEAAQAAgMBEgMxBAgKDgoHBAAEAAIDAhIDMQsMCmgKBgQABAACBBID
NQQPGlkgTm9ybWFsIGJ1dCBzaWduaWZpY2FudCBldmVudHMsIHN1Y2ggYXMgc3RhcnQgdXAs
IHNodXQgZG93biwgb3IgYQogY29uZmlndXJhdGlvbiBjaGFuZ2UuCgoOCgcEAAQAAgQBEgM1
BAoKDgoHBAAEAAIEAhIDNQ0OCjUKBgQABAACBRIDOAQQGiYgV2FybmluZyBldmVudHMgbWln
aHQgY2F1c2UgcHJvYmxlbXMuCgoOCgcEAAQAAgUBEgM4BAsKDgoHBAAEAAIFAhIDOA4PCjsK
BgQABAACBhIDOwQOGiwgRXJyb3IgZXZlbnRzIGFyZSBsaWtlbHkgdG8gY2F1c2UgcHJvYmxl
bXMuCgoOCgcEAAQAAgYBEgM7BAkKDgoHBAAEAAIGAhIDOwwNCkcKBgQABAACBxIDPgQRGjgg
Q3JpdGljYWwgZXZlbnRzIGNhdXNlIG1vcmUgc2V2ZXJlIHByb2JsZW1zIG9yIG91dGFnZXMu
CgoOCgcEAAQAAgcBEgM+BAwKDgoHBAAEAAIHAhIDPg8QCjcKBgQABAACCBIDQQQOGiggQSBw
ZXJzb24gbXVzdCB0YWtlIGFjdGlvbiBpbW1lZGlhdGVseS4KCg4KBwQABAACCAESA0EECQoO
CgcEAAQAAggCEgNBDA0KMgoGBAAEAAIJEgNEBBIaIyBPbmUgb3IgbW9yZSBzeXN0ZW1zIGFy
ZSB1bnVzYWJsZS4KCg4KBwQABAACCQESA0QEDQoOCgcEAAQAAgkCEgNEEBEKrwEKBAQAAgAS
A0oCSBqhASBPcHRpb25hbC4gVGhlIG1pbmltdW0gc2V2ZXJpdHkgb2YgbG9ncyB0aGF0IHdp
bGwgYmUgc2VudCB0bwogU3RhY2tkcml2ZXIvUGxhdGZvcm0gVGVsZW1ldHJ5LiBMb2dzIGF0
IHNldmVyaXRpeSDiiaUgdGhpcyB2YWx1ZSB3aWxsIGJlCiBzZW50LCB1bmxlc3MgaXQgaXMg
Tk9ORS4KCgwKBQQAAgAGEgNKAg0KDAoFBAACAAESA0oOGgoMCgUEAAIAAxIDSh0eCgwKBQQA
AgAIEgNKH0cKDwoIBAACAAicCAASA0ogRmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Eventarc::V1::LoggingConfig::LoggingConfig ===
    # Fields for LoggingConfig
    # Field: log_severity Type: 14 (.google.cloud.eventarc.v1.LoggingConfig.LogSeverity)

# Enum: LoggingConfig::LogSeverity
our $LoggingConfig_LOG_SEVERITY_UNSPECIFIED = 0;
our $LoggingConfig_NONE = 1;
our $LoggingConfig_DEBUG = 2;
our $LoggingConfig_INFO = 3;
our $LoggingConfig_NOTICE = 4;
our $LoggingConfig_WARNING = 5;
our $LoggingConfig_ERROR = 6;
our $LoggingConfig_CRITICAL = 7;
our $LoggingConfig_ALERT = 8;
our $LoggingConfig_EMERGENCY = 9;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Eventarc::V1::LoggingConfig - Compiled Protocol Buffers messages for google/cloud/eventarc/v1/logging_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Eventarc::V1::LoggingConfig;

    my $msg = Google::Cloud::Eventarc::V1::LoggingConfig::LoggingConfig->new({
        log_severity => $log_severity,
    });

    # Read or update a field
    my $val = $msg->log_severity();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Eventarc::V1::LoggingConfig::LoggingConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/eventarc/v1/logging_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Eventarc::V1::LoggingConfig::LoggingConfig

The configuration for Platform Telemetry logging for Eventarc Advanced
resources.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->log_severity() >> / C<< $msg->log_severity($value) >>

Type: C<Enum> (L<Google::Cloud::Eventarc::V1::LoggingConfig::LogSeverity>)

Optional. The minimum severity of logs that will be sent to
Stackdriver/Platform Telemetry. Logs at severitiy ≥ this value will be
sent, unless it is NONE.

=back

=head3 Enum: LoggingConfig::LogSeverity

=over 4

=item * C<LOG_SEVERITY_UNSPECIFIED> => C<0>

=item * C<NONE> => C<1>

=item * C<DEBUG> => C<2>

=item * C<INFO> => C<3>

=item * C<NOTICE> => C<4>

=item * C<WARNING> => C<5>

=item * C<ERROR> => C<6>

=item * C<CRITICAL> => C<7>

=item * C<ALERT> => C<8>

=item * C<EMERGENCY> => C<9>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Eventarc::V1::LoggingConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
