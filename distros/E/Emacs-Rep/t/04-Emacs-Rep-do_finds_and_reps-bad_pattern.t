# A perl test file, which can be run like so:
#   perl 04-Emacs-Rep-do_finds_and_reps-bad_pattern.t
#                     doom@kzsu.stanford.edu     2010/05/14 01:41:59

use warnings;
use strict;
$|=1;
my $DEBUG = 0;             # TODO set to 0 before ship
use Data::Dumper;

use Test::More;
BEGIN { plan tests => 4 };
use Test::Trap;

use FindBin qw( $Bin );
use lib "$Bin/../lib";

my $module;
BEGIN {
  $module = 'Emacs::Rep';
  use_ok( $module, ':all' );
}


my $perl_code_example=<<'PERL_CODE';
#.../usr/bin/perl
# trial_for_rep.pl                   doom@kzsu.stanford.edu
#                                    01 Jun 2010

my $argy  = shift;
my $bargy = shift;

if( $argy =~ m{ $bargy }xms ) {
  print $&, "\n"; # TODO needs improvement...
}
# Now what?  Bug that human one cube over. TODO.

my $temper ="<<END_T";
  Hello [% planet %]
END_T
print $temper, "\n";
PERL_CODE

{ my $test_name = "Testing do_finds_and_reps with bad pattern";

  my $text = $perl_code_example;

# Note below, a find pattern with a missing escape on an open square bracket
  my $substitutions=<<'END_S';
# Enter s///g lines /e not allowed /g assumed, 'C-x #' applies to other window
s/sucks/needs improvement/g;
s/!/.../g;
s/the jerk/that human/g;
s/[%/<%/g;
s/%\]/%>/g;
END_S

  my $find_replaces_aref =
    parse_perl_substitutions( \$substitutions );

  my $locs;
  my @r = trap {
    $locs =
      do_finds_and_reps( \$text, $find_replaces_aref );
  };

  ($DEBUG) && print "locs: ", Dumper( $locs );

  my $expected_return_pat= qr{^\QProblem: Unmatched [ in regex; marked by <-- HERE in m/[\E};
  like ( $trap->stdout, $expected_return_pat, "$test_name: errmess to STDOUT" );

  my $expected_locs = [];
  is_deeply( $locs, $expected_locs,
             "$test_name: no locations reported" );

  my $expected_text = $text;

  is( $text, $expected_text,
             "$test_name: rollback happened" );

}

### end main, into the subs
