package Google::Cloud::Securitycenter::V1::ExternalExposure;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldInfo };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvZXh0ZXJuYWxfZXhwb3N1cmUucHJv
dG8SHmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MRobZ29vZ2xlL2FwaS9maWVsZF9p
bmZvLnByb3RvIsIEChBFeHRlcm5hbEV4cG9zdXJlEjYKEnByaXZhdGVfaXBfYWRkcmVzcxgB
IAEoCUII4ozP1wgCCARSEHByaXZhdGVJcEFkZHJlc3MSIQoMcHJpdmF0ZV9wb3J0GAIgASgJ
Ugtwcml2YXRlUG9ydBInCg9leHBvc2VkX3NlcnZpY2UYAyABKAlSDmV4cG9zZWRTZXJ2aWNl
EjQKEXB1YmxpY19pcF9hZGRyZXNzGAQgASgJQgjijM/XCAIIBFIPcHVibGljSXBBZGRyZXNz
Eh8KC3B1YmxpY19wb3J0GAUgASgJUgpwdWJsaWNQb3J0EikKEGV4cG9zZWRfZW5kcG9pbnQY
BiABKAlSD2V4cG9zZWRFbmRwb2ludBJBCh1sb2FkX2JhbGFuY2VyX2ZpcmV3YWxsX3BvbGlj
eRgHIAEoCVIabG9hZEJhbGFuY2VyRmlyZXdhbGxQb2xpY3kSNgoXc2VydmljZV9maXJld2Fs
bF9wb2xpY3kYCCABKAlSFXNlcnZpY2VGaXJld2FsbFBvbGljeRInCg9mb3J3YXJkaW5nX3J1
bGUYCSABKAlSDmZvcndhcmRpbmdSdWxlEicKD2JhY2tlbmRfc2VydmljZRgKIAEoCVIOYmFj
a2VuZFNlcnZpY2USJQoOaW5zdGFuY2VfZ3JvdXAYCyABKAlSDWluc3RhbmNlR3JvdXASNAoW
bmV0d29ya19lbmRwb2ludF9ncm91cBgMIAEoCVIUbmV0d29ya0VuZHBvaW50R3JvdXBC7wEK
ImNvbS5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjFCFUV4dGVybmFsRXhwb3N1cmVQ
cm90b1ABWkpjbG91ZC5nb29nbGUuY29tL2dvL3NlY3VyaXR5Y2VudGVyL2FwaXYxL3NlY3Vy
aXR5Y2VudGVycGI7c2VjdXJpdHljZW50ZXJwYqoCHkdvb2dsZS5DbG91ZC5TZWN1cml0eUNl
bnRlci5WMcoCHkdvb2dsZVxDbG91ZFxTZWN1cml0eUNlbnRlclxWMeoCIUdvb2dsZTo6Q2xv
dWQ6OlNlY3VyaXR5Q2VudGVyOjpWMUqgFwoGEgQOAEoBCrwECgEMEgMOABIysQQgQ29weXJp
Z2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5z
ZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMg
ZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBv
YnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAnCgkKAgMAEgMSACUKCAoBCBIDFAA7CgkKAgglEgMU
ADsKCAoBCBIDFQBhCgkKAggLEgMVAGEKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwA2
CgkKAggIEgMXADYKCAoBCBIDGAA7CgkKAggBEgMYADsKCAoBCBIDGQA7CgkKAggpEgMZADsK
CAoBCBIDGgA6CgkKAggtEgMaADoKWAoCBAASBB0ASgEaTCBEZXRhaWxzIGFib3V0IHRoZSBl
eHRlcm5hbGx5IGV4cG9zZWQgcmVzb3VyY2UgYXNzb2NpYXRlZCB3aXRoIHRoZSBmaW5kaW5n
LgoKCgoDBAABEgMdCBgKOgoEBAACABIDHwJQGi0gUHJpdmF0ZSBJUCBhZGRyZXNzIG9mIHRo
ZSBleHBvc2VkIGVuZHBvaW50LgoKDAoFBAACAAUSAx8CCAoMCgUEAAIAARIDHwkbCgwKBQQA
AgADEgMfHh8KDAoFBAACAAgSAx8gTwoSCgsEAAIACMzx+YoBARIDHyFOCj4KBAQAAgESAyIC
GhoxIFBvcnQgbnVtYmVyIGFzc29jaWF0ZWQgd2l0aCBwcml2YXRlIElQIGFkZHJlc3MuCgoM
CgUEAAIBBRIDIgIICgwKBQQAAgEBEgMiCRUKDAoFBAACAQMSAyIYGQpcCgQEAAICEgMmAh0a
TyBUaGUgbmFtZSBhbmQgdmVyc2lvbiBvZiB0aGUgc2VydmljZSwgZm9yIGV4YW1wbGUsICJK
dXB5dGVyCiBOb3RlYm9vayA2LjE0LjAiLgoKDAoFBAACAgUSAyYCCAoMCgUEAAICARIDJgkY
CgwKBQQAAgIDEgMmGxwKOQoEBAACAxIDKQJPGiwgUHVibGljIElQIGFkZHJlc3Mgb2YgdGhl
IGV4cG9zZWQgZW5kcG9pbnQuCgoMCgUEAAIDBRIDKQIICgwKBQQAAgMBEgMpCRoKDAoFBAAC
AwMSAykdHgoMCgUEAAIDCBIDKR9OChIKCwQAAgMIzPH5igEBEgMpIE0KOgoEBAACBBIDLAIZ
Gi0gUHVibGljIHBvcnQgbnVtYmVyIG9mIHRoZSBleHBvc2VkIGVuZHBvaW50LgoKDAoFBAAC
BAUSAywCCAoMCgUEAAIEARIDLAkUCgwKBQQAAgQDEgMsFxgKpgEKBAQAAgUSAzACHhqYASBU
aGUgcmVzb3VyY2Ugd2hpY2ggaXMgcnVubmluZyB0aGUgZXhwb3NlZCBzZXJ2aWNlLCBmb3Ig
ZXhhbXBsZSwKICIvL2NvbXB1dGUuZ29vZ2xlYXBpcy5jb20vcHJvamVjdHMve3Byb2plY3Qt
aWR9L3pvbmVzL3t6b25lfS9pbnN0YW5jZXMve2luc3RhbmNlfS7igJ0KCgwKBQQAAgUFEgMw
AggKDAoFBAACBQESAzAJGQoMCgUEAAIFAxIDMBwdCrIBCgQEAAIGEgM0AisapAEgVGhlIGZ1
bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgbG9hZCBiYWxhbmNlciBmaXJld2FsbCBwb2xpY3ks
IGZvciBleGFtcGxlLAogIi8vY29tcHV0ZS5nb29nbGVhcGlzLmNvbS9wcm9qZWN0cy97cHJv
amVjdC1pZH0vZ2xvYmFsL2ZpcmV3YWxsUG9saWNpZXMve3BvbGljeS1uYW1lfSIuCgoMCgUE
AAIGBRIDNAIICgwKBQQAAgYBEgM0CSYKDAoFBAACBgMSAzQpKgq8AQoEBAACBxIDOQIlGq4B
IFRoZSBmdWxsIHJlc291cmNlIG5hbWUgb2YgdGhlIGZpcmV3YWxsIHBvbGljeSBvZiB0aGUg
ZXhwb3NlZCBzZXJ2aWNlLCBmb3IKIGV4YW1wbGUsCiAiLy9jb21wdXRlLmdvb2dsZWFwaXMu
Y29tL3Byb2plY3RzL3twcm9qZWN0LWlkfS9nbG9iYWwvZmlyZXdhbGxQb2xpY2llcy97cG9s
aWN5LW5hbWV9Ii4KCgwKBQQAAgcFEgM5AggKDAoFBAACBwESAzkJIAoMCgUEAAIHAxIDOSMk
CqwBCgQEAAIIEgM9Ah0angEgVGhlIGZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgZm9yd2Fy
ZGluZyBydWxlLCBmb3IgZXhhbXBsZSwKICIvL2NvbXB1dGUuZ29vZ2xlYXBpcy5jb20vcHJv
amVjdHMve3Byb2plY3QtaWR9L2dsb2JhbC9mb3J3YXJkaW5nUnVsZXMve2ZvcndhcmRpbmct
cnVsZS1uYW1lfSIuCgoMCgUEAAIIBRIDPQIICgwKBQQAAggBEgM9CRgKDAoFBAACCAMSAz0b
HAqmAQoEBAACCRIDQQIeGpgBIFRoZSBmdWxsIHJlc291cmNlIG5hbWUgb2YgbG9hZCBiYWxh
bmNlciBiYWNrZW5kIHNlcnZpY2UsIGZvciBleGFtcGxlLAogIi8vY29tcHV0ZS5nb29nbGVh
cGlzLmNvbS9wcm9qZWN0cy97cHJvamVjdC1pZH0vZ2xvYmFsL2JhY2tlbmRTZXJ2aWNlcy97
bmFtZX0iLgoKDAoFBAACCQUSA0ECCAoMCgUEAAIJARIDQQkYCgwKBQQAAgkDEgNBGx0KmgEK
BAQAAgoSA0UCHRqMASBUaGUgZnVsbCByZXNvdXJjZSBuYW1lIG9mIHRoZSBpbnN0YW5jZSBn
cm91cCwgZm9yIGV4YW1wbGUsCiAiLy9jb21wdXRlLmdvb2dsZWFwaXMuY29tL3Byb2plY3Rz
L3twcm9qZWN0LWlkfS9nbG9iYWwvaW5zdGFuY2VHcm91cHMve25hbWV9Ii4KCgwKBQQAAgoF
EgNFAggKDAoFBAACCgESA0UJFwoMCgUEAAIKAxIDRRocCqkBCgQEAAILEgNJAiUamwEgVGhl
IGZ1bGwgcmVzb3VyY2UgbmFtZSBvZiB0aGUgbmV0d29yayBlbmRwb2ludCBncm91cCwgZm9y
IGV4YW1wbGUsCiAiLy9jb21wdXRlLmdvb2dsZWFwaXMuY29tL3Byb2plY3RzL3twcm9qZWN0
LWlkfS9nbG9iYWwvbmV0d29ya0VuZHBvaW50R3JvdXBzL3tuYW1lfSIuCgoMCgUEAAILBRID
SQIICgwKBQQAAgsBEgNJCR8KDAoFBAACCwMSA0kiJGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::ExternalExposure::ExternalExposure ===
    # Fields for ExternalExposure
    # Field: private_ip_address Type: 9 ()
    # Field: private_port Type: 9 ()
    # Field: exposed_service Type: 9 ()
    # Field: public_ip_address Type: 9 ()
    # Field: public_port Type: 9 ()
    # Field: exposed_endpoint Type: 9 ()
    # Field: load_balancer_firewall_policy Type: 9 ()
    # Field: service_firewall_policy Type: 9 ()
    # Field: forwarding_rule Type: 9 ()
    # Field: backend_service Type: 9 ()
    # Field: instance_group Type: 9 ()
    # Field: network_endpoint_group Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::ExternalExposure - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/external_exposure.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::ExternalExposure;

    my $msg = Google::Cloud::Securitycenter::V1::ExternalExposure::ExternalExposure->new({
        private_ip_address => $private_ip_address,
        private_port => $private_port,
        exposed_service => $exposed_service,
        public_ip_address => $public_ip_address,
    });

    # Read or update a field
    my $val = $msg->private_ip_address();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::ExternalExposure::ExternalExposure->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/external_exposure.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::ExternalExposure::ExternalExposure

Details about the externally exposed resource associated with the finding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->private_ip_address() >> / C<< $msg->private_ip_address($value) >>

Type: C<String>

Private IP address of the exposed endpoint.

=item * C<< $msg->private_port() >> / C<< $msg->private_port($value) >>

Type: C<String>

Port number associated with private IP address.

=item * C<< $msg->exposed_service() >> / C<< $msg->exposed_service($value) >>

Type: C<String>

The name and version of the service, for example, "Jupyter
Notebook 6.14.0".

=item * C<< $msg->public_ip_address() >> / C<< $msg->public_ip_address($value) >>

Type: C<String>

Public IP address of the exposed endpoint.

=item * C<< $msg->public_port() >> / C<< $msg->public_port($value) >>

Type: C<String>

Public port number of the exposed endpoint.

=item * C<< $msg->exposed_endpoint() >> / C<< $msg->exposed_endpoint($value) >>

Type: C<String>

The resource which is running the exposed service, for example,
"//compute.googleapis.com/projects/{project-id}/zones/{zone}/instances/{instance}.”

=item * C<< $msg->load_balancer_firewall_policy() >> / C<< $msg->load_balancer_firewall_policy($value) >>

Type: C<String>

The full resource name of the load balancer firewall policy, for example,
"//compute.googleapis.com/projects/{project-id}/global/firewallPolicies/{policy-name}".

=item * C<< $msg->service_firewall_policy() >> / C<< $msg->service_firewall_policy($value) >>

Type: C<String>

The full resource name of the firewall policy of the exposed service, for
example,
"//compute.googleapis.com/projects/{project-id}/global/firewallPolicies/{policy-name}".

=item * C<< $msg->forwarding_rule() >> / C<< $msg->forwarding_rule($value) >>

Type: C<String>

The full resource name of the forwarding rule, for example,
"//compute.googleapis.com/projects/{project-id}/global/forwardingRules/{forwarding-rule-name}".

=item * C<< $msg->backend_service() >> / C<< $msg->backend_service($value) >>

Type: C<String>

The full resource name of load balancer backend service, for example,
"//compute.googleapis.com/projects/{project-id}/global/backendServices/{name}".

=item * C<< $msg->instance_group() >> / C<< $msg->instance_group($value) >>

Type: C<String>

The full resource name of the instance group, for example,
"//compute.googleapis.com/projects/{project-id}/global/instanceGroups/{name}".

=item * C<< $msg->network_endpoint_group() >> / C<< $msg->network_endpoint_group($value) >>

Type: C<String>

The full resource name of the network endpoint group, for example,
"//compute.googleapis.com/projects/{project-id}/global/networkEndpointGroups/{name}".

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::ExternalExposure::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
