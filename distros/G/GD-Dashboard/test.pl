# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use GD::Dashboard;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# 2: Test when FNAME not specified.
my $d1 = new GD::Dashboard(FNAME=>'examples\m1.jpg');
my $jpeg = $d1->jpeg;

if (!defined($jpeg))
{
   print "not ok 2\n";
}
else
{
   print "ok 2\n";
}

# 3: test jpg success
$jpeg = $d1->jpeg;
if (!defined($jpeg))
{
   print "not ok 3\n";
}
else
{
   print "ok 3\n";
}

# 4: test png success
$jpeg = $d1->png;
if (!defined($jpeg))
{
   print "not ok 4\n";
}
else
{
   print "ok 4\n";
}

# 5: test jpeg to file
$d1->write_jpeg('t5.jpg');
if (-e 't5.jpg')
{
   print "ok 5\n";
}
else
{
   print "not ok 5\n";
}

# 6: test png to file
$d1->write_png('t6.png');
if (-e 't6.png')
{
   print "ok 6\n";
}
else
{
   print "not ok 6\n";
}

# 7 - test from a PNG background
my $d2 = new GD::Dashboard(FNAME=>'t6.png');
$jpeg = $d2->jpeg;
if (!defined($jpeg))
{
   print "not ok 7\n";
}
else
{
   print "ok 7\n";
}
