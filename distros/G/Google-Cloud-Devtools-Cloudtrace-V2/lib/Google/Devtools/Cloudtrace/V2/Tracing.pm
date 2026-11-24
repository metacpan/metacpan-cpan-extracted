package Google::Devtools::Cloudtrace::V2::Tracing;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Devtools::Cloudtrace::V2::Trace };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvZGV2dG9vbHMvY2xvdWR0cmFjZS92Mi90cmFjaW5nLnByb3RvEh1nb29nbGUu
ZGV2dG9vbHMuY2xvdWR0cmFjZS52MhocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoX
Z29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aKWdvb2dsZS9kZXZ0b29scy9jbG91ZHRy
YWNlL3YyL3RyYWNlLnByb3RvGhtnb29nbGUvcHJvdG9idWYvZW1wdHkucHJvdG8ioQEKFkJh
dGNoV3JpdGVTcGFuc1JlcXVlc3QSRwoEbmFtZRgBIAEoCUIz4EEC+kEtCitjbG91ZHJlc291
cmNlbWFuYWdlci5nb29nbGVhcGlzLmNvbS9Qcm9qZWN0UgRuYW1lEj4KBXNwYW5zGAIgAygL
MiMuZ29vZ2xlLmRldnRvb2xzLmNsb3VkdHJhY2UudjIuU3BhbkID4EECUgVzcGFuczK6AwoM
VHJhY2VTZXJ2aWNlEqEBCg9CYXRjaFdyaXRlU3BhbnMSNS5nb29nbGUuZGV2dG9vbHMuY2xv
dWR0cmFjZS52Mi5CYXRjaFdyaXRlU3BhbnNSZXF1ZXN0GhYuZ29vZ2xlLnByb3RvYnVmLkVt
cHR5Ij+C0+STAiwiJy92Mi97bmFtZT1wcm9qZWN0cy8qfS90cmFjZXM6YmF0Y2hXcml0ZToB
KtpBCm5hbWUsc3BhbnMSiQEKCkNyZWF0ZVNwYW4SIy5nb29nbGUuZGV2dG9vbHMuY2xvdWR0
cmFjZS52Mi5TcGFuGiMuZ29vZ2xlLmRldnRvb2xzLmNsb3VkdHJhY2UudjIuU3BhbiIxgtPk
kwIrIiYvdjIve25hbWU9cHJvamVjdHMvKi90cmFjZXMvKi9zcGFucy8qfToBKhp6ykEZY2xv
dWR0cmFjZS5nb29nbGVhcGlzLmNvbdJBW2h0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL2F1
dGgvY2xvdWQtcGxhdGZvcm0saHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC90cmFj
ZS5hcHBlbmRCrwEKIWNvbS5nb29nbGUuZGV2dG9vbHMuY2xvdWR0cmFjZS52MkIMVHJhY2lu
Z1Byb3RvUAFaL2Nsb3VkLmdvb2dsZS5jb20vZ28vdHJhY2UvYXBpdjIvdHJhY2VwYjt0cmFj
ZXBiqgIVR29vZ2xlLkNsb3VkLlRyYWNlLlYyygIVR29vZ2xlXENsb3VkXFRyYWNlXFYy6gIY
R29vZ2xlOjpDbG91ZDo6VHJhY2U6OlYySvEPCgYSBA4ATwEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACYKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMC
EgMUACkKCQoCAwMSAxUAIwoJCgIDBBIDFgAzCgkKAgMFEgMXACUKCAoBCBIDGQAyCgkKAggl
EgMZADIKCAoBCBIDGgBGCgkKAggLEgMaAEYKCAoBCBIDGwAiCgkKAggKEgMbACIKCAoBCBID
HAAtCgkKAggIEgMcAC0KCAoBCBIDHQA6CgkKAggBEgMdADoKCAoBCBIDHgAyCgkKAggpEgMe
ADIKCAoBCBIDHwAxCgkKAggtEgMfADEKygIKAgYAEgQoAD8BGr0CIFNlcnZpY2UgZm9yIGNv
bGxlY3RpbmcgYW5kIHZpZXdpbmcgdHJhY2VzIGFuZCBzcGFucyB3aXRoaW4gYSB0cmFjZS4K
CiBBIHRyYWNlIGlzIGEgY29sbGVjdGlvbiBvZiBzcGFucyBjb3JyZXNwb25kaW5nIHRvIGEg
c2luZ2xlCiBvcGVyYXRpb24gb3IgYSBzZXQgb2Ygb3BlcmF0aW9ucyBpbiBhbiBhcHBsaWNh
dGlvbi4KCiBBIHNwYW4gaXMgYW4gaW5kaXZpZHVhbCB0aW1lZCBldmVudCB3aGljaCBmb3Jt
cyBhIG5vZGUgb2YgdGhlIHRyYWNlIHRyZWUuCiBBIHNpbmdsZSB0cmFjZSBjYW4gY29udGFp
biBzcGFucyBmcm9tIG11bHRpcGxlIHNlcnZpY2VzLgoKCgoDBgABEgMoCBQKCgoDBgADEgMp
AkEKDAoFBgADmQgSAykCQQoLCgMGAAMSBCoCLDUKDQoFBgADmggSBCoCLDUKZAoEBgACABIE
MAI2AxpWIEJhdGNoIHdyaXRlcyBuZXcgc3BhbnMgdG8gbmV3IG9yIGV4aXN0aW5nIHRyYWNl
cy4gWW91IGNhbm5vdCB1cGRhdGUKIGV4aXN0aW5nIHNwYW5zLgoKDAoFBgACAAESAzAGFQoM
CgUGAAIAAhIDMBYsCgwKBQYAAgADEgMwN0wKDQoFBgACAAQSBDEENAYKEQoJBgACAASwyrwi
EgQxBDQGCgwKBQYAAgAEEgM1BDgKDwoIBgACAASbCAASAzUEOAojCgQGAAIBEgQ5Aj4DGhUg
Q3JlYXRlcyBhIG5ldyBzcGFuLgoKDAoFBgACAQESAzkGEAoMCgUGAAIBAhIDOREVCgwKBQYA
AgEDEgM5ICQKDQoFBgACAQQSBDoEPQYKEQoJBgACAQSwyrwiEgQ6BD0GCkMKAgQAEgRCAE8B
GjcgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IgdGhlIGBCYXRjaFdyaXRlU3BhbnNgIG1ldGhv
ZC4KCgoKAwQAARIDQggeCnEKBAQAAgASBEUCSgQaYyBSZXF1aXJlZC4gVGhlIG5hbWUgb2Yg
dGhlIHByb2plY3Qgd2hlcmUgdGhlIHNwYW5zIGJlbG9uZy4gVGhlIGZvcm1hdCBpcwogYHBy
b2plY3RzL1tQUk9KRUNUX0lEXWAuCgoMCgUEAAIABRIDRQIICgwKBQQAAgABEgNFCQ0KDAoF
BAACAAMSA0UQEQoNCgUEAAIACBIERRJKAwoPCggEAAIACJwIABIDRgQqCg8KBwQAAgAInwgS
BEcESQUKgQEKBAQAAgESA04CQxp0IFJlcXVpcmVkLiBBIGxpc3Qgb2YgbmV3IHNwYW5zLiBU
aGUgc3BhbiBuYW1lcyBtdXN0IG5vdCBtYXRjaCBleGlzdGluZwogc3BhbnMsIG90aGVyd2lz
ZSB0aGUgcmVzdWx0cyBhcmUgdW5kZWZpbmVkLgoKDAoFBAACAQQSA04CCgoMCgUEAAIBBhID
TgsPCgwKBQQAAgEBEgNOEBUKDAoFBAACAQMSA04YGQoMCgUEAAIBCBIDThpCCg8KCAQAAgEI
nAgAEgNOG0FiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Cloudtrace::V2::Tracing::BatchWriteSpansRequest ===
    # Fields for BatchWriteSpansRequest
    # Field: name Type: 9 ()
    # Field: spans Type: 11 (.google.devtools.cloudtrace.v2.Span)

# === Service Client: Google::Devtools::Cloudtrace::V2::Tracing::TraceServiceClient ===
package Google::Devtools::Cloudtrace::V2::Tracing::TraceServiceClient;

=pod

=head2 Service Client: Google::Devtools::Cloudtrace::V2::Tracing::TraceServiceClient

Client stub representing the remote C<TraceService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<devtools.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'devtools.googleapis.com:443' );

has _grpc_client => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Google::gRPC::Client->new(
            target     => $self->target,
            auth_token => $self->credentials->get_token(),
        );
    }
);

sub batch_write_spans {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Cloudtrace::V2::Tracing::BatchWriteSpansRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.cloudtrace.v2.TraceService',
        method         => 'BatchWriteSpans',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub create_span {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Devtools::Cloudtrace::V2::Trace::Span->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.devtools.cloudtrace.v2.TraceService',
        method         => 'CreateSpan',
        request        => $req,
        response_class => 'Google::Devtools::Cloudtrace::V2::Trace::Span',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Cloudtrace::V2::Tracing - Compiled Protocol Buffers messages for google/devtools/cloudtrace/v2/tracing.proto

=head1 SYNOPSIS

    use Google::Devtools::Cloudtrace::V2::Tracing;

    my $msg = Google::Devtools::Cloudtrace::V2::Tracing::BatchWriteSpansRequest->new({
        name => $name,
        spans => $spans,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Cloudtrace::V2::Tracing::BatchWriteSpansRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/cloudtrace/v2/tracing.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Cloudtrace::V2::Tracing::BatchWriteSpansRequest

The request message for the `BatchWriteSpans` method.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the project where the spans belong. The format is
`projects/[PROJECT_ID]`.

=item * C<< $msg->spans() >> / C<< $msg->spans($value) >>

Type: C<Message> (L<Google::Devtools::Cloudtrace::V2::Trace::Span>)

Required. A list of new spans. The span names must not match existing
spans, otherwise the results are undefined.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Cloudtrace::V2::Tracing::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
