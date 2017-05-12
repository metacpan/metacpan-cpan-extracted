BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

use Math::Base::Convert qw( ascii );

my $exp = q| !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|.'|'.q|}~|;

my $got = join '',@{&ascii};
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
print "ok 2\n";
