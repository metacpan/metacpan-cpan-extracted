#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Test::Exception;

require Test::NoWarnings if $ENV{RELEASE_TESTING};

use Log::Any::Plugin;

use Log::Any::Test;
use Log::Any qw($log);

note 'Stringify plugin not applied yet. Checking default behaviour.'; {
    $log->debug('debug msg');
    eq_or_diff($log->msgs, [
        { category => 'main', level => 'debug', message => 'debug msg' },
    ], '... single args work as expected');
    $log->error('error msg', 'are logged', 'now');
    eq_or_diff($log->msgs, [
        { category => 'main', level => 'debug', message => 'debug msg' },
        { category => 'main', level => 'error',
          message => 'error msg are logged now' },
    ], '... further args are concatenated with space');
}

note 'Applying Stringify plugin.'; {
    lives_ok { Log::Any::Plugin->add('Stringify') }
        '... plugin applied ok';
}

note 'Check functionality of default stringifier.'; {
    $log->clear;
    $log->debug('one', 'two', 'three');
    $log->contains_ok('onetwothree', '... multiple args concatenated');

    $log->trace('four', [ 5, 6, 7 ]);
    $log->contains_ok('four\[5,6,7\]', '... listrefs get expanded');

    $log->error('eight', { a => 'one', b => 'two' });
    $log->contains_ok(qr(eight\{a=\'one\',b=\'two\'\}),
        '... hashrefs get expanded');
}

note 'Applying stacked Stringify plugin.'; {
    # Normally you wouldn't stack the same plugin, but for these purposes
    lives_ok { Log::Any::Plugin->add('Stringify',
            stringifier => sub { reverse @_ }) }
        '... plugin applied ok';
}

note 'Check functionality of non-default stringifier.'; {
    $log->clear;
    $log->debug('one', 'two', 'three');
    $log->contains_ok('threetwoone', '... multiple args concatenated');
}

Test::NoWarnings::had_no_warnings() if $ENV{RELEASE_TESTING};
done_testing();
