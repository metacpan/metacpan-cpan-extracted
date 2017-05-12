use strict;
use warnings;
use Test::More 'no_plan';
use Dependencies::Searcher;

my $searcher = Dependencies::Searcher->new;

my @elements = $searcher->get_files;

my @uses = $searcher->get_modules("^use", @elements);

my @requires = $searcher->get_modules("^require", @elements);

for my $use (@uses) {
    isnt( $use, qr/^use.+;$/, "Pattern $use finish with a semicolon");
}

for my $require (@requires) {
    isnt( $require, qr/^requires.+;$/, "Pattern $require finish with a semicolon");
}
