use strict;
use warnings;

use GitHub::MergeVelocity;

my $mv = GitHub::MergeVelocity->new(
    url => [
        'neilbowers/PAUSE-Permissions',
        'https://github.com/oalders/html-restrict/issues',
    ]
);

$mv->print_report;
