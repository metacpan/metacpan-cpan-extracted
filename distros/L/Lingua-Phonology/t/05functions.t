#!/usr/bin/perl

use strict;
use warnings;
use Lingua::Phonology;
use Test::More tests=>36;

# use
eval {
	use Lingua::Phonology::Functions qw/:all/;
	pass('use Lingua::Phonology::Functions'); # will pass if use is okay
};
# Comment out for debugging
no warnings 'Lingua::Phonology::Functions';

# Prepare the test materials (a lot of them)
# basic features and symbol sets
my $phono = new Lingua::Phonology;
$phono->features->loadfile;
$phono->symbols->loadfile;
# drop these symbols to avoid having to syllabify
$phono->symbols->drop_symbol('j'); 
$phono->symbols->drop_symbol('w');

# bad segments to use in failure testing
my $notseg = {};
my $bound = Lingua::Phonology::Segment::Boundary->new();

my @word = $phono->symbols->segment(split //, 'bkinimo');

# assimilate
ok assimilate('voice', $word[0], $word[1]), 'test assimilate()';
is $word[1]->value_ref('voice'), $word[0]->value_ref('voice'), 'test results of assimilate()';
ok((not assimilate('voice', $word[0], $notseg)), 'test failure of assimilate() on non-segment');

# flat assimilate
$word[3]->ROOT(1);
ok flat_assimilate('ROOT', $word[3], $word[4]), 'test flat_assimilate';
is $word[3]->value_ref('ROOT'), $word[4]->value_ref('ROOT'), 'test result of flat_assimilate';
isnt $word[3]->nasal, $word[4]->nasal, 'test child feature is unchanged';
ok((not flat_assimilate('ROOT', $word[4], $notseg)), 'test failure of flat_assimilate() on non-segment');

# copy
ok copy('aperture', $word[6], $word[4]), 'test copy()';
is $word[4]->aperture, $word[6]->aperture, 'test results of copy()';
ok((not copy('aperture', $word[1], $notseg)), 'test failure of copy() on non-segment');

# flat copy
ok flat_copy('ROOT', $word[3], $word[2]), 'test flat_copy';
is $word[3]->value('ROOT'), $word[2]->value('ROOT'), 'test result of flat_copy';
isnt $word[3]->nasal, $word[2]->nasal, 'test child feature is unchanged';
ok((not flat_copy('ROOT', $word[2], $notseg)), 'test failure of flat_copy() on non-segment');

# dissimilate
ok((not dissimilate('nasal', $word[3], $word[5])), 'test dissimilate()');
ok((not $word[5]->nasal), 'test results of dissimilate()');
ok((not dissimilate('nasal', $word[3], $notseg)), 'test failure of dissimilate() on non-segment');

# change
ok(change($word[3], 's'), 'test change()');
is($word[3]->spell, 's', 'test result of change()');
ok((not change($notseg, 's')), 'test failure of change() on non-segment');

# Make a real rules object for the following tests, which don't make sense
# outside of Rules

my $rules = $phono->rules;

{
    $rules->add_rule(
        meta => { 
            do => sub { ok metathesize($_[0], $_[1]), 'test metathesize()' }, 
            where => sub { $_[-1]->BOUNDARY }
        }
    );
    
    # segment metathesize
    $rules->meta(\@word);
    is $word[0]->spell . $word[1]->spell, 'gb', 'test results of metathesize()';
    ok((not metathesize($word[0], $notseg)), 'test failure of metathesize() on non-segment');
    $rules->drop_rule('meta');
}

{
    $rules->add_rule(
        meta_feature => {
            where => sub { $_[-1]->BOUNDARY },
            do => sub { ok metathesize_feature('labial', $_[1], $_[0]), 'test metathesize_feature()'; }
        }
    );

    $rules->meta_feature(\@word);
    ok(($word[0]->labial && not $word[1]->labial), 'test results of metathesize_feature()');
    ok((not metathesize_feature('labial', $word[4], $notseg)), 'test failure of metathesize_feature() on non-segment');
}

# delete segments
{
    $rules->add_rule(
        del => {
            where => sub {$_[1]->BOUNDARY},
            do => sub { ok delete_seg($_[0]), 'test delete_seg()'; }
        }
    );
    my @word = $phono->symbols->segment(split //, 'kad');

    $rules->del(\@word);
    is($phono->symbols->spell(@word), 'ka', 'test result of delete_seg()');
    ok((not delete_seg($notseg)), 'test failure of delete_seg() on non-segment');
}

# insert before
{
    $rules->add_rule(
        lefter => {
            where => sub { $_[0]->spell eq 'd' },
            do => sub { ok insert_before($_[0], $phono->symbols->segment('@')), 'test insert_before()'; }
        }
    );
    my @word = $phono->symbols->segment('d');

    $rules->lefter(\@word);
    is $phono->symbols->spell(@word), '@d', 'test result of insert_before()';
    ok((not insert_before($notseg, $phono->symbols->segment('@'))), 'test failure of insert_before() on non-segment');
}

# insert after
{
    $rules->add_rule(
        righter => {
            where => sub { $_[0]->spell eq 'd' },
            do => sub { ok insert_after($_[0], $phono->symbols->segment('@')), 'test insert_before()'; }
        }
    );
    my @word = $phono->symbols->segment('d');

    $rules->righter(\@word);
    is $phono->symbols->spell(@word), 'd@', 'test result of insert_before()';
    ok((not insert_after($notseg, $word[0]->duplicate)), 'test failure of insert_after() on non-segment');
}

