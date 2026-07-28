package Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions;

use strict;
use warnings;

our $VERSION = '0.11';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Type::Date };
    my $descriptor_b64 = <<'EOF';
CkJnb29nbGUvY2xvdWQvb3JjaGVzdHJhdGlvbi9haXJmbG93L3NlcnZpY2UvdjEvaW1hZ2Vf
dmVyc2lvbnMucHJvdG8SLWdvb2dsZS5jbG91ZC5vcmNoZXN0cmF0aW9uLmFpcmZsb3cuc2Vy
dmljZS52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGll
bnQucHJvdG8aFmdvb2dsZS90eXBlL2RhdGUucHJvdG8iogEKGExpc3RJbWFnZVZlcnNpb25z
UmVxdWVzdBIWCgZwYXJlbnQYASABKAlSBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBh
Z2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbhIyChVpbmNsdWRlX3Bhc3Rf
cmVsZWFzZXMYBCABKAhSE2luY2x1ZGVQYXN0UmVsZWFzZXMipwEKGUxpc3RJbWFnZVZlcnNp
b25zUmVzcG9uc2USYgoOaW1hZ2VfdmVyc2lvbnMYASADKAsyOy5nb29nbGUuY2xvdWQub3Jj
aGVzdHJhdGlvbi5haXJmbG93LnNlcnZpY2UudjEuSW1hZ2VWZXJzaW9uUg1pbWFnZVZlcnNp
b25zEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbiKhAgoMSW1hZ2VW
ZXJzaW9uEigKEGltYWdlX3ZlcnNpb25faWQYASABKAlSDmltYWdlVmVyc2lvbklkEh0KCmlz
X2RlZmF1bHQYAiABKAhSCWlzRGVmYXVsdBI6ChlzdXBwb3J0ZWRfcHl0aG9uX3ZlcnNpb25z
GAMgAygJUhdzdXBwb3J0ZWRQeXRob25WZXJzaW9ucxI0CgxyZWxlYXNlX2RhdGUYBCABKAsy
ES5nb29nbGUudHlwZS5EYXRlUgtyZWxlYXNlRGF0ZRIrChFjcmVhdGlvbl9kaXNhYmxlZBgF
IAEoCFIQY3JlYXRpb25EaXNhYmxlZBIpChB1cGdyYWRlX2Rpc2FibGVkGAYgASgIUg91cGdy
YWRlRGlzYWJsZWQyyQIKDUltYWdlVmVyc2lvbnMS6gEKEUxpc3RJbWFnZVZlcnNpb25zEkcu
Z29vZ2xlLmNsb3VkLm9yY2hlc3RyYXRpb24uYWlyZmxvdy5zZXJ2aWNlLnYxLkxpc3RJbWFn
ZVZlcnNpb25zUmVxdWVzdBpILmdvb2dsZS5jbG91ZC5vcmNoZXN0cmF0aW9uLmFpcmZsb3cu
c2VydmljZS52MS5MaXN0SW1hZ2VWZXJzaW9uc1Jlc3BvbnNlIkKC0+STAjMSMS92MS97cGFy
ZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L2ltYWdlVmVyc2lvbnPaQQZwYXJlbnQaS8pB
F2NvbXBvc2VyLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20v
YXV0aC9jbG91ZC1wbGF0Zm9ybUKCAQoxY29tLmdvb2dsZS5jbG91ZC5vcmNoZXN0cmF0aW9u
LmFpcmZsb3cuc2VydmljZS52MVABWktjbG91ZC5nb29nbGUuY29tL2dvL29yY2hlc3RyYXRp
b24vYWlyZmxvdy9zZXJ2aWNlL2FwaXYxL3NlcnZpY2VwYjtzZXJ2aWNlcGJKxRUKBhIEDgBZ
AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAANgoJCgIDABID
EgAmCgkKAgMBEgMTACEKCQoCAwISAxQAIAoICgEIEgMWAGIKCQoCCAsSAxYAYgoICgEIEgMX
ACIKCQoCCAoSAxcAIgoICgEIEgMYAEoKCQoCCAESAxgASgpACgIGABIEGwAoARo0IFJlYWRv
bmx5IHNlcnZpY2UgdG8gcXVlcnkgYXZhaWxhYmxlIEltYWdlVmVyc2lvbnMuCgoKCgMGAAES
AxsIFQoKCgMGAAMSAxwCPwoMCgUGAAOZCBIDHAI/CgsKAwYAAxIEHQIeNwoNCgUGAAOaCBIE
HQIeNwo5CgQGAAIAEgQhAicDGisgTGlzdCBJbWFnZVZlcnNpb25zIGZvciBwcm92aWRlZCBs
b2NhdGlvbi4KCgwKBQYAAgABEgMhBhcKDAoFBgACAAISAyEYMAoMCgUGAAIAAxIDIg8oCg0K
BQYAAgAEEgQjBCUGChEKCQYAAgAEsMq8IhIEIwQlBgoMCgUGAAIABBIDJgQ0Cg8KCAYAAgAE
mwgAEgMmBDQKOwoCBAASBCsAOAEaLyBMaXN0IEltYWdlVmVyc2lvbnMgaW4gYSBwcm9qZWN0
IGFuZCBsb2NhdGlvbi4KCgoKAwQAARIDKwggCoABCgQEAAIAEgMuAhQacyBMaXN0IEltYWdl
VmVyc2lvbnMgaW4gdGhlIGdpdmVuIHByb2plY3QgYW5kIGxvY2F0aW9uLCBpbiB0aGUgZm9y
bToKICJwcm9qZWN0cy97cHJvamVjdElkfS9sb2NhdGlvbnMve2xvY2F0aW9uSWR9IgoKDAoF
BAACAAUSAy4CCAoMCgUEAAIAARIDLgkPCgwKBQQAAgADEgMuEhMKPgoEBAACARIDMQIWGjEg
VGhlIG1heGltdW0gbnVtYmVyIG9mIGltYWdlX3ZlcnNpb25zIHRvIHJldHVybi4KCgwKBQQA
AgEFEgMxAgcKDAoFBAACAQESAzEIEQoMCgUEAAIBAxIDMRQVClcKBAQAAgISAzQCGBpKIFRo
ZSBuZXh0X3BhZ2VfdG9rZW4gdmFsdWUgcmV0dXJuZWQgZnJvbSBhIHByZXZpb3VzIExpc3Qg
cmVxdWVzdCwgaWYgYW55LgoKDAoFBAACAgUSAzQCCAoMCgUEAAICARIDNAkTCgwKBQQAAgID
EgM0FhcKUgoEBAACAxIDNwIhGkUgV2hldGhlciBvciBub3QgaW1hZ2UgdmVyc2lvbnMgZnJv
bSBvbGQgcmVsZWFzZXMgc2hvdWxkIGJlIGluY2x1ZGVkLgoKDAoFBAACAwUSAzcCBgoMCgUE
AAIDARIDNwccCgwKBQQAAgMDEgM3HyAKOgoCBAESBDsAQQEaLiBUaGUgSW1hZ2VWZXJzaW9u
cyBpbiBhIHByb2plY3QgYW5kIGxvY2F0aW9uLgoKCgoDBAEBEgM7CCEKQQoEBAECABIDPQIr
GjQgVGhlIGxpc3Qgb2Ygc3VwcG9ydGVkIEltYWdlVmVyc2lvbnMgaW4gYSBsb2NhdGlvbi4K
CgwKBQQBAgAEEgM9AgoKDAoFBAECAAYSAz0LFwoMCgUEAQIAARIDPRgmCgwKBQQBAgADEgM9
KSoKTAoEBAECARIDQAIdGj8gVGhlIHBhZ2UgdG9rZW4gdXNlZCB0byBxdWVyeSBmb3IgdGhl
IG5leHQgcGFnZSBpZiBvbmUgZXhpc3RzLgoKDAoFBAECAQUSA0ACCAoMCgUEAQIBARIDQAkY
CgwKBQQBAgEDEgNAGxwKJgoCBAISBEQAWQEaGiBJbWFnZVZlcnNpb24gaW5mb3JtYXRpb24K
CgoKAwQCARIDRAgUCmYKBAQCAgASA0cCHhpZIFRoZSBzdHJpbmcgaWRlbnRpZmllciBvZiB0
aGUgSW1hZ2VWZXJzaW9uLCBpbiB0aGUgZm9ybToKICJjb21wb3Nlci14Lnkuei1haXJmbG93
LWEuYi5jIgoKDAoFBAICAAUSA0cCCAoMCgUEAgIAARIDRwkZCgwKBQQCAgADEgNHHB0KjAEK
BAQCAgESA0sCFhp/IFdoZXRoZXIgdGhpcyBpcyB0aGUgZGVmYXVsdCBJbWFnZVZlcnNpb24g
dXNlZCBieSBDb21wb3NlciBkdXJpbmcKIGVudmlyb25tZW50IGNyZWF0aW9uIGlmIG5vIGlu
cHV0IEltYWdlVmVyc2lvbiBpcyBzcGVjaWZpZWQuCgoMCgUEAgIBBRIDSwIGCgwKBQQCAgEB
EgNLBxEKDAoFBAICAQMSA0sUFQooCgQEAgICEgNOAjAaGyBzdXBwb3J0ZWQgcHl0aG9uIHZl
cnNpb25zCgoMCgUEAgICBBIDTgIKCgwKBQQCAgIFEgNOCxEKDAoFBAICAgESA04SKwoMCgUE
AgICAxIDTi4vCi8KBAQCAgMSA1ECJBoiIFRoZSBkYXRlIG9mIHRoZSB2ZXJzaW9uIHJlbGVh
c2UuCgoMCgUEAgIDBhIDUQISCgwKBQQCAgMBEgNREx8KDAoFBAICAwMSA1EiIwpYCgQEAgIE
EgNUAh0aSyBXaGV0aGVyIGl0IGlzIGltcG9zc2libGUgdG8gY3JlYXRlIGFuIGVudmlyb25t
ZW50IHdpdGggdGhlIGltYWdlIHZlcnNpb24uCgoMCgUEAgIEBRIDVAIGCgwKBQQCAgQBEgNU
BxgKDAoFBAICBAMSA1QbHApiCgQEAgIFEgNYAhwaVSBXaGV0aGVyIGl0IGlzIGltcG9zc2li
bGUgdG8gdXBncmFkZSBhbiBlbnZpcm9ubWVudCBydW5uaW5nIHdpdGggdGhlIGltYWdlCiB2
ZXJzaW9uLgoKDAoFBAICBQUSA1gCBgoMCgUEAgIFARIDWAcXCgwKBQQCAgUDEgNYGhtiBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::ListImageVersionsRequest ===
    # Fields for ListImageVersionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: include_past_releases Type: 8 ()

=pod

=head1 NAME

Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::ListImageVersionsRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions;

    my $msg = Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::ListImageVersionsRequest->new(
        parent => $value,
    );

=head1 FIELDS

=over 4

=item * B<parent>

Type: String

=item * B<page_size>

Type: Int32

=item * B<page_token>

Type: String

=item * B<include_past_releases>

Type: Bool

=back

=cut

# === Message: Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::ListImageVersionsResponse ===
    # Fields for ListImageVersionsResponse
    # Field: image_versions Type: 11 (.google.cloud.orchestration.airflow.service.v1.ImageVersion)
    # Field: next_page_token Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::ListImageVersionsResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions;

    my $msg = Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::ListImageVersionsResponse->new(
        image_versions => $value,
    );

=head1 FIELDS

=over 4

=item * B<image_versions>

Type: Message (.google.cloud.orchestration.airflow.service.v1.ImageVersion)

=item * B<next_page_token>

Type: String

=back

=cut

# === Message: Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::ImageVersion ===
    # Fields for ImageVersion
    # Field: image_version_id Type: 9 ()
    # Field: is_default Type: 8 ()
    # Field: supported_python_versions Type: 9 ()
    # Field: release_date Type: 11 (.google.type.Date)
    # Field: creation_disabled Type: 8 ()
    # Field: upgrade_disabled Type: 8 ()

=pod

=head1 NAME

Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::ImageVersion - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions;

    my $msg = Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::ImageVersion->new(
        image_version_id => $value,
    );

=head1 FIELDS

=over 4

=item * B<image_version_id>

Type: String

=item * B<is_default>

Type: Bool

=item * B<supported_python_versions>

Type: String

=item * B<release_date>

Type: Message (.google.type.Date)

=item * B<creation_disabled>

Type: Bool

=item * B<upgrade_disabled>

Type: Bool

=back

=cut

# === Service Client: Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::ImageVersionsClient ===
package Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::ImageVersionsClient;

=pod

=head1 NAME

Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::ImageVersionsClient - Client stub representing the remote ImageVersions service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<orchestration.googleapis.com:443>.

=head2 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'orchestration.googleapis.com:443' );

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

sub list_image_versions {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::ListImageVersionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.orchestration.airflow.service.v1.ImageVersions',
        method         => 'ListImageVersions',
        request        => $req,
        response_class => 'Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions::ListImageVersionsResponse',
    });
}

1;

__END__

=head1 NAME

Google::Cloud::Orchestration::Airflow::Service::V1::ImageVersions - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
