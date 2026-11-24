package Google::Cloud::Channel::V1::BillingAccounts;

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
Ci5nb29nbGUvY2xvdWQvY2hhbm5lbC92MS9iaWxsaW5nX2FjY291bnRzLnByb3RvEhdnb29n
bGUuY2xvdWQuY2hhbm5lbC52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZ
Z29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5w
cm90byLFAgoOQmlsbGluZ0FjY291bnQSFwoEbmFtZRgBIAEoCUID4EEDUgRuYW1lEiEKDGRp
c3BsYXlfbmFtZRgCIAEoCVILZGlzcGxheU5hbWUSQAoLY3JlYXRlX3RpbWUYAyABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSKAoNY3VycmVuY3lf
Y29kZRgEIAEoCUID4EEDUgxjdXJyZW5jeUNvZGUSJAoLcmVnaW9uX2NvZGUYBSABKAlCA+BB
A1IKcmVnaW9uQ29kZTpl6kFiCipjbG91ZGNoYW5uZWwuZ29vZ2xlYXBpcy5jb20vQmlsbGlu
Z0FjY291bnQSNGFjY291bnRzL3thY2NvdW50fS9iaWxsaW5nQWNjb3VudHMve2JpbGxpbmdf
YWNjb3VudH1CbAobY29tLmdvb2dsZS5jbG91ZC5jaGFubmVsLnYxQhRCaWxsaW5nQWNjb3Vu
dHNQcm90b1ABWjVjbG91ZC5nb29nbGUuY29tL2dvL2NoYW5uZWwvYXBpdjEvY2hhbm5lbHBi
O2NoYW5uZWxwYkr1CwoGEgQOADIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29v
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
LgoKCAoBAhIDEAAgCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAApCggKAQgSAxYA
TAoJCgIICxIDFgBMCggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgANQoJCgIICBIDGAA1
CggKAQgSAxkANAoJCgIIARIDGQA0CisKAgQAEgQcADIBGh8gUmVwcmVzZW50cyBhIGJpbGxp
bmcgYWNjb3VudC4KCgoKAwQAARIDHAgWCgsKAwQABxIEHQIgBAoNCgUEAAedCBIEHQIgBAqG
AQoEBAACABIDJAI+GnkgT3V0cHV0IG9ubHkuIFJlc291cmNlIG5hbWUgb2YgdGhlIGJpbGxp
bmcgYWNjb3VudC4KIEZvcm1hdDogYWNjb3VudHMve2FjY291bnRfaWR9L2JpbGxpbmdBY2Nv
dW50cy97YmlsbGluZ19hY2NvdW50X2lkfS4KCgwKBQQAAgAFEgMkAggKDAoFBAACAAESAyQJ
DQoMCgUEAAIAAxIDJBARCgwKBQQAAgAIEgMkEj0KDwoIBAACAAicCAASAyQTPAozCgQEAAIB
EgMnAhoaJiBEaXNwbGF5IG5hbWUgb2YgdGhlIGJpbGxpbmcgYWNjb3VudC4KCgwKBQQAAgEF
EgMnAggKDAoFBAACAQESAycJFQoMCgUEAAIBAxIDJxgZCkwKBAQAAgISBCoCKzIaPiBPdXRw
dXQgb25seS4gVGhlIHRpbWUgd2hlbiB0aGlzIGJpbGxpbmcgYWNjb3VudCB3YXMgY3JlYXRl
ZC4KCgwKBQQAAgIGEgMqAhsKDAoFBAACAgESAyocJwoMCgUEAAICAxIDKiorCgwKBQQAAgII
EgMrBjEKDwoIBAACAgicCAASAysHMApLCgQEAAIDEgMuAkcaPiBPdXRwdXQgb25seS4gVGhl
IDMtbGV0dGVyIGN1cnJlbmN5IGNvZGUgZGVmaW5lZCBpbiBJU08gNDIxNy4KCgwKBQQAAgMF
EgMuAggKDAoFBAACAwESAy4JFgoMCgUEAAIDAxIDLhkaCgwKBQQAAgMIEgMuG0YKDwoIBAAC
AwicCAASAy4cRQoxCgQEAAIEEgMxAkUaJCBPdXRwdXQgb25seS4gVGhlIENMRFIgcmVnaW9u
IGNvZGUuCgoMCgUEAAIEBRIDMQIICgwKBQQAAgQBEgMxCRQKDAoFBAACBAMSAzEXGAoMCgUE
AAIECBIDMRlECg8KCAQAAgQInAgAEgMxGkNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Channel::V1::BillingAccounts::BillingAccount ===
    # Fields for BillingAccount
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: currency_code Type: 9 ()
    # Field: region_code Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Channel::V1::BillingAccounts - Compiled Protocol Buffers messages for google/cloud/channel/v1/billing_accounts.proto

=head1 SYNOPSIS

    use Google::Cloud::Channel::V1::BillingAccounts;

    my $msg = Google::Cloud::Channel::V1::BillingAccounts::BillingAccount->new({
        name => $name,
        display_name => $display_name,
        create_time => $create_time,
        currency_code => $currency_code,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Channel::V1::BillingAccounts::BillingAccount->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/channel/v1/billing_accounts.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Channel::V1::BillingAccounts::BillingAccount

Represents a billing account.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Resource name of the billing account.
Format: accounts/{account_id}/billingAccounts/{billing_account_id}.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Display name of the billing account.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when this billing account was created.

=item * C<< $msg->currency_code() >> / C<< $msg->currency_code($value) >>

Type: C<String>

Output only. The 3-letter currency code defined in ISO 4217.

=item * C<< $msg->region_code() >> / C<< $msg->region_code($value) >>

Type: C<String>

Output only. The CLDR region code.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Channel::V1::BillingAccounts::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
