package Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModule;

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
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cklnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvZXZlbnRfdGhyZWF0X2RldGVjdGlv
bl9jdXN0b21fbW9kdWxlLnByb3RvEh5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEa
H2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2Uu
cHJvdG8aHGdvb2dsZS9wcm90b2J1Zi9zdHJ1Y3QucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90
aW1lc3RhbXAucHJvdG8ioQcKIEV2ZW50VGhyZWF0RGV0ZWN0aW9uQ3VzdG9tTW9kdWxlEhcK
BG5hbWUYASABKAlCA+BBBVIEbmFtZRIvCgZjb25maWcYAiABKAsyFy5nb29nbGUucHJvdG9i
dWYuU3RydWN0UgZjb25maWcSbwoPYW5jZXN0b3JfbW9kdWxlGAMgASgJQkbgQQP6QUAKPnNl
Y3VyaXR5Y2VudGVyLmdvb2dsZWFwaXMuY29tL0V2ZW50VGhyZWF0RGV0ZWN0aW9uQ3VzdG9t
TW9kdWxlUg5hbmNlc3Rvck1vZHVsZRJ7ChBlbmFibGVtZW50X3N0YXRlGAQgASgOMlAuZ29v
Z2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxLkV2ZW50VGhyZWF0RGV0ZWN0aW9uQ3VzdG9t
TW9kdWxlLkVuYWJsZW1lbnRTdGF0ZVIPZW5hYmxlbWVudFN0YXRlEhIKBHR5cGUYBSABKAlS
BHR5cGUSIQoMZGlzcGxheV9uYW1lGAYgASgJUgtkaXNwbGF5TmFtZRIgCgtkZXNjcmlwdGlv
bhgHIAEoCVILZGVzY3JpcHRpb24SQAoLdXBkYXRlX3RpbWUYCCABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRpbWUSJAoLbGFzdF9lZGl0b3IYCSABKAlC
A+BBA1IKbGFzdEVkaXRvciJdCg9FbmFibGVtZW50U3RhdGUSIAocRU5BQkxFTUVOVF9TVEFU
RV9VTlNQRUNJRklFRBAAEgsKB0VOQUJMRUQQARIMCghESVNBQkxFRBACEg0KCUlOSEVSSVRF
RBADOqQC6kGgAgo+c2VjdXJpdHljZW50ZXIuZ29vZ2xlYXBpcy5jb20vRXZlbnRUaHJlYXRE
ZXRlY3Rpb25DdXN0b21Nb2R1bGUSUG9yZ2FuaXphdGlvbnMve29yZ2FuaXphdGlvbn0vZXZl
bnRUaHJlYXREZXRlY3Rpb25TZXR0aW5ncy9jdXN0b21Nb2R1bGVzL3ttb2R1bGV9EkRmb2xk
ZXJzL3tmb2xkZXJ9L2V2ZW50VGhyZWF0RGV0ZWN0aW9uU2V0dGluZ3MvY3VzdG9tTW9kdWxl
cy97bW9kdWxlfRJGcHJvamVjdHMve3Byb2plY3R9L2V2ZW50VGhyZWF0RGV0ZWN0aW9uU2V0
dGluZ3MvY3VzdG9tTW9kdWxlcy97bW9kdWxlfUL/AQoiY29tLmdvb2dsZS5jbG91ZC5zZWN1
cml0eWNlbnRlci52MUIlRXZlbnRUaHJlYXREZXRlY3Rpb25DdXN0b21Nb2R1bGVQcm90b1AB
WkpjbG91ZC5nb29nbGUuY29tL2dvL3NlY3VyaXR5Y2VudGVyL2FwaXYxL3NlY3VyaXR5Y2Vu
dGVycGI7c2VjdXJpdHljZW50ZXJwYqoCHkdvb2dsZS5DbG91ZC5TZWN1cml0eUNlbnRlci5W
McoCHkdvb2dsZVxDbG91ZFxTZWN1cml0eUNlbnRlclxWMeoCIUdvb2dsZTo6Q2xvdWQ6OlNl
Y3VyaXR5Q2VudGVyOjpWMUrXGQoGEgQOAGUBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAnCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAmCgkK
AgMDEgMVACkKCAoBCBIDFwA7CgkKAgglEgMXADsKCAoBCBIDGABhCgkKAggLEgMYAGEKCAoB
CBIDGQAiCgkKAggKEgMZACIKCAoBCBIDGgBGCgkKAggIEgMaAEYKCAoBCBIDGwA7CgkKAggB
EgMbADsKCAoBCBIDHAA7CgkKAggpEgMcADsKCAoBCBIDHQA6CgkKAggtEgMdADoK6gIKAgQA
EgQkAGUBGt0CIFJlcHJlc2VudHMgYW4gaW5zdGFuY2Ugb2YgYW4gRXZlbnQgVGhyZWF0IERl
dGVjdGlvbiBjdXN0b20gbW9kdWxlLAogaW5jbHVkaW5nIGl0cyBmdWxsIG1vZHVsZSBuYW1l
LCBkaXNwbGF5IG5hbWUsIGVuYWJsZW1lbnQgc3RhdGUsIGFuZCBsYXN0CiB1cGRhdGVkIHRp
bWUuIFlvdSBjYW4gY3JlYXRlIGEgY3VzdG9tIG1vZHVsZSBhdCB0aGUgb3JnYW5pemF0aW9u
LCBmb2xkZXIsIG9yCiBwcm9qZWN0IGxldmVsLiBDdXN0b20gbW9kdWxlcyB0aGF0IHlvdSBj
cmVhdGUgYXQgdGhlIG9yZ2FuaXphdGlvbiBvciBmb2xkZXIKIGxldmVsIGFyZSBpbmhlcml0
ZWQgYnkgY2hpbGQgZm9sZGVycyBhbmQgcHJvamVjdHMuCgoKCgMEAAESAyQIKAoLCgMEAAcS
BCUCKgQKDQoFBAAHnQgSBCUCKgQKMwoEBAAEABIELQI5AxolIFRoZSBlbmFibGVtZW50IHN0
YXRlIG9mIHRoZSBtb2R1bGUuCgoMCgUEAAQAARIDLQcWCi4KBgQABAACABIDLwQlGh8gVW5z
cGVjaWZpZWQgZW5hYmxlbWVudCBzdGF0ZS4KCg4KBwQABAACAAESAy8EIAoOCgcEAAQAAgAC
EgMvIyQKOgoGBAAEAAIBEgMyBBAaKyBUaGUgbW9kdWxlIGlzIGVuYWJsZWQgYXQgdGhlIGdp
dmVuIGxldmVsLgoKDgoHBAAEAAIBARIDMgQLCg4KBwQABAACAQISAzIODwo7CgYEAAQAAgIS
AzUEERosIFRoZSBtb2R1bGUgaXMgZGlzYWJsZWQgYXQgdGhlIGdpdmVuIGxldmVsLgoKDgoH
BAAEAAICARIDNQQMCg4KBwQABAACAgISAzUPEAo4CgYEAAQAAgMSAzgEEhopIFdoZW4gdGhl
IGVuYWJsZW1lbnQgc3RhdGUgaXMgaW5oZXJpdGVkLgoKDgoHBAAEAAIDARIDOAQNCg4KBwQA
BAACAwISAzgQEQrgAgoEBAACABIDQgI8GtICIEltbXV0YWJsZS4gVGhlIHJlc291cmNlIG5h
bWUgb2YgdGhlIEV2ZW50IFRocmVhdCBEZXRlY3Rpb24gY3VzdG9tIG1vZHVsZS4KCiBJdHMg
Zm9ybWF0IGlzOgoKICAgKiBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9ldmVudFRo
cmVhdERldGVjdGlvblNldHRpbmdzL2N1c3RvbU1vZHVsZXMve21vZHVsZX1gLgogICAqIGBm
b2xkZXJzL3tmb2xkZXJ9L2V2ZW50VGhyZWF0RGV0ZWN0aW9uU2V0dGluZ3MvY3VzdG9tTW9k
dWxlcy97bW9kdWxlfWAuCiAgICogYHByb2plY3RzL3twcm9qZWN0fS9ldmVudFRocmVhdERl
dGVjdGlvblNldHRpbmdzL2N1c3RvbU1vZHVsZXMve21vZHVsZX1gLgoKDAoFBAACAAUSA0IC
CAoMCgUEAAIAARIDQgkNCgwKBQQAAgADEgNCEBEKDAoFBAACAAgSA0ISOwoPCggEAAIACJwI
ABIDQhM6Cr4BCgQEAAIBEgNHAiQasAEgQ29uZmlnIGZvciB0aGUgbW9kdWxlLiBGb3IgdGhl
IHJlc2lkZW50IG1vZHVsZSwgaXRzIGNvbmZpZyB2YWx1ZSBpcyBkZWZpbmVkCiBhdCB0aGlz
IGxldmVsLiBGb3IgdGhlIGluaGVyaXRlZCBtb2R1bGUsIGl0cyBjb25maWcgdmFsdWUgaXMg
aW5oZXJpdGVkIGZyb20KIHRoZSBhbmNlc3RvciBtb2R1bGUuCgoMCgUEAAIBBhIDRwIYCgwK
BQQAAgEBEgNHGR8KDAoFBAACAQMSA0ciIwq+AQoEBAACAhIETAJRBBqvASBPdXRwdXQgb25s
eS4gVGhlIGNsb3Nlc3QgYW5jZXN0b3IgbW9kdWxlIHRoYXQgdGhpcyBtb2R1bGUgaW5oZXJp
dHMgdGhlCiBlbmFibGVtZW50IHN0YXRlIGZyb20uIFRoZSBmb3JtYXQgaXMgdGhlIHNhbWUg
YXMgdGhlCiBFdmVudFRocmVhdERldGVjdGlvbkN1c3RvbU1vZHVsZSByZXNvdXJjZSBuYW1l
LgoKDAoFBAACAgUSA0wCCAoMCgUEAAICARIDTAkYCgwKBQQAAgIDEgNMGxwKDQoFBAACAggS
BEwdUQMKDwoIBAACAgicCAASA00ELQoPCgcEAAICCJ8IEgROBFAFCloKBAQAAgMSA1QCJxpN
IFRoZSBzdGF0ZSBvZiBlbmFibGVtZW50IGZvciB0aGUgbW9kdWxlIGF0IHRoZSBnaXZlbiBs
ZXZlbCBvZiB0aGUgaGllcmFyY2h5LgoKDAoFBAACAwYSA1QCEQoMCgUEAAIDARIDVBIiCgwK
BQQAAgMDEgNUJSYKPQoEBAACBBIDVwISGjAgVHlwZSBmb3IgdGhlIG1vZHVsZS4gZS5nLiBD
T05GSUdVUkFCTEVfQkFEX0lQLgoKDAoFBAACBAUSA1cCCAoMCgUEAAIEARIDVwkNCgwKBQQA
AgQDEgNXEBEKRgoEBAACBRIDWgIaGjkgVGhlIGh1bWFuIHJlYWRhYmxlIG5hbWUgdG8gYmUg
ZGlzcGxheWVkIGZvciB0aGUgbW9kdWxlLgoKDAoFBAACBQUSA1oCCAoMCgUEAAIFARIDWgkV
CgwKBQQAAgUDEgNaGBkKLgoEBAACBhIDXQIZGiEgVGhlIGRlc2NyaXB0aW9uIGZvciB0aGUg
bW9kdWxlLgoKDAoFBAACBgUSA10CCAoMCgUEAAIGARIDXQkUCgwKBQQAAgYDEgNdFxgKQgoE
BAACBxIEYAJhMho0IE91dHB1dCBvbmx5LiBUaGUgdGltZSB0aGUgbW9kdWxlIHdhcyBsYXN0
IHVwZGF0ZWQuCgoMCgUEAAIHBhIDYAIbCgwKBQQAAgcBEgNgHCcKDAoFBAACBwMSA2AqKwoM
CgUEAAIHCBIDYQYxCg8KCAQAAgcInAgAEgNhBzAKRgoEBAACCBIDZAJFGjkgT3V0cHV0IG9u
bHkuIFRoZSBlZGl0b3IgdGhlIG1vZHVsZSB3YXMgbGFzdCB1cGRhdGVkIGJ5LgoKDAoFBAAC
CAUSA2QCCAoMCgUEAAIIARIDZAkUCgwKBQQAAggDEgNkFxgKDAoFBAACCAgSA2QZRAoPCggE
AAIICJwIABIDZBpDYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModule::EventThreatDetectionCustomModule ===
    # Fields for EventThreatDetectionCustomModule
    # Field: name Type: 9 ()
    # Field: config Type: 11 (.google.protobuf.Struct)
    # Field: ancestor_module Type: 9 ()
    # Field: enablement_state Type: 14 (.google.cloud.securitycenter.v1.EventThreatDetectionCustomModule.EnablementState)
    # Field: type Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: last_editor Type: 9 ()

# Enum: EventThreatDetectionCustomModule::EnablementState
our $EventThreatDetectionCustomModule_ENABLEMENT_STATE_UNSPECIFIED = 0;
our $EventThreatDetectionCustomModule_ENABLED = 1;
our $EventThreatDetectionCustomModule_DISABLED = 2;
our $EventThreatDetectionCustomModule_INHERITED = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModule - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/event_threat_detection_custom_module.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModule;

    my $msg = Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModule::EventThreatDetectionCustomModule->new({
        name => $name,
        config => $config,
        ancestor_module => $ancestor_module,
        enablement_state => $enablement_state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModule::EventThreatDetectionCustomModule->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/event_threat_detection_custom_module.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModule::EventThreatDetectionCustomModule

Represents an instance of an Event Threat Detection custom module,
including its full module name, display name, enablement state, and last
updated time. You can create a custom module at the organization, folder, or
project level. Custom modules that you create at the organization or folder
level are inherited by child folders and projects.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Immutable. The resource name of the Event Threat Detection custom module.

Its format is:

  * `organizations/{organization}/eventThreatDetectionSettings/customModules/{module}`.
  * `folders/{folder}/eventThreatDetectionSettings/customModules/{module}`.
  * `projects/{project}/eventThreatDetectionSettings/customModules/{module}`.

=item * C<< $msg->config() >> / C<< $msg->config($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Config for the module. For the resident module, its config value is defined
at this level. For the inherited module, its config value is inherited from
the ancestor module.

=item * C<< $msg->ancestor_module() >> / C<< $msg->ancestor_module($value) >>

Type: C<String>

Output only. The closest ancestor module that this module inherits the
enablement state from. The format is the same as the
EventThreatDetectionCustomModule resource name.

=item * C<< $msg->enablement_state() >> / C<< $msg->enablement_state($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModule::EnablementState>)

The state of enablement for the module at the given level of the hierarchy.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Type for the module. e.g. CONFIGURABLE_BAD_IP.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

The human readable name to be displayed for the module.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

The description for the module.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the module was last updated.

=item * C<< $msg->last_editor() >> / C<< $msg->last_editor($value) >>

Type: C<String>

Output only. The editor the module was last updated by.

=back

=head3 Enum: EventThreatDetectionCustomModule::EnablementState

=over 4

=item * C<ENABLEMENT_STATE_UNSPECIFIED> => C<0>

=item * C<ENABLED> => C<1>

=item * C<DISABLED> => C<2>

=item * C<INHERITED> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::EventThreatDetectionCustomModule::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
