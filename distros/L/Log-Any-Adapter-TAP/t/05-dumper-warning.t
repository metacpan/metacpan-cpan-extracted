#! /usr/bin/perl

use strict;
use warnings;
use Test::More;
use Log::Any '$log';
use Log::Any::Adapter;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestLogging;

$SIG{__DIE__}= $SIG{__WARN__}= sub { diag @_; };

my ($stdout, $stderr)= capture_output {
	Log::Any::Adapter->set('TAP', dumper => sub { "foo" } );
	# construct additional adapters
	Log::Any->get_logger('foo');
	Log::Any->get_logger('bar');
};

like( $stdout, qr/\n# notice: Custom 'dumper' will not work with Log::Any versions >= 0.9\n$/s, 'exactly one warning' );

done_testing;
