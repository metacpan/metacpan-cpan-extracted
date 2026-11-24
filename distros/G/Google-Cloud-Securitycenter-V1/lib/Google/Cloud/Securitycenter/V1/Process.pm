package Google::Cloud::Securitycenter::V1::Process;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Securitycenter::V1::File };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvcHJvY2Vzcy5wcm90bxIeZ29vZ2xl
LmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxGilnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIv
djEvZmlsZS5wcm90byLlAwoHUHJvY2VzcxISCgRuYW1lGAwgASgJUgRuYW1lEjwKBmJpbmFy
eRgDIAEoCzIkLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MS5GaWxlUgZiaW5hcnkS
QgoJbGlicmFyaWVzGAQgAygLMiQuZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxLkZp
bGVSCWxpYnJhcmllcxI8CgZzY3JpcHQYBSABKAsyJC5nb29nbGUuY2xvdWQuc2VjdXJpdHlj
ZW50ZXIudjEuRmlsZVIGc2NyaXB0EhIKBGFyZ3MYBiADKAlSBGFyZ3MSLwoTYXJndW1lbnRz
X3RydW5jYXRlZBgHIAEoCFISYXJndW1lbnRzVHJ1bmNhdGVkElgKDWVudl92YXJpYWJsZXMY
CCADKAsyMy5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjEuRW52aXJvbm1lbnRWYXJp
YWJsZVIMZW52VmFyaWFibGVzEjYKF2Vudl92YXJpYWJsZXNfdHJ1bmNhdGVkGAkgASgIUhVl
bnZWYXJpYWJsZXNUcnVuY2F0ZWQSEAoDcGlkGAogASgDUgNwaWQSHQoKcGFyZW50X3BpZBgL
IAEoA1IJcGFyZW50UGlkIjsKE0Vudmlyb25tZW50VmFyaWFibGUSEgoEbmFtZRgBIAEoCVIE
bmFtZRIQCgN2YWwYAiABKAlSA3ZhbELmAQoiY29tLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNl
bnRlci52MUIMUHJvY2Vzc1Byb3RvUAFaSmNsb3VkLmdvb2dsZS5jb20vZ28vc2VjdXJpdHlj
ZW50ZXIvYXBpdjEvc2VjdXJpdHljZW50ZXJwYjtzZWN1cml0eWNlbnRlcnBiqgIeR29vZ2xl
LkNsb3VkLlNlY3VyaXR5Q2VudGVyLlYxygIeR29vZ2xlXENsb3VkXFNlY3VyaXR5Q2VudGVy
XFYx6gIhR29vZ2xlOjpDbG91ZDo6U2VjdXJpdHlDZW50ZXI6OlYxSvcSCgYSBA4ASQEKvAQK
AQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIg
dGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3Ug
bWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExp
Y2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAg
aHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJl
cXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0
d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24g
YW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9G
IEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNl
IGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAog
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIAMwoI
CgEIEgMUADsKCQoCCCUSAxQAOwoICgEIEgMVAGEKCQoCCAsSAxUAYQoICgEIEgMWACIKCQoC
CAoSAxYAIgoICgEIEgMXAC0KCQoCCAgSAxcALQoICgEIEgMYADsKCQoCCAESAxgAOwoICgEI
EgMZADsKCQoCCCkSAxkAOwoICgEIEgMaADoKCQoCCC0SAxoAOgo1CgIEABIEHQA/ARopIFJl
cHJlc2VudHMgYW4gb3BlcmF0aW5nIHN5c3RlbSBwcm9jZXNzLgoKCgoDBAABEgMdCA8KrgEK
BAQAAgASAyECExqgASBUaGUgcHJvY2VzcyBuYW1lLCBhcyBkaXNwbGF5ZWQgaW4gdXRpbGl0
aWVzIGxpa2UgYHRvcGAgYW5kIGBwc2AuIFRoaXMgbmFtZQogY2FuIGJlIGFjY2Vzc2VkIHRo
cm91Z2ggYC9wcm9jL1twaWRdL2NvbW1gIGFuZCBjaGFuZ2VkIHdpdGgKIGBwcmN0bChQUl9T
RVRfTkFNRSlgLgoKDAoFBAACAAUSAyECCAoMCgUEAAIAARIDIQkNCgwKBQQAAgADEgMhEBIK
OwoEBAACARIDJAISGi4gRmlsZSBpbmZvcm1hdGlvbiBmb3IgdGhlIHByb2Nlc3MgZXhlY3V0
YWJsZS4KCgwKBQQAAgEGEgMkAgYKDAoFBAACAQESAyQHDQoMCgUEAAIBAxIDJBARCkQKBAQA
AgISAycCHho3IEZpbGUgaW5mb3JtYXRpb24gZm9yIGxpYnJhcmllcyBsb2FkZWQgYnkgdGhl
IHByb2Nlc3MuCgoMCgUEAAICBBIDJwIKCgwKBQQAAgIGEgMnCw8KDAoFBAACAgESAycQGQoM
CgUEAAICAxIDJxwdCtUBCgQEAAIDEgMsAhIaxwEgV2hlbiB0aGUgcHJvY2VzcyByZXByZXNl
bnRzIHRoZSBpbnZvY2F0aW9uIG9mIGEgc2NyaXB0LCBgYmluYXJ5YCBwcm92aWRlcwogaW5m
b3JtYXRpb24gYWJvdXQgdGhlIGludGVycHJldGVyLCB3aGlsZSBgc2NyaXB0YCBwcm92aWRl
cyBpbmZvcm1hdGlvbgogYWJvdXQgdGhlIHNjcmlwdCBmaWxlIHByb3ZpZGVkIHRvIHRoZSBp
bnRlcnByZXRlci4KCgwKBQQAAgMGEgMsAgYKDAoFBAACAwESAywHDQoMCgUEAAIDAxIDLBAR
CjkKBAQAAgQSAy8CGxosIFByb2Nlc3MgYXJndW1lbnRzIGFzIEpTT04gZW5jb2RlZCBzdHJp
bmdzLgoKDAoFBAACBAQSAy8CCgoMCgUEAAIEBRIDLwsRCgwKBQQAAgQBEgMvEhYKDAoFBAAC
BAMSAy8ZGgosCgQEAAIFEgMyAh8aHyBUcnVlIGlmIGBhcmdzYCBpcyBpbmNvbXBsZXRlLgoK
DAoFBAACBQUSAzICBgoMCgUEAAIFARIDMgcaCgwKBQQAAgUDEgMyHR4KLQoEBAACBhIDNQIx
GiAgUHJvY2VzcyBlbnZpcm9ubWVudCB2YXJpYWJsZXMuCgoMCgUEAAIGBBIDNQIKCgwKBQQA
AgYGEgM1Cx4KDAoFBAACBgESAzUfLAoMCgUEAAIGAxIDNS8wCjUKBAQAAgcSAzgCIxooIFRy
dWUgaWYgYGVudl92YXJpYWJsZXNgIGlzIGluY29tcGxldGUuCgoMCgUEAAIHBRIDOAIGCgwK
BQQAAgcBEgM4Bx4KDAoFBAACBwMSAzghIgoeCgQEAAIIEgM7AhEaESBUaGUgcHJvY2VzcyBJ
RC4KCgwKBQQAAggFEgM7AgcKDAoFBAACCAESAzsICwoMCgUEAAIIAxIDOw4QCiUKBAQAAgkS
Az4CGBoYIFRoZSBwYXJlbnQgcHJvY2VzcyBJRC4KCgwKBQQAAgkFEgM+AgcKDAoFBAACCQES
Az4IEgoMCgUEAAIJAxIDPhUXCmoKAgQBEgRDAEkBGl4gQSBuYW1lLXZhbHVlIHBhaXIgcmVw
cmVzZW50aW5nIGFuIGVudmlyb25tZW50IHZhcmlhYmxlIHVzZWQgaW4gYW4gb3BlcmF0aW5n
CiBzeXN0ZW0gcHJvY2Vzcy4KCgoKAwQBARIDQwgbCkIKBAQBAgASA0UCEho1IEVudmlyb25t
ZW50IHZhcmlhYmxlIG5hbWUgYXMgYSBKU09OIGVuY29kZWQgc3RyaW5nLgoKDAoFBAECAAUS
A0UCCAoMCgUEAQIAARIDRQkNCgwKBQQBAgADEgNFEBEKQwoEBAECARIDSAIRGjYgRW52aXJv
bm1lbnQgdmFyaWFibGUgdmFsdWUgYXMgYSBKU09OIGVuY29kZWQgc3RyaW5nLgoKDAoFBAEC
AQUSA0gCCAoMCgUEAQIBARIDSAkMCgwKBQQBAgEDEgNIDxBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::Process::Process ===
    # Fields for Process
    # Field: name Type: 9 ()
    # Field: binary Type: 11 (.google.cloud.securitycenter.v1.File)
    # Field: libraries Type: 11 (.google.cloud.securitycenter.v1.File)
    # Field: script Type: 11 (.google.cloud.securitycenter.v1.File)
    # Field: args Type: 9 ()
    # Field: arguments_truncated Type: 8 ()
    # Field: env_variables Type: 11 (.google.cloud.securitycenter.v1.EnvironmentVariable)
    # Field: env_variables_truncated Type: 8 ()
    # Field: pid Type: 3 ()
    # Field: parent_pid Type: 3 ()

# === Message: Google::Cloud::Securitycenter::V1::Process::EnvironmentVariable ===
    # Fields for EnvironmentVariable
    # Field: name Type: 9 ()
    # Field: val Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::Process - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/process.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::Process;

    my $msg = Google::Cloud::Securitycenter::V1::Process::Process->new({
        name => $name,
        binary => $binary,
        libraries => $libraries,
        script => $script,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::Process::Process->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/process.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::Process::Process

Represents an operating system process.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The process name, as displayed in utilities like `top` and `ps`. This name
can be accessed through `/proc/[pid]/comm` and changed with
`prctl(PR_SET_NAME)`.

=item * C<< $msg->binary() >> / C<< $msg->binary($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::File::File>)

File information for the process executable.

=item * C<< $msg->libraries() >> / C<< $msg->libraries($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::File::File>)

File information for libraries loaded by the process.

=item * C<< $msg->script() >> / C<< $msg->script($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::File::File>)

When the process represents the invocation of a script, `binary` provides
information about the interpreter, while `script` provides information
about the script file provided to the interpreter.

=item * C<< $msg->args() >> / C<< $msg->args($value) >>

Type: C<String>

Process arguments as JSON encoded strings.

=item * C<< $msg->arguments_truncated() >> / C<< $msg->arguments_truncated($value) >>

Type: C<Bool>

True if `args` is incomplete.

=item * C<< $msg->env_variables() >> / C<< $msg->env_variables($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::Process::EnvironmentVariable>)

Process environment variables.

=item * C<< $msg->env_variables_truncated() >> / C<< $msg->env_variables_truncated($value) >>

Type: C<Bool>

True if `env_variables` is incomplete.

=item * C<< $msg->pid() >> / C<< $msg->pid($value) >>

Type: C<Int64>

The process ID.

=item * C<< $msg->parent_pid() >> / C<< $msg->parent_pid($value) >>

Type: C<Int64>

The parent process ID.

=back

=head2 Google::Cloud::Securitycenter::V1::Process::EnvironmentVariable

A name-value pair representing an environment variable used in an operating
system process.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Environment variable name as a JSON encoded string.

=item * C<< $msg->val() >> / C<< $msg->val($value) >>

Type: C<String>

Environment variable value as a JSON encoded string.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::Process::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
