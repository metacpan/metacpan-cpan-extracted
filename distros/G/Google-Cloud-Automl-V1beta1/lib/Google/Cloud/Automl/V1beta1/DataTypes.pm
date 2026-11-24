package Google::Cloud::Automl::V1beta1::DataTypes;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvZGF0YV90eXBlcy5wcm90bxIbZ29vZ2xl
LmNsb3VkLmF1dG9tbC52MWJldGExIrkCCghEYXRhVHlwZRJTChFsaXN0X2VsZW1lbnRfdHlw
ZRgCIAEoCzIlLmdvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5EYXRhVHlwZUgAUg9saXN0
RWxlbWVudFR5cGUSSgoLc3RydWN0X3R5cGUYAyABKAsyJy5nb29nbGUuY2xvdWQuYXV0b21s
LnYxYmV0YTEuU3RydWN0VHlwZUgAUgpzdHJ1Y3RUeXBlEiEKC3RpbWVfZm9ybWF0GAUgASgJ
SABSCnRpbWVGb3JtYXQSQgoJdHlwZV9jb2RlGAEgASgOMiUuZ29vZ2xlLmNsb3VkLmF1dG9t
bC52MWJldGExLlR5cGVDb2RlUgh0eXBlQ29kZRIaCghudWxsYWJsZRgEIAEoCFIIbnVsbGFi
bGVCCQoHZGV0YWlscyK7AQoKU3RydWN0VHlwZRJLCgZmaWVsZHMYASADKAsyMy5nb29nbGUu
Y2xvdWQuYXV0b21sLnYxYmV0YTEuU3RydWN0VHlwZS5GaWVsZHNFbnRyeVIGZmllbGRzGmAK
C0ZpZWxkc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EjsKBXZhbHVlGAIgASgLMiUuZ29vZ2xl
LmNsb3VkLmF1dG9tbC52MWJldGExLkRhdGFUeXBlUgV2YWx1ZToCOAEqcgoIVHlwZUNvZGUS
GQoVVFlQRV9DT0RFX1VOU1BFQ0lGSUVEEAASCwoHRkxPQVQ2NBADEg0KCVRJTUVTVEFNUBAE
EgoKBlNUUklORxAGEgkKBUFSUkFZEAgSCgoGU1RSVUNUEAkSDAoIQ0FURUdPUlkQCkKbAQof
Y29tLmdvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMVABWjdjbG91ZC5nb29nbGUuY29tL2dv
L2F1dG9tbC9hcGl2MWJldGExL2F1dG9tbHBiO2F1dG9tbHBiygIbR29vZ2xlXENsb3VkXEF1
dG9NbFxWMWJldGEx6gIeR29vZ2xlOjpDbG91ZDo6QXV0b01MOjpWMWJldGExSu0fCgYSBA4A
ZwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACQKCAoBCBID
EwBOCgkKAggLEgMTAE4KCAoBCBIDFAAiCgkKAggKEgMUACIKCAoBCBIDFQA4CgkKAggBEgMV
ADgKCAoBCBIDFgA4CgkKAggpEgMWADgKCAoBCBIDFwA3CgkKAggtEgMXADcKYAoCBQASBBsA
PAEaVCBgVHlwZUNvZGVgIGlzIHVzZWQgYXMgYSBwYXJ0IG9mCiBbRGF0YVR5cGVdW2dvb2ds
ZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5EYXRhVHlwZV0uCgoKCgMFAAESAxsFDQoxCgQFAAIA
EgMdAhwaJCBOb3Qgc3BlY2lmaWVkLiBTaG91bGQgbm90IGJlIHVzZWQuCgoMCgUFAAIAARID
HQIXCgwKBQUAAgACEgMdGhsKXAoEBQACARIDIQIOGk8gRW5jb2RlZCBhcyBgbnVtYmVyYCwg
b3IgdGhlIHN0cmluZ3MgYCJOYU4iYCwgYCJJbmZpbml0eSJgLCBvcgogYCItSW5maW5pdHki
YC4KCgwKBQUAAgEBEgMhAgkKDAoFBQACAQISAyEMDQqUAgoEBQACAhIDJwIQGoYCIE11c3Qg
YmUgYmV0d2VlbiAwQUQgYW5kIDk5OTlBRC4gRW5jb2RlZCBhcyBgc3RyaW5nYCBhY2NvcmRp
bmcgdG8KIFt0aW1lX2Zvcm1hdF1bZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLkRhdGFU
eXBlLnRpbWVfZm9ybWF0XSwgb3IsIGlmCiB0aGF0IGZvcm1hdCBpcyBub3Qgc2V0LCB0aGVu
IGluIFJGQyAzMzM5IGBkYXRlLXRpbWVgIGZvcm1hdCwgd2hlcmUKIGB0aW1lLW9mZnNldGAg
PSBgIloiYCAoZS5nLiAxOTg1LTA0LTEyVDIzOjIwOjUwLjUyWikuCgoMCgUFAAICARIDJwIL
CgwKBQUAAgICEgMnDg8KIwoEBQACAxIDKgINGhYgRW5jb2RlZCBhcyBgc3RyaW5nYC4KCgwK
BQUAAgMBEgMqAggKDAoFBQACAwISAyoLDAqmAQoEBQACBBIDLwIMGpgBIEVuY29kZWQgYXMg
YGxpc3RgLCB3aGVyZSB0aGUgbGlzdCBlbGVtZW50cyBhcmUgcmVwcmVzZW50ZWQgYWNjb3Jk
aW5nIHRvCgogW2xpc3RfZWxlbWVudF90eXBlXVtnb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0
YTEuRGF0YVR5cGUubGlzdF9lbGVtZW50X3R5cGVdLgoKDAoFBQACBAESAy8CBwoMCgUFAAIE
AhIDLwoLCpYBCgQFAAIFEgMzAg0aiAEgRW5jb2RlZCBhcyBgc3RydWN0YCwgd2hlcmUgZmll
bGQgdmFsdWVzIGFyZSByZXByZXNlbnRlZCBhY2NvcmRpbmcgdG8KIFtzdHJ1Y3RfdHlwZV1b
Z29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLkRhdGFUeXBlLnN0cnVjdF90eXBlXS4KCgwK
BQUAAgUBEgMzAggKDAoFBQACBQISAzMLDArEAgoEBQACBhIDOwIQGrYCIFZhbHVlcyBvZiB0
aGlzIHR5cGUgYXJlIG5vdCBmdXJ0aGVyIHVuZGVyc3Rvb2QgYnkgQXV0b01MLAogZS5nLiBB
dXRvTUwgaXMgdW5hYmxlIHRvIHRlbGwgdGhlIG9yZGVyIG9mIHZhbHVlcyAoYXMgaXQgY291
bGQgd2l0aAogRkxPQVQ2NCksIG9yIGlzIHVuYWJsZSB0byBzYXkgaWYgb25lIHZhbHVlIGNv
bnRhaW5zIGFub3RoZXIgKGFzIGl0CiBjb3VsZCB3aXRoIFNUUklORykuCiBFbmNvZGVkIGFz
IGBzdHJpbmdgIChieXRlcyBzaG91bGQgYmUgYmFzZTY0LWVuY29kZWQsIGFzIGRlc2NyaWJl
ZCBpbiBSRkMKIDQ2NDgsIHNlY3Rpb24gNCkuCgoMCgUFAAIGARIDOwIKCgwKBQUAAgYCEgM7
DQ8KaAoCBAASBEAAXwEaXCBJbmRpY2F0ZWQgdGhlIHR5cGUgb2YgZGF0YSB0aGF0IGNhbiBi
ZSBzdG9yZWQgaW4gYSBzdHJ1Y3R1cmVkIGRhdGEgZW50aXR5CiAoZS5nLiBhIHRhYmxlKS4K
CgoKAwQAARIDQAgQCkkKBAQACAASBEICVwMaOyBEZXRhaWxzIG9mIERhdGFUeXBlLXMgdGhh
dCBuZWVkIGFkZGl0aW9uYWwgc3BlY2lmaWNhdGlvbi4KCgwKBQQACAABEgNCCA8KvQEKBAQA
AgASA0UEIxqvASBJZiBbdHlwZV9jb2RlXVtnb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEu
RGF0YVR5cGUudHlwZV9jb2RlXSA9PSBbQVJSQVldW2dvb2dsZS5jbG91ZC5hdXRvbWwudjFi
ZXRhMS5UeXBlQ29kZS5BUlJBWV0sCiB0aGVuIGBsaXN0X2VsZW1lbnRfdHlwZWAgaXMgdGhl
IHR5cGUgb2YgdGhlIGVsZW1lbnRzLgoKDAoFBAACAAYSA0UEDAoMCgUEAAIAARIDRQ0eCgwK
BQQAAgADEgNFISIKzwEKBAQAAgESA0kEHxrBASBJZiBbdHlwZV9jb2RlXVtnb29nbGUuY2xv
dWQuYXV0b21sLnYxYmV0YTEuRGF0YVR5cGUudHlwZV9jb2RlXSA9PSBbU1RSVUNUXVtnb29n
bGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuVHlwZUNvZGUuU1RSVUNUXSwgdGhlbiBgc3RydWN0
X3R5cGVgCiBwcm92aWRlcyB0eXBlIGluZm9ybWF0aW9uIGZvciB0aGUgc3RydWN0J3MgZmll
bGRzLgoKDAoFBAACAQYSA0kEDgoMCgUEAAIBARIDSQ8aCgwKBQQAAgEDEgNJHR4KzAQKBAQA
AgISA1YEGxq+BCBJZiBbdHlwZV9jb2RlXVtnb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEu
RGF0YVR5cGUudHlwZV9jb2RlXSA9PSBbVElNRVNUQU1QXVtnb29nbGUuY2xvdWQuYXV0b21s
LnYxYmV0YTEuVHlwZUNvZGUuVElNRVNUQU1QXQogdGhlbiBgdGltZV9mb3JtYXRgIHByb3Zp
ZGVzIHRoZSBmb3JtYXQgaW4gd2hpY2ggdGhhdCB0aW1lIGZpZWxkIGlzCiBleHByZXNzZWQu
IFRoZSB0aW1lX2Zvcm1hdCBtdXN0IGVpdGhlciBiZSBvbmUgb2Y6CiAqIGBVTklYX1NFQ09O
RFNgCiAqIGBVTklYX01JTExJU0VDT05EU2AKICogYFVOSVhfTUlDUk9TRUNPTkRTYAogKiBg
VU5JWF9OQU5PU0VDT05EU2AKIChmb3IgcmVzcGVjdGl2ZWx5IG51bWJlciBvZiBzZWNvbmRz
LCBtaWxsaXNlY29uZHMsIG1pY3Jvc2Vjb25kcyBhbmQKIG5hbm9zZWNvbmRzIHNpbmNlIHN0
YXJ0IG9mIHRoZSBVbml4IGVwb2NoKTsKIG9yIGJlIHdyaXR0ZW4gaW4gYHN0cmZ0aW1lYCBz
eW50YXguIElmIHRpbWVfZm9ybWF0IGlzIG5vdCBzZXQsIHRoZW4gdGhlCiBkZWZhdWx0IGZv
cm1hdCBhcyBkZXNjcmliZWQgb24gdGhlIHR5cGVfY29kZSBpcyB1c2VkLgoKDAoFBAACAgUS
A1YECgoMCgUEAAICARIDVgsWCgwKBQQAAgIDEgNWGRoKXAoEBAACAxIDWgIZGk8gUmVxdWly
ZWQuIFRoZSBbVHlwZUNvZGVdW2dvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5UeXBlQ29k
ZV0gZm9yIHRoaXMgdHlwZS4KCgwKBQQAAgMGEgNaAgoKDAoFBAACAwESA1oLFAoMCgUEAAID
AxIDWhcYCnYKBAQAAgQSA14CFBppIElmIHRydWUsIHRoaXMgRGF0YVR5cGUgY2FuIGFsc28g
YmUgYE5VTExgLiBJbiAuQ1NWIGZpbGVzIGBOVUxMYCB2YWx1ZSBpcwogZXhwcmVzc2VkIGFz
IGFuIGVtcHR5IHN0cmluZy4KCgwKBQQAAgQFEgNeAgYKDAoFBAACBAESA14HDwoMCgUEAAIE
AxIDXhITCnIKAgQBEgRiAGcBGmYgYFN0cnVjdFR5cGVgIGRlZmluZXMgdGhlIERhdGFUeXBl
LXMgb2YgYSBbU1RSVUNUXVtnb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuVHlwZUNvZGUu
U1RSVUNUXSB0eXBlLgoKCgoDBAEBEgNiCBIKpgEKBAQBAgASA2YCIxqYASBVbm9yZGVyZWQg
bWFwIG9mIHN0cnVjdCBmaWVsZCBuYW1lcyB0byB0aGVpciBkYXRhIHR5cGVzLgogRmllbGRz
IGNhbm5vdCBiZSBhZGRlZCBvciByZW1vdmVkIHZpYSBVcGRhdGUuIFRoZWlyIG5hbWVzIGFu
ZAogZGF0YSB0eXBlcyBhcmUgc3RpbGwgbXV0YWJsZS4KCgwKBQQBAgAGEgNmAhcKDAoFBAEC
AAESA2YYHgoMCgUEAQIAAxIDZiEiYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::DataTypes::DataType ===
    # Fields for DataType
    # Field: list_element_type Type: 11 (.google.cloud.automl.v1beta1.DataType)
    # Field: struct_type Type: 11 (.google.cloud.automl.v1beta1.StructType)
    # Field: time_format Type: 9 ()
    # Field: type_code Type: 14 (.google.cloud.automl.v1beta1.TypeCode)
    # Field: nullable Type: 8 ()

# === Message: Google::Cloud::Automl::V1beta1::DataTypes::StructType ===
    # Fields for StructType
    # Field: fields Type: 11 (.google.cloud.automl.v1beta1.StructType.FieldsEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::DataTypes - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/data_types.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::DataTypes;

    my $msg = Google::Cloud::Automl::V1beta1::DataTypes::DataType->new({
        list_element_type => $list_element_type,
        struct_type => $struct_type,
        time_format => $time_format,
        type_code => $type_code,
    });

    # Read or update a field
    my $val = $msg->list_element_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::DataTypes::DataType->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/data_types.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::DataTypes::DataType

Indicated the type of data that can be stored in a structured data entity
(e.g. a table).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->list_element_type() >> / C<< $msg->list_element_type($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataTypes::DataType>)

If [type_code][google.cloud.automl.v1beta1.DataType.type_code] == [ARRAY][google.cloud.automl.v1beta1.TypeCode.ARRAY],
then `list_element_type` is the type of the elements.

=item * C<< $msg->struct_type() >> / C<< $msg->struct_type($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataTypes::StructType>)

If [type_code][google.cloud.automl.v1beta1.DataType.type_code] == [STRUCT][google.cloud.automl.v1beta1.TypeCode.STRUCT], then `struct_type`
provides type information for the struct's fields.

=item * C<< $msg->time_format() >> / C<< $msg->time_format($value) >>

Type: C<String>

If [type_code][google.cloud.automl.v1beta1.DataType.type_code] == [TIMESTAMP][google.cloud.automl.v1beta1.TypeCode.TIMESTAMP]
then `time_format` provides the format in which that time field is
expressed. The time_format must either be one of:
* `UNIX_SECONDS`
* `UNIX_MILLISECONDS`
* `UNIX_MICROSECONDS`
* `UNIX_NANOSECONDS`
(for respectively number of seconds, milliseconds, microseconds and
nanoseconds since start of the Unix epoch);
or be written in `strftime` syntax. If time_format is not set, then the
default format as described on the type_code is used.

=item * C<< $msg->type_code() >> / C<< $msg->type_code($value) >>

Type: C<Enum> (L<Google::Cloud::Automl::V1beta1::TypeCode>)

Required. The [TypeCode][google.cloud.automl.v1beta1.TypeCode] for this type.

=item * C<< $msg->nullable() >> / C<< $msg->nullable($value) >>

Type: C<Bool>

If true, this DataType can also be `NULL`. In .CSV files `NULL` value is
expressed as an empty string.

=back

=head2 Google::Cloud::Automl::V1beta1::DataTypes::StructType

`StructType` defines the DataType-s of a [STRUCT][google.cloud.automl.v1beta1.TypeCode.STRUCT] type.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataTypes::StructType::FieldsEntry>)

Unordered map of struct field names to their data types.
Fields cannot be added or removed via Update. Their names and
data types are still mutable.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::DataTypes::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
