use strict;
use warnings;

use Data::Dumper;
use Test::More;

my $CLASS = 'Geo::OLC::XS';

sub main {
    use_ok($CLASS);

    my %data = (
        '8Q6QMG93+742' => [ 34.6681375, 135.502765625, 11],
    );

    my $olc = $CLASS->new;
    foreach my $code (sort keys %data) {
        my ($lat, $lon, $len) = $data{$code}->@*;

        my $encoded = $olc->encode($lat, $lon, $len);
        is_deeply($encoded, $code, "code $code encoded correctly");

        my $decoded = $olc->decode($code);
        my $expected = +[ $lat, $lon ];
        is_deeply($decoded->{center}, $expected, "code $code decoded correctly");
    }

    done_testing;
    return 0;
}

exit main();
