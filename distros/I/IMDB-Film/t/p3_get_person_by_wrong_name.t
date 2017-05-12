use Test::More tests => 4;

use IMDB::Persons;

my %pars = (crit => 'hhhhhhhhhhhhh', cache => 0, debug => 0);

my $person = new IMDB::Persons(%pars);

is($person->error, 'Not Found', 'error');
is($person->status, 0, 'status');
is($person->code, undef, 'code');
is($person->name, '', 'name');
