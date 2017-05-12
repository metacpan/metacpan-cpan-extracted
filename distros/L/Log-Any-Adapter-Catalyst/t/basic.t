#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use File::Basename 'dirname';
use File::Spec;
use lib join '/', File::Spec->splitdir( dirname(__FILE__) ), '..', 'lib';

our @MESSAGES;

# Override the method that Catalyst::Log uses to output the log message.
# Capture the output so we can analyze it.
{

    package Catalyst::Log::TestClass;
    use base qw/Catalyst::Log/;

    sub _send_to_log {
        my $self = shift;
        push @MESSAGES, @_;
    }
    1;
}

{

    package MyTest;

    use Test::More;
    use Log::Any qw($log);

    sub test_log_methods {
        is( _test_log('trace'),     "[debug] TEST\n", 'trace' );
        is( _test_log('debug'),     "[debug] TEST\n", 'debug' );
        is( _test_log('info'),      "[info] TEST\n",  'info' );
        is( _test_log('inform'),    "[info] TEST\n",  'info' );
        is( _test_log('notice'),    "[info] TEST\n",  'notice' );
        is( _test_log('warn'),      "[warn] TEST\n",  'warning' );
        is( _test_log('warning'),   "[warn] TEST\n",  'warning' );
        is( _test_log('error'),     "[error] TEST\n", 'error' );
        is( _test_log('err'),       "[error] TEST\n", 'error' );
        is( _test_log('critical'),  "[fatal] TEST\n", 'critical' );
        is( _test_log('crit'),      "[fatal] TEST\n", 'critical' );
        is( _test_log('fatal'),     "[fatal] TEST\n", 'critical' );
        is( _test_log('alert'),     "[fatal] TEST\n", 'alert' );
        is( _test_log('emergency'), "[fatal] TEST\n", 'emergency' );
    }

    sub test_logf_methods {
        is( _test_logf('trace'),     "[debug] TEST\n", 'tracef' );
        is( _test_logf('debug'),     "[debug] TEST\n", 'debugf' );
        is( _test_logf('info'),      "[info] TEST\n",  'infof' );
        is( _test_logf('inform'),    "[info] TEST\n",  'infof' );
        is( _test_logf('notice'),    "[info] TEST\n",  'noticef' );
        is( _test_logf('warn'),      "[warn] TEST\n",  'warningf' );
        is( _test_logf('warning'),   "[warn] TEST\n",  'warningf' );
        is( _test_logf('error'),     "[error] TEST\n", 'errorf' );
        is( _test_logf('err'),       "[error] TEST\n", 'errorf' );
        is( _test_logf('critical'),  "[fatal] TEST\n", 'criticalf' );
        is( _test_logf('crit'),      "[fatal] TEST\n", 'criticalf' );
        is( _test_logf('fatal'),     "[fatal] TEST\n", 'criticalf' );
        is( _test_logf('alert'),     "[fatal] TEST\n", 'alertf' );
        is( _test_logf('emergency'), "[fatal] TEST\n", 'emergencyf' );
    }

    sub test_detection_methods {
        ok( $log->is_trace,     'is_trace' );
        ok( $log->is_debug,     'is_debug' );
        ok( $log->is_info,      'is_info' );
        ok( $log->is_notice,    'is_notice' );
        ok( $log->is_warning,   'is_warning' );
        ok( $log->is_error,     'is_error' );
        ok( $log->is_critical,  'is_critical' );
        ok( $log->is_alert,     'is_alert' );
        ok( $log->is_emergency, 'is_emergency' );
    }

    sub test_log_methods_at_warn {
        is( _test_log('trace'),     undef,            'trace at warn' );
        is( _test_log('debug'),     undef,            'debug at warn' );
        is( _test_log('info'),      undef,            'info at warn' );
        is( _test_log('inform'),    undef,            'info at warn' );
        is( _test_log('notice'),    undef,            'notice at warn' );
        is( _test_log('warn'),      "[warn] TEST\n",  'warning at warn' );
        is( _test_log('warning'),   "[warn] TEST\n",  'warning at warn' );
        is( _test_log('error'),     "[error] TEST\n", 'error at warn' );
        is( _test_log('err'),       "[error] TEST\n", 'error at warn' );
        is( _test_log('critical'),  "[fatal] TEST\n", 'critical at warn' );
        is( _test_log('crit'),      "[fatal] TEST\n", 'critical at warn' );
        is( _test_log('fatal'),     "[fatal] TEST\n", 'critical at warn' );
        is( _test_log('alert'),     "[fatal] TEST\n", 'alert at warn' );
        is( _test_log('emergency'), "[fatal] TEST\n", 'emergency at warn' );
    }

    sub test_logf_methods_at_warn {
        is( _test_logf('trace'),     undef,            'tracef at warn' );
        is( _test_logf('debug'),     undef,            'debugf at warn' );
        is( _test_logf('info'),      undef,            'infof at warn' );
        is( _test_logf('inform'),    undef,            'infof at warn' );
        is( _test_logf('notice'),    undef,            'noticef at warn' );
        is( _test_logf('warn'),      "[warn] TEST\n",  'warningf at warn' );
        is( _test_logf('warning'),   "[warn] TEST\n",  'warningf at warn' );
        is( _test_logf('error'),     "[error] TEST\n", 'errorf at warn' );
        is( _test_logf('err'),       "[error] TEST\n", 'errorf at warn' );
        is( _test_logf('critical'),  "[fatal] TEST\n", 'criticalf at warn' );
        is( _test_logf('crit'),      "[fatal] TEST\n", 'criticalf at warn' );
        is( _test_logf('fatal'),     "[fatal] TEST\n", 'criticalf at warn' );
        is( _test_logf('alert'),     "[fatal] TEST\n", 'alertf at warn' );
        is( _test_logf('emergency'), "[fatal] TEST\n", 'emergencyf at warn' );
    }

    sub test_detection_methods_at_warn {
        ok( !$log->is_trace,    'is_trace at warn' );
        ok( !$log->is_debug,    'is_debug at warn' );
        ok( !$log->is_info,     'is_info at warn' );
        ok( !$log->is_notice,   'is_notice at warn' );
        ok( $log->is_warning,   'is_warning at warn' );
        ok( $log->is_error,     'is_error at warn' );
        ok( $log->is_critical,  'is_critical at warn' );
        ok( $log->is_alert,     'is_alert at warn' );
        ok( $log->is_emergency, 'is_emergency at warn' );
    }

    sub _test_log {
        my $method = shift;
        $log->$method('TEST');
        $main::cat_log->_flush;
        return shift @MESSAGES;
    }

    sub _test_logf {
        my $method = shift;
        $method .= 'f';
        $log->$method( "%s", 'TEST' );
        $main::cat_log->_flush;
        return shift @MESSAGES;
    }
    1;

}

{

    package main;

    use Log::Any::Adapter;
    our $cat_log = Catalyst::Log::TestClass->new or die;
    Log::Any->set_adapter( 'Catalyst', logger => $cat_log );

    $cat_log->levels(qw/debug info warn error fatal/);
    MyTest->test_detection_methods;
    MyTest->test_log_methods;
    MyTest->test_logf_methods;

    $cat_log->levels(qw/warn error fatal/);
    MyTest->test_detection_methods_at_warn;
    MyTest->test_log_methods_at_warn;
    MyTest->test_logf_methods_at_warn;

    done_testing;

}

