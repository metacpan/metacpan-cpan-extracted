#!/usr/bin/perl

use strict;
use Test::More;

# Print the plan before module loads.
BEGIN { plan tests => 5, todo => [] }

use_ok('Log::WithCallbacks');

{   my $log;
    eval {
        isa_ok( $log = Log::WithCallbacks->new('temp'), 'Log::WithCallbacks' );
    };
    ok( length $@ == 0, 'No warnings messages from constructor');
    is( $log->status, 'closed', 'New object has closed filehandle');

}

{   my $log;
    eval {
        $log = Log::WithCallbacks->new();
    };
    like( $@, qr/^Must supply a filename/, 'Constructor fails without filename argument');

}


