#!/usr/bin/env perl

use strict;
use warnings;

use Math::BigInt;
use Test;

BEGIN { plan tests => 5; }

use Math::Base85;
ok(1);

# Stealing values from RFC 1924.
my $n = Math::BigInt->new("21932261930451111902915077091070067066");
my $m = Math::Base85::to_base85($n);
ok($m, "4)+k&C#VzJ4br>0wv%Yp");

# Supply some invalid stuff.
my $x = qq("anbukrvq35490ASRVKOAMRS");
eval {
    my $y = Math::Base85::from_base85($x);
};
ok($@);
ok($@, qr/invalid base 85 digit/);

# Add 1 and see if we get what we expect.
my $p = "4)+k&C#VzJ4br>0wv%Yq";
my $q = Math::Base85::from_base85($p);
my $r = Math::BigInt->new("21932261930451111902915077091070067067");
ok($q == $r);

# vim: expandtab shiftwidth=4
