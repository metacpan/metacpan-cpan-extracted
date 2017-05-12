use strict;
use warnings;
use Math::MPFR qw(:mpfr);

print "1..6\n";

my $prec = 100009;
my $fh;
my $file = 'p_spec.txt';
my $ok = '';
my $bytes = 7;

eval{Rmpfr_printf("hello world\n", 0);};
if($@) {
  warn "1a: \$\@: $@\n";
}
else {$ok .= 'a'};


eval{Rmpfr_printf("%Pu\n", 0, 0);};
if($@ =~ /In Rmpfr_printf: The rounding argument is specific to Math::MPFR objects/) {
  $ok .= 'b'
}
else {warn "1b: \$\@: $@\n"};

eval{Rmpfr_printf("%Pu\n", prec_cast($prec));};
if($@) {
  warn "1c: \$\@: $@\n";
}
else {$ok .= 'c'};


eval{Rmpfr_printf("%Pu\n", 0, prec_cast($prec));};
if($@ =~ /You've provided both a rounding arg and a Math::MPFR::Prec object to Rmpfr_printf/) {
  $ok .= 'd'
}
else {warn "1d: \$\@: $@\n"};

if($ok eq 'abcd') {print "ok 1\n"}
else {print "not ok 1\n"}

$ok = '';
my $o = open($fh, '>', $file);
if($o) {
  Rmpfr_fprintf($fh, "%Pu\n", prec_cast($prec));
  eval{Rmpfr_fprintf($fh, "%Pu\n", GMP_RNDN, prec_cast($prec));};
  if($@ =~ /You've provided both a rounding arg and a Math::MPFR::Prec object to Rmpfr_fprintf/) {$ok = 'a'}
  else {warn "2a: \$\@: $@\n"}
  close $fh;
  if(open(RD, '<', $file)) {
    my $num = <RD>;
    chomp $num;
    if($num == $prec) {$ok .= 'b'}
  }
  else { warn "Failed to open $file for reading: $!";}

  if($ok eq 'ab') {print "ok 2\n"}
  else {
    warn "\$ok: $ok\n";
    print "not ok 2\n";
  }
}
else {
  warn "Failed to open $file for writing: $!";
  warn "\nSkipping test 2 - couldn't open $file\n";
  print "ok 2\n";
}

my $buf;
Rmpfr_sprintf ($buf, "%Pu\n", prec_cast($prec), 200);

if($buf == 100009) {print "ok 3\n"}
else {
  warn "\$buf: $buf\n";
  print "not ok 3\n";
}

eval{Rmpfr_sprintf ($buf, "%Pu\n", GMP_RNDN, prec_cast($prec), 100);};
if($@ =~ /You've provided both a rounding arg and a Math::MPFR::Prec object to Rmpfr_sprintf/) {print "ok 4\n"}
else {
  warn "4: \$\@: $@\n";
  print "not ok 4\n";
}

Rmpfr_snprintf ($buf, $bytes, "%Pu\n", prec_cast($prec), 200);

chomp $buf;

if($buf == 100009) {print "ok 5\n"}
else {
  warn "\$buf: $buf\n";
  print "not ok 5\n";
}

eval{Rmpfr_snprintf ($buf, $bytes, "%Pu\n", GMP_RNDN, prec_cast($prec), 10);};
if($@ =~ /You've provided both a rounding arg and a Math::MPFR::Prec object to Rmpfr_snprintf/) {print "ok 6\n"}
else {
  warn "6: \$\@: $@\n";
  print "not ok 6\n";
}

