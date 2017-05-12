#!/usr/bin/perl

sub BEGIN { push @INC,"./blib/arch/auto/Digest/ManberHash","./blib/lib"; };
use Digest::ManberHash;


$a=Digest::ManberHash->new();
while (@ARGV)
{
  $fn=shift;

  $b=$a->DoHash($fn);
  push @fn,$fn;
  push @a,$b;
}

if (@fn == 1)
{
  print $fn[0],"\n";
  $x=$a[0]{"data"};
  @k=sort keys %$x;
  for ($i=0; $i<@k; $i++)
  {
    printf "%-12s:%3d%s",
    $k[$i],$x->{$k[$i]}, ( ($i+1) % 4) ? "    " :"\n" ;
  }
  print "\n";
}
else
{
  for ($i=0; $i<@a-1; $i++)
  {
    for ($j=$i+1; $j<@a; $j++)
    {
      $v=$a->Compare($a[$i],$a[$j]);
      $f1=$fn[$i];
      $f2=$fn[$j];
      write;
    }
  }
}


format =
@.####   @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<
$v,$f1,$f2
.

