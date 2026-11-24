package Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlanMetadata;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CkNnb29nbGUvY2xvdWQvZ2tlYmFja3VwL2xvZ2dpbmcvdjEvbG9nZ2VkX2JhY2t1cF9wbGFu
X21ldGFkYXRhLnByb3RvEiFnb29nbGUuY2xvdWQuZ2tlYmFja3VwLmxvZ2dpbmcudjEijwEK
GExvZ2dlZEJhY2t1cFBsYW5NZXRhZGF0YRIlCg5iYWNrdXBfY2hhbm5lbBgBIAEoCVINYmFj
a3VwQ2hhbm5lbBIkCg5ycG9fcmlza19sZXZlbBgCIAEoBVIMcnBvUmlza0xldmVsEiYKD3Jw
b19yaXNrX3JlYXNvbhgDIAEoCVINcnBvUmlza1JlYXNvbkL5AQolY29tLmdvb2dsZS5jbG91
ZC5na2ViYWNrdXAubG9nZ2luZy52MUIdTG9nZ2VkQmFja3VwUGxhbk1ldGFkYXRhUHJvdG9Q
AVo/Y2xvdWQuZ29vZ2xlLmNvbS9nby9na2ViYWNrdXAvbG9nZ2luZy9hcGl2MS9sb2dnaW5n
cGI7bG9nZ2luZ3BiqgIhR29vZ2xlLkNsb3VkLkdrZUJhY2t1cC5Mb2dnaW5nLlYxygIhR29v
Z2xlXENsb3VkXEdrZUJhY2t1cFxMb2dnaW5nXFYx6gIlR29vZ2xlOjpDbG91ZDo6R2tlQmFj
a3VwOjpMb2dnaW5nOjpWMUrUCgoGEgQOACgBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAqCggKAQgSAxIAPgoJCgIIJRIDEgA+CggKAQgSAxMAVgoJCgII
CxIDEwBWCggKAQgSAxQAIgoJCgIIChIDFAAiCggKAQgSAxUAPgoJCgIICBIDFQA+CggKAQgS
AxYAPgoJCgIIARIDFgA+CggKAQgSAxcAPwoJCgIIKRIDFwA/CggKAQgSAxgAPgoJCgIILRID
GAA+CrIBCgIEABIEHQAoARqlASBMb2dnZWRCYWNrdXBQbGFuTWV0YWRhdGEgYXMgc3RvcmVk
IGluIFBsYXRmb3JtIGxvZy4gSXQncyB1c2VkIHRvIGxvZyB0aGUKIGRldGFpbHMgb2YgYSBC
YWNrdXBQbGFuLCB3aGljaCBhcmUgbm90IHByb3ZpZGVkIGJ5IHVzZXJzLCBidXQgYXJlIGZp
bGxlZAogYnkgdGhlIHNlcnZpY2UuCgoKCgMEAAESAx0IIAo1CgQEAAIAEgMfAhwaKCBUaGUg
bmFtZSBvZiB0aGUgYmFja3VwIGNoYW5uZWwgaWYgYW55LgoKDAoFBAACAAUSAx8CCAoMCgUE
AAIAARIDHwkXCgwKBQQAAgADEgMfGhsKlwEKBAQAAgESAyMCGxqJASBBIG51bWJlciB0aGF0
IHJlcHJlc2VudHMgdGhlIGN1cnJlbnQgcmlzayBsZXZlbCBvZiB0aGlzIEJhY2t1cFBsYW4g
ZnJvbSBSUE8KIHBlcnNwZWN0aXZlIHdpdGggMSBiZWluZyBubyByaXNrIGFuZCA1IGJlaW5n
IGhpZ2hlc3Qgcmlzay4KCgwKBQQAAgEFEgMjAgcKDAoFBAACAQESAyMIFgoMCgUEAAIBAxID
IxkaCl4KBAQAAgISAycCHRpRIFRoZSByZWFzb24gZm9yIHRoZSBjdXJyZW50IHJpc2sgbGV2
ZWwgb2YgdGhpcyBCYWNrdXBQbGFuIGZyb20gUlBPCiBwZXJzcGVjdGl2ZS4KCgwKBQQAAgIF
EgMnAggKDAoFBAACAgESAycJGAoMCgUEAAICAxIDJxscYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlanMetadata::LoggedBackupPlanMetadata ===
    # Fields for LoggedBackupPlanMetadata
    # Field: backup_channel Type: 9 ()
    # Field: rpo_risk_level Type: 5 ()
    # Field: rpo_risk_reason Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlanMetadata - Compiled Protocol Buffers messages for google/cloud/gkebackup/logging/v1/logged_backup_plan_metadata.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlanMetadata;

    my $msg = Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlanMetadata::LoggedBackupPlanMetadata->new({
        backup_channel => $backup_channel,
        rpo_risk_level => $rpo_risk_level,
        rpo_risk_reason => $rpo_risk_reason,
    });

    # Read or update a field
    my $val = $msg->backup_channel();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlanMetadata::LoggedBackupPlanMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkebackup/logging/v1/logged_backup_plan_metadata.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlanMetadata::LoggedBackupPlanMetadata

LoggedBackupPlanMetadata as stored in Platform log. It's used to log the
details of a BackupPlan, which are not provided by users, but are filled
by the service.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->backup_channel() >> / C<< $msg->backup_channel($value) >>

Type: C<String>

The name of the backup channel if any.

=item * C<< $msg->rpo_risk_level() >> / C<< $msg->rpo_risk_level($value) >>

Type: C<Int32>

A number that represents the current risk level of this BackupPlan from RPO
perspective with 1 being no risk and 5 being highest risk.

=item * C<< $msg->rpo_risk_reason() >> / C<< $msg->rpo_risk_reason($value) >>

Type: C<String>

The reason for the current risk level of this BackupPlan from RPO
perspective.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlanMetadata::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
