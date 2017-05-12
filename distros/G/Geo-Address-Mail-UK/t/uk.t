use Test::More;
use Test::Exception;

use Geo::Address::Mail::UK;

dies_ok(sub {
    my $usaddr = Geo::Address::Mail::UK->new(
        name => 'Dr. Watson', postal_code => 'COR BLIMEY'
    )
}, 'invalid code');

lives_ok(sub {
    my $ukaddr = Geo::Address::Mail::UK->new(
        name => 'Sherlock Holmes', postal_code => 'N1 6XE'
    )
}, 'AN NAA');

lives_ok(sub {
    my $ukaddr = Geo::Address::Mail::UK->new(
        postal_code => 'N57 6XE'
    )
}, 'ANN NAA');

lives_ok(sub {
    my $ukaddr = Geo::Address::Mail::UK->new(
        postal_code => 'NS1 6XE'
    )
}, 'AAN NAA');

lives_ok(sub {
    my $ukaddr = Geo::Address::Mail::UK->new(
        postal_code => 'NW13 6XE'
    )
}, 'AANN NAA');

lives_ok(sub {
    my $ukaddr = Geo::Address::Mail::UK->new(
        postal_code => 'N1D 6XE'
    )
}, 'ANA NAA');

lives_ok(sub {
    my $ukaddr = Geo::Address::Mail::UK->new(
        postal_code => 'NE1W 6XE'
    )
}, 'AANA NAA');

# now some "declared invalid" codes
dies_ok(sub {
    my $ukaddr = Geo::Address::Mail::UK->new(
        postal_code => 'QE1W 6XE'
    )
}, 'Bad first position');

dies_ok(sub {
    my $ukaddr = Geo::Address::Mail::UK->new(
        postal_code => 'DJ1W 6XE'
    )
}, 'Bad second position');

dies_ok(sub {
    my $ukaddr = Geo::Address::Mail::UK->new(
        postal_code => 'N1L 6XE'
    )
}, 'Bad third position in ANA NAA');

dies_ok(sub {
    my $ukaddr = Geo::Address::Mail::UK->new(
        postal_code => 'QE1D 6XE'
    )
}, 'Bad fourth position in AANA');

dies_ok(sub {
    my $ukaddr = Geo::Address::Mail::UK->new(
        postal_code => 'QE1W 6VE'
    )
}, 'Bad alpha in inward code');

done_testing;
