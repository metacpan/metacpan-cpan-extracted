
# Time-stamp: "2004-12-29 19:01:10 AST"

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Mac::FileSpec::Unixish;
$loaded = 1;
print "ok 1\n";
print "# Running under MacOS: ",
  &Mac::FileSpec::Unixish::under_macos() ? "yes\n" : "no\n";


