package Google::Cloud::Geminidataanalytics::V1alpha::Credentials;

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
Cjpnb29nbGUvY2xvdWQvZ2VtaW5pZGF0YWFuYWx5dGljcy92MWFscGhhL2NyZWRlbnRpYWxz
LnByb3RvEihnb29nbGUuY2xvdWQuZ2VtaW5pZGF0YWFuYWx5dGljcy52MWFscGhhGh9nb29n
bGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvImkKC0NyZWRlbnRpYWxzElIKBW9hdXRoGAEg
ASgLMjouZ29vZ2xlLmNsb3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjFhbHBoYS5PQXV0aENy
ZWRlbnRpYWxzSABSBW9hdXRoQgYKBGtpbmQi7AIKEE9BdXRoQ3JlZGVudGlhbHMSYAoGc2Vj
cmV0GAIgASgLMkYuZ29vZ2xlLmNsb3VkLmdlbWluaWRhdGFhbmFseXRpY3MudjFhbHBoYS5P
QXV0aENyZWRlbnRpYWxzLlNlY3JldEJhc2VkSABSBnNlY3JldBJdCgV0b2tlbhgDIAEoCzJF
Lmdvb2dsZS5jbG91ZC5nZW1pbmlkYXRhYW5hbHl0aWNzLnYxYWxwaGEuT0F1dGhDcmVkZW50
aWFscy5Ub2tlbkJhc2VkSABSBXRva2VuGlkKC1NlY3JldEJhc2VkEiAKCWNsaWVudF9pZBgC
IAEoCUID4EECUghjbGllbnRJZBIoCg1jbGllbnRfc2VjcmV0GAMgASgJQgPgQQJSDGNsaWVu
dFNlY3JldBo0CgpUb2tlbkJhc2VkEiYKDGFjY2Vzc190b2tlbhgBIAEoCUID4EECUgthY2Nl
c3NUb2tlbkIGCgRraW5kQqYCCixjb20uZ29vZ2xlLmNsb3VkLmdlbWluaWRhdGFhbmFseXRp
Y3MudjFhbHBoYUIQQ3JlZGVudGlhbHNQcm90b1ABWl5jbG91ZC5nb29nbGUuY29tL2dvL2dl
bWluaWRhdGFhbmFseXRpY3MvYXBpdjFhbHBoYS9nZW1pbmlkYXRhYW5hbHl0aWNzcGI7Z2Vt
aW5pZGF0YWFuYWx5dGljc3BiqgIoR29vZ2xlLkNsb3VkLkdlbWluaURhdGFBbmFseXRpY3Mu
VjFBbHBoYcoCKEdvb2dsZVxDbG91ZFxHZW1pbmlEYXRhQW5hbHl0aWNzXFYxYWxwaGHqAitH
b29nbGU6OkNsb3VkOjpHZW1pbmlEYXRhQW5hbHl0aWNzOjpWMWFscGhhSqoPCgYSBA4AQAEK
vAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5k
ZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5
b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhl
IExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAg
ICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNz
IHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBz
b2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQg
b24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05T
IE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNl
bnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFu
ZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQADEKCQoCAwASAxIA
KQoICgEIEgMUAEUKCQoCCCUSAxQARQoICgEIEgMVAHUKCQoCCAsSAxUAdQoICgEIEgMWACIK
CQoCCAoSAxYAIgoICgEIEgMXADEKCQoCCAgSAxcAMQoICgEIEgMYAEUKCQoCCAESAxgARQoI
CgEIEgMZAEUKCQoCCCkSAxkARQoICgEIEgMaAEQKCQoCCC0SAxoARApFCgIEABIEHQAjARo5
IFJlcHJlc2VudHMgZGlmZmVyZW50IGZvcm1zIG9mIGNyZWRlbnRpYWwgc3BlY2lmaWNhdGlv
bi4KCgoKAwQAARIDHQgTCigKBAQACAASBB8CIgMaGiBUaGUga2luZCBvZiBjcmVkZW50aWFs
cy4KCgwKBQQACAABEgMfCAwKIQoEBAACABIDIQQfGhQgT0F1dGggY3JlZGVudGlhbHMuCgoM
CgUEAAIABhIDIQQUCgwKBQQAAgABEgMhFRoKDAoFBAACAAMSAyEdHgorCgIEARIEJgBAARof
IFJlcHJlc2VudHMgT0F1dGggY3JlZGVudGlhbHMuCgoKCgMEAQESAyYIGApvCgQEAQMAEgQp
Ai8DGmEgVGhlIG5hbWUgb2YgdGhlIHNlY3JldCBjb250YWluaW5nIHRoZSBhY2Nlc3MgdG9r
ZW4uCiBSZXByZXNlbnRzIHNlY3JldC1iYXNlZCBPQXV0aCBjcmVkZW50aWFscy4KCgwKBQQB
AwABEgMpChUKLgoGBAEDAAIAEgMrBEIaHyBSZXF1aXJlZC4gQW4gT0F1dGggY2xpZW50IElE
LgoKDgoHBAEDAAIABRIDKwQKCg4KBwQBAwACAAESAysLFAoOCgcEAQMAAgADEgMrFxgKDgoH
BAEDAAIACBIDKxlBChEKCgQBAwACAAicCAASAysaQAoyCgYEAQMAAgESAy4ERhojIFJlcXVp
cmVkLiBBbiBPQXV0aCBjbGllbnQgc2VjcmV0LgoKDgoHBAEDAAIBBRIDLgQKCg4KBwQBAwAC
AQESAy4LGAoOCgcEAQMAAgEDEgMuGxwKDgoHBAEDAAIBCBIDLh1FChEKCgQBAwACAQicCAAS
Ay4eRAp9CgQEAQMBEgQzAjYDGm8gUmVhZCBtb3JlIGFib3V0IExvb2tlciBhY2Nlc3MgdG9r
ZW5zIGhlcmU6CiBodHRwczovL2RldmVsb3BlcnMubG9va2VyLmNvbS9hcGkvYWR2YW5jZWQt
dXNhZ2UvbG9va2VyLWFwaS1vYXV0aAoKDAoFBAEDAQESAzMKFApOCgYEAQMBAgASAzUERRo/
IFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgc2VjcmV0IGNvbnRhaW5pbmcgdGhlIGFjY2Vz
cyB0b2tlbi4KCg4KBwQBAwECAAUSAzUECgoOCgcEAQMBAgABEgM1CxcKDgoHBAEDAQIAAxID
NRobCg4KBwQBAwECAAgSAzUcRAoRCgoEAQMBAgAInAgAEgM1HUMKLgoEBAEIABIEOQI/Axog
IFRoZSBraW5kIG9mIE9BdXRoIGNyZWRlbnRpYWxzLgoKDAoFBAEIAAESAzkIDAouCgQEAQIA
EgM7BBsaISBTZWNyZXQtYmFzZWQgT0F1dGggY3JlZGVudGlhbHMuCgoMCgUEAQIABhIDOwQP
CgwKBQQBAgABEgM7EBYKDAoFBAECAAMSAzsZGgotCgQEAQIBEgM+BBkaICBUb2tlbi1iYXNl
ZCBPQXV0aCBjcmVkZW50aWFscy4KCgwKBQQBAgEGEgM+BA4KDAoFBAECAQESAz4PFAoMCgUE
AQIBAxIDPhcYYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Geminidataanalytics::V1alpha::Credentials::Credentials ===
    # Fields for Credentials
    # Field: oauth Type: 11 (.google.cloud.geminidataanalytics.v1alpha.OAuthCredentials)

# === Message: Google::Cloud::Geminidataanalytics::V1alpha::Credentials::OAuthCredentials ===
    # Fields for OAuthCredentials
    # Field: secret Type: 11 (.google.cloud.geminidataanalytics.v1alpha.OAuthCredentials.SecretBased)
    # Field: token Type: 11 (.google.cloud.geminidataanalytics.v1alpha.OAuthCredentials.TokenBased)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Geminidataanalytics::V1alpha::Credentials - Compiled Protocol Buffers messages for google/cloud/geminidataanalytics/v1alpha/credentials.proto

=head1 SYNOPSIS

    use Google::Cloud::Geminidataanalytics::V1alpha::Credentials;

    my $msg = Google::Cloud::Geminidataanalytics::V1alpha::Credentials::Credentials->new({
        oauth => $oauth,
    });

    # Read or update a field
    my $val = $msg->oauth();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Geminidataanalytics::V1alpha::Credentials::Credentials->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/geminidataanalytics/v1alpha/credentials.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Geminidataanalytics::V1alpha::Credentials::Credentials

Represents different forms of credential specification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->oauth() >> / C<< $msg->oauth($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1alpha::Credentials::OAuthCredentials>)

OAuth credentials.

=back

=head2 Google::Cloud::Geminidataanalytics::V1alpha::Credentials::OAuthCredentials

Represents OAuth credentials.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->secret() >> / C<< $msg->secret($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1alpha::Credentials::OAuthCredentials::SecretBased>)

Secret-based OAuth credentials.

=item * C<< $msg->token() >> / C<< $msg->token($value) >>

Type: C<Message> (L<Google::Cloud::Geminidataanalytics::V1alpha::Credentials::OAuthCredentials::TokenBased>)

Token-based OAuth credentials.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Geminidataanalytics::V1alpha::Credentials::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
