#    $Id: 06-warn.t,v 1.2 2007-08-19 19:15:56 adam Exp $

use Test::More;
use strict;
use Log::Trivial;

BEGIN {
    eval ' use Test::Warn; ';

    if ($@) {
        plan( skip_all => 'Test::Warn not installled.' );
    }
    else {
        plan( tests => 3 );
    }
}

my $logger = Log::Trivial->new();
$logger->{_debug} = 1;

warning_is { ok(! $logger->set_log_file(),        'Log file failed?') }
    'File error: No file name supplied',    'Correct error to STDERR?';
is($logger->get_error(), 'File error: No file name supplied',
                              'Correct error from get_error method?' );
