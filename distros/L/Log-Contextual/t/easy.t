use strict;
use warnings;

use Test::More;

use lib 't/lib';
use My::Module;     # makes use of Log::Contextual::Easy::Default;
use My::Module2;    # makes use of Log::Contextual::Easy::Package;

# capture logging messages of My::Module, mapping "[...] xxx" to "...$sep"
sub logshort($$) {
  my ($cap, $sep) = @_;
  sub {
    local $_ = shift;
    s/^\[(.+)\] (xxx|"xxx")\n$/$1$sep/;
    $$cap .= $_;
  }
}

# capture warnings
my ($cap_warn, $cap_with, $cap_set);
local $SIG{__WARN__} = logshort \$cap_warn, '!';

{
  My::Module::log();
  My::Module2::log();
  is($cap_warn, undef, 'no logging by default');
}

{
  local $ENV{MY_MODULE_UPTO}  = 'info';
  local $ENV{MY_MODULE2_UPTO} = 'info';
  My::Module::log();
  My::Module2::log();
  is(
    $cap_warn,
    "info!warn!error!fatal!info!warn!error!fatal!",
    'WarnLogger enabled via ENV'
  );
  $cap_warn = '';
}

{
  use Log::Contextual::SimpleLogger;
  use Log::Contextual qw(with_logger set_logger);

  set_logger(
    Log::Contextual::SimpleLogger->new({
      levels  => [qw(info warn error)],
      coderef => logshort(\$cap_set, '/'),
    })
  );

  my $with_logger = Log::Contextual::SimpleLogger->new({
    levels  => [qw(trace info fatal)],
    coderef => logshort(\$cap_with, '|'),
  });

  with_logger $with_logger => sub {
    My::Module::log();
    My::Module2::log();    # will not be overridden
  };
  is($cap_with, 'trace|info|fatal|', 'with_logger');

  My::Module::log();
  My::Module2::log();       # will not be overridden
  is($cap_set, 'info/warn/error/', 'set_logger');

  is($cap_warn, '', 'no warnings if with_logger or set_logger');
}

done_testing;
