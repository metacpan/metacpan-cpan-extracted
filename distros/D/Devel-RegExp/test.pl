use Devel::RegExp;

print "ok 1\n";

{
  my $reg = new Devel::RegExp "abc";

  print "ok 2\n" if $reg;
  #$reg->regdump;
  print "ok 3\n" if $reg->regexec("xyabcde");
  print "ok 4\n" unless $reg->regexec("xyaBcde");
  $reg = new Devel::RegExp "abc", FOLD;
  print "ok 5\n" if $reg->regexec("xyabcde");
  print "ok 6\n" if $reg->regexec("xyaBcde");  
  print "ok 7\n" unless $reg->regexec("xyaBBcde");  
  $reg = new Devel::RegExp ".((a)b(c))(e)?.", FOLD;
  print "ok 8\n" if $reg->regexec("xyaBcde");  
  print "ok 9\n" if $reg->lastparen == 3; 
  @matches = $reg->match;
  print "ok 10\n" if "@matches" eq "1 6 2 5 2 3 4 5  ";
}

print "ok 11\n";
