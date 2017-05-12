use strict;

use Test::More tests => 3;

use Log::Defer;

Log::Defer->new(sub {
  my $msg = shift;
  is(scalar keys %$msg, 2, 'exactly 2 elements');
  ok(exists $msg->{start}, 'start is there');
  ok(exists $msg->{end}, 'end is there');
});
