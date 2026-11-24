package Google::Cloud::Retail::V2beta::Safety;

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
Cidnb29nbGUvY2xvdWQvcmV0YWlsL3YyYmV0YS9zYWZldHkucHJvdG8SGmdvb2dsZS5jbG91
ZC5yZXRhaWwudjJiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvIv4DCg1T
YWZldHlTZXR0aW5nEkQKCGNhdGVnb3J5GAEgASgOMiguZ29vZ2xlLmNsb3VkLnJldGFpbC52
MmJldGEuSGFybUNhdGVnb3J5UghjYXRlZ29yeRJaCgl0aHJlc2hvbGQYAiABKA4yPC5nb29n
bGUuY2xvdWQucmV0YWlsLnYyYmV0YS5TYWZldHlTZXR0aW5nLkhhcm1CbG9ja1RocmVzaG9s
ZFIJdGhyZXNob2xkElYKBm1ldGhvZBgDIAEoDjI5Lmdvb2dsZS5jbG91ZC5yZXRhaWwudjJi
ZXRhLlNhZmV0eVNldHRpbmcuSGFybUJsb2NrTWV0aG9kQgPgQQFSBm1ldGhvZCKdAQoSSGFy
bUJsb2NrVGhyZXNob2xkEiQKIEhBUk1fQkxPQ0tfVEhSRVNIT0xEX1VOU1BFQ0lGSUVEEAAS
FwoTQkxPQ0tfTE9XX0FORF9BQk9WRRABEhoKFkJMT0NLX01FRElVTV9BTkRfQUJPVkUQAhIT
Cg9CTE9DS19PTkxZX0hJR0gQAxIOCgpCTE9DS19OT05FEAQSBwoDT0ZGEAUiUwoPSGFybUJs
b2NrTWV0aG9kEiEKHUhBUk1fQkxPQ0tfTUVUSE9EX1VOU1BFQ0lGSUVEEAASDAoIU0VWRVJJ
VFkQARIPCgtQUk9CQUJJTElUWRACKtcBCgxIYXJtQ2F0ZWdvcnkSHQoZSEFSTV9DQVRFR09S
WV9VTlNQRUNJRklFRBAAEh0KGUhBUk1fQ0FURUdPUllfSEFURV9TUEVFQ0gQARIjCh9IQVJN
X0NBVEVHT1JZX0RBTkdFUk9VU19DT05URU5UEAISHAoYSEFSTV9DQVRFR09SWV9IQVJBU1NN
RU5UEAMSIwofSEFSTV9DQVRFR09SWV9TRVhVQUxMWV9FWFBMSUNJVBAEEiEKHUhBUk1fQ0FU
RUdPUllfQ0lWSUNfSU5URUdSSVRZEAVCygEKHmNvbS5nb29nbGUuY2xvdWQucmV0YWlsLnYy
YmV0YUILU2FmZXR5UHJvdG9QAVo2Y2xvdWQuZ29vZ2xlLmNvbS9nby9yZXRhaWwvYXBpdjJi
ZXRhL3JldGFpbHBiO3JldGFpbHBiogIGUkVUQUlMqgIaR29vZ2xlLkNsb3VkLlJldGFpbC5W
MkJldGHKAhpHb29nbGVcQ2xvdWRcUmV0YWlsXFYyYmV0YeoCHUdvb2dsZTo6Q2xvdWQ6OlJl
dGFpbDo6VjJiZXRhSpcVCgYSBA4AXgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBH
b29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9u
IDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2Vw
dCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNv
cHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vu
c2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9y
IGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhl
IExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQg
V0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBv
ciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2Ug
Z292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vu
c2UuCgoICgECEgMQACMKCQoCAwASAxIAKQoICgEIEgMUADcKCQoCCCUSAxQANwoICgEIEgMV
AE0KCQoCCAsSAxUATQoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXACwKCQoCCAgSAxcA
LAoICgEIEgMYADcKCQoCCAESAxgANwoICgEIEgMZACQKCQoCCCQSAxkAJAoICgEIEgMaADcK
CQoCCCkSAxoANwoICgEIEgMbADYKCQoCCC0SAxsANgo6CgIFABIEHgAwARouIEhhcm0gY2F0
ZWdvcmllcyB0aGF0IHdpbGwgYmxvY2sgdGhlIGNvbnRlbnQuCgoKCgMFAAESAx4FEQowCgQF
AAIAEgMgAiAaIyBUaGUgaGFybSBjYXRlZ29yeSBpcyB1bnNwZWNpZmllZC4KCgwKBQUAAgAB
EgMgAhsKDAoFBQACAAISAyAeHwowCgQFAAIBEgMjAiAaIyBUaGUgaGFybSBjYXRlZ29yeSBp
cyBoYXRlIHNwZWVjaC4KCgwKBQUAAgEBEgMjAhsKDAoFBQACAQISAyMeHwo2CgQFAAICEgMm
AiYaKSBUaGUgaGFybSBjYXRlZ29yeSBpcyBkYW5nZXJvdXMgY29udGVudC4KCgwKBQUAAgIB
EgMmAiEKDAoFBQACAgISAyYkJQovCgQFAAIDEgMpAh8aIiBUaGUgaGFybSBjYXRlZ29yeSBp
cyBoYXJhc3NtZW50LgoKDAoFBQACAwESAykCGgoMCgUFAAIDAhIDKR0eCj4KBAUAAgQSAywC
JhoxIFRoZSBoYXJtIGNhdGVnb3J5IGlzIHNleHVhbGx5IGV4cGxpY2l0IGNvbnRlbnQuCgoM
CgUFAAIEARIDLAIhCgwKBQUAAgQCEgMsJCUKNAoEBQACBRIDLwIkGicgVGhlIGhhcm0gY2F0
ZWdvcnkgaXMgY2l2aWMgaW50ZWdyaXR5LgoKDAoFBQACBQESAy8CHwoMCgUFAAIFAhIDLyIj
Ch4KAgQAEgQzAF4BGhIgU2FmZXR5IHNldHRpbmdzLgoKCgoDBAABEgMzCBUKQQoEBAAEABIE
NQJHAxozIFByb2JhYmlsaXR5IGJhc2VkIHRocmVzaG9sZHMgbGV2ZWxzIGZvciBibG9ja2lu
Zy4KCgwKBQQABAABEgM1BxkKMgoGBAAEAAIAEgM3BCkaIyBVbnNwZWNpZmllZCBoYXJtIGJs
b2NrIHRocmVzaG9sZC4KCg4KBwQABAACAAESAzcEJAoOCgcEAAQAAgACEgM3JygKQQoGBAAE
AAIBEgM6BBwaMiBCbG9jayBsb3cgdGhyZXNob2xkIGFuZCBhYm92ZSAoaS5lLiBibG9jayBt
b3JlKS4KCg4KBwQABAACAQESAzoEFwoOCgcEAAQAAgECEgM6GhsKMgoGBAAEAAICEgM9BB8a
IyBCbG9jayBtZWRpdW0gdGhyZXNob2xkIGFuZCBhYm92ZS4KCg4KBwQABAACAgESAz0EGgoO
CgcEAAQAAgICEgM9HR4KPQoGBAAEAAIDEgNABBgaLiBCbG9jayBvbmx5IGhpZ2ggdGhyZXNo
b2xkIChpLmUuIGJsb2NrIGxlc3MpLgoKDgoHBAAEAAIDARIDQAQTCg4KBwQABAACAwISA0AW
FwocCgYEAAQAAgQSA0MEExoNIEJsb2NrIG5vbmUuCgoOCgcEAAQAAgQBEgNDBA4KDgoHBAAE
AAIEAhIDQxESCiwKBgQABAACBRIDRgQMGh0gVHVybiBvZmYgdGhlIHNhZmV0eSBmaWx0ZXIu
CgoOCgcEAAQAAgUBEgNGBAcKDgoHBAAEAAIFAhIDRgoLCigKBAQABAESBEoCUwMaGiBQcm9i
YWJpbGl0eSB2cyBzZXZlcml0eS4KCgwKBQQABAEBEgNKBxYKNgoGBAAEAQIAEgNMBCYaJyBU
aGUgaGFybSBibG9jayBtZXRob2QgaXMgdW5zcGVjaWZpZWQuCgoOCgcEAAQBAgABEgNMBCEK
DgoHBAAEAQIAAhIDTCQlClEKBgQABAECARIDTwQRGkIgVGhlIGhhcm0gYmxvY2sgbWV0aG9k
IHVzZXMgYm90aCBwcm9iYWJpbGl0eSBhbmQgc2V2ZXJpdHkgc2NvcmVzLgoKDgoHBAAEAQIB
ARIDTwQMCg4KBwQABAECAQISA08PEApCCgYEAAQBAgISA1IEFBozIFRoZSBoYXJtIGJsb2Nr
IG1ldGhvZCB1c2VzIHRoZSBwcm9iYWJpbGl0eSBzY29yZS4KCg4KBwQABAECAgESA1IEDwoO
CgcEAAQBAgICEgNSEhMKHQoEBAACABIDVgIcGhAgSGFybSBjYXRlZ29yeS4KCgwKBQQAAgAG
EgNWAg4KDAoFBAACAAESA1YPFwoMCgUEAAIAAxIDVhobCigKBAQAAgESA1kCIxobIFRoZSBo
YXJtIGJsb2NrIHRocmVzaG9sZC4KCgwKBQQAAgEGEgNZAhQKDAoFBAACAQESA1kVHgoMCgUE
AAIBAxIDWSEiCp0BCgQEAAICEgNdAkYajwEgT3B0aW9uYWwuIFNwZWNpZnkgaWYgdGhlIHRo
cmVzaG9sZCBpcyB1c2VkIGZvciBwcm9iYWJpbGl0eSBvciBzZXZlcml0eQogc2NvcmUuIElm
IG5vdCBzcGVjaWZpZWQsIHRoZSB0aHJlc2hvbGQgaXMgdXNlZCBmb3IgcHJvYmFiaWxpdHkg
c2NvcmUuCgoMCgUEAAICBhIDXQIRCgwKBQQAAgIBEgNdEhgKDAoFBAACAgMSA10bHAoMCgUE
AAICCBIDXR1FCg8KCAQAAgIInAgAEgNdHkRiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2beta::Safety::SafetySetting ===
    # Fields for SafetySetting
    # Field: category Type: 14 (.google.cloud.retail.v2beta.HarmCategory)
    # Field: threshold Type: 14 (.google.cloud.retail.v2beta.SafetySetting.HarmBlockThreshold)
    # Field: method Type: 14 (.google.cloud.retail.v2beta.SafetySetting.HarmBlockMethod)

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

Google::Cloud::Retail::V2beta::Safety - Compiled Protocol Buffers messages for google/cloud/retail/v2beta/safety.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2beta::Safety;

    my $msg = Google::Cloud::Retail::V2beta::Safety::SafetySetting->new({
        category => $category,
        threshold => $threshold,
        method => $method,
    });

    # Read or update a field
    my $val = $msg->category();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2beta::Safety::SafetySetting->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2beta/safety.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2beta::Safety::SafetySetting

Safety settings.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->category() >> / C<< $msg->category($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2beta::HarmCategory>)

Harm category.

=item * C<< $msg->threshold() >> / C<< $msg->threshold($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2beta::SafetySetting::HarmBlockThreshold>)

The harm block threshold.

=item * C<< $msg->method() >> / C<< $msg->method($value) >>

Type: C<Enum> (L<Google::Cloud::Retail::V2beta::SafetySetting::HarmBlockMethod>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2beta::Safety::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
