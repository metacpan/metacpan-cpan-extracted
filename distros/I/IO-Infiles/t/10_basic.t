use IO::Infiles;
use Test::More tests=>4;

is @{[ <END>  ]} => 0;
is @{[ <FOO>  ]} => 1;
is @{[ <SUN1> ]} => 0;
is @{[ <SUN2> ]} => 3;


__END__ 
__FOO__ 
foo one
__SUN1__
__SUN2__
jdsu one
jdsu two
jdsu three
