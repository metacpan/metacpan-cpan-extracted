# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 4;    # last test to print
use Log::Log4perl::Tiny qw( :levels );

my $logger = Log::Log4perl::Tiny::get_logger();
ok($logger, 'got a logger instance');
is($logger->level(), $INFO, 'logger level set to INFO as default');

use_ok('Log::Log4perl::Tiny', ':DEAD_if_first');
is($logger->level(), $INFO, 'logger level still set to INFO after new import');
