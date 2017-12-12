#!perl -wT

use File::HomeDir'Tiny;

print "1..4\n";

{
 local $ENV{HOME} = '/hoom';
 print "not " unless home eq '/hoom';
 print "ok 1\n";
 {
  local $ENV{HOME} = '/hoose';
  print "not " unless home eq '/hoose';
  print "ok 2\n";
 }
 print "not " unless home eq '/hoom';
 print "ok 3\n";
}

eval { import File'HomeDir'Tiny foo => } ; $line = __LINE__;
$want = 
  "File::HomeDir::Tiny does not export foo at ".__FILE__." line $line.\n";
print "# [$@]\n#   should be\n# [$want]\nnot " unless $@ eq $want;
print "ok 4\n";
