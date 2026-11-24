package Google::Cloud::Oracledatabase::V1::AutonomousDbVersion;

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
    eval { require Google::Cloud::Oracledatabase::V1::AutonomousDatabase };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvYXV0b25vbW91c19kYl92ZXJzaW9u
LnByb3RvEh5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjEaH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aOGdvb2dsZS9j
bG91ZC9vcmFjbGVkYXRhYmFzZS92MS9hdXRvbm9tb3VzX2RhdGFiYXNlLnByb3RvIoIDChNB
dXRvbm9tb3VzRGJWZXJzaW9uEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRIdCgd2ZXJzaW9u
GAIgASgJQgPgQQNSB3ZlcnNpb24SUAoLZGJfd29ya2xvYWQYBCABKA4yKi5nb29nbGUuY2xv
dWQub3JhY2xlZGF0YWJhc2UudjEuREJXb3JrbG9hZEID4EEDUgpkYldvcmtsb2FkEiYKDHdv
cmtsb2FkX3VyaRgFIAEoCUID4EEDUgt3b3JrbG9hZFVyaTq4AepBtAEKMW9yYWNsZWRhdGFi
YXNlLmdvb2dsZWFwaXMuY29tL0F1dG9ub21vdXNEYlZlcnNpb24SVHByb2plY3RzL3twcm9q
ZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hdXRvbm9tb3VzRGJWZXJzaW9ucy97YXV0b25v
bW91c19kYl92ZXJzaW9ufSoUYXV0b25vbW91c0RiVmVyc2lvbnMyE2F1dG9ub21vdXNEYlZl
cnNpb25C8gEKImNvbS5nb29nbGUuY2xvdWQub3JhY2xlZGF0YWJhc2UudjFCGEF1dG9ub21v
dXNEYlZlcnNpb25Qcm90b1ABWkpjbG91ZC5nb29nbGUuY29tL2dvL29yYWNsZWRhdGFiYXNl
L2FwaXYxL29yYWNsZWRhdGFiYXNlcGI7b3JhY2xlZGF0YWJhc2VwYqoCHkdvb2dsZS5DbG91
ZC5PcmFjbGVEYXRhYmFzZS5WMcoCHkdvb2dsZVxDbG91ZFxPcmFjbGVEYXRhYmFzZVxWMeoC
IUdvb2dsZTo6Q2xvdWQ6Ok9yYWNsZURhdGFiYXNlOjpWMUqlDQoGEgQOADYBCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAnCgkKAgMAEgMSACkKCQoCAwES
AxMAIwoJCgIDAhIDFABCCggKAQgSAxYAOwoJCgIIJRIDFgA7CggKAQgSAxcAYQoJCgIICxID
FwBhCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkAOQoJCgIICBIDGQA5CggKAQgSAxoA
OwoJCgIIARIDGgA7CggKAQgSAxsAOwoJCgIIKRIDGwA7CggKAQgSAxwAOgoJCgIILRIDHAA6
CpUBCgIEABIEIAA2ARqIASBEZXRhaWxzIG9mIHRoZSBBdXRvbm9tb3VzIERhdGFiYXNlIHZl
cnNpb24uCiBodHRwczovL2RvY3Mub3JhY2xlLmNvbS9lbi11cy9pYWFzL2FwaS8jL2VuL2Rh
dGFiYXNlLzIwMTYwOTE4L0F1dG9ub21vdXNEYlZlcnNpb25TdW1tYXJ5LwoKCgoDBAABEgMg
CBsKCwoDBAAHEgQhAiYECg0KBQQAB50IEgQhAiYECrYBCgQEAAIAEgMrAj0aqAEgSWRlbnRp
Zmllci4gVGhlIG5hbWUgb2YgdGhlIEF1dG9ub21vdXMgRGF0YWJhc2UgVmVyc2lvbiByZXNv
dXJjZSB3aXRoIHRoZQogZm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97
cmVnaW9ufS9hdXRvbm9tb3VzRGJWZXJzaW9ucy97YXV0b25vbW91c19kYl92ZXJzaW9ufQoK
DAoFBAACAAUSAysCCAoMCgUEAAIAARIDKwkNCgwKBQQAAgADEgMrEBEKDAoFBAACAAgSAysS
PAoPCggEAAIACJwIABIDKxM7Ck8KBAQAAgESAy4CQRpCIE91dHB1dCBvbmx5LiBBbiBPcmFj
bGUgRGF0YWJhc2UgdmVyc2lvbiBmb3IgQXV0b25vbW91cyBEYXRhYmFzZS4KCgwKBQQAAgEF
EgMuAggKDAoFBAACAQESAy4JEAoMCgUEAAIBAxIDLhMUCgwKBQQAAgEIEgMuFUAKDwoIBAAC
AQicCAASAy4WPwpCCgQEAAICEgMxAkkaNSBPdXRwdXQgb25seS4gVGhlIEF1dG9ub21vdXMg
RGF0YWJhc2Ugd29ya2xvYWQgdHlwZS4KCgwKBQQAAgIGEgMxAgwKDAoFBAACAgESAzENGAoM
CgUEAAICAxIDMRscCgwKBQQAAgIIEgMxHUgKDwoIBAACAgicCAASAzEeRwpsCgQEAAIDEgM1
AkYaXyBPdXRwdXQgb25seS4gQSBVUkwgdGhhdCBwb2ludHMgdG8gYSBkZXRhaWxlZCBkZXNj
cmlwdGlvbiBvZiB0aGUgQXV0b25vbW91cwogRGF0YWJhc2UgdmVyc2lvbi4KCgwKBQQAAgMF
EgM1AggKDAoFBAACAwESAzUJFQoMCgUEAAIDAxIDNRgZCgwKBQQAAgMIEgM1GkUKDwoIBAAC
AwicCAASAzUbRGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::AutonomousDbVersion::AutonomousDbVersion ===
    # Fields for AutonomousDbVersion
    # Field: name Type: 9 ()
    # Field: version Type: 9 ()
    # Field: db_workload Type: 14 (.google.cloud.oracledatabase.v1.DBWorkload)
    # Field: workload_uri Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::AutonomousDbVersion - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/autonomous_db_version.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::AutonomousDbVersion;

    my $msg = Google::Cloud::Oracledatabase::V1::AutonomousDbVersion::AutonomousDbVersion->new({
        name => $name,
        version => $version,
        db_workload => $db_workload,
        workload_uri => $workload_uri,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::AutonomousDbVersion::AutonomousDbVersion->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/autonomous_db_version.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::AutonomousDbVersion::AutonomousDbVersion

Details of the Autonomous Database version.
https://docs.oracle.com/en-us/iaas/api/#/en/database/20160918/AutonomousDbVersionSummary/

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the Autonomous Database Version resource with the
format:
projects/{project}/locations/{region}/autonomousDbVersions/{autonomous_db_version}

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

Output only. An Oracle Database version for Autonomous Database.

=item * C<< $msg->db_workload() >> / C<< $msg->db_workload($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::DBWorkload>)

Output only. The Autonomous Database workload type.

=item * C<< $msg->workload_uri() >> / C<< $msg->workload_uri($value) >>

Type: C<String>

Output only. A URL that points to a detailed description of the Autonomous
Database version.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::AutonomousDbVersion::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
