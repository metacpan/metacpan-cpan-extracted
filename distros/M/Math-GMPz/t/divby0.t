use strict;
use warnings;
use Math::GMPz qw(:mpz);
use Math::BigInt;

print "1..38\n";

my $rop1 = Math::GMPz->new();
my $rop2 = Math::GMPz->new(0);
my $op   = Math::GMPz->new(42);
my $z0   = Math::GMPz->new(0);

##############################

eval{Rmpz_cdiv_q($rop1, $op, $z0);};

if($@ =~ /Division by 0 not allowed in Rmpz_cdiv_q/) {print "ok 1\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 1\n";
}

##############################

eval{Rmpz_cdiv_r($rop1, $op, $z0);};

if($@ =~ /Division by 0 not allowed in Rmpz_cdiv_r/) {print "ok 2\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 2\n";
}

##############################

eval{Rmpz_cdiv_qr($rop1, $rop2, $op, $z0);};

if($@ =~ /Division by 0 not allowed in Rmpz_cdiv_qr/) {print "ok 3\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 3\n";
}

##############################

eval{Rmpz_cdiv_q_ui($rop1, $op, 0);};

if($@ =~ /Division by 0 not allowed in Rmpz_cdiv_q_ui/) {print "ok 4\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 4\n";
}

##############################

eval{Rmpz_cdiv_r_ui($rop1, $op, 0);};

if($@ =~ /Division by 0 not allowed in Rmpz_cdiv_r_ui/) {print "ok 5\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 5\n";
}

##############################

eval{Rmpz_cdiv_qr_ui($rop1, $rop2, $op, 0);};

if($@ =~ /Division by 0 not allowed in Rmpz_cdiv_qr_ui/) {print "ok 6\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 6\n";
}

##############################

eval{Rmpz_cdiv_ui($op, 0);};

if($@ =~ /Division by 0 not allowed in Rmpz_cdiv_ui/) {print "ok 7\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 7\n";
}

##############################

eval{Rmpz_fdiv_q($rop1, $op, $z0);};

if($@ =~ /Division by 0 not allowed in Rmpz_fdiv_q/) {print "ok 8\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 8\n";
}

##############################

eval{Rmpz_div($rop1, $op, $z0);};

if($@ =~ /Division by 0 not allowed in Rmpz_div/) {print "ok 9\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 9\n";
}

##############################

eval{Rmpz_fdiv_r($rop1, $op, $z0);};

if($@ =~ /Division by 0 not allowed in Rmpz_fdiv_r/) {print "ok 10\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 10\n";
}

##############################

eval{Rmpz_fdiv_qr($rop1, $rop2, $op, $z0);};

if($@ =~ /Division by 0 not allowed in Rmpz_fdiv_qr/) {print "ok 11\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 11\n";
}

##############################

eval{Rmpz_divmod($rop1, $rop2, $op, $z0);};

if($@ =~ /Division by 0 not allowed in Rmpz_divmod/) {print "ok 12\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 12\n";
}

##############################

eval{Rmpz_fdiv_q_ui($rop1, $op, 0);};

if($@ =~ /Division by 0 not allowed in Rmpz_fdiv_q_ui/) {print "ok 13\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 13\n";
}

##############################

eval{Rmpz_div_ui($rop1, $op, 0);};

if($@ =~ /Division by 0 not allowed in Rmpz_div_ui/) {print "ok 14\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 14\n";
}

##############################

eval{Rmpz_fdiv_r_ui($rop1, $op, 0);};

if($@ =~ /Division by 0 not allowed in Rmpz_fdiv_r_ui/) {print "ok 15\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 15\n";
}

##############################

eval{Rmpz_fdiv_qr_ui($rop1, $rop2, $op, 0);};

if($@ =~ /Division by 0 not allowed in Rmpz_fdiv_qr_ui/) {print "ok 16\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 16\n";
}

##############################

eval{Rmpz_divmod_ui($rop1, $rop2, $op, 0);};

if($@ =~ /Division by 0 not allowed in Rmpz_divmod_ui/) {print "ok 17\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 17\n";
}

##############################

eval{Rmpz_fdiv_ui($op, 0);};

if($@ =~ /Division by 0 not allowed in Rmpz_fdiv_ui/) {print "ok 18\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 18\n";
}

##############################

eval{Rmpz_tdiv_q($rop1, $op, $z0);};

if($@ =~ /Division by 0 not allowed in Rmpz_tdiv_q/) {print "ok 19\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 19\n";
}

##############################

eval{Rmpz_tdiv_r($rop1, $op, $z0);};

if($@ =~ /Division by 0 not allowed in Rmpz_tdiv_r/) {print "ok 20\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 20\n";
}

##############################

eval{Rmpz_tdiv_qr($rop1, $rop2, $op, $z0);};

if($@ =~ /Division by 0 not allowed in Rmpz_tdiv_qr/) {print "ok 21\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 21\n";
}

##############################

eval{Rmpz_tdiv_q_ui($rop1, $op, 0);};

if($@ =~ /Division by 0 not allowed in Rmpz_tdiv_q_ui/) {print "ok 22\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 22\n";
}

##############################

eval{Rmpz_tdiv_r_ui($rop1, $op, 0);};

if($@ =~ /Division by 0 not allowed in Rmpz_tdiv_r_ui/) {print "ok 23\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 23\n";
}

##############################

eval{Rmpz_tdiv_qr_ui($rop1, $rop2, $op, 0);};

if($@ =~ /Division by 0 not allowed in Rmpz_tdiv_qr_ui/) {print "ok 24\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 24\n";
}

##############################

eval{Rmpz_tdiv_ui($op, 0);};

if($@ =~ /Division by 0 not allowed in Rmpz_tdiv_ui/) {print "ok 25\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 25\n";
}

##############################

eval{Rmpz_mod($rop1, $op, $z0);};

if($@ =~ /Division by 0 not allowed in Rmpz_mod/) {print "ok 26\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 26\n";
}

##############################

eval{Rmpz_mod_ui($rop1, $op, 0);};

if($@ =~ /Division by 0 not allowed in Rmpz_mod_ui/) {print "ok 27\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 27\n";
}

##############################

eval{Rmpz_divexact($rop1, $op, $z0);};

if($@ =~ /Division by 0 not allowed in Rmpz_divexact/) {print "ok 28\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 28\n";
}

##############################

eval{Rmpz_divexact_ui($rop1, $op, 0);};

if($@ =~ /Division by 0 not allowed in Rmpz_divexact_ui/) {print "ok 29\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 29\n";
}

##############################

eval{$rop1 = $op / 0;};

if($@ =~ /Division by 0 not allowed in Rmpz_tdiv_q/) {print "ok 30\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 30\n";
}


##############################

eval{$rop1 = 10 / Math::GMPz->new(0);};

if($@ =~ /Division by 0 not allowed in Rmpz_tdiv_q/) {print "ok 31\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 31\n";
}

##############################

eval{$rop1 = ~0 / Math::GMPz->new(0);};

if($@ =~ /Division by 0 not allowed in Rmpz_tdiv_q/) {print "ok 32\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 32\n";
}

##############################

eval{$rop1 = $op / 0.0;};

if($@ =~ /Division by 0 not allowed in Rmpz_tdiv_q/) {print "ok 33\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 33\n";
}

##############################

eval{$rop1 = 10.1 / Math::GMPz->new(0);};

if($@ =~ /Division by 0 not allowed in Rmpz_tdiv_q/) {print "ok 34\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 34\n";
}

##############################

eval{$rop1 = Math::GMPz->new(5) / Math::GMPz->new(0);};

if($@ =~ /Division by 0 not allowed in Rmpz_tdiv_q/) {print "ok 35\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 35\n";
}

eval{$rop1 = Math::GMPz->new(5) / Math::BigInt->new(0);};

if($@ =~ /Division by 0 not allowed in Rmpz_tdiv_q/) {print "ok 36\n"}
else {
  warn "\n\$\@: $@\n";
  print "not ok 36\n";
}

eval{require Math::GMPq;};

if($@) {
  warn "\n\$\@: $@\n";
  warn "Skipping tests 37 & 38 - can't load Math::GMPq\n";
  print "ok 37\n";
  print "ok 38\n";
}
elsif($Math::GMPq::VERSION < 0.45) {
  warn "Skipping tests 37 & 38 - Math::GMPq-$Math::GMPq::VERSION is buggy re these divby0 tests.\n",
       "Please consider updating Math::GMPq to latest stable version \n";
  print "ok 37\n";
  print "ok 38\n";
}
else {
  eval{my $x = Math::GMPz->new(10) / Math::GMPq->new(0);};

  if($@) {print "ok 37\n"}
  else {print "not ok 37\n"}

  eval{my $x = Math::GMPq->new('1/5') / Math::GMPz->new(0);};

  if($@) {print "ok 38\n"}
  else {print "not ok 38\n"}
}
