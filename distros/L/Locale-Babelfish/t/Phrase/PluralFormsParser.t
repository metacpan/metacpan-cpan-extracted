=head1 stable test

ok

=cut

use utf8;
use strict;
use warnings;


use Test::Spec;
use Test::More::UTF8;

use Locale::Babelfish::Phrase::PluralFormsParser ();
use Locale::Babelfish::Phrase::Literal ();

describe "Locale::Babelfish::Phrase::PluralFormsParser" => sub {
    my $parser;

    before all => sub {
        $parser = new_ok "Locale::Babelfish::Phrase::PluralFormsParser";
    };

    describe init => sub {
        before all => sub {
            $parser->init( 'abc' );
        };

        it "should have no regular forms" => sub {
            cmp_deeply $parser->regular_forms, [];
        };

        it "should have no strict forms" => sub {
            cmp_deeply $parser->strict_forms, {};
        };

        it "should have phrase" => sub {
            cmp_deeply $parser->phrase, "abc";
        };
    };

    describe parse => sub {
        it "should parse regular forms" => sub {
            cmp_deeply $parser->parse("a|b|c"), {
                strict => {},
                regular => [
                    [ Locale::Babelfish::Phrase::Literal->new( text => 'a' ) ],
                    [ Locale::Babelfish::Phrase::Literal->new( text => 'b' ) ],
                    [ Locale::Babelfish::Phrase::Literal->new( text => 'c' ) ],
                ],
            };
        };

        it "should parse strict forms" => sub {
            cmp_deeply $parser->parse("=1a|=0 b|=4 c"), {
                strict => {
                    1 => [ Locale::Babelfish::Phrase::Literal->new( text => 'a' ) ],
                    0 => [ Locale::Babelfish::Phrase::Literal->new( text => 'b' ) ],
                    4 => [ Locale::Babelfish::Phrase::Literal->new( text => 'c' ) ],
                },
                regular => [],
            };
        };

        it 'should allow escaped "|" character' => sub {
            cmp_deeply $parser->parse("a\\||b"), {
                strict => {},
                regular => [
                    [ Locale::Babelfish::Phrase::Literal->new( text => 'a|' ) ],
                    [ Locale::Babelfish::Phrase::Literal->new( text => 'b' ) ],
                ],
            };
        };

        it "should not overwrite results of previous parsing" => sub {
            my $prev_results = $parser->parse("a|b|c");
            $parser->parse("d|a|b");
            cmp_deeply $prev_results, {
                strict => {},
                regular => [
                    [ Locale::Babelfish::Phrase::Literal->new( text => 'a' ) ],
                    [ Locale::Babelfish::Phrase::Literal->new( text => 'b' ) ],
                    [ Locale::Babelfish::Phrase::Literal->new( text => 'c' ) ],
                ],
            };
        };
    };
};

runtests  unless caller;
