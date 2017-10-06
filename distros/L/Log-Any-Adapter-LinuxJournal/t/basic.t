#!/usr/bin/env perl

use Test2::V0;
use Log::Any::Adapter;
use Log::Any '$log';
use Sys::Hostname;

ok(Log::Any::Adapter->set('LinuxJournal', app_id => 'testapp5000'));

ok $log->info('starting up');

ok $log->debugf('connecting to db at "%s:5432"', hostname);

ok $log->info('logging user in',
    {user => 'bob', action => 'login', ip => '54.54.54.54'});

ok $log->error('database error',
    {user => 'alice', action => 'account_update', ip => '12.34.56.78'});

subtest 'in a sub' => sub {
    ok $log->info('logging user in from a subroutine',
       {user => 'jane', action => 'login', ip => '56.54.52.51'});

};

done_testing;
