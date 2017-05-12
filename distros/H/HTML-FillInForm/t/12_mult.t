# -*- Mode: Perl; -*-

use strict;

$^W = 1;

print "1..3\n";

use HTML::FillInForm;

print "ok 1\n";

my $hidden_form_in = qq{<INPUT TYPE="TEXT" NAME="foo1" value="cat1">
<input type="text" name="foo1" value="cat2"/>};

my %fdat = (foo1 => ['bar1','bar2']);

my $fif = new HTML::FillInForm;
my $output = $fif->fill(scalarref => \$hidden_form_in,
			fdat => \%fdat);
if ($output =~ m/^<input( (type="TEXT"|name="foo1"|value="bar1")){3}>\s*<input( (type="text"|name="foo1"|value="bar2")){3} \/>$/){
	print "ok 2\n";
} else {
	print "Got unexpected out for $hidden_form_in:\n$output\n";
	print "not ok 2\n";
}

%fdat = (foo1 => ['bar1']);

$output = $fif->fill(scalarref => \$hidden_form_in,
			fdat => \%fdat);
if ($output =~ m/^<input( (type="TEXT"|name="foo1"|value="bar1")){3}>\s*<input( (type="text"|name="foo1"|value="")){3} \/>$/){
	print "ok 3\n";
} else {
	print "Got unexpected out for $hidden_form_in:\n$output\n";
	print "not ok 3\n";
}
