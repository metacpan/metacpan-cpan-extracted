use strict;
use warnings;

use Test::More tests => 5;

eval 'use Devel::LineName;';
like $@, qr/Devel::LineName must be use\(\)ed with two args/,
     "bare use";

eval 'use Devel::LineName "foo";';
like $@, qr/Devel::LineName must be use\(\)ed with two args/,
     "1arg use";

eval 'use Devel::LineName "---", "foo";';
like $@, qr/Invalid Devel::LineName line naming pragma \[---\]/,
     "bad pragma";

eval 'use Devel::LineName foo => 12;';
like $@, qr/2nd arg to 'use Devel::LineName' must be a hashref/,
     "bad hashref";

eval 'my %x; use Devel::LineName Carp => \%x;';
like $@, qr/Devel::LineName pragma \[Carp\] clashes with the Carp module/,
     "pragma clash";
