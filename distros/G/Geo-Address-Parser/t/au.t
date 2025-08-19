use strict;
use warnings;
use Test::More;
use Geo::Address::Parser;

my $parser = Geo::Address::Parser->new(country => 'Australia');
my $result = $parser->parse('Royal Exhibition Building, 9 Nicholson St, Carlton, VIC 3053');

is $result->{name}, 'Royal Exhibition Building', 'Name parsed';
is $result->{road}, '9 Nicholson St', 'Street parsed';
is $result->{suburb}, 'Carlton', 'Suburb parsed';
is $result->{region}, 'VIC', 'State parsed';
is $result->{postcode}, '3053', 'Postcode parsed';

done_testing();
