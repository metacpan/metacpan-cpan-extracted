package Google::Cloud::Securitycenter::V2::LogEntry;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvbG9nX2VudHJ5LnByb3RvEh5nb29n
bGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIaH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAu
cHJvdG8ifAoITG9nRW50cnkSYwoTY2xvdWRfbG9nZ2luZ19lbnRyeRgBIAEoCzIxLmdvb2ds
ZS5jbG91ZC5zZWN1cml0eWNlbnRlci52Mi5DbG91ZExvZ2dpbmdFbnRyeUgAUhFjbG91ZExv
Z2dpbmdFbnRyeUILCglsb2dfZW50cnkisAEKEUNsb3VkTG9nZ2luZ0VudHJ5EhsKCWluc2Vy
dF9pZBgBIAEoCVIIaW5zZXJ0SWQSFQoGbG9nX2lkGAIgASgJUgVsb2dJZBItChJyZXNvdXJj
ZV9jb250YWluZXIYAyABKAlSEXJlc291cmNlQ29udGFpbmVyEjgKCXRpbWVzdGFtcBgEIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXRpbWVzdGFtcELnAQoiY29tLmdvb2ds
ZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MkINTG9nRW50cnlQcm90b1ABWkpjbG91ZC5nb29n
bGUuY29tL2dvL3NlY3VyaXR5Y2VudGVyL2FwaXYyL3NlY3VyaXR5Y2VudGVycGI7c2VjdXJp
dHljZW50ZXJwYqoCHkdvb2dsZS5DbG91ZC5TZWN1cml0eUNlbnRlci5WMsoCHkdvb2dsZVxD
bG91ZFxTZWN1cml0eUNlbnRlclxWMuoCIUdvb2dsZTo6Q2xvdWQ6OlNlY3VyaXR5Q2VudGVy
OjpWMkryDQoGEgQOADcBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExM
QwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRo
ZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29t
cGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRo
ZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNF
TlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQg
dG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNl
IGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJ
RVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGll
ZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmlu
ZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoB
AhIDEAAnCgkKAgMAEgMSACkKCAoBCBIDFAA7CgkKAgglEgMUADsKCAoBCBIDFQBhCgkKAggL
EgMVAGEKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAuCgkKAggIEgMXAC4KCAoBCBID
GAA7CgkKAggBEgMYADsKCAoBCBIDGQA7CgkKAggpEgMZADsKCAoBCBIDGgA6CgkKAggtEgMa
ADoKKwoCBAASBB0AIwEaHyBBbiBpbmRpdmlkdWFsIGVudHJ5IGluIGEgbG9nLgoKCgoDBAAB
EgMdCBAKHgoEBAAIABIEHwIiAxoQIFRoZSBsb2cgZW50cnkuCgoMCgUEAAgAARIDHwgRCkQK
BAQAAgASAyEELho3IEFuIGluZGl2aWR1YWwgZW50cnkgaW4gYSBsb2cgc3RvcmVkIGluIENs
b3VkIExvZ2dpbmcuCgoMCgUEAAIABhIDIQQVCgwKBQQAAgABEgMhFikKDAoFBAACAAMSAyEs
LQqCAQoCBAESBCcANwEadiBNZXRhZGF0YSB0YWtlbiBmcm9tIGEgW0Nsb3VkIExvZ2dpbmcK
IExvZ0VudHJ5XShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vbG9nZ2luZy9kb2NzL3JlZmVy
ZW5jZS92Mi9yZXN0L3YyL0xvZ0VudHJ5KQoKCgoDBAEBEgMnCBkKNQoEBAECABIDKQIXGigg
QSB1bmlxdWUgaWRlbnRpZmllciBmb3IgdGhlIGxvZyBlbnRyeS4KCgwKBQQBAgAFEgMpAggK
DAoFBAECAAESAykJEgoMCgUEAQIAAxIDKRUWCoMCCgQEAQIBEgMvAhQa9QEgVGhlIHR5cGUg
b2YgdGhlIGxvZyAocGFydCBvZiBgbG9nX25hbWVgLiBgbG9nX25hbWVgIGlzIHRoZSByZXNv
dXJjZSBuYW1lIG9mCiB0aGUgbG9nIHRvIHdoaWNoIHRoaXMgbG9nIGVudHJ5IGJlbG9uZ3Mp
LiBGb3IgZXhhbXBsZToKIGBjbG91ZHJlc291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNvbS9h
Y3Rpdml0eWAgTm90ZSB0aGF0IHRoaXMgZmllbGQgaXMgbm90CiBVUkwtZW5jb2RlZCwgdW5s
aWtlIGluIGBMb2dFbnRyeWAuCgoMCgUEAQIBBRIDLwIICgwKBQQBAgEBEgMvCQ8KDAoFBAEC
AQMSAy8SEwpsCgQEAQICEgMzAiAaXyBUaGUgb3JnYW5pemF0aW9uLCBmb2xkZXIsIG9yIHBy
b2plY3Qgb2YgdGhlIG1vbml0b3JlZCByZXNvdXJjZSB0aGF0CiBwcm9kdWNlZCB0aGlzIGxv
ZyBlbnRyeS4KCgwKBQQBAgIFEgMzAggKDAoFBAECAgESAzMJGwoMCgUEAQICAxIDMx4fCkYK
BAQBAgMSAzYCKho5IFRoZSB0aW1lIHRoZSBldmVudCBkZXNjcmliZWQgYnkgdGhlIGxvZyBl
bnRyeSBvY2N1cnJlZC4KCgwKBQQBAgMGEgM2AhsKDAoFBAECAwESAzYcJQoMCgUEAQIDAxID
NigpYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::LogEntry::LogEntry ===
    # Fields for LogEntry
    # Field: cloud_logging_entry Type: 11 (.google.cloud.securitycenter.v2.CloudLoggingEntry)

# === Message: Google::Cloud::Securitycenter::V2::LogEntry::CloudLoggingEntry ===
    # Fields for CloudLoggingEntry
    # Field: insert_id Type: 9 ()
    # Field: log_id Type: 9 ()
    # Field: resource_container Type: 9 ()
    # Field: timestamp Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::LogEntry - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/log_entry.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::LogEntry;

    my $msg = Google::Cloud::Securitycenter::V2::LogEntry::LogEntry->new({
        cloud_logging_entry => $cloud_logging_entry,
    });

    # Read or update a field
    my $val = $msg->cloud_logging_entry();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::LogEntry::LogEntry->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/log_entry.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::LogEntry::LogEntry

An individual entry in a log.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cloud_logging_entry() >> / C<< $msg->cloud_logging_entry($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::LogEntry::CloudLoggingEntry>)

An individual entry in a log stored in Cloud Logging.

=back

=head2 Google::Cloud::Securitycenter::V2::LogEntry::CloudLoggingEntry

Metadata taken from a [Cloud Logging
LogEntry](https://cloud.google.com/logging/docs/reference/v2/rest/v2/LogEntry)

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->insert_id() >> / C<< $msg->insert_id($value) >>

Type: C<String>

A unique identifier for the log entry.

=item * C<< $msg->log_id() >> / C<< $msg->log_id($value) >>

Type: C<String>

The type of the log (part of `log_name`. `log_name` is the resource name of
the log to which this log entry belongs). For example:
`cloudresourcemanager.googleapis.com/activity` Note that this field is not
URL-encoded, unlike in `LogEntry`.

=item * C<< $msg->resource_container() >> / C<< $msg->resource_container($value) >>

Type: C<String>

The organization, folder, or project of the monitored resource that
produced this log entry.

=item * C<< $msg->timestamp() >> / C<< $msg->timestamp($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time the event described by the log entry occurred.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::LogEntry::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
