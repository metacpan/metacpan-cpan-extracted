package Google::Actions::Sdk::V2::ConfigFile;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::AccountLinkingSecret };
    eval { require Google::Actions::Sdk::V2::Action };
    eval { require Google::Actions::Sdk::V2::Interactionmodel::EntitySet };
    eval { require Google::Actions::Sdk::V2::Interactionmodel::GlobalIntentEvent };
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Intent };
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticPrompt };
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Scene };
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Type::Type };
    eval { require Google::Actions::Sdk::V2::Manifest };
    eval { require Google::Actions::Sdk::V2::Settings };
    eval { require Google::Actions::Sdk::V2::Webhook };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvYWN0aW9ucy9zZGsvdjIvY29uZmlnX2ZpbGUucHJvdG8SFWdvb2dsZS5hY3Rp
b25zLnNkay52MhoyZ29vZ2xlL2FjdGlvbnMvc2RrL3YyL2FjY291bnRfbGlua2luZ19zZWNy
ZXQucHJvdG8aImdvb2dsZS9hY3Rpb25zL3Nkay92Mi9hY3Rpb24ucHJvdG8aN2dvb2dsZS9h
Y3Rpb25zL3Nkay92Mi9pbnRlcmFjdGlvbm1vZGVsL2VudGl0eV9zZXQucHJvdG8aQGdvb2ds
ZS9hY3Rpb25zL3Nkay92Mi9pbnRlcmFjdGlvbm1vZGVsL2dsb2JhbF9pbnRlbnRfZXZlbnQu
cHJvdG8aM2dvb2dsZS9hY3Rpb25zL3Nkay92Mi9pbnRlcmFjdGlvbm1vZGVsL2ludGVudC5w
cm90bxpBZ29vZ2xlL2FjdGlvbnMvc2RrL3YyL2ludGVyYWN0aW9ubW9kZWwvcHJvbXB0L3N0
YXRpY19wcm9tcHQucHJvdG8aMmdvb2dsZS9hY3Rpb25zL3Nkay92Mi9pbnRlcmFjdGlvbm1v
ZGVsL3NjZW5lLnByb3RvGjZnb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2Rl
bC90eXBlL3R5cGUucHJvdG8aJGdvb2dsZS9hY3Rpb25zL3Nkay92Mi9tYW5pZmVzdC5wcm90
bxokZ29vZ2xlL2FjdGlvbnMvc2RrL3YyL3NldHRpbmdzLnByb3RvGiNnb29nbGUvYWN0aW9u
cy9zZGsvdjIvd2ViaG9vay5wcm90bxocZ29vZ2xlL3Byb3RvYnVmL3N0cnVjdC5wcm90byJT
CgtDb25maWdGaWxlcxJECgxjb25maWdfZmlsZXMYASADKAsyIS5nb29nbGUuYWN0aW9ucy5z
ZGsudjIuQ29uZmlnRmlsZVILY29uZmlnRmlsZXMizwcKCkNvbmZpZ0ZpbGUSGwoJZmlsZV9w
YXRoGAEgASgJUghmaWxlUGF0aBI9CghtYW5pZmVzdBgCIAEoCzIfLmdvb2dsZS5hY3Rpb25z
LnNkay52Mi5NYW5pZmVzdEgAUghtYW5pZmVzdBI6CgdhY3Rpb25zGAMgASgLMh4uZ29vZ2xl
LmFjdGlvbnMuc2RrLnYyLkFjdGlvbnNIAFIHYWN0aW9ucxI9CghzZXR0aW5ncxgEIAEoCzIf
Lmdvb2dsZS5hY3Rpb25zLnNkay52Mi5TZXR0aW5nc0gAUghzZXR0aW5ncxI6Cgd3ZWJob29r
GAYgASgLMh4uZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLldlYmhvb2tIAFIHd2ViaG9vaxJICgZp
bnRlbnQYByABKAsyLi5nb29nbGUuYWN0aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbC5J
bnRlbnRIAFIGaW50ZW50EkcKBHR5cGUYCCABKAsyMS5nb29nbGUuYWN0aW9ucy5zZGsudjIu
aW50ZXJhY3Rpb25tb2RlbC50eXBlLlR5cGVIAFIEdHlwZRJSCgplbnRpdHlfc2V0GA8gASgL
MjEuZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0aW9ubW9kZWwuRW50aXR5U2V0SABS
CWVudGl0eVNldBJrChNnbG9iYWxfaW50ZW50X2V2ZW50GAkgASgLMjkuZ29vZ2xlLmFjdGlv
bnMuc2RrLnYyLmludGVyYWN0aW9ubW9kZWwuR2xvYmFsSW50ZW50RXZlbnRIAFIRZ2xvYmFs
SW50ZW50RXZlbnQSRQoFc2NlbmUYCiABKAsyLS5nb29nbGUuYWN0aW9ucy5zZGsudjIuaW50
ZXJhY3Rpb25tb2RlbC5TY2VuZUgAUgVzY2VuZRJiCg1zdGF0aWNfcHJvbXB0GAsgASgLMjsu
Z29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0aW9ubW9kZWwucHJvbXB0LlN0YXRpY1By
b21wdEgAUgxzdGF0aWNQcm9tcHQSYwoWYWNjb3VudF9saW5raW5nX3NlY3JldBgNIAEoCzIr
Lmdvb2dsZS5hY3Rpb25zLnNkay52Mi5BY2NvdW50TGlua2luZ1NlY3JldEgAUhRhY2NvdW50
TGlua2luZ1NlY3JldBJCCg9yZXNvdXJjZV9idW5kbGUYDCABKAsyFy5nb29nbGUucHJvdG9i
dWYuU3RydWN0SABSDnJlc291cmNlQnVuZGxlQgYKBGZpbGVCaAoZY29tLmdvb2dsZS5hY3Rp
b25zLnNkay52MkIPQ29uZmlnRmlsZVByb3RvUAFaOGdvb2dsZS5nb2xhbmcub3JnL2dlbnBy
b3RvL2dvb2dsZWFwaXMvYWN0aW9ucy9zZGsvdjI7c2RrStceCgYSBA4AbwEKvAQKAQwSAw4A
EjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB4KCQoCAwASAxIAPAoJCgIDARID
EwAsCgkKAgMCEgMUAEEKCQoCAwMSAxUASgoJCgIDBBIDFgA9CgkKAgMFEgMXAEsKCQoCAwYS
AxgAPAoJCgIDBxIDGQBACgkKAgMIEgMaAC4KCQoCAwkSAxsALgoJCgIDChIDHAAtCgkKAgML
EgMdACYKCAoBCBIDHwBPCgkKAggLEgMfAE8KCAoBCBIDIAAiCgkKAggKEgMgACIKCAoBCBID
IQAwCgkKAggIEgMhADAKCAoBCBIDIgAyCgkKAggBEgMiADIKWQoCBAASBCUAKAEaTSBXcmFw
cGVyIGZvciByZXBlYXRlZCBjb25maWcgZmlsZXMuIFJlcGVhdGVkIGZpZWxkcyBjYW5ub3Qg
ZXhpc3QgaW4gYSBvbmVvZi4KCgoKAwQAARIDJQgTCiUKBAQAAgASAycCJxoYIE11bHRpcGxl
IGNvbmZpZyBmaWxlcy4KCgwKBQQAAgAEEgMnAgoKDAoFBAACAAYSAycLFQoMCgUEAAIAARID
JxYiCgwKBQQAAgADEgMnJSYKtwEKAgQBEgQtAG8BGqoBIFJlcHJlc2VudHMgYSBzaW5nbGUg
ZmlsZSB3aGljaCBjb250YWlucyBzdHJ1Y3R1cmVkIGRhdGEuIERldmVsb3BlcnMgY2FuCiBk
ZWZpbmUgbW9zdCBvZiB0aGVpciBwcm9qZWN0IHVzaW5nIHN0cnVjdHVyZWQgY29uZmlnIGlu
Y2x1ZGluZyBBY3Rpb25zLAogU2V0dGluZ3MsIEZ1bGZpbGxtZW50LgoKCgoDBAEBEgMtCBIK
rwEKBAQBAgASAzECFxqhASBSZWxhdGl2ZSBwYXRoIG9mIHRoZSBjb25maWcgZmlsZSBmcm9t
IHRoZSBwcm9qZWN0IHJvb3QgaW4gdGhlIFNESyBmaWxlCiBzdHJ1Y3R1cmUuIEVhY2ggZmls
ZSB0eXBlcyBiZWxvdyBoYXZlIGFuIGFsbG93ZWQgZmlsZSBwYXRoLgogRWc6IHNldHRpbmdz
L3NldHRpbmdzLnlhbWwKCgwKBQQBAgAFEgMxAggKDAoFBAECAAESAzEJEgoMCgUEAQIAAxID
MRUWClgKBAQBCAASBDQCbgMaSiBFYWNoIHR5cGUgb2YgY29uZmlnIGZpbGUgc2hvdWxkIGhh
dmUgYSBjb3JyZXNwb25kaW5nIGZpZWxkIGluIHRoZSBvbmVvZi4KCgwKBQQBCAABEgM0CAwK
SAoEBAECARIDNwQaGjsgU2luZ2xlIG1hbmlmZXN0IGZpbGUuCiBBbGxvd2VkIGZpbGUgcGF0
aDogYG1hbmlmZXN0LnlhbWxgCgoMCgUEAQIBBhIDNwQMCgwKBQQBAgEBEgM3DRUKDAoFBAEC
AQMSAzcYGQp4CgQEAQICEgM7BBgaayBTaW5nbGUgYWN0aW9ucyBmaWxlIHdpdGggYWxsIHRo
ZSBhY3Rpb25zIGRlZmluZWQuCiBBbGxvd2VkIGZpbGUgcGF0aHM6IGBhY3Rpb25zL3tsYW5n
dWFnZX0/L2FjdGlvbnMueWFtbGAKCgwKBQQBAgIGEgM7BAsKDAoFBAECAgESAzsMEwoMCgUE
AQICAxIDOxYXCocDCgQEAQIDEgNEBBoa+QIgU2luZ2xlIHNldHRpbmdzIGNvbmZpZyB3aGlj
aCBpbmNsdWRlcyBub24tbG9jYWxpemFibGUgc2V0dGluZ3MgYW5kCiBzZXR0aW5ncyBmb3Ig
dGhlIHByb2plY3QncyBkZWZhdWx0IGxvY2FsZSAoaWYgc3BlY2lmaWVkKS4KIEZvciBhIGxv
Y2FsZSBvdmVycmlkZSBmaWxlLCBvbmx5IGxvY2FsaXplZF9zZXR0aW5ncyBmaWVsZCB3aWxs
IGJlCiBwb3B1bGF0ZWQuCiBBbGxvd2VkIGZpbGUgcGF0aHM6IGBzZXR0aW5ncy97bGFuZ3Vh
Z2V9Py9zZXR0aW5ncy55YW1sYAogTm90ZSB0aGF0IHRoZSBub24tbG9jYWxpemVkIHNldHRp
bmdzIGZpbGUgYHNldHRpbmdzL3NldHRpbmdzLnlhbWxgIG11c3QKIGJlIHByZXNlbnQgaW4g
dGhlIHdyaXRlIGZsb3cgcmVxdWVzdHMuCgoMCgUEAQIDBhIDRAQMCgwKBQQBAgMBEgNEDRUK
DAoFBAECAwMSA0QYGQpbCgQEAQIEEgNIBBgaTiBTaW5nbGUgd2ViaG9vayBkZWZpbml0aW9u
LgogQWxsb3dlZCBmaWxlIHBhdGg6IGB3ZWJob29rcy97V2ViaG9va05hbWV9LnlhbWxgCgoM
CgUEAQIEBhIDSAQLCgwKBQQBAgQBEgNIDBMKDAoFBAECBAMSA0gWFwpsCgQEAQIFEgNMBD0a
XyBTaW5nbGUgaW50ZW50IGRlZmluaXRpb24uCiBBbGxvd2VkIGZpbGUgcGF0aHM6IGBjdXN0
b20vaW50ZW50cy97bGFuZ3VhZ2V9Py97SW50ZW50TmFtZX0ueWFtbGAKCgwKBQQBAgUGEgNM
BDEKDAoFBAECBQESA0wyOAoMCgUEAQIFAxIDTDs8CmYKBAQBAgYSA1AEPhpZIFNpbmdsZSB0
eXBlIGRlZmluaXRpb24uCiBBbGxvd2VkIGZpbGUgcGF0aHM6IGBjdXN0b20vdHlwZXMve2xh
bmd1YWdlfT8ve1R5cGVOYW1lfS55YW1sYAoKDAoFBAECBgYSA1AENAoMCgUEAQIGARIDUDU5
CgwKBQQBAgYDEgNQPD0KdgoEBAECBxIDVARFGmkgU2luZ2xlIGVudGl0eSBzZXQgZGVmaW5p
dGlvbi4KIEFsbG93ZWQgZmlsZSBwYXRoczogYGN1c3RvbS9lbnRpdHlTZXRzL3tsYW5ndWFn
ZX0/L3tFbnRpdHlTZXROYW1lfS55YW1sYAoKDAoFBAECBwYSA1QENAoMCgUEAQIHARIDVDU/
CgwKBQQBAgcDEgNUQkQK7wEKBAQBAggSA1oEVRrhASBTaW5nbGUgZ2xvYmFsIGludGVudCBl
dmVudCBkZWZpbml0aW9uLgogQWxsb3dlZCBmaWxlIHBhdGhzOiBgY3VzdG9tL2dsb2JhbC97
R2xvYmFsSW50ZW50RXZlbnROYW1lfS55YW1sYAogVGhlIGZpbGUgbmFtZSAoR2xvYmFsSW50
ZW50RXZlbnROYW1lKSBzaG91bGQgYmUgdGhlIG5hbWUgb2YgdGhlIGludGVudAogdGhhdCB0
aGlzIGdsb2JhbCBpbnRlbnQgZXZlbnQgY29ycmVzcG9uZHMgdG8uCgoMCgUEAQIIBhIDWgQ8
CgwKBQQBAggBEgNaPVAKDAoFBAECCAMSA1pTVApdCgQEAQIJEgNeBDwaUCBTaW5nbGUgc2Nl
bmUgZGVmaW5pdGlvbi4KIEFsbG93ZWQgZmlsZSBwYXRoczogYGN1c3RvbS9zY2VuZXMve1Nj
ZW5lTmFtZX0ueWFtbGAKCgwKBQQBAgkGEgNeBDAKDAoFBAECCQESA14xNgoMCgUEAQIJAxID
Xjk7CnkKBAQBAgoSA2IEUhpsIFNpbmdsZSBzdGF0aWMgcHJvbXB0IGRlZmluaXRpb24uCiBB
bGxvd2VkIGZpbGUgcGF0aHM6IGBjdXN0b20vcHJvbXB0cy97bGFuZ3VhZ2V9Py97U3RhdGlj
UHJvbXB0TmFtZX0ueWFtbGAKCgwKBQQBAgoGEgNiBD4KDAoFBAECCgESA2I/TAoMCgUEAQIK
AxIDYk9RCowBCgQEAQILEgNmBDUafyBNZXRhZGF0YSBjb3JyZXNwb25kaW5nIHRvIHRoZSBj
bGllbnQgc2VjcmV0IHVzZWQgaW4gYWNjb3VudCBsaW5raW5nLgogQWxsb3dlZCBmaWxlIHBh
dGg6IGBzZXR0aW5ncy9hY2NvdW50TGlua2luZ1NlY3JldC55YW1sYAoKDAoFBAECCwYSA2YE
GAoMCgUEAQILARIDZhkvCgwKBQQBAgsDEgNmMjQKjwIKBAQBAgwSA20EMBqBAiBTaW5nbGUg
cmVzb3VyY2UgYnVuZGxlLCB3aGljaCBpcyBhIG1hcCBmcm9tIGEgc3RyaW5nIHRvIGEgc3Ry
aW5nIG9yIGxpc3QKIG9mIHN0cmluZ3MuIFJlc291cmNlIGJ1bmRsZXMgY291bGQgYmUgdXNl
ZCBmb3IgbG9jYWxpemluZyBzdHJpbmdzIGluCiBzdGF0aWMgcHJvbXB0cy4KIEFsbG93ZWQg
ZmlsZSBwYXRoczogYHJlc291cmNlcy9zdHJpbmdzL3tsYW5ndWFnZX0/L3ttdWx0aXBsZQog
ZGlyZWN0b3JpZXN9Py97QnVuZGxlTmFtZX0ueWFtbGAKCgwKBQQBAgwGEgNtBBoKDAoFBAEC
DAESA20bKgoMCgUEAQIMAxIDbS0vYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::ConfigFile::ConfigFiles ===
    # Fields for ConfigFiles
    # Field: config_files Type: 11 (.google.actions.sdk.v2.ConfigFile)

# === Message: Google::Actions::Sdk::V2::ConfigFile::ConfigFile ===
    # Fields for ConfigFile
    # Field: file_path Type: 9 ()
    # Field: manifest Type: 11 (.google.actions.sdk.v2.Manifest)
    # Field: actions Type: 11 (.google.actions.sdk.v2.Actions)
    # Field: settings Type: 11 (.google.actions.sdk.v2.Settings)
    # Field: webhook Type: 11 (.google.actions.sdk.v2.Webhook)
    # Field: intent Type: 11 (.google.actions.sdk.v2.interactionmodel.Intent)
    # Field: type Type: 11 (.google.actions.sdk.v2.interactionmodel.type.Type)
    # Field: entity_set Type: 11 (.google.actions.sdk.v2.interactionmodel.EntitySet)
    # Field: global_intent_event Type: 11 (.google.actions.sdk.v2.interactionmodel.GlobalIntentEvent)
    # Field: scene Type: 11 (.google.actions.sdk.v2.interactionmodel.Scene)
    # Field: static_prompt Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.StaticPrompt)
    # Field: account_linking_secret Type: 11 (.google.actions.sdk.v2.AccountLinkingSecret)
    # Field: resource_bundle Type: 11 (.google.protobuf.Struct)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::ConfigFile - Compiled Protocol Buffers messages for google/actions/sdk/v2/config_file.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::ConfigFile;

    my $msg = Google::Actions::Sdk::V2::ConfigFile::ConfigFiles->new({
        config_files => $config_files,
    });

    # Read or update a field
    my $val = $msg->config_files();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::ConfigFile::ConfigFiles->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/config_file.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::ConfigFile::ConfigFiles

Wrapper for repeated config files. Repeated fields cannot exist in a oneof.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->config_files() >> / C<< $msg->config_files($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::ConfigFile::ConfigFile>)

Multiple config files.

=back

=head2 Google::Actions::Sdk::V2::ConfigFile::ConfigFile

Represents a single file which contains structured data. Developers can
define most of their project using structured config including Actions,
Settings, Fulfillment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->file_path() >> / C<< $msg->file_path($value) >>

Type: C<String>

Relative path of the config file from the project root in the SDK file
structure. Each file types below have an allowed file path.
Eg: settings/settings.yaml

=item * C<< $msg->manifest() >> / C<< $msg->manifest($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Manifest::Manifest>)

Single manifest file.
Allowed file path: `manifest.yaml`

=item * C<< $msg->actions() >> / C<< $msg->actions($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Action::Actions>)

Single actions file with all the actions defined.
Allowed file paths: `actions/{language}?/actions.yaml`

=item * C<< $msg->settings() >> / C<< $msg->settings($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Settings::Settings>)

Single settings config which includes non-localizable settings and
settings for the project's default locale (if specified).
For a locale override file, only localized_settings field will be
populated.
Allowed file paths: `settings/{language}?/settings.yaml`
Note that the non-localized settings file `settings/settings.yaml` must
be present in the write flow requests.

=item * C<< $msg->webhook() >> / C<< $msg->webhook($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Webhook::Webhook>)

Single webhook definition.
Allowed file path: `webhooks/{WebhookName}.yaml`

=item * C<< $msg->intent() >> / C<< $msg->intent($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Intent::Intent>)

Single intent definition.
Allowed file paths: `custom/intents/{language}?/{IntentName}.yaml`

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Type::Type::Type>)

Single type definition.
Allowed file paths: `custom/types/{language}?/{TypeName}.yaml`

=item * C<< $msg->entity_set() >> / C<< $msg->entity_set($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::EntitySet::EntitySet>)

Single entity set definition.
Allowed file paths: `custom/entitySets/{language}?/{EntitySetName}.yaml`

=item * C<< $msg->global_intent_event() >> / C<< $msg->global_intent_event($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::GlobalIntentEvent::GlobalIntentEvent>)

Single global intent event definition.
Allowed file paths: `custom/global/{GlobalIntentEventName}.yaml`
The file name (GlobalIntentEventName) should be the name of the intent
that this global intent event corresponds to.

=item * C<< $msg->scene() >> / C<< $msg->scene($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Scene::Scene>)

Single scene definition.
Allowed file paths: `custom/scenes/{SceneName}.yaml`

=item * C<< $msg->static_prompt() >> / C<< $msg->static_prompt($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticPrompt::StaticPrompt>)

Single static prompt definition.
Allowed file paths: `custom/prompts/{language}?/{StaticPromptName}.yaml`

=item * C<< $msg->account_linking_secret() >> / C<< $msg->account_linking_secret($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::AccountLinkingSecret::AccountLinkingSecret>)

Metadata corresponding to the client secret used in account linking.
Allowed file path: `settings/accountLinkingSecret.yaml`

=item * C<< $msg->resource_bundle() >> / C<< $msg->resource_bundle($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Single resource bundle, which is a map from a string to a string or list
of strings. Resource bundles could be used for localizing strings in
static prompts.
Allowed file paths: `resources/strings/{language}?/{multiple
directories}?/{BundleName}.yaml`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::ConfigFile::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
