package Google::Cloud::Contentwarehouse::V1::PipelineService;

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
    eval { require Google::Cloud::Contentwarehouse::V1::Common };
    eval { require Google::Cloud::Contentwarehouse::V1::Pipelines };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvY29udGVudHdhcmVob3VzZS92MS9waXBlbGluZV9zZXJ2aWNlLnBy
b3RvEiBnb29nbGUuY2xvdWQuY29udGVudHdhcmVob3VzZS52MRocZ29vZ2xlL2FwaS9hbm5v
dGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aLWdvb2dsZS9j
bG91ZC9jb250ZW50d2FyZWhvdXNlL3YxL2NvbW1vbi5wcm90bxowZ29vZ2xlL2Nsb3VkL2Nv
bnRlbnR3YXJlaG91c2UvdjEvcGlwZWxpbmVzLnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcv
b3BlcmF0aW9ucy5wcm90byK3BQoSUnVuUGlwZWxpbmVSZXF1ZXN0EkQKBG5hbWUYASABKAlC
MOBBAvpBKgooY29udGVudHdhcmVob3VzZS5nb29nbGVhcGlzLmNvbS9Mb2NhdGlvblIEbmFt
ZRJlChNnY3NfaW5nZXN0X3BpcGVsaW5lGAIgASgLMjMuZ29vZ2xlLmNsb3VkLmNvbnRlbnR3
YXJlaG91c2UudjEuR2NzSW5nZXN0UGlwZWxpbmVIAFIRZ2NzSW5nZXN0UGlwZWxpbmUSogEK
Kmdjc19pbmdlc3Rfd2l0aF9kb2NfYWlfcHJvY2Vzc29yc19waXBlbGluZRgDIAEoCzJGLmdv
b2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxLkdjc0luZ2VzdFdpdGhEb2NBaVByb2Nl
c3NvcnNQaXBlbGluZUgAUiRnY3NJbmdlc3RXaXRoRG9jQWlQcm9jZXNzb3JzUGlwZWxpbmUS
ZwoTZXhwb3J0X2Nkd19waXBlbGluZRgEIAEoCzI1Lmdvb2dsZS5jbG91ZC5jb250ZW50d2Fy
ZWhvdXNlLnYxLkV4cG9ydFRvQ2R3UGlwZWxpbmVIAFIRZXhwb3J0Q2R3UGlwZWxpbmUSfAoc
cHJvY2Vzc193aXRoX2RvY19haV9waXBlbGluZRgFIAEoCzI6Lmdvb2dsZS5jbG91ZC5jb250
ZW50d2FyZWhvdXNlLnYxLlByb2Nlc3NXaXRoRG9jQWlQaXBlbGluZUgAUhhwcm9jZXNzV2l0
aERvY0FpUGlwZWxpbmUSXAoQcmVxdWVzdF9tZXRhZGF0YRgGIAEoCzIxLmdvb2dsZS5jbG91
ZC5jb250ZW50d2FyZWhvdXNlLnYxLlJlcXVlc3RNZXRhZGF0YVIPcmVxdWVzdE1ldGFkYXRh
QgoKCHBpcGVsaW5lMrkCCg9QaXBlbGluZVNlcnZpY2US0AEKC1J1blBpcGVsaW5lEjQuZ29v
Z2xlLmNsb3VkLmNvbnRlbnR3YXJlaG91c2UudjEuUnVuUGlwZWxpbmVSZXF1ZXN0Gh0uZ29v
Z2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiJsgtPkkwIyIi0vdjEve25hbWU9cHJvamVjdHMv
Ki9sb2NhdGlvbnMvKn06cnVuUGlwZWxpbmU6ASraQQRuYW1lykEqChNSdW5QaXBlbGluZVJl
c3BvbnNlEhNSdW5QaXBlbGluZU1ldGFkYXRhGlPKQR9jb250ZW50d2FyZWhvdXNlLmdvb2ds
ZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0
Zm9ybUL8AQokY29tLmdvb2dsZS5jbG91ZC5jb250ZW50d2FyZWhvdXNlLnYxQhRQaXBlbGlu
ZVNlcnZpY2VQcm90b1ABWlBjbG91ZC5nb29nbGUuY29tL2dvL2NvbnRlbnR3YXJlaG91c2Uv
YXBpdjEvY29udGVudHdhcmVob3VzZXBiO2NvbnRlbnR3YXJlaG91c2VwYqoCIEdvb2dsZS5D
bG91ZC5Db250ZW50V2FyZWhvdXNlLlYxygIgR29vZ2xlXENsb3VkXENvbnRlbnRXYXJlaG91
c2VcVjHqAiNHb29nbGU6OkNsb3VkOjpDb250ZW50V2FyZWhvdXNlOjpWMUqkEQoGEgQOAFYB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAApCgkKAgMAEgMS
ACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoCAwQSAxYANwoJCgIDBRID
FwA6CgkKAgMGEgMYAC0KCAoBCBIDGgA9CgkKAgglEgMaAD0KCAoBCBIDGwBnCgkKAggLEgMb
AGcKCAoBCBIDHAAiCgkKAggKEgMcACIKCAoBCBIDHQA1CgkKAggIEgMdADUKCAoBCBIDHgA9
CgkKAggBEgMeAD0KCAoBCBIDHwA9CgkKAggpEgMfAD0KCAoBCBIDIAA8CgkKAggtEgMgADwK
NQoCBgASBCMANAEaKSBUaGlzIHNlcnZpY2UgbGV0cyB5b3UgbWFuYWdlIHBpcGVsaW5lcy4K
CgoKAwYAARIDIwgXCgoKAwYAAxIDJAJHCgwKBQYAA5kIEgMkAkcKCwoDBgADEgQlAiY3Cg0K
BQYAA5oIEgQlAiY3CioKBAYAAgASBCkCMwMaHCBSdW4gYSBwcmVkZWZpbmVkIHBpcGVsaW5l
LgoKDAoFBgACAAESAykGEQoMCgUGAAIAAhIDKRIkCgwKBQYAAgADEgMpL0sKDQoFBgACAAQS
BCoELQYKEQoJBgACAASwyrwiEgQqBC0GCgwKBQYAAgAEEgMuBDIKDwoIBgACAASbCAASAy4E
MgoNCgUGAAIABBIELwQyBgoPCgcGAAIABJkIEgQvBDIGCj4KAgQAEgQ3AFYBGjIgUmVxdWVz
dCBtZXNzYWdlIGZvciBEb2N1bWVudFNlcnZpY2UuUnVuUGlwZWxpbmUuCgoKCgMEAAESAzcI
GgqPAQoEBAACABIEOgI/BBqAASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgd2hpY2gg
b3ducyB0aGUgcmVzb3VyY2VzIG9mIHRoZSBwaXBlbGluZS4KIEZvcm1hdDogcHJvamVjdHMv
e3Byb2plY3RfbnVtYmVyfS9sb2NhdGlvbnMve2xvY2F0aW9ufS4KCgwKBQQAAgAFEgM6AggK
DAoFBAACAAESAzoJDQoMCgUEAAIAAxIDOhARCg0KBQQAAgAIEgQ6Ej8DCg8KCAQAAgAInAgA
EgM7BCoKDwoHBAACAAifCBIEPAQ+BQopCgQEAAgAEgRCAlEDGhsgVGhlIHByZWRlZmluZWQg
cGlwZWxpbmVzLgoKDAoFBAAIAAESA0IIEAowCgQEAAIBEgNEBC4aIyBDbG91ZCBTdG9yYWdl
IGluZ2VzdGlvbiBwaXBlbGluZS4KCgwKBQQAAgEGEgNEBBUKDAoFBAACAQESA0QWKQoMCgUE
AAIBAxIDRCwtCnIKBAQAAgISBEgESTcaZCBVc2UgRG9jQUkgcHJvY2Vzc29ycyB0byBwcm9j
ZXNzIGRvY3VtZW50cyBpbiBDbG91ZCBTdG9yYWdlIGFuZCBpbmdlc3QKIHRoZW0gdG8gRG9j
dW1lbnQgV2FyZWhvdXNlLgoKDAoFBAACAgYSA0gEKAoMCgUEAAICARIDSQgyCgwKBQQAAgID
EgNJNTYKVAoEBAACAxIDTAQwGkcgRXhwb3J0IGRvY3VlbW50cyBmcm9tIERvY3VtZW50IFdh
cmVob3VzZSB0byBDRFcgZm9yIHRyYWluaW5nIHB1cnBvc2UuCgoMCgUEAAIDBhIDTAQXCgwK
BQQAAgMBEgNMGCsKDAoFBAACAwMSA0wuLwqMAQoEBAACBBIDUAQ+Gn8gVXNlIGEgRG9jQUkg
cHJvY2Vzc29yIHRvIHByb2Nlc3MgZG9jdW1lbnRzIGluIERvY3VtZW50IFdhcmVob3VzZSwg
YW5kCiByZS1pbmdlc3QgdGhlIHVwZGF0ZWQgcmVzdWx0cyBpbnRvIERvY3VtZW50IFdhcmVo
b3VzZS4KCgwKBQQAAgQGEgNQBBwKDAoFBAACBAESA1AdOQoMCgUEAAIEAxIDUDw9CnIKBAQA
AgUSA1UCJxplIFRoZSBtZXRhIGluZm9ybWF0aW9uIGNvbGxlY3RlZCBhYm91dCB0aGUgZW5k
IHVzZXIsIHVzZWQgdG8gZW5mb3JjZSBhY2Nlc3MKIGNvbnRyb2wgZm9yIHRoZSBzZXJ2aWNl
LgoKDAoFBAACBQYSA1UCEQoMCgUEAAIFARIDVRIiCgwKBQQAAgUDEgNVJSZiBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Contentwarehouse::V1::PipelineService::RunPipelineRequest ===
    # Fields for RunPipelineRequest
    # Field: name Type: 9 ()
    # Field: gcs_ingest_pipeline Type: 11 (.google.cloud.contentwarehouse.v1.GcsIngestPipeline)
    # Field: gcs_ingest_with_doc_ai_processors_pipeline Type: 11 (.google.cloud.contentwarehouse.v1.GcsIngestWithDocAiProcessorsPipeline)
    # Field: export_cdw_pipeline Type: 11 (.google.cloud.contentwarehouse.v1.ExportToCdwPipeline)
    # Field: process_with_doc_ai_pipeline Type: 11 (.google.cloud.contentwarehouse.v1.ProcessWithDocAiPipeline)
    # Field: request_metadata Type: 11 (.google.cloud.contentwarehouse.v1.RequestMetadata)

# === Service Client: Google::Cloud::Contentwarehouse::V1::PipelineService::PipelineServiceClient ===
package Google::Cloud::Contentwarehouse::V1::PipelineService::PipelineServiceClient;

=pod

=head2 Service Client: Google::Cloud::Contentwarehouse::V1::PipelineService::PipelineServiceClient

Client stub representing the remote C<PipelineService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub run_pipeline {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Contentwarehouse::V1::PipelineService::RunPipelineRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.contentwarehouse.v1.PipelineService',
        method         => 'RunPipeline',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Contentwarehouse::V1::PipelineService - Compiled Protocol Buffers messages for google/cloud/contentwarehouse/v1/pipeline_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Contentwarehouse::V1::PipelineService;

    my $msg = Google::Cloud::Contentwarehouse::V1::PipelineService::RunPipelineRequest->new({
        name => $name,
        gcs_ingest_pipeline => $gcs_ingest_pipeline,
        gcs_ingest_with_doc_ai_processors_pipeline => $gcs_ingest_with_doc_ai_processors_pipeline,
        export_cdw_pipeline => $export_cdw_pipeline,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Contentwarehouse::V1::PipelineService::RunPipelineRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/contentwarehouse/v1/pipeline_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Contentwarehouse::V1::PipelineService::RunPipelineRequest

Request message for DocumentService.RunPipeline.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name which owns the resources of the pipeline.
Format: projects/{project_number}/locations/{location}.

=item * C<< $msg->gcs_ingest_pipeline() >> / C<< $msg->gcs_ingest_pipeline($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Pipelines::GcsIngestPipeline>)

Cloud Storage ingestion pipeline.

=item * C<< $msg->gcs_ingest_with_doc_ai_processors_pipeline() >> / C<< $msg->gcs_ingest_with_doc_ai_processors_pipeline($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Pipelines::GcsIngestWithDocAiProcessorsPipeline>)

Use DocAI processors to process documents in Cloud Storage and ingest
them to Document Warehouse.

=item * C<< $msg->export_cdw_pipeline() >> / C<< $msg->export_cdw_pipeline($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Pipelines::ExportToCdwPipeline>)

Export docuemnts from Document Warehouse to CDW for training purpose.

=item * C<< $msg->process_with_doc_ai_pipeline() >> / C<< $msg->process_with_doc_ai_pipeline($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Pipelines::ProcessWithDocAiPipeline>)

Use a DocAI processor to process documents in Document Warehouse, and
re-ingest the updated results into Document Warehouse.

=item * C<< $msg->request_metadata() >> / C<< $msg->request_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Contentwarehouse::V1::Common::RequestMetadata>)

The meta information collected about the end user, used to enforce access
control for the service.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Contentwarehouse::V1::PipelineService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
