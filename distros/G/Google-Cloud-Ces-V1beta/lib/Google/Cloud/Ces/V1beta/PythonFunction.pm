package Google::Cloud::Ces::V1beta::PythonFunction;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Ces::V1beta::Common };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9weXRob25fZnVuY3Rpb24ucHJvdG8SF2dvb2ds
ZS5jbG91ZC5jZXMudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGiRn
b29nbGUvY2xvdWQvY2VzL3YxYmV0YS9jb21tb24ucHJvdG8i5gEKDlB5dGhvbkZ1bmN0aW9u
EhcKBG5hbWUYASABKAlCA+BBAVIEbmFtZRIkCgtweXRob25fY29kZRgCIAEoCUID4EEBUgpw
eXRob25Db2RlEiUKC2Rlc2NyaXB0aW9uGAMgASgJQgPgQQNSC2Rlc2NyaXB0aW9uEm4KGHNl
cnZpY2VfZGlyZWN0b3J5X2NvbmZpZxgEIAEoCzIvLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRh
LlNlcnZpY2VEaXJlY3RvcnlDb25maWdCA+BBAVIWc2VydmljZURpcmVjdG9yeUNvbmZpZ0Jj
Chtjb20uZ29vZ2xlLmNsb3VkLmNlcy52MWJldGFCE1B5dGhvbkZ1bmN0aW9uUHJvdG9QAVot
Y2xvdWQuZ29vZ2xlLmNvbS9nby9jZXMvYXBpdjFiZXRhL2Nlc3BiO2Nlc3BiSv4LCgYSBA4A
KwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACAKCQoCAwAS
AxIAKQoJCgIDARIDEwAuCggKAQgSAxUARAoJCgIICxIDFQBECggKAQgSAxYAIgoJCgIIChID
FgAiCggKAQgSAxcANAoJCgIICBIDFwA0CggKAQgSAxgANAoJCgIIARIDGAA0CiUKAgQAEgQb
ACsBGhkgQSBQeXRob24gZnVuY3Rpb24gdG9vbC4KCgoKAwQAARIDGwgWCu4BCgQEAAIAEgMf
Ajsa4AEgT3B0aW9uYWwuIFRoZSBuYW1lIG9mIHRoZSBQeXRob24gZnVuY3Rpb24gdG8gZXhl
Y3V0ZS4gTXVzdCBtYXRjaCBhIFB5dGhvbgogZnVuY3Rpb24gbmFtZSBkZWZpbmVkIGluIHRo
ZSBweXRob24gY29kZS4gQ2FzZSBzZW5zaXRpdmUuIElmIHRoZSBuYW1lIGlzCiBub3QgcHJv
dmlkZWQsIHRoZSBmaXJzdCBmdW5jdGlvbiBkZWZpbmVkIGluIHRoZSBweXRob24gY29kZSB3
aWxsIGJlIHVzZWQuCgoMCgUEAAIABRIDHwIICgwKBQQAAgABEgMfCQ0KDAoFBAACAAMSAx8Q
EQoMCgUEAAIACBIDHxI6Cg8KCAQAAgAInAgAEgMfEzkKQQoEBAACARIDIgJCGjQgT3B0aW9u
YWwuIFRoZSBQeXRob24gY29kZSB0byBleGVjdXRlIGZvciB0aGUgdG9vbC4KCgwKBQQAAgEF
EgMiAggKDAoFBAACAQESAyIJFAoMCgUEAAIBAxIDIhcYCgwKBQQAAgEIEgMiGUEKDwoIBAAC
AQicCAASAyIaQAptCgQEAAICEgMmAkUaYCBPdXRwdXQgb25seS4gVGhlIGRlc2NyaXB0aW9u
IG9mIHRoZSBQeXRob24gZnVuY3Rpb24sIHBhcnNlZCBmcm9tIHRoZSBweXRob24KIGNvZGUn
cyBkb2NzdHJpbmcuCgoMCgUEAAICBRIDJgIICgwKBQQAAgIBEgMmCRQKDAoFBAACAgMSAyYX
GAoMCgUEAAICCBIDJhlECg8KCAQAAgIInAgAEgMmGkMKRwoEBAACAxIEKQIqLxo5IE9wdGlv
bmFsLiBTZXJ2aWNlIERpcmVjdG9yeSBjb25maWd1cmF0aW9uIGZvciB0aGUgdG9vbC4KCgwK
BQQAAgMGEgMpAhgKDAoFBAACAwESAykZMQoMCgUEAAIDAxIDKTQ1CgwKBQQAAgMIEgMqBi4K
DwoIBAACAwicCAASAyoHLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::PythonFunction::PythonFunction ===
    # Fields for PythonFunction
    # Field: name Type: 9 ()
    # Field: python_code Type: 9 ()
    # Field: description Type: 9 ()
    # Field: service_directory_config Type: 11 (.google.cloud.ces.v1beta.ServiceDirectoryConfig)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::PythonFunction - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/python_function.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::PythonFunction;

    my $msg = Google::Cloud::Ces::V1beta::PythonFunction::PythonFunction->new({
        name => $name,
        python_code => $python_code,
        description => $description,
        service_directory_config => $service_directory_config,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::PythonFunction::PythonFunction->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/python_function.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::PythonFunction::PythonFunction

A Python function tool.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Optional. The name of the Python function to execute. Must match a Python
function name defined in the python code. Case sensitive. If the name is
not provided, the first function defined in the python code will be used.

=item * C<< $msg->python_code() >> / C<< $msg->python_code($value) >>

Type: C<String>

Optional. The Python code to execute for the tool.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Output only. The description of the Python function, parsed from the python
code's docstring.

=item * C<< $msg->service_directory_config() >> / C<< $msg->service_directory_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Common::ServiceDirectoryConfig>)

Optional. Service Directory configuration for the tool.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::PythonFunction::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
