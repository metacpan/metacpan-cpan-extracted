package t::Class2;

use Mew;

has _num     => PositiveNum;
has _bool    => Optional[Bool];
has _type    => ( Str, default => 'text/html');
has _init    => ( Optional[Str], init_arg => 'initizer');
has chained  => ( Optional[Str], chained => 1 );
has chained2 => ( Optional[Num], chained => 1 );

has [qw/ar1 -_ar2/] => Str;

has _cust => ( is => 'rw', default => 'Zoffix' );
1;