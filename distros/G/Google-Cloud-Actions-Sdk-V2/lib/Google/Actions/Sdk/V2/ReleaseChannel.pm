package Google::Actions::Sdk::V2::ReleaseChannel;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvYWN0aW9ucy9zZGsvdjIvcmVsZWFzZV9jaGFubmVsLnByb3RvEhVnb29nbGUu
YWN0aW9ucy5zZGsudjIaGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8i2AEKDlJlbGVhc2VD
aGFubmVsEhIKBG5hbWUYASABKAlSBG5hbWUSJwoPY3VycmVudF92ZXJzaW9uGAIgASgJUg5j
dXJyZW50VmVyc2lvbhInCg9wZW5kaW5nX3ZlcnNpb24YAyABKAlSDnBlbmRpbmdWZXJzaW9u
OmDqQV0KJWFjdGlvbnMuZ29vZ2xlYXBpcy5jb20vUmVsZWFzZUNoYW5uZWwSNHByb2plY3Rz
L3twcm9qZWN0fS9yZWxlYXNlQ2hhbm5lbHMve3JlbGVhc2VfY2hhbm5lbH1CbAoZY29tLmdv
b2dsZS5hY3Rpb25zLnNkay52MkITUmVsZWFzZUNoYW5uZWxQcm90b1ABWjhnb29nbGUuZ29s
YW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2FjdGlvbnMvc2RrL3YyO3Nka0qhCgoGEgQO
ACsBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAeCgkKAgMA
EgMSACMKCAoBCBIDFABPCgkKAggLEgMUAE8KCAoBCBIDFQAiCgkKAggKEgMVACIKCAoBCBID
FgA0CgkKAggIEgMWADQKCAoBCBIDFwAyCgkKAggBEgMXADIKNQoCBAASBBoAKwEaKSBEZWZp
bml0aW9uIG9mIHJlbGVhc2UgY2hhbm5lbCByZXNvdXJjZS4KCgoKAwQAARIDGggWCgsKAwQA
BxIEGwIeBAoNCgUEAAedCBIEGwIeBAqHAQoEBAACABIDIgISGnogVGhlIHVuaXF1ZSBuYW1l
IG9mIHRoZSByZWxlYXNlIGNoYW5uZWwgaW4gdGhlIGZvbGxvd2luZyBmb3JtYXQuCiBgcHJv
amVjdHMve3Byb2plY3R9L3JlbGVhc2VDaGFubmVscy97cmVsZWFzZV9jaGFubmVsfWAuCgoM
CgUEAAIABRIDIgIICgwKBQQAAgABEgMiCQ0KDAoFBAACAAMSAyIQEQqEAQoEBAACARIDJgId
GncgVmVyc2lvbiBjdXJyZW50bHkgZGVwbG95ZWQgdG8gdGhpcyByZWxlYXNlIGNoYW5uZWwg
aW4gdGhlIGZvbGxvd2luZyBmb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L3ZlcnNpb25z
L3t2ZXJzaW9ufWAuCgoMCgUEAAIBBRIDJgIICgwKBQQAAgEBEgMmCRgKDAoFBAACAQMSAyYb
HAqAAQoEBAACAhIDKgIdGnMgVmVyc2lvbiB0byBiZSBkZXBsb3llZCB0byB0aGlzIHJlbGVh
c2UgY2hhbm5lbCBpbiB0aGUgZm9sbG93aW5nIGZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVj
dH0vdmVyc2lvbnMve3ZlcnNpb259YC4KCgwKBQQAAgIFEgMqAggKDAoFBAACAgESAyoJGAoM
CgUEAAICAxIDKhscYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::ReleaseChannel::ReleaseChannel ===
    # Fields for ReleaseChannel
    # Field: name Type: 9 ()
    # Field: current_version Type: 9 ()
    # Field: pending_version Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::ReleaseChannel - Compiled Protocol Buffers messages for google/actions/sdk/v2/release_channel.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::ReleaseChannel;

    my $msg = Google::Actions::Sdk::V2::ReleaseChannel::ReleaseChannel->new({
        name => $name,
        current_version => $current_version,
        pending_version => $pending_version,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::ReleaseChannel::ReleaseChannel->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/release_channel.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::ReleaseChannel::ReleaseChannel

Definition of release channel resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The unique name of the release channel in the following format.
`projects/{project}/releaseChannels/{release_channel}`.

=item * C<< $msg->current_version() >> / C<< $msg->current_version($value) >>

Type: C<String>

Version currently deployed to this release channel in the following format:
`projects/{project}/versions/{version}`.

=item * C<< $msg->pending_version() >> / C<< $msg->pending_version($value) >>

Type: C<String>

Version to be deployed to this release channel in the following format:
`projects/{project}/versions/{version}`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::ReleaseChannel::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
