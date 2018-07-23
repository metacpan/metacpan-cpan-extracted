
use strict;
use warnings;

use Test::More tests => 4;

use Data::Dumper;

package H::in;

use HO::class
  _index => 'loud' => '$',
  _index => 'noise' => '@',
  _rw => 'code' => '%';

package main;

my $t = H::in->new;

is($t->loud,0,'first accessor');
is($t->[$t->loud],undef,'default for first field is undef');

is($t->noise,1,'second accessor');
is_deeply($t->[$t->noise],[],'default for second fiels is empty array ref');

#print Dumper $t;
