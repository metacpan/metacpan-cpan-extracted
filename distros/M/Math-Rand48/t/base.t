$| = 1;
$t = 1;
print "1..37\n";
eval { require Math::Rand48 };
warn $@ if $@;
print "not " if $@;
print "ok ",$t++,"\n";
eval { Math::Rand48->import };
warn $@ if $@;
print "not " if $@;
print "ok ",$t++,"\n";
    
my $i;
my $s = seed48($i);
my $x = $s;
seed48($s);
for $i (0..4)
 {
  $d[$i] = drand48();
  print "not " unless (0 <= $d[$i] && $d[$i] < 1.0);
  print "ok ",$t++,"\n";
 }
for $i (0..4)
 {
  $e[$i] = erand48($s);
  print "not " unless (0 <= $e[$i] && $e[$i] < 1.0);
  print "ok ",$t++,"\n";
  unless ($e[$i] == $d[$i])
   {
    warn sprintf("e = %g d = %g \n",$e[$i],$d[$i]);
    print "not " 
   }
  print "ok ",$t++,"\n";
 }

for $i (0..4)
 {
  $x[$i] = erand48($x);
  print "not " unless (0 <= $x[$i] && $x[$i] < 1.0);
  print "ok ",$t++,"\n";
  unless ($e[$i] == $x[$i])
   {
    warn sprintf("e = %g x = %g \n",$e[$i],$x[$i]);
    print "not " 
   }
  print "ok ",$t++,"\n";
 }
    
undef $x;
for $i (0..4)
 {
  $d[$i] = erand48($x);
  print "not " unless (0 <= $x[$i] && $x[$i] < 1.0);
  print "ok ",$t++,"\n";
  if ($i)
   {
    print "not " if ($d[$i] == $d[$i-1]);
    print "ok ",$t++,"\n";
   }
 }

print "not " if erand48($x = "Foo") == erand48($x = "Bar");
print "ok ",$t++,"\n";

