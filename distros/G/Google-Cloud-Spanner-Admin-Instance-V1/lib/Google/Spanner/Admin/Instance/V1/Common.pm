package Google::Spanner::Admin::Instance::V1::Common;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvc3Bhbm5lci9hZG1pbi9pbnN0YW5jZS92MS9jb21tb24ucHJvdG8SIGdvb2ds
ZS5zcGFubmVyLmFkbWluLmluc3RhbmNlLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGlt
ZXN0YW1wLnByb3RvIrABChFPcGVyYXRpb25Qcm9ncmVzcxIpChBwcm9ncmVzc19wZXJjZW50
GAEgASgFUg9wcm9ncmVzc1BlcmNlbnQSOQoKc3RhcnRfdGltZRgCIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBSCXN0YXJ0VGltZRI1CghlbmRfdGltZRgDIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5UaW1lc3RhbXBSB2VuZFRpbWUiMwoQUmVwbGljYVNlbGVjdGlvbhIfCghs
b2NhdGlvbhgBIAEoCUID4EECUghsb2NhdGlvbip3ChFGdWxmaWxsbWVudFBlcmlvZBIiCh5G
VUxGSUxMTUVOVF9QRVJJT0RfVU5TUEVDSUZJRUQQABIdChlGVUxGSUxMTUVOVF9QRVJJT0Rf
Tk9STUFMEAESHwobRlVMRklMTE1FTlRfUEVSSU9EX0VYVEVOREVEEAJC/QEKJGNvbS5nb29n
bGUuc3Bhbm5lci5hZG1pbi5pbnN0YW5jZS52MUILQ29tbW9uUHJvdG9QAVpGY2xvdWQuZ29v
Z2xlLmNvbS9nby9zcGFubmVyL2FkbWluL2luc3RhbmNlL2FwaXYxL2luc3RhbmNlcGI7aW5z
dGFuY2VwYqoCJkdvb2dsZS5DbG91ZC5TcGFubmVyLkFkbWluLkluc3RhbmNlLlYxygImR29v
Z2xlXENsb3VkXFNwYW5uZXJcQWRtaW5cSW5zdGFuY2VcVjHqAitHb29nbGU6OkNsb3VkOjpT
cGFubmVyOjpBZG1pbjo6SW5zdGFuY2U6OlYxSvUOCgYSBA4APwEKvAQKAQwSAw4AEjKxBCBD
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
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACkKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkK
AgMCEgMUACkKCAoBCBIDFgBDCgkKAgglEgMWAEMKCAoBCBIDFwBdCgkKAggLEgMXAF0KCAoB
CBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQAsCgkKAggIEgMZACwKCAoBCBIDGgA9CgkKAggB
EgMaAD0KCAoBCBIDGwBFCgkKAggpEgMbAEUKCAoBCBIDHABECgkKAggtEgMcAEQKbgoCBAAS
BCAAKwEaYiBFbmNhcHN1bGF0ZXMgcHJvZ3Jlc3MgcmVsYXRlZCBpbmZvcm1hdGlvbiBmb3Ig
YSBDbG91ZCBTcGFubmVyIGxvbmcKIHJ1bm5pbmcgaW5zdGFuY2Ugb3BlcmF0aW9ucy4KCgoK
AwQAARIDIAgZClwKBAQAAgASAyMCHRpPIFBlcmNlbnQgY29tcGxldGlvbiBvZiB0aGUgb3Bl
cmF0aW9uLgogVmFsdWVzIGFyZSBiZXR3ZWVuIDAgYW5kIDEwMCBpbmNsdXNpdmUuCgoMCgUE
AAIABRIDIwIHCgwKBQQAAgABEgMjCBgKDAoFBAACAAMSAyMbHAotCgQEAAIBEgMmAisaICBU
aW1lIHRoZSByZXF1ZXN0IHdhcyByZWNlaXZlZC4KCgwKBQQAAgEGEgMmAhsKDAoFBAACAQES
AyYcJgoMCgUEAAIBAxIDJikqCl4KBAQAAgISAyoCKRpRIElmIHNldCwgdGhlIHRpbWUgYXQg
d2hpY2ggdGhpcyBvcGVyYXRpb24gZmFpbGVkIG9yIHdhcyBjb21wbGV0ZWQKIHN1Y2Nlc3Nm
dWxseS4KCgwKBQQAAgIGEgMqAhsKDAoFBAACAgESAyocJAoMCgUEAAICAxIDKicoCkgKAgUA
EgQuADkBGjwgSW5kaWNhdGVzIHRoZSBleHBlY3RlZCBmdWxmaWxsbWVudCBwZXJpb2Qgb2Yg
YW4gb3BlcmF0aW9uLgoKCgoDBQABEgMuBRYKHQoEBQACABIDMAIlGhAgTm90IHNwZWNpZmll
ZC4KCgwKBQUAAgABEgMwAiAKDAoFBQACAAISAzAjJApgCgQFAAIBEgM0AiAaUyBOb3JtYWwg
ZnVsZmlsbG1lbnQgcGVyaW9kLiBUaGUgb3BlcmF0aW9uIGlzIGV4cGVjdGVkIHRvIGNvbXBs
ZXRlIHdpdGhpbgogbWludXRlcy4KCgwKBQUAAgEBEgM0AhsKDAoFBQACAQISAzQeHwplCgQF
AAICEgM4AiIaWCBFeHRlbmRlZCBmdWxmaWxsbWVudCBwZXJpb2QuIEl0IGNhbiB0YWtlIHVw
IHRvIGFuIGhvdXIgZm9yIHRoZSBvcGVyYXRpb24KIHRvIGNvbXBsZXRlLgoKDAoFBQACAgES
AzgCHQoMCgUFAAICAhIDOCAhCkoKAgQBEgQ8AD8BGj4gUmVwbGljYVNlbGVjdGlvbiBpZGVu
dGlmaWVzIHJlcGxpY2FzIHdpdGggY29tbW9uIHByb3BlcnRpZXMuCgoKCgMEAQESAzwIGApU
CgQEAQIAEgM+Aj8aRyBSZXF1aXJlZC4gTmFtZSBvZiB0aGUgbG9jYXRpb24gb2YgdGhlIHJl
cGxpY2FzIChlLmcuLCAidXMtY2VudHJhbDEiKS4KCgwKBQQBAgAFEgM+AggKDAoFBAECAAES
Az4JEQoMCgUEAQIAAxIDPhQVCgwKBQQBAgAIEgM+Fj4KDwoIBAECAAicCAASAz4XPWIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Spanner::Admin::Instance::V1::Common::OperationProgress ===
    # Fields for OperationProgress
    # Field: progress_percent Type: 5 ()
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Spanner::Admin::Instance::V1::Common::ReplicaSelection ===
    # Fields for ReplicaSelection
    # Field: location Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Spanner::Admin::Instance::V1::Common - Compiled Protocol Buffers messages for google/spanner/admin/instance/v1/common.proto

=head1 SYNOPSIS

    use Google::Spanner::Admin::Instance::V1::Common;

    my $msg = Google::Spanner::Admin::Instance::V1::Common::OperationProgress->new({
        progress_percent => $progress_percent,
        start_time => $start_time,
        end_time => $end_time,
    });

    # Read or update a field
    my $val = $msg->progress_percent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Spanner::Admin::Instance::V1::Common::OperationProgress->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/spanner/admin/instance/v1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Spanner::Admin::Instance::V1::Common::OperationProgress

Encapsulates progress related information for a Cloud Spanner long
running instance operations.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->progress_percent() >> / C<< $msg->progress_percent($value) >>

Type: C<Int32>

Percent completion of the operation.
Values are between 0 and 100 inclusive.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time the request was received.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

If set, the time at which this operation failed or was completed
successfully.

=back

=head2 Google::Spanner::Admin::Instance::V1::Common::ReplicaSelection

ReplicaSelection identifies replicas with common properties.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

Required. Name of the location of the replicas (e.g., "us-central1").

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Spanner::Admin::Instance::V1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
