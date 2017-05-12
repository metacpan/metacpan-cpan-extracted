# -*- Mode: Perl; -*-

use strict;

$^W = 1;

print "1..2\n";

use HTML::FillInForm;

print "ok 1\n";

my $hidden_form_in = qq{<input type="hidden" name="foo1">
<input type="hidden" name="foo2" value="ack">};

my %fdat = (foo1a => 'bar1a',
	foo2 => ['bar2','bar3']);

my $fif = new HTML::FillInForm;
my $output = $fif->fill(scalarref => \$hidden_form_in,
			fdat => \%fdat);
if ($output =~ m/^<input( (type="hidden"|name="foo1"|value="")){3}>\s*<input( (type="hidden"|name="foo2"|value="bar2")){3}>$/){
	print "ok 2\n";
} else {
	print "Got unexpected out for hidden form:\n$output\n";
	print "not ok 2\n";
}
