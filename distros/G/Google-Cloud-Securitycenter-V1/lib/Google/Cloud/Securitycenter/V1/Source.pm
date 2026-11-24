package Google::Cloud::Securitycenter::V1::Source;

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
Citnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvc291cmNlLnByb3RvEh5nb29nbGUu
Y2xvdWQuc2VjdXJpdHljZW50ZXIudjEaGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8irAIK
BlNvdXJjZRISCgRuYW1lGAEgASgJUgRuYW1lEiEKDGRpc3BsYXlfbmFtZRgCIAEoCVILZGlz
cGxheU5hbWUSIAoLZGVzY3JpcHRpb24YAyABKAlSC2Rlc2NyaXB0aW9uEiUKDmNhbm9uaWNh
bF9uYW1lGA4gASgJUg1jYW5vbmljYWxOYW1lOqEB6kGdAQokc2VjdXJpdHljZW50ZXIuZ29v
Z2xlYXBpcy5jb20vU291cmNlEi1vcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb259L3NvdXJj
ZXMve3NvdXJjZX0SIWZvbGRlcnMve2ZvbGRlcn0vc291cmNlcy97c291cmNlfRIjcHJvamVj
dHMve3Byb2plY3R9L3NvdXJjZXMve3NvdXJjZX1C2AEKImNvbS5nb29nbGUuY2xvdWQuc2Vj
dXJpdHljZW50ZXIudjFQAVpKY2xvdWQuZ29vZ2xlLmNvbS9nby9zZWN1cml0eWNlbnRlci9h
cGl2MS9zZWN1cml0eWNlbnRlcnBiO3NlY3VyaXR5Y2VudGVycGKqAh5Hb29nbGUuQ2xvdWQu
U2VjdXJpdHlDZW50ZXIuVjHKAh5Hb29nbGVcQ2xvdWRcU2VjdXJpdHlDZW50ZXJcVjHqAiFH
b29nbGU6OkNsb3VkOjpTZWN1cml0eUNlbnRlcjo6VjFKqRIKBhIEDgBEAQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgAjCggKAQgSAxQA
OwoJCgIIJRIDFAA7CggKAQgSAxUAYQoJCgIICxIDFQBhCggKAQgSAxYAIgoJCgIIChIDFgAi
CggKAQgSAxcAOwoJCgIIARIDFwA7CggKAQgSAxgAOwoJCgIIKRIDGAA7CggKAQgSAxkAOgoJ
CgIILRIDGQA6Cu4BCgIEABIEHwBEARrhASBTZWN1cml0eSBDb21tYW5kIENlbnRlciBmaW5k
aW5nIHNvdXJjZS4gQSBmaW5kaW5nIHNvdXJjZQogaXMgYW4gZW50aXR5IG9yIGEgbWVjaGFu
aXNtIHRoYXQgY2FuIHByb2R1Y2UgYSBmaW5kaW5nLiBBIHNvdXJjZSBpcyBsaWtlIGEKIGNv
bnRhaW5lciBvZiBmaW5kaW5ncyB0aGF0IGNvbWUgZnJvbSB0aGUgc2FtZSBzY2FubmVyLCBs
b2dnZXIsIG1vbml0b3IsIGFuZAogb3RoZXIgdG9vbHMuCgoKCgMEAAESAx8IDgoLCgMEAAcS
BCACJQQKDQoFBAAHnQgSBCACJQQKzAEKBAQAAgASAysCEhq+ASBUaGUgcmVsYXRpdmUgcmVz
b3VyY2UgbmFtZSBvZiB0aGlzIHNvdXJjZS4gU2VlOgogaHR0cHM6Ly9jbG91ZC5nb29nbGUu
Y29tL2FwaXMvZGVzaWduL3Jlc291cmNlX25hbWVzI3JlbGF0aXZlX3Jlc291cmNlX25hbWUK
IEV4YW1wbGU6CiAib3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9uX2lkfS9zb3VyY2VzL3tz
b3VyY2VfaWR9IgoKDAoFBAACAAUSAysCCAoMCgUEAAIAARIDKwkNCgwKBQQAAgADEgMrEBEK
iQIKBAQAAgESAzICGhr7ASBUaGUgc291cmNlJ3MgZGlzcGxheSBuYW1lLgogQSBzb3VyY2Un
cyBkaXNwbGF5IG5hbWUgbXVzdCBiZSB1bmlxdWUgYW1vbmdzdCBpdHMgc2libGluZ3MsIGZv
ciBleGFtcGxlLAogdHdvIHNvdXJjZXMgd2l0aCB0aGUgc2FtZSBwYXJlbnQgY2FuJ3Qgc2hh
cmUgdGhlIHNhbWUgZGlzcGxheSBuYW1lLgogVGhlIGRpc3BsYXkgbmFtZSBtdXN0IGhhdmUg
YSBsZW5ndGggYmV0d2VlbiAxIGFuZCA2NCBjaGFyYWN0ZXJzCiAoaW5jbHVzaXZlKS4KCgwK
BQQAAgEFEgMyAggKDAoFBAACAQESAzIJFQoMCgUEAAIBAxIDMhgZCvoCCgQEAAICEgM7Ahka
7AIgVGhlIGRlc2NyaXB0aW9uIG9mIHRoZSBzb3VyY2UgKG1heCBvZiAxMDI0IGNoYXJhY3Rl
cnMpLgogRXhhbXBsZToKICJXZWIgU2VjdXJpdHkgU2Nhbm5lciBpcyBhIHdlYiBzZWN1cml0
eSBzY2FubmVyIGZvciBjb21tb24KIHZ1bG5lcmFiaWxpdGllcyBpbiBBcHAgRW5naW5lIGFw
cGxpY2F0aW9ucy4gSXQgY2FuIGF1dG9tYXRpY2FsbHkKIHNjYW4gYW5kIGRldGVjdCBmb3Vy
IGNvbW1vbiB2dWxuZXJhYmlsaXRpZXMsIGluY2x1ZGluZyBjcm9zcy1zaXRlLXNjcmlwdGlu
ZwogKFhTUyksIEZsYXNoIGluamVjdGlvbiwgbWl4ZWQgY29udGVudCAoSFRUUCBpbiBIVFRQ
UyksIGFuZAogb3V0ZGF0ZWQgb3IgaW5zZWN1cmUgbGlicmFyaWVzLiIKCgwKBQQAAgIFEgM7
AggKDAoFBAACAgESAzsJFAoMCgUEAAICAxIDOxcYCrMCCgQEAAIDEgNDAh0apQIgVGhlIGNh
bm9uaWNhbCBuYW1lIG9mIHRoZSBmaW5kaW5nIHNvdXJjZS4gSXQncyBlaXRoZXIKICJvcmdh
bml6YXRpb25zL3tvcmdhbml6YXRpb25faWR9L3NvdXJjZXMve3NvdXJjZV9pZH0iLAogImZv
bGRlcnMve2ZvbGRlcl9pZH0vc291cmNlcy97c291cmNlX2lkfSIsIG9yCiAicHJvamVjdHMv
e3Byb2plY3RfbnVtYmVyfS9zb3VyY2VzL3tzb3VyY2VfaWR9IiwKIGRlcGVuZGluZyBvbiB0
aGUgY2xvc2VzdCBDUk0gYW5jZXN0b3Igb2YgdGhlIHJlc291cmNlIGFzc29jaWF0ZWQgd2l0
aCB0aGUKIGZpbmRpbmcuCgoMCgUEAAIDBRIDQwIICgwKBQQAAgMBEgNDCRcKDAoFBAACAwMS
A0MaHGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::Source::Source ===
    # Fields for Source
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: canonical_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::Source - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/source.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::Source;

    my $msg = Google::Cloud::Securitycenter::V1::Source::Source->new({
        name => $name,
        display_name => $display_name,
        description => $description,
        canonical_name => $canonical_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::Source::Source->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/source.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::Source::Source

Security Command Center finding source. A finding source
is an entity or a mechanism that can produce a finding. A source is like a
container of findings that come from the same scanner, logger, monitor, and
other tools.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The relative resource name of this source. See:
https://cloud.google.com/apis/design/resource_names#relative_resource_name
Example:
"organizations/{organization_id}/sources/{source_id}"

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The source's display name.
A source's display name must be unique amongst its siblings, for example,
two sources with the same parent can't share the same display name.
The display name must have a length between 1 and 64 characters
(inclusive).

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

The description of the source (max of 1024 characters).
Example:
"Web Security Scanner is a web security scanner for common
vulnerabilities in App Engine applications. It can automatically
scan and detect four common vulnerabilities, including cross-site-scripting
(XSS), Flash injection, mixed content (HTTP in HTTPS), and
outdated or insecure libraries."

=item * C<< $msg->canonical_name() >> / C<< $msg->canonical_name($value) >>

Type: C<String>

The canonical name of the finding source. It's either
"organizations/{organization_id}/sources/{source_id}",
"folders/{folder_id}/sources/{source_id}", or
"projects/{project_number}/sources/{source_id}",
depending on the closest CRM ancestor of the resource associated with the
finding.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::Source::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
