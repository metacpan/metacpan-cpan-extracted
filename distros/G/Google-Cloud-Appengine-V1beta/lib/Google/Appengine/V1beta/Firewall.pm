package Google::Appengine::V1beta::Firewall;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvYXBwZW5naW5lL3YxYmV0YS9maXJld2FsbC5wcm90bxIXZ29vZ2xlLmFwcGVu
Z2luZS52MWJldGEi7AEKDEZpcmV3YWxsUnVsZRIaCghwcmlvcml0eRgBIAEoBVIIcHJpb3Jp
dHkSRAoGYWN0aW9uGAIgASgOMiwuZ29vZ2xlLmFwcGVuZ2luZS52MWJldGEuRmlyZXdhbGxS
dWxlLkFjdGlvblIGYWN0aW9uEiEKDHNvdXJjZV9yYW5nZRgDIAEoCVILc291cmNlUmFuZ2US
IAoLZGVzY3JpcHRpb24YBCABKAlSC2Rlc2NyaXB0aW9uIjUKBkFjdGlvbhIWChJVTlNQRUNJ
RklFRF9BQ1RJT04QABIJCgVBTExPVxABEggKBERFTlkQAkLcAQokY29tLmdvb2dsZS5hcHBl
bmdpbmUudjFiZXRhLmZpcmV3YWxsQg1GaXJld2FsbFByb3RvUAFaQGdvb2dsZS5nb2xhbmcu
b3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvYXBwZW5naW5lL3YxYmV0YTthcHBlbmdpbmWqAh1H
b29nbGUuQ2xvdWQuQXBwRW5naW5lLlYxQmV0YcoCHUdvb2dsZVxDbG91ZFxBcHBFbmdpbmVc
VjFiZXRh6gIgR29vZ2xlOjpDbG91ZDo6QXBwRW5naW5lOjpWMWJldGFK/RIKBhIEDgBEAQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIAoICgEIEgMTADoK
CQoCCCUSAxMAOgoICgEIEgMUAFcKCQoCCAsSAxQAVwoICgEIEgMVACIKCQoCCAoSAxUAIgoI
CgEIEgMWAC4KCQoCCAgSAxYALgoICgEIEgMXAD0KCQoCCAESAxcAPQoICgEIEgMYADoKCQoC
CCkSAxgAOgoICgEIEgMZADkKCQoCCC0SAxkAOQqEAQoCBAASBB0ARAEaeCBBIHNpbmdsZSBm
aXJld2FsbCBydWxlIHRoYXQgaXMgZXZhbHVhdGVkIGFnYWluc3QgaW5jb21pbmcgdHJhZmZp
YwogYW5kIHByb3ZpZGVzIGFuIGFjdGlvbiB0byB0YWtlIG9uIG1hdGNoZWQgcmVxdWVzdHMu
CgoKCgMEAAESAx0IFAo/CgQEAAQAEgQfAicDGjEgQXZhaWxhYmxlIGFjdGlvbnMgdG8gdGFr
ZSBvbiBtYXRjaGluZyByZXF1ZXN0cy4KCgwKBQQABAABEgMfBw0KDQoGBAAEAAIAEgMgBBsK
DgoHBAAEAAIAARIDIAQWCg4KBwQABAACAAISAyAZGgovCgYEAAQAAgESAyMEDhogIE1hdGNo
aW5nIHJlcXVlc3RzIGFyZSBhbGxvd2VkLgoKDgoHBAAEAAIBARIDIwQJCg4KBwQABAACAQIS
AyMMDQouCgYEAAQAAgISAyYEDRofIE1hdGNoaW5nIHJlcXVlc3RzIGFyZSBkZW5pZWQuCgoO
CgcEAAQAAgIBEgMmBAgKDgoHBAAEAAICAhIDJgsMCskCCgQEAAIAEgMvAhUauwIgQSBwb3Np
dGl2ZSBpbnRlZ2VyIGJldHdlZW4gWzEsIEludDMyLk1heFZhbHVlLTFdIHRoYXQgZGVmaW5l
cyB0aGUgb3JkZXIgb2YKIHJ1bGUgZXZhbHVhdGlvbi4gUnVsZXMgd2l0aCB0aGUgbG93ZXN0
IHByaW9yaXR5IGFyZSBldmFsdWF0ZWQgZmlyc3QuCgogQSBkZWZhdWx0IHJ1bGUgYXQgcHJp
b3JpdHkgSW50MzIuTWF4VmFsdWUgbWF0Y2hlcyBhbGwgSVB2NCBhbmQgSVB2NiB0cmFmZmlj
CiB3aGVuIG5vIHByZXZpb3VzIHJ1bGUgbWF0Y2hlcy4gT25seSB0aGUgYWN0aW9uIG9mIHRo
aXMgcnVsZSBjYW4gYmUgbW9kaWZpZWQKIGJ5IHRoZSB1c2VyLgoKDAoFBAACAAUSAy8CBwoM
CgUEAAIAARIDLwgQCgwKBQQAAgADEgMvExQKNgoEBAACARIDMgIUGikgVGhlIGFjdGlvbiB0
byB0YWtlIG9uIG1hdGNoZWQgcmVxdWVzdHMuCgoMCgUEAAIBBhIDMgIICgwKBQQAAgEBEgMy
CQ8KDAoFBAACAQMSAzISEwrHBAoEBAACAhIDPwIaGrkEIElQIGFkZHJlc3Mgb3IgcmFuZ2Us
IGRlZmluZWQgdXNpbmcgQ0lEUiBub3RhdGlvbiwgb2YgcmVxdWVzdHMgdGhhdCB0aGlzCiBy
dWxlIGFwcGxpZXMgdG8uIFlvdSBjYW4gdXNlIHRoZSB3aWxkY2FyZCBjaGFyYWN0ZXIgIioi
IHRvIG1hdGNoIGFsbCBJUHMKIGVxdWl2YWxlbnQgdG8gIjAvMCIgYW5kICI6Oi8wIiB0b2dl
dGhlci4KIEV4YW1wbGVzOiBgMTkyLjE2OC4xLjFgIG9yIGAxOTIuMTY4LjAuMC8xNmAgb3Ig
YDIwMDE6ZGI4OjovMzJgCiAgICAgICAgICAgb3IgYDIwMDE6MGRiODowMDAwOjAwNDI6MDAw
MDo4YTJlOjAzNzA6NzMzNGAuCgoKIDxwPlRydW5jYXRpb24gd2lsbCBiZSBzaWxlbnRseSBw
ZXJmb3JtZWQgb24gYWRkcmVzc2VzIHdoaWNoIGFyZSBub3QKIHByb3Blcmx5IHRydW5jYXRl
ZC4gRm9yIGV4YW1wbGUsIGAxLjIuMy40LzI0YCBpcyBhY2NlcHRlZCBhcyB0aGUgc2FtZQog
YWRkcmVzcyBhcyBgMS4yLjMuMC8yNGAuIFNpbWlsYXJseSwgZm9yIElQdjYsIGAyMDAxOmRi
ODo6MS8zMmAgaXMgYWNjZXB0ZWQKIGFzIHRoZSBzYW1lIGFkZHJlc3MgYXMgYDIwMDE6ZGI4
OjovMzJgLgoKDAoFBAACAgUSAz8CCAoMCgUEAAICARIDPwkVCgwKBQQAAgIDEgM/GBkKbwoE
BAACAxIDQwIZGmIgQW4gb3B0aW9uYWwgc3RyaW5nIGRlc2NyaXB0aW9uIG9mIHRoaXMgcnVs
ZS4KIFRoaXMgZmllbGQgaGFzIGEgbWF4aW11bSBsZW5ndGggb2YgMTAwIGNoYXJhY3RlcnMu
CgoMCgUEAAIDBRIDQwIICgwKBQQAAgMBEgNDCRQKDAoFBAACAwMSA0MXGGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Appengine::V1beta::Firewall::FirewallRule ===
    # Fields for FirewallRule
    # Field: priority Type: 5 ()
    # Field: action Type: 14 (.google.appengine.v1beta.FirewallRule.Action)
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

Google::Appengine::V1beta::Firewall - Compiled Protocol Buffers messages for google/appengine/v1beta/firewall.proto

=head1 SYNOPSIS

    use Google::Appengine::V1beta::Firewall;

    my $msg = Google::Appengine::V1beta::Firewall::FirewallRule->new({
        priority => $priority,
        action => $action,
        source_range => $source_range,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->priority();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Appengine::V1beta::Firewall::FirewallRule->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/appengine/v1beta/firewall.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Appengine::V1beta::Firewall::FirewallRule

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

Type: C<Enum> (L<Google::Appengine::V1beta::FirewallRule::Action>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Appengine::V1beta::Firewall::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
