use strict;
use warnings;

use Log::Contextual qw{:log with_logger set_logger};
use Log::Contextual::SimpleLogger;
use Test::More;

my @levels = qw(debug trace warn info error fatal);

my $var1;
my $var2;
my $var3;
my $var_logger1 = Log::Contextual::SimpleLogger->new({
  levels  => [qw(trace debug info warn error fatal)],
  coderef => sub { $var1 = shift },
});

my $var_logger2 = Log::Contextual::SimpleLogger->new({
  levels  => [qw(trace debug info warn error fatal)],
  coderef => sub { $var2 = shift },
});

my $var_logger3 = Log::Contextual::SimpleLogger->new({
  levels  => [qw(trace debug info warn error fatal)],
  coderef => sub { $var3 = shift },
});

SETLOGGER: {
  set_logger(sub { $var_logger3 });
  log_debug { 'set_logger' };
  is($var3, "[debug] set_logger\n", 'set logger works');
}

SETLOGGERTWICE: {
  my $foo;
  local $SIG{__WARN__} = sub { $foo = shift };
  set_logger(sub { $var_logger3 });
  like(
    $foo,
    qr/set_logger \(or -logger\) called more than once!  This is a bad idea! at/,
    'set_logger twice warns correctly'
  );
}

WITHLOGGER: {
  with_logger sub { $var_logger2 } => sub {

    with_logger $var_logger1 => sub {
      log_debug { 'nothing!' }
    };
    log_debug { 'frew!' };

  };

  is($var1, "[debug] nothing!\n", 'inner scoped logger works');
  is($var2, "[debug] frew!\n",    'outer scoped logger works');
}

SETWITHLOGGER: {
  with_logger $var_logger1 => sub {
    log_debug { 'nothing again!' };

    # do this just so the following set_logger won't warn
    local $SIG{__WARN__} = sub { };
    set_logger(sub { $var_logger3 });
    log_debug { 'this is a set inside a with' };
  };

  is(
    $var1,
    "[debug] nothing again!\n",
    'inner scoped logger works after using set_logger'
  );

  is($var3, "[debug] this is a set inside a with\n", 'set inside with works');

  log_debug { 'frioux!' };
  is(
    $var3,
    "[debug] frioux!\n",
    q{set_logger's logger comes back after scoped logger}
  );
}

VANILLA: {
  for (@levels) {
    main->can("log_$_")->(sub { 'fiSMBoC' });
    is($var3, "[$_] fiSMBoC\n", "$_ works");

    my @vars =
      main->can("log_$_")->(sub { 'fiSMBoC: ' . $_[1] }, qw{foo bar baz});
    is($var3, "[$_] fiSMBoC: bar\n", "log_$_ works with input");
    ok(
      eq_array(\@vars, [qw{foo bar baz}]),
      "log_$_ passes data through correctly"
    );

    my $val = main->can("logS_$_")->(sub { 'fiSMBoC: ' . $_[0] }, 'foo');
    is($var3, "[$_] fiSMBoC: foo\n", "logS_$_ works with input");
    is($val, 'foo', "logS_$_ passes data through correctly");
  }
}

ok(!eval { Log::Contextual->import; 1 }, 'Blank Log::Contextual import dies');

done_testing;
