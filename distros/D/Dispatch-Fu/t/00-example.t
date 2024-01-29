use strict;
use warnings;
use Test::More;
use Dispatch::Fu;

sub _runner {
    my $INPUT = shift;

    my ($ouput, $canary) = dispatch {
        my $input_ref = shift;

        # checking internal inspection routine, cases
        my @cases = cases;
        is 7, @cases, q{found expected number of cases};

        return ( scalar @$input_ref > 5 )
          ? q{case5}
          : sprintf qq{case%d}, scalar @$input_ref;
    }
    $INPUT,
      on case0 => sub { return qw/0 +/ },
      on case1 => sub { return qw/1 +/ },
      on case2 => sub { return qw/2 +/ },
      on case3 => sub { return qw/3 +/ },
      on case4 => sub { return qw/4 +/ },
      on case5 => sub { return qw/5 +/ };

    my @cases = cases;
    is 1, @cases, q{found expected number of cases};

    # quick test to make sure files get returned as expected when run in
    # a loop, necessarily involves clearing $DISPATCH_TABLE and rebuilding it
    is $canary, q{+}, q{return LIST working fine.};

    return $ouput;
}

my @queue = ();
foreach my $i ( 0 .. 5 ) {
    is _runner( \@queue ), $i, q{Got expected result back from dispatch};
    push @queue, $i;
}

foreach my $i ( 6 ... 98 ) {
    is _runner( \@queue ), 5, q{Got expected result back from dispatch};
    push @queue, $i;
}

done_testing;
