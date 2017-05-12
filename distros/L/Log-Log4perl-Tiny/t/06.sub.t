# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 2;    # last test to print
use Log::Log4perl::Tiny qw( :levels );

use lib 't';
use TestLLT qw( set_logger log_is );

my $logger = Log::Log4perl::Tiny::get_logger();
ok($logger, 'got a logger instance');
$logger->level($INFO);
$logger->format('%m');
set_logger($logger);
log_is {
   $logger->info('scalar', sub { 'subroutine' }, '---', sub { 13 * 17 });
}
'scalarsubroutine---221', 'mixed subroutine and scalars';
