#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 33;

BEGIN {
	use_ok('Lingua::Phonology::Symbols');
}
# Comment out for debugging
no warnings 'Lingua::Phonology::Symbols';

# prepare
use Lingua::Phonology;
my $phono = new Lingua::Phonology;
my $feat = $phono->features;
$feat->loadfile;

# new as class method
ok(my $sym = Lingua::Phonology::Symbols->new($feat), 'new as class method');

# new as object method
ok(my $other = $sym->new($feat), 'new as object method');

# check features
is($sym->features, $feat, 'assignment/retreival from features()');

# prepare segments
my $b = $phono->segment;
$b->voice(1);
$b->labial(1);

# test symbol
ok($sym->symbol(b => $b), 'assign with symbol()');

# test diacritic
my $n = $phono->segment;
$n->nasal(1);
ok $sym->symbol('*~' => $n), 'assign diacritic with symbol()';

# get a copy segment
ok(my $bnew = $sym->segment('b'), 'fetch copy with segment()');

# spell yourself
is($sym->spell($bnew), 'b', 'spelling via spell()');

# diacritics flag (should start out off)
ok ((not $sym->diacritics), 'get value of diacritics');
ok $sym->diacritics(1), 'set value of diacritics';
ok $sym->no_diacritics, 'test no_diacritics';
ok $sym->set_diacritics, 'test set_diacritics';

# spell yourself with diacritics (and a new feature)
$bnew->nasal(1);
is $sym->spell($bnew), 'b~', 'spelling via spell() with diacritics on';

# prototype yourself
is($sym->prototype('b'), $b, 'fetching via prototype()');

# bad symbol
my $otherphono = new Lingua::Phonology; #prepare
ok((not $sym->symbol(fail => $phono)), 'failure of symbol(): bad prototype');
ok((not $sym->symbol(fail => $otherphono->segment)), 'failure of symbol(): bad featureset');

# bad segment
ok((not $sym->segment('fail')), 'failure of segment()');

# bad spelling
ok((not $sym->spell($phono)), 'failure of spell()');

# bad prototype
ok((not $sym->prototype('fail')), 'failure of prototype()');

# change symbol
ok($sym->change_symbol(b => $bnew), 'change_symbol()');
is($sym->prototype('b'), $bnew, 'results of change_symbol()');

# bad change_symbol()
ok((not $sym->change_symbol(fail => $bnew)), 'failure of change_symbol()');

# drop symbol()
ok($sym->drop_symbol('b'), 'drop_symbol');
ok $sym->drop_symbol('*~'), 'drop_symbol on diacritic';

# auto_reindex
is $sym->auto_reindex, 1, 'test auto_reindex';
is $sym->auto_reindex('foo'), 1, 'test auto_reindex';

# reindexing
ok $sym->reindex, 'test reindex';
is $sym->{REINDEX}, 0, 'check result of reindex';

# auto index off
ok $sym->no_auto_reindex, 'test no_auto_reindex';
is $sym->{AUTOINDEX}, 0, 'result of no_auto_reindex';

# auto index on
ok $sym->set_auto_reindex, 'test set_auto_reindex';
is $sym->{AUTOINDEX}, 1, 'result of set_auto_reindex';

# test that auto index off actually does its thing
$sym->no_auto_reindex;
$sym->symbol(b => $b); # trips the REINDEX flag on
$sym->spell($b); # should leave the REINDEX flag on
is $sym->{REINDEX}, 1, 'test effect of no_auto_reindex'; # we have to break encapsulation here
