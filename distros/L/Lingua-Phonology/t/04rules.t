#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 65;

BEGIN {
	use_ok('Lingua::Phonology::Rules');
}
# Comment out for debugging
no warnings 'Lingua::Phonology::Rules';
no warnings 'Lingua::Phonology::Common';

# This module is difficult to test. The number of possible interactions is
# enormous, and the pieces interlock very tightly, making it difficult to
# create independent tests. Still, I'm doing the best I can 

# new as a class method
ok(my $rules = new Lingua::Phonology::Rules, 'new as a class method');

# new as an object method
ok(my $otherrules = $rules->new, 'new as an object method');

# add a sample meaningless rule
# prepare some rules and a list of methods
my $testrule = {
	tier => 'tier',
	domain => 'domain',
	direction => 'leftward',
	filter => sub {},
	where => sub {},
	do => sub {}
};
my $setrule = {
	tier => 'new tier',
	domain => 'new domain',
	direction => 'rightward',
	filter => sub {},
	where => sub {},
	do => sub {}
};
my @methods = ('tier', 'domain', 'direction', 'filter', 'where','do');

# test assigning the rule
ok($rules->add_rule(test => $testrule), 'add via add_rule');

# failure on bad directions
ok((not $rules->add_rule(fail => { direction => 'sucka' })), 'add_rule failure on bad direction');

# failure on bad filter
ok((not $rules->add_rule(fail => { filter => 'nope' })), 'add_rule failure on bad filter');

# failure on bad where
ok((not $rules->add_rule(fail => { where => 'no way' })), 'add_rule failure on bad where');

# failure on bad do
ok((not $rules->add_rule(fail => { do => 'not even' })), 'add_rule failure on bad do');

# change a rule
ok $rules->change_rule(test => $setrule), 'change w/ change_rule';

# failure of change on nonexistent rule
ok !$rules->change_rule(nonesuch => $testrule), 'change_rule failure on no such rule';

# drop a rule
ok $rules->drop_rule('test'), 'drop_rule w/ single';
ok !exists $rules->{RULES}->{test}, 'drop_rule had desired effect';

# test the various get/set methods
$rules->add_rule(test => $testrule);
for (@methods) {
	# test getting
	is($rules->$_('test'), $testrule->{$_}, "test get $_");

	# test setting
	ok($rules->$_('test', $setrule->{$_}), "test set $_");

	# get after set
	is($rules->$_('test'), $setrule->{$_}, "test get $_ after set");
}

# test failure of these methods
for (@methods) {
	# just do a simple get
	ok((not $rules->$_('nonesuch')), "failure of $_");
}

# test getting rid of junk (which now needs to be done)
ok($rules->clear, 'test clear');

# Here is the hard part: writing meaningful tests for the actual application of
# rules. This part is inelegant and obtuse. Oh, well.

# prepare yourself-load default features and symbols
use Lingua::Phonology;
my $phono = new Lingua::Phonology;
$phono->features->loadfile;
$phono->symbols->loadfile;
$phono->symbols->drop_symbol('j','w');

# Test directionality
{
    my $word = 'dirs';
    my @word = $phono->symbols->segment(split //, $word);
    my ($right, $left);

    $rules->add_rule(
        left => {
            direction => 'leftward',
            do => sub { $left .= $_[0]->spell }
        },
        right => {
            direction => 'rightward',
            do => sub { $right .= $_[0]->spell }
        }
    );

    ok $rules->left(\@word), 'direction: apply dir rule 1';
    ok $rules->right(\@word), 'direction: apply dir rule 2';
    is $right, $word, 'direction: rightward rule matches';
    is $left, reverse($word), 'direction: leftward rule matches';

    $rules->drop_rule('left', 'right');
}

# Test domains
{
    # make a random domain and manually assign features
    # b = bound, i = interior
    my @word = $phono->symbols->segment(split //, 'bibbiibbb');
    $phono->features->add_feature(DOM => { type => 'binary' });
    $word[0]->DOM(1);
    $word[1]->DOM($word[0]->value_ref('DOM'));
    $word[2]->DOM($word[0]->value_ref('DOM'));
    $word[3]->DOM(0);
    $word[4]->DOM($word[3]->value_ref('DOM'));
    $word[5]->DOM($word[3]->value_ref('DOM'));
    $word[6]->DOM($word[3]->value_ref('DOM'));
    $word[7]->DOM(1);
    $word[8]->DOM($word[7]->value_ref('DOM'));

    # In this rule we add $_[0]->{seg} to @b and @i, briefly breaking
    # encapsulation of the Segment::Rule objects used inside the rule
    my (@b, @i);
    $rules->add_rule(
        get_bs => {
            direction => 'rightward',
            domain => 'DOM',
            where => sub { $_[1]->BOUNDARY || $_[-1]->BOUNDARY },
            do => sub { push @b, $_[0]->{seg} }
        },
        get_is => {
            direction => 'rightward',
            domain => 'DOM',
            where => sub { not ($_[1]->BOUNDARY || $_[-1]->BOUNDARY) },
            do => sub { push @i, $_[0]->{seg} }
        }
    );

    ok $rules->get_bs(\@word), 'domain: apply domain rule 1';
    ok $rules->get_is(\@word), 'domain: apply domain rule 2';
    is_deeply \@b, [ @word[0,2,3,6,7,8] ], 'domain: boundaries correct';
    is_deeply \@i, [ @word[1,4,5] ], 'domain: interiors correct';

    $rules->drop_rule('get_bs', 'get_is');
    $phono->features->drop_feature('DOM');
}

# Test tiers
{
    # We'll take the following word and make it into 3 segs:
    # 1: i, 2: ea, 3: oua
    my @word = $phono->symbols->segment(split //, 'iXeaXXouXa');
    $word[3]->vocoid($word[2]->value_ref('vocoid')); # join /a/ to /e/
    $word[7]->vocoid($word[6]->value_ref('vocoid')); # join /u/ to /o/
    $word[9]->vocoid($word[6]->value_ref('vocoid')); # join /a/ to /o/

    # Add a dummy feature for testing assignment
    $phono->features->add_feature(TIER => { type => 'privative' });

    # Write a rule to capture the pseudo-segs
    my @segs;
    $rules->add_rule(
        tiers => {
            tier => 'vocoid',
            direction => 'rightward',
            do => sub { push @segs, $_[0]->{seg}; $_[0]->TIER(1); }
        }
    );
    my @expected_segs = 
        map { Lingua::Phonology::Segment::Tier->new(@$_) } 
        ([$word[0]], [@word[2,3]], [@word[6,7,9]]);

    ok $rules->tiers(\@word), 'tiers: apply tier rule';
    is_deeply \@segs, \@expected_segs, 'tiers: segs selected';
    is_deeply [ map { scalar $_->vocoid } @segs ], [1,1,1], 'tiers: return value of tiered feature';
    is_deeply [ map { scalar $_->TIER } @segs ], [1,1,1], 'tiers: return value of assigned feature';
    is_deeply [ map { scalar $_->labial } @segs ], [undef, undef, undef], 'tiers: return value of non-common feature';

    $rules->drop_rule('tiers');
    $phono->features->drop_feature('TIER');
}

# Test filters
{
    my @word = $phono->symbols->segment(split //, 'baku');

    my @caught;
    $rules->add_rule(
        filters => {
            filter => sub { not $_[0]->vocoid },
            do => sub { push @caught, $_[0]->{seg} }
        }
    );
    ok $rules->filters(\@word), 'filters: apply filter rule';
    is_deeply \@caught, [ @word[0,2] ], 'filters: correct segments filtered';

    $rules->drop_rule('filters');
}

# Make sure INSERT_RIGHT, INSERT_LEFT, and delete work properly
{
    my @word = $phono->symbols->segment(split //, 'sk');

    $rules->add_rule(
        lefter => {
            where => sub { $_[0]->spell eq 's' },
            do => sub { $_[0]->INSERT_LEFT($phono->symbols->segment('a')) }
        },
        righter => {
            where => sub { $_[0]->spell eq 'k' },
            do => sub { $_[0]->INSERT_RIGHT($phono->symbols->segment('a')) }
        },
        dropper => {
            where => sub { $_[0]->spell eq 'k' && $_[-1]->spell eq 's' },
            do => sub { $_[0]->clear }
        }
    );

    $rules->lefter(\@word);
    is $phono->symbols->spell(@word), 'ask', 'INSERT_LEFT succeeds';
    $rules->righter(\@word);
    is $phono->symbols->spell(@word), 'aska', 'INSERT_RIGHT succeeds';
    $rules->dropper(\@word);
    is $phono->symbols->spell(@word), 'asa', 'delete succeeds';

    $rules->drop_rule('lefter', 'righter', 'dropper');
}


# where and do have been implicit in every rule so far, so we won't test them

# Test failure of apply()
{
    my @word = ();
    $rules->add_rule(test => {});
    ok((not $rules->apply('nonesuch', \@word)), 'failure of apply() on bad rule name');
    ok((not $rules->apply('test', 0)), 'failure of apply() on bad word');
    ok((not $rules->apply('test', [0,0,1,undef])), 'failure of apply() on bad segments');
    $rules->drop_rule('test');
}

# test persist
{   # fortunately, these don't have to be real rule names (is this a bug or a feature?)
    my @persist = ('one','two');
    ok $rules->persist(@persist), 'test persist';
    is_deeply [ $rules->persist ], \@persist, 'result of assignment to persist';
}

# test order
{
    my @order = (['a', 'b', 'c'], 'd', ['e', 'f']);
    ok $rules->order(@order), 'test order';
    is_deeply [ $rules->order ], [ $order[0], [$order[1]], $order[2] ], 'result of assignment to order';
}

# test apply_all, count
{
    my @word = $phono->symbols->segment(split //, 'pbtdkg');
    $rules->add_rule(
        flip => {
            do => sub { $_[0]->voice(not $_[0]->voice) }
        },
        flop => {
            do => sub { $_[0]->voice(not $_[0]->voice) }
        }
    );

    # Apply one rule, test count
    $rules->apply('flip', \@word);
    is $rules->count, scalar @word, 'count after apply';

    # Set up apply_all
    $rules->persist('flip');
    $rules->order('flop');
    ok $rules->apply_all(\@word), 'test apply_all';
    is_deeply $rules->count, { flip => 2*scalar @word, flop => scalar @word }, 'count after apply_all';

}
