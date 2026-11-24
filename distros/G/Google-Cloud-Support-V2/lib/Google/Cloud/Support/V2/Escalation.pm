package Google::Cloud::Support::V2::Escalation;

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
Cihnb29nbGUvY2xvdWQvc3VwcG9ydC92Mi9lc2NhbGF0aW9uLnByb3RvEhdnb29nbGUuY2xv
dWQuc3VwcG9ydC52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90byLlAQoKRXNj
YWxhdGlvbhJHCgZyZWFzb24YBCABKA4yKi5nb29nbGUuY2xvdWQuc3VwcG9ydC52Mi5Fc2Nh
bGF0aW9uLlJlYXNvbkID4EECUgZyZWFzb24SKQoNanVzdGlmaWNhdGlvbhgFIAEoCUID4EEC
Ug1qdXN0aWZpY2F0aW9uImMKBlJlYXNvbhIWChJSRUFTT05fVU5TUEVDSUZJRUQQABITCg9S
RVNPTFVUSU9OX1RJTUUQARIXChNURUNITklDQUxfRVhQRVJUSVNFEAISEwoPQlVTSU5FU1Nf
SU1QQUNUEANCuAEKG2NvbS5nb29nbGUuY2xvdWQuc3VwcG9ydC52MkIPRXNjYWxhdGlvblBy
b3RvUAFaNWNsb3VkLmdvb2dsZS5jb20vZ28vc3VwcG9ydC9hcGl2Mi9zdXBwb3J0cGI7c3Vw
cG9ydHBiqgIXR29vZ2xlLkNsb3VkLlN1cHBvcnQuVjLKAhdHb29nbGVcQ2xvdWRcU3VwcG9y
dFxWMuoCGkdvb2dsZTo6Q2xvdWQ6OlN1cHBvcnQ6OlYySsQNCgYSBA4ANAEKvAQKAQwSAw4A
EjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACAKCQoCAwASAxIAKQoICgEIEgMU
ADQKCQoCCCUSAxQANAoICgEIEgMVAEwKCQoCCAsSAxUATAoICgEIEgMWACIKCQoCCAoSAxYA
IgoICgEIEgMXADAKCQoCCAgSAxcAMAoICgEIEgMYADQKCQoCCAESAxgANAoICgEIEgMZADQK
CQoCCCkSAxkANAoICgEIEgMaADMKCQoCCC0SAxoAMwouCgIEABIEHQA0ARoiIEFuIGVzY2Fs
YXRpb24gb2YgYSBzdXBwb3J0IGNhc2UuCgoKCgMEAAESAx0IEgpPCgQEAAQAEgQfAiwDGkEg
QW4gZW51bSBkZXRhaWxpbmcgdGhlIHBvc3NpYmxlIHJlYXNvbnMgYSBjYXNlIG1heSBiZSBl
c2NhbGF0ZWQuCgoMCgUEAAQAARIDHwcNClgKBgQABAACABIDIQQbGkkgVGhlIGVzY2FsYXRp
b24gcmVhc29uIGlzIGluIGFuIHVua25vd24gc3RhdGUgb3IgaGFzIG5vdCBiZWVuIHNwZWNp
ZmllZC4KCg4KBwQABAACAAESAyEEFgoOCgcEAAQAAgACEgMhGRoKOAoGBAAEAAIBEgMkBBga
KSBUaGUgY2FzZSBpcyB0YWtpbmcgdG9vIGxvbmcgdG8gcmVzb2x2ZS4KCg4KBwQABAACAQES
AyQEEwoOCgcEAAQAAgECEgMkFhcKawoGBAAEAAICEgMoBBwaXCBUaGUgc3VwcG9ydCBhZ2Vu
dCBkb2VzIG5vdCBoYXZlIHRoZSBleHBlcnRpc2UgcmVxdWlyZWQgdG8gc3VjY2Vzc2Z1bGx5
CiByZXNvbHZlIHRoZSBpc3N1ZS4KCg4KBwQABAACAgESAygEFwoOCgcEAAQAAgICEgMoGhsK
QwoGBAAEAAIDEgMrBBgaNCBUaGUgaXNzdWUgaXMgaGF2aW5nIGEgc2lnbmlmaWNhbnQgYnVz
aW5lc3MgaW1wYWN0LgoKDgoHBAAEAAIDARIDKwQTCg4KBwQABAACAwISAysWFwpECgQEAAIA
EgMvAj0aNyBSZXF1aXJlZC4gVGhlIHJlYXNvbiB3aHkgdGhlIENhc2UgaXMgYmVpbmcgZXNj
YWxhdGVkLgoKDAoFBAACAAYSAy8CCAoMCgUEAAIAARIDLwkPCgwKBQQAAgADEgMvEhMKDAoF
BAACAAgSAy8UPAoPCggEAAIACJwIABIDLxU7CpkBCgQEAAIBEgMzAkQaiwEgUmVxdWlyZWQu
IEEgZnJlZSB0ZXh0IGRlc2NyaXB0aW9uIHRvIGFjY29tcGFueSB0aGUgYHJlYXNvbmAgZmll
bGQgYWJvdmUuCiBQcm92aWRlcyBhZGRpdGlvbmFsIGNvbnRleHQgb24gd2h5IHRoZSBjYXNl
IGlzIGJlaW5nIGVzY2FsYXRlZC4KCgwKBQQAAgEFEgMzAggKDAoFBAACAQESAzMJFgoMCgUE
AAIBAxIDMxkaCgwKBQQAAgEIEgMzG0MKDwoIBAACAQicCAASAzMcQmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Support::V2::Escalation::Escalation ===
    # Fields for Escalation
    # Field: reason Type: 14 (.google.cloud.support.v2.Escalation.Reason)
    # Field: justification Type: 9 ()

# Enum: Escalation::Reason
our $Escalation_REASON_UNSPECIFIED = 0;
our $Escalation_RESOLUTION_TIME = 1;
our $Escalation_TECHNICAL_EXPERTISE = 2;
our $Escalation_BUSINESS_IMPACT = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Support::V2::Escalation - Compiled Protocol Buffers messages for google/cloud/support/v2/escalation.proto

=head1 SYNOPSIS

    use Google::Cloud::Support::V2::Escalation;

    my $msg = Google::Cloud::Support::V2::Escalation::Escalation->new({
        reason => $reason,
        justification => $justification,
    });

    # Read or update a field
    my $val = $msg->reason();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Support::V2::Escalation::Escalation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/support/v2/escalation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Support::V2::Escalation::Escalation

An escalation of a support case.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->reason() >> / C<< $msg->reason($value) >>

Type: C<Enum> (L<Google::Cloud::Support::V2::Escalation::Reason>)

Required. The reason why the Case is being escalated.

=item * C<< $msg->justification() >> / C<< $msg->justification($value) >>

Type: C<String>

Required. A free text description to accompany the `reason` field above.
Provides additional context on why the case is being escalated.

=back

=head3 Enum: Escalation::Reason

=over 4

=item * C<REASON_UNSPECIFIED> => C<0>

=item * C<RESOLUTION_TIME> => C<1>

=item * C<TECHNICAL_EXPERTISE> => C<2>

=item * C<BUSINESS_IMPACT> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Support::V2::Escalation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
