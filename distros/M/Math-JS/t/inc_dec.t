use strict;
use warnings;
use Math::JS;
use Test::More;

my $js = Math::JS->new(Math::JS::MIN_SLONG);
cmp_ok($js->{type}, 'eq', 'sint32', "1t: type is 'sint32'");
cmp_ok($js->{val}, '==', -2147483648, "1v: value is -2147483648");
$js--;
cmp_ok($js->{type}, 'eq', 'number', "2t: type is 'number'");
cmp_ok($js->{val}, '==', -2147483649, "2v: value is -2147483649");
$js++;
cmp_ok($js->{type}, 'eq', 'sint32', "3t: type is 'sint32'again");
cmp_ok($js->{val}, '==', -2147483648, "3v:value is -2147483648 again");

$js = Math::JS->new(Math::JS::MAX_SLONG);
cmp_ok($js->{type}, 'eq', 'sint32', "4t: type is 'sint32'");
cmp_ok($js->{val}, '==', 2147483647, "4v: value is 2147483647");
$js++;
cmp_ok($js->{type}, 'eq', 'uint32', "5t: type is 'uint32'");
cmp_ok($js->{val}, '==', 2147483648, "5v:value is 2147483648");
$js--;
cmp_ok($js->{type}, 'eq', 'sint32', "6t: type is 'sint32' again");
cmp_ok($js->{val}, '==', 2147483647, "6v: value is 2147483647 again");

$js = Math::JS->new(Math::JS::MAX_ULONG);
cmp_ok($js->{type}, 'eq', 'uint32', "7t: type is 'uint32'");
cmp_ok($js->{val}, '==', 4294967295, "7v: value is 4294967295");
$js++;
cmp_ok($js->{type}, 'eq', 'number', "8t: type is 'number'");
cmp_ok($js->{val}, '==', 4294967296, "8v: value is 4294967296");
$js--;
cmp_ok($js->{type}, 'eq', 'uint32', "9t: type is 'uint32' again");
cmp_ok($js->{val}, '==', 4294967295, "9v: value is 4294967295 again");

done_testing();
