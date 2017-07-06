#!perl

use strict;
use warnings;
use Test::More 0.98;

subtest "conf:logging_cb" => sub {
    my $str = "";
    require Log::ger::Output;
    Log::ger::Output->set(
        'Callback',
        logging_cb => sub { $str .= "$_[1],$_[2]\n" }),
            ;
    my $h = {}; Log::ger::init_target(hash => $h);

    $h->{warn}("a");
    $h->{error}("b");
    $h->{debug}("c");
    is($str, "3,a\n2,b\n5,c\n");
};

# XXX test conf:detection_cb

done_testing;
