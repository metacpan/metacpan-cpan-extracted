#!/usr/bin/perl

use Test::More tests => 150;
# 9 tests for each alg/mode

@algs = qw (BLOWFISH
		DES
		3DES
		GOST
		CAST_128
		XTEA
		RC2
		TWOFISH
		CAST_256
		SAFERPLUS
		LOKI97
		SERPENT
		RIJNDAEL_128
		RIJNDAEL_192
		RIJNDAEL_256);

@modes = qw (CBC
             ECB);

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
      while(sysread(IN, $_, $td->{BLOCK_SIZE})) {
        $out = $td->encrypt($_);
        print OUT $out;
      }
    } else {
      while(sysread(IN, $_, $td->{BLOCK_SIZE})) {
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
