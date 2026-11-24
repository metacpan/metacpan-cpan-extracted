package Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlanMetadata;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CkRnb29nbGUvY2xvdWQvZ2tlYmFja3VwL2xvZ2dpbmcvdjEvbG9nZ2VkX3Jlc3RvcmVfcGxh
bl9tZXRhZGF0YS5wcm90bxIhZ29vZ2xlLmNsb3VkLmdrZWJhY2t1cC5sb2dnaW5nLnYxIkQK
GUxvZ2dlZFJlc3RvcmVQbGFuTWV0YWRhdGESJwoPcmVzdG9yZV9jaGFubmVsGAEgASgJUg5y
ZXN0b3JlQ2hhbm5lbEL6AQolY29tLmdvb2dsZS5jbG91ZC5na2ViYWNrdXAubG9nZ2luZy52
MUIeTG9nZ2VkUmVzdG9yZVBsYW5NZXRhZGF0YVByb3RvUAFaP2Nsb3VkLmdvb2dsZS5jb20v
Z28vZ2tlYmFja3VwL2xvZ2dpbmcvYXBpdjEvbG9nZ2luZ3BiO2xvZ2dpbmdwYqoCIUdvb2ds
ZS5DbG91ZC5Ha2VCYWNrdXAuTG9nZ2luZy5WMcoCIUdvb2dsZVxDbG91ZFxHa2VCYWNrdXBc
TG9nZ2luZ1xWMeoCJUdvb2dsZTo6Q2xvdWQ6OkdrZUJhY2t1cDo6TG9nZ2luZzo6VjFKiQgK
BhIEDgAgAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKgoI
CgEIEgMSAD4KCQoCCCUSAxIAPgoICgEIEgMTAFYKCQoCCAsSAxMAVgoICgEIEgMUACIKCQoC
CAoSAxQAIgoICgEIEgMVAD8KCQoCCAgSAxUAPwoICgEIEgMWAD4KCQoCCAESAxYAPgoICgEI
EgMXAD8KCQoCCCkSAxcAPwoICgEIEgMYAD4KCQoCCC0SAxgAPgq0AQoCBAASBB0AIAEapwEg
TG9nZ2VkUmVzdG9yZVBsYW5NZXRhZGF0YSBhcyBzdG9yZWQgaW4gUGxhdGZvcm0gbG9nLiBJ
dCdzIHVzZWQgdG8gbG9nIHRoZQogZGV0YWlscyBvZiBhIFJlc3RvcmVQbGFuLCB3aGljaCBh
cmUgbm90IHByb3ZpZGVkIGJ5IHVzZXJzLCBidXQgYXJlIGZpbGxlZAogYnkgdGhlIHNlcnZp
Y2UuCgoKCgMEAAESAx0IIQo2CgQEAAIAEgMfAh0aKSBUaGUgbmFtZSBvZiB0aGUgcmVzdG9y
ZSBjaGFubmVsIGlmIGFueS4KCgwKBQQAAgAFEgMfAggKDAoFBAACAAESAx8JGAoMCgUEAAIA
AxIDHxscYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlanMetadata::LoggedRestorePlanMetadata ===
    # Fields for LoggedRestorePlanMetadata
    # Field: restore_channel Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlanMetadata - Compiled Protocol Buffers messages for google/cloud/gkebackup/logging/v1/logged_restore_plan_metadata.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlanMetadata;

    my $msg = Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlanMetadata::LoggedRestorePlanMetadata->new({
        restore_channel => $restore_channel,
    });

    # Read or update a field
    my $val = $msg->restore_channel();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlanMetadata::LoggedRestorePlanMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkebackup/logging/v1/logged_restore_plan_metadata.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlanMetadata::LoggedRestorePlanMetadata

LoggedRestorePlanMetadata as stored in Platform log. It's used to log the
details of a RestorePlan, which are not provided by users, but are filled
by the service.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->restore_channel() >> / C<< $msg->restore_channel($value) >>

Type: C<String>

The name of the restore channel if any.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkebackup::Logging::V1::LoggedRestorePlanMetadata::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
