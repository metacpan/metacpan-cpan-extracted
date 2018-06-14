use warnings;
use strict;

use Test::More;

plan tests => 1;


use Keyword::Declare;

keyword DEVELOPMENT( Block $block) {
    if ( $ENV{PERL_KEYWORD_DEVELOPMENT} ) {
        return $block;
    }
    return "# Code Omitted";
}

my $aref = [ 1, 2, 3 ];

DEVELOPMENT {
    my @example = map { $_ => $_ } $aref->@*;
    print join '-' => @example;
}

ok 1;

done_testing();

