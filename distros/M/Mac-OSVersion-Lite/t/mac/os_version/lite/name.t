use strict;
use warnings FATAL => 'all';
use utf8;

use lib '.';
use t::Util;
use Mac::OSVersion::Lite;

subtest succeeded => sub {
    my $version = Mac::OSVersion::Lite->new('10.11');
    is $version->name, 'el_capitan';
};

subtest failed => sub {
    my $version = Mac::OSVersion::Lite->new('12.34');
    is $version->name, undef;
};

done_testing;
