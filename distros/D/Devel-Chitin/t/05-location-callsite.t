use strict;
use warnings;

use Test2::V0; no warnings 'void';
use lib 't/lib';
use TestHelper qw(has_callsite ok_location db_continue do_test);
use Devel::Chitin::Location;

$DB::single=1;
for ( 1 .. 2 ) {
    $DB::single=1;
    12;
}
$DB::single=1; 14; $DB::single=1; 14;

sub __tests__ {
    if (has_callsite) {
        plan tests => 4;
    } else {
        plan skip_all => 'Devel::Callsite not available';
    }

    my $loop_callsite;
    db_continue;
    do_test {
        my $loc = shift;
        ok($loop_callsite = $loc->callsite, 'Getting callsite inside loop');
    };

    db_continue;
    do_test {
        my $loc = shift;
        is($loc->callsite, $loop_callsite, 'Callsite same second time in loop');
    };

    my $sequential_callsite;
    db_continue;
    do_test {
        my $loc = shift;
        ok($sequential_callsite = $loc->callsite, 'Getting callsite for sequential statement');
    };

    db_continue;
    do_test {
        my $loc = shift;
        isnt($loc->callsite, $sequential_callsite, 'Second in sequence has different callsite');
    };
}
