# Test file created outside of h2xs framework.
# Run this like so: `perl 05-Emacs-Rep-do_finds_and_reps-problem_case.t'
#   doom@kzsu.stanford.edu     2010/06/06 21:26:18

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { plan tests => 4 };
use Test::Differences;
my $DEBUG = 0;
use warnings;
use strict;
$|=1;
use Data::Dumper;
use FindBin qw( $Bin );
use lib "$Bin/../lib";
my $module;
BEGIN {
  $module = 'Emacs::Rep';
  use_ok( $module, ':all' );
}

my $PERL_CODE_EXAMPLE=<<'PERL_CODE';
#!/usr/bin/perl
my $argy  = shift;
my $bargy = shift;
if( $argy =~ m{ $bargy }xms ) {
  print $&, "\n"; # TODO sucks!
} # Now what?  Bug the jerk one cube over. TODO.

my $temper ="<<END_T";
  Hello [% planet %]
END_T
print $temper, "\n";
PERL_CODE

ok(1, "If we made it this far, we're ok. All modules are loaded.");

my $case_name = 'problem case 1';

{
  my $test_name = "do_finds_and_reps $case_name";

  my $text = $PERL_CODE_EXAMPLE;

  my $substitutions=<<'END_S';
# Enter s///g lines /e not allowed /g assumed, 'C-x #' applies to other window
s/argy/arg/g;
s/shift;/XXXXXXXXXXXXXXXXXX/g;
END_S

  my $find_replaces_aref =
    parse_perl_substitutions( \$substitutions );

  ($DEBUG) && print STDERR Dumper( $find_replaces_aref ), "\n";

  my $metadata =
    do_finds_and_reps( \$text, $find_replaces_aref );

  ($DEBUG) && print STDERR "after change:", $text, "\n";

  my $expected_text =<<'__PERL_MUNGED';
#!/usr/bin/perl
my $arg  = XXXXXXXXXXXXXXXXXX
my $barg = XXXXXXXXXXXXXXXXXX
if( $arg =~ m{ $barg }xms ) {
  print $&, "\n"; # TODO sucks!
} # Now what?  Bug the jerk one cube over. TODO.

my $temper ="<<END_T";
  Hello [% planet %]
END_T
print $temper, "\n";
__PERL_MUNGED

  is( $text, $expected_text, "$test_name: modifications look good");

  ($DEBUG) && print STDERR Dumper( $metadata ), "\n";

  my $expected = define_expected_metadata();

  eq_or_diff( $metadata, $expected, "$test_name" );
}

sub define_expected_metadata {
  my $metadata =
    [
          [
            {
              'beg' => 21,
              'delta' => -1,
              'orig' => 'argy',
              'rep' => 'arg'
            },
            {
              'beg' => 41,
              'delta' => -1,
              'orig' => 'argy',
              'rep' => 'arg'
            },
            {
              'beg' => 60,
              'delta' => -1,
              'orig' => 'argy',
              'rep' => 'arg'
            },
            {
              'beg' => 73,
              'delta' => -1,
              'orig' => 'argy',
              'rep' => 'arg'
            }
          ],
          [
            {
              'beg' => 28,
              'delta' => 12,
              'orig' => 'shift;',
              'rep' => 'XXXXXXXXXXXXXXXXXX'
            },
            {
              'beg' => 46,
              'delta' => 12,
              'orig' => 'shift;',
              'rep' => 'XXXXXXXXXXXXXXXXXX'
            }
          ]
        ];

  return $metadata;
}

