use Test::More;
use Inline::Perl6;

is(Inline::Perl6::p6_run("1;"), 1);
is(Inline::Perl6::p6_run("'yes'"), 'yes');

done_testing;
