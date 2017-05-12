use strict;

use Test::More tests => 2;
use IMDB::Film;


my $crit = 'Con Air';
my %pars = (cache => 0, debug => 0, crit => $crit, exact => 1);

my $obj = new IMDB::Film(%pars);

is($obj->code, '0118880', 'search code');

is(scalar(@{$obj->matched}), 5, 'Matched results');
