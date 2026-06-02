use strict;
use warnings;
use utf8;
use Test::More;
use Test::Warn;

use lib './lib'; # actually use the module, not other versions installed
use Geo::Coder::OpenCage;

# Mock UA so this test runs offline and we control the response
{
    package MockUA;
    sub new   { bless {}, shift }
    sub agent { }
    sub get {
        return {
            success => 1,
            content => '{"status":{"code":200,"message":"OK"},"results":[]}'
        };
    }
}

my $geocoder = Geo::Coder::OpenCage->new(
    api_key => 'dummy',
    ua      => MockUA->new
);

warning_like {
    $geocoder->geocode(location => "Berlin", langauge => "en");
}
qr/Unknown geocode parameter: langauge/, "typo in parameter triggers warning";

warning_like {
    $geocoder->geocode(location => "Berlin", key => "sneaky");
}
qr/Unsupported geocode parameter: key/, "'key' parameter triggers warning";

# 'format' and 'jsonp' are known API parameters but this module deliberately
# does not support them (always parses JSON into Perl data structures)
warning_like {
    $geocoder->geocode(location => "Berlin", format => "xml");
}
qr/Unsupported geocode parameter: format/,
    "'format' (known but unsupported) triggers warning";

warning_like {
    $geocoder->geocode(location => "Berlin", jsonp => "callback");
}
qr/Unsupported geocode parameter: jsonp/,
    "'jsonp' (known but unsupported) triggers warning";

done_testing();
