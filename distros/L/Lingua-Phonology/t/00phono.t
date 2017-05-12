#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 15;
use Carp;

# Test 1
# Load the module
use_ok('Lingua::Phonology');

# test 2
# new() as class method
my $phono = new Lingua::Phonology;
ok(UNIVERSAL::isa($phono, 'Lingua::Phonology'), 'new() as a class method');

# test 3
# as an object method
my $nother = $phono->new();
ok(UNIVERSAL::isa($phono, 'Lingua::Phonology'), 'new() as an object method');

# tests 4 through (3 + 2*(keys %methods))
# test the get/set sub-objects
# methods to test in method => class sets
my %methods = ( 
	features => 'Lingua::Phonology::Features',
	symbols => 'Lingua::Phonology::Symbols',
	rules => 'Lingua::Phonology::Rules',
	syllable => 'Lingua::Phonology::Syllable',
);
for (keys %methods) {
	# Test that the methods fetch the correct objects
	my $test = $phono->$_;
	ok(UNIVERSAL::isa($test, $methods{$_}), "get $_");

	# test that the methods set the correct objects
	my $other_test = $nother->$_;
	$phono->$_($other_test);
	is($phono->$_, $nother->$_, "set $_");
} # end for

# test getting segments
my $test = $phono->segment;
ok(UNIVERSAL::isa($test, 'Lingua::Phonology::Segment'), "get segment");

# test equivalencies btwn sub-objects
# start with a new object
$phono = new Lingua::Phonology;
is($phono->symbols->features, $phono->features, 'dependency btwn features and symbols');
is($phono->segment->featureset, $phono->features, 'dependency btwn features and segment');
is($phono->segment->symbolset, $phono->symbols, 'dependency btwn symbols and segment');

=begin

# Test 2, make sure you can load default features
eval {
	require Lingua::Phonology::Features;
	$features = new Lingua::Phonology::Features or die 'failure on test 2\n';
	$features->loadfile or die 'failure on test 2\n';
	return 1;
};
ok($@, '');

# Test 3, make sure you can load default symbols
eval {
	require Lingua::Phonology::Symbols;
	$symbols = Lingua::Phonology::Symbols->new($features) or die 'failure on test 3\n';
	$symbols->loadfile or die 'failure on test 3\n';
	return 1;
};
ok($@, '');

# Test 4, add a simple rule
eval {
	require Lingua::Phonology::Rules;
	$rules = new Lingua::Phonology::Rules;
	$rules->add_rule( Devoice => { where => sub { $_[1]->BOUNDARY },
	                               do => sub { $_[0]->voice(0) }})
	or die 'failure on test 4\n';
	return 1;
};
ok($@, '');

# Test 5 apply the simple rule
eval {
	@word = $symbols->segment('b','a','n','d');
	$rules->Devoice(\@word);
	return 1
};
ok(join('', $symbols->spell(@word)), 'bant');

# Test 6: apply a set of rules with several advanced features
# This lasts from here to the end of the script

@word = $symbols->segment('b', 'o', 'n', 'i', 'n', 'a', 'n');

$rules->add_rule(Redundancy => {do => \&redundancy});
$rules->add_rule(Nucleus => { where =>	sub { sonority($_[0]) > sonority($_[1])
										&& sonority($_[0]) > sonority($_[-1]) },
								do => sub { $_[0]->nucleus(1) }});

# Assign syllable onsets
$onset_if = sub {
	($_[1]->nucleus && not $_[0]->nucleus) || 
	(((sonority($_[1]) - sonority($_[0])) > 1) && ($_[1]->onset)) 
};
$onset = sub {
	$_[0]->onset(1); 
	adjoin('SYLL', $_[1], $_[0]);
};
$rules->add_rule(Onset => { where => $onset_if, do => $onset });

# Assign syllable codas
$coda_if = sub { $_[-1]->nucleus && not $_[0]->SYLL };
$coda = sub {
	$_[0]->coda(1);
	adjoin('SYLL', $_[-1], $_[0]);
};
$rules->add_rule(Coda => { where => $coda_if, do => $coda });

# Do some vowel assimilation and test tiers
$harmony_if = sub { $_[1]->aperture eq 0 };
$harmony = sub { adjoin('aperture', $_[1], $_[0]) };
$rules->add_rule(HeightHarmony => { tier => 'aperture',
									 direction => 'rightward',
									 where => $harmony_if,
									 do => $harmony
									 });

# A more vigorous tier test
$lower_if = sub { $_[1]->BOUNDARY };
$lower = sub { $_[0]->aperture( $_[0]->aperture + 1 ) };
$rules->add_rule(FinalLowering => { tier => 'aperture',
									 where => $lower_if,
									 do => $lower
									 });

# Do some nasal dissimilation and test domains
$dissim_if = sub { $_[0]->nasal eq $_[1]->nasal };
$dissim = sub { $_[0]->delink('nasal') };
$rules->add_rule( NasalDissimilation => { tier => 'nasal',
										   domain => 'SYLL',
										   direction => 'rightward',
										   where => $dissim_if,
										   do => $dissim
										   });

# What happens if we delete stuff?
$delete_if = sub {$_[1]->BOUNDARY};
$delete = sub {$_[0]->clear};
$rules->add_rule(Deletion => {where => $delete_if, do => $delete, tier => 'vocoid'});

# Now insert stuff
$insert_if = sub {(not $_[-1]->nucleus) && $_[0]->coda};
$insert = sub {$_[0]->INSERT_RIGHT($symbols->segment('@'))};
$rules->add_rule(Insertion => {where => $insert_if, do => $insert});

$rules->persist('Redundancy');
$rules->order('Nucleus', 'Onset', 'Coda', 'HeightHarmony', 'FinalLowering', 'NasalDissimilation', 'Deletion', 'Insertion');
$rules->apply_all(\@word);

ok(join('', $symbols->spell(@word)), 'bunidn@');

sub redundancy {
	my $seg = $_[0];

	# Sonority stuff
	$seg->approximant(1) if ($seg->vocoid);
	$seg->approximant(1) if ($seg->lateral);
	$seg->sonorant(1) if ($seg->approximant);
	$seg->sonorant(1) if ($seg->nasal);
	$seg->voice(1) if $seg->sonorant;
	$seg->aperture(2) if $seg->aperture > 2;

	# Syllable stuff
	$seg->Rime(1) if ($seg->nucleus and not $seg->Rime);
	$seg->SYLL(1) if ($seg->Rime and not $seg->SYLL);
	$seg->SYLL(1) if ($seg->onset and not $seg->SYLL);

#	print $symbols->spell(@_), "\n";
} # end redundancy

sub sonority {
	$seg = shift;

	my $son = 0;
	$son++ if $seg->sonorant;
	$son++ if $seg->vocoid;
	$son++ if $seg->approximant;
	$son = $son + $seg->aperture;
	return $son;
} # end sonority

sub adjoin {
	my $feature = shift;
	my $seg1 = shift;
	my $seg2 = shift;

	$seg2->value_ref($feature, $seg1->value_ref($feature));
} # end join

=cut
