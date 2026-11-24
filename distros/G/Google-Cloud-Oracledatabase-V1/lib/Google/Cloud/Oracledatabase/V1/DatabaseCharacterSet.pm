package Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet;

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
    my $descriptor_b64 = <<'EOF';
Cjtnb29nbGUvY2xvdWQvb3JhY2xlZGF0YWJhc2UvdjEvZGF0YWJhc2VfY2hhcmFjdGVyX3Nl
dC5wcm90bxIeZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxGh9nb29nbGUvYXBpL2Zp
ZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvIucDChREYXRh
YmFzZUNoYXJhY3RlclNldBIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSeAoSY2hhcmFjdGVy
X3NldF90eXBlGAIgASgOMkUuZ29vZ2xlLmNsb3VkLm9yYWNsZWRhdGFiYXNlLnYxLkRhdGFi
YXNlQ2hhcmFjdGVyU2V0LkNoYXJhY3RlclNldFR5cGVCA+BBA1IQY2hhcmFjdGVyU2V0VHlw
ZRIoCg1jaGFyYWN0ZXJfc2V0GAMgASgJQgPgQQNSDGNoYXJhY3RlclNldCJSChBDaGFyYWN0
ZXJTZXRUeXBlEiIKHkNIQVJBQ1RFUl9TRVRfVFlQRV9VTlNQRUNJRklFRBAAEgwKCERBVEFC
QVNFEAESDAoITkFUSU9OQUwQAjq9AepBuQEKMm9yYWNsZWRhdGFiYXNlLmdvb2dsZWFwaXMu
Y29tL0RhdGFiYXNlQ2hhcmFjdGVyU2V0ElZwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25z
L3tsb2NhdGlvbn0vZGF0YWJhc2VDaGFyYWN0ZXJTZXRzL3tkYXRhYmFzZV9jaGFyYWN0ZXJf
c2V0fSoVZGF0YWJhc2VDaGFyYWN0ZXJTZXRzMhRkYXRhYmFzZUNoYXJhY3RlclNldCLZAQog
TGlzdERhdGFiYXNlQ2hhcmFjdGVyU2V0c1JlcXVlc3QSUgoGcGFyZW50GAEgASgJQjrgQQL6
QTQSMm9yYWNsZWRhdGFiYXNlLmdvb2dsZWFwaXMuY29tL0RhdGFiYXNlQ2hhcmFjdGVyU2V0
UgZwYXJlbnQSIAoJcGFnZV9zaXplGAIgASgFQgPgQQFSCHBhZ2VTaXplEiIKCnBhZ2VfdG9r
ZW4YAyABKAlCA+BBAVIJcGFnZVRva2VuEhsKBmZpbHRlchgEIAEoCUID4EEBUgZmaWx0ZXIi
uQEKIUxpc3REYXRhYmFzZUNoYXJhY3RlclNldHNSZXNwb25zZRJsChdkYXRhYmFzZV9jaGFy
YWN0ZXJfc2V0cxgBIAMoCzI0Lmdvb2dsZS5jbG91ZC5vcmFjbGVkYXRhYmFzZS52MS5EYXRh
YmFzZUNoYXJhY3RlclNldFIVZGF0YWJhc2VDaGFyYWN0ZXJTZXRzEiYKD25leHRfcGFnZV90
b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbkLzAQoiY29tLmdvb2dsZS5jbG91ZC5vcmFjbGVk
YXRhYmFzZS52MUIZRGF0YWJhc2VDaGFyYWN0ZXJTZXRQcm90b1ABWkpjbG91ZC5nb29nbGUu
Y29tL2dvL29yYWNsZWRhdGFiYXNlL2FwaXYxL29yYWNsZWRhdGFiYXNlcGI7b3JhY2xlZGF0
YWJhc2VwYqoCHkdvb2dsZS5DbG91ZC5PcmFjbGVEYXRhYmFzZS5WMcoCHkdvb2dsZVxDbG91
ZFxPcmFjbGVEYXRhYmFzZVxWMeoCIUdvb2dsZTo6Q2xvdWQ6Ok9yYWNsZURhdGFiYXNlOjpW
MUrhGgoGEgQOAGgBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAnCgkKAgMAEgMSACkKCQoCAwESAxMAIwoICgEIEgMVADsKCQoCCCUSAxUAOwoICgEIEgMW
AGEKCQoCCAsSAxYAYQoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYADoKCQoCCAgSAxgA
OgoICgEIEgMZADsKCQoCCAESAxkAOwoICgEIEgMaADsKCQoCCCkSAxoAOwoICgEIEgMbADoK
CQoCCC0SAxsAOgo9CgIEABIEHgA+ARoxIERldGFpbHMgb2YgdGhlIERhdGFiYXNlIGNoYXJh
Y3RlciBzZXQgcmVzb3VyY2UuCgoKCgMEAAESAx4IHAoLCgMEAAcSBB8CJAQKDQoFBAAHnQgS
BB8CJAQKPgoEBAAEABIEJwIwAxowIFRoZSB0eXBlIG9mIGNoYXJhY3RlciBzZXQgYSBEYXRh
YmFzZSBjYW4gaGF2ZS4KCgwKBQQABAABEgMnBxcKNQoGBAAEAAIAEgMpBCcaJiBDaGFyYWN0
ZXIgc2V0IHR5cGUgaXMgbm90IHNwZWNpZmllZC4KCg4KBwQABAACAAESAykEIgoOCgcEAAQA
AgACEgMpJSYKNwoGBAAEAAIBEgMsBBEaKCBDaGFyYWN0ZXIgc2V0IHR5cGUgaXMgc2V0IHRv
IGRhdGFiYXNlLgoKDgoHBAAEAAIBARIDLAQMCg4KBwQABAACAQISAywPEAo3CgYEAAQAAgIS
Ay8EERooIENoYXJhY3RlciBzZXQgdHlwZSBpcyBzZXQgdG8gbmF0aW9uYWwuCgoOCgcEAAQA
AgIBEgMvBAwKDgoHBAAEAAICAhIDLw8QCrsBCgQEAAIAEgM1Aj0arQEgSWRlbnRpZmllci4g
VGhlIG5hbWUgb2YgdGhlIERhdGFiYXNlIENoYXJhY3RlciBTZXQgcmVzb3VyY2UgaW4gdGhl
CiBmb2xsb3dpbmcgZm9ybWF0OgogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97cmVn
aW9ufS9kYXRhYmFzZUNoYXJhY3RlclNldHMve2RhdGFiYXNlX2NoYXJhY3Rlcl9zZXR9CgoM
CgUEAAIABRIDNQIICgwKBQQAAgABEgM1CQ0KDAoFBAACAAMSAzUQEQoMCgUEAAIACBIDNRI8
Cg8KCAQAAgAInAgAEgM1EzsKRQoEBAACARIEOAI5Mho3IE91dHB1dCBvbmx5LiBUaGUgY2hh
cmFjdGVyIHNldCB0eXBlIGZvciB0aGUgRGF0YWJhc2UuCgoMCgUEAAIBBhIDOAISCgwKBQQA
AgEBEgM4EyUKDAoFBAACAQMSAzgoKQoMCgUEAAIBCBIDOQYxCg8KCAQAAgEInAgAEgM5BzAK
agoEBAACAhIDPQJHGl0gT3V0cHV0IG9ubHkuIFRoZSBjaGFyYWN0ZXIgc2V0IG5hbWUgZm9y
IHRoZSBEYXRhYmFzZSB3aGljaCBpcyB0aGUgSUQgaW4gdGhlCiByZXNvdXJjZSBuYW1lLgoK
DAoFBAACAgUSAz0CCAoMCgUEAAICARIDPQkWCgwKBQQAAgIDEgM9GRoKDAoFBAACAggSAz0b
RgoPCggEAAICCJwIABIDPRxFCjoKAgQBEgRBAF8BGi4gVGhlIHJlcXVlc3QgZm9yIGBEYXRh
YmFzZUNoYXJhY3RlclNldC5MaXN0YC4KCgoKAwQBARIDQQgoCocBCgQEAQIAEgREAkkEGnkg
UmVxdWlyZWQuIFRoZSBwYXJlbnQgdmFsdWUgZm9yIERhdGFiYXNlQ2hhcmFjdGVyU2V0cyBp
biB0aGUgZm9sbG93aW5nCiBmb3JtYXQ6IHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS4KCgwKBQQBAgAFEgNEAggKDAoFBAECAAESA0QJDwoMCgUEAQIAAxIDRBIT
Cg0KBQQBAgAIEgREFEkDCg8KCAQBAgAInAgAEgNFBCoKDwoHBAECAAifCBIERgRIBQqKAgoE
BAECARIDTwI/GvwBIE9wdGlvbmFsLiBUaGUgbWF4aW11bSBudW1iZXIgb2YgRGF0YWJhc2VD
aGFyYWN0ZXJTZXRzIHRvIHJldHVybi4gVGhlCiBzZXJ2aWNlIG1heSByZXR1cm4gZmV3ZXIg
dGhhbiB0aGlzIHZhbHVlLiBJZiB1bnNwZWNpZmllZCwgYXQgbW9zdCA1MAogRGF0YWJhc2VD
aGFyYWN0ZXJTZXRzIHdpbGwgYmUgcmV0dXJuZWQuIFRoZSBtYXhpbXVtIHZhbHVlIGlzIDEw
MDA7IHZhbHVlcwogYWJvdmUgMTAwMCB3aWxsIGJlIGNvZXJjZWQgdG8gMTAwMC4KCgwKBQQB
AgEFEgNPAgcKDAoFBAECAQESA08IEQoMCgUEAQIBAxIDTxQVCgwKBQQBAgEIEgNPFj4KDwoI
BAECAQicCAASA08XPQqWAgoEBAECAhIDWAJBGogCIE9wdGlvbmFsLiBBIHBhZ2UgdG9rZW4s
IHJlY2VpdmVkIGZyb20gYSBwcmV2aW91cwogYExpc3REYXRhYmFzZUNoYXJhY3RlclNldHNg
IGNhbGwuIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudAogcGFnZS4K
CiBXaGVuIHBhZ2luYXRpbmcsIGFsbCBvdGhlciBwYXJhbWV0ZXJzIHByb3ZpZGVkIHRvCiBg
TGlzdERhdGFiYXNlQ2hhcmFjdGVyU2V0c2AgbXVzdCBtYXRjaCB0aGUgY2FsbCB0aGF0IHBy
b3ZpZGVkIHRoZSBwYWdlCiB0b2tlbi4KCgwKBQQBAgIFEgNYAggKDAoFBAECAgESA1gJEwoM
CgUEAQICAxIDWBYXCgwKBQQBAgIIEgNYGEAKDwoIBAECAgicCAASA1gZPwr+AQoEBAECAxID
XgI9GvABIE9wdGlvbmFsLiBBbiBleHByZXNzaW9uIGZvciBmaWx0ZXJpbmcgdGhlIHJlc3Vs
dHMgb2YgdGhlIHJlcXVlc3QuIE9ubHkgdGhlCiAqKmNoYXJhY3Rlcl9zZXRfdHlwZSoqIGZp
ZWxkIGlzIHN1cHBvcnRlZCBpbiB0aGUgZm9sbG93aW5nIGZvcm1hdDoKIGBjaGFyYWN0ZXJf
c2V0X3R5cGU9IntjaGFyYWN0ZXJTZXRUeXBlfSJgLiBBY2NlcHRlZCB2YWx1ZXMgaW5jbHVk
ZQogYERBVEFCQVNFYCBhbmQgYE5BVElPTkFMYC4KCgwKBQQBAgMFEgNeAggKDAoFBAECAwES
A14JDwoMCgUEAQIDAxIDXhITCgwKBQQBAgMIEgNeFDwKDwoIBAECAwicCAASA14VOwo7CgIE
AhIEYgBoARovIFRoZSByZXNwb25zZSBmb3IgYERhdGFiYXNlQ2hhcmFjdGVyU2V0Lkxpc3Rg
LgoKCgoDBAIBEgNiCCkKMQoEBAICABIDZAI8GiQgVGhlIGxpc3Qgb2YgRGF0YWJhc2VDaGFy
YWN0ZXJTZXRzLgoKDAoFBAICAAQSA2QCCgoMCgUEAgIABhIDZAsfCgwKBQQCAgABEgNkIDcK
DAoFBAICAAMSA2Q6OwpOCgQEAgIBEgNnAh0aQSBBIHRva2VuIGlkZW50aWZ5aW5nIGEgcGFn
ZSBvZiByZXN1bHRzIHRoZSBzZXJ2ZXIgc2hvdWxkIHJldHVybi4KCgwKBQQCAgEFEgNnAggK
DAoFBAICAQESA2cJGAoMCgUEAgIBAxIDZxscYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet::DatabaseCharacterSet ===
    # Fields for DatabaseCharacterSet
    # Field: name Type: 9 ()
    # Field: character_set_type Type: 14 (.google.cloud.oracledatabase.v1.DatabaseCharacterSet.CharacterSetType)
    # Field: character_set Type: 9 ()

# Enum: DatabaseCharacterSet::CharacterSetType
our $DatabaseCharacterSet_CHARACTER_SET_TYPE_UNSPECIFIED = 0;
our $DatabaseCharacterSet_DATABASE = 1;
our $DatabaseCharacterSet_NATIONAL = 2;

# === Message: Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet::ListDatabaseCharacterSetsRequest ===
    # Fields for ListDatabaseCharacterSetsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()
    # Field: filter Type: 9 ()

# === Message: Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet::ListDatabaseCharacterSetsResponse ===
    # Fields for ListDatabaseCharacterSetsResponse
    # Field: database_character_sets Type: 11 (.google.cloud.oracledatabase.v1.DatabaseCharacterSet)
    # Field: next_page_token Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet - Compiled Protocol Buffers messages for google/cloud/oracledatabase/v1/database_character_set.proto

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet;

    my $msg = Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet::DatabaseCharacterSet->new({
        name => $name,
        character_set_type => $character_set_type,
        character_set => $character_set,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet::DatabaseCharacterSet->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/oracledatabase/v1/database_character_set.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet::DatabaseCharacterSet

Details of the Database character set resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the Database Character Set resource in the
following format:
projects/{project}/locations/{region}/databaseCharacterSets/{database_character_set}

=item * C<< $msg->character_set_type() >> / C<< $msg->character_set_type($value) >>

Type: C<Enum> (L<Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet::CharacterSetType>)

Output only. The character set type for the Database.

=item * C<< $msg->character_set() >> / C<< $msg->character_set($value) >>

Type: C<String>

Output only. The character set name for the Database which is the ID in the
resource name.

=back

=head3 Enum: DatabaseCharacterSet::CharacterSetType

=over 4

=item * C<CHARACTER_SET_TYPE_UNSPECIFIED> => C<0>

=item * C<DATABASE> => C<1>

=item * C<NATIONAL> => C<2>

=back

=head2 Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet::ListDatabaseCharacterSetsRequest

The request for `DatabaseCharacterSet.List`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent value for DatabaseCharacterSets in the following
format: projects/{project}/locations/{location}.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

Optional. The maximum number of DatabaseCharacterSets to return. The
service may return fewer than this value. If unspecified, at most 50
DatabaseCharacterSets will be returned. The maximum value is 1000; values
above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

Optional. A page token, received from a previous
`ListDatabaseCharacterSets` call. Provide this to retrieve the subsequent
page.

When paginating, all other parameters provided to
`ListDatabaseCharacterSets` must match the call that provided the page
token.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

Optional. An expression for filtering the results of the request. Only the
B<character_set_type> field is supported in the following format:
`character_set_type="{characterSetType}"`. Accepted values include
`DATABASE` and `NATIONAL`.

=back

=head2 Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet::ListDatabaseCharacterSetsResponse

The response for `DatabaseCharacterSet.List`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->database_character_sets() >> / C<< $msg->database_character_sets($value) >>

Type: C<Message> (L<Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet::DatabaseCharacterSet>)

The list of DatabaseCharacterSets.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token identifying a page of results the server should return.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
