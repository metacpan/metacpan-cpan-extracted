use strict;
use warnings;
use lib 'lib';
use aliased 'Javonet::Core::Exception::ExceptionSerializer' => 'ExceptionSerializer';
use aliased 'Javonet::Sdk::Core::PerlCommand' => 'PerlCommand';
use aliased 'Javonet::Sdk::Core::PerlCommandType' => 'Javonet::Sdk::Core::PerlCommandType';
use aliased 'Javonet::Sdk::Core::RuntimeLib' => 'Javonet::Sdk::Core::RuntimeLib';
use Test::More qw(no_plan);

package DummyException;
sub new { bless {}, shift }
sub get_message { "Test exception" }
sub get_stack_trace { "" }

package main;

# Test: serialize normal exception
my $exception = DummyException->new();
my $command = PerlCommand->new(
    runtime      => Javonet::Sdk::Core::RuntimeLib::get_runtime('Perl'),
    command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('GetType'),
    payload      => ['TestCommand']
);
my $serialized_command = ExceptionSerializer->serialize($exception);

is($serialized_command->{command_type}, 10, 'command_type is Exception');
is($serialized_command->{payload}->[0], 0, 'payload\[0\] == ExceptionType::Exception');
is($serialized_command->{payload}->[2], 'DummyException', 'payload\[2\] == Exception class');
is($serialized_command->{payload}->[3], 'Test exception', 'payload\[3\] == exception message');
is($serialized_command->{payload}->[4], '', 'payload\[4\] == stack trace');
is($serialized_command->{payload}->[5], undef, 'payload\[5\] == undef');
is($serialized_command->{payload}->[6], undef, 'payload\[6\] == undef');
is($serialized_command->{payload}->[7], undef, 'payload\[7\] == undef');

# Test: serialize with undef exception
my $serialized_command_null = ExceptionSerializer->serialize(undef);

is($serialized_command_null->{command_type}, 10, 'command_type is Exception');
is($serialized_command_null->{payload}->[0], 0, 'payload\[0\] == ExceptionType::Exception');
is($serialized_command_null->{payload}->[3], 'Failed to serialize exception: ', 'payload\[3\] contains error');
is($serialized_command_null->{payload}->[2], 'SerializationError', 'payload\[2\] == SerializationError');

1;
