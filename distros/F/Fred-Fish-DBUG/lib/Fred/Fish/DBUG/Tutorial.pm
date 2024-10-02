###
###  Copyright (c) 2019 - 2024 Curtis Leach.  All rights reserved.
###
###  Module: Fred::Fish::DBUG::Tutorial

package Fred::Fish::DBUG::Tutorial;

use strict;
use warnings;

use vars qw ( @ISA @EXPORT @EXPORT_OK $VERSION );
use Exporter;

$VERSION   = "2.05";
@ISA       = qw ( Exporter );
@EXPORT    = qw ();
@EXPORT_OK = qw ();

# =============================================================================
# Only POD text appears below this line!
# =============================================================================

=head1 NAME

Fred::Fish::DBUG::Tutorial - Gives a basic tutorial on how to use the
L<Fred::Fish::DBUG> module.

=head1 SYNOPSIS

This is real "old school" technology.  So it's fairly obvious on how to use it.
It's basically the next step up from just putting print STDERR calls in your
code.  But in this case you don't have to remember to remove the debug prints
from the code before releasing it into production.  The logging is always
available on an on demand basis!

In many cases it's just easier to show an example instead of trying to put
things into words.  So this module is just some POD text to document how to use
L<Fred::Fish::DBUG>.

For more details on how to use a function mentioned in this POD text see
I<perldoc Fred::Fish::DBUG>.  The POD you are reading right now just gives
you the basics, not the advanced options available.  There is a lot of extra
functionality not covered here.

=head1 BASIC USAGE

In order to get anything to write to your B<fish> logs, you must first call
I<DBUG_PUSH()>.  If you never call it then nothing will be written to your
B<fish> logs.  It won't even create an empty file.

Also if you call it more than once, all subsequent calls to DBUG_PUSH() are
ignored.  Only the 1st call is honored!

There are many interesting optional arguments to DBUG_PUSH() so read the POD
on it for more details!

The following are all examples for a program called B<example.pl>.  It's
assumed it's called like:

     example.pl -a -b

=head1 EXAMPLE # 1 - a really simple example.

    use Fred::Fish::DBUG qw / on /;
    DBUG_PUSH ($file);         # Assuming $file is already set.
    DBUG_ENTER_FUNC (@ARGV);
    DBUG_LEAVE (0);

Here's what's written to your B<fish> logs.  Notice how it put square brackets
around each argument to your program and made it a comma separated list.

    >main-prog
    | args: [-a], [-b]
    <main-prog
    exit (0)

    >Fred::Fish::DBUG::END
    | Fred::Fish::DBUG: So Long, and Thanks for All the Fish!
    <Fred::Fish::DBUG::END ()

 ===============================================================

=head1 EXAMPLE # 2 - Another simple example!

    use Fred::Fish::DBUG qw / on /;
    my $flag = 1;
    DBUG_PUSH ($file, off=>${flag});     # Assuming $file is already set.
    DBUG_ENTER_FUNC (@ARGV);
    DBUG_LEAVE (0);

Wait, what happened?  There is no B<fish> output!

The B<off> argument said to turn B<fish> off.  If you'd set I<$flag> to B<0>
instead of B<1>, it would have turned B<fish> back on again.  So if you had the
value of I<$flag> controlled by an argument to your program, or by a special
environment variable, you could decide at run time if you are going to generate
a B<fish> log or not.

You could have done the same thing by putting the call to DBUG_PUSH() into an
B<if> block, but that's a bit more typing and messy.

 ===============================================================

=head1 EXAMPLE # 3 - Yet another simple example!

    use Fred::Fish::DBUG qw / off /;
    DBUG_PUSH ($file);         # Assuming $file is already set.
    DBUG_ENTER_FUNC (@ARGV);
    DBUG_LEAVE (0);

Oops, no B<fish> logs again.  This time B<fish> has been completely disabled.
Nothing will be logged.  You did notice the change from B<on> to B<off>.

 ===============================================================

=head1 EXAMPLE # 4 - Some conditional logic.

    use Fred::Fish::DBUG qw / on_if_set  env_var_of_your_choice /;

If ( B<$ENV{env_var_of_your_choice}> ) is true it will behave like EXAMPLE # 1
& 2, otherwise it will behave like EXAMPLE # 3.

    use Fred::Fish::DBUG qw / off_if_set  env_var_of_your_choice /;

If ( B<$ENV{env_var_of_your_choice}> ) is true it will behave like EXAMPLE # 3,
otherwise it will behave like EXAMPLE # 1 & 2.

As it's name implies B<env_var_of_your_choice> can be any name you want.
Provides an easy way to take your module out of the B<fish> trace even when
other code currently has B<fish> active.  Allows someone to see only his own
code without having your module cluttering up his logs uless he requests to see
it by setting the appropriate ENV var.

 ===============================================================

=head1 EXAMPLE # 5 - Something a little more advanced.


    use Fred::Fish::DBUG qw / on /;
    DBUG_PUSH ($file);         # Assuming $file is already set.
    DBUG_ENTER_FUNC (@ARGV);
    my ($a, $b);
    my @pass = qw /1 2 3/;
    some_function ( qw /Once upon a time!/ );
    $a = some_function ( "There were", 3, "little pigs.", "?@*!*#****" );
    my @names = some_function ( qw /Larry Joe Curly/ );
    ($a, $b) = some_function ( @pass, \@pass, undef );
    DBUG_LEAVE (0);

    sub some_function {
       DBUG_ENTER_FUNC (@_);
       # Do some unspecified work here!
       DBUG_RETURN (@_);
    }

Here's what's written to your B<fish> logs.  See the return values are also
surrounded by square brackets in a comma separated list.  Also see how what's
returned is controlled by what you plan on doing with the return value.  Toss
it, saving as a scalar, and asking for all or part of the array!

The return basically evaluates as:

    return ( wantarray ? @_ : (defined wantarray ? $_[0] : undef) );

    >main-prog
    | args: [-a], [-b]
    | >main::some_function
    | | args: [Once], [upon], [a], [time!]
    | <main::some_function - return ()
    | >main::some_function
    | | args: [There were], [3], [little pigs.], [?@*!*#****]
    | <main::some_function - return ([There were])
    | >main::some_function
    | | args: [Larry], [Joe], [Curly]
    | <main::some_function - return ([Larry], [Joe], [Curly])
    | >main::some_function
    | | args: [1], [2], [3], [ARRAY(0x2013bd78)], [<undef>]
    | <main::some_function - return ([1], [2], [3], [ARRAY(0x2013bd78)], [<undef>])
    <main-prog
    exit (0)

    >Fred::Fish::DBUG::END
    | Fred::Fish::DBUG: So Long, and Thanks for All the Fish!
    <Fred::Fish::DBUG::END ()

Some special notes about the 4th call to some_function.

It sets $a to "1" and $b to "2".  The rest of the return values are tossed.
Since ($a, $b) just asks for the 1st 2 values in the returned array!  Too bad
perl doesn't provide a way to tell how many of the values are actually used.
All perl's B<wantarray> feature says is to expect zero, one or many return
values.  So this module can't tell you that these extra values are being tossed
and not show these extra unused values in the B<fish> logs!

Another note is that it doesn't attempt to expand array or hash references.
You'd have to do that yourself if you want to see it in B<fish>.

But it does convert a code reference into the name of the function.  That
information is just too useful when it happens.

  Ex:  some_function ( \&call_me );

The argument would show up as:

    | | args: [\&main::call_me]

Finally note the final E<lt>undefE<gt> in both the args and return value.
You'll see this whenever an undefined value is passed this way so that the
value won't be mistaken for the empty string.  So you're out of luck if you
expect to see this value as a string in your data and know which is which.

 ===============================================================

=head1 EXAMPLE # 6 - Lets do some printing ...

    use Fred::Fish::DBUG qw / on /;
    DBUG_PUSH ($file, kill_end_trace => 1);    # Assuming $file is already set.
    DBUG_ENTER_FUNC (@ARGV);
    some_function ( qw /Once upon a time!/ );
    DBUG_LEAVE (0);

    sub some_function {
       DBUG_ENTER_FUNC (@_);
       DBUG_PRINT ("INFO", "<%s> <%s>", "Hello", "World!");
       DBUG_PRINT ("WARN", "<%s> <%s>", "Goodbye!");
       DBUG_PRINT ("DBUG", "<%s> <%s>");
       $msg = DBUG_PRINT ("TRICK", "one", "two", "three");
       DBUG_VOID_RETURN ();
    }

Here's what's written to your B<fish> logs.  Note that the B<kill_end_trace>
option stopped the printing of the B<END> block info after DBUG_LEAVE() was
called.  This would include any of your own B<END> blocks as well.

    >main-prog
    | args: [-a], [-b]
    | >main::some_function
    | | args: [Once], [upon], [a], [time!]
    | | INFO: <Hello> <World>
    | | WARN: <Goodbye!> <>
    | | DBUG: <%s> <%s>
    | | TRICK: one
    | <main::some_function ()
    <main-prog
    exit (0)

Now for some fun facts about the above B<fish> trace.  The WARN line had
generated a warning due to the missing 2nd value.  Which we could have trapped
if we wanted to via DBUG_TRAP_SIGNAL or DBUG_TIE_STDERR.

Since the DBUG line had no arguments it didn't interpret it as a format string.
And the TRICK line just printed "one" since it didn't include any formatting
information to process the other arguments with.  It doesn't mash them together
like S<B<print qw/one two three/, "\n";>> would have.  And $msg was set to
S<"one\n">.

 ===============================================================

=head1 EXAMPLE # 7 - What happens if you call die in your function?

    sub some_function {
       DBUG_ENTER_FUNC (@_);
       die ("Die you dirty rotten scoundrel!\n");
       DBUG_PRINT ("INFO", "Did you miss me?");
       DBUG_RETURN (@_);
    }

Here's what's written to your B<fish> logs.

    >main-prog
    | args: [-a], [-b]
    | >main::some_function
    | | args: [Once], [upon], [a], [time!]

    >Fred::Fish::DBUG::END
    | Fred::Fish::DBUG: So Long, and Thanks for All the Fish!
    | Fred::Fish::DBUG: Exit Status (255)
    <Fred::Fish::DBUG::END ()

If you want your die message also written to fish, see DBUG_TRAP_SIGNAL or
DBUG_TIE_STDERR for how to do that as well.  That's not covered here!

 ===============================================================

=head1 EXAMPLE # 8 - What happens if your die calls are trapped by eval or try?

    use Try::Tiny;
    ...
    some_function ();   # Called from your main program ...
    ...

    sub some_function {
       DBUG_ENTER_FUNC (@_);
       eval {
          die_function (1);
       };
       eval {
          help_me_die ();
       };
       try {
          die_function (2);
       };

       DBUG_PRINT ("INFO", "So are we ready to die yet?");
       die ("So die already!\n");
       DBUG_VOID_RETURN ();    # We never get here!
    }

    sub die_function {
       DBUG_ENTER_FUNC (@_);
       die ("I want to die!\n");
       DBUG_VOID_RETURN ();    # We never get here!
    }

    sub help_me_die {
       DBUG_ENTER_FUNC (@_);
       die_function (@_);
       DBUG_VOID_RETURN ();    # We never get here!
    }

See how the fish logs auto-balance themselves after each die was trapped!  Older
releases of this module couldn't do this and required the use of DBUG_CATCH() to
do this.  If used today all it would do is change the Auto-balancing message.
See the POD for more info and why it's still around.

    >main-prog
    | args: [-a], [-b]
    | >main::some_function
    | | >main::die_function
    | | | args: [1]
    | | <main::die_function   *** Auto-balancing the fish stack again after leaving an eval/try block! ***
    | | >main::help_me_die
    | | | >main::die_function
    | | | <main::die_function   *** Auto-balancing the fish stack again after leaving an eval/try block! ***
    | | <main::help_me_die   *** Auto-balancing the fish stack again after leaving an eval/try block! ***
    | | >main::die_function
    | | | args: [2]
    | | <main::die_function   *** Auto-balancing the fish stack again after leaving an eval/try block! ***
    | | INFO: So are we ready to die yet?

    >Fred::Fish::DBUG::END
    | Fred::Fish::DBUG: So Long, and Thanks for All the Fish!
    | Fred::Fish::DBUG: Exit Status (255)
    <Fred::Fish::DBUG::END ()


 ===============================================================

=head1 EXAMPLE # 9 - So it rebalances.  What if I forget to put in the RETURN?

    # Called from your main program ...
    ...
    some_function (qw /a b c/);
    some_function (qw /x y z/);
    some_function (qw /1 2 3/);
    ...

    sub some_function {
       DBUG_ENTER_FUNC (@_);
    }

See how the B<fish> logs got confused because of this.  There is no way to
auto-correct for this type of misuse of the module.  You have to figure out
yourself where the missing DBUG_RETURN call belonged!

    >main-prog
    | args: [-a], [-b]
    | >main::some_function
    | | args: [a], [b], [c]
    | | >main::some_function
    | | | args: [x], [y], [z]
    | | | >main::some_function
    | | | | args: [1], [2], [3]
    | | | <main::some_function
    exit (0)

    >Fred::Fish::DBUG::END
    | Fred::Fish::DBUG: So Long, and Thanks for All the Fish!
    <Fred::Fish::DBUG::END ()

This problem doesn't necessarily mean your code isn't working.  It just proves
you have an issue writing to B<fish>.  And you might not be able to use the
B<fish> logs to prove your code is working as expected!

But what about that last return in B<fish> before the exit?  That return was 
done by the call to DBUG_LEAVE() that was assumed by the example.

 ===============================================================

=head1 EXAMPLE # 10 - Misusing the RETURN functions ...

Please remember that this module is a collection of functions.  It can't do
a return for you.  There is a bug in this code.  Can you see it?

    ...
    my @array = some_function (qw /a b c/);
    DBUG_PRINT ("WARN", "Do you see it now?");
    ...

    sub some_function {
       DBUG_ENTER_FUNC (@_);

       # I'll leave it as an exercise on why I used BLOCK vs FUNC here!
       # Try it out yourself if you dare!
       foreach ( qw / One Two Three / ) {
          DBUG_ENTER_BLOCK ("LOOP", $_);   # Naming this foreach code block!
          DBUG_VOID_RETURN ();             # This is OK.
       }

       unless ( 0 ) {
          DBUG_ENTER_BLOCK ("NEVER");      # Naming this unless code block!
          DBUG_VOID_RETURN ();             # This is OK.
       }

       if ( 1 ) {
          DBUG_RETURN (@_);                # The bug!
       }

       DBUG_PRINT ("WARN", "Did you notice what the mistake was?");

       DBUG_RETURN (reverse @_);           # This is OK!
    }

Hopefully looking at the B<fish> trace below made it obvious what the bug was.
And this most likely represents a real logic bug in your code.  Not just a
problem writing to the B<fish> log correctly like in the previous example.

    >main-prog
    | args: [-a], [-b]
    | >main::some_function
    | | args: [a], [b], [c]
    | | >>LOOP
    | | | args: [One]
    | | <<LOOP ()
    | | >>LOOP
    | | | args: [Two]
    | | <<LOOP ()
    | | >>LOOP
    | | | args: [Three]
    | | <<LOOP ()
    | | >>NEVER
    | | <<NEVER ()
    | <main::some_function - return ([a], [b], [c])
    | WARN: Did you notice what the mistake was?
    <main-prog - return ([c], [b], [a])
    WARN: Do you see it now?
    < *** Unbalanced Returns *** Potential bug in your code!
    exit (0)

    >Fred::Fish::DBUG::END
    | Fred::Fish::DBUG: So Long, and Thanks for All the Fish!
    <Fred::Fish::DBUG::END ()

Still didn't see it?  The B<if> block should have done
S<"B<return> DBUG_RETURN(@_);">  It wasn't actually returning control to the
caller as expected!  We could have put a return before the last S<DBUG_RETURN()>
as well, but perl already assumes the last line of a function provides the
return value.

The DBUG_VOID_RETURN in the foreach and unless blocks are OK.  All it's doing
is terminating a block of code that we named.  It's not expected to do an actual
return.  I'm just treating them as virtual functions in the B<fish> logs!

I could even had done S<@a = DBUG_RETURN ($a, $b, $c, $d>) to end the foreach
loop so that I could log the progress of the loop as it cycled through the
code over and over again.  In this case the S<B<@a =>> is important, otherwise
the caller of the function dictates what gets written to B<fish>.  When we
actually want to always see the entire list.

 ===============================================================

=head1 EXAMPLE # 11 - What about the special BEGIN/END functions?

    use Fred::Fish::DBUG;
    DBUG_PUSH ($file);         # Assuming $file is already set.
    DBUG_ENTER_FUNC (@ARGV);
    DBUG_LEAVE (0);
    BEGIN {
       DBUG_ENTER_FUNC (@_);
       DBUG_VOID_RETURN ();
    }
    END {
       DBUG_ENTER_FUNC (@_);
       DBUG_VOID_RETURN ();
    }

Gives the following B<fish> log.

    >main-prog
    | args: [-a], [-b]
    <main-prog
    exit (0)

    >main::END
    <main::END

    >Fred::Fish::DBUG::END
    | Fred::Fish::DBUG: So Long, and Thanks for All the Fish!
    <Fred::Fish::DBUG::END ()

What happened to the tracing of the BEGIN block of code?

BEGIN was called before you called DBUG_PUSH(), so it wasn't tracked in the
B<fish> log.  You'd need to call DBUG_PUSH() in the BEGIN block itself if you'd
like B<fish> to trace your BEGIN logic.

And speaking of BEGIN, never, ever call DBUG_TRAP_SIGNAL in a BEGIN block.  You
can get really strange behavior if you have syntax errors in your code and these
error messages and warnings get trapped by L<Fred::Fish::DBUG>.  The only reason
to call it in a BEGIN block is to stress test L<Fred::Fish::DBUG> itself.

As a final note, except for AUTOLOAD, these and the other special Perl functions
have no caller, arguments or return values.  They are called by Perl itself and
not by your code.  Like BEGIN at compile time and END when Perl is shutting down
your code.

 ===============================================================

=head1 EXAMPLE # 12 - Some not so obvious surprises ...

Or maybe not if you've been paying close attention.

For all examples below assume:

    sub some_function {
       DBUG_ENTER_FUNC (@_);
       DBUG_RETURN (@_);
    }

 ********************

    if ( some_function ( qw /1 0 -1/ ) ) { ... }
    if ( some_function ( qw /1 0 -1/ ) == 0 ) { ... }

The interesting part, both calls log the same return value to B<fish>.

   | <main::some_function - return ([1])

It was smart enough to tell it to return just the first value instead of a list
of values.

 ********************

   foreach ( some_function ( qw /1 0 -1/ ) ) { ... }

The interesting part of the B<fish> log:

   | <main::some_function - return ([1], [0], [-1])

Notice it was smart enough to return a list of values.  And the loop had three
iterations.

 ********************

   while ( some_function ( qw /1 0 -1/ ) ) { ... }

The interesting part of the B<fish> log:

   | <main::some_function - return ([1])

It was smart enough to tell it to return just the first value instead of a list
of values.  But you ended up in an infinite loop!

 ********************

    $val = ( some_function ( qw / a b c / ) )[1];

The interesting part of the B<fish> log:

   | <main::some_function - return ([a], [b], [c])

And B<$val> gets set to "b"!

 ********************

    my $x = call_me ( some_function ( qw /a b c/ ) );

The interesting part of the B<fish> log:

   | <main::some_function - return ([a], [b], [c])
   | >main::call_me
   | | args: [a], [b], [c]
   | <main::call_me - return ([a])

Notice that B<some_function> returned all it's return values as arguments to
B<call_me>!

 ********************

Which leads us to this final surprising result.  Which should be obvious, but
usually isn't at first glance.

   call_me (qw /a b c/);
   $x = call_me (qw /a b c/);
   @l = call_me (qw /a b c/);

   sub call_me {
      DBUG_ENTER_FUNC (@_);
      DBUG_RETURN ( some_function (@_) );
   }

The call to B<some_function> will always return in list mode!  No matter what it
finally decides to return for B<call_me>!  It doesn't inherit the I<wantarray>
status!

   | | <main::some_function - return ([a], [b], [c])

It treats DBUG_RETURN() as just another function call!  Which can be a bit
counterintuitive at times!  So if you wanted B<some_function> to inherit the
I<wantarray> status of B<call_me>, you'd have to do something like this.

   sub call_me {
      DBUG_ENTER_FUNC (@_);
      if ( wantarray ) {
         return DBUG_RETURN (some_function (@_));
      } elsif ( defined  wantarray ) {
         return DBUG_RETURN (scalar some_function (@_));
      } else {
         some_function (@_);
         return DBUG_VOID_RETURN ();
      }
   }

In this example B<some_function> would write to B<fish> one of the following 3
cases, depending on how B<call_me> was called.

   | | <main::some_function - return ([a], [b], [c])
   | | <main::some_function - return ([a])
   | | <main::some_function - return ()

In most cases this distinction makes no difference, it can just be a bit of a
surprise.

But what if B<some_function> did some monkey business like B<localtime> does?
Where list mode returns a list of integers representing the various parts of the
date/time.  While in scalar mode it returns the entire date/time as a single
string.  Then you'd have to implement the work around shown above if you didn't
want to return that 1st integer in scalar mode.

See DBUG_RETURN_SPECIAL() if you'd like to implement something like B<localtime>
yourself and hide the complex return logic.  All it does is allow you to
easily customize what's returned in scalar mode.

 ===============================================================

=head1 IN CONCLUSION

This should help get you started using this module.  Just remember that only the
call to DBUG_PUSH was required.  Everything else is optional!  You can even
trace just some functions, you don't have to trace them all.

There were many features not covered by this tutorial that you could find
useful.

Such as:

   * Trapping signals for logging to fish.
   * Trapping STDOUT/STDERR for logging to fish.
   * Masking passwords and other sensitive arguments to your function.
   * Masking passwords and other sensitive return values.
   * Temporarily pausing fish's output when fish just gets too verbose.
   * Filtering your fish output.
   * Using color in your fish logs.
   * Handling multi-threading programs in a single fish log.
   * Handling multi-processing in a single fish log.
   * Auto-deleting your fish file if your program exits with status zero,
     and keeping it for all other exit status codes.  So you can easily
     detect and debug your rare failure cases without filling up your disk
     with logs on success.
   * Admin funcs like ASSERT, ACTIVE, and EXECUTE.
   * And much, much more ...

This is only the beginning!  :)


=head1 COPYRIGHT

Copyright (c) 2019 - 2024 Curtis Leach.  All rights reserved.

This program is free software.  You can redistribute it and/or modify it under
the same terms as Perl itself.


=head1 SEE ALSO

L<Fred::Fish::DBUG> - The module we are talking about in this POD.  The one
you should be using.

L<Fred::Fish::DBUG::ON> - Does the actual work when fish is enabled.

L<Fred::Fish::DBUG::OFF> - The stub version of the ON module.

L<Fred::Fish::DBUG::TIE> - Allows you to trap and log STDOUT/STDERR to B<fish>.

L<Fred::Fish::DBUG::Signal> - Allows you to trap and log signals to B<fish>.

L<Fred::Fish::DBUG::SignalKilller> - Allows you to implement action
DBUG_SIG_ACTION_LOG for B<die>.  Really dangerous to use.  Will break most
code bases.

=cut

# ==============================================================
#required if module is included w/ require command;
1;
