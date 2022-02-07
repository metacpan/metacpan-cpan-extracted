
use warnings;
use strict;
use Math::MPFR qw(:mpfr);
use Math::MPFI qw(:mpfi);

print "1..9\n";

print STDERR "\n# Using Math::MPFI version ", $Math::MPFI::VERSION, "\n";
print STDERR "# Math::MPFI uses mpfi library version ", Rmpfi_get_version(), "\n";
print STDERR "# Math::MPFR uses mpfr library version ", Rmpfr_get_version(), "\n";
print STDERR "# Math::MPFI uses mpfr library version ", Math::MPFI::mpfr_v(), "\n";
print STDERR "# Math::MPFR uses gmp library version ", Math::MPFR::gmp_v(), "\n";
print STDERR "# Math::MPFI uses gmp library version ", Math::MPFI::gmp_v(), "\n";
print STDERR "# Using gmp library version ", Math::MPFI::gmp_v(), "\n";

if($Math::MPFI::VERSION eq '0.10' && Math::MPFI::_get_xs_version() eq $Math::MPFI::VERSION) {print "ok 1\n"}
else {print "not ok 1 $Math::MPFI::VERSION ", Math::MPFI::_get_xs_version(), "\n"}

my $prec = 101;

Rmpfi_set_default_prec($prec);

if(Rmpfr_get_default_prec() == $prec && Rmpfi_get_default_prec() == $prec) {print "ok 2\n"}
else {
  warn "Rmpfr_get default_prec == ", Rmpfr_get_default_prec(),
       "\nRmpfi_get default_prec == ", Rmpfi_get_default_prec(), "\n";
  print "not ok 2\n";
}

my $fi = Rmpfi_init();

if(Rmpfi_get_prec($fi) == $prec) {print "ok 3\n"}
else {
  warn "Rmpfi_get_prec(\$fi) == ", Rmpfi_get_prec($fi), "\n";
  print "not ok 3 \n";
}

my @v = split /\./, Rmpfi_get_version();
my $v_num = ($v[0] * 100) + ($v[1] * 10);
$v_num += $v[2] if @v > 2;

if($v_num >= 151) {
  my $check = (100 * MPFI_VERSION_MAJOR) + (10 * MPFI_VERSION_MINOR) + (MPFI_VERSION_PATCHLEVEL);
  if($v_num == $check) {print "ok 4\n"}
  else {
    warn "\$v_num: $v_num\n\$check: $check\n";
    warn "Header version(", MPFI_VERSION_MAJOR, ".", MPFI_VERSION_MINOR, ".", MPFI_VERSION_PATCHLEVEL,
         ") and library version (", Rmpfi_get_version(), ") do not match\n";
    print "not ok 4\n";
  }

  my $v_string = MPFI_VERSION_MAJOR.'.'.MPFI_VERSION_MINOR.'.'.MPFI_VERSION_PATCHLEVEL;
  if($v_string eq MPFI_VERSION_STRING) {print "ok 5\n"}
  else {
    warn "\$v_string: $v_string\nMPFI_VERSION_STRING: ", MPFI_VERSION_STRING, "\n";
    print "not ok 5\n";
  }
}
else {
  warn "Skipping tests 4 & 5 - old version (", Rmpfi_get_version(), ") of the mpfi library\n";
  print "ok 4\n";
  print "ok 5\n";
}

eval{MPFI_VERSION_STRING};
if($v_num < 151) {
  if($@ =~ /MPFI_VERSION_STRING not defined in mpfi\.h/) {print "ok 6\n"}
  else {
    warn "\$\@: $@";
    print "not ok 6\n";
  }
}
else {
  unless($@) {print "ok 6\n"}
  else {
    warn "\$\@: $@";
    print "not ok 6\n";
  }
}

eval{MPFI_VERSION_MAJOR};
if($v_num < 151) {
  if($@ =~ /MPFI_VERSION_MAJOR not defined in mpfi\.h/) {print "ok 7\n"}
  else {
    warn "\$\@: $@";
    print "not ok 7\n";
  }
}
else {
  unless($@) {print "ok 7\n"}
  else {
    warn "\$\@: $@";
    print "not ok 7\n";
  }
}

eval{MPFI_VERSION_MINOR};
if($v_num < 151) {
  if($@ =~ /MPFI_VERSION_MINOR not defined in mpfi\.h/) {print "ok 8\n"}
  else {
    warn "\$\@: $@";
    print "not ok 8\n";
  }
}
else {
  unless($@) {print "ok 8\n"}
  else {
    warn "\$\@: $@";
    print "not ok 8\n";
  }
}

eval{MPFI_VERSION_PATCHLEVEL};
if($v_num < 151) {
  if($@ =~ /MPFI_VERSION_PATCHLEVEL not defined in mpfi\.h/) {print "ok 9\n"}
  else {
    warn "\$\@: $@";
    print "not ok 9\n";
  }
}
else {
  unless($@) {print "ok 9\n"}
  else {
    warn "\$\@: $@";
    print "not ok 9\n";
  }
}
