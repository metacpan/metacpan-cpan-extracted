use Test::Most;

use HTML::DeferableCSS;

subtest "css_href" => sub {

    my $css = HTML::DeferableCSS->new(
        css_root => 't/etc/css',
        aliases  => {
            reset => 'reset',
        },
        url_base_path => '/css/',
    );

    isa_ok $css, 'HTML::DeferableCSS';

    is $css->href('reset'), '/css/reset.min.css';

    is $css->link_html('reset'),
        '<link rel="stylesheet" href="/css/reset.min.css">',
        "link_html";

};

subtest "css_href (URL)" => sub {

    my $url = 'http://cdn.example.com/reset.css';

    my $css = HTML::DeferableCSS->new(
        css_root => 't/etc/css',
        aliases  => {
            reset => $url,
        },
        url_base_path => '/css/',
    );

    isa_ok $css, 'HTML::DeferableCSS';

    is $css->href('reset'), $url;

    is $css->link_html('reset'),
        qq{<link rel="stylesheet" href="$url">},
        "link_html";

};

subtest "css_href with asset_id" => sub {

    my $css = HTML::DeferableCSS->new(
        css_root => 't/etc/css',
        asset_id => 'v2',
        aliases  => {
            reset => 'reset',
        },
        url_base_path => '/css/',
    );

    isa_ok $css, 'HTML::DeferableCSS';

    is $css->href('reset'), '/css/reset.min.css?v2';

    is $css->link_html('reset'),
        '<link rel="stylesheet" href="/css/reset.min.css?v2">',
        "link_html";

};

subtest "css_href with cdn_links" => sub {

    my $href = '//cdnjs.cloudflare.com/ajax/libs/meyer-reset/2.0/reset.css';

    my $css = HTML::DeferableCSS->new(
        css_root => 't/etc/css',
        aliases  => {
            reset => 'reset',
        },
        url_base_path => '/css/',
        cdn_links => {
            reset => $href,
        },
    );

    isa_ok $css, 'HTML::DeferableCSS';

    is $css->href('reset'), $href;

};

subtest "css_href with cdn_links disabled" => sub {

    my $href = '//cdnjs.cloudflare.com/ajax/libs/meyer-reset/2.0/reset.css';

    my $css = HTML::DeferableCSS->new(
        css_root => 't/etc/css',
        aliases  => {
            reset => 'reset',
        },
        url_base_path => '/css/',
        use_cdn_links => 0,
        cdn_links => {
            reset => $href,
        },
    );

    isa_ok $css, 'HTML::DeferableCSS';

    is $css->href('reset'), '/css/reset.min.css';

};

done_testing;
