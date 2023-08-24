use strict;
use warnings;
use Dispatch::Fu;    # exports 'dispatch' and 'on'
use Test::More tests => 99;

sub _runner {
    my $bar   = shift;
    my $ouput = dispatch {
        my $baz = shift;
        return ( scalar @$baz > 5 )
          ? q{bucket5}
          : sprintf qq{bucket%d}, scalar @$baz;
    }
    $bar,
      on bucket0 => sub { return qq{0} },
      on bucket1 => sub { return qq{1} },
      on bucket2 => sub { return qq{2} },
      on bucket3 => sub { return qq{3} },
      on bucket4 => sub { return qq{4} },
      on bucket5 => sub { return qq{5} };
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
