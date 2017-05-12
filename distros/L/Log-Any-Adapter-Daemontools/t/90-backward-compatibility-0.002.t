#! /usr/bin/perl

use strict;
use warnings;
use Test::More;
use Log::Any '$log';

use_ok( 'Log::Any::Adapter', 'Daemontools' ) || BAIL_OUT;

my $buf;

sub reset_stdout {
	close STDOUT;
	$buf= '';
	open STDOUT, '>', \$buf or die "Can't redirect stdout to a memory buffer: $!";
}

Log::Any::Adapter->set('Daemontools', filter => undef);

reset_stdout;
$log->debug("test4");
like( $buf, qr/debug: test4\n/ );
ok( $log->is_debug, 'nothing disabled' );
ok( $log->is_trace, 'nothing disabled' );

Log::Any::Adapter->set('Daemontools', filter => -1);
ok( $log->is_info, '-1 enabled info' );
ok( !$log->is_debug, '-1 disables debug' );

Log::Any::Adapter->set('Daemontools', filter => 'notice');
ok( !$log->is_info, 'notice disables info' );
ok( !$log->is_notice, 'notice disabled notice' );
ok( $log->is_warn, 'notice enabled warning' );

is( Log::Any::Adapter::Daemontools::_default_dumper([1, 2, 3]), "[1,2,3]" );

done_testing;