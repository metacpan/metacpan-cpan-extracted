use strict;
use warnings;
use Test::More;

use HTTP::AcceptLanguage;

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

# This behavior was changed.
# https://github.com/yappo/p5-HTTP-AcceptLanguage/issues/1
subtest 'flat quality' => sub {
    my $parser = HTTP::AcceptLanguage->new('en, ja');
    is($parser->match(qw/ en ja /), 'en');

    $parser = HTTP::AcceptLanguage->new('en, ja');
    is($parser->match(qw/ ja en /), 'en');

    $parser = HTTP::AcceptLanguage->new('ja, en');
    is($parser->match(qw/ en ja /), 'ja');

    $parser = HTTP::AcceptLanguage->new('ja, en');
    is($parser->match(qw/ ja en /), 'ja');
};

subtest 'prefix tag' => sub {
    my $parser = HTTP::AcceptLanguage->new('en-us');
    is($parser->match(qw/ en /), 'en');

    $parser = HTTP::AcceptLanguage->new('en-us, ja');
    is($parser->match(qw/ en ja /), 'en');

    $parser = HTTP::AcceptLanguage->new('en-us, ja');
    is($parser->match(qw/ ja en /), 'en');

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
        is($parser->match(qw/ en en-us /), 'en-us');

        $parser = HTTP::AcceptLanguage->new('en-us, en');
        is($parser->match(qw/ en-us en /), 'en-us');

        $parser = HTTP::AcceptLanguage->new('en-gb, en-us, en');
        is($parser->match(qw/ en-us en /), 'en'); # same as en-gb;q=0.9, en-us;q=0.8, en;q=0.7
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
    is($parser->match(qw/ en-us ja en /), 'en');

    $parser = HTTP::AcceptLanguage->new('en;q=0.1, en-us;q=0.2');
    is($parser->match(qw/ en ja en-us /), 'en-us');

    $parser = HTTP::AcceptLanguage->new('en;q=0.2, en-us;q=0.1');
    is($parser->match(qw/ en-us ja en /), 'en');


    $parser = HTTP::AcceptLanguage->new('th;q=0.1, ja;q=0.1, en-gb;q=0.2, en-us;q=0.2, en;q=0.1');
    is($parser->match(qw/ en-us ja en /), 'en'); # same as en-gb;q=0.29, en-us;q=0.28, th;q=0.19, ja;q=0.18, en;q=0.17

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
    is($parser->match(qw/ en ja /), 'ja');

    $parser = HTTP::AcceptLanguage->new('ja, *;q=0.3');
    is($parser->match(qw/ en ja /), 'ja');

    $parser = HTTP::AcceptLanguage->new('*, da');
    is($parser->match(qw/ ja da /), 'ja');

    $parser = HTTP::AcceptLanguage->new('*, zh-tw');
    is($parser->match(qw/ en-US ja da /), 'en-US');

};

done_testing;
