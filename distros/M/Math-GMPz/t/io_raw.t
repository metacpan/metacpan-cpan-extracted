use warnings;
use strict;
use Math::GMPz qw(:mpz);

print "1..1\n";

print "# Using gmp version ", Math::GMPz::gmp_v(), "\n";

my $out = Math::GMPz->new("123456" x 20);
my $copy = Math::GMPz->new("123456" x 20, 10);
my $in = Math::GMPz->new();

open WR, '>', 'vec.out' or die $!;
Rmpz_out_raw(\*WR, $out);
close WR or die $!;

open RD, '<', 'vec.out' or die $!;
Rmpz_inp_raw($in, \*RD);
close RD or die $!;

if($in == $copy) {print "ok 1\n"}
else {print "not ok 1\n$in\n$copy\n"}

warn "Failed to unlink t/vec.out" unless unlink('vec.out');
