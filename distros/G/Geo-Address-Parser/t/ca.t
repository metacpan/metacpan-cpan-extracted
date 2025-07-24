use strict;
use warnings;
use Test::More;
use Geo::Address::Parser;

my $parser = Geo::Address::Parser->new(country => 'CA');
my $result = $parser->parse('Dr. Peter Smith, 123 Bloor St W, Toronto, ON M5S 1N5');

is $result->{name},     'Dr. Peter Smith',     'Name parsed';
is $result->{street},   '123 Bloor St W',      'Street parsed';
is $result->{city},     'Toronto',             'City parsed';
is $result->{region},   'ON',                  'Province parsed';
is $result->{postcode}, 'M5S 1N5',             'Postal code parsed';

done_testing();
