package Google::Cloud::Websecurityscanner::V1alpha::FindingAddon;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cjtnb29nbGUvY2xvdWQvd2Vic2VjdXJpdHlzY2FubmVyL3YxYWxwaGEvZmluZGluZ19hZGRv
bi5wcm90bxInZ29vZ2xlLmNsb3VkLndlYnNlY3VyaXR5c2Nhbm5lci52MWFscGhhInYKD091
dGRhdGVkTGlicmFyeRIhCgxsaWJyYXJ5X25hbWUYASABKAlSC2xpYnJhcnlOYW1lEhgKB3Zl
cnNpb24YAiABKAlSB3ZlcnNpb24SJgoPbGVhcm5fbW9yZV91cmxzGAMgAygJUg1sZWFybk1v
cmVVcmxzIlkKEVZpb2xhdGluZ1Jlc291cmNlEiEKDGNvbnRlbnRfdHlwZRgBIAEoCVILY29u
dGVudFR5cGUSIQoMcmVzb3VyY2VfdXJsGAIgASgJUgtyZXNvdXJjZVVybCI/ChRWdWxuZXJh
YmxlUGFyYW1ldGVycxInCg9wYXJhbWV0ZXJfbmFtZXMYASADKAlSDnBhcmFtZXRlck5hbWVz
IpACChFWdWxuZXJhYmxlSGVhZGVycxJbCgdoZWFkZXJzGAEgAygLMkEuZ29vZ2xlLmNsb3Vk
LndlYnNlY3VyaXR5c2Nhbm5lci52MWFscGhhLlZ1bG5lcmFibGVIZWFkZXJzLkhlYWRlclIH
aGVhZGVycxJqCg9taXNzaW5nX2hlYWRlcnMYAiADKAsyQS5nb29nbGUuY2xvdWQud2Vic2Vj
dXJpdHlzY2FubmVyLnYxYWxwaGEuVnVsbmVyYWJsZUhlYWRlcnMuSGVhZGVyUg5taXNzaW5n
SGVhZGVycxoyCgZIZWFkZXISEgoEbmFtZRgBIAEoCVIEbmFtZRIUCgV2YWx1ZRgCIAEoCVIF
dmFsdWUiTQoDWHNzEiEKDHN0YWNrX3RyYWNlcxgBIAMoCVILc3RhY2tUcmFjZXMSIwoNZXJy
b3JfbWVzc2FnZRgCIAEoCVIMZXJyb3JNZXNzYWdlQp8BCitjb20uZ29vZ2xlLmNsb3VkLndl
YnNlY3VyaXR5c2Nhbm5lci52MWFscGhhQhFGaW5kaW5nQWRkb25Qcm90b1ABWltjbG91ZC5n
b29nbGUuY29tL2dvL3dlYnNlY3VyaXR5c2Nhbm5lci9hcGl2MWFscGhhL3dlYnNlY3VyaXR5
c2Nhbm5lcnBiO3dlYnNlY3VyaXR5c2Nhbm5lcnBiSrsSCgYSBA8ATQEKvQQKAQwSAw8AEjKy
BCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoKCAoBAhIDEQAwCggKAQgSAxMAcgoJCgIICxIDEwBy
CggKAQgSAxQAIgoJCgIIChIDFAAiCggKAQgSAxUAMgoJCgIICBIDFQAyCggKAQgSAxYARAoJ
CgIIARIDFgBECjsKAgQAEgQZACIBGi8gSW5mb3JtYXRpb24gcmVwb3J0ZWQgZm9yIGFuIG91
dGRhdGVkIGxpYnJhcnkuCgoKCgMEAAESAxkIFwowCgQEAAIAEgMbAhoaIyBUaGUgbmFtZSBv
ZiB0aGUgb3V0ZGF0ZWQgbGlicmFyeS4KCgwKBQQAAgAFEgMbAggKDAoFBAACAAESAxsJFQoM
CgUEAAIAAxIDGxgZCiIKBAQAAgESAx4CFRoVIFRoZSB2ZXJzaW9uIG51bWJlci4KCgwKBQQA
AgEFEgMeAggKDAoFBAACAQESAx4JEAoMCgUEAAIBAxIDHhMUClcKBAQAAgISAyECJhpKIFVS
THMgdG8gbGVhcm4gbW9yZSBpbmZvcm1hdGlvbiBhYm91dCB0aGUgdnVsbmVyYWJpbGl0aWVz
IGluIHRoZSBsaWJyYXJ5LgoKDAoFBAACAgQSAyECCgoMCgUEAAICBRIDIQsRCgwKBQQAAgIB
EgMhEiEKDAoFBAACAgMSAyEkJQqAAQoCBAESBCYALAEadCBJbmZvcm1hdGlvbiByZWdhcmRp
bmcgYW55IHJlc291cmNlIGNhdXNpbmcgdGhlIHZ1bG5lcmFiaWxpdHkgc3VjaAogYXMgSmF2
YVNjcmlwdCBzb3VyY2VzLCBpbWFnZSwgYXVkaW8gZmlsZXMsIGV0Yy4KCgoKAwQBARIDJggZ
Ci4KBAQBAgASAygCGhohIFRoZSBNSU1FIHR5cGUgb2YgdGhpcyByZXNvdXJjZS4KCgwKBQQB
AgAFEgMoAggKDAoFBAECAAESAygJFQoMCgUEAQIAAxIDKBgZCi4KBAQBAgESAysCGhohIFVS
TCBvZiB0aGlzIHZpb2xhdGluZyByZXNvdXJjZS4KCgwKBQQBAgEFEgMrAggKDAoFBAECAQES
AysJFQoMCgUEAQIBAxIDKxgZCj4KAgQCEgQvADIBGjIgSW5mb3JtYXRpb24gYWJvdXQgdnVs
bmVyYWJsZSByZXF1ZXN0IHBhcmFtZXRlcnMuCgoKCgMEAgESAy8IHAouCgQEAgIAEgMxAiYa
ISBUaGUgdnVsbmVyYWJsZSBwYXJhbWV0ZXIgbmFtZXMuCgoMCgUEAgIABBIDMQIKCgwKBQQC
AgAFEgMxCxEKDAoFBAICAAESAzESIQoMCgUEAgIAAxIDMSQlCkMKAgQDEgQ1AEQBGjcgSW5m
b3JtYXRpb24gYWJvdXQgdnVsbmVyYWJsZSBvciBtaXNzaW5nIEhUVFAgSGVhZGVycy4KCgoK
AwQDARIDNQgZCigKBAQDAwASBDcCPQMaGiBEZXNjcmliZXMgYSBIVFRQIEhlYWRlci4KCgwK
BQQDAwABEgM3ChAKHQoGBAMDAAIAEgM5BBQaDiBIZWFkZXIgbmFtZS4KCg4KBwQDAwACAAUS
AzkECgoOCgcEAwMAAgABEgM5Cw8KDgoHBAMDAAIAAxIDORITCh4KBgQDAwACARIDPAQVGg8g
SGVhZGVyIHZhbHVlLgoKDgoHBAMDAAIBBRIDPAQKCg4KBwQDAwACAQESAzwLEAoOCgcEAwMA
AgEDEgM8ExQKKgoEBAMCABIDQAIeGh0gTGlzdCBvZiB2dWxuZXJhYmxlIGhlYWRlcnMuCgoM
CgUEAwIABBIDQAIKCgwKBQQDAgAGEgNACxEKDAoFBAMCAAESA0ASGQoMCgUEAwIAAxIDQBwd
CicKBAQDAgESA0MCJhoaIExpc3Qgb2YgbWlzc2luZyBoZWFkZXJzLgoKDAoFBAMCAQQSA0MC
CgoMCgUEAwIBBhIDQwsRCgwKBQQDAgEBEgNDEiEKDAoFBAMCAQMSA0MkJQouCgIEBBIERwBN
ARoiIEluZm9ybWF0aW9uIHJlcG9ydGVkIGZvciBhbiBYU1MuCgoKCgMEBAESA0cICwpICgQE
BAIAEgNJAiMaOyBTdGFjayB0cmFjZXMgbGVhZGluZyB0byB0aGUgcG9pbnQgd2hlcmUgdGhl
IFhTUyBvY2N1cnJlZC4KCgwKBQQEAgAEEgNJAgoKDAoFBAQCAAUSA0kLEQoMCgUEBAIAARID
SRIeCgwKBQQEAgADEgNJISIKQwoEBAQCARIDTAIbGjYgQW4gZXJyb3IgbWVzc2FnZSBnZW5l
cmF0ZWQgYnkgYSBqYXZhc2NyaXB0IGJyZWFrYWdlLgoKDAoFBAQCAQUSA0wCCAoMCgUEBAIB
ARIDTAkWCgwKBQQEAgEDEgNMGRpiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Websecurityscanner::V1alpha::FindingAddon::OutdatedLibrary ===
    # Fields for OutdatedLibrary
    # Field: library_name Type: 9 ()
    # Field: version Type: 9 ()
    # Field: learn_more_urls Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1alpha::FindingAddon::ViolatingResource ===
    # Fields for ViolatingResource
    # Field: content_type Type: 9 ()
    # Field: resource_url Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1alpha::FindingAddon::VulnerableParameters ===
    # Fields for VulnerableParameters
    # Field: parameter_names Type: 9 ()

# === Message: Google::Cloud::Websecurityscanner::V1alpha::FindingAddon::VulnerableHeaders ===
    # Fields for VulnerableHeaders
    # Field: headers Type: 11 (.google.cloud.websecurityscanner.v1alpha.VulnerableHeaders.Header)
    # Field: missing_headers Type: 11 (.google.cloud.websecurityscanner.v1alpha.VulnerableHeaders.Header)

# === Message: Google::Cloud::Websecurityscanner::V1alpha::FindingAddon::Xss ===
    # Fields for Xss
    # Field: stack_traces Type: 9 ()
    # Field: error_message Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Websecurityscanner::V1alpha::FindingAddon - Compiled Protocol Buffers messages for google/cloud/websecurityscanner/v1alpha/finding_addon.proto

=head1 SYNOPSIS

    use Google::Cloud::Websecurityscanner::V1alpha::FindingAddon;

    my $msg = Google::Cloud::Websecurityscanner::V1alpha::FindingAddon::OutdatedLibrary->new({
        library_name => $library_name,
        version => $version,
        learn_more_urls => $learn_more_urls,
    });

    # Read or update a field
    my $val = $msg->library_name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Websecurityscanner::V1alpha::FindingAddon::OutdatedLibrary->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/websecurityscanner/v1alpha/finding_addon.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Websecurityscanner::V1alpha::FindingAddon::OutdatedLibrary

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

=head2 Google::Cloud::Websecurityscanner::V1alpha::FindingAddon::ViolatingResource

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

=head2 Google::Cloud::Websecurityscanner::V1alpha::FindingAddon::VulnerableParameters

Information about vulnerable request parameters.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parameter_names() >> / C<< $msg->parameter_names($value) >>

Type: C<String>

The vulnerable parameter names.

=back

=head2 Google::Cloud::Websecurityscanner::V1alpha::FindingAddon::VulnerableHeaders

Information about vulnerable or missing HTTP Headers.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->headers() >> / C<< $msg->headers($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1alpha::FindingAddon::VulnerableHeaders::Header>)

List of vulnerable headers.

=item * C<< $msg->missing_headers() >> / C<< $msg->missing_headers($value) >>

Type: C<Message> (L<Google::Cloud::Websecurityscanner::V1alpha::FindingAddon::VulnerableHeaders::Header>)

List of missing headers.

=back

=head2 Google::Cloud::Websecurityscanner::V1alpha::FindingAddon::Xss

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Websecurityscanner::V1alpha::FindingAddon::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
