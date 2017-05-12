use strict;
use warnings;

use Encode;
use FilmAffinity::Utils qw/demoronize/;

use Test::More tests => 10;

my $string = [
  { string => undef,                expected => undef },
  { string => '[•REC]',             expected => '[*REC]' },
  { string => '“it’s the police!”', expected => '"it\'s the police!"'},
  { string => 'left ‘ quote',       expected => 'left ` quote'},
  { string => 'All…',               expected => 'All...'},
  { string => '‹Test›',             expected => '<Test>'},
  { string => '‚SINGLE„DOUBLE',     expected => ',SINGLE,,DOUBLE' },
  { string => 'ˆcircum',            expected => '^circum' },
  { string => 'perl–style',         expected => 'perl-style'},    #EN DASH
  { string => 'another—style',      expected => 'another-style'}, #EM DASH
];

foreach my $t (@{$string}){
  is(demoronize(decode('utf-8', $t->{string})), $t->{expected}, 'demoronisation');
}
