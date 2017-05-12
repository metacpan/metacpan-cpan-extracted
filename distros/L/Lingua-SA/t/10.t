#!/usr/bin/perl -Tw

use Carp;
use English qw{-no_match_vars};

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 2.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More tests => 4;
use Test::More 'no_plan';
#BEGIN { use_ok('Lingua::SA') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Lingua::SA qw(vibhakti);
my %naam = (
	'1'		=> "raama", 
	);

my %linga = (
	'1'		=> "puM", 
	);

my %vibhakti = (
	'1'		=> "prathamaa", 
	);

my %vachana = (
	'1'		=> "ekavachana", 
	);

my %vibhakti_of = (
	'1'		=> "rAm + aH", 
	);

for my $word (keys  %naam){
	my $expected = $vibhakti_of{$word};
	my $computed = vibhakti({naam=>$naam{$word}, linga=>$linga{$word},
		vibhakti=>$vibhakti{$word}, vachana=>$vachana{$word}});

	# Test expected and computed transliteration for word equality
	is( $computed, $expected, $expected );
	}
#########################
# Input argument errors
	my $word = 1;
	eval { 
		my $computed = vibhakti({naama=>$naam{$word}, linga=>$linga{$word},
		vibhakti=>$vibhakti{$word}, vachana=>$vachana{$word}}); 
		};
	like($EVAL_ERROR,'/Argument naam/','naam not passed');
	eval { 
		my $computed = vibhakti({naam=>$naam{$word}, lingaa=>$linga{$word},
		vibhakti=>$vibhakti{$word}, vachana=>$vachana{$word}}); 
		};
	like($EVAL_ERROR,'/Argument linga/','lingaa not passed');
	eval { 
		my $computed = vibhakti({naam=>$naam{$word}, linga=>$linga{$word},
		vibhaktia=>$vibhakti{$word}, vachana=>$vachana{$word}}); 
		};
	like($EVAL_ERROR,'/Argument vibhakti/','vibhakti not passed');
	eval { 
		my $computed = vibhakti({naam=>$naam{$word}, linga=>$linga{$word},
		vibhakti=>$vibhakti{$word}, vachanaa=>$vachana{$word}}); 
		};
	like($EVAL_ERROR,'/Argument vachana/','vachana not passed');


#	unsupported "type" errors
	eval { 
		my $computed = vibhakti({naam=>"naag", linga=>$linga{$word},
		vibhakti=>$vibhakti{$word}, vachana=>$vachana{$word}}); 
		};
	like($EVAL_ERROR,'/Unsupported noun/','naam ending invalid');
	eval { 
		my $computed = vibhakti({naam=>$naam{$word}, linga=>"arbit_linga",
		vibhakti=>$vibhakti{$word}, vachana=>$vachana{$word}}); 
		};
	like($EVAL_ERROR,'/Invalid linga/','invalid linga');
	eval { 
		my $computed = vibhakti({naam=>$naam{$word}, linga=>$linga{$word},
		vibhakti=>"arbit_vibhakti", vachana=>$vachana{$word}}); 
		};
	like($EVAL_ERROR,'/Invalid vibhakti/','invalid vibhakti');
	eval { 
		my $computed = vibhakti({naam=>$naam{$word}, linga=>$linga{$word},
		vibhakti=>$vibhakti{$word}, vachana=>"arbit_vachana"}); 
		};
	like($EVAL_ERROR,'/Invalid vachana/','invalid vachana');

#	Unsupported linga-aakaar error (ending coef not defined)
	eval { 
		my $computed = vibhakti({naam=>'ramA', linga=>'napuMsaka',
		vibhakti=>$vibhakti{$word}, vachana=>$vachana{$word}}); 
		};
	like($EVAL_ERROR,'/nouns ending in/','invalid linga-ending');
