use strict;
use warnings;
use Test::More;

# this is needed to avoid false passes if was done first without 'info'
use Inline CPP => config => force_build => 1, clean_after_build => 0;

use Inline 'CPP';

is(sum(), 0, "Var-args: 0" );
is(sum(1), 1, "Var-args: 1" );
is(sum(1, 2), 3, "Var-args: 2" );
is(sum(1, 2, 3), 6, "Var-args: 3" );
is(sum(1, 2, 3, 4), 10, "Var-args: 4" );
is(sum(1, 2, 3, 4, 5), 15, "Var-args: 5" );

done_testing();

__END__
__CPP__

int sum(...) {
    Inline_Stack_Vars;
    int s = 0;
    for (int i=0; i<items; i++)
    {
    int tmp = SvIV(Inline_Stack_Item(i));
    s += tmp;
    }
    return s;
}
