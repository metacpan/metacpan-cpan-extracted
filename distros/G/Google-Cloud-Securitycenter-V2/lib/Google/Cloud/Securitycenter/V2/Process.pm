package Google::Cloud::Securitycenter::V2::Process;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Securitycenter::V2::File };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvcHJvY2Vzcy5wcm90bxIeZ29vZ2xl
LmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyGilnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIv
djIvZmlsZS5wcm90byL+AwoHUHJvY2VzcxISCgRuYW1lGAEgASgJUgRuYW1lEjwKBmJpbmFy
eRgCIAEoCzIkLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52Mi5GaWxlUgZiaW5hcnkS
QgoJbGlicmFyaWVzGAMgAygLMiQuZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyLkZp
bGVSCWxpYnJhcmllcxI8CgZzY3JpcHQYBCABKAsyJC5nb29nbGUuY2xvdWQuc2VjdXJpdHlj
ZW50ZXIudjIuRmlsZVIGc2NyaXB0EhIKBGFyZ3MYBSADKAlSBGFyZ3MSLwoTYXJndW1lbnRz
X3RydW5jYXRlZBgGIAEoCFISYXJndW1lbnRzVHJ1bmNhdGVkElgKDWVudl92YXJpYWJsZXMY
ByADKAsyMy5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjIuRW52aXJvbm1lbnRWYXJp
YWJsZVIMZW52VmFyaWFibGVzEjYKF2Vudl92YXJpYWJsZXNfdHJ1bmNhdGVkGAggASgIUhVl
bnZWYXJpYWJsZXNUcnVuY2F0ZWQSEAoDcGlkGAkgASgDUgNwaWQSHQoKcGFyZW50X3BpZBgK
IAEoA1IJcGFyZW50UGlkEhcKB3VzZXJfaWQYCyABKANSBnVzZXJJZCI7ChNFbnZpcm9ubWVu
dFZhcmlhYmxlEhIKBG5hbWUYASABKAlSBG5hbWUSEAoDdmFsGAIgASgJUgN2YWxC5gEKImNv
bS5nb29nbGUuY2xvdWQuc2VjdXJpdHljZW50ZXIudjJCDFByb2Nlc3NQcm90b1ABWkpjbG91
ZC5nb29nbGUuY29tL2dvL3NlY3VyaXR5Y2VudGVyL2FwaXYyL3NlY3VyaXR5Y2VudGVycGI7
c2VjdXJpdHljZW50ZXJwYqoCHkdvb2dsZS5DbG91ZC5TZWN1cml0eUNlbnRlci5WMsoCHkdv
b2dsZVxDbG91ZFxTZWN1cml0eUNlbnRlclxWMuoCIUdvb2dsZTo6Q2xvdWQ6OlNlY3VyaXR5
Q2VudGVyOjpWMkqVFAoGEgQOAE0BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAAnCgkKAgMAEgMSADMKCAoBCBIDFAA7CgkKAgglEgMUADsKCAoBCBIDFQBh
CgkKAggLEgMVAGEKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAtCgkKAggIEgMXAC0K
CAoBCBIDGAA7CgkKAggBEgMYADsKCAoBCBIDGQA7CgkKAggpEgMZADsKCAoBCBIDGgA6CgkK
AggtEgMaADoKNQoCBAASBB0AQwEaKSBSZXByZXNlbnRzIGFuIG9wZXJhdGluZyBzeXN0ZW0g
cHJvY2Vzcy4KCgoKAwQAARIDHQgPCq4BCgQEAAIAEgMhAhIaoAEgVGhlIHByb2Nlc3MgbmFt
ZSwgYXMgZGlzcGxheWVkIGluIHV0aWxpdGllcyBsaWtlIGB0b3BgIGFuZCBgcHNgLiBUaGlz
IG5hbWUKIGNhbiBiZSBhY2Nlc3NlZCB0aHJvdWdoIGAvcHJvYy9bcGlkXS9jb21tYCBhbmQg
Y2hhbmdlZCB3aXRoCiBgcHJjdGwoUFJfU0VUX05BTUUpYC4KCgwKBQQAAgAFEgMhAggKDAoF
BAACAAESAyEJDQoMCgUEAAIAAxIDIRARCjsKBAQAAgESAyQCEhouIEZpbGUgaW5mb3JtYXRp
b24gZm9yIHRoZSBwcm9jZXNzIGV4ZWN1dGFibGUuCgoMCgUEAAIBBhIDJAIGCgwKBQQAAgEB
EgMkBw0KDAoFBAACAQMSAyQQEQpECgQEAAICEgMnAh4aNyBGaWxlIGluZm9ybWF0aW9uIGZv
ciBsaWJyYXJpZXMgbG9hZGVkIGJ5IHRoZSBwcm9jZXNzLgoKDAoFBAACAgQSAycCCgoMCgUE
AAICBhIDJwsPCgwKBQQAAgIBEgMnEBkKDAoFBAACAgMSAyccHQrVAQoEBAACAxIDLAISGscB
IFdoZW4gdGhlIHByb2Nlc3MgcmVwcmVzZW50cyB0aGUgaW52b2NhdGlvbiBvZiBhIHNjcmlw
dCwgYGJpbmFyeWAgcHJvdmlkZXMKIGluZm9ybWF0aW9uIGFib3V0IHRoZSBpbnRlcnByZXRl
ciwgd2hpbGUgYHNjcmlwdGAgcHJvdmlkZXMgaW5mb3JtYXRpb24KIGFib3V0IHRoZSBzY3Jp
cHQgZmlsZSBwcm92aWRlZCB0byB0aGUgaW50ZXJwcmV0ZXIuCgoMCgUEAAIDBhIDLAIGCgwK
BQQAAgMBEgMsBw0KDAoFBAACAwMSAywQEQo5CgQEAAIEEgMvAhsaLCBQcm9jZXNzIGFyZ3Vt
ZW50cyBhcyBKU09OIGVuY29kZWQgc3RyaW5ncy4KCgwKBQQAAgQEEgMvAgoKDAoFBAACBAUS
Ay8LEQoMCgUEAAIEARIDLxIWCgwKBQQAAgQDEgMvGRoKLAoEBAACBRIDMgIfGh8gVHJ1ZSBp
ZiBgYXJnc2AgaXMgaW5jb21wbGV0ZS4KCgwKBQQAAgUFEgMyAgYKDAoFBAACBQESAzIHGgoM
CgUEAAIFAxIDMh0eCi0KBAQAAgYSAzUCMRogIFByb2Nlc3MgZW52aXJvbm1lbnQgdmFyaWFi
bGVzLgoKDAoFBAACBgQSAzUCCgoMCgUEAAIGBhIDNQseCgwKBQQAAgYBEgM1HywKDAoFBAAC
BgMSAzUvMAo1CgQEAAIHEgM4AiMaKCBUcnVlIGlmIGBlbnZfdmFyaWFibGVzYCBpcyBpbmNv
bXBsZXRlLgoKDAoFBAACBwUSAzgCBgoMCgUEAAIHARIDOAceCgwKBQQAAgcDEgM4ISIKHgoE
BAACCBIDOwIQGhEgVGhlIHByb2Nlc3MgSUQuCgoMCgUEAAIIBRIDOwIHCgwKBQQAAggBEgM7
CAsKDAoFBAACCAMSAzsODwolCgQEAAIJEgM+AhgaGCBUaGUgcGFyZW50IHByb2Nlc3MgSUQu
CgoMCgUEAAIJBRIDPgIHCgwKBQQAAgkBEgM+CBIKDAoFBAACCQMSAz4VFwpyCgQEAAIKEgNC
AhUaZSBUaGUgSUQgb2YgdGhlIHVzZXIgdGhhdCBleGVjdXRlZCB0aGUgcHJvY2Vzcy4gRS5n
LiBJZiB0aGlzIGlzIHRoZSByb290IHVzZXIKIHRoaXMgd2lsbCBhbHdheXMgYmUgMC4KCgwK
BQQAAgoFEgNCAgcKDAoFBAACCgESA0IIDwoMCgUEAAIKAxIDQhIUCmoKAgQBEgRHAE0BGl4g
QSBuYW1lLXZhbHVlIHBhaXIgcmVwcmVzZW50aW5nIGFuIGVudmlyb25tZW50IHZhcmlhYmxl
IHVzZWQgaW4gYW4gb3BlcmF0aW5nCiBzeXN0ZW0gcHJvY2Vzcy4KCgoKAwQBARIDRwgbCkIK
BAQBAgASA0kCEho1IEVudmlyb25tZW50IHZhcmlhYmxlIG5hbWUgYXMgYSBKU09OIGVuY29k
ZWQgc3RyaW5nLgoKDAoFBAECAAUSA0kCCAoMCgUEAQIAARIDSQkNCgwKBQQBAgADEgNJEBEK
QwoEBAECARIDTAIRGjYgRW52aXJvbm1lbnQgdmFyaWFibGUgdmFsdWUgYXMgYSBKU09OIGVu
Y29kZWQgc3RyaW5nLgoKDAoFBAECAQUSA0wCCAoMCgUEAQIBARIDTAkMCgwKBQQBAgEDEgNM
DxBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::Process::Process ===
    # Fields for Process
    # Field: name Type: 9 ()
    # Field: binary Type: 11 (.google.cloud.securitycenter.v2.File)
    # Field: libraries Type: 11 (.google.cloud.securitycenter.v2.File)
    # Field: script Type: 11 (.google.cloud.securitycenter.v2.File)
    # Field: args Type: 9 ()
    # Field: arguments_truncated Type: 8 ()
    # Field: env_variables Type: 11 (.google.cloud.securitycenter.v2.EnvironmentVariable)
    # Field: env_variables_truncated Type: 8 ()
    # Field: pid Type: 3 ()
    # Field: parent_pid Type: 3 ()
    # Field: user_id Type: 3 ()

# === Message: Google::Cloud::Securitycenter::V2::Process::EnvironmentVariable ===
    # Fields for EnvironmentVariable
    # Field: name Type: 9 ()
    # Field: val Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::Process - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/process.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::Process;

    my $msg = Google::Cloud::Securitycenter::V2::Process::Process->new({
        name => $name,
        binary => $binary,
        libraries => $libraries,
        script => $script,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::Process::Process->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/process.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::Process::Process

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

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::File::File>)

File information for the process executable.

=item * C<< $msg->libraries() >> / C<< $msg->libraries($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::File::File>)

File information for libraries loaded by the process.

=item * C<< $msg->script() >> / C<< $msg->script($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::File::File>)

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

Type: C<Message> (L<Google::Cloud::Securitycenter::V2::Process::EnvironmentVariable>)

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

=item * C<< $msg->user_id() >> / C<< $msg->user_id($value) >>

Type: C<Int64>

The ID of the user that executed the process. E.g. If this is the root user
this will always be 0.

=back

=head2 Google::Cloud::Securitycenter::V2::Process::EnvironmentVariable

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::Process::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
