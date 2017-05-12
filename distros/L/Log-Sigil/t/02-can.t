use strict;
use warnings;
use Test::More tests => 1;
use Log::Sigil;

my @methods = qw(
    swarn
    swarn2
);

can_ok( "Log::Sigil", @methods );
