package My::Module2;
use Log::Contextual::Easy::Package;

sub log {
  Dlog_fatal { $_ }
  DlogS_error { $_ }
  logS_warn { $_[0] }
  logS_info { $_[0] } log_debug { $_[0] } log_trace { $_[0] } 'xxx';
}

1;
