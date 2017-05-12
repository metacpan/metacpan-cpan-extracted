use strict;
use Test::More;
use Test::Exception;
use MARC::Spec::Comparisonstring;

my $cmp = MARC::Spec::Comparisonstring->new('this\sis\sa\stest');
ok $cmp->raw eq 'this\sis\sa\stest', 'raw';
ok $cmp->comparable eq 'this is a test', 'comparable';

throws_ok {MARC::Spec::Comparisonstring->new('this|is|wrong');} qr/^MARCspec Comparisonstring exception.*/, 'MARCspec Comparisonstring exception';
done_testing;