#!/usr/bin/perl

use strict;
use warnings;

#######################
# TESTING starts here #
#######################
use Test::More tests => 8;

###########################
# General module tests... #
###########################

my $module = 'EBook::MOBI';
use_ok( $module );

my $obj = $module->new();

isa_ok($obj, $module);

can_ok($obj, 'new');
can_ok($obj, 'add_content');
can_ok($obj, 'make');
can_ok($obj, 'print_mhtml');

my $in  = '';
my $out = '';
my $expected = '';

$in = <<EXAMPLE;
!h! head
! ! normal text
!b! bold text
! ! now that is simple line based markup!
EXAMPLE

$expected = <<EXAMPLE;
<html>
<head>
</head>
<body>
<h1>head</h1>
normal text<br />
<b>bold text</b><br />
now that is simple line based markup!<br />
</body>
</html>
EXAMPLE

$obj->add_content(data => $in, driver => 'EBook::MOBI::Driver::Example');
$obj->make();
$out = $obj->print_mhtml(1);

is($out, $expected, 'Tested EBook::MOBI::Driver::Example');
$obj->reset();

$in = <<POD;
=head1 head

normal text

B<bold text>

this is POD
POD

$expected = <<POD;
<html>
<head>
</head>
<body>
<h1>head</h1>
<p>normal text</p>
<p><b>bold text</b></p>
<p>this is POD</p>
</body>
</html>
POD

$obj->add_content(data => $in, driver => 'EBook::MOBI::Driver::POD');
$obj->make();
$out = $obj->print_mhtml(1);

is($out, $expected, 'Tested EBook::MOBI::Driver::POD');
$obj->reset();

