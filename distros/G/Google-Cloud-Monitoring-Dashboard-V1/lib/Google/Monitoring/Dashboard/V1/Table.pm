package Google::Monitoring::Dashboard::V1::Table;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Monitoring::Dashboard::V1::Metrics };
    eval { require Google::Monitoring::Dashboard::V1::TableDisplayOptions };
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvbW9uaXRvcmluZy9kYXNoYm9hcmQvdjEvdGFibGUucHJvdG8SHmdvb2dsZS5t
b25pdG9yaW5nLmRhc2hib2FyZC52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
bxosZ29vZ2xlL21vbml0b3JpbmcvZGFzaGJvYXJkL3YxL21ldHJpY3MucHJvdG8aOmdvb2ds
ZS9tb25pdG9yaW5nL2Rhc2hib2FyZC92MS90YWJsZV9kaXNwbGF5X29wdGlvbnMucHJvdG8a
Hmdvb2dsZS9wcm90b2J1Zi9kdXJhdGlvbi5wcm90byLbBgoPVGltZVNlcmllc1RhYmxlEl4K
CWRhdGFfc2V0cxgBIAMoCzI8Lmdvb2dsZS5tb25pdG9yaW5nLmRhc2hib2FyZC52MS5UaW1l
U2VyaWVzVGFibGUuVGFibGVEYXRhU2V0QgPgQQJSCGRhdGFTZXRzEnsKFG1ldHJpY192aXN1
YWxpemF0aW9uGAIgASgOMkMuZ29vZ2xlLm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxLlRpbWVT
ZXJpZXNUYWJsZS5NZXRyaWNWaXN1YWxpemF0aW9uQgPgQQFSE21ldHJpY1Zpc3VhbGl6YXRp
b24SbAoPY29sdW1uX3NldHRpbmdzGAQgAygLMj4uZ29vZ2xlLm1vbml0b3JpbmcuZGFzaGJv
YXJkLnYxLlRpbWVTZXJpZXNUYWJsZS5Db2x1bW5TZXR0aW5nc0ID4EEBUg5jb2x1bW5TZXR0
aW5ncxrcAgoMVGFibGVEYXRhU2V0EmAKEXRpbWVfc2VyaWVzX3F1ZXJ5GAEgASgLMi8uZ29v
Z2xlLm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxLlRpbWVTZXJpZXNRdWVyeUID4EECUg90aW1l
U2VyaWVzUXVlcnkSKgoOdGFibGVfdGVtcGxhdGUYAiABKAlCA+BBAVINdGFibGVUZW1wbGF0
ZRJQChRtaW5fYWxpZ25tZW50X3BlcmlvZBgDIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJh
dGlvbkID4EEBUhJtaW5BbGlnbm1lbnRQZXJpb2QSbAoVdGFibGVfZGlzcGxheV9vcHRpb25z
GAQgASgLMjMuZ29vZ2xlLm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxLlRhYmxlRGlzcGxheU9w
dGlvbnNCA+BBAVITdGFibGVEaXNwbGF5T3B0aW9ucxpMCg5Db2x1bW5TZXR0aW5ncxIbCgZj
b2x1bW4YASABKAlCA+BBAlIGY29sdW1uEh0KB3Zpc2libGUYAiABKAhCA+BBAlIHdmlzaWJs
ZSJQChNNZXRyaWNWaXN1YWxpemF0aW9uEiQKIE1FVFJJQ19WSVNVQUxJWkFUSU9OX1VOU1BF
Q0lGSUVEEAASCgoGTlVNQkVSEAESBwoDQkFSEAJC8wEKImNvbS5nb29nbGUubW9uaXRvcmlu
Zy5kYXNoYm9hcmQudjFCClRhYmxlUHJvdG9QAVpGY2xvdWQuZ29vZ2xlLmNvbS9nby9tb25p
dG9yaW5nL2Rhc2hib2FyZC9hcGl2MS9kYXNoYm9hcmRwYjtkYXNoYm9hcmRwYqoCJEdvb2ds
ZS5DbG91ZC5Nb25pdG9yaW5nLkRhc2hib2FyZC5WMcoCJEdvb2dsZVxDbG91ZFxNb25pdG9y
aW5nXERhc2hib2FyZFxWMeoCKEdvb2dsZTo6Q2xvdWQ6Ok1vbml0b3Jpbmc6OkRhc2hib2Fy
ZDo6VjFK+RgKBhIEDgBbAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAAJwoJCgIDABIDEgApCgkKAgMBEgMTADYKCQoCAwISAxQARAoJCgIDAxIDFQAoCggK
AQgSAxcAQQoJCgIIJRIDFwBBCggKAQgSAxgAXQoJCgIICxIDGABdCggKAQgSAxkAIgoJCgII
ChIDGQAiCggKAQgSAxoAKwoJCgIICBIDGgArCggKAQgSAxsAOwoJCgIIARIDGwA7CggKAQgS
AxwAQgoJCgIIKRIDHABCCggKAQgSAx0AQQoJCgIILRIDHQBBCjUKAgQAEgQgAFsBGikgQSB0
YWJsZSB0aGF0IGRpc3BsYXlzIHRpbWUgc2VyaWVzIGRhdGEuCgoKCgMEAAESAyAIFwpJCgQE
AAMAEgQiAjoDGjsgR3JvdXBzIGEgdGltZSBzZXJpZXMgcXVlcnkgZGVmaW5pdGlvbiB3aXRo
IHRhYmxlIG9wdGlvbnMuCgoMCgUEAAMAARIDIgoWCmMKBgQAAwACABIEJQQmMRpTIFJlcXVp
cmVkLiBGaWVsZHMgZm9yIHF1ZXJ5aW5nIHRpbWUgc2VyaWVzIGRhdGEgZnJvbSB0aGUKIFN0
YWNrZHJpdmVyIG1ldHJpY3MgQVBJLgoKDgoHBAADAAIABhIDJQQTCg4KBwQAAwACAAESAyUU
JQoOCgcEAAMAAgADEgMlKCkKDgoHBAADAAIACBIDJggwChEKCgQAAwACAAicCAASAyYJLwr6
AQoGBAADAAIBEgMsBEca6gEgT3B0aW9uYWwuIEEgdGVtcGxhdGUgc3RyaW5nIGZvciBuYW1p
bmcgYFRpbWVTZXJpZXNgIGluIHRoZSByZXN1bHRpbmcgZGF0YQogc2V0LiBUaGlzIHNob3Vs
ZCBiZSBhIHN0cmluZyB3aXRoIGludGVycG9sYXRpb25zIG9mIHRoZSBmb3JtCiBgJHtsYWJl
bF9uYW1lfWAsIHdoaWNoIHdpbGwgcmVzb2x2ZSB0byB0aGUgbGFiZWwncyB2YWx1ZSBpLmUu
CiAiJHtyZXNvdXJjZS5sYWJlbHMucHJvamVjdF9pZH0uIgoKDgoHBAADAAIBBRIDLAQKCg4K
BwQAAwACAQESAywLGQoOCgcEAAMAAgEDEgMsHB0KDgoHBAADAAIBCBIDLB5GChEKCgQAAwAC
AQicCAASAywfRQrwAgoGBAADAAICEgQzBDQxGt8CIE9wdGlvbmFsLiBUaGUgbG93ZXIgYm91
bmQgb24gZGF0YSBwb2ludCBmcmVxdWVuY3kgZm9yIHRoaXMgZGF0YSBzZXQsCiBpbXBsZW1l
bnRlZCBieSBzcGVjaWZ5aW5nIHRoZSBtaW5pbXVtIGFsaWdubWVudCBwZXJpb2QgdG8gdXNl
IGluIGEgdGltZQogc2VyaWVzIHF1ZXJ5IEZvciBleGFtcGxlLCBpZiB0aGUgZGF0YSBpcyBw
dWJsaXNoZWQgb25jZSBldmVyeSAxMCBtaW51dGVzLAogdGhlIGBtaW5fYWxpZ25tZW50X3Bl
cmlvZGAgc2hvdWxkIGJlIGF0IGxlYXN0IDEwIG1pbnV0ZXMuIEl0IHdvdWxkIG5vdAogbWFr
ZSBzZW5zZSB0byBmZXRjaCBhbmQgYWxpZ24gZGF0YSBhdCBvbmUgbWludXRlIGludGVydmFs
cy4KCg4KBwQAAwACAgYSAzMEHAoOCgcEAAMAAgIBEgMzHTEKDgoHBAADAAICAxIDMzQ1Cg4K
BwQAAwACAggSAzQIMAoRCgoEAAMAAgIInAgAEgM0CS8KXQoGBAADAAIDEgQ4BDkxGk0gT3B0
aW9uYWwuIFRhYmxlIGRpc3BsYXkgb3B0aW9ucyBmb3IgY29uZmlndXJpbmcgaG93IHRoZSB0
YWJsZSBpcwogcmVuZGVyZWQuCgoOCgcEAAMAAgMGEgM4BBcKDgoHBAADAAIDARIDOBgtCg4K
BwQAAwACAwMSAzgwMQoOCgcEAAMAAgMIEgM5CDAKEQoKBAADAAIDCJwIABIDOQkvCjQKBAQA
BAASBD0CRgMaJiBFbnVtIGZvciBtZXRyaWMgbWV0cmljX3Zpc3VhbGl6YXRpb24KCgwKBQQA
BAABEgM9BxoKIgoGBAAEAAIAEgM/BCkaEyBVbnNwZWNpZmllZCBzdGF0ZQoKDgoHBAAEAAIA
ARIDPwQkCg4KBwQABAACAAISAz8nKAonCgYEAAQAAgESA0IEDxoYIERlZmF1bHQgdGV4dCBy
ZW5kZXJpbmcKCg4KBwQABAACAQESA0IECgoOCgcEAAQAAgECEgNCDQ4KKQoGBAAEAAICEgNF
BAwaGiBIb3Jpem9udGFsIGJhciByZW5kZXJpbmcKCg4KBwQABAACAgESA0UEBwoOCgcEAAQA
AgICEgNFCgsKPgoEBAADARIESQJPAxowIFRoZSBwZXJzaXN0ZW50IHNldHRpbmdzIGZvciBh
IHRhYmxlJ3MgY29sdW1ucy4KCgwKBQQAAwEBEgNJChgKMAoGBAADAQIAEgNLBD8aISBSZXF1
aXJlZC4gVGhlIGlkIG9mIHRoZSBjb2x1bW4uCgoOCgcEAAMBAgAFEgNLBAoKDgoHBAADAQIA
ARIDSwsRCg4KBwQAAwECAAMSA0sUFQoOCgcEAAMBAgAIEgNLFj4KEQoKBAADAQIACJwIABID
Sxc9Ck0KBgQAAwECARIDTgQ+Gj4gUmVxdWlyZWQuIFdoZXRoZXIgdGhlIGNvbHVtbiBzaG91
bGQgYmUgdmlzaWJsZSBvbiBwYWdlIGxvYWQuCgoOCgcEAAMBAgEFEgNOBAgKDgoHBAADAQIB
ARIDTgkQCg4KBwQAAwECAQMSA04TFAoOCgcEAAMBAgEIEgNOFT0KEQoKBAADAQIBCJwIABID
ThY8CjoKBAQAAgASA1ICTxotIFJlcXVpcmVkLiBUaGUgZGF0YSBkaXNwbGF5ZWQgaW4gdGhp
cyB0YWJsZS4KCgwKBQQAAgAEEgNSAgoKDAoFBAACAAYSA1ILFwoMCgUEAAIAARIDUhghCgwK
BQQAAgADEgNSJCUKDAoFBAACAAgSA1ImTgoPCggEAAIACJwIABIDUidNCjIKBAQAAgESBFUC
Vi8aJCBPcHRpb25hbC4gU3RvcmUgcmVuZGVyaW5nIHN0cmF0ZWd5CgoMCgUEAAIBBhIDVQIV
CgwKBQQAAgEBEgNVFioKDAoFBAACAQMSA1UtLgoMCgUEAAIBCBIDVgYuCg8KCAQAAgEInAgA
EgNWBy0KUwoEBAACAhIEWQJaLxpFIE9wdGlvbmFsLiBUaGUgbGlzdCBvZiB0aGUgcGVyc2lz
dGVudCBjb2x1bW4gc2V0dGluZ3MgZm9yIHRoZSB0YWJsZS4KCgwKBQQAAgIEEgNZAgoKDAoF
BAACAgYSA1kLGQoMCgUEAAICARIDWRopCgwKBQQAAgIDEgNZLC0KDAoFBAACAggSA1oGLgoP
CggEAAICCJwIABIDWgctYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::Dashboard::V1::Table::TimeSeriesTable ===
    # Fields for TimeSeriesTable
    # Field: data_sets Type: 11 (.google.monitoring.dashboard.v1.TimeSeriesTable.TableDataSet)
    # Field: metric_visualization Type: 14 (.google.monitoring.dashboard.v1.TimeSeriesTable.MetricVisualization)
    # Field: column_settings Type: 11 (.google.monitoring.dashboard.v1.TimeSeriesTable.ColumnSettings)

# Enum: TimeSeriesTable::MetricVisualization
our $TimeSeriesTable_METRIC_VISUALIZATION_UNSPECIFIED = 0;
our $TimeSeriesTable_NUMBER = 1;
our $TimeSeriesTable_BAR = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::Dashboard::V1::Table - Compiled Protocol Buffers messages for google/monitoring/dashboard/v1/table.proto

=head1 SYNOPSIS

    use Google::Monitoring::Dashboard::V1::Table;

    my $msg = Google::Monitoring::Dashboard::V1::Table::TimeSeriesTable->new({
        data_sets => $data_sets,
        metric_visualization => $metric_visualization,
        column_settings => $column_settings,
    });

    # Read or update a field
    my $val = $msg->data_sets();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::Dashboard::V1::Table::TimeSeriesTable->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/dashboard/v1/table.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::Dashboard::V1::Table::TimeSeriesTable

A table that displays time series data.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_sets() >> / C<< $msg->data_sets($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Table::TimeSeriesTable::TableDataSet>)

Required. The data displayed in this table.

=item * C<< $msg->metric_visualization() >> / C<< $msg->metric_visualization($value) >>

Type: C<Enum> (L<Google::Monitoring::Dashboard::V1::TimeSeriesTable::MetricVisualization>)

Optional. Store rendering strategy

=item * C<< $msg->column_settings() >> / C<< $msg->column_settings($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Table::TimeSeriesTable::ColumnSettings>)

Optional. The list of the persistent column settings for the table.

=back

=head3 Enum: TimeSeriesTable::MetricVisualization

=over 4

=item * C<METRIC_VISUALIZATION_UNSPECIFIED> => C<0>

=item * C<NUMBER> => C<1>

=item * C<BAR> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::Dashboard::V1::Table::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
