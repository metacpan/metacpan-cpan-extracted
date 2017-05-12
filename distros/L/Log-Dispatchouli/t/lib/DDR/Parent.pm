use strict;
package DDR::Parent;
use base 'Log::Dispatchouli::Global';
sub logger_globref { no warnings 'once'; \*Logger }
sub default_logger_args {
  return {
    ident   => __PACKAGE__,
    log_pid => 0,
    to_self => 1,
  }
}
1;
