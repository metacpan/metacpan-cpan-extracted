=head1 stable test

ok

=cut

use utf8;
use strict;
use warnings;

use Test::Spec;
use Test::More::UTF8;

use Locale::Babelfish::Phrase::Node ();


describe "Locale::Babelfish::Phrase::Node" => sub {
    my $node;

    before all => sub {
        $node = new_ok 'Locale::Babelfish::Phrase::Node', [ a => 1 ];
    };

    it "should save new args" => sub {
        is $node->{a}, 1;
    };

    describe to_perl_escaped_str => sub {
        it "should correcly escape string" => sub {
            my $str = "test \$test \@test \$test->{test} \\ \' \"";
            is eval($node->to_perl_escaped_str($str)), $str;
        };
    };

};

runtests  unless caller;
