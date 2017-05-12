#!/usr/bin/perl
use strict;
use warnings;

use Logging::Simple;
use Test::More;

my $mod = 'Logging::Simple';

{ # in instantiate

    my $log = $mod->new(level => -1, print => 0);

    is ($log->_0('msg'), undef, "level -1 disables 0 in new()");
    is ($log->_1('msg'), undef, "level -1 disables 1 in new()");
    is ($log->_2('msg'), undef, "level -1 disables 2 in new()");
    is ($log->_3('msg'), undef, "level -1 disables 3 in new()");
    is ($log->_4('msg'), undef, "level -1 disables 4 in new()");
    is ($log->_5('msg'), undef, "level -1 disables 5 in new()");
    is ($log->_6('msg'), undef, "level -1 disables 6 in new()");
    is ($log->_7('msg'), undef, "level -1 disables 7 in new()");

    $log->level(7);

    like ($log->_0('msg'), qr/msg/, "level(7) 0 re-enabled after new(level -1)");
    like ($log->_1('msg'), qr/msg/, "level(7) 1 re-enabled after new(level -1)");
    like ($log->_2('msg'), qr/msg/, "level(7) 2 re-enabled after new(level -1)");
    like ($log->_3('msg'), qr/msg/, "level(7) 3 re-enabled after new(level -1)");
    like ($log->_4('msg'), qr/msg/, "level(7) 4 re-enabled after new(level -1)");
    like ($log->_5('msg'), qr/msg/, "level(7) 5 re-enabled after new(level -1)");
    like ($log->_6('msg'), qr/msg/, "level(7) 6 re-enabled after new(level -1)");
    like ($log->_7('msg'), qr/msg/, "level(7) 7 re-enabled after new(level -1)");

    $log->level(-1);

    is ($log->_0('msg'), undef, "level(-1) disables 0");
    is ($log->_1('msg'), undef, "level(-1) disables 1");
    is ($log->_2('msg'), undef, "level(-1) disables 2");
    is ($log->_3('msg'), undef, "level(-1) disables 3");
    is ($log->_4('msg'), undef, "level(-1) disables 4");
    is ($log->_5('msg'), undef, "level(-1) disables 5");
    is ($log->_6('msg'), undef, "level(-1) disables 6");
    is ($log->_7('msg'), undef, "level(-1) disables 7");
}

done_testing();

