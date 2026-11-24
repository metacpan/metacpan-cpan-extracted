package Google::Cloud::Designcenter::V1::ApphubIntegration;

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
CjVnb29nbGUvY2xvdWQvZGVzaWduY2VudGVyL3YxL2FwcGh1Yl9pbnRlZ3JhdGlvbi5wcm90
bxIcZ29vZ2xlLmNsb3VkLmRlc2lnbmNlbnRlci52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90byKVAQoUVW5yZWdpc3RlcmVkUmVzb3VyY2USYAoRZGVwbG95ZWRfcmVzb3Vy
Y2UYASABKAsyLi5nb29nbGUuY2xvdWQuZGVzaWduY2VudGVyLnYxLkRlcGxveWVkUmVzb3Vy
Y2VCA+BBA1IQZGVwbG95ZWRSZXNvdXJjZRIbCgZyZWFzb24YAiABKAlCA+BBA1IGcmVhc29u
IngKEERlcGxveWVkUmVzb3VyY2USJAoLcmVzb3VyY2VfaWQYASABKAlCA+BBAlIKcmVzb3Vy
Y2VJZBIdCgdwcm9qZWN0GAIgASgJQgPgQQFSB3Byb2plY3QSHwoIbG9jYXRpb24YAyABKAlC
A+BBAVIIbG9jYXRpb25C4gEKIGNvbS5nb29nbGUuY2xvdWQuZGVzaWduY2VudGVyLnYxQhZB
cHBodWJJbnRlZ3JhdGlvblByb3RvUAFaRGNsb3VkLmdvb2dsZS5jb20vZ28vZGVzaWduY2Vu
dGVyL2FwaXYxL2Rlc2lnbmNlbnRlcnBiO2Rlc2lnbmNlbnRlcnBiqgIcR29vZ2xlLkNsb3Vk
LkRlc2lnbkNlbnRlci5WMcoCHEdvb2dsZVxDbG91ZFxEZXNpZ25DZW50ZXJcVjHqAh9Hb29n
bGU6OkNsb3VkOjpEZXNpZ25DZW50ZXI6OlYxSvYNCgYSBA4AMgEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACUKCQoCAwASAxIAKQoICgEIEgMUADkKCQoC
CCUSAxQAOQoICgEIEgMVAFsKCQoCCAsSAxUAWwoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEI
EgMXADcKCQoCCAgSAxcANwoICgEIEgMYADkKCQoCCAESAxgAOQoICgEIEgMZADkKCQoCCCkS
AxkAOQoICgEIEgMaADgKCQoCCC0SAxoAOAp6CgIEABIEHgAlARpuIFVucmVnaXN0ZXJlZFJl
c291cmNlIHJlcHJlc2VudHMgYSBHQ1AgcmVzb3VyY2UgdGhhdCBmYWlsZWQgdG8gcmVnaXN0
ZXIgYW5kCiBhcHBodWIgd2FzIG5vdCBhYmxlIHRvIGRpc2NvdmVyLgoKCgoDBAABEgMeCBwK
TwoEBAACABIEIAIhMhpBIE91dHB1dCBvbmx5LiBUaGUgZGVwbG95ZWQgR0NQIHJlc291cmNl
IHRoYXQgZmFpbGVkIHRvIHJlZ2lzdGVyLgoKDAoFBAACAAYSAyACEgoMCgUEAAIAARIDIBMk
CgwKBQQAAgADEgMgJygKDAoFBAACAAgSAyEGMQoPCggEAAIACJwIABIDIQcwCkcKBAQAAgES
AyQCQBo6IE91dHB1dCBvbmx5LiBUaGUgcmVhc29uIGZvciB0aGUgZmFpbHVyZSBvZiByZWdp
c3RyYXRpb24uCgoMCgUEAAIBBRIDJAIICgwKBQQAAgEBEgMkCQ8KDAoFBAACAQMSAyQSEwoM
CgUEAAIBCBIDJBQ/Cg8KCAQAAgEInAgAEgMkFT4KSQoCBAESBCgAMgEaPSBEZXBsb3llZFJl
c291cmNlIHJlcHJlc2VudHMgYSBzaW5nbGUgZGVwbG95ZWQgR0NQIHJlc291cmNlLgoKCgoD
BAEBEgMoCBgKmgEKBAQBAgASAysCQhqMASBSZXF1aXJlZC4gVGhlIGZ1bGwgcmVzb3VyY2Ug
bmFtZSBvZiB0aGUgZGVwbG95ZWQgR0NQIHJlc291cmNlLgogRXhhbXBsZTogcHJvamVjdHMv
bXktcHJvamVjdC9sb2NhdGlvbnMvdXMtY2VudHJhbDEtYS9pbnN0YW5jZXMvbXktaW5zdGFu
Y2UKCgwKBQQBAgAFEgMrAggKDAoFBAECAAESAysJFAoMCgUEAQIAAxIDKxcYCgwKBQQBAgAI
EgMrGUEKDwoIBAECAAicCAASAysaQApBCgQEAQIBEgMuAj4aNCBPcHRpb25hbC4gVGhlIHBy
b2plY3QgSUQgb2YgdGhlIGRlcGxveWVkIHJlc291cmNlLgoKDAoFBAECAQUSAy4CCAoMCgUE
AQIBARIDLgkQCgwKBQQBAgEDEgMuExQKDAoFBAECAQgSAy4VPQoPCggEAQIBCJwIABIDLhY8
Cj8KBAQBAgISAzECPxoyIE9wdGlvbmFsLiBUaGUgbG9jYXRpb24gb2YgdGhlIGRlcGxveWVk
IHJlc291cmNlLgoKDAoFBAECAgUSAzECCAoMCgUEAQICARIDMQkRCgwKBQQBAgIDEgMxFBUK
DAoFBAECAggSAzEWPgoPCggEAQICCJwIABIDMRc9YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Designcenter::V1::ApphubIntegration::UnregisteredResource ===
    # Fields for UnregisteredResource
    # Field: deployed_resource Type: 11 (.google.cloud.designcenter.v1.DeployedResource)
    # Field: reason Type: 9 ()

# === Message: Google::Cloud::Designcenter::V1::ApphubIntegration::DeployedResource ===
    # Fields for DeployedResource
    # Field: resource_id Type: 9 ()
    # Field: project Type: 9 ()
    # Field: location Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Designcenter::V1::ApphubIntegration - Compiled Protocol Buffers messages for google/cloud/designcenter/v1/apphub_integration.proto

=head1 SYNOPSIS

    use Google::Cloud::Designcenter::V1::ApphubIntegration;

    my $msg = Google::Cloud::Designcenter::V1::ApphubIntegration::UnregisteredResource->new({
        deployed_resource => $deployed_resource,
        reason => $reason,
    });

    # Read or update a field
    my $val = $msg->deployed_resource();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Designcenter::V1::ApphubIntegration::UnregisteredResource->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/designcenter/v1/apphub_integration.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Designcenter::V1::ApphubIntegration::UnregisteredResource

UnregisteredResource represents a GCP resource that failed to register and
apphub was not able to discover.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->deployed_resource() >> / C<< $msg->deployed_resource($value) >>

Type: C<Message> (L<Google::Cloud::Designcenter::V1::ApphubIntegration::DeployedResource>)

Output only. The deployed GCP resource that failed to register.

=item * C<< $msg->reason() >> / C<< $msg->reason($value) >>

Type: C<String>

Output only. The reason for the failure of registration.

=back

=head2 Google::Cloud::Designcenter::V1::ApphubIntegration::DeployedResource

DeployedResource represents a single deployed GCP resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resource_id() >> / C<< $msg->resource_id($value) >>

Type: C<String>

Required. The full resource name of the deployed GCP resource.
Example: projects/my-project/locations/us-central1-a/instances/my-instance

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Optional. The project ID of the deployed resource.

=item * C<< $msg->location() >> / C<< $msg->location($value) >>

Type: C<String>

Optional. The location of the deployed resource.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Designcenter::V1::ApphubIntegration::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
