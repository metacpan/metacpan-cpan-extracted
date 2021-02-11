use strict;
use warnings;

BEGIN {
    use Test::More;
    our $tests = 2;
    eval "use Test::NoWarnings";
    $tests++ unless ($@);
    plan tests => $tests;
}

use_ok( 'List::Uniq', ':all' );

# rt.cpan.org #37837, reported by Peter Caffin
# don't emit warnings on an undef element
my @authors;
is_deeply scalar uniq(undef), [undef], 'list with undef elements';
