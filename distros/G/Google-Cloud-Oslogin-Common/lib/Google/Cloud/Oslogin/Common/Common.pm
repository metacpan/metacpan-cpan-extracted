package Google::Cloud::Oslogin::Common::Common;

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
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvb3Nsb2dpbi9jb21tb24vY29tbW9uLnByb3RvEhtnb29nbGUuY2xv
dWQub3Nsb2dpbi5jb21tb24aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdv
b2dsZS9hcGkvcmVzb3VyY2UucHJvdG8ixgMKDFBvc2l4QWNjb3VudBIYCgdwcmltYXJ5GAEg
ASgIUgdwcmltYXJ5EhoKCHVzZXJuYW1lGAIgASgJUgh1c2VybmFtZRIQCgN1aWQYAyABKANS
A3VpZBIQCgNnaWQYBCABKANSA2dpZBIlCg5ob21lX2RpcmVjdG9yeRgFIAEoCVINaG9tZURp
cmVjdG9yeRIUCgVzaGVsbBgGIAEoCVIFc2hlbGwSFAoFZ2Vjb3MYByABKAlSBWdlY29zEhsK
CXN5c3RlbV9pZBgIIAEoCVIIc3lzdGVtSWQSIgoKYWNjb3VudF9pZBgJIAEoCUID4EEDUglh
Y2NvdW50SWQSZAoVb3BlcmF0aW5nX3N5c3RlbV90eXBlGAogASgOMjAuZ29vZ2xlLmNsb3Vk
Lm9zbG9naW4uY29tbW9uLk9wZXJhdGluZ1N5c3RlbVR5cGVSE29wZXJhdGluZ1N5c3RlbVR5
cGUSFwoEbmFtZRgLIAEoCUID4EEDUgRuYW1lOknqQUYKI29zbG9naW4uZ29vZ2xlYXBpcy5j
b20vUG9zaXhBY2NvdW50Eh91c2Vycy97dXNlcn0vcHJvamVjdHMve3Byb2plY3R9IuYBCgxT
c2hQdWJsaWNLZXkSEAoDa2V5GAEgASgJUgNrZXkSMAoUZXhwaXJhdGlvbl90aW1lX3VzZWMY
AiABKANSEmV4cGlyYXRpb25UaW1lVXNlYxIlCgtmaW5nZXJwcmludBgDIAEoCUID4EEDUgtm
aW5nZXJwcmludBIXCgRuYW1lGAQgASgJQgPgQQNSBG5hbWU6UupBTwojb3Nsb2dpbi5nb29n
bGVhcGlzLmNvbS9Tc2hQdWJsaWNLZXkSKHVzZXJzL3t1c2VyfS9zc2hQdWJsaWNLZXlzL3tm
aW5nZXJwcmludH0qVAoTT3BlcmF0aW5nU3lzdGVtVHlwZRIlCiFPUEVSQVRJTkdfU1lTVEVN
X1RZUEVfVU5TUEVDSUZJRUQQABIJCgVMSU5VWBABEgsKB1dJTkRPV1MQAkLwAQofY29tLmdv
b2dsZS5jbG91ZC5vc2xvZ2luLmNvbW1vbkIMT3NMb2dpblByb3RvWjRjbG91ZC5nb29nbGUu
Y29tL2dvL29zbG9naW4vY29tbW9uL2NvbW1vbnBiO2NvbW1vbnBiqgIbR29vZ2xlLkNsb3Vk
Lk9zTG9naW4uQ29tbW9uygIbR29vZ2xlXENsb3VkXE9zTG9naW5cQ29tbW9u6gIeR29vZ2xl
OjpDbG91ZDo6T3NMb2dpbjo6Q29tbW9u6kErChtvc2xvZ2luLmdvb2dsZWFwaXMuY29tL1Vz
ZXISDHVzZXJzL3t1c2VyfUq2GAoGEgQOAGoBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
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
aWNlbnNlLgoKCAoBAhIDEAAkCgkKAgMAEgMSACkKCQoCAwESAxMAIwoICgEIEgMVADgKCQoC
CCUSAxUAOAoICgEIEgMWAEsKCQoCCAsSAxYASwoICgEIEgMXAC0KCQoCCAgSAxcALQoICgEI
EgMYADgKCQoCCAESAxgAOAoICgEIEgMZADgKCQoCCCkSAxkAOAoICgEIEgMaADcKCQoCCC0S
AxoANwoJCgEIEgQbAB4CCgwKBAidCAASBBsAHgIKPwoCBQASBCEAKwEaMyBUaGUgb3BlcmF0
aW5nIHN5c3RlbSBvcHRpb25zIGZvciBhY2NvdW50IGVudHJpZXMuCgoKCgMFAAESAyEFGApm
CgQFAAIAEgMkAigaWSBUaGUgb3BlcmF0aW5nIHN5c3RlbSB0eXBlIGFzc29jaWF0ZWQgd2l0
aCB0aGUgdXNlciBhY2NvdW50IGluZm9ybWF0aW9uIGlzCiB1bnNwZWNpZmllZC4KCgwKBQUA
AgABEgMkAiMKDAoFBQACAAISAyQmJwouCgQFAAIBEgMnAgwaISBMaW51eCB1c2VyIGFjY291
bnQgaW5mb3JtYXRpb24uCgoMCgUFAAIBARIDJwIHCgwKBQUAAgECEgMnCgsKMAoEBQACAhID
KgIOGiMgV2luZG93cyB1c2VyIGFjY291bnQgaW5mb3JtYXRpb24uCgoMCgUFAAICARIDKgIJ
CgwKBQUAAgICEgMqDA0KTQoCBAASBC4AVQEaQSBUaGUgUE9TSVggYWNjb3VudCBpbmZvcm1h
dGlvbiBhc3NvY2lhdGVkIHdpdGggYSBHb29nbGUgYWNjb3VudC4KCgoKAwQAARIDLggUCgsK
AwQABxIELwIyBAoNCgUEAAedCBIELwIyBAo/CgQEAAIAEgM1AhMaMiBPbmx5IG9uZSBQT1NJ
WCBhY2NvdW50IGNhbiBiZSBtYXJrZWQgYXMgcHJpbWFyeS4KCgwKBQQAAgAFEgM1AgYKDAoF
BAACAAESAzUHDgoMCgUEAAIAAxIDNRESCjEKBAQAAgESAzgCFhokIFRoZSB1c2VybmFtZSBv
ZiB0aGUgUE9TSVggYWNjb3VudC4KCgwKBQQAAgEFEgM4AggKDAoFBAACAQESAzgJEQoMCgUE
AAIBAxIDOBQVChsKBAQAAgISAzsCEBoOIFRoZSB1c2VyIElELgoKDAoFBAACAgUSAzsCBwoM
CgUEAAICARIDOwgLCgwKBQQAAgIDEgM7Dg8KJAoEBAACAxIDPgIQGhcgVGhlIGRlZmF1bHQg
Z3JvdXAgSUQuCgoMCgUEAAIDBRIDPgIHCgwKBQQAAgMBEgM+CAsKDAoFBAACAwMSAz4ODwo/
CgQEAAIEEgNBAhwaMiBUaGUgcGF0aCB0byB0aGUgaG9tZSBkaXJlY3RvcnkgZm9yIHRoaXMg
YWNjb3VudC4KCgwKBQQAAgQFEgNBAggKDAoFBAACBAESA0EJFwoMCgUEAAIEAxIDQRobCjwK
BAQAAgUSA0QCExovIFRoZSBwYXRoIHRvIHRoZSBsb2dpYyBzaGVsbCBmb3IgdGhpcyBhY2Nv
dW50LgoKDAoFBAACBQUSA0QCCAoMCgUEAAIFARIDRAkOCgwKBQQAAgUDEgNEERIKQwoEBAAC
BhIDRwITGjYgVGhlIEdFQ09TICh1c2VyIGluZm9ybWF0aW9uKSBlbnRyeSBmb3IgdGhpcyBh
Y2NvdW50LgoKDAoFBAACBgUSA0cCCAoMCgUEAAIGARIDRwkOCgwKBQQAAgYDEgNHERIKeAoE
BAACBxIDSwIXGmsgU3lzdGVtIGlkZW50aWZpZXIgZm9yIHdoaWNoIGFjY291bnQgdGhlIHVz
ZXJuYW1lIG9yIHVpZCBhcHBsaWVzIHRvLgogQnkgZGVmYXVsdCwgdGhlIGVtcHR5IHZhbHVl
IGlzIHVzZWQuCgoMCgUEAAIHBRIDSwIICgwKBQQAAgcBEgNLCRIKDAoFBAACBwMSA0sVFgo3
CgQEAAIIEgNOAkQaKiBPdXRwdXQgb25seS4gQSBQT1NJWCBhY2NvdW50IGlkZW50aWZpZXIu
CgoMCgUEAAIIBRIDTgIICgwKBQQAAggBEgNOCRMKDAoFBAACCAMSA04WFwoMCgUEAAIICBID
ThhDCg8KCAQAAggInAgAEgNOGUIKRAoEBAACCRIDUQIxGjcgVGhlIG9wZXJhdGluZyBzeXN0
ZW0gdHlwZSB3aGVyZSB0aGlzIGFjY291bnQgYXBwbGllcy4KCgwKBQQAAgkGEgNRAhUKDAoF
BAACCQESA1EWKwoMCgUEAAIJAxIDUS4wCjgKBAQAAgoSA1QCPxorIE91dHB1dCBvbmx5LiBU
aGUgY2Fub25pY2FsIHJlc291cmNlIG5hbWUuCgoMCgUEAAIKBRIDVAIICgwKBQQAAgoBEgNU
CQ0KDAoFBAACCgMSA1QQEgoMCgUEAAIKCBIDVBM+Cg8KCAQAAgoInAgAEgNUFD0KTgoCBAES
BFgAagEaQiBUaGUgU1NIIHB1YmxpYyBrZXkgaW5mb3JtYXRpb24gYXNzb2NpYXRlZCB3aXRo
IGEgR29vZ2xlIGFjY291bnQuCgoKCgMEAQESA1gIFAoLCgMEAQcSBFkCXAQKDQoFBAEHnQgS
BFkCXAQKdgoEBAECABIDYAIRGmkgUHVibGljIGtleSB0ZXh0IGluIFNTSCBmb3JtYXQsIGRl
ZmluZWQgYnkKIFtSRkM0MjUzXShodHRwczovL3d3dy5pZXRmLm9yZy9yZmMvcmZjNDI1My50
eHQpIHNlY3Rpb24gNi42LgoKDAoFBAECAAUSA2ACCAoMCgUEAQIAARIDYAkMCgwKBQQBAgAD
EgNgDxAKPgoEBAECARIDYwIhGjEgQW4gZXhwaXJhdGlvbiB0aW1lIGluIG1pY3Jvc2Vjb25k
cyBzaW5jZSBlcG9jaC4KCgwKBQQBAgEFEgNjAgcKDAoFBAECAQESA2MIHAoMCgUEAQIBAxID
Yx8gCkoKBAQBAgISA2YCRRo9IE91dHB1dCBvbmx5LiBUaGUgU0hBLTI1NiBmaW5nZXJwcmlu
dCBvZiB0aGUgU1NIIHB1YmxpYyBrZXkuCgoMCgUEAQICBRIDZgIICgwKBQQBAgIBEgNmCRQK
DAoFBAECAgMSA2YXGAoMCgUEAQICCBIDZhlECg8KCAQBAgIInAgAEgNmGkMKOAoEBAECAxID
aQI+GisgT3V0cHV0IG9ubHkuIFRoZSBjYW5vbmljYWwgcmVzb3VyY2UgbmFtZS4KCgwKBQQB
AgMFEgNpAggKDAoFBAECAwESA2kJDQoMCgUEAQIDAxIDaRARCgwKBQQBAgMIEgNpEj0KDwoI
BAECAwicCAASA2kTPGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oslogin::Common::Common::PosixAccount ===
    # Fields for PosixAccount
    # Field: primary Type: 8 ()
    # Field: username Type: 9 ()
    # Field: uid Type: 3 ()
    # Field: gid Type: 3 ()
    # Field: home_directory Type: 9 ()
    # Field: shell Type: 9 ()
    # Field: gecos Type: 9 ()
    # Field: system_id Type: 9 ()
    # Field: account_id Type: 9 ()
    # Field: operating_system_type Type: 14 (.google.cloud.oslogin.common.OperatingSystemType)
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Oslogin::Common::Common::SshPublicKey ===
    # Fields for SshPublicKey
    # Field: key Type: 9 ()
    # Field: expiration_time_usec Type: 3 ()
    # Field: fingerprint Type: 9 ()
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oslogin::Common::Common - Compiled Protocol Buffers messages for google/cloud/oslogin/common/common.proto

=head1 SYNOPSIS

    use Google::Cloud::Oslogin::Common::Common;

    my $msg = Google::Cloud::Oslogin::Common::Common::PosixAccount->new({
        primary => $primary,
        username => $username,
        uid => $uid,
        gid => $gid,
    });

    # Read or update a field
    my $val = $msg->primary();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oslogin::Common::Common::PosixAccount->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oslogin/common/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oslogin::Common::Common::PosixAccount

The POSIX account information associated with a Google account.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->primary() >> / C<< $msg->primary($value) >>

Type: C<Bool>

Only one POSIX account can be marked as primary.

=item * C<< $msg->username() >> / C<< $msg->username($value) >>

Type: C<String>

The username of the POSIX account.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<Int64>

The user ID.

=item * C<< $msg->gid() >> / C<< $msg->gid($value) >>

Type: C<Int64>

The default group ID.

=item * C<< $msg->home_directory() >> / C<< $msg->home_directory($value) >>

Type: C<String>

The path to the home directory for this account.

=item * C<< $msg->shell() >> / C<< $msg->shell($value) >>

Type: C<String>

The path to the logic shell for this account.

=item * C<< $msg->gecos() >> / C<< $msg->gecos($value) >>

Type: C<String>

The GECOS (user information) entry for this account.

=item * C<< $msg->system_id() >> / C<< $msg->system_id($value) >>

Type: C<String>

System identifier for which account the username or uid applies to.
By default, the empty value is used.

=item * C<< $msg->account_id() >> / C<< $msg->account_id($value) >>

Type: C<String>

Output only. A POSIX account identifier.

=item * C<< $msg->operating_system_type() >> / C<< $msg->operating_system_type($value) >>

Type: C<Enum> (L<Google::Cloud::Oslogin::Common::OperatingSystemType>)

The operating system type where this account applies.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The canonical resource name.

=back

=head2 Google::Cloud::Oslogin::Common::Common::SshPublicKey

The SSH public key information associated with a Google account.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<String>

Public key text in SSH format, defined by
[RFC4253](https://www.ietf.org/rfc/rfc4253.txt) section 6.6.

=item * C<< $msg->expiration_time_usec() >> / C<< $msg->expiration_time_usec($value) >>

Type: C<Int64>

An expiration time in microseconds since epoch.

=item * C<< $msg->fingerprint() >> / C<< $msg->fingerprint($value) >>

Type: C<String>

Output only. The SHA-256 fingerprint of the SSH public key.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The canonical resource name.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oslogin::Common::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
