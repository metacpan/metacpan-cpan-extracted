use strict;
use warnings;
use Test::More tests => 9;
use List::Util::PP;

{
  package WithCodeOverload;
  use overload
    '&{}' => sub {
      $_[0]->{called}++;
      $_[0]->{check};
    },
    bool => sub { 1 },
    fallback => 1,
  ;
  sub new {
    my ($class, $check) = @_;
    bless {
      called => 0,
      check => $check,
    }, $class;
  }
}

my $cb = WithCodeOverload->new(sub { 1 });
for my $sub (qw(first all any notall none reduce pairmap pairgrep pairfirst)) {
  local $cb->{called} = 0;
  no strict 'refs';
  &{'List::Util::PP::'.$sub}($cb, 0 .. 5);
  is $cb->{called}, 1,
    "$sub calls &{} overload only once";
}
