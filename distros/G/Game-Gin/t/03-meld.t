#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Gin::Card qw(id_of name_of);
use Game::Gin::Meld qw(melds_in is_meld is_set is_run);

sub h { return [ map { id_of($_) } @_ ] }
# By ID and not alphabetically: names sorted as strings put JS before TS,
# which made the expected key for 9S TS JS read "9S JS TS". Sorting by id
# groups by suit and then orders by rank, which is how a hand is read.
sub shown { return join ' ', map { name_of($_) } sort { $a <=> $b } @{ $_[0] } }
sub found { my %s; $s{ shown($_) } = 1 for melds_in(h(@_)); return \%s }

# ---- sets ----------------------------------------------------------------------------

subtest 'a set is three or four of a rank, in different suits' => sub {
    plan tests => 6;
    ok(is_set(h(qw(7S 7H 7D))),     'three sevens');
    ok(is_set(h(qw(7S 7H 7D 7C))),  'four sevens');
    ok(!is_set(h(qw(7S 7H))),       'two is not a meld');
    ok(!is_set(h(qw(7S 7H 8D))),    'and a stray rank is not a set');
    ok(!is_run(h(qw(7S 7H 7D))),    'a set is not also a run');
    ok(is_meld(h(qw(7S 7H 7D))),    'but it is a meld');
};

# ---- runs ------------------------------------------------------------------------------

subtest 'a run is three or more consecutive in one suit' => sub {
    plan tests => 6;
    ok(is_run(h(qw(5S 6S 7S))),      'five six seven of spades');
    ok(is_run(h(qw(7S 5S 6S))),      'given in any order');
    ok(is_run(h(qw(5S 6S 7S 8S))),   'four of them');
    ok(!is_run(h(qw(5S 6H 7S))),     'not across suits');
    ok(!is_run(h(qw(5S 7S 8S))),     'not with a gap');
    ok(!is_run(h(qw(5S 6S))),        'and not two cards');
};

subtest 'the ace is low, so Q-K-A is not a run' => sub {
    plan tests => 3;
    ok(is_run(h(qw(AS 2S 3S))), 'ace two three is a run');
    ok(!is_run(h(qw(QS KS AS))), 'queen king ace is not');
    # The enumeration must agree with the predicate, which is a separate
    # thing: melds_in walks consecutive ranks and could in principle wrap
    # where is_run does not.
    my $f = found(qw(QS KS AS 2H 3H));
    is_deeply([ keys %$f ], [], 'and the enumeration offers no meld at all there');
};

# ---- the enumeration, which is where the interesting bug lives ----------------------------

subtest 'a four of a kind offers its triples as well as itself' => sub {
    plan tests => 6;
    my $f = found(qw(7S 7H 7D 7C));
    is(scalar keys %$f, 5, 'five candidates: the four-set and each of its triples');
    ok($f->{'7S 7H 7D 7C'}, 'the four');
    ok($f->{'7H 7D 7C'},    'and the triple without the spade');
    ok($f->{'7S 7D 7C'},    'without the heart');
    ok($f->{'7S 7H 7C'},    'without the diamond');
    ok($f->{'7S 7H 7D'},    'and without the club');
};

subtest 'a long run offers every window inside it' => sub {
    plan tests => 4;
    my $f = found(qw(4S 5S 6S 7S 8S));
    # lengths 3, 4 and 5: three windows of three, two of four, one of five
    is(scalar keys %$f, 6, 'six windows in a run of five');
    ok($f->{'4S 5S 6S'},          'the first three');
    ok($f->{'6S 7S 8S'},          'the last three');
    ok($f->{'4S 5S 6S 7S 8S'},    'and the whole thing');
};

subtest 'a broken suit yields only its consecutive stretches' => sub {
    plan tests => 3;
    my $f = found(qw(2S 3S 4S 9S TS JS));
    is(scalar keys %$f, 2, 'two runs, and nothing spanning the gap');
    ok($f->{'2S 3S 4S'},  'the low one');
    ok($f->{'9S TS JS'},  'and the high one');
};

# ---- the case the sub-melds exist for ----------------------------------------------------

subtest 'the seven that is wanted by both a set and a run' => sub {
    plan tests => 3;
    my $f = found(qw(7S 7H 7D 7C 5S 6S));
    ok($f->{'7S 7H 7D 7C'}, 'the four sevens are offered');
    ok($f->{'7H 7D 7C'},    'so is the triple that leaves the SPADE out');
    ok($f->{'5S 6S 7S'},    'and so is the run that then uses the spade');
};

done_testing();
