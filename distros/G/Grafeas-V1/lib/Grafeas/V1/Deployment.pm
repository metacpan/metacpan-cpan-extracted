package Grafeas::V1::Deployment;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
ChtncmFmZWFzL3YxL2RlcGxveW1lbnQucHJvdG8SCmdyYWZlYXMudjEaH2dvb2dsZS9wcm90
b2J1Zi90aW1lc3RhbXAucHJvdG8iMwoORGVwbG95bWVudE5vdGUSIQoMcmVzb3VyY2VfdXJp
GAEgAygJUgtyZXNvdXJjZVVyaSKUAwoURGVwbG95bWVudE9jY3VycmVuY2USHQoKdXNlcl9l
bWFpbBgBIAEoCVIJdXNlckVtYWlsEjsKC2RlcGxveV90aW1lGAIgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcFIKZGVwbG95VGltZRI/Cg11bmRlcGxveV90aW1lGAMgASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIMdW5kZXBsb3lUaW1lEhYKBmNvbmZpZxgEIAEo
CVIGY29uZmlnEhgKB2FkZHJlc3MYBSABKAlSB2FkZHJlc3MSIQoMcmVzb3VyY2VfdXJpGAYg
AygJUgtyZXNvdXJjZVVyaRJFCghwbGF0Zm9ybRgHIAEoDjIpLmdyYWZlYXMudjEuRGVwbG95
bWVudE9jY3VycmVuY2UuUGxhdGZvcm1SCHBsYXRmb3JtIkMKCFBsYXRmb3JtEhgKFFBMQVRG
T1JNX1VOU1BFQ0lGSUVEEAASBwoDR0tFEAESCAoERkxFWBACEgoKBkNVU1RPTRADQlEKDWlv
LmdyYWZlYXMudjFQAVo4Z29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9n
cmFmZWFzL3YxO2dyYWZlYXOiAgNHUkFKixEKBhIEDgBBAQraBAoBDBIDDgASMs8EIENvcHly
aWdodCAyMDE5IFRoZSBHcmFmZWFzIEF1dGhvcnMuIEFsbCByaWdodHMgcmVzZXJ2ZWQuCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
EwoJCgIDABIDEgApCggKAQgSAxQATwoJCgIICxIDFABPCggKAQgSAxUAIgoJCgIIChIDFQAi
CggKAQgSAxYAJgoJCgIIARIDFgAmCggKAQgSAxcAIQoJCgIIJBIDFwAhCj8KAgQAEgQaAB0B
GjMgQW4gYXJ0aWZhY3QgdGhhdCBjYW4gYmUgZGVwbG95ZWQgaW4gc29tZSBydW50aW1lLgoK
CgoDBAABEgMaCBYKRgoEBAACABIDHAIjGjkgUmVxdWlyZWQuIFJlc291cmNlIFVSSSBmb3Ig
dGhlIGFydGlmYWN0IGJlaW5nIGRlcGxveWVkLgoKDAoFBAACAAQSAxwCCgoMCgUEAAIABRID
HAsRCgwKBQQAAgABEgMcEh4KDAoFBAACAAMSAxwhIgpOCgIEARIEIABBARpCIFRoZSBwZXJp
b2QgZHVyaW5nIHdoaWNoIHNvbWUgZGVwbG95YWJsZSB3YXMgYWN0aXZlIGluIGEgcnVudGlt
ZS4KCgoKAwQBARIDIAgcCkMKBAQBAgASAyICGBo2IElkZW50aXR5IG9mIHRoZSB1c2VyIHRo
YXQgdHJpZ2dlcmVkIHRoaXMgZGVwbG95bWVudC4KCgwKBQQBAgAFEgMiAggKDAoFBAECAAES
AyIJEwoMCgUEAQIAAxIDIhYXCkYKBAQBAgESAyUCLBo5IFJlcXVpcmVkLiBCZWdpbm5pbmcg
b2YgdGhlIGxpZmV0aW1lIG9mIHRoaXMgZGVwbG95bWVudC4KCgwKBQQBAgEGEgMlAhsKDAoF
BAECAQESAyUcJwoMCgUEAQIBAxIDJSorCjYKBAQBAgISAygCLhopIEVuZCBvZiB0aGUgbGlm
ZXRpbWUgb2YgdGhpcyBkZXBsb3ltZW50LgoKDAoFBAECAgYSAygCGwoMCgUEAQICARIDKBwp
CgwKBQQBAgIDEgMoLC0KPAoEBAECAxIDKwIUGi8gQ29uZmlndXJhdGlvbiB1c2VkIHRvIGNy
ZWF0ZSB0aGlzIGRlcGxveW1lbnQuCgoMCgUEAQIDBRIDKwIICgwKBQQBAgMBEgMrCQ8KDAoF
BAECAwMSAysSEwpGCgQEAQIEEgMuAhUaOSBBZGRyZXNzIG9mIHRoZSBydW50aW1lIGVsZW1l
bnQgaG9zdGluZyB0aGlzIGRlcGxveW1lbnQuCgoMCgUEAQIEBRIDLgIICgwKBQQBAgQBEgMu
CRAKDAoFBAECBAMSAy4TFAp9CgQEAQIFEgMyAiMacCBPdXRwdXQgb25seS4gUmVzb3VyY2Ug
VVJJIGZvciB0aGUgYXJ0aWZhY3QgYmVpbmcgZGVwbG95ZWQgdGFrZW4gZnJvbQogdGhlIGRl
cGxveWFibGUgZmllbGQgd2l0aCB0aGUgc2FtZSBuYW1lLgoKDAoFBAECBQQSAzICCgoMCgUE
AQIFBRIDMgsRCgwKBQQBAgUBEgMyEh4KDAoFBAECBQMSAzIhIgojCgQEAQQAEgQ1Aj4DGhUg
VHlwZXMgb2YgcGxhdGZvcm1zLgoKDAoFBAEEAAESAzUHDwoZCgYEAQQAAgASAzcEHRoKIFVu
a25vd24uCgoOCgcEAQQAAgABEgM3BBgKDgoHBAEEAAIAAhIDNxscCikKBgQBBAACARIDOQQM
GhogR29vZ2xlIENvbnRhaW5lciBFbmdpbmUuCgoOCgcEAQQAAgEBEgM5BAcKDgoHBAEEAAIB
AhIDOQoLCjkKBgQBBAACAhIDOwQNGiogR29vZ2xlIEFwcCBFbmdpbmU6IEZsZXhpYmxlIEVu
dmlyb25tZW50LgoKDgoHBAEEAAICARIDOwQICg4KBwQBBAACAgISAzsLDAouCgYEAQQAAgMS
Az0EDxofIEN1c3RvbSB1c2VyLWRlZmluZWQgcGxhdGZvcm0uCgoOCgcEAQQAAgMBEgM9BAoK
DgoHBAEEAAIDAhIDPQ0OCjAKBAQBAgYSA0ACGBojIFBsYXRmb3JtIGhvc3RpbmcgdGhpcyBk
ZXBsb3ltZW50LgoKDAoFBAECBgYSA0ACCgoMCgUEAQIGARIDQAsTCgwKBQQBAgYDEgNAFhdi
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Grafeas::V1::Deployment::DeploymentNote ===
    # Fields for DeploymentNote
    # Field: resource_uri Type: 9 ()

# === Message: Grafeas::V1::Deployment::DeploymentOccurrence ===
    # Fields for DeploymentOccurrence
    # Field: user_email Type: 9 ()
    # Field: deploy_time Type: 11 (.google.protobuf.Timestamp)
    # Field: undeploy_time Type: 11 (.google.protobuf.Timestamp)
    # Field: config Type: 9 ()
    # Field: address Type: 9 ()
    # Field: resource_uri Type: 9 ()
    # Field: platform Type: 14 (.grafeas.v1.DeploymentOccurrence.Platform)

# Enum: DeploymentOccurrence::Platform
our $DeploymentOccurrence_PLATFORM_UNSPECIFIED = 0;
our $DeploymentOccurrence_GKE = 1;
our $DeploymentOccurrence_FLEX = 2;
our $DeploymentOccurrence_CUSTOM = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Grafeas::V1::Deployment - Compiled Protocol Buffers messages for grafeas/v1/deployment.proto

=head1 SYNOPSIS

    use Grafeas::V1::Deployment;

    my $msg = Grafeas::V1::Deployment::DeploymentNote->new({
        resource_uri => $resource_uri,
    });

    # Read or update a field
    my $val = $msg->resource_uri();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Grafeas::V1::Deployment::DeploymentNote->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<grafeas/v1/deployment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Grafeas::V1::Deployment::DeploymentNote

An artifact that can be deployed in some runtime.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->resource_uri() >> / C<< $msg->resource_uri($value) >>

Type: C<String>

Required. Resource URI for the artifact being deployed.

=back

=head2 Grafeas::V1::Deployment::DeploymentOccurrence

The period during which some deployable was active in a runtime.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->user_email() >> / C<< $msg->user_email($value) >>

Type: C<String>

Identity of the user that triggered this deployment.

=item * C<< $msg->deploy_time() >> / C<< $msg->deploy_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. Beginning of the lifetime of this deployment.

=item * C<< $msg->undeploy_time() >> / C<< $msg->undeploy_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

End of the lifetime of this deployment.

=item * C<< $msg->config() >> / C<< $msg->config($value) >>

Type: C<String>

Configuration used to create this deployment.

=item * C<< $msg->address() >> / C<< $msg->address($value) >>

Type: C<String>

Address of the runtime element hosting this deployment.

=item * C<< $msg->resource_uri() >> / C<< $msg->resource_uri($value) >>

Type: C<String>

Output only. Resource URI for the artifact being deployed taken from
the deployable field with the same name.

=item * C<< $msg->platform() >> / C<< $msg->platform($value) >>

Type: C<Enum> (L<Grafeas::V1::DeploymentOccurrence::Platform>)

Platform hosting this deployment.

=back

=head3 Enum: DeploymentOccurrence::Platform

=over 4

=item * C<PLATFORM_UNSPECIFIED> => C<0>

=item * C<GKE> => C<1>

=item * C<FLEX> => C<2>

=item * C<CUSTOM> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Grafeas::V1::Deployment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
