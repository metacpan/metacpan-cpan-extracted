use warnings;
use strict;
use Math::MPFR qw(:mpfr);

my $tests = 29;

print "1..$tests\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

my $ok = '';

Rmpfr_set_overflow();
if(Rmpfr_overflow_p()) {$ok .= 'a'}
Rmpfr_clear_overflow();
if(!Rmpfr_overflow_p()) {$ok .= 'b'}

Rmpfr_set_underflow();
if(Rmpfr_underflow_p()) {$ok .= 'c'}
Rmpfr_clear_underflow();
if(!Rmpfr_underflow_p()) {$ok .= 'd'}

Rmpfr_set_inexflag();
if(Rmpfr_inexflag_p()) {$ok .= 'e'}
Rmpfr_clear_inexflag();
if(!Rmpfr_inexflag_p()) {$ok .= 'f'}

Rmpfr_set_erangeflag();
if(Rmpfr_erangeflag_p()) {$ok .= 'g'}
Rmpfr_clear_erangeflag();
if(!Rmpfr_erangeflag_p()) {$ok .= 'h'}

Rmpfr_set_nanflag();
if(Rmpfr_nanflag_p()) {$ok .= 'i'}
Rmpfr_clear_nanflag();
if(!Rmpfr_nanflag_p()) {$ok .= 'j'}

if($ok eq 'abcdefghij') {print "ok 1\n"}
else {print "not ok 1\n"}

my $zero = Math::MPFR->new(0);
my $inf = Math::MPFR->new(1);

$ok = '';

$inf /= $zero;

Rmpfr_clear_overflow();
if(!Rmpfr_overflow_p()) {$ok .= 'a'}
Rmpfr_check_range($inf, 123, GMP_RNDN);
if(Rmpfr_overflow_p()) {$ok .= 'b'}

$inf *= -1;

Rmpfr_clear_overflow();
if(!Rmpfr_overflow_p()) {$ok .= 'c'}
Rmpfr_check_range($inf, 123, GMP_RNDN);
if(Rmpfr_overflow_p()) {$ok .= 'd'}

if($ok eq 'abcd') {print "ok 2\n"}
else {print "not ok 2 $ok\n"}

# Check the nanflag setting for some specific functions (which were buggy
# up to and including 3.1.4)

my $nan = Math::MPFR->new();
Rmpfr_clear_nanflag();

Rmpfr_add_ui($nan, $nan, ~0, MPFR_RNDN);

if(Rmpfr_nanflag_p()) {
  print "ok 3\n";
  Rmpfr_clear_nanflag();
}
else {
  print "not ok 3\n";
}

Rmpfr_add_si($nan, $nan, -1, MPFR_RNDN);

if(Rmpfr_nanflag_p()) {
  print "ok 4\n";
  Rmpfr_clear_nanflag();
}
else {
  print "not ok 4\n";
}

Rmpfr_sub_ui($nan, $nan, ~0, MPFR_RNDN);

if(Rmpfr_nanflag_p()) {
  print "ok 5\n";
  Rmpfr_clear_nanflag();
}
else {
  print "not ok 5\n";
}

Rmpfr_sub_si($nan, $nan, -1, MPFR_RNDN);

if(Rmpfr_nanflag_p()) {
  print "ok 6\n";
  Rmpfr_clear_nanflag();
}
else {
  print "not ok 6\n";
}

Rmpfr_ui_sub($nan, ~0, $nan, MPFR_RNDN); # OK

if(Rmpfr_nanflag_p()) {
  print "ok 7\n";
  Rmpfr_clear_nanflag();
}
else {
  print "not ok 7\n";
}

Rmpfr_si_sub($nan, -1, $nan, MPFR_RNDN);

if(Rmpfr_nanflag_p()) {
  print "ok 8\n";
  Rmpfr_clear_nanflag();
}
else {
  print "not ok 8\n";
}

$nan = $nan + ~0;

if(Rmpfr_nanflag_p()) {
  print "ok 9\n";
  Rmpfr_clear_nanflag();
}
else {
  print "not ok 9\n";
}

$nan = ~0 + $nan;

if(Rmpfr_nanflag_p()) {
  print "ok 10\n";
  Rmpfr_clear_nanflag();
}
else {
  print "not ok 10\n";
}

$nan += ~0;

if(Rmpfr_nanflag_p()) {
  print "ok 11\n";
  Rmpfr_clear_nanflag();
}
else {
  print "not ok 11\n";
}

$nan = $nan + -2;

if(Rmpfr_nanflag_p()) {
  print "ok 12\n";
  Rmpfr_clear_nanflag();
}
else {
  print "not ok 12\n";
}

$nan = -3 + $nan;

if(Rmpfr_nanflag_p()) {
  print "ok 13\n";
  Rmpfr_clear_nanflag();
}
else {
  print "not ok 13\n";
}

$nan += -5;

if(Rmpfr_nanflag_p()) {
  print "ok 14\n";
  Rmpfr_clear_nanflag();
}
else {
  print "not ok 14\n";
}

###################

$nan = $nan - ~0;

if(Rmpfr_nanflag_p()) {
  print "ok 15\n";
  Rmpfr_clear_nanflag();
}
else {
  print "not ok 15\n";
}

$nan = ~0 - $nan;       # OK

if(Rmpfr_nanflag_p()) {
  print "ok 16\n";
  Rmpfr_clear_nanflag();
}
else {
  print "not ok 16\n";
}

$nan -= ~0;

if(Rmpfr_nanflag_p()) {
  print "ok 17\n";
  Rmpfr_clear_nanflag();
}
else {
  print "not ok 17\n";
}

$nan = $nan - 2;

if(Rmpfr_nanflag_p()) {
  print "ok 18\n";
  Rmpfr_clear_nanflag();
}
else {
  print "not ok 18\n";
}

$nan = -3 - $nan;

if(Rmpfr_nanflag_p()) {
  print "ok 19\n";
  Rmpfr_clear_nanflag();
}
else {
  print "not ok 19\n";
}

$nan -= 5;

if(Rmpfr_nanflag_p()) {
  print "ok 20\n";
  Rmpfr_clear_nanflag();
}
else {
  print "not ok 20\n";
}

###################

eval{require Math::GMPz;};

if(!$@) {

  my $z = Math::GMPz->new(123);

  Rmpfr_add_z($nan, $nan, $z, MPFR_RNDN);

  if(Rmpfr_nanflag_p()) {
    print "ok 21\n";
    Rmpfr_clear_nanflag();
  }
  else {
    print "not ok 21\n";
  }

  Rmpfr_sub_z($nan, $nan, $z, MPFR_RNDN);

  if(Rmpfr_nanflag_p()) {
    print "ok 22\n";
    Rmpfr_clear_nanflag();
  }
  else {
    print "not ok 22\n";
  }

  eval {Rmpfr_z_sub($nan, $z, $nan, MPFR_RNDN)}; # OK

  if($@) {
    if($@ =~ /Rmpfr_z_sub not implemented with this version of the mpfr library/) {
      warn "\nSkipping test 23 - Rmpfr_z_sub not implemented\n";
      print "ok 23\n";
    }
    else {
      warn "\n\$\@: $@\n";
      print "not ok 23\n";
    }
  }
  elsif(Rmpfr_nanflag_p()) {
    print "ok 23\n";
    Rmpfr_clear_nanflag();
  }
  else {
    print "not ok 23\n";
  }

  $nan = $nan + $z;

  if(Rmpfr_nanflag_p()) {
    print "ok 24\n";
    Rmpfr_clear_nanflag();
  }
  else {
    print "not ok 24\n";
  }

  $nan = $z + $nan;

  if(Rmpfr_nanflag_p()) {
    print "ok 25\n";
    Rmpfr_clear_nanflag();
  }
  else {
    print "not ok 25\n";
  }

  $nan += $z;

  if(Rmpfr_nanflag_p()) {
    print "ok 26\n";
    Rmpfr_clear_nanflag();
  }
  else {
    print "not ok 26\n";
  }

  $nan = $nan - $z;

  if(Rmpfr_nanflag_p()) {
    print "ok 27\n";
    Rmpfr_clear_nanflag();
  }
  else {
    print "not ok 27\n";
  }

  $nan = $z - $nan;       # OK

  if(Rmpfr_nanflag_p()) {
    print "ok 28\n";
    Rmpfr_clear_nanflag();
  }
  else {
    print "not ok 28\n";
  }

  $nan -= $z;

  if(Rmpfr_nanflag_p()) {
    print "ok 29\n";
    Rmpfr_clear_nanflag();
  }
  else {
    print "not ok 29\n";
  }

}
else {
  warn "\nSkipping tests 21 .. $tests - couldn't load Math::GMPZ:\n\$\@: $@\n";
  for(21 .. $tests) {print "ok $_\n"};
}



