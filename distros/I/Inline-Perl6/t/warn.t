use Test::More;

use Inline::Perl6;

v6::run('warn "foo";');

ok(1);

done_testing;
