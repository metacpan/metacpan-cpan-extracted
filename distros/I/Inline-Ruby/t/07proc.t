#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use Inline 'Ruby';

sub my_a_func {
    my ($i, $n) = @_;

    # TEST*3
    ok ($i, "Test");
    # print "Elapsed: $n\n";
}

invoke_wait(0.1, \&my_a_func, \&{"main::my_a_func"}, \&my_a_func);

__END__
__Ruby__

def invoke_wait(t, *procs)
  n = 0;
  i = 0;
  procs.each { |pr|
    i = i + 1
    n = n + sleep(t)
    pr.call(i, n)
  }
end
