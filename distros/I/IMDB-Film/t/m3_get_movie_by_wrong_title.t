use strict;

use Test::More tests => 3;
use IMDB::Film;

my $crit = 'hhhhhhhhhhh';
my %pars = (cache => 0, debug => 0, crit => $crit);

my $obj = new IMDB::Film(%pars);

is($obj->error, 'Not Found', 'error');
is($obj->status, 0, 'status');
is($obj->code, undef, 'code');

