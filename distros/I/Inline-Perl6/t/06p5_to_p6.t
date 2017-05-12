use 5.10.0;
use strict;
use warnings;
use utf8;

use Encode qw(encode);
use Test::More;
use Inline::Perl6;

Inline::Perl6::p6_run(q[
    &GLOBAL::identity = sub ($value) { return $value };
]);

my $foo = bless {}, 'Foo';

foreach my $obj ('abcö', encode('latin-1', 'äbc'), 24, 2.4, [1, 2], {a => 1, b => 2}, undef, $foo) {
    is_deeply Inline::Perl6::call('identity', $obj), $obj, "Can round-trip " . (ref $obj // $obj);
}

done_testing;
