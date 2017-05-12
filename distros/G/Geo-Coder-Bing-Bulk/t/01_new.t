use strict;
use warnings;
use Test::More tests => 5;
use Geo::Coder::Bing::Bulk;

new_ok('Geo::Coder::Bing::Bulk' => ['Your Bing Maps key']);
new_ok('Geo::Coder::Bing::Bulk' => ['Your Bing Maps key', debug => 1]);
new_ok('Geo::Coder::Bing::Bulk' => [key => 'Your Bing Maps key']);
new_ok(
    'Geo::Coder::Bing::Bulk' => [key => 'Your Bing Maps key', debug => 1]
);

can_ok(
    'Geo::Coder::Bing::Bulk',
    qw(download failed is_pending response ua upload)
);
