use strict;
use warnings;

use Test::More tests => 2;

use Make;
my $m = Make->new( Makefile => "Makefile" );

is ref($m), 'Make';
eval { $m->Make('all') };
is $@, '',;

1;
