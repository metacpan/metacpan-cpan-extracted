#/usr/bin/env perl
#===============================================================================
#Last Modified:  2012/11/02
#===============================================================================
use Test::More 0.96;
use HTML::WikiConverter;


my $wc = new HTML::WikiConverter(
    dialect  => 'FreeStyleWiki',
    base_uri => 'http://www.example.com/wiki/wiki.cgi',
);


my $testcases = make_testcases();

foreach my $t (@$testcases) {
    is( $wc->html2wiki( html => $t->[0] ), $t->[1], $t->[2] );
}

sub make_testcases {
    my @tests = (
        [ '<b>text</b>',                              q{'''text'''},                  'bold' ],
        [ '<i>text</i>',                              q{''text''},                    'ital' ],
        [ 'hoge<b>text</b>fuga',                      q{hoge'''text'''fuga},          'bold' ],
        [ 'hoge<i>text</i>fuga',                      q{hoge''text''fuga},            'ital' ],
        [ "text<ins>hoge</ins>fuga",                  qq{text__hoge__fuga},           'underline' ],
        [ "text<del>hoge</del>fuga",                  qq{text==hoge==fuga},           'delete' ],
        [ '<a href="http://example.com">Example</a>', '[Example|http://example.com]', 'link' ],
        [ '<a href="http://example.com/">Example</a>', '[Example|http://example.com/]', 'link' ],
        [ '<blockquote>text1</blockquote>', '""text1', 'blockquote' ],
        [   '<blockquote>text1<blockquote>text2</blockquote></blockquote>', qq{""text1\n""text2},
            'nested blockquote change to plain blockquote'
        ],
        [ '<blockquote><p>text1</p><p>text2</p></blockquote>', qq{""text1\n""text2}, 'blockquote' ],
        [ '<a href="/">Example</a>', '[Example|http://www.example.com/]', 'relative URL in link' ],
        [ '<strong>text</strong>',   q{'''text'''},                       'strong' ],
        [ '<em>text</em>',           q{''text''},                         'em' ],
        [ '<a href="/wiki/wiki.cgi?page=Example">Example</a>', '[[Example]]', 'wiki link' ],
        [ '<a href="?page=Example">Example</a>', '[[Example]]', 'wiki link' ],
        [ '<a href="wiki.cgi?action=PRINTMODE&page=Example">Example</a>', '[Example|?action=PRINTMODE&page=Example]', 'wiki action link' ],
        [ '<a href="/wiki/wiki.cgi/farm?page=Example">Example</a>', '[Example|wiki.cgi/farm?page=Example]', 'wiki farm link' ],
        [ '<a href="wiki.cgi/farm?page=Example">Example</a>', '[Example|wiki.cgi/farm?page=Example]', 'wiki farm link' ],
        [ '<a href="wiki.cgi/../wiki.cgi/farm?page=Example">Example</a>', '[Example|wiki.cgi/farm?page=Example]', 'some plugin link' ],
        [ '<a href="wiki.cgi/../wiki.cgi?page=Example">Example</a>', '[[Example]]', 'some plugin link' ],
        [ '<a href="wiki.cgi/../wiki.cgi?page=Example&action=vote">vote</a>', '[vote|?page=Example&action=vote]', 'some plugin link' ],
        [   '<img src="?page=FrontPage&amp;file=image%2Ejpg&amp;action=ATTACH"/>',
            '{{ref_image image.jpg,FrontPage}}',
            'ref_image plugin'
        ],
        [   '<img src="http://sub.example.com/img.jpg "/>',
            '{{image http://sub.example.com/img.jpg}}',
            'image plugin : direct link to other domian site.'
        ],
        [   '<a href="wiki.cgi?page=Thingy">Text</a>',
            '[[Text|Thingy]]', 'long wiki url'
        ],
        [ "<p>text\n<br />hoge\n</p>", qq{text\nhoge}, 'multiline paragraph' ],
        [ "<p>\ntext<br />\nhoge\n</p>", qq{text\nhoge}, 'multiline paragraph' ],
        [ "<pre>::text1\n:::text2</pre>", qq{ ::text1\n :::text2}, 'pre' ],
        [ "<br>\n<pre>::text1\n:::text2</pre>", qq{ ::text1\n :::text2}, 'pre' ],
        [ "<br><pre>::text1\n:::text2</pre>", qq{ ::text1\n :::text2}, 'pre' ],
    );
    return \@tests;
}

done_testing;
