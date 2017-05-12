# -*- Mode: Perl; -*-

use strict;

$^W = 1;

print "1..6\n";

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

my $output = HTML::FillInForm->fill(\$hidden_form_in,
                                    $q,
                                clear_absent_checkboxes => 1);

my $is_selected = join(" ",map { m/selected/ ? "yes" : "no" } grep /option/, split ("\n",$output));

if ($is_selected eq "yes no no yes yes no no no no no no no"){
       print "ok 2\n$output\n";
} else {
       print "Got unexpected is_seleced for select menus:\n$is_selected\n$output\n";
       print "not ok 2\n";
}

$hidden_form_in = qq{<select multiple name="foo1">
	<option>bar1</option>
	<option>bar2</option>
	<option>bar3</option>
</select>
<select multiple name="foo2">
	<option> bar1</option>
	<option> bar2</option>
	<option>bar3</option>
</select>
<select multiple name="foo3">
	<option>bar1</option>
	<option selected>bar2</option>
	<option>bar3</option>
</select>
<select multiple name="foo4">
	<option>bar1</option>
	<option selected>bar2</option>
	<option>bar3  </option>
</select>};

$q = new CGI( { foo1 => 'bar1',
           foo2 => ['bar1', 'bar2',],
	   foo3 => '' }
	);

my $fif = new HTML::FillInForm;
$output = $fif->fill(scalarref => \$hidden_form_in,
                       fobject => $q,
                       clear_absent_checkboxes => 1
                   );

$is_selected = join(" ",map { m/selected/ ? "yes" : "no" } grep /option/, split ("\n",$output));

if ($is_selected eq "yes no no yes yes no no no no no no no"){
       print "ok 3\n";
} else {
       print "Got unexpected is_selected for select menus:\n$is_selected\n$output\n";
       print "not ok 3\n";
}

# test empty option tag

$hidden_form_in = qq{<select name="x"><option></select>};
$fif = new HTML::FillInForm;
$output = $fif->fill(scalarref => \$hidden_form_in,
                       fobject => $q);
if ($output eq qq{<select name="x"><option></select>}){
       print "ok 4\n";
} else {
       print "Got unexpected output for empty option:\n$output\n";
       print "not ok 4\n";
}

$hidden_form_in = qq{<select name="foo1"><option><option value="bar1"></select>};
$fif = new HTML::FillInForm;
$output = $fif->fill(scalarref => \$hidden_form_in,
                       fobject => $q,
                   clear_absent_checkboxes => 1);
if ($output =~ m!^<select name="foo1"><option><option( selected="selected"| value="bar1"){2}></select>$!){
       print "ok 5\n";
} else {
       print "Got unexpected output for empty option:\n$output\n";
       print "not ok 5\n";
}

$hidden_form_in = qq{<select name="foo9"><option><option value="bar1" selected></select>};
$fif = new HTML::FillInForm;
$output = $fif->fill(scalarref => \$hidden_form_in,
                       fobject => $q,
                       clear_absent_checkboxes => 1);
if ($output eq '<select name="foo9"><option><option value="bar1"></select>'){
       print "ok 6\n";
} else {
       print "Got unexpected output for empty option:\n$output\n";
       print "not ok 6\n";
}

