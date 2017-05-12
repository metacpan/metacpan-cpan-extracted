use strict;
use warnings;
use Test::More;
use HTML::TreeBuilder::LibXML;

plan skip_all => "this test requires Web::Scraper" unless eval "use Web::Scraper; 1";
plan tests => 2*3+1;

can_ok 'HTML::TreeBuilder::LibXML', 'ignore_unknown';

my $html = <<'...';
<html>
    <a href="http://wassr.jp/">wassr</a>
    <div>
        <a href="http://mixi.jp/">mixi</a>
    </div>
</html>
...

my $code = <<'...';
use Web::Scraper;

my $ret = scraper {
    process '//a', 'text[]', 'TEXT';
    process '//a', 'href[]', '@href';
    process '//div', 'div[]', scraper {
        process '//a', 'link[]', 'TEXT';
    };
}->scrape($html);
is_deeply($ret->{text}, ['wassr', 'mixi']);
is_deeply($ret->{href}, ['http://wassr.jp/', 'http://mixi.jp/']);
is_deeply($ret->{div}, [{link => ['mixi']}]);
...

&run;
HTML::TreeBuilder::LibXML->replace_original();
&run;

sub run {
    eval $code;
    die $@ if $@;
}

