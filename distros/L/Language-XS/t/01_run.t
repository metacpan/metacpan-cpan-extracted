BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use Language::XS;
$loaded = 1;
print "ok 1\n";

# create a Language::XS-object
my $xs = new Language::XS cachedir => undef;

print $xs ? "" : "not ", "ok 2\n";

# add plain C to the header
$xs->hdr("#include <stdlib.h>");
# add a c function (not using xs syntax)
$xs->cfun('sv_setiv (ST(0), abs (1 + SvIV (ST(0)))); XSRETURN (1);');

# now compile ...
print $xs->gen ? "" : "not ", "ok 3\n";
print $xs->messages;
      
# ... load ...
print $xs->load ? "" : "not ", "ok 4\n";

# ... and find the code-reference
my $coderef = $xs->find;

print $coderef ? "" : "not ", "ok 5\n";

# Now call it
$x =  77; print $coderef && ($coderef->($x) == 78) ? "" : "not ", "ok 6\n";
$x = -77; print $coderef && ($coderef->($x) == 76) ? "" : "not ", "ok 7\n";
