use strict;
use warnings;
use Test::Arrow;

use HTTP::UserAgentClientHints;
use HTTP::Headers;

my $h = HTTP::Headers->new(
    'Sec-CH-UA' => q|"Chrome"; v="73", "Chromium"; v="73", "?Not:Your Browser"; v="11"|,
    'Sec-CH-UA-Mobile' => q|?1|,
    'Sec-CH-UA-Platform' => q|"Windows"|,
    'Sec-CH-UA-Arch' => q|"arm"|,
    'Sec-CH-UA-Bitness' => q|"64"|,
    'Sec-CH-UA-Model' => q|"Pixel 2 XL"|,
    'Sec-CH-UA-Full-Version' => q|"73.1.2343B.TR"|,
    'Sec-CH-UA-Full-Version-List' => q|"Microsoft Edge"; v="92.0.902.73", "Chromium"; v="92.0.4515.131", "?Not:Your Browser"; v="3.1.2.0"|,
);

my $uach = HTTP::UserAgentClientHints->new($h);

t->got($uach)->expected('HTTP::UserAgentClientHints')->isa_ok;

{
    # arg object doesn't have `header` method.
    t->throw(sub { HTTP::UserAgentClientHints->new($uach) })->catch(qr/^Argument object:/);
}

RAW: {
    t->got($uach->ua_raw)->expected(q|"Chrome"; v="73", "Chromium"; v="73", "?Not:Your Browser"; v="11"|)->is;
    t->got($uach->mobile_raw)->expected(q|?1|)->is;
    t->got($uach->platform_raw)->expected(q|"Windows"|)->is;
    t->got($uach->arch_raw)->expected(q|"arm"|)->is;
    t->got($uach->bitness_raw)->expected(q|"64"|)->is;
    t->got($uach->model_raw)->expected(q|"Pixel 2 XL"|)->is;
    t->got($uach->full_version_raw)->expected(q|"73.1.2343B.TR"|)->is;
    t->got($uach->full_version_list_raw)->expected(q|"Microsoft Edge"; v="92.0.902.73", "Chromium"; v="92.0.4515.131", "?Not:Your Browser"; v="3.1.2.0"|)->is;

    # get again (from cache)
    t->got($uach->platform_raw)->expected(q|"Windows"|)->is;
}

{
    t->got($uach->ua)->expected('HTTP::UserAgentClientHints::BrandVersion')->isa_ok;
    t->got($uach->ua->brand_version->{Chromium})->expected(73)->is;
    t->got($uach->mobile)->expected(q|1|)->is;
    t->got($uach->platform)->expected(q|Windows|)->is;
    t->got($uach->arch)->expected(q|arm|)->is;
    t->got($uach->bitness)->expected(q|64|)->is;
    t->got($uach->model)->expected(q|Pixel 2 XL|)->is;
    t->got($uach->full_version)->expected(q|73.1.2343B.TR|)->is;
    t->got($uach->full_version_list)->expected('HTTP::UserAgentClientHints::BrandVersion')->isa_ok;
    t->got($uach->full_version_list->brand_version->{Chromium})->expected("92.0.4515.131")->is;

    # get again (from cache)
    t->got($uach->platform)->expected(q|Windows|)->is;
}

ACCEPT_CH: {
    t->got($uach->accept_ch)->expected('Sec-CH-UA-Arch, Sec-CH-UA-Bitness, Sec-CH-UA-Model, Sec-CH-UA-Full-Version-List, Sec-CH-UA-Full-Version')->is;
    t->got($uach->accept_ch([qw/Sec-CH-UA-Full-Version/]))->expected('Sec-CH-UA-Arch, Sec-CH-UA-Bitness, Sec-CH-UA-Model, Sec-CH-UA-Full-Version-List')->is;
    t->got($uach->accept_ch([qw/Sec-CH-UA-Full-Version Sec-CH-UA-Bitness/]))->expected('Sec-CH-UA-Arch, Sec-CH-UA-Model, Sec-CH-UA-Full-Version-List')->is;
}

EDGE_CASES: {
    my $h = HTTP::Headers->new(
        'Sec-CH-UA' => undef,
        'Sec-CH-UA-Mobile' => '',
        'Sec-CH-UA-Platform' => 0,
    );

    my $uach = HTTP::UserAgentClientHints->new($h);

    t->got($uach->ua_raw)->expected(undef)->is;
    t->got($uach->mobile_raw)->expected('')->is;
    t->got($uach->platform_raw)->expected(0)->is;
    t->got($uach->arch_raw)->expected(undef)->is;

    t->got($uach->ua)->expected(undef)->is;
    t->got($uach->mobile)->expected('')->is;
    t->got($uach->platform)->expected(0)->is;
    t->got($uach->arch)->expected(undef)->is;
}

done;
