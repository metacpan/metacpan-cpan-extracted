#! perl

use strict;
use warnings;

use Test::More;
use Test::Warnings ':all';

use Magic::Coerce;

coerce_int(my $first = 1);

is $first, 1, '$first = 1';
is_deeply(warning { $first = 2 }, [], 'Assigning an integer doesn\'t warn');
is $first, 2, '$first = 2';

like warning { $first = "abc" }, qr/Argument "abc" isn't numeric in /, 'Assigning a string warns';
is $first, 0, 'Value is 0 after failed numification';

coerce_float(my $second = 1.5);

is $second, 1.5, '$second = 1.5';
is_deeply(warning { $second = 2.0 }, [], 'Assigning a float doesn\'t warn');
is $second, 2, '$second = 2';

like warning { $second = 'abc' }, qr/Argument "abc" isn't numeric in /, 'Assigning a string warns';
is $second, 0, 'Value is 0 after failed numification';


coerce_string(my $third = "abc");

is $third, 'abc', '$third = 1';
is_deeply(warning { $third = [] }, [], 'Assigning an integer doesn\'t warn');
ok !ref($third), '$third is not a ref';
like $third, qr/^ARRAY/, '$third =~ /ARRAY/';

coerce_callback(my $fourth = 0, sub { $_[0] + 1 });
is $fourth, 1, '$fourth is magically 1';

$fourth = 41;
is $fourth, 42, '$fourth is 42';

done_testing;
