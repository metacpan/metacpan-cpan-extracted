#
# Test retrieving list of cast in case of Credited cast.
#

use strict;

use Test::More tests => 2;
use IMDB::Film;

my $crit = '0326272';
my %pars = (cache => 0, debug => 0, crit => $crit);

my $obj = new IMDB::Film(%pars);
is($obj->title, 'Three Sopranos', 'Movie title');
my $cast = $obj->cast;
is_deeply($cast->[0], {id => '1202207', name => 'Kathleen Cassello', role => 'Herself'}, 'cast');

