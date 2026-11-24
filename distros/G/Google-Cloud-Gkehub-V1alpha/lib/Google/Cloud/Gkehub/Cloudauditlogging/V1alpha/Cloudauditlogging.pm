package Google::Cloud::Gkehub::Cloudauditlogging::V1alpha::Cloudauditlogging;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CkVnb29nbGUvY2xvdWQvZ2tlaHViL3YxYWxwaGEvY2xvdWRhdWRpdGxvZ2dpbmcvY2xvdWRh
dWRpdGxvZ2dpbmcucHJvdG8SLWdvb2dsZS5jbG91ZC5na2VodWIuY2xvdWRhdWRpdGxvZ2dp
bmcudjFhbHBoYSJPCgtGZWF0dXJlU3BlYxJAChxhbGxvd2xpc3RlZF9zZXJ2aWNlX2FjY291
bnRzGAEgAygJUhphbGxvd2xpc3RlZFNlcnZpY2VBY2NvdW50c0LCAgoxY29tLmdvb2dsZS5j
bG91ZC5na2VodWIuY2xvdWRhdWRpdGxvZ2dpbmcudjFhbHBoYUIWQ2xvdWRBdWRpdExvZ2dp
bmdQcm90b1ABWl9jbG91ZC5nb29nbGUuY29tL2dvL2drZWh1Yi9jbG91ZGF1ZGl0bG9nZ2lu
Zy9hcGl2MWFscGhhL2Nsb3VkYXVkaXRsb2dnaW5ncGI7Y2xvdWRhdWRpdGxvZ2dpbmdwYqoC
LUdvb2dsZS5DbG91ZC5Ha2VIdWIuQ2xvdWRBdWRpdExvZ2dpbmcuVjFBbHBoYcoCLUdvb2ds
ZVxDbG91ZFxHa2VIdWJcQ2xvdWRBdWRpdExvZ2dpbmdcVjFhbHBoYeoCMUdvb2dsZTo6Q2xv
dWQ6OkdrZUh1Yjo6Q2xvdWRBdWRpdExvZ2dpbmc6OlYxYWxwaGFK1gkKBhIEDgAjAQq8BAoB
DBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0
aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBt
YXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGlj
ZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBo
dHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVx
dWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3
YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBh
biAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0Yg
QU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2Ug
Zm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBs
aW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAANgoICgEIEgMTAEoKCQoC
CCUSAxMASgoICgEIEgMUAHYKCQoCCAsSAxQAdgoICgEIEgMVACIKCQoCCAoSAxUAIgoICgEI
EgMWADcKCQoCCAgSAxYANwoICgEIEgMXAEoKCQoCCAESAxcASgoICgEIEgMYAEsKCQoCCCkS
AxgASwoICgEIEgMZAEoKCQoCCC0SAxkASgpLCgIEABIEHAAjARo/ICoqQ2xvdWQgQXVkaXQg
TG9nZ2luZyoqOiBTcGVjIGZvciBBdWRpdCBMb2dnaW5nIEFsbG93bGlzdGluZy4KCgoKAwQA
ARIDHAgTCt4CCgQEAAIAEgMiAjMa0AIgU2VydmljZSBhY2NvdW50IHRoYXQgc2hvdWxkIGJl
IGFsbG93bGlzdGVkIHRvIHNlbmQgdGhlIGF1ZGl0IGxvZ3M7IGVnCiBjbG91ZGF1ZGl0bG9n
Z2luZ0BnY3AtcHJvamVjdC5pYW0uZ3NlcnZpY2VhY2NvdW50LmNvbS4gVGhlc2UgYWNjb3Vu
dHMgbXVzdAogYWxyZWFkeSBleGlzdCwgYnV0IGRvIG5vdCBuZWVkIHRvIGhhdmUgYW55IHBl
cm1pc3Npb25zIGdyYW50ZWQgdG8gdGhlbS4KIFRoZSBjdXN0b21lcidzIGVudGl0bGVtZW50
cyB3aWxsIGJlIGNoZWNrZWQgcHJpb3IgdG8gYWxsb3dsaXN0aW5nIChpLmUuCiB0aGUgY3Vz
dG9tZXIgbXVzdCBiZSBhbiBBbnRob3MgY3VzdG9tZXIuKQoKDAoFBAACAAQSAyICCgoMCgUE
AAIABRIDIgsRCgwKBQQAAgABEgMiEi4KDAoFBAACAAMSAyIxMmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkehub::Cloudauditlogging::V1alpha::Cloudauditlogging::FeatureSpec ===
    # Fields for FeatureSpec
    # Field: allowlisted_service_accounts Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkehub::Cloudauditlogging::V1alpha::Cloudauditlogging - Compiled Protocol Buffers messages for google/cloud/gkehub/v1alpha/cloudauditlogging/cloudauditlogging.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkehub::Cloudauditlogging::V1alpha::Cloudauditlogging;

    my $msg = Google::Cloud::Gkehub::Cloudauditlogging::V1alpha::Cloudauditlogging::FeatureSpec->new({
        allowlisted_service_accounts => $allowlisted_service_accounts,
    });

    # Read or update a field
    my $val = $msg->allowlisted_service_accounts();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkehub::Cloudauditlogging::V1alpha::Cloudauditlogging::FeatureSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkehub/v1alpha/cloudauditlogging/cloudauditlogging.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkehub::Cloudauditlogging::V1alpha::Cloudauditlogging::FeatureSpec

B<Cloud Audit Logging>: Spec for Audit Logging Allowlisting.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->allowlisted_service_accounts() >> / C<< $msg->allowlisted_service_accounts($value) >>

Type: C<String>

Service account that should be allowlisted to send the audit logs; eg
cloudauditlogging@gcp-project.iam.gserviceaccount.com. These accounts must
already exist, but do not need to have any permissions granted to them.
The customer's entitlements will be checked prior to allowlisting (i.e.
the customer must be an Anthos customer.)

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkehub::Cloudauditlogging::V1alpha::Cloudauditlogging::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
