use Test::Most;

use Font::Fontconfig::Pattern;

subtest 'parse basic line' => sub {
    
    cmp_deeply(
        Font::Fontconfig::Pattern::_parse_fc_line(
            '/Path/to/fonts/Test Font-Semi.test: '
        ),
        {
            file => '/Path/to/fonts/Test Font-Semi.test'
        },
        "file name is first and only result"
    );
    
    cmp_deeply(
        Font::Fontconfig::Pattern::_parse_fc_line(
            'Test Font,Try Letters'
        ),
        {
            family => 'Test Font,Try Letters'
        },
        "family is only result"
    );
    
    cmp_deeply(
        Font::Fontconfig::Pattern::_parse_fc_line(
            ':foo=one:bar=2,3:baz=two words:qux=three-four'
        ),
        {
            foo => 'one',
            bar => '2,3',
            baz => 'two words',
            qux => 'three-four',
        },
        "only elements as result"
    );
    
};



subtest 'parse complex line' => sub {
    
    cmp_deeply(
        Font::Fontconfig::Pattern::_parse_fc_line(
            '/Path/to/fonts/Test Font-Semi.test: Test Font,Try Letters'
        ),
        {
            file => '/Path/to/fonts/Test Font-Semi.test',
            family => 'Test Font,Try Letters',
        },
        "file name and family result"
    );
    
    cmp_deeply(
        Font::Fontconfig::Pattern::_parse_fc_line(
            '/Path/to/fonts/Test Font-Semi.test: Test Font,Try Letters:foo=one'
        ),
        {
            file => '/Path/to/fonts/Test Font-Semi.test',
            family => 'Test Font,Try Letters',
            foo => 'one',
        },
        "file name and family and elements result"
    );
    
    cmp_deeply(
        Font::Fontconfig::Pattern::_parse_fc_line(
            '/Path/to/fonts/Test Font-Semi.test: :foo=one:bar=2,3:baz=two words'
        ),
        {
            file => '/Path/to/fonts/Test Font-Semi.test',
            foo => 'one',
            bar => '2,3',
            baz => 'two words',
        },
        "file name and elements result"
    );
    
    cmp_deeply(
        Font::Fontconfig::Pattern::_parse_fc_line(
            'Test Font,Try Letters:foo=one:bar=2,3:baz=two words:qux=three-four'
        ),
        {
            family => 'Test Font,Try Letters',
            foo => 'one',
            bar => '2,3',
            baz => 'two words',
            qux => 'three-four',
        },
        "family and elements result"
    );
    
};



subtest 'parse empty line' => sub {
    
    cmp_deeply(
        Font::Fontconfig::Pattern::_parse_fc_line( '' ), { },
        "no result"
    );
    
};



subtest 'parse undef' => sub {
    
    is(
        Font::Fontconfig::Pattern::_parse_fc_line( ), undef,
        "undef result"
    );
    
};



done_testing;
