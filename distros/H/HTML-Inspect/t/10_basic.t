use strict;
use warnings;
use utf8;

use Test::More;
use Log::Report 'html-inspect';
use File::Slurper qw(read_text);

require_ok('HTML::Inspect');

my $constructor_and_doc = sub {
    my $inspector;
    try { HTML::Inspect->new };
    like($@ => qr/html_ref is required/, '_init croaks ok1');
    try { HTML::Inspect->new(html_ref => "foo") };
    like($@ => qr/html_ref not SCALAR/, '_init croaks ok2');
    try { HTML::Inspect->new(html_ref => \"foo") };
    like($@ => qr/Not HTML/, '_init croaks ok3');
    try { HTML::Inspect->new(html_ref => \"<B>FooBar</B>") };
    like($@ => qr/is\smandatory/, '_init croaks ok4');
    my $req_uri = 'http://example.com/doc.html';
    $inspector = HTML::Inspect->new(location => $req_uri, html_ref => \"<B>FooBar</B>");
    isa_ok($inspector => 'HTML::Inspect');
    is($req_uri => $inspector->location, 'location ok');
    isa_ok(HTML::Inspect->new(location => URI->new('http://example.com/doc.htm'), html_ref => \"<B>FooBar</B>"),
        'HTML::Inspect');
    isa_ok(HTML::Inspect->new(location => URI->new('http://example.com/doc.htm')->canonical, html_ref => \"<B>FooBar</B>"),
        'HTML::Inspect');
    # note $inspector->_doc;
    isa_ok($inspector->_doc, 'XML::LibXML::Element');
    like($inspector->_doc => qr|<b>FooBar</b>|, 'doc, lowercased ok');
};

my $collectMeta = sub {
    my $html                = read_text "t/data/collectMeta.html";
    my $inspector           = HTML::Inspect->new(location => 'http://example.com/doc', html_ref => \$html);
    my $expectedMetaClassic = {
        'charset'    => 'utf-8',
        'http-equiv' =>
          {'content-disposition' => '', 'content-type' => 'text/html;charset=utf-8', 'refresh' => '3;url=https://www.mozilla.org'},
        'name' => {
            # Should capital letters be acepted in name attributes content? Not
            # in standart metadata names, otherwise why not.
            # See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/meta/name
            # 'Author'      => "Ванчо Панчев",
            'description' => 'The Open Graph protocol enables...',
            'generator'   => "Хей, гиди Ванчо",
            'referrer'    => 'no-referrer'
        }
    };
    my $collectedMetaClassic = $inspector->collectMetaClassic;
    is_deeply($collectedMetaClassic => $expectedMetaClassic, 'HIM_classic, parsed ok');
    is($collectedMetaClassic => $inspector->collectMetaClassic(), 'collectMetaClassic() returns already parsed HIM_classic');
    note explain $collectedMetaClassic;

    # but here capitalised name="Values" are OK
    my $expectedMetaNames  = {'empty' => '', 'Author' => "Ванчо Панчев", 'Алабала' => 'ница', %{$expectedMetaClassic->{name}}};
    my $collectedMetaNames = $inspector->collectMetaNames();    # cached already
    is_deeply($collectedMetaNames => $expectedMetaNames, 'collectMetaNames() returns already parsed HIM_names');
    note explain $collectedMetaNames;
    my $expectedAllMeta = [
        {'charset' => 'UTF-8'},
        {'content' => 'Open Graph protocol',     'property' => 'og:title'},
        {'content' => 'website',                 'property' => 'OG:TYPE'},
        {'content' => 'https://ogp.me/',         'property' => 'og:url'},
        {'content' => 'https://ogp.me/logo.png', 'property' => 'og:image'},
        {'content' => '115190258555800',         'prefix'   => 'fb: https://ogp.me/ns/fb#', 'property' => 'fb:app_id'},
        {},
        {'content'    => "ница", 'name' => "Алабала"},
        {'content'    => '',     'name' => 'empty'},
        {'name'       => 'undefined'},
        {'content'    => 'no-referrer',                        'name'       => 'referrer'},
        {'content'    => 'The Open Graph protocol enables...', 'name'       => 'description'},
        {'content'    => "Ванчо Панчев",                       'name'       => 'Author'},
        {'content'    => "Хей, гиди Ванчо",                    'name'       => 'generator'},
        {'content'    => '3;url=https://www.mozilla.org',      'http-equiv' => 'refresh'},
        {'content'    => 'text/html',                          'http-equiv' => 'Content-type'},
        {'content'    => 'text/html;charset=utf-8',            'http-equiv' => 'Content-Type'},
        {'content'    => '',                                   'http-equiv' => 'Content-Disposition'},
        {'http-equiv' => 'Keep-Alive'}
    ];
    my $collectedAllMeta = $inspector->collectMeta();
    is_deeply($expectedAllMeta => $collectedAllMeta, 'HIM_all, parsed ok');
    note explain $collectedAllMeta;
};

my $collectOpenGraph = sub {
    my $html = read_text "t/data/collectOpenGraph.html";

    my $i  = HTML::Inspect->new(location => 'http://example.com/doc', html_ref => \$html);
    my $og = $i->collectOpenGraph();
    is(ref $og          => 'HASH',                 'collectOpenGraph() returns a HASH reference');
    is($og->{og}{title} => 'Open Graph protocol',  'content is trimmed');
    is($og              => $i->collectOpenGraph(), 'collectOpenGraph() returns alrady parsed Graph data');
    is_deeply(
        $og => {
            fb => {'app_id' => '115190258555800'},
            og => {
                'image' => [
                    {'url' => 'https://ogp.me/logo.png'},
                    {
                        'alt'        => 'A shiny red apple with a bite taken out',
                        'height'     => '300',
                        'secure_url' => 'https://secure.example.com/ogp.jpg',
                        'type'       => 'image/jpeg',
                        'url'        => 'https://example.com/ogp.jpg',
                        'width'      => '400'
                    },
                    {'url' => 'HTTPS://EXAMPLE.COM/ROCK.JPG'},
                    {'url' => 'HTTPS://EXAMPLE.COM/ROCK2.JPG'}
                ],
                'title' => 'Open Graph protocol',
                'type'  => 'website',
                'url'   => 'https://ogp.me/',
                'video' => [
                    {
                        'height'     => '300',
                        'secure_url' => 'https://secure.example.com/movie.swf',
                        'type'       => 'application/x-shockwave-flash',
                        'url'        => 'https://example.com/movie.swf',
                        'width'      => '400'
                    }
                ],
            },
            profile => {
                'first_name' => "\x{41f}\x{435}\x{440}\x{43a}\x{43e}",
                'last_name'  => "\x{41d}\x{430}\x{443}\x{43c}\x{43e}\x{432}",
                'username'   => "\x{43d}\x{430}\x{443}\x{43c}\x{43e}\x{432}"
            },
        },
        'all OG meta tags are parsed properly'
    );
    note explain $og;
};

my $collectReferences = sub {
    my $html      = read_text "t/data/links.html";
    my $inspector = HTML::Inspect->new(location => 'https://html.spec.whatwg.org/multipage/dom.html', html_ref => \$html);

    my $a_href    = $inspector->collectReferencesFor(a => 'href');
    note explain $a_href;

    my $links     = $inspector->collectReferences;
    is(ref $links           => 'HASH',  'collectReferences() returns a HASH reference');
    is(ref $links->{a_href} => 'ARRAY', 'collectReferences() returns a HASH reference of ARRAYs');
    is $a_href, $links->{a_href}, 'no reprocessing of already processed field';
    ok defined $links->{img_src}, 'added more reference groups';
    note explain $links;
};

subtest constructor_and_doc => $constructor_and_doc;
subtest collectMeta         => $collectMeta;
subtest collectOpenGraph    => $collectOpenGraph;
subtest collectReferences   => $collectReferences;

done_testing;
