use strict;
use warnings;
use Dispatch::Fu qw/dispatch on/;
use Test::More tests => 99;

sub _runner {
    my $CASES = shift;
    my $ouput = dispatch {
        my $cases = shift;
        return ( scalar @$cases > 5 )
          ? q{case5}
          : sprintf qq{case%d}, scalar @$cases;
    }
    $CASES,
      on case0 => sub { return qq{0} },
      on case1 => sub { return qq{1} },
      on case2 => sub { return qq{2} },
      on case3 => sub { return qq{3} },
      on case4 => sub { return qq{4} },
      on case5 => sub { return qq{5} };
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
