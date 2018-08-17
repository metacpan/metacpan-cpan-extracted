use Test::More;

use lib 't/test';
use One;
use One::Two;
use One::Two::Three;
use One::Two::Three::Four;
use Globs qw/all/;

is(zzx(), 'Hello World');

is(One->new->one, 'Hello World');

is(One::Two->new->two, 'Whats');
is(One::Two->new->one, 'Hello World');

is(One::Two::Three->new->one, 'Hello World');
is(One::Two::Three->new->two, 'Whats');

is(One::Two::Three::Four->new->one, 'Hello World');
is(One::Two::Three::Four->new->two, 'Whats');

done_testing();
