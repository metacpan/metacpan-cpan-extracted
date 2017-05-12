BEGIN { $| = 1; print "1..33\n"; }
END {print "not ok 1\n" unless $loaded;}
use MPE::File;
$loaded = 1;
print "ok 1\n";

our $testcount = 1;
sub ok {
  my $result = shift;
  ++$testcount;
  if (defined($result) && $result) {
    print "ok $testcount\n";
  } else {
    my ($package, $filename, $line) = caller;
    print "not ok $testcount\n";
    print "Test $testcount failed on line $line of $filename\n";
    $result = 0;
  }
  return $result;
}

my $file;
my $teststring;
$teststring = "F=./nonexistent.file,old;acc=in";
$file = MPE::File->new($teststring);
ok($MPE_error == -16187249);
$fname = "./filetest.out";

unlink($fname);
$teststring = "$fname,new;acc=out;save;rec=-60,,f,ascii";
ok ($file = MPE::File->new($teststring)) or 
  print STDERR "open failed: $teststring\n";

my $writes = 0;
for (my $i=1; $i <= 10; $i++) {
  if ($file->writerec($i)) {
    $writes++;
  }
}

ok ($writes == 10);

ok($file->fclose(1,0));
my $recsize;
ok (($recsize) = flabelinfo($fname, 0, 30)) 
   or print "Error on flabelinfo: $MPE_error\n";
ok ($recsize == 60)
   or print "Recsize should be 60, was $recsize\n";

$teststring = "$fname,old;acc=in";
ok ($file = MPE::File->new($teststring)) or 
  print STDERR "open failed: $teststring\n";

my $eof;
ok (($eof) = $file->ffileinfo(10))
   or print "Error on ffileinfo: $MPE_error\n";
ok ($eof == 10)
   or print "eof should be 10, was $recsize\n";


my $reads = 0;
my $rec;
my $lastrec;
while (defined($rec = $file->readrec)) {
  $reads++;
  $lastrec = $rec;
}
ok ($reads == 10)
  or print "Should have read 10 recs, read $reads instead\n";
ok ($lastrec =~ /^10 *$/) or print "lastrec = '$lastrec'\n";
ok($file->fclose(1,0));


$teststring = "$fname,old;acc=update";
ok ($file = MPE::File->new($teststring)) or 
  print STDERR "open failed: $teststring\n";

ok ($rec = $file->freaddir(4));

ok ($rec =~ /^5\s*$/) 
  or print "freaddir(4) rec='$rec'\n";

$rec = "Surprise";
ok ($file->fwritedir($rec, 6));

ok ($file->fpoint(0));
my $recnum = 0;
while (defined($rec=$file->readrec)) {
  ok (($recnum == 6 && $rec =~ /Surprise/) || 
     ($rec =~ /^(\d+)\s*/ && ($1 - 1 == $recnum)))

    or print "recnum=$recnum rec=$rec\n";
  $recnum++;
}


my @ffileinfotypes = qw( x
  A28 S S s s S S s l l
  l l l s s S s A18 l s
  s s s s s A32 A32 S s s
  s S s s s S l S x l
  s s A36 s A18 s s s S S
  s l S S S l s s s s
  A52 A8 a20 q x L L L L x
  x x x q A64 A34 L L s z
  L l l S A18 l A18 l L L
  q l L l l l l l l l
  l l l l l l l l q l
);
@in = grep {$ffileinfotypes[$_] ne 'x'} 1 .. 110;
@out = $file->ffileinfo(@in);
ok(1); #i.e. The last test did not abort the program
my @path = grep {/$fname/} @out;
ok (scalar(@path) == 1) 
  or print "\@path = ", join(' ', @path), "\n";

ok($file->fclose(4,0));

my $testconst = MPE::File->new("./testwrite,new;del;acc=update")
  or die ("Cannot open testwrite: $MPE_error");

$testconst->writerec("Hello there");
ok(1); #i.e. The last test did not abort the program

$testconst->fcontrol(2, 1);
ok(1); #i.e. The last test did not abort the program
