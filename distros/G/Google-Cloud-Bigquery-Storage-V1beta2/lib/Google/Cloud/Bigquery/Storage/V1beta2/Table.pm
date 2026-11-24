package Google::Cloud::Bigquery::Storage::V1beta2::Table;

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
CjFnb29nbGUvY2xvdWQvYmlncXVlcnkvc3RvcmFnZS92MWJldGEyL3RhYmxlLnByb3RvEiVn
b29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MWJldGEyGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvIl4KC1RhYmxlU2NoZW1hEk8KBmZpZWxkcxgBIAMoCzI3Lmdvb2ds
ZS5jbG91ZC5iaWdxdWVyeS5zdG9yYWdlLnYxYmV0YTIuVGFibGVGaWVsZFNjaGVtYVIGZmll
bGRzIvYEChBUYWJsZUZpZWxkU2NoZW1hEhcKBG5hbWUYASABKAlCA+BBAlIEbmFtZRJVCgR0
eXBlGAIgASgOMjwuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnN0b3JhZ2UudjFiZXRhMi5UYWJs
ZUZpZWxkU2NoZW1hLlR5cGVCA+BBAlIEdHlwZRJVCgRtb2RlGAMgASgOMjwuZ29vZ2xlLmNs
b3VkLmJpZ3F1ZXJ5LnN0b3JhZ2UudjFiZXRhMi5UYWJsZUZpZWxkU2NoZW1hLk1vZGVCA+BB
AVIEbW9kZRJUCgZmaWVsZHMYBCADKAsyNy5nb29nbGUuY2xvdWQuYmlncXVlcnkuc3RvcmFn
ZS52MWJldGEyLlRhYmxlRmllbGRTY2hlbWFCA+BBAVIGZmllbGRzEiUKC2Rlc2NyaXB0aW9u
GAYgASgJQgPgQQFSC2Rlc2NyaXB0aW9uItUBCgRUeXBlEhQKEFRZUEVfVU5TUEVDSUZJRUQQ
ABIKCgZTVFJJTkcQARIJCgVJTlQ2NBACEgoKBkRPVUJMRRADEgoKBlNUUlVDVBAEEgkKBUJZ
VEVTEAUSCAoEQk9PTBAGEg0KCVRJTUVTVEFNUBAHEggKBERBVEUQCBIICgRUSU1FEAkSDAoI
REFURVRJTUUQChINCglHRU9HUkFQSFkQCxILCgdOVU1FUklDEAwSDgoKQklHTlVNRVJJQxAN
EgwKCElOVEVSVkFMEA4SCAoESlNPThAPIkYKBE1vZGUSFAoQTU9ERV9VTlNQRUNJRklFRBAA
EgwKCE5VTExBQkxFEAESDAoIUkVRVUlSRUQQAhIMCghSRVBFQVRFRBADQn4KKWNvbS5nb29n
bGUuY2xvdWQuYmlncXVlcnkuc3RvcmFnZS52MWJldGEyQgpUYWJsZVByb3RvUAFaQ2Nsb3Vk
Lmdvb2dsZS5jb20vZ28vYmlncXVlcnkvc3RvcmFnZS9hcGl2MWJldGEyL3N0b3JhZ2VwYjtz
dG9yYWdlcGJK5BgKBhIEDgBuAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2ds
ZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4w
ICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGlu
IGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBv
ZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMv
TElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdy
ZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGlj
ZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJS
QU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGlt
cGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zl
cm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4K
CggKAQISAxAALgoJCgIDABIDEgApCggKAQgSAxQAWgoJCgIICxIDFABaCggKAQgSAxUAIgoJ
CgIIChIDFQAiCggKAQgSAxYAKwoJCgIICBIDFgArCggKAQgSAxcAQgoJCgIIARIDFwBCCh8K
AgQAEgQaAB0BGhMgU2NoZW1hIG9mIGEgdGFibGUKCgoKAwQAARIDGggTCi8KBAQAAgASAxwC
JxoiIERlc2NyaWJlcyB0aGUgZmllbGRzIGluIGEgdGFibGUuCgoMCgUEAAIABBIDHAIKCgwK
BQQAAgAGEgMcCxsKDAoFBAACAAESAxwcIgoMCgUEAAIAAxIDHCUmCiQKAgQBEgQgAG4BGhgg
QSBmaWVsZCBpbiBUYWJsZVNjaGVtYQoKCgoDBAEBEgMgCBgKDAoEBAEEABIEIQJRAwoMCgUE
AQQAARIDIQcLCh4KBgQBBAACABIDIwQZGg8gSWxsZWdhbCB2YWx1ZQoKDgoHBAEEAAIAARID
IwQUCg4KBwQBBAACAAISAyMXGAoaCgYEAQQAAgESAyYEDxoLIDY0SywgVVRGOAoKDgoHBAEE
AAIBARIDJgQKCg4KBwQBBAACAQISAyYNDgoeCgYEAQQAAgISAykEDhoPIDY0LWJpdCBzaWdu
ZWQKCg4KBwQBBAACAgESAykECQoOCgcEAQQAAgICEgMpDA0KKwoGBAEEAAIDEgMsBA8aHCA2
NC1iaXQgSUVFRSBmbG9hdGluZyBwb2ludAoKDgoHBAEEAAIDARIDLAQKCg4KBwQBBAACAwIS
AywNDgofCgYEAQQAAgQSAy8EDxoQIEFnZ3JlZ2F0ZSB0eXBlCgoOCgcEAQQAAgQBEgMvBAoK
DgoHBAEEAAIEAhIDLw0OChwKBgQBBAACBRIDMgQOGg0gNjRLLCBCaW5hcnkKCg4KBwQBBAAC
BQESAzIECQoOCgcEAQQAAgUCEgMyDA0KGQoGBAEEAAIGEgM1BA0aCiAyLXZhbHVlZAoKDgoH
BAEEAAIGARIDNQQICg4KBwQBBAACBgISAzULDAozCgYEAQQAAgcSAzgEEhokIDY0LWJpdCBz
aWduZWQgdXNlYyBzaW5jZSBVVEMgZXBvY2gKCg4KBwQBBAACBwESAzgEDQoOCgcEAQQAAgcC
EgM4EBEKLgoGBAEEAAIIEgM7BA0aHyBDaXZpbCBkYXRlIC0gWWVhciwgTW9udGgsIERheQoK
DgoHBAEEAAIIARIDOwQICg4KBwQBBAACCAISAzsLDApACgYEAQQAAgkSAz4EDRoxIENpdmls
IHRpbWUgLSBIb3VyLCBNaW51dGUsIFNlY29uZCwgTWljcm9zZWNvbmRzCgoOCgcEAQQAAgkB
EgM+BAgKDgoHBAEEAAIJAhIDPgsMCjkKBgQBBAACChIDQQQSGiogQ29tYmluYXRpb24gb2Yg
Y2l2aWwgZGF0ZSBhbmQgY2l2aWwgdGltZQoKDgoHBAEEAAIKARIDQQQMCg4KBwQBBAACCgIS
A0EPEQohCgYEAQQAAgsSA0QEExoSIEdlb2dyYXBoeSBvYmplY3QKCg4KBwQBBAACCwESA0QE
DQoOCgcEAQQAAgsCEgNEEBIKHgoGBAEEAAIMEgNHBBEaDyBOdW1lcmljIHZhbHVlCgoOCgcE
AQQAAgwBEgNHBAsKDgoHBAEEAAIMAhIDRw4QCiEKBgQBBAACDRIDSgQUGhIgQmlnTnVtZXJp
YyB2YWx1ZQoKDgoHBAEEAAINARIDSgQOCg4KBwQBBAACDQISA0oREwoZCgYEAQQAAg4SA00E
EhoKIEludGVydmFsCgoOCgcEAQQAAg4BEgNNBAwKDgoHBAEEAAIOAhIDTQ8RCh0KBgQBBAAC
DxIDUAQOGg4gSlNPTiwgU3RyaW5nCgoOCgcEAQQAAg8BEgNQBAgKDgoHBAEEAAIPAhIDUAsN
CgwKBAQBBAESBFMCXAMKDAoFBAEEAQESA1MHCwoeCgYEAQQBAgASA1UEGRoPIElsbGVnYWwg
dmFsdWUKCg4KBwQBBAECAAESA1UEFAoOCgcEAQQBAgACEgNVFxgKDQoGBAEEAQIBEgNXBBEK
DgoHBAEEAQIBARIDVwQMCg4KBwQBBAECAQISA1cPEAoNCgYEAQQBAgISA1kEEQoOCgcEAQQB
AgIBEgNZBAwKDgoHBAEEAQICAhIDWQ8QCg0KBgQBBAECAxIDWwQRCg4KBwQBBAECAwESA1sE
DAoOCgcEAQQBAgMCEgNbDxAKzwEKBAQBAgASA2ECOxrBASBSZXF1aXJlZC4gVGhlIGZpZWxk
IG5hbWUuIFRoZSBuYW1lIG11c3QgY29udGFpbiBvbmx5IGxldHRlcnMgKGEteiwgQS1aKSwK
IG51bWJlcnMgKDAtOSksIG9yIHVuZGVyc2NvcmVzIChfKSwgYW5kIG11c3Qgc3RhcnQgd2l0
aCBhIGxldHRlciBvcgogdW5kZXJzY29yZS4gVGhlIG1heGltdW0gbGVuZ3RoIGlzIDEyOCBj
aGFyYWN0ZXJzLgoKDAoFBAECAAUSA2ECCAoMCgUEAQIAARIDYQkNCgwKBQQBAgADEgNhEBEK
DAoFBAECAAgSA2ESOgoPCggEAQIACJwIABIDYRM5Ci0KBAQBAgESA2QCORogIFJlcXVpcmVk
LiBUaGUgZmllbGQgZGF0YSB0eXBlLgoKDAoFBAECAQYSA2QCBgoMCgUEAQIBARIDZAcLCgwK
BQQBAgEDEgNkDg8KDAoFBAECAQgSA2QQOAoPCggEAQIBCJwIABIDZBE3CkcKBAQBAgISA2cC
ORo6IE9wdGlvbmFsLiBUaGUgZmllbGQgbW9kZS4gVGhlIGRlZmF1bHQgdmFsdWUgaXMgTlVM
TEFCTEUuCgoMCgUEAQICBhIDZwIGCgwKBQQBAgIBEgNnBwsKDAoFBAECAgMSA2cODwoMCgUE
AQICCBIDZxA4Cg8KCAQBAgIInAgAEgNnETcKYgoEBAECAxIDagJQGlUgT3B0aW9uYWwuIERl
c2NyaWJlcyB0aGUgbmVzdGVkIHNjaGVtYSBmaWVsZHMgaWYgdGhlIHR5cGUgcHJvcGVydHkg
aXMgc2V0IHRvIFNUUlVDVC4KCgwKBQQBAgMEEgNqAgoKDAoFBAECAwYSA2oLGwoMCgUEAQID
ARIDahwiCgwKBQQBAgMDEgNqJSYKDAoFBAECAwgSA2onTwoPCggEAQIDCJwIABIDaihOClcK
BAQBAgQSA20CQhpKIE9wdGlvbmFsLiBUaGUgZmllbGQgZGVzY3JpcHRpb24uIFRoZSBtYXhp
bXVtIGxlbmd0aCBpcyAxLDAyNCBjaGFyYWN0ZXJzLgoKDAoFBAECBAUSA20CCAoMCgUEAQIE
ARIDbQkUCgwKBQQBAgQDEgNtFxgKDAoFBAECBAgSA20ZQQoPCggEAQIECJwIABIDbRpAYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Storage::V1beta2::Table::TableSchema ===
    # Fields for TableSchema
    # Field: fields Type: 11 (.google.cloud.bigquery.storage.v1beta2.TableFieldSchema)

# === Message: Google::Cloud::Bigquery::Storage::V1beta2::Table::TableFieldSchema ===
    # Fields for TableFieldSchema
    # Field: name Type: 9 ()
    # Field: type Type: 14 (.google.cloud.bigquery.storage.v1beta2.TableFieldSchema.Type)
    # Field: mode Type: 14 (.google.cloud.bigquery.storage.v1beta2.TableFieldSchema.Mode)
    # Field: fields Type: 11 (.google.cloud.bigquery.storage.v1beta2.TableFieldSchema)
    # Field: description Type: 9 ()

# Enum: TableFieldSchema::Type
our $TableFieldSchema_TYPE_UNSPECIFIED = 0;
our $TableFieldSchema_STRING = 1;
our $TableFieldSchema_INT64 = 2;
our $TableFieldSchema_DOUBLE = 3;
our $TableFieldSchema_STRUCT = 4;
our $TableFieldSchema_BYTES = 5;
our $TableFieldSchema_BOOL = 6;
our $TableFieldSchema_TIMESTAMP = 7;
our $TableFieldSchema_DATE = 8;
our $TableFieldSchema_TIME = 9;
our $TableFieldSchema_DATETIME = 10;
our $TableFieldSchema_GEOGRAPHY = 11;
our $TableFieldSchema_NUMERIC = 12;
our $TableFieldSchema_BIGNUMERIC = 13;
our $TableFieldSchema_INTERVAL = 14;
our $TableFieldSchema_JSON = 15;

# Enum: TableFieldSchema::Mode
our $TableFieldSchema_MODE_UNSPECIFIED = 0;
our $TableFieldSchema_NULLABLE = 1;
our $TableFieldSchema_REQUIRED = 2;
our $TableFieldSchema_REPEATED = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Storage::V1beta2::Table - Compiled Protocol Buffers messages for google/cloud/bigquery/storage/v1beta2/table.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Storage::V1beta2::Table;

    my $msg = Google::Cloud::Bigquery::Storage::V1beta2::Table::TableSchema->new({
        fields => $fields,
    });

    # Read or update a field
    my $val = $msg->fields();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Storage::V1beta2::Table::TableSchema->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/storage/v1beta2/table.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Storage::V1beta2::Table::TableSchema

Schema of a table

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta2::Table::TableFieldSchema>)

Describes the fields in a table.

=back

=head2 Google::Cloud::Bigquery::Storage::V1beta2::Table::TableFieldSchema

A field in TableSchema

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The field name. The name must contain only letters (a-z, A-Z),
numbers (0-9), or underscores (_), and must start with a letter or
underscore. The maximum length is 128 characters.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Storage::V1beta2::TableFieldSchema::Type>)

Required. The field data type.

=item * C<< $msg->mode() >> / C<< $msg->mode($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Storage::V1beta2::TableFieldSchema::Mode>)

Optional. The field mode. The default value is NULLABLE.

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Storage::V1beta2::Table::TableFieldSchema>)

Optional. Describes the nested schema fields if the type property is set to STRUCT.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The field description. The maximum length is 1,024 characters.

=back

=head3 Enum: TableFieldSchema::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<STRING> => C<1>

=item * C<INT64> => C<2>

=item * C<DOUBLE> => C<3>

=item * C<STRUCT> => C<4>

=item * C<BYTES> => C<5>

=item * C<BOOL> => C<6>

=item * C<TIMESTAMP> => C<7>

=item * C<DATE> => C<8>

=item * C<TIME> => C<9>

=item * C<DATETIME> => C<10>

=item * C<GEOGRAPHY> => C<11>

=item * C<NUMERIC> => C<12>

=item * C<BIGNUMERIC> => C<13>

=item * C<INTERVAL> => C<14>

=item * C<JSON> => C<15>

=back

=head3 Enum: TableFieldSchema::Mode

=over 4

=item * C<MODE_UNSPECIFIED> => C<0>

=item * C<NULLABLE> => C<1>

=item * C<REQUIRED> => C<2>

=item * C<REPEATED> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Storage::V1beta2::Table::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
