package Google::Cloud::Gkebackup::Logging::V1::LoggedRestoreChannel;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvY2xvdWQvZ2tlYmFja3VwL2xvZ2dpbmcvdjEvbG9nZ2VkX3Jlc3RvcmVfY2hh
bm5lbC5wcm90bxIhZ29vZ2xlLmNsb3VkLmdrZWJhY2t1cC5sb2dnaW5nLnYxIoECChRMb2dn
ZWRSZXN0b3JlQ2hhbm5lbBIvChNkZXN0aW5hdGlvbl9wcm9qZWN0GAEgASgJUhJkZXN0aW5h
dGlvblByb2plY3QSWwoGbGFiZWxzGAIgAygLMkMuZ29vZ2xlLmNsb3VkLmdrZWJhY2t1cC5s
b2dnaW5nLnYxLkxvZ2dlZFJlc3RvcmVDaGFubmVsLkxhYmVsc0VudHJ5UgZsYWJlbHMSIAoL
ZGVzY3JpcHRpb24YAyABKAlSC2Rlc2NyaXB0aW9uGjkKC0xhYmVsc0VudHJ5EhAKA2tleRgB
IAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAFC9QEKJWNvbS5nb29nbGUuY2xv
dWQuZ2tlYmFja3VwLmxvZ2dpbmcudjFCGUxvZ2dlZFJlc3RvcmVDaGFubmVsUHJvdG9QAVo/
Y2xvdWQuZ29vZ2xlLmNvbS9nby9na2ViYWNrdXAvbG9nZ2luZy9hcGl2MS9sb2dnaW5ncGI7
bG9nZ2luZ3BiqgIhR29vZ2xlLkNsb3VkLkdrZUJhY2t1cC5Mb2dnaW5nLlYxygIhR29vZ2xl
XENsb3VkXEdrZUJhY2t1cFxMb2dnaW5nXFYx6gIlR29vZ2xlOjpDbG91ZDo6R2tlQmFja3Vw
OjpMb2dnaW5nOjpWMUrJCgoGEgQOACgBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAAqCggKAQgSAxIAPgoJCgIIJRIDEgA+CggKAQgSAxMAVgoJCgIICxID
EwBWCggKAQgSAxQAIgoJCgIIChIDFAAiCggKAQgSAxUAOgoJCgIICBIDFQA6CggKAQgSAxYA
PgoJCgIIARIDFgA+CggKAQgSAxcAPwoJCgIIKRIDFwA/CggKAQgSAxgAPgoJCgIILRIDGAA+
CuoBCgIEABIEHgAoARrdASBBIFJlc3RvcmVDaGFubmVsIGltcG9zZXMgY29uc3RyYWludHMg
b24gd2hlcmUgYmFja3VwcyBjYW4gYmUgcmVzdG9yZWQuCiBUaGUgUmVzdG9yZUNoYW5uZWwg
c2hvdWxkIGJlIGluIHRoZSBzYW1lIHByb2plY3QgYW5kIHJlZ2lvbgogYXMgdGhlIGJhY2t1
cHMgYmVpbmcgY3JlYXRlZC4KIFRoZSByZXN0b3JlIGNhbiBiZSBjcmVhdGVkIG9ubHkgaW4g
ZGVzdGluYXRpb25fcHJvamVjdC4KCgoKAwQAARIDHggcCmgKBAQAAgASAyECIRpbIFRoZSBw
cm9qZWN0IHdoZXJlIFJlc3RvcmVzIGFyZSBhbGxvd2VkIHRvIGJlIHN0b3JlZC4KIFRoZSBm
b3JtYXQgaXMgYHByb2plY3RzL3twcm9qZWN0fWAuCgoMCgUEAAIABRIDIQIICgwKBQQAAgAB
EgMhCRwKDAoFBAACAAMSAyEfIAo3CgQEAAIBEgMkAiEaKiBBIHNldCBvZiBjdXN0b20gbGFi
ZWxzIHN1cHBsaWVkIGJ5IHVzZXIuCgoMCgUEAAIBBhIDJAIVCgwKBQQAAgEBEgMkFhwKDAoF
BAACAQMSAyQfIApJCgQEAAICEgMnAhkaPCBVc2VyIHNwZWNpZmllZCBkZXNjcmlwdGl2ZSBz
dHJpbmcgZm9yIHRoaXMgUmVzdG9yZUNoYW5uZWwuCgoMCgUEAAICBRIDJwIICgwKBQQAAgIB
EgMnCRQKDAoFBAACAgMSAycXGGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkebackup::Logging::V1::LoggedRestoreChannel::LoggedRestoreChannel ===
    # Fields for LoggedRestoreChannel
    # Field: destination_project Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.gkebackup.logging.v1.LoggedRestoreChannel.LabelsEntry)
    # Field: description Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkebackup::Logging::V1::LoggedRestoreChannel - Compiled Protocol Buffers messages for google/cloud/gkebackup/logging/v1/logged_restore_channel.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkebackup::Logging::V1::LoggedRestoreChannel;

    my $msg = Google::Cloud::Gkebackup::Logging::V1::LoggedRestoreChannel::LoggedRestoreChannel->new({
        destination_project => $destination_project,
        labels => $labels,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->destination_project();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkebackup::Logging::V1::LoggedRestoreChannel::LoggedRestoreChannel->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkebackup/logging/v1/logged_restore_channel.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkebackup::Logging::V1::LoggedRestoreChannel::LoggedRestoreChannel

A RestoreChannel imposes constraints on where backups can be restored.
The RestoreChannel should be in the same project and region
as the backups being created.
The restore can be created only in destination_project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->destination_project() >> / C<< $msg->destination_project($value) >>

Type: C<String>

The project where Restores are allowed to be stored.
The format is `projects/{project}`.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::Logging::V1::LoggedRestoreChannel::LoggedRestoreChannel::LabelsEntry>)

A set of custom labels supplied by user.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

User specified descriptive string for this RestoreChannel.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkebackup::Logging::V1::LoggedRestoreChannel::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
