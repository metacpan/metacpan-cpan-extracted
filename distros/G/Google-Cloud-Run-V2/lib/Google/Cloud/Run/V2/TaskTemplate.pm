package Google::Cloud::Run::V2::TaskTemplate;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Run::V2::K8sMin };
    eval { require Google::Cloud::Run::V2::Sandbox };
    eval { require Google::Cloud::Run::V2::VendorSettings };
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvcnVuL3YyL3Rhc2tfdGVtcGxhdGUucHJvdG8SE2dvb2dsZS5jbG91
ZC5ydW4udjIaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkv
cmVzb3VyY2UucHJvdG8aIWdvb2dsZS9jbG91ZC9ydW4vdjIvazhzLm1pbi5wcm90bxohZ29v
Z2xlL2Nsb3VkL3J1bi92Mi9zYW5kYm94LnByb3RvGilnb29nbGUvY2xvdWQvcnVuL3YyL3Zl
bmRvcl9zZXR0aW5ncy5wcm90bxoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvIo4H
CgxUYXNrVGVtcGxhdGUSPgoKY29udGFpbmVycxgBIAMoCzIeLmdvb2dsZS5jbG91ZC5ydW4u
djIuQ29udGFpbmVyUgpjb250YWluZXJzEkwKCXNhbmRib3hlcxgPIAEoCzIpLmdvb2dsZS5j
bG91ZC5ydW4udjIuU2FuZGJveENvbmZpZ3VyYXRpb25CA+BBAVIJc2FuZGJveGVzEjoKB3Zv
bHVtZXMYAiADKAsyGy5nb29nbGUuY2xvdWQucnVuLnYyLlZvbHVtZUID4EEBUgd2b2x1bWVz
EiEKC21heF9yZXRyaWVzGAMgASgFSABSCm1heFJldHJpZXMSOAoHdGltZW91dBgEIAEoCzIZ
Lmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvbkID4EEBUgd0aW1lb3V0EiwKD3NlcnZpY2VfYWNj
b3VudBgFIAEoCUID4EEBUg5zZXJ2aWNlQWNjb3VudBJjChVleGVjdXRpb25fZW52aXJvbm1l
bnQYBiABKA4yKS5nb29nbGUuY2xvdWQucnVuLnYyLkV4ZWN1dGlvbkVudmlyb25tZW50QgPg
QQFSFGV4ZWN1dGlvbkVudmlyb25tZW50Ek0KDmVuY3J5cHRpb25fa2V5GAcgASgJQib6QSMK
IWNsb3Vka21zLmdvb2dsZWFwaXMuY29tL0NyeXB0b0tleVINZW5jcnlwdGlvbktleRJCCgp2
cGNfYWNjZXNzGAggASgLMh4uZ29vZ2xlLmNsb3VkLnJ1bi52Mi5WcGNBY2Nlc3NCA+BBAVIJ
dnBjQWNjZXNzEksKDW5vZGVfc2VsZWN0b3IYCyABKAsyIS5nb29nbGUuY2xvdWQucnVuLnYy
Lk5vZGVTZWxlY3RvckID4EEBUgxub2RlU2VsZWN0b3ISSwodZ3B1X3pvbmFsX3JlZHVuZGFu
Y3lfZGlzYWJsZWQYDCABKAhCA+BBAUgBUhpncHVab25hbFJlZHVuZGFuY3lEaXNhYmxlZIgB
ARJqChh3b3JrbG9hZF9pZGVudGl0eV9jb25maWcYDSABKAsyKy5nb29nbGUuY2xvdWQucnVu
LnYyLldvcmtsb2FkSWRlbnRpdHlDb25maWdCA+BBAVIWd29ya2xvYWRJZGVudGl0eUNvbmZp
Z0IJCgdyZXRyaWVzQiAKHl9ncHVfem9uYWxfcmVkdW5kYW5jeV9kaXNhYmxlZEJZChdjb20u
Z29vZ2xlLmNsb3VkLnJ1bi52MkIRVGFza1RlbXBsYXRlUHJvdG9QAVopY2xvdWQuZ29vZ2xl
LmNvbS9nby9ydW4vYXBpdjIvcnVucGI7cnVucGJK6RkKBhIEDgBXAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHAoJCgIDABIDEgApCgkKAgMBEgMTACMK
CQoCAwISAxQAKwoJCgIDAxIDFQArCgkKAgMEEgMWADMKCQoCAwUSAxcAKAoICgEIEgMZAEAK
CQoCCAsSAxkAQAoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbADIKCQoCCAgSAxsAMgoI
CgEIEgMcADAKCQoCCAESAxwAMApfCgIEABIEIABXARpTIFRhc2tUZW1wbGF0ZSBkZXNjcmli
ZXMgdGhlIGRhdGEgYSB0YXNrIHNob3VsZCBoYXZlIHdoZW4gY3JlYXRlZAogZnJvbSBhIHRl
bXBsYXRlLgoKCgoDBAABEgMgCBQKXAoEBAACABIDIwIkGk8gSG9sZHMgdGhlIHNpbmdsZSBj
b250YWluZXIgdGhhdCBkZWZpbmVzIHRoZSB1bml0IG9mIGV4ZWN1dGlvbiBmb3IgdGhpcwog
dGFzay4KCgwKBQQAAgAEEgMjAgoKDAoFBAACAAYSAyMLFAoMCgUEAAIAARIDIxUfCgwKBQQA
AgADEgMjIiMKNQoEBAACARIDJgJPGiggT3B0aW9uYWwuIENvbmZpZ3VyYXRpb24gZm9yIHNh
bmRib3hlcy4KCgwKBQQAAgEGEgMmAhYKDAoFBAACAQESAyYXIAoMCgUEAAIBAxIDJiMlCgwK
BQQAAgEIEgMmJk4KDwoIBAACAQicCAASAyYnTQpLCgQEAAICEgMpAkcaPiBPcHRpb25hbC4g
QSBsaXN0IG9mIFZvbHVtZXMgdG8gbWFrZSBhdmFpbGFibGUgdG8gY29udGFpbmVycy4KCgwK
BQQAAgIEEgMpAgoKDAoFBAACAgYSAykLEQoMCgUEAAICARIDKRIZCgwKBQQAAgIDEgMpHB0K
DAoFBAACAggSAykeRgoPCggEAAICCJwIABIDKR9FCgwKBAQACAASBCsCLwMKDAoFBAAIAAES
AysIDwpjCgQEAAIDEgMuBBoaViBOdW1iZXIgb2YgcmV0cmllcyBhbGxvd2VkIHBlciBUYXNr
LCBiZWZvcmUgbWFya2luZyB0aGlzIFRhc2sgZmFpbGVkLgogRGVmYXVsdHMgdG8gMy4KCgwK
BQQAAgMFEgMuBAkKDAoFBAACAwESAy4KFQoMCgUEAAIDAxIDLhgZCpECCgQEAAIEEgM1AlAa
gwIgT3B0aW9uYWwuIE1heCBhbGxvd2VkIHRpbWUgZHVyYXRpb24gdGhlIFRhc2sgbWF5IGJl
IGFjdGl2ZSBiZWZvcmUgdGhlCiBzeXN0ZW0gd2lsbCBhY3RpdmVseSB0cnkgdG8gbWFyayBp
dCBmYWlsZWQgYW5kIGtpbGwgYXNzb2NpYXRlZCBjb250YWluZXJzLgogVGhpcyBhcHBsaWVz
IHBlciBhdHRlbXB0IG9mIGEgdGFzaywgbWVhbmluZyBlYWNoIHJldHJ5IGNhbiBydW4gZm9y
IHRoZSBmdWxsCiB0aW1lb3V0LiBEZWZhdWx0cyB0byA2MDAgc2Vjb25kcy4KCgwKBQQAAgQG
EgM1AhoKDAoFBAACBAESAzUbIgoMCgUEAAIEAxIDNSUmCgwKBQQAAgQIEgM1J08KDwoIBAAC
BAicCAASAzUoTgqhAgoEBAACBRIDOwJGGpMCIE9wdGlvbmFsLiBFbWFpbCBhZGRyZXNzIG9m
IHRoZSBJQU0gc2VydmljZSBhY2NvdW50IGFzc29jaWF0ZWQgd2l0aCB0aGUgVGFzawogb2Yg
YSBKb2IuIFRoZSBzZXJ2aWNlIGFjY291bnQgcmVwcmVzZW50cyB0aGUgaWRlbnRpdHkgb2Yg
dGhlIHJ1bm5pbmcgdGFzaywKIGFuZCBkZXRlcm1pbmVzIHdoYXQgcGVybWlzc2lvbnMgdGhl
IHRhc2sgaGFzLiBJZiBub3QgcHJvdmlkZWQsIHRoZSB0YXNrCiB3aWxsIHVzZSB0aGUgcHJv
amVjdCdzIGRlZmF1bHQgc2VydmljZSBhY2NvdW50LgoKDAoFBAACBQUSAzsCCAoMCgUEAAIF
ARIDOwkYCgwKBQQAAgUDEgM7GxwKDAoFBAACBQgSAzsdRQoPCggEAAIFCJwIABIDOx5EClEK
BAQAAgYSBD4CPy8aQyBPcHRpb25hbC4gVGhlIGV4ZWN1dGlvbiBlbnZpcm9ubWVudCBiZWlu
ZyB1c2VkIHRvIGhvc3QgdGhpcyBUYXNrLgoKDAoFBAACBgYSAz4CFgoMCgUEAAIGARIDPhcs
CgwKBQQAAgYDEgM+LzAKDAoFBAACBggSAz8GLgoPCggEAAIGCJwIABIDPwctCsQBCgQEAAIH
EgREAkYFGrUBIEEgcmVmZXJlbmNlIHRvIGEgY3VzdG9tZXIgbWFuYWdlZCBlbmNyeXB0aW9u
IGtleSAoQ01FSykgdG8gdXNlIHRvIGVuY3J5cHQKIHRoaXMgY29udGFpbmVyIGltYWdlLiBG
b3IgbW9yZSBpbmZvcm1hdGlvbiwgZ28gdG8KIGh0dHBzOi8vY2xvdWQuZ29vZ2xlLmNvbS9y
dW4vZG9jcy9zZWN1cmluZy91c2luZy1jbWVrCgoMCgUEAAIHBRIDRAIICgwKBQQAAgcBEgNE
CRcKDAoFBAACBwMSA0QaGwoNCgUEAAIHCBIERBxGBAoPCgcEAAIHCJ8IEgREHUYDCqQBCgQE
AAIIEgNLAkQalgEgT3B0aW9uYWwuIFZQQyBBY2Nlc3MgY29uZmlndXJhdGlvbiB0byB1c2Ug
Zm9yIHRoaXMgVGFzay4gRm9yIG1vcmUKIGluZm9ybWF0aW9uLCB2aXNpdAogaHR0cHM6Ly9j
bG91ZC5nb29nbGUuY29tL3J1bi9kb2NzL2NvbmZpZ3VyaW5nL2Nvbm5lY3RpbmctdnBjLgoK
DAoFBAACCAYSA0sCCwoMCgUEAAIIARIDSwwWCgwKBQQAAggDEgNLGRoKDAoFBAACCAgSA0sb
QwoPCggEAAIICJwIABIDSxxCCkEKBAQAAgkSA04CSxo0IE9wdGlvbmFsLiBUaGUgbm9kZSBz
ZWxlY3RvciBmb3IgdGhlIHRhc2sgdGVtcGxhdGUuCgoMCgUEAAIJBhIDTgIOCgwKBQQAAgkB
EgNODxwKDAoFBAACCQMSA04fIQoMCgUEAAIJCBIDTiJKCg8KCAQAAgkInAgAEgNOI0kKWQoE
BAACChIEUQJSLxpLIE9wdGlvbmFsLiBUcnVlIGlmIEdQVSB6b25hbCByZWR1bmRhbmN5IGlz
IGRpc2FibGVkIG9uIHRoaXMgdGFzayB0ZW1wbGF0ZS4KCgwKBQQAAgoEEgNRAgoKDAoFBAAC
CgUSA1ELDwoMCgUEAAIKARIDURAtCgwKBQQAAgoDEgNRMDIKDAoFBAACCggSA1IGLgoPCggE
AAIKCJwIABIDUgctCkAKBAQAAgsSBFUCVi8aMiBPcHRpb25hbC4gVGhlIFRhc2sncyB3b3Jr
bG9hZCBpZGVudGl0eSBzZXR0aW5ncy4KCgwKBQQAAgsGEgNVAhgKDAoFBAACCwESA1UZMQoM
CgUEAAILAxIDVTQ2CgwKBQQAAgsIEgNWBi4KDwoIBAACCwicCAASA1YHLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Run::V2::TaskTemplate::TaskTemplate ===
    # Fields for TaskTemplate
    # Field: containers Type: 11 (.google.cloud.run.v2.Container)
    # Field: sandboxes Type: 11 (.google.cloud.run.v2.SandboxConfiguration)
    # Field: volumes Type: 11 (.google.cloud.run.v2.Volume)
    # Field: max_retries Type: 5 ()
    # Field: timeout Type: 11 (.google.protobuf.Duration)
    # Field: service_account Type: 9 ()
    # Field: execution_environment Type: 14 (.google.cloud.run.v2.ExecutionEnvironment)
    # Field: encryption_key Type: 9 ()
    # Field: vpc_access Type: 11 (.google.cloud.run.v2.VpcAccess)
    # Field: node_selector Type: 11 (.google.cloud.run.v2.NodeSelector)
    # Field: gpu_zonal_redundancy_disabled Type: 8 ()
    # Field: workload_identity_config Type: 11 (.google.cloud.run.v2.WorkloadIdentityConfig)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Run::V2::TaskTemplate - Compiled Protocol Buffers messages for google/cloud/run/v2/task_template.proto

=head1 SYNOPSIS

    use Google::Cloud::Run::V2::TaskTemplate;

    my $msg = Google::Cloud::Run::V2::TaskTemplate::TaskTemplate->new({
        containers => $containers,
        sandboxes => $sandboxes,
        volumes => $volumes,
        max_retries => $max_retries,
    });

    # Read or update a field
    my $val = $msg->containers();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Run::V2::TaskTemplate::TaskTemplate->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/run/v2/task_template.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Run::V2::TaskTemplate::TaskTemplate

TaskTemplate describes the data a task should have when created
from a template.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->containers() >> / C<< $msg->containers($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::K8sMin::Container>)

Holds the single container that defines the unit of execution for this
task.

=item * C<< $msg->sandboxes() >> / C<< $msg->sandboxes($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::Sandbox::SandboxConfiguration>)

Optional. Configuration for sandboxes.

=item * C<< $msg->volumes() >> / C<< $msg->volumes($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::K8sMin::Volume>)

Optional. A list of Volumes to make available to containers.

=item * C<< $msg->max_retries() >> / C<< $msg->max_retries($value) >>

Type: C<Int32>

Number of retries allowed per Task, before marking this Task failed.
Defaults to 3.

=item * C<< $msg->timeout() >> / C<< $msg->timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. Max allowed time duration the Task may be active before the
system will actively try to mark it failed and kill associated containers.
This applies per attempt of a task, meaning each retry can run for the full
timeout. Defaults to 600 seconds.

=item * C<< $msg->service_account() >> / C<< $msg->service_account($value) >>

Type: C<String>

Optional. Email address of the IAM service account associated with the Task
of a Job. The service account represents the identity of the running task,
and determines what permissions the task has. If not provided, the task
will use the project's default service account.

=item * C<< $msg->execution_environment() >> / C<< $msg->execution_environment($value) >>

Type: C<Enum> (L<Google::Cloud::Run::V2::ExecutionEnvironment>)

Optional. The execution environment being used to host this Task.

=item * C<< $msg->encryption_key() >> / C<< $msg->encryption_key($value) >>

Type: C<String>

A reference to a customer managed encryption key (CMEK) to use to encrypt
this container image. For more information, go to
https://cloud.google.com/run/docs/securing/using-cmek

=item * C<< $msg->vpc_access() >> / C<< $msg->vpc_access($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::VendorSettings::VpcAccess>)

Optional. VPC Access configuration to use for this Task. For more
information, visit
https://cloud.google.com/run/docs/configuring/connecting-vpc.

=item * C<< $msg->node_selector() >> / C<< $msg->node_selector($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::VendorSettings::NodeSelector>)

Optional. The node selector for the task template.

=item * C<< $msg->gpu_zonal_redundancy_disabled() >> / C<< $msg->gpu_zonal_redundancy_disabled($value) >>

Type: C<Bool>

Optional. True if GPU zonal redundancy is disabled on this task template.

=item * C<< $msg->workload_identity_config() >> / C<< $msg->workload_identity_config($value) >>

Type: C<Message> (L<Google::Cloud::Run::V2::VendorSettings::WorkloadIdentityConfig>)

Optional. The Task's workload identity settings.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Run::V2::TaskTemplate::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
