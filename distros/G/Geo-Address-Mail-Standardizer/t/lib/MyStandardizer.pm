package # hide from CPAN
    MyStandardizer;
use Moose;

with 'Geo::Address::Mail::Standardizer';

use Geo::Address::Mail::Standardizer::Results;

sub standardize {
    my ($self, $address) = @_;

    my $newaddr = $address->clone;
    my $results = Geo::Address::Mail::Standardizer::Results->new(
        standardized_address => $newaddr
    );

    if($newaddr->street =~ /Street/) {
        my $street = $newaddr->street;
        $street =~ s/Street/ST/;
        $newaddr->street($street);
        $results->set_changed('street', $street);
    }

    return $results;
}

1;
