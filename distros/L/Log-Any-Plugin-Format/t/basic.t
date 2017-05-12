use Test::More;

use strict;
use warnings;

use Log::Any;
use Log::Any::Adapter;
use Log::Any::Plugin;

Log::Any::Adapter->set( 'TAP' );
my $log = Log::Any->get_logger;

my $orig = msg();

Log::Any::Plugin->add( 'Format', formatter => sub { map { uc } @_ } );

can_ok $log, 'format';
isnt $orig, msg(), 'Formatted message';
like msg(), qr/^[A-Z]+$/, 'All caps';

$log->format(sub { @_ });

is   $orig, msg(), 'Cleared formatter';

done_testing();

sub msg { $log->info('test') }
