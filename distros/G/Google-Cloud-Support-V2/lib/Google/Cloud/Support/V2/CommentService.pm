package Google::Cloud::Support::V2::CommentService;

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
    eval { require Google::Cloud::Support::V2::Comment };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvc3VwcG9ydC92Mi9jb21tZW50X3NlcnZpY2UucHJvdG8SF2dvb2ds
ZS5jbG91ZC5zdXBwb3J0LnYyGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29n
bGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZ
Z29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxolZ29vZ2xlL2Nsb3VkL3N1cHBvcnQvdjIvY29t
bWVudC5wcm90byKTAQoTTGlzdENvbW1lbnRzUmVxdWVzdBJACgZwYXJlbnQYASABKAlCKOBB
AvpBIgogY2xvdWRzdXBwb3J0Lmdvb2dsZWFwaXMuY29tL0Nhc2VSBnBhcmVudBIbCglwYWdl
X3NpemUYBCABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YBSABKAlSCXBhZ2VUb2tlbiJ8
ChRMaXN0Q29tbWVudHNSZXNwb25zZRI8Cghjb21tZW50cxgBIAMoCzIgLmdvb2dsZS5jbG91
ZC5zdXBwb3J0LnYyLkNvbW1lbnRSCGNvbW1lbnRzEiYKD25leHRfcGFnZV90b2tlbhgCIAEo
CVINbmV4dFBhZ2VUb2tlbiKZAQoUQ3JlYXRlQ29tbWVudFJlcXVlc3QSQAoGcGFyZW50GAEg
ASgJQijgQQL6QSIKIGNsb3Vkc3VwcG9ydC5nb29nbGVhcGlzLmNvbS9DYXNlUgZwYXJlbnQS
PwoHY29tbWVudBgCIAEoCzIgLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyLkNvbW1lbnRCA+BB
AlIHY29tbWVudCJUChFHZXRDb21tZW50UmVxdWVzdBI/CgRuYW1lGAEgASgJQivgQQL6QSUK
I2Nsb3Vkc3VwcG9ydC5nb29nbGVhcGlzLmNvbS9Db21tZW50UgRuYW1lMrQFCg5Db21tZW50
U2VydmljZRLXAQoMTGlzdENvbW1lbnRzEiwuZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjIuTGlz
dENvbW1lbnRzUmVxdWVzdBotLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyLkxpc3RDb21tZW50
c1Jlc3BvbnNlImqC0+STAlsSKC92Mi97cGFyZW50PXByb2plY3RzLyovY2FzZXMvKn0vY29t
bWVudHNaLxItL3YyL3twYXJlbnQ9b3JnYW5pemF0aW9ucy8qL2Nhc2VzLyp9L2NvbW1lbnRz
2kEGcGFyZW50EucBCg1DcmVhdGVDb21tZW50Ei0uZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjIu
Q3JlYXRlQ29tbWVudFJlcXVlc3QaIC5nb29nbGUuY2xvdWQuc3VwcG9ydC52Mi5Db21tZW50
IoQBgtPkkwJtIigvdjIve3BhcmVudD1wcm9qZWN0cy8qL2Nhc2VzLyp9L2NvbW1lbnRzOgdj
b21tZW50WjgiLS92Mi97cGFyZW50PW9yZ2FuaXphdGlvbnMvKi9jYXNlcy8qfS9jb21tZW50
czoHY29tbWVudNpBDnBhcmVudCxjb21tZW50EowBCgpHZXRDb21tZW50EiouZ29vZ2xlLmNs
b3VkLnN1cHBvcnQudjIuR2V0Q29tbWVudFJlcXVlc3QaIC5nb29nbGUuY2xvdWQuc3VwcG9y
dC52Mi5Db21tZW50IjCC0+STAiMSIS92Mi97bmFtZT0qLyovY2FzZXMvKi9jb21tZW50cy8q
fdpBBG5hbWUaT8pBG2Nsb3Vkc3VwcG9ydC5nb29nbGVhcGlzLmNvbdJBLmh0dHBzOi8vd3d3
Lmdvb2dsZWFwaXMuY29tL2F1dGgvY2xvdWQtcGxhdGZvcm1CvAEKG2NvbS5nb29nbGUuY2xv
dWQuc3VwcG9ydC52MkITQ29tbWVudFNlcnZpY2VQcm90b1ABWjVjbG91ZC5nb29nbGUuY29t
L2dvL3N1cHBvcnQvYXBpdjIvc3VwcG9ydHBiO3N1cHBvcnRwYqoCF0dvb2dsZS5DbG91ZC5T
dXBwb3J0LlYyygIXR29vZ2xlXENsb3VkXFN1cHBvcnRcVjLqAhpHb29nbGU6OkNsb3VkOjpT
dXBwb3J0OjpWMkqYHQoHEgUOAJoBAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAIAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxID
FQAjCgkKAgMEEgMWAC8KCAoBCBIDGAA0CgkKAgglEgMYADQKCAoBCBIDGQBMCgkKAggLEgMZ
AEwKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwA0CgkKAggIEgMbADQKCAoBCBIDHAA0
CgkKAggBEgMcADQKCAoBCBIDHQA0CgkKAggpEgMdADQKCAoBCBIDHgAzCgkKAggtEgMeADMK
NAoCBgASBCEAZAEaKCBBIHNlcnZpY2UgdG8gbWFuYWdlIGNvbW1lbnRzIG9uIGNhc2VzLgoK
CgoDBgABEgMhCBYKCgoDBgADEgMiAkMKDAoFBgADmQgSAyICQwoLCgMGAAMSBCMCJDcKDQoF
BgADmggSBCMCJDcKPQoEBgACABIEJwIvAxovIExpc3QgYWxsIHRoZSBjb21tZW50cyBhc3Nv
Y2lhdGVkIHdpdGggYSBjYXNlLgoKDAoFBgACAAESAycGEgoMCgUGAAIAAhIDJxMmCgwKBQYA
AgADEgMnMUUKDQoFBgACAAQSBCgELQYKEQoJBgACAASwyrwiEgQoBC0GCgwKBQYAAgAEEgMu
BDQKDwoIBgACAASbCAASAy4ENApmCgQGAAIBEgQ0Aj4DGlggQWRkIGEgbmV3IGNvbW1lbnQg
dG8gYSBjYXNlLgoKIFRoZSBjb21tZW50IG11c3QgaGF2ZSB0aGUgZm9sbG93aW5nIGZpZWxk
cyBzZXQ6IGBib2R5YC4KCgwKBQYAAgEBEgM0BhMKDAoFBgACAQISAzQUKAoMCgUGAAIBAxID
NDM6Cg0KBQYAAgEEEgQ1BDwGChEKCQYAAgEEsMq8IhIENQQ8BgoMCgUGAAIBBBIDPQQ8Cg8K
CAYAAgEEmwgAEgM9BDwK1QUKBAYAAgISBF4CYwMaxgUgUmV0cmlldmUgYSBjb21tZW50LgoK
IEVYQU1QTEVTOgoKIGNVUkw6CgogYGBgc2hlbGwKIGNvbW1lbnQ9InByb2plY3RzL3NvbWUt
cHJvamVjdC9jYXNlcy80MzU5NTM0NC9jb21tZW50cy8yMzQ1Njc4OTAiCiBjdXJsIFwKICAg
LS1oZWFkZXIgIkF1dGhvcml6YXRpb246IEJlYXJlciAkKGdjbG91ZCBhdXRoIHByaW50LWFj
Y2Vzcy10b2tlbikiIFwKICAgImh0dHBzOi8vY2xvdWRzdXBwb3J0Lmdvb2dsZWFwaXMuY29t
L3YyLyRjb21tZW50IgogYGBgCgogUHl0aG9uOgoKIGBgYHB5dGhvbgogaW1wb3J0IGdvb2ds
ZWFwaWNsaWVudC5kaXNjb3ZlcnkKCiBhcGlfdmVyc2lvbiA9ICJ2MiIKIHN1cHBvcnRBcGlT
ZXJ2aWNlID0gZ29vZ2xlYXBpY2xpZW50LmRpc2NvdmVyeS5idWlsZCgKICAgICBzZXJ2aWNl
TmFtZT0iY2xvdWRzdXBwb3J0IiwKICAgICB2ZXJzaW9uPWFwaV92ZXJzaW9uLAogICAgIGRp
c2NvdmVyeVNlcnZpY2VVcmw9ZiJodHRwczovL2Nsb3Vkc3VwcG9ydC5nb29nbGVhcGlzLmNv
bS8kZGlzY292ZXJ5L3Jlc3Q/dmVyc2lvbj17YXBpX3ZlcnNpb259IiwKICkKCiByZXF1ZXN0
ID0gc3VwcG9ydEFwaVNlcnZpY2UuY2FzZXMoKS5jb21tZW50cygpLmdldCgKICAgICBuYW1l
PSJwcm9qZWN0cy9zb21lLXByb2plY3QvY2FzZXMvNDM1OTUzNDQvY29tbWVudHMvMjM0NTY3
ODkwIiwKICkKIHByaW50KHJlcXVlc3QuZXhlY3V0ZSgpKQogYGBgCgoMCgUGAAICARIDXgYQ
CgwKBQYAAgICEgNeESIKDAoFBgACAgMSA14tNAoNCgUGAAICBBIEXwRhBgoRCgkGAAICBLDK
vCISBF8EYQYKDAoFBgACAgQSA2IEMgoPCggGAAICBJsIABIDYgQyCkAKAgQAEgRnAHYBGjQg
VGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IgdGhlIExpc3RDb21tZW50cyBlbmRwb2ludC4KCgoK
AwQAARIDZwgbCkoKBAQAAgASBGkCbgQaPCBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGNh
c2UgZm9yIHdoaWNoIHRvIGxpc3QgY29tbWVudHMuCgoMCgUEAAIABRIDaQIICgwKBQQAAgAB
EgNpCQ8KDAoFBAACAAMSA2kSEwoNCgUEAAIACBIEaRRuAwoPCggEAAIACJwIABIDagQqCg8K
BwQAAgAInwgSBGsEbQUKRwoEBAACARIDcQIWGjogVGhlIG1heGltdW0gbnVtYmVyIG9mIGNv
bW1lbnRzIHRvIGZldGNoLiBEZWZhdWx0cyB0byAxMC4KCgwKBQQAAgEFEgNxAgcKDAoFBAAC
AQESA3EIEQoMCgUEAAIBAxIDcRQVCm4KBAQAAgISA3UCGBphIEEgdG9rZW4gaWRlbnRpZnlp
bmcgdGhlIHBhZ2Ugb2YgcmVzdWx0cyB0byByZXR1cm4uIElmIHVuc3BlY2lmaWVkLCB0aGUK
IGZpcnN0IHBhZ2UgaXMgcmV0dXJuZWQuCgoMCgUEAAICBRIDdQIICgwKBQQAAgIBEgN1CRMK
DAoFBAACAgMSA3UWFwpCCgIEARIFeQCBAQEaNSBUaGUgcmVzcG9uc2UgbWVzc2FnZSBmb3Ig
dGhlIExpc3RDb21tZW50cyBlbmRwb2ludC4KCgoKAwQBARIDeQgcCj0KBAQBAgASA3sCIBow
IExpc3Qgb2YgdGhlIGNvbW1lbnRzIGFzc29jaWF0ZWQgd2l0aCB0aGUgY2FzZS4KCgwKBQQB
AgAEEgN7AgoKDAoFBAECAAYSA3sLEgoMCgUEAQIAARIDexMbCgwKBQQBAgADEgN7Hh8KyAEK
BAQBAgESBIABAh0auQEgQSB0b2tlbiB0byByZXRyaWV2ZSB0aGUgbmV4dCBwYWdlIG9mIHJl
c3VsdHMuIFNldCB0aGlzIGluIHRoZSBgcGFnZV90b2tlbmAKIGZpZWxkIG9mIHN1YnNlcXVl
bnQgYGNhc2VzLmNvbW1lbnRzLmxpc3RgIHJlcXVlc3RzLiBJZiB1bnNwZWNpZmllZCwgdGhl
cmUKIGFyZSBubyBtb3JlIHJlc3VsdHMgdG8gcmV0cmlldmUuCgoNCgUEAQIBBRIEgAECCAoN
CgUEAQIBARIEgAEJGAoNCgUEAQIBAxIEgAEbHApDCgIEAhIGhAEAjwEBGjUgVGhlIHJlcXVl
c3QgbWVzc2FnZSBmb3IgdGhlIENyZWF0ZUNvbW1lbnQgZW5kcG9pbnQuCgoLCgMEAgESBIQB
CBwKVgoEBAICABIGhgECiwEEGkYgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBjYXNlIHRv
IHdoaWNoIHRoZSBjb21tZW50IHNob3VsZCBiZSBhZGRlZC4KCg0KBQQCAgAFEgSGAQIICg0K
BQQCAgABEgSGAQkPCg0KBQQCAgADEgSGARITCg8KBQQCAgAIEgaGARSLAQMKEAoIBAICAAic
CAASBIcBBCoKEQoHBAICAAifCBIGiAEEigEFCjIKBAQCAgESBI4BAj8aJCBSZXF1aXJlZC4g
VGhlIGNvbW1lbnQgdG8gYmUgYWRkZWQuCgoNCgUEAgIBBhIEjgECCQoNCgUEAgIBARIEjgEK
EQoNCgUEAgIBAxIEjgEUFQoNCgUEAgIBCBIEjgEWPgoQCggEAgIBCJwIABIEjgEXPQpACgIE
AxIGkgEAmgEBGjIgVGhlIHJlcXVlc3QgbWVzc2FnZSBmb3IgdGhlIEdldENvbW1lbnQgZW5k
cG9pbnQuCgoLCgMEAwESBJIBCBkKQAoEBAMCABIGlAECmQEEGjAgUmVxdWlyZWQuIFRoZSBu
YW1lIG9mIHRoZSBjb21tZW50IHRvIHJldHJpZXZlLgoKDQoFBAMCAAUSBJQBAggKDQoFBAMC
AAESBJQBCQ0KDQoFBAMCAAMSBJQBEBEKDwoFBAMCAAgSBpQBEpkBAwoQCggEAwIACJwIABIE
lQEEKgoRCgcEAwIACJ8IEgaWAQSYAQViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Support::V2::CommentService::ListCommentsRequest ===
    # Fields for ListCommentsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Support::V2::CommentService::ListCommentsResponse ===
    # Fields for ListCommentsResponse
    # Field: comments Type: 11 (.google.cloud.support.v2.Comment)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Support::V2::CommentService::CreateCommentRequest ===
    # Fields for CreateCommentRequest
    # Field: parent Type: 9 ()
    # Field: comment Type: 11 (.google.cloud.support.v2.Comment)

# === Message: Google::Cloud::Support::V2::CommentService::GetCommentRequest ===
    # Fields for GetCommentRequest
    # Field: name Type: 9 ()

# === Service Client: Google::Cloud::Support::V2::CommentService::CommentServiceClient ===
package Google::Cloud::Support::V2::CommentService::CommentServiceClient;

=pod

=head2 Service Client: Google::Cloud::Support::V2::CommentService::CommentServiceClient

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
        ? Google::Cloud::Support::V2::CommentService::ListCommentsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2.CommentService',
        method         => 'ListComments',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2::CommentService::ListCommentsResponse',
    });
}

sub create_comment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2::CommentService::CreateCommentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2.CommentService',
        method         => 'CreateComment',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2::Comment::Comment',
    });
}

sub get_comment {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Support::V2::CommentService::GetCommentRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.support.v2.CommentService',
        method         => 'GetComment',
        request        => $req,
        response_class => 'Google::Cloud::Support::V2::Comment::Comment',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Support::V2::CommentService - Compiled Protocol Buffers messages for google/cloud/support/v2/comment_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Support::V2::CommentService;

    my $msg = Google::Cloud::Support::V2::CommentService::ListCommentsRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Support::V2::CommentService::ListCommentsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/support/v2/comment_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Support::V2::CommentService::ListCommentsRequest

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

=head2 Google::Cloud::Support::V2::CommentService::ListCommentsResponse

The response message for the ListComments endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->comments() >> / C<< $msg->comments($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2::Comment::Comment>)

List of the comments associated with the case.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token to retrieve the next page of results. Set this in the `page_token`
field of subsequent `cases.comments.list` requests. If unspecified, there
are no more results to retrieve.

=back

=head2 Google::Cloud::Support::V2::CommentService::CreateCommentRequest

The request message for the CreateComment endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The name of the case to which the comment should be added.

=item * C<< $msg->comment() >> / C<< $msg->comment($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2::Comment::Comment>)

Required. The comment to be added.

=back

=head2 Google::Cloud::Support::V2::CommentService::GetCommentRequest

The request message for the GetComment endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the comment to retrieve.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Support::V2::CommentService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
