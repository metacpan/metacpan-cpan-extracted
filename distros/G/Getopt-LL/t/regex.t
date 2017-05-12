use strict;
use warnings;
use Test::More;
use English qw( -no_match_vars );

use lib 'lib';

our $THIS_TEST_HAS_TESTS  = 9;
our $THIS_BLOCK_HAS_TESTS = 0;

plan( tests => $THIS_TEST_HAS_TESTS );


use Getopt::LL qw(getoptions);



my $rules = {
    '--head'        => qr/(hello|goodbye)/xmsi,
    '--bottom'      => qr/\A\w+\z/xms,
            

};

my $getopt_options = {
   die_on_type_mismatch => 0,
   silent               => 1,
   allow_unspecified    => 1,
};

my $argv = [qw( --head hello --bottom )];
my $result = do { eval 'getoptions($rules, $getopt_options, $argv)' };
my $err = quotemeta
    'Argument --bottom [<no-value>] does not match /\A\w+\z/msx-i'
;
like( $EVAL_ERROR, qr/$err/, 'die on regex mismatch');

$argv = [qw( --head hello --bottom xyzzy )];
$result = do { eval 'getoptions($rules, $getopt_options, $argv)' };
is_deeply($result, { '--head' => 'hello', '--bottom' => 'xyzzy' }, 'regexes');

$argv = [qw( --head bonjour --bottom xyzzy )];
$result = do { eval 'getoptions($rules, $getopt_options, $argv)' };
$err = quotemeta
    'Argument --head [bonjour] does not match /(hello|goodbye)/msix'
;
like( $EVAL_ERROR, qr/$err/, 'die on regex mismatch');

$argv = [qw( --head goodbye --bottom x!x )];
$result = do { eval 'getoptions($rules, $getopt_options, $argv)' };
$err = quotemeta
    'Argument --bottom [x!x] does not match /\A\w+\z/msx-i'
;
like( $EVAL_ERROR, qr/$err/, 'die on regex mismatch');

package Getopt::LL;
use Test::More;

is(_regex_as_text(qr/((hello))/xms), '/((hello))/msx-i',
    '_regexp_as_text(qr/((hello))/xms)');
is(_regex_as_text(qr/(?:hello|olleh|leoh)/xms), '/(?:hello|olleh|leoh)/msx-i',
    '_regexp_as_text(qr/(?:hello|olleh|leoh)/xms)');

my $test_re = qr/
          \A          # starts with...
          -           # single dash.
          (?!-)       # with no dash after that.
          .
/xmsi;

is(_regex_as_text($test_re), '/
          \A          # starts with...
          -           # single dash.
          (?!-)       # with no dash after that.
          .
/msix');

is(_regex_as_text("(?:hello)"), '/hello/');

is(_regex_as_text("blablabla"), '/blablabla/');
