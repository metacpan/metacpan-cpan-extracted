use Config::Plugin::Tiny; # For config_tiny().

use Log::Handler::Plugin::DBI; # For configure_logger() and log_object().

use Test::More tests => 1;

# ------------------------

# Use undef as the first parameter because $self is not available.

my($config) = config_tiny(undef, 't/config.logger.conf');

configure_logger(undef, $$config{logger});

isa_ok(log_object, 'Log::Handler::Output::DBI', 'log_object');

log(undef, notice => 'One');
