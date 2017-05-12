# $Id: data.t,v 1.1 2005/12/14 04:22:16 ben Exp $
use Test;
use strict;

BEGIN { plan tests => 37 }

use GD::Graph::Data;
ok(1);
use Data::Dumper;
ok(1);

my @data = (
	[qw( Jan Feb Mar )],
	[11, 12],
	[21],
	[31, 32, 33, 34],
);

print "# Test setting up of object\n";
my $data = GD::Graph::Data->new();
ok($data);
ok($data->isa("GD::Graph::Data"));

$GD::Graph::Error::Debug = 4;

print "# Test that empty object is empty\n";
my @l = $data->get_min_max_x;
ok(@l, 0);

my $err_ar_ref = $data->clear_errors;
ok(@{$err_ar_ref}, 1);

print "# Fill with data\n";
my $rc = $data->copy_from(\@data);
ok($rc);

#@l = $data->get_min_max_x;
#ok(@l, 2);
#ok("@l", "Jan Jan"); # Nonsensical test for non-numeric data

print "# Check number of data sets\n";
my $nd = $data->num_sets;
ok($nd, 3);

print "# Get min and max\n";
@l = $data->get_min_max_y(1);
ok(@l, 2);
ok("@l", "11 12");

@l = $data->get_min_max_y($nd);
ok(@l, 2);
ok("@l", "31 34");

print "# Check number of points, and y value\n";
my $np = $data->num_points;
my $y = $data->get_y($nd, $np-1);
ok($np, 3);
ok($y, 33);

print "# Add a point and check dimensions\n";
$data->add_point(qw(X3 13 23 35));
$nd = $data->num_sets;
$np = $data->num_points;
$y = $data->get_y($nd, $np-1);
ok($nd, 3);
ok($np, 4);
ok($y, 35);

@l = $data->y_values(3) ;
ok(@l, 4);
ok("@l", "31 32 33 35");

print "# Check cumulate\n";
$data->cumulate(preserve_undef => 0) ;
@l = $data->y_values(3);
ok(@l, 4);
ok("@l", "63 44 33 71");

print "# Check reverse\n";
$data->reverse;
@l = $data->y_values(1) ;
ok(@l, 4);
ok("@l", "63 44 33 71");

print "# Check min and max\n";
@l = $data->get_min_max_y_all;
ok(@l, 2);
ok("@l", "0 71");

print "# Check copy()\n";
my $data2 = $data->copy;
ok($data2);
ok($data2->isa("GD::Graph::Data"));
ok(Dumper($data2), Dumper($data));

my $file;

print "# Read tab-separated file\n";

$file =	    -f 'data.tab'   ? 'data.tab'  :
	    -f 't/data.tab' ? 't/data.tab':
	    undef;

$data = GD::Graph::Data->new();
$rc = $data->read(file => $file);
ok(ref $rc, "GD::Graph::Data", "Couldn't read input data.tab input file");

if (!defined $rc)
{
    skip("data.tab not read", 0) for 1..2;
}
else
{
    ok($data->num_sets(), 5);
    ok(scalar $data->num_points(), 4);
}

print "# Read comma-separated file\n";

$file =	    -f 'data.csv'   ? 'data.csv'  :
	    -f 't/data.csv' ? 't/data.csv':
	    undef;

$data = GD::Graph::Data->new();
$rc = $data->read(file => $file, delimiter => qr/,/);
ok(ref $rc, "GD::Graph::Data", "Couldn't read input data.csv input file");

if (!defined $rc)
{
    skip("data.csv not read", 0) for 1..2;
}
else
{
    ok($data->num_sets(), 5);
    ok(scalar $data->num_points(), 4);
}

print "# Read from DATA\n";

# Skip first line of DATA
<DATA>;
$data = GD::Graph::Data->new();
$rc = $data->read(file => \*DATA, delimiter => qr/,/);
# TODO This test cannot fail, because I don't check whether DATA is an
# open file handle in read().
ok(ref $rc, "GD::Graph::Data", "Couldn't read from DATA file handle");

if (!defined $rc)
{
    skip("DATA not read", 0) for 1..2;
}
else
{
    ok($data->num_sets(), 3);
    ok(scalar $data->num_points(), 3);
}

__DATA__
We will skip this line
# And from here on, things should be normal for input files
A,1,2,3
B,1,2,3
C,1,2,3
