use Test::Most;

use File::ShareDir;
use Cwd qw( getcwd );
use File::Spec::Functions qw( rel2abs catdir );

$File::ShareDir::DIST_SHARE{'HTML-DeferableCSS'} = rel2abs(catdir(getcwd,'share'));

use HTML::DeferableCSS;

subtest "deferred_link_html with defer and inline disabled" => sub {

    my $css = HTML::DeferableCSS->new(
        css_root => 't/etc/css',
        aliases  => {
            reset => 'reset',
            test  => 'foo',
            nope  => undef,
        },
        inline_max => 0,
        defer_css  => 0,
    );

    isa_ok $css, 'HTML::DeferableCSS';

    is $css->deferred_link_html('nope'), "", "disabled link";

    is $css->deferred_link_html('test'), $css->link_html('test'),
        'deferred_link_html';

    is $css->deferred_link_html('test', 'test', 'nope'), $css->link_html('test'),
        'deferred_link_html (duplicates removed)';

};

subtest "deferred_link_html with defer disabled" => sub {

    my $css = HTML::DeferableCSS->new(
        css_root => 't/etc/css',
        aliases  => {
            reset => 'reset',
            test  => 'foo',
        },
        defer_css  => 0,
    );

    isa_ok $css, 'HTML::DeferableCSS';

    is $css->deferred_link_html('test'), $css->link_or_inline_html('test'),
        'deferred_link_html';

};

subtest "deferred_link_html with inline disabled" => sub {

    my $css = HTML::DeferableCSS->new(
        css_root => 't/etc/css',
        aliases  => {
            reset => 'reset',
            test  => 'foo',
        },
        inline_max => 0,
    );

    isa_ok $css, 'HTML::DeferableCSS';

    ok $css->preload_script, 'preload script exists';

    my $link = $css->link_html('test');

    ok my $cdata = $css->preload_script->slurp_raw, 'got script content';


    my $html = $css->deferred_link_html('test');


    is $html, '<link rel="preload" as="style" href="/foo.css" onload="this.onload=null;this.rel=\'stylesheet\'"><noscript>' . $link . '</noscript><script>' . $cdata . '</script>',
        'deferred_link_html';

};

done_testing;
