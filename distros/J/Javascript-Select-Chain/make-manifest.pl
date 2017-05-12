open F, "find . -type f |";

while (<F>) {
  next if /blib/;
  next if /~$/;
  next if /tar$/;
  next if /gz$/;
  next if /MANIFEST.tmp/;
  
  push @F, substr($_, 2);
}

open O, ">MANIFEST.tmp" or die $!;

print O join "", @F;
