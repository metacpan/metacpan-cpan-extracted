#!perl -w

use strict;
no strict "vars";

use Math::MatrixBool;

# ======================================================================
#   $Math::MatrixBool::VERSION
# ======================================================================

print "1..1\n";

$n = 1;
if ($Math::MatrixBool::VERSION eq "5.8")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

