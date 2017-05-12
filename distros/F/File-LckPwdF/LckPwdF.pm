package File::LckPwdF;
require 5.002;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;

#use diagnostics;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(lock_passwd unlock_passwd);
@EXPORT_OK =
  qw(lckpwdf ulckpwdf $Default_Timeout $Rand_Wait $Passwd_Locked $EAGAIN);

BEGIN: {
  undef($@);
  my($Errno_OK) = eval "use Errno qw(EAGAIN EACCES EINVAL EALREADY); 1;";

  if ($Errno_OK && (!defined($@) || ($@ eq ""))) {
    $EAGAIN = &EAGAIN();
  } else {
    undef($@);
    my($Errno_OK) =
      eval "use Errno qw(EWOULDBLOCK EACCES EINVAL EALREADY); 1;";
    if ($Errno_OK && (!defined($@) || ($@ eq ""))) {
      $EAGAIN = &EWOULDBLOCK();
    } else {
      undef($@);
      my($POSIX_OK) = eval "use POSIX qw(EAGAIN EACCES EINVAL EALREADY); 1;";

      if ($POSIX_OK && (!defined($@) || ($@ eq ""))) {
	$EAGAIN = &EAGAIN();
      } else {
	my($POSIX_OK) =
	  eval "use POSIX qw(EWOULDBLOCK EACCES EINVAL EALREADY); 1;";

	if ($POSIX_OK && (!defined($@) || ($@ eq ""))) {
	  $EAGAIN = &EWOULDBLOCK();
	} else {
	  require ("errno.ph");
	  $EAGAIN = eval "&EAGAIN();" || eval "&EWOULDBLOCK();";
	}
      }
    }
  }
  $VERSION = '0.01';
  $Default_Timeout = 15;
  $Rand_Wait = 10;
  $Passwd_Locked = 0;
}

bootstrap File::LckPwdF $VERSION;

# Preloaded methods go here.

sub lock_passwd (;$) {
  my($time) = time;
  
  unless ($> == 0) {
    if (&lckpwdf() >= 0) {
      $Passwd_Locked = 1;
      return 1;
    } else {
      if ($Passwd_Locked) {
	$! = &EALREADY();
      } else {
	$! = &EACCES();
      }
      return 0;
    }
  }

  if ($Passwd_Locked) {
    if (&lckpwdf() >= 0) {
      return 1;
    } else {
      $! = &EALREADY();
      return 0;
    }
  }
  
  my($timeout) = $Default_Timeout;
  
  if ($#_ > -1) {
    $timeout = $_[0];
  }

  if ($timeout < 0) {
    $! = &EINVAL();
    carp("File::LckPwdF::lock_passwd fed a timeout value below 0");
    return 0;
  } elsif ($timeout == 0) {
    until (&lckpwdf() >= 0) {
      if ($Rand_Wait > 0) {
	sleep int(rand($Rand_Wait) + 1);
      }
    }
    $Passwd_Locked = 1;
    return 1;
  } else {
    if (&lckpwdf() >= 0) {
      $Passwd_Locked = 1;
      return 1;
    } else {
      until ((($status = &lckpwdf()) >= 0) || ((time - $time) >= $timeout)) {
	if ($Rand_Wait > 0) {
	  sleep int(rand($Rand_Wait) + 1);
	}
      }
      if ($status >= 0) {
	$Passwd_Locked = 1;
	return 1;
      } else {
	$! = $EAGAIN;
	return 0;
      }
    }
  }
}

sub unlock_passwd () {
  if (&ulckpwdf() >= 0) {
    $Passwd_Locked = 0;
    return 1;
  } else {
    if (! $Passwd_Locked) {
      $! = &EALREADY();
    } elsif ($> == 0) {
      $! = &EINVAL;
    } else {
      $! = &EACCES;
    }
    return 0;
  }
}

END: {
  if ($Passwd_Locked) {
    unlock_passwd();
  }
}

1;
__END__

=head1 NAME

File::LckPwdF - Lock and unlock the passwd and shadow files with lckpwdf and ulckpwdf

=head1 SYNOPSIS

  use File::LckPwdF;

  (lock_passwd(15)) || (die "Can't lock password file:\n$! stopped");

  # ... do stuff with the passwd file ...

  (unlock_passwd()) || (die "Can't unlock password file:\n$! stopped");

=head1 DESCRIPTION

This is a perl module to use B<lckpwdf(3)> and B<ulckpwdf(3)> to lock
the F</etc/passwd> and (if present) F</etc/shadow> files.

=head2 Functions exported automatically

B<lock_passwd($timeout)>

B<$timeout> works as follows:

=over 4

=item 1. The initial time is checked.

=item 2. If B<$timeout> is 0, it tries B<lckpwdf()> until it succeeds,
         waiting a random time in between.

=item 3. If B<$timeout> is above 0, it tries B<lckpwdf()> once. If
         that (or any following B<lckpwdf()>) succeeds, it returns
         1. It will try B<lckpwdf()> until either it succeeds or the
         time is greater than the initial time plus B<$timeout>. In
         the latter case, it returns 0. It waits a random time in
         between tries of B<lckpwdf()>.

=back

The random timeout is controlled by B<$File::LckPwdF::Rand_Wait>,
which is exported on request. It is used via

    sleep int(rand($Rand_Wait) + 1);

inside an until loop. This sleep is only done if
B<$File::LckPwdF::Rand_Wait> is above 0.

B<$timeout> defaults to B<$File::LckPwdF::Default_Timeout>, which is
also exported on request; the initial setting of
B<$File::LckPwdF::Default_Timeout> (the default default) is 15
seconds. The default setting for B<$File::LckPwdF::Rand_Wait> is 10
seconds.

B<unlock_passwd()>

This function uses B<ulckpwdf()>. If B<lock_passwd()> has previously
been used to lock the passwd file, and B<unlock_passwd()> has not been
used to lock it, then it will be used to unlock the passwd file in an
END: statement.  (Admittedly, with many implementations of
B<lckpwdf()> this is not necessary, since when a process exits it
loses the passwd file lock; it is present as a safety measure for
those systems for which this is not true.)

=head2 Functions exported by request

B<lckpwdf()>
B<ulckpwdf()>

These are the xs-loaded versions of B<lckpwdf(3)> and B<ulckpwdf(3)>,
respectively.

=head1 RETURN VALUE

The B<lock_passwd()> and B<unlock_passwd()> functions return 1 on
success and 0 on failure.  The return values for B<lckpwdf()> and
B<ulckpwdf()> are the same as for the system versions (B<lckpwdf(3)>
and B<ulckpwdf(3)>).

=head1 ERRORS

If the effective UID is not 0, then B<lock_passwd()> and
B<unlock_passwd()> set B<$!> to B<EACCES> if they fail (they do try
once, just in case you've got a I<really> weird setup).

If the effective UID is 0, in the event of failure, B<lock_passwd()>
sets B<$!> to:

=over 4

=item 1. if you've already locked the file through B<lock_passwd()>,
   B<EALREADY>

=item 2. B<EAGAIN> (or B<EWOULDBLOCK>, if B<EAGAIN> isn't present on your
   system and B<EWOULDBLOCK> is; B<$File::LckPwdF::EAGAIN>,
   which is exported on request, is equal to the value
   returned).

=back

B<unlock_passwd()>, in the event of failure, sets B<$!> to:

=over 4

=item 1. if you've already unlocked the file via B<unlock_passwd()> or
         haven't locked it via B<lock_passwd()>, B<EALREADY>.

=item 2.  B<EINVAL>.

=back

If you try to use a negative number for B<$timeout> with
B<lock_passwd($timeout)>, it carps, returns 0, and sets B<$!> to
B<EINVAL>.

=head1 CAVEATS

This program only works if your system has B<lckpwdf(3)> and
B<ulckpwdf(3)>. This should be true of SVR4 systems; others will
vary. If you use B<lock_passwd()> and B<unlock_passwd()>,
B<lckpwdf(3)> and B<ulckpwdf(3)> need to have return values of 0+ for
success and below 0 (usually -1) for failure.

The timeout period for B<lock_passwd()> is approximate, since many
versions of B<lckpwdf()> will keep trying for a total of 15 seconds to
lock the passwd (and possibly shadow) files before they return an
appropriate value.

This module only keeps track on its own of whether the passwd file is
locked if you always use B<lock_passwd()> and B<unlock_passwd()>. If
you use B<lckpwdf()> or B<ulckpwdf()> by themselves for locking and
unlocking, you will need to set B<$File::LckPwdF::Passwd_Locked> to 1
for locked and 0 for unlocked yourself.

=head1 BUGS

I haven't written any good automated tests for this program yet. If
anyone's interested, be my guest (or for any other improvements, of
course).

=head1 AUTHOR

E. Allen Smith, <easmith@beatrice.rutgers.edu>. Copyright 1998. This
software may be used, distributed, modified, etcetera under the same
conditions as B<perl>.

=head1 FILES

F</etc/passwd>, F</etc/shadow>

=head1 SEE ALSO

L<perl(1)>, L<lckpwdf(3)>, L<ulckpwdf(3)>

=cut

