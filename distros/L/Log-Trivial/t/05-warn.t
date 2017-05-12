#    $Id: 05-warn.t,v 1.2 2007-08-19 19:15:56 adam Exp $

use Test::More;
use strict;
use Log::Trivial;

BEGIN {
    eval 'use IO::Capture::Stderr';

    if ($@) {
        plan( skip_all => 'IO::Capture::Stderr not installled.' );
    }
    elsif ($] < 5.008) {
        plan( skip_all => 'IO::Capture::Stderr does work reliably on your Perl version.' );
    }
    else {
        plan( tests => 3 );
    }
}

my $logger = Log::Trivial->new();
$logger->{_debug} = 1;

my $capture = IO::Capture::Stderr->new( );
$capture->start();
ok(! $logger->set_log_file(),                  'set_log_file fails?' );
$capture->stop();

my $line = $capture->read;
like( $line, qr/File error: No file name supplied/,
                                        'Right File error in STDERR?' );
is( $logger->get_error(), 'File error: No file name supplied',
                            'Right File error from get_error method?' );
