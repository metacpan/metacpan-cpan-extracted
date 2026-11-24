package Google::Cloud::Integrations::V1alpha::IntegrationState;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cjlnb29nbGUvY2xvdWQvaW50ZWdyYXRpb25zL3YxYWxwaGEvaW50ZWdyYXRpb25fc3RhdGUu
cHJvdG8SIWdvb2dsZS5jbG91ZC5pbnRlZ3JhdGlvbnMudjFhbHBoYSpoChBJbnRlZ3JhdGlv
blN0YXRlEiEKHUlOVEVHUkFUSU9OX1NUQVRFX1VOU1BFQ0lGSUVEEAASCQoFRFJBRlQQARIK
CgZBQ1RJVkUQAhIMCghBUkNISVZFRBADEgwKCFNOQVBTSE9UEARCrwEKJWNvbS5nb29nbGUu
Y2xvdWQuaW50ZWdyYXRpb25zLnYxYWxwaGFCFUludGVncmF0aW9uU3RhdGVQcm90b1ABWklj
bG91ZC5nb29nbGUuY29tL2dvL2ludGVncmF0aW9ucy9hcGl2MWFscGhhL2ludGVncmF0aW9u
c3BiO2ludGVncmF0aW9uc3BiqgIhR29vZ2xlLkNsb3VkLkludGVncmF0aW9ucy5WMUFscGhh
SoYICgYSBA4AKAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQ
ACoKCAoBCBIDEgA+CgkKAgglEgMSAD4KCAoBCBIDEwBgCgkKAggLEgMTAGAKCAoBCBIDFAAi
CgkKAggKEgMUACIKCAoBCBIDFQA2CgkKAggIEgMVADYKCAoBCBIDFgA+CgkKAggBEgMWAD4K
NgoCBQASBBkAKAEaKiBJbmRpY2F0ZXMgdGhlIHN0YXR1cyBvZiB0aGUgaW50ZWdyYXRpb24u
CgoKCgMFAAESAxkFFQoXCgQFAAIAEgMbAiQaCiBEZWZhdWx0LgoKDAoFBQACAAESAxsCHwoM
CgUFAAIAAhIDGyIjChUKBAUAAgESAx4CDBoIIERyYWZ0LgoKDAoFBQACAQESAx4CBwoMCgUF
AAIBAhIDHgoLChYKBAUAAgISAyECDRoJIEFjdGl2ZS4KCgwKBQUAAgIBEgMhAggKDAoFBQAC
AgISAyELDAoYCgQFAAIDEgMkAg8aCyBBcmNoaXZlZC4KCgwKBQUAAgMBEgMkAgoKDAoFBQAC
AwISAyQNDgoYCgQFAAIEEgMnAg8aCyBTbmFwc2hvdC4KCgwKBQUAAgQBEgMnAgoKDAoFBQAC
BAISAycNDmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Integrations::V1alpha::IntegrationState - Compiled Protocol Buffers messages for google/cloud/integrations/v1alpha/integration_state.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/integrations/v1alpha/integration_state.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Integrations::V1alpha::IntegrationState::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
