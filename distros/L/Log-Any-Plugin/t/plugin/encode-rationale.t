#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use Test::Exception;
use Test::Warn;

require Test::NoWarnings if $ENV{RELEASE_TESTING};

use Log::Any::Plugin;

use Log::Any qw( $log );
use Log::Any::Adapter;


#####
# Tests the initial rationale behind the Encode plugin:
# Wide char warnings when no encoding/default logging happens through an
# adapter like Stderr.
#####

Log::Any::Adapter->set('Stderr');

my $msg = "鸿涛 \x{1f4A9} -- adapter with encoding set should have no warnings or errors on wide char output";

note 'log->error expected to be available to test functionality'; {
    ok( $log->is_error, '... $log->error is enabled' );
}

note 'Encode has not been applied yet. Check warning occurs.'; {
    warning_like { $log->error($msg) }
        qr/Wide character in print at/,
        "log error gives wide char warning";
}

note "Applying Encode plugin with default encoding"; {
    # Default utf8 encoding is sufficient.
    lives_ok { Log::Any::Plugin->add('Encode') }
        'plugin applied ok';
}

note 'Check that logging no longer produces the warning'; {
    warnings_are { $log->error($msg) }
        [ ],
        "No warnings expected after encoding in effect";
}


Test::NoWarnings::had_no_warnings() if $ENV{RELEASE_TESTING};
done_testing();
