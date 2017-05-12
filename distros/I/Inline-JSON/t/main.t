#!perl

use strict;
use warnings;

use Test::More 'tests' => 3;

BEGIN {
    use_ok('Inline::JSON');
}

use Data::Dumper;
print Dumper(
    json: {
        "name":   "Awesome",
        "title":  "Mr.",
        "skills": [
            "Nunchucking",
            "Bowhunting",
            "Computer Hacking",
            "Being Awesome"
        ]
    }
);


is_deeply(
    json: {
        "name":   "Awesome",
        "title":  "Mr.",
        "skills": [
            "Nunchucking",
            "Bowhunting",
            "Computer Hacking",
            "Being Awesome"
        ],
        "friends": {
            "pedro": "mexican",
            "deb": "girl"
        }
    },
    {
        'name' => 'Awesome',
        'title' => 'Mr.',
        'skills' => [
            'Nunchucking',
            'Bowhunting',
            'Computer Hacking',
            'Being Awesome',
        ],
        'friends' => {
            'pedro' => 'mexican',
            'deb'   => 'girl',
        },
    },
    'hash structure mathces'
);

is_deeply(
    json:
    [
        "awesome",
        "list!"
    ],
    [
        'awesome',
        'list!',
    ],
    'array structure matches, with newline',
);

