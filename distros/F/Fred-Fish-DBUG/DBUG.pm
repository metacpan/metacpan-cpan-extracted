###
###  Copyright (c) 2007 - 2024 Curtis Leach.  All rights reserved.
###
###  Based on the Fred Fish DBUG macros in C/C++.
###  This Algorithm is in the public domain!
###
###  Module: Fred::Fish::DBUG

=head1 NAME

Fred::Fish::DBUG - Fred Fish library for Perl

=head1 SYNOPSIS  (Default)

 use Fred::Fish::DBUG qw / on /;
   or 
 require Fred::Fish::DBUG;
 Fred::Fish::DBUG::import ( qw / on / );

=head1 DESCRIPTION

F<Fred::Fish::DBUG> is a pure Perl implementation of the C/C++ Fred Fish macro
libraries.  While in C/C++ this library is implemented mostly via macros, in
Perl this library is implemented using true function calls.   It has also been
slightly modified to address Perlish features over C/C++ ones.  This can make
using some features a bit strange compared to C/C++.  But the basic concepts
are the same.  The most powerful feature being able to dynamically turn B<fish>
logging on and off.

But due to this module being implemented as functions, there can be significant
overhead when using this module.  So see the next section on how to mitigate
this overhead.

=head1 ELIMINATING THE OVERHEAD

This can be as simple as changing B<qw /on/> to B<qw /off/>.  This turns most
DBUG calls into calls to stubs that do very little.  Dropping the current file
from any fish logging.

But having to modify your code right before moving it into production, or
modifying it to troubleshoot, can make anyone nervous.  So I provided ways to
dynamically do this for you.

  # Called from package my::special::module ... (off by default)
  use Fred::Fish::DBUG qw / on_if_set  my_special_module_flag /;

  Is equivalant to:
  BEGIN { require Fred::Fish::DBUG;
          my @opt = $ENV{my_special_module_flag} ? qw / ON / : qw / OFF /;
          Fred::Fish::DBUG->import ( @opt );
	}

Where if B<$ENV{my_special_module_flag}> evaluates to true you have B<fish>
logging available.  Otherwise it isn't.  Chose a name for the environment
variable as appropriate to your situation.

Or you can do the reverse where it's on by default:

  use Fred::Fish::DBUG qw / off_if_set  my_special_module_flag /;

In summary all the options are:

   use Fred::Fish::DBUG qw / on /;
   use Fred::Fish::DBUG qw / off /;
   use Fred::Fish::DBUG qw / on_if_set  EnvVar /;
   use Fred::Fish::DBUG qw / off_if_set EnvVar /;
   use Fred::Fish::DBUG;         # Same as if qw / on / was used.

   # While enforcing a minimum version ...
   use Fred::Fish::DBUG 2.04 qw / on /;

=head1 TRAPPING SIGNALS IN FISH

As an extension to the Fred Fish library, this module allows the trapping and
logging to B<fish> of all trappable signals for your OS.  This list of signals
varies per OS.  But the most common two being B<__DIE__> and B<__WARN__>.

But in order to trace these signals you must first ask B<fish> to do so by
by first sourcing in F<Fred::Fish::DBUG::Signal>, and then calling
L<DBUG_TRAP_SIGNAL>.  See that module for more details.  You don't have to
use that module, but it can make thigs easier if you do.

Just be aware that both B<__DIE__> and B<__WARN__> signals can be thrown
during Perl's parsing phase of your code.  So care must be taken if you try
to trap these signals in a BEGIN block.  Since if set in BEGIN these traps
may end up interfering with your attempts to debug your code.

=head1 TRAPPING STDOUT AND STDERR IN FISH

Another extension to the Fred Fish libary allowing you to trap all prints to
STDOUT and/or STDERR to also appear in your B<fish> logs.  Implemented as a
wrapper to Perl's "B<tie>" feature against the SDTOUT and STDERR file handles.

Very useful for putting prints from your program or other modules into context
in your fish logs.  Just be aware that you may have only one B<tie> per file
handle.  But if your code does require ties to work, this module provides a
way to coexist.

See F<Fred::Fish::DBUG::TIE> for more details on how to enable this feature.

=head1 FISH FOR MULTI-THREADED PERL PROGRAMS

This module should be thread-safe as long as Perl's I<print> command is
thread-safe.  If threads are used, there are two ways to use this module.

The first way is call DBUG_PUSH($file, multi=>1) in the main process and then
spawn your threads.  This will cause all threads to write to the same B<fish>
file as your main program.  But you'll have to use a tool such as B<grep> in
order to be able to trace the logic of individual threads.  Thread 0 is the main
process.  If you don't use the B<multi> option, your B<fish> log will be
unusable since you'll be unable to tell which thread wrote each entry in your
log.

The second way is to not call DBUG_PUSH() in the main thread until after you
spawn all your threads.  In this case you can't share the same B<fish> file
name.  Each thread should call DBUG_PUSH($file) using a unique file name for
each thread's B<fish> log.  Using option B<multi> is optional in this case,
but still recommended.

But what happens with the B<second> option if you reuse the same filename
between threads?  In that case this module is B<not> thread-safe!  Each thread
can step on each other.  You can limit the impact with a creative combination
of options to DBUG_PUSH(), but you can't reliably remove all the corruption
and dropped lines in the shared B<fish> logs.  And your work around may
break in future releases of this module.

As a reminder, when the main process (I<thread # 0>) terminates, this causes
all the child threads to terminate as well.  Even if they are still busy.
Also child threads do not normally call I<BEGIN> and/or I<END> blocks of code!
And all threads share the same PID.

=head1 FISH FOR MULTI-PROCESS PERL PROGRAMS

This is when you spawn a child process using B<fork>.  In this case all
processes have a unique PID and each child process will call their own I<END>
blocks.  But otherwise it follows the same B<fish> rules as multi-threading.

When the parent process terminates, it allows any running child process to
finish it's work and they can still write to B<fish>.

To turn on fish for multi-process use DBUG_PUSH($file, multi=>1) as well.

=head1 FURTHER INFORMATION

Not all Perl implementations support mutli-threading and/or multi-processing.
So if you are not using multi-threading or multi-processing, I recommend
I<not> using the B<multi> option.

=head1 USING GOTO STATEMENTS

Using a B<goto> can cause B<fish> issues where the return statements get out
of sync with the proper function entry points in your B<fish> logs.  This is
because calls like B<goto &MyPackage::MyFunction;> jump to MyFunction's entry
point, and removes the function using B<goto> from Perl's stack as if it was
never there.

Currently the only fix for this is to not use B<DBUG_ENTER_(FUNC|BLOCK)> and
the corresponding B<DBUG_RETURN> methods in functions that use B<goto>.
Limit yourself to calls to B<DBUG_PRINT> in those methods instead.

Your other choice is to reorganize your code to avoid using the B<goto>
statement in the first place.

A common place you'd see a B<goto> is if you used the I<AUTOLOAD> function.
But even there, there are alternatives to using the B<goto> if you want
clean B<fish> logging.

=head1 USING THIS MODULE IN A CPAN MODULE

When you upload a module using B<fish> to CPAN, you probably don't want your
code trace being dumped to an end user's B<fish> logs by default.  So I
recommend doing the following in your code so that "make test" will still have
B<fish> turned on, while normal usage won't trace in B<fish>.

  use Fred::Fish::DBUG qw / on_if_set  my_special_module_flag /;

For an explination on how this works, reread the POD above.

=head1 FUNCTIONS

=over 4

=cut 

package Fred::Fish::DBUG;

use strict;
use warnings;

use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
use Exporter;

$VERSION = "2.04";
@ISA = qw( Exporter );

# ------------------------------------------------------------------------------
# When this module inherits from Fred::Fish::DBBUG::ON or Fred::Fish::DBUG::OFF,
# the special var @EXPORT will contain both functions and constant vars after
# import() is called.
#
# So "use Fred::Fish::DBUG;"    Works just fine.
#
# require Fred::Fish::DBUG;     Nothing available yet.
# Fred::Fish::DBUG->import ();  Makes everything available for use.
#
# Everything exported for public use will always be named in upper case!
# ------------------------------------------------------------------------------
# The others were written to help the t/*.t programs validate that this module
# worked as advertised.  Exposing them would just polute Perl's name space and
# perhaps confuse people when they don't always work.
# ------------------------------------------------------------------------------

@EXPORT = qw( );
@EXPORT_OK = qw( );

# Tells which module we are acting on.
# Only set during the call to import()!
# Must be a hash to allow for mixing & matching modes between files!
my %global_fish_module;

# So we can dynamically swap between
# Fred::Fish::DBUG::ON & Fred::Fish::DBUG::OFF
# Is automatically called in most cases after BEGIN is called.
sub import
{
   # Assuming:   Fred::Fish::DBUG->import ()
   my $pkg = shift;
   my $mode = shift;
   my $env_var = shift;

   # Fred::Fish::DBUG::import () after all.
   if ( $pkg ne __PACKAGE__ ) {
      $env_var = $mode;
      $mode = $pkg;
      $pkg = __PACKAGE__;
   }

   # print STDERR "use $pkg qw ($mode $env_var)\n";

   my $umode = $mode ? uc ($mode) : "ON";

   my $on_flag;

   if ( $umode eq "ON" ) {
      $on_flag = 1;

   } elsif ( $umode eq "OFF" ) {
      $on_flag = 0;

   } elsif ( $umode eq "ON_IF_SET" || $umode eq "OFF_IF_SET" ) {
      if (! defined $env_var ) {
         die ( "\nMissing required environment variable to use when '$mode' is used!\n",
                 "Syntax:  use $pkg qw / $mode  env_var_name /",
		 "\n\n" );
      }
      my $set = ( exists $ENV{$env_var} && $ENV{$env_var} ) ? 1 : 0;
      if ( $umode eq "ON_IF_SET" ) {
         $on_flag = $set;
      } else {
         $on_flag = $set ? 0 : 1;
      }

   } else {
      my $env = (defined $env_var) ? $env_var : "";
      die ( "\nuse $pkg qw / $mode $env /; --- Unknown module option!\n\n" );
   }

   my @imports;
   my $fish_module = __PACKAGE__ . "::";

   my $minVer = 2.04;
   if ( $on_flag ) {
      $fish_module .= "ON";
      require Fred::Fish::DBUG::ON;
      Fred::Fish::DBUG::ON->VERSION ($minVer);
      @imports = @Fred::Fish::DBUG::ON::EXPORT;
   } else {
      $fish_module .= "OFF";
      require Fred::Fish::DBUG::OFF;
      Fred::Fish::DBUG::OFF->VERSION ($minVer);
      @imports = @Fred::Fish::DBUG::OFF::EXPORT;
   }

   # Get the list of functions from the appropriate module.
   push (@EXPORT, @imports);

   # print STDERR "\n", join (", ", @EXPORT), "\n\n";

   # Make everything loaded public ...
   my $caller = caller();
   ${fish_module}->export ($caller);

   # Determine which file the call to import happened in!
   my $which = _find_key ();

   # print STDERR "\n -------> File: $which\n\n";   _print_trace ();

   $global_fish_module{$which} = $fish_module;

   return;
}

# The key is the filename of the program that did "use Fred::Fish::DBUG"
# So we can say which module we inherited from this time.
sub _find_key
{
   my $idx = 1;

   my $key = (caller ($idx))[1];
   while ( defined $key && $key =~ m/^[(]eval/ ) {
      $key = (caller (++$idx))[1];
   }
   return ( $key );
}

# Used to debug _find_key () ...
sub _print_trace
{
   my $idx = 0;
   my ($pkg, $f, $s) = (caller ($idx))[0, 1, 3];
   print STDERR "\n$idx:  $pkg --> $f --> $s\n";
   while ( $pkg ) {
      ($pkg, $f, $s) = (caller (++$idx))[0, 1, 3];
      print STDERR "$idx:  $pkg --> $f --> $s\n"  if (defined $pkg);
   }
   print STDERR "\n";
   return;
}

# ==============================================================================
# Start of Helper methods designed to help test out this module's functionality.
# ==============================================================================

# ==============================================================
# Not exposed on purpose, so they won't polute the naming space!
# Or have people trying to use them!
# ==============================================================
# Undocumented helper functions exclusively for use by the "t/*.t" programs.
# Not intended for use by anyone else.
# So subject to change without notice!
# They are used to help these test programs validate that this module is working
# as expected without having to manually examine the fish logs for everything!!
# But despite everything, some manual checks will always be needed!
# ==============================================================
# Most of these test functions in Fred::Fish::DBUG:OFF are broken and do not
# work there unless you lie and use the $hint arguments!  So it's another
# reason not to use them in your own code base!
# In fact many of these test functions in this module are broken as well if fish
# was turned off or paused when the measured event happened.
# ==============================================================
# NOTE: Be carefull how they are called in the t/*.t programs.
#       Always call as Fred::Fish::DBUG::func();
#       never as Fred::Fish::DBUG->func();
# ==============================================================

# This is the only method that knows about "other" instances ...
sub dbug_module_used
{
   my $key = shift;    # Pass __FILE__ sourcing in this module ...

   # If not provided determine where func was called from.
   unless ( defined $key ) {
      my $idx = 0;
      my ($caller_pkg, $caller_file, $this_func) = (caller ($idx))[0, 1, 3];
      # print STDERR "\n$idx:  $caller_pkg --> $caller_file --> $this_func\n";
      $key = $caller_file;
   }

   my $fish_module = _find_module ($key);
   return ( wantarray ? ($fish_module, $key) : $fish_module );
}

sub _find_module
{
   my $key = shift;
   my $mod = $global_fish_module{$key} || 'Fred::Fish::DBUG::Unknown';
   return ( $mod );
}

# ==================================================================
# The remaining functions only work against the "current" instance!
# ==================================================================

# The current FISH function on the fish stack ...
sub dbug_func_name
{
   my $hint = shift;    # Only used in OFF.pm ...

   my ($pkg, $file, $this_func) = (caller (0))[0, 1, 3];
   my $fish_module = _find_module ($file);

   my $func = ${fish_module}->can ('dbug_func_name');
   return ( $func->( $hint ) );   # A name ...
}

# Number of fish functions on the stack
# This one is used internally as well.
sub dbug_level
{
   my $hint = shift;    # Only used in OFF.pm ...

   my ($pkg, $file, $this_func) = (caller (0))[0, 1, 3];
   my $fish_module = _find_module ($file);

   my $func = ${fish_module}->can ('dbug_level');
   if (! defined $func) { return(-100); }   # Hack.

   return ( $func->( $hint ) );   # A count ...
}

# This value is set via the calls to
#     DBUG_RETURN() / DBUG_VOID_RETURN() / DBUG_RETURN_SPECIAL().
# It can only be non-zero if DBUG_MASK() was called 1st and only for
# DBUG_RETURN().  If fish is turned off it will be -1.  Otherwise
# it will be a count of the masked values in fish!
# In all other situations it will return zero!

sub dbug_mask_return_counts
{
   my $hint = shift;    # Only used in OFF.pm ...

   my ($pkg, $file, $this_func) = (caller (0))[0, 1, 3];
   my $fish_module = _find_module ($file);

   my $func = ${fish_module}->can ('dbug_mask_return_counts');
   return ( $func->( $hint ) );   # A count ...
}

# This value is set via the last call to DBUG_ENTER_FUNC() / DBUG_ENTER_BLOCK()
# when it prints it's masked arguments to fish.  If the write to fish doesn't
# happen the count will be -1!
# To decide what needs to be masked, you must call DBUG_MASK_NEXT_FUNC_CALL() 1st!
# Otherwise it will always be zero!

sub dbug_mask_argument_counts
{
   my $hint = shift;    # Only used in OFF.pm ...

   my ($pkg, $file, $this_func) = (caller (0))[0, 1, 3];
   my $fish_module = _find_module ($file);

   my $func = ${fish_module}->can ('dbug_mask_argument_counts');
   return ( $func->( $hint ) );   # A count ...
}

# These 3 actually work in Fred::Fish::DBUG::OFF as well!
sub dbug_threads_supported
{
   my ($pkg, $file, $this_func) = (caller (0))[0, 1, 3];
   my $fish_module = _find_module ($file);

   my $func = ${fish_module}->can ('dbug_threads_supported');
   return ( $func->() );   # A boolean result ... 1/0
}

sub dbug_fork_supported
{
   my ($pkg, $file, $this_func) = (caller (0))[0, 1, 3];
   my $fish_module = _find_module ($file);

   my $func = ${fish_module}->can ('dbug_fork_supported');
   return ( $func->() );   # A boolean result ... 1/0
}

sub dbug_time_hires_supported
{
   my ($pkg, $file, $this_func) = (caller (0))[0, 1, 3];
   my $fish_module = _find_module ($file);

   my $func = ${fish_module}->can ('dbug_time_hires_supported');
   return ( $func->() );   # A boolean result ... 1/0
}

# Internal functions some tests sometimes need access to ...
sub dbug_called_by
{
   my ($pkg, $file, $this_func) = (caller (0))[0, 1, 3];
   my $fish_module = _find_module ($file);

   my $func = ${fish_module}->can ('_dbug_called_by');
   return ( $func->( @_ ) );   # A name ...
}

sub dbug_indent
{
   my $msg = shift;
   $msg = "" unless (defined $msg);

   my ($pkg, $file, $this_func) = (caller (0))[0, 1, 3];
   my $fish_module = _find_module ($file);

   my $func = ${fish_module}->can ('_indent');
   return ($msg)  unless (defined $func);
   return ( $func->( $msg, @_ ) );   # A string ...
}

sub dbug_stack_trace
{
   my $msg = shift || "";

   my ($pkg, $file, $this_func) = (caller (0))[0, 1, 3];
   my $fish_module = _find_module ($file);

   my $func = ${fish_module}->can ('_dbug_stack_trace');
   return (0)  unless (defined $func);

   my $cnt = $func->(1, $msg);
   return ($cnt);   # Count of eval levels detected.
}

# ------------------------------------------------------------------------------
# Fred::Fish::DBUG POD
# 
# I have tried to keep the POD functions in a meaningfull order.  And keep the
# functions in Fred::Fish::DBUG:ON  &  Fred::Fish::DBUG::OFF in the same order.
# Hopefully this should make it easier to learn how to use & maintain this module.
#
# There is no actual code below this line, only POD text!
# ------------------------------------------------------------------------------

=item DBUG_PUSH ( [$file [, %opts]] )

Calling this function turns logging on so that all future DBUG B<fish> calls are
written to the requested file.  Failure to call this function results in nothing
being written to the B<fish> logs.  Currently there is no way to turn B<fish>
back off again except by aborting the program.  But there are ways to turn
some of the logging off.

You are expected to provide a filename to write the fish logs to.  If
that file already exists, this function will recreate the B<fish> file and
write as its first log message that this happened.  By default, the B<fish>
log's file permissions allow anyone to read the log file no matter the current
I<umask> settings.

But if you fail to provide a filename, B<fish> will instead be written to
I<STDERR>.  You may also use an open file handle or I<GLOB> reference instead
of a filename and B<fish> would be written there instead.

The options hash may be passed by either reference or value.  Either way works.
Most options are ignored unless you also gave it a filename to open.
Most option's value is a flag telling if it's turned on (1) or off (0), and
most options default to off unless otherwise specified.  The valid options are:

=over 4

B<append> - Open an old B<fish> log in append mode instead of creating a new
one.

B<autoflush> - Turn autoflush on/off.  By default it's turned on!

B<autoopen> - Turn auto-open on/off.  Causes each call to a B<fish> function to
auto-reopen the B<fish> log, write out its message, and then close the B<fish>
file again.

B<off> - If set, treat as if I<DBUG_PUSH> was never called!  (IE: Fish is off.)
It overrides all other options.

B<filter> - See I<DBUG_FILTER> for more details.

B<kill_end_trace> - Suppress the B<fish> logging for the Perl B<END> blocks.

B<who_called> - Adds I<function/file/line #> to the end of the enter function
block.  So you can locate the code making the call.  Also added to the end of
I<DBUG_PRINT> messages.

B<multi> - Turns on/off writing process ownership info to the start of each line
of the B<fish> log.  For multi-thread programs this is B<PID>-B<thread-id>.
Ex: 252345-0 is the main process && 252345-4 is the 4th thread spawned by the
process.  But if it's a forked process it would be B<PID>/B<2-digits>.
Ex: 252345/00 is the main process.  And 536435/35 is one of its forked child
processes.  There are no sequential ids for forked processes, nor is the 2-digit
code guaranteed to be unique.

B<limit> - If your program is multi-threaded or muli-process, use this option to
limit what gets written to B<fish>.  B<1> - Limit B<fish> to the parent process.
B<0> - Write everything (default).  B<-1> - Limit B<fish> to the child processes.

B<chmod> - Override the default B<fish> file permissions.  Default is B<0644>.
It ignores the current I<umask> settings!

B<before> - Normally the 1st call to I<DBUG_ENTER_FUNC> is after the call to
I<DBUG_PUSH>, but set to B<on> if you've already called it.  But you will lose
printing the function arguments if you do it this way.

B<strip> - Strip off the module name for I<DBUG_ENTER_FUNC> and the various
return methods.  So I<main::abc> becomes I<abc> in B<fish>.

B<delay> - Number of seconds to sleep after calling I<DBUG_PRINT> in your code.
The delay only happens if the write to B<fish> actually happens.
If I<Time::HiRes> is installed you can sleep for fractions of a second.  But if
it isn't installed your time will be truncated.  IE: 0.5 becomes 0.

B<elapsed> - Prints the elapsed time inside the function once any DBUG return
function is called.  If I<Time::HiRes> is installed it tracks to fractions of a
second.  Otherwise it's whole seconds only.

B<keep> - (1/0/code ref) - (1) Keep your B<fish> log only if your program exits
with a non-zero exit status. (0) Always keep your B<fish> log (default).
Otherwise it calls your function with the exit status as it's single argument.
It's expected to return B<1> to keep the B<fish> log or B<0> to toss it.  This
code ref is only called if there is a B<fish> log to potentially remove.

B<no_addresses> - (1/0) - (0) Default, print variable reference addresses like
S<HASH(0x202f4028)> which change between runs.  (1) Suppress addresses so shows
up like S<HASN(001)> so it's easier to compare fish files between runs.  Only
works for arguments and return values.

B<allow_utf8> - Writes to B<fish> in UTF-8 mode.  Use if you get warnings
about writing S<'Wide character in print'> to B<fish>.

=back

=cut

# ==============================================================

=item DBUG_POP ( )

Not yet implemented.

=cut

# ==============================================================

=item DBUG_ENTER_FUNC ( [@arguments] )

Its expected to be called whenever you enter a function.  You pass all the
arguments from the calling function to this one (B<@_>).  It automatically
knows the calling function without having to be told what it is.

To keep things in the B<fish> logs balanced, it expects you to call one of the
I<DBUG_RETURN> variant methods when exiting your function!

This function also works when called inside named blocks such as B<eval> blocks
or even try/catch blocks.

It returns the name of the calling function.  In rare cases this name can be
useful.

See I<DBUG_MASK_NEXT_FUNC_CALL> should you need to mask any arguments!

=cut

# ==============================================================

=item DBUG_ENTER_BLOCK ( $name[, @arguments] )

Similar to I<DBUG_ENTER_FUNC> except that it deals with I<unnamed> blocks of
code.  Or if you wish to call a particular function a different name in the
B<fish> logs.

It usually expects you to call I<DBUG_VOID_RETURN> when the block goes out of
scope to keep the B<fish> logs balanced.  But nothing prevents you from using
one of the other return variants instead.

It returns the name of the code block you used.  In rare cases this name can
be useful.

=cut

# ==============================================================

=item DBUG_PRINT ( $tag, $fmt [, $val1 [, $val2 [, ...]]] )

This function writes the requested message to the active B<fish> log.

The B<$tag> argument is a text identifier that will be used to 'tag' the line
being printed out and enforce any requested filtering and/or coloring.

The remaining arguments are the same as what's passed to L<printf(1)> if given a
B<$fmt> and one or more values.  But if no values are given then it's treated
as a regular call to L<print>.

If the formatted message should be terminated by multiple B<\n>, then it will
be truncated to a single B<\n>.  All trailing whitespace on each line will be
removed as well.

It returns the formatted message written to fish and it will always end in
B<\n>.  This message doesn't include the I<$tag> or the optional caller info
if the I<who_called> option was used by B<DBUG_PUSH>.

This message is returned even if fish is currently turned off!

B<NOTE>: If this request resulted in a write to B<fish>, and you asked for a
B<delay> in I<DBUG_PUSH>, this function will sleep the requested number of
seconds before returning control to you.  If no write, then no delay!

=cut

# ==============================================================

=item DBUG_RETURN ( ... )

It takes the parameter(s) passed as arguments and uses them as the return
values to the calling function similar to how perl's return command works.
Except that it also writes what is being returned to B<fish>.  Since this is a
function, care should be taken if called from the middle of your function's
code.  In that case use the syntax:
S<"return DBUG_RETURN( value1 [, value2 [, ...]] );">.

It uses Perl's B<wantarray> feature to determine what to print to B<fish> and
return to the calling function.  IE scalar mode (only the 1st value) or list
mode (all the values in the list).  Which is not quite what many perl developers
might expect.

EX: return (wantarray ? (value1, value2, ...) : value1);

If I<DBUG_MASK> was called, it will mask the appropriate return value(s)
as:  B<S<E<lt>******E<gt>>>.

=cut

# ==============================================================

=item DBUG_ARRAY_RETURN ( @args )

A variant of S<"DBUG_RETURN()"> that behaves the same as perl does natively when
returning a list to a scalar.  IE it returns the # of elements in the @args
array.

It always assumes @args is a list, even when provided a single scalar value.

=cut

# ==============================================================

=item DBUG_VOID_RETURN ( )

Terminates the current block of B<fish> code.  It doesn't return any value back
to the calling function.

=cut

# ==============================================================

=item DBUG_RETURN_SPECIAL ( $scalar, @array )

This I<DBUG_RETURN> variant allows you to differentiate between what to return
when your function is called in a scalar context vs an array context vs void
context.

If called in an array context, the return value is equivalent to
S<I<DBUG_RETURN (@array)>.>

If called in a scalar context, the return value is equivalent to
S<I<DBUG_RETURN ($scalar)>.>  With a few special case exceptions.

=over

Special case # 1: If I<$scalar> is set to the predefined constant value
B<DBUG_SPECIAL_ARRAYREF>, it returns the equivalent to
S<I<DBUG_RETURN (\@array)>.> Feel free to modify the contents of the referenced
array, it can't hurt anything.  It's a copy.

Special case # 2: If I<$scalar> is set to the predefined constant value
B<DBUG_SPECIAL_COUNT>, it returns the equivalent to
S<I<DBUG_RETURN (scalar (@array))>,> the number of elements in the array.

Special case # 3: If I<$scalar> is set to the predefined constant value
B<DBUG_SPECIAL_LAST>, it returns the equivalent to
S<I<DBUG_RETURN ($array[-1])>,> the last element in the array.

Special case # 4: If I<$scalar> is a CODE ref, it returns the equivalent to
S<I<DBUG_RETURN (scalar($scalar-E<gt>(@array)))>.>

=back

If called in a void context, the return value is equivalent to
S<I<DBUG_VOID_RETURN ()>.>  But in some cases it will print additional
information to B<fish>.  But it will B<never> call the CODE reference
when called in void context.

=cut

# ==============================================================

=item DBUG_LEAVE ( [$status] )

This function terminates your program with a call to I<exit()>.  It expects a
numeric argument to use as the program's I<$status> code, but will default to
zero if it's missing.  It is considered the final return of your program.

Only module B<END> and B<DESTROY> blocks can be logged after this function is
called as Perl cleans up after itself, unless you turned this feature off with
option B<kill_end_trace> when B<fish> was first enabled.

=cut

# ==============================================================

=item DBUG_CATCH ( )

This function rebalances the B<fish> function trace after trapping B<die> from
an B<eval> or B<try> code block.

If using B<eval>, place this function call inside the S<B<if ($@) { }>> section
after each B<eval> block of code.

If using B<try>/B<catch>, place this function inside the B<catch> block instead.

But if you don't call this function, the B<fish> logs will still try to auto
rebalance itself.  But you loose why this happens and it I<may> mischaracterize
why it did so in the B<fish> logs.  It implies you trapped an B<eval> or B<try>
event.

So calling this function is in most cases optional.  One of the few times it
could be considered required is if you used the B<elapsed> option to
I<DBUG_PUSH>.  In that case failure to immediately call it could affect your
timings when the rebalancing gets deferred until the next DBUG call.

=cut

# ==============================================================

=item DBUG_PAUSE ( )

Temporarily turns B<fish> off until the pause request goes out of scope.  This
allows you to conditionally disable B<fish> for particularly verbose blocks of
code or any other reason you choose.

The scope of the pause is defined as the previous call to a I<DBUG_ENTER>
function variant and it's coresponding call to a I<DBUG_RETURN> variant.

While the pause is active, calling it again does nothing.

=cut

# ==============================================================

=item DBUG_MASK ( @offsets )

Sometimes the return value(s) returned by I<DBUG_RETURN> and/or it's variants
contain sensitive data that you wouldn't want to see recorded in a B<fish> file.
Such as user names and passwords.  So we need a way to mask these values without
the programmer having to jump through too many hoops to do so.

So this function tells the I<DBUG_RETURN> call that goes with the most recent
I<DBUG_ENTER> variant which of its return values to mask.  So if you have
multiple exit points to the current function, this one call handles the masking
for them all.

The I<@offsets> array consists of 1 or more integers representing the offset to
expected return values.  Or the special case of B<-1> to say mask all return
values.

So I<DBUG_MASK(0,2)> would cause I<DBUG_RETURN> to mask the 1st and 3rd elements
being returned.

If you pass a non-numeric value, it will assume that the return value is a hash
and that you are providing a hash key who's value needs to be masked.

So if you say I<DBUG_MASK("TWO", "THREE")>, it might return
B<S<[TWO], [E<lt>*****E<gt>], [ONE], [1]>>.  And since there is no key "THREE"
in your hash, nothing was masked for it.  And as you can see, we only mask the
value, not the key itself!  The key is case sensitive, so "two" wouldn't have
matched anything.  Also remember that the order of the keys returned is random,
so pure numeric offsets wouldn't give you the desired results.

We could have combined both examples with I<DBUG_MASK(0,2,"TWO","THREE")>.

=cut

# ==============================================================

=item DBUG_MASK_NEXT_FUNC_CALL ( @offsets )

Sometimes some arguments passed to I<DBUG_ENTER_FUNC> contain sensitive data
that you wouldn't want to see recorded in a B<fish> file.  Such as user names
and passwords.  So we need a way to mask these values without the programmer
having to jump through too many hoops to do so.

So this function tells the next I<DBUG_ENTER_FUNC> or I<DBUG_ENTER_BLOCK> call
which arguments are sensitive.  If you call it multiple times before the next
time the enter function is called it will only remember the last time called!

The I<@offsets> array consists of 1 or more integers representing the offset to
expected arguments.  Or the special case of B<-1> to say mask all arguments
passed.  Any other negative value will be ignored.

But should any offset be non-numeric, it assumes one of the arguments was a
hash I<passed by value> with that string as it's key.  And so it will mask the
next value after it if the key exists.  Needed since the order of hash keys is
random.  Also in this case the hash key is case insensitive.  So "abc" and "ABC"
represent the same hash key.

So I<DBUG_MASK_NEXT_FUNCT_CALL(0,2,"password")> would cause I<DBUG_ENTER_FUNC>
to mask the 1st and 3rd elements passed to it as well as the next argument
after the "password" key.

Any invalid offset value will be silently ignored.

=cut

# ==============================================================

=item DBUG_FILTER ( [$level] )

This function allows you to filter out unwanted messages being written to
B<fish>.  This is controlled by the value of I<$level> being passed to
this method.  If you never call this method, by default you'll get
everything.

If you call it with no I<$level> provided, the current level will remain
unchanged!

It returns up to two values: (old_level, new_level)

The old_level may be -1 if it was previously using custom filtering.

The valid levels are defined by the following exposed constants:

=over 4

B<DBUG_FILTER_LEVEL_FUNC> - Just the function entry and exit points.

B<DBUG_FILTER_LEVEL_ARGS> - Add on the function arguments & return values.

B<DBUG_FILTER_LEVEL_ERROR> - Add on DBUG_PRINT calls with ERROR as their tag.

B<DBUG_FILTER_LEVEL_STD> - Add on trapped writes to STDOUT & STDERR.

B<DBUG_FILTER_LEVEL_WARN> - Add on DBUG_PRINT calls with WARN or WARNING as
their tag.

B<DBUG_FILTER_LEVEL_DEBUG> - Add on DBUG_PRINT calls with DEBUG or DBUG as
their tag.

B<DBUG_FILTER_LEVEL_INFO> - Add on DBUG_PRINT calls with INFO as their tag.

B<DBUG_FILTER_LEVEL_OTHER> - Include everything! (default)

B<DBUG_FILTER_LEVEL_INTERNAL> - Include Fred::Fish::DBUG diagnostics.

=back

=cut

# ==============================================================

=item DBUG_CUSTOM_FILTER ( @levels )

This function allows you to customize which filter level(s) should appear in
your B<fish> logs.  You can pick and choose from any of the levels defined by
I<DBUG_FILTER()>.  If you provide an invalid level, it will be silently ignored.
Any level not listed will no longer appear in B<fish>.

=cut

# ==============================================================

=item DBUG_CUSTOM_FILTER_OFF ( @levels )

This function is the reverse of I<DBUG_CUSTOM_FILTER>.  Instead of specifying
the filter levels you wish to see, you specify the list of levels you don't
want to see.  Sometimes it's just easier to list what you don't want to see
in B<fish>.

=cut

# ==============================================================

=item DBUG_SET_FILTER_COLOR ( $level [, @color_attr] )

This method allows you to control what I<color> to use when printing to the
B<fish> logs for each filter I<level>.  Each I<level> may use different
I<colors> or repeat the same I<color> between I<levels>.

See I<DBUG_FILTER()> above to see what the valid levels are.

See L<Term::ANSIColor> for what I<color> strings are available.  But I<undef>
or the empty string means to use no I<color> information.  (default)  You may
use strings like ("red on_yellow") or ("red", "on_yellow") or even use the color
constants (RED, ON_YELLOW).

If L<Term::ANSIColor> is not installed, this method does nothing.  If you set
I<$ENV{ANSI_COLORS_DISABLED}> to a non-zero value it will disable your I<color>
choice as well.

Returns B<1> if the color request was accepted, else B<0>.

=cut

# ==============================================================

=item DBUG_ACTIVE ( )

This function tells you if B<fish> is currently turned on or not.

It will return B<0> if I<DBUG_PUSH()> was never called, called with
S<B<off =E<gt> 1>>, or if I<DBUG_PAUSE()> is currently in effect.  It ignores
any filter request.

It will return B<1> if B<fish> is currently writing to a file.

It will return B<-1> if B<fish> is currently writing to your screen via
B<STDERR> or B<STDOUT>.

=cut

# ==============================================================

=item DBUG_EXECUTE ( $tag )

This boolean function helps determine if a call to I<DBUG_PRINT> using this
I<$tag> would actually result in the print request being written to B<fish>
or not.

It returns B<1> if the I<DBUG_PRINT> would write it to B<fish> and B<0> if for
any reason it wouldn't write to B<fish>.  It returns B<-1> if B<fish> is
currently writing to your screena via B<STDERR> or B<STDOUT>.

Reasons for returning B<0> would be: Fish was turned off, pause was turned on,
or you set your B<fish> filtering level too low.

This way you can write conditional code based on what's being written to fish!

=cut

# ==============================================================

=item DBUG_FILE_NAME ( )

Returns the full absolute file name to the B<fish> log created by I<DBUG_PUSH>.
If I<DBUG_PUSH> was passed an open file handle, then the file name is unknown
and the empty string is returned!

=cut

# ==============================================================

=item DBUG_FILE_HANDLE ( )

Returns the file handle to the open I<fish> file created by I<DBUG_PUSH>.  If
I<DBUG_PUSH> wasn't called, or called using I<autoopen>, then it returns
I<undef> instead.

=cut;

# ==============================================================

=item DBUG_ASSERT ( $expression [, $always_on [, $msg]] )

This function works similar to the C/C++ I<assert> function except that it
can't tell you what the boolean expression was.

This I<assert> is usually turned off when B<fish> isn't currently active.
But you may enable it even when B<fish> is turned off by setting the
I<$always_on> flag to true.

If the I<$expression> is true, no action is taken and nothing is written
to B<fish>.

But if the I<$expression> is false, it will log the event to B<fish> and then
exit your program with a status code of B<14>.  Meaning this exit can't be
trapped by I<eval> or I<try>/I<catch> blocks.

If you provide the optional I<$msg>, it will print out that message as well
after the assert statement.

These messages will be written to both B<STDERR> and B<fish>.

=cut

# ==============================================================

=item DBUG_MODULE_LIST ( )

This optional method writes to B<fish> all modules used by your program.  It
provides the module version as well as where the module was installed.  Very
useful when you are trying to see what's different between different installs
of perl or when you need to open a CPAN ticket.

=cut

# ------------------------------------------------------------------------------
# End of Fred::Fish::DBUG ...
# ------------------------------------------------------------------------------

# ==============================================================================
# Start of Signal Handling Extenstion to this module ...
# No longer has POD since now in separate module.
# ==============================================================================

# =item DBUG_TRAP_SIGNAL ( $signal, $action [, @forward_to] )

# =item DBUG_FIND_CURRENT_TRAPS ( $signal )

# =item DBUG_DIE_CONTEXT ( )

# ==============================================================================
# Start of TIE to STDOUT/STDERR Extenstion to this module ...
# No longer has POD since now in separate module.
# ==============================================================================

# =item DBUG_TIE_STDERR ( [$callback_func [, $ignore_chaining [, $caller ]]] )

# =item DBUG_TIE_STDOUT ( [$callback_func [, $ignore_chaining [, $caller ]]] )

# =item DBUG_UNTIE_STDERR ( )

# =item DBUG_UNTIE_STDOUT ( )

# ==============================================================

=back

=head1 CREDITS

To Fred Fish for developing the basic algorithm and putting it into the
public domain!  Any bugs in its implementation are purely my fault.

=head1 SEE ALSO

L<Fred::Fish::DBUG::ON> - Is what does the actual work when fish is enabled.

L<Fred::Fish::DBUG::OFF> - Is the stub version of the ON module.

L<Fred::Fish::DBUG::TIE> - Allows you to trap and log STDOUT/STDERR to B<fish>.

L<Fred::Fish::DBUG::Signal> - Allows you to trap and log signals to B<fish>.

L<Fred::Fish::DBUG::SignalKiller> - Allows you to implement action
DBUG_SIG_ACTION_LOG for B<die>.  Really dangerous to use.  Will break most
code bases.

L<Fred::Fish::DBUG::Tutorial> - Sample code demonstrating using the DBUG module.

=head1 COPYRIGHT

Copyright (c) 2007 - 2024 Curtis Leach.  All rights reserved.

This program is free software.  You can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# ============================================================
#required if module is included w/ require command;
1;
 
