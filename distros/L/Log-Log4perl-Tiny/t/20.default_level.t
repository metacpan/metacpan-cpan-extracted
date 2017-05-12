# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 6;    # last test to print
use Log::Log4perl::Tiny qw( :levels );

my $logger = Log::Log4perl::Tiny::get_logger();
ok($logger, 'got a logger instance');
is($logger->level(), $INFO, 'logger level set to INFO as default');

$logger->level($WARN);
is($logger->level(), $WARN, 'logger level set to WARN as modified');

use_ok 'Log::Log4perl::Tiny';
is($logger->level(), $WARN, 'logger level still set to WARN after new "use"');

my $new_logger = Log::Log4perl::Tiny->new();
is($new_logger->level(), $INFO, 'new logger level set to INFO as default');
