use strict;
use warnings;

use Test::More;

use Test::Needs {
  'Log::Log4perl' => 1.29,
};

use File::Temp qw();

Log::Log4perl->init(\<<'END_CONFIG');
log4perl.rootLogger = ERROR, LOGFILE

log4perl.appender.LOGFILE = Log::Log4perl::Appender::String

log4perl.appender.LOGFILE.layout = PatternLayout
log4perl.appender.LOGFILE.layout.ConversionPattern = file:%F line:%L method:%M - %m%n
END_CONFIG

use Log::Contextual qw( :log set_logger );
set_logger(Log::Log4perl->get_logger);

my $appender = Log::Log4perl->appender_by_name('LOGFILE');

my @elines;
my @datas;

push @elines, __LINE__; log_error { 'err FIRST' };

push @datas, $appender->string;
$appender->string('');

sub foo {
  push @elines, __LINE__; log_error { 'err SECOND' };
}
foo();

push @datas, $appender->string;
$appender->string('');

is $datas[0], "file:".__FILE__." line:$elines[0] method:main:: - err FIRST\n",
  'file and line work with Log4perl';
is $datas[1],
  "file:".__FILE__." line:$elines[1] method:main::foo - err SECOND\n",
  'file and line work with Log4perl in a sub';

done_testing;
