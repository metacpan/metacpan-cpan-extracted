package Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomModule;

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
    eval { require Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ckxnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvc2VjdXJpdHlfaGVhbHRoX2FuYWx5
dGljc19jdXN0b21fbW9kdWxlLnByb3RvEh5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIu
djEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3Vy
Y2UucHJvdG8aTGdvb2dsZS9jbG91ZC9zZWN1cml0eWNlbnRlci92MS9zZWN1cml0eV9oZWFs
dGhfYW5hbHl0aWNzX2N1c3RvbV9jb25maWcucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1l
c3RhbXAucHJvdG8itwcKI1NlY3VyaXR5SGVhbHRoQW5hbHl0aWNzQ3VzdG9tTW9kdWxlEhcK
BG5hbWUYASABKAlCA+BBBVIEbmFtZRIhCgxkaXNwbGF5X25hbWUYAiABKAlSC2Rpc3BsYXlO
YW1lEn4KEGVuYWJsZW1lbnRfc3RhdGUYBCABKA4yUy5nb29nbGUuY2xvdWQuc2VjdXJpdHlj
ZW50ZXIudjEuU2VjdXJpdHlIZWFsdGhBbmFseXRpY3NDdXN0b21Nb2R1bGUuRW5hYmxlbWVu
dFN0YXRlUg9lbmFibGVtZW50U3RhdGUSQAoLdXBkYXRlX3RpbWUYBSABKAsyGi5nb29nbGUu
cHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSJAoLbGFzdF9lZGl0b3IYBiAB
KAlCA+BBA1IKbGFzdEVkaXRvchJyCg9hbmNlc3Rvcl9tb2R1bGUYByABKAlCSeBBA/pBQwpB
c2VjdXJpdHljZW50ZXIuZ29vZ2xlYXBpcy5jb20vU2VjdXJpdHlIZWFsdGhBbmFseXRpY3ND
dXN0b21Nb2R1bGVSDmFuY2VzdG9yTW9kdWxlElEKDWN1c3RvbV9jb25maWcYCCABKAsyLC5n
b29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEuQ3VzdG9tQ29uZmlnUgxjdXN0b21Db25m
aWciXQoPRW5hYmxlbWVudFN0YXRlEiAKHEVOQUJMRU1FTlRfU1RBVEVfVU5TUEVDSUZJRUQQ
ABILCgdFTkFCTEVEEAESDAoIRElTQUJMRUQQAhINCglJTkhFUklURUQQAzrFAupBwQIKQXNl
Y3VyaXR5Y2VudGVyLmdvb2dsZWFwaXMuY29tL1NlY3VyaXR5SGVhbHRoQW5hbHl0aWNzQ3Vz
dG9tTW9kdWxlElpvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb259L3NlY3VyaXR5SGVhbHRo
QW5hbHl0aWNzU2V0dGluZ3MvY3VzdG9tTW9kdWxlcy97Y3VzdG9tX21vZHVsZX0STmZvbGRl
cnMve2ZvbGRlcn0vc2VjdXJpdHlIZWFsdGhBbmFseXRpY3NTZXR0aW5ncy9jdXN0b21Nb2R1
bGVzL3tjdXN0b21fbW9kdWxlfRJQcHJvamVjdHMve3Byb2plY3R9L3NlY3VyaXR5SGVhbHRo
QW5hbHl0aWNzU2V0dGluZ3MvY3VzdG9tTW9kdWxlcy97Y3VzdG9tX21vZHVsZX1C6QMKImNv
bS5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjFCKFNlY3VyaXR5SGVhbHRoQW5hbHl0
aWNzQ3VzdG9tTW9kdWxlUHJvdG9QAVpKY2xvdWQuZ29vZ2xlLmNvbS9nby9zZWN1cml0eWNl
bnRlci9hcGl2MS9zZWN1cml0eWNlbnRlcnBiO3NlY3VyaXR5Y2VudGVycGKqAh5Hb29nbGUu
Q2xvdWQuU2VjdXJpdHlDZW50ZXIuVjHKAh5Hb29nbGVcQ2xvdWRcU2VjdXJpdHlDZW50ZXJc
VjHqAiFHb29nbGU6OkNsb3VkOjpTZWN1cml0eUNlbnRlcjo6VjHqQeMBCj1zZWN1cml0eWNl
bnRlci5nb29nbGVhcGlzLmNvbS9TZWN1cml0eUhlYWx0aEFuYWx5dGljc1NldHRpbmdzEjxv
cmdhbml6YXRpb25zL3tvcmdhbml6YXRpb259L3NlY3VyaXR5SGVhbHRoQW5hbHl0aWNzU2V0
dGluZ3MSMGZvbGRlcnMve2ZvbGRlcn0vc2VjdXJpdHlIZWFsdGhBbmFseXRpY3NTZXR0aW5n
cxIycHJvamVjdHMve3Byb2plY3R9L3NlY3VyaXR5SGVhbHRoQW5hbHl0aWNzU2V0dGluZ3NK
phwKBhIEDgBtAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
JwoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAVgoJCgIDAxIDFQApCggKAQgSAxcA
OwoJCgIIJRIDFwA7CggKAQgSAxgAYQoJCgIICxIDGABhCggKAQgSAxkAIgoJCgIIChIDGQAi
CggKAQgSAxoASQoJCgIICBIDGgBJCggKAQgSAxsAOwoJCgIIARIDGwA7CggKAQgSAxwAOwoJ
CgIIKRIDHAA7CggKAQgSAx0AOgoJCgIILRIDHQA6CgkKAQgSBB4AIwIKDAoECJ0IABIEHgAj
AgrwAgoCBAASBCoAbQEa4wIgUmVwcmVzZW50cyBhbiBpbnN0YW5jZSBvZiBhIFNlY3VyaXR5
IEhlYWx0aCBBbmFseXRpY3MgY3VzdG9tIG1vZHVsZSwKIGluY2x1ZGluZyBpdHMgZnVsbCBt
b2R1bGUgbmFtZSwgZGlzcGxheSBuYW1lLCBlbmFibGVtZW50IHN0YXRlLCBhbmQgbGFzdAog
dXBkYXRlZCB0aW1lLiBZb3UgY2FuIGNyZWF0ZSBhIGN1c3RvbSBtb2R1bGUgYXQgdGhlIG9y
Z2FuaXphdGlvbiwgZm9sZGVyLCBvcgogcHJvamVjdCBsZXZlbC4gQ3VzdG9tIG1vZHVsZXMg
dGhhdCB5b3UgY3JlYXRlIGF0IHRoZSBvcmdhbml6YXRpb24gb3IgZm9sZGVyCiBsZXZlbCBh
cmUgaW5oZXJpdGVkIGJ5IHRoZSBjaGlsZCBmb2xkZXJzIGFuZCBwcm9qZWN0cy4KCgoKAwQA
ARIDKggrCgsKAwQABxIEKwIwBAoNCgUEAAedCBIEKwIwBAo+CgQEAAQAEgQzAkEDGjAgUG9z
c2libGUgZW5hYmxlbWVudCBzdGF0ZXMgb2YgYSBjdXN0b20gbW9kdWxlLgoKDAoFBAAEAAES
AzMHFgouCgYEAAQAAgASAzUEJRofIFVuc3BlY2lmaWVkIGVuYWJsZW1lbnQgc3RhdGUuCgoO
CgcEAAQAAgABEgM1BCAKDgoHBAAEAAIAAhIDNSMkCkEKBgQABAACARIDOAQQGjIgVGhlIG1v
ZHVsZSBpcyBlbmFibGVkIGF0IHRoZSBnaXZlbiBDUk0gcmVzb3VyY2UuCgoOCgcEAAQAAgEB
EgM4BAsKDgoHBAAEAAIBAhIDOA4PCkIKBgQABAACAhIDOwQRGjMgVGhlIG1vZHVsZSBpcyBk
aXNhYmxlZCBhdCB0aGUgZ2l2ZW4gQ1JNIHJlc291cmNlLgoKDgoHBAAEAAICARIDOwQMCg4K
BwQABAACAgISAzsPEArCAQoGBAAEAAIDEgNABBIasgEgU3RhdGUgaXMgaW5oZXJpdGVkIGZy
b20gYW4gYW5jZXN0b3IgbW9kdWxlLiBUaGUgbW9kdWxlIHdpbGwgZWl0aGVyCiBiZSBlZmZl
Y3RpdmVseSBFTkFCTEVEIG9yIERJU0FCTEVEIGJhc2VkIG9uIGl0cyBjbG9zZXN0IG5vbi1p
bmhlcml0ZWQKIGFuY2VzdG9yIG1vZHVsZSBpbiB0aGUgQ1JNIGhpZXJhcmNoeS4KCg4KBwQA
BAACAwESA0AEDQoOCgcEAAQAAgMCEgNAEBEK0wMKBAQAAgASA00CPBrFAyBJbW11dGFibGUu
IFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBjdXN0b20gbW9kdWxlLgogSXRzIGZvcm1hdCBp
cwogIm9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vc2VjdXJpdHlIZWFsdGhBbmFseXRp
Y3NTZXR0aW5ncy9jdXN0b21Nb2R1bGVzL3tjdXN0b21Nb2R1bGV9IiwKIG9yCiAiZm9sZGVy
cy97Zm9sZGVyfS9zZWN1cml0eUhlYWx0aEFuYWx5dGljc1NldHRpbmdzL2N1c3RvbU1vZHVs
ZXMve2N1c3RvbU1vZHVsZX0iLAogb3IKICJwcm9qZWN0cy97cHJvamVjdH0vc2VjdXJpdHlI
ZWFsdGhBbmFseXRpY3NTZXR0aW5ncy9jdXN0b21Nb2R1bGVzL3tjdXN0b21Nb2R1bGV9IgoK
IFRoZSBpZCB7Y3VzdG9tTW9kdWxlfSBpcyBzZXJ2ZXItZ2VuZXJhdGVkIGFuZCBpcyBub3Qg
dXNlciBzZXR0YWJsZS4KIEl0IHdpbGwgYmUgYSBudW1lcmljIGlkIGNvbnRhaW5pbmcgMS0y
MCBkaWdpdHMuCgoMCgUEAAIABRIDTQIICgwKBQQAAgABEgNNCQ0KDAoFBAACAAMSA00QEQoM
CgUEAAIACBIDTRI7Cg8KCAQAAgAInAgAEgNNEzoKzAIKBAQAAgESA1QCGhq+AiBUaGUgZGlz
cGxheSBuYW1lIG9mIHRoZSBTZWN1cml0eSBIZWFsdGggQW5hbHl0aWNzIGN1c3RvbSBtb2R1
bGUuIFRoaXMKIGRpc3BsYXkgbmFtZSBiZWNvbWVzIHRoZSBmaW5kaW5nIGNhdGVnb3J5IGZv
ciBhbGwgZmluZGluZ3MgdGhhdCBhcmUKIHJldHVybmVkIGJ5IHRoaXMgY3VzdG9tIG1vZHVs
ZS4gVGhlIGRpc3BsYXkgbmFtZSBtdXN0IGJlIGJldHdlZW4gMSBhbmQKIDEyOCBjaGFyYWN0
ZXJzLCBzdGFydCB3aXRoIGEgbG93ZXJjYXNlIGxldHRlciwgYW5kIGNvbnRhaW4gYWxwaGFu
dW1lcmljCiBjaGFyYWN0ZXJzIG9yIHVuZGVyc2NvcmVzIG9ubHkuCgoMCgUEAAIBBRIDVAII
CgwKBQQAAgEBEgNUCRUKDAoFBAACAQMSA1QYGQo5CgQEAAICEgNXAicaLCBUaGUgZW5hYmxl
bWVudCBzdGF0ZSBvZiB0aGUgY3VzdG9tIG1vZHVsZS4KCgwKBQQAAgIGEgNXAhEKDAoFBAAC
AgESA1cSIgoMCgUEAAICAxIDVyUmClIKBAQAAgMSBFoCWzIaRCBPdXRwdXQgb25seS4gVGhl
IHRpbWUgYXQgd2hpY2ggdGhlIGN1c3RvbSBtb2R1bGUgd2FzIGxhc3QgdXBkYXRlZC4KCgwK
BQQAAgMGEgNaAhsKDAoFBAACAwESA1ocJwoMCgUEAAIDAxIDWiorCgwKBQQAAgMIEgNbBjEK
DwoIBAACAwicCAASA1sHMApLCgQEAAIEEgNeAkUaPiBPdXRwdXQgb25seS4gVGhlIGVkaXRv
ciB0aGF0IGxhc3QgdXBkYXRlZCB0aGUgY3VzdG9tIG1vZHVsZS4KCgwKBQQAAgQFEgNeAggK
DAoFBAACBAESA14JFAoMCgUEAAIEAxIDXhcYCgwKBQQAAgQIEgNeGUQKDwoIBAACBAicCAAS
A14aQwqYAgoEBAACBRIEZAJpBBqJAiBPdXRwdXQgb25seS4gSWYgZW1wdHksIGluZGljYXRl
cyB0aGF0IHRoZSBjdXN0b20gbW9kdWxlIHdhcyBjcmVhdGVkIGluIHRoZQogb3JnYW5pemF0
aW9uLCBmb2xkZXIsIG9yIHByb2plY3QgaW4gd2hpY2ggeW91IGFyZSB2aWV3aW5nIHRoZSBj
dXN0b20KIG1vZHVsZS4gT3RoZXJ3aXNlLCBgYW5jZXN0b3JfbW9kdWxlYCBzcGVjaWZpZXMg
dGhlIG9yZ2FuaXphdGlvbiBvciBmb2xkZXIKIGZyb20gd2hpY2ggdGhlIGN1c3RvbSBtb2R1
bGUgaXMgaW5oZXJpdGVkLgoKDAoFBAACBQUSA2QCCAoMCgUEAAIFARIDZAkYCgwKBQQAAgUD
EgNkGxwKDQoFBAACBQgSBGQdaQMKDwoIBAACBQicCAASA2UELQoPCgcEAAIFCJ8IEgRmBGgF
CkYKBAQAAgYSA2wCIRo5IFRoZSB1c2VyIHNwZWNpZmllZCBjdXN0b20gY29uZmlndXJhdGlv
biBmb3IgdGhlIG1vZHVsZS4KCgwKBQQAAgYGEgNsAg4KDAoFBAACBgESA2wPHAoMCgUEAAIG
AxIDbB8gYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomModule::SecurityHealthAnalyticsCustomModule ===
    # Fields for SecurityHealthAnalyticsCustomModule
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: enablement_state Type: 14 (.google.cloud.securitycenter.v1.SecurityHealthAnalyticsCustomModule.EnablementState)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: last_editor Type: 9 ()
    # Field: ancestor_module Type: 9 ()
    # Field: custom_config Type: 11 (.google.cloud.securitycenter.v1.CustomConfig)

# Enum: SecurityHealthAnalyticsCustomModule::EnablementState
our $SecurityHealthAnalyticsCustomModule_ENABLEMENT_STATE_UNSPECIFIED = 0;
our $SecurityHealthAnalyticsCustomModule_ENABLED = 1;
our $SecurityHealthAnalyticsCustomModule_DISABLED = 2;
our $SecurityHealthAnalyticsCustomModule_INHERITED = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomModule - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/security_health_analytics_custom_module.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomModule;

    my $msg = Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomModule::SecurityHealthAnalyticsCustomModule->new({
        name => $name,
        display_name => $display_name,
        enablement_state => $enablement_state,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomModule::SecurityHealthAnalyticsCustomModule->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/security_health_analytics_custom_module.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomModule::SecurityHealthAnalyticsCustomModule

Represents an instance of a Security Health Analytics custom module,
including its full module name, display name, enablement state, and last
updated time. You can create a custom module at the organization, folder, or
project level. Custom modules that you create at the organization or folder
level are inherited by the child folders and projects.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. The resource name of the custom module.
Its format is
"organizations/{organization}/securityHealthAnalyticsSettings/customModules/{customModule}",
or
"folders/{folder}/securityHealthAnalyticsSettings/customModules/{customModule}",
or
"projects/{project}/securityHealthAnalyticsSettings/customModules/{customModule}"

The id {customModule} is server-generated and is not user settable.
It will be a numeric id containing 1-20 digits.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The display name of the Security Health Analytics custom module. This
display name becomes the finding category for all findings that are
returned by this custom module. The display name must be between 1 and
128 characters, start with a lowercase letter, and contain alphanumeric
characters or underscores only.

=item * C<< $msg->enablement_state() >> / C<< $msg->enablement_state($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomModule::EnablementState>)

The enablement state of the custom module.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which the custom module was last updated.

=item * C<< $msg->last_editor() >> / C<< $msg->last_editor($value) >>

Type: C<String>

Output only. The editor that last updated the custom module.

=item * C<< $msg->ancestor_module() >> / C<< $msg->ancestor_module($value) >>

Type: C<String>

Output only. If empty, indicates that the custom module was created in the
organization, folder, or project in which you are viewing the custom
module. Otherwise, `ancestor_module` specifies the organization or folder
from which the custom module is inherited.

=item * C<< $msg->custom_config() >> / C<< $msg->custom_config($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig::CustomConfig>)

The user specified custom configuration for the module.

=back

=head3 Enum: SecurityHealthAnalyticsCustomModule::EnablementState

=over 4

=item * C<ENABLEMENT_STATE_UNSPECIFIED> => C<0>

=item * C<ENABLED> => C<1>

=item * C<DISABLED> => C<2>

=item * C<INHERITED> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomModule::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
