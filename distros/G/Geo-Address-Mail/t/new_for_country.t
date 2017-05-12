use Test::More;

use Geo::Address::Mail;

my $usaddr = Geo::Address::Mail->new_for_country('us', {
    name => 'Cory Watson', postal_code => '12345'
});
ok(defined($usaddr), 'got something from new_for_country');
isa_ok($usaddr, 'Geo::Address::Mail::US');

done_testing;