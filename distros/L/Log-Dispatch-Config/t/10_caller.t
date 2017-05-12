use strict;
use Test::More tests => 2;

use FileHandle;

sub slurp {
    my $fh = FileHandle->new(shift) or die $!;
    local $/;
    return $fh->getline;
}

use Log::Dispatch::Config;
Log::Dispatch::Config->configure('t/log.cfg');

sub logit {
    my $disp = Log::Dispatch::Config->instance;
    $disp->debug(@_);
}

logit "foobar";
like slurp("t/log.out"), qr/foobar at .*10_caller\.t line 17/;

local $Log::Dispatch::Config::CallerDepth = 1;
logit "bazbaz";
like slurp("t/log.out"), qr/bazbaz at .*10_caller\.t line 24/;

END { unlink 't/log.out' if -e 't/log.out' }
