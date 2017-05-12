#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Games::SMTNocturne::Demons 'fuse';

for my $demon1 (Games::SMTNocturne::Demons::Demon->all_demons) {
    for my $demon2 (Games::SMTNocturne::Demons::Demon->all_demons) {
        next if $demon1 le $demon2;

        my $fusion1 = fuse($demon1, $demon2);
        my $fusion2 = fuse($demon2, $demon1);

        is(fuse($demon1, $demon2), fuse($demon2, $demon1));
    }
}

done_testing;
