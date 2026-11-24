package Google::Cloud::Securitycenter::V2::Notebook;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvbm90ZWJvb2sucHJvdG8SHmdvb2ds
ZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MhofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5w
cm90byKnAQoITm90ZWJvb2sSEgoEbmFtZRgBIAEoCVIEbmFtZRIYCgdzZXJ2aWNlGAIgASgJ
UgdzZXJ2aWNlEh8KC2xhc3RfYXV0aG9yGAMgASgJUgpsYXN0QXV0aG9yEkwKFG5vdGVib29r
X3VwZGF0ZV90aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFISbm90ZWJv
b2tVcGRhdGVUaW1lQucBCiJjb20uZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyQg1O
b3RlYm9va1Byb3RvUAFaSmNsb3VkLmdvb2dsZS5jb20vZ28vc2VjdXJpdHljZW50ZXIvYXBp
djIvc2VjdXJpdHljZW50ZXJwYjtzZWN1cml0eWNlbnRlcnBiqgIeR29vZ2xlLkNsb3VkLlNl
Y3VyaXR5Q2VudGVyLlYyygIeR29vZ2xlXENsb3VkXFNlY3VyaXR5Q2VudGVyXFYy6gIhR29v
Z2xlOjpDbG91ZDo6U2VjdXJpdHlDZW50ZXI6OlYySuEKCgYSBA4AKwEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIAKQoICgEIEgMUADsK
CQoCCCUSAxQAOwoICgEIEgMVAGEKCQoCCAsSAxUAYQoICgEIEgMWACIKCQoCCAoSAxYAIgoI
CgEIEgMXAC4KCQoCCAgSAxcALgoICgEIEgMYADsKCQoCCAESAxgAOwoICgEIEgMZADsKCQoC
CCkSAxkAOwoICgEIEgMaADoKCQoCCC0SAxoAOgq7AQoCBAASBB8AKwEargEgUmVwcmVzZW50
cyBhIEp1cHl0ZXIgbm90ZWJvb2sgSVBZTkIgZmlsZSwgc3VjaCBhcyBhIFtDb2xhYiBFbnRl
cnByaXNlCiBub3RlYm9va10oaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL2NvbGFiL2RvY3Mv
aW50cm9kdWN0aW9uKSBmaWxlLCB0aGF0IGlzCiBhc3NvY2lhdGVkIHdpdGggYSBmaW5kaW5n
LgoKCgoDBAABEgMfCBAKKAoEBAACABIDIQISGhsgVGhlIG5hbWUgb2YgdGhlIG5vdGVib29r
LgoKDAoFBAACAAUSAyECCAoMCgUEAAIAARIDIQkNCgwKBQQAAgADEgMhEBEKTAoEBAACARID
JAIVGj8gVGhlIHNvdXJjZSBub3RlYm9vayBzZXJ2aWNlLCBmb3IgZXhhbXBsZSwgIkNvbGFi
IEVudGVycHJpc2UiLgoKDAoFBAACAQUSAyQCCAoMCgUEAAIBARIDJAkQCgwKBQQAAgEDEgMk
ExQKRwoEBAACAhIDJwIZGjogVGhlIHVzZXIgSUQgb2YgdGhlIGxhdGVzdCBhdXRob3IgdG8g
bW9kaWZ5IHRoZSBub3RlYm9vay4KCgwKBQQAAgIFEgMnAggKDAoFBAACAgESAycJFAoMCgUE
AAICAxIDJxcYCj0KBAQAAgMSAyoCNRowIFRoZSBtb3N0IHJlY2VudCB0aW1lIHRoZSBub3Rl
Ym9vayB3YXMgdXBkYXRlZC4KCgwKBQQAAgMGEgMqAhsKDAoFBAACAwESAyocMAoMCgUEAAID
AxIDKjM0YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::Notebook::Notebook ===
    # Fields for Notebook
    # Field: name Type: 9 ()
    # Field: service Type: 9 ()
    # Field: last_author Type: 9 ()
    # Field: notebook_update_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::Notebook - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/notebook.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::Notebook;

    my $msg = Google::Cloud::Securitycenter::V2::Notebook::Notebook->new({
        name => $name,
        service => $service,
        last_author => $last_author,
        notebook_update_time => $notebook_update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::Notebook::Notebook->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/notebook.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::Notebook::Notebook

Represents a Jupyter notebook IPYNB file, such as a [Colab Enterprise
notebook](https://cloud.google.com/colab/docs/introduction) file, that is
associated with a finding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the notebook.

=item * C<< $msg->service() >> / C<< $msg->service($value) >>

Type: C<String>

The source notebook service, for example, "Colab Enterprise".

=item * C<< $msg->last_author() >> / C<< $msg->last_author($value) >>

Type: C<String>

The user ID of the latest author to modify the notebook.

=item * C<< $msg->notebook_update_time() >> / C<< $msg->notebook_update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The most recent time the notebook was updated.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::Notebook::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
