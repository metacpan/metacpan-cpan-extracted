use strict;
use warnings;
use EAV::XS;
use Test::More tests => 6;


my $eav;

eval {
    $eav = EAV::XS->new('tld_check');
};

ok (! $eav && $@ =~ /odd number of elements/);

$eav = EAV::XS->new();
ok (! $eav->get_is_ipv4(), "get_is_ipv4: false" );
ok (! $eav->get_is_ipv6(), "get_is_ipv6: false" );
ok (! $eav->get_is_domain(), "get_is_domain: false" );
cmp_ok ($eav->get_lpart(), "eq", "", "get_lpart: empty" );
cmp_ok ($eav->get_domain(), "eq", "", "get_domain: empty" );
