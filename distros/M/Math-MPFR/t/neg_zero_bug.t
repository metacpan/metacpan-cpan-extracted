# This file so named because it tests the fixing of a bug with -0 and mpfr_fits_u*_p().
# The bug was present in mpfr up to (and including) version 3.1.2.

use warnings;
use strict;
use Math::MPFR qw(:mpfr);

print "1..8\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

Rmpfr_set_default_prec(150);

my($ok, $count) = (0, 24);

my @vals = (
            Math::MPFR->new(-0.99999), Math::MPFR->new(-0.50001),
            Math::MPFR->new(-0.5), Math::MPFR->new(-0.4999999),
            Math::MPFR->new(-0.000001), Math::MPFR->new(0.0),
           );

$vals[5] *= -1.0;

my @rnds = (0 .. 3);

unless(3 > MPFR_VERSION_MAJOR) {
  $count += 6;
  push @rnds, 4;
}

for my $r(@rnds) {
  for my $v(@vals) {

    if($r == MPFR_RNDN) {
      if($v >= -0.5) {
        if(Rmpfr_fits_ushort_p($v, $r)) {$ok++}
        else { warn "$r : $v : ", Rmpfr_fits_ushort_p($v, $r), "\n"}
      }
      else {
        if(!Rmpfr_fits_ushort_p($v, $r)) {$ok++}
        else { warn "$r : $v : ", Rmpfr_fits_ushort_p($v, $r), "\n"}
      }
    }
    elsif($r == MPFR_RNDZ || $r == MPFR_RNDU) {
      if(Rmpfr_fits_ushort_p($v, $r)) {$ok++}
      else { warn "$r : $v : ", Rmpfr_fits_ushort_p($v, $r), "\n"}
    }
    else {
      if($v == 0) {
        if(Rmpfr_fits_ushort_p($v, $r)) {$ok++}
        else { warn "$r : $v : ", Rmpfr_fits_ushort_p($v, $r), "\n"}
      }
      else {
        if(!Rmpfr_fits_ushort_p($v, $r)) {$ok++}
        else { warn "$r : $v : ", Rmpfr_fits_ushort_p($v, $r), "\n"}
      }
    }
  }
}

if($ok == $count) {print "ok 1\n"}
else {
  warn "\n\$ok: $ok\n\$count: $count\n";
  print "not ok 1\n";
}

$ok = 0;

for my $r(@rnds) {
  for my $v(@vals) {

    if($r == MPFR_RNDN) {
      if($v >= -0.5) {
        if(Rmpfr_fits_uint_p($v, $r)) {$ok++}
        else { warn "$r : $v : ", Rmpfr_fits_uint_p($v, $r), "\n"}
      }
      else {
        if(!Rmpfr_fits_uint_p($v, $r)) {$ok++}
        else { warn "$r : $v : ", Rmpfr_fits_uint_p($v, $r), "\n"}
      }
    }
    elsif($r == MPFR_RNDZ || $r == MPFR_RNDU) {
      if(Rmpfr_fits_uint_p($v, $r)) {$ok++}
      else { warn "$r : $v : ", Rmpfr_fits_uint_p($v, $r), "\n"}
    }
    else {
      if($v == 0) {
        if(Rmpfr_fits_uint_p($v, $r)) {$ok++}
        else { warn "$r : $v : ", Rmpfr_fits_uint_p($v, $r), "\n"}
      }
      else {
        if(!Rmpfr_fits_uint_p($v, $r)) {$ok++}
        else { warn "$r : $v : ", Rmpfr_fits_uint_p($v, $r), "\n"}
      }
    }
  }
}

if($ok == $count) {print "ok 2\n"}
else {
  warn "\n\$ok: $ok\n\$count: $count\n";
  print "not ok 2\n";
}

$ok = 0;

for my $r(@rnds) {
  for my $v(@vals) {

    if($r == MPFR_RNDN) {
      if($v >= -0.5) {
        if(Rmpfr_fits_ulong_p($v, $r)) {$ok++}
        else { warn "$r : $v : ", Rmpfr_fits_ulong_p($v, $r), "\n"}
      }
      else {
        if(!Rmpfr_fits_ulong_p($v, $r)) {$ok++}
        else { warn "$r : $v : ", Rmpfr_fits_ulong_p($v, $r), "\n"}
      }
    }
    elsif($r == MPFR_RNDZ || $r == MPFR_RNDU) {
      if(Rmpfr_fits_ulong_p($v, $r)) {$ok++}
      else { warn "$r : $v : ", Rmpfr_fits_ulong_p($v, $r), "\n"}
    }
    else {
      if($v == 0) {
        if(Rmpfr_fits_ulong_p($v, $r)) {$ok++}
        else { warn "$r : $v : ", Rmpfr_fits_ulong_p($v, $r), "\n"}
      }
      else {
        if(!Rmpfr_fits_ulong_p($v, $r)) {$ok++}
        else { warn "$r : $v : ", Rmpfr_fits_ulong_p($v, $r), "\n"}
      }
    }
  }
}

if($ok == $count) {print "ok 3\n"}
else {
  warn "\n\$ok: $ok\n\$count: $count\n";
  print "not ok 3\n";
}

$ok = 0;

for my $r(@rnds) {
  for my $v(@vals) {

    if($r == MPFR_RNDN) {
      if($v >= -0.5) {
        if(Rmpfr_fits_uintmax_p($v, $r)) {$ok++}
        else { warn "$r : $v : ", Rmpfr_fits_uintmax_p($v, $r), "\n"}
      }
      else {
        if(!Rmpfr_fits_uintmax_p($v, $r)) {$ok++}
        else { warn "$r : $v : ", Rmpfr_fits_uintmax_p($v, $r), "\n"}
      }
    }
    elsif($r == MPFR_RNDZ || $r == MPFR_RNDU) {
      if(Rmpfr_fits_uintmax_p($v, $r)) {$ok++}
      else { warn "$r : $v : ", Rmpfr_fits_uintmax_p($v, $r), "\n"}
    }
    else {
      if($v == 0) {
        if(Rmpfr_fits_uintmax_p($v, $r)) {$ok++}
        else { warn "$r : $v : ", Rmpfr_fits_uintmax_p($v, $r), "\n"}
      }
      else {
        if(!Rmpfr_fits_uintmax_p($v, $r)) {$ok++}
        else { warn "$r : $v : ", Rmpfr_fits_uintmax_p($v, $r), "\n"}
      }
    }
  }
}

if($ok == $count) {print "ok 4\n"}
else {
  warn "\n\$ok: $ok\n\$count: $count\n";
  print "not ok 4\n";
}

$ok = 0;

for my $r(@rnds) {
  for my $v(@vals) {

    if($r == MPFR_RNDN) {
      if($v >= -0.5) {
        if(Rmpfr_fits_UV_p($v, $r)) {$ok++}
        else { warn "$r : $v : ", Rmpfr_fits_UV_p($v, $r), "\n"}
      }
      else {
        if(!Rmpfr_fits_UV_p($v, $r)) {$ok++}
        else { warn "$r : $v : ", Rmpfr_fits_UV_p($v, $r), "\n"}
      }
    }
    elsif($r == MPFR_RNDZ || $r == MPFR_RNDU) {
      if(Rmpfr_fits_UV_p($v, $r)) {$ok++}
      else { warn "$r : $v : ", Rmpfr_fits_UV_p($v, $r), "\n"}
    }
    else {
      if($v == 0) {
        if(Rmpfr_fits_UV_p($v, $r)) {$ok++}
        else { warn "$r : $v : ", Rmpfr_fits_UV_p($v, $r), "\n"}
      }
      else {
        if(!Rmpfr_fits_UV_p($v, $r)) {$ok++}
        else { warn "$r : $v : ", Rmpfr_fits_UV_p($v, $r), "\n"}
      }
    }
  }
}

if($ok == $count) {print "ok 5\n"}
else {
  warn "\n\$ok: $ok\n\$count: $count\n";
  print "not ok 5\n";
}

$ok = 0;

for my $r(@rnds) {
  for my $v(@vals) {
    if(Rmpfr_fits_sshort_p($v, $r)) {$ok++}
    else { warn "sshort: $r : $v : ", Rmpfr_fits_sshort_p($v, $r), "\n"}

    if(Rmpfr_fits_sint_p($v, $r)) {$ok++}
    else { warn "sint: $r : $v : ", Rmpfr_fits_sint_p($v, $r), "\n"}

    if(Rmpfr_fits_slong_p($v, $r)) {$ok++}
    else { warn "slong: $r : $v : ", Rmpfr_fits_slong_p($v, $r), "\n"}

    if(Rmpfr_fits_intmax_p($v, $r)) {$ok++}
    else { warn "intmax: $r : $v : ", Rmpfr_fits_intmax_p($v, $r), "\n"}

    if(Rmpfr_fits_IV_p($v, $r)) {$ok++}
    else { warn "IV: $r : $v : ", Rmpfr_fits_IV_p($v, $r), "\n"}
  }
}

if($ok == $count * 5) {print "ok 6\n"}
else {
  warn "\n\$ok: $ok\n\$count: $count\n";
  print "not ok 6\n";
}

my $fr1 = Math::MPFR->new(-1.0);
my $fr2 = Math::MPFR->new(0.6);
$ok = 1;

for my $r(@rnds) {
  if(Rmpfr_fits_ushort_p($fr1, $r)) {
    warn "ushort: $fr1: $r: ", Rmpfr_fits_ushort_p($fr1, $r), "\n";
    $ok = 0;
  }

  if(Rmpfr_fits_uint_p($fr1, $r)) {
    warn "uint: $fr1: $r: ", Rmpfr_fits_uint_p($fr1, $r), "\n";
    $ok = 0;
  }

  if(Rmpfr_fits_ulong_p($fr1, $r)) {
    warn "ulong: $fr1: $r: ", Rmpfr_fits_ulong_p($fr1, $r), "\n";
    $ok = 0;
  }

  if(Rmpfr_fits_uintmax_p($fr1, $r)) {
    warn "uintmax: $fr1: $r: ", Rmpfr_fits_uintmax_p($fr1, $r), "\n";
    $ok = 0;
  }

  if(Rmpfr_fits_UV_p($fr1, $r)) {
    warn "UV: $fr1: $r: ", Rmpfr_fits_UV_p($fr1, $r), "\n";
    $ok = 0;
  }
}

if($ok){print "ok 7\n"}
else {print "not ok 7\n"}

$ok = 1;

for my $r(@rnds) {
  if(!Rmpfr_fits_ushort_p($fr2, $r)) {
    warn "ushort: $fr2: $r: ", Rmpfr_fits_ushort_p($fr2, $r), "\n";
    $ok = 0;
  }

  if(!Rmpfr_fits_uint_p($fr2, $r)) {
    warn "uint: $fr2: $r: ", Rmpfr_fits_uint_p($fr2, $r), "\n";
    $ok = 0;
  }

  if(!Rmpfr_fits_ulong_p($fr2, $r)) {
    warn "ulong: $fr2: $r: ", Rmpfr_fits_ulong_p($fr2, $r), "\n";
    $ok = 0;
  }

  if(!Rmpfr_fits_uintmax_p($fr2, $r)) {
    warn "uintmax: $fr2: $r: ", Rmpfr_fits_uintmax_p($fr2, $r), "\n";
    $ok = 0;
  }

  if(!Rmpfr_fits_UV_p($fr2, $r)) {
    warn "UV: $fr2: $r: ", Rmpfr_fits_UV_p($fr2, $r), "\n";
    $ok = 0;
  }
}

if($ok){print "ok 8\n"}
else {print "not ok 8\n"}
