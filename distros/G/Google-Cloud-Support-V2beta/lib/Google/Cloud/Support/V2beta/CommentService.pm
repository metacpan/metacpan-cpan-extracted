package Google::Cloud::Support::V2beta::CommentService;

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
    eval { require Google::Cloud::Support::V2beta::Comment };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvc3VwcG9ydC92MmJldGEvY29tbWVudF9zZXJ2aWNlLnByb3RvEhtn
b29nbGUuY2xvdWQuc3VwcG9ydC52MmJldGEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJv
dG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGilnb29nbGUvY2xvdWQvc3VwcG9y
dC92MmJldGEvY29tbWVudC5wcm90byKTAQoTTGlzdENvbW1lbnRzUmVxdWVzdBJACgZwYXJl
bnQYASABKAlCKOBBAvpBIgogY2xvdWRzdXBwb3J0Lmdvb2dsZWFwaXMuY29tL0Nhc2VSBnBh
cmVudBIbCglwYWdlX3NpemUYBCABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YBSABKAlS
CXBhZ2VUb2tlbiKAAQoUTGlzdENvbW1lbnRzUmVzcG9uc2USQAoIY29tbWVudHMYASADKAsy
JC5nb29nbGUuY2xvdWQuc3VwcG9ydC52MmJldGEuQ29tbWVudFIIY29tbWVudHMSJgoPbmV4
dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2VuIp0BChRDcmVhdGVDb21tZW50UmVx
dWVzdBJACgZwYXJlbnQYASABKAlCKOBBAvpBIgogY2xvdWRzdXBwb3J0Lmdvb2dsZWFwaXMu
Y29tL0Nhc2VSBnBhcmVudBJDCgdjb21tZW50GAIgASgLMiQuZ29vZ2xlLmNsb3VkLnN1cHBv
cnQudjJiZXRhLkNvbW1lbnRCA+BBAlIHY29tbWVudCJUChFHZXRDb21tZW50UmVxdWVzdBI/
CgRuYW1lGAEgASgJQivgQQL6QSUKI2Nsb3Vkc3VwcG9ydC5nb29nbGVhcGlzLmNvbS9Db21t
ZW50UgRuYW1lMuAFCg5Db21tZW50U2VydmljZRLnAQoMTGlzdENvbW1lbnRzEjAuZ29vZ2xl
LmNsb3VkLnN1cHBvcnQudjJiZXRhLkxpc3RDb21tZW50c1JlcXVlc3QaMS5nb29nbGUuY2xv
dWQuc3VwcG9ydC52MmJldGEuTGlzdENvbW1lbnRzUmVzcG9uc2UicoLT5JMCYxIsL3YyYmV0
YS97cGFyZW50PXByb2plY3RzLyovY2FzZXMvKn0vY29tbWVudHNaMxIxL3YyYmV0YS97cGFy
ZW50PW9yZ2FuaXphdGlvbnMvKi9jYXNlcy8qfS9jb21tZW50c9pBBnBhcmVudBL3AQoNQ3Jl
YXRlQ29tbWVudBIxLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyYmV0YS5DcmVhdGVDb21tZW50
UmVxdWVzdBokLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyYmV0YS5Db21tZW50IowBgtPkkwJ1
IiwvdjJiZXRhL3twYXJlbnQ9cHJvamVjdHMvKi9jYXNlcy8qfS9jb21tZW50czoHY29tbWVu
dFo8IjEvdjJiZXRhL3twYXJlbnQ9b3JnYW5pemF0aW9ucy8qL2Nhc2VzLyp9L2NvbW1lbnRz
Ogdjb21tZW502kEOcGFyZW50LGNvbW1lbnQSmAEKCkdldENvbW1lbnQSLi5nb29nbGUuY2xv
dWQuc3VwcG9ydC52MmJldGEuR2V0Q29tbWVudFJlcXVlc3QaJC5nb29nbGUuY2xvdWQuc3Vw
cG9ydC52MmJldGEuQ29tbWVudCI0gtPkkwInEiUvdjJiZXRhL3tuYW1lPSovKi9jYXNlcy8q
L2NvbW1lbnRzLyp92kEEbmFtZRpPykEbY2xvdWRzdXBwb3J0Lmdvb2dsZWFwaXMuY29t0kEu
aHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybULQAQofY29t
Lmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyYmV0YUITQ29tbWVudFNlcnZpY2VQcm90b1ABWjlj
bG91ZC5nb29nbGUuY29tL2dvL3N1cHBvcnQvYXBpdjJiZXRhL3N1cHBvcnRwYjtzdXBwb3J0
cGKqAhtHb29nbGUuQ2xvdWQuU3VwcG9ydC5WMkJldGHKAhtHb29nbGVcQ2xvdWRcU3VwcG9y
dFxWMmJldGHqAh5Hb29nbGU6OkNsb3VkOjpTdXBwb3J0OjpWMmJldGFKvxcKBhIEDgB9AQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJAoJCgIDABIDEgAm
CgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMWADMKCAoBCBIDGAA4
CgkKAgglEgMYADgKCAoBCBIDGQBQCgkKAggLEgMZAFAKCAoBCBIDGgAiCgkKAggKEgMaACIK
CAoBCBIDGwA0CgkKAggIEgMbADQKCAoBCBIDHAA4CgkKAggBEgMcADgKCAoBCBIDHQA4CgkK
AggpEgMdADgKCAoBCBIDHgA3CgkKAggtEgMeADcKNAoCBgASBCEARwEaKCBBIHNlcnZpY2Ug
dG8gbWFuYWdlIGNvbW1lbnRzIG9uIGNhc2VzLgoKCgoDBgABEgMhCBYKCgoDBgADEgMiAkMK
DAoFBgADmQgSAyICQwoLCgMGAAMSBCMCJDcKDQoFBgADmggSBCMCJDcKPQoEBgACABIEJwIv
AxovIExpc3QgYWxsIHRoZSBjb21tZW50cyBhc3NvY2lhdGVkIHdpdGggYSBjYXNlLgoKDAoF
BgACAAESAycGEgoMCgUGAAIAAhIDJxMmCgwKBQYAAgADEgMnMUUKDQoFBgACAAQSBCgELQYK
EQoJBgACAASwyrwiEgQoBC0GCgwKBQYAAgAEEgMuBDQKDwoIBgACAASbCAASAy4ENApmCgQG
AAIBEgQ0Aj4DGlggQWRkIGEgbmV3IGNvbW1lbnQgdG8gYSBjYXNlLgoKIFRoZSBjb21tZW50
IG11c3QgaGF2ZSB0aGUgZm9sbG93aW5nIGZpZWxkcyBzZXQ6IGBib2R5YC4KCgwKBQYAAgEB
EgM0BhMKDAoFBgACAQISAzQUKAoMCgUGAAIBAxIDNDM6Cg0KBQYAAgEEEgQ1BDwGChEKCQYA
AgEEsMq8IhIENQQ8BgoMCgUGAAIBBBIDPQQ8Cg8KCAYAAgEEmwgAEgM9BDwKIwoEBgACAhIE
QQJGAxoVIFJldHJpZXZlIGEgY29tbWVudC4KCgwKBQYAAgIBEgNBBhAKDAoFBgACAgISA0ER
IgoMCgUGAAICAxIDQS00Cg0KBQYAAgIEEgRCBEQGChEKCQYAAgIEsMq8IhIEQgREBgoMCgUG
AAICBBIDRQQyCg8KCAYAAgIEmwgAEgNFBDIKQAoCBAASBEoAWQEaNCBUaGUgcmVxdWVzdCBt
ZXNzYWdlIGZvciB0aGUgTGlzdENvbW1lbnRzIGVuZHBvaW50LgoKCgoDBAABEgNKCBsKSgoE
BAACABIETAJRBBo8IFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgY2FzZSBmb3Igd2hpY2gg
dG8gbGlzdCBjb21tZW50cy4KCgwKBQQAAgAFEgNMAggKDAoFBAACAAESA0wJDwoMCgUEAAIA
AxIDTBITCg0KBQQAAgAIEgRMFFEDCg8KCAQAAgAInAgAEgNNBCoKDwoHBAACAAifCBIETgRQ
BQpHCgQEAAIBEgNUAhYaOiBUaGUgbWF4aW11bSBudW1iZXIgb2YgY29tbWVudHMgdG8gZmV0
Y2guIERlZmF1bHRzIHRvIDEwLgoKDAoFBAACAQUSA1QCBwoMCgUEAAIBARIDVAgRCgwKBQQA
AgEDEgNUFBUKbgoEBAACAhIDWAIYGmEgQSB0b2tlbiBpZGVudGlmeWluZyB0aGUgcGFnZSBv
ZiByZXN1bHRzIHRvIHJldHVybi4gSWYgdW5zcGVjaWZpZWQsIHRoZQogZmlyc3QgcGFnZSBp
cyByZXR1cm5lZC4KCgwKBQQAAgIFEgNYAggKDAoFBAACAgESA1gJEwoMCgUEAAICAxIDWBYX
CkEKAgQBEgRcAGQBGjUgVGhlIHJlc3BvbnNlIG1lc3NhZ2UgZm9yIHRoZSBMaXN0Q29tbWVu
dHMgZW5kcG9pbnQuCgoKCgMEAQESA1wIHAo9CgQEAQIAEgNeAiAaMCBMaXN0IG9mIHRoZSBj
b21tZW50cyBhc3NvY2lhdGVkIHdpdGggdGhlIGNhc2UuCgoMCgUEAQIABBIDXgIKCgwKBQQB
AgAGEgNeCxIKDAoFBAECAAESA14TGwoMCgUEAQIAAxIDXh4fCscBCgQEAQIBEgNjAh0auQEg
QSB0b2tlbiB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHJlc3VsdHMuIFNldCB0aGlz
IGluIHRoZSBgcGFnZV90b2tlbmAKIGZpZWxkIG9mIHN1YnNlcXVlbnQgYGNhc2VzLmNvbW1l
bnRzLmxpc3RgIHJlcXVlc3RzLiBJZiB1bnNwZWNpZmllZCwgdGhlcmUKIGFyZSBubyBtb3Jl
IHJlc3VsdHMgdG8gcmV0cmlldmUuCgoMCgUEAQIBBRIDYwIICgwKBQQBAgEBEgNjCRgKDAoF
BAECAQMSA2MbHApBCgIEAhIEZwByARo1IFRoZSByZXF1ZXN0IG1lc3NhZ2UgZm9yIHRoZSBD
cmVhdGVDb21tZW50IGVuZHBvaW50LgoKCgoDBAIBEgNnCBwKVAoEBAICABIEaQJuBBpGIFJl
cXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgY2FzZSB0byB3aGljaCB0aGUgY29tbWVudCBzaG91
bGQgYmUgYWRkZWQuCgoMCgUEAgIABRIDaQIICgwKBQQCAgABEgNpCQ8KDAoFBAICAAMSA2kS
EwoNCgUEAgIACBIEaRRuAwoPCggEAgIACJwIABIDagQqCg8KBwQCAgAInwgSBGsEbQUKMQoE
BAICARIDcQI/GiQgUmVxdWlyZWQuIFRoZSBjb21tZW50IHRvIGJlIGFkZGVkLgoKDAoFBAIC
AQYSA3ECCQoMCgUEAgIBARIDcQoRCgwKBQQCAgEDEgNxFBUKDAoFBAICAQgSA3EWPgoPCggE
AgIBCJwIABIDcRc9Cj4KAgQDEgR1AH0BGjIgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IgdGhl
IEdldENvbW1lbnQgZW5kcG9pbnQuCgoKCgMEAwESA3UIGQo+CgQEAwIAEgR3AnwEGjAgUmVx
dWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBjb21tZW50IHRvIHJldHJpZXZlLgoKDAoFBAMCAAUS
A3cCCAoMCgUEAwIAARIDdwkNCgwKBQQDAgADEgN3EBEKDQoFBAMCAAgSBHcSfAMKDwoIBAMC
AAicCAASA3gEKgoPCgcEAwIACJ8IEgR5BHsFYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Support::V2beta::CommentService::ListCommentsRequest ===
    # Fields for ListCommentsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Support::V2beta::CommentService::ListCommentsResponse ===
    # Fields for ListCommentsResponse
    # Field: comments Type: 11 (.google.cloud.support.v2beta.Comment)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Support::V2beta::CommentService::CreateCommentRequest ===
    # Fields for CreateCommentRequest
    # Field: parent Type: 9 ()
    # Field: comment Type: 11 (.google.cloud.support.v2beta.Comment)

# === Message: Google::Cloud::Support::V2beta::CommentService::GetCommentRequest ===
    # Fields for GetCommentRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Support::V2beta::CommentService::CommentServiceClient ===
package Google::Cloud::Support::V2beta::CommentService::CommentServiceClient;

=pod

=head2 Service Client: Google::Cloud::Support::V2beta::CommentService::CommentServiceClient

Client stub representing the remote C<CommentService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<support.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'support.googleapis.com:443' );

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

sub list_comments {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2beta::CommentService::ListCommentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2beta.CommentService',
        method         => 'ListComments',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2beta::CommentService::ListCommentsResponse',
    });
}

sub create_comment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2beta::CommentService::CreateCommentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2beta.CommentService',
        method         => 'CreateComment',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2beta::Comment::Comment',
    });
}

sub get_comment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2beta::CommentService::GetCommentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2beta.CommentService',
        method         => 'GetComment',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2beta::Comment::Comment',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Support::V2beta::CommentService - Compiled Protocol Buffers messages for google/cloud/support/v2beta/comment_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Support::V2beta::CommentService;

    my $msg = Google::Cloud::Support::V2beta::CommentService::ListCommentsRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Support::V2beta::CommentService::ListCommentsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/support/v2beta/comment_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Support::V2beta::CommentService::ListCommentsRequest

The request message for the ListComments endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the case for which to list comments.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of comments to fetch. Defaults to 10.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A token identifying the page of results to return. If unspecified, the
first page is returned.

=back

=head2 Google::Cloud::Support::V2beta::CommentService::ListCommentsResponse

The response message for the ListComments endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->comments() >> / C<< $msg->comments($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::Comment::Comment>)

List of the comments associated with the case.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve the next page of results. Set this in the `page_token`
field of subsequent `cases.comments.list` requests. If unspecified, there
are no more results to retrieve.

=back

=head2 Google::Cloud::Support::V2beta::CommentService::CreateCommentRequest

The request message for the CreateComment endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the case to which the comment should be added.

=item * C<< $msg->comment() >> / C<< $msg->comment($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::Comment::Comment>)

Required. The comment to be added.

=back

=head2 Google::Cloud::Support::V2beta::CommentService::GetCommentRequest

The request message for the GetComment endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the comment to retrieve.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Support::V2beta::CommentService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
