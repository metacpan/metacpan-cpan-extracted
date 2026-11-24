package Google::Cloud::Websecurityscanner::V1beta::FindingAddon;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxYmV0YS9maW5kaW5nX2FkZG9u
LnByb3RvEiZnb29nbGUuY2xvdWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYmV0YSI9CgRGb3Jt
Eh0KCmFjdGlvbl91cmkYASABKAlSCWFjdGlvblVyaRIWCgZmaWVsZHMYAiADKAlSBmZpZWxk
cyJ2Cg9PdXRkYXRlZExpYnJhcnkSIQoMbGlicmFyeV9uYW1lGAEgASgJUgtsaWJyYXJ5TmFt
ZRIYCgd2ZXJzaW9uGAIgASgJUgd2ZXJzaW9uEiYKD2xlYXJuX21vcmVfdXJscxgDIAMoCVIN
bGVhcm5Nb3JlVXJscyJZChFWaW9sYXRpbmdSZXNvdXJjZRIhCgxjb250ZW50X3R5cGUYASAB
KAlSC2NvbnRlbnRUeXBlEiEKDHJlc291cmNlX3VybBgCIAEoCVILcmVzb3VyY2VVcmwiPwoU
VnVsbmVyYWJsZVBhcmFtZXRlcnMSJwoPcGFyYW1ldGVyX25hbWVzGAEgAygJUg5wYXJhbWV0
ZXJOYW1lcyKOAgoRVnVsbmVyYWJsZUhlYWRlcnMSWgoHaGVhZGVycxgBIAMoCzJALmdvb2ds
ZS5jbG91ZC53ZWJzZWN1cml0eXNjYW5uZXIudjFiZXRhLlZ1bG5lcmFibGVIZWFkZXJzLkhl
YWRlclIHaGVhZGVycxJpCg9taXNzaW5nX2hlYWRlcnMYAiADKAsyQC5nb29nbGUuY2xvdWQu
d2Vic2VjdXJpdHlzY2FubmVyLnYxYmV0YS5WdWxuZXJhYmxlSGVhZGVycy5IZWFkZXJSDm1p
c3NpbmdIZWFkZXJzGjIKBkhlYWRlchISCgRuYW1lGAEgASgJUgRuYW1lEhQKBXZhbHVlGAIg
ASgJUgV2YWx1ZSJNCgNYc3MSIQoMc3RhY2tfdHJhY2VzGAEgAygJUgtzdGFja1RyYWNlcxIj
Cg1lcnJvcl9tZXNzYWdlGAIgASgJUgxlcnJvck1lc3NhZ2VCmwIKKmNvbS5nb29nbGUuY2xv
dWQud2Vic2VjdXJpdHlzY2FubmVyLnYxYmV0YUIRRmluZGluZ0FkZG9uUHJvdG9QAVpaY2xv
dWQuZ29vZ2xlLmNvbS9nby93ZWJzZWN1cml0eXNjYW5uZXIvYXBpdjFiZXRhL3dlYnNlY3Vy
aXR5c2Nhbm5lcnBiO3dlYnNlY3VyaXR5c2Nhbm5lcnBiqgImR29vZ2xlLkNsb3VkLldlYlNl
Y3VyaXR5U2Nhbm5lci5WMUJldGHKAiZHb29nbGVcQ2xvdWRcV2ViU2VjdXJpdHlTY2FubmVy
XFYxYmV0YeoCKUdvb2dsZTo6Q2xvdWQ6OldlYlNlY3VyaXR5U2Nhbm5lcjo6VjFiZXRhSrgV
CgYSBA8AWQEKvQQKAQwSAw8AEjKyBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoKCAoBAhIDEQAv
CggKAQgSAxMAQwoJCgIIJRIDEwBDCggKAQgSAxQAcQoJCgIICxIDFABxCggKAQgSAxUAIgoJ
CgIIChIDFQAiCggKAQgSAxYAMgoJCgIICBIDFgAyCggKAQgSAxcAQwoJCgIIARIDFwBDCggK
AQgSAxgAQwoJCgIIKRIDGABDCggKAQgSAxkAQgoJCgIILRIDGQBCCj8KAgQAEgQcACIBGjMg
ISBJbmZvcm1hdGlvbiBhYm91dCBhIHZ1bG5lcmFiaWxpdHkgd2l0aCBhbiBIVE1MLgoKCgoD
BAABEgMcCAwKRAoEBAACABIDHgIYGjcgISBUaGUgVVJJIHdoZXJlIHRvIHNlbmQgdGhlIGZv
cm0gd2hlbiBpdCdzIHN1Ym1pdHRlZC4KCgwKBQQAAgAFEgMeAggKDAoFBAACAAESAx4JEwoM
CgUEAAIAAxIDHhYXCkcKBAQAAgESAyECHRo6ICEgVGhlIG5hbWVzIG9mIGZvcm0gZmllbGRz
IHJlbGF0ZWQgdG8gdGhlIHZ1bG5lcmFiaWxpdHkuCgoMCgUEAAIBBBIDIQIKCgwKBQQAAgEF
EgMhCxEKDAoFBAACAQESAyESGAoMCgUEAAIBAxIDIRscCjsKAgQBEgQlAC4BGi8gSW5mb3Jt
YXRpb24gcmVwb3J0ZWQgZm9yIGFuIG91dGRhdGVkIGxpYnJhcnkuCgoKCgMEAQESAyUIFwow
CgQEAQIAEgMnAhoaIyBUaGUgbmFtZSBvZiB0aGUgb3V0ZGF0ZWQgbGlicmFyeS4KCgwKBQQB
AgAFEgMnAggKDAoFBAECAAESAycJFQoMCgUEAQIAAxIDJxgZCiIKBAQBAgESAyoCFRoVIFRo
ZSB2ZXJzaW9uIG51bWJlci4KCgwKBQQBAgEFEgMqAggKDAoFBAECAQESAyoJEAoMCgUEAQIB
AxIDKhMUClcKBAQBAgISAy0CJhpKIFVSTHMgdG8gbGVhcm4gbW9yZSBpbmZvcm1hdGlvbiBh
Ym91dCB0aGUgdnVsbmVyYWJpbGl0aWVzIGluIHRoZSBsaWJyYXJ5LgoKDAoFBAECAgQSAy0C
CgoMCgUEAQICBRIDLQsRCgwKBQQBAgIBEgMtEiEKDAoFBAECAgMSAy0kJQqAAQoCBAISBDIA
OAEadCBJbmZvcm1hdGlvbiByZWdhcmRpbmcgYW55IHJlc291cmNlIGNhdXNpbmcgdGhlIHZ1
bG5lcmFiaWxpdHkgc3VjaAogYXMgSmF2YVNjcmlwdCBzb3VyY2VzLCBpbWFnZSwgYXVkaW8g
ZmlsZXMsIGV0Yy4KCgoKAwQCARIDMggZCi4KBAQCAgASAzQCGhohIFRoZSBNSU1FIHR5cGUg
b2YgdGhpcyByZXNvdXJjZS4KCgwKBQQCAgAFEgM0AggKDAoFBAICAAESAzQJFQoMCgUEAgIA
AxIDNBgZCi4KBAQCAgESAzcCGhohIFVSTCBvZiB0aGlzIHZpb2xhdGluZyByZXNvdXJjZS4K
CgwKBQQCAgEFEgM3AggKDAoFBAICAQESAzcJFQoMCgUEAgIBAxIDNxgZCj4KAgQDEgQ7AD4B
GjIgSW5mb3JtYXRpb24gYWJvdXQgdnVsbmVyYWJsZSByZXF1ZXN0IHBhcmFtZXRlcnMuCgoK
CgMEAwESAzsIHAouCgQEAwIAEgM9AiYaISBUaGUgdnVsbmVyYWJsZSBwYXJhbWV0ZXIgbmFt
ZXMuCgoMCgUEAwIABBIDPQIKCgwKBQQDAgAFEgM9CxEKDAoFBAMCAAESAz0SIQoMCgUEAwIA
AxIDPSQlCkMKAgQEEgRBAFABGjcgSW5mb3JtYXRpb24gYWJvdXQgdnVsbmVyYWJsZSBvciBt
aXNzaW5nIEhUVFAgSGVhZGVycy4KCgoKAwQEARIDQQgZCigKBAQEAwASBEMCSQMaGiBEZXNj
cmliZXMgYSBIVFRQIEhlYWRlci4KCgwKBQQEAwABEgNDChAKHQoGBAQDAAIAEgNFBBQaDiBI
ZWFkZXIgbmFtZS4KCg4KBwQEAwACAAUSA0UECgoOCgcEBAMAAgABEgNFCw8KDgoHBAQDAAIA
AxIDRRITCh4KBgQEAwACARIDSAQVGg8gSGVhZGVyIHZhbHVlLgoKDgoHBAQDAAIBBRIDSAQK
Cg4KBwQEAwACAQESA0gLEAoOCgcEBAMAAgEDEgNIExQKKgoEBAQCABIDTAIeGh0gTGlzdCBv
ZiB2dWxuZXJhYmxlIGhlYWRlcnMuCgoMCgUEBAIABBIDTAIKCgwKBQQEAgAGEgNMCxEKDAoF
BAQCAAESA0wSGQoMCgUEBAIAAxIDTBwdCicKBAQEAgESA08CJhoaIExpc3Qgb2YgbWlzc2lu
ZyBoZWFkZXJzLgoKDAoFBAQCAQQSA08CCgoMCgUEBAIBBhIDTwsRCgwKBQQEAgEBEgNPEiEK
DAoFBAQCAQMSA08kJQouCgIEBRIEUwBZARoiIEluZm9ybWF0aW9uIHJlcG9ydGVkIGZvciBh
biBYU1MuCgoKCgMEBQESA1MICwpICgQEBQIAEgNVAiMaOyBTdGFjayB0cmFjZXMgbGVhZGlu
ZyB0byB0aGUgcG9pbnQgd2hlcmUgdGhlIFhTUyBvY2N1cnJlZC4KCgwKBQQFAgAEEgNVAgoK
DAoFBAUCAAUSA1ULEQoMCgUEBQIAARIDVRIeCgwKBQQFAgADEgNVISIKQwoEBAUCARIDWAIb
GjYgQW4gZXJyb3IgbWVzc2FnZSBnZW5lcmF0ZWQgYnkgYSBqYXZhc2NyaXB0IGJyZWFrYWdl
LgoKDAoFBAUCAQUSA1gCCAoMCgUEBQIBARIDWAkWCgwKBQQFAgEDEgNYGRpiBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1beta::FindingAddon::Form ===
    # Fields for Form
    # Field: action_uri Type: 9 ()
    # Field: fields Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1beta::FindingAddon::OutdatedLibrary ===
    # Fields for OutdatedLibrary
    # Field: library_name Type: 9 ()
    # Field: version Type: 9 ()
    # Field: learn_more_urls Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1beta::FindingAddon::ViolatingResource ===
    # Fields for ViolatingResource
    # Field: content_type Type: 9 ()
    # Field: resource_url Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1beta::FindingAddon::VulnerableParameters ===
    # Fields for VulnerableParameters
    # Field: parameter_names Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1beta::FindingAddon::VulnerableHeaders ===
    # Fields for VulnerableHeaders
    # Field: headers Type: 11 (.google.cloud.websecurityscanner.v1beta.VulnerableHeaders.Header)
    # Field: missing_headers Type: 11 (.google.cloud.websecurityscanner.v1beta.VulnerableHeaders.Header)

# === Message: Google::Cloud::Websecurityscanner::V1beta::FindingAddon::Xss ===
    # Fields for Xss
    # Field: stack_traces Type: 9 ()
    # Field: error_message Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Websecurityscanner::V1beta::FindingAddon - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1beta/finding_addon.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1beta::FindingAddon;

    my $msg = Google::Cloud::Websecurityscanner::V1beta::FindingAddon::Form->new({
        action_uri => $action_uri,
        fields => $fields,
    });

    # Read or update a field
    my $val = $msg->action_uri();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1beta::FindingAddon::Form->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1beta/finding_addon.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1beta::FindingAddon::Form

! Information about a vulnerability with an HTML.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->action_uri() >> / C<< $msg->action_uri($value) >>

Type: C<String>

! The URI where to send the form when it's submitted.

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<String>

! The names of form fields related to the vulnerability.

=back

=head2 Google::Cloud::Websecurityscanner::V1beta::FindingAddon::OutdatedLibrary

Information reported for an outdated library.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->library_name() >> / C<< $msg->library_name($value) >>

Type: C<String>

The name of the outdated library.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

The version number.

=item * C<< $msg->learn_more_urls() >> / C<< $msg->learn_more_urls($value) >>

Type: C<String>

URLs to learn more information about the vulnerabilities in the library.

=back

=head2 Google::Cloud::Websecurityscanner::V1beta::FindingAddon::ViolatingResource

Information regarding any resource causing the vulnerability such
as JavaScript sources, image, audio files, etc.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->content_type() >> / C<< $msg->content_type($value) >>

Type: C<String>

The MIME type of this resource.

=item * C<< $msg->resource_url() >> / C<< $msg->resource_url($value) >>

Type: C<String>

URL of this violating resource.

=back

=head2 Google::Cloud::Websecurityscanner::V1beta::FindingAddon::VulnerableParameters

Information about vulnerable request parameters.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parameter_names() >> / C<< $msg->parameter_names($value) >>

Type: C<String>

The vulnerable parameter names.

=back

=head2 Google::Cloud::Websecurityscanner::V1beta::FindingAddon::VulnerableHeaders

Information about vulnerable or missing HTTP Headers.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->headers() >> / C<< $msg->headers($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1beta::FindingAddon::VulnerableHeaders::Header>)

List of vulnerable headers.

=item * C<< $msg->missing_headers() >> / C<< $msg->missing_headers($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1beta::FindingAddon::VulnerableHeaders::Header>)

List of missing headers.

=back

=head2 Google::Cloud::Websecurityscanner::V1beta::FindingAddon::Xss

Information reported for an XSS.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->stack_traces() >> / C<< $msg->stack_traces($value) >>

Type: C<String>

Stack traces leading to the point where the XSS occurred.

=item * C<< $msg->error_message() >> / C<< $msg->error_message($value) >>

Type: C<String>

An error message generated by a javascript breakage.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1beta::FindingAddon::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
