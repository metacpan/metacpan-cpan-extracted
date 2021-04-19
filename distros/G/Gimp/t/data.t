use strict;
use Test::More;
our ($dir, $DEBUG);
BEGIN {
#  $Gimp::verbose = 3;
  $DEBUG = 0;
  require './t/gimpsetup.pl';
}
use Gimp qw(:DEFAULT net_init=spawn/);
use Gimp::Data;

my @DATA = (
  [ 'testing/newkey1', 'data' ],
  [ 'testing/newkey2', [ 8, 'stuff', 1 ] ],
  [ 'testing/newkey3', +{ k1 => 9, k2 => 'other' } ],
);

for my $pair (@DATA) {
  ok(!$Gimp::Data{$pair->[0]}, "start empty $pair->[0]");
  $Gimp::Data{$pair->[0]} = $pair->[1];
  is_deeply($Gimp::Data{$pair->[0]}, $pair->[1], "stored $pair->[0]");
}

my @found = grep { $_ eq $DATA[0]->[0] } keys %Gimp::Data;
is(scalar(@found), 1, 'keys %Gimp::Data');
@found = grep { $_ eq $DATA[0]->[1] } values %Gimp::Data;
is(scalar(@found), 1, 'values %Gimp::Data');

Gimp::Net::gimp_end;
Gimp->import(qw(net_init=spawn/));

for my $pair (@DATA) {
  is_deeply([ $Gimp::Data{$pair->[0]} ], [ $pair->[1] ], "still $pair->[0]");
}

my $pair = $DATA[0];
is_deeply(delete $Gimp::Data{$pair->[0]}, $pair->[1], "delete $pair->[0]");
ok(!exists $Gimp::Data{$pair->[0]}, "exists $pair->[0]");


Gimp::Net::gimp_end;

done_testing;
