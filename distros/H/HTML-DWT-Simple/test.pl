#!/usr/bin/perl -w 
#############################################################
#  HTML::DWT::Simple
#  Whyte.Wolf DreamWeaver HTML Template Module (Simple)
#  Copyright (c) 2002 by S.D. Campbell <whytwolf@spots.ab.ca>
#
#  Last modified 04/05/2002
#
#  Test scripts to test that the HTML::DWT::Simple module has 
#  been installed correctly.  
#
#  Support routines by Grant McLean <grantm@cpan.org>
#############################################################

use Carp;
use strict;

print "1..19\n";

my $t = 1;

##############################################################################
#                   S U P P O R T   R O U T I N E S
##############################################################################

##############################################################################
# Print out 'n ok' or 'n not ok' as expected by test harness.
# First arg is test number (n).  If only one following arg, it is interpreted
# as true/false value.  If two args, equality = true.
#

sub ok {
  my($n, $x, $y) = @_;
  die "Sequence error got $n expected $t" if($n != $t);
  $x = 0 if(@_ > 2  and  $x ne $y);
  print(($x ? '' : 'not '), 'ok ', $t++, "\n");
}


##############################################################################
# Take two scalar values (may be references) and compare them (recursively
# if necessary) returning 1 if same, 0 if different.
#

sub DataCompare {
  my($x, $y) = @_;

  my($i);

  if(!defined($x)) {
    return(1) if(!defined($y));
    print STDERR "$t:DataCompare: undef != $y\n";
    return(0);
  }


  if(!ref($x)) {
    return(1) if($x eq $y);
    print STDERR "$t:DataCompare: $x != $y\n";
    return(0);
  }

  if(ref($x) eq 'ARRAY') {
    unless(ref($y) eq 'ARRAY') {
      print STDERR "$t:DataCompare: expected arrayref, got: $y\n";
      return(0);
    }
    if(scalar(@$x) != scalar(@$y)) {
      print STDERR "$t:DataCompare: expected ", scalar(@$x),
                   " element(s), got: ", scalar(@$y), "\n";
      return(0);
    }
    for($i = 0; $i < scalar(@$x); $i++) {
      DataCompare($x->[$i], $y->[$i]) || return(0);
    }
    return(1);
  }

  if(ref($x) eq 'HASH') {
    unless(ref($y) eq 'HASH') {
      print STDERR "$t:DataCompare: expected hashref, got: $y\n";
      return(0);
    }
    if(scalar(keys(%$x)) != scalar(keys(%$y))) {
      print STDERR "$t:DataCompare: expected ", scalar(keys(%$x)),
                   " key(s), (", join(', ', keys(%$x)),
		   ") got: ",  scalar(keys(%$y)), " (", join(', ', keys(%$y)),
		   ")\n";
      return(0);
    }
    foreach $i (keys(%$x)) {
      unless(exists($y->{$i})) {
	print STDERR "$t:DataCompare: missing hash key - {$i}\n";
	return(0);
      }
      DataCompare($x->{$i}, $y->{$i}) || return(0);
    }
    return(1);
  }

  print STDERR "Don't know how to compare: " . ref($x) . "\n";
  return(0);
}

##############################################################################
#                      T E S T   R O U T I N E S
##############################################################################

#  Check to see if we can use and/or require the module
eval "use HTML::DWT::Simple;";
ok(1, !$@);                       # Module compiled OK

use HTML::DWT::Simple;
#  Create a new HTML::DWT object and test to see if it's a 
#  properly blessed reference.  Die if the file isn't found.

my $tp = new HTML::DWT::Simple(filename => 'tmp/temp.dwt') or die $HTML::DWT::Simple::errmsg;
ok(2, DataCompare(ref($tp),'HTML::DWT::Simple'));

#  Grab a list of the parameters from the template and test to see if
#  they're what we were expecting

my @test = $tp->param();
my $num = 3;
foreach my $field(@test){
	ok($num, $field =~ /doctitle|leftcont|centercont|rightcont/);
	$num++;
}


#  Create a data hash and fill the template with it

my %data = (
	doctitle => 'fill title',
	leftcont => 'fill left',
	centercont => 'fill center',
	rightcont => 'fill right'
	);
	
$tp->param(%data);
#  Test each parameter to see if the field was filled properly by param()

ok(7, DataCompare($tp->param('doctitle'), '<title>fill title</title>'));
ok(8, DataCompare($tp->param('leftcont'), 'fill left'));
ok(9, DataCompare($tp->param('centercont'),'fill center'));
ok(10, DataCompare($tp->param('rightcont'),'fill right'));

#  Load the paramters from the template with new values and then test to 
#  see if those values have been stored properly

$tp->param(doctitle=>'test');
$tp->param(leftcont=>'Left Cont');
$tp->param(centercont=>'Center Cont');
$tp->param(rightcont=>'Right Cont');

ok(11, DataCompare($tp->param('doctitle'), '<title>test</title>'));
ok(12, DataCompare($tp->param('leftcont'), 'Left Cont'));
ok(13, DataCompare($tp->param('centercont'),'Center Cont'));
ok(14, DataCompare($tp->param('rightcont'),'Right Cont'));

use CGI;

my $q = new CGI({doctitle => 'CGI Test',
	      leftcont => 'CGI Test',
	      centercont => 'CGI Test',
	      rightcont => 'CGI Test'});

$tp = undef;
$tp = new HTML::DWT::Simple(filename => 'tmp/temp.dwt', associate => $q) or die $HTML::DWT::Simple::errmsg;

#  Were the values form the CGI object associated?

ok(15, DataCompare($tp->param('doctitle'), '<title>CGI Test</title>'));	
ok(16, DataCompare($tp->param('leftcont'), 'CGI Test'));
ok(17, DataCompare($tp->param('centercont'), 'CGI Test'));	
ok(18, DataCompare($tp->param('rightcont'), 'CGI Test'));	

my $outhtml = $tp->output();

ok(19, defined($outhtml));
