package Google::Cloud::Ces::V1beta::Changelog;

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
Cidnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9jaGFuZ2Vsb2cucHJvdG8SF2dvb2dsZS5jbG91
ZC5jZXMudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUv
YXBpL3Jlc291cmNlLnByb3RvGhxnb29nbGUvcHJvdG9idWYvc3RydWN0LnByb3RvGh9nb29n
bGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIsoFCglDaGFuZ2Vsb2cSFwoEbmFtZRgBIAEo
CUID4EEIUgRuYW1lEhsKBmF1dGhvchgCIAEoCUID4EEDUgZhdXRob3ISJgoMZGlzcGxheV9u
YW1lGAMgASgJQgPgQQNSC2Rpc3BsYXlOYW1lEiUKC2Rlc2NyaXB0aW9uGAsgASgJQgPgQQNS
C2Rlc2NyaXB0aW9uEh8KCHJlc291cmNlGAQgASgJQgPgQQNSCHJlc291cmNlEigKDXJlc291
cmNlX3R5cGUYBSABKAlCA+BBA1IMcmVzb3VyY2VUeXBlEhsKBmFjdGlvbhgGIAEoCUID4EED
UgZhY3Rpb24SSQoRb3JpZ2luYWxfcmVzb3VyY2UYByABKAsyFy5nb29nbGUucHJvdG9idWYu
U3RydWN0QgPgQQNSEG9yaWdpbmFsUmVzb3VyY2USPwoMbmV3X3Jlc291cmNlGAggASgLMhcu
Z29vZ2xlLnByb3RvYnVmLlN0cnVjdEID4EEDUgtuZXdSZXNvdXJjZRJNChNkZXBlbmRlbnRf
cmVzb3VyY2VzGAkgAygLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdEID4EEDUhJkZXBlbmRl
bnRSZXNvdXJjZXMSQAoLY3JlYXRlX3RpbWUYCiABKAsyGi5nb29nbGUucHJvdG9idWYuVGlt
ZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSLAoPc2VxdWVuY2VfbnVtYmVyGAwgASgDQgPgQQNS
DnNlcXVlbmNlTnVtYmVyOoQB6kGAAQocY2VzLmdvb2dsZWFwaXMuY29tL0NoYW5nZWxvZxJJ
cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FwcHMve2FwcH0vY2hh
bmdlbG9ncy97Y2hhbmdlbG9nfSoKY2hhbmdlbG9nczIJY2hhbmdlbG9nQl4KG2NvbS5nb29n
bGUuY2xvdWQuY2VzLnYxYmV0YUIOQ2hhbmdlbG9nUHJvdG9QAVotY2xvdWQuZ29vZ2xlLmNv
bS9nby9jZXMvYXBpdjFiZXRhL2Nlc3BiO2Nlc3BiSukVCgYSBA4AUQEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACAKCQoCAwASAxIAKQoJCgIDARIDEwAj
CgkKAgMCEgMUACYKCQoCAwMSAxUAKQoICgEIEgMXAEQKCQoCCAsSAxcARAoICgEIEgMYACIK
CQoCCAoSAxgAIgoICgEIEgMZAC8KCQoCCAgSAxkALwoICgEIEgMaADQKCQoCCAESAxoANApe
CgIEABIEHgBRARpSIENoYW5nZWxvZ3MgcmVwcmVzZW50IGEgY2hhbmdlIG1hZGUgdG8gdGhl
IGFwcCBvciB0byBhbiByZXNvdXJjZSB3aXRoaW4gdGhlCiBhcHAuCgoKCgMEAAESAx4IEQoL
CgMEAAcSBB8CJAQKDQoFBAAHnQgSBB8CJAQKmQEKBAQAAgASAykCPRqLASBJZGVudGlmaWVy
LiBUaGUgdW5pcXVlIGlkZW50aWZpZXIgb2YgdGhlIGNoYW5nZWxvZy4KIEZvcm1hdDoKIGBw
cm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYXBwcy97YXBwfS9jaGFu
Z2Vsb2dzL3tjaGFuZ2Vsb2d9YAoKDAoFBAACAAUSAykCCAoMCgUEAAIAARIDKQkNCgwKBQQA
AgADEgMpEBEKDAoFBAACAAgSAykSPAoPCggEAAIACJwIABIDKRM7Cj8KBAQAAgESAywCQBoy
IE91dHB1dCBvbmx5LiBFbWFpbCBhZGRyZXNzIG9mIHRoZSBjaGFuZ2UgYXV0aG9yLgoKDAoF
BAACAQUSAywCCAoMCgUEAAIBARIDLAkPCgwKBQQAAgEDEgMsEhMKDAoFBAACAQgSAywUPwoP
CggEAAIBCJwIABIDLBU+CoIBCgQEAAICEgMwAkYadSBPdXRwdXQgb25seS4gRGlzcGxheSBu
YW1lIG9mIHRoZSBjaGFuZ2UuIEl0IHR5cGljYWxseSBzaG91bGQgYmUgdGhlIGRpc3BsYXkK
IG5hbWUgb2YgdGhlIHJlc291cmNlIHRoYXQgd2FzIGNoYW5nZWQuCgoMCgUEAAICBRIDMAII
CgwKBQQAAgIBEgMwCRUKDAoFBAACAgMSAzAYGQoMCgUEAAICCBIDMBpFCg8KCAQAAgIInAgA
EgMwG0QKdAoEBAACAxIDNAJGGmcgT3V0cHV0IG9ubHkuIERlc2NyaXB0aW9uIG9mIHRoZSBj
aGFuZ2UuIHdoaWNoIHR5cGljYWxseSBjYXB0dXJlcyB0aGUKIGNoYW5nZWQgZmllbGRzIGlu
IHRoZSByZXNvdXJjZS4KCgwKBQQAAgMFEgM0AggKDAoFBAACAwESAzQJFAoMCgUEAAIDAxID
NBcZCgwKBQQAAgMIEgM0GkUKDwoIBAACAwicCAASAzQbRAo6CgQEAAIEEgM3AkIaLSBPdXRw
dXQgb25seS4gVGhlIHJlc291cmNlIHRoYXQgd2FzIGNoYW5nZWQuCgoMCgUEAAIEBRIDNwII
CgwKBQQAAgQBEgM3CREKDAoFBAACBAMSAzcUFQoMCgUEAAIECBIDNxZBCg8KCAQAAgQInAgA
EgM3F0AKRgoEBAACBRIDOgJHGjkgT3V0cHV0IG9ubHkuIFRoZSB0eXBlIG9mIHRoZSByZXNv
dXJjZSB0aGF0IHdhcyBjaGFuZ2VkLgoKDAoFBAACBQUSAzoCCAoMCgUEAAIFARIDOgkWCgwK
BQQAAgUDEgM6GRoKDAoFBAACBQgSAzobRgoPCggEAAIFCJwIABIDOhxFCkoKBAQAAgYSAz0C
QBo9IE91dHB1dCBvbmx5LiBUaGUgYWN0aW9uIHRoYXQgd2FzIHBlcmZvcm1lZCBvbiB0aGUg
cmVzb3VyY2UuCgoMCgUEAAIGBRIDPQIICgwKBQQAAgYBEgM9CQ8KDAoFBAACBgMSAz0SEwoM
CgUEAAIGCBIDPRQ/Cg8KCAQAAgYInAgAEgM9FT4KRQoEBAACBxIEQAJBMho3IE91dHB1dCBv
bmx5LiBUaGUgb3JpZ2luYWwgcmVzb3VyY2UgYmVmb3JlIHRoZSBjaGFuZ2UuCgoMCgUEAAIH
BhIDQAIYCgwKBQQAAgcBEgNAGSoKDAoFBAACBwMSA0AtLgoMCgUEAAIHCBIDQQYxCg8KCAQA
AgcInAgAEgNBBzAKPwoEBAACCBIERAJFMhoxIE91dHB1dCBvbmx5LiBUaGUgbmV3IHJlc291
cmNlIGFmdGVyIHRoZSBjaGFuZ2UuCgoMCgUEAAIIBhIDRAIYCgwKBQQAAggBEgNEGSUKDAoF
BAACCAMSA0QoKQoMCgUEAAIICBIDRQYxCg8KCAQAAggInAgAEgNFBzAKRwoEBAACCRIESAJJ
Mho5IE91dHB1dCBvbmx5LiBUaGUgZGVwZW5kZW50IHJlc291cmNlcyB0aGF0IHdlcmUgY2hh
bmdlZC4KCgwKBQQAAgkEEgNIAgoKDAoFBAACCQYSA0gLIQoMCgUEAAIJARIDSCI1CgwKBQQA
AgkDEgNIODkKDAoFBAACCQgSA0kGMQoPCggEAAIJCJwIABIDSQcwCj8KBAQAAgoSBEwCTTIa
MSBPdXRwdXQgb25seS4gVGhlIHRpbWUgd2hlbiB0aGUgY2hhbmdlIHdhcyBtYWRlLgoKDAoF
BAACCgYSA0wCGwoMCgUEAAIKARIDTBwnCgwKBQQAAgoDEgNMKiwKDAoFBAACCggSA00GMQoP
CggEAAIKCJwIABIDTQcwCloKBAQAAgsSA1ACSRpNIE91dHB1dCBvbmx5LiBUaGUgbW9ub3Rv
bmljYWxseSBpbmNyZWFzaW5nIHNlcXVlbmNlIG51bWJlciBvZiB0aGUgY2hhbmdlbG9nLgoK
DAoFBAACCwUSA1ACBwoMCgUEAAILARIDUAgXCgwKBQQAAgsDEgNQGhwKDAoFBAACCwgSA1Ad
SAoPCggEAAILCJwIABIDUB5HYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::Changelog::Changelog ===
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

Google::Cloud::Ces::V1beta::Changelog - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/changelog.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::Changelog;

    my $msg = Google::Cloud::Ces::V1beta::Changelog::Changelog->new({
        name => $name,
        author => $author,
        display_name => $display_name,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::Changelog::Changelog->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/changelog.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::Changelog::Changelog

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::Changelog::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
