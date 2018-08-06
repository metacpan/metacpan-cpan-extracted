package t::Class3;

use Mew;

has -_bool    => Maybe[Bool];
has -_init    => ( Maybe[Str], init_arg => 'initizer');
has -chained  => ( Maybe[Str], chained => 1 );
has -chained2 => ( Maybe[Num], chained => 1 );

1;
