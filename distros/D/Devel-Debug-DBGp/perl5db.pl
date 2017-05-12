# perl5db.pl
# 
# Modified version of PerlDB.pl, for use with the ActiveState
# debugger protocol, DBGp
# See http://aspn.activestate.com/ASPN/DBGP for more info.
#
# Copyright (c) 1998-2006 ActiveState Software Inc.
# All rights reserved.
#
# Xdebug compatibility, UNIX domain socket support and misc fixes
# by Mattia Barbon <mattia@barbon.org>
# 
# This software (the Perl-DBGP package) is covered by the Artistic License
# (http://www.opensource.org/licenses/artistic-license.php).


# Start with some lengthy, unattributed comments from perl5db.pl

=head2 REMOTE DEBUGGING

Copy the following files from a Komodo installation to
the target system

    <Komodo InstallDir>/perllib/* <TargetDir>

Set the following shell variables.  On Windows use C<set>
instead of C<export>, use double-quoting instead of
single-quoting, and use backslashes instead of forward-slashes.

    export PERLDB_OPTS=RemotePort=hostname:port
    export PERL5DB='BEGIN { require q(<TargetDir>/perl5db.pl) }'
    export PERL5LIB=<TargetDir>
    export DBGP_IDEKEY="username"

=cut

=head2 FLAGS, FLAGS, FLAGS

There is a certain C programming legacy in the debugger. Some variables,
such as C<$single>, C<$trace>, and C<$frame>, have "magical" values composed
of 1, 2, 4, etc. (powers of 2) OR'ed together. This allows several pieces
of state to be stored independently in a single scalar. 

=head4 C<$signal>

Used to track whether or not an C<INT> signal has been detected. C<DB::DB()>,
which is called before every statement, checks this and puts the user into
command mode if it finds C<$signal> set to a true value.

=head4 C<$single>

Controls behavior during single-stepping. Stacked in C<@stack> on entry to
each subroutine; popped again at the end of each subroutine.

=over 4 

=item * 0 - run continuously.

=item * 1 - single-step, go into subs. The 's' command.

=item * 2 - single-step, don't go into subs. The 'n' command.

=item * 4 - print current sub depth (turned on to force this when "too much
recursion" occurs.

=back

=head4 C<@saved>

Saves important globals (C<$@>, C<$!>, C<$^E>, C<$,>, C<$/>, C<$\>, C<$^W>)
so that the debugger can substitute safe values while it's running, and
restore them when it returns control.

=head4 C<@stack>

Saves the current value of C<$single> on entry to a subroutine.
Manipulated by the C<c> command to turn off tracing in all subs above the
current one.

=head4 C<%dbline>

Keys are line numbers, values are "condition\0action". If used in numeric
context, values are 0 if not breakable, 1 if breakable, no matter what is
in the actual hash entry.

=cut

=head1 DEBUGGER INITIALIZATION

The debugger\'s initialization actually jumps all over the place inside this
package. This is because there are several BEGIN blocks (which of course 
execute immediately) spread through the code. Why is that? 

The debugger needs to be able to change some things and set some things up 
before the debugger code is compiled; most notably, the C<$deep> variable that
C<DB::sub> uses to tell when a program has recursed deeply. In addition, the
debugger has to turn off warnings while the debugger code is compiled, but then
restore them to their original setting before the program being debugged begins
executing.

The first C<BEGIN> block simply turns off warnings by saving the current
setting of C<$^W> and then setting it to zero. The second one initializes
the debugger variables that are needed before the debugger begins executing.
The third one puts C<$^X> back to its former value. 

We'll detail the second C<BEGIN> block later; just remember that if you need
to initialize something before the debugger starts really executing, that's
where it has to go.

=cut

package DB;

sub DB {}
BEGIN {
    # kill the empty sub installed by Enbugger
    my ($scalar, $array, $hash) = (*DB::sub{SCALAR}, *DB::sub{ARRAY}, *DB::sub{HASH});
    undef *DB::sub;
    *DB::sub = $scalar; *DB::sub = $array; *DB::sub = $hash;
}

sub DEBUG_ALL()             { 0x7ff }
sub DEBUG_SINGLE_STEP_ON()  {  0x20 }
sub DEBUG_USE_SUB_ADDRESS() {  0x40 }
sub DEBUG_REPORT_GOTO()     {  0x80 }
sub DEBUG_DEFAULT_FLAGS() # 0x73f
       { DEBUG_ALL & ~(DEBUG_USE_SUB_ADDRESS|DEBUG_REPORT_GOTO) }
sub DEBUG_PREPARE_FLAGS() # 0x73c
       { DEBUG_ALL & ~(DEBUG_USE_SUB_ADDRESS|DEBUG_REPORT_GOTO|DEBUG_SINGLE_STEP_ON) }

sub DB_RECURSIVE_DEBUG()    { 0x40000000 }

# 'my' variables used here could leak into (that is, be visible in)
# the context that the code being evaluated is executing in. This means that
# the code could modify the debugger's variables.
#
# Fiddling with the debugger's context could be Bad. We insulate things as
# much as we can.

sub eval {

    # 'my' would make it visible from user code
    #    but so does local! --tchrist  
    # Remember: this localizes @DB::res, not @main::res.
    local @res;
    {
        # Try to keep the user code from messing  with us. Save these so that 
        # even if the eval'ed code changes them, we can put them back again. 
        # Needed because the user could refer directly to the debugger's 
        # package globals (and any 'my' variables in this containing scope)
        # inside the eval(), and we want to try to stay safe.
        local $otrace  = $trace; 
        local $osingle = $single;
        local $od      = $^D;
        local $op      = $^P;
	local ($^W) = 0;    # Switch run-time warnings off during eval.

        # speed up evaluation if no recursive debugging is required
        clobber_db_sub() unless $^D & DB_RECURSIVE_DEBUG;
        $^P = DEBUG_PREPARE_FLAGS unless $^D & DB_RECURSIVE_DEBUG;

        # Untaint the incoming eval() argument.
        { ($evalarg) = $evalarg =~ /(.*)/s; }

        # $usercontext built in DB::DB near the comment 
        # "set up the context for DB::eval ..."
        # Evaluate and save any results.

	# Do this in case there are user args in the expression --
	# pull them from the user's context.
	local @_;  # Clear each time.
	local @unused = caller($evalSkipFrames);
	local $additionalLevels = 0;
	# first term is for the extra stack frame of pure-Perl DB::sub
	# second term is for eval BLOCK stack frames
	local $notRealSubCall = $unused[0] eq 'DB' || ($unused[3] eq '(eval)' && !$unused[4]);
	while ($evalStackLevel > 0 || $notRealSubCall) {
	    $evalStackLevel-- if !$notRealSubCall;
	    $additionalLevels++;
	    @unused = caller($evalSkipFrames + $additionalLevels);
	    $notRealSubCall = $unused[0] eq 'DB' || ($unused[3] eq '(eval)' && !$unused[4]);
	    last unless @unused;
	}
	if ($unused[4]) {
	    # hasargs field is set -- an instance of @_ was set up.
	    eval { @_ = @args; };
	    @_ = () if $@;
	}
	my $usercontext2 = (($evalarg =~ /[\$\@\%]\w*[^\x00-\x7f]/)
                            ? "$usercontext use utf8; "
                            : $usercontext);
	@res = eval "$usercontext2 $evalarg;\n"; # '\n' for nice recursive debug

	if ($ldebug) {
	    if ($@) {
		dblog("eval($evalarg) => exception [$@]\n");
	    } elsif (scalar @res) {
		if (substr($evalarg, 0, 1) eq '%') {
		    dblog("eval($evalarg) => [hash val]\n");
		} elsif (scalar @res == 1 && ! defined $res[0]) {
		    dblog("eval($evalarg) => (undef)\n");
		    $no_value = 1;
		    @res = ("");
		} else {
		    my $str_out = join('', @res);
		    my $max_len = $settings{max_data}[0];
		    $max_len = 103 if $max_len > 103;
		    if (length($str_out) > $max_len) {
			$str_out = substr($str_out, 0, $max_len - 3) . '...';
		    }
		    $str_out = nonXmlChar_Encode($str_out) unless ref $str_out;
		    dblog("eval($evalarg) => <<$str_out>>\n");
		}
	    } else {
		dblog("eval($evalarg) => no value\n");
		$no_value = 1;
		@res = ("");
	    }
	} elsif (!$@ && scalar @res == 1 && ! defined $res[0]) {
	    $no_value = 1;
	    @res = ("");
	}

        # Restore those old values.
        $trace  = $otrace;
        $single = $osingle;
        $^D     = $od;
        $^P     = $op;
        restore_db_sub() unless $^D & DB_RECURSIVE_DEBUG;
    }

    # Save the current value of $@, and preserve it in the debugger's copy
    # of the saved precious globals.
    my $at = $@;

    # Since we're only saving $@, we only have to localize the array element
    # that it will be stored in.
    local $saved[0];                          # Preserve the old value of $@
    eval { &save };

    # Now see whether we need to report an error back to the user.
    if ($at) {
        die $at;
    }

    @res;
} ## end sub eval

# moved here to avoid it seeing the lexical context
sub simple_eval {
    eval $_[0];
}

use strict qw(vars subs);
use IO::Handle;

# Debugger for Perl 5.00x; perl5db.pl patch level:
our $VERSION = 0.30;

# $Log$

=head1 DEBUGGER INITIALIZATION

The debugger starts up in phases.

=head2 BASIC SETUP

First, it initializes the environment it wants to run in: turning off
warnings during its own compilation, defining variables which it will need
to avoid warnings later, setting itself up to not exit when the program
terminates, and defaulting to printing return values for the C<r> command.

=cut

our ($no_value, $evalarg, $usercontext, $evalSkipFrames, $evalStackLevel, @saved); # used by sub eval above

our ($single, $trace, $signal, $sub, %sub, @args);
our ($ldebug); # it should be my (), as all other $ldebug around the code
my ($currentFilename, $currentLine);

my ($pending_check_enabled, $pending_check_count, $pending_check_lim, $pending_check_timeout, $pending_check_interval, $skip_alarm, @pending_commands);

my ($setup_once_after_connection, $ready, $ini_warn);
my %firstFileInfo;

my (@stack, $deep);
our ($stack_depth, $level); # for local()

BEGIN {
    # Switch compilation warnings off until another BEGIN.
    $ini_warn = $^W;
    $^W       = 0;

    #init $deep to avoid warning
    # By default it doesn't stop.
    $deep = -1;
    $skip_alarm = 1;
    # True if we're logging
    $ldebug = 0;

    # uninitialized warning suppression
    $signal = $single = $trace = 0;
    # important stuff
    @stack = (0);
    $stack_depth = 0;    # Localized repeatedly; simple way to track $#stack
    $level = 0;
    $evalSkipFrames = $evalStackLevel = 0;
}

local ($^W) = 0;    # Switch run-time warnings off during init.

# more stuff
require Config;

# We set these variables to safe values. We don't want to blindly turn
# off warnings, because other packages may still want them.
my ($finished, $runnonstop, $fall_off_end) = (0, 0, 0);

our ($inPostponed) = (0); # because of local()
my @postponedFiles;

=head1 DEBUGGER SETTINGS

Keep track of the various settings in this hash

=cut

use DB::DbgrCommon;
use DB::DbgrProperties;
use DB::DbgrContext;
use DB::DbgrXS;

my %supportedCommands = (
    status              => 1,
    feature_get         => 1,
    feature_set         => 1,
    run                 => 1,
    step_into           => 1,
    step_over           => 1,
    step_out            => 1,
    stop                => 1, #xxxstop
    detach              => 1,
    breakpoint_set      => 1,
    breakpoint_get      => 1,
    breakpoint_update   => 1,
    breakpoint_remove   => 1,
    breakpoint_list     => 1,
    stack_depth         => 1,
    stack_get           => 1,
    context_names       => 1,
    context_get         => 1,
    typemap_get         => 1,
    property_get        => 1,
    property_set        => 1,
    property_value      => 1,
    source              => 1,
    stdout              => 1,
    stderr              => 1,
    stdin               => 0,
    break               => 0,
    'eval'              => 1,
    interact            => 0,
);

# Feature name => [bool(3): is supported, is settable, has associated value]
my %supportedFeatures = (
    encoding                    => [1, 1, 1],
    data_encoding               => [1, 1, 1],
    max_children                => [1, 1, 1],
    max_data                    => [1, 1, 1],
    max_depth                   => [1, 1, 1],
    multiple_sessions           => [0, 0, 0],
    language_supports_threads   => [0, 0, 0],
    language_name               => [1, 0, 1],
    language_version            => [1, 0, 1],
    protocol_version            => [1, 0, 1],
    supports_async              => [0, 0, 0],
    multiple_sessions           => [0, 0, 0],
);

# Feature name => [value, allowed settable values, if constrained]

# this is shared with DB::DbgrCommon and DB::DbgrProperties via exporting
%settings = (
    encoding            => ['UTF-8', ['UTF-8', 'iso-8859-1']],
    # binary and 'none' are the same
    data_encoding       => ['base64', [qw(urlescape base64 none binary)]],
    max_children        => [10, 1],
    max_data            => [32767, 1],
    max_depth           => [1, 1],
    language_name       => ['Perl'],
    language_version    => [sprintf("%vd", $^V)],
    protocol_version    => ['1.0'],
);

sub xsdNamespace() {
  return q(xmlns:xsd="http://www.w3.org/2001/XMLSchema");
}

sub xsiNamespace() {
  return q(xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance");
}

sub decodeData($;$) {
    my ($str, $encoding) = @_;
    my $finalStr;
    my $currDataEncoding = defined $encoding ? $encoding : $settings{data_encoding}->[0];
    $finalStr = $str;
    eval {
	if ($currDataEncoding eq 'none' || $currDataEncoding eq 'binary') {
	    $finalStr = $str;
	} elsif ($currDataEncoding eq 'urlescape') {
	    $finalStr = DB::CGI::Util::unescape($str);
	} elsif ($currDataEncoding eq 'base64') {
	    $finalStr = DB::MIME::Base64::decode_base64($str);
	} else {
            dblog("Converting $str with unknown encoding of $currDataEncoding\n") if $ldebug;
	    $finalStr = $str;
	}
    };
    if ($ldebug) {
	if ($@) {
	    # Log the string that caused problems.
	    $str = (substr($str, 0, 100) . '...') if length($str) > 100;
	    dblog("decodeData($str) => [$@]\n");
	}
    }
    return $finalStr;
}

my $fakeFirstStepInto = 0;
my $sentInitString = 0;
my $startedAsInteractiveShell = undef;

my $lastContinuationCommand = undef;
my $lastContinuationStatus = 'break';
my $lastTranID = 0;  # The transactionID that started

my $stopReason = STOP_REASON_STARTING();
my @stopReasons = (qw(starting stopping stopped running break interactive));

=head1 StopReasons

Why we are stopping

=over 4 

=item * 0 - started program

=item * 1 - user did a step_into

=item * 2 - user did a step_over

=item * 4 - user did a step_out

=item * 8 - program hit max-recursion depth

=back

=cut

# open input and output (to and from console)
open(IN,  "<&STDIN") || warn "open(IN)";
open(OUT, ">&STDERR") || open(OUT, ">&STDOUT") || warn "open(OUT)";

# force autoflush of output
eval {
    select(OUT);
    $| = 1;			# for DB::OUT
    select(STDERR);
    $| = 1;
    select(STDOUT);
    $| = 1;			# for real STDOUT
};

# Variables and subs for doing option processing
# (Copied from standard perl5db.pl to support PDK products)

my $remoteport;
my $remotepath;
my $connect_at_start = 1;
my $keep_running = 0;
my $xdebug_file_line_in_step = undef;
our $xdebug_no_value_tag = undef; # used by DB::DbgrProperties
my $xdebug_full_values_in_context = undef;
my $xdebug_temporary_breakpoint_state = undef;
# If the PERLDB_OPTS variable has options in it, parse those out next.
if (defined $ENV{PERLDB_OPTS}) {
    parse_options($ENV{PERLDB_OPTS});
}
if (!defined $remoteport && !defined $remotepath) {
    if (exists $ENV{RemotePort}) {
        $remoteport = $ENV{RemotePort};
    } else {
        die "Env variable RemotePort not set.";
    }
}
if ($remoteport =~ /^\d+$/) {
    die "Env variable RemotePort not numeric (set to $remoteport).";
}

my $has_xs = 0;
if (DB::DbgrXS::HAS_XS() && !$ENV{DBGP_PURE_PERL}) {
    eval {
	require XSLoader;

	XSLoader::load('dbgp-helper::perl5db');
	use_xs_sub();
	$has_xs = 1;

	1;
    } or do {
	my $error = $@ || "Unknown error";

	dblog("Error loading XS code: $error") if $ldebug;
	if ($ENV{DBGP_XS_ONLY}) {
	    dblog("Not falling back to pure-Perl, as per DBGP_XS_ONLY");
	    die "Aborting after error loading XS code: $error";
	}
    };
} else {
    if ($ENV{DBGP_XS_ONLY}) {
	dblog("DBGP_XS_ONLY but XS not compiled: aborting");
	die "DBGP_XS_ONLY but XS not compiled: aborting";
    }
}

sub emitBanner {
    my $version_str;
    if ($Config::Config{PERL_REVISION}) {
	$version_str = $Config::Config{PERL_REVISION};
	if ($Config::Config{PERL_VERSION}) {
	    $version_str .= '.' . $Config::Config{PERL_VERSION};
	    if ($Config::Config{PERL_SUBVERSION}) {
		$version_str .= '.' . $Config::Config{PERL_SUBVERSION};
	    }
	}
    } else {
	$version_str = $];
    }
    my $str = "# ";
    $str .= ($Config::Config{cf_by} =~ /activestate/i
	     ? "ActivePerl" : ($Config::Config{perl} || "Perl"));
    $str .= " v$version_str";
    $str .= " [$Config::Config{archname}]\n";
    # $str .= "# Type    `perl -v`   for more info.\n";
    print STDOUT $str;
}

my ($PID, $IN, $OUT, $OUT_selector);

sub disconnect {
  # force-close any copies of the file descriptor in other processes
  if (ref $OUT and UNIVERSAL::isa($OUT, 'IO::Socket')) {
      $OUT->shutdown(2);
  }
  $OUT = $IN = $OUT_selector = undef;
  $stopReason = STOP_REASON_STARTING();
  $lastContinuationCommand = undef;
  $lastContinuationStatus = 'break';
  $lastTranID = 0;  # The transactionID that started
}

sub connectOrReconnect {
  dblog("Trying to open connection to client") if $ldebug;
  $PID = $$;
  disconnect() if $OUT;
  # If RemotePort was defined in the options, connect input and output
  # to the socket.
  require IO::Socket;
  if ($remoteport) {
    $OUT = new IO::Socket::INET(
			        Timeout  => '10',
			        PeerAddr => $remoteport,
			        Proto    => 'tcp',
			       );
  } elsif ($remotepath) {
    $OUT = new IO::Socket::UNIX(
			        Timeout  => '10',
			        Peer     => $remotepath,
			       );
  }

  # disabled by 'detach'
  map { $supportedCommands{$_} = 1 } (qw(run step_into step_over step_out detach));

  if (!$OUT) {
      my ($error_num, $error_str) = ($!, "$!");
      if ($remoteport) {
          dblog("Unable to connect to remote host: $remoteport ($error_str)") if $ldebug;
          warn "Unable to connect to remote host: $remoteport ($error_str)\n";
      } else {
          dblog("Unable to connect to Unix socket: $remotepath ($error_str)") if $ldebug;
          warn "Unable to connect to Unix socket: $remotepath ($error_str)\n";
      }
      dblog("Running program outside the debugger") if $ldebug;
      warn "Running program outside the debugger...\n";
      # Disable the debugger to keep the Perl program running
      disable();
  } else {
      $signal = $single = $finished = $runnonstop = 0;
      $stopReason = STOP_REASON_STARTING();
      $sentInitString = 0;
      $fakeFirstStepInto = 1;
      setDefaultOutput($OUT);
      $IN = $OUT;
      eval {
	  require IO::Select;
	  $OUT_selector = IO::Select->new();
	  $OUT_selector->add($OUT);
	  # Indicate that we support asynchrousness
	  $supportedCommands{break} = 1;
	  if (!$skip_alarm) {
	      $supportedFeatures{supports_async} = [1, 1, 1];
	      $settings{supports_async} = [1];
	      $pending_check_enabled = 1;
	  }
	  $pending_check_count = 0;
	  $pending_check_lim = 100;
	  $pending_check_timeout = .000001;
	  $pending_check_interval = 1; # Check for a break every 1 second
	  @pending_commands = ();
      };

      # print "# Talking to port $remoteport\n" if $ldebug;
      # Moved stuff to start of init loop
      # sendInitString();
      setupOnceAfterConnection();
  }
}

sub isConnected { !!$OUT }

if (!$connect_at_start) {
    # Keep going
    disable();
} elsif (defined $remoteport || defined $remotepath) {
    connectOrReconnect();
} else {
    dblog("RemotePort not set for debugger") if $ldebug;
    warn "RemotePort not set for debugger\n";
    # Keep going
    disable();
}

sub setupOnceAfterConnection {
    return if $setup_once_after_connection;
    # Unbuffer DB::OUT. We need to see responses right away. 
    my $previous = select($OUT);
    # for DB::OUT
    $| = 1;
    select STDERR;
    $| = 1;
    select($previous);
    # $single = 1;
    if (!$skip_alarm) {
	$SIG{ALRM} = \&_break_check_handler;
    }
    $setup_once_after_connection = 1;
}

# Set a breakpoint for the first line of breakable code now,
# so we don't have to duplicate the reason in two places.
# Chat with the debug server until we get a continuation command.

# things to help the breakpoint mechanism

# Data structures for managing breakpoints

use DB::DbgrURI qw(canonicalizeFName
		   canonicalizeURI
		   filenameToURI
		   uriToFilename
		   );
use DB::RedirectStdOutput;

use DB::CGI::Util;
use DB::MIME::Base64;

use constant BKPT_DISABLE => 1;
use constant BKPT_ENABLE => 2;
use constant BKPT_TEMPORARY => 3;

use constant BKPT_REQ_ENABLED => 'enabled';
use constant BKPT_REQ_DISABLED => 'disabled';
use constant BKPT_REQ_TEMPORARY => 'temporary';

# Indices into the breakpoint Table

use constant BKPTBL_FILEURI => 0;
use constant BKPTBL_LINENO => 1;
use constant BKPTBL_STATE => 2;
use constant BKPTBL_TYPE => 3;
use constant BKPTBL_FUNCTION_NAME => 4;
use constant BKPTBL_CONDITION => 5;
use constant BKPTBL_EXCEPTION => 6;
use constant BKPTBL_HIT_INFO => 7;

use constant HIT_TBL_COUNT => 0; # No. Times we've hit this bpt
use constant HIT_TBL_VALUE => 1; # Target hit value
use constant HIT_TBL_EVAL_FUNC => 2; # Function to call(VALUE, COUNT)
use constant HIT_TBL_COND_STRING => 3; # Condition string

use constant STOP_REASON_STARTING => 0;
use constant STOP_REASON_STOPPING => 1;
use constant STOP_REASON_STOPPED => 2;
use constant STOP_REASON_RUNNING => 3;
use constant STOP_REASON_BREAK => 4;
use constant STOP_REASON_INTERACT => 5;

use DB::Data::Dump;
use File::Basename;
use File::Spec;
use Getopt::Std;

# Load the proper base class at compile time
BEGIN {
    require File::Spec::Functions;
    if ($^O eq 'MSWin32') {
	require File::Spec::Win32;
    } else {
	require File::Spec::Unix;
    }
    my $junk = File::Spec::Functions::devnull();
    dblog("dev-null => $junk");
}

my @bkptLookupTable = (); # Map fileURI_No -> hash of (lineNo => breakPtID)
my %bkptInfoTable = ();	  # Map breakPtID -> [fileURINo, lineNo, state, type, function, expression, exception, hitInfo]
my %FQFnNameLookupTable = (); # Map fully qualified fn names =>
			      # { call => breakPtID, return => breakPtID }

my @fileNameTable = ();			 # Map fileURI_No => [
					 #  $bFileURI,
					 #  $bFileName, (fwd slashes)
					 #  $perlFileName (backwd slashes)
					 # ]
my %watchedExpressionLookupTable = ();	 # Map watchedExpn => breakPtID

my $nextBkPtIndex = 0;

my (@watchPoints, @watchPointValues);
my $numWatchPoints = 0;

my ($tiedStdout, $tiedStderr);

# End of initialization code.

my $full_dbgp_prefix;
{
    my $hostname = 'unknown';
    local $@;
    eval {
	require 'Sys/Hostname.pm';
	$hostname = Sys::Hostname::hostname();
	$hostname =~ s/\..*$//;	# Keep only the first part of a dotted name
	$hostname =~ s/[^-_\w\d]+/_/g; # Turn non-alnums to safe chars
	dblog("**** \$hostname=$hostname") if $ldebug;
    };
    if ($@) {
	dblog("Error -- [$@]\n") if $ldebug;
    }
    $full_dbgp_prefix = "dbgp://perl/$hostname/$$";
}

{
    require Cwd;

    # get current directory
    my $cwd = Cwd::cwd();

    # cwd bug: returns C: rather than C:/ if we're in the root
    if ($cwd =~ /^[A-Z]:$/i) {
        $cwd .= "/";
    }

    DB::DbgrURI::init(ldebug => $ldebug, cwd => $cwd);
}

# Handle postponed requests that came in earlier.

finish_postponed();
$ready = 1;
$single = 0;

sub sendInitString {
    # Send the init command at this point
    my $ppid = $ENV{DEBUGGER_APPID} || "";
    my $appid = $$;  # getpid
    my $ideKey = $ENV{DBGP_IDEKEY} || "";
    my $initString = sprintf(qq(%s\n<init %s
				appid="%s"
				idekey="%s"
				parent="%s"
			       ),
			     xmlHeader(),
			     namespaceAttr(),
			     $appid,
			     $ideKey,
			     $ppid,
			     );
    if (exists $ENV{DBGP_COOKIE} && $ENV{DBGP_COOKIE}) {
	$initString .= qq( session="$ENV{DBGP_COOKIE}");
    }
    $initString .= sprintf(qq( thread="%s"
			       language="%s"
			       protocol_version="%s"),
			   0,	# Main thread in a program defined to be 0
			   'Perl', # Language
			   $settings{protocol_version}[0],
			   );
    if ($startedAsInteractiveShell) {
	$initString .= ' interactive="%"';
    } else {
	$initString .= ' fileuri="' . filenameToURI($0, 0) . '"';
    }
    my $hostname;
    if (!($hostname = $ENV{HOST_HTTP})) {
	# Get the hostname from perl
	require Sys::Hostname;
	$hostname = eval { Sys::Hostname::hostname() };
    }
    $initString .= qq( hostname="$hostname") if $hostname;
    $initString .= '/>';
    printWithLength($initString);
    $ENV{DEBUGGER_APPID} = $appid;
}

sub getArg {
  my ($cmdArgsARef, $optString) = @_;
  my $i;
  # Don't look at the last arg -- if it's an option, we're out of luck
  for ($i = 0; $i <= $#$cmdArgsARef - 1; $i++) {
    if ($cmdArgsARef->[$i] eq $optString) {
      return splice(@$cmdArgsARef, $i, 2);
    } elsif ($cmdArgsARef->[$i] eq '--') {
	last;
    }
  }
  return undef;
}

# Never delete entries here.
my (%fileURILookupTable, %perlNameToFileURINo, @fileURI_No_ReverseLookupTable);

sub internFileURI {
    my ($bFileURI) = @_;
    $bFileURI = canonicalizeURI($bFileURI);
    if (!exists $fileURILookupTable{$bFileURI}) {
	my $tblSize = scalar keys %fileURILookupTable;
	$fileURILookupTable{$bFileURI} = $tblSize + 1;
	$fileURI_No_ReverseLookupTable[$tblSize + 1] = $bFileURI;
    }
    return $fileURILookupTable{$bFileURI};
}

sub internFileURINo_LineNo {
    my ($bFileURINo, $bLine) = @_;
    if (!$bkptLookupTable[$bFileURINo]) {
	$bkptLookupTable[$bFileURINo] = {$bLine => $nextBkPtIndex};
	return $nextBkPtIndex++;
    } elsif (! exists $bkptLookupTable[$bFileURINo]->{$bLine}) {
	$bkptLookupTable[$bFileURINo]->{$bLine} = $nextBkPtIndex;
	return $nextBkPtIndex++;
    }
    return $bkptLookupTable[$bFileURINo]->{$bLine};
}

sub internFunctionName_CallType_Breakpoint($$) {
    my ($functionName, $bType) = @_;
    if (! exists $FQFnNameLookupTable{$functionName}) {
	$FQFnNameLookupTable{$functionName} = { $bType => $nextBkPtIndex };
	return $nextBkPtIndex++;
    } elsif (exists $FQFnNameLookupTable{$functionName}{$bType}) {
	# Overwrite existing breakpoint
	return $FQFnNameLookupTable{$functionName}{$bType};
    } else {
	$FQFnNameLookupTable{$functionName}{$bType} = $nextBkPtIndex;
	return $nextBkPtIndex++;
    }
}

sub internFunctionName_watchedExpn($) {
    my ($bExpn) = @_;
    if (! exists $watchedExpressionLookupTable{$bExpn}) {
	$watchedExpressionLookupTable{$bExpn} = $nextBkPtIndex++;
    }
    return $watchedExpressionLookupTable{$bExpn};
}

sub getURIByNo {
    my ($fileURINo) = @_;
    return $fileURI_No_ReverseLookupTable[$fileURINo] || "";
}

sub storeBkPtInfo {
    my ($bkptID, $bFileURINo, $bLine, $bstate, $bType, $bFunction, $bCondition) = @_;
    $bkptInfoTable{$bkptID} = [$bFileURINo, $bLine, $bstate, $bType, $bFunction, $bCondition, undef, undef];
}

# No conditions, but we want to maintain a hit count on the breakpoint.

sub setNullBkPtHitInfo {
    my ($bkptID) = @_;
    $bkptInfoTable{$bkptID}[BKPTBL_HIT_INFO] = [0, 0, undef, undef];
}

# Take a target value and a string representing a hit condition,
# and return a closure encapsulating the test.
# We need to expose the target, so there's no point encapsulating
# it into the closure.

# $bkptHitCount is the current value (hit count) on the breakpoint
# $bkptHitValue is the target value

sub testGE {
    my ($bkptHitCount, $bkptHitValue) = @_;
    return $bkptHitCount >= $bkptHitValue;
}

sub testEQ {
    my ($bkptHitCount, $bkptHitValue) = @_;
    return $bkptHitCount == $bkptHitValue;
}

sub testMod {
    my ($bkptHitCount, $bkptHitValue) = @_;
    return $bkptHitValue > 0 && $bkptHitCount % $bkptHitValue == 0;
}

sub parseBkPtHitInfo($) {
    my ($bkptHitConditionFunc) = @_;
    if ($bkptHitConditionFunc eq '>=') {
	return \&testGE;
    } elsif ($bkptHitConditionFunc eq '==') {
	return \&testEQ;
    } elsif ($bkptHitConditionFunc eq '%') {
	return \&testMod;
    } else {
	return undef;
    }
}

sub setBkPtHitInfo($$$) {
    my ($bkptID, $bkptHitValue, $bkptHitConditionString) = @_;
    $bkptHitConditionString = '>=' if (!defined $bkptHitConditionString);
    my $sub = parseBkPtHitInfo($bkptHitConditionString);
    if (!defined $sub) {
	# Formulate an error condition
	return 0;
    }
    if (! defined $bkptInfoTable{$bkptID}[BKPTBL_HIT_INFO]) {
	$bkptInfoTable{$bkptID}[BKPTBL_HIT_INFO] = [];
    }
    # Always reset hit-count to 0 -- part of bug 40561
    $bkptInfoTable{$bkptID}[BKPTBL_HIT_INFO][HIT_TBL_COUNT] = 0;
    $bkptInfoTable{$bkptID}[BKPTBL_HIT_INFO][HIT_TBL_VALUE] = $bkptHitValue; # Target
    $bkptInfoTable{$bkptID}[BKPTBL_HIT_INFO][HIT_TBL_EVAL_FUNC] = $sub;
    $bkptInfoTable{$bkptID}[BKPTBL_HIT_INFO][HIT_TBL_COND_STRING] = $bkptHitConditionString;
}
    

sub getBkPtInfo {
    my ($bkptID) = @_;
    if (!exists $bkptInfoTable{$bkptID} || (ref $bkptInfoTable{$bkptID}) ne 'ARRAY') {
	return;
    } else {
	return wantarray ? @{$bkptInfoTable{$bkptID}} : $bkptInfoTable{$bkptID};
    }
}

sub setBkPtState {
    my ($bkptID, $bstate) = @_;
    if (!exists $bkptInfoTable{$bkptID} || (ref $bkptInfoTable{$bkptID}) ne 'ARRAY') {
	# No such breakpoint
	return 0;
    }
    $bkptInfoTable{$bkptID}->[2] = $bstate;
    return 1;
}

sub getBkPtState {
    my ($bkptID, $bstate) = @_;
    if (!exists $bkptInfoTable{$bkptID} || (ref $bkptInfoTable{$bkptID}) ne 'ARRAY') {
	# No such breakpoint
	return BKPT_DISABLE;
    }
    return $bkptInfoTable{$bkptID}->[2];
}

sub deleteBkPtInfo {
    my ($bkptID) = @_;
    if (!exists $bkptInfoTable{$bkptID} || (ref $bkptInfoTable{$bkptID}) ne 'ARRAY') {
	# No such breakpoint
	return 0;
    }
    delete $bkptInfoTable{$bkptID};
    return 1;
}

sub remove_FileURI_LineNo_Breakpoint {
    my ($fileURINo, $bLine) = @_;
    if ($bkptLookupTable[$fileURINo]) {
	if (exists $bkptLookupTable[$fileURINo]->{$bLine}) {
	    if (defined $fileNameTable[$fileURINo]) {
		(undef, undef, my $perlFileName) = @{$fileNameTable[$fileURINo]};
		if ($perlFileName) {
		    our %dbline;
		    local *dbline = $main::{'_<' . $perlFileName};
		    $dbline{$bLine} = 0;
		} else {
		    dblog("remove_FileURI_LineNo_Breakpoint: No perlFileName entry in info \$fileNameTable[$fileURINo]\n") if $ldebug;
		}
	    } else {
		dblog("remove_FileURI_LineNo_Breakpoint: No info \$fileNameTable[$fileURINo]\n") if $ldebug;
	    }
	    delete $bkptLookupTable[$fileURINo]->{$bLine};
	} else {
	    dblog("remove_FileURI_LineNo_Breakpoint: Can't find bkpt info for (uri $fileURINo, line $bLine)\n") if $ldebug;
	}
    }
}

sub getStateName {
    my ($bState) = @_;
    if ($bState == BKPT_DISABLE) {
	return BKPT_REQ_DISABLED;
    } elsif ($bState == BKPT_ENABLE) {
	return BKPT_REQ_ENABLED;
    } elsif ($bState == BKPT_TEMPORARY) {
	return BKPT_REQ_TEMPORARY;
    } else {
	return BKPT_REQ_DISABLED;
    }
}

sub getExpressionTag {
    my ($bExpression) = @_;
    if (!$bExpression) {
	return "";
    } else {
	return sprintf('<expression>%s</expression>',
		       xmlEncode($bExpression));
    }
}

sub lookupBkptInfo {
    my ($fileNameURINo, $lineNo) = @_;
    if (!defined $bkptLookupTable[$fileNameURINo]) {
	dblog("lookupBkptInfo: No \$fileNameURINo ($fileNameURINo)\n") if $ldebug;
	return undef;
    } elsif (!exists $bkptLookupTable[$fileNameURINo]->{$lineNo}) {
	dblog("lookupBkptInfo: No entry at \$fileNameURINo ($fileNameURINo)->\{$lineNo}\n") if $ldebug;
	return undef;
    } else {
	my $bkptID = eval { $bkptLookupTable[$fileNameURINo]->{$lineNo}};
	return undef if !defined $bkptID;
	dblog("lookupBkptInfo: \$bkptID = $bkptID\n") if $ldebug;
	return $bkptInfoTable{$bkptID};
    }
}


# Precondition: $bFileName is canonicalized

sub lookForPerlFileName {
    my ($bFileName) = @_;
    my $result;
    # Look at all keys that start with '_<', aren't in eval blocks
    # and find one that canonicalizes to the same thing

    my @perlKeys = grep /_</, (grep !/eval/, keys %{*main::});
    foreach my $perlFileKey (@perlKeys) {
	$perlFileKey =~ s/_<//;
	my $origKey = $perlFileKey;
	local $@;
	eval {
	    $perlFileKey = canonicalizeFName(uriToFilename(filenameToURI($perlFileKey, 1)));
	    if ($bFileName eq $perlFileKey) {
		$result = $origKey;
	    }
	};
	if ($@) {
	    dblog("Called uriToFilename in " .
		  join("\n", dump_trace(0))) if $ldebug;
	}
    }
    return $result;
}

# Variables for the eval things
# Hash on <<(eval \d+)[parentLocn:lineNum]>> to (filename, startLine, @src)
my %evalTable = ();
my @evalTableIdx = (undef); # 0 is special-cased in calcFileURI

sub internEvalURI($;$) {
    my ($filename, $srcLinesARef) = @_;
    if (!exists $evalTable{$filename}) {
	my ($evalIdx, $parentLocation, $startingPoint) =
	    ($filename =~ /\(eval\s*(\d+)\)\[(.*):(\d+)\]$/);
	my $etCount = scalar @evalTableIdx;
	$evalTable{$filename} = {
	    file => $parentLocation,
	    startLine => $startingPoint,
	    src => $srcLinesARef,
	    idx => $etCount,
	};
	$evalTableIdx[$etCount] = $filename;
	if (!defined $srcLinesARef) {
	    our @dbline;
	    local *dbline = $main::{'_<' . $filename};
	    dblog("internEvalURI -- found src lines for ($filename), using ", join('', (scalar @dbline > 100 ? @dbline[0..99] : @dbline))) if $ldebug;
	    $evalTable{$filename}{src} = \@dbline;
	}
    }
}

# Assume this routine is called from the main routine only
# while we're trying to convert the current filename to a URI
#
# Don't convert the case here.

sub calcFileURI($) {
    my ($filename) = @_;
    if ($filename =~ m/^(\(eval\s*\d+\))\[.+:\d+\]$/) {
	my $evalName = $1;
	internEvalURI($filename);
	my $idx;
	if (exists $evalTable{$filename}
	    && defined ($idx = $evalTable{$filename}{idx})
	    && defined $evalTableIdx[$idx]) {
	    my $retName = "$full_dbgp_prefix/$idx/" . encodeData($evalName, 'urlescape');
	    dblog "calcFileURI: mapping $filename => [$retName]\n" if $ldebug;
	    return $retName;
	} else {
	    dblog "Can't map [$filename] to an evalTableIdx entry" if $ldebug;
	    return "$full_dbgp_prefix/0/" . encodeData($filename, 'urlescape');
	}
    } elsif (defined &INC && (index($filename, "/PerlApp/") == 0 # PDK ... 6
			      || $filename =~ m@^/<.*>@     # PDK 7
			      )) {
	return "dbgp:///perl/$filename";
    } else {
	return filenameToURI($filename, 0);
    }
}

sub downcaseDriveLetter {
    # If we're on windows systems, we'll need to manually
    # lcase the drive letter -- the uri canonicalizer
    # doesn't do that.
    $_[0] =~ s@^([A-Z])(?=:[/\\])@lc $1@e;
}

# Functions for manipulating breaking at functions:

=head1 findAndAddFunctionBreakPoints

Four ways to break on a sub:

1. No file or line # given: break at the start (or end) of all instances
   of all loaded subs with the given name

2. File given, no line #: break at the start (or end) of all instances
   ot the named function in the given file

3. File and line # given: use the line # to identify which instance of
   a function that matches the given name.  This is to allow for a
   file that contains multiple packages, with the same function name
   in more than one package.

4. No file given, but line # given: This is weird, but we have a
   story:
   Find all instances of the given function, and accept only if the
   given line # falls in the function's range.

=cut

sub addSubBreakPoint($$$$$$$$$);

sub addSubBreakPoint($$$$$$$$$) {
    my ($functionName,
	$fileURINo,
	$lineNumber,
	$bState,
	$possibleSub,
	$bCondition,
	$bType,
	$bHitCount,
	$bHitConditionOperator) = @_;
    my $bkptID = internFunctionName_CallType_Breakpoint($functionName, $bType);
    dblog("FQFnNameLookupTable: ", DB::Data::Dump::dump(%FQFnNameLookupTable), "\n") if $ldebug;
    storeBkPtInfo($bkptID, $fileURINo, $lineNumber, $bState,
		  $bType, $functionName, $bCondition);
    if ($bHitCount) {
	setBkPtHitInfo($bkptID, $bHitCount, $bHitConditionOperator);
    } else {
	setNullBkPtHitInfo($bkptID);
    }
    return $bkptID;
}

sub findAndAddFunctionBreakPoints($$$$$$$$$) {
    my ($bFunctionName, $perlFileName, $lineNumber,
	$bCondition, $bState, $bIsTemporary, $bType,
	$bHitCount,
	$bHitConditionOperator) = @_;
    my $isQualified = ($bFunctionName =~ /::/);
    my $fqSubName;
    if (!$isQualified) {
	$fqSubName = 'main::' . $bFunctionName;
    } else {
	$fqSubName = $bFunctionName;
    }
    my @possibleSubNames;
    # First try the direct lookup approach
    if (exists $sub{$fqSubName}) {
	@possibleSubNames = ($fqSubName);
    } elsif (!$isQualified) {
	my ($baseFunctionName) = ($bFunctionName =~ /([^:]+)$/);
	@possibleSubNames = grep(/$baseFunctionName$/, keys %sub);
    } else {
	# postponed
	@possibleSubNames = ($fqSubName);
    }

    # First find all the packages
    return if (!@possibleSubNames);
    my @bkptIDs;
    foreach my $possibleSub (@possibleSubNames) {
	my $addIt = 0;
	my ($fileName, $startLineNo, $endLineNo) = ($sub{$possibleSub} =~ /^(.*):(\d+)-(\d+)$/);
	if ($fileName) {
	    if ($perlFileName) {
		if (lc $fileName eq lc $perlFileName
		    || $fileName =~ /$perlFileName/i) {
		    if (!defined $lineNumber
			|| ($lineNumber >= $startLineNo
			    && $lineNumber <= $endLineNo)) {
			$addIt = 1;
		    }
		}
	    } else {
		$addIt = (!defined $lineNumber
			  || ($lineNumber >= $startLineNo
			      && $lineNumber <= $endLineNo));
	    }
	} elsif ($isQualified) {
	    # postponed
	    $addIt = 1;
	}
	if ($addIt) {
	    my $bFileURINo;
	    my $fileURI = filenameToURI($fileName, 1);
	    my $fileURINo = internFileURI($fileURI);
	    my $bkptID = addSubBreakPoint($possibleSub,
					  $fileURINo,
					  $lineNumber,
					  $bState,
					  $possibleSub,
					  $bCondition,
					  $bType,
					  $bHitCount,
					  $bHitConditionOperator);
	    push @bkptIDs, $bkptID;
	}
    }
    return @bkptIDs;
}

# I try to make the types transparent, but we need to give a typemap
# anyway

sub emitTypeMapInfo($$) {
    my ($cmd, $transactionID) = @_;
    my $res = sprintf(qq(%s\n<response %s %s %s command="%s" 
			 transaction_id="%s" >),
		      xmlHeader(),
		      namespaceAttr(),
		      xsdNamespace(),
		      xsiNamespace(),
		      $cmd,
		      $transactionID);
    # Schema, CommonTypeName (type attr) LanguageTypeName (name attr)
    foreach my $e (['boolean', 'bool'],
		   ['float'],
		   ['integer', 'int'],
		   ['string'],
		   [undef, 'undefined', 'undef'],
		   [undef, 'array', 'ARRAY'],
		   [undef, 'hash', 'HASH']) {
	my $xsdName = $e->[0];
	my $commonTypeName = $e->[1] || $xsdName;
	my $languageTypeName = $e->[2] || $commonTypeName;
	if ($xsdName) {
	    $res .= qq(<map type="$commonTypeName" name="$languageTypeName" xsi:type="xsd:$xsdName"/>);
	} else {
	    $res .= qq(<map type="$commonTypeName" name="$languageTypeName"/>);
	}
    }
    $res .= "\n</response>";
    printWithLength($res);
}

sub decodeCmdLineData($$$$) {
    my ($cmd, $transactionID, $dataLength, $argsARef) = @_;
    my @args = @$argsARef;
    my $currDataEncoding = $settings{data_encoding}->[0];
    my $decodedData;
    if ($currDataEncoding eq 'none' || $currDataEncoding eq 'binary') {
	$decodedData = join(" ", @args);
	$dataLength = length ($decodedData);
    } elsif (scalar @args == 0) {
	printWithLength(sprintf
			qq(%s\n<response %s command="%s" transaction_id="%s" ><error code="%d" apperr="4"><message>Expecting exactly 1 argument for %s command, got [nothing].</message></error></response>),

			xmlHeader(),
			namespaceAttr(),
			$cmd,
			$transactionID,
			DBP_E_CommandUnimplemented,
			$cmd,
			);
	return ();
    } else {
	$decodedData = decodeData(join("", @args));
	$dataLength = length ($decodedData);
    }
    dblog("decodeCmdLineData: returning [$decodedData]\n") if $ldebug;
    return ($dataLength, $currDataEncoding, $decodedData);
}

sub checkForEvalStackType($) {
    my ($stackDumpTypeValue) = @_;
    if ($stackDumpTypeValue && $stackDumpTypeValue =~ /^eval [\"\'q<]/) {
	return 'eval';
    } else {
	return 'file';
    }
}

sub getFileInfo($$$$$) {
    my ($bFileURI,
        $rbFileURI,
	$rbFileURINo,
	$rbFileName,
	$rperlFileName) = @_;

    my ($bFileURINo,
	$bFileName,
	$perlFileName);

    # URIs need to be stored in a canonical format,
    # since they're how we look things up.
    # Filenames aren't used for lookups directly.
    $bFileURI = canonicalizeURI($bFileURI);
    $bFileURINo = internFileURI($bFileURI);
    if (defined $fileNameTable[$bFileURINo]) {
	(undef, $bFileName, $perlFileName) = @{$fileNameTable[$bFileURINo]};
    } else {
	local $@;
	eval {
	    $bFileName = canonicalizeFName(uriToFilename($bFileURI));
	    $perlFileName = lookForPerlFileName($bFileName);
	    if (defined $perlFileName) {
		$perlNameToFileURINo{$perlFileName} = $bFileURINo;
		$fileNameTable[$bFileURINo] = [$bFileURI,
					       $bFileName,
					       $perlFileName];
	    }
	};
	if ($@) {
	    my $error = $@;

	    dblog("Error in uriToFilename: $error " .
		  DB::Data::Dump::dump(dump_trace(0))) if $ldebug;
	}
    }

    # And set the references
    $$rbFileURI = $bFileURI;
    $$rbFileURINo = $bFileURINo;
    $$rbFileName = $bFileName;
    $$rperlFileName = $perlFileName;
}
    

sub getBreakpointInfoString($%) {
    my ($bkptID, %extraInfo) = @_;
    my $bkptInfo = $bkptInfoTable{$bkptID};
    if (defined $bkptInfo && ref $bkptInfo eq 'ARRAY') {
	my ($xbFileURINo, $xbLine, $bState, $bType, $bFunction, $bExpression, $bException, $bHitInfo) = @$bkptInfo;
	my $res = sprintf(qq(<breakpoint
			     id="%s"
			     type="%s"),
			  $bkptID,
			  $bType
			  );
	if ($extraInfo{fileURI} || $xbFileURINo) {
	    my $bFileURI = getURIByNo($extraInfo{fileURI} || $xbFileURINo);
	    if ($bFileURI) {
		$res .= sprintf(' filename="%s"',
				$bFileURI);
	    }
	}
	if ($extraInfo{lineNo} || $xbLine) {
	    $res .= sprintf(' line="%s" lineno="%s"',
			    ($extraInfo{lineNo} || $xbLine) x 2);
	}
	if ($extraInfo{function} || $bFunction) {
	    $res .= sprintf(' function="%s"',
			    ($extraInfo{function} || $bFunction));
	}
	$res .= sprintf(' state="%s"',
			$bState == BKPT_TEMPORARY ?
			    ($xdebug_temporary_breakpoint_state ? 'temporary' : 'enabled') :
			$bState == BKPT_DISABLE	  ? 'disabled' :
						    'enabled');
	$res .= sprintf(' temporary="%d"',
			$bState == BKPT_TEMPORARY ? 1 : 0);
	$res .= sprintf(' exception="%s"',
			$bException) if defined $bException;
	if ($bHitInfo && defined $bHitInfo->[HIT_TBL_COUNT]) {
	    $res .= sprintf(' hit_count ="%s"', $bHitInfo->[HIT_TBL_COUNT]);
	    if (defined $bHitInfo->[HIT_TBL_VALUE]) {
		$res .= sprintf(' hit_value ="%s"', $bHitInfo->[HIT_TBL_VALUE]);
	    }
	    if (defined $bHitInfo->[HIT_TBL_COND_STRING]) {
		$res .= sprintf(' hit_condition ="%s"',
				xmlAttrEncode($bHitInfo->[HIT_TBL_COND_STRING]));
	    }
	}
	$res .= sprintf(">%s</breakpoint>\n",
			getExpressionTag($bExpression));
	return $res;
    } else {
	if ($ldebug) {
	    dblog("bkptInfo($bkptID, ",
	          join(", ", map{$_ => "($_, $extraInfo{$_})"} keys %extraInfo),
	          "), not defined\n");
	}
	return undef;
    }
}

sub processPossibleBreakpoint($$;$$) {
    my ($bkptInfoRef, $locationString, $dbline, $line) = @_;
    # ($bFileURINo, $bLine, $bState, $bType, $bFunction, $bExpression, $bException, $bHitInfo) = @$bkptInfoRef;
    if (!defined $bkptInfoRef) {
	return;
    }
    my $bState = $bkptInfoRef->[BKPTBL_STATE];
    if ($bState == BKPT_DISABLE) {
	return;
    }
    elsif ($bkptInfoRef->[BKPTBL_TYPE] eq 'watch') {
	dblog("Don't break on watch-breakpoints in processPossibleBreakpoint") if $ldebug;
	return;
    }
    my $bHitInfo = $bkptInfoRef->[BKPTBL_HIT_INFO];
    my $breakHere;
    if ($bHitInfo && defined $bHitInfo->[HIT_TBL_COUNT]) {
	$bHitInfo->[HIT_TBL_COUNT] += 1;

	# Are we doing hit-testing?
	if (defined $bHitInfo->[HIT_TBL_EVAL_FUNC]) {
	    $breakHere = $bHitInfo->[HIT_TBL_EVAL_FUNC]->($bHitInfo->[HIT_TBL_COUNT],
							  $bHitInfo->[HIT_TBL_VALUE]);
	} else {
	    $breakHere = 1;
	}
    } else {
	$breakHere = 1;
    }
    if (!$breakHere) {
	return;
    }
    my $bExpression = $bkptInfoRef->[BKPTBL_CONDITION];
    if ($bExpression) {
	# If we're here, $DB::signal must be false.
	# Can only be called from DB -- function breakpoints
	# can't be conditional.
	
	# As long as we're only called from DB::DB, there's
	# no reason to save the globals.
	local $evalSkipFrames = $evalSkipFrames + 2;
	eval {
	    # $DB::signal because $usercontext overrides the package
	    $evalarg = "\$DB::signal |= do {$bExpression;}"; &eval();
	};
	if ($@ || !$signal) {
	    $breakHere = 0;
	}
    }
    if ($breakHere) {
	$signal |= 1;
	if ($bState == BKPT_TEMPORARY) {
	    $bkptInfoRef->[BKPTBL_STATE] = BKPT_DISABLE;
	    $dbline->{$line} = 0 if $line && $dbline;
	}
    } else {
	# Don't break here, but there are no
	# more items that need to be turned off.
	# If we got to the caller by stepping in, over, or out, we
	# wouldn't have invoked this routine at all.
    }
}

sub splitCommandLine {
    my ($cmd) = @_;
    my @args;
    ($cmd) = $cmd =~ /^\s*(.*)$/s;
    while (length $cmd) {
	if ($cmd =~ /^([\"\'])/) {
	    my $q = $1;
	    my $arg = "";
	    $cmd = substr($cmd, 1);
	    while (length $cmd) {
		if ($cmd =~ /^$q\s*(.*)$/s) {
		    $cmd = $1;
		    last;
		} elsif ($cmd =~ /^\\([\'\"\\])(.*)$/s) {
		    $arg .= $1;
		    $cmd = $2;
		} else {
		    $cmd =~ /^(.[^\'\"\\]*)(.*)$/s;
		    $arg .= $1;
		    $cmd = $2;
		}
	    }
	    push @args, $arg;
	} elsif ($cmd =~ /^'((?:\\.|[^\'])*)'\s*(.*)$/s) {
            push @args, $1;
	    $cmd = $2;
        } elsif ($cmd =~ /^([^\s\"]+)\s*(.*)$/s) {
            push @args, $1;
	    $cmd = $2;
        } else {
	    dblog("Can't deal with input [$cmd]") if $ldebug;
	    push @args, substr($cmd, 0, 1);
	    $cmd = substr($cmd, 1);
	}
    }
    return @args;
}

sub trimEvalSubNames($) {
    my ($subname) = @_;
    if ($subname =~ /^eval\s+[\"\'q]/) {
	$subname = q(eval '...');
    } elsif ($subname =~ /^eval\s+\{/) {
	$subname = q(eval {...});
    }
    return $subname;
}

sub _guessScalarOrArray($) {
    my $valsARef = shift;
    if (!$valsARef) {
	return [];
    }
    my $size = scalar @$valsARef;
    if ($size == 0) {
	return "";
    } elsif ($size == 1) {
	return $valsARef->[0];
    } else {
	foreach my $currLine (@$valsARef) {
	    if (ref $currLine) {
		return $valsARef;
	    } elsif ($currLine !~ /\n$/) {
		return $valsARef;
	    }
	}
	# They're all strings
	return join('', @$valsARef);
    }
}

sub _fillMissingPodlines {
    my ($beginLine, $endLine, $dblines) = @_;
    my @copy = @$dblines[$beginLine .. $endLine];
    # Perl strips away the pod lines as a cheap way of
    # determining which lines are breakable -- sort of
    # -- we need to put something
    # back or Komodo goes berserk.

    my $eol;
    if ($copy[0] =~ /([\r\n]+)$/) {
	$eol = $1;
    } else {
	$eol = "\n";
    }
    for (my $i = 0; $i <= $#copy; ++$i) {
	dblog("Processing line $i : <<$copy[$i]>>") if $ldebug;
	if (!defined $copy[$i]) {
	    if (substr($copy[$i - 1], 0, 1) == "=") {
		$copy[$i] = "<pod dropped>$eol";
		dblog("Setting line $i to pod-dropped") if $ldebug;
		while (++$i <= $#copy && !defined $copy[$i]) {
		    $copy[$i] = "?$eol";
		    dblog("Setting line $i to unknown") if $ldebug;
		}
		if ($i <= $#copy) {
		    if ($copy[$i] !~ /[\r\n]$/) {
			$copy[$i] = "=cut$eol";
		    } else {
			dblog("Hey, line $i : $copy[$i] already ends with nl") if $ldebug;
		    }
		} else {
		    dblog("Ran off the end of the file") if $ldebug;
		}
	    } else {
		dblog("line $i is undefined, but prev line = $copy[$i - 1]") if $ldebug;
		$copy[$i] = "$eol";
	    }
	} elsif ($copy[$i] !~ /[\r\n]$/) {
	    dblog("line $i ($copy[$i]) doesn't end with newline") if $ldebug;
	    if ($copy[$i - 1] =~ /^[\?=]/ && length($copy[$i]) == 0) {
		$copy[$i] = "=cut$eol";
	    } else {
		$copy[$i] .= "$eol";
	    }
	}
    } 
    return join("", @copy);
}

sub _fileSource {
    my ($perlFileName, $beginLine, $endLine, $dblines) = @_;
    my $sourceKey = '_<' . $perlFileName;
    my $sourceString;
    local $@;
    if (!defined $sourceString && defined &INC && $perlFileName =~ m,^/(Perl\w{3}/|<.*?>)(.*),) {
	my $pdkUtilityName = $1;
	$sourceString = INC($2);
	if ($ldebug && defined $sourceString) {
	    my @lines = split(/\n/, $sourceString);
	    dblog("Debugging a $pdkUtilityName module, grab source and get [" . join("\n", @lines[0..2]) . "]");
	}
    }
    if (!defined $sourceString && exists $main::{$sourceKey}) {
	our @dbline;
	local *dbline = $main::{$sourceKey};
	if (@dbline > 0) {
	    $endLine = $#dbline if !$endLine;
	    $endLine < $beginLine and $endLine = $beginLine;
	    $sourceString = $] >= 5.012 ?
		join('', @dbline[$beginLine .. $endLine]) :
		_fillMissingPodlines($beginLine, $endLine, $dblines);
	}
    }
    if (!defined $sourceString) {
	dblog("source: using file [$perlFileName]\n") if $ldebug;
	eval {
	    open my $fh, "<", $perlFileName;
	    if ($fh) {
		if ($beginLine == 1 && !$endLine) {
		    local $/ = undef;
		    $sourceString = <$fh>;
		} else {
		    my @lines = <$fh>;
		    $sourceString = join '', @lines[($beginLine - 1) .. ((!$endLine || $endLine >= @lines) ? @lines - 1 : $endLine - 1)];
		}
		close $fh;
	    }
	};
	if ($@) {
	    dblog("open file $perlFileName: $@\n") if $ldebug;
	}
    }
    if (!defined $sourceString) {
	if (!$@) {
	    $@ = "# Error: Komodo couldn't find the file $perlFileName\n";
	}
    }
    return ($sourceString, $@);
}


sub _trimExceptionInfo($) {
    my $error = shift;
    $error =~ s/ at (?:\(eval \d+\))?\[.*:\d+\] line \d+, at .+$//;
    return $error;
}

# Better to wrap the function than to override it,
# as the user code might rely on alarm() faulting on
# certain systems.

sub db_alarm {
    return if $skip_alarm;
    my $time = shift;
    local $@;
    eval {
	alarm($time);
    };
    $skip_alarm = 1 if $@;
}

# DB::eval returns an array, but we can do better
sub eval_term {
    my ($term) = @_;
    my $valRef;
    # Avoid pattern-matching
    my $firstChar = substr($term, 0, 1);
    $no_value = undef;
    $evalarg = $term;
    local $evalSkipFrames = $evalSkipFrames + 1;
    if ($firstChar eq '@') {
	my @tmp = &eval();
	if ($no_value) {
	    @tmp = ();
	}
	$valRef = \@tmp;
    } elsif ($firstChar eq '%') {
	my %tmp = &eval();
	if ($no_value) {
	    %tmp = ();
	}
	$valRef = \%tmp;
    } else {
	# eval always fires in array context
	my @tmp = &eval();
	if ($no_value) {
	    $valRef = undef;
	} else {
	    $valRef = _guessScalarOrArray(\@tmp);
	}
    }
}

my %firstFileInfo;
our ($full_bypass); # used in DB::RedirectStdOutput

sub DB {
    if ($full_bypass) {
	my ($pkg, $filename, $line) = caller;
	dblog("Bypassing ($pkg, $filename, $line)") if $ldebug;
	return;
    }
    # return unless $ready;
    if (! $ready) {
	#### dblog("Not ready in DB -- returning\n") if $ldebug;
	return;
    }
    db_alarm(0);

    # do important stuff
    #
    &save;
    if ($PID != $$) {
        connectOrReconnect();
        unless ($OUT) {
            ($@, $!, $,, $/, $\, $^W) = @saved;
            return;
        }
    }
    (my $pkg, $currentFilename, $currentLine) = caller;
    # stack layout
    # Perl DB::sub: call-site -> DB::sub -> actual sub -> DB::DB
    # XS   DB::sub: call-site ->         -> actual sub -> DB::DB
    # so we need 2 or 3 levels for DB::eval to get to the actual call
    #
    # however if we skip the extra frame directly here (with a conditional),
    # if makes the interaction of sub foo { eval { ... } } with the logic
    # to look at deeper stack frames more complicated, so here we only
    # skip the two level required to go to the first non-debugger frame,
    # and leave the logic to deal with the XS vs. non-XS DB::sub in DB::eval
    local $evalSkipFrames = 2;
    if (!defined $startedAsInteractiveShell) {
	# This won't work with code that changes $0 to "-e"
	# in a BEGIN block.
	if ($0 eq '-e') {
	    $startedAsInteractiveShell = 1;
	    $stopReason = STOP_REASON_INTERACT;
	    emitBanner();
	} else {
	    $startedAsInteractiveShell = 0;
	    $stopReason = STOP_REASON_BREAK;
	}
    }
    if ($ldebug && $pkg !~ /^DB::/) {
	dblog("In $pkg, $currentFilename, $currentLine\n");
    }
    
    $usercontext = '($@, $!, $,, $/, $\, $^W) = @saved;' .
	"package $pkg;";	# this won't let them modify, alas

    if ($currentFilename =~ s/ \(autosplit .*$//) {
	my $substr = $Config::Config{prefix};
	$currentFilename =~ s/^\.\./$substr/;
    }

    if ($pkg eq 'DB::fake') {
	# Fallen off the end, so allow debugging
	# Set the DB::eval context appropriately.
	if (exists $firstFileInfo{file}) {
	    ($pkg, $currentFilename, $currentLine) = @firstFileInfo{qw/pkg file lastLineNumber/};
	} else {
	    $pkg     = 'main';
	}
	$usercontext =
	    '($@, $!, $^E, $,, $/, $\, $^W) = @saved;' .
		"package $pkg;"; # this won't let them modify, alas
	if ($runnonstop) {
	    exit 0;
	}
	$supportedCommands{'detach'} = 1;
	# This just doesn't make sense: at the end of the program,
	# we aren't executing anymore.
	# But we can look at the global variables
	# $supportedCommands{'stack_get'} = 0;
	$supportedCommands{'context_get'} = 0;
	$single = 1;
    } elsif ($runnonstop) {
	db_alarm($pending_check_interval);
	($@, $!, $,, $/, $\, $^W) = @saved;
	return;
    } elsif (!$sentInitString) {
	sendInitString();
	$sentInitString = 1;
    }

    my $fileNameURI;
    my $fileNameURINo;
    our (@dbline, %dbline);

    local*dbline = "::_<$currentFilename";
    if ($ldebug && $pkg eq 'DB::fake') {
	dblog($dbline[$currentLine]);
    }

    my $canPerlFileName = canonicalizeFName($currentFilename);
    if (exists $perlNameToFileURINo{$canPerlFileName}) {
	$fileNameURINo = $perlNameToFileURINo{$canPerlFileName};
	($fileNameURI, undef, undef) = @{$fileNameTable[$fileNameURINo]};
    } elsif ($currentFilename =~ /\(eval (\d+)\)\[(.*):(\d+)\]$/) {
	internEvalURI($currentFilename, \@dbline);
	$fileNameURI = calcFileURI($currentFilename);
	$fileNameURINo = internFileURI($fileNameURI);
    } else {
	$fileNameURI = filenameToURI($currentFilename, 1);
	$fileNameURINo = internFileURI($fileNameURI);
    }

    if ($pkg !~ /^DB::/) {
	if (! exists $firstFileInfo{file}) {
	    $firstFileInfo{file} = $currentFilename; # Perl file name
	    $firstFileInfo{pkg} = $pkg;
	    $firstFileInfo{lastLine} = $currentLine; # last line executed
	    $firstFileInfo{lineInfo} = \@dbline;
	    $firstFileInfo{lastLineNumber} = $#dbline;
	} elsif ($firstFileInfo{file} eq $currentFilename) {
	    $firstFileInfo{lastLine} = $currentLine; # last line executed
	}
    }

    if (!$single) {
	my $bkptInfoRef = lookupBkptInfo($fileNameURINo, $currentLine);
	processPossibleBreakpoint($bkptInfoRef, "File $fileNameURINo, line $currentLine", \%dbline, $currentLine);
    }

    # If we have any watch expressions ...
    if (!$single && ($trace & 2) && $pkg !~ /^DB::/) {
        for (my $i = 0 ; $i <= $#watchPoints ; $i++) {
            $evalarg = $watchPoints[$i];

            # Fix context DB::eval() wants to return an array, but
            # we need a scalar here.
            my ($val) = eval { join (' ', &eval ) };
            $val = ((defined $val) ? "'$val'" : 'undef');

            # Did it change?
            if ($val ne $watchPointValues[$i]) {
		dblog("checking watches, {$watchPoints[$i]} was [$watchPointValues[$i]], not [$val]") if $ldebug;
                # Yep! Show the difference, and fake an interrupt.
                $signal = 1;
                $watchPointValues[$i] = $val;
		last;
            }
        }
    }

    if (($single || $signal)
	&& ($pkg eq 'DB::fake' || $pkg !~ /^DB::/)
	&& !$inPostponed) {
        # Yes, go down a level.
        local $level = $level + 1;
	if ($ldebug) {
	    dblog("file:$currentFilename, line:$currentLine, package:$pkg\n");
	    dblog($#stack . " levels deep in subroutine calls!\n") if $single & 4;
	}
	# Send a status thing back
	if ($pkg eq 'DB::fake') {
	    # Do nothing
	} elsif (defined $lastContinuationCommand &&
                     ($lastContinuationCommand eq 'detach' ||
                      $lastContinuationStatus ne 'stopping')) {
	  printWithLength(sprintf(qq(%s\n<response %s command="%s" status="%s"
				       reason="ok" transaction_id="%s" %s>),
				  xmlHeader(),
				  namespaceAttr(),
				  $lastContinuationCommand,
				  $lastContinuationStatus,
				  $lastTranID,
				  fileAndLineIfXdebug()));
	}
	$stopReason = STOP_REASON_BREAK unless $finished;

	# command loop
	local $@;
      CMD:
	while (1) {
	    # dblog("About to get the command...\n") if $ldebug;
	    my $cmd = &readline();
	    if ($cmd eq '') {
		if ($keep_running) {
		    disconnect();
		    disable();
		    last CMD;
		} else {
		    # dblog("Got no command\n") if $ldebug;
		    exit 0;
		}
	    }
	    dblog("Got command [$cmd]\n") if $ldebug;

	    $single = 0;
	    $signal = 0;

	    #### print OUT "cmd: $cmd\n";
	    my @cmdArgs;
	    # For now assume commands use urlencoding
	    eval { @cmdArgs = splitCommandLine($cmd); };
	    if ($@) {
		makeErrorResponse("cmd",
				  -1,
				  1,
				  "Failed to parse command-line [$cmd]");
		next CMD;
	    }
	    my $transactionID = getArg(\@cmdArgs, '-i');

	    # Enter the big pseudo-switch stmt.

	    my $cmd = $cmdArgs[0];
	    if (exists $supportedCommands{$cmd}) {
		if (!$supportedCommands{$cmd}) {
		    printWithLength(sprintf
				    (qq(%s\n<response %s command="%s" 
					transaction_id="%s" ><error code="%d" apperr="4">
					<message>command '%s' not currently supported</message>
					</error></response>),
				     xmlHeader(),
				     namespaceAttr(),
				     $cmd,
				     $transactionID,
				     DBP_E_CommandUnimplemented,
				     $cmd,
				     ));
		    next CMD;
		}
	    } else {
		printWithLength(sprintf
				(qq(%s\n<response %s command="%s" 
				    transaction_id="%s" ><error code="%d" apperr="4">
				    <message>command '%s' not recognized</message>
				    </error></response>),
				 xmlHeader(),
				 namespaceAttr(),
				 $cmd,
				 $transactionID,
				 DBP_E_UnrecognizedCommand,
				 $cmd,
				 ));
		next CMD;
	    }

	    if ($cmd eq 'status') {
		printWithLength(sprintf
				(qq(%s\n<response %s command="status" status="%s"
				    reason="ok" transaction_id="%s"/>),
				 xmlHeader(),
				 namespaceAttr(),
				 $startedAsInteractiveShell ? 'interactive' : $stopReasons[$stopReason],
				 $transactionID));

	    } elsif ($cmd eq 'feature_get') {
		my $featureName = getArg(\@cmdArgs, '-n');
		my ($supported, $innerText);

		if (! defined $featureName) {
		    $featureName = "unspecified";
		    $supported = 0;
		    $innerText = "";
		} elsif (exists $supportedCommands{$featureName}) {
		    $supported = $supportedCommands{$featureName};
		    $innerText = "";
		} elsif (exists $supportedFeatures{$featureName}) {
		    my @vals = @{$supportedFeatures{$featureName}};
		    $supported = $vals[0];
		    if (!$vals[2] || !exists $settings{$featureName}) {
			$innerText = "";
		    } else {
			$innerText = $settings{$featureName}->[0];
		    }
		} else {
		    # Command not recognized
		    $supported = 0;
		    $innerText = "";
		}
		printWithLength(sprintf
				(qq(%s\n<response %s command="%s" feature_name="%s"
				    supported="%d" transaction_id="%s">%s</response>),
				 xmlHeader(),
				 namespaceAttr(),
				 $cmd,
				 $featureName,
				 $supported,
				 $transactionID,
				 $innerText));
		if ($transactionID == 1 && $finished) {
		    # Observed behavior: we've hit the END block,
		    # and called DB::fake::at_exit(),
		    # but the debugger is still calling us.  Let's
		    # tell it that we've stopped, and then stop.
		    #
		    # This came up in bug 33128.

		    close $IN;
		    close $OUT;
		    exit 0;
		}

	    } elsif ($cmd eq 'feature_set') {
		my $featureName = getArg(\@cmdArgs, '-n');
		my $featureValue = getArg(\@cmdArgs, '-v');
		my ($status, $success, $reason);

		# $success not used
		$reason = undef;
		if (!defined $featureName) {
		    $success = 0;
		    $reason = "Command not specified";
		} elsif (!exists $supportedFeatures{$featureName}) {
		    $status = 0;
		    $reason = "Command $featureName not recognized";
		} else {
		    my $vals = $supportedFeatures{$featureName};
		    if (!$vals->[1]) {
			$status = 0;
			$reason = "Command $featureName not modifiable";
		    } elsif (!$vals->[2]) {
			# No associated data, use boolean value in
			# table
			$vals->[0] = $featureValue ? 1 : 0;
			$status = 1;
			$success = $vals->[0];
		    } elsif (!exists $settings{$featureName}) {
			$status = 0;
			$reason = "Command $featureName not in settings table";
		    } else {
			my $svals = $settings{$featureName}->[1];
			if (!defined $svals) {
			    $status = 0;
			    $reason = "Command $featureName is readonly settings table";
			} elsif ($svals == 1) {
				# Hardwire numeric values
			    if ($featureValue =~ /^\d+$/) {
				$status = 1;
				$settings{$featureName}->[0] = $featureValue;
			    } else {
				$status = 0;
				$reason = "Command $featureName value of $featureValue isn't numeric.";
			    }
			} elsif ($svals == 'a') {
				# Allow any ascii data
			    $status = 1;
			    $settings{$featureName}->[0] = $featureValue;
			} elsif (ref $svals eq 'ARRAY') {
			    $status = 0;
			    foreach my $allowedValue (@$svals) {
				if ($featureValue eq $allowedValue) {
				    $status = 1;
				    $settings{$featureName}->[0] = $featureValue;
				    last;
				}
			    }
			    if (!$status) {
				$reason = "Command $featureName value of $featureValue isn't an allowed value.";
			    }
			} else {
			    $status = 0;
			    $reason = "Command $featureName=$featureValue, can't deal with current setting of " . ref $vals . "\n";
			}
		    }
		}
		printWithLength(sprintf
				(qq(%s\n<response %s command="%s" feature_name="%s"
				    success="%d" transaction_id="%s" %s/>),
				 xmlHeader(),
				 namespaceAttr(),
				 $cmd,
				 $featureName,
				 $status,
				 $transactionID,
				 $reason ? ('reason="' . $reason . '"') : ''
				 ));

		# Continuation commands
	    } elsif ($cmd eq 'run') {
		if ($finished and $level <= 1) {
		    end_report($cmd, $transactionID);
		    next CMD;
		}
		$lastContinuationCommand = $cmd;
		$lastContinuationStatus = 'break';
		$lastTranID = $transactionID;
		my $getNextCmd;

		# debug message
		if ($fakeFirstStepInto) {
		    my $bkptInfoRef = lookupBkptInfo($fileNameURINo, $currentLine);
		    if ($bkptInfoRef) {
			dblog("hit a breakpoint at first breakable line") if $ldebug;
			$getNextCmd = 1;
		    } else {
			if ($ldebug) {
			    dblog("\$fakeFirstStepInto was true, turning it off.");
			    dblog("\$single = $single");
			}
			$getNextCmd = 0;
		    }
		    $fakeFirstStepInto = 0;
		} else {
		    $getNextCmd = 0;
		}
		# dblog("Continuing...\n") if $ldebug;

		# continue
		for (my $i=0; $i <= $#stack; ) {
		    $stack[$i++] &= ~1;
		}
		if ($getNextCmd) {
		    printWithLength(sprintf
				    (qq(%s\n<response %s command="%s"
					status="break"
					reason="ok" transaction_id="%s"/>),
				     xmlHeader(),
				     namespaceAttr(),
				     $cmd,
				     $transactionID));
		    next CMD;
		} else {
		    $stopReason = STOP_REASON_RUNNING;
		    last CMD;
		}

	    } elsif ($cmd eq 'break') {
		$fakeFirstStepInto = 0;
		printWithLength(sprintf
				(qq(%s\n<response %s command="%s"
				    status="break"
				    success="1"
				    transaction_id="%s"/>),
				 xmlHeader(),
				 namespaceAttr(),
				 $cmd,
				 $transactionID));
		next CMD;
	    } elsif ($cmd eq 'step_into') {
		if ($finished and $level <= 1) {
		    end_report($cmd, $transactionID);
		    next CMD;
		} elsif ($fakeFirstStepInto) {
		    # We're already at position 1, so don't go anywhere.
		    $fakeFirstStepInto = 0;
		    printWithLength(sprintf
				    (qq(%s\n<response %s command="%s"
					status="break"
					reason="ok" transaction_id="%s" %s>),
				     xmlHeader(),
				     namespaceAttr(),
				     $cmd,
				     $transactionID,
				     fileAndLineIfXdebug()));
		    next CMD;
		}

		$lastContinuationCommand = $cmd;
		$lastContinuationStatus = 'break';
		$lastTranID = $transactionID;
		# debug message
		dblog("Stepping into...\n") if $ldebug;

		# step into
		$single = 1;
		$stopReason = STOP_REASON_RUNNING;
		last CMD;

	    } elsif ($cmd eq 'step_over') {
		if ($finished and $level <= 1) {
		    end_report($cmd, $transactionID);
		    next CMD;
		} elsif ($fakeFirstStepInto) {
		    # We're already at position 1, so don't go anywhere.
		    $fakeFirstStepInto = 0;
		    printWithLength(sprintf
				    (qq(%s\n<response %s command="%s"
					status="break"
					reason="ok" transaction_id="%s" %s>),
				     xmlHeader(),
				     namespaceAttr(),
				     $cmd,
				     $transactionID,
				     fileAndLineIfXdebug()));
		    next CMD;
		}

		$lastContinuationCommand = $cmd;
		$lastContinuationStatus = 'break';
		$lastTranID = $transactionID;
		# debug message
		dblog("Stepping over...\n") if $ldebug;

		# step over
		$single = 2;
		$stopReason = STOP_REASON_RUNNING;
		last CMD;

	    } elsif ($cmd eq 'step_out') {
		if ($finished and $level <= 1) {
		    end_report($cmd, $transactionID);
		    next CMD;
		}
		my $getNextCmd;
		# This is more like starting with a run than a step
		# So always check $fakeFirstStepInto to 0.
		if ($fakeFirstStepInto) {
		    my $bkptInfoRef = lookupBkptInfo($fileNameURINo, $currentLine);
		    if ($bkptInfoRef) {
			dblog("hit a breakpoint at first breakable line") if $ldebug;
			$getNextCmd = 1;
		    } else {
			dblog("\$fakeFirstStepInto was true, turning it off.") if $ldebug;
			$getNextCmd = 0;
		    }
		    $fakeFirstStepInto = 0;
		} else {
		    $getNextCmd = 0;
		}

		$lastContinuationCommand = $cmd;
		$lastContinuationStatus = 'break';
		$lastTranID = $transactionID;
		# debug message
		dblog("Stepping out...\n") if $ldebug;

		# step out
		$stack[$stack_depth] |= 2;
		if ($getNextCmd) {
		    printWithLength(sprintf
				    (qq(%s\n<response %s command="%s"
					status="break"
					reason="ok" transaction_id="%s" %s>),
				     xmlHeader(),
				     namespaceAttr(),
				     $cmd,
				     $transactionID,
				     fileAndLineIfXdebug()));
		    next CMD;
		} else {
		    $stopReason = STOP_REASON_RUNNING;
		    last CMD;
		}

	    } elsif ($cmd eq 'stop') { #xxxstop
		$fall_off_end = 1;
		$stopReason = STOP_REASON_STOPPING;
		printWithLength(sprintf(qq(%s\n<response %s command="%s" status="%s"
					   reason="ok" transaction_id="%s"/>),
					xmlHeader(),
					namespaceAttr(),
					$cmd,
					'stopped',
					$transactionID));
		dblog("Exiting script on stop command ...\n") if $ldebug;
		close $IN;
		close $OUT;
		exit 0;

	    } elsif ($cmd eq 'detach') {
		$stopReason = STOP_REASON_STOPPED;
		$runnonstop = 1;
		# continue
		for (my $i=0; $i <= $#stack; ) {
		    $stack[$i++] &= ~1;
		}
		# Disable all the move commands
		map { $supportedCommands{$_} = 0 } (qw(run step_into step_over step_out detach));
		# status will be emitted when the program hits the end
		$lastContinuationCommand = $cmd;
		$lastContinuationStatus = 'stopping';
		$lastTranID = $transactionID;
		last CMD;

		# Breakpoint commands...
	    } elsif ($cmd eq 'breakpoint_update') {
		my %opts;
		{
		    local *ARGV = \@cmdArgs;
		    shift @ARGV;
		    getopts('d:h:n:o:r:s:t:', \%opts);
		}
		my $bkptID = $opts{d};
		my $bNewState = $opts{s} || BKPT_REQ_ENABLED;
		my $bIsTemporary = $opts{r} ? 1 : 0;
		my $bHitCount = $opts{h};
		my $bHitConditionOperator = $opts{o};

		# Currently ignored:
		# -n <line no>

		my $bptErrorCode = 0;
		my $bptErrorMsg;
		my $fileNameTableInfo;
		my $bpCmd;
		my ($bFileURINo, $bLine, $bState, $bType, $bFunction, $bExpression, $bException, $bHitInfo) = getBkPtInfo($bkptID);
		if (!defined $bFileURINo) {
		    $bptErrorCode = DBP_E_NoSuchBreakpoint;
		    $bptErrorMsg = "Unknown breakpoint ID $bkptID.";
		} elsif (!getURIByNo($bFileURINo)) {
		    $bptErrorCode = DBP_E_NoSuchBreakpoint;
		    $bptErrorMsg = "Unknown fileURI NO $bFileURINo.";
		} elsif (!($fileNameTableInfo = $fileNameTable[$bFileURINo])) {
		    $bptErrorCode = DBP_E_NoSuchBreakpoint;
		    $bptErrorMsg = "No fileURI info under URI NO $bFileURINo.";
		}		    

		if ($bptErrorCode == 0) {
		    $bpCmd = ($bNewState eq BKPT_REQ_DISABLED
				 ? BKPT_DISABLE
				 : ($bIsTemporary
				    ? BKPT_TEMPORARY
				    : BKPT_ENABLE));
		    if (!setBkPtState($bkptID, $bpCmd)) {
			$bptErrorCode = DBP_E_BreakpointNotSet;
			$bptErrorMsg = sprintf("Can't %able breakpoint ID %s",
					       $bpCmd == BKPT_DISABLE ? 'dis' : 'en',

					       $bkptID);
		    } elsif ($bHitCount || $bHitConditionOperator) {
			# Komodo only sends in changed values, so merge in old values
			if (!$bHitCount && $bHitInfo->[HIT_TBL_VALUE]) {
			    $bHitCount = $bHitInfo->[HIT_TBL_VALUE];
			}
			if (!$bHitConditionOperator && $bHitInfo->[HIT_TBL_COND_STRING]) {
			    $bHitConditionOperator = $bHitInfo->[HIT_TBL_COND_STRING];
			}
		    }
		}
		if ($bptErrorCode == 0) {
		    my $perlFileName = $fileNameTableInfo->[2];
		    our %dbline;
		    local *dbline = $main::{'_<' . $perlFileName};

		    $dbline{$bLine} = $bpCmd == BKPT_ENABLE ? 1 : 0;
		    if ($bHitCount) {
			setBkPtHitInfo($bkptID, $bHitCount, $bHitConditionOperator);
		    } elsif (!$bHitInfo
			     || !defined $bHitInfo->[HIT_TBL_EVAL_FUNC]) {
			setNullBkPtHitInfo($bkptID);
		    } else {
			dblog("breakpoint_update -- doing nothing") if $ldebug;
		    }
		    dblog("doing op $cmd\n") if $ldebug;
		    my $res = sprintf(qq(%s\n<response %s command="%s"
					 transaction_id="%s" >),
				      xmlHeader(),
				      namespaceAttr(),
				      $cmd,
				      $transactionID);
		    my $bpInfo = getBreakpointInfoString($bkptID);
		    if (! defined $bpInfo || length $bpInfo == 0) {
			makeErrorResponse($cmd,
					  $transactionID,
					  DBP_E_NoSuchBreakpoint,
					  "Unknown breakpoint ID $bkptID.");
		    } else {
			$res .= $bpInfo;
			$res .= "\n</response>\n";
			dblog("$cmd => $res") if $ldebug;
			printWithLength($res);
		    }
		} else {
		    dblog("failed to do op $cmd (error code $bptErrorCode)\n") if $ldebug;
		    makeErrorResponse($cmd,
				      $transactionID,
				      $bptErrorCode,
				      $bptErrorMsg);
		}
	    } elsif ($cmd eq 'breakpoint_remove') {
		my $bkptID = getArg(\@cmdArgs, '-d');
		my $bptErrorCode = 0;
		my $bptErrorMsg;
		my ($bFileURINo, $bLine, $bState, $bType, $bFunction, $bExpression, $bException) = getBkPtInfo($bkptID);
		if ($bType eq 'watch') {
		    dblog("Deleting watchpoint [$bExpression]") if $ldebug;
		    my $i_cnt = 0;
		    foreach (@watchPoints) {
			my $val = $watchPoints[$i_cnt];

			# Does this one match the command argument?
			if ($val eq $bExpression) { # =~ m/^\Q$i$/) {
				# Yes. Turn it off, and its value too.
			    splice(@watchPoints, $i_cnt, 1);
			    splice(@watchPointValues, $i_cnt, 1);
			    last;
			}
			$i_cnt++;
		    }		## end foreach (@watchPoints)
		    if (--$numWatchPoints <= 0) {
			dblog("No more watching anything [\$numWatchPoints = $numWatchPoints]") if $ldebug;
			$numWatchPoints = 0;
			$trace &= ~2;
		    } else {
			dblog("Still watching $numWatchPoints watchPoints") if $ldebug;
		    }
		} elsif (!defined $bFileURINo) {
		    $bptErrorCode = DBP_E_NoSuchBreakpoint;
		    $bptErrorMsg = "Unknown breakpoint ID $bkptID.";
		} elsif (!getURIByNo($bFileURINo)) {
		    $bptErrorCode = DBP_E_NoSuchBreakpoint;
		    $bptErrorMsg = "Unknown fileURI NO $bFileURINo.";
		}

		if (!deleteBkPtInfo($bkptID)) {
		    $bptErrorCode = DBP_E_NoSuchBreakpoint;
		    $bptErrorMsg = "Problems deleting breakpoint ID $bkptID";
		} else {
		    remove_FileURI_LineNo_Breakpoint($bFileURINo, $bLine);
		}
		if ($bptErrorCode == 0) {
		    my $res = sprintf(qq(%s\n<response %s command="%s"
					 transaction_id="%s" />\n),
				      xmlHeader(),
				      namespaceAttr(),
				      $cmd,
				      $transactionID);
		    dblog("$cmd => $res") if $ldebug;
		    printWithLength($res);
		} else {
		    makeErrorResponse($cmd,
				      $transactionID,
				      $bptErrorCode,
				      $bptErrorMsg);
		}

	    } elsif ($cmd eq 'breakpoint_get') {
		my $bkptID = getArg(\@cmdArgs, '-d');
		my $res = sprintf(qq(%s\n<response %s command="%s"
				     transaction_id="%s" >),
				  xmlHeader(),
				  namespaceAttr(),
				  $cmd,
				  $transactionID);
		my $bpInfo = getBreakpointInfoString($bkptID);
		if (! defined $res || length $res == 0) {
		    makeErrorResponse($cmd,
				      $transactionID,
				      DBP_E_NoSuchBreakpoint,
				      "Unknown breakpoint ID $bkptID.");
		    next CMD;
		}
		$res .= $bpInfo;
		$res .= "\n</response>\n";
		dblog("$cmd => $res") if $ldebug;
		printWithLength($res);

	    } elsif ($cmd eq 'breakpoint_list') {
		my $res = sprintf(qq(%s\n<response %s command="%s"
				     transaction_id="%s" >),
				  xmlHeader(),
				  namespaceAttr(),
				  $cmd,
				  $transactionID);

		for my $fileURINo (0 .. $#bkptLookupTable) {
		    my $fileURIInfo = $bkptLookupTable[$fileURINo];
		    next unless $fileURIInfo;
		    while (my ($lineNo, $bkptID) = each %$fileURIInfo) {
			my $bpInfo = getBreakpointInfoString($bkptID, fileURI => $fileURINo, lineNo => $lineNo);
			$res .= $bpInfo if $bpInfo;
		    }
		}
		dblog("bpList: FQFnNameLookupTable: ", DB::Data::Dump::dump(%FQFnNameLookupTable)) if $ldebug;
		while (my ($bFunction, $val) = each %FQFnNameLookupTable) {
		    dblog("info($bFunction, $val): ", DB::Data::Dump::dump($val)) if $ldebug;
		    while (my ($bType, $bkptID) = each %$val) {
			my $bpInfo = getBreakpointInfoString($bkptID, function => $bFunction);
			$res .= $bpInfo if $bpInfo;
		    }
		}
		$res .= "\n</response>\n";
		dblog("$cmd => $res") if $ldebug;
		printWithLength($res);

	    } elsif ($cmd eq 'breakpoint_set') {
		my %opts;
		{
		    local *ARGV = \@cmdArgs;
		    shift @ARGV;
		    getopts('c:f:h:m:n:o:r:s:t:x', \%opts);
		}

		# For now, set the filename to either $opts{f} or curr filename
		my $bHitCount = $opts{h};
		my $bFunctionName = $opts{m};
		my $bLine = $opts{n} || $currentLine;
		my $bHitConditionOperator = $opts{o};
		my $bIsTemporary = $opts{r} ? 1 : 0;
		my $bState = $opts{s} || BKPT_REQ_ENABLED;
		my $bType = $opts{t};
		my $bException = $opts{x};
		my $bCondition = "";
		if (exists $opts{f}) {
		    $opts{f} =~ s@^dbgp:///file:/@file:/@;
		    $opts{f} =~ s@^file:/([^/])@file://$1@;
		    # work around broken clients
		    $opts{f} =~ s@^file%3[Aa]//@file://@;
		    $opts{f} = 'file://' . $opts{f} unless
			$opts{f} =~ m@^(?:file|dbgp)://@;
		}
		my ($bFileURINo, $bkptID, $bStateVal);
		my ($perlFileName, $bFileURI, $bFileName);
		my $bptErrorCode = 0;
		my $bptErrorMsg = undef;

                if (rindex($opts{f}, "$full_dbgp_prefix/", 0) == 0) {
		    my ($evalIdx, $encodedName) = $opts{f} =~ m{^\Q$full_dbgp_prefix/\E(\d+)/(.*)$};
		    my $evalName = decodeData($encodedName, 'urlescape');
		    my $evalInfo = $evalTableIdx[$evalIdx] &&
			$evalTableIdx[$evalIdx] &&
			$evalTable{$evalTableIdx[$evalIdx]};

		    if ($evalName && $evalInfo) {
			$bFileURI = $opts{f};
			$bFileName = $opts{f};
			$bFileURINo = internFileURI($bFileURI);
			$perlFileName = $evalTableIdx[$evalIdx];
		    }
                } else {
		    getFileInfo(defined $opts{f} ? $opts{f} : calcFileURI($currentFilename),
			        \$bFileURI,
			        \$bFileURINo,
			        \$bFileName,
			        \$perlFileName);
                }

		if ($opts{f} =~ m@^dbgp:///perl//(?:PerlApp/|<.*>)@) {
		    $bptErrorCode = DBP_E_BreakpointTypeNotSupported;
		    $bptErrorMsg = "Breakpoints in compiled modules are not supported.";
		} elsif (defined $bException) {
		    # Don't support break on exceptions
		    $bptErrorCode = DBP_E_BreakpointTypeNotSupported;
		    $bptErrorMsg = "Breaking on exceptions not supported.";
		} elsif (defined $bFunctionName) {
		    if (!defined $bType || ($bType ne 'call'
					    &&  $bType ne 'return')) {
			$bptErrorMsg = "Breaking on functions requires a breakpoint type of 'call' or 'return', got [$bType].";
			$bptErrorCode = DBP_E_InvalidOption;
		    }
		} elsif ($bType eq 'conditional') {
		    if (!defined $bLine) {
			$bptErrorCode = DBP_E_InvalidOption;
			$bptErrorMsg = "Line number required for setting a conditional breakpoint in Perl.";
		    } else {
			$bType = 'line';
			if ($cmdArgs[0] && length $cmdArgs[0]) {
			    $bCondition = $cmdArgs[0];
			    dblog("Got raw condition [$bCondition]") if $ldebug;
			    $bCondition = decodeData($bCondition);
			    dblog("Got decoded condition [$bCondition]") if $ldebug;
			} else {
			    $bptErrorCode = DBP_E_InvalidOption;
			    $bptErrorMsg = "Condition required for setting a conditional breakpoint.";
			}
		    }
		} elsif ($bType eq 'watch') {
		    my $bptErrorCode = 0;
		    my $bptErrorMsg;
		    if ($cmdArgs[0] && length $cmdArgs[0]) {
			$bCondition = $cmdArgs[0];
			dblog("Got raw condition [$bCondition]") if $ldebug;
			$bCondition = decodeData($bCondition);
			dblog("Got decoded condition [$bCondition]") if $ldebug;
			if ($bCondition) {
			    $evalarg = $bCondition;
			    my ($val) = eval { join(' ', &eval) };
			    $val = (defined $val) ? "'$val'" : 'undef';
			    push @watchPoints, $bCondition;
			    push @watchPointValues, $val;
				# We are now watching expressions.
			    $trace |= 2;
			    ++$numWatchPoints;
			}
		    } else {
			$bptErrorCode = DBP_E_InvalidOption;
			$bptErrorMsg = "Expression required for setting a watchpoint.";
		    }
		} elsif (defined $bType && $bType ne 'line') {
		    $bptErrorMsg = "Breakpoint type of $bType not supported -- only 'line' is supported.";
		    $bptErrorCode = DBP_E_BreakpointTypeNotSupported;

		} elsif (!defined $bFileName && !defined $bLine) {
		    # Need a filename and a line no for breaking
		    $bptErrorMsg = "Filename and line number required for setting a breakpoint.";
		    $bptErrorCode = DBP_E_InvalidOption;
		} elsif ($bLine < 0) {
		    $bptErrorMsg = "Negative line numbers not supported (got [$bLine])";
		    $bptErrorCode = DBP_E_InvalidOption;
		} elsif ($bHitConditionOperator && ! defined $bHitCount) {
		    $bptErrorMsg = "Hit condition operator specified without a target hit count.";
		    $bptErrorCode = DBP_E_InvalidOption;
		}

		# Figure out our state
		if ($bptErrorCode == 0) {
		    if ($bState eq BKPT_REQ_ENABLED) {
			$bStateVal = $bIsTemporary ? BKPT_TEMPORARY : BKPT_ENABLE;
		    } elsif ($bState eq BKPT_REQ_DISABLED) {
			$bStateVal = BKPT_DISABLE;
		    } else {
			$bptErrorCode = DBP_E_BreakpointStateInvalid;
			$bptErrorMsg = "Breakpoint state '$bState' not recognized.";
		    }
		}

		if ($bptErrorCode != 0) {
		    makeErrorResponse($cmd,
				      $transactionID,
				      $bptErrorCode,
				      $bptErrorMsg);
		    next CMD;
		}

		if ($bFunctionName) {
		    my @bptIDs =
			findAndAddFunctionBreakPoints($bFunctionName,
						      defined $opts{f} && $perlFileName,
						      $opts{n},
						      $bCondition,
						      $bStateVal,
						      $bIsTemporary,
						      $bType,
						      $bHitCount,
						      $bHitConditionOperator);
		    if (@bptIDs == 0) {
			# No breakpoints found
			my $fname = $opts{f} || "any loaded file";
			my $msg = "Currently can't find sub $bFunctionName in $fname.";
			makeErrorResponse($cmd,
					  $transactionID,
					  DBP_E_NoSuchBreakpoint,
					  $msg);
			next CMD;
		    } elsif (@bptIDs == 1) {
			$bkptID = $bptIDs[0];
		    }
		} else {
		    # None of these can fail
		    if ($bType eq 'watch') {
			$bkptID = internFunctionName_watchedExpn($bCondition);
		    } else {
			$bkptID = internFileURINo_LineNo($bFileURINo, $bLine);
		    }
		    storeBkPtInfo($bkptID, $bFileURINo, $bLine, $bStateVal, $bType, undef, $bCondition);
		    if ($bHitCount) {
			setBkPtHitInfo($bkptID, $bHitCount, $bHitConditionOperator);
		    } else {
			setNullBkPtHitInfo($bkptID);
		    }

		    #todo: add pending, etc. on the dbline thing
		    if (defined $perlFileName && $bStateVal != BKPT_DISABLE) {
			our %dbline;
			local *dbline = $main::{'_<' . $perlFileName};
			if ($bLine < 1 || $bLine > $#dbline || $dbline[$bLine] == 0) {
			    my $code = (($bLine < 1 || $bLine > $#dbline)
					? DBP_E_Unbreakable_InvalidCodeLine
					: DBP_E_Unbreakable_EmptyCodeLine);
			    makeErrorResponse($cmd,
					      $transactionID,
					      $code,
					      "Line $bLine isn't breakable");
			    next CMD;
			}
			$dbline{$bLine} = 1;
			if ($ldebug) {
			    dblog("Here are the breakpoints for file [$perlFileName] (ID $bkptID, fileNum $bFileURINo):\n");
			    dblog((join(", ", grep ($dbline{$_}, keys %dbline)), "\n"));
			}
		    } else {
			if ($ldebug) {
			    my $str = "Curr file = |$currentFilename|, bpt set for file |$bFileName|, bStateVal = |$bStateVal|, \$bFileURI = |$bFileURI|";
			    $str .= ", \$perlFileName=$perlFileName" if $perlFileName;
			    $str .= "\n";
			    dblog($str);
			}
		    }
		}

		printWithLength(sprintf
				(qq(%s\n<response %s command="%s" 
				    state="%s" id="%d" transaction_id="%s" />),
				 xmlHeader(),
				 namespaceAttr(),
				 $cmd,
				 $bState,
				 $bkptID,
				 $transactionID));

	    } elsif ($cmd eq 'stack_depth') {
		my $stackCount = count_trace(1);
		printWithLength(sprintf
				(qq(%s\n<response %s command="%s" 
				    depth="%d" transaction_id="%s" />),
				 xmlHeader(),
				 namespaceAttr(),
				 $cmd,
				 $stackCount,
				 $transactionID,
				 ));

	    } elsif ($cmd eq 'stack_get') {
		my $stackDepth = getArg(\@cmdArgs, '-d');
		my $numLevelsToShow;
		if (!defined $stackDepth) {
		    $numLevelsToShow = 1e9; # Get them all
		} elsif ($stackDepth !~ /^\d+$/ || $stackDepth < 0) {
		    printWithLength(sprintf
				    (qq(%s\n<response %s command="%s" 
					transaction_id="%s" ><error code="%d" apperr="4">
					<message>%s</message>
					</error></response>),
				     xmlHeader(),
				     namespaceAttr(),
				     $cmd,
				     $transactionID,
				     DBP_E_StackDepthInvalid,
				     "Invalid stack depth arg of '$stackDepth'"));
		    next CMD;
		} else {
		    $numLevelsToShow = $stackDepth;
		}
		my $res = sprintf(qq(%s\n<response %s command="%s"
				     transaction_id="%s" >),
				  xmlHeader(),
				  namespaceAttr(),
				  $cmd,
				  $transactionID);
		my @sub = dump_trace(0); # , $numLevelsToShow);
		# dblog("raw stack trace = ", DB::Data::Dump::dump(@sub), "\n") if $ldebug;
		if (@sub && $sub[0]->{line} == 0) {
		    # We have no active stacks at this point
		    @sub = ();
		}
		if (defined $stackDepth || scalar @sub == 0) {
		    if (defined $stackDepth) {
			if ($stackDepth > scalar @sub) {
			    printWithLength(sprintf
					    (qq(%s\n<response %s command="%s" 
						transaction_id="%s" ><error code="%d" apperr="4">
						<message>%s</message>
						</error></response>),
					     xmlHeader(),
					     namespaceAttr(),
					     $cmd,
					     $transactionID,
					     DBP_E_StackDepthInvalid,
					     "Invalid stack depth arg of '$stackDepth'"));
			    next CMD;
			}
			if ($stackDepth == 0) {
			    $res .= sprintf(qq(<stack level="%d"
					       type="%s"
					       filename="%s"
					       lineno="%s"
					       where="%s"/>),
					    $stackDepth,
					    checkForEvalStackType($sub[0]->{sub}),
					    calcFileURI $currentFilename,
					    $currentLine,
					    (($#sub >= 0 && $sub[0]{sub})
					     ? trimEvalSubNames ($sub[0]{sub})
					     : 'main'),
					    );
			} else {
			    my $sub2 = $sub[$stackDepth - 1];
			    dblog("raw stack trace [$stackDepth] = ", DB::Data::Dump::dump($sub2), "\n") if $ldebug;
			    $res .= sprintf(qq(<stack level="%d"
					       type="%s"
					       filename="%s"
					       lineno="%s"
					       where="%s"/>),
					    $stackDepth,
					    checkForEvalStackType($sub[$stackDepth]->{sub}),
					    calcFileURI $sub2->{file},
					    $sub2->{line},
					    ($sub[$stackDepth]->{sub}
					     ? trimEvalSubNames ($sub[$stackDepth]{sub})
					     : 'main'),
					    );
			}
		    } else {
			$res .= sprintf(qq(<stack level="%d"
					   type="%s"
					   filename="%s"
					   lineno="%s"
					   where="%s"/>),
					0,
					checkForEvalStackType($sub[0]->{sub}),
					calcFileURI $currentFilename,
					$currentLine,
					(($#sub >= 0 && $sub[0]{sub})
					 ? trimEvalSubNames ($sub[0]{sub})
					 : 'main'),
					);
		    }
		} else {
		    # We get back a stack of callers, and need to
		    # transform it into a stack of positions
		    $res .= sprintf(qq(<stack level="%d"
				       type="%s"
				       filename="%s"
				       lineno="%s"
				       where="%s"/>),
				    0,
				    checkForEvalStackType($sub[0]->{sub}), # where we are
				    calcFileURI $currentFilename, # and where we were called
				    $currentLine,
				    (($#sub >= 0 && $sub[0]{sub})
				     ? trimEvalSubNames($sub[0]{sub})
				     : 'main'),
				    );

		    my $i;
		    for ($i = 1 ; $i <= $#sub ; $i++) {
			$res .= sprintf(qq(<stack level="%d"
					   type="%s"
					   filename="%s"
					   lineno="%s"
					   where="%s"/>),
					$i,
					checkForEvalStackType($sub[$i]->{sub}),
					calcFileURI $sub[$i - 1]->{file},
					$sub[$i - 1]->{line},
					trimEvalSubNames($sub[$i]{sub}),
					);
		    }
		    $res .= sprintf(qq(<stack level="%d"
				       type="%s"
				       filename="%s"
				       lineno="%s"
				       where="%s"/>),
				    $i,
				    checkForEvalStackType($sub[$#sub]->{sub}),
				    calcFileURI $sub[$#sub]->{file},
				    $sub[$#sub]->{line},
				    'main');
		}
		$res .= "\n</response>\n";
		# dblog("$cmd => $res") if $ldebug;
		printWithLength($res);

	    } elsif ($cmd eq 'context_names') {
		emitContextNames($cmd,
				 $transactionID);

	    } elsif ($cmd eq 'context_get') {
		my $stackDepth = getArg(\@cmdArgs, '-d');
		my $context_id = getArg(\@cmdArgs, '-c');
		$stackDepth = 0 unless defined $stackDepth;
		local $settings{max_depth}[0] = 0
                    unless $xdebug_full_values_in_context;
		my $currStackSize = count_trace(0); # , $numLevelsToShow;
		dblog("main->getContextProperties: \$currStackSize = $currStackSize\n") if $ldebug;
		my $namesAndValues;
		if ($context_id == FunctionArguments) {
		    my @savedArgs;
		    my $actualStackDepth = $stackDepth + 1;
		    while (1) {
			my @unused = caller($actualStackDepth);
			if (!@unused) {
			    last;
			} elsif ($unused[3] eq '(eval)' && !$unused[4]) {
			    $actualStackDepth++;
				# dblog("context_get: moving up to level $actualStackDepth");
			} else {
				# dblog("context_get: settle on caller => [@unused]");
				# dblog("stack depth [$actualStackDepth]: curr args are [", join(", ", @args), "]") if $ldebug;
			    @savedArgs = @args;
			    last;
			}
		    }
		    if (@savedArgs) {
			# Are there args?  This gets around Perl's
			# behavior where if caller fails it doesn't
			# change the value of @args

			# dblog("caller => [@unused]");
			# dblog("stack depth [$stackDepth]: curr args are [", join(", ", @args), "]") if $ldebug;
			$namesAndValues = [];
			for (my $j = 0; $j < @savedArgs; $j++) {
			    push @$namesAndValues, [sprintf('$_[%d]', $j), $savedArgs[$j], 0];
			}
		    }
		} elsif ($context_id == LocalVars) {
		    $namesAndValues = eval {
                        hasPadWalker() ?
                            getProximityVarsViaPadWalker($pkg, $currentFilename, $currentLine, $stackDepth) :
                            getProximityVarsViaB($pkg, $currentFilename, $currentLine, $stackDepth);
                    };
		} else {
		    $namesAndValues = eval { getContextProperties($context_id, $pkg); };
		}
		if ($@) {
		    my ($code, $error) = ($@ =~ /code:(.*):error<:<(.*?)>:>/);
		    if (!$code) {
			$code = DBP_E_ParseError;
			$error = _trimExceptionInfo($@);
		    }
		    makeErrorResponse($cmd,
				      $transactionID,
				      $code,
				      $error);
		    next CMD;
		}
		#dblog("unsorted vars:", DB::Data::Dump::dump($namesAndValues), "\n") if $ldebug;
		my @sortedNames;
		if ($context_id != FunctionArguments) {
		    @sortedNames = sort {
			# For some reason this doesn't work as an external fn
			# All the values come in undef'ed
			my ($a1, $a2) = split(//, $a->[0], 2);
			my ($b1, $b2) = split(//, $b->[0], 2);
			($a2 cmp $b2 || $a1 cmp $b1);
		    } @$namesAndValues;
		} else {
		    @sortedNames = @$namesAndValues;
		}
		if ($ldebug) {
		    my @names = map $_->[NV_NAME], @sortedNames;
		    dblog("Found variables: @names");
		}
		# dblog("sorted vars:", DB::Data::Dump::dump(@sortedNames), "\n") if $ldebug;
		foreach my $entry (@sortedNames) {
		    if ($entry->[NV_NEED_MAIN_LEVEL_EVAL]) {
			eval {
			    $entry->[NV_VALUE] = eval_term($entry->[NV_NAME]);
			};
			if ($@) {
			    $entry->[NV_VALUE] = _trimExceptionInfo($@);
			    $entry->[NV_UNSET_FLAG] = 1;
			}
		    }
		}
		# If anything had to be re-evaluated, and didn't return
		# a value, remove it.
		@sortedNames = grep { !($_->[NV_NEED_MAIN_LEVEL_EVAL])
					  || defined $_->[NV_VALUE] } @sortedNames;
		if ($context_id == PunctuationVariables) {
		    # Filter out unset values, and add the pattern-matching ones.
		    @sortedNames = grep { ! defined $_->[NV_UNSET_FLAG] } @sortedNames;
		    # And add the pattern-match vars
		    $evalarg = '$#-';
		    my ($numPVs) = &eval();
		    for (my $pvnum = $numPVs; $pvnum > 0; $pvnum--) {
			eval {
			    my $pvname = "\$$pvnum";
			    $evalarg = $pvname;
			    my ($val) = &eval();
			    if (length $val) {
				unshift @sortedNames, [$pvname, $val, 1];
			    }
			};
		    }
		}
		eval { emitContextProperties($cmd, $transactionID, $context_id, \@sortedNames, $settings{max_data}[0]); };
	    } elsif ($cmd eq 'typemap_get') {
		emitTypeMapInfo($cmd, $transactionID);

	    } elsif ($cmd eq 'property_get' || $cmd eq 'property_value') {
		# First get the args, and then sanity check.
		my %opts;
		{
		    local *ARGV = \@cmdArgs;
		    shift @ARGV;
		    getopts('c:d:k:m:n:p:', \%opts);
		}
		my $context_id = $opts{c};
		my $stackDepth = $opts{d} || 0;
		my $propertyKey = $opts{k};
		my $maxDataSize = $opts{m} || $settings{max_data}[0];
		my $property_long_name = $opts{n};
		my $pageIndex = $opts{p} || 0;
		$property_long_name = nonXmlChar_Decode($property_long_name);
                if ($context_id == FunctionArguments &&
                            $property_long_name ne '@_' &&
                            $property_long_name !~ /^\$_\[/) {
			makeErrorResponse($cmd,
					  $transactionID,
					  DBP_E_CantGetProperty,
					  "Property $property_long_name doesn't identify an arg");
			next CMD;
                }
		(my $fullName, $propertyKey) = makeFullPropertyName($property_long_name, $propertyKey);
		my $nameAndValue = [$fullName, undef, 1];
		# + 1 is for the eval BLOCK below
		local $evalSkipFrames = $evalSkipFrames + 1;
		local $evalStackLevel = $stackDepth;
		eval {
		    $nameAndValue->[NV_VALUE] = eval_term($nameAndValue->[NV_NAME]);
		};
		if ($@) {
		    $nameAndValue->[NV_VALUE] = _trimExceptionInfo($@);
		    $nameAndValue->[NV_UNSET_FLAG] = 1;
		}
		eval {
		    emitEvaluatedPropertyGetInfo($cmd,
						 $transactionID,
						 $nameAndValue,
						 $property_long_name,
						 $propertyKey,
						 $maxDataSize,
						 $pageIndex);
		};
		if ($@) {
		    dblog("Error in emitEvaluatedPropertyGetInfo: [$@]") if $ldebug;
		    makeErrorResponse($cmd,
				  $transactionID,
				  DBP_E_InternalException,
				  "Internal error while formatting result");
		}
	    } elsif ($cmd eq 'property_set') {
		# First get the args, and then sanity check.
		my %opts;
		{
		    local *ARGV = \@cmdArgs;
		    shift @ARGV;
		    getopts('a:c:d:l:n:t:', \%opts);
		}
		my $context_id = $opts{c};
		my $stackDepth = $opts{d} || 0;
		my $advertisedDataLength = $opts{l} || 0;
		my $property_long_name = $opts{n};
		$property_long_name = nonXmlChar_Decode($property_long_name);
		my $valueType = $opts{t};

		if ($context_id == FunctionArguments) {
		    makeErrorResponse($cmd,
				      $transactionID,
				      DBP_E_CantSetProperty,
				      "This debugger currently doesn't modify function arguments");
		    next CMD;
		}

		my ($actualDataLength, $currDataEncoding, $decodedData);
		if (scalar @cmdArgs) {
		    ($actualDataLength, $currDataEncoding, $decodedData) =
			decodeCmdLineData($cmd, $transactionID, $advertisedDataLength, \@cmdArgs);
		}
		if (!defined $decodedData) {
		    dblog("property_set: \$decodedData not defined\n") if $ldebug;
		    makeErrorResponse($cmd,
				      $transactionID,
				      DBP_E_CantSetProperty,
				      "Can't decode the data");
		    next CMD;
		}
		if ($valueType
		    && $valueType eq 'string'
		    && substr($decodedData, 0, 1) !~ /[\"\']/) {
		    $decodedData =~ s,\\,\\\\,g;
		    $decodedData =~ s,',\\',g;
		    $decodedData = "\'$decodedData\'";
		}
		my $nameAndValue = doPropertySetInfo($cmd,
						     $transactionID,
						     $property_long_name);
		if (!$nameAndValue) {
		    # Already gave an error message
		    next CMD;
		}

		if ($nameAndValue->[NV_NEED_MAIN_LEVEL_EVAL]) {
		    $evalarg = $nameAndValue->[NV_NAME] . '=' . $decodedData;
		    # here we don't adjust $evalSkipFrames because
		    # modifying function arguments is not supported
		    eval {
			&eval();
		    };
		    if ($@) {
			# dblog("Have to deal with error [$@]\n") if $ldebug;
			# Fix $@;
			my ($code, $error) = ($@ =~ /code:(.*):error<:<(.*?)>:>/);
			if (!$code) {
			    $code = DBP_E_CantGetProperty;
			    $error = _trimExceptionInfo($@);
			}
			makeErrorResponse($cmd,
					  $transactionID,
					  207, #XXX: Invalid expression
					  $error);
		    } else {
			my $res = sprintf(qq(%s\n<response %s command="%s"
					     transaction_id="%s" success="1" />),
					  xmlHeader(),
					  namespaceAttr(),
					  $cmd,
					  $transactionID);
			printWithLength($res);
		    }
		}

	    } elsif ($cmd eq 'source') {
		my %opts;
		{
		    local *ARGV = \@cmdArgs;
		    dblog("source: args={@ARGV}") if $ldebug;

		    shift @ARGV;
		    getopts('b:e:f:', \%opts);
		}
		# Line 0 contains the 'require perl5db.pl thing'?
		my $beginLine = $opts{b} || 1;
		$beginLine < 1 and $beginLine = 1;
		my $endLine;
		my $sourceString;
		my $error;
		$opts{f} = calcFileURI $currentFilename unless exists $opts{f};
		if (defined &INC && $opts{f} =~ m@^dbgp:///perl//(PerlApp/|<.*?>)(.*)@) {
		    # Definitely three slashes between 'perl' and 'PerlApp'
		    my $pdkUtilityName = $1;
		    my @lines = split(/\n/, INC($2));
		    $endLine = $opts{e} || $#lines;
		    dblog("Line " . __LINE__ . ": Debugging a $pdkUtilityName module, grab source($1) and get [" . join("\n", @lines[0..2]) . "]") if $ldebug;
		    ($sourceString, $error) =
			_fileSource($1,
				    $beginLine,
				    $endLine,
				    \@lines);
		    # One slash or two in this next pattern?
		} elsif ($opts{f} =~ m@^dbgp:///?perl/.*(\d+)(/\(eval\s\d+\).*)$@ || $opts{f} =~ m@^dbgp:///?perl/.*(\d+)(/%28eval%20\d+%29.*)$@) {
		    dblog("source: it's a dbgp thing ($1/$2)") if $ldebug;
		    my $dynLocnIdx = $1;
		    my $dynamicLocation;
		    if (defined $evalTableIdx[$dynLocnIdx]
			    && exists $evalTable{$evalTableIdx[$dynLocnIdx]}) {
			dblog("source -- mapping \$dynamicLocation = $dynamicLocation to evalstring" . $evalTableIdx[$dynLocnIdx]) if $ldebug;
			$dynamicLocation = $evalTableIdx[$dynLocnIdx];
		    } else {
			dblog("source -- can't resolve numeric \$dynamicLocation = $dynamicLocation") if $ldebug;
			$error = "Can't find src for location $dynamicLocation";
		    }
		    # dblog("source: locn = ", $dynamicLocation) if $ldebug;
		    if (!$error) {
			if (!exists $evalTable{$dynamicLocation}) {
			    our $dbline;
			    local *dbline = $main::{"_<$dynamicLocation"};
			    if ($dbline eq $dynamicLocation) {
				if ($dynamicLocation =~ /\(eval (\d+)\)\[(.*):(\d+)\]$/) {
				    my ($innerEvalIdx, $parentLocation, $startingPoint) = ($1, $2, $3);
				    my $etCount = scalar @evalTableIdx;
				    $evalTable{$dynamicLocation} = {
					file => $parentLocation,
					startLine => $startingPoint,
					src => \@dbline,
					idx => $etCount,
				    };
				    $evalTableIdx[$etCount] = \$evalTable{$currentFilename};
				} else {
				    dblog "get source error: Can't parse [$dynamicLocation]\n" if $ldebug;
				}
			    } else {
				dblog "get source error: Can't find a glob from [$dynamicLocation]\n" if $ldebug;
			    }
			}
			if (exists $evalTable{$dynamicLocation}) {
			    my @src = @{$evalTable{$dynamicLocation}{src}};
			    $endLine = $opts{e} || $#src;
			    $endLine < $beginLine and $endLine = $beginLine;
			    eval {
				$sourceString = join("",
						     @src[$beginLine .. $endLine]
						     );
			    };
			} else {
			    $error = "Can't find src for URI " . $opts{f};
			}
		    }
		} else {
		    my ($bFileURI,
			$bFileURINo,
			$bFileName,
			$perlFileName);
		    # work around broken clients
		    $opts{f} =~ s@^file%3[Aa]//@file://@;
		    $opts{f} = 'file://' . $opts{f} unless
			$opts{f} =~ m@^(?:file|dbgp)://@;
		    $endLine = $opts{e};

		    getFileInfo($opts{f},
				\$bFileURI,
				\$bFileURINo,
				\$bFileName,
				\$perlFileName);
		    dblog("** source -- file $currentFilename, perl name $perlFileName") if $ldebug;
		    ($sourceString, $error) =
			_fileSource($perlFileName,
				    $beginLine,
				    $endLine,
				    \@dbline)
			if $perlFileName;
		}
		if ($error || !$sourceString) {
		    if (!$error) {
			dblog("Failed to set an error, but got no string") if $ldebug;
			$error = "source cmd -- unknown error";
		    } else {
			dblog("source: $error\n") if $ldebug;
		    }
		    makeErrorResponse($cmd,
				      $transactionID,
				      DBP_E_CantOpenSource,
				      $error);
		    next CMD;
		};
		my ($encoding, $encVal) = figureEncoding($sourceString);
		my $res = sprintf(qq(%s\n<response %s command="%s"
				     transaction_id="%s"
				     success="1"
				     encoding="%s"
				     >%s</response>\n),
				  xmlHeader(),
				  namespaceAttr(),
				  $cmd,
				  $transactionID,
				  $encoding,
				  $encVal);
		printWithLength($res);

	    } elsif ($cmd eq 'stdout' || $cmd eq 'stderr') {
		my %opts;
		{
		    local *ARGV = \@cmdArgs;
		    shift @ARGV;
		    getopts('c:', \%opts);
		}
		my $copyType = $opts{c} || 0;
		eval {
		    my $redirectType;
		    if ($copyType < DBGP_Redirect_Disable
			|| $copyType > DBGP_Redirect_Redirect) {
			makeErrorResponse($cmd,
					  $transactionID,
					  DBP_E_InvalidOption,
					  "Invalid -c value of $copyType");
			next CMD;
		    }
		    if ($cmd eq 'stdout') {
			if ($tiedStdout) {
				# Update the copy-type
			    untie(*STDOUT);
			}
			if (!open ActualSTDOUT, ">&STDOUT") {
			    makeErrorResponse($cmd,
					      $transactionID,
					      DBP_E_InvalidOption,
					      "Invalid -c value of $copyType");
			    next CMD;
			}
			tie(*STDOUT, 'DB::RedirectStdOutput', *ActualSTDOUT, $OUT, $cmd, $copyType);
			$tiedStdout = 1;
			if (logName && logName == \*STDOUT) {
			    setLogFH(\*ActualSTDOUT);
			}
		    } elsif ($cmd eq 'stderr' && !$ldebug) {
			if ($tiedStderr) {
				# Update the copy-type
			    untie(*STDERR);
			}
			if (!open ActualSTDERR, ">&STDERR") {
			    makeErrorResponse($cmd,
					      $transactionID,
					      DBP_E_InvalidOption,
					      "Invalid -c value of $copyType");
			    next CMD;
			}
			tie(*STDERR, 'DB::RedirectStdOutput', *ActualSTDERR, $OUT, $cmd, $copyType);
			$tiedStderr = 1;
			if (logName && logName == \*STDERR) {
			    setLogFH(\*ActualSTDERR);
			}
		    }
		    my $res = sprintf(qq(%s\n<response %s command="%s"
					 transaction_id="%s" success="1" />),
				      xmlHeader(),
				      namespaceAttr(),
				      $cmd,
				      $transactionID);
		    {
			local $ldebug = $cmd ne 'stderr' && $ldebug;
			printWithLength($res);
		    }
		};
		if ($@) {
		    makeErrorResponse($cmd,
				      $transactionID,
				      DBP_E_InvalidOption,
				      "Invalid -c value of $copyType");
		}
	    } elsif ($cmd eq 'stdin') {

=head unsupported

		    my %opts;
		{
		    local *ARGV = \@cmdArgs;
		    shift @ARGV;
		    getopts('c:l:', \%opts);
		}
		if ($opts{c} == 1) {
		} else {
		    dblog("stdin: opts{c} = $opts{c}\n") if $ldebug;
		    next CMD;
		}
		my $dataLength = $opts{l}; # ignore
		my $encodedData = join("", @cmdArgs);
		my $actualData = decodeData($encodedData, 'base64');
		dblog "stdin: [$actualData]\n" if $ldebug;

=cut

		makeErrorResponse($cmd,
				  $transactionID,
				  DBP_E_CommandUnimplemented,
				  "stdin not supported via protocol");
	    } elsif ($cmd eq 'eval') {
		my %opts;
		{
		    local *ARGV = \@cmdArgs;
		    shift @ARGV;
		    getopts('l:p:', \%opts);
		}
		my $dataLength = $opts{l};
		my $pageIndex = $opts{p} || 0;
		my ($actualDataLength, $currDataEncoding, $decodedData);
		if (scalar @cmdArgs) {
		    ($actualDataLength, $currDataEncoding, $decodedData) =
			decodeCmdLineData($cmd, $transactionID, $dataLength, \@cmdArgs);
		}
		if (!defined $decodedData) {
		    next CMD;
		}
		eval {
		    local $evalSkipFrames = $evalSkipFrames + 1;
		    my $res = eval_term($decodedData);
		    emitEvalResultAsProperty($cmd,
			 $transactionID,
			 $decodedData,
			 $res,
			 $settings{max_data}[0],
			 $pageIndex);
		    1;
		} or do {
		    my $error = $@ || "";

		    makeErrorResponse($cmd, $transactionID, DBP_E_PropertyEvalError, "Error in eval: $error")
		};
	    } else {
		# Fallback
		printWithLength(sprintf
				(qq(%s\n<response %s command="%s" 
				    transaction_id="%s" ><error code="6" apperr="4">
				    <message>%s command not recognized</message>
				    </error></response>),
				 xmlHeader(),
				 namespaceAttr(),
				 $cmd,
				 $transactionID));

	    }
	}
    } elsif ($pkg =~ /^DB::/) {
	dblog("Skipping package [$pkg]\n") if $ldebug;
    } elsif ($inPostponed) {
	dblog("Still postponed: [$pkg/$currentFilename/$currentLine]\n") if $ldebug;
    }
	
    # Put the user's globals back where you found them.
    ($@, $!, $,, $/, $\, $^W) = @saved;
    db_alarm($pending_check_interval);
    $pending_check_enabled = 1 unless $skip_alarm;
    return ();
}

# Avoid re-entrancy problems by putting newly entered files in a
# queue and processing them when it's appropriate.

sub postponed {
    local *dbline_arg = shift;
    push @postponedFiles, *dbline_arg;
    if ($inPostponed || !$ready) {
	return;
    }
    finish_postponed();
    return 1;
}

sub finish_postponed {
    local $inPostponed = 1;
    while (@postponedFiles) {
	our ($dbline, %dbline);
	local *dbline = shift @postponedFiles;
	my $filename = $dbline;
	$filename =~ s/^<_//;

	# Get the Perl filename, canonical filename, and URI, and see
	# if it was set as postponed
	my $perlFileName = $filename;
	my ($bFileURI, $bFileURINo, $bFileName);

	if (exists $perlNameToFileURINo{$perlFileName}) {
	    # Why are we here -- we already know about this filename.
	    $bFileURINo = $perlNameToFileURINo{$perlFileName};
	    ($bFileURI, $bFileName, undef) = @{$fileNameTable[$bFileURINo]};
	} else {
	    $bFileURI = canonicalizeURI(filenameToURI($filename, 1));
	    $bFileURINo = internFileURI($bFileURI);
	    local $@;
	    eval {
		$bFileName = canonicalizeFName(uriToFilename($bFileURI));
	    };
	    if ($@) {
		dblog("Called uriToFilename in " .
		      join("\n", dump_trace(0))) if $ldebug;
		return;
	    }
	    $perlNameToFileURINo{canonicalizeFName($perlFileName)} = $bFileURINo;
	    $fileNameTable[$bFileURINo] = [$bFileURI,
					   $bFileName,
					   $perlFileName];
	}

	if (defined $bkptLookupTable[$bFileURINo]) {
	    # Set the breakpoints in %dbline now...
	    foreach my $k (keys %{$bkptLookupTable[$bFileURINo]}) {
		$dbline{$k} = 1;
	    }
	}
    }
}

# This routine needs to localize these globals, as function
# breakpoints are not conditional.  We only need to localize
# $@ because the eval() destroys it.

sub tryBreaking($$$) {
    return if ($signal || $single); # we're about to break anyway.
    my ($bkptEntry, $fqsubname, $callDirection) = @_;
    local $@;
    eval {
	if (exists $bkptEntry->{$callDirection}) {
	    # 3 because of DB::sub + tryBreaking + the eval BLOCK
	    local $evalSkipFrames = $evalSkipFrames + 3;
	    my $breakHere = 0;
	    my $bkptInfoRef = getBkPtInfo($bkptEntry->{$callDirection});
	    processPossibleBreakpoint($bkptInfoRef, "sub $fqsubname");
	}
	if (!$single && _checkForBreak()) {
	    $single = 1;
	}
    };
    if ($@) {
	dblog "Error while trying to eval breakpoint($fqsubname, $callDirection): $@" if $ldebug;
    }
}


sub sub_pp {
    local $stack_depth = $stack_depth + 1;    # Protect from non-local exits
    $#stack = $stack_depth;
    $stack[-1] = $single;
    $single &= 1;
    $single |= 4 if $#stack == $deep;
    my $pkg = caller;
    my $inDB = ($pkg && rindex($pkg, "DB::", 0) == 0);
    my $bkptEntry = $FQFnNameLookupTable{$sub};
    tryBreaking($bkptEntry, $sub, 'call') if $bkptEntry && !$inDB;

    if (wantarray)
    {
	my @i = &$sub;
	$single |= $stack[$stack_depth];
	# it would be nicer to break on return statement inside the function
	$bkptEntry = $FQFnNameLookupTable{$sub};
	tryBreaking($bkptEntry, $sub, 'return') if $bkptEntry && !$inDB;
	@i;
    }
    else
    {
	my $i;
	if (defined wantarray) {
	    $i = &$sub;
	} else {
	    &$sub;
	};
	$single |= $stack[$stack_depth];
	# it would be nicer to break on return statement inside the function
	$bkptEntry = $FQFnNameLookupTable{$sub};
	tryBreaking($bkptEntry, $sub, 'return') if $bkptEntry && !$inDB;
	$i;
    }
}

sub lsub_pp : lvalue {
    local $stack_depth = $stack_depth + 1;    # Protect from non-local exits
    $#stack = $stack_depth;
    $stack[-1] = $single;
    $single &= 1;
    $single |= 4 if $#stack == $deep;
    my $pkg = caller;
    my $inDB = ($pkg && rindex($pkg, "DB::", 0) == 0);
    my $bkptEntry = $FQFnNameLookupTable{$sub};
    tryBreaking($bkptEntry, $sub, 'call') if $bkptEntry && !$inDB;

    # breakpoint on return not supported for lvalue subs
    &$sub;
}

# exception handling?
$SIG{'INT'} = "DB::catch";

sub catch
{
    $signal = 1;
}
#
# save
#
# Save registers.
#
sub save
{
    @saved = ($@, $!, $,, $/, $\, $^W);
    $, = ""; $/ = "\n"; $\ = ""; $^W = 0;
}

sub chr_expand {
    my $s = shift;
    return "" unless defined $s;
    $s =~ s/([\x00-\x08\x0a-\x1f\x7e-\xff])/sprintf('\\x%02x', ord($1))/eg;
    $s;
}

# Slight modification so this routine buffers,
# returning strings separated by nulls or newlines

sub readline {
    local $.;
    # Nothing on the filehandle stack. Socket?
    if (ref $OUT and UNIVERSAL::isa($OUT, 'IO::Socket')) {
        # Send anything we have to send.
	if (@_) {
	    $OUT->write(join ('', @_));
	}

        # Receive anything there is to receive.
        my $finalBuffer = '';
	if (@pending_commands) {
	    return shift @pending_commands;
	}
	my $amtToRead = 2048;
	while (1) {
	    my $thisBuffer;
	    $IN->recv($thisBuffer, $amtToRead);  # XXX "what's wrong with sysread?"
						 # XXX Don't know. You tell me.
	    # Check the size before removing nulls
	    my $leave = (length($thisBuffer) < $amtToRead);
	    # dblog("Read in [", chr_expand($thisBuffer), "], adding to [", chr_expand($finalBuffer), "]");
	    # And allow for embedded newlines
	    $thisBuffer =~ s/\r?\n//g;
	    $finalBuffer .= $thisBuffer;
	    last if $leave && (length($finalBuffer) == 0
			       || $finalBuffer =~ /\0$/);
	}
	# Remove trailing null on last command
	$finalBuffer =~ s/\0$//;
	
	# And if we read multiple commands in one go, hold on to them.
	($finalBuffer, @pending_commands) = split(/[\x00\n]/, $finalBuffer);
	if ($ldebug && @pending_commands) {
	    dblog("Multiple cmds read in: <$finalBuffer>, <",
		  join(">, <", @pending_commands), ">");
	}
        return $finalBuffer;
    } ## end if (ref $OUT and UNIVERSAL::isa...)
} ## end sub readline

sub _break_check_handler {
    if (!$single) {
	# We timed out, so move the pending-check counter up
	$pending_check_count = $pending_check_lim;
	if (_checkForBreak()) {
	    $single = 1;
	    db_alarm(0);
	}
    }
    if (!$single) {
	db_alarm($pending_check_interval);
    }
}

sub _checkForBreak {
    return if $skip_alarm;
    return unless $pending_check_enabled && $OUT_selector;
    return if ++$pending_check_count < $pending_check_lim;
    $pending_check_count = 0;
    # dblog("_checkForBreak: About to select...($pending_check_timeout)");
    my $have_something = $OUT_selector->can_read($pending_check_timeout);
    # dblog("... Done");
    return unless $have_something;
    my $cmd = &readline();
    # dblog("_checkForBreak: Got command [$cmd]\n");
    if ($cmd =~ /\Abreak\b/) {
	unshift(@pending_commands, $cmd);
	$pending_check_enabled = 0;
	return 1;
    } else {
	# Put the command back at the front, so we process it in due time.
	my $directive = $cmd;
	if (!@pending_commands
	    || ($cmd =~ /^(\w+)\b/ && $supportedCommands{$1})) {
	    unshift(@pending_commands, $cmd);
	} else {
	    dblog("_checkForBreak: Appending [$cmd] onto $pending_commands[0]\n") if $ldebug;
	    $pending_commands[0] .= $cmd;
	}
    }
    return 0;
}

sub fileAndLineIfXdebug {
    return '/' unless $xdebug_file_line_in_step;
    return sprintf '><xdebug:message filename="%s" lineno="%s" /></response',
        calcFileURI($currentFilename), $currentLine;
}

sub dump_trace {

    # How many levels to skip.
    my $skip = shift;

    # How many levels to show. (1e9 is a cheap way of saying "all of them";
    # it's unlikely that we'll have more than a billion stack frames. If you
    # do, you've got an awfully big machine...)
    my $count = shift || 1e9;

    # We increment skip because caller(1) is the first level *back* from
    # the current one.  Add $skip to the count of frames so we have a 
    # simple stop criterion, counting from $skip to $count+$skip.
    $skip++;
    $count += $skip;

    # These variables are used to capture output from caller();
    my ($p, $file, $line, $sub);

    my ($e, $r, @sub);

    # Do not want to trace this.
    local $trace = 0;

    # Start out at the skip count.
    # If we haven't reached the number of frames requested, and caller() is
    # still returning something, stay in the loop. (If we pass the requested
    # number of stack frames, or we run out - caller() returns nothing - we
    # quit.
    # Up the stack frame index to go back one more level each time.
    for (
        my $i = $skip ;
        $i < $count
        and ($p, $file, $line, $sub, undef, undef, $e, $r) = caller($i) ;
        $i++
      )
    {
        if ($p eq 'DB' || $p =~ /^DB::/) {
	    # Don't count debugger entries
	    next;
	}

        # remove trailing newline-whitespace-semicolon-end of line sequence
        # from the eval text, if any.
        $e =~ s/\n\s*\;\s*\Z//  if $e;

        # Escape backslashed single-quotes again if necessary.
        $e =~ s/([\\\'])/\\$1/g if $e;

        # if the require flag is true, the eval text is from a require.
        if ($r) {
            $sub = "require '$e'";
        }
        # if it's false, the eval text is really from an eval.
        elsif (defined $r) {
            $sub = "eval '$e'";
        }

        # If the sub is '(eval)', this is a block eval, meaning we don't
        # know what the eval'ed text actually was.
        elsif ($sub eq '(eval)') {
            $sub = "eval {...}";
        }
	if ($sub =~ /^DB::/) {
	    next;
	}

        # Stick the collected information into @sub as an anonymous hash.
        push (
            @sub,
            {
                sub     => $sub,
                file    => $file,
                line    => $line
            }
            );

        # Stop processing frames if the user hit control-C.
        last if $signal;
    } ## end for ($i = $skip ; $i < ...

    @sub;
} ## end sub dump_trace

# equivalent to scalar dump_trace(...)
sub count_trace {

    # How many levels to skip.
    my $skip = shift;

    # How many levels to show. (1e9 is a cheap way of saying "all of them";
    # it's unlikely that we'll have more than a billion stack frames. If you
    # do, you've got an awfully big machine...)
    my $count = shift || 1e9;

    # We increment skip because caller(1) is the first level *back* from
    # the current one.  Add $skip to the count of frames so we have a 
    # simple stop criterion, counting from $skip to $count+$skip.
    $skip++;
    $count += $skip;

    my ($p, $frames);

    # Do not want to trace this.
    local $trace = 0;

    # Start out at the skip count.
    # If we haven't reached the number of frames requested, and caller() is
    # still returning something, stay in the loop. (If we pass the requested
    # number of stack frames, or we run out - caller() returns nothing - we
    # quit.
    # Up the stack frame index to go back one more level each time.
    for (
        my $i = $skip ;
        $i < $count
        and ($p) = caller($i) ;
        $i++
      )
    {
        if ($p eq 'DB' || $p =~ /^DB::/) {
	    # Don't count debugger entries
	    next;
	}

        $frames++;

        # Stop processing frames if the user hit control-C.
        last if $signal;
    } ## end for ($i = $skip ; $i < ...

    $frames;
}

=head2 C<parse_options>

Trimmed down version for processing only RemotePort=\d+

=cut

sub parse_options {
    local ($_) = @_;
    local $\ = '';

    my %xdebug_map = (
	send_position_after_stepping	=> \$xdebug_file_line_in_step,
	property_without_value_tag	=> \$xdebug_no_value_tag,
	nested_properties_in_context	=> \$xdebug_full_values_in_context,
	temporary_breakpoint_state	=> \$xdebug_temporary_breakpoint_state,
    );

    while (length) {
        my $val_defaulted;

        # Clean off excess leading whitespace.
        s/^\s+//;
	
        s/^(\w+)(\W?)// or last;
        my ($opt, $sep) = ($1, $2);
        my $val;

	print OUT "Info: Opt = [$opt], sep=[$sep]\n" if $ldebug;

        # '?' as separator means query, but must have whitespace after it.
        if ("?" eq $sep) {
            print(OUT "Option query `$opt?' followed by non-space `$_'\n"),
              last
              if /^\S/;
        } ## end if ("?" eq $sep)

        # Separator is whitespace (or just a carriage return).
        # They're going for a default, which we assume is 1.
        elsif ($sep !~ /\S/) {
            $val_defaulted = 1;
            $val           = "1"; #  this is an evil default; make 'em set it!
        }

        # Separator is =. Trying to set a value.
        elsif ($sep eq "=") {
            # If quoted, extract a quoted string.
            if (s/ ([\"\']) ( (?: \\. | (?! \1 ) [^\\] )* ) \1 //x) {
                my $quote = $1;
                ($val = $2) =~ s/\\([$quote\\])/$1/g;
            }

            # Not quoted. Use the whole thing. Warn about 'option='.
            else {
                s/^(\S*)//;
                $val = $1;
                print OUT qq(Option better cleared using $opt=""\n)
                  unless length $val;
		print OUT "Info: Val = [$val]\n" if $ldebug;
            } ## end else [ if (s/ (["']) ( (?: \\. | (?! \1 ) [^\\] )* ) \1 //x)

        } ## end elsif ($sep eq "=")

        # "Quoted" with [], <>, or {}.  
        else {    #{ to "let some poor schmuck bounce on the % key in B<vi>."
            my ($end) = "\\" . substr(")]>}$sep", index("([<{", $sep), 1);  #}
            s/^(([^\\$end]|\\[\\$end])*)$end($|\s+)//
              or print(OUT "Unclosed option value `$opt$sep$_'\n"), last;
            ($val = $1) =~ s/\\([\\$end])/$1/g;
        } ## end else [ if ("?" eq $sep)

        # Impedance-match the code above to the code below.
        my $option = $opt;

        # Save the option value.
        next unless length($val);
	if (lc $option eq 'remoteport' && $val =~ /.*:\d+$/) {
	    $remoteport = $val;
	} elsif ($option eq 'RemotePath' && $val =~ /^\//) {
	    $remotepath = $val;
	} elsif ($option eq 'Xdebug') {
	    $val = $val ? 'send_position_after_stepping,property_without_value_tag,nested_properties_in_context' : ''
		if $val =~ /^\d+$/;
	    for my $tag (split /,/, $val) {
		die "Invalid Xdebug compatibility tag: '$tag'"
		    unless exists $xdebug_map{$tag};
		${$xdebug_map{$tag}} = 1;
	    }
	} elsif ($option eq 'ConnectAtStart') {
	    $connect_at_start = !!$val;
	} elsif ($option eq 'KeepRunning') {
	    $keep_running = !!$val;
	} elsif ($option eq 'LogFile' && length($val)) {
	    my $logThing;
	    if (lc $val eq 'stdout') {
	        $logThing = \*STDOUT;
	    } elsif (lc $val eq 'stderr') {
	        $logThing = \*STDERR;
	    } else {
	        $logThing = $val;
	    }
	    if ($logThing) {
	        eval {
		    DB::DbgrCommon::enableLogger($logThing);
		    $ldebug = 1;
		    $DB::DbgrProperties::ldebug = 1;
		    $DB::DbgrCommon::ldebug = 1;
		};
		if ($@) {
		    # Disable this.
		    print STDERR "Info: enableLogger => $@\n";
		}
	    }
	} elsif (lc $option eq 'alarm' || lc $option eq 'async') {
	    # Both options mean the same
	    $val = eval($val) if $val =~ /^\d+$/;
	    $skip_alarm = 0 if $val;
        } elsif ($option eq 'RecursionCheckDepth' && $val =~ /^\d+$/) {
	    $deep = $val;
	}
    } ## end while (length)
} ## end sub parse_options

sub answerLastContinuationCommand {
    return unless defined $lastContinuationCommand;
    my ($status) = @_;
    printWithLength(sprintf(qq(%s\n<response %s command="%s" status="%s"
			       reason="ok" transaction_id="%s" %s>),
			    xmlHeader(),
			    namespaceAttr(),
			    $lastContinuationCommand || 'run',
			    $lastContinuationStatus = $status,
			    $lastTranID || '0',
			    fileAndLineIfXdebug()));
}

END {
    # avoid breakpoints if we call code outside DB
    $single = 0;
    # Do not stop in at_exit() and destructors on exit:
    $finished = 1;
    $stopReason = STOP_REASON_STOPPING;
    if ($fall_off_end) {
	dblog("END block: single <= 0\n") if $ldebug;
	$single = 0;
    } else {
	dblog("END block: single <= 1\n") if $ldebug;
	if ($OUT) {
	    # Send a status of stopping

	    # Invariant:
	    # $lastContinuationCommand and $lastTranID must be set

	    answerLastContinuationCommand('stopping');
	}
	# do this after printing the response (since it might indirectly
	# call code outside the DB package)
	$single = 1;
        DB::fake::at_exit();
    }
} ## end END

sub end_report {
    my ($cmd, $transactionID) = @_;
    printWithLength(sprintf
		    (qq(%s\n<response %s command="%s" 
			transaction_id="%s" ><error code="6" apperr="4">
			<message>Command '%s' not valid at end of run.</message>
			</error></response>),
		     xmlHeader(),
		     namespaceAttr(),
		     $cmd,
		     $transactionID,
		     $cmd,
		     ));
}

my (%ORIG_DB_SUB, %DISABLED_DB_SUB, $ORIG_DB_LSUB);

BEGIN {
    %ORIG_DB_SUB = %DISABLED_DB_SUB = map {
        ($_ => *DB::sub{$_}) x !!*DB::sub{$_}
    } qw(CODE SCALAR ARRAY HASH);
    $ORIG_DB_SUB{CODE} = \&DB::sub_pp;
    $ORIG_DB_LSUB = \&DB::lsub_pp;
    *DB::sub = \&DB::sub_pp;
    *DB::lsub = \&DB::lsub_pp;
}

sub enable {
    dblog("(Re-)enabling the debugger via DB::enable()") if $ldebug;
    die "DB::enable() called too early" unless %ORIG_DB_SUB;
    $single = 1;
    $^P = DEBUG_DEFAULT_FLAGS;
    undef *DB::sub;
    *DB::sub = $ORIG_DB_SUB{$_} for keys %ORIG_DB_SUB;
    *DB::lsub = $ORIG_DB_LSUB;
}

sub disable {
    dblog("Disabling the debugger via DB::disable()") if $ldebug;
    die "DB::disable() called too early" unless %ORIG_DB_SUB;
    $single = 0;
    $^P = DEBUG_PREPARE_FLAGS;
    undef *DB::sub;
    undef *DB::lsub;
    *DB::sub = $DISABLED_DB_SUB{$_} for keys %DISABLED_DB_SUB;
}

sub restore_db_sub {
    undef *DB::sub;
    *DB::sub = $ORIG_DB_SUB{$_} for keys %ORIG_DB_SUB;
    *DB::lsub = $ORIG_DB_LSUB;
}

sub clobber_db_sub {
    undef *DB::sub;
    undef *DB::lsub;
    *DB::sub = $DISABLED_DB_SUB{$_} for keys %DISABLED_DB_SUB;
}

# called from XS
sub setup_lexicals {
    DB::XS::setup_lexicals(\$ldebug, \@stack, \$deep, \%FQFnNameLookupTable);
}

sub use_xs_sub {
    $ORIG_DB_SUB{CODE} = \&DB::XS::sub_xs;
    $ORIG_DB_LSUB = \&DB::XS::lsub_xs if $] >= 5.016;
    *DB::sub = \&DB::XS::sub_xs if defined &DB::sub;
    *DB::lsub = \&DB::XS::lsub_xs if defined &DB::lsub && $] >= 5.016;
}

BEGIN {
    $^W = $ini_warn;
}

=head1 C<DB::fake>

Contains the C<at_exit> routine that the debugger uses to issue the
C<Debugged program terminated ...> message after the program completes. See
the C<END> block documentation for more details.

=cut

package DB::fake;

sub at_exit {
    $DB::single = 1;
    "Debugged program terminated.";
}

package DB;    # Do not trace this 1; below!

1;
