package Google::Cloud::Sql::V1::CloudSqlDatabases;

use strict;
use warnings;

our $VERSION = '0.11';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Cloud::Sql::V1::CloudSqlResources };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvc3FsL3YxL2Nsb3VkX3NxbF9kYXRhYmFzZXMucHJvdG8SE2dvb2ds
ZS5jbG91ZC5zcWwudjEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9h
cGkvY2xpZW50LnByb3RvGi1nb29nbGUvY2xvdWQvc3FsL3YxL2Nsb3VkX3NxbF9yZXNvdXJj
ZXMucHJvdG8ibQoZU3FsRGF0YWJhc2VzRGVsZXRlUmVxdWVzdBIaCghkYXRhYmFzZRgBIAEo
CVIIZGF0YWJhc2USGgoIaW5zdGFuY2UYAiABKAlSCGluc3RhbmNlEhgKB3Byb2plY3QYAyAB
KAlSB3Byb2plY3QiagoWU3FsRGF0YWJhc2VzR2V0UmVxdWVzdBIaCghkYXRhYmFzZRgBIAEo
CVIIZGF0YWJhc2USGgoIaW5zdGFuY2UYAiABKAlSCGluc3RhbmNlEhgKB3Byb2plY3QYAyAB
KAlSB3Byb2plY3QihAEKGVNxbERhdGFiYXNlc0luc2VydFJlcXVlc3QSGgoIaW5zdGFuY2UY
ASABKAlSCGluc3RhbmNlEhgKB3Byb2plY3QYAiABKAlSB3Byb2plY3QSMQoEYm9keRhkIAEo
CzIdLmdvb2dsZS5jbG91ZC5zcWwudjEuRGF0YWJhc2VSBGJvZHkiTwoXU3FsRGF0YWJhc2Vz
TGlzdFJlcXVlc3QSGgoIaW5zdGFuY2UYASABKAlSCGluc3RhbmNlEhgKB3Byb2plY3QYAiAB
KAlSB3Byb2plY3QioAEKGVNxbERhdGFiYXNlc1VwZGF0ZVJlcXVlc3QSGgoIZGF0YWJhc2UY
ASABKAlSCGRhdGFiYXNlEhoKCGluc3RhbmNlGAIgASgJUghpbnN0YW5jZRIYCgdwcm9qZWN0
GAMgASgJUgdwcm9qZWN0EjEKBGJvZHkYZCABKAsyHS5nb29nbGUuY2xvdWQuc3FsLnYxLkRh
dGFiYXNlUgRib2R5ImAKFURhdGFiYXNlc0xpc3RSZXNwb25zZRISCgRraW5kGAEgASgJUgRr
aW5kEjMKBWl0ZW1zGAIgAygLMh0uZ29vZ2xlLmNsb3VkLnNxbC52MS5EYXRhYmFzZVIFaXRl
bXMy7QgKE1NxbERhdGFiYXNlc1NlcnZpY2USogEKBkRlbGV0ZRIuLmdvb2dsZS5jbG91ZC5z
cWwudjEuU3FsRGF0YWJhc2VzRGVsZXRlUmVxdWVzdBoeLmdvb2dsZS5jbG91ZC5zcWwudjEu
T3BlcmF0aW9uIkiC0+STAkIqQC92MS9wcm9qZWN0cy97cHJvamVjdH0vaW5zdGFuY2VzL3tp
bnN0YW5jZX0vZGF0YWJhc2VzL3tkYXRhYmFzZX0SmwEKA0dldBIrLmdvb2dsZS5jbG91ZC5z
cWwudjEuU3FsRGF0YWJhc2VzR2V0UmVxdWVzdBodLmdvb2dsZS5jbG91ZC5zcWwudjEuRGF0
YWJhc2UiSILT5JMCQhJAL3YxL3Byb2plY3RzL3twcm9qZWN0fS9pbnN0YW5jZXMve2luc3Rh
bmNlfS9kYXRhYmFzZXMve2RhdGFiYXNlfRKdAQoGSW5zZXJ0Ei4uZ29vZ2xlLmNsb3VkLnNx
bC52MS5TcWxEYXRhYmFzZXNJbnNlcnRSZXF1ZXN0Gh4uZ29vZ2xlLmNsb3VkLnNxbC52MS5P
cGVyYXRpb24iQ4LT5JMCPSI1L3YxL3Byb2plY3RzL3twcm9qZWN0fS9pbnN0YW5jZXMve2lu
c3RhbmNlfS9kYXRhYmFzZXM6BGJvZHkSnwEKBExpc3QSLC5nb29nbGUuY2xvdWQuc3FsLnYx
LlNxbERhdGFiYXNlc0xpc3RSZXF1ZXN0GiouZ29vZ2xlLmNsb3VkLnNxbC52MS5EYXRhYmFz
ZXNMaXN0UmVzcG9uc2UiPYLT5JMCNxI1L3YxL3Byb2plY3RzL3twcm9qZWN0fS9pbnN0YW5j
ZXMve2luc3RhbmNlfS9kYXRhYmFzZXMSpwEKBVBhdGNoEi4uZ29vZ2xlLmNsb3VkLnNxbC52
MS5TcWxEYXRhYmFzZXNVcGRhdGVSZXF1ZXN0Gh4uZ29vZ2xlLmNsb3VkLnNxbC52MS5PcGVy
YXRpb24iToLT5JMCSDJAL3YxL3Byb2plY3RzL3twcm9qZWN0fS9pbnN0YW5jZXMve2luc3Rh
bmNlfS9kYXRhYmFzZXMve2RhdGFiYXNlfToEYm9keRKoAQoGVXBkYXRlEi4uZ29vZ2xlLmNs
b3VkLnNxbC52MS5TcWxEYXRhYmFzZXNVcGRhdGVSZXF1ZXN0Gh4uZ29vZ2xlLmNsb3VkLnNx
bC52MS5PcGVyYXRpb24iToLT5JMCSBpAL3YxL3Byb2plY3RzL3twcm9qZWN0fS9pbnN0YW5j
ZXMve2luc3RhbmNlfS9kYXRhYmFzZXMve2RhdGFiYXNlfToEYm9keRp8ykEXc3FsYWRtaW4u
Z29vZ2xlYXBpcy5jb23SQV9odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3Vk
LXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvc3Fsc2VydmljZS5h
ZG1pbkJeChdjb20uZ29vZ2xlLmNsb3VkLnNxbC52MUIWQ2xvdWRTcWxEYXRhYmFzZXNQcm90
b1ABWiljbG91ZC5nb29nbGUuY29tL2dvL3NxbC9hcGl2MS9zcWxwYjtzcWxwYkrzHwoHEgUO
AJcBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHAoJCgID
ABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQANwoICgEIEgMWAEAKCQoCCAsSAxYAQAoICgEI
EgMXACIKCQoCCAoSAxcAIgoICgEIEgMYADcKCQoCCAgSAxgANwoICgEIEgMZADAKCQoCCAES
AxkAMAoqCgIGABIEHABUARoeIFNlcnZpY2UgdG8gbWFuYWdlIGRhdGFiYXNlcy4KCgoKAwYA
ARIDHAgbCgoKAwYAAxIDHQI/CgwKBQYAA5kIEgMdAj8KCwoDBgADEgQeAiA5Cg0KBQYAA5oI
EgQeAiA5Cj0KBAYAAgASBCMCJwMaLyBEZWxldGVzIGEgZGF0YWJhc2UgZnJvbSBhIENsb3Vk
IFNRTCBpbnN0YW5jZS4KCgwKBQYAAgABEgMjBgwKDAoFBgACAAISAyMNJgoMCgUGAAIAAxID
IzE6Cg0KBQYAAgAEEgQkBCYGChEKCQYAAgAEsMq8IhIEJAQmBgpqCgQGAAIBEgQrAi8DGlwg
UmV0cmlldmVzIGEgcmVzb3VyY2UgY29udGFpbmluZyBpbmZvcm1hdGlvbiBhYm91dCBhIGRh
dGFiYXNlIGluc2lkZSBhIENsb3VkCiBTUUwgaW5zdGFuY2UuCgoMCgUGAAIBARIDKwYJCgwK
BQYAAgECEgMrCiAKDAoFBgACAQMSAysrMwoNCgUGAAIBBBIELAQuBgoRCgkGAAIBBLDKvCIS
BCwELgYKrwEKBAYAAgISBDUCOgMaoAEgSW5zZXJ0cyBhIHJlc291cmNlIGNvbnRhaW5pbmcg
aW5mb3JtYXRpb24gYWJvdXQgYSBkYXRhYmFzZSBpbnNpZGUgYSBDbG91ZAogU1FMIGluc3Rh
bmNlLgoKICoqTm90ZToqKiBZb3UgY2FuJ3QgbW9kaWZ5IHRoZSBkZWZhdWx0IGNoYXJhY3Rl
ciBzZXQgYW5kIGNvbGxhdGlvbi4KCgwKBQYAAgIBEgM1BgwKDAoFBgACAgISAzUNJgoMCgUG
AAICAxIDNTE6Cg0KBQYAAgIEEgQ2BDkGChEKCQYAAgIEsMq8IhIENgQ5BgpECgQGAAIDEgQ9
AkEDGjYgTGlzdHMgZGF0YWJhc2VzIGluIHRoZSBzcGVjaWZpZWQgQ2xvdWQgU1FMIGluc3Rh
bmNlLgoKDAoFBgACAwESAz0GCgoMCgUGAAIDAhIDPQsiCgwKBQYAAgMDEgM9LUIKDQoFBgAC
AwQSBD4EQAYKEQoJBgACAwSwyrwiEgQ+BEAGCpkBCgQGAAIEEgRFAkoDGooBIFBhcnRpYWxs
eSB1cGRhdGVzIGEgcmVzb3VyY2UgY29udGFpbmluZyBpbmZvcm1hdGlvbiBhYm91dCBhIGRh
dGFiYXNlIGluc2lkZQogYSBDbG91ZCBTUUwgaW5zdGFuY2UuIFRoaXMgbWV0aG9kIHN1cHBv
cnRzIHBhdGNoIHNlbWFudGljcy4KCgwKBQYAAgQBEgNFBgsKDAoFBgACBAISA0UMJQoMCgUG
AAIEAxIDRTA5Cg0KBQYAAgQEEgRGBEkGChEKCQYAAgQEsMq8IhIERgRJBgpoCgQGAAIFEgRO
AlMDGlogVXBkYXRlcyBhIHJlc291cmNlIGNvbnRhaW5pbmcgaW5mb3JtYXRpb24gYWJvdXQg
YSBkYXRhYmFzZSBpbnNpZGUgYSBDbG91ZAogU1FMIGluc3RhbmNlLgoKDAoFBgACBQESA04G
DAoMCgUGAAIFAhIDTg0mCgwKBQYAAgUDEgNOMToKDQoFBgACBQQSBE8EUgYKEQoJBgACBQSw
yrwiEgRPBFIGCiYKAgQAEgRXAGABGhogRGF0YWJhc2UgZGVsZXRlIHJlcXVlc3QuCgoKCgME
AAESA1cIIQpCCgQEAAIAEgNZAhYaNSBOYW1lIG9mIHRoZSBkYXRhYmFzZSB0byBiZSBkZWxl
dGVkIGluIHRoZSBpbnN0YW5jZS4KCgwKBQQAAgAFEgNZAggKDAoFBAACAAESA1kJEQoMCgUE
AAIAAxIDWRQVCkoKBAQAAgESA1wCFho9IERhdGFiYXNlIGluc3RhbmNlIElELiBUaGlzIGRv
ZXMgbm90IGluY2x1ZGUgdGhlIHByb2plY3QgSUQuCgoMCgUEAAIBBRIDXAIICgwKBQQAAgEB
EgNcCREKDAoFBAACAQMSA1wUFQpECgQEAAICEgNfAhUaNyBQcm9qZWN0IElEIG9mIHRoZSBw
cm9qZWN0IHRoYXQgY29udGFpbnMgdGhlIGluc3RhbmNlLgoKDAoFBAACAgUSA18CCAoMCgUE
AAICARIDXwkQCgwKBQQAAgIDEgNfExQKIwoCBAESBGMAbAEaFyBEYXRhYmFzZSBnZXQgcmVx
dWVzdC4KCgoKAwQBARIDYwgeCjQKBAQBAgASA2UCFhonIE5hbWUgb2YgdGhlIGRhdGFiYXNl
IGluIHRoZSBpbnN0YW5jZS4KCgwKBQQBAgAFEgNlAggKDAoFBAECAAESA2UJEQoMCgUEAQIA
AxIDZRQVCkoKBAQBAgESA2gCFho9IERhdGFiYXNlIGluc3RhbmNlIElELiBUaGlzIGRvZXMg
bm90IGluY2x1ZGUgdGhlIHByb2plY3QgSUQuCgoMCgUEAQIBBRIDaAIICgwKBQQBAgEBEgNo
CREKDAoFBAECAQMSA2gUFQpECgQEAQICEgNrAhUaNyBQcm9qZWN0IElEIG9mIHRoZSBwcm9q
ZWN0IHRoYXQgY29udGFpbnMgdGhlIGluc3RhbmNlLgoKDAoFBAECAgUSA2sCCAoMCgUEAQIC
ARIDawkQCgwKBQQBAgIDEgNrExQKJgoCBAISBG8AdwEaGiBEYXRhYmFzZSBpbnNlcnQgcmVx
dWVzdC4KCgoKAwQCARIDbwghCkoKBAQCAgASA3ECFho9IERhdGFiYXNlIGluc3RhbmNlIElE
LiBUaGlzIGRvZXMgbm90IGluY2x1ZGUgdGhlIHByb2plY3QgSUQuCgoMCgUEAgIABRIDcQII
CgwKBQQCAgABEgNxCREKDAoFBAICAAMSA3EUFQpECgQEAgIBEgN0AhUaNyBQcm9qZWN0IElE
IG9mIHRoZSBwcm9qZWN0IHRoYXQgY29udGFpbnMgdGhlIGluc3RhbmNlLgoKDAoFBAICAQUS
A3QCCAoMCgUEAgIBARIDdAkQCgwKBQQCAgEDEgN0ExQKCwoEBAICAhIDdgIWCgwKBQQCAgIG
EgN2AgoKDAoFBAICAgESA3YLDwoMCgUEAgICAxIDdhIVCiUKAgQDEgV6AIABARoYIERhdGFi
YXNlIGxpc3QgcmVxdWVzdC4KCgoKAwQDARIDeggfCksKBAQDAgASA3wCFho+IENsb3VkIFNR
TCBpbnN0YW5jZSBJRC4gVGhpcyBkb2VzIG5vdCBpbmNsdWRlIHRoZSBwcm9qZWN0IElELgoK
DAoFBAMCAAUSA3wCCAoMCgUEAwIAARIDfAkRCgwKBQQDAgADEgN8FBUKRAoEBAMCARIDfwIV
GjcgUHJvamVjdCBJRCBvZiB0aGUgcHJvamVjdCB0aGF0IGNvbnRhaW5zIHRoZSBpbnN0YW5j
ZS4KCgwKBQQDAgEFEgN/AggKDAoFBAMCAQESA38JEAoMCgUEAwIBAxIDfxMUCigKAgQEEgaD
AQCOAQEaGiBEYXRhYmFzZSB1cGRhdGUgcmVxdWVzdC4KCgsKAwQEARIEgwEIIQpDCgQEBAIA
EgSFAQIWGjUgTmFtZSBvZiB0aGUgZGF0YWJhc2UgdG8gYmUgdXBkYXRlZCBpbiB0aGUgaW5z
dGFuY2UuCgoNCgUEBAIABRIEhQECCAoNCgUEBAIAARIEhQEJEQoNCgUEBAIAAxIEhQEUFQpL
CgQEBAIBEgSIAQIWGj0gRGF0YWJhc2UgaW5zdGFuY2UgSUQuIFRoaXMgZG9lcyBub3QgaW5j
bHVkZSB0aGUgcHJvamVjdCBJRC4KCg0KBQQEAgEFEgSIAQIICg0KBQQEAgEBEgSIAQkRCg0K
BQQEAgEDEgSIARQVCkUKBAQEAgISBIsBAhUaNyBQcm9qZWN0IElEIG9mIHRoZSBwcm9qZWN0
IHRoYXQgY29udGFpbnMgdGhlIGluc3RhbmNlLgoKDQoFBAQCAgUSBIsBAggKDQoFBAQCAgES
BIsBCRAKDQoFBAQCAgMSBIsBExQKDAoEBAQCAxIEjQECFgoNCgUEBAIDBhIEjQECCgoNCgUE
BAIDARIEjQELDwoNCgUEBAIDAxIEjQESFQonCgIEBRIGkQEAlwEBGhkgRGF0YWJhc2UgbGlz
dCByZXNwb25zZS4KCgsKAwQFARIEkQEIHQozCgQEBQIAEgSTAQISGiUgVGhpcyBpcyBhbHdh
eXMgYHNxbCNkYXRhYmFzZXNMaXN0YC4KCg0KBQQFAgAFEgSTAQIICg0KBQQFAgABEgSTAQkN
Cg0KBQQFAgADEgSTARARCjsKBAQFAgESBJYBAh4aLSBMaXN0IG9mIGRhdGFiYXNlIHJlc291
cmNlcyBpbiB0aGUgaW5zdGFuY2UuCgoNCgUEBQIBBBIElgECCgoNCgUEBQIBBhIElgELEwoN
CgUEBQIBARIElgEUGQoNCgUEBQIBAxIElgEcHWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesDeleteRequest ===
    # Fields for SqlDatabasesDeleteRequest
    # Field: database Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesDeleteRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlDatabases;

    my $msg = Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesDeleteRequest->new(
        database => $value,
    );

=head1 FIELDS

=over 4

=item * B<database>

Type: String

=item * B<instance>

Type: String

=item * B<project>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesGetRequest ===
    # Fields for SqlDatabasesGetRequest
    # Field: database Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesGetRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlDatabases;

    my $msg = Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesGetRequest->new(
        database => $value,
    );

=head1 FIELDS

=over 4

=item * B<database>

Type: String

=item * B<instance>

Type: String

=item * B<project>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesInsertRequest ===
    # Fields for SqlDatabasesInsertRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: body Type: 11 (.google.cloud.sql.v1.Database)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesInsertRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlDatabases;

    my $msg = Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesInsertRequest->new(
        instance => $value,
    );

=head1 FIELDS

=over 4

=item * B<instance>

Type: String

=item * B<project>

Type: String

=item * B<body>

Type: Message (.google.cloud.sql.v1.Database)

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesListRequest ===
    # Fields for SqlDatabasesListRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesListRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlDatabases;

    my $msg = Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesListRequest->new(
        instance => $value,
    );

=head1 FIELDS

=over 4

=item * B<instance>

Type: String

=item * B<project>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesUpdateRequest ===
    # Fields for SqlDatabasesUpdateRequest
    # Field: database Type: 9 ()
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: body Type: 11 (.google.cloud.sql.v1.Database)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesUpdateRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlDatabases;

    my $msg = Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesUpdateRequest->new(
        database => $value,
    );

=head1 FIELDS

=over 4

=item * B<database>

Type: String

=item * B<instance>

Type: String

=item * B<project>

Type: String

=item * B<body>

Type: Message (.google.cloud.sql.v1.Database)

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlDatabases::DatabasesListResponse ===
    # Fields for DatabasesListResponse
    # Field: kind Type: 9 ()
    # Field: items Type: 11 (.google.cloud.sql.v1.Database)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlDatabases::DatabasesListResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlDatabases;

    my $msg = Google::Cloud::Sql::V1::CloudSqlDatabases::DatabasesListResponse->new(
        kind => $value,
    );

=head1 FIELDS

=over 4

=item * B<kind>

Type: String

=item * B<items>

Type: Message (.google.cloud.sql.v1.Database)

=back

=cut

# === Service Client: Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesServiceClient ===
package Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesServiceClient;

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesServiceClient - Client stub representing the remote SqlDatabasesService service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<sql.googleapis.com:443>.

=head2 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'sql.googleapis.com:443' );

has _grpc_client => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Google::gRPC::Client->new(
            target     => $self->target,
            auth_token => $self->credentials->get_token(),
        );
    }
);

sub delete {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesDeleteRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlDatabasesService',
        method         => 'Delete',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

sub get {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesGetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlDatabasesService',
        method         => 'Get',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Database',
    });
}

sub insert {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesInsertRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlDatabasesService',
        method         => 'Insert',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

sub list {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesListRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlDatabasesService',
        method         => 'List',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlDatabases::DatabasesListResponse',
    });
}

sub patch {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesUpdateRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlDatabasesService',
        method         => 'Patch',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

sub update {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesUpdateRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlDatabasesService',
        method         => 'Update',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlDatabases - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
