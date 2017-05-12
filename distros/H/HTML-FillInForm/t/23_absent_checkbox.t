# -*- Mode: Perl; -*-

use strict;

$^W = 1;

print "1..2\n";

use HTML::FillInForm;

print "ok 1\n";

my $hidden_form_in = qq{<input type="checkbox" name="foo1" value="bar1">
<input type="checkbox" name="foo1" value="bar2">
<input type="checkbox" name="foo1" value="bar3">
<input type="checkbox" name="foo2" value="bar1">
<input type="checkbox" name="foo2" value="bar2">
<input type="checkbox" name="foo2" value="bar3">
<input type="checkbox" name="foo3" value="bar1">
<input type="checkbox" name="foo3" checked value="bar2">
<input type="checkbox" name="foo3" value="bar3">
<input type="checkbox" name="foo4" value="bar1">
<input type="checkbox" name="foo4" checked value="bar2">
<input type="checkbox" name="foo4" value="bar3">
<input type="checkbox" name="foo5">
<input type="checkbox" name="foo6">
<input type="checkbox" name="foo7" checked>
<input type="checkbox" name="foo8" checked>};

my %fdat = (foo1 => 'bar1',
           foo2 => ['bar1', 'bar2',],
	   foo3 => '',
	   foo5 => 'on',
	   foo6 => '',
	   foo7 => 'on',
	   foo8 => '');

my $fif = new HTML::FillInForm;
my $output = $fif->fill(scalarref => \$hidden_form_in,
                       fdat => \%fdat,
                        clear_absent_checkboxes => 1);

my $is_checked = join(" ",map { m/checked/ ? "yes" : "no" } split ("\n",$output));

if ($is_checked eq "yes no no yes yes no no no no no no no yes no yes no"){
       print "ok 2\n";
} else {
       print "Got unexpected is_checked for checkboxes:\n$is_checked\n";
       print "not ok 2\n";
}
