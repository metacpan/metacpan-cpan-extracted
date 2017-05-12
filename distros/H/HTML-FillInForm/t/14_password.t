# -*- Mode: Perl; -*-

#!/usr/bin/perl -w

use CGI qw(:no_debug);
use HTML::FillInForm;
use Test;

BEGIN { plan tests => 2 }

local $/;
my $html = qq{<input type="password" name="foo">};
my $q = new CGI;
$q->param( foo => 'bar' );

{
    my $fif = new HTML::FillInForm;
    my $output = $fif->fill(
	scalarref => \$html,
	fobject   => $q,
	fill_password => 0,
    );

    ok($output !~ /value="bar"/);
}


{
    my $fif = new HTML::FillInForm;
    my $output = $fif->fill(
	scalarref => \$html,
	fobject   => $q,
#	fill_password => 1,
    );

    ok($output =~ /value="bar"/);
}


