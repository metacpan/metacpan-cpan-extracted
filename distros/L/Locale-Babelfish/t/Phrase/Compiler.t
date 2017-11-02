=head1 stable test

ok

=cut

use utf8;
use strict;
use warnings;


use Test::Spec;
use Test::Exception;
use Test::More::UTF8;

use Locale::Babelfish::Phrase::Compiler ();

describe "Locale::Babelfish::Phrase::Compiler" => sub {
    my $compiler;

    before all => sub {
        $compiler = new_ok 'Locale::Babelfish::Phrase::Compiler';
    };

    it "should compile literal" => sub {
        my $res = $compiler->compile([
            Locale::Babelfish::Phrase::Literal->new( text => '"разное"' ),
        ]);

        is $res, '"разное"';
    };

    it "should compile variables" => sub {
        my $res = $compiler->compile([
            Locale::Babelfish::Phrase::Literal->new( text => 'итого ' ),
            Locale::Babelfish::Phrase::Variable->new( name => 'count' ),
            Locale::Babelfish::Phrase::Literal->new( text => ' рублей' ),
        ]);

        is $res->({ count => 5 }), 'итого 5 рублей';
    };

    it "should compile plurals" => sub {
        my $res = $compiler->compile([
            Locale::Babelfish::Phrase::Literal->new( text => 'итого ' ),
            Locale::Babelfish::Phrase::Variable->new( name => 'count' ),
            Locale::Babelfish::Phrase::PluralForms->new(
                locale => 'ru_RU',
                name => 'count',
                forms => {
                    strict => {},
                    regular => [
                        [
                            Locale::Babelfish::Phrase::Literal->new( text => ' рубль' ),
                        ],
                        [
                            Locale::Babelfish::Phrase::Literal->new( text => ' рубля' ),
                        ],
                        [
                            Locale::Babelfish::Phrase::Literal->new( text => ' рублей' ),
                        ],
                    ]
                }
            ),
        ]);

        is $res->({ count => 1 }), 'итого 1 рубль';
        is $res->({ count => 5 }), 'итого 5 рублей';
    };

};



runtests  unless caller;
