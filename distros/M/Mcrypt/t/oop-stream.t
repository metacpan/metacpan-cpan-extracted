#!/usr/bin/perl

use Test::More tests => 5;
# 9 tests for each alg/mode

@algs = qw (ARCFOUR);

@modes = qw (STREAM);

use Mcrypt qw(:ALGORITHMS :MODES :FUNCS);

sub doit {
  my($method, $alg, $mode, $infile, $outfile) = @_;
  my($td) = Mcrypt->new( algorithm => $alg,
			 mode => $mode,
		         verbose => 0 );
  ok($td, "Loaded $alg/$mode");
  my($key) = "k" x $td->{KEY_SIZE};
  my($iv) = "i" x $td->{IV_SIZE};
  my $i = eval { $td->init($key, $iv) };
  ok($i && !$@, "initialized");
  open(IN,  "<$infile" );
  open(OUT, ">$outfile");
  eval {
    if($method eq "encrypt") {
      while(<IN>) {
        $out = $td->encrypt($_);
        print OUT $out;
      }
    } else {
      while(<IN>) {
        $out = $td->decrypt($_);
        print OUT $out;
      }
    }
  };
  close(IN) && close(OUT);
}

sub testam {
 my ($alg, $mode) = @_;
  doit("encrypt", $alg, $mode, "t/testfile", "t/testfile.blown");
  doit("decrypt", $alg, $mode, "t/testfile.blown", "t/testfile.2");
  unlink("t/testfile.blown");

  open(FILE, "<t/testfile");
$oldis = $/;
undef($/);
  $file1 = <FILE>;
$/ = $oldis;
  close(FILE);
  open(FILE, "<t/testfile.2");
$oldis = $/;
undef($/);
  $file2 = <FILE>;
$/ = $oldis;
  close(FILE);
#  unlink("t/testfile.2");

  is($file1, $file2, "crypto worked");
}
foreach $alg (@algs) {
  $valg = eval "{ Mcrypt::$alg }";
  foreach $mode (@modes) {
    $vmode = eval "{ Mcrypt::$mode }";
    testam($valg, $vmode);
  }
}
