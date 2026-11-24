package Google::Apps::Script::Type::Calendar::CalendarAddonManifest;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Apps::Script::Type::ExtensionPoint };
    my $descriptor_b64 = <<'EOF';
Cj5nb29nbGUvYXBwcy9zY3JpcHQvdHlwZS9jYWxlbmRhci9jYWxlbmRhcl9hZGRvbl9tYW5p
ZmVzdC5wcm90bxIgZ29vZ2xlLmFwcHMuc2NyaXB0LnR5cGUuY2FsZW5kYXIaH2dvb2dsZS9h
cGkvZmllbGRfYmVoYXZpb3IucHJvdG8aLWdvb2dsZS9hcHBzL3NjcmlwdC90eXBlL2V4dGVu
c2lvbl9wb2ludC5wcm90byK5BQoVQ2FsZW5kYXJBZGRPbk1hbmlmZXN0EloKEGhvbWVwYWdl
X3RyaWdnZXIYBiABKAsyLy5nb29nbGUuYXBwcy5zY3JpcHQudHlwZS5Ib21lcGFnZUV4dGVu
c2lvblBvaW50Ug9ob21lcGFnZVRyaWdnZXISZQoTY29uZmVyZW5jZV9zb2x1dGlvbhgDIAMo
CzI0Lmdvb2dsZS5hcHBzLnNjcmlwdC50eXBlLmNhbGVuZGFyLkNvbmZlcmVuY2VTb2x1dGlv
blISY29uZmVyZW5jZVNvbHV0aW9uEj8KHGNyZWF0ZV9zZXR0aW5nc191cmxfZnVuY3Rpb24Y
BSABKAlSGWNyZWF0ZVNldHRpbmdzVXJsRnVuY3Rpb24SZgoSZXZlbnRfb3Blbl90cmlnZ2Vy
GAogASgLMjguZ29vZ2xlLmFwcHMuc2NyaXB0LnR5cGUuY2FsZW5kYXIuQ2FsZW5kYXJFeHRl
bnNpb25Qb2ludFIQZXZlbnRPcGVuVHJpZ2dlchJqChRldmVudF91cGRhdGVfdHJpZ2dlchgL
IAEoCzI4Lmdvb2dsZS5hcHBzLnNjcmlwdC50eXBlLmNhbGVuZGFyLkNhbGVuZGFyRXh0ZW5z
aW9uUG9pbnRSEmV2ZW50VXBkYXRlVHJpZ2dlchJ1ChRjdXJyZW50X2V2ZW50X2FjY2VzcxgM
IAEoDjJDLmdvb2dsZS5hcHBzLnNjcmlwdC50eXBlLmNhbGVuZGFyLkNhbGVuZGFyQWRkT25N
YW5pZmVzdC5FdmVudEFjY2Vzc1ISY3VycmVudEV2ZW50QWNjZXNzIlEKC0V2ZW50QWNjZXNz
Eg8KC1VOU1BFQ0lGSUVEEAASDAoITUVUQURBVEEQARIICgRSRUFEEAMSCQoFV1JJVEUQBBIO
CgpSRUFEX1dSSVRFEAUilQEKEkNvbmZlcmVuY2VTb2x1dGlvbhIxChJvbl9jcmVhdGVfZnVu
Y3Rpb24YASABKAlCA+BBAlIQb25DcmVhdGVGdW5jdGlvbhITCgJpZBgEIAEoCUID4EECUgJp
ZBIXCgRuYW1lGAUgASgJQgPgQQJSBG5hbWUSHgoIbG9nb191cmwYBiABKAlCA+BBAlIHbG9n
b1VybCJAChZDYWxlbmRhckV4dGVuc2lvblBvaW50EiYKDHJ1bl9mdW5jdGlvbhgBIAEoCUID
4EECUgtydW5GdW5jdGlvbkLyAQokY29tLmdvb2dsZS5hcHBzLnNjcmlwdC50eXBlLmNhbGVu
ZGFyQhpDYWxlbmRhckFkZE9uTWFuaWZlc3RQcm90b1ABWj9nb29nbGUuZ29sYW5nLm9yZy9n
ZW5wcm90by9nb29nbGVhcGlzL2FwcHMvc2NyaXB0L3R5cGUvY2FsZW5kYXKqAiBHb29nbGUu
QXBwcy5TY3JpcHQuVHlwZS5DYWxlbmRhcsoCIEdvb2dsZVxBcHBzXFNjcmlwdFxUeXBlXENh
bGVuZGFy6gIkR29vZ2xlOjpBcHBzOjpTY3JpcHQ6OlR5cGU6OkNhbGVuZGFyStsfCgYSBA4A
agEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACkKCQoCAwAS
AxIAKQoJCgIDARIDEwA3CggKAQgSAxUAPQoJCgIIJRIDFQA9CggKAQgSAxYAVgoJCgIICxID
FgBWCggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgAOwoJCgIICBIDGAA7CggKAQgSAxkA
PQoJCgIIARIDGQA9CggKAQgSAxoAPgoJCgIIKRIDGgA+CggKAQgSAxsAPQoJCgIILRIDGwA9
ClkKAgQAEgQgAFABGhsgQ2FsZW5kYXIgYWRkLW9uIG1hbmlmZXN0LgoyMCBNYW5pZmVzdCBz
ZWN0aW9uIHNwZWNpZmljIHRvIENhbGVuZGFyIGFkZC1vbnMuCgoKCgMEAAESAyAIHQpRCgQE
AAQAEgQiAjcDGkMgQW4gZW51bSBkZWZpbmluZyB0aGUgbGV2ZWwgb2YgZGF0YSBhY2Nlc3Mg
ZXZlbnQgdHJpZ2dlcnMgcmVxdWlyZS4KCgwKBQQABAABEgMiBxIKQwoGBAAEAAIAEgMkBBQa
NCBEZWZhdWx0IHZhbHVlIHdoZW4gbm90aGluZyBpcyBzZXQgZm9yIEV2ZW50QWNjZXNzLgoK
DgoHBAAEAAIAARIDJAQPCg4KBwQABAACAAISAyQSEwqBAQoGBAAEAAIBEgMoBBEaciBNRVRB
REFUQSBnaXZlcyBldmVudCB0cmlnZ2VycyB0aGUgcGVybWlzc2lvbiB0byBhY2Nlc3MgdGhl
IG1ldGFkYXRhIG9mCiBldmVudHMgc3VjaCBhcyBldmVudCBpZCBhbmQgY2FsZW5kYXIgaWQu
CgoOCgcEAAQAAgEBEgMoBAwKDgoHBAAEAAIBAhIDKA8QCocBCgYEAAQAAgISAywEDRp4IFJF
QUQgZ2l2ZXMgZXZlbnQgdHJpZ2dlcnMgYWNjZXNzIHRvIGFsbCBwcm92aWRlZCBldmVudCBm
aWVsZHMgaW5jbHVkaW5nCiB0aGUgbWV0YWRhdGEsIGF0dGVuZGVlcywgYW5kIGNvbmZlcmVu
Y2UgZGF0YS4KCg4KBwQABAACAgESAywECAoOCgcEAAQAAgICEgMsCwwKrwEKBgQABAACAxID
MQQOGp8BIFdSSVRFIGdpdmVzIGV2ZW50IHRyaWdnZXJzIGFjY2VzcyB0byB0aGUgbWV0YWRh
dGEgb2YgZXZlbnRzIGFuZCB0aGUKIGFiaWxpdHkgdG8gcGVyZm9ybSBhbGwgYWN0aW9ucywg
aW5jbHVkaW5nIGFkZGluZyBhdHRlbmRlZXMgYW5kIHNldHRpbmcKIGNvbmZlcmVuY2UgZGF0
YS4KCg4KBwQABAACAwESAzEECQoOCgcEAAQAAgMCEgMxDA0KtgEKBgQABAACBBIDNgQTGqYB
IFJFQURfV1JJVEUgZ2l2ZXMgZXZlbnQgdHJpZ2dlcnMgYWNjZXNzIHRvIGFsbCBwcm92aWRl
ZCBldmVudCBmaWVsZHMKIGluY2x1ZGluZyB0aGUgbWV0YWRhdGEsIGF0dGVuZGVlcywgYW5k
IGNvbmZlcmVuY2UgZGF0YSBhbmQgdGhlIGFiaWxpdHkgdG8KIHBlcmZvcm0gYWxsIGFjdGlv
bnMuCgoOCgcEAAQAAgQBEgM2BA4KDgoHBAAEAAIEAhIDNhESCvICCgQEAAIAEgNAAkYa5AIg
RGVmaW5lcyBhbiBlbmRwb2ludCB0aGF0IHdpbGwgYmUgZXhlY3V0ZWQgY29udGV4dHMgdGhh
dCBkb24ndAogbWF0Y2ggYSBkZWNsYXJlZCBjb250ZXh0dWFsIHRyaWdnZXIuIEFueSBjYXJk
cyBnZW5lcmF0ZWQgYnkgdGhpcyBmdW5jdGlvbgogd2lsbCBhbHdheXMgYmUgYXZhaWxhYmxl
IHRvIHRoZSB1c2VyLCBidXQgbWF5IGJlIGVjbGlwc2VkIGJ5IGNvbnRleHR1YWwKIGNvbnRl
bnQgd2hlbiB0aGlzIGFkZC1vbiBkZWNsYXJlcyBtb3JlIHRhcmdldGVkIHRyaWdnZXJzLgoK
IElmIHByZXNlbnQsIHRoaXMgb3ZlcnJpZGVzIHRoZSBjb25maWd1cmF0aW9uIGZyb20KIGBh
ZGRPbnMuY29tbW9uLmhvbWVwYWdlVHJpZ2dlcmAuCgoMCgUEAAIABhIDQAIwCgwKBQQAAgAB
EgNAMUEKDAoFBAACAAMSA0BERQpECgQEAAIBEgNDAjYaNyBEZWZpbmVzIGNvbmZlcmVuY2Ug
c29sdXRpb25zIHByb3ZpZGVkIGJ5IHRoaXMgYWRkLW9uLgoKDAoFBAACAQQSA0MCCgoMCgUE
AAIBBhIDQwsdCgwKBQQAAgEBEgNDHjEKDAoFBAACAQMSA0M0NQpXCgQEAAICEgNGAioaSiBB
biBlbmRwb2ludCB0byBleGVjdXRlIHRoYXQgY3JlYXRlcyBhIFVSTCB0byB0aGUgYWRkLW9u
J3Mgc2V0dGluZ3MgcGFnZS4KCgwKBQQAAgIFEgNGAggKDAoFBAACAgESA0YJJQoMCgUEAAIC
AxIDRigpCk4KBAQAAgMSA0kCMRpBIEFuIGVuZHBvaW50IHRvIHRyaWdnZXIgd2hlbiBhbiBl
dmVudCBpcyBvcGVuZWQgKHZpZXdlZC9lZGl0ZWQpLgoKDAoFBAACAwYSA0kCGAoMCgUEAAID
ARIDSRkrCgwKBQQAAgMDEgNJLjAKRQoEBAACBBIDTAIzGjggQW4gZW5kcG9pbnQgdG8gdHJp
Z2dlciB3aGVuIHRoZSBvcGVuIGV2ZW50IGlzIHVwZGF0ZWQuCgoMCgUEAAIEBhIDTAIYCgwK
BQQAAgQBEgNMGS0KDAoFBAACBAMSA0wwMgpQCgQEAAIFEgNPAigaQyBEZWZpbmUgdGhlIGxl
dmVsIG9mIGRhdGEgYWNjZXNzIHdoZW4gYW4gZXZlbnQgYWRkb24gaXMgdHJpZ2dlcmVkLgoK
DAoFBAACBQYSA08CDQoMCgUEAAIFARIDTw4iCgwKBQQAAgUDEgNPJScKMAoCBAESBFMAYwEa
JCBEZWZpbmVzIGNvbmZlcmVuY2UgcmVsYXRlZCB2YWx1ZXMuCgoKCgMEAQESA1MIGgpUCgQE
AQIAEgNVAkkaRyBSZXF1aXJlZC4gVGhlIGVuZHBvaW50IHRvIGNhbGwgd2hlbiBDb25mZXJl
bmNlRGF0YSBzaG91bGQgYmUgY3JlYXRlZC4KCgwKBQQBAgAFEgNVAggKDAoFBAECAAESA1UJ
GwoMCgUEAQIAAxIDVR4fCgwKBQQBAgAIEgNVIEgKDwoIBAECAAicCAASA1UhRwrqAgoEBAEC
ARIDXAI5GtwCIFJlcXVpcmVkLiBJRHMgc2hvdWxkIGJlIHVuaXF1ZSBhY3Jvc3MgQ29uZmVy
ZW5jZVNvbHV0aW9ucyB3aXRoaW4gb25lCiBhZGQtb24sIGJ1dCB0aGlzIGlzIG5vdCBzdHJp
Y3RseSBlbmZvcmNlZC4gSXQgaXMgdXAgdG8gdGhlIGFkZC1vbiBkZXZlbG9wZXIKIHRvIGFz
c2lnbiB0aGVtIHVuaXF1ZWx5LCBvdGhlcndpc2UgdGhlIHdyb25nIENvbmZlcmVuY2VTb2x1
dGlvbiBtYXkgYmUKIHVzZWQgd2hlbiB0aGUgYWRkLW9uIGlzIHRyaWdnZXJlZC4gV2hpbGUg
dGhlIGRldmVsb3BlciBtYXkgY2hhbmdlIHRoZQogZGlzcGxheSBuYW1lIG9mIGFuIGFkZC1v
biwgdGhlIElEIHNob3VsZCBub3QgYmUgY2hhbmdlZC4KCgwKBQQBAgEFEgNcAggKDAoFBAEC
AQESA1wJCwoMCgUEAQIBAxIDXA4PCgwKBQQBAgEIEgNcEDgKDwoIBAECAQicCAASA1wRNwpE
CgQEAQICEgNfAjsaNyBSZXF1aXJlZC4gVGhlIGRpc3BsYXkgbmFtZSBvZiB0aGUgQ29uZmVy
ZW5jZVNvbHV0aW9uLgoKDAoFBAECAgUSA18CCAoMCgUEAQICARIDXwkNCgwKBQQBAgIDEgNf
EBEKDAoFBAECAggSA18SOgoPCggEAQICCJwIABIDXxM5Ck4KBAQBAgMSA2ICPxpBIFJlcXVp
cmVkLiBUaGUgVVJMIGZvciB0aGUgbG9nbyBpbWFnZSBvZiB0aGUgQ29uZmVyZW5jZVNvbHV0
aW9uLgoKDAoFBAECAwUSA2ICCAoMCgUEAQIDARIDYgkRCgwKBQQBAgMDEgNiFBUKDAoFBAEC
AwgSA2IWPgoPCggEAQIDCJwIABIDYhc9CkcKAgQCEgRmAGoBGjsgQ29tbW9uIGZvcm1hdCBm
b3IgZGVjbGFyaW5nIGEgY2FsZW5kYXIgYWRkLW9uJ3MgdHJpZ2dlcnMuCgoKCgMEAgESA2YI
HgpZCgQEAgIAEgNpAkMaTCBSZXF1aXJlZC4gVGhlIGVuZHBvaW50IHRvIGV4ZWN1dGUgd2hl
biB0aGlzIGV4dGVuc2lvbiBwb2ludCBpcwogYWN0aXZhdGVkLgoKDAoFBAICAAUSA2kCCAoM
CgUEAgIAARIDaQkVCgwKBQQCAgADEgNpGBkKDAoFBAICAAgSA2kaQgoPCggEAgIACJwIABID
aRtBYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Apps::Script::Type::Calendar::CalendarAddonManifest::CalendarAddOnManifest ===
    # Fields for CalendarAddOnManifest
    # Field: homepage_trigger Type: 11 (.google.apps.script.type.HomepageExtensionPoint)
    # Field: conference_solution Type: 11 (.google.apps.script.type.calendar.ConferenceSolution)
    # Field: create_settings_url_function Type: 9 ()
    # Field: event_open_trigger Type: 11 (.google.apps.script.type.calendar.CalendarExtensionPoint)
    # Field: event_update_trigger Type: 11 (.google.apps.script.type.calendar.CalendarExtensionPoint)
    # Field: current_event_access Type: 14 (.google.apps.script.type.calendar.CalendarAddOnManifest.EventAccess)

# Enum: CalendarAddOnManifest::EventAccess
our $CalendarAddOnManifest_UNSPECIFIED = 0;
our $CalendarAddOnManifest_METADATA = 1;
our $CalendarAddOnManifest_READ = 3;
our $CalendarAddOnManifest_WRITE = 4;
our $CalendarAddOnManifest_READ_WRITE = 5;

# === Message: Google::Apps::Script::Type::Calendar::CalendarAddonManifest::ConferenceSolution ===
    # Fields for ConferenceSolution
    # Field: on_create_function Type: 9 ()
    # Field: id Type: 9 ()
    # Field: name Type: 9 ()
    # Field: logo_url Type: 9 ()

# === Message: Google::Apps::Script::Type::Calendar::CalendarAddonManifest::CalendarExtensionPoint ===
    # Fields for CalendarExtensionPoint
    # Field: run_function Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Apps::Script::Type::Calendar::CalendarAddonManifest - Compiled Protocol Buffers messages for google/apps/script/type/calendar/calendar_addon_manifest.proto

=head1 SYNOPSIS

    use Google::Apps::Script::Type::Calendar::CalendarAddonManifest;

    my $msg = Google::Apps::Script::Type::Calendar::CalendarAddonManifest::CalendarAddOnManifest->new({
        homepage_trigger => $homepage_trigger,
        conference_solution => $conference_solution,
        create_settings_url_function => $create_settings_url_function,
        event_open_trigger => $event_open_trigger,
    });

    # Read or update a field
    my $val = $msg->homepage_trigger();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Apps::Script::Type::Calendar::CalendarAddonManifest::CalendarAddOnManifest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/apps/script/type/calendar/calendar_addon_manifest.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Apps::Script::Type::Calendar::CalendarAddonManifest::CalendarAddOnManifest

Calendar add-on manifest.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->homepage_trigger() >> / C<< $msg->homepage_trigger($value) >>

Type: C<Message> (L<Google::Apps::Script::Type::ExtensionPoint::HomepageExtensionPoint>)

Defines an endpoint that will be executed contexts that don't
match a declared contextual trigger. Any cards generated by this function
will always be available to the user, but may be eclipsed by contextual
content when this add-on declares more targeted triggers.

If present, this overrides the configuration from
`addOns.common.homepageTrigger`.

=item * C<< $msg->conference_solution() >> / C<< $msg->conference_solution($value) >>

Type: C<Message> (L<Google::Apps::Script::Type::Calendar::CalendarAddonManifest::ConferenceSolution>)

Defines conference solutions provided by this add-on.

=item * C<< $msg->create_settings_url_function() >> / C<< $msg->create_settings_url_function($value) >>

Type: C<String>

An endpoint to execute that creates a URL to the add-on's settings page.

=item * C<< $msg->event_open_trigger() >> / C<< $msg->event_open_trigger($value) >>

Type: C<Message> (L<Google::Apps::Script::Type::Calendar::CalendarAddonManifest::CalendarExtensionPoint>)

An endpoint to trigger when an event is opened (viewed/edited).

=item * C<< $msg->event_update_trigger() >> / C<< $msg->event_update_trigger($value) >>

Type: C<Message> (L<Google::Apps::Script::Type::Calendar::CalendarAddonManifest::CalendarExtensionPoint>)

An endpoint to trigger when the open event is updated.

=item * C<< $msg->current_event_access() >> / C<< $msg->current_event_access($value) >>

Type: C<Enum> (L<Google::Apps::Script::Type::Calendar::CalendarAddOnManifest::EventAccess>)

Define the level of data access when an event addon is triggered.

=back

=head3 Enum: CalendarAddOnManifest::EventAccess

=over 4

=item * C<UNSPECIFIED> => C<0>

=item * C<METADATA> => C<1>

=item * C<READ> => C<3>

=item * C<WRITE> => C<4>

=item * C<READ_WRITE> => C<5>

=back

=head2 Google::Apps::Script::Type::Calendar::CalendarAddonManifest::ConferenceSolution

Defines conference related values.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->on_create_function() >> / C<< $msg->on_create_function($value) >>

Type: C<String>

Required. The endpoint to call when ConferenceData should be created.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Required. IDs should be unique across ConferenceSolutions within one
add-on, but this is not strictly enforced. It is up to the add-on developer
to assign them uniquely, otherwise the wrong ConferenceSolution may be
used when the add-on is triggered. While the developer may change the
display name of an add-on, the ID should not be changed.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The display name of the ConferenceSolution.

=item * C<< $msg->logo_url() >> / C<< $msg->logo_url($value) >>

Type: C<String>

Required. The URL for the logo image of the ConferenceSolution.

=back

=head2 Google::Apps::Script::Type::Calendar::CalendarAddonManifest::CalendarExtensionPoint

Common format for declaring a calendar add-on's triggers.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->run_function() >> / C<< $msg->run_function($value) >>

Type: C<String>

Required. The endpoint to execute when this extension point is
activated.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Apps::Script::Type::Calendar::CalendarAddonManifest::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
