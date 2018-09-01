use ELF::sign;

print "signFile\n";
signFile("dev/test", "dev/test.signed");

print "verifyFile\n";
verifyFile("dev/test.signed");

print "verifyFileInmemory\n";
verifyFileInmemory("dev/test.signed");
unlink "dev/test.signed";

print "signFileInmemory\n";
signFileInmemory("dev/test", "dev/test.mem.signed");

print "verifyFile\n";
verifyFile("dev/test.mem.signed");

print "verifyFile\n";
verifyFile("dev/test.mem.signed");

print "verifyFileInmemory\n";
verifyFileInmemory("dev/test.mem.signed");
unlink "dev/test.mem.signed";

print "signInmemory\n";
my $signeddata = signInmemoryFile("dev/test");

print "verifyInmemory\n";
print "  Length:".length($signeddata)."\n";
verifyInmemory($signeddata);

print "verifyInmemoryFile\n";
writeFile("dev/test.mem.signed.out", $signeddata);
verifyFile("dev/test.mem.signed.out");

print "verifyInmemoryFile FAIL\n";
writeFile("dev/test.mem.signed.out", "x".$signeddata);
verifyFile("dev/test.mem.signed.out");

print "verifyInmemoryFile FAIL POST\n";
writeFile("dev/test.mem.signed.out", $signeddata."x");
verifyFile("dev/test.mem.signed.out");
unlink "dev/test.mem.signed.out";

print "signInmemory\n";
my $data = time();
print "  Length:".length($data)."\n";
my $signeddata = signInmemory($data);

print "verifyInmemory\n";
verifyInmemory($signeddata);
print "verifyInmemoryGet\n";
my $data = verifyInmemoryGet($signeddata);
print "  Get:".$data."\n";
print "  Length:".length($data)."\n";

print "verifyInmemory FAIL\n";
verifyInmemory("x".$signeddata);

print "verifyInmemory FAIL POST\n";
verifyInmemory($signeddata."x");

print "verifyInmemoryFile\n";
writeFile("dev/test.mem.signed.out.time", $signeddata);
my $data = verifyFileGet("dev/test.mem.signed.out.time");
print "  Get:".$data."\n";
print "  Length:".length($data)."\n";
unlink "dev/test.mem.signed.out.time";

sub verifyInmemory {
   my $data = shift;
   my $x = ELF::sign->new();
   $x->data($data);
   verify($x);
}

sub verifyInmemoryGet {
   my $data = shift;
   my $x = ELF::sign->new();
   $x->data($data);
   verify($x);
   unless ($return = $x->get(1)) {
      print "  ERROR: verifyInmemoryGet->get\n";
   }
   return $return;
}

sub verifyFileInmemory {
   my $data = readFile(shift);
   my $x = ELF::sign->new();
   $x->data($data);
   verify($x);
}

sub verifyFile {
   my $x = ELF::sign->new();
   $x->dataFile(shift);
   verify($x);
}

sub verifyFileGet {
   my $x = ELF::sign->new();
   $x->dataFile(shift);
   verify($x);
   unless ($return = $x->get(1)) {
      print "  ERROR: verifyFileGet->get\n";
   }
   return $return;
}

sub verify {
   my $x = shift;
   $x->crtFile("dev/test.crt");
   if (my $error = $x->verify()) {
      print "  ERROR: verify: ".$error."\n";
   } else {
      print "  Verified\n";
   }
}

sub signInmemoryFile {
   return signInmemory(readFile(shift));
}

sub signInmemory {
   my $data = shift;
   my $x = ELF::sign->new();
   $x->data($data);
   sign($x);
   my $return = '';
   unless ($return = $x->get()) {
      print "  ERROR: signInmemory->get\n";
   }
   return $return;
}

sub signFileInmemory {
   my $file = shift;
   my $outfile = shift;
   my $data = readFile($file);
   my $x = ELF::sign->new();
   $x->data($data);
   sign($x);
   if (my $error = $x->save($outfile)) {
      print "  ERROR: signFileInmemory->save: ".$error."\n";
   }
}

sub signFile {
   my $file = shift;
   my $outfile = shift;
   my $x = ELF::sign->new();
   $x->dataFile($file);
   sign($x);
   if (my $error = $x->save($outfile)) {
      print "  ERROR: signFile->save: ".$error."\n";
   }
}

sub sign {
   my $x = shift;
   $x->crtFile("dev/test.crt");
   $x->keyFile("dev/test.key");
   if (my $error = $x->sign()) {
      print "  ERROR: sign: ".$error."\n";
   } else {
      print "  Signed.\n";
   }
   if (my $error = $x->verify()) {
      print "  ERROR: sign->verify: ".$error."\n";
   } else {
      print "  Verified\n";
   }
}

sub readFile {
   open(IN, "<", shift) ||
      die $!;
   my $data = undef;
   while(sysread(IN, $buf, 1024)) {
      $size += length($buf);
      $data .= $buf;
   }
   #print "  Read.".$size."\n";
   return $data;
}

sub writeFile {
   open(OUT, ">", shift) ||
      die $!;
   my $return = syswrite(OUT, shift);
   close OUT;
   return $return;
}
