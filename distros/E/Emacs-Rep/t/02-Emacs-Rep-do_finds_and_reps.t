# A perl test file, which can be run like so:
#   perl 02-Emacs-Rep-do_finds_and_reps.t
#                     doom@kzsu.stanford.edu     2010/05/14 01:41:59

use warnings;
use strict;
$|=1;
my $DEBUG = 0;             # TODO set to 0 before ship
use Data::Dumper;

use Test::More;
BEGIN { plan tests => 3 };

use FindBin qw( $Bin );
use lib "$Bin/../lib";

my $module;
BEGIN {
  $module = 'Emacs::Rep';
  use_ok( $module, ':all' );
}

{ my $test_name = "Testing do_finds_and_reps";
  my $substitutions = define_substitution_cases( 'first' );

  my $find_reps =
    parse_perl_substitutions( \$substitutions );

  ($DEBUG) && print Dumper( $find_reps );

  my $text = define_text( 'main_text' );

  my $locs =
        do_finds_and_reps( \$text, $find_reps );

  ($DEBUG) && print Dumper( $locs );
  ($DEBUG) && print Dumper( $text );

  my $expected = define_expected_locs( 'first' );

  is_deeply( $locs, $expected,
             "$test_name -- metadata: first case" );

  my $expected_text = define_expected_text( 'first' );
  is( $text, $expected_text,
             "$test_name -- text: first case" );

# Dropping test of deprecated routine:
#   my $report = serialize_change_metadata( $locs );
#   ($DEBUG) && print "report:\n$report\n";

# my $expected_report=<<"EXPECTORANT";
# 0:622:630:2:stocky;
# 1:632:640:2:square;
# 2:605:608:-7:individual;
# EXPECTORANT

# # was:
# # 2:594:597:-7:individual

#   is( $report, $expected_report, "Testing serialize_change_metadata" );
}


### end main, into the subs

=item define_substitution_cases

=cut

sub define_substitution_cases {
  my $type = shift;

  my $first_substitutions=<<'END_S';
   s/stocky/stockish/;
   s/square/squarish/;
   s|individual|MAN|;
END_S

  my $second_substitutions=<<'END_S2';
   s/cars/bikes/;
   s/evening/women's/;
   s/midnight/midnightMIDNIGHTmidnight/;
   s|MIDNIGHTmidnight| (midnacht!)|;
END_S2

# Go for lots of scattered little changes
  my $third_substitutions=<<'END_S3';
   s/cars/bikes/;
   s/of/OVER-THERE/;
   s/\. /. And it was all DOOMED. /;
   s/evening/women's/;
   s/cane/vibrator/;
   s/\bin/skin/;
   s|CHAPTER|Chapped|;
END_S3

# munging strings with semi-colons
  my $fourth_substitutions=<<'END_S3';
   s/individual; the/individual!; --The/g;
END_S3


  my $cases =
    {
     first  => $first_substitutions,
     second => $second_substitutions,
     third  => $third_substitutions,
     fourth => $fourth_substitutions,
      };

  my $substitutions = $cases->{ $type };
  $substitutions
}


=item define_text

=cut

sub define_text {
  my $type = shift;

  my $first_text=<<'END_S';
     CHAPTER I

     FOOTSTEPS TO CRIME

     IT was midnight. From the brilliance of one of Washington's broad avenues,
the lights of a large embassy building could be seen glowing upon the sidewalks
of the street on which it fronted.
     Parked cars lined the side street. One by one they were moving from their
places, edging to the space in front of the embassy, where departing guests
were ready to leave. An important social event was coming to its close.
     The broad steps of the embassy were plainly lighted. Upon them appeared
two men dressed in evening clothes. One was a tall, gray-haired individual; the
other a stocky, square-faced man who leaned heavily upon a stout cane as he
descended the steps. The two men paused as they reached the sidewalk.
END_S

  my $texts =
    {
     main_text => $first_text,
      };

  my $substitutions = $texts->{ $type };
  $substitutions
}


### TODO only the NON-*_revised below are used here, correct?
### The *_revised are now used by 06-*.t
### (a) could trim this down
### (b) could move test cases to a joint library file



=item define_expected_locs

=cut

sub define_expected_locs {
  my $type = shift;

  my $expected =
    {
     'first'
     => [
         [
          {
              'beg' => 629,
              'delta' => 2,
              'orig' => 'stocky',
              'rep' => 'stockish'
            }
          ],
          [
            {
              'beg' => 639,
              'delta' => 2,
              'orig' => 'square',
              'rep' => 'squarish'
            }
          ],
          [
            {
              'beg' => 605,
              'delta' => -7,
              'orig' => 'individual',
              'rep' => 'MAN'
            }
          ]
        ]
    };

  my $ret = $expected->{ $type };
  return $ret;
}




=item define_expected_text

=cut

sub define_expected_text {
  my $type = shift;

  my $expected =
    {
     'first' =>
     '     CHAPTER I

     FOOTSTEPS TO CRIME

     IT was midnight. From the brilliance of one of Washington\'s broad avenues,
the lights of a large embassy building could be seen glowing upon the sidewalks
of the street on which it fronted.
     Parked cars lined the side street. One by one they were moving from their
places, edging to the space in front of the embassy, where departing guests
were ready to leave. An important social event was coming to its close.
     The broad steps of the embassy were plainly lighted. Upon them appeared
two men dressed in evening clothes. One was a tall, gray-haired MAN; the
other a stockish, squarish-faced man who leaned heavily upon a stout cane as he
descended the steps. The two men paused as they reached the sidewalk.
',
      };


  my $ret = $expected->{ $type };
  return $ret;
}

