use Test::More tests => 4;

use IMDB::Film;

my $obj = new IMDB::Film(crit => 't/test.html', debug => 0, cache => 0);

is($obj->status, 1, 'Object status');
is($obj->code, '0332452', 'Movie IMDB Code');
is($obj->title, 'Troy', 'Movie Title');
is($obj->cast->[0]{name}, 'Julian Glover', 'Movie Person');
