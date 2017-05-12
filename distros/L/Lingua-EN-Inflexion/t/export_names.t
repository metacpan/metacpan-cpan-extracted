use Test::More;
use Lingua::EN::Inflexion { inflect => 'prettily', noun => 'N', verb => 'V'};

my @results = 1..10;
is prettily "<#i:$#results> <N:item> <V:was> found",      "10 items were found"  => 'prettily';

is '10 '.N('item')->plural.' '.V('was')->plural.' found', "10 items were found"  => 'N() / V()';

done_testing();
