use strict;
use warnings;

use Test::Most;
use Test::Returns;

BEGIN { use_ok('Geo::Address::Parser') }

my $parser = Geo::Address::Parser->new(country => 'UK');
my $result = $parser->parse('Jane Doe, 10 Downing St, Westminster, SW1A 2AA');

returns_ok($result, { type => 'hashref', 'min' => 4 });

is $result->{name},     'Jane Doe',            'Name parsed';
is $result->{street},   '10 Downing St',       'Street parsed';
is $result->{city},     'Westminster',         'City parsed';
is $result->{postcode}, 'SW1A 2AA',            'Postcode parsed';

done_testing();
