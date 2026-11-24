package Google::Cloud::Ces::V1::Changelog;

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
CiNnb29nbGUvY2xvdWQvY2VzL3YxL2NoYW5nZWxvZy5wcm90bxITZ29vZ2xlLmNsb3VkLmNl
cy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNv
dXJjZS5wcm90bxocZ29vZ2xlL3Byb3RvYnVmL3N0cnVjdC5wcm90bxofZ29vZ2xlL3Byb3Rv
YnVmL3RpbWVzdGFtcC5wcm90byLKBQoJQ2hhbmdlbG9nEhcKBG5hbWUYASABKAlCA+BBCFIE
bmFtZRIbCgZhdXRob3IYAiABKAlCA+BBA1IGYXV0aG9yEiYKDGRpc3BsYXlfbmFtZRgDIAEo
CUID4EEDUgtkaXNwbGF5TmFtZRIlCgtkZXNjcmlwdGlvbhgLIAEoCUID4EEDUgtkZXNjcmlw
dGlvbhIfCghyZXNvdXJjZRgEIAEoCUID4EEDUghyZXNvdXJjZRIoCg1yZXNvdXJjZV90eXBl
GAUgASgJQgPgQQNSDHJlc291cmNlVHlwZRIbCgZhY3Rpb24YBiABKAlCA+BBA1IGYWN0aW9u
EkkKEW9yaWdpbmFsX3Jlc291cmNlGAcgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdEID
4EEDUhBvcmlnaW5hbFJlc291cmNlEj8KDG5ld19yZXNvdXJjZRgIIAEoCzIXLmdvb2dsZS5w
cm90b2J1Zi5TdHJ1Y3RCA+BBA1ILbmV3UmVzb3VyY2USTQoTZGVwZW5kZW50X3Jlc291cmNl
cxgJIAMoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RCA+BBA1ISZGVwZW5kZW50UmVzb3Vy
Y2VzEkAKC2NyZWF0ZV90aW1lGAogASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID
4EEDUgpjcmVhdGVUaW1lEiwKD3NlcXVlbmNlX251bWJlchgMIAEoA0ID4EEDUg5zZXF1ZW5j
ZU51bWJlcjqEAepBgAEKHGNlcy5nb29nbGVhcGlzLmNvbS9DaGFuZ2Vsb2cSSXByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hcHBzL3thcHB9L2NoYW5nZWxvZ3Mv
e2NoYW5nZWxvZ30qCmNoYW5nZWxvZ3MyCWNoYW5nZWxvZ0JWChdjb20uZ29vZ2xlLmNsb3Vk
LmNlcy52MUIOQ2hhbmdlbG9nUHJvdG9QAVopY2xvdWQuZ29vZ2xlLmNvbS9nby9jZXMvYXBp
djEvY2VzcGI7Y2VzcGJK6RUKBhIEDgBRAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2
IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNp
b24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhj
ZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEg
Y29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGlj
ZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcg
b3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0
aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9V
VCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNz
IG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFn
ZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGlj
ZW5zZS4KCggKAQISAxAAHAoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAJgoJCgID
AxIDFQApCggKAQgSAxcAQAoJCgIICxIDFwBACggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgS
AxkALwoJCgIICBIDGQAvCggKAQgSAxoAMAoJCgIIARIDGgAwCl4KAgQAEgQeAFEBGlIgQ2hh
bmdlbG9ncyByZXByZXNlbnQgYSBjaGFuZ2UgbWFkZSB0byB0aGUgYXBwIG9yIHRvIGFuIHJl
c291cmNlIHdpdGhpbiB0aGUKIGFwcC4KCgoKAwQAARIDHggRCgsKAwQABxIEHwIkBAoNCgUE
AAedCBIEHwIkBAqZAQoEBAACABIDKQI9GosBIElkZW50aWZpZXIuIFRoZSB1bmlxdWUgaWRl
bnRpZmllciBvZiB0aGUgY2hhbmdlbG9nLgogRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hcHBzL3thcHB9L2NoYW5nZWxvZ3Mve2NoYW5nZWxv
Z31gCgoMCgUEAAIABRIDKQIICgwKBQQAAgABEgMpCQ0KDAoFBAACAAMSAykQEQoMCgUEAAIA
CBIDKRI8Cg8KCAQAAgAInAgAEgMpEzsKPwoEBAACARIDLAJAGjIgT3V0cHV0IG9ubHkuIEVt
YWlsIGFkZHJlc3Mgb2YgdGhlIGNoYW5nZSBhdXRob3IuCgoMCgUEAAIBBRIDLAIICgwKBQQA
AgEBEgMsCQ8KDAoFBAACAQMSAywSEwoMCgUEAAIBCBIDLBQ/Cg8KCAQAAgEInAgAEgMsFT4K
ggEKBAQAAgISAzACRhp1IE91dHB1dCBvbmx5LiBEaXNwbGF5IG5hbWUgb2YgdGhlIGNoYW5n
ZS4gSXQgdHlwaWNhbGx5IHNob3VsZCBiZSB0aGUgZGlzcGxheQogbmFtZSBvZiB0aGUgcmVz
b3VyY2UgdGhhdCB3YXMgY2hhbmdlZC4KCgwKBQQAAgIFEgMwAggKDAoFBAACAgESAzAJFQoM
CgUEAAICAxIDMBgZCgwKBQQAAgIIEgMwGkUKDwoIBAACAgicCAASAzAbRAp0CgQEAAIDEgM0
AkYaZyBPdXRwdXQgb25seS4gRGVzY3JpcHRpb24gb2YgdGhlIGNoYW5nZS4gd2hpY2ggdHlw
aWNhbGx5IGNhcHR1cmVzIHRoZQogY2hhbmdlZCBmaWVsZHMgaW4gdGhlIHJlc291cmNlLgoK
DAoFBAACAwUSAzQCCAoMCgUEAAIDARIDNAkUCgwKBQQAAgMDEgM0FxkKDAoFBAACAwgSAzQa
RQoPCggEAAIDCJwIABIDNBtECjoKBAQAAgQSAzcCQhotIE91dHB1dCBvbmx5LiBUaGUgcmVz
b3VyY2UgdGhhdCB3YXMgY2hhbmdlZC4KCgwKBQQAAgQFEgM3AggKDAoFBAACBAESAzcJEQoM
CgUEAAIEAxIDNxQVCgwKBQQAAgQIEgM3FkEKDwoIBAACBAicCAASAzcXQApGCgQEAAIFEgM6
AkcaOSBPdXRwdXQgb25seS4gVGhlIHR5cGUgb2YgdGhlIHJlc291cmNlIHRoYXQgd2FzIGNo
YW5nZWQuCgoMCgUEAAIFBRIDOgIICgwKBQQAAgUBEgM6CRYKDAoFBAACBQMSAzoZGgoMCgUE
AAIFCBIDOhtGCg8KCAQAAgUInAgAEgM6HEUKSgoEBAACBhIDPQJAGj0gT3V0cHV0IG9ubHku
IFRoZSBhY3Rpb24gdGhhdCB3YXMgcGVyZm9ybWVkIG9uIHRoZSByZXNvdXJjZS4KCgwKBQQA
AgYFEgM9AggKDAoFBAACBgESAz0JDwoMCgUEAAIGAxIDPRITCgwKBQQAAgYIEgM9FD8KDwoI
BAACBgicCAASAz0VPgpFCgQEAAIHEgRAAkEyGjcgT3V0cHV0IG9ubHkuIFRoZSBvcmlnaW5h
bCByZXNvdXJjZSBiZWZvcmUgdGhlIGNoYW5nZS4KCgwKBQQAAgcGEgNAAhgKDAoFBAACBwES
A0AZKgoMCgUEAAIHAxIDQC0uCgwKBQQAAgcIEgNBBjEKDwoIBAACBwicCAASA0EHMAo/CgQE
AAIIEgREAkUyGjEgT3V0cHV0IG9ubHkuIFRoZSBuZXcgcmVzb3VyY2UgYWZ0ZXIgdGhlIGNo
YW5nZS4KCgwKBQQAAggGEgNEAhgKDAoFBAACCAESA0QZJQoMCgUEAAIIAxIDRCgpCgwKBQQA
AggIEgNFBjEKDwoIBAACCAicCAASA0UHMApHCgQEAAIJEgRIAkkyGjkgT3V0cHV0IG9ubHku
IFRoZSBkZXBlbmRlbnQgcmVzb3VyY2VzIHRoYXQgd2VyZSBjaGFuZ2VkLgoKDAoFBAACCQQS
A0gCCgoMCgUEAAIJBhIDSAshCgwKBQQAAgkBEgNIIjUKDAoFBAACCQMSA0g4OQoMCgUEAAIJ
CBIDSQYxCg8KCAQAAgkInAgAEgNJBzAKPwoEBAACChIETAJNMhoxIE91dHB1dCBvbmx5LiBU
aGUgdGltZSB3aGVuIHRoZSBjaGFuZ2Ugd2FzIG1hZGUuCgoMCgUEAAIKBhIDTAIbCgwKBQQA
AgoBEgNMHCcKDAoFBAACCgMSA0wqLAoMCgUEAAIKCBIDTQYxCg8KCAQAAgoInAgAEgNNBzAK
WgoEBAACCxIDUAJJGk0gT3V0cHV0IG9ubHkuIFRoZSBtb25vdG9uaWNhbGx5IGluY3JlYXNp
bmcgc2VxdWVuY2UgbnVtYmVyIG9mIHRoZSBjaGFuZ2Vsb2cuCgoMCgUEAAILBRIDUAIHCgwK
BQQAAgsBEgNQCBcKDAoFBAACCwMSA1AaHAoMCgUEAAILCBIDUB1ICg8KCAQAAgsInAgAEgNQ
HkdiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::Changelog::Changelog ===
    # Fields for Changelog
    # Field: name Type: 9 ()
    # Field: author Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: resource Type: 9 ()
    # Field: resource_type Type: 9 ()
    # Field: action Type: 9 ()
    # Field: original_resource Type: 11 (.google.protobuf.Struct)
    # Field: new_resource Type: 11 (.google.protobuf.Struct)
    # Field: dependent_resources Type: 11 (.google.protobuf.Struct)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: sequence_number Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::Changelog - Compiled Protocol Buffers messages for google/cloud/ces/v1/changelog.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::Changelog;

    my $msg = Google::Cloud::Ces::V1::Changelog::Changelog->new({
        name => $name,
        author => $author,
        display_name => $display_name,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::Changelog::Changelog->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/changelog.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::Changelog::Changelog

Changelogs represent a change made to the app or to an resource within the
app.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The unique identifier of the changelog.
Format:
`projects/{project}/locations/{location}/apps/{app}/changelogs/{changelog}`

=item * C<< $msg->author() >> / C<< $msg->author($value) >>

Type: C<String>

Output only. Email address of the change author.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. Display name of the change. It typically should be the display
name of the resource that was changed.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Output only. Description of the change. which typically captures the
changed fields in the resource.

=item * C<< $msg->resource() >> / C<< $msg->resource($value) >>

Type: C<String>

Output only. The resource that was changed.

=item * C<< $msg->resource_type() >> / C<< $msg->resource_type($value) >>

Type: C<String>

Output only. The type of the resource that was changed.

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<String>

Output only. The action that was performed on the resource.

=item * C<< $msg->original_resource() >> / C<< $msg->original_resource($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Output only. The original resource before the change.

=item * C<< $msg->new_resource() >> / C<< $msg->new_resource($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Output only. The new resource after the change.

=item * C<< $msg->dependent_resources() >> / C<< $msg->dependent_resources($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Output only. The dependent resources that were changed.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the change was made.

=item * C<< $msg->sequence_number() >> / C<< $msg->sequence_number($value) >>

Type: C<Int64>

Output only. The monotonically increasing sequence number of the changelog.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::Changelog::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
