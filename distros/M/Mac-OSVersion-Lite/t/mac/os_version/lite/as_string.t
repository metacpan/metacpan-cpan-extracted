use strict;
use warnings FATAL => 'all';
use utf8;

use lib '.';
use t::Util;
use Mac::OSVersion::Lite;

subtest basic => sub {
    subtest '# major' => sub {
        my $version = Mac::OSVersion::Lite->new('12');
        is $version->as_string, '12.0';
    };

    subtest '# minor' => sub {
        my $version = Mac::OSVersion::Lite->new('12.34');
        is $version->as_string, '12.34';
    };
};

done_testing;
