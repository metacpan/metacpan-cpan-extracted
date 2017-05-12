use strict; use warnings;
use Test::More tests => 6;
use Lingua::IND::Numbers;

my $number = Lingua::IND::Numbers->new;

eval { $number->to_string; };
like($@, qr/ERROR: Undefined number/);

eval { $number->to_string('a'); };
like($@, qr/ERROR: Invalid number/);

eval { $number->to_string(-1); };
like($@, qr/ERROR: Only positive number/);

eval { $number->to_string(1.2); };
like($@, qr/ERROR: No decimal number/);

eval { $number->to_string('1,000'); };
like($@, qr/ERROR: Invalid number/);

eval { $number->to_string(1412191612000000000); };
like($@, qr/ERROR: No representation in Indian Numbering System/);

done_testing();
