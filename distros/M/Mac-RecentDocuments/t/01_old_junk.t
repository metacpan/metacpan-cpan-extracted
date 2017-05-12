
# Time-stamp: "2004-12-29 18:57:23 AST"


BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Mac::RecentDocuments;
$loaded = 1;
print "ok 1\n";

print "# Am under MacOS and could find my Recent Documents dir: ",
  Mac::RecentDocuments::OK ? "Yes\n" : "No\n";

print "ok 2\n";
