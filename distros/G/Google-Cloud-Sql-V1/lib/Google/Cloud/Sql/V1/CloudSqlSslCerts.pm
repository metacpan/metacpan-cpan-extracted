package Google::Cloud::Sql::V1::CloudSqlSslCerts;

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
Ci1nb29nbGUvY2xvdWQvc3FsL3YxL2Nsb3VkX3NxbF9zc2xfY2VydHMucHJvdG8SE2dvb2ds
ZS5jbG91ZC5zcWwudjEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9h
cGkvY2xpZW50LnByb3RvGi1nb29nbGUvY2xvdWQvc3FsL3YxL2Nsb3VkX3NxbF9yZXNvdXJj
ZXMucHJvdG8iewoYU3FsU3NsQ2VydHNEZWxldGVSZXF1ZXN0EhoKCGluc3RhbmNlGAEgASgJ
UghpbnN0YW5jZRIYCgdwcm9qZWN0GAIgASgJUgdwcm9qZWN0EikKEHNoYTFfZmluZ2VycHJp
bnQYAyABKAlSD3NoYTFGaW5nZXJwcmludCJ4ChVTcWxTc2xDZXJ0c0dldFJlcXVlc3QSGgoI
aW5zdGFuY2UYASABKAlSCGluc3RhbmNlEhgKB3Byb2plY3QYAiABKAlSB3Byb2plY3QSKQoQ
c2hhMV9maW5nZXJwcmludBgDIAEoCVIPc2hhMUZpbmdlcnByaW50IpABChhTcWxTc2xDZXJ0
c0luc2VydFJlcXVlc3QSGgoIaW5zdGFuY2UYASABKAlSCGluc3RhbmNlEhgKB3Byb2plY3QY
AiABKAlSB3Byb2plY3QSPgoEYm9keRhkIAEoCzIqLmdvb2dsZS5jbG91ZC5zcWwudjEuU3Ns
Q2VydHNJbnNlcnRSZXF1ZXN0UgRib2R5Ik4KFlNxbFNzbENlcnRzTGlzdFJlcXVlc3QSGgoI
aW5zdGFuY2UYASABKAlSCGluc3RhbmNlEhgKB3Byb2plY3QYAiABKAlSB3Byb2plY3QiOAoV
U3NsQ2VydHNJbnNlcnRSZXF1ZXN0Eh8KC2NvbW1vbl9uYW1lGAEgASgJUgpjb21tb25OYW1l
IvMBChZTc2xDZXJ0c0luc2VydFJlc3BvbnNlEhIKBGtpbmQYASABKAlSBGtpbmQSPAoJb3Bl
cmF0aW9uGAIgASgLMh4uZ29vZ2xlLmNsb3VkLnNxbC52MS5PcGVyYXRpb25SCW9wZXJhdGlv
bhJCCg5zZXJ2ZXJfY2FfY2VydBgDIAEoCzIcLmdvb2dsZS5jbG91ZC5zcWwudjEuU3NsQ2Vy
dFIMc2VydmVyQ2FDZXJ0EkMKC2NsaWVudF9jZXJ0GAQgASgLMiIuZ29vZ2xlLmNsb3VkLnNx
bC52MS5Tc2xDZXJ0RGV0YWlsUgpjbGllbnRDZXJ0Il4KFFNzbENlcnRzTGlzdFJlc3BvbnNl
EhIKBGtpbmQYASABKAlSBGtpbmQSMgoFaXRlbXMYAiADKAsyHC5nb29nbGUuY2xvdWQuc3Fs
LnYxLlNzbENlcnRSBWl0ZW1zMqoGChJTcWxTc2xDZXJ0c1NlcnZpY2USqAEKBkRlbGV0ZRIt
Lmdvb2dsZS5jbG91ZC5zcWwudjEuU3FsU3NsQ2VydHNEZWxldGVSZXF1ZXN0Gh4uZ29vZ2xl
LmNsb3VkLnNxbC52MS5PcGVyYXRpb24iT4LT5JMCSSpHL3YxL3Byb2plY3RzL3twcm9qZWN0
fS9pbnN0YW5jZXMve2luc3RhbmNlfS9zc2xDZXJ0cy97c2hhMV9maW5nZXJwcmludH0SoAEK
A0dldBIqLmdvb2dsZS5jbG91ZC5zcWwudjEuU3FsU3NsQ2VydHNHZXRSZXF1ZXN0GhwuZ29v
Z2xlLmNsb3VkLnNxbC52MS5Tc2xDZXJ0Ik+C0+STAkkSRy92MS9wcm9qZWN0cy97cHJvamVj
dH0vaW5zdGFuY2VzL3tpbnN0YW5jZX0vc3NsQ2VydHMve3NoYTFfZmluZ2VycHJpbnR9EqgB
CgZJbnNlcnQSLS5nb29nbGUuY2xvdWQuc3FsLnYxLlNxbFNzbENlcnRzSW5zZXJ0UmVxdWVz
dBorLmdvb2dsZS5jbG91ZC5zcWwudjEuU3NsQ2VydHNJbnNlcnRSZXNwb25zZSJCgtPkkwI8
IjQvdjEvcHJvamVjdHMve3Byb2plY3R9L2luc3RhbmNlcy97aW5zdGFuY2V9L3NzbENlcnRz
OgRib2R5EpwBCgRMaXN0EisuZ29vZ2xlLmNsb3VkLnNxbC52MS5TcWxTc2xDZXJ0c0xpc3RS
ZXF1ZXN0GikuZ29vZ2xlLmNsb3VkLnNxbC52MS5Tc2xDZXJ0c0xpc3RSZXNwb25zZSI8gtPk
kwI2EjQvdjEvcHJvamVjdHMve3Byb2plY3R9L2luc3RhbmNlcy97aW5zdGFuY2V9L3NzbENl
cnRzGnzKQRdzcWxhZG1pbi5nb29nbGVhcGlzLmNvbdJBX2h0dHBzOi8vd3d3Lmdvb2dsZWFw
aXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20v
YXV0aC9zcWxzZXJ2aWNlLmFkbWluQl0KF2NvbS5nb29nbGUuY2xvdWQuc3FsLnYxQhVDbG91
ZFNxbFNzbENlcnRzUHJvdG9QAVopY2xvdWQuZ29vZ2xlLmNvbS9nby9zcWwvYXBpdjEvc3Fs
cGI7c3FscGJK0B8KBxIFDgCMAQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQABwKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUADcKCAoBCBIDFgBA
CgkKAggLEgMWAEAKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAA2CgkKAggIEgMYADYK
CAoBCBIDGQAwCgkKAggBEgMZADAKQgoCBgASBBwAQwEaNiBTZXJ2aWNlIHRvIG1hbmFnZSBT
U0wgY2VydHMgZm9yIENsb3VkIFNRTCBpbnN0YW5jZXMuCgoKCgMGAAESAxwIGgoKCgMGAAMS
Ax0CPwoMCgUGAAOZCBIDHQI/CgsKAwYAAxIEHgIgOQoNCgUGAAOaCBIEHgIgOQqMAQoEBgAC
ABIEJAIoAxp+IERlbGV0ZXMgdGhlIFNTTCBjZXJ0aWZpY2F0ZS4gRm9yIEZpcnN0IEdlbmVy
YXRpb24gaW5zdGFuY2VzLCB0aGUKIGNlcnRpZmljYXRlIHJlbWFpbnMgdmFsaWQgdW50aWwg
dGhlIGluc3RhbmNlIGlzIHJlc3RhcnRlZC4KCgwKBQYAAgABEgMkBgwKDAoFBgACAAISAyQN
JQoMCgUGAAIAAxIDJDA5Cg0KBQYAAgAEEgQlBCcGChEKCQYAAgAEsMq8IhIEJQQnBgq4AQoE
BgACARIELQIxAxqpASBSZXRyaWV2ZXMgYSBwYXJ0aWN1bGFyIFNTTCBjZXJ0aWZpY2F0ZS4g
IERvZXMgbm90IGluY2x1ZGUgdGhlIHByaXZhdGUga2V5CiAocmVxdWlyZWQgZm9yIHVzYWdl
KS4gIFRoZSBwcml2YXRlIGtleSBtdXN0IGJlIHNhdmVkIGZyb20gdGhlIHJlc3BvbnNlIHRv
CiBpbml0aWFsIGNyZWF0aW9uLgoKDAoFBgACAQESAy0GCQoMCgUGAAIBAhIDLQofCgwKBQYA
AgEDEgMtKjEKDQoFBgACAQQSBC4EMAYKEQoJBgACAQSwyrwiEgQuBDAGCsIBCgQGAAICEgQ2
AjsDGrMBIENyZWF0ZXMgYW4gU1NMIGNlcnRpZmljYXRlIGFuZCByZXR1cm5zIGl0IGFsb25n
IHdpdGggdGhlIHByaXZhdGUga2V5IGFuZAogc2VydmVyIGNlcnRpZmljYXRlIGF1dGhvcml0
eS4gIFRoZSBuZXcgY2VydGlmaWNhdGUgd2lsbCBub3QgYmUgdXNhYmxlIHVudGlsCiB0aGUg
aW5zdGFuY2UgaXMgcmVzdGFydGVkLgoKDAoFBgACAgESAzYGDAoMCgUGAAICAhIDNg0lCgwK
BQYAAgIDEgM2MEYKDQoFBgACAgQSBDcEOgYKEQoJBgACAgSwyrwiEgQ3BDoGCksKBAYAAgMS
BD4CQgMaPSBMaXN0cyBhbGwgb2YgdGhlIGN1cnJlbnQgU1NMIGNlcnRpZmljYXRlcyBmb3Ig
dGhlIGluc3RhbmNlLgoKDAoFBgACAwESAz4GCgoMCgUGAAIDAhIDPgshCgwKBQYAAgMDEgM+
LEAKDQoFBgACAwQSBD8EQQYKEQoJBgACAwSwyrwiEgQ/BEEGCgoKAgQAEgRFAE4BCgoKAwQA
ARIDRQggCksKBAQAAgASA0cCFho+IENsb3VkIFNRTCBpbnN0YW5jZSBJRC4gVGhpcyBkb2Vz
IG5vdCBpbmNsdWRlIHRoZSBwcm9qZWN0IElELgoKDAoFBAACAAUSA0cCCAoMCgUEAAIAARID
RwkRCgwKBQQAAgADEgNHFBUKRAoEBAACARIDSgIVGjcgUHJvamVjdCBJRCBvZiB0aGUgcHJv
amVjdCB0aGF0IGNvbnRhaW5zIHRoZSBpbnN0YW5jZS4KCgwKBQQAAgEFEgNKAggKDAoFBAAC
AQESA0oJEAoMCgUEAAIBAxIDShMUCiAKBAQAAgISA00CHhoTIFNoYTEgRmluZ2VyUHJpbnQu
CgoMCgUEAAICBRIDTQIICgwKBQQAAgIBEgNNCRkKDAoFBAACAgMSA00cHQoKCgIEARIEUABZ
AQoKCgMEAQESA1AIHQpLCgQEAQIAEgNSAhYaPiBDbG91ZCBTUUwgaW5zdGFuY2UgSUQuIFRo
aXMgZG9lcyBub3QgaW5jbHVkZSB0aGUgcHJvamVjdCBJRC4KCgwKBQQBAgAFEgNSAggKDAoF
BAECAAESA1IJEQoMCgUEAQIAAxIDUhQVCkQKBAQBAgESA1UCFRo3IFByb2plY3QgSUQgb2Yg
dGhlIHByb2plY3QgdGhhdCBjb250YWlucyB0aGUgaW5zdGFuY2UuCgoMCgUEAQIBBRIDVQII
CgwKBQQBAgEBEgNVCRAKDAoFBAECAQMSA1UTFAogCgQEAQICEgNYAh4aEyBTaGExIEZpbmdl
clByaW50LgoKDAoFBAECAgUSA1gCCAoMCgUEAQICARIDWAkZCgwKBQQBAgIDEgNYHB0KCgoC
BAISBFsAYwEKCgoDBAIBEgNbCCAKSwoEBAICABIDXQIWGj4gQ2xvdWQgU1FMIGluc3RhbmNl
IElELiBUaGlzIGRvZXMgbm90IGluY2x1ZGUgdGhlIHByb2plY3QgSUQuCgoMCgUEAgIABRID
XQIICgwKBQQCAgABEgNdCREKDAoFBAICAAMSA10UFQpECgQEAgIBEgNgAhUaNyBQcm9qZWN0
IElEIG9mIHRoZSBwcm9qZWN0IHRoYXQgY29udGFpbnMgdGhlIGluc3RhbmNlLgoKDAoFBAIC
AQUSA2ACCAoMCgUEAgIBARIDYAkQCgwKBQQCAgEDEgNgExQKCwoEBAICAhIDYgIjCgwKBQQC
AgIGEgNiAhcKDAoFBAICAgESA2IYHAoMCgUEAgICAxIDYh8iCgoKAgQDEgRlAGsBCgoKAwQD
ARIDZQgeCksKBAQDAgASA2cCFho+IENsb3VkIFNRTCBpbnN0YW5jZSBJRC4gVGhpcyBkb2Vz
IG5vdCBpbmNsdWRlIHRoZSBwcm9qZWN0IElELgoKDAoFBAMCAAUSA2cCCAoMCgUEAwIAARID
ZwkRCgwKBQQDAgADEgNnFBUKRAoEBAMCARIDagIVGjcgUHJvamVjdCBJRCBvZiB0aGUgcHJv
amVjdCB0aGF0IGNvbnRhaW5zIHRoZSBpbnN0YW5jZS4KCgwKBQQDAgEFEgNqAggKDAoFBAMC
AQESA2oJEAoMCgUEAwIBAxIDahMUCiYKAgQEEgRuAHIBGhogU3NsQ2VydHMgaW5zZXJ0IHJl
cXVlc3QuCgoKCgMEBAESA24IHQprCgQEBAIAEgNxAhkaXiBVc2VyIHN1cHBsaWVkIG5hbWUu
ICBNdXN0IGJlIGEgZGlzdGluY3QgbmFtZSBmcm9tIHRoZSBvdGhlciBjZXJ0aWZpY2F0ZXMK
IGZvciB0aGlzIGluc3RhbmNlLgoKDAoFBAQCAAUSA3ECCAoMCgUEBAIAARIDcQkUCgwKBQQE
AgADEgNxFxgKJwoCBAUSBXUAgwEBGhogU3NsQ2VydCBpbnNlcnQgcmVzcG9uc2UuCgoKCgME
BQESA3UIHgozCgQEBQIAEgN3AhIaJiBUaGlzIGlzIGFsd2F5cyBgc3FsI3NzbENlcnRzSW5z
ZXJ0YC4KCgwKBQQFAgAFEgN3AggKDAoFBAUCAAESA3cJDQoMCgUEBQIAAxIDdxARCkMKBAQF
AgESA3oCGho2IFRoZSBvcGVyYXRpb24gdG8gdHJhY2sgdGhlIHNzbCBjZXJ0cyBpbnNlcnQg
cmVxdWVzdC4KCgwKBQQFAgEGEgN6AgsKDAoFBAUCAQESA3oMFQoMCgUEBQIBAxIDehgZCrUB
CgQEBQICEgN/Ah0apwEgVGhlIHNlcnZlciBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkncyBjZXJ0
aWZpY2F0ZS4gIElmIHRoaXMgaXMgbWlzc2luZyB5b3UgY2FuCiBmb3JjZSBhIG5ldyBvbmUg
dG8gYmUgZ2VuZXJhdGVkIGJ5IGNhbGxpbmcgcmVzZXRTc2xDb25maWcgbWV0aG9kIG9uCiBp
bnN0YW5jZXMgcmVzb3VyY2UuCgoMCgUEBQICBhIDfwIJCgwKBQQFAgIBEgN/ChgKDAoFBAUC
AgMSA38bHAo7CgQEBQIDEgSCAQIgGi0gVGhlIG5ldyBjbGllbnQgY2VydGlmaWNhdGUgYW5k
IHByaXZhdGUga2V5LgoKDQoFBAUCAwYSBIIBAg8KDQoFBAUCAwESBIIBEBsKDQoFBAUCAwMS
BIIBHh8KJwoCBAYSBoYBAIwBARoZIFNzbENlcnRzIGxpc3QgcmVzcG9uc2UuCgoLCgMEBgES
BIYBCBwKMgoEBAYCABIEiAECEhokIFRoaXMgaXMgYWx3YXlzIGBzcWwjc3NsQ2VydHNMaXN0
YC4KCg0KBQQGAgAFEgSIAQIICg0KBQQGAgABEgSIAQkNCg0KBQQGAgADEgSIARARCj0KBAQG
AgESBIsBAh0aLyBMaXN0IG9mIGNsaWVudCBjZXJ0aWZpY2F0ZXMgZm9yIHRoZSBpbnN0YW5j
ZS4KCg0KBQQGAgEEEgSLAQIKCg0KBQQGAgEGEgSLAQsSCg0KBQQGAgEBEgSLARMYCg0KBQQG
AgEDEgSLARscYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsDeleteRequest ===
    # Fields for SqlSslCertsDeleteRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: sha1_fingerprint Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsDeleteRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlSslCerts;

    my $msg = Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsDeleteRequest->new(
        instance => $value,
    );

=head1 FIELDS

=over 4

=item * B<instance>

Type: String

=item * B<project>

Type: String

=item * B<sha1_fingerprint>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsGetRequest ===
    # Fields for SqlSslCertsGetRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: sha1_fingerprint Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsGetRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlSslCerts;

    my $msg = Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsGetRequest->new(
        instance => $value,
    );

=head1 FIELDS

=over 4

=item * B<instance>

Type: String

=item * B<project>

Type: String

=item * B<sha1_fingerprint>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsInsertRequest ===
    # Fields for SqlSslCertsInsertRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()
    # Field: body Type: 11 (.google.cloud.sql.v1.SslCertsInsertRequest)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsInsertRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlSslCerts;

    my $msg = Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsInsertRequest->new(
        instance => $value,
    );

=head1 FIELDS

=over 4

=item * B<instance>

Type: String

=item * B<project>

Type: String

=item * B<body>

Type: Message (.google.cloud.sql.v1.SslCertsInsertRequest)

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsListRequest ===
    # Fields for SqlSslCertsListRequest
    # Field: instance Type: 9 ()
    # Field: project Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsListRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlSslCerts;

    my $msg = Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsListRequest->new(
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

# === Message: Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsInsertRequest ===
    # Fields for SslCertsInsertRequest
    # Field: common_name Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsInsertRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlSslCerts;

    my $msg = Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsInsertRequest->new(
        common_name => $value,
    );

=head1 FIELDS

=over 4

=item * B<common_name>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsInsertResponse ===
    # Fields for SslCertsInsertResponse
    # Field: kind Type: 9 ()
    # Field: operation Type: 11 (.google.cloud.sql.v1.Operation)
    # Field: server_ca_cert Type: 11 (.google.cloud.sql.v1.SslCert)
    # Field: client_cert Type: 11 (.google.cloud.sql.v1.SslCertDetail)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsInsertResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlSslCerts;

    my $msg = Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsInsertResponse->new(
        kind => $value,
    );

=head1 FIELDS

=over 4

=item * B<kind>

Type: String

=item * B<operation>

Type: Message (.google.cloud.sql.v1.Operation)

=item * B<server_ca_cert>

Type: Message (.google.cloud.sql.v1.SslCert)

=item * B<client_cert>

Type: Message (.google.cloud.sql.v1.SslCertDetail)

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsListResponse ===
    # Fields for SslCertsListResponse
    # Field: kind Type: 9 ()
    # Field: items Type: 11 (.google.cloud.sql.v1.SslCert)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsListResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlSslCerts;

    my $msg = Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsListResponse->new(
        kind => $value,
    );

=head1 FIELDS

=over 4

=item * B<kind>

Type: String

=item * B<items>

Type: Message (.google.cloud.sql.v1.SslCert)

=back

=cut

# === Service Client: Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsServiceClient ===
package Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsServiceClient;

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsServiceClient - Client stub representing the remote SqlSslCertsService service

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
        ? Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsDeleteRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlSslCertsService',
        method         => 'Delete',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

sub get {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsGetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlSslCertsService',
        method         => 'Get',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::SslCert',
    });
}

sub insert {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsInsertRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlSslCertsService',
        method         => 'Insert',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsInsertResponse',
    });
}

sub list {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsListRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlSslCertsService',
        method         => 'List',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsListResponse',
    });
}

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlSslCerts - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
