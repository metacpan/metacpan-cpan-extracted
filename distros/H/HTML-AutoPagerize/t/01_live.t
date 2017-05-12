use strict;
use Test::Base;

plan skip_all => 'TEST_LIVE is not defined'
    unless $ENV{TEST_LIVE};

plan tests => 4 * blocks;
filters { page_element => 'regexp' };

use LWP::Simple;
use HTML::AutoPagerize;

my $auto  = HTML::AutoPagerize->new;
$auto->add_site(
    url         => 'http://.+.tumblr.com/',
    nextLink    => '//div[@id="content" or @id="container"]/div[last()]/a[last()]',
    pageElement => '//div[@id="content" or @id="container"]/div[@class!="footer" or @class!="navigation"]',
);

run {
    my $block = shift;
    my $html  = LWP::Simple::get($block->url);

    my $res = $auto->handle($block->url, $html);

    ok $res, 'handled the URL correctly';
    is $res->{next_link}, $block->next_link, "next link is $res->{next_link}";
    ok $res->{page_element};

    my $page_html = join '', map $_->as_HTML, $res->{page_element}->get_nodelist;
    like $page_html, $block->page_element;
}

__END__
=== Tumblr
--- url: http://otsune.tumblr.com/
--- next_link: http://otsune.tumblr.com/page/2
--- page_element: otsune.tumblr.com/post
