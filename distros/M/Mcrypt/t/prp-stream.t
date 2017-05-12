#!/usr/bin/perl

use Test::More tests => 7;

@algs = qw (ARCFOUR);

@modes = qw (STREAM);

use Mcrypt qw(:ALGORITHMS :MODES :FUNCS);

sub doit {
  my($method, $alg, $mode, $infile, $outfile) = @_;
  my($td) = Mcrypt::mcrypt_load( $alg, "", $mode, "");
  ok($td, "loaded $alg/$mode");
  $keysize = Mcrypt::mcrypt_get_key_size($td);
  $ivsize = Mcrypt::mcrypt_get_iv_size($td);
  my($key) = "k" x $keysize;
  my($iv) = "i" x $ivsize;
  my $i = eval { Mcrypt::mcrypt_init($td, $key, $iv); };
  ok($i && !$@, "initialized");
  open(IN,  "<$infile" ) || (($loaded+=2) && return 0);
  open(OUT, ">$outfile") || (($loaded+=2) && return 0);
  if($method eq "encrypt") {
    while(<IN>) {
      $out = Mcrypt::mcrypt_encrypt($td, $_);
      print OUT $out;
    }
  } else {
    while(<IN>) {
      print OUT Mcrypt::mcrypt_decrypt($td, $_);
    }
  }
  close(IN) && close(OUT);
  eval { Mcrypt::mcrypt_end($td); };
  ok(!$@, "destroyed");
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
  unlink("t/testfile.2");

  is $file1, $file2, "crypto worked";
}
foreach $alg (@algs) {
  $valg = eval "{ Mcrypt::$alg }";
  foreach $mode (@modes) {
    $vmode = eval "{ Mcrypt::$mode }";
    testam($valg, $vmode);
  }
}
