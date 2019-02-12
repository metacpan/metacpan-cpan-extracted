#! /usr/bin/perl

BEGIN { @ARGV= qw( -vv -a foo --quiet -b bar -- a b c --verbose ) }
use Test::More;
use Log::Any '$log';
use Log::Any::Adapter 'Daemontools', -init => {
	level => 'error',
	argv => 'consume',
};

ok( $log->is_warning, 'warning enabled' );
ok( !$log->is_notice, 'notice squelched' );
is_deeply( \@ARGV, [qw( -a foo -b bar -- a b c --verbose )] );

done_testing;
