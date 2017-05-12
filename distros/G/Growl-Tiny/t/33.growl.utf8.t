#!/perl
use strict;

use utf8;
use Test::More tests => 1;

use Growl::Tiny qw(notify);

ok( notify( { subject => "utf-8 詩意圖靈測驗" } ),
    "notification with single quotes"
);
