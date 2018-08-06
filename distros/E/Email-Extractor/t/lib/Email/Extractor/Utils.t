use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN { use_ok( 'Email::Extractor::Utils', qw(:ALL) ); }

subtest "looks_like_url" => sub {
    ok !looks_like_url('some str'),          'str not url';
    ok looks_like_url('http://fabmarkt.ru'), 'http url';
    is 'http://fabmarkt.ru', looks_like_url('http://fabmarkt.ru'),
      'http url return self';
    ok looks_like_url('https://fabmarkt.ru'), 'https url';
    is 'https://fabmarkt.ru', looks_like_url('https://fabmarkt.ru'),
      'https url return self';
};

subtest "looks_like_rel_link" => sub {
    ok looks_like_rel_link('/contacts'),                    'rel link';
    ok !looks_like_rel_link('http://example.com/contacts'), 'full link';
};

subtest "looks_like_file" => sub {
    ok looks_like_file('file:///htmls/regexp_test_1.html'),
      'path with extension is file';
    ok !looks_like_file('htmls/regexp_test_1.html'), 'no file://';
    ok !looks_like_file('http://fabmarkt.ru'),       'url is not file';
    ok !looks_like_file('http://дрг62.рф'),          'cyrillic url is not file';
};

subtest "absolutize_links_array" => sub {

    my $a = [ '/contacts', '/about', '/test' ];
    my $b = [
        'http://example.com/contacts', 'http://example.com/about',
        'http://example.com/test'
    ];
    my $dname = 'http://example.com';

    dies_ok { absolutize_links_array($a) }
    'expecting to die when no dname provided';

    is_deeply absolutize_links_array( $a, $dname ), $b, 'all relative';

    $a->[0] = 'http://example.com/contacts';
    is_deeply absolutize_links_array( $a, $dname ), $b, 'one absolute';

};

my $html_chunks = [
    '<a href="/test">Example</a>',
    '<a href="/test2">Example2</a>',
    '<a href="/lalala">Lalala</a>'
];
my $links = [ '/test', '/test2', '/lalala' ];

subtest "find_all_links" => sub {
    is_deeply find_all_links( join( '', @$html_chunks ) ), $links,
      'found all links';
};

subtest "find_links_by_text" => sub {

    # remember is that grep in find_links_by_text is exact

    is_deeply find_links_by_text( join( '', @$html_chunks ), 'Example2' ),
      [ $links->[1] ], 'all ok';

    is_deeply find_links_by_text( $html_chunks->[0], 'Example' ),
      [ $links->[0] ], 'one chunk ok';

    is_deeply
      find_links_by_text(
        $html_chunks->[0] . '' . $html_chunks->[1], 'Example'
      ),
      [ $links->[0] ],
      'two chunks ok';

    is_deeply
      find_links_by_text( join( '', @$html_chunks ), 'Lalala' ),
      [ $links->[2] ],
      'three chunks ok';

};

my $l = [
    'http://example.com/js/html5.js',
    'http://example.com/js/html5.js?ver=1.5.3&a=1',
    'http://example.com/2018/03/',
    'https://a.com/index.JPG',
    'http://vk.com'
];

subtest "remove_query_params" => sub {
    my $res = $l;
    $res->[1] = 'http://example.com/js/html5.js';
    is_deeply remove_query_params($l), $res,
      'Params removed and no query urls leave untouched';
};

subtest "drop_asset_links" => sub {
    is_deeply drop_asset_links($l), [ $l->[2], $l->[4] ],
      'asset links droped, queried and no query both';
};

subtest "drop_anchor_links" => sub {

    is_deeply
      drop_anchor_links( [ '/test', '#rec' ] ),
      ['/test'],
      'asset links droped, queried and no query both';

};

subtest "remove_external_links" => sub {
    my $res = $l;

    dies_ok { remove_external_links($l) }
    'expecting to die when no dname provided';

    is_deeply
      remove_external_links( $l, 'http://vk.com' ),
      [ $l->[4] ],
      'one link';

    is_deeply
      remove_external_links( $l, 'http://example.com' ),
      [ $l->[0], $l->[1], $l->[2] ],
      'two links';
};

subtest "load_addr_to_str" => sub {

    my $content = '<p>someone@example.com<p>';
    no warnings 'redefine';

    local *LWP::UserAgent::get = sub {
        my $r = HTTP::Response->new( undef, undef, undef, $content );
        return $r;
    };

    is load_addr_to_str('http://example.com'), $content, 'loads html fine';

    # local *File::Slurp::read_file = sub {
    #     return $content;
    # };
    #
    # is load_addr_to_str('test.html'), $content, 'loads file fine';

};

done_testing;
