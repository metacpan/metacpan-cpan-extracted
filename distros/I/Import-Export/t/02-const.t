use Test::More;

use lib 't/test';
use Const;
use Const::Easy;

is(Const::one, 'ro');

is(Const::Easy->new->hello, 'ro');
is_deeply(Const::Easy->new->listing, { one => 'two' });
done_testing();
