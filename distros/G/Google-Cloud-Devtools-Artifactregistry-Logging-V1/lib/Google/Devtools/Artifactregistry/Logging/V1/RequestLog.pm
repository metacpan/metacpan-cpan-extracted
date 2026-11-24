package Google::Devtools::Artifactregistry::Logging::V1::RequestLog;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Struct };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
Cj1nb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS9sb2dnaW5nL3YxL3JlcXVlc3Rf
bG9nLnByb3RvEitnb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3RyeS5sb2dnaW5nLnYx
Ghxnb29nbGUvcHJvdG9idWYvc3RydWN0LnByb3RvGhdnb29nbGUvcnBjL3N0YXR1cy5wcm90
byLVAQoKUmVxdWVzdExvZxIqCgZzdGF0dXMYASABKAsyEi5nb29nbGUucnBjLlN0YXR1c1IG
c3RhdHVzEjEKB3JlcXVlc3QYAiABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0UgdyZXF1
ZXN0EjMKCHJlc3BvbnNlGAMgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFIIcmVzcG9u
c2USMwoIbWV0YWRhdGEYBCABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0UghtZXRhZGF0
YUKRAgovY29tLmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LmxvZ2dpbmcudjFC
D1JlcXVlc3RMb2dQcm90b1ABWkZjbG91ZC5nb29nbGUuY29tL2dvL2FydGlmYWN0cmVnaXN0
cnkvbG9nZ2luZy9hcGl2MS9sb2dnaW5ncGI7bG9nZ2luZ3BiqgIoR29vZ2xlLkNsb3VkLkFy
dGlmYWN0UmVnaXN0cnkuTG9nZ2luZy5WMcoCKEdvb2dsZVxDbG91ZFxBcnRpZmFjdFJlZ2lz
dHJ5XExvZ2dpbmdcVjHqAixHb29nbGU6OkNsb3VkOjpBcnRpZmFjdFJlZ2lzdHJ5OjpMb2dn
aW5nOjpWMUrIDAoGEgQOAC8BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xl
IExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAg
KHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4g
Y29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9m
IHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9M
SUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3Jl
ZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNl
bnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJB
TlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1w
bGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVy
bmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoK
CAoBAhIDEAA0CgkKAgMAEgMSACYKCQoCAwESAxMAIQoICgEIEgMVAEUKCQoCCCUSAxUARQoI
CgEIEgMWAF0KCQoCCAsSAxYAXQoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYADAKCQoC
CAgSAxgAMAoICgEIEgMZAEgKCQoCCAESAxkASAoICgEIEgMaAEYKCQoCCCkSAxoARgoICgEI
EgMbAEUKCQoCCC0SAxsARQpICgIEABIEHgAvARo8IExvZyBtZXNzYWdlIHRoYXQgY29udGFp
bnMgaW5mb3JtYXRpb24gYWJvdXQgYW4gQVIgcmVxdWVzdC4KCgoKAwQAARIDHggSCjMKBAQA
AgASAyACHxomIFRoZSBzdGF0dXMgb2YgdGhlIG92ZXJhbGwgb3BlcmF0aW9uLgoKDAoFBAAC
AAYSAyACEwoMCgUEAAIAARIDIBQaCgwKBQQAAgADEgMgHR4KfgoEBAACARIDJAIlGnEgVGhl
IHJlcXVlc3QgcGFyYW1ldGVycy4gSXQgbWF5IG5vdCBpbmNsdWRlIGFsbCBvZiB0aGVtLCBz
dWNoIGFzIHRob3NlIHRoYXQKIGFyZSB0b28gbGFyZ2Ugb3IgcHJpdmFjeS1zZW5zaXRpdmUu
CgoMCgUEAAIBBhIDJAIYCgwKBQQAAgEBEgMkGSAKDAoFBAACAQMSAyQjJAp9CgQEAAICEgMo
AiYacCBUaGUgcmVzcG9uc2UgZWxlbWVudHMuIGl0IG1heSBub3QgaW5jbHVkZSBhbGwgb2Yg
dGhlbSwgc3VjaCBhcyB0aG9zZSB0aGF0CiBhcmUgdG9vIGxhcmdlIG9yIHByaXZhY3ktc2Vu
c2l0aXZlLgoKDAoFBAACAgYSAygCGAoMCgUEAAICARIDKBkhCgwKBQQAAgIDEgMoJCUKmQIK
BAQAAgMSAy4CJhqLAiBPdGhlciBzZXJ2aWNlLXNwZWNpZmljIGRhdGEgYWJvdXQgY3VycmVu
dCByZXF1ZXN0IHRoYXQgaXMgbm90IGluY2x1ZGVkIGluCiB0aGUgcmVxdWVzdCBwYXJhbWV0
ZXJzIHJlY2VpdmVkIGZyb20gdGhlIHVzZXIgb3IgaW4gdGhlIHJlc3BvbnNlIHNlbnQgYmFj
ay4KIEZvciBleGFtcGxlLCB0aGUgbnVtYmVyIG9yIGxpc3Qgb2YgdmVyc2lvbnMgdGhhdCBo
YXZlIGJlZW4gZGVsZXRlZCwgd2hlbgogdGhlIHVzZXIgcmVxdWVzdGVkIHRvIGRlbGV0ZSBh
IHBhY2thZ2UuCgoMCgUEAAIDBhIDLgIYCgwKBQQAAgMBEgMuGSEKDAoFBAACAwMSAy4kJWIG
cHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::Logging::V1::RequestLog::RequestLog ===
    # Fields for RequestLog
    # Field: status Type: 11 (.google.rpc.Status)
    # Field: request Type: 11 (.google.protobuf.Struct)
    # Field: response Type: 11 (.google.protobuf.Struct)
    # Field: metadata Type: 11 (.google.protobuf.Struct)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::Logging::V1::RequestLog - Compiled Protocol Buffers messages for google/devtools/artifactregistry/logging/v1/request_log.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::Logging::V1::RequestLog;

    my $msg = Google::Devtools::Artifactregistry::Logging::V1::RequestLog::RequestLog->new({
        status => $status,
        request => $request,
        response => $response,
        metadata => $metadata,
    });

    # Read or update a field
    my $val = $msg->status();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::Logging::V1::RequestLog::RequestLog->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/logging/v1/request_log.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::Logging::V1::RequestLog::RequestLog

Log message that contains information about an AR request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

The status of the overall operation.

=item * C<< $msg->request() >> / C<< $msg->request($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

The request parameters. It may not include all of them, such as those that
are too large or privacy-sensitive.

=item * C<< $msg->response() >> / C<< $msg->response($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

The response elements. it may not include all of them, such as those that
are too large or privacy-sensitive.

=item * C<< $msg->metadata() >> / C<< $msg->metadata($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Other service-specific data about current request that is not included in
the request parameters received from the user or in the response sent back.
For example, the number or list of versions that have been deleted, when
the user requested to delete a package.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::Logging::V1::RequestLog::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
