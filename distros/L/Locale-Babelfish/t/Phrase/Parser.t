=head1 stable test

ok

=cut

use utf8;
use strict;
use warnings;


use Test::Spec;
use Test::Exception;
use Test::More::UTF8;

use Locale::Babelfish::Phrase::Parser ();


describe "Locale::Babelfish::Phrase::Parser" => sub {
    my $parser;

    before all => sub {
        $parser = new_ok 'Locale::Babelfish::Phrase::Parser';
    };

    it "should die on undef" => sub {
        throws_ok { $parser->parse( undef) } qr<No phrase given>;
    };

    it "should parse empty text" => sub {
        cmp_deeply $parser->parse(""), [
            noclass({ text => "" }),
        ];
    };

    it "should parse simple text as one literal" => sub {
        cmp_deeply $parser->parse("простой text"), [
            noclass({ text => "простой text" }),
        ];
    };

    it "should escape backslashed characters in literals" => sub {
        cmp_deeply $parser->parse("si\\mple text"), [
            noclass({ text => "simple text" }),
        ];
    };

    it "should parse variable substitutions" => sub {
        cmp_deeply $parser->parse("some text with #{ var } subst"), [
            noclass({ text => "some text with " }),
            noclass({ name => "var" }),
            noclass({ text => " subst" }),
        ];
    };

    it "should die on no variable" => sub {
        throws_ok { $parser->parse("some text with #{ } subst") } qr<No variable>;
    };

    it "should die on bad variable name" => sub {
        throws_ok { $parser->parse("some text with #{ var-вар } subst") } qr<var-вар>;
    };

    it "should parse plural forms without variable name" => sub {
        cmp_deeply $parser->parse("some ((=0 no nails|one nail|#{count} nails)) here"), noclass([
            { text => "some " },
            {
                forms => {
                    regular => [
                        [ { text => "one nail" } ],
                        [
                            { name => "count" },
                            { text => " nails" },
                        ],
                    ],
                    strict => {
                        0 => [
                            { text => 'no nails' },
                        ]
                    },
                },
                name => 'count',
                locale => undef,
            },
            { text => " here" },
        ]);
    };

    it "should parse plural forms with variable name" => sub {
        cmp_deeply $parser->parse("some ((=0 no nails|one nail|#{val} nails)):val here"), noclass([
            { text => "some " },
            {
                forms => {
                    regular => [
                        [ { text => "one nail" } ],
                        [
                            { name => "val" },
                            { text => " nails" },
                        ],
                    ],
                    strict => {
                        0 => [
                            { text => 'no nails' },
                        ]
                    },
                },
                name => 'val',
                locale => undef,
            },
            { text => " here" },
        ]);
    };

    it "should parse plural forms with variable name without ending dot" => sub {
        cmp_deeply $parser->parse("some ((=0 no nails|one nail|#{val} nails)):val. here"), noclass([
            { text => "some " },
            {
                forms => {
                    regular => [
                        [ { text => "one nail" } ],
                        [
                            { name => "val" },
                            { text => " nails" },
                        ],
                    ],
                    strict => {
                        0 => [
                            { text => 'no nails' },
                        ]
                    },
                },
                name => 'val',
                locale => undef,
            },
            { text => ". here" },
        ]);
    };
};


runtests  unless caller;
