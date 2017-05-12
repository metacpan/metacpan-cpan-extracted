# Now check the output file and see how it did.
print "1..10\n";
unless (open(OUT,'smallprof.out')) {
  for (1..10) { 
    print "not ok $_\n"; 
  } 
  exit;
}
undef $/;
$_ = <OUT>;
close OUT;
print +(/Profile of \(eval/ && m!Profile of t.part1\.b!) 
                                           ? "ok  1\n" : "not ok  1\n";
my (@matches) = /Profile of/g;
print +(@matches == 3)                     ? "ok  2\n" : "not ok  2\n";
print +(/^\s*[16]\s.*:for \(1..5\).*$/m)   ? "ok  3\n" : "not ok  3\n";
print +(!/\$x\+\+;/)                       ? "ok  4\n" : "not ok  4\n";
print +(m'^\s*10\s.*\$z\+\+; \$z--;\s*$'m) ? "ok  5\n" : "not ok  5\n";
if (/^\s*1\s+(\d+.\d+)\s.*sleep/m) {
  print "ok  6\n";
  my $a=$1;
  $a =~ s/,/./;
  print +(($a + 0.2)>1.0)                  ? "ok  7\n" : "not ok  7\n";
} else {
  print "not ok 6\nnot ok 7\n";
}
print +(/\$c\+\+;/)                        ? "ok  8\n" : "not ok  8\n";
print +(!/\$b\+\+;/)                       ? "ok  9\n" : "not ok  9\n";
print +(!/\$a\+\+;/)                       ? "ok 10\n" : "not ok 10\n";

# Now setup for parts 3 and 4
open(DOT,'>.smallprof');
print DOT '$DB::drop_zeros=1;';
print DOT '$DB::profile=0;';
close DOT;
