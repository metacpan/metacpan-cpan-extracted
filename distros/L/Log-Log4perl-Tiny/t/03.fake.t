# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 6;    # last test to print
use Log::Log4perl::Tiny qw( :fake get_logger );

can_ok('Log::Log4perl', $_) for qw( import easy_init );

my $real_logger = Log::Log4perl::Tiny::get_logger();
ok($real_logger, 'got a logger instance');

my $logger = get_logger();
is($logger, $real_logger, 'get_logger() works as expected');

$logger->level($Log::Log4perl::Tiny::DEBUG);

use Log::Log4perl qw( :easy );    # should be a no-op
Log::Log4perl->easy_init($Log::Log4perl::Tiny::ERROR);

$logger = get_logger();
is($logger, $real_logger, 'get_logger() still works as expected');

is($logger->level(), $Log::Log4perl::Tiny::ERROR, 'easy_init');
