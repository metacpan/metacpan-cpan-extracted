use strict;
use Test::More 0.98;
use List::Flat(qw/flat flat_f flat_r/);

note('Use Ref::Util for checking array references');

unless ( eval { require Ref::Util; 1 } ) {
    plan skip_all => 'No Ref::Util';
}

require './t/lib/list_flat.pl';

done_testing;
