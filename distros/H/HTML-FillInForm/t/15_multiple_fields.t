# -*- Mode: Perl; -*-

use strict;

$^W = 1;

print "1..2\n";

use HTML::FillInForm;
print "ok 1\n";

my $hidden_form_in = qq{<input type="hidden" name="foo">
<input type="hidden" name="foo" value="ack">};

my %fdat = (foo => 'bar1a');

my $fif = new HTML::FillInForm;
my $output = $fif->fill(scalarref => \$hidden_form_in,
			fdat => \%fdat);
if ($output =~ m/^<input( (type="hidden"|name="foo"|value="bar1a")){3}>\s*<input( (type="hidden"|name="foo"|value="bar1a")){3}>$/){
	print "ok 2\n";
} else {
	print "Got unexpected out for hidden form:\n$output\n";
	print "not ok 2\n";
}
