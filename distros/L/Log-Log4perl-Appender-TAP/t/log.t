use Test2::Bundle::Extended;
use Log::Log4perl qw( :easy );

Log::Log4perl::init(\<<CONF);
log4perl.rootLogger=DEBUG, AppDebug, AppError

log4perl.filter.MatchError = Log::Log4perl::Filter::LevelMatch
log4perl.filter.MatchError.LevelToMatch = ERROR
log4perl.filter.MatchError.AcceptOnMatch = true

log4perl.filter.MatchDebug = Log::Log4perl::Filter::LevelMatch
log4perl.filter.MatchDebug.LevelToMatch = DEBUG
log4perl.filter.MatchDebug.AcceptOnMatch = true

log4perl.appender.AppDebug=Log::Log4perl::Appender::TAP
log4perl.appender.AppDebug.method=note
log4perl.appender.AppDebug.layout=PatternLayout
log4perl.appender.AppDebug.layout.ConversionPattern=prefix1 %m
log4perl.appender.AppDebug.Filter = MatchDebug

log4perl.appender.AppError=Log::Log4perl::Appender::TAP
log4perl.appender.AppError.method=diag
log4perl.appender.AppError.layout=PatternLayout
log4perl.appender.AppError.layout.ConversionPattern=prefix2 %m
log4perl.appender.AppError.Filter = MatchError

CONF

is(
  intercept { DEBUG "this is debug" },
  array {
    event Note => sub {
      call message => 'prefix1 this is debug';
    };
    end;
  },
  'debug sent to note with prefix',
);

is(
  intercept {  ERROR "this is error" },
  array {
    event Diag => sub {
      call message => 'prefix2 this is error',
    };
    end;
  },
  'error sent to diag with prefix',
);

my $appender = eval { Log::Log4perl::Appender::TAP->new };
diag $@ if $@;
isa_ok $appender, 'Log::Log4perl::Appender::TAP';
isa_ok $appender, 'Log::Log4perl::Appender';

done_testing;
