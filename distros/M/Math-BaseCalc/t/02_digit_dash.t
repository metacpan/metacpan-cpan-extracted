#! perl

use strict;
use warnings;
use Test::More tests => 24;
use_ok('Math::BaseCalc');

my $calc = new Math::BaseCalc(digits=>[0,1]);
isa_ok($calc, "Math::BaseCalc");


my @calcs;
push(@calcs, new Math::BaseCalc(digits => [ '0', '&' ]));
push(@calcs, new Math::BaseCalc(digits => [ '0', '-' ]));

for my $calcX ( @calcs ) {
  for my $source (0..10) {
    my $in_base_X  = $calcX->to_base( $source );
    my $in_base_10 = $calcX->from_base( $in_base_X );
	
    is $in_base_10, $source, "from( to ( $source ) == $source ";
  }
}
