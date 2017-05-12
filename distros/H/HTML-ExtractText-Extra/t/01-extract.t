#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Deep;

use HTML::ExtractText::Extra;

{
    my $ext = HTML::ExtractText::Extra->new;
    can_ok($ext,
        qw/new  extract  error  last_results  separator  ignore_not_found
            whitespace  nbsp/
    );
    isa_ok($ext, 'HTML::ExtractText::Extra');
}

{ # check defaults
    my $ext = HTML::ExtractText::Extra->new;
    is $ext->whitespace, 1, 'default whitespace';
    is $ext->nbsp, 1, 'default nbsp';
    is $ext->separator, "\n", 'default separator';
    is $ext->ignore_not_found, 1, 'default ignore_not_found';
}

{ # check setting defaults through ->new
    my $ext = HTML::ExtractText::Extra->new(
        whitespace => 0,
        nbsp       => 0,
        separator  => '42',
        ignore_not_found => 0,
    );

    is $ext->whitespace, 0, 'change default whitespace through ->new';
    is $ext->nbsp, 0, 'change default nbsp through ->new';
    is $ext->separator, '42', 'change default separator through ->new';
    is $ext->ignore_not_found, 0,
        'changedefault ignore_not_found through ->new';
}

{ # check setting defaults through accessors
    my $ext = HTML::ExtractText::Extra->new;
    $ext->whitespace(0);
    $ext->nbsp(0);
    $ext->separator('42');
    $ext->ignore_not_found(0);

    is $ext->whitespace, 0, 'change default whitespace through accessor';
    is $ext->nbsp, 0, 'change default nbsp through accessor';
    is $ext->separator, '42', 'change default separator through accessor';
    is $ext->ignore_not_found, 0,
        'changedefault ignore_not_found through accessor';
}

diag "\nChecking advanced extraction procedures";
{ # check basic extraction
    my $ext = HTML::ExtractText::Extra->new;
    my $result = $ext->extract(
        {
            p => 'p',
            a => [ '[href]', qr/a.+/ ],
            b => [ 'b', sub { return "[$_[0]]" } ],
        },
        '<p>Paras1</p><a href="#">Linkas</a><p>Paras2</p><b>Foo</b>',
    );

    my $expected_result = {
        p => "Paras1\nParas2",
        a => 'Link',
        b => '[Foo]',
    };

    cmp_deeply $result, $expected_result, 'return of ->extract';
    cmp_deeply +{%$ext}, $expected_result, 'hash interpolation of object';
    cmp_deeply $ext->last_results, $expected_result,
        'return from ->last_results()';
}

diag "\nChecking stripping of trash";
{ # check stripping of trash
    my $ext = HTML::ExtractText::Extra->new;
    my $result = $ext->extract(
        {
            p => 'p',
            a => [ '[href]', qr/a.+/ ],
            b => [ 'b', sub { return "[$_[0]]" } ],
            span => 'span',
        },
        qq{<p> &nbsp;Paras1 </p><a href="#">Lin&nbsp;kas</a><p>Paras2</p><b>Foo&nbsp;\n</b><span> \n</span>},
    );

    my $expected_result = {
        p => "Paras1\nParas2",
        a => 'Lin k',
        b => '[Foo]',
        span => '',
    };

    cmp_deeply $result, $expected_result, 'return of ->extract';
    cmp_deeply +{%$ext}, $expected_result, 'hash interpolation of object';
    cmp_deeply $ext->last_results, $expected_result,
        'return from ->last_results()';
}

done_testing();