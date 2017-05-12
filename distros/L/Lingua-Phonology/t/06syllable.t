#!/usr/bin/perl

# Syllabification testing script

use strict;
use warnings;
use Test::More tests => 56;
use Lingua::Phonology;

BEGIN {
	use_ok('Lingua::Phonology::Syllable');
}
# Comment out for debugging
no warnings 'Lingua::Phonology::Syllable';

# new as a class method
ok my $syll = new Lingua::Phonology::Syllable, 'new as a class method';

# new as an object method
ok my $other_syll = $syll->new, 'new as an object method';

# simple test of return values for boolean methods
for ('onset', 'complex_onset','coda','complex_coda') {
	ok $syll->$_(1), "test assign true to $_";
	is $syll->$_, 1, "test result of $_(1)";
	ok !$syll->$_(0), "test assign false to $_";
	is $syll->$_, 0, "test result of $_(0)";
	my $method = 'set_' . $_;
	ok $syll->$method, "test $method";
	is $syll->$_, 1, "test result of $method";
	$method = 'no_' . $_;
	ok !$syll->$method, "test $method";
	is $syll->$_, 0, "test result of $method";

	# Put things back how you found them.
	$syll->$_(0);
}

# Prepare the test materials
my $phono = new Lingua::Phonology;
$phono->features->loadfile;
$phono->symbols->loadfile;
my @word = $phono->symbols->segment(split(//, 'skraduipnts'));

# syllabify() is used repeatedly from here on out, but we'll only check it
# once. We'll also not bother to recheck the okayness of the boolean methods
# (but we will check the others).

# default CV syllables.
$syll->set_onset;
ok $syll->syllabify(@word), 'test syllabify';
is spell_syll(@word), 'sk<ra><du><i>pnts', 'test CV syllabification';

# no onsets, only V syllables
$syll->no_onset;
$syll->syllabify(@word);
is spell_syll(@word), 'skr<a>d<u><i>pnts', 'test V syllabification';
$syll->set_onset;

# Complex onsets allowed
$syll->set_complex_onset;
$syll->syllabify(@word);
is spell_syll(@word), 's<kra><du><i>pnts', 'test syllabification with complex onsets';

# Codas allowed
$syll->set_coda;
$syll->syllabify(@word);
is spell_syll(@word), 's<kra><duj>pnts', 'test syllabification with codas';

# Complex codas allowed
$syll->set_complex_coda;
$syll->syllabify(@word);
is spell_syll(@word), 's<kra><dujp>nts', 'test syllabification with complex codas';

# Same, with R->L syllabification
ok $syll->direction('leftward'), 'test set direction';
$syll->syllabify(@word);
is spell_syll(@word), 's<kra><dwip>nts', 'test syllabification with direction set';

# Allow syllabic nasals (decrease min_nucl_son)
ok $syll->min_nucl_son(1), 'set min_nucl_son';
$syll->syllabify(@word);
is spell_syll(@word), 's<kra><dwi><pnt>s', 'syllabify with min_nucl_son';

# Force all Vs to be nuclei
ok $syll->max_edge_son(2), 'set max_edge_son';
$syll->syllabify(@word);
is spell_syll(@word), 's<kra><du><i><pnt>s', 'syllabify with max_edge_son';

# End-adjoin coronals
ok $syll->end_adjoin(sub { $_[0]->Coronal }), 'set end_adjoin';
$syll->syllabify(@word);
is spell_syll(@word), 's<kra><du><i><pnts>', 'syllabify with end_adjoin';

# Begin-adjoin coronal continuants
ok $syll->begin_adjoin(sub { $_[0]->Coronal && $_[0]->continuant }), 'set begin_adjoin';
$syll->syllabify(@word);
is spell_syll(@word), '<skra><du><i><pnts>', 'syllabify with begin_adjoin';

# Sonorous - make voice count for sonority (just for test purposes)
ok $syll->sonorous->{voice} = 1, 'assign to sonorous()';
is $syll->sonority($word[4]), 1, 'test sonority after sonorous()';
my $fail = 0;
ok ((not $syll->sonorous($fail)), 'test failure of sonority()');

# clear seg
# prepare - turn these off. Now the first seg can't be syllabified--but setting
# clear_seg() to an always-false function prevents resyllabification, so the
# first seg should remain syllabified.
$syll->no_coda;
$syll->no_complex_onset;
ok $syll->clear_seg(sub {0}), 'assign to clear_seg';
$syll->syllabify(@word);
ok $word[0]->SYLL, 'syllabify after clear_seg';

# This nifty function takes a word and spells it via syllables
# perhaps this should actually be part of the Syllable package?
sub spell_syll {
	my $return = '';
	for (my $i=0; $i<=$#_; $i++) {
		$return .= '<' if ($_[$i]->SYLL && (not $_[$i]->coda) && ($i == 0 || not $_[$i - 1]->onset));
		$return .= $phono->symbols->spell($_[$i]);
		$return .= '>' if ($_[$i]->Rime && ($i == $#_ || not $_[$i + 1]->coda));
	}
	return $return;
}
