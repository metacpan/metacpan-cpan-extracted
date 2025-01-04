###
###  Copyright (c) 2007 - 2025 Curtis Leach.  All rights reserved.
###
###  Based on the Fred Fish DBUG macros in C/C++.
###  This Algorithm is in the public domain!
###
###  Module: Fred::Fish::DBUG::ON

=head1 NAME

Fred::Fish::DBUG::ON - Fred Fish Live library for Perl

=head1 SYNOPSIS

  use Fred::Fish::DBUG  qw / ON /;
    or 
  require Fred::Fish::DBUG;
  Fred::Fish::DBUG->import (qw / ON /);

 Depreciated way.
   use Fred::Fish::DBUG::ON;
     or 
   require Fred::Fish::DBUG::ON;

=head1 DESCRIPTION

F<Fred::Fish::DBUG::ON> is a pure Perl implementation of the C/C++ Fred Fish
macro libraries.  While in C/C++ this library is implemented mostly via macros,
in Perl this library is implemented using true function calls.   It has also
been slightly modified to address Perlish features over C/C++ ones.  This can
make using some features a bit strange compared to C/C++.  But the basic
concepts are the same.

Using this module directly has been depreciated.  You should be using
L<Fred::Fish::DBUG> instead.  The list of functions listed below are a subset
of what's available there.  It also provides a lot of other usefull information
not repeated here.

=head1 FUNCTIONS

=over 4

=cut 

package Fred::Fish::DBUG::ON;

use strict;
use warnings;

use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
use Exporter;

use Perl::OSType ':all';
use FileHandle;
use File::Basename;
use Cwd 'abs_path';
use Config qw( %Config );
use Sub::Identify 'sub_fullname';

$VERSION = "2.10";
@ISA = qw( Exporter );

# ------------------------------------------------------------------------------
# The special var @EXPORT contains the list of functions and constants exposed
# to the users of this module.  The breakdown is as follows:
# 1) The 1st section is a list of exposed functions that a user may call.
#    They mostly follow the Fred Fish standards!
# 2) The remaining sections are exposed constants that can be passed as values
#    to exposed functions.  They can also be used to test some return values.
#    See the POD for more details!
#
# Function names that are in lower case will never be exposed!  They are not for
# the general public and risk breaking your code between releases if used!
# Those that begin with underscores (_) are for internal use only to centralize
# common tasks.
# The others were written to help the t/*.t programs validate that this module
# worked as advertised.  Exposing them would just polute Perl's name space.
# ------------------------------------------------------------------------------


@EXPORT = qw( DBUG_PUSH           DBUG_POP
              DBUG_ENTER_FUNC     DBUG_ENTER_BLOCK         DBUG_PRINT
              DBUG_RETURN         DBUG_ARRAY_RETURN
              DBUG_VOID_RETURN    DBUG_RETURN_SPECIAL
              DBUG_LEAVE          DBUG_CATCH               DBUG_PAUSE
              DBUG_MASK           DBUG_MASK_NEXT_FUNC_CALL
              DBUG_FILTER         DBUG_SET_FILTER_COLOR
              DBUG_CUSTOM_FILTER  DBUG_CUSTOM_FILTER_OFF
              DBUG_ACTIVE         DBUG_EXECUTE
              DBUG_FILE_NAME      DBUG_FILE_HANDLE         DBUG_ASSERT
              DBUG_MODULE_LIST

              DBUG_SPECIAL_ARRAYREF      DBUG_SPECIAL_COUNT
	      DBUG_SPECIAL_LAST

              DBUG_FILTER_LEVEL_FUNC     DBUG_FILTER_LEVEL_ARGS
              DBUG_FILTER_LEVEL_ERROR    DBUG_FILTER_LEVEL_STD
              DBUG_FILTER_LEVEL_WARN
              DBUG_FILTER_LEVEL_DEBUG    DBUG_FILTER_LEVEL_INFO
              DBUG_FILTER_LEVEL_OTHER    DBUG_FILTER_LEVEL_INTERNAL
            );

@EXPORT_OK = qw( );

# NOTE:  OFF.pm inherits all exposed functions and constants exported here.
#        So if you add a new function, consider if it needs to be a stub in
#        OFF.pm.  Otherwise it's automatically available in OFF.pm.  Done this
#        way to keep this module and OFF.pm compatible.

# Constants for use by DBUG_RETURN_SPECIAL () ...
use constant DBUG_SPECIAL_ARRAYREF => "_-"x40 . "_";    # A long random string ...
use constant DBUG_SPECIAL_COUNT    => "-_"x40 . "-";    # A long random string ...
use constant DBUG_SPECIAL_LAST     => "-="x40 . "=";    # A long random string ...

# An array for convering the DBUG_FILTER_LEVEL_... constants into stings ...
my @dbug_levels;
my @dbug_custom_levels;

# For filtering what get's written to fish ... (never use level 0)
use constant DBUG_FILTER_LEVEL_FUNC  => 1;    # Most restrictive.
use constant DBUG_FILTER_LEVEL_ARGS  => 2;
use constant DBUG_FILTER_LEVEL_ERROR => 3;
use constant DBUG_FILTER_LEVEL_STD   => 4;
use constant DBUG_FILTER_LEVEL_WARN  => 5;
use constant DBUG_FILTER_LEVEL_DEBUG => 6;
use constant DBUG_FILTER_LEVEL_INFO  => 7;
use constant DBUG_FILTER_LEVEL_OTHER => 8;    # Least restrictive.

# Used for debugging this module.
use constant DBUG_FILTER_LEVEL_INTERNAL => 99;

# So can easily add new levels and not have to worry about changing other code!
use constant DBUG_FILTER_LEVEL_MIN => DBUG_FILTER_LEVEL_FUNC;
use constant DBUG_FILTER_LEVEL_MAX => DBUG_FILTER_LEVEL_OTHER;

# Names the unamed main function for the trace ...
use constant MAIN_FUNC_NAME => "main-prog";

# Value to use when masking sensitive data in fish ...
use constant MASKING_VALUE => "<******>";

# Value to use when making undefined values printable in fish ...
use constant UNDEF_VALUE => "<undef>";

# This hash variable holds all the global variables used by this module.
my %dbug_global_vars;     # The current fish frame ...

my $threads_possible;     # Boolean flag telling if threads are supported.
my $fork_possible;        # Boolean flag telling if forks are supported.
my $color_supported;      # Boolean flag telling if Term::ANSIColor is avaailable.
my @color_list;
my $color_clear;
my $time_hires_flag;      # Boolean flag telling if Time::HiRes is supported!

# Holds the version of Perl & OS ...
my $dbug_log_msg;

# So we can one day support multiple fish frames
sub _init_frame
{
   my $frame_ref = shift;      # A hash reference ...
   my $old_stack = shift;      # An array of hash reference ...

   $frame_ref->{can_close}  = 0;        # OK to close the file handle.
   $frame_ref->{fh}         = undef;    # Fish's file handle.
   $frame_ref->{file}       = "";       # The full absolute path to fish file.
   $frame_ref->{who_called} = 0;        # Print func/file/line of caller.
   $frame_ref->{no_end}     = 0;        # Turn off fish tracing for END blocks!
   $frame_ref->{on}         = 0;        # Is Fish currently turned on or off.
   $frame_ref->{pause}      = 0;        # Is Fish is currently paused?
   $frame_ref->{multi}      = 0;        # Will we write the PID-TID or PID/xx pair to Fish?
   $frame_ref->{limit}      = 0;        # Will we limit which thread to write to Fish?
   $frame_ref->{screen}     = 0;        # Fish is writing to your screen.
   $frame_ref->{strip}      = 0;        # Will fish strip the module part of func namee?
   $frame_ref->{delay}      = 0.0;      # Will we delay after each write to fish?
   $frame_ref->{elapsed}    = 0;        # Will we track elapsed time in your code?
   $frame_ref->{keep}       = 0;        # Will we toss the logs on success? (keep on failure)
   $frame_ref->{no_addresses} = 0;      # Will we supress unique addresses for references?
   $frame_ref->{dbug_leave_called} = 0; # Tells if DBUG_LEAVE() was called or not.
   $frame_ref->{allow_utf8} = 0;        # Will we support UTF8 chars to fish?

   # Used when forking a sub-process (not separate threads!)
   $frame_ref->{PID}        = $$;       # The process PID.

   # Tell's how many return values by DBUG_RETURN() were to be masked.
   # Only non-zero if DBUG_MASK() was called!
   # You will always get the same results even if the return values
   # weren't printed to fish.
   # For DBUG_VOID_RETURN() it will always be zero!
   $frame_ref->{mask_return_count} = 0;

   # The filtering tags ...
   $frame_ref->{filter}       = DBUG_FILTER_LEVEL_MAX;
   $dbug_global_vars{pkg_lvl} = DBUG_FILTER_LEVEL_INTERNAL;
   $frame_ref->{filter_style} = 1;      # Standard filtering enabled ...

   # What to call the unnamed main function block in your code ...
   $frame_ref->{main} = MAIN_FUNC_NAME;

   # Tells what functions are currently on the stack ...
   if ( $old_stack ) {
      $frame_ref->{functions} = $old_stack;
   } else {
      my @funcs;           # Will be an array of hashes ...
      $frame_ref->{functions} = \@funcs;
   }

   # Flag tells if the exit status was printed in DBUG_LEAVE().
   $frame_ref->{printed_exit_status} = 0;

   return;
}

# --------------------------------
# This BEGIN block handles the initialization of the DBUG frame logic.
# It can only call DBUG functions appearing before this function is defined!
# All BEGIN blocks are automatically executed when this module is 1st soruced
# in via 'use' or 'require'!
# --------------------------------
BEGIN
{
   _init_frame ( \%dbug_global_vars, undef );

   # The array to convert the constant values into something human readable!
   $dbug_levels[DBUG_FILTER_LEVEL_FUNC]  = "DBUG_FILTER_LEVEL_FUNC";
   $dbug_levels[DBUG_FILTER_LEVEL_ARGS]  = "DBUG_FILTER_LEVEL_ARGS";
   $dbug_levels[DBUG_FILTER_LEVEL_ERROR] = "DBUG_FILTER_LEVEL_ERROR";
   $dbug_levels[DBUG_FILTER_LEVEL_STD]   = "DBUG_FILTER_LEVEL_STD";
   $dbug_levels[DBUG_FILTER_LEVEL_WARN]  = "DBUG_FILTER_LEVEL_WARN";
   $dbug_levels[DBUG_FILTER_LEVEL_DEBUG] = "DBUG_FILTER_LEVEL_DEBUG";
   $dbug_levels[DBUG_FILTER_LEVEL_INFO]  = "DBUG_FILTER_LEVEL_INFO";
   $dbug_levels[DBUG_FILTER_LEVEL_OTHER] = "DBUG_FILTER_LEVEL_OTHER";

   # The odd ball undocumented filter level.
   $dbug_levels[DBUG_FILTER_LEVEL_INTERNAL] = "DBUG_FILTER_LEVEL_INTERNAL";

   # The custom levels are all off by default!
   # $dbug_custom_levels[...] = 0;

   return;
}

# --------------------------------
# This BEGIN block detects if Perl supports threads.
# So that we can detect which thread we're in for logging purposes!
# Tests came from Test2::Util ...
# --------------------------------
BEGIN
{
   $threads_possible = 0;       # Threads are not supporteed ...

   if ( $] >= 5.008001 && $Config{useithreads} ) {
      # Threads are broken on Perl 5.10.0 built with gcc 4.8+
      my $broken = 0;
      if ($] == 5.010000 && $Config{ccname} eq 'gcc' && $Config{gccversion}) {
         my @parts = split /\./, $Config{gccversion};
         $broken = 1  if ($parts[0] > 4 || ($parts[0] == 4 && $parts[1] >= 8));
      }

     unless ( $broken ) {
        eval {
           require threads;
           threads->import ();
           $threads_possible = 1;  # Threads are supporteed after all ...
        };
     }
   }    # Ends if Perl > v5.8.1 && compiled with threads.
}


# --------------------------------
# This BEGIN block detects if Perl supports forking.
# So that we can detect which child process we're in for logging purposes!
# Tests came from Test2::Util ...
# --------------------------------
BEGIN
{
   $fork_possible = 1;       # Assuming fork is supporteed ...

   unless ( $Config{d_fork} ) {
      $fork_possible = 0  unless ($^O eq 'MSWin32' || $^O eq 'NetWare');
      $fork_possible = 0  if ( $threads_possible == 0 );
      $fork_possible = 0  unless ($Config{ccflags} =~ m/-DPERL_IMPLICIT_SYS/);
   }
}

# --------------------------------
# Tells if the optional Term::ANSIColor module is installed!
# Done this way so that color is an optional feature.
# --------------------------------
BEGIN
{
   $color_supported = 0;    # Assume color isn't supported!

   eval {
      if ( $^O eq "MSWin32" ) {
         # Windows needs this module for Term::ANSIColor to work.
         require Win32::Console::ANSI;
         Win32::Console::ANSI->import ();
      }

      require Term::ANSIColor;
      Term::ANSIColor->import ();

      $color_supported = 1;
   };
}

# --------------------------------
# Tells if the HiRes timer is available ...
# Overrides the core time() & sleep() functions if available.
# --------------------------------
BEGIN
{
   $time_hires_flag = 0;   # Assume the HiRes timer isn't supported!

   eval {
      require Time::HiRes;
      Time::HiRes->import ( qw(time sleep) );
      $time_hires_flag = 1;
   };
}

# --------------------------------
# Builds the string for CPAN support ...
# --------------------------------
BEGIN
{
   my $pv = sprintf ("%s  [%vd]", $], $^V);   # The version of perl!
   my $flvr = os_type ();

   $dbug_log_msg = "Perl: $pv,  OS: $^O,  Flavor: $flvr\n";
   $dbug_log_msg .= "Threads: " . ($threads_possible ? "Supported" : "Unsupported") . "\n";
   $dbug_log_msg .= "Forking: " . ($fork_possible    ? "Supported" : "Unsupported") . "\n";
   $dbug_log_msg .= "Color: "   . ($color_supported  ? "Supported" : "Unsupported") . "\n";
   $dbug_log_msg .= "HiRes: "   . ($time_hires_flag  ? "Supported" : "Unsupported") . "\n";
   $dbug_log_msg .= "Program: $0\n";

   # Assume not running via a "make test" variant ...
   my $make_test_flag = 0;

   if ( $ENV{PERL_DL_NONLAZY} ) {
      $make_test_flag = 1;    # Detects "make test" on Unix like systems ...

   } elsif ( $ENV{PERL_USE_UNSAFE_INC} ) {
      $make_test_flag = 1;    # Detects "gmake test" on Windows (Strawberry Perl) ...

   } elsif ( $ENV{HARNESS_ACTIVE} ) {
      $make_test_flag = 1;    # Detects "prove -vl t/*.t" ...
   }

   if ( $make_test_flag ) {
      $dbug_log_msg .= "Run during a \"make test\" run.\n";
   }
}


# --------------------------------
# END is automatically called when this module goes out of scope!
# --------------------------------
END
{
   # Only happens if you call exit() directly, die due to an
   # untrapped signal, or just return from your main program.
   # If this happens the code never gets the chance to clean
   # up properly.  So doing it now!
   unless ( $dbug_global_vars{dbug_leave_called} ) {
      _dbug_leave_cleanup ();
   }

   # Clear the function stack of all remaining entries ...
   while ( pop (@{$dbug_global_vars{functions}}) ) { }

   DBUG_ENTER_FUNC (@_);

   _dbug_print_pkg_tag ( DBUG_FILTER_LEVEL_INFO,
                         "So Long, and Thanks for All the Fish!" );

   unless ( $dbug_global_vars{printed_exit_status} ) {
      _dbug_print_pkg_tag ( DBUG_FILTER_LEVEL_INFO,
                            "Exit Status (%d)", $? );
   }

   DBUG_VOID_RETURN ();

   # ------------------------------------------------
   # Implements:  keep => 1 or keep => \&test().
   # ------------------------------------------------
   my $toss_the_file;
   if ( $dbug_global_vars{keep} && $dbug_global_vars{file} ) {
      my $keep = ($? != 0);
      if ( ref ($dbug_global_vars{keep}) eq "CODE" ) {
         $keep = $dbug_global_vars{keep}->($?);
      }
      $toss_the_file = $dbug_global_vars{file}  unless ( $keep );
   }

   $dbug_global_vars{on} = 0;    # Turn fish off.

   if ( $dbug_global_vars{can_close} ) {
      my $dbug_fh = $dbug_global_vars{fh};
      close ( $dbug_fh );
   }

   # Finishes:  keep => ?.
   unlink ( $toss_the_file )  if ( $toss_the_file );
}


# --------------------------------
# Tells if you are in the required thread/process ...
# Returns:
#    1 - You are in the correct thread
#    0 - You are in the wrong thread.
# --------------------------------
sub _limit_thread_check
{
   return (1)  unless ( $dbug_global_vars{limit} );

   # Which thread/process are we in ...
   my $parent = 0;
   if ( $dbug_global_vars{PID} == $$ ) {
      my $tid = ( $threads_possible ) ? threads->tid () : 0;
      $parent = 1  if ( $tid == 0 );
   }

   return (1)  if ( $parent == 1 && $dbug_global_vars{limit} == 1 );
   return (1)  if ( $parent == 0 && $dbug_global_vars{limit} == -1 );

   return (0);    # In the wrong thread/process ...
}

# --------------------------------
# This function handles all printing to the fish logs.
# Done this way so we don't have to call "or die" all over the place or check
# if fish is active all the time or not.  This slows the module down slightly
# when fish is turned off, but makes the coding significantly simpler.
# If formatted printing is desired, just use "sprintf" & then call this method!
# Returns:
#    0 - Nothing written to fish
#    1 - Something was written to fish
# Calls die if the write fails!
# --------------------------------
sub _printing
{
   # Fish must be active to print anything ...
   return (0)  unless ( DBUG_ACTIVE () );

   my $dbug_fh = $dbug_global_vars{fh};

   if ( defined $dbug_fh ) {
      print $dbug_fh @_  or
                    die ("Can't write the mesage to the fish file! $!\n");
   } else {
      # Open, write, close the fish file ... doesn't return on error!
      _dbug_auto_open_printing (@_);
   }

   return (1);
}


# For inserting color directives into preformatted multi-line messages ...
sub _printing_with_color
{
   my $lvl = shift;

   my @colors = _get_filter_color ( $lvl );
   if ( $colors[0] eq "" ) {
      return ( _printing ( @_ ) );     # No color asked for.
   }

   # Join the rest of the arguments into a single message to parse!
   my $msg = join ("", @_);

   my $term = "-_"x100 . "-";
   my @lines = split ( /\n/, $msg . $term );

   my ($build, $sep) = ("", "");
   my $final = $lines[-1];

   foreach my $ln ( @lines ) {
      if ( (! defined $ln) || $ln eq $term || $ln =~ m/^\s*$/ ) {
         $build .= $sep;     # Blank lines have no color!
      } elsif ( $ln eq $final ) {
         $ln =~ s/${term}$//;
         $build .= $sep . $colors[0] . $ln . $colors[1];
      } else {
         $build .= $sep . $colors[0] . $ln . $colors[1];
      }

      $sep = "\n";
   }

   return ( _printing ( $build ) );
}

# --------------------------------
# To handle printing for the auto-open option ... (very slow!)
# Only called via _printing()!  Never by anyone else!
# --------------------------------
sub _dbug_auto_open_printing
{
   my $f = $dbug_global_vars{file};
   unless ($f) {
      die ("No fish file name available for auto-reopen to use!\n");
   }
   open (REOPEN_FISH_FILE, ">>", $f) or
            die ("Can't reopen the FISH file: " . basename ($f) . " $!\n");
   if ( $dbug_global_vars{allow_utf8} ) {
      binmode (REOPEN_FISH_FILE, "encoding(UTF-8)");
   }

   print REOPEN_FISH_FILE @_ or
               die ("Can't write the mesage to the reopened fish file! $!\n");
   close (REOPEN_FISH_FILE);
   return (1);
}

# --------------------------------
# These 2 private functions handle indenting each line written to fish!
# It builds & returns the string to use to allow the caller to
# combine calls to _printing(), just in case using the auto-reopen logic,
# which is slow, slow, slow, ...
# Or if multiple threads are writing to fish to make the calls atomic!
# --------------------------------
sub _indent_multi
{
   my $remove = shift || 0;

   # A no-op if option multi wasn't used ...
   return ( "" )  unless ( $dbug_global_vars{multi} );

   my ($tid, $fid, $ind_str) = (-1, -1, "");

   # Gives preference to logging threads over forks ...

   # Logging Threads ...
   $tid = threads->tid ()  if ( $threads_possible );

   # Logging Forks ...
   if ( $fork_possible ) {
      if ( $dbug_global_vars{PID} == $$ ) {
         $fid = 0   if ( $tid == -1 );
      } else {
         my $id = ( abs ($$) % 100 );
         $fid = ($id == 0) ? 100 : $id;
         $tid = -1  if ( $tid == 0 );
      }
   }

   # Build the line's prefix ...
   if ( $tid != -1 && $fid != -1 ) {
      # Both threads and forks ...
      $ind_str .= sprintf ( "%d/%02d-%d", $$, $fid, $tid );
   } elsif ( $tid != -1 ) {
      # Threads only ...
      $ind_str .= sprintf ( "%d-%d", $$, $tid );
   } elsif ( $fid != -1 ) {
      # Forks only ...
      $ind_str .= sprintf ( "%d/%02d", $$, $fid );
   } else {
      # Neither threads nor forks are supported ...
      $ind_str = $$;
   }

   # Easier to not add it than remove it ...
   $ind_str .= ":: "  if ( $remove == 0 );

   return ( $ind_str );
}


# Determines how deep to indent each row ...
sub _indent
{
   my $label = shift || "";

   my $ind_str = _indent_multi ();

   # Building the indenting string ... "| | | | | ..."
   my $cnt = @{$dbug_global_vars{functions}};
   $ind_str .= "| "x$cnt . $label;

   return ($ind_str);
}


# ==============================================================
# A helper function ...
# Returns the number of evals on the stack + an array refernce containing
# the line number each eval appears on.
sub _eval_depth
{
   my $base = shift || 0;  # The caller() index to the code that called DBUG_...

   my @eval_lines;

   my $eval_lvl = 0;
   my ($c2, $ln2) = (caller ($base + $eval_lvl))[3,2];
   while ( defined $c2 ) {
      if ( $c2 eq "(eval)" ) {
         ++$eval_lvl;            # Just count how deep in eval's we are!
         push (@eval_lines, $ln2);
      } else {
         ++$base;                # Wasn't an eval!
      }
      ($c2, $ln2) = (caller ($base + $eval_lvl))[3,2];
   }

   return ( wantarray ? ( $eval_lvl, \@eval_lines) : $eval_lvl );
}


# ==============================================================
# A helper function for elapsed time ...
sub _dbug_elapsed_time
{
   my $start_clock = shift;

   return ("")  unless ( $dbug_global_vars{elapsed} );
   return ("")  unless ( defined $start_clock );

   my $elapsed_time = time () - $start_clock;

   my $msg;
   if ( $time_hires_flag ) {
      $msg = sprintf ("   -- Elapsed time: %0.6f second(s)", $elapsed_time);
   } else {
      $msg = sprintf ("   -- Elapsed time: %d second(s)", $elapsed_time);
   }

   return ( $msg );
}

# ==============================================================
# A helper function ...
# This will never return a Fred::Fish::DBUG::ON funtion as the caller!
# It will return who called the DBUG function instead!
# So sometimes the caller looks a bit indirect!
# Returns:  "  -- caller at file line 1234"
#      or:  "caller at file line 1234"
sub _dbug_called_by
{
   # Uncomment next 2 lines to demonstrate potential problem with t/*.t progs...
   # _dbug_auto_fix_eval_exception ();
   # _printing ("XXXX: Inside of _dbug_called_by(", join (", ", @_), ")\n");

   # Only happens if called by any of the t/*.t program hacks as an object!
   shift  if ( defined $_[0] && $_[0] eq __PACKAGE__ );

   # The real arguments ...
   my $no_prefix_flg  = shift || 0;
   my $dbug_enter_flg = shift || 0;   # Called by DBUG_ENTER_FUNC() ?
   my $anon_flag      = shift || 0;   # Ignored unless $dbug_enter_flg is true.


   my $eval_caller = '(eval)';
   my $pkg = __PACKAGE__ . '::';
   $pkg =~ s/::ON::$/::/;

   # Start with who called me ...
   my ($ind_by, $ind_call) = (1, 0);

   my $by = (caller($ind_by))[3] || $dbug_global_vars{main};

   # Find caller of the 1st Fred::Fish::DBUG::ON entry point ...
   while ( $by =~ m/^${pkg}/ || $by eq $eval_caller ) {
      $ind_call = $ind_by  if ( $by =~ m/^${pkg}/ );
      $by = (caller(++$ind_by))[3] || $dbug_global_vars{main};
   }

   # Get the line number of where the calling function was called.
   # Only happens when called by DBUG_ENTER_FUNC() & it asked for it.
   # Will never return as the caller another DBUG function!
   if ( $dbug_enter_flg && $by ne $dbug_global_vars{main} ) {
      $by = $pkg;   # So I'll skip over the current function!

      while ( $by =~ m/^${pkg}/ || $by eq $eval_caller ) {
         $ind_call = $ind_by  if ( $by =~ m/^${pkg}/ );
         # ++$ind_call  if ( $by ne $eval_caller );
         $by = (caller(++$ind_by))[3] || $dbug_global_vars{main};
      }

      # HACK: If called in a try/catch/finally block ...
      #       Then was called with wrong arguments to this function!
      #       So ask caller to try again with $dbug_enter_flg set to 0!
      if ( $anon_flag ) {
         return ("")  if ( $by eq "Try::Tiny::try" );
         return ("")  if ( $by eq "Try::Tiny::ScopeGuard::DESTROY" );
         return ("")  if ( $by eq "Error::subs::try" );
      }
   }

   # Get file & line number ...
   my @c = (caller($ind_call))[1,2];

   my $prefix = ($no_prefix_flg) ? "" : "   -- ";
   my $line;
   if ( $#c == -1 ) {
      $line = sprintf ("%s%s at ? line ?", $prefix, $by);  # Can we fix?
   } else {
      $line = sprintf ("%s%s at %s line %d", $prefix, $by, @c);
   }

   # (${ind_by} > ${ind_call}) is always true!  Never equal!
   # $line .= "  IDX: ${ind_by}, ${ind_call}";

   return ( $line );
}

# ==============================================================
# Allows for a quick and dirty way to cheat this module without
# giving you access to the underlying module configuration
# variable %dbug_global_vars.
# It tells which key(s) to temporarily override before calling
# the requested function without having to worry about the
# scope of the change.
# Since not exposed, you don't have access to it by default and
# can remain undocumentded in the POD.
# For use by my helper modules and t/*.t programs only!
# Also use internally by the Signal handling & TIE routines!
# --------------------------------------------------------------
# Usage:  $res = Fred::Fish::DBUG::ON::_dbug_hack ( %opts, $func, @args);
sub _dbug_hack
{
   my $key  = shift;
   my $val  = shift;
   my $func = shift;   # May be start of another key/val pair instead!
#  my @args = @_;

   # Usage error ... no hash key provided.
   rturn (undef)  unless ( $key );

   # If undef, don't change the value ...
   $val = $dbug_global_vars{$key}  unless ( defined $val );

   # ERROR: Can only replace with the same data type ...
   return (undef)  if ( ref ($val) ne ref ($dbug_global_vars{$key}) );

   local $dbug_global_vars{$key} = $val;

   if ( $func && ref ($func) eq "CODE" ) {
      return ( $func->( @_ ) );
   }

   # Recursively add the next key/value pair ...
   return ( _dbug_hack ($func, @_) );
}

# --------------------------------------------------------------
# Get the requested entry in the global hash ...
# --------------------------------------------------------------
sub _get_global_var
{
   my $key  = shift;
   return ( $dbug_global_vars{$key} );
}

# --------------------------------------------------------------
# Permanently set the requested entry in the global hash ...
# --------------------------------------------------------------
sub _set_global_var
{
   my $key  = shift;
   my $val  = shift;
   $dbug_global_vars{$key} = $val;
   return;
}

# ------------------------------------------------------------------------------
# DBUG Code
# 
# I have tried to keep the functions in a meaningfull order, to make it 
# easier to learn how to use this module.
#
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
up like S<HASH(001)> so it's easier to compare fish files between runs.  Only
works for arguments and return values.

B<allow_utf8> - Writes to B<fish> in UTF-8 mode.  Use if you get warnings
about writing S<'Wide character in print'> to B<fish>.

=back

=cut

# ==============================================================
sub DBUG_PUSH
{
   my $file = shift;
   my $opts = (ref ($_[0]) eq "HASH") ? $_[0] : {@_};

   if ( $dbug_global_vars{on} ) {
      warn "You may not call DBUG_PUSH() more than once!\n";
      return;
   }

   # Check if eval needs rebalancing ...
   _dbug_auto_fix_eval_exception ();

   if ( $opts->{off} ) {
      # warn "You disabled fish, no fish logs are kept!\n";
      return;
   }

   # DBUG_SET_FILTER_COLOR ( DBUG_FILTER_LEVEL_INTERNAL, "green" );

   # Set all flags to a default value ...
   my @lst = @{$dbug_global_vars{functions}};
   _init_frame ( \%dbug_global_vars, \@lst );

   $dbug_global_vars{no_end}       = 1  if ( $opts->{kill_end_trace} );
   $dbug_global_vars{who_called}   = 1  if ( $opts->{who_called} );
   $dbug_global_vars{multi}        = 1  if ( $opts->{multi} );
   $dbug_global_vars{strip}        = 1  if ( $opts->{strip} );
   $dbug_global_vars{elapsed}      = 1  if ( $opts->{elapsed} );
   $dbug_global_vars{no_addresses} = 1  if ( $opts->{no_addresses} );
   $dbug_global_vars{allow_utf8}   = 1  if ( $opts->{allow_utf8} );

   if ( $opts->{keep} ) {
      if ( ref ($opts->{keep}) eq "CODE" ) {
         $dbug_global_vars{keep} = $opts->{keep};
      } else {
         $dbug_global_vars{keep} = 1;
      }
   }

   if ( $opts->{limit} ) {
      $dbug_global_vars{limit} = ( $opts->{limit} > 0 ) ? 1 : -1;
   }

   if ( $opts->{delay} && $opts->{delay} =~ m/(^\d+$)|(\d+\.\d+$)/ ) {
      $dbug_global_vars{delay} = $opts->{delay};
      unless ( $time_hires_flag ) {
         if ( $dbug_global_vars{delay} =~ s/[.]\d+$// ) {
            warn ( "Time::HiRes isn't installed.  Truncating delay to ",
                   $dbug_global_vars{delay}, ".\n" );
         }
      }
   } elsif ( $opts->{delay} ) {
      warn ( "Option 'delay' isn't numeric, so the delay request is ignored!\n" );
   }

   DBUG_FILTER ($opts->{filter});

   $file = \*STDERR  unless ( defined $file );

   if ( ref ($file) eq "GLOB" ) {
      if ( $file == \*STDERR || $file == \*STDOUT ) {
         $dbug_global_vars{screen} = 1;
      }

      # Enable writing to the open file handle by fish ...
      $dbug_global_vars{on} = 1;

      # Provided an open file handle to write to ...
      $dbug_global_vars{fh} = $file;
      return;
   }

   if ( ref ($file) ne "" ) {
      die ("Unknown reference for a filename: " . ref($file) . "\n");
   }

   # Trim leading/trailing spaces from the file name.
   $file =~ s/^\s+//;
   $file =~ s/\s+$//;
   die ("The filename can't be all spaces!\n")  if ( $file eq "" );

   # Now let's acutally open up the file ... if we were given a name ...

   # Don't need to remember this option ...
   my $flush = 1;
   if ( exists $opts->{autoflush} && ! $opts->{autoflush} ) {
      $flush = 0;
   }

   # Get the old fish log file's age ...
   my ($age, $overwritten, $type, $mode) = (0, 0, "day(s)", ">");
   if ( -f $file ) {
      $age = -M _;
      if ( $age < 1 ) {
         $age *= 24;  $type = "hour(s)";
         if ( $age < 1 ) {
            $age *= 60;  $type = "minute(s)";
            if ( $age < 1 ) {
               $age *= 60;  $type = "second(s)";
            }
         }
      }

      if ( $opts->{append} ) {
         $mode = ">>";
      } else {
         $overwritten = 1;
         unlink ( $file );
      }
   }

   open ( FISH_FILE, $mode, $file ) or
               die ("Can't open the fish file for writing: $file  ($!)\n");
   FISH_FILE->autoflush (1)  if ( $flush );
   if ( $dbug_global_vars{allow_utf8} ) {
      binmode (FISH_FILE, "encoding(UTF-8)");
   }
   $dbug_global_vars{fh} = \*FISH_FILE;

   # If we're going to auto-open/close the file, we need to always have
   # a full absolute path name to the file instead of a relatve file name!
   # Just in case the program changes directories on us!
   # On Windows, this file must always exists for this to work!
   $dbug_global_vars{file} = abs_path ($file);

   # Allow writing to the fish log ...
   # Must set only after the fish log has been opened!
   $dbug_global_vars{on} = 1;

   if ( $overwritten ) {
      my $fmt = " *** Overwrote a previous fish file of the same name. ***\n"
              . " *** Previous file was last written to %0.3f %s ago. ***\n\n";
      _printing_with_color ( DBUG_FILTER_LEVEL_INTERNAL,
                             sprintf ( $fmt, $age, $type ) );

   } elsif ( $mode eq ">>" ) {
      my $id = $dbug_global_vars{multi} ? _indent_multi (1) : $$;

      my $msg = "\n" . "="x70 .
                "\n*** Appending to a pre-existing fish log.  PID ($id)\n";
      $msg .= sprintf ("*** The log was last written to %0.3f %s ago.\n", $age, $type);
      $msg .= "="x70 . "\n\n";
      _printing_with_color ( DBUG_FILTER_LEVEL_INTERNAL, $msg );
   }

   # Print out the CPAN support info to FISH ...
   _printing_with_color ( DBUG_FILTER_LEVEL_INTERNAL,
                          sprintf ("%s %s\n", __PACKAGE__, $VERSION) );
   _printing_with_color ( DBUG_FILTER_LEVEL_INTERNAL, $dbug_log_msg );
   _printing "\n";

   # ------------------------------------------------------------------
   # Tells what options were selected for generating the fish file ...
   # ------------------------------------------------------------------
   my $opts_prefix = "DBUG_PUSH Options: ";
   my ($opts_str, $sep) = ("", "");
   foreach my $k ( sort keys %{$opts} ) {
      my $str;
      if ( $k eq "chmod" && defined $opts->{chmod} ) {
         $str = sprintf ("%s => 0%o", $k, $opts->{$k});
      } else {
         $str = sprintf ("%s => %s", $k, $opts->{$k});
      }
      $opts_str .= ${sep} . ${str};
      $sep = ", ";
   }
   if ( $opts_str eq "" ) {
      $opts_str = ${opts_prefix} . "<defaults>\n\n";
   } else {
      $opts_str = ${opts_prefix} . ${opts_str} . "\n\n";
   }
   _printing_with_color ( DBUG_FILTER_LEVEL_INTERNAL, _indent ($opts_str) );
   # ------------------------------------------------------------------

   if ( defined $opts->{chmod} ) {
      chmod (oct ($opts->{chmod}), $file);
   } else {
      chmod (0644, $file);         # So it's always -rw-r--r--.
   }

   if ( $opts->{autoopen} ) {
      close (FISH_FILE);
      $dbug_global_vars{fh} = undef;
   } else {
      $dbug_global_vars{can_close} = 1;
   }

   # Check if we have to print the previous function declaration ...
   # We've lost the arguments if this option was used!
   # We've also lost the start time if asked for!
   if ( $opts->{before} && $#lst != -1 ) {
      my $block = pop ( @{$dbug_global_vars{functions}} );
      my $func = $block->{NAME};
      my $line = $block->{LINE};
      _printing ( $block->{COLOR1}, _indent (">${func}${line}"), $block->{COLOR2}, "\n");
      push ( @{$dbug_global_vars{functions}}, $block );
   }

   return;
}


=item DBUG_POP ( )

Not yet implemented.

=cut

# ==============================================================
sub DBUG_POP
{
   warn "DBUG_POP() is currently a NO-OP!\n";
}


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
sub DBUG_ENTER_FUNC
{
   # Who called this function ...
   my $func = (caller (1))[3] || $dbug_global_vars{main};

   # Check if eval needs rebalancing ...
   _dbug_auto_fix_eval_exception ();

   # Count how deep in eval blocks we are so DBUG_CATCH can work!
   my ($eval_cnt, $eval_lns) = _eval_depth (1);
   my $eval_flg = 0;
   if ( $func eq "(eval)" ) {
      $func .="  [${eval_cnt}, " . $eval_lns->[0] . "]";
      $eval_flg = 1;
   }

   # This special function traps calls to undefined functions.
   # So we want to know what the user was really calling by
   # referencing the special variable named after the function!
   if ( $func =~ m/::AUTOLOAD$/ ) {
      no strict;      # So can indirectly access the variable as a ref.
      my $aka = ${$func};
      $aka = $1   if ( $dbug_global_vars{strip} && $aka =~ m/::([^:]+)$/ );
      $func .= " <aka ${aka}>";
   }

   # Do we need to know who called ${func} at this time ???
   my $line="";
   if ( $dbug_global_vars{who_called} && $func ne $dbug_global_vars{main} ) {
      # Special functions where there are no valid callers ...
      if ( $eval_flg || $func =~ m/::END$/ || $func =~ m/::BEGIN$/ ||
           $func =~ m/::UNITCHECK$/ || $func =~ m/::CHECK$/ || $func =~ m/::INIT$/ ||
           $func =~ m/::DESTROY$/ ) {
         $line = _dbug_called_by (0, 0, 0);

      # When Try::Tiny renames the __ANON__ function to ... "YourModule::xxx {...}"
      # It doesn't always do this ...
      } elsif ( $func =~ m/::try [{][.]{3}[}]\s*$/ ||
                $func =~ m/::catch [{][.]{3}[}]\s*$/ ||
                $func =~ m/::finally [{][.]{3}[}]\s*$/ ) {
         $line = _dbug_called_by (0, 0, 0);

      # Want who called the logged function, not who called DBUG_ENTER_FUNC ...
      } else {
         my $may_be_a_try_catch_finally_event = ( $func =~ m/::__ANON__$/ );
         $line = _dbug_called_by (0, 1, $may_be_a_try_catch_finally_event);
         $line = _dbug_called_by (0, 0, 0)   unless ( $line );
      }
   }

   # Put a blank line before all END blocks ...
   my $skip = ( $func =~ m/::END$/ ) ? "\n" : "";

   # Strip off any module info from the calling function's name?
   $func = $1   if ( $dbug_global_vars{strip} && $func =~ m/::([^:]+)$/ );

   my @colors = _get_filter_color (DBUG_FILTER_LEVEL_FUNC);
   if ( DBUG_EXECUTE ( DBUG_FILTER_LEVEL_FUNC ) ) {
      _printing ( $skip, $colors[0], _indent (">${func}${line}"), $colors[1], "\n");
   }

   my %block = ( NAME    => $func,
                 PAUSED  => $dbug_global_vars{pause},
                 EVAL    => $eval_cnt,
                 EVAL_LN => $eval_lns->[0],
                 LINE    => $line,
                 FUNC    => 1,
                 COLOR1  => $colors[0],
                 COLOR2  => $colors[1] );
   $block{TIME} = time ()  if ( $dbug_global_vars{elapsed} );
   $block{MULTI} = _indent_multi (1)  if ( $dbug_global_vars{multi} );

   push ( @{$dbug_global_vars{functions}}, \%block );

   _dbug_args ( @_ );

   return ( $func );
}


# Helper method to DBUG_ENTER_FUNC & DBUG_ENTER_BLOCK!
# Called almost as frequently as DBUG_PRINT ...
sub _dbug_args
{
   my @args = @_;

   $dbug_global_vars{mask_last_argument_count} = 0;

   # If nothing to write to fish ...
   if ( $#args == -1 ) {
      delete $dbug_global_vars{mask_func_call};
      return;
   } elsif ( DBUG_EXECUTE ("args") == 0 ) {
      if ( exists $dbug_global_vars{mask_func_call} ) {
         $dbug_global_vars{mask_last_argument_count} = -1;
         delete $dbug_global_vars{mask_func_call};
      }
      return;
   }

   # Optionally mask your function arguments ...
   if ( exists $dbug_global_vars{mask_func_call} ) {
      my $mask = $dbug_global_vars{mask_func_call};
      if ( $mask->{ALL} ) {
         foreach (0..$#args) {
            $args[$_] = MASKING_VALUE;
            ++$dbug_global_vars{mask_last_argument_count};
         }
      }
      if ( $mask->{ARRAY} ) {
         foreach ( @{$mask->{ARRAY}} ) {
            if ( $_ <= $#args ) {
               $args[$_] = MASKING_VALUE;
               ++$dbug_global_vars{mask_last_argument_count};
            }
         }
      }
      if ( $mask->{HASH} ) {
         my $mask_flag = 0;
         foreach (0..$#args) {
            if ( $mask_flag ) {
               $args[$_] = MASKING_VALUE;
               $mask_flag = 0;
               ++$dbug_global_vars{mask_last_argument_count};
            } else {
               my $k = lc ($args[$_]);   # All keys are in lower case.
               $mask_flag = 1  if ( exists $mask->{HASH}->{$k} );
            }
         }
      }
      delete $dbug_global_vars{mask_func_call};
   }

   # Convert any code refs into it's function name ...
   foreach (0..$#args) {
      if ( ref ( $args[$_] ) eq "CODE" ) {
         my $f = sub_fullname ( $args[$_] );
         $f = $1   if ( $dbug_global_vars{strip} && $f =~ m/::([^:]+)$/ );
         $args[$_] = '\&' . $f;
      }
   }

   if ( $dbug_global_vars{no_addresses} ) {
      my $i = 0;
      foreach (0..$#args) {
         if ( ref ( $args[$_] ) ne "" ) {
            $args[$_] = sprintf ("%s(%03d)", ref ( $args[$_] ), ++$i);
         }
      }
   }

   # Now format the arugment list you need to print out ...
   my ($sep, $msg) = ("", "");
   foreach (0..$#args) {
      my $val = (defined $args[$_]) ? $args[$_] : UNDEF_VALUE;

      $msg .= $sep . "[${val}]";
      $sep = ", ";
   }

   _dbug_print_no_delay_or_caller ("args", $msg);

   return;
}


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
sub DBUG_ENTER_BLOCK
{
   my $block_name = shift;

   $block_name = "[undef]"  unless ( defined $block_name );

   # Strip off any module info from the passed block name?
   $block_name = $1   if ( $dbug_global_vars{strip} && $block_name =~ m/::([^:]+)$/ );

   # Determine if the caller info is needed at this point.
   my $line="";
   if ( $dbug_global_vars{who_called} ) {
      $line = _dbug_called_by (0);
   }

   # Check if eval needs rebalancing ...
   _dbug_auto_fix_eval_exception ();

   my @colors = _get_filter_color (DBUG_FILTER_LEVEL_FUNC);
   if ( DBUG_EXECUTE ( DBUG_FILTER_LEVEL_FUNC ) ) {
      _printing ( $colors[0], _indent (">>${block_name}${line}"), $colors[1], "\n");
   }

   my ($eval_dp, $eval_lns) = _eval_depth (1);
   my %block = ( NAME    => $block_name,
                 PAUSED  => $dbug_global_vars{pause},
                 EVAL    => $eval_dp,
                 EVAL_LN => $eval_lns->[0],
                 LINE    => $line,
                 FUNC    => 0,
                 COLOR1  => $colors[0],
                 COLOR2  => $colors[1] );
   $block{TIME} = time ()  if ( $dbug_global_vars{elapsed} );
   $block{MULTI} = _indent_multi (1)  if ( $dbug_global_vars{multi} );

   push ( @{$dbug_global_vars{functions}}, \%block );

   _dbug_args ( @_ );

   return ( $block_name );
}


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
# Determine the current filter level from the tag's value ...
sub _filter_lvl
{
   my $tag = shift || "";    # The keyword/tag passed to DBUG_PRINT!
                             # or _filter_on() or DBUG_EXECUTE() ...

   # Not recomended: But someone always tries it ...
   # If you used one of the DBUG_FILTER_LEVEL_... constants instead
   # of a string in your DBUG_PRINT($tag,...) call.
   # So if valid just return it as the level selected!
   # Also greatly helped with Custom Filtering to allow this.
   if ( $tag =~ m/^\d+$/ && defined $dbug_levels[$tag] ) {
      return ( wantarray ? ($tag, $tag) : $tag );
   }

   my $utag = uc ( $tag );   # The tag in upper case!

   # Assume this level until proven otherwise ...
   my $fltr_lvl = DBUG_FILTER_LEVEL_OTHER;   # Filtering ...
   my $clr_lvl = $fltr_lvl;                  # Coloring ...

   my $pkg = __PACKAGE__;

   if ( $tag eq "args" ) {
      $fltr_lvl = $clr_lvl = DBUG_FILTER_LEVEL_ARGS;
   } elsif ( $utag eq "ERROR" ) {
      $fltr_lvl = $clr_lvl = DBUG_FILTER_LEVEL_ERROR;
   } elsif ( $utag eq "STDOUT" || $utag eq "STDERR") {
      $fltr_lvl = $clr_lvl = DBUG_FILTER_LEVEL_STD;
   } elsif ( $utag eq "WARN" || $utag eq "WARNING" ) {
      $fltr_lvl = $clr_lvl = DBUG_FILTER_LEVEL_WARN;
   } elsif ( $utag eq "DEBUG" || $utag eq "DBUG" ) {
      $fltr_lvl = $clr_lvl = DBUG_FILTER_LEVEL_DEBUG;
   } elsif ( $utag eq "INFO" ) {
      $fltr_lvl = $clr_lvl = DBUG_FILTER_LEVEL_INFO;

   # The 3 different ways to specify internal levels ...
   } elsif ( $utag eq "INTERNAL" ) {
      $fltr_lvl = $clr_lvl = DBUG_FILTER_LEVEL_INTERNAL;
   } elsif ( $tag eq __PACKAGE__ ) {
      $fltr_lvl = $dbug_global_vars{pkg_lvl} || DBUG_FILTER_LEVEL_INTERNAL;
      $clr_lvl  = DBUG_FILTER_LEVEL_INTERNAL;
   } elsif ( $tag =~ m/^${pkg}::/ ) {
      $fltr_lvl = $dbug_global_vars{pkg_lvl} || DBUG_FILTER_LEVEL_INTERNAL;
      $clr_lvl  = DBUG_FILTER_LEVEL_INTERNAL;
   }

   return ( wantarray ? ($fltr_lvl, $clr_lvl) : $fltr_lvl );
}

# ==============================================================
# Does the filter rule say it's OK to print things?
# Based on the keyword/tag value ($_[0]) ...
# Or the DBUG_FILTER_LEVEL_... constants ...
sub _filter_on
{
   my $lvl = _filter_lvl ( $_[0] );

   if ( $dbug_global_vars{filter_style} >= 0 ) {
      return ( $lvl <= $dbug_global_vars{filter} );    # Standard filtering ...
   } else {
      return ( $dbug_custom_levels[$lvl] );            # Custom filtering ...
   }
}

# ==============================================================
# So can always call DBUG_PRINT internally without any delays or caller info ...
sub _dbug_print_no_delay_or_caller
{
   local $dbug_global_vars{delay} = 0;        # Don't delay on this call ...
   local $dbug_global_vars{who_called} = 0;   # Don't add caller info ...
   return DBUG_PRINT (@_);
}

# ==============================================================
# So can print with tag PACKAGE with custom internal levels ...
sub _dbug_print_pkg_tag
{
   my $level = shift;      # if undef, don't change the level!

   $level = $dbug_global_vars{pkg_lvl}  unless ( $level );

   local $dbug_global_vars{pkg_lvl} = $level;

   my $pkg = __PACKAGE__;
   if ( $_[0] && $_[0] =~ m/^::[^:]/ ) {
      $pkg .= shift;
   }

   return ( _dbug_print_no_delay_or_caller ( $pkg, @_ ) );
}

# ==============================================================
# Make as efficient as possible since this is the most frequently called method!
# And usually the return value is tossed!
# ------------------------------------------------------------------
sub DBUG_PRINT
{
   my ($keyword, $fmt, @values) = @_;

   # Check if untrapped eval needs rebalancing ...
   _dbug_auto_fix_eval_exception ();

   # If undef, the caller wasn't interested in any return value!
   my $want_return = wantarray;   # Or could have used: (caller(0))[5] instead;

   my $fish_on = DBUG_EXECUTE ( $keyword );

   # -------------------------------------------------------------------
   # A no-op if fish isn't turned on & you don't want the return value!
   # Very, very common!
   # -------------------------------------------------------------------
   unless ( defined $want_return ) {
      unless ( $fish_on ) {
         return (undef);      # Not interested in the return value ...
      }
   }

   # ---------------------------------------------------------
   # Build the message that we want to print out.
   # ---------------------------------------------------------
   # Also converts any CODE references encountered.
   # ---------------------------------------------------------
   my $msg;
   if ( ! defined $fmt ) {
      $msg = "";
   } elsif ( $#values == -1 ) {
      $msg = $fmt;
      if ( ref ($fmt) eq "CODE" ) {
         my $f = sub_fullname ($fmt);
         $f = $1   if ( $dbug_global_vars{strip} && $f =~ m/::([^:]+)$/ );
         $msg = '\&' . $f;
      }
   } else {
      # Get rid of undef warnings & CODE references for sprintf() ...
      foreach (@values) {
         $_ = ""   unless ( defined $_ );
         if ( ref ($_) eq "CODE" ) {
            my $f = sub_fullname ($_);
            $f = $1   if ( $dbug_global_vars{strip} && $f =~ m/::([^:]+)$/ );
            $_ = '\&' . $f;
         }
      }
      $msg = sprintf ( $fmt, @values );
   }

   # ---------------------------------------------------------
   # Split the resulting message into multiple lines ...
   # ---------------------------------------------------------
   my @lines = split ( /[^\S\n]*\n/, $msg );  # Split on "\n" & trim!
   push (@lines, "")   if ( $#lines == -1 );  # Must have at least one line!

   if ( defined $want_return ) {
      $msg = join ( "\n", @lines ) . "\n";    # Put back together trimmed!
   } else {
      $msg = undef;    # The message wasn't wanted!
   }

   # ---------------------------------------------------------
   # Only do this complex work if fish is turned on ...
   # ---------------------------------------------------------
   if ( $fish_on ) {
      my $sep = _indent ("${keyword}: ");
      my $len = length ($sep) - 2;         # Doesn't count the trailing ": ".

      my $help_str = _indent_multi ();
      $len = $len - length ($help_str);

      my ($level, $color_lvl) = _filter_lvl ($keyword);

      # Check if the caller info needs to be retuned as part of $msg ...
      if ( $dbug_global_vars{who_called} ) {
         my $ln = _dbug_called_by (1);
         # unshift (@lines, $ln);    # Put before the message.
         push (@lines, $ln);         # Put after the message.
      }

      if ( $dbug_global_vars{delay} ) {
         if ( $time_hires_flag ) {
            push (@lines, sprintf ("Sleeping %0.6f second(s)", $dbug_global_vars{delay}));
         } else {
            push (@lines, sprintf ("Sleeping %d second(s)", $dbug_global_vars{delay}));
         }
      }

      my @colors = _get_filter_color ( $color_lvl );

      # Indent each line of the message ... (note: \s includes \n!)
      my ($output, $spaces) = ("", ${help_str} . " "x${len} . ": ");
      foreach my $row (@lines) {
         $output .= $colors[0] . ${sep} . $row . $colors[1] . "\n";
         $sep = $spaces;
      }
      my $flg = _printing ($output);

      if ( $flg && $dbug_global_vars{delay} ) {
         sleep ( $dbug_global_vars{delay} );
      }
   }

   return ( $msg );     # Returns what was printed out to the fish file.
}


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
# Tells which return values are to be masked ...
# The index to the values to mask are returned as keys to a hash.
sub _dbug_mask_expect
{
   my $func = shift;    # The return func block hash ref.
   my $max  = shift;    # The count of return values. (-1 is no args)
   my $args = shift;    # A reference to the list of args to DBUG_RETURN.

   # Did we decide to mask specific values by offset ??
   my %mask = %{$func->{AMASK}}  if ( exists $func->{AMASK} );
   my $all  = $mask{-1};   # Did we say mask everything returned???

   # Did we decide to mask specific hash values ??
   # If so, get the offset to that hash key's value!
   unless ( $all ) {
      if ( exists $func->{HMASK} && $max > 0 ) {
         my $idx = (($max % 2) == 0) ? 1 : 0;
         while ( $idx <= $max ) {
            my $key = $args->[$idx];  # The key to check for
            my $iv = $idx + 1;        # It's value
            $idx += 2;                # Skip to the next key

            next unless ( defined $key );
            next unless ( exists $func->{HMASK}->{$key} );
            $mask{$iv} = 1;    # Mark this key's value as maskable!
         }
      }
   }

   # Now count how many of the return values would be masked ...
   my $cnt = 0;
   foreach (0..$max) {
      ++$cnt  if ( $all || $mask{$_} );
   }

   # The keys to this hash are it's offsets!
   return ($cnt, %mask);
}

# ==============================================================
sub DBUG_RETURN
{
   my @args = @_;

   # Check if untrapped eval needs rebalancing ...
   _dbug_auto_fix_eval_exception ();

   # Pop off the function being returned ...
   my $block = pop ( @{$dbug_global_vars{functions}} );

   # Will this turn pause off ???
   unless ( $block->{PAUSED} ) {
      $dbug_global_vars{pause} = 0;    # Yes!
   }

   # How many of the return values are to be masked in fish ...
   $dbug_global_vars{mask_return_count} = 0;    # Actual count
   my %mask;

   # ------------------------------------------------------------------------
   # If undef, the caller wasn't interested in looking at any return values!
   # Assume that its planing on doing a normal "return" later on and you just
   # wanted to see what the expected return values are in fish.
   # But DBUG_RETURN() will still return undef to the caller in this case!
   # ------------------------------------------------------------------------
   # See t/15-return_simple.t for examples of this type of return.
   # It's too difficult to explain otherwise.
   # ------------------------------------------------------------------------
   my $fish_return = wantarray;   # Or could have used: (caller(0))[5] instead.

   unless ( defined $fish_return ) {
      my $func;
      my $called_by_special = __PACKAGE__ . "::DBUG_RETURN_SPECIAL";
      my $called_by_special2 = __PACKAGE__ . "::DBUG_ARRAY_RETURN";
      ($func, $fish_return) = (caller(1))[3,5];
      $fish_return = (caller(2))[5]    if ( defined $func && ($func eq $called_by_special || $func eq $called_by_special2) );
   }

   # Take a shortcut if fish is currently disabled ...
   unless ( DBUG_EXECUTE ( DBUG_FILTER_LEVEL_FUNC ) ) {
      my $unknown = ( exists $block->{AMASK} || exists $block->{HMASK} ) ? -1 : 0;
      if ( ! defined $fish_return ) {
         return ( undef );     # Return value is being ignored!
      } elsif (  DBUG_EXECUTE ( DBUG_FILTER_LEVEL_ARGS ) ) {
         ;    # Can't quit now, we have return values to print out!
      } elsif ( $fish_return ) {
         $dbug_global_vars{mask_return_count} = $unknown;
         return ( @args );     # Array context ...
      } else {
         $dbug_global_vars{mask_return_count} = $unknown;
         return ( $args[0] );  # Scalar context ...
      }
   }

   # From here on down we know we know we'll write something to fish ...

   # How many of the arguments do we expect to mask when we print them out ...
   my $max = $#args;
   if ($max != -1) {
      $max = ($fish_return ? $#args : 0);
      ($dbug_global_vars{mask_return_count}, %mask) =
                          _dbug_mask_expect ($block, $max, \@args);
   }

   my @colors = _get_filter_color (DBUG_FILTER_LEVEL_ARGS);

   my $func = $block->{NAME};
   my $lbl = ( $block->{FUNC} ) ? "<" : "<<";
   my $ret = $block->{COLOR1};
   $ret .= _indent ("${lbl}${func} - return (");
   $ret .= $block->{COLOR2} . $colors[0];

   unless ( _filter_on ( DBUG_FILTER_LEVEL_ARGS ) ) {
      $ret .= "?";    # Don't print the return value(s) to fish ...

   # Do we have any return values to print to fish ???
   } elsif ( $max != -1 && defined $fish_return ) {
      my $all = $mask{-1};   # Did we request to mask all return values ???

      # Now let's build the return value list to print to fish ...
      my $sep = "";
      my $cnt = 0;     # Count return values masked.
      my $i   = 500;   # Count reference addresses dereferenced.

      foreach (0..$max) {
         my $val;

         if ( $all || $mask{$_} ) {
            $val = MASKING_VALUE;            # Let's mask it ...
            ++$cnt;                          # Count it!
         } elsif ( ! defined $args[$_] ) {
            $val = UNDEF_VALUE;
         } elsif ( ref ($args[$_]) eq "CODE" ) {
            my $f = sub_fullname ( $args[$_] );
            $f = $1   if ( $dbug_global_vars{strip} && $f =~ m/::([^:]+)$/ );
            $val = '\&' . $f;
         } elsif ( $dbug_global_vars{no_addresses} &&  ref ($args[$_]) ne "" ) {
            $val = sprintf ("%s(%03d)", ref ($args[$_]), ++$i);
         } else {
            $val = $args[$_];
         }

         $ret .= $sep . "[" . $val . "]";
         $sep = ", ";
      }

      # Should never happen ...
      if ( $cnt != $dbug_global_vars{mask_return_count} ) {
         _dbug_print_pkg_tag ( DBUG_FILTER_LEVEL_INFO,
                               "Expected %d masked return values and found %d.",
                               $dbug_global_vars{mask_return_count}, $cnt );
         $dbug_global_vars{mask_return_count} = $cnt;
      }
   }

   # Finishing up all paths ...
   $ret .= $colors[1] . $block->{COLOR1} . ")";
   $ret .= _dbug_elapsed_time ($block->{TIME})   if ( $dbug_global_vars{elapsed} );
   $ret .= $block->{COLOR2} . "\n";

   _printing ($ret);

   if ( $fish_return ) {
      return ( @args );     # Array context ...
   } elsif ( defined $fish_return ) {
      return ( $args[0] );  # Scalar context ...
   } else {
      return ( undef );     # Return value is being ignored!
   }
}


=item DBUG_ARRAY_RETURN ( @args )

A variant of S<"DBUG_RETURN()"> that behaves the same as perl does natively when
returning a list to a scalar.  IE it returns the # of elements in the @args
array.

It always assumes @args is a list, even when provided a single scalar value.

=cut

# ==============================================================
sub DBUG_ARRAY_RETURN
{
   my @args = @_;

   unless ( defined wantarray ) {
      return DBUG_VOID_RETURN ();
   }

   if ( wantarray ) {
      return DBUG_RETURN ( @args );
   }

   my $cnt = @args;         # The number of elements in the array.
   return DBUG_RETURN ( $cnt )
}


=item DBUG_VOID_RETURN ( )

Terminates the current block of B<fish> code.  It doesn't return any value back
to the calling function.

=cut

# ==============================================================
sub DBUG_VOID_RETURN
{
   # Check if untrapped eval needs rebalancing ...
   _dbug_auto_fix_eval_exception ();

   # Pop off the function being returned ...
   my $block = pop ( @{$dbug_global_vars{functions}} );

   unless ( $block->{PAUSED} ) {
      $dbug_global_vars{pause} = 0;

      if ( DBUG_EXECUTE ( DBUG_FILTER_LEVEL_FUNC ) ) {
         my $func = $block->{NAME};
         my $lbl = ( $block->{FUNC} ) ? "<" : "<<";
         _printing ( $block->{COLOR1}, _indent ("${lbl}${func} ()"),
                     _dbug_elapsed_time ($block->{TIME}),
                     $block->{COLOR2}, "\n" );
      }
   }

   # No return values can ever be masked here!
   $dbug_global_vars{mask_return_count} = 0;

   return (undef);   # Undef just in case someone looks!
}


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
# Must always call DBUG_RETURN() or DBUG_VOID_RETURN ()
# to handle all the bookkeeping!
# --------------------------------------------------------------
sub DBUG_RETURN_SPECIAL
{
   my $scalar = shift;     # Just take the scalar of the stack ...

   # Caller is asking for an array of values ...
   if  ( wantarray ) {
      return DBUG_RETURN ( @_ );
   }

   # Check if we have to monkey with the return value masking ...
   my $last_masked = 0;
   my %new_mask;
   if ( $scalar eq DBUG_SPECIAL_LAST && exists $dbug_global_vars{functions}->[-1]->{AMASK} ) {
       my $msk = $dbug_global_vars{functions}->[-1]->{AMASK};
       if ( $msk->{$#_ + 0} ) {
          $new_mask{0} = 1;
          $last_masked = 1;
       } elsif ( $msk->{0} ) {
          $last_masked = 1;
       }
   }

   # ------------------------------------------------------------------------
   # If undef, the caller wasn't interested in looking at any return values!
   # Assume that its planing on doing a normal "return" later on and you just
   # wanted to see what the expected return values are in fish.
   # But DBUG_RETURN_SPECIAL() will still return undef to the caller no
   # matter what's written to fish in this case!
   # ------------------------------------------------------------------------
   # See "t/16-return_special_scalar_join.t" for examples of this type of
   # return.  It's just too difficult to explain otherwise.
   # ------------------------------------------------------------------------
   #   return_test_1 () - Shows the expected way to use this function.
   #   return_test_2 () - Shows the problem way on why this code is complex.
   #            I don't recommend you use DBUG_RETURN_SPECIAL() this 2nd way.
   #   deep_test_1 ()   - Shows how your intuition may be wrong!
   # ------------------------------------------------------------------------
   unless ( defined wantarray ) {
      my $parent_wantarray = (caller(1))[5];

      # If called like return_test_1 () ... (expected way)
      return DBUG_VOID_RETURN ()  unless ( defined $parent_wantarray );

      # If called like return_test_2 () ... (problem way)
      return DBUG_RETURN ( @_ )   if ( $parent_wantarray );

      # Not doing the CODE ref conversion on purpose!  Since not saving any
      # return value we want to avoid any potenial side affects due to
      # calling the CODE ref function.
      if ( defined $scalar ) {
         if ( $scalar eq DBUG_SPECIAL_ARRAYREF ) {
            $scalar = \@_;
         } elsif ( $scalar eq DBUG_SPECIAL_COUNT ) {
            $scalar = scalar (@_);
         } elsif ( $scalar eq DBUG_SPECIAL_LAST ) {
            $scalar = $_[-1];
         }
      }

      if ( $last_masked ) {
         local  $dbug_global_vars{functions}->[-1]->{AMASK};
         $dbug_global_vars{functions}->[-1]->{AMASK} = \%new_mask;
         return DBUG_RETURN ( $scalar );
      } else {
         return DBUG_RETURN ( $scalar );
      }
   }

   # ------------------------------------------------------------------------
   # If you get here, you want a scalar value returned ...
   # Was it one of the special case values???
   # ------------------------------------------------------------------------
   if ( defined $scalar ) {
      if ( ref ($scalar) eq "CODE" ) {
         my $res = $scalar->( @_ );
         return DBUG_RETURN ( $res );
      } elsif ( $scalar eq DBUG_SPECIAL_ARRAYREF ) {
         my @args = @_;
         return DBUG_RETURN ( \@args );
      } elsif ( $scalar eq DBUG_SPECIAL_COUNT ) {
         return DBUG_RETURN ( scalar (@_) );
      } elsif ( $scalar eq DBUG_SPECIAL_LAST && ! $last_masked ) {
         return DBUG_RETURN ( $_[-1] );
      } elsif ( $scalar eq DBUG_SPECIAL_LAST && $last_masked ) {
         local  $dbug_global_vars{functions}->[-1]->{AMASK};
         $dbug_global_vars{functions}->[-1]->{AMASK} = \%new_mask;
         return DBUG_RETURN ( $_[-1] );
      }
   }

   # Not a special case ... returning the literal value!
   DBUG_RETURN ( $scalar );
}


=item DBUG_LEAVE ( [$status] )

This function terminates your program with a call to I<exit()>.  It expects a
numeric argument to use as the program's I<$status> code, but will default to
zero if it's missing.  It is considered the final return of your program.

Only module B<END> and B<DESTROY> blocks can be logged after this function is
called as Perl cleans up after itself, unless you turned this feature off with
option B<kill_end_trace> when B<fish> was first enabled.

=cut

# ==============================================================
sub DBUG_LEAVE
{
   my $status        = shift || 0;

   # Check if untrapped eval needs rebalancing ...
   _dbug_auto_fix_eval_exception ();

   # Pop off the function being returned ...
   my $block = pop ( @{$dbug_global_vars{functions}} );

   if ( DBUG_EXECUTE ( DBUG_FILTER_LEVEL_FUNC ) ) {
      my $func;
      my @colors;
      my $lbl = "<";
      my $elaps = "";
      unless ( defined $block ) {
         $func = " *** Unbalanced Returns *** Potential bug in your code!";
         $colors[0] = $colors[1] = "";
      } else {
         $func = $block->{NAME};
         $colors[0] = $block->{COLOR1};
         $colors[1] = $block->{COLOR2};
         $lbl = "<<"  unless ( $block->{FUNC} );
         $elaps = _dbug_elapsed_time ( $block->{TIME} )  if ( $dbug_global_vars{elapsed} );
      }

      $dbug_global_vars{printed_exit_status} = _printing (
                $colors[0], _indent ("${lbl}${func}"), $elaps, $colors[1], "\n",
                _indent_multi (), "exit ($status)\n\n" );
   }

   _dbug_leave_cleanup ();

   exit ($status);        # Exit the program!  (This isn't trappable by eval!)
}


# Broken out so I can call from END block and
# Fred::Fish::DBUG::OFF as well.
# So that we can trace all the END/DESTROY blocks cleanly ...
sub _dbug_leave_cleanup
{
   $dbug_global_vars{pause} = 0;

   my @empty;
   @{$dbug_global_vars{functions}} = @empty;

   # Are we tracing the END/DESTROY blocks after all?
   $dbug_global_vars{on} = 0   if ( $dbug_global_vars{no_end} );

   # So any requested caller info/line numbers are never printed out ...
   $dbug_global_vars{who_called} = 0;

   # Tells the END code DBUG_LEAVE was aleady called.
   $dbug_global_vars{dbug_leave_called} = 1;

   return;
}


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
sub DBUG_CATCH
{
   # No matter what, when called don't disable rebalancing the stack!
   local $dbug_global_vars{skip_eval_fix} = 0;

   _dbug_auto_fix_eval_exception (1);

   return;
}

# --------------------------------------------------------------
# Auto-handles dynamic DBUG_CATCH logic ... It's a real mess!
# This was the reason keys EVAL_LN & MULTI were added to the function block ...
# Called whenever anything writes to the fish logs ...
# --------------------------------------------------------------
# Works since "eval" is in Perl's stack trace and I can easily detect from the
# fish stack if we're still in the same eval block of code.
# It works for "try" since it eventually puts an "eval" onto the stack itself.
# --------------------------------------------------------------
# Doesn't work for perl -we '...' scripts since everything is a 1 liner!
# --------------------------------------------------------------
# Too bad we can't auto-balance other usage issues with this module.

sub _dbug_auto_fix_eval_exception
{
   my $from_dbug_catch_flag = shift || 0;

   return  if ( $dbug_global_vars{skip_eval_fix} );

   my ($eval_cnt, $eval_lns) = _eval_depth (2);

   my @list = @{$dbug_global_vars{functions}};

   my $pop_msg = $from_dbug_catch_flag
                  ? "   *** Caught eval/try trap and popped the fish stack! ***"
                  : "   *** Auto-balancing the fish stack again after leaving an eval/try block! ***";

   foreach my $b ( reverse @list ) {
      last  if ( $b->{EVAL} < $eval_cnt );
      last  if ( $eval_cnt == 0 && $b->{EVAL} == 0 );

      # Don't pop items owned by another thread/PID ...
      last  if ( exists $b->{MULTI} && $b->{MULTI} ne _indent_multi (1) );

      # Checking if in the same eval block.  May have to add a filename
      # comparision to this logic in the future.
      # IE two evals with the same depth & line numbers from different files.
      if ( $b->{EVAL} == $eval_cnt ) {
         last  if ( $b->{EVAL_LN} == $eval_lns->[0] );
         --$eval_cnt;
         shift ( @{$eval_lns} );
      }

      # Now lets pop off the bypassed return calls ...
      pop ( @{$dbug_global_vars{functions}} );

      unless ( $b->{PAUSED} ) {
         $dbug_global_vars{pause} = 0;

         if ( DBUG_EXECUTE ( DBUG_FILTER_LEVEL_FUNC ) ) {
            my $func = $b->{NAME};
            my $lbl = ( $b->{FUNC} ) ? "<" : "<<";
            my $elaps = _dbug_elapsed_time ($b->{TIME});
            _printing $b->{COLOR1}, _indent ("${lbl}${func}"), $pop_msg, $elaps, $b->{COLOR2}, "\n";
         }
      }
   }

   return;
}


=item DBUG_PAUSE ( )

Temporarily turns B<fish> off until the pause request goes out of scope.  This
allows you to conditionally disable B<fish> for particularly verbose blocks of
code or any other reason you choose.

The scope of the pause is defined as the previous call to a I<DBUG_ENTER>
function variant and it's coresponding call to a I<DBUG_RETURN> variant.

While the pause is active, calling it again does nothing.

=cut

# ==============================================================
sub DBUG_PAUSE
{
   return  if ( $dbug_global_vars{pause} );

   _dbug_print_pkg_tag ( DBUG_FILTER_LEVEL_INFO,
                         "PAUSE: Fish has been paused!  In %s",
                         _dbug_called_by (1) );

   $dbug_global_vars{pause} = 1;

   return;
}


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
sub DBUG_MASK
{
   my @lst = sort (@_);    # So the list of offsets are in predictable order.

   return  if ( $#lst == -1 );


   # Silently drop any invalid masking offset.
   my (%amask, %hmask);
   my ($acnt,  $hcnt)  = (0, 0);
   foreach my $idx (@lst) {
      next  unless ( defined $idx );
      next  if ( $idx =~ m/^\s*$/ );

      # if non-numeric ... assume it's a hash key to match.
      unless ( $idx =~ m/^-?\d+$/ ) {
         $hmask{$idx} = 1;
         ++$hcnt;
         next;
      }

      ++$acnt;
      if ( $idx <= -1 ) {
         $amask{-1} = 1;
         $hcnt = 0;
         last;
      }

      $amask{$idx + 0} = 1;    # The +0 removes leading 0's.
   }

   # Updates the most recent ENTER block ...
   if ( $acnt > 0 ) {
      $dbug_global_vars{functions}->[-1]->{AMASK} = \%amask;
   } else {
      delete $dbug_global_vars{functions}->[-1]->{AMASK};
   }
   if ( $hcnt > 0 ) {
      $dbug_global_vars{functions}->[-1]->{HMASK} = \%hmask;
   } else {
      delete $dbug_global_vars{functions}->[-1]->{HMASK};
   }

   return;
}


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
sub DBUG_MASK_NEXT_FUNC_CALL
{
   my @args = @_;

   delete $dbug_global_vars{mask_func_call};

   return  if ( $#args == -1 );

   my (@offsets, %mask);
   my ($acnt, $hcnt, $all) = (0, 0, 0);

   foreach my $idx (@args) {
      next  unless ( defined $idx );
      next  if ( $idx =~ m/^\s*$/ );

      if  ( $idx =~ m/^-\d+$/ ) {
         if ( $idx == -1 ) {
            $acnt = $hcnt = 0;
            $all = 1;
            last;
         }

      } elsif ( $idx =~ m/^\d+$/ ) {
         push (@offsets, $idx);
         ++$acnt;

      } else {
         $mask{lc($idx)} = 1;   # Make case insensitive.
         ++$hcnt;
      }
   }

   # Register that the next call to DBUG_ENTER_FUNC() should mask it's values!
   if ( ($acnt + $hcnt + $all) > 0 ) {
      my %mask_it;

      $mask_it{ALL}  = $all;
      $mask_it{HASH} = \%mask     if ( $hcnt > 0 );

      if ( $acnt > 0 ) {
         @offsets = sort (@offsets);
         $mask_it{ARRAY} = \@offsets;
      }

      $dbug_global_vars{mask_func_call} = \%mask_it;
   }

   return;
}


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
sub DBUG_FILTER
{
   my $level = shift;

   my $old_lvl;
   if ( $dbug_global_vars{filter_style} == 1 ) {
      $old_lvl = $dbug_global_vars{filter} || DBUG_FILTER_LEVEL_MAX;
   } else {
      $old_lvl = -1;      # Currently using custom filtering ...
   }
   my $new_lvl = $old_lvl;

   # Only update the level if it's valid ...
   if ( $level && $level =~ m/^\d+$/ ) {
      if (DBUG_FILTER_LEVEL_MIN <= $level && $level <= DBUG_FILTER_LEVEL_MAX) {
         $new_lvl = $dbug_global_vars{filter} = $level;
      } elsif ( $level == DBUG_FILTER_LEVEL_INTERNAL ) {
         $new_lvl = $dbug_global_vars{filter} = $level;
      }

      if ( $old_lvl != $new_lvl ) {
         my $old = ($old_lvl == -1) ? "Custom Level" : ($dbug_levels[$old_lvl] || $old_lvl);
         my $new = $dbug_levels[$new_lvl] || $new_lvl;
         my $direction = ($old_lvl > $new_lvl) ? "down to" : "up to";

         # Standard Style ...
         $dbug_global_vars{filter_style} = 1;

         # Determine index to whom to say was our caller.
         my $c = (caller(1))[3] || "";

         _dbug_print_pkg_tag ( DBUG_FILTER_LEVEL_MIN,
                      "The fish filtering level was changed from\n%s %s %s\n%s",
                      $old, $direction, $new, _dbug_called_by (1) );
      }
   }

   return ( wantarray ? ( $old_lvl, $new_lvl ) : $old_lvl );
}


=item DBUG_CUSTOM_FILTER ( @levels )

This function allows you to customize which filter level(s) should appear in
your B<fish> logs.  You can pick and choose from any of the levels defined by
I<DBUG_FILTER()>.  If you provide an invalid level, it will be silently ignored.
Any level not listed will no longer appear in B<fish>.

=cut

# ==============================================================
sub DBUG_CUSTOM_FILTER
{
   # Convert this list of arguments into a hash of valid levels ...
   my %levels;
   foreach my $lvl (@_) {
      next unless ( defined $lvl && $lvl =~ m/^\d+$/ );

      if (DBUG_FILTER_LEVEL_MIN <= $lvl || $lvl <= DBUG_FILTER_LEVEL_MAX) {
         $levels{$lvl + 0} = 1;
      } elsif ( $lvl == DBUG_FILTER_LEVEL_INTERNAL ) {
         $levels{DBUG_FILTER_LEVEL_INTERNAL} = 1;
      }
   }

   my ( $msg, $sep, $plvl ) =  ( "", "", DBUG_FILTER_LEVEL_MIN );

   # Now lets turn on/off the individual filter levels ...
   foreach (DBUG_FILTER_LEVEL_MIN..DBUG_FILTER_LEVEL_MAX, DBUG_FILTER_LEVEL_INTERNAL) {
      $dbug_custom_levels[$_] = ( $levels{$_} ) ? 1 : 0;
      if ( $dbug_custom_levels[$_] ) {
         $msg .= ${sep} . $dbug_levels[$_];
         $plvl = $_   if ( $sep eq "" );
         $sep = ", ";
      }
   }

   # Custom Style ...
   $dbug_global_vars{filter_style} = -1;

   # What if called by the inverse function?
   my $c = (caller(1))[3] || "";
   return  if ( $c eq __PACKAGE__ . "::DBUG_CUSTOM_FILTER_OFF" );

   _dbug_print_pkg_tag ( $plvl, "The filtering level was changed to custom level(s): %s", $msg );

   return;
}


=item DBUG_CUSTOM_FILTER_OFF ( @levels )

This function is the reverse of I<DBUG_CUSTOM_FILTER>.  Instead of specifying
the filter levels you wish to see, you specify the list of levels you don't
want to see.  Sometimes it's just easier to list what you don't want to see
in B<fish>.

=cut

# ==============================================================
sub DBUG_CUSTOM_FILTER_OFF
{
   DBUG_CUSTOM_FILTER ( @_ );     # Set to custom filter levels ...

   my ( $msg, $sep, $plvl ) =  ( "", "", DBUG_FILTER_LEVEL_MIN );

   # Now lets invert the on/off settings of the individual filter levels ...
   foreach (DBUG_FILTER_LEVEL_MIN..DBUG_FILTER_LEVEL_MAX, DBUG_FILTER_LEVEL_INTERNAL) {
      $dbug_custom_levels[$_] = ( $dbug_custom_levels[$_] ) ? 0 : 1;

      if ( $dbug_custom_levels[$_] ) {
         $msg .= ${sep} . $dbug_levels[$_];
         $plvl = $_   if ( $sep eq "" );
         $sep = ", ";
      }
   }

   _dbug_print_pkg_tag ( $plvl, "The filtering level was changed to custom level(s): %s", $msg );

   return;
}


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
sub DBUG_SET_FILTER_COLOR
{
   my $level      = shift;   # Always non-zero ...
   my @color_attr = @_;      # List of color attributs.

   # If color not supported ...
   return (0)   if ( $color_supported == 0 );

   my $valid_level = 0;
   if ( $level && $level =~ m/^\d+$/ ) {
      if ( (DBUG_FILTER_LEVEL_MIN <= $level && $level <= DBUG_FILTER_LEVEL_MAX) ||
           ($level == DBUG_FILTER_LEVEL_INTERNAL) ) {
         $valid_level = 1;
      }
   }

   # Merge all the color attributes into a single escape sequence string ...
   my $color_str = "";
   if ( $valid_level ) {
      local $ENV{ANSI_COLORS_DISABLED} = 0;       # Enable colors!
      local $SIG{__DIE__} = "";                   # Disable any die customization ...

      foreach my $cm ( @color_attr ) {
         next  unless (defined $cm);
         next  if ( $cm =~m/^\s*$/ );
         eval {
            # Throws an exception if not a valid color string such as "red",
            # "red on_yellow", or "bold red on_yellow".
            my $str = color ($cm);     # Convert to an escape sequence ...
            $color_str .= $str;
            # print STDERR "Valid Color String '$cm'\n";
         };
         if ( $@ ) {
            eval {
               # Throws exception if color value wasn't from a color macro!
               # Ex: use Term::ANSIColor qw(:constants); $color = RED;
               # Not all color macro values are escape sequences ...
               my @str = Term::ANSIColor::uncolor ($cm);
               foreach my $s ( @str ) {
                  $color_str .= color ($s);     # Makes sure always an escape sequence ...
               }
               # print STDERR "Valid Color Macro(s): '", join (", ", @str), "'\n";
            };
            if ( $@ ) {
               warn ("Invalid color string '$cm'.\nColor request reset to no colors for level $dbug_levels[$level]!\n");
               $color_str = "";
               last;
            }
         }
      }
   }

   # Save the results ...
   if ( $valid_level ) {
      if ( $color_str ) {
         local $ENV{ANSI_COLORS_DISABLED} = 0;       # Enable colors!
         $color_list[$level] = $color_str;           # Get the escape sequence for this color.
         $color_clear = color ("clear");             # Back to defaults.
      } else {
         delete ( $color_list[$level] );
      }
   }

   return ( $valid_level );
}


# ==============================================================
# Get the colors to use for the current filter level.
sub _get_filter_color
{
   my $level = shift;

   return ("", "")  if ( $color_supported == 0 );
   return ("", "")  if ( $ENV{ANSI_COLORS_DISABLED} );
   return ("", "")  unless ( defined $color_list[$level] );

   return ( $color_list[$level], $color_clear );
}


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
sub DBUG_ACTIVE
{
   my $active = 0;   # Assume not currently active ...

   if ( $dbug_global_vars{on} && (! $dbug_global_vars{pause}) &&
        _limit_thread_check () ) {
      $active = ($dbug_global_vars{screen}) ? -1 : 1;
   }

   return ( $active );
}


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
sub DBUG_EXECUTE
{
   my $tag = shift;

   # Is fish active ?
   my $active = DBUG_ACTIVE ();    # -1, 0, 1

   # Return if inactive ...
   return (0)  unless ( $active );

   # Are we filtering the results out of fish ???
   return (0)  unless ( _filter_on ( $tag ) );

   return ($active);    # This tag would be written to fish!
}


=item DBUG_FILE_NAME ( )

Returns the full absolute file name to the B<fish> log created by I<DBUG_PUSH>.
If I<DBUG_PUSH> was passed an open file handle, then the file name is unknown
and the empty string is returned!

=cut

# ==============================================================
sub DBUG_FILE_NAME
{
   return ( $dbug_global_vars{file} );
}


=item DBUG_FILE_HANDLE ( )

Returns the file handle to the open I<fish> file created by I<DBUG_PUSH>.  If
I<DBUG_PUSH> wasn't called, or called using I<autoopen>, then it returns
I<undef> instead.

=cut;

# ==============================================================
sub DBUG_FILE_HANDLE
{
   return ( $dbug_global_vars{fh} );      # The open file handle written to ...
}


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
sub DBUG_ASSERT
{
   my $bool_expr = shift;
   return  if ( $bool_expr );   # The assertion is true ... (noop)

   my $always_on = shift;
   my $msg       = shift;

   my $asserted = 0;    # Assume it can't be triggered ...

   # Checks if the assert was triggered.
   if ( $always_on ) {
      $asserted = 1;    # Always assert ...
   } elsif ( DBUG_ACTIVE () ) {
      $asserted = 1;    # Only when Fish is turned on ...
   }

   if ( $asserted ) {
      my $str = _dbug_called_by (1);  # Where the assertion was made.
      $str = "Assertion Violation: " . $str;

      my $level = DBUG_FILTER_LEVEL_ERROR;

      unless ( $dbug_global_vars{screen} && _filter_on ( $level ) ) {
         print STDERR "\n", $str, "\n";
         print STDERR $msg, "\n"  if ( $msg );
         print STDERR "\n";
      }

      _dbug_print_pkg_tag ( $level, "ASSERT: %s", $str );
      _dbug_print_pkg_tag ( $level, "ASSERT: %s", $msg )  if ( $msg );
      DBUG_LEAVE (14);
   }

   return;
}


=item DBUG_MODULE_LIST ( )

This optional method writes to B<fish> all modules used by your program.  It
provides the module version as well as where the module was installed.  Very
useful when you are trying to see what's different between different installs
of perl or when you need to open a CPAN ticket.

=cut

sub DBUG_MODULE_LIST
{
   my ($max1, $max2) = (0, 0);   # (label len, version len)
   my %vers;
   my %mod;

   # Get the formatting data & version info.
   foreach ( sort keys %INC ) {
      my $len = length ($_);
      $max1 = $len  if ( $len > $max1 );

      # Get the module name ...
      my $module = $_;
      $module =~ s#[\\/]#::#g;
      $module =~ s/[.]pm$//i;

      # Determine the module's version ...
      my $ver = "(Unknown)";
      eval {
         local $SIG{__DIE__} = undef;   # Just in case already trapped.
         my $tmp = ${module}->VERSION ();
         $ver = $tmp  if ( $tmp );
      };

      # Save the version info ...
      $len = length ($ver);
      $max2 = $len  if ( $len > $max2 );
      $vers{$_} = $ver;

      # Save the module info ...
      $mod{$_} = $module;
      $len = length ($module);
      $max1 = $len  if ( $len > $max1 );
   }

   _dbug_print_no_delay_or_caller ( "INFO", "The Module List ..." );

   # Now print out the results ...
   foreach ( sort keys %INC ) {
      _dbug_print_no_delay_or_caller ( "MODULE", "%*s ==> %*s ==> %s",
                                  $max1, $mod{$_}, $max2, $vers{$_}, $INC{$_} );
   }

   return;
}


# Converts the reqeuested code ref or function string into a code ref/name pair.
# Used by both the Signal & TIE extensions for low level work!
sub _get_func_info
{
   my $callback = shift;   # A String or a CODE ref ...
   my $msg      = shift;   # A label to use when printing warnings.

   my ( $code, $func );    # The return values ...

   if ( $callback ) {
      my $pkg_name = __PACKAGE__ . "::";
      $pkg_name =~ s/:ON::$/:/;
      my $use_warn = 1;

      if ( ref ($callback) eq "CODE" ) {
         # Can't detect if there was typo in the given func name of the CODE ref
         $code = $callback;                     # Already a code referencd.
         $func = sub_fullname ($callback);      # Get it's name ... or  _ANNON_

         if ( $func =~ m/^${pkg_name}/ ) {
            warn ("You may not ${msg} a member of the FISH package!\n",
                  ' ==> ' . $func . "\n");
            $code = $func = undef;
            $use_warn = 0;
         }

      # May not self-reference something in this module ...
      } elsif ( $callback =~ m/^${pkg_name}/ ) {
         warn ("You may not ${msg} a member of the FISH package!\n",
               ' ==> ' . $callback . "\n");
         $use_warn = 0;

      # Provided a fully qualified function name as a string ...
      } elsif ( $callback =~ m/^(.+)::([^:]+)$/ ) {
         my ($pkg, $name) = ($1, $2);
         if ( $pkg->can ($name) ) {
            $code = $pkg->can ($name);          # Convert name into code ref.
            $func = $callback;
         }

      # Provided a partially qualified function name as a string ...
      # Done by figuring out who called the original DBUG method!
      } else {
         my $call_ind = 1;
         my $called_by = (caller ($call_ind))[3] || "";
         while ( $called_by =~ m/^${pkg_name}/ || $called_by eq "(eval)" ) {
            $called_by = (caller (++$call_ind))[3] || "";
         }

         # Get the package name of the caller ...
         if ( $called_by && $called_by =~ m/^(.+)::([^:]+)$/ ) {
            my ($pkg, $name) = ($1, $2);
            if ( $pkg->can ($callback) ) {
               $code = $pkg->can ($callback);   # Convert name into code ref.
               $func = $callback;
            }
         }

         # If not from the caller's package ...
         unless ( $func ) {
            my $tmp = "main"->can ($callback);
            if ( $tmp ) {
               $code = $tmp;
               $func = "main::" . $callback;
            }
         }
      }

      if ( $use_warn && ! $func ) {
         warn ("No such ${msg} function!  ($callback)\n");
      }
   }

   return ( wantarray ? ( $code, $func ) : $code );
}

# ==============================================================================
# Start of Helper methods designed to help test out this module's functionality.
# ==============================================================================

# ==============================================================
# Not exposed on purpose, so they don't polute the naming space!
# Or have people trying to use them!
# ==============================================================
# Undocumented helper functions exclusively for use by the "t/*.t" programs via
# the t/off/helper1234.pm helper module.
# Not intended for use by anyone else.
# So subject to change without notice!
# They are used to help these test programs validate that this module is working
# as expected without having to manually examine the fish logs for everything!!
# But despite everything, some manual checks will always be needed!
# ==============================================================
# Most of these functions in Fred::Fish::DBUG:OFF are broken and do not
# work there unless you lie and use the $hint arguments!  So it's another
# reason not to use them in yor own code base!
# In fact many of these functions in this module are broken as well if fish was
# turned off or paused when the measured event happened.
# ==============================================================
# NOTE: Be carefull how they are called in the t/*.t programs.  If called
#       the wrong way the HINT parameter won't be handled properly when
#       you swap over to the OFF.pm module!  The $hint arguments are
#       ignored here!
# ==============================================================
# The current FISH function on the fish stack ...
sub dbug_func_name
{
   my $hint = shift;    # Only used in OFF.pm ...
   return ( $dbug_global_vars{functions}->[-1]->{NAME} );
}

# Number of fish functions on the stack
# This one is used internally as well.
sub dbug_level
{
   my $hint = shift;    # Only used in OFF.pm ...
   my $cnt = @{$dbug_global_vars{functions}};
   return ( $cnt );
}

# This value is set via the calls to DBUG_RETURN() / DBUG_VOID_RETURN() /
# DBUG_RETURN_SPECIAL().
# It can only be non-zero if DBUG_MASK() was called 1st and only for
# DBUG_RETURN().  If fish is turned off it will be -1.  Otherwise
# it will be a count of the masked values in fish!
# In all other situations it will return zero!

sub dbug_mask_return_counts
{
   my $hint = shift;    # Only used in OFF.pm ...
   my $cnt = $dbug_global_vars{mask_return_count};
   $cnt = $hint  if ( $cnt == -1 && defined $hint );   # If unknown ...
   return ( $cnt );
}

# This value is set via the last call to DBUG_ENTER_FUNC() / DBUG_ENTER_BLOCK()
# when it prints it's masked arguments to fish.  If the write to fish doesn't
# happen the count will be -1!
# To decide what needs to be masked, you must call DBUG_MASK_NEXT_FUNC_CALL() 1st!
# Otherwise it will always be zero!

sub dbug_mask_argument_counts
{
   my $hint = shift;    # Only used in OFF.pm ...
   my $cnt = $dbug_global_vars{mask_last_argument_count};
   $cnt = $hint  if ( $cnt == -1 && defined $hint );   # If unknown ...
   return ( $cnt );
}

# These 4 actually work in Fred::Fish::DBUG::OFF as well!
sub dbug_threads_supported
{
   return ( $threads_possible );
}

sub dbug_fork_supported
{
   return ( $fork_possible );
}

sub dbug_time_hires_supported
{
   return ( $time_hires_flag );
}

sub dbug_get_frame_value
{
   my $key = shift;

   my $value;

   if ( $dbug_global_vars{on} && exists $dbug_global_vars{$key} ) {
      $value = $dbug_global_vars{$key}; 
   }

   return ( $value );
}

=back

=head1 CREDITS

To Fred Fish for developing the basic algorithm and putting it into the
public domain!  Any bugs in its implementation are purely my fault.

=head1 SEE ALSO

L<Fred::Fish::DBUG> The controling module which you should be using instead
of this one.

L<Fred::Fish::DBUG::OFF> The stub version of the ON module.

L<Fred::Fish::DBUG::TIE> - Allows you to trap and log STDOUT/STDERR to B<fish>.

L<Fred::Fish::DBUG::Signal> - Allows you to trap and log signals to B<fish>.

L<Fred::Fish::DBUG::SignalKiller> - Allows you to implement action
DBUG_SIG_ACTION_LOG for B<die>.  Really dangerous to use.  Will break most
code bases.

L<Fred::Fish::DBUG::Test> - A L<Test::More> wrapper to redirect test results to
B<fish>.

L<Fred::Fish::DBUG::Tutorial> - Sample code demonstrating using DBUG module.

=head1 COPYRIGHT

Copyright (c) 2007 - 2025 Curtis Leach.  All rights reserved.

This program is free software.  You can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# ============================================================
#required if module is included w/ require command;
1;
 
