use warnings;
use strict;
use Math::Random::BlumBlumShub qw(:all);

my($have_gmp, $have_gmpz) = (0, 0);

eval{require Math::GMP;};
$have_gmp = 1 if !$@;

eval{require Math::GMPz;};
$have_gmpz = 1 if !$@;

if(!$have_gmp && !$have_gmpz) {die "You need Math::GMP and/or Math::GMPz to use this module"}

if($have_gmp && $have_gmpz) {print "1..26\n"}
else {print "1..13\n"}

my $s1 = '615389388455725613122981570401989286707';
my $s2 = '8936277569639798554773638405675965349567';
my $count = 0;

if($have_gmp) {
  my $p1 =  Math::GMP->new($s1);
  my $p2 =  Math::GMP->new($s2);
  my $seed = Math::GMP->new(int(rand(100000)));
  my $random_offset = 10 + int(rand(10000));
  my $neg_seed = $seed * -1;
  my $bitstream = Math::GMP->new(0);
  my $bitstream_20000 = Math::GMP->new();
  my $size = Math::GMP::sizeinbase_gmp($p1 * $p2, 2);

  bbs_seedgen($seed, $p1, $p2);
  if(Math::GMP::sizeinbase_gmp($seed, 2) <= $size && Math::GMP::sizeinbase_gmp($seed, 2) >= $size - 30) {print "ok 1\n"}
  else {
    warn " $size ", Math::GMP::sizeinbase_gmp($seed, 2), "\n";
    print "not ok 1\n";
  }

  bbs($bitstream, $p1, $p2, $seed, 20000);
  bbs($bitstream_20000, $p2, $p1, $seed, 20000 + $random_offset);

  my $bitstream_copy = $bitstream;
  my $bitstream_20000_copy = $bitstream_20000;

  if(monobit($bitstream)) {print "ok 2\n"}
  else {print "not ok 2\n"}

  if(longrun($bitstream)) {print "ok 3\n"}
  else {print "not ok 3\n"}

  if(runs($bitstream)) {print "ok 4\n"}
  else {print "not ok 4\n"}

  if(poker($bitstream)) {print "ok 5\n"}
  else {print "not ok 5\n"}

  eval{bbs($bitstream, $p1 + 2, $p2, $seed, 1000);};
  if($@ =~ /prime is unsuitable/) {print "ok 6\n"}
  else {print "not ok 6\n"}

  eval{bbs($bitstream, $p1, $p2, $seed * -1, 1000);};
  if($@ =~ /Negative/) {print "ok 7\n"}
  else {print "not ok 7\n"}

  eval{bbs($bitstream, $p1, $p2, $p1 * $p2 + 4, 1000);};
  if($@ =~ /too big/) {print "ok 8\n"}
  else {print "not ok 8\n"}

  eval{bbs_seedgen($neg_seed, $p1, $p2);};
  if($@ =~ /Negative/) {print "ok 9\n"}
  else {print "not ok 9\n"}

  my @ret = autocorrelation($bitstream, 1);

  if($ret[0] > 9654 && $ret[0] < 10346) {print "ok 10\n"}
  else {
    warn "Math::GMP: 10: Got $_[0]";
    print "not ok 10\n";
  }

  if($bitstream == $bitstream_copy) {print "ok 11\n"}
  else {
    warn "\$bitstream got clobbered\n";
    print "not ok 11\n";
  }

  if(autocorrelation_20000($bitstream_20000, $random_offset)) {print "ok 12\n"}
  else {print "not ok 12\n"}

  if($bitstream_20000_copy == $bitstream_20000) {print "ok 13\n"}
  else {
    warn "\$bitstream_20000_copy got clobbered\n";
    print "not ok 13\n";
  }

  $count = 13;
}

if($have_gmpz) {
  my $p1 =  Math::GMPz->new($s1);
  my $p2 =  Math::GMPz->new($s2);
  my $seed = Math::GMPz->new(int(rand(100000)));
  my $random_offset = 10 + int(rand(10000));
  my $neg_seed = $seed * -1;
  my $bitstream = Math::GMPz::Rmpz_init2(20000);
  my $bitstream_20000 = Math::GMPz::Rmpz_init2(20000 + $random_offset);
  my $size = Math::GMPz::Rmpz_sizeinbase($p1 * $p2, 2);

  bbs_seedgen($seed, $p1, $p2);
  if(Math::GMPz::Rmpz_sizeinbase($seed, 2) <= $size && Math::GMPz::Rmpz_sizeinbase($seed, 2) >= $size - 30) {print "ok ", $count + 1, "\n"}
  else {print "not ok ", $count + 1, "\n"}

  bbs($bitstream, $p1, $p2, $seed, 20000);
  bbs($bitstream_20000, $p2, $p1, $seed, 20000 + $random_offset);

  my $bitstream_copy = $bitstream;
  my $bitstream_20000_copy = $bitstream_20000;

  if(monobit($bitstream)) {print "ok ", $count + 2, "\n"}
  else {print "not ok ", $count + 2, "\n"}

  if(longrun($bitstream)) {print "ok ", $count + 3, "\n"}
  else {print "not ok ", $count + 3, "\n"}

  if(runs($bitstream)) {print "ok ", $count + 4, "\n"}
  else {print "not ok ", $count + 4, "\n"}

  if(poker($bitstream)) {print "ok ", $count + 5, "\n"}
  else {print "not ok ", $count + 5, "\n"}

  eval{bbs($bitstream, $p1 + 2, $p2, $seed, 1000);};
  if($@ =~ /prime is unsuitable/) {print "ok ", $count + 6, "\n"}
  else {print "not ok ", $count + 6, "\n"}

  eval{bbs($bitstream, $p1, $p2, $seed * -1, 1000);};
  if($@ =~ /Negative/) {print "ok ", $count + 7, "\n"}
  else {print "not ok ", $count + 7, "\n"}

  eval{bbs($bitstream, $p1, $p2, $p1 * $p2 + 4, 1000);};
  if($@ =~ /too big/) {print "ok ", $count + 8, "\n"}
  else {print "not ok ", $count + 8, "\n"}

  eval{bbs_seedgen($neg_seed, $p1, $p2);};
  if($@ =~ /Negative/) {print "ok ", $count + 9, "\n"}
  else {print "not ok ", $count + 9, " $@\n"}

  my @ret = autocorrelation($bitstream, 2);

  if($ret[0] > 9654 && $ret[0] < 10346) {print "ok ", $count + 10, "\n"}
  else {
    warn "Math::GMPz: 10: Got $_[0]";
    print "not ok ", $count + 10, "\n";
  }

  if($bitstream == $bitstream_copy) {print "ok ", $count + 11, "\n"}
  else {
    warn "\$bitstream got clobbered\n";
    print "not ok ", $count + 11, "\n";
  }

  if(autocorrelation_20000($bitstream_20000, $random_offset)) {print "ok ", $count + 12, "\n"}
  else {print "not ok ", $count + 12, "\n"}

  if($bitstream_20000_copy == $bitstream_20000) {print "ok ", $count + 13, "\n"}
  else {
    warn "\$bitstream_20000_copy got clobbered\n";
    print "not ok ", $count + 13, "\n";
  }

}
