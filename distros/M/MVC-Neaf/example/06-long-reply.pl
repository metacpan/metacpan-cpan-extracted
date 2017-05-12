#!/usr/bin/env perl

use strict;
use warnings;

# This script demonstrates...
my $descr  = "Unspecified length reply";

# Always use latest and greatest Neaf, no matter what's in the @INC
use FindBin qw($Bin);
use File::Basename qw(basename dirname);
use lib dirname($Bin)."/lib";
use MVC::Neaf;

# Add some flexibility to run alongside other examples
my $script = basename(__FILE__);

# And some HTML boilerplate.
my $tt_head = <<"TT";
<html><head><title>$descr - $script</title></head>
<body><h1>$script</h1><h2>$descr</h2>
TT

# The boilerplate ends here

my $tpl = <<"TT";
$tt_head
<h3>Let's make a sequence of numbers</h3>
<form method="GET">
    <input name="start" value="[% start %]">
    <input name="step"  value="[% step %]">
    <input name="end"   value="[% end %]">
    <input type="submit" value="Generate">
</form>
<hr>
TT

MVC::Neaf->route( cgi => $script => sub {
    my $req = shift;

    # TODO Form validation needs to be implemented for such cases
    my $start = $req->param( start => '\d+(\.\d+)?', 1);
    my $end   = $req->param( end   => '\d+(\.\d+)?', 0);
    my $step  = $req->param( step  => '\d+(\.\d+)?', 1);

    my $continue = ($start <= $end && $step > 0) ? sub {
        my $req = shift;

        while ($start <= $end) {
            $req->write("$start<br>\n");
            $start += $step;
        }

            $req->close;
    } : undef;

    return {
        start => $start,
        end   => $end,
        step  => $step,
        -template => \$tpl,
        -continue => $continue,
    };
}, description => $descr);

MVC::Neaf->run;
