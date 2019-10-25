use strict;
use warnings;

# this does a conditional load of log4perl and if not found, stubs out
# the logger calls. it should be called with a 'do' so that the code
# executes in the caller's package.
BEGIN {
  if ($INC{'Log/Log4perl.pm'}) {
    eval "use Log::Log4perl qw(:easy)";
  }

  no strict 'refs';
  foreach (qw(TRACE DEBUG INFO WARN ERROR FATAL)) {
    my $glob = __PACKAGE__ . "::$_";
    *{$glob} = sub {} if !defined &$glob;
  }
  
  my $glob = __PACKAGE__ . "::LOGDIE";
  *{$glob} = sub { die @_; } if !defined &$glob;
};
