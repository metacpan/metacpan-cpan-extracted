use warnings;
use strict;
use Math::Decimal64 qw(:all);
use Config;

print "1..1\n";

if($Config{ivsize} > 4) {
  warn "\n Skipping these tests - the precision of your UV\n",
       " is greater than the precision of the _Decimal64 type\n",
       " Usefulness of UV overloading is therefore limited.\n";
  print "ok 1\n";
}
else {

  my $dec1 = NVtoD64(1.7);

  my $uv = ~0;
  my $uv_d64 = PVtoD64("$uv");

  my($ok, $c);

  if($dec1 * $uv > $uv)          {$ok .= 'a'}
  if($dec1 < $uv)                {$ok .= 'b'}
  if($uv_d64 == $uv)             {$ok .= 'c'}
  if(($uv_d64 <=> $uv) == 0)     {$ok .= 'd'}
  if(($dec1 * $uv <=> $uv) == 1) {$ok .= 'e'}
  if(($dec1 <=> $uv) == -1)      {$ok .= 'f'}
  if(!defined(NaND64() <=> $uv)) {$ok .= 'g'}

  if($dec1 * $uv >= $uv)         {$ok .= 'h'}
  if($dec1 <= $uv)               {$ok .= 'i'}


  if($ok eq 'abcdefghi') {print "ok 1\n"}
  else {
    warn "\n1: \$ok: $ok\n";
    print "not ok 1\n";
  }
}


