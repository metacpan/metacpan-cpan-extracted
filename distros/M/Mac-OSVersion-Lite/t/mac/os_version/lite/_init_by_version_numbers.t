use strict;
use warnings FATAL => 'all';
use utf8;

use lib '.';
use t::Util;
use Mac::OSVersion::Lite;

sub create_instance { bless {} => 'Mac::OSVersion::Lite' }

subtest basic => sub {
    my $version = create_instance;

    $version->_init_by_version_numbers(undef, undef);
    is $version->major, 0;
    is $version->minor, 0;

    $version->_init_by_version_numbers(10, undef);
    is $version->major, 10;
    is $version->minor, 0;

    $version->_init_by_version_numbers(10, 11);
    is $version->major, 10;
    is $version->minor, 11;
};

done_testing;
