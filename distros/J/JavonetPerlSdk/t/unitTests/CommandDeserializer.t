use strict;
use warnings;
use Test::More qw(no_plan);
use lib 'lib';
use aliased 'Javonet::Core::Protocol::CommandDeserializer' => 'CommandDeserializer';
SKIP: {
    skip "To evaluate", 1 eq 1;
    cmp_ok(scalar test_command_deserialize(), '==', 0, 'Command deserialization success');
}

sub test_command_deserialize{

    my @array_command = (5,0,0,0,0,0,0,0,5,0,0,0,12,5,7,0,8,5,9,1,0,8,100,97,116,101,116,105,109,101,1,0,4,100,97,116,101,1,0,5,116,111,100,97,121);
    my $commandDeserializer = CommandDeserializer->new(\@array_command);

    my $result = $commandDeserializer->decode();

    return 0;

}


done_testing();
