package Google::Devicesandservices::Health::V4::MedicalDeviceInfo;

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
Cj1nb29nbGUvZGV2aWNlc2FuZHNlcnZpY2VzL2hlYWx0aC92NC9tZWRpY2FsX2RldmljZV9p
bmZvLnByb3RvEiNnb29nbGUuZGV2aWNlc2FuZHNlcnZpY2VzLmhlYWx0aC52NBofZ29vZ2xl
L2FwaS9maWVsZF9iZWhhdmlvci5wcm90byL5AQoRTWVkaWNhbERldmljZUluZm8SMAoRYWxn
b3JpdGhtX3ZlcnNpb24YASABKAlCA+BBA1IQYWxnb3JpdGhtVmVyc2lvbhIsCg9zZXJ2aWNl
X3ZlcnNpb24YAiABKAlCA+BBA1IOc2VydmljZVZlcnNpb24SLgoQZmlybXdhcmVfdmVyc2lv
bhgDIAEoCUID4EEDUg9maXJtd2FyZVZlcnNpb24SLAoPZmVhdHVyZV92ZXJzaW9uGAQgASgJ
QgPgQQNSDmZlYXR1cmVWZXJzaW9uEiYKDGRldmljZV9tb2RlbBgFIAEoCUID4EEDUgtkZXZp
Y2VNb2RlbEKIAgonY29tLmdvb2dsZS5kZXZpY2VzYW5kc2VydmljZXMuaGVhbHRoLnY0QhZN
ZWRpY2FsRGV2aWNlSW5mb1Byb3RvUAFaTmdvb2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dv
b2dsZWFwaXMvZGV2aWNlc2FuZHNlcnZpY2VzL2hlYWx0aC9hcGl2NDtoZWFsdGhwYqoCI0dv
b2dsZS5EZXZpY2VzQW5kU2VydmljZXMuSGVhbHRoLlY0ygIjR29vZ2xlXERldmljZXNBbmRT
ZXJ2aWNlc1xIZWFsdGhcVjTqAiZHb29nbGU6OkRldmljZXNBbmRTZXJ2aWNlczo6SGVhbHRo
OjpWNEqYDQoGEgQOAC8BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExM
QwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRo
ZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29t
cGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRo
ZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNF
TlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQg
dG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNl
IGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJ
RVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGll
ZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmlu
ZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoB
AhIDEAAsCgkKAgMAEgMSACkKCAoBCBIDFABACgkKAgglEgMUAEAKCAoBCBIDFQBlCgkKAggL
EgMVAGUKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwA3CgkKAggIEgMXADcKCAoBCBID
GABACgkKAggBEgMYAEAKCAoBCBIDGQBACgkKAggpEgMZAEAKCAoBCBIDGgA/CgkKAggtEgMa
AD8KcAoCBAASBB4ALwEaZCBTb2Z0d2FyZSBhcyBNZWRpY2FsIERldmljZSAoU2FNRCkgbWV0
YWRhdGEuCiBVc2VkIHRvIGNvbnN0cnVjdCB0aGUgVW5pcXVlIERldmljZSBJZGVudGlmaWVy
IChVREkpLgoKCgoDBAABEgMeCBkKRgoEBAACABIDIAJLGjkgT3V0cHV0IG9ubHkuIFRoZSBh
bGdvcml0aG0gdmVyc2lvbiB1c2VkIGJ5IHRoZSBmZWF0dXJlLgoKDAoFBAACAAUSAyACCAoM
CgUEAAIAARIDIAkaCgwKBQQAAgADEgMgHR4KDAoFBAACAAgSAyAfSgoPCggEAAIACJwIABID
ICBJCkQKBAQAAgESAyMCSRo3IE91dHB1dCBvbmx5LiBUaGUgc2VydmljZSB2ZXJzaW9uIHVz
ZWQgYnkgdGhlIGZlYXR1cmUuCgoMCgUEAAIBBRIDIwIICgwKBQQAAgEBEgMjCRgKDAoFBAAC
AQMSAyMbHAoMCgUEAAIBCBIDIx1ICg8KCAQAAgEInAgAEgMjHkcKbAoEBAACAhIDJwJKGl8g
T3V0cHV0IG9ubHkuIFRoZSBmaXJtd2FyZSB2ZXJzaW9uIHJ1bm5pbmcgb24gdGhlIGNvbXBh
dGlibGUgZGV2aWNlIHVzZWQgdG8KIGNvbGxlY3QgdGhlIGRhdGEuCgoMCgUEAAICBRIDJwII
CgwKBQQAAgIBEgMnCRkKDAoFBAACAgMSAyccHQoMCgUEAAICCBIDJx5JCg8KCAQAAgIInAgA
EgMnH0gKUQoEBAACAxIDKgJJGkQgT3V0cHV0IG9ubHkuIFRoZSB2ZXJzaW9uIG9mIHRoZSBm
ZWF0dXJlL2FwcCBydW5uaW5nIG9uIHRoZSBkZXZpY2UuCgoMCgUEAAIDBRIDKgIICgwKBQQA
AgMBEgMqCRgKDAoFBAACAwMSAyobHAoMCgUEAAIDCBIDKh1ICg8KCAQAAgMInAgAEgMqHkcK
bQoEBAACBBIDLgJGGmAgT3V0cHV0IG9ubHkuIFRoZSBtb2RlbCBuYW1lIG9yIGRldmljZSB0
eXBlIG9mIHRoZSBjb21wYXRpYmxlIGRldmljZSB1c2VkIHRvCiBjb2xsZWN0IHRoZSBkYXRh
LgoKDAoFBAACBAUSAy4CCAoMCgUEAAIEARIDLgkVCgwKBQQAAgQDEgMuGBkKDAoFBAACBAgS
Ay4aRQoPCggEAAIECJwIABIDLhtEYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devicesandservices::Health::V4::MedicalDeviceInfo::MedicalDeviceInfo ===
    # Fields for MedicalDeviceInfo
    # Field: algorithm_version Type: 9 ()
    # Field: service_version Type: 9 ()
    # Field: firmware_version Type: 9 ()
    # Field: feature_version Type: 9 ()
    # Field: device_model Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devicesandservices::Health::V4::MedicalDeviceInfo - Compiled Protocol Buffers messages for google/devicesandservices/health/v4/medical_device_info.proto

=head1 SYNOPSIS

    use Google::Devicesandservices::Health::V4::MedicalDeviceInfo;

    my $msg = Google::Devicesandservices::Health::V4::MedicalDeviceInfo::MedicalDeviceInfo->new({
        algorithm_version => $algorithm_version,
        service_version => $service_version,
        firmware_version => $firmware_version,
        feature_version => $feature_version,
    });

    # Read or update a field
    my $val = $msg->algorithm_version();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devicesandservices::Health::V4::MedicalDeviceInfo::MedicalDeviceInfo->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devicesandservices/health/v4/medical_device_info.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devicesandservices::Health::V4::MedicalDeviceInfo::MedicalDeviceInfo

Software as Medical Device (SaMD) metadata.
Used to construct the Unique Device Identifier (UDI).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->algorithm_version() >> / C<< $msg->algorithm_version($value) >>

Type: C<String>

Output only. The algorithm version used by the feature.

=item * C<< $msg->service_version() >> / C<< $msg->service_version($value) >>

Type: C<String>

Output only. The service version used by the feature.

=item * C<< $msg->firmware_version() >> / C<< $msg->firmware_version($value) >>

Type: C<String>

Output only. The firmware version running on the compatible device used to
collect the data.

=item * C<< $msg->feature_version() >> / C<< $msg->feature_version($value) >>

Type: C<String>

Output only. The version of the feature/app running on the device.

=item * C<< $msg->device_model() >> / C<< $msg->device_model($value) >>

Type: C<String>

Output only. The model name or device type of the compatible device used to
collect the data.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devicesandservices::Health::V4::MedicalDeviceInfo::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
