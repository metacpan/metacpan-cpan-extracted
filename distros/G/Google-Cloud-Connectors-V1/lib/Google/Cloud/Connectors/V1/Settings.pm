package Google::Cloud::Connectors::V1::Settings;

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
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvY29ubmVjdG9ycy92MS9zZXR0aW5ncy5wcm90bxIaZ29vZ2xlLmNs
b3VkLmNvbm5lY3RvcnMudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdv
b2dsZS9hcGkvcmVzb3VyY2UucHJvdG8iWgoYR2V0R2xvYmFsU2V0dGluZ3NSZXF1ZXN0Ej4K
BG5hbWUYASABKAlCKuBBAvpBJAoiY29ubmVjdG9ycy5nb29nbGVhcGlzLmNvbS9TZXR0aW5n
c1IEbmFtZSKuAQoIU2V0dGluZ3MSFwoEbmFtZRgBIAEoCUID4EEDUgRuYW1lEhkKBXZwY3Nj
GAIgASgIQgPgQQFSBXZwY3NjEhcKBHBheWcYAyABKAhCA+BBA1IEcGF5ZzpV6kFSCiJjb25u
ZWN0b3JzLmdvb2dsZWFwaXMuY29tL1NldHRpbmdzEixwcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL2dsb2JhbC9zZXR0aW5nc0JxCh5jb20uZ29vZ2xlLmNsb3VkLmNvbm5lY3RvcnMu
djFCDVNldHRpbmdzUHJvdG9QAVo+Y2xvdWQuZ29vZ2xlLmNvbS9nby9jb25uZWN0b3JzL2Fw
aXYxL2Nvbm5lY3RvcnNwYjtjb25uZWN0b3JzcGJKwAsKBhIEDgA1AQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIwoJCgIDABIDEgApCgkKAgMBEgMTACMK
CAoBCBIDFQBVCgkKAggLEgMVAFUKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAuCgkK
AggIEgMXAC4KCAoBCBIDGAA3CgkKAggBEgMYADcKNQoCBAASBBsAIwEaKSBSZXF1ZXN0IGZv
ciBbR2V0R2xvYmFsU2V0dGluZ3NSZXF1ZXN0XS4KCgoKAwQAARIDGwggCjwKBAQAAgASBB0C
IgQaLiBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIFNldHRpbmdzLgoKDAoF
BAACAAUSAx0CCAoMCgUEAAIAARIDHQkNCgwKBQQAAgADEgMdEBEKDQoFBAACAAgSBB0SIgMK
DwoIBAACAAicCAASAx4EKgoPCgcEAAIACJ8IEgQfBCEFCiYKAgQBEgQmADUBGhogR2xvYmFs
IFNldHRpbmdzIGRldGFpbHMuCgoKCgMEAQESAyYIEAoLCgMEAQcSBCcCKgQKDQoFBAEHnQgS
BCcCKgQKcwoEBAECABIDLgI+GmYgT3V0cHV0IG9ubHkuIFJlc291cmNlIG5hbWUgb2YgdGhl
IENvbm5lY3Rpb24uCiBGb3JtYXQ6IHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMvZ2xv
YmFsL3NldHRpbmdzfQoKDAoFBAECAAUSAy4CCAoMCgUEAQIAARIDLgkNCgwKBQQBAgADEgMu
EBEKDAoFBAECAAgSAy4SPQoPCggEAQIACJwIABIDLhM8CkIKBAQBAgESAzECOho1IE9wdGlv
bmFsLiBGbGFnIGluZGljYXRlcyB3aGV0aGVyIHZwYy1zYyBpcyBlbmFibGVkLgoKDAoFBAEC
AQUSAzECBgoMCgUEAQIBARIDMQcMCgwKBQQBAgEDEgMxDxAKDAoFBAECAQgSAzEROQoPCggE
AQIBCJwIABIDMRI4CkMKBAQBAgISAzQCPBo2IE91dHB1dCBvbmx5LiBGbGFnIGluZGljYXRl
cyBpZiB1c2VyIGlzIGluIFBheUcgbW9kZWwKCgwKBQQBAgIFEgM0AgYKDAoFBAECAgESAzQH
CwoMCgUEAQICAxIDNA4PCgwKBQQBAgIIEgM0EDsKDwoIBAECAgicCAASAzQROmIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Connectors::V1::Settings::GetGlobalSettingsRequest ===
    # Fields for GetGlobalSettingsRequest
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Connectors::V1::Settings::Settings ===
    # Fields for Settings
    # Field: name Type: 9 ()
    # Field: vpcsc Type: 8 ()
    # Field: payg Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Connectors::V1::Settings - Compiled Protocol Buffers messages for google/cloud/connectors/v1/settings.proto

=head1 SYNOPSIS

    use Google::Cloud::Connectors::V1::Settings;

    my $msg = Google::Cloud::Connectors::V1::Settings::GetGlobalSettingsRequest->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Connectors::V1::Settings::GetGlobalSettingsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/connectors/v1/settings.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Connectors::V1::Settings::GetGlobalSettingsRequest

Request for [GetGlobalSettingsRequest].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the Settings.

=back

=head2 Google::Cloud::Connectors::V1::Settings::Settings

Global Settings details.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Resource name of the Connection.
Format: projects/{project}/locations/global/settings}

=item * C<< $msg->vpcsc() >> / C<< $msg->vpcsc($value) >>

Type: C<Bool>

Optional. Flag indicates whether vpc-sc is enabled.

=item * C<< $msg->payg() >> / C<< $msg->payg($value) >>

Type: C<Bool>

Output only. Flag indicates if user is in PayG model

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Connectors::V1::Settings::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
