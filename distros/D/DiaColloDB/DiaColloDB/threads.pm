## -*- Mode: CPerl -*-
## File: DiaColloDB::threads.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Descript: DiaColloDB: temporary data structures: use threads.pm or forks.pm

package DiaColloDB::threads;
use Config;
use strict;

our ($MODULE);
BEGIN {
  #$MODULE = '' if ($^P); ##-- disable threads if running under debugger

  if (!defined($MODULE)) {
    ##-- attempt to load thread support
    my $loadme = $Config{usethreads} ? 'threads' : 'forks';

    if ($INC{"$loadme.pm"}) {
      ##-- thread-support already loaded
      $MODULE = $loadme;
    }
    else {
      ##-- no thread-support loaded yet (loading forks.pm also sets $INC{"threads.pm"}=>"/path/to/forks.pm")
      #print STDERR __PACKAGE__, ": attempting to load $module\n";
      my $rc  = eval "use $loadme; 1";
      my $err = "$@";
      $MODULE = ($rc && !$err) ? $loadme : '';
      warn(__PACKAGE__, " Warning: failed to load thread-support via ${loadme}.pm: $err") if (!$MODULE);
    }
    $MODULE //= '';
  }
  *import = $MODULE ? UNIVERSAL::can($MODULE,'import') : sub {}
    if (!UNIVERSAL::can(__PACKAGE__,'import'));
}

## $threadid = CLASS->tid()
sub tid {
  return $MODULE ? threads->tid() : 0;
}



1; ##-- be happy

__END__
