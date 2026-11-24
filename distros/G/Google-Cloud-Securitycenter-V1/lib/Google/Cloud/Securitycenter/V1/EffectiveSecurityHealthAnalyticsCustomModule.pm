package Google::Cloud::Securitycenter::V1::EffectiveSecurityHealthAnalyticsCustomModule;

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
    my $descriptor_b64 = <<'EOF';
ClZnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvZWZmZWN0aXZlX3NlY3VyaXR5X2hl
YWx0aF9hbmFseXRpY3NfY3VzdG9tX21vZHVsZS5wcm90bxIeZ29vZ2xlLmNsb3VkLnNlY3Vy
aXR5Y2VudGVyLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUv
YXBpL3Jlc291cmNlLnByb3RvGkxnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvc2Vj
dXJpdHlfaGVhbHRoX2FuYWx5dGljc19jdXN0b21fY29uZmlnLnByb3RvIrAGCixFZmZlY3Rp
dmVTZWN1cml0eUhlYWx0aEFuYWx5dGljc0N1c3RvbU1vZHVsZRIXCgRuYW1lGAEgASgJQgPg
QQNSBG5hbWUSVgoNY3VzdG9tX2NvbmZpZxgCIAEoCzIsLmdvb2dsZS5jbG91ZC5zZWN1cml0
eWNlbnRlci52MS5DdXN0b21Db25maWdCA+BBA1IMY3VzdG9tQ29uZmlnEowBChBlbmFibGVt
ZW50X3N0YXRlGAMgASgOMlwuZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxLkVmZmVj
dGl2ZVNlY3VyaXR5SGVhbHRoQW5hbHl0aWNzQ3VzdG9tTW9kdWxlLkVuYWJsZW1lbnRTdGF0
ZUID4EEDUg9lbmFibGVtZW50U3RhdGUSJgoMZGlzcGxheV9uYW1lGAQgASgJQgPgQQNSC2Rp
c3BsYXlOYW1lIk4KD0VuYWJsZW1lbnRTdGF0ZRIgChxFTkFCTEVNRU5UX1NUQVRFX1VOU1BF
Q0lGSUVEEAASCwoHRU5BQkxFRBABEgwKCERJU0FCTEVEEAI6hwPqQYMDCkpzZWN1cml0eWNl
bnRlci5nb29nbGVhcGlzLmNvbS9FZmZlY3RpdmVTZWN1cml0eUhlYWx0aEFuYWx5dGljc0N1
c3RvbU1vZHVsZRJtb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9zZWN1cml0eUhlYWx0
aEFuYWx5dGljc1NldHRpbmdzL2VmZmVjdGl2ZUN1c3RvbU1vZHVsZXMve2VmZmVjdGl2ZV9j
dXN0b21fbW9kdWxlfRJhZm9sZGVycy97Zm9sZGVyfS9zZWN1cml0eUhlYWx0aEFuYWx5dGlj
c1NldHRpbmdzL2VmZmVjdGl2ZUN1c3RvbU1vZHVsZXMve2VmZmVjdGl2ZV9jdXN0b21fbW9k
dWxlfRJjcHJvamVjdHMve3Byb2plY3R9L3NlY3VyaXR5SGVhbHRoQW5hbHl0aWNzU2V0dGlu
Z3MvZWZmZWN0aXZlQ3VzdG9tTW9kdWxlcy97ZWZmZWN0aXZlX2N1c3RvbV9tb2R1bGV9QosC
CiJjb20uZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxQjFFZmZlY3RpdmVTZWN1cml0
eUhlYWx0aEFuYWx5dGljc0N1c3RvbU1vZHVsZVByb3RvUAFaSmNsb3VkLmdvb2dsZS5jb20v
Z28vc2VjdXJpdHljZW50ZXIvYXBpdjEvc2VjdXJpdHljZW50ZXJwYjtzZWN1cml0eWNlbnRl
cnBiqgIeR29vZ2xlLkNsb3VkLlNlY3VyaXR5Q2VudGVyLlYxygIeR29vZ2xlXENsb3VkXFNl
Y3VyaXR5Q2VudGVyXFYx6gIhR29vZ2xlOjpDbG91ZDo6U2VjdXJpdHlDZW50ZXI6OlYxSuEW
CgYSBA4AUAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcK
CQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUAFYKCAoBCBIDFgA7CgkKAgglEgMWADsK
CAoBCBIDFwBhCgkKAggLEgMXAGEKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQBSCgkK
AggIEgMZAFIKCAoBCBIDGgA7CgkKAggBEgMaADsKCAoBCBIDGwA7CgkKAggpEgMbADsKCAoB
CBIDHAA6CgkKAggtEgMcADoKsgUKAgQAEgQnAFABGqUFIEFuIEVmZmVjdGl2ZVNlY3VyaXR5
SGVhbHRoQW5hbHl0aWNzQ3VzdG9tTW9kdWxlIGlzIHRoZSByZXByZXNlbnRhdGlvbiBvZgog
YSBTZWN1cml0eSBIZWFsdGggQW5hbHl0aWNzIGN1c3RvbSBtb2R1bGUgYXQgYSBzcGVjaWZp
ZWQgbGV2ZWwgb2YgdGhlCiByZXNvdXJjZSBoaWVyYXJjaHk6IG9yZ2FuaXphdGlvbiwgZm9s
ZGVyLCBvciBwcm9qZWN0LiBJZiBhIGN1c3RvbSBtb2R1bGUgaXMKIGluaGVyaXRlZCBmcm9t
IGEgcGFyZW50IG9yZ2FuaXphdGlvbiBvciBmb2xkZXIsIHRoZSB2YWx1ZSBvZiB0aGUKIGBl
bmFibGVtZW50U3RhdGVgIHByb3BlcnR5IGluIEVmZmVjdGl2ZVNlY3VyaXR5SGVhbHRoQW5h
bHl0aWNzQ3VzdG9tTW9kdWxlIGlzCiBzZXQgdG8gdGhlIHZhbHVlIHRoYXQgaXMgZWZmZWN0
aXZlIGluIHRoZSBwYXJlbnQsIGluc3RlYWQgb2YgIGBJTkhFUklURURgLgogRm9yIGV4YW1w
bGUsIGlmIHRoZSBtb2R1bGUgaXMgZW5hYmxlZCBpbiBhIHBhcmVudCBvcmdhbml6YXRpb24g
b3IgZm9sZGVyLCB0aGUKIGVmZmVjdGl2ZSBlbmFibGVtZW50X3N0YXRlIGZvciB0aGUgbW9k
dWxlIGluIGFsbCBjaGlsZCBmb2xkZXJzIG9yIHByb2plY3RzIGlzCiBhbHNvIGBlbmFibGVk
YC4gRWZmZWN0aXZlU2VjdXJpdHlIZWFsdGhBbmFseXRpY3NDdXN0b21Nb2R1bGUgaXMgcmVh
ZC1vbmx5LgoKCgoDBAABEgMnCDQKCwoDBAAHEgQoAi0ECg0KBQQAB50IEgQoAi0ECjMKBAQA
BAASBDACOQMaJSBUaGUgZW5hYmxlbWVudCBzdGF0ZSBvZiB0aGUgbW9kdWxlLgoKDAoFBAAE
AAESAzAHFgouCgYEAAQAAgASAzIEJRofIFVuc3BlY2lmaWVkIGVuYWJsZW1lbnQgc3RhdGUu
CgoOCgcEAAQAAgABEgMyBCAKDgoHBAAEAAIAAhIDMiMkCjoKBgQABAACARIDNQQQGisgVGhl
IG1vZHVsZSBpcyBlbmFibGVkIGF0IHRoZSBnaXZlbiBsZXZlbC4KCg4KBwQABAACAQESAzUE
CwoOCgcEAAQAAgECEgM1Dg8KOwoGBAAEAAICEgM4BBEaLCBUaGUgbW9kdWxlIGlzIGRpc2Fi
bGVkIGF0IHRoZSBnaXZlbiBsZXZlbC4KCg4KBwQABAACAgESAzgEDAoOCgcEAAQAAgICEgM4
DxAK+QIKBAQAAgASA0ICPhrrAiBPdXRwdXQgb25seS4gVGhlIHJlc291cmNlIG5hbWUgb2Yg
dGhlIGN1c3RvbSBtb2R1bGUuCiBJdHMgZm9ybWF0IGlzCiAib3JnYW5pemF0aW9ucy97b3Jn
YW5pemF0aW9ufS9zZWN1cml0eUhlYWx0aEFuYWx5dGljc1NldHRpbmdzL2VmZmVjdGl2ZUN1
c3RvbU1vZHVsZXMve2N1c3RvbU1vZHVsZX0iLAogb3IKICJmb2xkZXJzL3tmb2xkZXJ9L3Nl
Y3VyaXR5SGVhbHRoQW5hbHl0aWNzU2V0dGluZ3MvZWZmZWN0aXZlQ3VzdG9tTW9kdWxlcy97
Y3VzdG9tTW9kdWxlfSIsCiBvcgogInByb2plY3RzL3twcm9qZWN0fS9zZWN1cml0eUhlYWx0
aEFuYWx5dGljc1NldHRpbmdzL2VmZmVjdGl2ZUN1c3RvbU1vZHVsZXMve2N1c3RvbU1vZHVs
ZX0iCgoMCgUEAAIABRIDQgIICgwKBQQAAgABEgNCCQ0KDAoFBAACAAMSA0IQEQoMCgUEAAIA
CBIDQhI9Cg8KCAQAAgAInAgAEgNCEzwKTAoEBAACARIDRQJNGj8gT3V0cHV0IG9ubHkuIFRo
ZSB1c2VyLXNwZWNpZmllZCBjb25maWd1cmF0aW9uIGZvciB0aGUgbW9kdWxlLgoKDAoFBAAC
AQYSA0UCDgoMCgUEAAIBARIDRQ8cCgwKBQQAAgEDEgNFHyAKDAoFBAACAQgSA0UhTAoPCggE
AAIBCJwIABIDRSJLCnMKBAQAAgISBEkCSjIaZSBPdXRwdXQgb25seS4gVGhlIGVmZmVjdGl2
ZSBzdGF0ZSBvZiBlbmFibGVtZW50IGZvciB0aGUgbW9kdWxlIGF0IHRoZSBnaXZlbgogbGV2
ZWwgb2YgdGhlIGhpZXJhcmNoeS4KCgwKBQQAAgIGEgNJAhEKDAoFBAACAgESA0kSIgoMCgUE
AAICAxIDSSUmCgwKBQQAAgIIEgNKBjEKDwoIBAACAgicCAASA0oHMArNAQoEBAACAxIDTwJG
Gr8BIE91dHB1dCBvbmx5LiBUaGUgZGlzcGxheSBuYW1lIGZvciB0aGUgY3VzdG9tIG1vZHVs
ZS4gVGhlIG5hbWUgbXVzdCBiZQogYmV0d2VlbiAxIGFuZCAxMjggY2hhcmFjdGVycywgc3Rh
cnQgd2l0aCBhIGxvd2VyY2FzZSBsZXR0ZXIsIGFuZCBjb250YWluCiBhbHBoYW51bWVyaWMg
Y2hhcmFjdGVycyBvciB1bmRlcnNjb3JlcyBvbmx5LgoKDAoFBAACAwUSA08CCAoMCgUEAAID
ARIDTwkVCgwKBQQAAgMDEgNPGBkKDAoFBAACAwgSA08aRQoPCggEAAIDCJwIABIDTxtEYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::EffectiveSecurityHealthAnalyticsCustomModule::EffectiveSecurityHealthAnalyticsCustomModule ===
    # Fields for EffectiveSecurityHealthAnalyticsCustomModule
    # Field: name Type: 9 ()
    # Field: custom_config Type: 11 (.google.cloud.securitycenter.v1.CustomConfig)
    # Field: enablement_state Type: 14 (.google.cloud.securitycenter.v1.EffectiveSecurityHealthAnalyticsCustomModule.EnablementState)
    # Field: display_name Type: 9 ()

# Enum: EffectiveSecurityHealthAnalyticsCustomModule::EnablementState
our $EffectiveSecurityHealthAnalyticsCustomModule_ENABLEMENT_STATE_UNSPECIFIED = 0;
our $EffectiveSecurityHealthAnalyticsCustomModule_ENABLED = 1;
our $EffectiveSecurityHealthAnalyticsCustomModule_DISABLED = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::EffectiveSecurityHealthAnalyticsCustomModule - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/effective_security_health_analytics_custom_module.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::EffectiveSecurityHealthAnalyticsCustomModule;

    my $msg = Google::Cloud::Securitycenter::V1::EffectiveSecurityHealthAnalyticsCustomModule::EffectiveSecurityHealthAnalyticsCustomModule->new({
        name => $name,
        custom_config => $custom_config,
        enablement_state => $enablement_state,
        display_name => $display_name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::EffectiveSecurityHealthAnalyticsCustomModule::EffectiveSecurityHealthAnalyticsCustomModule->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/effective_security_health_analytics_custom_module.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::EffectiveSecurityHealthAnalyticsCustomModule::EffectiveSecurityHealthAnalyticsCustomModule

An EffectiveSecurityHealthAnalyticsCustomModule is the representation of
a Security Health Analytics custom module at a specified level of the
resource hierarchy: organization, folder, or project. If a custom module is
inherited from a parent organization or folder, the value of the
`enablementState` property in EffectiveSecurityHealthAnalyticsCustomModule is
set to the value that is effective in the parent, instead of  `INHERITED`.
For example, if the module is enabled in a parent organization or folder, the
effective enablement_state for the module in all child folders or projects is
also `enabled`. EffectiveSecurityHealthAnalyticsCustomModule is read-only.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of the custom module.
Its format is
"organizations/{organization}/securityHealthAnalyticsSettings/effectiveCustomModules/{customModule}",
or
"folders/{folder}/securityHealthAnalyticsSettings/effectiveCustomModules/{customModule}",
or
"projects/{project}/securityHealthAnalyticsSettings/effectiveCustomModules/{customModule}"

=item * C<< $msg->custom_config() >> / C<< $msg->custom_config($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::SecurityHealthAnalyticsCustomConfig::CustomConfig>)

Output only. The user-specified configuration for the module.

=item * C<< $msg->enablement_state() >> / C<< $msg->enablement_state($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V1::EffectiveSecurityHealthAnalyticsCustomModule::EnablementState>)

Output only. The effective state of enablement for the module at the given
level of the hierarchy.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The display name for the custom module. The name must be
between 1 and 128 characters, start with a lowercase letter, and contain
alphanumeric characters or underscores only.

=back

=head3 Enum: EffectiveSecurityHealthAnalyticsCustomModule::EnablementState

=over 4

=item * C<ENABLEMENT_STATE_UNSPECIFIED> => C<0>

=item * C<ENABLED> => C<1>

=item * C<DISABLED> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::EffectiveSecurityHealthAnalyticsCustomModule::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
