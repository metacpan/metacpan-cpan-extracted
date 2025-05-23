use strict;
use warnings;
use Test::More qw(no_plan);
use lib 'lib';

use aliased 'Javonet::Sdk::Core::PerlCommand' => 'PerlCommand';
use aliased 'Javonet::Core::Protocol::CommandSerializer' => 'CommandSerializer';
use aliased 'Javonet::Core::Protocol::CommandDeserializer' => 'CommandDeserializer';
use aliased 'Javonet::Sdk::Core::RuntimeLib' => 'RuntimeLib';
use aliased 'Javonet::Sdk::Core::PerlCommandType' => 'PerlCommandType';

my $command = PerlCommand->new(runtime => Javonet::Sdk::Core::RuntimeLib::get_runtime('Perl'),
    command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('GetStaticField'),
    payload => ['TestClass::TestClass', 'static_variable','../../testResources/perl-package']);

my $nested_command = PerlCommand->new(
    runtime => Javonet::Sdk::Core::RuntimeLib::get_runtime('Perl'),
    command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('GetStaticField'),
    payload => [PerlCommand->new(
        runtime => Javonet::Sdk::Core::RuntimeLib::get_runtime('Perl'),
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('LoadLibrary'),
        payload => ['../../testResources/perl-package','TestClass::TestClass','TestClass.pm']
    ), 'static_variable']);

my $deserialized_nested_command = test_nested_command_serialize_deserialize();
# my $deserialized_command = test_command_serialize_deserialize();
# cmp_ok($deserialized_command->{payload}[0], 'eq', $command->{payload}[0], 'Command serialize and deserialize returns correct first payload argument test');
# cmp_ok($deserialized_command->{payload}[1], 'eq', $command->{payload}[1], 'Command serialize and deserialize returns correct second payload argument test');
# cmp_ok($deserialized_command->{payload}[2], 'eq', $command->{payload}[2], 'Command serialize and deserialize returns correct third payload argument test');
cmp_ok($deserialized_nested_command->{payload}[0]->{payload}[0], 'eq', $nested_command->{payload}[0]->{payload}[0], 'Command serialize and deserialize returns correct second payload argument test');
cmp_ok($deserialized_nested_command->{payload}[0]->{payload}[1], 'eq', $nested_command->{payload}[0]->{payload}[1], 'Command serialize and deserialize returns correct third payload argument test');

sub test_command_serialize_deserialize{

    my $commandSerializer = CommandSerializer->new();

    my @result = $commandSerializer->serialize($command);


    my $commandDeserializer = CommandDeserializer->new(\@result);
    my $deserializedResult = $commandDeserializer->decode();

    return $deserializedResult;

}

sub test_nested_command_serialize_deserialize{
    my $get_static_method_nested_command = PerlCommand->new(
        runtime => Javonet::Sdk::Core::RuntimeLib::get_runtime('Perl'),
        command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('GetStaticField'),
        payload => [PerlCommand->new(
            runtime => Javonet::Sdk::Core::RuntimeLib::get_runtime('Perl'),
            command_type => Javonet::Sdk::Core::PerlCommandType::get_command_type('LoadLibrary'),
            payload => ['../../testResources/perl-package','TestClass::TestClass','TestClass.pm']
        ), 'static_variable']);

    my $commandSerializer = CommandSerializer->new();

    my @result = $commandSerializer->serialize($get_static_method_nested_command, 0);


    my $commandDeserializer = CommandDeserializer->new(\@result);
    my $deserializedResult = $commandDeserializer->decode();

    return $deserializedResult;

}
done_testing();
