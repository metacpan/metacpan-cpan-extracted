use strict;
use warnings;

use Test::Most;

use GitHub::MergeVelocity;
use Test::RequiresInternet ( 'api.github.com' => 443 );

my $velo = GitHub::MergeVelocity->new(
    cache_requests  => $ENV{GMV_CACHE_REQUESTS},
    debug_useragent => $ENV{GMV_DEBUG_USERAGENT} || 0,
    $ENV{GMV_GITHUB_TOKEN}
    ? (
        github_token => $ENV{GMV_GITHUB_TOKEN},
        github_user  => $ENV{GMV_GITHUB_USER},
        )
    : (),
    url => ['https://github.com/oalders/html-restrict'],
);

ok( $velo->report, 'report' );
diag $velo->print_report;

done_testing();

