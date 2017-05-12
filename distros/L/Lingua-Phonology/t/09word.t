#!/usr/bin/perl

use Test::More tests => 10;
use strict;
#use warnings; # Uncomment for debugging

use Lingua::Phonology;
use Lingua::Phonology::Word;

my $p = new Lingua::Phonology;
my $word = new Lingua::Phonology::Word;
$p->loadfile;

# set segs, get orig segs
{
    my @word = $p->symbols->segment(split //, 'kad');
    ok $word->set_segs(@word), 'set segs';
    is_deeply \@word, [ $word->get_orig_segs ], 'get orig segs';
}

# insert right
{
    my @word = $p->symbols->segment(split //, 'bam');
    $word->set_segs(@word);
    $word->next;
    my @working = $word->get_working_segs;
    $working[0]->INSERT_RIGHT($p->symbols->segment('r'));
    is $p->symbols->spell(($word->get_working_segs)[0..3]), 'bram', 'insert right';
}

# insert left
{
    my @word = $p->symbols->segment(split //, 'bam');
    $word->set_segs(@word);
    $word->next;
    my @working = $word->get_working_segs;
    $working[2]->INSERT_LEFT($p->symbols->segment('l'));
    is $p->symbols->spell(($word->get_working_segs)[0..3]), 'balm', 'insert right';
}

# delete
{
    my @word = $p->symbols->segment(split //, 'bard');
    $word->set_segs(@word);
    $word->next;
    my @working = $word->get_working_segs;
    $working[2]->DELETE;
    is $p->symbols->spell(($word->get_working_segs)[0..2]), 'bad', 'delete';
}

# insert at left bound
{
    my @word = $p->symbols->segment(split //, 'sos');
    $word->set_segs(@word);
    $word->next;
    my @working = $word->get_working_segs;
    $working[-1]->INSERT_LEFT($p->symbols->segment('a'));
    is $p->symbols->spell(($word->get_working_segs)[-1..2]), 'asos', 'insert at left bound';
}

# insert at right bound
{
    my @word = $p->symbols->segment(split //, 'sos');
    $word->set_segs(@word);
    $word->next;
    my @working = $word->get_working_segs;
    $working[-2]->INSERT_RIGHT($p->symbols->segment('a'));
    is $p->symbols->spell(($word->get_working_segs)[0..3]), 'sosa', 'insert at left bound';
}

# can't insert/delete, etc. with tier
{
    my @word = $p->symbols->segment(split //, 'banana');
    $word->tier('vocoid');
    $word->set_segs(@word);
    $word->next;
    my @working = $word->get_working_segs;
    my $ins = $p->symbols->segment('a');
    ok !$working[1]->INSERT_RIGHT($ins), 'cant insert right';
    ok !$working[1]->INSERT_LEFT($ins), 'cant insert left';
    ok !$working[1]->DELETE($ins), 'cant delete';
}
