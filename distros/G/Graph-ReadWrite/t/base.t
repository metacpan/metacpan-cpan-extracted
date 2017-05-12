#!./perl
#
# base.t - simple tests for the base classes
#

use Graph::Writer;
use Graph::Reader;

print "1..2\n";

#
# You can't create instances of the base classes directly
#

#-----------------------------------------------------------------------
eval { $r = Graph::Reader->new(); };
if ($@ && not defined $r)
{
    print "ok 1\n";
}
else
{
    print "not ok 1\n";
}

#-----------------------------------------------------------------------
eval { $r = Graph::Writer->new(); };
if ($@ && not defined $r)
{
    print "ok 2\n";
}
else
{
    print "not ok 2\n";
}

