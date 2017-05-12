use strict;
use warnings;
use utf8;
use Test::More;
use LiBot::Handler::Karma;
use LiBot::Test::Handler;
use File::Temp;

my $tmp = File::Temp->new(UNLINK => 1);

load_plugin(
    'Handler' => 'Karma' => {
        path => "$tmp",
    }
);

test_message '<tokuhirom> mattn++' => 'mattn: 1';
test_message '<gfx> mattn++'       => 'mattn: 2';
test_message '<hsegawa> mattn--'   => 'mattn: 1';
test_message '<hsegawa> mattn--'   => 'mattn: 0';
test_message '<hsegawa> mattn--'   => 'mattn: -1';
test_message '<hsegawa> mattn--'   => 'mattn: -2';
test_message '<hsegawa> gfx--'     => 'gfx: -1';
test_message '<hsegawa> gfx--'     => 'gfx: -2';
test_message '<hsegawa> gfx--'     => 'gfx: -3';
test_message '<hsegawa> gfx--'     => 'gfx: -4';

done_testing;

