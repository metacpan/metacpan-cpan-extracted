#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

require Test::NoWarnings if $ENV{RELEASE_TESTING};

use Log::Any::Plugin;

use Log::Any::Test;
use Log::Any qw($log);

note 'LogLevel has not been applied yet. Check default behaviour.'; {
    $log->debug('debug');
    $log->contains_ok('debug', '... debug gets logged');
    $log->error('error');
    $log->contains_ok('error', '... error gets logged');

    ok( ! $log->can('level'), '... no level method exists' );
}

note 'Applying LogLevel plugin.'; {
    lives_ok { Log::Any::Plugin->add('Levels') }
        '... plugin applied ok';
}

note 'Check that enabled message types get logged correctly'; {
    ok( $log->is_error, '... $log->error is enabled' );
    $log->clear;
    $log->error('error');
    $log->contains_ok('error', '... error gets logged');
}

note 'Check that disabled message types get ignored correctly'; {
    ok( ! $log->is_debug, '... $log->debug should to be disabled' );
    $log->clear;
    $log->debug('debug');
    $log->empty_ok('... log should still be empty (debug not logged)');
}

note 'Check synonyms'; {
    ok( ! $log->is_info, '... $log->info should be disabled' );
    ok( ! $log->is_inform, '... $log->inform should be disabled' );
    $log->clear;
    $log->info('info');
    $log->empty_ok('... log should still be empty (info not logged)');
    $log->inform('inform');
    $log->empty_ok('... log should still be empty (inform not logged)');
}

note 'Check changing the log level'; {
    ok( $log->can('level'), '... level method exists' );
    throws_ok { $log->level('mumble') } qr/Unknown log level/,
        '... unknown log levels cannot be set';
    lives_ok { $log->level('debug') }
        '... known log levels should able to be set';
    is( $log->level, 'debug',  '... log level should now be debug' );
    ok( $log->is_debug, '... $log->debug should now be enabled' );
    $log->clear;
    $log->debug('debug');
    $log->contains_ok('debug', '... debug gets logged');
}

note 'Check default levels;'; {
    lives_ok { $log->level('default') }
        '... default log levels should able to be set';
    $log->clear;
    is( $log->level, 'default',  '... log level should now be default' );
    ok( ! $log->is_debug, '... $log->debug should be disabled again' );
    $log->debug('debug');
    $log->empty_ok('... log should be empty');
}

note 'Applying LogLevel plugin again.'; {
    # This is a bit unrealistic, but applying the same plugin again
    lives_ok { Log::Any::Plugin->add('Levels',
        level => 'trace', accessor => 'level2') }
        '... plugin applied ok';
}

note 'Check clashing method names'; {
    throws_ok {
        Log::Any::Plugin->add('Levels', accessor => 'contains_ok')
    } qr/Test::contains_ok already exists/,
        '... method name clashes get detected';
}

Test::NoWarnings::had_no_warnings() if $ENV{RELEASE_TESTING};
done_testing();
