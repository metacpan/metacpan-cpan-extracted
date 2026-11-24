package Google::Cloud::Securitycenter::V2::OrgPolicy;

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
Ci9nb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvb3JnX3BvbGljeS5wcm90bxIeZ29v
Z2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvIuEBCglPcmdQb2xpY3kSFwoEbmFt
ZRgBIAEoCUID4EEIUgRuYW1lOroB6kG2AQofb3JncG9saWN5Lmdvb2dsZWFwaXMuY29tL1Bv
bGljeRI3b3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9wb2xpY2llcy97Y29uc3RyYWlu
dF9uYW1lfRIrZm9sZGVycy97Zm9sZGVyfS9wb2xpY2llcy97Y29uc3RyYWludF9uYW1lfRIt
cHJvamVjdHMve3Byb2plY3R9L3BvbGljaWVzL3tjb25zdHJhaW50X25hbWV9QugBCiJjb20u
Z29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyQg5PcmdQb2xpY3lQcm90b1ABWkpjbG91
ZC5nb29nbGUuY29tL2dvL3NlY3VyaXR5Y2VudGVyL2FwaXYyL3NlY3VyaXR5Y2VudGVycGI7
c2VjdXJpdHljZW50ZXJwYqoCHkdvb2dsZS5DbG91ZC5TZWN1cml0eUNlbnRlci5WMsoCHkdv
b2dsZVxDbG91ZFxTZWN1cml0eUNlbnRlclxWMuoCIUdvb2dsZTo6Q2xvdWQ6OlNlY3VyaXR5
Q2VudGVyOjpWMkrNCAoGEgQOACoBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAnCgkKAgMAEgMSACkKCQoCAwESAxMAIwoICgEIEgMVADsKCQoCCCUSAxUA
OwoICgEIEgMWAGEKCQoCCAsSAxYAYQoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYAC8K
CQoCCAgSAxgALwoICgEIEgMZADsKCQoCCAESAxkAOwoICgEIEgMaADsKCQoCCCkSAxoAOwoI
CgEIEgMbADoKCQoCCC0SAxsAOgpWCgIEABIEHgAqARpKIENvbnRhaW5zIGluZm9ybWF0aW9u
IGFib3V0IHRoZSBvcmcgcG9saWNpZXMgYXNzb2NpYXRlZCB3aXRoIHRoZSBmaW5kaW5nLgoK
CgoDBAABEgMeCBEKCwoDBAAHEgQfAiQECg0KBQQAB50IEgQfAiQECocBCgQEAAIAEgMpAj0a
eiBJZGVudGlmaWVyLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgb3JnIHBvbGljeS4KIEV4
YW1wbGU6CiAib3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9uX2lkfS9wb2xpY2llcy97Y29u
c3RyYWludF9uYW1lfSIKCgwKBQQAAgAFEgMpAggKDAoFBAACAAESAykJDQoMCgUEAAIAAxID
KRARCgwKBQQAAgAIEgMpEjwKDwoIBAACAAicCAASAykTO2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::OrgPolicy::OrgPolicy ===
    # Fields for OrgPolicy
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::OrgPolicy - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/org_policy.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::OrgPolicy;

    my $msg = Google::Cloud::Securitycenter::V2::OrgPolicy::OrgPolicy->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::OrgPolicy::OrgPolicy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/org_policy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::OrgPolicy::OrgPolicy

Contains information about the org policies associated with the finding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the org policy.
Example:
"organizations/{organization_id}/policies/{constraint_name}"

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::OrgPolicy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
