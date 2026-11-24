package Google::Actions::Sdk::V2::Files;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::ConfigFile };
    eval { require Google::Actions::Sdk::V2::DataFile };
    my $descriptor_b64 = <<'EOF';
CiFnb29nbGUvYWN0aW9ucy9zZGsvdjIvZmlsZXMucHJvdG8SFWdvb2dsZS5hY3Rpb25zLnNk
ay52MhonZ29vZ2xlL2FjdGlvbnMvc2RrL3YyL2NvbmZpZ19maWxlLnByb3RvGiVnb29nbGUv
YWN0aW9ucy9zZGsvdjIvZGF0YV9maWxlLnByb3RvIqABCgVGaWxlcxJHCgxjb25maWdfZmls
ZXMYASABKAsyIi5nb29nbGUuYWN0aW9ucy5zZGsudjIuQ29uZmlnRmlsZXNIAFILY29uZmln
RmlsZXMSQQoKZGF0YV9maWxlcxgCIAEoCzIgLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5EYXRh
RmlsZXNIAFIJZGF0YUZpbGVzQgsKCWZpbGVfdHlwZUJjChljb20uZ29vZ2xlLmFjdGlvbnMu
c2RrLnYyQgpGaWxlc1Byb3RvUAFaOGdvb2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dvb2ds
ZWFwaXMvYWN0aW9ucy9zZGsvdjI7c2RrSpcJCgYSBA4AJwEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB4KCQoCAwASAxIAMQoJCgIDARIDEwAvCggKAQgS
AxUATwoJCgIICxIDFQBPCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcAKwoJCgIICBID
FwArCggKAQgSAxgAMgoJCgIIARIDGAAyCioKAgQAEgQbACcBGh4gV3JhcHBlciBmb3IgYSBs
aXN0IG9mIGZpbGVzLgoKCgoDBAABEgMbCA0KaAoEBAAIABIEHgImAxpaIE9ubHkgb25lIHR5
cGUgb2YgZmlsZXMgY2FuIGJlIHNlbnQgdG8gdGhlIHNlcnZlciBhdCBhIHRpbWUsIGNvbmZp
ZyBmaWxlcyBvcgogZGF0YSBmaWxlcy4KCgwKBQQACAABEgMeCBEKdAoEBAACABIDIQQhGmcg
TGlzdCBvZiBjb25maWcgZmlsZXMuIFRoaXMgaW5jbHVkZXMgbWFuaWZlc3QsIHNldHRpbmdz
LCBpbnRlcmFjdGlvbiBtb2RlbAogcmVzb3VyY2UgYnVuZGxlcyBhbmQgbW9yZS4KCgwKBQQA
AgAGEgMhBA8KDAoFBAACAAESAyEQHAoMCgUEAAIAAxIDIR8gCmAKBAQAAgESAyUEHRpTIExp
c3Qgb2YgZGF0YSBmaWxlcy4gVGhpcyBpbmNsdWRlcyBpbWFnZSwgYXVkaW8gZmlsZSwgY2xv
dWQgZnVuY3Rpb24KIHNvdXJjZSBjb2RlLgoKDAoFBAACAQYSAyUEDQoMCgUEAAIBARIDJQ4Y
CgwKBQQAAgEDEgMlGxxiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Files::Files ===
    # Fields for Files
    # Field: config_files Type: 11 (.google.actions.sdk.v2.ConfigFiles)
    # Field: data_files Type: 11 (.google.actions.sdk.v2.DataFiles)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Files - Compiled Protocol Buffers messages for google/actions/sdk/v2/files.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Files;

    my $msg = Google::Actions::Sdk::V2::Files::Files->new({
        config_files => $config_files,
        data_files => $data_files,
    });

    # Read or update a field
    my $val = $msg->config_files();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Files::Files->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/files.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Files::Files

Wrapper for a list of files.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->config_files() >> / C<< $msg->config_files($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::ConfigFile::ConfigFiles>)

List of config files. This includes manifest, settings, interaction model
resource bundles and more.

=item * C<< $msg->data_files() >> / C<< $msg->data_files($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::DataFile::DataFiles>)

List of data files. This includes image, audio file, cloud function
source code.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Files::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
