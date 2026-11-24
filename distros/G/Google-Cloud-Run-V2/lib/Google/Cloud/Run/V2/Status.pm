package Google::Cloud::Run::V2::Status;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CiBnb29nbGUvY2xvdWQvcnVuL3YyL3N0YXR1cy5wcm90bxITZ29vZ2xlLmNsb3VkLnJ1bi52
MiJUChVSZXZpc2lvblNjYWxpbmdTdGF0dXMSOwoaZGVzaXJlZF9taW5faW5zdGFuY2VfY291
bnQYASABKAVSF2Rlc2lyZWRNaW5JbnN0YW5jZUNvdW50QlMKF2NvbS5nb29nbGUuY2xvdWQu
cnVuLnYyQgtTdGF0dXNQcm90b1ABWiljbG91ZC5nb29nbGUuY29tL2dvL3J1bi9hcGl2Mi9y
dW5wYjtydW5wYkrpBgoGEgQOABsBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29v
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
LgoKCAoBAhIDEAAcCggKAQgSAxIAQAoJCgIICxIDEgBACggKAQgSAxMAIgoJCgIIChIDEwAi
CggKAQgSAxQALAoJCgIICBIDFAAsCggKAQgSAxUAMAoJCgIIARIDFQAwCjkKAgQAEgQYABsB
Gi0gRWZmZWN0aXZlIHNldHRpbmdzIGZvciB0aGUgY3VycmVudCByZXZpc2lvbgoKCgoDBAAB
EgMYCB0KUQoEBAACABIDGgInGkQgVGhlIGN1cnJlbnQgbnVtYmVyIG9mIG1pbiBpbnN0YW5j
ZXMgcHJvdmlzaW9uZWQgZm9yIHRoaXMgcmV2aXNpb24uCgoMCgUEAAIABRIDGgIHCgwKBQQA
AgABEgMaCCIKDAoFBAACAAMSAxolJmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Run::V2::Status::RevisionScalingStatus ===
    # Fields for RevisionScalingStatus
    # Field: desired_min_instance_count Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Run::V2::Status - Compiled Protocol Buffers messages for google/cloud/run/v2/status.proto

=head1 SYNOPSIS

    use Google::Cloud::Run::V2::Status;

    my $msg = Google::Cloud::Run::V2::Status::RevisionScalingStatus->new({
        desired_min_instance_count => $desired_min_instance_count,
    });

    # Read or update a field
    my $val = $msg->desired_min_instance_count();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Run::V2::Status::RevisionScalingStatus->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/run/v2/status.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Run::V2::Status::RevisionScalingStatus

Effective settings for the current revision

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->desired_min_instance_count() >> / C<< $msg->desired_min_instance_count($value) >>

Type: C<Int32>

The current number of min instances provisioned for this revision.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Run::V2::Status::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
