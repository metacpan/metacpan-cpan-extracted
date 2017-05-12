
#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('HTTP::Headers::ActionPack::LinkHeader');
}

=pod

Examples taken from http://tools.ietf.org/html/rfc5988

=cut

sub test_link {
    my $link = shift;

    isa_ok($link, 'HTTP::Headers::ActionPack::LinkHeader');

    is($link->href, 'http://example.com/TheBook/chapter2', '... got the link we expected');
    is($link->rel, 'previous', '... got the relation we expected');
    is_deeply(
        $link->params,
        { rel => 'previous', title => 'previous chapter' },
        '... got the parameters we expected'
    );

    ok($link->relation_matches('previous'), '... relation matching works');
    ok($link->relation_matches('Previous'), '... relation matching works');
    ok($link->relation_matches('PREVIOUS'), '... relation matching works');

    is(
        $link->as_string,
        '<http://example.com/TheBook/chapter2>; rel="previous"; title="previous chapter"',
        '... got the string we expected'
    );
}

test_link(
    HTTP::Headers::ActionPack::LinkHeader->new_from_string(
        '<http://example.com/TheBook/chapter2>;rel="previous";title="previous chapter"'
    )
);

test_link(
    HTTP::Headers::ActionPack::LinkHeader->new(
        '<http://example.com/TheBook/chapter2>' => (
            rel   => "previous",
            title => "previous chapter"
        )
    )
);

test_link(
    HTTP::Headers::ActionPack::LinkHeader->new(
        'http://example.com/TheBook/chapter2' => (
            rel   => "previous",
            title => "previous chapter"
        )
    )
);

{
    my $link = HTTP::Headers::ActionPack::LinkHeader->new_from_string(
        '</>; rel="http://example.net/foo"'
    );
    isa_ok($link, 'HTTP::Headers::ActionPack::LinkHeader');

    is($link->href, '/', '... got the link we expected');
    is($link->rel, 'http://example.net/foo', '... got the relation we expected');
    is_deeply(
        $link->params,
        { rel => 'http://example.net/foo' },
        '... got the parameters we expected'
    );

    ok($link->relation_matches('http://example.net/foo'), '... relation matching works');
    ok(!$link->relation_matches('HTTP://example.net/foo'), '... relation matching works');

    is(
        $link->as_string,
        '</>; rel="http://example.net/foo"',
        '... got the string we expected'
    );
}

{
    my $link = HTTP::Headers::ActionPack::LinkHeader->new_from_string(
        q{</TheBook/chapter2>; rel="previous"; title*="UTF-8'de'letztes%20Kapitel"}
    );
    isa_ok($link, 'HTTP::Headers::ActionPack::LinkHeader');

    is($link->href, '/TheBook/chapter2', '... got the link we expected');
    is($link->rel, 'previous', '... got the relation we expected');
    is_deeply(
        $link->params,
        {
            'rel'    => 'previous',
            'title*' => {
                encoding => 'UTF-8',
                language => 'de',
                content  => 'letztes Kapitel'
            }
        },
        '... got the parameters we expected'
    );

    is(
        $link->as_string,
        q{</TheBook/chapter2>; rel="previous"; title*="UTF-8'de'letztes%20Kapitel"},
        '... got the string we expected'
    );
}

{
    my $link = HTTP::Headers::ActionPack::LinkHeader->new_from_string(
        q{</TheBook/chapter4>; rel="next"; title*=UTF-8'de'n%c3%a4chstes%20Kapitel}
    );
    isa_ok($link, 'HTTP::Headers::ActionPack::LinkHeader');

    is($link->href, '/TheBook/chapter4', '... got the link we expected');
    is($link->rel, 'next', '... got the relation we expected');
    is_deeply(
        $link->params,
        {
            'rel'    => 'next',
            'title*' => {
                encoding => 'UTF-8',
                language => 'de',
                content  => 'nächstes Kapitel'
            }
        },
        '... got the parameters we expected'
    );

    is(
        $link->as_string,
        q{</TheBook/chapter4>; rel="next"; title*="UTF-8'de'n%C3%A4chstes%20Kapitel"},
        '... got the string we expected'
    );
}

done_testing;