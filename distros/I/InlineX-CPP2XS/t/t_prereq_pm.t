use warnings;
use strict;
use InlineX::CPP2XS ('cpp2xs');

print "1..4\n";

my $outdir = "./prereq_pm_test";
my $code = 'void greet() {printf("Hello World\n");}' . "\n\n";
my $prereq = {'Some::Mod' => '1.23', 'Nother::Mod' => '3.21'};

cpp2xs('FOO', 'FOO', $outdir,
     {
     CODE => $code, PREREQ_PM => $prereq, WRITE_MAKEFILE_PL => 1, VERSION => '0.01'
     }
    );

my($M_e, $X_e);

if(-e "$outdir/Makefile.PL") {
  $M_e = 1;
  print "ok 1\n";
}
else {
  print "not ok 1\n";
}

if(-e "$outdir/FOO.xs") {
  $X_e = 1;
  print "ok 2\n";
}
else {
  print "not ok 2\n";
}

if($M_e) {
  if(check_makefile_pl()  > 0) {print "ok 3\n"}
  else {print "not ok 3\n"}
}
else {
  warn "Skipping test 3 - no Makefile.PL\n";
  print "ok 3\n";
}

if($X_e) {
  if(check_xs() > 0) {print "ok 4\n"}
  else {print "not ok 4\n"}
}
else {
  warn "Skipping test 4 - no FOO.xs\n";
  print "ok 4\n";
}

if($M_e) {
  warn "Couldn't unlink Makefile.PL\n"
    unless unlink "$outdir/Makefile.PL";
}

if($X_e) {
  warn "Couldn't unlink FOO.xs\n"
    unless unlink "$outdir/FOO.xs";
}

sub check_makefile_pl {

  my ($ok0, $ok1, $ok2, $ok3, $ok4);
  open RD1, '<', "$outdir/Makefile.PL" or die "Couldn't open $outdir/Makefile.PL: $!";

  while(<RD1>) {
    if($_ =~ /my %options/) {
      $ok0 = 1;
      if($ok1 || $ok2 || $ok3 || $ok4) {
        close RD1 or die "Couldn't close $outdir/Makefile.PL: $!";
        return 0;
      }
    }
    if($_ =~ /PREREQ_PM/) {$ok1 = 1}
    if($_ =~ /Nother::Mod/) {$ok2 = 1}
    if($_ =~ /Some::Mod/) {$ok3 = 1}
    if($ok1 && $ok2 && $ok3) {
      close RD1 or die "Couldn't close $outdir/Makefile.PL: $!";
      return 1;
    }
    if($_ =~ /WriteMakefile/) {
      $ok4 = 1;
      if(!$ok1 || !$ok2 || !$ok3) {
        close RD1 or die "Couldn't close $outdir/Makefile.PL: $!";
        return 0;
      }
    }
  }

  close RD1 or die "Couldn't close $outdir/Makefile.PL: $!";
  return -1;
}

sub check_xs {

  my $ok0 = 0;
  open RD2, '<', "$outdir/FOO.xs" or die "Couldn't open $outdir/FOO.xs: $!";

  while(<RD2>) {
    if($_ =~ /PREINIT:/) {$ok0 = 1}
  }

  close RD2 or die "Couldn't close $outdir/FOO.xs: $!";
  return $ok0;

}
