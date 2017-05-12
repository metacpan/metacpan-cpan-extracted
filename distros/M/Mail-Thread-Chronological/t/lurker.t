#!perl -w
use strict;
use Test::More tests => 1;

use_ok('Mail::Thread::Chronological');
# TODO real live testing

eval "use Test::Differences";
# a beefed up is_deeply
sub deeply ($$;$) {
    goto &eq_or_diff if defined &eq_or_diff;
    goto &is_deeply;
}
