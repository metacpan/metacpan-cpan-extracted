package Google::Cloud::Securitycenter::V2::CloudDlpDataProfile;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
Cjtnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvY2xvdWRfZGxwX2RhdGFfcHJvZmls
ZS5wcm90bxIeZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyGhlnb29nbGUvYXBpL3Jl
c291cmNlLnByb3RvIo0CChNDbG91ZERscERhdGFQcm9maWxlEksKDGRhdGFfcHJvZmlsZRgB
IAEoCUIo+kElCiNkbHAuZ29vZ2xlYXBpcy5jb20vVGFibGVEYXRhUHJvZmlsZVILZGF0YVBy
b2ZpbGUSXwoLcGFyZW50X3R5cGUYAiABKA4yPi5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50
ZXIudjIuQ2xvdWREbHBEYXRhUHJvZmlsZS5QYXJlbnRUeXBlUgpwYXJlbnRUeXBlIkgKClBh
cmVudFR5cGUSGwoXUEFSRU5UX1RZUEVfVU5TUEVDSUZJRUQQABIQCgxPUkdBTklaQVRJT04Q
ARILCgdQUk9KRUNUEAJClAMKImNvbS5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjJC
GENsb3VkRGxwRGF0YVByb2ZpbGVQcm90b1ABWkpjbG91ZC5nb29nbGUuY29tL2dvL3NlY3Vy
aXR5Y2VudGVyL2FwaXYyL3NlY3VyaXR5Y2VudGVycGI7c2VjdXJpdHljZW50ZXJwYqoCHkdv
b2dsZS5DbG91ZC5TZWN1cml0eUNlbnRlci5WMsoCHkdvb2dsZVxDbG91ZFxTZWN1cml0eUNl
bnRlclxWMuoCIUdvb2dsZTo6Q2xvdWQ6OlNlY3VyaXR5Q2VudGVyOjpWMupBngEKI2RscC5n
b29nbGVhcGlzLmNvbS9UYWJsZURhdGFQcm9maWxlEjBwcm9qZWN0cy97cHJvamVjdH0vdGFi
bGVQcm9maWxlcy97dGFibGVfcHJvZmlsZX0SRXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufS90YWJsZVByb2ZpbGVzL3t0YWJsZV9wcm9maWxlfUqNDAoGEgQOADgB
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
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAnCgkKAgMAEgMS
ACMKCAoBCBIDFAA7CgkKAgglEgMUADsKCAoBCBIDFQBhCgkKAggLEgMVAGEKCAoBCBIDFgAi
CgkKAggKEgMWACIKCAoBCBIDFwA5CgkKAggIEgMXADkKCAoBCBIDGAA7CgkKAggBEgMYADsK
CAoBCBIDGQA7CgkKAggpEgMZADsKCAoBCBIDGgA6CgkKAggtEgMaADoKCQoBCBIEGwAfAgoM
CgQInQgAEgQbAB8CCm8KAgQAEgQjADgBGmMgVGhlIFtkYXRhIHByb2ZpbGVdKGh0dHBzOi8v
Y2xvdWQuZ29vZ2xlLmNvbS9kbHAvZG9jcy9kYXRhLXByb2ZpbGVzKQogYXNzb2NpYXRlZCB3
aXRoIHRoZSBmaW5kaW5nLgoKCgoDBAABEgMjCBsKTgoEBAAEABIEJQIuAxpAIFBhcmVudHMg
Zm9yIGNvbmZpZ3VyYXRpb25zIHRoYXQgcHJvZHVjZSBkYXRhIHByb2ZpbGUgZmluZGluZ3Mu
CgoMCgUEAAQAARIDJQcRCikKBgQABAACABIDJwQgGhogVW5zcGVjaWZpZWQgcGFyZW50IHR5
cGUuCgoOCgcEAAQAAgABEgMnBBsKDgoHBAAEAAIAAhIDJx4fCjMKBgQABAACARIDKgQVGiQg
T3JnYW5pemF0aW9uLWxldmVsIGNvbmZpZ3VyYXRpb25zLgoKDgoHBAAEAAIBARIDKgQQCg4K
BwQABAACAQISAyoTFAouCgYEAAQAAgISAy0EEBofIFByb2plY3QtbGV2ZWwgY29uZmlndXJh
dGlvbnMuCgoOCgcEAAQAAgIBEgMtBAsKDgoHBAAEAAICAhIDLQ4PCm4KBAQAAgASBDICNAUa
YCBOYW1lIG9mIHRoZSBkYXRhIHByb2ZpbGUsIGZvciBleGFtcGxlLAogYHByb2plY3RzLzEy
My9sb2NhdGlvbnMvZXVyb3BlL3RhYmxlUHJvZmlsZXMvODM4MzkyOWAuCgoMCgUEAAIABRID
MgIICgwKBQQAAgABEgMyCRUKDAoFBAACAAMSAzIYGQoNCgUEAAIACBIEMho0BAoPCgcEAAIA
CJ8IEgQyGzQDClQKBAQAAgESAzcCHRpHIFRoZSByZXNvdXJjZSBoaWVyYXJjaHkgbGV2ZWwg
YXQgd2hpY2ggdGhlIGRhdGEgcHJvZmlsZSB3YXMgZ2VuZXJhdGVkLgoKDAoFBAACAQYSAzcC
DAoMCgUEAAIBARIDNw0YCgwKBQQAAgEDEgM3GxxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::CloudDlpDataProfile::CloudDlpDataProfile ===
    # Fields for CloudDlpDataProfile
    # Field: data_profile Type: 9 ()
    # Field: parent_type Type: 14 (.google.cloud.securitycenter.v2.CloudDlpDataProfile.ParentType)

# Enum: CloudDlpDataProfile::ParentType
our $CloudDlpDataProfile_PARENT_TYPE_UNSPECIFIED = 0;
our $CloudDlpDataProfile_ORGANIZATION = 1;
our $CloudDlpDataProfile_PROJECT = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::CloudDlpDataProfile - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/cloud_dlp_data_profile.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::CloudDlpDataProfile;

    my $msg = Google::Cloud::Securitycenter::V2::CloudDlpDataProfile::CloudDlpDataProfile->new({
        data_profile => $data_profile,
        parent_type => $parent_type,
    });

    # Read or update a field
    my $val = $msg->data_profile();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::CloudDlpDataProfile::CloudDlpDataProfile->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/cloud_dlp_data_profile.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::CloudDlpDataProfile::CloudDlpDataProfile

The [data profile](https://cloud.google.com/dlp/docs/data-profiles)
associated with the finding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_profile() >> / C<< $msg->data_profile($value) >>

Type: C<String>

Name of the data profile, for example,
`projects/123/locations/europe/tableProfiles/8383929`.

=item * C<< $msg->parent_type() >> / C<< $msg->parent_type($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V2::CloudDlpDataProfile::ParentType>)

The resource hierarchy level at which the data profile was generated.

=back

=head3 Enum: CloudDlpDataProfile::ParentType

=over 4

=item * C<PARENT_TYPE_UNSPECIFIED> => C<0>

=item * C<ORGANIZATION> => C<1>

=item * C<PROJECT> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::CloudDlpDataProfile::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
