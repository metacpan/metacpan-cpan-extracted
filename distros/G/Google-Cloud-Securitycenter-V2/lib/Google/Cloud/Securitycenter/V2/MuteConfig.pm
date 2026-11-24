package Google::Cloud::Securitycenter::V2::MuteConfig;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvbXV0ZV9jb25maWcucHJvdG8SHmdv
b2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3Rp
bWVzdGFtcC5wcm90byKrBwoKTXV0ZUNvbmZpZxIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUS
IAoLZGVzY3JpcHRpb24YAiABKAlSC2Rlc2NyaXB0aW9uEhsKBmZpbHRlchgDIAEoCUID4EEC
UgZmaWx0ZXISQAoLY3JlYXRlX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYBSABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSMQoSbW9zdF9yZWNlbnRfZWRpdG9y
GAYgASgJQgPgQQNSEG1vc3RSZWNlbnRFZGl0b3ISUgoEdHlwZRgIIAEoDjI5Lmdvb2dsZS5j
bG91ZC5zZWN1cml0eWNlbnRlci52Mi5NdXRlQ29uZmlnLk11dGVDb25maWdUeXBlQgPgQQJS
BHR5cGUSQAoLZXhwaXJ5X3RpbWUYCSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1w
QgPgQQFSCmV4cGlyeVRpbWUiSwoOTXV0ZUNvbmZpZ1R5cGUSIAocTVVURV9DT05GSUdfVFlQ
RV9VTlNQRUNJRklFRBAAEgoKBlNUQVRJQxABEgsKB0RZTkFNSUMQAjqqA+pBpgMKKHNlY3Vy
aXR5Y2VudGVyLmdvb2dsZWFwaXMuY29tL011dGVDb25maWcSNm9yZ2FuaXphdGlvbnMve29y
Z2FuaXphdGlvbn0vbXV0ZUNvbmZpZ3Mve211dGVfY29uZmlnfRJLb3JnYW5pemF0aW9ucy97
b3JnYW5pemF0aW9ufS9sb2NhdGlvbnMve2xvY2F0aW9ufS9tdXRlQ29uZmlncy97bXV0ZV9j
b25maWd9Eipmb2xkZXJzL3tmb2xkZXJ9L211dGVDb25maWdzL3ttdXRlX2NvbmZpZ30SP2Zv
bGRlcnMve2ZvbGRlcn0vbG9jYXRpb25zL3tsb2NhdGlvbn0vbXV0ZUNvbmZpZ3Mve211dGVf
Y29uZmlnfRIscHJvamVjdHMve3Byb2plY3R9L211dGVDb25maWdzL3ttdXRlX2NvbmZpZ30S
QXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9tdXRlQ29uZmlncy97
bXV0ZV9jb25maWd9KgttdXRlQ29uZmlnczIKbXV0ZUNvbmZpZ0LpAQoiY29tLmdvb2dsZS5j
bG91ZC5zZWN1cml0eWNlbnRlci52MkIPTXV0ZUNvbmZpZ1Byb3RvUAFaSmNsb3VkLmdvb2ds
ZS5jb20vZ28vc2VjdXJpdHljZW50ZXIvYXBpdjIvc2VjdXJpdHljZW50ZXJwYjtzZWN1cml0
eWNlbnRlcnBiqgIeR29vZ2xlLkNsb3VkLlNlY3VyaXR5Q2VudGVyLlYyygIeR29vZ2xlXENs
b3VkXFNlY3VyaXR5Q2VudGVyXFYy6gIhR29vZ2xlOjpDbG91ZDo6U2VjdXJpdHlDZW50ZXI6
OlYySrMjCgYSBA4AfwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQACcKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACkKCAoBCBIDFgA7CgkKAggl
EgMWADsKCAoBCBIDFwBhCgkKAggLEgMXAGEKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBID
GQAwCgkKAggIEgMZADAKCAoBCBIDGgA7CgkKAggBEgMaADsKCAoBCBIDGwA7CgkKAggpEgMb
ADsKCAoBCBIDHAA6CgkKAggtEgMcADoKfgoCBAASBCAAfwEaciBBIG11dGUgY29uZmlnIGlz
IGEgQ2xvdWQgU0NDIHJlc291cmNlIHRoYXQgY29udGFpbnMgdGhlIGNvbmZpZ3VyYXRpb24K
IHRvIG11dGUgY3JlYXRlL3VwZGF0ZSBldmVudHMgb2YgZmluZGluZ3MuCgoKCgMEAAESAyAI
EgoLCgMEAAcSBCECKwQKDQoFBAAHnQgSBCECKwQKJwoEBAAEABIELgI+AxoZIFRoZSB0eXBl
IG9mIE11dGVDb25maWcuCgoMCgUEAAQAARIDLgcVChgKBgQABAACABIDMAQlGgkgVW51c2Vk
LgoKDgoHBAAEAAIAARIDMAQgCg4KBwQABAACAAISAzAjJArUAQoGBAAEAAIBEgM1BA8axAEg
QSBzdGF0aWMgbXV0ZSBjb25maWcsIHdoaWNoIHNldHMgdGhlIHN0YXRpYyBtdXRlIHN0YXRl
IG9mIGZ1dHVyZSBtYXRjaGluZwogZmluZGluZ3MgdG8gbXV0ZWQuIE9uY2UgdGhlIHN0YXRp
YyBtdXRlIHN0YXRlIGhhcyBiZWVuIHNldCwgZmluZGluZyBvcgogY29uZmlnIG1vZGlmaWNh
dGlvbnMgd2lsbCBub3QgYWZmZWN0IHRoZSBzdGF0ZS4KCg4KBwQABAACAQESAzUECgoOCgcE
AAQAAgECEgM1DQ4KlwMKBgQABAACAhIDPQQQGocDIEEgZHluYW1pYyBtdXRlIGNvbmZpZywg
d2hpY2ggaXMgYXBwbGllZCB0byBleGlzdGluZyBhbmQgZnV0dXJlIG1hdGNoaW5nCiBmaW5k
aW5ncywgc2V0dGluZyB0aGVpciBkeW5hbWljIG11dGUgc3RhdGUgdG8gIm11dGVkIi4gSWYg
dGhlIGNvbmZpZyBpcwogdXBkYXRlZCBvciBkZWxldGVkLCBvciBhIG1hdGNoaW5nIGZpbmRp
bmcgaXMgdXBkYXRlZCwgc3VjaCB0aGF0IHRoZQogZmluZGluZyBkb2Vzbid0IG1hdGNoIHRo
ZSBjb25maWcsIHRoZSBjb25maWcgd2lsbCBiZSByZW1vdmVkIGZyb20gdGhlCiBmaW5kaW5n
LCBhbmQgdGhlIGZpbmRpbmcncyBkeW5hbWljIG11dGUgc3RhdGUgbWF5IGJlY29tZSAidW5t
dXRlZCIKICh1bmxlc3Mgb3RoZXIgY29uZmlncyBzdGlsbCBtYXRjaCkuCgoOCgcEAAQAAgIB
EgM9BAsKDgoHBAAEAAICAhIDPQ4PCooECgQEAAIAEgNKAj0a/AMgSWRlbnRpZmllci4gVGhp
cyBmaWVsZCB3aWxsIGJlIGlnbm9yZWQgaWYgcHJvdmlkZWQgb24gY29uZmlnIGNyZWF0aW9u
LiBUaGUKIGZvbGxvd2luZyBsaXN0IHNob3dzIHNvbWUgZXhhbXBsZXMgb2YgdGhlIGZvcm1h
dDoKCiArIGBvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb259L211dGVDb25maWdzL3ttdXRl
X2NvbmZpZ31gCiArCiBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufWxvY2F0aW9ucy97
bG9jYXRpb259Ly9tdXRlQ29uZmlncy97bXV0ZV9jb25maWd9YAogKyBgZm9sZGVycy97Zm9s
ZGVyfS9tdXRlQ29uZmlncy97bXV0ZV9jb25maWd9YAogKyBgZm9sZGVycy97Zm9sZGVyfS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9tdXRlQ29uZmlncy97bXV0ZV9jb25maWd9YAogKyBgcHJv
amVjdHMve3Byb2plY3R9L211dGVDb25maWdzL3ttdXRlX2NvbmZpZ31gCiArIGBwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vbXV0ZUNvbmZpZ3Mve211dGVfY29u
ZmlnfWAKCgwKBQQAAgAFEgNKAggKDAoFBAACAAESA0oJDQoMCgUEAAIAAxIDShARCgwKBQQA
AgAIEgNKEjwKDwoIBAACAAicCAASA0oTOwowCgQEAAIBEgNNAhkaIyBBIGRlc2NyaXB0aW9u
IG9mIHRoZSBtdXRlIGNvbmZpZy4KCgwKBQQAAgEFEgNNAggKDAoFBAACAQESA00JFAoMCgUE
AAIBAxIDTRcYCpsGCgQEAAICEgNjAj0ajQYgUmVxdWlyZWQuIEFuIGV4cHJlc3Npb24gdGhh
dCBkZWZpbmVzIHRoZSBmaWx0ZXIgdG8gYXBwbHkgYWNyb3NzCiBjcmVhdGUvdXBkYXRlIGV2
ZW50cyBvZiBmaW5kaW5ncy4gV2hpbGUgY3JlYXRpbmcgYSBmaWx0ZXIgc3RyaW5nLCBiZQog
bWluZGZ1bCBvZiB0aGUgc2NvcGUgaW4gd2hpY2ggdGhlIG11dGUgY29uZmlndXJhdGlvbiBp
cyBiZWluZyBjcmVhdGVkLgogRS5nLiwgSWYgYSBmaWx0ZXIgY29udGFpbnMgcHJvamVjdCA9
IFggYnV0IGlzIGNyZWF0ZWQgdW5kZXIgdGhlIHByb2plY3QgPSBZCiBzY29wZSwgaXQgbWln
aHQgbm90IG1hdGNoIGFueSBmaW5kaW5ncy4KCiBUaGUgZm9sbG93aW5nIGZpZWxkIGFuZCBv
cGVyYXRvciBjb21iaW5hdGlvbnMgYXJlIHN1cHBvcnRlZDoKCiAqIHNldmVyaXR5OiBgPWAs
IGA6YAogKiBjYXRlZ29yeTogYD1gLCBgOmAKICogcmVzb3VyY2UubmFtZTogYD1gLCBgOmAK
ICogcmVzb3VyY2UucHJvamVjdF9uYW1lOiBgPWAsIGA6YAogKiByZXNvdXJjZS5wcm9qZWN0
X2Rpc3BsYXlfbmFtZTogYD1gLCBgOmAKICogcmVzb3VyY2UuZm9sZGVycy5yZXNvdXJjZV9m
b2xkZXI6IGA9YCwgYDpgCiAqIHJlc291cmNlLnBhcmVudF9uYW1lOiBgPWAsIGA6YAogKiBy
ZXNvdXJjZS5wYXJlbnRfZGlzcGxheV9uYW1lOiBgPWAsIGA6YAogKiByZXNvdXJjZS50eXBl
OiBgPWAsIGA6YAogKiBmaW5kaW5nX2NsYXNzOiBgPWAsIGA6YAogKiBpbmRpY2F0b3IuaXBf
YWRkcmVzc2VzOiBgPWAsIGA6YAogKiBpbmRpY2F0b3IuZG9tYWluczogYD1gLCBgOmAKCgwK
BQQAAgIFEgNjAggKDAoFBAACAgESA2MJDwoMCgUEAAICAxIDYxITCgwKBQQAAgIIEgNjFDwK
DwoIBAACAgicCAASA2MVOwqiAQoEBAACAxIEaAJpMhqTASBPdXRwdXQgb25seS4gVGhlIHRp
bWUgYXQgd2hpY2ggdGhlIG11dGUgY29uZmlnIHdhcyBjcmVhdGVkLgogVGhpcyBmaWVsZCBp
cyBzZXQgYnkgdGhlIHNlcnZlciBhbmQgd2lsbCBiZSBpZ25vcmVkIGlmIHByb3ZpZGVkIG9u
IGNvbmZpZwogY3JlYXRpb24uCgoMCgUEAAIDBhIDaAIbCgwKBQQAAgMBEgNoHCcKDAoFBAAC
AwMSA2gqKwoMCgUEAAIDCBIDaQYxCg8KCAQAAgMInAgAEgNpBzAKuAEKBAQAAgQSBG4CbzIa
qQEgT3V0cHV0IG9ubHkuIFRoZSBtb3N0IHJlY2VudCB0aW1lIGF0IHdoaWNoIHRoZSBtdXRl
IGNvbmZpZyB3YXMgdXBkYXRlZC4KIFRoaXMgZmllbGQgaXMgc2V0IGJ5IHRoZSBzZXJ2ZXIg
YW5kIHdpbGwgYmUgaWdub3JlZCBpZiBwcm92aWRlZCBvbiBjb25maWcKIGNyZWF0aW9uIG9y
IHVwZGF0ZS4KCgwKBQQAAgQGEgNuAhsKDAoFBAACBAESA24cJwoMCgUEAAIEAxIDbiorCgwK
BQQAAgQIEgNvBjEKDwoIBAACBAicCAASA28HMAq3AQoEBAACBRIDdAJMGqkBIE91dHB1dCBv
bmx5LiBFbWFpbCBhZGRyZXNzIG9mIHRoZSB1c2VyIHdobyBsYXN0IGVkaXRlZCB0aGUgbXV0
ZSBjb25maWcuCiBUaGlzIGZpZWxkIGlzIHNldCBieSB0aGUgc2VydmVyIGFuZCB3aWxsIGJl
IGlnbm9yZWQgaWYgcHJvdmlkZWQgb24gY29uZmlnCiBjcmVhdGlvbiBvciB1cGRhdGUuCgoM
CgUEAAIFBRIDdAIICgwKBQQAAgUBEgN0CRsKDAoFBAACBQMSA3QeHwoMCgUEAAIFCBIDdCBL
Cg8KCAQAAgUInAgAEgN0IUoKjgEKBAQAAgYSA3gCQxqAASBSZXF1aXJlZC4gVGhlIHR5cGUg
b2YgdGhlIG11dGUgY29uZmlnLCB3aGljaCBkZXRlcm1pbmVzIHdoYXQgdHlwZSBvZiBtdXRl
CiBzdGF0ZSB0aGUgY29uZmlnIGFmZmVjdHMuIEltbXV0YWJsZSBhZnRlciBjcmVhdGlvbi4K
CgwKBQQAAgYGEgN4AhAKDAoFBAACBgESA3gRFQoMCgUEAAIGAxIDeBgZCgwKBQQAAgYIEgN4
GkIKDwoIBAACBgicCAASA3gbQQqwAQoEBAACBxIEfQJ+LxqhASBPcHRpb25hbC4gVGhlIGV4
cGlyeSBvZiB0aGUgbXV0ZSBjb25maWcuIE9ubHkgYXBwbGljYWJsZSBmb3IgZHluYW1pYwog
Y29uZmlncy4gSWYgdGhlIGV4cGlyeSBpcyBzZXQsIHdoZW4gdGhlIGNvbmZpZyBleHBpcmVz
LCBpdCBpcyByZW1vdmVkIGZyb20KIGFsbCBmaW5kaW5ncy4KCgwKBQQAAgcGEgN9AhsKDAoF
BAACBwESA30cJwoMCgUEAAIHAxIDfSorCgwKBQQAAgcIEgN+Bi4KDwoIBAACBwicCAASA34H
LWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::MuteConfig::MuteConfig ===
    # Fields for MuteConfig
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: most_recent_editor Type: 9 ()
    # Field: type Type: 14 (.google.cloud.securitycenter.v2.MuteConfig.MuteConfigType)
    # Field: expiry_time Type: 11 (.google.protobuf.Timestamp)

# Enum: MuteConfig::MuteConfigType
our $MuteConfig_MUTE_CONFIG_TYPE_UNSPECIFIED = 0;
our $MuteConfig_STATIC = 1;
our $MuteConfig_DYNAMIC = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::MuteConfig - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/mute_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::MuteConfig;

    my $msg = Google::Cloud::Securitycenter::V2::MuteConfig::MuteConfig->new({
        name => $name,
        description => $description,
        filter => $filter,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::MuteConfig::MuteConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/mute_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::MuteConfig::MuteConfig

A mute config is a Cloud SCC resource that contains the configuration
to mute create/update events of findings.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. This field will be ignored if provided on config creation. The
following list shows some examples of the format:

+ `organizations/{organization}/muteConfigs/{mute_config}`
+
`organizations/{organization}locations/{location}//muteConfigs/{mute_config}`
+ `folders/{folder}/muteConfigs/{mute_config}`
+ `folders/{folder}/locations/{location}/muteConfigs/{mute_config}`
+ `projects/{project}/muteConfigs/{mute_config}`
+ `projects/{project}/locations/{location}/muteConfigs/{mute_config}`

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A description of the mute config.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Required. An expression that defines the filter to apply across
create/update events of findings. While creating a filter string, be
mindful of the scope in which the mute configuration is being created.
E.g., If a filter contains project = X but is created under the project = Y
scope, it might not match any findings.

The following field and operator combinations are supported:

* severity: `=`, `:`
* category: `=`, `:`
* resource.name: `=`, `:`
* resource.project_name: `=`, `:`
* resource.project_display_name: `=`, `:`
* resource.folders.resource_folder: `=`, `:`
* resource.parent_name: `=`, `:`
* resource.parent_display_name: `=`, `:`
* resource.type: `=`, `:`
* finding_class: `=`, `:`
* indicator.ip_addresses: `=`, `:`
* indicator.domains: `=`, `:`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which the mute config was created.
This field is set by the server and will be ignored if provided on config
creation.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The most recent time at which the mute config was updated.
This field is set by the server and will be ignored if provided on config
creation or update.

=item * C<< $msg->most_recent_editor() >> / C<< $msg->most_recent_editor($value) >>

Type: C<String>

Output only. Email address of the user who last edited the mute config.
This field is set by the server and will be ignored if provided on config
creation or update.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V2::MuteConfig::MuteConfigType>)

Required. The type of the mute config, which determines what type of mute
state the config affects. Immutable after creation.

=item * C<< $msg->expiry_time() >> / C<< $msg->expiry_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Optional. The expiry of the mute config. Only applicable for dynamic
configs. If the expiry is set, when the config expires, it is removed from
all findings.

=back

=head3 Enum: MuteConfig::MuteConfigType

=over 4

=item * C<MUTE_CONFIG_TYPE_UNSPECIFIED> => C<0>

=item * C<STATIC> => C<1>

=item * C<DYNAMIC> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::MuteConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
