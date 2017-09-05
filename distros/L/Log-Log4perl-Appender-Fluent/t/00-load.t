use Test::More;
use Log::Log4perl;

BEGIN {
  BAIL_OUT("can't import Log::Log4perl::Appender::Fluent")
    if not use_ok('Log::Log4perl::Appender::Fluent');
}

diag("Testing Log::Log4perl::Appender::Fluent $Log::Log4perl::Appender::Fluent::VERSION, Perl $], $^X");

done_testing();
