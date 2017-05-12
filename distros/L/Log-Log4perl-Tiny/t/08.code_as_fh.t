# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 4;    # last test to print
use Log::Log4perl::Tiny qw( :levels );

use lib 't';

my $logger = Log::Log4perl::Tiny::get_logger();
ok($logger, 'got a logger instance');
$logger->level($WARN);
$logger->format('%m');

my @messages;
$logger->fh(sub { push @messages, $_[0] });

$logger->warn('something here');
is(scalar(@messages), 1, 'a message was enqueued for warn');

$logger->error('error');
is(scalar(@messages), 2, 'another message was enqueued for error');

$logger->info('nothing');
is(scalar(@messages), 2, 'no message was enqueued for info');
