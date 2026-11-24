package Google::Cloud::Dialogflow::Cx::V3::CodeBlock;

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
Ci5nb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92My9jb2RlX2Jsb2NrLnByb3RvEh1nb29n
bGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52MxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90byIkCglDb2RlQmxvY2sSFwoEY29kZRgBIAEoCUID4EEBUgRjb2RlQrEBCiFjb20uZ29v
Z2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNCDkNvZGVCbG9ja1Byb3RvUAFaMWNsb3VkLmdv
b2dsZS5jb20vZ28vZGlhbG9nZmxvdy9jeC9hcGl2My9jeHBiO2N4cGKiAgJERqoCHUdvb2ds
ZS5DbG91ZC5EaWFsb2dmbG93LkN4LlYz6gIhR29vZ2xlOjpDbG91ZDo6RGlhbG9nZmxvdzo6
Q1g6OlYzSqoHCgYSBA4AIAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQACYKCQoCAwASAxIAKQoICgEIEgMUADoKCQoCCCUSAxQAOgoICgEIEgMVAEgKCQoC
CAsSAxUASAoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXAC8KCQoCCAgSAxcALwoICgEI
EgMYADoKCQoCCAESAxgAOgoICgEIEgMZACAKCQoCCCQSAxkAIAoICgEIEgMaADoKCQoCCC0S
AxoAOgomCgIEABIEHQAgARoaIFJlcHJlc2VudHMgYSBjb2RlIGJsb2NrLgoKCgoDBAABEgMd
CBEKPAoEBAACABIDHwI7Gi8gT3B0aW9uYWwuIFNvdXJjZSBjb2RlIG9mIHRoZSBibG9jayBp
biBQeXRob24uCgoMCgUEAAIABRIDHwIICgwKBQQAAgABEgMfCQ0KDAoFBAACAAMSAx8QEQoM
CgUEAAIACBIDHxI6Cg8KCAQAAgAInAgAEgMfEzliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3::CodeBlock::CodeBlock ===
    # Fields for CodeBlock
    # Field: code Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::CodeBlock - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3/code_block.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3::CodeBlock;

    my $msg = Google::Cloud::Dialogflow::Cx::V3::CodeBlock::CodeBlock->new({
        code => $code,
    });

    # Read or update a field
    my $val = $msg->code();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3::CodeBlock::CodeBlock->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3/code_block.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3::CodeBlock::CodeBlock

Represents a code block.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->code() >> / C<< $msg->code($value) >>

Type: C<String>

Optional. Source code of the block in Python.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3::CodeBlock::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
