use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );

use Test::More;
use Test::Exception;
use Test::RequiresInternet ( 'www.xe.com' => 80 );
use Class::Load qw/try_load_class/;
use Interchange6::Currency;

BEGIN {
    try_load_class('Finance::Currency::Convert::XE')
      or plan skip_all => "Finance::Currency::Convert::XE required";
}

my $obj;

lives_ok {
    $obj = Interchange6::Currency->new(
        locale          => 'en',
        currency_code   => 'GBP',
        value           => 3.41,
        converter_class => 'Finance::Currency::Convert::XE',
      )
}
'create $obj1 en/GBP currency object with value 3.41';

isa_ok $obj->converter, "Finance::Currency::Convert::XE", "->converter";

cmp_ok $obj, '==', 3.41, "check value is 3.41";

lives_ok { $obj->convert('JPY') } "convert to JPY in void context";

cmp_ok $obj, '>', 10, "check value is > 10 (should be much more)";

like $obj, qr/^¥\d+$/, "we now have JPY currency: $obj";

done_testing;
