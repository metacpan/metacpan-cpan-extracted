use strict;

use Test::More tests => 2;

use IMDB::Film;

my $crit = 'Jonny Zero';
my %pars = (cache => 0, debug => 0, crit => $crit);

my $obj = new IMDB::Film(%pars);
is($obj->code, '0412158', 'Movies IMDB Code');
is($obj->rating, $obj->rating, 'Movie Rating');
