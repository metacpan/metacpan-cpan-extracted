package Google::Cloud::Bigquery::Migration::V2::TranslationSuggestion;

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
Cj9nb29nbGUvY2xvdWQvYmlncXVlcnkvbWlncmF0aW9uL3YyL3RyYW5zbGF0aW9uX3N1Z2dl
c3Rpb24ucHJvdG8SImdvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24udjIaH2dvb2ds
ZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8i
vwIKF1RyYW5zbGF0aW9uUmVwb3J0UmVjb3JkEmAKCHNldmVyaXR5GAEgASgOMkQuZ29vZ2xl
LmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52Mi5UcmFuc2xhdGlvblJlcG9ydFJlY29yZC5T
ZXZlcml0eVIIc2V2ZXJpdHkSHwoLc2NyaXB0X2xpbmUYAiABKAVSCnNjcmlwdExpbmUSIwoN
c2NyaXB0X2NvbHVtbhgDIAEoBVIMc2NyaXB0Q29sdW1uEhoKCGNhdGVnb3J5GAQgASgJUghj
YXRlZ29yeRIYCgdtZXNzYWdlGAUgASgJUgdtZXNzYWdlIkYKCFNldmVyaXR5EhgKFFNFVkVS
SVRZX1VOU1BFQ0lGSUVEEAASCAoESU5GTxABEgsKB1dBUk5JTkcQAhIJCgVFUlJPUhADQtYB
CiZjb20uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52MkIaVHJhbnNsYXRpb25T
dWdnZXN0aW9uUHJvdG9QAVpEY2xvdWQuZ29vZ2xlLmNvbS9nby9iaWdxdWVyeS9taWdyYXRp
b24vYXBpdjIvbWlncmF0aW9ucGI7bWlncmF0aW9ucGKqAiJHb29nbGUuQ2xvdWQuQmlnUXVl
cnkuTWlncmF0aW9uLlYyygIiR29vZ2xlXENsb3VkXEJpZ1F1ZXJ5XE1pZ3JhdGlvblxWMkqk
DgoGEgQOAD4BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAr
CgkKAgMAEgMSACkKCQoCAwESAxMAIwoICgEIEgMVAD8KCQoCCCUSAxUAPwoICgEIEgMWAFsK
CQoCCAsSAxYAWwoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYADsKCQoCCAgSAxgAOwoI
CgEIEgMZAD8KCQoCCAESAxkAPwoICgEIEgMaAEAKCQoCCCkSAxoAQAolCgIEABIEHQA+ARoZ
IERldGFpbHMgYWJvdXQgYSByZWNvcmQuCgoKCgMEAAESAx0IHwowCgQEAAQAEgQfAiwDGiIg
VGhlIHNldmVyaXR5IHR5cGUgb2YgdGhlIHJlY29yZC4KCgwKBQQABAABEgMfBw8KLAoGBAAE
AAIAEgMhBB0aHSBTZXZlcml0eVR5cGUgbm90IHNwZWNpZmllZC4KCg4KBwQABAACAAESAyEE
GAoOCgcEAAQAAgACEgMhGxwKGwoGBAAEAAIBEgMkBA0aDCBJTkZPIHR5cGUuCgoOCgcEAAQA
AgEBEgMkBAgKDgoHBAAEAAIBAhIDJAsMCoABCgYEAAQAAgISAygEEBpxIFdBUk5JTkcgdHlw
ZS4gVGhlIHRyYW5zbGF0ZWQgcXVlcnkgbWF5IHN0aWxsIHByb3ZpZGUgdXNlZnVsIGluZm9y
bWF0aW9uCiBpZiBhbGwgdGhlIHJlcG9ydCByZWNvcmRzIGFyZSBXQVJOSU5HLgoKDgoHBAAE
AAICARIDKAQLCg4KBwQABAACAgISAygODwowCgYEAAQAAgMSAysEDhohIEVSUk9SIHR5cGUu
IFRyYW5zbGF0aW9uIGZhaWxlZC4KCg4KBwQABAACAwESAysECQoOCgcEAAQAAgMCEgMrDA0K
MgoEBAACABIDLwIYGiUgU2V2ZXJpdHkgb2YgdGhlIHRyYW5zbGF0aW9uIHJlY29yZC4KCgwK
BQQAAgAGEgMvAgoKDAoFBAACAAESAy8LEwoMCgUEAAIAAxIDLxYXCmUKBAQAAgESAzMCGBpY
IFNwZWNpZmllcyB0aGUgcm93IGZyb20gdGhlIHNvdXJjZSB0ZXh0IHdoZXJlIHRoZSBlcnJv
ciBvY2N1cnJlZCAoMCBiYXNlZCkuCiBFeGFtcGxlOiAyCgoMCgUEAAIBBRIDMwIHCgwKBQQA
AgEBEgMzCBMKDAoFBAACAQMSAzMWFwppCgQEAAICEgM3AhoaXCBTcGVjaWZpZXMgdGhlIGNv
bHVtbiBmcm9tIHRoZSBzb3VyY2UgdGV4dHMgd2hlcmUgdGhlIGVycm9yIG9jY3VycmVkLiAo
MAogYmFzZWQpIGV4YW1wbGU6IDYKCgwKBQQAAgIFEgM3AgcKDAoFBAACAgESAzcIFQoMCgUE
AAICAxIDNxgZCkIKBAQAAgMSAzoCFho1IENhdGVnb3J5IG9mIHRoZSBlcnJvci93YXJuaW5n
LiBFeGFtcGxlOiBTeW50YXhFcnJvcgoKDAoFBAACAwUSAzoCCAoMCgUEAAIDARIDOgkRCgwK
BQQAAgMDEgM6FBUKLgoEBAACBBIDPQIVGiEgRGV0YWlsZWQgbWVzc2FnZSBvZiB0aGUgcmVj
b3JkLgoKDAoFBAACBAUSAz0CCAoMCgUEAAIEARIDPQkQCgwKBQQAAgQDEgM9ExRiBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Migration::V2::TranslationSuggestion::TranslationReportRecord ===
    # Fields for TranslationReportRecord
    # Field: severity Type: 14 (.google.cloud.bigquery.migration.v2.TranslationReportRecord.Severity)
    # Field: script_line Type: 5 ()
    # Field: script_column Type: 5 ()
    # Field: category Type: 9 ()
    # Field: message Type: 9 ()

# Enum: TranslationReportRecord::Severity
our $TranslationReportRecord_SEVERITY_UNSPECIFIED = 0;
our $TranslationReportRecord_INFO = 1;
our $TranslationReportRecord_WARNING = 2;
our $TranslationReportRecord_ERROR = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Migration::V2::TranslationSuggestion - Compiled Protocol Buffers messages for google/cloud/bigquery/migration/v2/translation_suggestion.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Migration::V2::TranslationSuggestion;

    my $msg = Google::Cloud::Bigquery::Migration::V2::TranslationSuggestion::TranslationReportRecord->new({
        severity => $severity,
        script_line => $script_line,
        script_column => $script_column,
        category => $category,
    });

    # Read or update a field
    my $val = $msg->severity();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Migration::V2::TranslationSuggestion::TranslationReportRecord->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/migration/v2/translation_suggestion.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Migration::V2::TranslationSuggestion::TranslationReportRecord

Details about a record.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->severity() >> / C<< $msg->severity($value) >>

Type: C<Enum> (L<Google::Cloud::Bigquery::Migration::V2::TranslationReportRecord::Severity>)

Severity of the translation record.

=item * C<< $msg->script_line() >> / C<< $msg->script_line($value) >>

Type: C<Int32>

Specifies the row from the source text where the error occurred (0 based).
Example: 2

=item * C<< $msg->script_column() >> / C<< $msg->script_column($value) >>

Type: C<Int32>

Specifies the column from the source texts where the error occurred. (0
based) example: 6

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<String>

Category of the error/warning. Example: SyntaxError

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Detailed message of the record.

=back

=head3 Enum: TranslationReportRecord::Severity

=over 4

=item * C<SEVERITY_UNSPECIFIED> => C<0>

=item * C<INFO> => C<1>

=item * C<WARNING> => C<2>

=item * C<ERROR> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Migration::V2::TranslationSuggestion::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
