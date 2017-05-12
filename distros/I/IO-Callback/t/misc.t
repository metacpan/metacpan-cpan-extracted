# IO::Callback 1.08 t/misc.t
# Check that IO::Callback is consistent with real files in a few misc places.

use strict;
use warnings;

use Test::More tests => 9;
use Test::NoWarnings;

use IO::Callback;
use IO::Handle;
use File::Temp qw/tempdir/;

our $tmpfile = tempdir(CLEANUP => 1) . "/testfile";

foreach my $rw ('>', '<') {
    foreach my $close_it (0, 1) {
        my $ioc_fh = IO::Callback->new($rw, sub {});
        open my $real_fh, $rw, $tmpfile or die "open: $!";
        if ($close_it) {
            close $ioc_fh;
            close $real_fh;
        }
        foreach my $method (qw/opened error/) {
            is $ioc_fh->$method, $real_fh->$method, "$method consistent with perl ($close_it)";
        }
    }
}

