#! /usr/bin/perl

use strict;
use warnings;
use Test::More;
use Log::Any '$log';
$SIG{__DIE__}= $SIG{__WARN__}= sub { diag @_; };

use_ok( 'Log::Any::Adapter', 'Daemontools' ) || BAIL_OUT;

my $buf;

sub reset_stdout {
	close STDOUT;
	$buf= '';
	open STDOUT, '>', \$buf or die "Can't redirect stdout to a memory buffer: $!";
}

reset_stdout;
$log->warn("test1");
like( $buf, qr/warning: test1\n/, 'warn becomes warning' );

reset_stdout;
$log->err("test2");
like( $buf, qr/error: test2\n/, 'err becomes error' );

reset_stdout;
$log->info("test3");
like( $buf, qr/test3\n/, 'no prefix on "info"' );

reset_stdout;
$log->debug("test4");
is( length $buf, 0, 'debug suppressed by default' );

Log::Any::Adapter::Daemontools->global_config->log_level('debug');
$log->debug("test5");
like( $buf, qr/debug: test5\n/, 'debug un-suppressed' );

reset_stdout;
$log->warning("test6\ntest7");
like( $buf, qr/^warning: test6\nwarning: test7\n$/, 'prefix on each line' );

reset_stdout;
$log->warning("test8\n");
like( $buf, qr/^warning: test8\n$/, 'newline not duplicated' );

done_testing;
