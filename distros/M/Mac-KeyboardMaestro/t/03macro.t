#!/usr/bin/env perl

use strict;
use warnings;

# there's no auotmated way to install macros as far as I know
# so for the moment we can only run this test on my own machine
use Test::More;
BEGIN {
	unless ($ENV{THIS_IS_MARKF_YOU_BETCHA}) {
		plan( skip_all => "Requires macro only on author's Mac" );
		exit 0;
	}
	plan( tests => 1 );
};

use Mac::KeyboardMaestro qw(km_set km_get km_delete km_macro);

my $varname = "mackeyboardmaestrotestsuite";
km_set $varname => "6*7";

# this triggers a macro on my system that
#  1) takes the mackeyboardmaestrotestsuite var and puts it in the clipboard
#  2) filters the clipboard with the "Calculate" filter
#  3) puts the clipboard back in the mackeyboardmaestrotestsuite var
km_macro "Mac::KeyboardMaestro test";

# the var should now be 42!
is km_get $varname, 42, "The answer to life the universe and everything!";

# and clean up after ourselves
km_delete $varname;