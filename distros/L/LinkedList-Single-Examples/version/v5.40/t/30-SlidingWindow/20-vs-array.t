########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Testy;
use v5.40;
use FindBin::libs;

use Test::More;
use Test::Deep;

use LinkedList::Single::Example::SlidingWindow;
use LinkedList::Single::Example::SlidingWindow::Array;

########################################################################
# package variables
########################################################################

# fixed seed: a failure is reproducible.

srand 20261028;

my $span    = 50;
my $steps   = 2_000;

########################################################################
# tests
#
# drive the list window and the array window with the same random
# stream of events and expiries. the array version is the oracle.
########################################################################

my $list    = LinkedList::Single::Example::SlidingWindow->new(          span => $span );
my $array   = LinkedList::Single::Example::SlidingWindow::Array->new(   span => $span );

my @gone_list   = ();
my @gone_array  = ();

my $now     = 0;
my $bad     = 0;

for my $i ( 1 .. $steps )
{
    $now    += int rand 4;

    # mostly record, now and then expire, now and then jump far
    # enough ahead that the whole window expires.

    my $roll    = rand;

    if( $roll < 0.70 )
    {
        $_->record( $now, "e$i", $i ) for $list, $array;
    }
    else
    {
        $now    += 500 if $roll > 0.98;

        my $n_list  = $list->expire(  $now => sub { push @gone_list,  [ @_ ] } );
        my $n_array = $array->expire( $now => sub { push @gone_array, [ @_ ] } );

        $n_list == $n_array
        or ++$bad
        and diag "Step $i: expired $n_list (list) vs $n_array (array)";
    }

    cmp_deeply $list->contents, $array->contents, "Step $i: contents match"
    or ++$bad
    and last;
}

is $bad, 0, 'No mismatches against the array window';

cmp_deeply \@gone_list, \@gone_array, 'Same events expired, same order';

ok scalar @gone_list, 'Some events expired (the stream exercised expire)';

is $list->size, $array->size, 'Same final size';

done_testing
__END__
