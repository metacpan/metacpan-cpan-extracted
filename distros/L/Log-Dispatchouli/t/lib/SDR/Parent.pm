use strict;
package SDR::Parent;
use base 'Log::Dispatchouli::Global';
sub logger_globref { no warnings 'once'; \*Logger }

my $default_logger;
sub default_logger_ref { \$default_logger }
sub default_logger_args {
  return {
    ident   => __PACKAGE__,
    log_pid => 0,
    to_self => 1,
  }
}
1;
