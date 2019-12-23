package Time::Fake;
use Carp;
use strict;
use vars '$VERSION';
$VERSION = "0.11";

#####################

my $OFFSET = 0;

*CORE::GLOBAL::time = sub() { CORE::time() + $OFFSET };

*CORE::GLOBAL::localtime = sub(;$) {
   @_ ? CORE::localtime($_[0])
      : CORE::localtime(CORE::time() + $OFFSET);
};

*CORE::GLOBAL::gmtime = sub(;$) {
   @_ ? CORE::gmtime($_[0])
      : CORE::gmtime(CORE::time() + $OFFSET);
};

sub import {
    my $pkg = shift;
    $pkg->offset(shift);
}

sub offset {
    my $pkg = shift;
    return $OFFSET if !@_;
    
    my $old_offset = $OFFSET;
    $OFFSET = _to_offset(shift);
    return $old_offset;
}

sub reset {
    shift->offset(0);
}

my %mult = (
    s => 1,
    m => 60,
    h => 60*60,
    d => 60*60*24,
    M => 60*60*24*30,
    y => 60*60*24*365,
);

sub _to_offset {
    my $t = shift || return 0;
    
    if ($t =~ m/^([+-]\d+)([smhdMy]?)$/) {
        $t = $1 * $mult{ $2 || "s" };
        
    } elsif ($t !~ m/\D/) {
        $t = $t - CORE::time;
        
    } else {
        croak "Invalid time offset: `$t'";
    }
    
    return $t;
}

1;

__END__

=head1 NAME

Time::Fake - Simulate different times without changing your system clock

=head1 SYNOPSIS

Pretend we are running 1 day in the future:

  use Time::Fake '+1d';

Pretend we are running 1 year in the past:

  use Time::Fake '-1y';

Pretend the script started at epoch time 1234567:

  use Time::Fake 1234567;

See what an existing script would do if run 20 years in the future:

  % perl -MTime::Fake="+20y" test.pl

Run a section of code in a time warp:

  use Time::Fake;
  
  # do some setup
  
  Time::Fake->offset("+1y");
  run_tests(); # thinks it's a year ahead

  Time::Fake->reset; # back to the present

=head1 DESCRIPTION

Use this module to achieve the effect of changing your system clock, but
without actually changing your system clock. It overrides the Perl builtin
subs C<time>, C<localtime>, and C<gmtime>, causing them to return a
"faked" time of your choice. From the script's point of view, time still
flows at the normal rate, but it is just offset as if it were executing
in the past or present.

You may find this module useful in writing test scripts for code that has
time-sensitive logic.

=head1 USAGE

=head2 Using and importing:

  use Time::Fake $t;

Is equivalent to:

  use Time::Fake;
  Time::Fake->offset($t);

See below for arguments to C<offset>. This usage makes it easy to
fake the time for existing scripts, as in:

  % perl -MTime::Fake=+1y script.pl

=head2 offset

  Time::Fake->offset( [$t] );

C<$t> is either an epoch time, or a relative offset of the following
form:

  +3    # 3 seconds in the future
  -3s   # 3 seconds in the past
  +1h   # 1 hour in the future
  etc..

Relative offsets must begin with a plus or minus symbol. The supported
units are:

  s second
  m minute
  h hour
  d day (24 hours)
  M month (30 days)
  y year (365 days)

If C<$t> is an epoch time, then C<time>, C<localtime>, and C<gmtime>
will act as though the the current time (when C<offset> was called) was
actually at C<$t> epoch seconds.
Otherwise, the offset C<$t> will be added to the times returned by these
builtin subs.

When C<$t> is false, C<time>, C<localtime>, C<gmtime>
remain overridden, but their behavior resets to reflect the actual
system time.

When C<$t> is omitted, nothing is changed, but C<offset> returns the
current additive offset (in seconds). Otherwise, its return value is
the I<previous> offset.

C<offset> may be called several times. However, I<The effect of multiple
calls is NOT CUMULATIVE.> That is:

  Time::Fake->offset("+1h");
  Time::Fake->offset("+1h");
  
  ## same as
  # Time::Fake->offset("+1h");
  
  ## NOT the same as 
  # Time::Fake->offset("+2h");

Each call to C<offset> completely cancels out the effect of any
previous calls. To make the effect cumulative, use the return value
of calling C<offset> with no arguments:

  Time::Fake->offset("+1h");
  ...
  Time::Fake->offset( Time::Fake->offset + 3600 ); # add another hour

=head2 reset

  Time::Fake->reset;

Is the same as:

  Time::Fake->offset(0);

That is, it returns all the affected builtin subs to their
default behavior -- reporing the actual system time.

=head1 KNOWN CAVEATS

Time::Fake must be loaded at C<BEGIN>-time (e.g., with a standard
C<use> statement). It must be loaded before perl I<compiles> any code
that uses C<time>, C<localtime>, or C<gmtime>. Due to inherent
limitations in overriding builtin subs, any code that was compiled
before loading Time::Fake will not be affected.

Because the system clock is not being changed, only Perl code that
uses C<time>, C<localtime>, or C<gmtime> will be fooled about the date.
In particular, the operating system is not fooled,
nor are other programs. If your Perl code modifies a file for example,
the file's modification time will reflect the B<actual> (not faked) time.
Along the same lines, if your Perl script obtains the time from somewhere
other than the affected builtins subs (e.g., C<qx/date/>), the actual
(not faked) time will be reflected.

Time::Fake doesn't affect -M, -A, -C filetest operators in the way you'd
probably want. These still report the B<actual> (not faked) script start
time minus file access time.

Time::Fake has not been tested with other modules that override the time
builtins, e.g., Time::HiRes.

=head1 SEE ALSO

Time::Warp, which uses XS to fool more of Perl.

=head1 AUTHOR

Time::Fake is written by Mike Rosulek E<lt>mike@mikero.comE<gt>. Feel 
free to contact me with comments, questions, patches, or whatever.

=head1 COPYRIGHT

Copyright (c) 2008 Mike Rosulek. All rights reserved. This module is free 
software; you can redistribute it and/or modify it under the same terms as Perl 
itself.
