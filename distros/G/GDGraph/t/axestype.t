# $Id: axestype.t,v 1.1 2005/12/14 04:22:16 ben Exp $
#
# Test stuff related to axestype charts
#
use Test;
use strict;

BEGIN { plan tests => 13 }

# Use "mixed" as the generic chart type to test
use GD::Graph::mixed;
ok(1);

print "# Check for division by 0 errors when all data points are 0\n";
{
    my $g = GD::Graph::mixed->new();
    if (ok(defined $g))
    {
	ok($g->isa("GD::Graph::axestype"));
	my $gd = eval { $g->plot([[qw/A B C D E/], [0, 0, 0, 0, 0]]) };
	if (ok(defined $gd))
	{
	    ok($gd->isa("GD::Image"));
	}
	else
	{
	    skip($@, 0);
	}
    }
    else
    {
	skip("GD::Graph::mixed->new() failed", 0) for 1..3;
    }
}

print "# Check for division by 0 errors on zero two_axes charts\n";
{
    my $g = GD::Graph::lines->new();
    $g->set(two_axes => 1);
    if (ok(defined $g))
    {
	ok($g->isa("GD::Graph::axestype"));
	my $gd = eval { $g->plot([[qw/A B/], [0, 0], [0, 0]]) };
	if (ok(defined $gd))
	{
	    ok($gd->isa("GD::Image"));
	}
	else
	{
	    skip($@, 0);
	}
    }
    else
    {
	skip("GD::Graph::lines->new() failed", 0) for 1..3;
    }
}

print "# Check for division by 0 errors on non-zero two_axes charts\n";
{
    my $g = GD::Graph::lines->new();
    $g->set(two_axes => 1);
    if (ok(defined $g))
    {
	ok($g->isa("GD::Graph::axestype"));
	my $gd = eval { $g->plot([[qw/A B/], [1, 1], [1, 1]]) };
	if (ok(defined $gd))
	{
	    ok($gd->isa("GD::Image"));
	}
	else
	{
	    skip($@, 0);
	}
    }
    else
    {
	skip("GD::Graph::lines->new() failed", 0) for 1..3;
    }
}
