package Google::Appengine::V1::Firewall;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CiJnb29nbGUvYXBwZW5naW5lL3YxL2ZpcmV3YWxsLnByb3RvEhNnb29nbGUuYXBwZW5naW5l
LnYxIugBCgxGaXJld2FsbFJ1bGUSGgoIcHJpb3JpdHkYASABKAVSCHByaW9yaXR5EkAKBmFj
dGlvbhgCIAEoDjIoLmdvb2dsZS5hcHBlbmdpbmUudjEuRmlyZXdhbGxSdWxlLkFjdGlvblIG
YWN0aW9uEiEKDHNvdXJjZV9yYW5nZRgDIAEoCVILc291cmNlUmFuZ2USIAoLZGVzY3JpcHRp
b24YBCABKAlSC2Rlc2NyaXB0aW9uIjUKBkFjdGlvbhIWChJVTlNQRUNJRklFRF9BQ1RJT04Q
ABIJCgVBTExPVxABEggKBERFTlkQAkLHAQogY29tLmdvb2dsZS5hcHBlbmdpbmUudjEuZmly
ZXdhbGxCDUZpcmV3YWxsUHJvdG9QAVo7Y2xvdWQuZ29vZ2xlLmNvbS9nby9hcHBlbmdpbmUv
YXBpdjEvYXBwZW5naW5lcGI7YXBwZW5naW5lcGKqAhlHb29nbGUuQ2xvdWQuQXBwRW5naW5l
LlYxygIZR29vZ2xlXENsb3VkXEFwcEVuZ2luZVxWMeoCHEdvb2dsZTo6Q2xvdWQ6OkFwcEVu
Z2luZTo6VjFK/RIKBhIEDgBDAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2ds
ZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4w
ICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGlu
IGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBv
ZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMv
TElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdy
ZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGlj
ZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJS
QU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGlt
cGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zl
cm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4K
CggKAQISAxAAHAoICgEIEgMSADYKCQoCCCUSAxIANgoICgEIEgMTAFIKCQoCCAsSAxMAUgoI
CgEIEgMUACIKCQoCCAoSAxQAIgoICgEIEgMVAC4KCQoCCAgSAxUALgoICgEIEgMWADkKCQoC
CAESAxYAOQoICgEIEgMXADYKCQoCCCkSAxcANgoICgEIEgMYADUKCQoCCC0SAxgANQqEAQoC
BAASBBwAQwEaeCBBIHNpbmdsZSBmaXJld2FsbCBydWxlIHRoYXQgaXMgZXZhbHVhdGVkIGFn
YWluc3QgaW5jb21pbmcgdHJhZmZpYwogYW5kIHByb3ZpZGVzIGFuIGFjdGlvbiB0byB0YWtl
IG9uIG1hdGNoZWQgcmVxdWVzdHMuCgoKCgMEAAESAxwIFAo/CgQEAAQAEgQeAiYDGjEgQXZh
aWxhYmxlIGFjdGlvbnMgdG8gdGFrZSBvbiBtYXRjaGluZyByZXF1ZXN0cy4KCgwKBQQABAAB
EgMeBw0KDQoGBAAEAAIAEgMfBBsKDgoHBAAEAAIAARIDHwQWCg4KBwQABAACAAISAx8ZGgov
CgYEAAQAAgESAyIEDhogIE1hdGNoaW5nIHJlcXVlc3RzIGFyZSBhbGxvd2VkLgoKDgoHBAAE
AAIBARIDIgQJCg4KBwQABAACAQISAyIMDQouCgYEAAQAAgISAyUEDRofIE1hdGNoaW5nIHJl
cXVlc3RzIGFyZSBkZW5pZWQuCgoOCgcEAAQAAgIBEgMlBAgKDgoHBAAEAAICAhIDJQsMCskC
CgQEAAIAEgMuAhUauwIgQSBwb3NpdGl2ZSBpbnRlZ2VyIGJldHdlZW4gWzEsIEludDMyLk1h
eFZhbHVlLTFdIHRoYXQgZGVmaW5lcyB0aGUgb3JkZXIgb2YKIHJ1bGUgZXZhbHVhdGlvbi4g
UnVsZXMgd2l0aCB0aGUgbG93ZXN0IHByaW9yaXR5IGFyZSBldmFsdWF0ZWQgZmlyc3QuCgog
QSBkZWZhdWx0IHJ1bGUgYXQgcHJpb3JpdHkgSW50MzIuTWF4VmFsdWUgbWF0Y2hlcyBhbGwg
SVB2NCBhbmQgSVB2NiB0cmFmZmljCiB3aGVuIG5vIHByZXZpb3VzIHJ1bGUgbWF0Y2hlcy4g
T25seSB0aGUgYWN0aW9uIG9mIHRoaXMgcnVsZSBjYW4gYmUgbW9kaWZpZWQKIGJ5IHRoZSB1
c2VyLgoKDAoFBAACAAUSAy4CBwoMCgUEAAIAARIDLggQCgwKBQQAAgADEgMuExQKNgoEBAAC
ARIDMQIUGikgVGhlIGFjdGlvbiB0byB0YWtlIG9uIG1hdGNoZWQgcmVxdWVzdHMuCgoMCgUE
AAIBBhIDMQIICgwKBQQAAgEBEgMxCQ8KDAoFBAACAQMSAzESEwrHBAoEBAACAhIDPgIaGrkE
IElQIGFkZHJlc3Mgb3IgcmFuZ2UsIGRlZmluZWQgdXNpbmcgQ0lEUiBub3RhdGlvbiwgb2Yg
cmVxdWVzdHMgdGhhdCB0aGlzCiBydWxlIGFwcGxpZXMgdG8uIFlvdSBjYW4gdXNlIHRoZSB3
aWxkY2FyZCBjaGFyYWN0ZXIgIioiIHRvIG1hdGNoIGFsbCBJUHMKIGVxdWl2YWxlbnQgdG8g
IjAvMCIgYW5kICI6Oi8wIiB0b2dldGhlci4KIEV4YW1wbGVzOiBgMTkyLjE2OC4xLjFgIG9y
IGAxOTIuMTY4LjAuMC8xNmAgb3IgYDIwMDE6ZGI4OjovMzJgCiAgICAgICAgICAgb3IgYDIw
MDE6MGRiODowMDAwOjAwNDI6MDAwMDo4YTJlOjAzNzA6NzMzNGAuCgoKIDxwPlRydW5jYXRp
b24gd2lsbCBiZSBzaWxlbnRseSBwZXJmb3JtZWQgb24gYWRkcmVzc2VzIHdoaWNoIGFyZSBu
b3QKIHByb3Blcmx5IHRydW5jYXRlZC4gRm9yIGV4YW1wbGUsIGAxLjIuMy40LzI0YCBpcyBh
Y2NlcHRlZCBhcyB0aGUgc2FtZQogYWRkcmVzcyBhcyBgMS4yLjMuMC8yNGAuIFNpbWlsYXJs
eSwgZm9yIElQdjYsIGAyMDAxOmRiODo6MS8zMmAgaXMgYWNjZXB0ZWQKIGFzIHRoZSBzYW1l
IGFkZHJlc3MgYXMgYDIwMDE6ZGI4OjovMzJgLgoKDAoFBAACAgUSAz4CCAoMCgUEAAICARID
PgkVCgwKBQQAAgIDEgM+GBkKbwoEBAACAxIDQgIZGmIgQW4gb3B0aW9uYWwgc3RyaW5nIGRl
c2NyaXB0aW9uIG9mIHRoaXMgcnVsZS4KIFRoaXMgZmllbGQgaGFzIGEgbWF4aW11bSBsZW5n
dGggb2YgMTAwIGNoYXJhY3RlcnMuCgoMCgUEAAIDBRIDQgIICgwKBQQAAgMBEgNCCRQKDAoF
BAACAwMSA0IXGGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1::Firewall::FirewallRule ===
    # Fields for FirewallRule
    # Field: priority Type: 5 ()
    # Field: action Type: 14 (.google.appengine.v1.FirewallRule.Action)
    # Field: source_range Type: 9 ()
    # Field: description Type: 9 ()

# Enum: FirewallRule::Action
our $FirewallRule_UNSPECIFIED_ACTION = 0;
our $FirewallRule_ALLOW = 1;
our $FirewallRule_DENY = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Appengine::V1::Firewall - Compiled Protocol Buffers messages for google/appengine/v1/firewall.proto

=head1 SYNOPSIS

    use Google::Appengine::V1::Firewall;

    my $msg = Google::Appengine::V1::Firewall::FirewallRule->new({
        priority => $priority,
        action => $action,
        source_range => $source_range,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->priority();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1::Firewall::FirewallRule->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1/firewall.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1::Firewall::FirewallRule

A single firewall rule that is evaluated against incoming traffic
and provides an action to take on matched requests.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->priority() >> / C<< $msg->priority($value) >>

Type: C<Int32>

A positive integer between [1, Int32.MaxValue-1] that defines the order of
rule evaluation. Rules with the lowest priority are evaluated first.

A default rule at priority Int32.MaxValue matches all IPv4 and IPv6 traffic
when no previous rule matches. Only the action of this rule can be modified
by the user.

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<Enum> (L<Google::Appengine::V1::FirewallRule::Action>)

The action to take on matched requests.

=item * C<< $msg->source_range() >> / C<< $msg->source_range($value) >>

Type: C<String>

IP address or range, defined using CIDR notation, of requests that this
rule applies to. You can use the wildcard character "*" to match all IPs
equivalent to "0/0" and "::/0" together.
Examples: `192.168.1.1` or `192.168.0.0/16` or `2001:db8::/32`
          or `2001:0db8:0000:0042:0000:8a2e:0370:7334`.


<p>Truncation will be silently performed on addresses which are not
properly truncated. For example, `1.2.3.4/24` is accepted as the same
address as `1.2.3.0/24`. Similarly, for IPv6, `2001:db8::1/32` is accepted
as the same address as `2001:db8::/32`.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

An optional string description of this rule.
This field has a maximum length of 100 characters.

=back

=head3 Enum: FirewallRule::Action

=over 4

=item * C<UNSPECIFIED_ACTION> => C<0>

=item * C<ALLOW> => C<1>

=item * C<DENY> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1::Firewall::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
