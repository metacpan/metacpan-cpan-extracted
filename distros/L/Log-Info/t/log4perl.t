#!/usr/bin/env perl

use 5.10.0;
use strict;
use warnings;

use File::Spec::Functions  qw( catdir catfile updir );
use FindBin                qw( $Bin );
use Log::Log4perl          qw( );
use File::Temp             qw( tempfile );
use POSIX                  qw( strftime );

use lib catdir $Bin, updir, 'lib';
use Log::Info  qw( :default_channels :log_levels Log Logf );

use Test::More  tests => 14;

# ----------------------------------------------------------------------------

my ($tempfh,     $tempfn) =     tempfile(UNLINK => 1);
my ($tempfh_app, $tempfn_app) = tempfile(UNLINK => 1);
if ( $ENV{TEST_DEBUG} ) {
  diag "tempfn    : $tempfn";
  diag "tempfn_app: $tempfn_app";
}

Log::Log4perl::init
  (+{
     'log4perl.rootLogger' => 'WARN, tempfile',

     'log4perl.appender.stderr'        => 'Log::Log4perl::Appender::Screen',
     'log4perl.appender.stderr.stderr' => 1,
     'log4perl.appender.stderr.layout' => 
       'Log::Log4perl::Layout::PatternLayout',
     'log4perl.appender.stderr.layout.ConversionPattern' =>
       '[%r] %F %L %c - %m%n',

     'log4perl.appender.tempfile'          => 'Log::Log4perl::Appender::File',
     'log4perl.appender.tempfile.filename' => $tempfn,
     'log4perl.appender.tempfile.layout'   => 'Log::Log4perl::Layout::PatternLayout',
     'log4perl.appender.tempfile.layout.ConversionPattern' =>
       '[%P:%p] %F >%c< - %m%n',

     'log4perl.logger.:info'              => 'INFO', # XOX
     'log4perl.appender.:info'            => 'Log::Log4perl::Appender::Screen',
     'log4perl.appender.:info.stderr'     => 1,
     'log4perl.appender.:info.layout'     => 
       'Log::Log4perl::Layout::PatternLayout',
     'log4perl.appender.:info.layout.ConversionPattern' =>
       '[%r] %F %L %c - %m%n',
    });


{ no warnings 'once'; $DB::single = 1; } # triggers if called with -d
Log(':info', LOG_ERR,     'logged via Log::Info  (LOG_ERR)');
Log(':info', LOG_WARNING, 'logged via Log::Info  (LOG_WARNING)');
Log(':info', LOG_INFO,    'logged via Log::Info  (LOG_INFO)');

my $appender = Log::Log4perl::Appender->new('Log::Dispatch::File',
                                            name => 'jimbob',
                                            filename => $tempfn_app,
                                            handle => *STDERR{IO});
$appender->layout(Log::Log4perl::Layout::PatternLayout->new('[%d{yyyy-MM-dd}] %m%n'));
$appender->threshold('WARN');
Log::Log4perl->get_logger(':info')->add_appender($appender);
Log(':info', LOG_ERR,   'logged via Log::Info  (LOG_ERR)');
Log(':info', LOG_WARNING, 'logged via Log::Info  (LOG_WARNING)');
Log(':info', LOG_INFO,  'logged via Log::Info  (LOG_INFO)');
Log(':info', LOG_DEBUG, 'logged via Log::Info  (LOG_DEBUG)');

my $l1 = Log::Log4perl->get_logger;
my $l2 = Log::Log4perl->get_logger(':info');

$l1->warn('l1 warn');
$l2->warn('l2 warn');
$l1->info('l1 info');
$l2->info('l2 info');
$l1->debug('l1 debug');
$l2->debug('l2 debug');

chomp(my @templn     = <$tempfh>);
chomp(my @templn_app = <$tempfh_app>);


my $pid = $$;
my $info_pm = catfile $Bin, updir, qw( lib Log Info.pm );
my $date = strftime '%Y/%m/%d %H:%M:%S', localtime;
my %level_map = qw( WARNING WARN
                    ERR ERROR );

# diag $_ for @templn;

my @templn_expect =
  # items logged to the tempfile appender with pattern
  # [%P:%p] %F >%c< - %m%n
  # via the root logger, from Log()
  (map(sprintf("[%d:%s] %s >:info< - logged via Log::Info  (LOG_%s)", 
                $pid, ($level_map{$_} // $_), $info_pm, $_
              ),
        # The XOX line sets the level for ':info' to INFO, so we expect to see
        # DEBUG filtered 
        qw( ERR WARNING INFO ERR WARNING INFO )
      ),

   # l1 uses root logger which is set to WARN
   # l2 uses :info logger which is set to WARN
   map sprintf("[$pid:%s] $0 >%s< - %s %s", 
               uc $_->[1],
               ($_->[0] eq 'l1' ? 'main' : ':info'),
               $_->[0],
               $_->[1]),
       [ l1 => 'warn' ],
       [ l2 => 'warn' ],
       [ l2 => 'info' ],
  )
  ;

is 0+ @templn, 0+ @templn_expect, 'templn count';
is $templn[$_], $templn_expect[$_]
   for 0..$#templn_expect;

my ($yy, $mm, $dd) = (localtime)[5,4,3];
$date = sprintf '%04d-%02d-%02d', $yy+1900, $mm+1, $dd;
my @templn_app_expect =
  # items logged artificially-created appender; which is via :info (l2);
  # only logged after that appender was created; log level WARN
  (map(sprintf("[$date] logged via Log::Info  (LOG_%s)", $_),
        # The XOX line sets the level for ':info' to INFO, so we expect to see
        # DEBUG filtered 
        qw( ERR WARNING )
      ),

   # l1 uses root logger which is set to WARN
   # l2 uses :info logger which is set to WARN
   map sprintf("[$date] %s %s", 
               $_->[0],
               $_->[1]),
       [ l2 => 'warn' ],
  )
  ;

is 0+ @templn_app, 0+ @templn_app_expect, 'templn_app count';
is $templn_app[$_], $templn_app_expect[$_]
   for 0..$#templn_app_expect;
