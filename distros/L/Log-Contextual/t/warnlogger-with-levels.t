use strict;
use warnings;

use Log::Contextual::WarnLogger;    # -levels => [qw(custom1 custom2)];
use Log::Contextual qw{:log set_logger} => -logger =>
  Log::Contextual::WarnLogger->new({env_prefix => 'FOO'});

use Test::More;
use Test::Fatal;

{
  my $l;
  like(
    exception { $l = Log::Contextual::WarnLogger->new({levels => ''}) },
    qr/invalid levels specification: must be non-empty arrayref/,
    'cannot pass empty string for levels',
  );

  like(
    exception { $l = Log::Contextual::WarnLogger->new({levels => []}) },
    qr/invalid levels specification: must be non-empty arrayref/,
    'cannot pass empty list for levels',
  );

  is(
    exception {
      $l = Log::Contextual::WarnLogger->new({
        levels => undef,
        env_prefix => 'FOO'
      });
    },
    undef,
    'ok to leave levels undefined',
  );
}

{
  my $l = Log::Contextual::WarnLogger->new({
    env_prefix => 'BAR',
    levels     => [qw(custom1 custom2)],
  });

  foreach my $sub (qw(is_custom1 is_custom2 custom1 custom2)) {
    is(exception { $l->$sub }, undef, $sub . ' is handled by AUTOLOAD',);
  }

  foreach my $sub (qw(is_foo foo)) {
    is(
      exception { $l->$sub },
      undef, 'arbitrary sub ' . $sub . ' is handled by AUTOLOAD',
    );
  }
}

{
  # levels is optional - most things should still work otherwise.
  my $l = Log::Contextual::WarnLogger->new({env_prefix => 'BAR',});

  # if we don't know the level, and there are no environment variables set,
  # just log everything.
  {
    ok($l->is_custom1, 'is_custom1 defaults to true on WarnLogger');
    ok($l->is_custom2, 'is_custom2 defaults to true on WarnLogger');
  }

  # otherwise, go with what the variable says.
  {
    local $ENV{BAR_CUSTOM1} = 0;
    local $ENV{BAR_CUSTOM2} = 1;
    ok(!$l->is_custom1, 'is_custom1 is false on WarnLogger');
    ok($l->is_custom2,  'is_custom2 is true on WarnLogger');

    ok($l->is_foo, 'is_foo defaults to true on WarnLogger');

    local $ENV{BAR_UPTO} = 'foo';
    like(
      exception { $l->is_bar },
      qr/Unrecognized log level 'foo' in \$ENV\{BAR_UPTO\}/,
      'Cannot use an unrecognized log level in UPTO',
    );
  }
}

# these tests taken from t/warnlogger.t

my $l = Log::Contextual::WarnLogger->new({
  env_prefix => 'BAR',
  levels     => [qw(custom1 custom2)],
});

{
  local $ENV{BAR_CUSTOM1} = 0;
  local $ENV{BAR_CUSTOM2} = 1;
  ok(!$l->is_custom1, 'is_custom1 is false on WarnLogger');
  ok($l->is_custom2,  'is_custom2 is true on WarnLogger');

  ok(!$l->is_foo, 'is_foo is false (custom levels supplied) on WarnLogger');
}

{
  local $ENV{BAR_UPTO} = 'custom1';

  ok($l->is_custom1, 'is_custom1 is true on WarnLogger');
  ok($l->is_custom2, 'is_custom2 is true on WarnLogger');
}

{
  local $ENV{BAR_UPTO} = 'custom2';

  ok(!$l->is_custom1, 'is_custom1 is false on WarnLogger');
  ok($l->is_custom2,  'is_custom2 is true on WarnLogger');
}

{
  local $ENV{BAR_UPTO} = 'foo';

  like(
    exception { $l->is_custom1 },
    qr/Unrecognized log level 'foo'/,
    'Cannot use an unrecognized log level in UPTO',
  );
}

done_testing;
