use strict;
use Test::More;
use Test::Exception;
use MARC::Spec::Comparisonstring;
use MARC::Spec::Parser;

my $cmp = MARC::Spec::Comparisonstring->new('this\sis\sa\stest');
ok $cmp->raw eq 'this\sis\sa\stest', 'raw';
ok $cmp->comparable eq 'this is a test', 'comparable';

throws_ok {MARC::Spec::Comparisonstring->new('this|is|wrong');} qr/^MARCspec Comparisonstring exception.*/, 'MARCspec Comparisonstring exception';


my $parser = MARC::Spec::parse('245$a{245$a~\/}');
ok $parser->subfields->[0]->subspecs->[0]->right->raw eq '/', 'subspec right raw';

done_testing;