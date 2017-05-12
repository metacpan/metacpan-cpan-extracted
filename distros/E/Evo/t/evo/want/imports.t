use Evo;
use Test::More;
use Scalar::Util 'refaddr';

use Evo '-Want *';

use Evo '-Want WANT_LIST';
use Evo '-Want WANT_SCALAR';
use Evo '-Want WANT_VOID';

is refaddr(WANT_LIST),   refaddr(WANT_LIST);
is refaddr(WANT_SCALAR), refaddr(WANT_SCALAR);
is refaddr(WANT_VOID),   refaddr(WANT_VOID);

done_testing;
