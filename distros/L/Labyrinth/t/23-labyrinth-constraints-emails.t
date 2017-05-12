#!/usr/bin/perl -w
use strict;

use Data::FormValidator;
use Test::More tests => 44;
use Labyrinth::Constraints::Emails;
use Labyrinth::Variables;

Labyrinth::Variables::init();   # initial standard variable values

my @examples = (
    [ undef,                        0, undef,                       0, undef                        ],
    [ '',                           0, undef,                       0, undef                        ],
    [ 'barbie@example.com',         1, 'barbie@example.com',        1, 'barbie@example.com'         ],
    [ 'barbie',                     0, undef,                       0, undef                        ],
    [ 'barbie@example',             0, undef,                       0, undef                        ],
    [ '@example.com',               0, undef,                       0, undef                        ],
    [ 'b@example.com',              1, 'b@example.com',             1, 'b@example.com'              ],
    [ '-barbie@example.com',        0, undef,                       0, undef                        ],
    [ '#barbie@example.com',        0, undef,                       0, undef                        ],
    [ 'test#barbie@example.com',    0, undef,                       1, 'test#barbie@example.com'    ],
    [ 'test-barbie@example.com',    1, 'test-barbie@example.com',   1, 'test-barbie@example.com'    ],
);

for my $ex (@examples) {
    is(valid_emails(   undef,$ex->[0]), $ex->[1],  "'" . (defined $ex->[0] ? $ex->[0] : 'undef') ."' validates as expected for emails"     );
    is(match_emails(   undef,$ex->[0]), $ex->[2],  "'" . (defined $ex->[0] ? $ex->[0] : 'undef') ."' matches as expected for emails"       );
    is(valid_email_rfc(undef,$ex->[0]), $ex->[3],  "'" . (defined $ex->[0] ? $ex->[0] : 'undef') ."' validates as expected for email_rfc"  );
    is(match_email_rfc(undef,$ex->[0]), $ex->[4],  "'" . (defined $ex->[0] ? $ex->[0] : 'undef') ."' matches as expected for email_rfc"    );
}
