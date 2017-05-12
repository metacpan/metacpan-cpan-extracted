use warnings;
use Test::More;
use Boo;
use Boo::Far;
use Boo::Far::Faz;

is Boo::boo(), "Hello from Boo", 'perl sub';
is Boo::Far::boofar(), "Hello from Boo::Far", 'inline c 1 deep';
is Boo::Far::Faz::boofarfaz(), "Hello from Boo::Far::Faz", 'inline c 2 deep';
is $Boo::VERSION, '2.01', 'Boo $VERSION';
is $Boo::Far::VERSION, '2.01', 'Boo::Far $VERSION';
is $Boo::Far::Faz::VERSION, '2.01', 'Boo::Far::Faz $VERSION';

done_testing;
