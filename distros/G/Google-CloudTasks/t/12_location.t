use strict;
use warnings;
use utf8;

use lib qw/lib/;
use Test::More;
use Test::Deep;
use Google::CloudTasks;

BEGIN {
    unless (defined $ENV{GOOGLE_APPLICATION_CREDENTIALS} && defined $ENV{PROJECT_ID} && defined $ENV{LOCATION_ID}) {
        Test::More::plan(skip_all => 'This test needs GOOGLE_APPLICATION_CREDENTIALS and PROJECT_ID and LOCATION_ID')
    }
}

my $client = Google::CloudTasks->client(credentials_path => $ENV{GOOGLE_APPLICATION_CREDENTIALS});

subtest 'get' => sub {
    my $name = "projects/$ENV{PROJECT_ID}/locations/$ENV{LOCATION_ID}";
    my $res = $client->get_location($name);

    my $expected = {
        'labels' => {
            'cloud.googleapis.com/region' => $ENV{LOCATION_ID},
        },
        'locationId' => $ENV{LOCATION_ID},
        'name' => $name,
    };

    is_deeply $res, $expected;
};

subtest 'list' => sub {
    my $name = "projects/$ENV{PROJECT_ID}";
    my $res = $client->list_locations($name);

    my $expected = {
        'locations' => supersetof(
            {
                'labels' => {
                    'cloud.googleapis.com/region' => $ENV{LOCATION_ID},
                },
                'locationId' => $ENV{LOCATION_ID},
                'name' => "$name/locations/$ENV{LOCATION_ID}",
            },
        ),
    };

    cmp_deeply $res, $expected;
};

done_testing;
