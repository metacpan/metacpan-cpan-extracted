use Test::More;

use strict;
use warnings;

use Path::Tiny qw( tempfile );

use Log::Any;
use Log::Any::Adapter;
use Log::Any::Plugin;

my ($history, $content);
{
  my $logfile = tempfile();
  Log::Any::Adapter->set( File => $logfile, log_level => 'info' );
  Log::Any::Plugin->add( 'History', size => 2 );

  my $log = Log::Any->get_logger;

  $log->error('First');
  $log->fatal('Second');
  $log->debug('Third');
  $log->info('Fourth', 'Fifth');
  $history = $log->history;

  $content = $logfile->slurp;
}

like   $content, qr/\[.*\] First\n/,        'right error message';
like   $content, qr/\[.*\] Fourth Fifth\n/, 'right info message';
unlike $content, qr/debug/,                 'no debug message';

like $history->[0][0], qr/^\d+$/,      'right epoch time';
is   $history->[0][1], 'critical',     'right level';
is   $history->[0][2], 'Second',       'right message';
is   $history->[1][1], 'info',         'right level';
is   $history->[1][2], 'Fourth Fifth', 'right message';
ok  !$history->[2],                    'no more messages';

done_testing();
