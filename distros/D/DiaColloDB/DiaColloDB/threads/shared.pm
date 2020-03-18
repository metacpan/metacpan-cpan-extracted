## -*- Mode: CPerl -*-
## File: DiaColloDB::threads::shared.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Descript: DiaColloDB: temporary data structures: use threads/shared.pm or forks/shared.pm

package DiaColloDB::threads::shared;
use DiaColloDB::threads;
use strict;

our ($MODULE);
BEGIN {
  #$MODULE = '' if ($^P); ##-- disable threads if running under debugger

  if (!defined($DiaColloDB::threads::MODULE)) {
    $MODULE = '';
  }
  elsif (!defined($MODULE)) {
    ##-- attempt to load thread support
    my $loadme = $DiaColloDB::threads::MODULE; #.'::shared';

    if ($INC{"$loadme/shared.pm"}) {
      ##-- thread-support already loaded
      $MODULE = "${loadme}::shared";
    }
    else {
      ##-- no thread-support loaded yet  (loading forks/shared.pm does NOT set $INC{"threads/shared.pm"}=>"/path/to/forks/shared.pm")
      #print STDERR __PACKAGE__, ": attempting to load $module\n";
      my $rc  = eval "use ${loadme}::shared; 1";
      my $err = "$@";
      $MODULE = ($rc && !$err) ? "${loadme}::shared" : '';
      warn(__PACKAGE__, " Warning: failed to load thread-support via ${loadme}/shared.pm: $err") if (!$MODULE);
    }
    $MODULE //= '';
  }
}

sub import {
  if ($MODULE) {
    #my $that   = shift;
    my $caller = caller;
    my $sub = eval qq{sub { package $caller; $MODULE->import(); } };
    $sub->(@_);
  }
}

1; ##-- be happy

__END__
