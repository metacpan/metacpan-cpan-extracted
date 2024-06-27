#! /usr/bin/env perl

use 5.022;
use warnings;
use lib './demo/lib';

use Demo -debug;   # Comment out the -debug if you don't want to see how the sausages are made

sub demo ($what) {
    DWIM { a block, a magic block, with added $what }
}

say demo('mystery');
say 'sourcery'->&demo;

goto HERE;

[DONE]
say "done";
exit;

[HERE]
my $n = 3;
say qq{ok {$n++} - qq blocks};
say qq{ok {$n++} - qq blocks};

goto DONE;


sub DWIM::Block::_DWIM ($request) {
    state $n = 1;
    return 'ok ', $n++, " - DWIMMING: $request";
}

