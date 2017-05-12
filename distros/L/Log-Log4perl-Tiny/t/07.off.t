# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 7;    # last test to print
use Log::Log4perl::Tiny qw( :levels );

use lib 't';
use TestLLT qw( set_logger log_is );

my $logger = Log::Log4perl::Tiny::get_logger();
ok($logger, 'got a logger instance');
$logger->level($OFF);
$logger->format('%m');
set_logger($logger);

for my $method (qw( trace debug info warn error fatal )) {
   log_is {
      $logger->$method('scalar', sub { 'subroutine' }, '---', sub { 13 * 17 });
   }
   '', "no output for $method";
}
