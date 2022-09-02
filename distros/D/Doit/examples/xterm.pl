#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use FindBin;
use lib ("$FindBin::RealBin/../lib");

use Doit;
use Doit::Log;
use Doit::XTermRPC;

use Getopt::Long;
use IO::Select;

sub hello {
    warn "I am " . getpwuid($<);
}

sub something {
    warn "else...";
}

sub wait_for_end {
    my $timeout = 10;
    info "Please hit ENTER to exit, or wait ${timeout}s...";
    my $sel = IO::Select->new;
    $sel->add(\*STDIN);
    $sel->can_read($timeout);
}

return 1 if caller;

my $doit = Doit->init;

GetOptions("debug" => \my $debug)
    or die "usage?";

my $xterm = Doit::XTermRPC->do_connect(debug=>$debug, dry_run=>$doit->is_dry_run);
$xterm->system(qw(echo This runs in an XTerm window));
$xterm->call("hello");
$xterm->call("something");

my $second_xterm = Doit::XTermRPC->do_connect(debug=>$debug, dry_run=>$doit->is_dry_run);
$second_xterm->system('echo', 'Running two xterms in parallel is OK');

$second_xterm->call_with_runner('wait_for_end');

__END__
