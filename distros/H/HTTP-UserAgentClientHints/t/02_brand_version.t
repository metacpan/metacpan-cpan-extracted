use strict;
use warnings;
use Test::Arrow;

use HTTP::UserAgentClientHints::BrandVersion;

my $bv = HTTP::UserAgentClientHints::BrandVersion->new(
    q|" Not A;Brand";v="09", "Chromium";v="98", "Google Chrome";v="97.1"|,
);

t->got($bv)->expected('HTTP::UserAgentClientHints::BrandVersion')->isa_ok;

{
    t->got($bv->brands)->expect('ARRAY')->isa_ok;

    my $ordered_brands = [sort @{$bv->brands}];
    t->got($ordered_brands)->expect([' Not A;Brand', 'Chromium', 'Google Chrome'])->is_deeply;

    my $brand_version = $bv->brand_version;
    t->got($brand_version->{' Not A;Brand'})->expected('09')->is;
    t->got($brand_version->{Chromium})->expected('98')->is;
    t->got($brand_version->{'Google Chrome'})->expected('97.1')->is;
}

done;
