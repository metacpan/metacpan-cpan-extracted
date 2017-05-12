use strict;
use Test::More tests => 3;

use IO::Scalar;

use Log::Dispatch::Config;
Log::Dispatch::Config->configure('t/date.cfg');

my $disp = Log::Dispatch::Config->instance;
isa_ok $disp->{outputs}->{screen}, 'Log::Dispatch::Screen';

{
    my($mday, $mon, $year) = (localtime(time))[3..5];
    my $today = sprintf '%04s%02d%02d', $year + 1900, $mon + 1, $mday;

    tie *STDERR, 'IO::Scalar', \my $err;
    $disp->debug('debug');

    like $err, qr/$today/, $err;
    like $err, qr/debug/, $err;
}



