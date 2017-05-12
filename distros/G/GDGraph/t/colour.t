# $Id: colour.t,v 1.1 2005/12/14 04:22:16 ben Exp $
use Test;
use strict;

BEGIN { plan tests => 9 }

use GD::Graph::colour qw(:colours :lists :convert);

ok(1);

my $colour = '#7fef10';

print "# Convert a colour between hex and rgb list\n";
my @rgb = hex2rgb($colour);
ok("@rgb", "127 239 16");
ok($colour, rgb2hex(@rgb));

# Get the number of colours currently defined
my $nc = scalar (@_ = colour_list());

print "# add a colour explicitly\n";
my $rc = add_colour(foo => [12, 13, 14]);
ok($rc, "foo");
ok($nc + 1, $nc = scalar (@_ = colour_list()));
@rgb = _rgb("foo");
ok("@rgb", "12 13 14");

print "# The next should add a colour, since it hasn't been defined yet\n";
@rgb = _rgb("#7f1020");
ok("@rgb", "127 16 32");
ok($nc + 1, $nc = scalar (@_ = colour_list()));

print "# Check that colour_list() limits correctly\n";
ok(13, scalar (@_ = colour_list(13)));
