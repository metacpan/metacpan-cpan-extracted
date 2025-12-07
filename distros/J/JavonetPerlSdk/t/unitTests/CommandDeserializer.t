use strict;
use warnings;
use Test::More qw(no_plan);
use lib 'lib';
use aliased 'Javonet::Core::Protocol::CommandDeserializer' => 'CommandDeserializer';

sub test_command_deserialize{

    my @array_command = (4, 0, 0, 0, 0, 0, 0, 0, 0, 4, 1, 1, 1, 5, 0, 0, 0, 110, 117, 109, 112, 121);
    return CommandDeserializer->deserialize(\@array_command);
}

my $deserialized_command = test_command_deserialize();
is ($deserialized_command->{command_type}, 1, 'Command type is correct'); # LoadLibrary
is ($deserialized_command->{runtime}, 4, 'Runtime is correct'); # Perl
is ($deserialized_command->{payload}[0], 'numpy', 'Payload is correct'); # 'numpy'


done_testing();
