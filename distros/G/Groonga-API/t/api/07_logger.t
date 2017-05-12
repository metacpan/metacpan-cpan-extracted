use strict;
use warnings;
use Groonga::API::Test;

plan skip_all => 'requires groonga version > 1' if Groonga::API::get_major_version() == 1;

ctx_test(sub {
  my $ctx = shift;

  my $path = "./groonga.log";
  if (version_ge("2.1.2")) {
    unlink $path if -f $path;
    Groonga::API::default_logger_set_path($path);
    is Groonga::API::default_logger_get_path() => $path, "correct path";
  }

  my $default_level = Groonga::API::default_logger_get_max_level();
  note "default logger level: $default_level";

  my $rc = Groonga::API::logger_pass($ctx, GRN_LOG_DUMP);
  ok $rc, "should log DUMP message";

  $rc = Groonga::API::logger_pass($ctx, GRN_LOG_ERROR);
  ok $rc, "should also log ERROR message";

  # deprecated since groonga 2.1.2
  $rc = Groonga::API::logger_info_set($ctx, {
    max_level => GRN_LOG_NOTICE,
    flags => GRN_LOG_TIME|GRN_LOG_MESSAGE,
  });
  is $rc => GRN_SUCCESS, "set logger info";

  $rc = Groonga::API::logger_pass($ctx, GRN_LOG_DUMP);
  ok !$rc, "should not log DUMP message now";

  $rc = Groonga::API::logger_pass($ctx, GRN_LOG_ERROR);
  ok $rc, "should still log ERROR message";

  Groonga::API::logger_put($ctx, GRN_LOG_EMERG, __FILE__, __LINE__, 'test', '%s', "test");

  if (version_ge("2.1.2")) {
    ok -s $path, "log file has been written";
    unlink $path if -f $path;
  }

  if (version_ge("2.1.2")) {
    Groonga::API::logger_reopen($ctx);

    Groonga::API::logger_put($ctx, GRN_LOG_EMERG, __FILE__, __LINE__, 'test', '%s', "test");

    ok -s $path, "log file has been written";
    unlink $path if -f $path;
  }
});

# TODO: GRN_LOG() support?

done_testing;
