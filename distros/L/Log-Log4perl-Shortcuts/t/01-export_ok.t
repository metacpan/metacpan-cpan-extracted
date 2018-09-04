#/usr/bin/env perl
use Test::More;
use Test::NoWarnings;
use Test::File::ShareDir::Dist { 'Log-Log4perl-Shortcuts' => 'config/' };
use Test::File::ShareDir::Module { 'Log::Log4perl::Shortcuts' => 'config/' };
diag( "Running export tests" );










my $tests = 3; # keep on line 17 for ,i (increment and ,d (decrement)
plan tests => $tests;

subtest 'exports subs ok' => \&exports;
subtest 'exports all ok' => \&exports_all;

sub exports {
  use Log::Log4perl::Shortcuts qw(set_log_config);
  ok ( defined &Log::Log4perl::Shortcuts::set_log_config, 'exports "set_log_config" sub' );

  use Log::Log4perl::Shortcuts qw(logw);
  ok ( defined &Log::Log4perl::Shortcuts::logw, 'exports "logw" sub' );

  use Log::Log4perl::Shortcuts qw(logf);
  ok ( defined &Log::Log4perl::Shortcuts::logf, 'exports "logf" sub' );

  use Log::Log4perl::Shortcuts qw(loge);
  ok ( defined &Log::Log4perl::Shortcuts::loge, 'exports "loge" sub' );

  use Log::Log4perl::Shortcuts qw(logd);
  ok ( defined &Log::Log4perl::Shortcuts::logd, 'exports "logd" sub' );

  use Log::Log4perl::Shortcuts qw(logt);
  ok ( defined &Log::Log4perl::Shortcuts::logt, 'exports "logt" sub' );

  use Log::Log4perl::Shortcuts qw(logi);
  ok ( defined &Log::Log4perl::Shortcuts::logi, 'exports "logi" sub' );

  use Log::Log4perl::Shortcuts qw(logc);
  ok ( defined &Log::Log4perl::Shortcuts::logc, 'exports "logc" sub' );
}

sub exports_all {
  use Log::Log4perl::Shortcuts qw(:all);
  ok ( defined &Log::Log4perl::Shortcuts::set_log_config, 'exports "set_log_config" sub' );
  ok ( defined &Log::Log4perl::Shortcuts::logw, 'exports "logw" sub' );
  ok ( defined &Log::Log4perl::Shortcuts::logf, 'exports "logf" sub' );
  ok ( defined &Log::Log4perl::Shortcuts::loge, 'exports "loge" sub' );
  ok ( defined &Log::Log4perl::Shortcuts::logd, 'exports "logd" sub' );
  ok ( defined &Log::Log4perl::Shortcuts::logt, 'exports "logt" sub' );
  ok ( defined &Log::Log4perl::Shortcuts::logi, 'exports "logi" sub' );
  ok ( defined &Log::Log4perl::Shortcuts::logc, 'exports "logc" sub' );
}
