use strict;
use warnings;
use Test::More;
use Dispatch::Fu;

sub _runner {
    my $INPUT = shift;

    my $ouput = dispatch {
        my $input_ref = shift;

        # checking internal inspection routine, cases
        my @cases = cases;
        is 6, @cases, q{found expected number of cases};

        return ( scalar @$input_ref > 5 )
          ? q{case5}
          : sprintf qq{case%d}, scalar @$input_ref;
    }
    $INPUT,
      on case0 => sub { return qq{0} },
      on case1 => sub { return qq{1} },
      on case2 => sub { return qq{2} },
      on case3 => sub { return qq{3} },
      on case4 => sub { return qq{4} },
      on case5 => sub { return qq{5} };

      my @cases = cases;
      is 0, @cases, q{found expected number of cases};

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
