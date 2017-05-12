use strict; use warnings;
use Lowu;
use Data::Dumper;

use Types::Standard 'Str';

print Dumper 
  [foo => 'bar', baz => 'quux']
    ->tuples(2 => Str)
    ->map(sub { hash(@$_)->inflate })
