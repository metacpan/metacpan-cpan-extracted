package Google::Cloud::Retail::V2alpha::Safety;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvc2FmZXR5LnByb3RvEhtnb29nbGUuY2xv
dWQucmV0YWlsLnYyYWxwaGEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8igQQK
DVNhZmV0eVNldHRpbmcSRQoIY2F0ZWdvcnkYASABKA4yKS5nb29nbGUuY2xvdWQucmV0YWls
LnYyYWxwaGEuSGFybUNhdGVnb3J5UghjYXRlZ29yeRJbCgl0aHJlc2hvbGQYAiABKA4yPS5n
b29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGEuU2FmZXR5U2V0dGluZy5IYXJtQmxvY2tUaHJl
c2hvbGRSCXRocmVzaG9sZBJXCgZtZXRob2QYAyABKA4yOi5nb29nbGUuY2xvdWQucmV0YWls
LnYyYWxwaGEuU2FmZXR5U2V0dGluZy5IYXJtQmxvY2tNZXRob2RCA+BBAVIGbWV0aG9kIp0B
ChJIYXJtQmxvY2tUaHJlc2hvbGQSJAogSEFSTV9CTE9DS19USFJFU0hPTERfVU5TUEVDSUZJ
RUQQABIXChNCTE9DS19MT1dfQU5EX0FCT1ZFEAESGgoWQkxPQ0tfTUVESVVNX0FORF9BQk9W
RRACEhMKD0JMT0NLX09OTFlfSElHSBADEg4KCkJMT0NLX05PTkUQBBIHCgNPRkYQBSJTCg9I
YXJtQmxvY2tNZXRob2QSIQodSEFSTV9CTE9DS19NRVRIT0RfVU5TUEVDSUZJRUQQABIMCghT
RVZFUklUWRABEg8KC1BST0JBQklMSVRZEAIq1wEKDEhhcm1DYXRlZ29yeRIdChlIQVJNX0NB
VEVHT1JZX1VOU1BFQ0lGSUVEEAASHQoZSEFSTV9DQVRFR09SWV9IQVRFX1NQRUVDSBABEiMK
H0hBUk1fQ0FURUdPUllfREFOR0VST1VTX0NPTlRFTlQQAhIcChhIQVJNX0NBVEVHT1JZX0hB
UkFTU01FTlQQAxIjCh9IQVJNX0NBVEVHT1JZX1NFWFVBTExZX0VYUExJQ0lUEAQSIQodSEFS
TV9DQVRFR09SWV9DSVZJQ19JTlRFR1JJVFkQBULPAQofY29tLmdvb2dsZS5jbG91ZC5yZXRh
aWwudjJhbHBoYUILU2FmZXR5UHJvdG9QAVo3Y2xvdWQuZ29vZ2xlLmNvbS9nby9yZXRhaWwv
YXBpdjJhbHBoYS9yZXRhaWxwYjtyZXRhaWxwYqICBlJFVEFJTKoCG0dvb2dsZS5DbG91ZC5S
ZXRhaWwuVjJBbHBoYcoCG0dvb2dsZVxDbG91ZFxSZXRhaWxcVjJhbHBoYeoCHkdvb2dsZTo6
Q2xvdWQ6OlJldGFpbDo6VjJhbHBoYUqXFQoGEgQOAF4BCrwECgEMEgMOABIysQQgQ29weXJp
Z2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5z
ZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMg
ZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBv
YnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAkCgkKAgMAEgMSACkKCAoBCBIDFAA4CgkKAgglEgMU
ADgKCAoBCBIDFQBOCgkKAggLEgMVAE4KCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAs
CgkKAggIEgMXACwKCAoBCBIDGAA4CgkKAggBEgMYADgKCAoBCBIDGQAkCgkKAggkEgMZACQK
CAoBCBIDGgA4CgkKAggpEgMaADgKCAoBCBIDGwA3CgkKAggtEgMbADcKOgoCBQASBB4AMAEa
LiBIYXJtIGNhdGVnb3JpZXMgdGhhdCB3aWxsIGJsb2NrIHRoZSBjb250ZW50LgoKCgoDBQAB
EgMeBREKMAoEBQACABIDIAIgGiMgVGhlIGhhcm0gY2F0ZWdvcnkgaXMgdW5zcGVjaWZpZWQu
CgoMCgUFAAIAARIDIAIbCgwKBQUAAgACEgMgHh8KMAoEBQACARIDIwIgGiMgVGhlIGhhcm0g
Y2F0ZWdvcnkgaXMgaGF0ZSBzcGVlY2guCgoMCgUFAAIBARIDIwIbCgwKBQUAAgECEgMjHh8K
NgoEBQACAhIDJgImGikgVGhlIGhhcm0gY2F0ZWdvcnkgaXMgZGFuZ2Vyb3VzIGNvbnRlbnQu
CgoMCgUFAAICARIDJgIhCgwKBQUAAgICEgMmJCUKLwoEBQACAxIDKQIfGiIgVGhlIGhhcm0g
Y2F0ZWdvcnkgaXMgaGFyYXNzbWVudC4KCgwKBQUAAgMBEgMpAhoKDAoFBQACAwISAykdHgo+
CgQFAAIEEgMsAiYaMSBUaGUgaGFybSBjYXRlZ29yeSBpcyBzZXh1YWxseSBleHBsaWNpdCBj
b250ZW50LgoKDAoFBQACBAESAywCIQoMCgUFAAIEAhIDLCQlCjQKBAUAAgUSAy8CJBonIFRo
ZSBoYXJtIGNhdGVnb3J5IGlzIGNpdmljIGludGVncml0eS4KCgwKBQUAAgUBEgMvAh8KDAoF
BQACBQISAy8iIwoeCgIEABIEMwBeARoSIFNhZmV0eSBzZXR0aW5ncy4KCgoKAwQAARIDMwgV
CkEKBAQABAASBDUCRwMaMyBQcm9iYWJpbGl0eSBiYXNlZCB0aHJlc2hvbGRzIGxldmVscyBm
b3IgYmxvY2tpbmcuCgoMCgUEAAQAARIDNQcZCjIKBgQABAACABIDNwQpGiMgVW5zcGVjaWZp
ZWQgaGFybSBibG9jayB0aHJlc2hvbGQuCgoOCgcEAAQAAgABEgM3BCQKDgoHBAAEAAIAAhID
NycoCkEKBgQABAACARIDOgQcGjIgQmxvY2sgbG93IHRocmVzaG9sZCBhbmQgYWJvdmUgKGku
ZS4gYmxvY2sgbW9yZSkuCgoOCgcEAAQAAgEBEgM6BBcKDgoHBAAEAAIBAhIDOhobCjIKBgQA
BAACAhIDPQQfGiMgQmxvY2sgbWVkaXVtIHRocmVzaG9sZCBhbmQgYWJvdmUuCgoOCgcEAAQA
AgIBEgM9BBoKDgoHBAAEAAICAhIDPR0eCj0KBgQABAACAxIDQAQYGi4gQmxvY2sgb25seSBo
aWdoIHRocmVzaG9sZCAoaS5lLiBibG9jayBsZXNzKS4KCg4KBwQABAACAwESA0AEEwoOCgcE
AAQAAgMCEgNAFhcKHAoGBAAEAAIEEgNDBBMaDSBCbG9jayBub25lLgoKDgoHBAAEAAIEARID
QwQOCg4KBwQABAACBAISA0MREgosCgYEAAQAAgUSA0YEDBodIFR1cm4gb2ZmIHRoZSBzYWZl
dHkgZmlsdGVyLgoKDgoHBAAEAAIFARIDRgQHCg4KBwQABAACBQISA0YKCwooCgQEAAQBEgRK
AlMDGhogUHJvYmFiaWxpdHkgdnMgc2V2ZXJpdHkuCgoMCgUEAAQBARIDSgcWCjYKBgQABAEC
ABIDTAQmGicgVGhlIGhhcm0gYmxvY2sgbWV0aG9kIGlzIHVuc3BlY2lmaWVkLgoKDgoHBAAE
AQIAARIDTAQhCg4KBwQABAECAAISA0wkJQpRCgYEAAQBAgESA08EERpCIFRoZSBoYXJtIGJs
b2NrIG1ldGhvZCB1c2VzIGJvdGggcHJvYmFiaWxpdHkgYW5kIHNldmVyaXR5IHNjb3Jlcy4K
Cg4KBwQABAECAQESA08EDAoOCgcEAAQBAgECEgNPDxAKQgoGBAAEAQICEgNSBBQaMyBUaGUg
aGFybSBibG9jayBtZXRob2QgdXNlcyB0aGUgcHJvYmFiaWxpdHkgc2NvcmUuCgoOCgcEAAQB
AgIBEgNSBA8KDgoHBAAEAQICAhIDUhITCh0KBAQAAgASA1YCHBoQIEhhcm0gY2F0ZWdvcnku
CgoMCgUEAAIABhIDVgIOCgwKBQQAAgABEgNWDxcKDAoFBAACAAMSA1YaGwooCgQEAAIBEgNZ
AiMaGyBUaGUgaGFybSBibG9jayB0aHJlc2hvbGQuCgoMCgUEAAIBBhIDWQIUCgwKBQQAAgEB
EgNZFR4KDAoFBAACAQMSA1khIgqdAQoEBAACAhIDXQJGGo8BIE9wdGlvbmFsLiBTcGVjaWZ5
IGlmIHRoZSB0aHJlc2hvbGQgaXMgdXNlZCBmb3IgcHJvYmFiaWxpdHkgb3Igc2V2ZXJpdHkK
IHNjb3JlLiBJZiBub3Qgc3BlY2lmaWVkLCB0aGUgdGhyZXNob2xkIGlzIHVzZWQgZm9yIHBy
b2JhYmlsaXR5IHNjb3JlLgoKDAoFBAACAgYSA10CEQoMCgUEAAICARIDXRIYCgwKBQQAAgID
EgNdGxwKDAoFBAACAggSA10dRQoPCggEAAICCJwIABIDXR5EYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2alpha::Safety::SafetySetting ===
    # Fields for SafetySetting
    # Field: category Type: 14 (.google.cloud.retail.v2alpha.HarmCategory)
    # Field: threshold Type: 14 (.google.cloud.retail.v2alpha.SafetySetting.HarmBlockThreshold)
    # Field: method Type: 14 (.google.cloud.retail.v2alpha.SafetySetting.HarmBlockMethod)

# Enum: SafetySetting::HarmBlockThreshold
our $SafetySetting_HARM_BLOCK_THRESHOLD_UNSPECIFIED = 0;
our $SafetySetting_BLOCK_LOW_AND_ABOVE = 1;
our $SafetySetting_BLOCK_MEDIUM_AND_ABOVE = 2;
our $SafetySetting_BLOCK_ONLY_HIGH = 3;
our $SafetySetting_BLOCK_NONE = 4;
our $SafetySetting_OFF = 5;

# Enum: SafetySetting::HarmBlockMethod
our $SafetySetting_HARM_BLOCK_METHOD_UNSPECIFIED = 0;
our $SafetySetting_SEVERITY = 1;
our $SafetySetting_PROBABILITY = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2alpha::Safety - Compiled Protocol Buffers messages for google/cloud/retail/v2alpha/safety.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2alpha::Safety;

    my $msg = Google::Cloud::Retail::V2alpha::Safety::SafetySetting->new({
        category => $category,
        threshold => $threshold,
        method => $method,
    });

    # Read or update a field
    my $val = $msg->category();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2alpha::Safety::SafetySetting->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2alpha/safety.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2alpha::Safety::SafetySetting

Safety settings.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2alpha::HarmCategory>)

Harm category.

=item * C<< $msg->threshold() >> / C<< $msg->threshold($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2alpha::SafetySetting::HarmBlockThreshold>)

The harm block threshold.

=item * C<< $msg->method() >> / C<< $msg->method($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2alpha::SafetySetting::HarmBlockMethod>)

Optional. Specify if the threshold is used for probability or severity
score. If not specified, the threshold is used for probability score.

=back

=head3 Enum: SafetySetting::HarmBlockThreshold

=over 4

=item * C<HARM_BLOCK_THRESHOLD_UNSPECIFIED> => C<0>

=item * C<BLOCK_LOW_AND_ABOVE> => C<1>

=item * C<BLOCK_MEDIUM_AND_ABOVE> => C<2>

=item * C<BLOCK_ONLY_HIGH> => C<3>

=item * C<BLOCK_NONE> => C<4>

=item * C<OFF> => C<5>

=back

=head3 Enum: SafetySetting::HarmBlockMethod

=over 4

=item * C<HARM_BLOCK_METHOD_UNSPECIFIED> => C<0>

=item * C<SEVERITY> => C<1>

=item * C<PROBABILITY> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2alpha::Safety::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
