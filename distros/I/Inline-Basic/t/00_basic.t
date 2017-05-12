use strict;
use Test::More 'no_plan';

use Inline 'Basic';

is FNA(1), 6, 'FNA()';
is FNB(2), 20, 'FNB()';

__END__
__Basic__
010 DEF FNA(X) = INT(X + 5)
020 DEF FNB(X) = INT(X * 10)
