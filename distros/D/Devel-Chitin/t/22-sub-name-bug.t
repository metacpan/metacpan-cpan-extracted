use strict;
use warnings;

use Test2::V0; no warnings 'void';
use lib 't/lib';
use TestHelper qw(db_continue do_test);
use Sub::Name;


my $main_serial = $Devel::Chitin::stack_serial[0]->[-1];
my @serials;
my $anon = Sub::Name::subname 'foo' => sub {
    push @serials, $Devel::Chitin::stack_serial[-1]->[-1];
    $DB::single=1;
    19;
    $DB::single=1;
    21;
};
$anon->(7, 8, 9);
*anon = $anon;
anon('a', 'b', 'c');

sub __tests__ {
    plan tests => 6;

    # first, we're in the sub via the subref $anon->()
    do_test { is_stackframe_serial($serials[0], 'subref stackframe serial matches') };
    db_continue;
    do_test { is_stackframe_serial($serials[0], 'subref stackframe serial still matches') };
    db_continue;

    # now, we're in the sub via anan()
    do_test { is_stackframe_serial($serials[1], 'sub call stackframe serial is different than first call') };
    do_test { isnt_stackframe_serial($serials[0], 'sub call stackframe serial matches expected') };
    db_continue;
    do_test { is_stackframe_serial($serials[1], 'sub call stackframe serial is still different than first call') };
    do_test { isnt_stackframe_serial($serials[0], 'sub call stackframe serial still matches expected') };
}

sub is_stackframe_serial {
    my($serial, $message) = @_;
    my $stackframe = TestHelper->stack->frame(0);
    is($stackframe->serial, $serial, $message);
}

sub isnt_stackframe_serial {
    my($serial, $message) = @_;
    my $stackframe = TestHelper->stack->frame(0);
    isnt($stackframe->serial, $serial, $message);
}
