package Google::Actions::Sdk::V2::Interactionmodel::Type::ClassReference;

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
CkFnb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC90eXBlL2NsYXNzX3Jl
ZmVyZW5jZS5wcm90bxIrZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0aW9ubW9kZWwu
dHlwZRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90byJCCg5DbGFzc1JlZmVyZW5j
ZRIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWUSFwoEbGlzdBgCIAEoCEID4EEBUgRsaXN0QpQB
Ci9jb20uZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0aW9ubW9kZWwudHlwZUITQ2xh
c3NSZWZlcmVuY2VQcm90b1ABWkpnb29nbGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVh
cGlzL2FjdGlvbnMvc2RrL3YyL2ludGVyYWN0aW9ubW9kZWwvdHlwZUrfCQoGEgQOACMBCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAA0CgkKAgMAEgMSACkK
CAoBCBIDFABhCgkKAggLEgMUAGEKCAoBCBIDFQAiCgkKAggKEgMVACIKCAoBCBIDFgA0CgkK
AggIEgMWADQKCAoBCBIDFwBICgkKAggBEgMXAEgKsQEKAgQAEgQcACMBGqQBIEEgcmVmZXJl
bmNlIHRvIGEgY2xhc3Mgd2hpY2ggaXMgdXNlZCB0byBkZWNsYXJlIHRoZSB0eXBlIG9mIGEg
ZmllbGQgb3IgcmV0dXJuCiB2YWx1ZS4gRW51bXMgYXJlIGFsc28gYSB0eXBlIG9mIGNsYXNz
IHRoYXQgY2FuIGJlIHJlZmVyZW5jZWQgdXNpbmcKIENsYXNzUmVmZXJlbmNlLgoKCgoDBAAB
EgMcCBYKgwEKBAQAAgASAx8COxp2IFJlcXVpcmVkLiBOYW1lIG9mIGEgYnVpbHQtaW4gdHlw
ZSBvciBjdXN0b20gdHlwZSBvZiB0aGUgcGFyYW1ldGVyLiBFeGFtcGxlczoKIGBQaXp6YVRv
cHBpbmdzYCwgYGFjdGlvbnMudHlwZS5OdW1iZXJgCgoMCgUEAAIABRIDHwIICgwKBQQAAgAB
EgMfCQ0KDAoFBAACAAMSAx8QEQoMCgUEAAIACBIDHxI6Cg8KCAQAAgAInAgAEgMfEzkKVQoE
BAACARIDIgI5GkggT3B0aW9uYWwuIEluZGljYXRlcyB3aGV0aGVyIHRoZSBkYXRhIHR5cGUg
cmVwcmVzZW50cyBhIGxpc3Qgb2YgdmFsdWVzLgoKDAoFBAACAQUSAyICBgoMCgUEAAIBARID
IgcLCgwKBQQAAgEDEgMiDg8KDAoFBAACAQgSAyIQOAoPCggEAAIBCJwIABIDIhE3YgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Type::ClassReference::ClassReference ===
    # Fields for ClassReference
    # Field: name Type: 9 ()
    # Field: list Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Type::ClassReference - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/type/class_reference.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::Type::ClassReference;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::Type::ClassReference::ClassReference->new({
        name => $name,
        list => $list,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::Type::ClassReference::ClassReference->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/type/class_reference.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::Type::ClassReference::ClassReference

A reference to a class which is used to declare the type of a field or return
value. Enums are also a type of class that can be referenced using
ClassReference.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of a built-in type or custom type of the parameter. Examples:
`PizzaToppings`, `actions.type.Number`

=item * C<< $msg->list() >> / C<< $msg->list($value) >>

Type: C<Bool>

Optional. Indicates whether the data type represents a list of values.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::Type::ClassReference::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
