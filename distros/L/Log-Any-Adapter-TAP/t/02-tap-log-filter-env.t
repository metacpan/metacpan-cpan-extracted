#! /usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Log::Any;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestLogging;

$SIG{__DIE__}= $SIG{__WARN__}= sub { diag @_; };

$ENV{TAP_LOG_FILTER}= 'warn,Foo=trace,Bar=debug';
use_ok( 'Log::Any::Adapter', 'TAP' ) || die;

my $buf;

test_log_method( Log::Any->get_logger(category => $_->[0]), @{$_}[1..4] ) for (
	[ 'main', 'error', 'test-main-err',  '', qr/s*# error: test-main-err\n/ ],
	[ 'main', 'warn',  'test-main-warn', '', '' ],
	[ 'Foo',  'debug', 'test-foo-debug', qr/s*# debug: test-foo-debug\n/, '' ],
	[ 'Foo',  'trace', 'test-foo-trace', '', '' ],
	[ 'Bar',  'info',  'test-bar-info',  qr/s*# test-bar-info\n/, '' ],
	[ 'Bar',  'debug', 'test-bar-debug', '', '' ],
);

done_testing;