
# Time-stamp: "2004-12-29 19:50:33 AST"

BEGIN { $| = 1; print "1..1\n"; }
END {print "fail 1\n" unless $loaded;}
use File::Findgrep 0.01;
print "# Perl v$], File::Findgrep v$File::Findgrep::VERSION\n";
$loaded = 1;
print "ok 1\n";
