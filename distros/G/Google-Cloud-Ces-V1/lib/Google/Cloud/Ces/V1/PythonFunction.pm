package Google::Cloud::Ces::V1::PythonFunction;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Ces::V1::Common };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvY2VzL3YxL3B5dGhvbl9mdW5jdGlvbi5wcm90bxITZ29vZ2xlLmNs
b3VkLmNlcy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxogZ29vZ2xlL2Ns
b3VkL2Nlcy92MS9jb21tb24ucHJvdG8i4gEKDlB5dGhvbkZ1bmN0aW9uEhcKBG5hbWUYASAB
KAlCA+BBAVIEbmFtZRIkCgtweXRob25fY29kZRgCIAEoCUID4EEBUgpweXRob25Db2RlEiUK
C2Rlc2NyaXB0aW9uGAMgASgJQgPgQQNSC2Rlc2NyaXB0aW9uEmoKGHNlcnZpY2VfZGlyZWN0
b3J5X2NvbmZpZxgEIAEoCzIrLmdvb2dsZS5jbG91ZC5jZXMudjEuU2VydmljZURpcmVjdG9y
eUNvbmZpZ0ID4EEBUhZzZXJ2aWNlRGlyZWN0b3J5Q29uZmlnQlsKF2NvbS5nb29nbGUuY2xv
dWQuY2VzLnYxQhNQeXRob25GdW5jdGlvblByb3RvUAFaKWNsb3VkLmdvb2dsZS5jb20vZ28v
Y2VzL2FwaXYxL2Nlc3BiO2Nlc3BiSv4LCgYSBA4AKwEKvAQKAQwSAw4AEjKxBCBDb3B5cmln
aHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNl
LCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBm
aWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9i
dGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUu
b3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2Fi
bGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQg
dW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywK
IFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIg
ZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMg
bGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIg
dGhlIExpY2Vuc2UuCgoICgECEgMQABwKCQoCAwASAxIAKQoJCgIDARIDEwAqCggKAQgSAxUA
QAoJCgIICxIDFQBACggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcANAoJCgIICBIDFwA0
CggKAQgSAxgAMAoJCgIIARIDGAAwCiUKAgQAEgQbACsBGhkgQSBQeXRob24gZnVuY3Rpb24g
dG9vbC4KCgoKAwQAARIDGwgWCu4BCgQEAAIAEgMfAjsa4AEgT3B0aW9uYWwuIFRoZSBuYW1l
IG9mIHRoZSBQeXRob24gZnVuY3Rpb24gdG8gZXhlY3V0ZS4gTXVzdCBtYXRjaCBhIFB5dGhv
bgogZnVuY3Rpb24gbmFtZSBkZWZpbmVkIGluIHRoZSBweXRob24gY29kZS4gQ2FzZSBzZW5z
aXRpdmUuIElmIHRoZSBuYW1lIGlzCiBub3QgcHJvdmlkZWQsIHRoZSBmaXJzdCBmdW5jdGlv
biBkZWZpbmVkIGluIHRoZSBweXRob24gY29kZSB3aWxsIGJlIHVzZWQuCgoMCgUEAAIABRID
HwIICgwKBQQAAgABEgMfCQ0KDAoFBAACAAMSAx8QEQoMCgUEAAIACBIDHxI6Cg8KCAQAAgAI
nAgAEgMfEzkKQQoEBAACARIDIgJCGjQgT3B0aW9uYWwuIFRoZSBQeXRob24gY29kZSB0byBl
eGVjdXRlIGZvciB0aGUgdG9vbC4KCgwKBQQAAgEFEgMiAggKDAoFBAACAQESAyIJFAoMCgUE
AAIBAxIDIhcYCgwKBQQAAgEIEgMiGUEKDwoIBAACAQicCAASAyIaQAptCgQEAAICEgMmAkUa
YCBPdXRwdXQgb25seS4gVGhlIGRlc2NyaXB0aW9uIG9mIHRoZSBQeXRob24gZnVuY3Rpb24s
IHBhcnNlZCBmcm9tIHRoZSBweXRob24KIGNvZGUncyBkb2NzdHJpbmcuCgoMCgUEAAICBRID
JgIICgwKBQQAAgIBEgMmCRQKDAoFBAACAgMSAyYXGAoMCgUEAAICCBIDJhlECg8KCAQAAgII
nAgAEgMmGkMKRwoEBAACAxIEKQIqLxo5IE9wdGlvbmFsLiBTZXJ2aWNlIERpcmVjdG9yeSBj
b25maWd1cmF0aW9uIGZvciB0aGUgdG9vbC4KCgwKBQQAAgMGEgMpAhgKDAoFBAACAwESAykZ
MQoMCgUEAAIDAxIDKTQ1CgwKBQQAAgMIEgMqBi4KDwoIBAACAwicCAASAyoHLWIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::PythonFunction::PythonFunction ===
    # Fields for PythonFunction
    # Field: name Type: 9 ()
    # Field: python_code Type: 9 ()
    # Field: description Type: 9 ()
    # Field: service_directory_config Type: 11 (.google.cloud.ces.v1.ServiceDirectoryConfig)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::PythonFunction - Compiled Protocol Buffers messages for google/cloud/ces/v1/python_function.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::PythonFunction;

    my $msg = Google::Cloud::Ces::V1::PythonFunction::PythonFunction->new({
        name => $name,
        python_code => $python_code,
        description => $description,
        service_directory_config => $service_directory_config,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::PythonFunction::PythonFunction->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/python_function.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::PythonFunction::PythonFunction

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

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::ServiceDirectoryConfig>)

Optional. Service Directory configuration for the tool.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::PythonFunction::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
