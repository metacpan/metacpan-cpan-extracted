use strict;
use warnings FATAL => 'all';
use utf8;

use lib '.';
use t::Util;
use Mac::OSVersion::Lite;

sub create_instance { Mac::OSVersion::Lite->new(@_) }

subtest basic => sub {
    subtest '# ==' => sub {
        my $a = create_instance('12.34');
        my $b = create_instance('12.34');

        cmp_ok $a, '==', $b;
    };

    subtest '# <=' => sub {
        my $v1  = create_instance('10.00');
        my $v2  = create_instance('10.01');
        my $v3  = create_instance('11.00');
        my $v4  = create_instance('12.01');

        cmp_ok $v1, '<', $v2;
        cmp_ok $v2, '<', $v3;
        cmp_ok $v3, '<', $v4;
    };
};

done_testing;
