#!perl
use strict;
use warnings;
use String::Koremutake;

my $k = String::Koremutake->new;
my %hash = ('a' => 1);

show();
show(1, undef, 2);
show(123);
show(-0.3);
show('a');
show('orange o rama');
show([]);
show({});
show($k);

sub show {
  my($first, @rest) = @_;
  print $first, @rest, "\n";
  my $n = 1;
}
