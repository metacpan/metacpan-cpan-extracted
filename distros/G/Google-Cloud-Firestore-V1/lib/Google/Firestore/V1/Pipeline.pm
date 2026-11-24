package Google::Firestore::V1::Pipeline;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Firestore::V1::Document };
    my $descriptor_b64 = <<'EOF';
CiJnb29nbGUvZmlyZXN0b3JlL3YxL3BpcGVsaW5lLnByb3RvEhNnb29nbGUuZmlyZXN0b3Jl
LnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGiJnb29nbGUvZmlyZXN0b3Jl
L3YxL2RvY3VtZW50LnByb3RvIoECChJTdHJ1Y3R1cmVkUGlwZWxpbmUSPgoIcGlwZWxpbmUY
ASABKAsyHS5nb29nbGUuZmlyZXN0b3JlLnYxLlBpcGVsaW5lQgPgQQJSCHBpcGVsaW5lElMK
B29wdGlvbnMYAiADKAsyNC5nb29nbGUuZmlyZXN0b3JlLnYxLlN0cnVjdHVyZWRQaXBlbGlu
ZS5PcHRpb25zRW50cnlCA+BBAVIHb3B0aW9ucxpWCgxPcHRpb25zRW50cnkSEAoDa2V5GAEg
ASgJUgNrZXkSMAoFdmFsdWUYAiABKAsyGi5nb29nbGUuZmlyZXN0b3JlLnYxLlZhbHVlUgV2
YWx1ZToCOAFCxQEKF2NvbS5nb29nbGUuZmlyZXN0b3JlLnYxQg1QaXBlbGluZVByb3RvUAFa
O2Nsb3VkLmdvb2dsZS5jb20vZ28vZmlyZXN0b3JlL2FwaXYxL2ZpcmVzdG9yZXBiO2ZpcmVz
dG9yZXBiogIER0NGU6oCGUdvb2dsZS5DbG91ZC5GaXJlc3RvcmUuVjHKAhlHb29nbGVcQ2xv
dWRcRmlyZXN0b3JlXFYx6gIcR29vZ2xlOjpDbG91ZDo6RmlyZXN0b3JlOjpWMUrECgoGEgQO
ACoBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAcCgkKAgMA
EgMSACkKCQoCAwESAxMALAoICgEIEgMVADYKCQoCCCUSAxUANgoICgEIEgMWAFIKCQoCCAsS
AxYAUgoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYAC4KCQoCCAgSAxgALgoICgEIEgMZ
ADAKCQoCCAESAxkAMAoICgEIEgMaACIKCQoCCCQSAxoAIgoICgEIEgMbADYKCQoCCCkSAxsA
NgoICgEIEgMcADUKCQoCCC0SAxwANQqgAgoCBAASBCMAKgEakwIgQSBGaXJlc3RvcmUgcXVl
cnkgcmVwcmVzZW50ZWQgYXMgYW4gb3JkZXJlZCBsaXN0IG9mIG9wZXJhdGlvbnMgLyBzdGFn
ZXMuCgogVGhpcyBpcyBjb25zaWRlcmVkIHRoZSB0b3AtbGV2ZWwgZnVuY3Rpb24gd2hpY2gg
cGxhbnMgYW5kIGV4ZWN1dGVzIGEgcXVlcnkuCiBJdCBpcyBsb2dpY2FsbHkgZXF1aXZhbGVu
dCB0byBgcXVlcnkoc3RhZ2VzLCBvcHRpb25zKWAsIGJ1dCBwcmV2ZW50cyB0aGUKIGNsaWVu
dCBmcm9tIGhhdmluZyB0byBidWlsZCBhIGZ1bmN0aW9uIHdyYXBwZXIuCgoKCgMEAAESAyMI
Ggo3CgQEAAIAEgMlAkEaKiBSZXF1aXJlZC4gVGhlIHBpcGVsaW5lIHF1ZXJ5IHRvIGV4ZWN1
dGUuCgoMCgUEAAIABhIDJQIKCgwKBQQAAgABEgMlCxMKDAoFBAACAAMSAyUWFwoMCgUEAAIA
CBIDJRhACg8KCAQAAgAInAgAEgMlGT8KOQoEBAACARIDKQJKGiwgT3B0aW9uYWwuIE9wdGlv
bmFsIHF1ZXJ5LWxldmVsIGFyZ3VtZW50cy4KCgoMCgUEAAIBBhIDKQIUCgwKBQQAAgEBEgMp
FRwKDAoFBAACAQMSAykfIAoMCgUEAAIBCBIDKSFJCg8KCAQAAgEInAgAEgMpIkhiBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::V1::Pipeline::StructuredPipeline ===
    # Fields for StructuredPipeline
    # Field: pipeline Type: 11 (.google.firestore.v1.Pipeline)
    # Field: options Type: 11 (.google.firestore.v1.StructuredPipeline.OptionsEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::V1::Pipeline - Compiled Protocol Buffers messages for google/firestore/v1/pipeline.proto

=head1 SYNOPSIS

    use Google::Firestore::V1::Pipeline;

    my $msg = Google::Firestore::V1::Pipeline::StructuredPipeline->new({
        pipeline => $pipeline,
        options => $options,
    });

    # Read or update a field
    my $val = $msg->pipeline();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::V1::Pipeline::StructuredPipeline->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/v1/pipeline.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::V1::Pipeline::StructuredPipeline

A Firestore query represented as an ordered list of operations / stages.

This is considered the top-level function which plans and executes a query.
It is logically equivalent to `query(stages, options)`, but prevents the
client from having to build a function wrapper.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->pipeline() >> / C<< $msg->pipeline($value) >>

Type: C<Message> (L<Google::Firestore::V1::Document::Pipeline>)

Required. The pipeline query to execute.

=item * C<< $msg->options() >> / C<< $msg->options($value) >>

Type: C<Message> (L<Google::Firestore::V1::Pipeline::StructuredPipeline::OptionsEntry>)

Optional. Optional query-level arguments.


=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::V1::Pipeline::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
