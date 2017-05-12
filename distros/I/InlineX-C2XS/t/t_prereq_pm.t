use warnings;
use strict;
use InlineX::C2XS ('c2xs');

print "1..9\n";

my $outdir = "./prereq_pm_test";
my $code = 'void foo() {printf("Hello World\n");}' . "\n\n";
my $prereq = {'Some::Mod' => '1.23', 'Nother::Mod' => '3.21'};

c2xs('FOO', 'FOO', $outdir,
     {
      CODE => $code, PREREQ_PM => $prereq, DIST => 1, VERSION => '0.01'
     }
    );

my($M_e, $X_e, $PM_e, $MAN_e, $T_e);

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

if(-e "$outdir/FOO.pm") {
  $PM_e = 1;
  print "ok 5\n";
}
else {
  print "not ok 5\n";
}

if(-e "$outdir/MANIFEST") {
  $MAN_e = 1;
  print "ok 6\n";
}
else {
  print "not ok 6\n";
}

if($MAN_e) {
  my @w = ('FOO.pm', 'FOO.xs', 'Makefile.PL', 'MANIFEST', 't/00load.t');
  open RDMAN, '<', "$outdir/MANIFEST" or die "Couldn't open MANIFEST for reading: $!";
  my @h = <RDMAN>;
  close RDMAN or die "Couldn't close MANIFEST after reading: $!";

  for my $h(@h) {chomp $h}

  if(manifest_compare(\@w, \@h)) {print "ok 7\n"}
  else {print "not ok 7\n"}

  if(manifest_compare(\@h, \@w)) {print "ok 8\n"}
  else {print "not ok 8\n"}

}
else {
  warn "Skipping tests 7 & 8 - MANIFEST was not generated\n";
  print "ok 7\nok 8\n";
}

if(-e "$outdir/t/00load.t") {
  $T_e = 1;
  print "ok 9\n";
}
else {
  warn "$outdir/t/00load.t was not created\n";
  print "not ok 9\n";
}

if($M_e) {
  warn "Couldn't unlink Makefile.PL\n"
    unless unlink "$outdir/Makefile.PL";
}

if($PM_e) {
  warn "Couldn't unlink FOO.pm\n"
    unless unlink "$outdir/FOO.pm";
}


if($X_e) {
  warn "Couldn't unlink FOO.xs\n"
    unless unlink "$outdir/FOO.xs";
}

if($MAN_e) {
  warn "Couldn't unlink MANIFEST\n"
    unless unlink "$outdir/MANIFEST";
}

if($T_e) {
  warn "Couldn't unlink $outdir/t/00load.t\n"
    unless unlink "$outdir/t/00load.t";
  warn "Couldn't remove $outdir/t directory: $!"
    unless rmdir "$outdir/t";
}

#===========================#

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

#===========================#

sub check_xs {

  my $ok0 = 0;
  open RD2, '<', "$outdir/FOO.xs" or die "Couldn't open $outdir/FOO.xs: $!";

  while(<RD2>) {
    if($_ =~ /PREINIT:/) {$ok0 = 1}
  }

  close RD2 or die "Couldn't close $outdir/FOO.xs: $!";
  return $ok0;

}

#===========================#

sub manifest_compare {
    my @one = @{$_[0]};
    my @two = @{$_[1]};

    for my $one(@one) {
      my $ok = 0;
      for my $two(@two) {
        $ok = 1 if $one eq $two;
      }
      if(!$ok) {
        warn "No match found for $one\n";
        return 0;
      }
    }
    return 1;
}

#===========================#

#===========================#
