use strict;
use warnings;

use Test::More;
use Devel::Unwind;

use lib 't/lib';
use Foobar;

my $x;
mark FOO {
    eval {
        $x = 'foo';
        Foobar::unwind();
        fail "Execution resumes after sub call that unwinds inside eval";
    } or do {
        fail "Execution resumes in do block";
    };
    fail "Execution resumes inside mark block";
};
pass "Execution resumes after mark block";
is($x,'foo', 'Variable correctly set after mark block');
done_testing;
