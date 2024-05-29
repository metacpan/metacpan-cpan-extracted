use strict;
use warnings;
use Test::More;
use lib 't/lib';

use TestExporter qw(:log),
  -logger         => 'logger value',
  -default_logger => 'default logger value',
  -package_logger => 'package logger value';

my @test_args = qw( some argument values );
log_info { "Ignored value" } @test_args;

my $results     = TestExporter->router->captured;
my %export_info = (
  exporter  => 'TestExporter',
  target    => 'main',
  arguments => {
    logger         => 'logger value',
    default_logger => 'default logger value',
    package_logger => 'package logger value'
  },
);
my %message_info = (
  exporter       => 'TestExporter',
  caller_package => 'main',
  caller_level   => 1,
  message_level  => 'info',
  message_args   => \@test_args,
);

is_deeply($results->{before_import},
  \%export_info, 'before_import() values are correct');
is_deeply($results->{after_import},
  \%export_info, 'after_import() values are correct');

#can't really compare the sub ref value so make sure it exists and is the right type
#and remove it for the later result check
my $message_block = delete $results->{message}->{message_sub};
is(ref $message_block,
  'CODE', 'handle_log_request() got a sub ref for the message generator');
is_deeply($results->{message}, \%message_info,
  'handle_log_request() other values are correct');

done_testing;
