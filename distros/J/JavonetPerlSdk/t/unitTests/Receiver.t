use strict;
use warnings;
use lib 'lib';
use aliased 'Javonet::Core::Receiver::Receiver' => 'Receiver';
use Test::More qw(no_plan);

my @message_byte_array = (4, 0, 0, 0, 0, 0, 0, 0, 0, 4, 11);

is_deeply(Receiver->heart_beat(@message_byte_array), [49, 48], 'heart beat test');

1;
