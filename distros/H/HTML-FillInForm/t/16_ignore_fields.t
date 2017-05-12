# -*- Mode: Perl; -*-

use strict;

$^W = 1;

print "1..2\n";

use HTML::FillInForm;
use CGI;

print "ok 1\n";

my $hidden_form_in = qq{<select multiple name="foo1">
	<option value="0">bar1</option>
	<option value="bar2">bar2</option>
	<option value="bar3">bar3</option>
</select>
<select multiple name="foo2">
	<option value="bar1">bar1</option>
	<option value="bar2">bar2</option>
	<option value="bar3">bar3</option>
</select>
<select multiple name="foo3">
	<option value="bar1">bar1</option>
	<option selected value="bar2">bar2</option>
	<option value="bar3">bar3</option>
</select>
<select multiple name="foo4">
	<option value="bar1">bar1</option>
	<option selected value="bar2">bar2</option>
	<option value="bar3">bar3</option>
</select>};
my $q = new CGI( { foo1 => '0',
           foo2 => ['bar1', 'bar2',],
	   foo3 => '' }
	);

my $fif = new HTML::FillInForm;
my $output = $fif->fill(scalarref => \$hidden_form_in,
                       fobject => $q,
			ignore_fields => ['asdf','foo1','asdf']);

my $is_selected = join(" ",map { m/selected/ ? "yes" : "no" } grep /option/, split ("\n",$output));

if ($is_selected eq "no no no yes yes no no no no no yes no"){
       print "ok 2\n";
} else {
       print "Got unexpected is_selected for select menus:\n$is_selected\n$output\n";
       print "not ok 2\n";
}

