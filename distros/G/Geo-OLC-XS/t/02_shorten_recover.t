use strict;
use warnings;

use Data::Dumper;
use Test::More;

my $CLASS = 'Geo::OLC::XS';

sub main {
    use_ok($CLASS);

    my %data = (
        'MG93+742' => [ '8Q6QMG93+742', 34.6937048, 135.5016142 ],
        '93+742'   => [ '8Q6QMG93+742', 34.6788184, 135.4987303 ],
        'XQP5+'    => [ '8Q6QXQP5+'   , 35.0060799, 135.6909098 ],

    );

    my $olc = $CLASS->new;
    foreach my $short (sort keys %data) {
        my ($long, $lat, $lon) = $data{$short}->@*;

        my $shortened = $olc->shorten($long, $lat, $lon);
        is_deeply($shortened, $short, "code $long shortens to $short");

        my $recovered = $olc->recover_nearest($short, $lat, $lon);
        is_deeply($recovered, $long, "code $short recovers to $recovered");
    }

    done_testing;
    return 0;
}

exit main();
