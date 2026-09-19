########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Testy;
use v5.40;
use FindBin::libs;

use Test::More;

use LinkedList::Single::TestUtil;

use Symbol  qw( qualify_to_ref );

########################################################################
# tests
########################################################################

my $madness = $test->madness;
my $class   = $test->class;
my $wrapz   = *{ qualify_to_ref wrappers => $class }{ ARRAY };

use_ok $madness;

can_ok $class, $_
for $wrapz->@*;

done_testing
__END__
