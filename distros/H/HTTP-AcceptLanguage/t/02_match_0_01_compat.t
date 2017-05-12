use strict;
use warnings;
use Test::More;

use HTTP::AcceptLanguage;

# This test case checks 0.01 compatibility mode.
# Test case is taken from version 0.01 test suite.
local $HTTP::AcceptLanguage::MATCH_PRIORITY_0_01_STYLE = 1;

subtest 'empty' => sub {
    subtest 'undef' => sub {
        my $parser = HTTP::AcceptLanguage->new;
        is($parser->match(), undef);

        $parser = HTTP::AcceptLanguage->new;
        is($parser->match(''), undef);
    };
    subtest 'string' => sub {
        my $parser = HTTP::AcceptLanguage->new('');
        is($parser->match(), undef);

        $parser = HTTP::AcceptLanguage->new('');
        is($parser->match(''), undef);
    };
    subtest 'has header' => sub {
        my $parser = HTTP::AcceptLanguage->new('ja');
        is($parser->match(), undef);

        $parser = HTTP::AcceptLanguage->new('en');
        is($parser->match(''), undef);
    };
};

subtest 'empty header' => sub {
    my $parser = HTTP::AcceptLanguage->new;
    is($parser->match(qw/ en ja /), 'en');

    $parser = HTTP::AcceptLanguage->new('');
    is($parser->match(qw/ ja en /), 'ja');
};

subtest 'flat quality' => sub {
    my $parser = HTTP::AcceptLanguage->new('en, ja');
    is($parser->match(qw/ en ja /), 'en');

    $parser = HTTP::AcceptLanguage->new('en, ja');
    is($parser->match(qw/ ja en /), 'ja');

    $parser = HTTP::AcceptLanguage->new('ja, en');
    is($parser->match(qw/ en ja /), 'en');

    $parser = HTTP::AcceptLanguage->new('ja, en');
    is($parser->match(qw/ ja en /), 'ja');
};

subtest 'prefix tag' => sub {
    my $parser = HTTP::AcceptLanguage->new('en-us');
    is($parser->match(qw/ en /), 'en');

    $parser = HTTP::AcceptLanguage->new('en-us, ja');
    is($parser->match(qw/ en ja /), 'ja');

    $parser = HTTP::AcceptLanguage->new('en-us, ja');
    is($parser->match(qw/ ja en /), 'ja');

    subtest 'priority of full match' => sub {
        $parser = HTTP::AcceptLanguage->new('en-us');
        is($parser->match(qw/ en en-us /), 'en-us');

        $parser = HTTP::AcceptLanguage->new('en-us');
        is($parser->match(qw/ en-us en /), 'en-us');

        $parser = HTTP::AcceptLanguage->new('en');
        is($parser->match(qw/ en en-us /), 'en');

        $parser = HTTP::AcceptLanguage->new('en');
        is($parser->match(qw/ en-us en /), 'en');
    };

    subtest 'order by input list' => sub {
        $parser = HTTP::AcceptLanguage->new('en-us, en');
        is($parser->match(qw/ en en-us /), 'en');

        $parser = HTTP::AcceptLanguage->new('en-us, en');
        is($parser->match(qw/ en-us en /), 'en-us');
    };

    subtest 'unsupported of server side prefix tag' => sub {
        $parser = HTTP::AcceptLanguage->new('en-us');
        is($parser->match(qw/ en-gb /), undef);

        $parser = HTTP::AcceptLanguage->new('en');
        is($parser->match(qw/ en-gb /), undef);
    };
};

subtest 'quality' => sub {
    my $parser = HTTP::AcceptLanguage->new('en;q=0.1, ja');
    is($parser->match(qw/ en ja /), 'ja');

    $parser = HTTP::AcceptLanguage->new('en;q=0.1, ja;q=0.2');
    is($parser->match(qw/ en ja /), 'ja');

    $parser = HTTP::AcceptLanguage->new('en;q=0.1, en-us;q=0.1');
    is($parser->match(qw/ en ja en-us /), 'en');

    $parser = HTTP::AcceptLanguage->new('en;q=0.1, en-us;q=0.1');
    is($parser->match(qw/ en-us ja en /), 'en-us');

    $parser = HTTP::AcceptLanguage->new('en;q=0.1, en-us;q=0.2');
    is($parser->match(qw/ en ja en-us /), 'en-us');

    $parser = HTTP::AcceptLanguage->new('en;q=0.2, en-us;q=0.1');
    is($parser->match(qw/ en-us ja en /), 'en');

    subtest 'duplicated tag is order by quality' => sub {
        $parser = HTTP::AcceptLanguage->new('ja;q=0.1, en;q=0.5, ja;q=0.6');
        is($parser->match(qw/ en-us ja en /), 'ja');
    };
};

subtest 'case sensitive' => sub {
    my $parser = HTTP::AcceptLanguage->new('En');
    is($parser->match(qw/ en /), 'en');

    $parser = HTTP::AcceptLanguage->new('eN');
    is($parser->match(qw/ En /), 'En');

    $parser = HTTP::AcceptLanguage->new('En, zh-Tw');
    is($parser->match(qw/ zH /), 'zH');

    $parser = HTTP::AcceptLanguage->new('En, Zh-Tw');
    is($parser->match(qw/ zH-tw /), 'zH-tw');
};

subtest 'wildcard' => sub {
    my $parser = HTTP::AcceptLanguage->new('*');
    is($parser->match(qw/ en ja /), 'en');

    $parser = HTTP::AcceptLanguage->new('ja, *');
    is($parser->match(qw/ en ja /), 'en');

    $parser = HTTP::AcceptLanguage->new('ja, *;q=0.3');
    is($parser->match(qw/ en ja /), 'ja');

    $parser = HTTP::AcceptLanguage->new('*, da');
    is($parser->match(qw/ ja da /), 'ja');

    $parser = HTTP::AcceptLanguage->new('*, zh-tw');
    is($parser->match(qw/ en-US ja da /), 'en-US');

};

done_testing;
