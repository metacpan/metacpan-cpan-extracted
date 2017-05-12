#!perl -w

use strict;
no strict "vars";

use Graph::Kruskal;

# ======================================================================
#   $Graph::Kruskal::VERSION
# ======================================================================

print "1..1\n";

$n = 1;
if ($Graph::Kruskal::VERSION eq "2.0")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

