package FormValidator::LazyWay::Rule::Number::EN;

use strict;
use warnings;

sub int   {'integer'}
sub uint  {'unsigned integer'}
sub float {'float'}
sub ufloat{'unsigned float'}
sub range {'over $_[min] and under $_[max]'}

1;

