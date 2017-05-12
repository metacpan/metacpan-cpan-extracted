use warnings;
use strict;
use Test::More tests => 2;

my (%before, @after);

sub sublist {
    sort grep {*{$main::{$_}}{CODE}} keys %main::
}

BEGIN {%before = map {$_ => 1} sublist}

use List::Gen '*';

@after = grep {not $before{$_}} sublist;

ok $before{sublist}, 'sublist sanity check';
is_deeply \@after, [sort @List::Gen::EXPORT_OK, '\\'], q{use List::Gen '*';};
