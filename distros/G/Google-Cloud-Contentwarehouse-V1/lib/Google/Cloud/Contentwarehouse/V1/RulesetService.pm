package Google::Cloud::Contentwarehouse::V1::RulesetService;

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
    eval { require Google::Cloud::Contentwarehouse::V1::RuleEngine };
    eval { require Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvY29udGVudHdhcmVob3VzZS92MS9ydWxlc2V0X3NlcnZpY2UucHJv
dG8SIGdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxGhxnb29nbGUvYXBpL2Fubm90
YXRpb25zLnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxoyZ29vZ2xlL2Nsb3VkL2Nv
bnRlbnR3YXJlaG91c2UvdjEvcnVsZV9lbmdpbmUucHJvdG8aPmdvb2dsZS9jbG91ZC9jb250
ZW50d2FyZWhvdXNlL3YxL3J1bGVzZXRfc2VydmljZV9yZXF1ZXN0LnByb3RvGhtnb29nbGUv
cHJvdG9idWYvZW1wdHkucHJvdG8y9AcKDlJ1bGVTZXRTZXJ2aWNlEsQBCg1DcmVhdGVSdWxl
U2V0EjYuZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuQ3JlYXRlUnVsZVNldFJl
cXVlc3QaKS5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5SdWxlU2V0IlCC0+ST
AjgiLC92MS97cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L3J1bGVTZXRzOghydWxl
X3NldNpBD3BhcmVudCxydWxlX3NldBKpAQoKR2V0UnVsZVNldBIzLmdvb2dsZS5jbG91ZC5j
b250ZW50d2FyZWhvdXNlLnYxLkdldFJ1bGVTZXRSZXF1ZXN0GikuZ29vZ2xlLmNsb3VkLmNv
bnRlbnR3YXJlaG91c2UudjEuUnVsZVNldCI7gtPkkwIuEiwvdjEve25hbWU9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKi9ydWxlU2V0cy8qfdpBBG5hbWUSuwEKDVVwZGF0ZVJ1bGVTZXQSNi5n
b29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MS5VcGRhdGVSdWxlU2V0UmVxdWVzdBop
Lmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLlJ1bGVTZXQiR4LT5JMCMTIsL3Yx
L3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovcnVsZVNldHMvKn06ASraQQ1uYW1lLHJ1
bGVfc2V0EpwBCg1EZWxldGVSdWxlU2V0EjYuZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91
c2UudjEuRGVsZXRlUnVsZVNldFJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYuRW1wdHkiO4LT
5JMCLiosL3YxL3tuYW1lPXByb2plY3RzLyovbG9jYXRpb25zLyovcnVsZVNldHMvKn3aQQRu
YW1lErwBCgxMaXN0UnVsZVNldHMSNS5nb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52
MS5MaXN0UnVsZVNldHNSZXF1ZXN0GjYuZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2Uu
djEuTGlzdFJ1bGVTZXRzUmVzcG9uc2UiPYLT5JMCLhIsL3YxL3twYXJlbnQ9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKn0vcnVsZVNldHPaQQZwYXJlbnQaU8pBH2NvbnRlbnR3YXJlaG91c2Uu
Z29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3Vk
LXBsYXRmb3JtQvsBCiRjb20uZ29vZ2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjFCE1J1
bGVTZXRTZXJ2aWNlUHJvdG9QAVpQY2xvdWQuZ29vZ2xlLmNvbS9nby9jb250ZW50d2FyZWhv
dXNlL2FwaXYxL2NvbnRlbnR3YXJlaG91c2VwYjtjb250ZW50d2FyZWhvdXNlcGKqAiBHb29n
bGUuQ2xvdWQuQ29udGVudFdhcmVob3VzZS5WMcoCIEdvb2dsZVxDbG91ZFxDb250ZW50V2Fy
ZWhvdXNlXFYx6gIjR29vZ2xlOjpDbG91ZDo6Q29udGVudFdhcmVob3VzZTo6VjFKqw4KBhIE
DgBQAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKQoJCgID
ABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAPAoJCgIDAxIDFQBICgkKAgMEEgMWACUKCAoB
CBIDGAA9CgkKAgglEgMYAD0KCAoBCBIDGQBnCgkKAggLEgMZAGcKCAoBCBIDGgAiCgkKAggK
EgMaACIKCAoBCBIDGwA0CgkKAggIEgMbADQKCAoBCBIDHAA9CgkKAggBEgMcAD0KCAoBCBID
HQA9CgkKAggpEgMdAD0KCAoBCBIDHgA8CgkKAggtEgMeADwKOwoCBgASBCEAUAEaLyBTZXJ2
aWNlIHRvIG1hbmFnZSBjdXN0b21lciBzcGVjaWZpYyBSdWxlU2V0cy4KCgoKAwYAARIDIQgW
CgoKAwYAAxIDIgJHCgwKBQYAA5kIEgMiAkcKCwoDBgADEgQjAiQ3Cg0KBQYAA5oIEgQjAiQ3
CiIKBAYAAgASBCcCLQMaFCBDcmVhdGVzIGEgcnVsZXNldC4KCgwKBQYAAgABEgMnBhMKDAoF
BgACAAISAycUKAoMCgUGAAIAAxIDJzM6Cg0KBQYAAgAEEgQoBCsGChEKCQYAAgAEsMq8IhIE
KAQrBgoMCgUGAAIABBIDLAQ9Cg8KCAYAAgAEmwgAEgMsBD0KUAoEBgACARIEMAI1AxpCIEdl
dHMgYSBydWxlc2V0LiBSZXR1cm5zIE5PVF9GT1VORCBpZiB0aGUgcnVsZXNldCBkb2VzIG5v
dCBleGlzdC4KCgwKBQYAAgEBEgMwBhAKDAoFBgACAQISAzARIgoMCgUGAAIBAxIDMC00Cg0K
BQYAAgEEEgQxBDMGChEKCQYAAgEEsMq8IhIEMQQzBgoMCgUGAAIBBBIDNAQyCg8KCAYAAgEE
mwgAEgM0BDIKigEKBAYAAgISBDkCPwMafCBVcGRhdGVzIGEgcnVsZXNldC4gUmV0dXJucyBJ
TlZBTElEX0FSR1VNRU5UIGlmIHRoZSBuYW1lIG9mIHRoZSBydWxlc2V0CiBpcyBub24tZW1w
dHkgYW5kIGRvZXMgbm90IGVxdWFsIHRoZSBleGlzdGluZyBuYW1lLgoKDAoFBgACAgESAzkG
EwoMCgUGAAICAhIDORQoCgwKBQYAAgIDEgM5MzoKDQoFBgACAgQSBDoEPQYKEQoJBgACAgSw
yrwiEgQ6BD0GCgwKBQYAAgIEEgM+BDsKDwoIBgACAgSbCAASAz4EOwpUCgQGAAIDEgRCAkcD
GkYgRGVsZXRlcyBhIHJ1bGVzZXQuIFJldHVybnMgTk9UX0ZPVU5EIGlmIHRoZSBkb2N1bWVu
dCBkb2VzIG5vdCBleGlzdC4KCgwKBQYAAgMBEgNCBhMKDAoFBgACAwISA0IUKAoMCgUGAAID
AxIDQjNICg0KBQYAAgMEEgRDBEUGChEKCQYAAgMEsMq8IhIEQwRFBgoMCgUGAAIDBBIDRgQy
Cg8KCAYAAgMEmwgAEgNGBDIKHwoEBgACBBIESgJPAxoRIExpc3RzIHJ1bGVzZXRzLgoKDAoF
BgACBAESA0oGEgoMCgUGAAIEAhIDShMmCgwKBQYAAgQDEgNKMUUKDQoFBgACBAQSBEsETQYK
EQoJBgACBASwyrwiEgRLBE0GCgwKBQYAAgQEEgNOBDQKDwoIBgACBASbCAASA04ENGIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Contentwarehouse::V1::RulesetService::RuleSetServiceClient ===
package Google::Cloud::Contentwarehouse::V1::RulesetService::RuleSetServiceClient;

=pod

=head2 Service Client: Google::Cloud::Contentwarehouse::V1::RulesetService::RuleSetServiceClient

Client stub representing the remote C<RuleSetService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<contentwarehouse.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'contentwarehouse.googleapis.com:443' );

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

sub create_rule_set {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::CreateRuleSetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.RuleSetService',
        method         => 'CreateRuleSet',
        request        => $req,
        response_class => 'Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleSet',
    });
}

sub get_rule_set {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::GetRuleSetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.RuleSetService',
        method         => 'GetRuleSet',
        request        => $req,
        response_class => 'Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleSet',
    });
}

sub update_rule_set {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::UpdateRuleSetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.RuleSetService',
        method         => 'UpdateRuleSet',
        request        => $req,
        response_class => 'Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleSet',
    });
}

sub delete_rule_set {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::DeleteRuleSetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.RuleSetService',
        method         => 'DeleteRuleSet',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

sub list_rule_sets {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::ListRuleSetsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.RuleSetService',
        method         => 'ListRuleSets',
        request        => $req,
        response_class => 'Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::ListRuleSetsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Contentwarehouse::V1::RulesetService - Compiled Protocol Buffers messages for google/cloud/contentwarehouse/v1/ruleset_service.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/contentwarehouse/v1/ruleset_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Contentwarehouse::V1::RulesetService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
