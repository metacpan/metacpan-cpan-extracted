use Test::More;
use lib 't/test';

eval "use Kaput qw/okay/";
like($@, qr/define your %EX export hash/, 'no %EX defined in Kaput.pm');

eval "use Kaput2 qw/!okay/";
like($@, qr/Cant export symbol !/, 'symbol not exported');

eval "use Our qw/kaput/";
like($@, qr/kaput is not exported/, 'not exported');

our $scalar = 'kaput';
use Our qw/$scalar/;
is($scalar, 'kaput', 'not overriden');

sub one { 'Goodbye World' }
use One qw/one/;
is(one(), 'Goodbye World', 'not overriden');

done_testing;
