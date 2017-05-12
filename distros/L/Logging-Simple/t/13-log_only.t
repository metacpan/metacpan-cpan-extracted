#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Logging::Simple;

my $log = Logging::Simple->new(print => 0, display => 0);
my $msg;

{
    $log->level('=0');

    is($log->_0('msg'), "msg\n", "lvl 0 log only 0 works");
    is($log->_1('msg'), undef, "lvl 1 log only 0 works");
    is($log->_2('msg'), undef, "lvl 2 log only 0 works");
    is($log->_3('msg'), undef, "lvl 3 log only 0 works");
    is($log->_4('msg'), undef, "lvl 4 log only 0 works");
    is($log->_5('msg'), undef, "lvl 5 log only 0 works");
    is($log->_6('msg'), undef, "lvl 6 log only 0 works");
    is($log->_7('msg'), undef, "lvl 7 log only 0 works");
}
{
    $log->level('=1');

    is($log->_0('msg'), undef, "lvl 0 log only 1 works");
    is($log->_1('msg'), "msg\n", "lvl 1 log only 1 works");
    is($log->_2('msg'), undef, "lvl 2 log only 1 works");
    is($log->_3('msg'), undef, "lvl 3 log only 1 works");
    is($log->_4('msg'), undef, "lvl 4 log only 1 works");
    is($log->_5('msg'), undef, "lvl 5 log only 1 works");
    is($log->_6('msg'), undef, "lvl 6 log only 1 works");
    is($log->_7('msg'), undef, "lvl 7 log only 1 works");
}
{ # test going back to non-only
    $log->level(1);

    is($log->_0('msg'), "msg\n", "level works again without only for 0");
    is($log->_1('msg'), "msg\n", "level works again without only for 1");
    is($log->_2('msg'), undef, "level works again without only for 2");
}
{
    $log->level('=2');

    is($log->_0('msg'), undef, "lvl 0 log only 2 works");
    is($log->_1('msg'), undef, "lvl 1 log only 2 works");
    is($log->_2('msg'), "msg\n", "lvl 2 log only 2 works");
    is($log->_3('msg'), undef, "lvl 3 log only 2 works");
    is($log->_4('msg'), undef, "lvl 4 log only 2 works");
    is($log->_5('msg'), undef, "lvl 5 log only 2 works");
    is($log->_6('msg'), undef, "lvl 6 log only 2 works");
    is($log->_7('msg'), undef, "lvl 7 log only 2 works");
}
{
    $log->level('=7');

    is($log->_0('msg'), undef, "lvl 0 log only 7 works");
    is($log->_1('msg'), undef, "lvl 1 log only 7 works");
    is($log->_2('msg'), undef, "lvl 2 log only 7 works");
    is($log->_3('msg'), undef, "lvl 3 log only 7 works");
    is($log->_4('msg'), undef, "lvl 4 log only 7 works");
    is($log->_5('msg'), undef, "lvl 5 log only 7 works");
    is($log->_6('msg'), undef, "lvl 6 log only 7 works");
    is($log->_7('msg'), "msg\n", "lvl 7 log only 7 works");
}
{ # test going back to non-only
    $log->level(7);

    is($log->_0('msg'), "msg\n", "level works again without only for 0");
    is($log->_1('msg'), "msg\n", "level works again without only for 1");
    is($log->_2('msg'), "msg\n", "level works again without only for 2");
    is($log->_7('msg'), "msg\n", "level works again without only for 7");
}
done_testing();

