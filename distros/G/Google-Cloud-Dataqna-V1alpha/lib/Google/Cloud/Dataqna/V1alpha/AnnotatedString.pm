package Google::Cloud::Dataqna::V1alpha::AnnotatedString;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvZGF0YXFuYS92MWFscGhhL2Fubm90YXRlZF9zdHJpbmcucHJvdG8S
HGdvb2dsZS5jbG91ZC5kYXRhcW5hLnYxYWxwaGEi3gMKD0Fubm90YXRlZFN0cmluZxIlCg50
ZXh0X2Zvcm1hdHRlZBgBIAEoCVINdGV4dEZvcm1hdHRlZBIlCg5odG1sX2Zvcm1hdHRlZBgC
IAEoCVINaHRtbEZvcm1hdHRlZBJWCgdtYXJrdXBzGAMgAygLMjwuZ29vZ2xlLmNsb3VkLmRh
dGFxbmEudjFhbHBoYS5Bbm5vdGF0ZWRTdHJpbmcuU2VtYW50aWNNYXJrdXBSB21hcmt1cHMa
qAEKDlNlbWFudGljTWFya3VwElQKBHR5cGUYASABKA4yQC5nb29nbGUuY2xvdWQuZGF0YXFu
YS52MWFscGhhLkFubm90YXRlZFN0cmluZy5TZW1hbnRpY01hcmt1cFR5cGVSBHR5cGUSKAoQ
c3RhcnRfY2hhcl9pbmRleBgCIAEoBVIOc3RhcnRDaGFySW5kZXgSFgoGbGVuZ3RoGAMgASgF
UgZsZW5ndGgiegoSU2VtYW50aWNNYXJrdXBUeXBlEhsKF01BUktVUF9UWVBFX1VOU1BFQ0lG
SUVEEAASCgoGTUVUUklDEAESDQoJRElNRU5TSU9OEAISCgoGRklMVEVSEAMSCgoGVU5VU0VE
EAQSCwoHQkxPQ0tFRBAFEgcKA1JPVxAGQtYBCiBjb20uZ29vZ2xlLmNsb3VkLmRhdGFxbmEu
djFhbHBoYUIUQW5ub3RhdGVkU3RyaW5nUHJvdG9QAVo6Y2xvdWQuZ29vZ2xlLmNvbS9nby9k
YXRhcW5hL2FwaXYxYWxwaGEvZGF0YXFuYXBiO2RhdGFxbmFwYqoCHEdvb2dsZS5DbG91ZC5E
YXRhUW5BLlYxQWxwaGHKAhxHb29nbGVcQ2xvdWRcRGF0YVFuQVxWMWFscGhh6gIfR29vZ2xl
OjpDbG91ZDo6RGF0YVFuQTo6VjFhbHBoYUrjFgoGEgQOAGYBCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAlCggKAQgSAxIAOQoJCgIIJRIDEgA5CggKAQgS
AxMAUQoJCgIICxIDEwBRCggKAQgSAxQAIgoJCgIIChIDFAAiCggKAQgSAxUANQoJCgIICBID
FQA1CggKAQgSAxYAOQoJCgIIARIDFgA5CggKAQgSAxcAOQoJCgIIKRIDFwA5CggKAQgSAxgA
OAoJCgIILRIDGAA4Cr8FCgIEABIEOABmARqyBSBEZXNjcmliZXMgc3RyaW5nIGFubm90YXRp
b24gZnJvbSBib3RoIHNlbWFudGljIGFuZCBmb3JtYXR0aW5nIHBlcnNwZWN0aXZlcy4KIEV4
YW1wbGU6CgogVXNlciBRdWVyeToKCiAgIHRvcCBjb3VudHJpZXMgYnkgcG9wdWxhdGlvbiBp
biBBZnJpY2EKCiAgIDAgICA0ICAgICAgICAgMTQgMTcgICAgICAgICAyOCAzMSAgICAzNwoK
IFRhYmxlIERhdGE6CgogKyAiY291bnRyeSIgLSBkaW1lbnNpb24KICsgInBvcHVsYXRpb24i
IC0gbWV0cmljCiArICJBZnJpY2EiIC0gdmFsdWUgaW4gdGhlICJjb250aW5lbnQiIGNvbHVt
bgoKIHRleHRfZm9ybWF0dGVkID0gYCJ0b3AgY291bnRyaWVzIGJ5IHBvcHVsYXRpb24gaW4g
QWZyaWNhImAKCiBodG1sX2Zvcm1hdHRlZCA9CiAgIGAidG9wIDxiPmNvdW50cmllczwvYj4g
YnkgPGI+cG9wdWxhdGlvbjwvYj4gaW4gPGk+QWZyaWNhPC9pPiJgCgogYGBgCiBtYXJrdXBz
ID0gWwogICB7RElNRU5TSU9OLCA0LCAxMn0sIC8vICdjb3VudHJpZXMnCiAgIHtNRVRSSUMs
IDE3LCAyNn0sIC8vICdwb3B1bGF0aW9uJwogICB7RklMVEVSLCAzMSwgMzZ9ICAvLyAnQWZy
aWNhJwogXQogYGBgCgogTm90ZSB0aGF0IGh0bWwgZm9ybWF0dGluZ3MgZm9yICdESU1FTlNJ
T04nIGFuZCAnTUVUUklDJyBhcmUgdGhlIHNhbWUsIHdoaWxlCiBzZW1hbnRpYyBtYXJrdXBz
IGFyZSBkaWZmZXJlbnQuCgoKCgMEAAESAzgIFwpjCgQEAAMAEgQ7AkQDGlUgU2VtYW50aWMg
bWFya3VwIGRlbm90ZXMgYSBzdWJzdHJpbmcgKGJ5IGluZGV4IGFuZCBsZW5ndGgpIHdpdGgg
bWFya3VwCiBpbmZvcm1hdGlvbi4KCgwKBQQAAwABEgM7ChgKOwoGBAADAAIAEgM9BCAaLCBU
aGUgc2VtYW50aWMgdHlwZSBvZiB0aGUgbWFya3VwIHN1YnN0cmluZy4KCg4KBwQAAwACAAYS
Az0EFgoOCgcEAAMAAgABEgM9FxsKDgoHBAADAAIAAxIDPR4fCjYKBgQAAwACARIDQAQfGicg
VW5pY29kZSBjaGFyYWN0ZXIgaW5kZXggb2YgdGhlIHF1ZXJ5LgoKDgoHBAADAAIBBRIDQAQJ
Cg4KBwQAAwACAQESA0AKGgoOCgcEAAMAAgEDEgNAHR4KUwoGBAADAAICEgNDBBUaRCBUaGUg
bGVuZ3RoIChudW1iZXIgb2YgdW5pY29kZSBjaGFyYWN0ZXJzKSBvZiB0aGUgbWFya3VwIHN1
YnN0cmluZy4KCg4KBwQAAwACAgUSA0MECQoOCgcEAAMAAgIBEgNDChAKDgoHBAADAAICAxID
QxMUCiYKBAQABAASBEcCXAMaGCBTZW1hbnRpYyBtYXJrdXAgdHlwZXMuCgoMCgUEAAQAARID
RwcZCi4KBgQABAACABIDSQQgGh8gTm8gbWFya3VwIHR5cGUgd2FzIHNwZWNpZmllZC4KCg4K
BwQABAACAAESA0kEGwoOCgcEAAQAAgACEgNJHh8KOgoGBAAEAAIBEgNMBA8aKyBNYXJrdXAg
Zm9yIGEgc3Vic3RyaW5nIGRlbm90aW5nIGEgbWV0cmljLgoKDgoHBAAEAAIBARIDTAQKCg4K
BwQABAACAQISA0wNDgo9CgYEAAQAAgISA08EEhouIE1hcmt1cCBmb3IgYSBzdWJzdHJpbmcg
ZGVub3RpbmcgYSBkaW1lbnNpb24uCgoOCgcEAAQAAgIBEgNPBA0KDgoHBAAEAAICAhIDTxAR
CjoKBgQABAACAxIDUgQPGisgTWFya3VwIGZvciBhIHN1YnN0cmluZyBkZW5vdGluZyBhIGZp
bHRlci4KCg4KBwQABAACAwESA1IECgoOCgcEAAQAAgMCEgNSDQ4KMAoGBAAEAAIEEgNVBA8a
ISBNYXJrdXAgZm9yIGFuIHVudXNlZCBzdWJzdHJpbmcuCgoOCgcEAAQAAgQBEgNVBAoKDgoH
BAAEAAIEAhIDVQ0OCkMKBgQABAACBRIDWAQQGjQgTWFya3VwIGZvciBhIHN1YnN0cmluZyBj
b250YWluaW5nIGJsb2NrZWQgcGhyYXNlcy4KCg4KBwQABAACBQESA1gECwoOCgcEAAQAAgUC
EgNYDg8KRAoGBAAEAAIGEgNbBAwaNSBNYXJrdXAgZm9yIGEgc3Vic3RyaW5nIHRoYXQgY29u
dGFpbnMgdGVybXMgZm9yIHJvdy4KCg4KBwQABAACBgESA1sEBwoOCgcEAAQAAgYCEgNbCgsK
KgoEBAACABIDXwIcGh0gVGV4dCB2ZXJzaW9uIG9mIHRoZSBzdHJpbmcuCgoMCgUEAAIABRID
XwIICgwKBQQAAgABEgNfCRcKDAoFBAACAAMSA18aGwo1CgQEAAIBEgNiAhwaKCBIVE1MIHZl
cnNpb24gb2YgdGhlIHN0cmluZyBhbm5vdGF0aW9uLgoKDAoFBAACAQUSA2ICCAoMCgUEAAIB
ARIDYgkXCgwKBQQAAgEDEgNiGhsKOQoEBAACAhIDZQImGiwgU2VtYW50aWMgdmVyc2lvbiBv
ZiB0aGUgc3RyaW5nIGFubm90YXRpb24uCgoMCgUEAAICBBIDZQIKCgwKBQQAAgIGEgNlCxkK
DAoFBAACAgESA2UaIQoMCgUEAAICAxIDZSQlYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dataqna::V1alpha::AnnotatedString::AnnotatedString ===
    # Fields for AnnotatedString
    # Field: text_formatted Type: 9 ()
    # Field: html_formatted Type: 9 ()
    # Field: markups Type: 11 (.google.cloud.dataqna.v1alpha.AnnotatedString.SemanticMarkup)

# Enum: AnnotatedString::SemanticMarkupType
our $AnnotatedString_MARKUP_TYPE_UNSPECIFIED = 0;
our $AnnotatedString_METRIC = 1;
our $AnnotatedString_DIMENSION = 2;
our $AnnotatedString_FILTER = 3;
our $AnnotatedString_UNUSED = 4;
our $AnnotatedString_BLOCKED = 5;
our $AnnotatedString_ROW = 6;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dataqna::V1alpha::AnnotatedString - Compiled Protocol Buffers messages for google/cloud/dataqna/v1alpha/annotated_string.proto

=head1 SYNOPSIS

    use Google::Cloud::Dataqna::V1alpha::AnnotatedString;

    my $msg = Google::Cloud::Dataqna::V1alpha::AnnotatedString::AnnotatedString->new({
        text_formatted => $text_formatted,
        html_formatted => $html_formatted,
        markups => $markups,
    });

    # Read or update a field
    my $val = $msg->text_formatted();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dataqna::V1alpha::AnnotatedString::AnnotatedString->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dataqna/v1alpha/annotated_string.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dataqna::V1alpha::AnnotatedString::AnnotatedString

Describes string annotation from both semantic and formatting perspectives.
Example:

User Query:

  top countries by population in Africa

  0   4         14 17         28 31    37

Table Data:

+ "country" - dimension
+ "population" - metric
+ "Africa" - value in the "continent" column

text_formatted = `"top countries by population in Africa"`

html_formatted =
  `"top <b>countries</b> by <b>population</b> in <i>Africa</i>"`

```
markups = [
  {DIMENSION, 4, 12}, // 'countries'
  {METRIC, 17, 26}, // 'population'
  {FILTER, 31, 36}  // 'Africa'
]
```

Note that html formattings for 'DIMENSION' and 'METRIC' are the same, while
semantic markups are different.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text_formatted() >> / C<< $msg->text_formatted($value) >>

Type: C<String>

Text version of the string.

=item * C<< $msg->html_formatted() >> / C<< $msg->html_formatted($value) >>

Type: C<String>

HTML version of the string annotation.

=item * C<< $msg->markups() >> / C<< $msg->markups($value) >>

Type: C<Message> (L<Google::Cloud::Dataqna::V1alpha::AnnotatedString::AnnotatedString::SemanticMarkup>)

Semantic version of the string annotation.

=back

=head3 Enum: AnnotatedString::SemanticMarkupType

=over 4

=item * C<MARKUP_TYPE_UNSPECIFIED> => C<0>

=item * C<METRIC> => C<1>

=item * C<DIMENSION> => C<2>

=item * C<FILTER> => C<3>

=item * C<UNUSED> => C<4>

=item * C<BLOCKED> => C<5>

=item * C<ROW> => C<6>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dataqna::V1alpha::AnnotatedString::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
