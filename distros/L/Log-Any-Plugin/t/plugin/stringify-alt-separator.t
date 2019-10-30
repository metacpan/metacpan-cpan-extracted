#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

require Test::NoWarnings if $ENV{RELEASE_TESTING};

use Log::Any::Plugin;

use Log::Any::Test;
use Log::Any qw($log);

####
# Main stringifier tests are in stringify.t -- these tests check behaviour when
# specifying an alternative separator to the default stringifier.
####


note 'Applying Stringify plugin with sep "##".'; {
    lives_ok { Log::Any::Plugin->add('Stringify', separator => '##') }
        '... plugin applied ok';
}

note 'Check functionality of default stringifier.'; {
    $log->clear;
    $log->debug('one', 'two', 'three');
    $log->contains_ok('one##two##three', '... multiple args separated by ##');

    $log->trace('four', [ 5, 6, 7 ]);
    $log->contains_ok('four##\[5,6,7\]', '... listrefs get expanded, custom separator applied');

    $log->debug('one', 'two', [2, 4], 'three');
    $log->contains_ok('one##two##\[2,4\]##three', '... multiple args separated by ##');

    $log->error('eight', { a => 'one', b => 'two' });
    $log->contains_ok(qr(eight##\{a=\'one\',b=\'two\'\}),
        '... hashrefs get expanded, custom separator applied');
}


Test::NoWarnings::had_no_warnings() if $ENV{RELEASE_TESTING};
done_testing();
