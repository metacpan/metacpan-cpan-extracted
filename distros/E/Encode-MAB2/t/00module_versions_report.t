# -*- mode: cperl -*-

use strict;
BEGIN {
    my $exit_message = "";
    unless (eval { require Module::Versions::Report; 1 }) {
        $exit_message = "Module::Versions::Report not found";
    }
    if ($exit_message) {
        $|=1;
        print "1..0 # SKIP $exit_message\n";
        eval "require POSIX; 1" and POSIX::_exit(0);
    }
}

use Test::More tests => 1;
use Encode::MAB2;
use Tie::MAB2::Dualdb;
diag(Module::Versions::Report->report);
pass;


# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# End:
