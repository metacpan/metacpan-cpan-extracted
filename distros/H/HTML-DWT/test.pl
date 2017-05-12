#!/usr/bin/perl -w 
#############################################################
#  HTML::DWT
#  Whyte.Wolf DreamWeaver HTML Template Module
#  Copyright (c) 2002 by S.D. Campbell <whytwolf@spots.ab.ca>
#
#  Last modified 05/03/2002
#
#  Test scripts to test that the HTML::DWT module has been
#  installed correctly.  See Test::More for more information.
#
#############################################################

use Carp;
use CGI;
use Test::More tests => 27;

#  Check to see if we can use and/or require the module

BEGIN { 
	use_ok('HTML::DWT'); 																# Test 1
	use_ok('HTML::DWT', qw(:Template));													# Test 2
	}
	
require_ok('HTML::DWT');																# Test 3

#  Create a new HTML::DWT object and test to see if it's a 
#  properly blessed reference.  Die if the file isn't found.

my $t = new HTML::DWT(filename => 'tmp/temp.dwt') or die $HTML::DWT::errmsg;
isa_ok($t, 'HTML::DWT');																# Test 4

#  Grab a list of the parameters from the template and test to see if
#  they're what we were expecting

@test = $t->param();
foreach $field(@test){
	my $msg = "Searching field names: found $field";
	like($field, qr/doctitle|leftcont|centercont|rightcont/, $msg);						# Test 5 - 8																						
}


#  Create a data hash and fill the template with it

my %data = (
	doctitle => 'fill title',
	leftcont => 'fill left',
	centercont => 'fill center',
	rightcont => 'fill right'
	);
	
my $fillhtml = $t->fill(\%data);
is(defined($fillhtml), 1, 'fill() returned a value');									# Test 9

#  Test each parameter to see if the field was filled properly by fill()

is($t->param('doctitle'), '<title>fill title</title>', 'fill() doctype value correct'); # Test 10
is($t->param('leftcont'), 'fill left', 'fill() leftcont value correct');				# Test 11
is($t->param('centercont'),'fill center', 'fill() centercont value correct');			# Test 12
is($t->param('rightcont'),'fill right', 'fill() rightcont value correct');				# Test 13

#  Load the paramters from the template with new values and then test to 
#  see if those values have been stored properly

$t->param(doctitle=>'test');
$t->param(leftcont=>'Left Cont');
$t->param(centercont=>'Center Cont');
$t->param(rightcont=>'Right Cont');

is($t->param('doctitle'), '<title>test</title>', 'param() doctype value correct');		# Test 14
is($t->param('leftcont'), 'Left Cont', 'param() leftcont value correct');				# Test 15
is($t->param('centercont'),'Center Cont', 'param() centercont value correct');			# Test 16
is($t->param('rightcont'),'Right Cont', 'param() rightcont value correct');				# Test 17

#  Query each field from the template to ensure they are all of type VAR

is($t->query('doctitle'), 'VAR', 'doctype type: VAR');									# Test 18
is($t->query('leftcont'), 'VAR', 'leftcont type: VAR');									# Test 19
is($t->query('centercont'),'VAR', 'centercont type: VAR');								# Test 20
is($t->query('rightcont'),'VAR', 'rightcont type: VAR');								# Test 21

#  Load the template with data from the datahash through param() and
#  test to see if output() generates the same HTML output as fill()

$t->param(%data);

my $outhtml = $t->output();

is(defined($outhtml), 1, 'output() returned a value');									# Test 22
is($outhtml, $fillhtml, 'Similar HTML from fill() and output()');						# Test 23

#  Create and load a CGI object with predefined values.  Create a new HTML::DWT
#  object with a relative file name and path option, and associate the CGI object

$q = new CGI({doctitle => 'CGI Test',
	      leftcont => 'CGI Test',
	      centercont => 'CGI Test',
	      rightcont => 'CGI Test'});

$t = undef;
$t = new HTML::DWT(filename => 'temp.dwt', associate => $q, path => './') or die $HTML::DWT::errmsg;

#  Were the values form the CGI object associated?

is($t->param('doctitle'), '<title>CGI Test</title>', 'Associate CGI object');			# Test 24

# Create an xml document and load it into the template

$x = <<END;
<?xml version="1.0"?>
<templateItems template="tmp/temp.dwt">
<item name="centercont"><![CDATA[XML Testing]]></item>
<item name="doctitle"><![CDATA[<title>XML testing</title>]]></item>
<item name="leftcont"><![CDATA[XML Testing]]></item>
<item name="rightcont"><![CDATA[XML Testing]]></item>
</templateItems>
END

$t = undef;
$t = new HTML::DWT(filename => 'tmp/temp.dwt', xml => $x) or die $HTML::DWT::errmsg;

is($t->param('doctitle'), '<title>XML testing</title>', 'Associate XML object');		# Test 25

# Export an xml document and compare the export to the import

my $xml = $t->export(type => 'dw');
is(defined($xml), 1, 'export() returned a value');										# Test 26
is($xml, $x, 'export() regenerated XML');												# Test 27