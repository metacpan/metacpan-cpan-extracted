# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test; #tests => 5;
BEGIN { plan tests => 9 };
use Lingua::FeatureMatrix;
ok(1,1,"loading Lingua::FeatureMatrix");

#########################

use lib 'examples';
use Phone;
ok(1,1, "loading examples/Phone");

use Letter;
ok(1,1, "loading examples/Letter");

#warn "loading examples/phonematrix.dat...\n";
my $matrix =
  Lingua::FeatureMatrix->new(eme => 'Phone',
			     file => 'examples/phonematrix.dat',
			    );

ok(defined $matrix, 1,
   "building a Lingua::FeatureMatrix of Phones");

ok($matrix->isa('Lingua::FeatureMatrix'), 1,
   "checking type of Lingua::FeatureMatrix object\n");

my $sibilants =
  join(' ', sort $matrix->listFeatureClassMembers('SIBILANT'));
# warn "sibilants are: $sibilants\n";
ok($sibilants, 'CH J S SH Z ZH', "sibilants");

my $affricates =
  join(' ', sort $matrix->listFeatureClassMembers('AFF'));
# warn "affricates are: $affricates\n";
ok($affricates, 'CH J', "affricates");


# BUILD LETTER TEST CASES

my $matrix2 =
  Lingua::FeatureMatrix->new(eme=>'Letter',
			     file => 'examples/lettermatrix.dat',
			    );
ok(defined $matrix2, 1,
   "building a Lingua::FeatureMatrix of Letters");

my $widechars =
  join(' ', sort $matrix2->listFeatureClassMembers('WIDE'));
ok($widechars, 'Y m p q', "widechars"); # current test data

# use Graph::Writer::Dot;
# my $writer = Graph::Writer::Dot->new();
# $writer->write_graph($matrix2->implicature_graph, 'implicatures.dot');
# system ('dot', '-Tgif', '-o', 'implicatures.gif', 'implicatures.dot');
