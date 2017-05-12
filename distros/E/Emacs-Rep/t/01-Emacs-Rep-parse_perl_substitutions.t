# A perl test file, which can be run like so:
#   `perl 01-Emacs-Rep.t'
#         doom@kzsu.stanford.edu     2010/05/14 01:41:59

use warnings;
use strict;
$|=1;
my $DEBUG = 0;             # TODO set to 0 before ship
use Data::Dumper;

use Test::More;
BEGIN { plan tests => 2 }; # TODO revise test count

use FindBin qw( $Bin );
use lib "$Bin/../lib";

my $module;
BEGIN {
  $module = 'Emacs::Rep';
  use_ok( $module, ':all' );
}

{ my $test_name = "Testing parse_perl_substitutions";
  my $substitutions = define_substitution_cases('simple');

  my $find_reps =
    parse_perl_substitutions( \$substitutions );

  ($DEBUG) && print Dumper( $find_reps );

  my $expected_simple = define_expected( 'simple' );
  is_deeply( $find_reps, $expected_simple,
             "$test_name: simple (quote delim) cases" );
}

### end main, into the subs

=item define_substitution_cases

=cut

sub define_substitution_cases {
  my $type = shift;

  my $simple_substitutions=<<'END_S';
   s|bupkes|nada|;
   s/alpha/ralpha/;
   s/aaa/XXX/i;
   s/ bogus /lame/x;
   s|/usr/bin|/usr/local/bin|;
   s/JOKE/\/bin\/laden/;
   s/\/bin\/laden/<stale humor alert>/;
   s/by, the, way/by the way/;
   s|kirk\|spock /|yoda\|wookie /|i;
   s^crummy buttons^spinach^;
   s"stork"raven"ms;
   s/\bgreen\b/mauve/g;
   s/Login: $foo/Login: $bar/; # run-time pattern
   s/Mister\b/Mr./g;
   s/\d+/$&*2/e;               # yields abc246xyz
   s/\d+/sprintf("%5d",$&)/e;  # yields abc  246xyz
   s/\w/$& x 2/eg;             # yields aabbcc  224466xxyyzz
   s/%(.)/$percent{$1}/g;      # change percent escapes; no /e
   s/^\s*(.*?)\s*$/$1/;        # trim whitespace in $_, expensively
   s/^\s+//;
   s/\s+$//;
   s/([^ ]*) *([^ ]*)/$2 $1/;  # reverse 1st two fields

END_S

  my $cases =
    {
     simple => $simple_substitutions,
      };

  my $substitutions = $cases->{ $type };
  $substitutions
}

=item define_expected

=cut

sub define_expected {
  my $type = shift;

my $expected_simple = [
    [ 'bupkes',           'nada' ],
    [ 'alpha',            'ralpha' ],
    [ '(?i)aaa',          'XXX' ],
    [ '(?x) bogus ',      'lame' ],
    [ '/usr/bin',         '/usr/local/bin' ],
    [ 'JOKE',             '\/bin\/laden' ],
    [ '\/bin\/laden',       '<stale humor alert>' ],
    [ 'by, the, way',     'by the way' ],
    [ '(?i)kirk\|spock /', 'yoda\|wookie /' ],
    [ 'crummy buttons',   'spinach' ],
    [ '(?ms)stork',       'raven' ],
    [ '\\bgreen\\b',      'mauve' ],
    [ 'Login: $foo',      'Login: $bar' ],
    [ 'Mister\\b',        'Mr.' ],
    [ '\\d+',             '$&*2' ],
    [ '\\d+',             'sprintf("%5d",$&)' ],
    [ '\\w',              '$& x 2' ],
    [ '%(.)',             '$percent{$1}' ],
    [ '^\\s*(.*?)\\s*$',  '$1' ],
    [ '^\\s+',            '' ],
    [ '\\s+$',            '' ],
    [ '([^ ]*) *([^ ]*)', '$2 $1' ]
];

  my $expected;
  if( $type eq 'simple' ) {
    $expected = $expected_simple
  }

  return $expected;
}
