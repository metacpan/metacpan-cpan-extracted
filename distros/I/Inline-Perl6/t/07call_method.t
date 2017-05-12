use 5.10.0;
use strict;
use warnings;
use utf8;

use Test::More;
use Inline::Perl6;

Inline::Perl6::p6_run(q[
    class GLOBAL::Foo {
        method foo() {
            return 'foo';
        }
    }

    &GLOBAL::new_foo = sub () {
        return Foo.new;
    }
]);

is Inline::Perl6::call('new_foo')->foo, 'foo';

done_testing;

