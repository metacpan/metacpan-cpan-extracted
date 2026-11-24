package Google::Cloud::Securitycenter::V1::OrgPolicy;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvb3JnX3BvbGljeS5wcm90bxIeZ29v
Z2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3Rv
ItwBCglPcmdQb2xpY3kSEgoEbmFtZRgBIAEoCVIEbmFtZTq6AepBtgEKH29yZ3BvbGljeS5n
b29nbGVhcGlzLmNvbS9Qb2xpY3kSN29yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vcG9s
aWNpZXMve2NvbnN0cmFpbnRfbmFtZX0SK2ZvbGRlcnMve2ZvbGRlcn0vcG9saWNpZXMve2Nv
bnN0cmFpbnRfbmFtZX0SLXByb2plY3RzL3twcm9qZWN0fS9wb2xpY2llcy97Y29uc3RyYWlu
dF9uYW1lfULoAQoiY29tLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MUIOT3JnUG9s
aWN5UHJvdG9QAVpKY2xvdWQuZ29vZ2xlLmNvbS9nby9zZWN1cml0eWNlbnRlci9hcGl2MS9z
ZWN1cml0eWNlbnRlcnBiO3NlY3VyaXR5Y2VudGVycGKqAh5Hb29nbGUuQ2xvdWQuU2VjdXJp
dHlDZW50ZXIuVjHKAh5Hb29nbGVcQ2xvdWRcU2VjdXJpdHlDZW50ZXJcVjHqAiFHb29nbGU6
OkNsb3VkOjpTZWN1cml0eUNlbnRlcjo6VjFKlggKBhIEDgApAQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgAjCggKAQgSAxQAOwoJCgII
JRIDFAA7CggKAQgSAxUAYQoJCgIICxIDFQBhCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgS
AxcALwoJCgIICBIDFwAvCggKAQgSAxgAOwoJCgIIARIDGAA7CggKAQgSAxkAOwoJCgIIKRID
GQA7CggKAQgSAxoAOgoJCgIILRIDGgA6ClYKAgQAEgQdACkBGkogQ29udGFpbnMgaW5mb3Jt
YXRpb24gYWJvdXQgdGhlIG9yZyBwb2xpY2llcyBhc3NvY2lhdGVkIHdpdGggdGhlIGZpbmRp
bmcuCgoKCgMEAAESAx0IEQoLCgMEAAcSBB4CIwQKDQoFBAAHnQgSBB4CIwQKewoEBAACABID
KAISGm4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIG9yZyBwb2xpY3kuCiBFeGFtcGxlOgog
Im9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbl9pZH0vcG9saWNpZXMve2NvbnN0cmFpbnRf
bmFtZX0iCgoMCgUEAAIABRIDKAIICgwKBQQAAgABEgMoCQ0KDAoFBAACAAMSAygQEWIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::OrgPolicy::OrgPolicy ===
    # Fields for OrgPolicy
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::OrgPolicy - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/org_policy.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::OrgPolicy;

    my $msg = Google::Cloud::Securitycenter::V1::OrgPolicy::OrgPolicy->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::OrgPolicy::OrgPolicy->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/org_policy.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::OrgPolicy::OrgPolicy

Contains information about the org policies associated with the finding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the org policy.
Example:
"organizations/{organization_id}/policies/{constraint_name}"

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::OrgPolicy::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
