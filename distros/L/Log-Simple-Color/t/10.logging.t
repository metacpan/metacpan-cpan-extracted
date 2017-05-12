use strict;
use warnings;

use Test::More tests => 6;
use Log::Simple::Color;

diag( "Testing Log::Simple::Color API" );

my $log = Log::Simple::Color->new;
isa_ok( $log, 'Log::Simple::Color', 'instance check' );
is( $log->VERSION, '0.0.3', 'version check' );

is( $log->level, 'info', 'log level check' );
is( $log->debug('This is a debug message'), undef, 'debug is lower level than info' );

is( $log->level('unknown level'), 'info', 'unknown log level must be info level' );
is( $log->level('debug'), 'debug', 'set log level to debug' );
