#! perl

use strict;
use warnings;
use Test::More tests =>15;
use_ok('Math::BaseCalc');

my $calc = new Math::BaseCalc(digits=>[0,1]);
isa_ok($calc, "Math::BaseCalc");

{
    my $result = $calc->from_base('01101');
    is($result, 13, "from_base = 13");
}

{
    $calc->digits('bin');
    my $result = $calc->from_base('1101');
    is($result, 13, "1101 into decimal");
}

{
    my $result = $calc->to_base(13);
    is($result, '1101', "convert back to our base (binary)");
}

{
    $calc->digits('hex');
    my $result = $calc->to_base(46);
    is($result, '2e', "convert 46 into hex(2e)");
}

{
    $calc->digits([qw(i  a m  v e r y  p u n k)]);
    my $result = $calc->to_base(13933);
    is($result, 'krap', "base 11 with custom letters for each digit. Becomes a517 which is krap with custom letters");
}

{
    $calc->digits('hex');
    my $result = $calc->to_base('-17');
    is($result, '-11', "negative decimal (-17) into hex (-11)");
}

{
    $calc->digits('hex');
    my $result = $calc->from_base('-11');
    is($result, '-17', "negative hex (-11) into decimal (-17)");
}

{
    $calc->digits('hex');
    my $result = $calc->from_base('-11.05');
    is($result, '-17.01953125', "negative float number in hex to b10 (-11.05 to -17....");
}

{
    $calc->digits([0..6]);
    my $result = $calc->from_base('0.1');
    is($result, (1/7), "base 6 float (.1) converts to decimal (1/7).");
}

{
    # Test large numbers
    $calc->digits('hex');
    my $r1 = $calc->to_base(2**30 + 5);
    my $result = $calc->from_base($calc->to_base(2**30 + 5));
    #warn "res: $r1, $result";
    is($result, int(2**30 + 5), "hex (2**30 + 5) into hex then back");
}

{
  $calc->digits('bin');
  my $first  = $calc->from_base('1110111');
  my $second = $calc->from_base('1010110');
  my $third = $calc->to_base($first * $second);
  is($third, '10011111111010', "1110111 x 1010110 = 10011111111010");
}

{
  $calc->digits(['a', 'b', 'c']);
  my $result = $calc->from_base('-bba');
  is($result, '-12', "negative numbers treated correctly");

  $calc->digits(['a', 'b', '-']);
  $result = $calc->from_base('-bba');
  is($result, 2*27+9+3, "dash can be a digit");
}
