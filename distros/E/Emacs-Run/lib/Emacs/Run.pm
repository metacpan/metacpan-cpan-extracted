package Emacs::Run;
use base qw( Class::Base );

=head1 NAME

Emacs::Run - use emacs from perl via the shell

=head1 SYNOPSIS

   use Emacs::Run;
   my $er = Emacs::Run->new();
   my $major_version = $er->emacs_major_version;
   if ($major_version > 22) {
      print "You have a recent version of emacs\n";
   }

   # use extra emacs lisp libraries, then get emacs settings
   my $er = Emacs::Run->new({
                 emacs_libs => [ '~/lib/my-elisp.el',
                                 '/usr/lib/site-emacs/stuff.el' ],
                 });
   my $emacs_load_path_aref = $er->get_load_path;
   my $email = $er->get_variable(  'user-mail-address' );
   my $name  = $er->eval_function( 'user-full-name'    );

   # suppress the use of the usual emacs init (e.g. ~/.emacs)
   my $er = Emacs::Run->new({
                       load_emacs_init => 0,
                    });
   my $result = $er->eval_elisp( '(print (+ 2 2))' );  # that's "4"


   # the eval_elisp_full_emacs method works with a full externally
   # spawned emacs (for unusual code that won't run under '--batch')
   my $elisp_initialize =
     qq{
         (defvar my-temp-var "$text")
         (insert "The initialize elisp has no effect on output: you won't see this.")
      };
   my $elisp =
     qq{
         (insert my-temp-var)
         (downcase-region (point-min) (point-max))
         (my-test-lib-do-something)
        };

   my @emacs_libs = ( $dot_emacs, 'my-test-lib' );

   my $er = Emacs::Run->new({
                             load_no_inits => 1,
                             emacs_libs    => \@emacs_libs,
                            });

   my $output_lines_aref =
     $er->eval_elisp_full_emacs( {
          elisp_initialize => $elisp_initialize,
          output_file      => $name_list_file,    # omit to use temp file
          elisp            => $elisp,

=head1 DESCRIPTION

Emacs::Run is a module that provides portable utilities to run
emacs from perl as an external process.

This module provides methods to allow perl code to:

=over

=item *

Probe the system's emacs installation to get the installed
version, the user's current load-path, and so on.

=item *

Run chunks of emacs lisp code without worrying too much about the
details of quoting issues and loading libraries and so on.

=back

Most of the routines here make use of the emacs "--batch" feature
that runs emacs in a non-interactive mode.  A few, such as
L</eval_elisp_full_emacs> work by opening a full emacs window,
and then killing it when it's no longer needed.

=head2 MOTIVATION

Periodically, I find myself interested in the strange world of
running emacs code from perl.  There's a mildly obscure feature of
emacs command line invocations called "--batch" that essentially
transforms emacs into a lisp interpreter.  Additonal command-line
options allow one to load files of elisp code and run pieces of code
from the command-line.

I've found several uses for this tricks. You can use it to:

=over

=item *

Write perl tools to do automated installation of elisp packages.

=item *

To test elisp code using a perl test harness.

=item *

To use code written in elisp that you don't want to rewrite in perl.

=back

This emacs command line invocation is a little language all of it's
own, with just enough twists and turns to it that I've felt the need
to write perl routines to help drive the process.

At present, using Emacs::Run has one large portability advantage
over writing your own emacs invocation code: there are some
versions of GNU emacs 21 that require the "--no-splash" option,
but using this option would cause an error with earlier versions.
Emacs::Run handles the necessary probing for you, and generates
the right invocation string for the system's installed emacs.

There are also some other, smaller advantages (e.g. automatic
adjustment of the load-path to include the location of a package
loaded as a file), and there may be more in the future.

A raw "emacs --batch" run would suppress most of the usual init
files (but does load the essentially deprecated "site-start.pl").
Emacs::Run has the opposite bias: here we try to load all three
kinds of init files, though each one of these can be shut-off
individually if so desired.  This is because one of the main
intended uses is to let perl find out about things such as the
user's emacs settings (notably, the B<load-path>).  And depending
on your application, the performance hit of loading these files
may not seem like such a big deal these days.

=head2 METHODS

=over

=cut

use 5.8.0;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Hash::Util      qw( lock_keys unlock_keys );
use File::Basename  qw( fileparse basename dirname );
use File::Spec;
use Cwd qw( cwd abs_path );
use List::Util      qw( first );
use Env             qw( $HOME );
use List::MoreUtils qw( any );
use File::Temp      qw{ tempfile };

our $VERSION = '0.15';
my $DEBUG = 0;

# needed for accessor generation
our $AUTOLOAD;
my %ATTRIBUTES = ();

=item new

Creates a new Emacs::Run object.

Takes a hashref as an argument, with named fields identical
to the names of the object attributes. These attributes are:

=over

=item emacs_path

Indicates how to find the emacs program.  Defaults to 'emacs', which
lets the system (e.g. the shell's PATH environment variable) find the
program if it can. If you have multiple emacsen installed in different
places and/or under different names, you can choose which one will be
used by setting this attribute.

=item redirector

A code that specifies how the default way of handling the
standard output and error streams for some methods, such as
L</eval_elisp>, L</run_elisp_on_file> and L</eval_function>.

This may be one of three values:

=over

=item stdout_only

=item stderr_only

=item all_output  (object default -- some methods may differ)

=back

Alternately, one may enter Bourne shell redirection codes using
the L</shell_output_director>.

=item shell_output_director

A Bourne shell redirection code (e.g. '2>&1'). This is an
alternative to setting L</redirector>.

=item before_hook

A string inserted into the built-up emacs commands immediately
after "--batch", but before any thing else is executed.
This is a good place to insert additional invocation options
such as "--multibyte" or "--unibyte".  See </append_to_before_hook>.

=item load_emacs_init

Defaults to 1, if set to a false value, will suppress the use
of the user's emacs init file (e.g. "~/.emacs").

=item load_site_init

Defaults to 1, if set to a false value, will suppress the use
of the system "site-start.el" file (which loads before the
user's init file).

=item load_default_init

Defaults to 1, if set to a false value, will suppress the use
of the system "default.el" file (which loads after the user's
init file).

=item load_no_inits

A convenience flag, which may be set to disable all three types of emacs init
files in one step.  Overrides the other three.

=item emacs_libs

A list of emacs libraries (with or without paths) to be loaded
automatically.  This is recommended for most uses, though
to take full control over how your emacs libraries are handled,
see L</lib_data>.

=item default_priority

The global default for how all the emacs libraries should be loaded.
Normally this is set to "requested", but it can be set to "needed".

A 'requested' library will be silently skipped if it is not available
(and any elisp code using it may need to to adapt to it's absense,
e.g. by doing 'featurep' checks).

A 'needed' file will cause an error to occur if it is not available.

Note: this error does not occur during object instantiation, but
only after a method is called that needs to load the libraries
(e.g. L</eval_function> L</get_variable>, L</eval_elisp>,
L</run_elisp_on_file>, etc).

=item lib_data

Note: using L</emacs_libs> is usually preferrable to L</lib_data>.

B<lib_data> is the internal representation that </emacs_libs> is
converted into, but the client programmer is provided access to it to
cover any unusual needs.

The structure of B<lib_data> is an array of arrays of two elements each,
the first element is the library name (a string, with or without path),
the second element is a hash of library attributes: 'priority' (which can
be 'requested' or 'needed') and 'type' (which can be 'file' or 'lib').

Example:

  $lib_data = [
    [ 'dired',                 { type=>'lib',  priority=>'needed'    } ],
    [ '/tmp/my-load-path.el',  { type=>'file', priority=>'requested' } ],
    [ '/tmp/my-elisp.el',      { type=>'file', priority=>'needed'    } ],
  ];

emacs library attributes:

=over

=item priority

A 'requested' library will be silently skipped if it is not available,
but if a 'needed' file is not available it's regarded as an error condition.
The default priority is 'requested', but that can be changed via the
L</default_priority> attribute.  See L</default_priority> for more
details.

=item type

A library of type 'file' should be a filesystem path to a file
containing a library of emacs lisp code.  A library of type 'lib' is
specified by just the basename of the file (sans path or extension), and
we will search for it looking in the places specified in the emacs
variable load-path.  When neither is specified, this module guesses the
lib is a file if it looks that way (i.e it has a path and/or extension).

=back

If both B<lib_data> and B<emacs_libs> are used, the B<lib_data> libraries
are loaded first, followed by the B<emacs_libs> libraries.

These attributes are used to pass information to the client programmer,
they should be regarded as read-only:

=over

=item emacs_version

The version number of emacs in use: this is set automatically by the
"probe_emacs_version" method during object initialization.

=item emacs_type

The flavor of emacs in use, e.g. 'Gnu Emacs'.  Set automatically by
the "probe_emacs_version" method during object initialization.

=back

There are also a number of object attributes intended largely for
internal use.  The client programmer has access to these, but
is not expected to need it.  These are documented in L</internal attributes>.

=back

=cut

# Note: "new" is inherited from Class::Base and
# calls the following "init" routine automatically.

=item init

Method that initializes object attributes and then locks them
down to prevent accidental creation of new ones.

Any class that inherits from this one should have an L</init> of
it's own that calls this L</init>.

=cut

sub init {
  my $self = shift;
  my $args = shift;
  unlock_keys( %{ $self } );

  if ($DEBUG) {
    $self->debugging(1);
  }

  # object attributes here, including arguments that become attributes
  my @attributes = qw(
                       emacs_path
                       emacs_version
                       emacs_major_version
                       emacs_type

                       load_emacs_init
                       load_site_init
                       load_default_init
                       load_no_inits

                       emacs_libs
                       lib_data
                       lib_data_initial
                       default_priority

                       before_hook
                       ec_lib_loader
                       shell_output_director

                       redirector

                       message_log
                      );

  foreach my $field (@attributes) {
    $ATTRIBUTES{ $field } = 1;
    $self->{ $field } = $args->{ $field };
  }

  if( $self->{ redirector } && $self->{ shell_output_director } ) {
    carp "redirector takes precedence: shell_output_director setting ignored.";
  }
  if( $self->{ redirector } ) {
    $self->{ shell_output_director } = $self->redirector_to_sod( $self->redirector );
  } elsif ( $self->{ shell_output_director } ) {
    $self->{ redirector } = ''; # shouldn't matter now, in any case
  } else {
    # by default, we intermix STDOUT and STDERR
    $self->{ shell_output_director } = '2>&1';
    $self->{ redirector }            = 'all_output'; # redundant? what the hell.
  }

  # Define attributes (apply defaults, etc)
  $self->{ec_lib_loader} = '';

  # If we weren't given a path, let the $PATH sort it out
  $self->{ emacs_path } ||= 'emacs';

  # Determine the emacs version (if we haven't been told already - but why override TODO?)
  $self->{ emacs_version } ||= $self->probe_emacs_version;
  unless( $self->{ emacs_version } ) {  # if emacs is not found, just bail
    return;
  }

  # By default, we like to load all init files
  $self->{load_emacs_init}   = 1 unless defined( $self->{load_emacs_init}   );
  $self->{load_site_init}    = 1 unless defined( $self->{load_site_init}    );
  $self->{load_default_init} = 1 unless defined( $self->{load_default_init} );

  if( $self->{load_no_inits} ) { # ... but we make it easy to suppress all of them, too.
    $self->{load_emacs_init}   = 0;
    $self->{load_site_init}    = 0;
    $self->{load_default_init} = 0;
  }

  $self->{ before_hook } ||= '';
  if($self->{load_no_inits} ) {
    $self->append_to_before_hook( ' -Q ' );
  }

  $self->{ default_priority } ||= 'requested';

  # preserving any given lib_data in the event of a need to reset.
  $self->{lib_data_initial} = $self->{ lib_data };

  if( defined( my $emacs_libs = $self->{ emacs_libs } ) ) {
    $self->process_emacs_libs_addition( $emacs_libs );
  } else {
    # called indirectly by process_emacs_libs_addition.
    # no point in doing it again, *unless* no emacs_libs
    $self->set_up_ec_lib_loader;
  }

  lock_keys( %{ $self } );
  return $self;
}


=back

=head2 Simple Emacs Invocations

Some simple methods for obtaining information from your emacs
installation.

These methods default to returning STDOUT, suppressing anything
sent to STDERR.  This behavior can be overridden: see
L</Controlling Output Redirection>.

=over

=item eval_function

Given the name of an emacs function, this runs the function and
returns the value from emacs (when started with the the .emacs
located in $HOME, if one is found).  After the function name, an
optional array reference may be supplied to pass through a list
of simple arguments (limited to strings) to the elisp function.
And further, an optional hash reference may follow that to
specify options to the "eval_function" method.

By default the returned output is STDOUT only but this behavior
can be overridden: See L</Controlling Output Redirection>.

As with L</get_variable>, this uses the emacs 'print' function
internally.

Examples:

  my $name  = $er->eval_function( 'user-full-name' );

  $er->eval_function( 'extract-doctrings-generate-html-for-elisp-file',
                      [ "$input_elisp_file",
                        "$output_file",
                        "The extracted docstrings" ] );

=cut

sub eval_function {
  my $self     = shift;
  my $funcname = shift;
  my $arg2     = shift;
  my $subname = ( caller(0) )[3];

  my $devnull = File::Spec->devnull();

  my ($passthroughs, $opts, $passthru);
  if (ref( $arg2 ) eq 'ARRAY') {
    $passthroughs = $arg2;
    $passthru = join " ", map{ qq{"$_"} } @{ $passthroughs };
    $opts = shift;
  } elsif (ref( $arg2 ) eq 'HASH') {
    $opts     = $arg2;
  }

  my $redirector = $opts->{ redirector } || "stdout_only";
  my $sod =
    $opts->{ shell_output_director }                   ||
    $self->redirector_to_sod( $redirector )            ||
    "2>$devnull";

  my $elisp;
  if( $passthru ) {
    $elisp = qq{ (print ($funcname $passthru)) };
  } else {
    $elisp = qq{ (print ($funcname)) };
  }

  my $return = $self->eval_elisp( $elisp, {
                                           shell_output_director => $sod,
                                          } );
  return $return;
}

=item get_variable

Given the name of an emacs variable, returns the value from
emacs (when started with the the .emacs located in $HOME,
if one is found),

Internally, this uses the emacs 'print' function, which can
handle variables containing complex data types, but the
return value will be a "printed representation" that may
make more sense to emacs than to perl code.  For example,
the "load-path" variable might look like:

  ("/home/grunt/lib" "/usr/lib/emacs/site-lisp" "/home/xtra/lib")

See L</get_load_path> below for a more perl-friendly way of doing this.

Ignores redirector/shell_output_director.

=cut

sub get_variable {
  my $self    = shift;
  my $varname = shift;
  my $opts    = shift;
  my $devnull = File::Spec->devnull();

  my $redirector = 'stdout_only';
  my $sod = $self->redirector_to_sod( $redirector );

  my $subname = ( caller(0) )[3];
  my $elisp = qq{ (print $varname) };
  my $return = $self->eval_elisp( $elisp, {
                                           shell_output_director => $sod,
                                          } );
  return $return;
}

=item get_load_path

Returns the load-path from emacs (by default, using the
user's .emacs, if it can be found) as a reference to a perl array.

Changing the $HOME environment variable before running this method
results in loading the .emacs file located in the new $HOME.

Ignores redirector/shell_output_director.

=cut

sub get_load_path {
  my $self = shift;
  my $opts = shift;
  my $devnull = File::Spec->devnull();

  my $redirector = 'stdout_only';
  my $sod = $self->redirector_to_sod( $redirector );

  my $elisp = q{ (print (mapconcat 'identity load-path "\n")) };

  my $return = $self->eval_elisp( $elisp, {
                                           shell_output_director => $sod,
                                          } );
  my @load_path = split /\n/, $return;
  \@load_path;
}



=item probe_for_option_no_splash

Looks for the emacs command line option "--no-splash", returning true (1)
if it exists, and false (0) otherwise.

Ignores redirector/shell_output_director.

=cut

# earlier versions called this "no_splash_p"
sub probe_for_option_no_splash {
  my $self = shift;
  my $subname = ( caller(0) )[3];

  my $emacs       = $self->emacs_path;
  my $before_hook = $self->before_hook;
  $before_hook .= ' --no-splash ';

  if ( $self->emacs_type eq 'XEmacs' ) {
    return 0; # xemacs has no --no-splash
  }

  my $sod = '2>&1';

  my $cmd = qq{ $emacs --batch $before_hook $sod };
  $self->debug("$subname: cmd: $cmd\n");
  my $retval = qx{ $cmd };
  $retval = $self->clean_return_value( $retval );

  my $last_line = ( split /\n/, $retval )[-1] || '';

  $self->debug( "$subname retval:\n===\n$retval\n===\n" );

  if( $retval =~ m{ Unknown \s+ option \s+ .*? --no-splash }xms ) {
    return 0;
  } else {
    return 1;
  }
}



=back

=head2 Running Elisp

These are general methods that run pieces of emacs lisp code.

The detailed behavior of these methods have a number of things
in common:

By default the method first loads the user's initialization
file ("$HOME/.emacs") if it can be found.  It will also try to
load the libraries listed in the L</emacs_libs> and/or
L</lib_data> attributes.

There are object attribute settings that can be used to suppress
loading any of the various init files.  See L</new> for the full
list.  In particular, if the L</load_emacs_init> attribute has
been turned off, it will not try to load the .emacs file.

Unless specified otherwise, the methods return the
output from the elisp code with STDOUT and STDERR
mixed together, though this behavior can be overridden.
See L</Controlling Output Redirection>.

(The advantage of intermixing STDOUT and STDERR is that the
emacs functions 'message' as well as 'print' both may be used
for interesting output. The disadvantage is that you may have
many inane messages from emacs sent to STDERR such as 'Loading
library so-and-so')

=over

=item eval_elisp

Given a string containing a chunk of elisp code this method runs
it by invoking emacs in batch mode.

Example:

  my $result = $er->eval_elisp( '(print (+ 2 2))' );

=cut

sub eval_elisp {
  my $self     = shift;
  my $elisp    = shift;
  my $opts     = shift;
  my $subname  = ( caller(0) )[3];

  my $redirector = $opts->{ redirector } || $self->redirector;
  my $sod =
      $opts->{ shell_output_director }                    ||
      $self->redirector_to_sod( $opts->{ redirector } )   ||
      $self->shell_output_director                        ||
      $self->redirector_to_sod( $self->redirector );

  $elisp = $self->quote_elisp( $self->progn_wrapper( $elisp ));

  my $emacs = $self->emacs_path;
  my $before_hook = $self->before_hook;

  my $ec_head = qq{ $emacs --batch $before_hook };
  my $ec_tail = qq{ --eval "$elisp" };
  my $ec_lib_loader = $self->set_up_ec_lib_loader;

  my $cmd = "$ec_head $ec_lib_loader $ec_tail $sod";
  $self->debug("$subname: cmd:\n $cmd\n");

  my $retval = qx{ $cmd };
  $retval = $self->clean_return_value( $retval );
  $self->debug( "$subname retval:\n===\n$retval\n===\n" );

  return $retval;
}

=item run_elisp_on_file

Given a file name, and some emacs lisp code (which presumably
modifies the current buffer), this method opens the file, runs
the code on it, and then saves the file.

Returns whatever value the elisp returns.

Example usage:
  $self->run_elisp_on_file( $filename, $elisp );

=cut

sub run_elisp_on_file {
  my $self     = shift;
  my $filename = shift;
  my $elisp    = shift;
  my $opts     = shift;
   my $subname  = ( caller(0) )[3];

  my $redirector = $opts->{ redirector } || $self->redirector;

  my $sod =
      ( $opts->{ shell_output_director }                   ) ||
      ( $self->redirector_to_sod( $opts->{ redirector } )  ) ||
      ( $self->shell_output_director                       ) ||
      ( $self->redirector_to_sod( $self->redirector )      );

  $elisp = $self->quote_elisp( $elisp );

  my $emacs       = $self->emacs_path;
  my $before_hook = $self->before_hook;

  # Covering a stupidity with some versions of gnu emacs 21: "--no-splash"
  # to suppress an inane splash screen.
  if ( $self->emacs_major_version eq '21' &&
       $self->emacs_type eq 'GNU Emacs' &&
       $self->probe_for_option_no_splash ) {
    $before_hook .= ' --no-splash ';
  }

  my $ec_head = qq{ $emacs --batch $before_hook --file='$filename' };
  my $ec_tail = qq{ --eval "$elisp" -f save-buffer };
  my $ec_lib_loader = $self->ec_lib_loader;

  my $cmd = "$ec_head $ec_lib_loader $ec_tail $sod";
  $self->debug("$subname: cmd: $cmd\n");

  my $retval = qx{ $cmd };
  $retval = $self->clean_return_value( $retval );
  $self->debug( "$subname retval:\n===\n$retval\n===\n" );

  return $retval;
}

=item eval_elisp_full_emacs

Runs the given chunk(s) of elisp using a temporarily launched
full scale emacs window (does not work via "--batch" mode).

Returns an array reference of lines of output.

Of necessity, this emacs sub-process must communicate through a
file (similar to "run_elisp_on_file"), so the elisp run by this
routine should be designed to output to the current buffer
(e.g. via "insert" calls).

Any elisp functions such as "message" and "print" will have no
direct effect on output, and neither the <L/redirector> or
<L/shell_output_director> have any effect here.

As an option, a separate chunk of initialization elisp may also be
passed in: it will be run before the output file buffer is
opened, and hence any modification it makes to the current buffer
will be ignored.

If the "output_filename" is not supplied, a temporary file will
be created and deleted afterwards.  If the name is supplied, the
output file will be still exist afterwards (but note: any existing
contents will be over-written).

The current buffer is saved at the end of the processing (so
there's no need to include a "save-buffer" call in the elisp).

All arguments are passed into this method via a hashref of
options.  These are:

  elisp_initialize
  output_file
  elisp

Note that this last "option" is not optional: you need to supply
some "elisp" if you want anything to happen.

Example use:

  my $er = Emacs::Run->new({
                load_no_inits = 1,
                emacs_libs => [ '~/lib/my-elisp.el',
                                '/usr/lib/site-emacs/stuff.el' ],
                });

  # Using just the 'elisp' argument:
  my $elisp =
    qq{ (insert-file "$input_file")
       (downcase-region (point-min) (point-max))
     };

  my $output =
    $er->eval_elisp_full_emacs( {
         elisp => $elisp,
     }
   );

  # Using all options:
  my $output =
    $er->eval_elisp_full_emacs( {
         elisp_initialize => $elisp_initialize,
         output_file      => $output_file,
         elisp            => $elisp,
         message_log      => '/tmp/message.log',
     }
   );

This method only uses some of the usual Emacs::Run framework:

The three individual init settings flags have no effect on this
method ("load_emacs_init", "load_site_init", "load_default_init").
If "load_no_inits" is set, the emacs init files will be ignored
(via "-q") unless, of course, they're passed in manually in the
"emacs_libs" array reference.

Adding libraries to emacs_libs will not automatically add their
locations to the load-path (because the "ec_lib_loader" system is
not in use here).

Ignores redirector/shell_output_director.

If the option "message_log" contains the name of a log file
the emacs '*Messages*' buffer will be appended to it.

=cut

sub eval_elisp_full_emacs {
  my $self     = shift;
  my $opts     = shift;
  my $subname  = ( caller(0) )[3];

  # unpack options
#  my $elisp            = $opts->{ elisp };
  my $elisp_initialize = $self->progn_wrapper( $opts->{ elisp_initialize } );
  my $elisp            = $self->progn_wrapper( $opts->{ elisp } );
  my $output_file      = $opts->{ output_file };

  my $message_log      = $opts->{ message_log } || $self->message_log;

  # if $output_file is blank, need to pick a temp file to use.
  unless( $output_file ) {
    my $fh;
    my $unlink = not( $DEBUG );
    ($fh, $output_file) =
      tempfile( "emacs_run_eval_elisp_full_emacs-$$-XXXX",
                SUFFIX => '.txt',
                UNLINK => $unlink );
    close ($fh); # after it's written by the subprocess, we will read this file
  }

  # Have to do this to ensure that exit condition works
  unlink( $output_file ) if -e $output_file;

  my $emacs       = $self->emacs_path;
  my $before_hook = $self->before_hook;

  # need "--no-splash" for some versions of emacs
  if ( $self->emacs_major_version eq '21' &&
       $self->emacs_type eq 'GNU Emacs' &&
       $self->probe_for_option_no_splash ) {
    $before_hook .= ' --no-splash ';
  }

  my $elisp_log_messages = $self->progn_wrapper(
    $message_log ?
    qq{
    (find-file "$message_log")
    (insert (format "\n $0 logging *Messages* - %s\n" (current-time-string)))
    (goto-char (point-max))
    (insert-buffer "*Messages*")
    } : ''
   );
  ($DEBUG) && print STDERR "\n$elisp_log_messages\n\n";

  my $output_buffer = basename( $output_file );
  my $elisp_back_to_output =
    qq{
      (switch-to-buffer "$output_buffer")
    };
  ($DEBUG) && print STDERR "\n", $elisp_back_to_output, "\n\n";

  # Build up the command arguments
  my @cmd;
  push @cmd, ( "emacs_from_" . "$$" );  # just the process label, not the binary

  push @cmd, @{ $self->parse_ec_string( $before_hook ) } if $before_hook;

  foreach my $lib ( @{ $self->emacs_libs } ) {
    push @cmd, ( "-l", "$lib" ) if $lib;
  }

  push @cmd, ( "--eval", "$elisp_initialize" ) if $elisp_initialize;
  push @cmd, ( "--file", "$output_file" );
  push @cmd, ( "--eval", "$elisp" );

  if ($message_log) {
    push @cmd, ( "--eval", "$elisp_log_messages" );
    push @cmd, ( "-f", "save-buffer" );
  }

  push @cmd, ( "--eval", "$elisp_back_to_output" );
  push @cmd, ( "-f", "save-buffer" );

  $self->debug("$subname: cmd: " . Dumper( \@cmd ) . "\n");

  if ( my $pid = fork ) {
    # this is parent code
    ($DEBUG) && print STDERR "I'm the parent, the child pid is $pid\n";

    #  kill the child emacs when it's finished
    LOOP: while(1) { # TODO needs to time out (what if *nothing* is written?)
      if ( $self->full_emacs_done ({ output_file => $output_file,
                                     pid => $pid }) ){
        sleep 1; # a little time for things to settle down (paranoia)
        my $status =
          kill 1, $pid;
        ($DEBUG) && print STDERR "Tried to kill (1) pid $pid, status: $status \n";
        last LOOP;
      }
    }
 } else {
    # this is child code
    die "cannot fork: $!" unless defined $pid;

    ($DEBUG) && print STDERR "This is the child, about to exec:\n";
    exec { $emacs } @cmd;
  }

  open my $fh, '<', $output_file or die "$!";
  my @result = map{ chomp($_); s{\r$}{}xms; $_ } <$fh>;
  # Note: stripping CRs is a hack to deal with some windows-oriented .emacs
  return \@result;
}


=item full_emacs_done

Internally used routine.

When it looks as though the child process run by
eval_elisp_full_emacs is finished, this returns true.

At present, this just watches to see when the output_file
has been written.

=cut

### TODO - would be better to watch the process somehow and determine when it's idle.
sub full_emacs_done {
  my $self = shift;
  my $opts = shift;

  my $pid         = $opts->{ pid };
  my $output_file = $opts->{ output_file };

  my $cutoff = 0;      # could increase, if this seems flaky
  if ( (-e $output_file) && ( (-s $output_file) > $cutoff ) ) {
    return 1;
  } else {
    return 0;
  }
}


=back

=head1 INTERNAL METHODS

The following methods are intended primarily for internal use.

Note: the common "leading underscore" naming convention is not used here.

=head2 Utility Methods

=over

=item quote_elisp

Routine to quote elisp code before feeding it into an emacs batch
shell command.  Used internally by methods such as L</eval_elisp>.

This just adds a single backslash to all the double-quote characters
(essentially an empirically determined algorithm, i.e. hack).

Example usage:

  $elisp = $self->quote_elisp( $elisp );
  $emacs_cmd = qq{ emacs --batch --eval "$elisp" 2>&1 };
  my $return = qx{ $emacs_cmd };

=cut

sub quote_elisp {
  my $self = shift;
  my $elisp = shift;

  $elisp =~ s{"}{\\"}xmsg; # add one backwhack to the double-quotes
  return $elisp;
}


=item progn_wrapper

Takes a chunk of elisp, and adds a "progn" around it, to help
make multi-line chunks of elisp Just Work.

=cut

sub progn_wrapper {
  my $self = shift;
  my $elisp = shift;

  $elisp = "(progn $elisp )" if $elisp;
  return $elisp;
}

=item parse_ec_string

Takes a chunk of emacs command-line invocation in string form
and converts it to a list form (suitable for feeding into "system"
or "exec", stepping around the shell).

Returns an aref of tokens (filenames, options, option-arguments).

Limitation:

The '--' option (which indicates that all following tokens are
file names, even if they begin with a hyphen) is not yet handled
correctly here.

=cut

# processing one char at a time
#   different tokens have different syntax - when we know we're
#   doing one type, we'll watch for it's ending

#   quoted strings are treated as an additional token-type
#   filenames are handled as option-arguments

#   remember when you see quotes (toggle state)
#   when you see an unquoted leading [-+], that begins an option
#      [\s=] closes the option
#        = means the following is an option-arg
#        otherwise, it's an option-arg or a file if no leading [-+]

sub parse_ec_string {
  my $self = shift;

  my $ec_string = shift;
  my (@ec, $part);

  # drop leading and trailing whitespace
  chomp($ec_string);
  $ec_string =~ s/^\s//;
  $ec_string =~ s/\s$//;

  # state flags
  my $quoted = 0;
  my $opted  = 1; # begin saving whatever is there at the outset
  my $arged = 0;
  # 1-char of memory
  my $prev   = '';

  my @chars = split '', $ec_string;
  foreach (@chars) {
    if ( /\s/ and $prev =~ /\s/ ) { # turn multiple spaces into one
      next;
    }
    if ( not( $quoted) and /"/ ) {
      $quoted = 1;
    } elsif( ($quoted) and /"/ and $prev ne '\\') { # matches: " but not \"
      $quoted = 0;
      push @ec, $part; $part = '';
    } elsif ($quoted) {
      # fold double backwhacks into one
      if( $_ eq '\\' and $prev eq '\\' ){
        chop( $part );
      }
      # drop escapes from escaped quotes
      if( $_ eq '"' and $prev eq '\\' ) {
        chop( $part );
      }
      $part .= $_;
    } elsif( not( $opted ) and /[-+]/ and $prev ne '\\' ) {
      $arged = 1;
      $part .= $_;
    } elsif ( $opted and /[\s=]/ ) {
      $opted = 0;
      push @ec, $part; $part = '';
    } elsif ($opted) {
      $part .= $_;
    } elsif( not( $arged ) and ( $prev =~ /\s/ or ($prev eq '=') )) { # looks back ar prev char
      $arged = 1;
      $part .= $_;  # must save-up this char (transition char was the previous one)
    } elsif ($arged and /\s/ ) {
      $arged = 0;
      push @ec, $part; $part = '';
    } elsif ($arged) {
      $part .= $_;
    }
    $prev = $_;
  }
  push @ec, $part unless( $part =~ /^\s*$/ );  # skipping blank lines (hack hack)
  return \@ec;
}


=item clean_return_value

Cleans up a given string, trimming unwanted leading and trailing
blanks and double quotes.

This is intended to be used with elisp that uses the 'print'
function.  Note that it is limited to elisp with a single print
of a result: multiple prints will leave embedded quote-newline
pairs in the output.

=cut

sub clean_return_value {
  my $self = shift;
  my $string = shift;
  $string =~ s{^[\s"]+}{}xms;
  $string =~ s{[\s"]+$}{}xms;
  return $string;
}



=item redirector_to_sod

Convert a redirector code into the equivalent shell_output_director
(Bourne shell).

=cut

sub redirector_to_sod {
  my $self       = shift;
  my $redirector = shift;
  my $devnull = File::Spec->devnull;

  unless ( $redirector ) {
    return;
  }

  my $sod;
  if( $redirector eq 'stdout_only' ) {
    $sod = "2>$devnull";
  } elsif ( $redirector eq 'stderr_only' ) {
    $sod = "2>&1 1>$devnull";
  } elsif ( $redirector eq 'all_output' ) {
    $sod = '2>&1';
  }
  return $sod;
}

=back

=head2 Initialization Phase Methods

The following routines are largely used internally in the
object initialization phase.

=over

=item process_emacs_libs_addition

Goes through the given list of emacs_libs, and converts the names into
the lib_data style of data structure, appending it to lib_data.

Note that this method works on the given argument, without
reference to the object's "emacs_libs" field.

Returns a reference to a structure containing the new additions to lib_data.

=cut

# Note: since set_up_ec_lib_loader qualifies the data and fills in
# likely values for type and priority, it need not be done here.
sub process_emacs_libs_addition {
  my $self = shift;
  my $libs = shift;

  my @new_lib_data;
  foreach my $name ( @{ $libs } ) {
    my $rec = [ $name,  { type=>undef, priority=>undef } ];
    push @new_lib_data, $rec;
  }

  my $lib_data = $self->lib_data;
  push @{ $lib_data }, @new_lib_data;
  $self->set_lib_data( $lib_data );  # called for side-effects:
                                     #    set_up_ec_lib_loader
  return \@new_lib_data;
}

=item process_emacs_libs_reset

This converts the list of emacs_libs into the lib_data style of
structure much like L</process_emacs_libs_addition>, but this
method resets the lib_data field to the given value at
init time (if any) before appending the new data.

Defaults to using the object's "emacs_libs" setting.

Returns a reference to a structure containing the additions to lib_data
from emacs_libs.

=cut

sub process_emacs_libs_reset {
  my $self = shift;
  my $libs = shift || $self->emacs_libs;

  $self->reset_lib_data;

  my @new_lib_data;
  foreach my $name ( @{ $libs } ) {
    my $rec = [ $name,  { type=>undef, priority=>undef } ];
    push @new_lib_data, $rec;
  }

  my $lib_data = $self->lib_data;
  push @{ $lib_data }, @new_lib_data;
  $self->set_lib_data( $lib_data );  # called for side-effects:
                                     #   set_up_ec_lib_loader
  return \@new_lib_data;
}

=item set_up_ec_lib_loader

Initializes the ec_lib_loader attribute by scanning for the
appropriate emacs init file(s) and processing the list(s) of emacs
libraries specified in the object data.

Returns the newly defined $ec_lib_loader string.

This routine is called (indirectly) by L</init> during object
initialization.

=cut

sub set_up_ec_lib_loader {
  my $self = shift;

  $self->genec_load_emacs_init;  # zeroes out the ec_lib_loader string first

  my $lib_data = $self->lib_data;

  foreach my $rec (@{ $lib_data }) {

    my $name     = $rec->[0];
    my $type     = $rec->[1]->{type};      # file/lib
    my $priority = $rec->[1]->{priority};  # needed/requested

    # qualify the lib_data
    unless ( $type ) {
      $type = $self->lib_or_file( $name );
      $rec->[1]->{type} = $type;
    }
    unless ( $priority ) {
      $priority = $self->default_priority;
      $rec->[1]->{priority} = $priority;
    }

    my $method = sprintf "genec_loader_%s_%s", $type, $priority;
    $self->$method( $name );   # appends to ec_lib_loader
  }

  my $ec_lib_loader = $self->ec_lib_loader;

  return $ec_lib_loader;
}

=back

=head2 Generation of Emacs Command Strings to Load Libraries

These are routines run by L</set_up_ec_lib_loader> that generate a
string that can be included in an emacs command line invocation to
load certain libraries. Note the naming convention: "generate emacs
command-line" => "genec_".

=over

=item genec_load_emacs_init

Generates an emacs command line fragment to load the
emacs_init file(s) as appropriate.

Side effect: zeroes out the ec_lib_loader before rebuilding with inits only.

=cut

sub genec_load_emacs_init {
  my $self = shift;

  # start from clean slate
  my $ec_lib_loader = $self->set_ec_lib_loader( '' );

  my $load_no_inits     = $self->load_no_inits;
  if ( $load_no_inits ) {
    return $ec_lib_loader; # empty string
  }

  my $load_emacs_init   = $self->load_emacs_init;
  my $load_site_init    = $self->load_site_init;
  my $load_default_init = $self->load_default_init;

  if ( ( $load_site_init ) && ( $self->detect_site_init() ) ) {
    my $ec = qq{ -l "site-start" };
    $self->append_to_ec_lib_loader( $ec );
  }

  if ($load_emacs_init) {
    my $dot_emacs = $self->find_dot_emacs;
    if ( $dot_emacs ) {
      my $ec = qq{ -l "$dot_emacs" };
      $self->append_to_ec_lib_loader( $ec );
    }
  }

  if ( ($load_default_init) && ($self->detect_lib( 'default' )) ) {
    my $ec = qq{ -l "default" };
    $self->append_to_ec_lib_loader( $ec );
  }

  $ec_lib_loader = $self->ec_lib_loader;
  return $ec_lib_loader;
}

=item Genec Methods Called Dynamically

The following is a set of four routines used by
"set_up_ec_lib_loader" to generate a string that can be included
in an emacs command line invocation to load the given library.
The methods here are named according to the pattern:

  "genec_loader_$type_$priority"

where type is 'lib' or 'file' and priority is 'requested' or 'needed'.

All of these methods return the generated string, but also append it
to the L</ec_lib_loader> attribute.

=over

=item genec_loader_lib_needed

=cut

# used by set_up_ec_lib_loader
sub genec_loader_lib_needed {
  my $self = shift;
  my $name = shift;

  unless( defined( $name) ) {
    return;
  }

  my $ec = qq{ -l "$name" };
  # TODO what happens with names that contain double-quotes?

  $self->append_to_ec_lib_loader( $ec );
  return $ec;
}

=item genec_loader_file_needed

=cut

# used by set_up_ec_lib_loader
sub genec_loader_file_needed {
  my $self = shift;
  my $name = shift;

  unless ( -e $name ) {
    croak "Could not find required elisp library file: $name.";
  }
  my $elisp =
    $self->quote_elisp(
                       $self->elisp_to_load_file( $name )
                      );
  my $ec = qq{ --eval "$elisp" };
  $self->append_to_ec_lib_loader( $ec );
  return $ec;
}

=item genec_loader_lib_requested

=cut

# used by set_up_ec_lib_loader
sub genec_loader_lib_requested {
  my $self = shift;
  my $name = shift;

  unless ( $self->detect_lib( $name ) ) {
    return;
  }

  my $ec = qq{ -l "$name" };
  $self->append_to_ec_lib_loader( $ec );
  return $ec;
}

=item genec_loader_file_requested

=cut

# used by set_up_ec_lib_loader
sub genec_loader_file_requested {
  my $self = shift;
  my $name = shift;

  unless( -e $name ) {
    return;
  }

  my $elisp =
    $self->quote_elisp(
                       $self->elisp_to_load_file( $name )
                      );

  my $ec = qq{ --eval "$elisp" };
  $self->append_to_ec_lib_loader( $ec );
  return $ec;
}

=back

=back

=head2 Emacs probes

Methods that return information about the emacs installation.

=over

=item probe_emacs_version

Returns the version of the emacs program stored on your system.
This is called during the object initialization phase.

It checks the emacs specified in the object's emacs_path
(which defaults to the simple command "emacs", sans any path),
and returns the version.

As a side-effect, it sets a number of object attributes with
details about the emacs version:

  emacs_version
  emacs_major_version
  emacs_type

Ignores redirector/shell_output_director.

=cut

sub probe_emacs_version {
  my $self = shift;
  my $opts = shift;
  my $subname = ( caller(0) )[3];
  my $devnull = File::Spec->devnull();

  my $redirector = 'stdout_only';
  my $sod = $self->redirector_to_sod( $redirector );

  my $emacs = $self->emacs_path;
  my $cmd = "$emacs --version $sod";
  my $retval = qx{ $cmd };
  # $self->debug( "$subname:\n $retval\n" );

  my $version = $self->parse_emacs_version_string( $retval );
  return $version;
}


=item parse_emacs_version_string

The emacs version string returned from running "emacs --version"
is parsed by this routine, which picks out the version
numbers and so on and saves them as object data.

See probe_emacs_version (which uses this internally).

=cut

# Note, a Gnu emacs version string has a first line like so:
#   "GNU Emacs 22.1.1",
# followed by several other lines.
#
# For xemacs, the last line is important, though it's preceeded by
# various messages about for libraries loaded.

# Typical version lines.
#   GNU Emacs 22.1.1
#   GNU Emacs 22.1.92.1
#   GNU Emacs 23.0.0.1
#   GNU Emacs 21.4.1
#   XEmacs 21.4 (patch 18) "Social Property" [Lucid] (amd64-debian-linux, Mule) of Wed Dec 21 2005 on yellow

sub parse_emacs_version_string {
  my $self           = shift;
  my $version_mess   = shift;
  unless( $version_mess ) {
    return;
  }

  my ($emacs_type, $version);
  # TODO assuming versions are digits only (\d). Ever have letters, e.g. 'b'?
  if (      $version_mess =~ m{^ ( GNU \s+ Emacs ) \s+ ( [\d.]* ) }xms ) {
    $emacs_type = $1;
    $version    = $2;
  } elsif ( $version_mess =~ m{ ^( XEmacs )        \s+ ( [\d.]* ) }xms ) {
    $emacs_type = $1;
    $version    = $2;
  } else {
    $emacs_type ="not so gnu, not xemacs either";
    $version    = ''; # silence uninitialized value warnings
  }
  $self->debug( "version: $version\n" );

  $self->set_emacs_type( $emacs_type );
  $self->set_emacs_version( $version );

  my (@v) = split /\./, $version;

  my $major_version;
  if( defined( $v[0] ) ) {
    $major_version = $v[0];
  } else {
    $major_version = ''; # silence unitialized value warnings
  }
  $self->set_emacs_major_version( $major_version );
  $self->debug( "major_version: $major_version\n" );

  return $version;
}

=back

=head2 Utilities Used by Initialization

=over

=item elisp_to_load_file

Given the location of an emacs lisp file, generate the elisp
that ensures the library will be available and loaded.

=cut

sub elisp_to_load_file {
  my $self       = shift;
  my $elisp_file = shift;

  my $path = dirname( $elisp_file );

  my $elisp = qq{
   (progn
    (add-to-list 'load-path
      (expand-file-name "$path/"))
    (load-file "$elisp_file"))
  };
}

=item find_dot_emacs

Looks for one of the variants of the user's emacs init file
(e.g. "~/.emacs") in the same order that emacs would, and
returns the first one found.

Note: this relies on the environment variable $HOME.  (This
can be changed first to cause this to look for an emacs init
in some arbitrary location, e.g. for testing purposes.)

This code does not issue a warning if the elc is stale compared to
the el, that's left up to emacs.

=cut

sub find_dot_emacs {
  my $self = shift;
  my @dot_emacs_candidates = (
                   "$HOME/.emacs",
                   "$HOME/.emacs.elc",
                   "$HOME/.emacs.el",
                   "$HOME/.emacs.d/init.elc",
                   "$HOME/.emacs.d/init.el",
                  );

  my $dot_emacs =  first { -e $_ } @dot_emacs_candidates;
  return $dot_emacs;
}

=item detect_site_init

Looks for the "site-start.el" file in the raw load-path
without loading the regular emacs init file (e.g. ~/.emacs).

Emacs itself normally loads this file before it loads
anything else, so this method replicates that behavior.

Returns the library name ('site-start') if found, undef if not.

Ignores redirector/shell_output_director.

=cut

# runs an emacs batch process as a probe, and if the command
# runs "successfully", it checks the return value, and parses
# it to see if the library was in fact found.

# Note that this routine can not easily be written to use
# detect_lib below, because of the different handling of .emacs

sub detect_site_init {
  my $self = shift;
  my $opts = shift;
  my $subname = ( caller(0) )[3];

  my $redirector = 'all_output';
  my $sod = $self->redirector_to_sod( $redirector );

  my $emacs       = $self->emacs_path;
  my $before_hook = $self->before_hook;
  my $lib_name    = 'site-start';

  my $cmd = qq{ $emacs --batch $before_hook -l $lib_name $sod };
  $self->debug("$subname cmd:\n $cmd\n");

  my $retval = qx{ $cmd };
  $self->debug("$subname retval:\n $retval\n");

  if ( defined( $retval ) &&
       $retval =~
         m{\bCannot \s+ open \s+ load \s+ file: \s+ $lib_name \b}xms ) {
    return;
  } else {
    return $lib_name;
  }
}

=item detect_lib

Looks for the given elisp library in the load-path after
trying to load the given list of context_libs (that includes .emacs
as appropriate, and this method uses the requested_load_files as
context, as well).

Returns $lib if found, undef if not.

Example usage:

   if ( $self->detect_lib("dired") ) {
       print "As expected, dired.el is installed.";
   }

   my @good_libs = grep { defined($_) } map{ $self->detect_lib($_) } @candidate_libs;

Ignores redirector/shell_output_director.

=cut

sub detect_lib {
  my $self         = shift;
  my $lib          = shift;
  my $opts         = shift;
  my $subname = (caller(0))[3];

  return unless $lib;

  my $redirector = 'all_output';
  my $sod = $self->redirector_to_sod( $redirector );

  my $emacs       = $self->emacs_path;
  my $before_hook = $self->before_hook;
  my $ec_head = qq{ $emacs --batch $before_hook };
  # cmd string to load existing, presumably vetted, libs
  my $ec_lib_loader = $self->ec_lib_loader;

  my $cmd = qq{ $ec_head $ec_lib_loader -l $lib $sod};
  my $retval = qx{ $cmd };

  if ( defined( $retval ) &&
       $retval =~ m{\bCannot \s+ open \s+ load \s+ file: \s+ $lib \b}xms ) {
    return;
  } else {
    return $lib;
  }
}


=item lib_or_file

Given the name of an emacs library, examine it to see if it
looks like a file system path, or an emacs library (technically
a "feature name", i.e. sans path or extension).

Returns a string, either "file" or "lib".

=cut

sub lib_or_file {
  my $self = shift;
  my $name = shift;

  my $path_found;
  my ($volume,$directories,$file) = File::Spec->splitpath( $name );
  if( $directories || $volume ) {
    $path_found = 1;
  }

  my $ext_found =  ( $name =~ m{\.el[c]?$}xms );

  my $type;
  if ($path_found) {
    $type = 'file';
  } elsif ($ext_found) {
    $type = 'file';
  } else {
    $type = 'lib';
  }
  return $type;
}


=back

=head2 Routines in Use by Some External Libraries

These aren't expected to be generally useful methods, but
they are in use by some code (notably L<Emacs::Run::ExtractDocs>).

=over

=item elisp_file_from_library_name_if_in_loadpath

Identifies the file associated with a given elisp library name by
shelling out to emacs in batch mode.

=cut

# used externally by Emacs::Run::ExtractDocs
sub elisp_file_from_library_name_if_in_loadpath {
  my $self    = shift;
  my $library = shift;
  my $subname = (caller(0))[3];

  my $elisp = qq{
     (progn
       (setq codefile (locate-library "$library"))
       (message codefile))
  };

  my $return = $self->eval_elisp( $elisp );

  my $last_line = ( split /\n/, $return )[-1];

  my $file;
  if ( ($last_line) && (-e $last_line) ) {
    $self->debug( "$subname: $last_line is associated with $library\n" );
    $file = $last_line;
  } else {
    $self->debug( "$subname: no file name found for lib: $library\n" );
    $file = undef;
  }

  return $file;
}

=item generate_elisp_to_load_library

Generates elisp code that will instruct emacs to load the given
library.  It also makes sure it's location is in the load-path, which
is not precisely the same thing: See "Loaded vs. in load-path".

Takes one argument, which can either be the name of the library, or
the name of the file, as distinguished by the presence of a ".el"
extension on a file name.  Also, the file name will usually have a
path included, but the library name can not.

=cut

# used externally by Emacs::Run::ExtractDocs
sub generate_elisp_to_load_library {
  my $self = shift;
  my $arg  = shift;

  my ($elisp, $elisp_file);
  if ($arg =~ m{\.el$}){
    $elisp_file = $arg;
    $elisp = $self->elisp_to_load_file( $elisp_file );
  } else {

    $elisp_file = $self->elisp_file_from_library_name_if_in_loadpath( $arg );

    unless( $elisp_file ) {
      croak "Could not determine the file for the named library: $arg";
    }

    $elisp = $self->elisp_to_load_file( $elisp_file );
  }
  return $elisp;
}


=back

=head2 Basic Setters and Getters

The naming convention in use here is that setters begin with
"set_", but getters have *no* prefix: the most commonly used case
deserves the simplest syntax (and mutators are deprecated).

Setters and getters exist for all of the object attributes which are
documented with the L</new> method (but note that these exist even for
"internal" attributes that are not expected to be useful to the client
coder).

=head2 Special Accessors

=over

=item append_to_ec_lib_loader

Non-standard setter that appends the given string to the
the L</elisp_to_load_file> attribute.

=cut

sub append_to_ec_lib_loader {
  my $self = shift;
  my $append_string = shift;

  my $ec_lib_loader = $self->{ ec_lib_loader } || '';
  $ec_lib_loader .= $append_string;

  $self->{ ec_lib_loader } = $ec_lib_loader;

  return $ec_lib_loader;
}


=item append_to_before_hook

Non-standard setter that appends the given string to the
the L</before_hook> attribute.

Under some circumstances, this module uses the L</before_hook> for
internal purposes (for -Q and --no-splash), so using an ordinary
setter might erase something you didn't realize was there.
Typically it's safer to do an append to the L</before_hook> by
using this method.

=cut

sub append_to_before_hook {
  my $self = shift;
  my $append_string = shift;

  my $before_hook = $self->{ before_hook } || '';
  $before_hook .= $append_string;

  $self->{ before_hook } = $before_hook;

  return $before_hook;
}

=back

=head2 accessors that effect the L</ec_lib_loader> attribute

If either lib_data or emacs_libs is modified, this must
trigger another run of L</set_up_ec_lib_loader> to keep
the L</ec_lib_loader> string up-to-date.

=over

=item set_lib_data

Setter for lib_data.

=cut

sub set_lib_data {
  my $self = shift;
  my $lib_data = shift;
  $self->{ lib_data } = $lib_data;
  $self->set_up_ec_lib_loader;
  return $lib_data;
}


=item reset_lib_data

Reverts lib_data to the value supplied during
initization (it empties it entirely, if none was supplied).

Note: this does not (at present) trigger a re-build of L</ec_lib_loader>,
because it's presumed that this will be triggered by some step
following this one.

=cut

sub reset_lib_data {
  my $self = shift;
  @{ $self->{ lib_data } } = @{ $self->{ lib_data_given } };
  return $self->{ lib_data };
}



=item set_emacs_libs

Setter for emacs_libs.

Side effect: runs process_emacs_libs_rest on the given emacs_libs
list.

process_emacs_libs_reset indirectly calls set_up_ec_lib_loader
so we don't need to do so explicitly here.

=cut

sub set_emacs_libs {
  my $self        = shift;
  my $emacs_libs  = shift;
  $self->{ emacs_libs } = $emacs_libs;
  $self->process_emacs_libs_reset( $emacs_libs );
  return $emacs_libs;
}

=item push_emacs_libs

Pushes a new lib to the emacs_libs array.

Takes a string, returns aref of the full list of emacs_libs.

Side-effect: runs process_emacs_libs_addition on the new lib,
(appending the new info to lib_data).

process_emacs_libs_addition indirectly calls set_up_ec_lib_loader
so we don't need to do so explicitly here.

=cut

sub push_emacs_libs {
  my $self = shift;
  my $newlib = shift;

  my $emacs_libs = $self->emacs_libs;
  push @{ $emacs_libs }, $newlib;
  $self->process_emacs_libs_addition( [ $newlib ] );
  return $emacs_libs;
}

=item set_redirector

Setter for object attribute set_redirector.
Automatically sets the shell_output_director field.

=cut

sub set_redirector {
  my $self = shift;
  my $redirector = shift;
  $self->{ redirector } = $redirector;

  $self->{ shell_output_director } = $self->redirector_to_sod( $redirector );

  return $redirector;
}




# automatic generation of the basic setters and getters
sub AUTOLOAD {
  return if $AUTOLOAD =~ /DESTROY$/;  # skip calls to DESTROY ()

  my ($name) = $AUTOLOAD =~ /([^:]+)$/; # extract method name
  (my $field = $name) =~ s/^set_//;

  # check that this is a valid accessor call
  croak("Unknown method '$AUTOLOAD' called")
    unless defined( $ATTRIBUTES{ $field } );

  { no strict 'refs';

    # create the setter and getter and install them in the symbol table

    if ( $name =~ /^set_/ ) {

      *$name = sub {
        my $self = shift;
        $self->{ $field } = shift;
        return $self->{ $field };
      };

      goto &$name;              # jump to the new method.
    } elsif ( $name =~ /^get_/ ) {
      carp("Apparent attempt at using a getter with unneeded 'get_' prefix.");
    }

    *$name = sub {
      my $self = shift;
      return $self->{ $field };
    };

    goto &$name;                # jump to the new method.
  }
}


1;

###  end of code

=back

=head2 Controlling Output Redirection

As described under L</new>, the L</redirector> is a code used to
control what happens to the output streams STDOUT and STDERR (or
in elisp terms, the output from "print" or "message"):
B<stdout_only>, B<stderr_only> or B<all_output>.

The client programmer may not need to worry about the L</redirector> at
all, since some (hopefully) sensible defaults have been chosen for the
major methods here:

  all_output   (using the object default)

     eval_elisp
     run_elisp_on_file

  stdout_only  (special method-level defaults)

     get_load_path
     get_variable
     eval_function

In addition to being able to set L</redirector> at instantiation
(as an option to L</new>), L</redirector> can also often be set
at the method level to temporarily override the object-level setting.

For example, if "eval_elisp" is returning some messages to STDERR
that you'd rather filter out, you could do that in one of two ways:

Changing the object-wide default:

   my $er = Emacs::Run->new( { redirector => 'stdout_only' } );
   my $result = $er->eval_elisp( $elisp_code );

Using an option specific to this method call:

   my $er = Emacs::Run->new();
   my $result = $er->eval_elisp( $elisp_code, { redirector => 'stdout_only' } );

If you need some behavior not supported by these redirector codes,
it is possible to use a Bourne-shell style redirect, like so:

   # return stdout only, but maintain an error log file
   my $er = Emacs::Run->new( { shell_output_director => "2>$logfile" } );
   my $result = $er->eval_elisp( $elisp_code );

As with L</redirector>, the L</shell_output_director> can be set
at the object-level or (often) at the method-level.

=over

=item shell_output_director

The B<shell_output_director> (sometimes called B<sod> for short) is a
string appended to the internally generated emacs invocation commands to
control what happens to output.

Typical values (on a unix-like system) are:

=over

=item  '2>&1'

Intermix STDOUT and STDERR (in elisp: both "message" and "print"
functions work).

=item  '2>/dev/null'

return only STDOUT, throwing away STDERR (in elisp: get output
only from "print"). But see L<File::Spec>'s B<devnull>.

=item  "> $file 2>&1"

send all output to the file $file

=item  ">> $file 2>&1"

append all output to the file $file, preserving any existing
content.

=item  "2 > $log_file"

return only STDOUT, but save STDERR to $log_file

=back

=back

=head1 internal documentation (how the code works, etc).

=head2 internal attributes

Object attributes intended largely for internal use.  The client
programmer has access to these, but is not expected to need it.
Note: the common "leading underscore" naming convention is not used here.

=over

=item  ec_lib_loader

A fragment of an emacs command line invocation to load emacs libraries.
Different attributes exist to specify emacs libraries to be loaded:
as these are processed, the ec_lib_loader string gradually accumulates
code needed to load them (so that when need be, the process can use
the intermediate value of the ec_lib_loader to get the benefit of
the previously processed library specifications).

The primary reason for this approach is that each library loaded
has the potential to modify the emacs load-path, which may be
key for the success of later load attempts.

The process of probing for each library in one of the "requested"
lists has to be done in the context of all libraries that have been
previously found.  Without some place to store intermediate results
in some form, this process might need to be programmed as one large
monolithic routine.

=item lib_data_initial

The initial setting of L</lib_data> when the object is instantiated.
As currently implemented, some operations here require resetting
the state of L</lib_data> and re-building it.  This attribute
facilitates that process.

=back

=head2 Loaded vs. in load-path

The emacs variable "load-path" behaves much like the shell's $PATH
(or perl's @INC): if you try to load a library called "dired", emacs
searches through the load-path in sequence, looking for an appropriately
named file (e.g. "dired.el"), it then evaluates it's contents, and
the features defined in the file become available for use.  It is also possible
to load a file by telling emacs the path and filename, and that works
whether or not it is located in the load-path.

There I<is> at least a slight difference between the two, however.
For example, the present version of the "extract-docstrings.el"
library (see L<Emacs::Run::ExtractDocs>) contains code like this, that
will break if the library you're looking for is not in the load-path:

  (setq codefile (locate-library library))

So some of the routines here (notably L</elisp_to_load_file>)
generate elisp with an extra feature that adds the location of the file
to the load-path as well as just loading it.

=head2 Interactive vs. Non-interactive Elisp Init

Emacs::Run tries to use the user's normal emacs init process even
though it runs non-interactively.  Unfortunately, it's possible that
the init files may need to be cleaned up in order to be used
non-interactively.  In my case I found that I needed to check the
"x-no-window-manager" variable and selectively disable some code that
sets X fonts for me:

  ;; We must do this check to allow "emacs --batch -l .emacs" to work
  (unless (eq x-no-window-manager nil)
    (zoom-set-font "-Misc-Fixed-Bold-R-Normal--15-140-75-75-C-90-ISO8859-1"))

Alternately, L</eval_elisp_full_emacs> may be used to run elisp using a
full, externally spawned emacs, without using the --batch option:
you'll see another emacs window temporarily spring into life, and then
get destroyed, after passing the contents of the current-buffer back
by using a temporary file.

=head2 INTERNALS

=head3 The Tree of Method Calls

The potential tree of method calls now runs fairly deep.  A bug in a
primitive such as L</detect_site_init> can have wide-ranging effects:

   new
     init
        append_to_before_hook
        process_emacs_libs_addition
        set_up_ec_lib_loader
           lib_or_file
           genec_load_emacs_init
              append_to_ec_lib_loader
              detect_site_init
              detect_lib
           genec_loader_lib_needed
              append_to_ec_lib_loader
           genec_loader_file_needed
              quote_elisp
              elisp_to_load_file
              append_to_ec_lib_loader
           genec_loader_lib_requested
              detect_lib
              append_to_ec_lib_loader
           genec_loader_file_requested
              quote_elisp
              elisp_to_load_file
              append_to_ec_lib_loader
        probe_emacs_version
           parse_emacs_version_string


   eval_elisp
     quote_elisp
     clean_return_value
     set_up_ec_lib_loader
        lib_or_file
        genec_load_emacs_init
           append_to_ec_lib_loader
           find_dot_emacs
           detect_site_init
           detect_lib
        genec_loader_lib_needed
           append_to_ec_lib_loader
        genec_loader_file_needed
           quote_elisp
           elisp_to_load_file
           append_to_ec_lib_loader
        genec_loader_lib_requested
           detect_lib
           append_to_ec_lib_loader
        genec_loader_file_requested
           quote_elisp
           elisp_to_load_file
           append_to_ec_lib_loader

Note that as of this writing (version 0.09) this code ensures that
the L</ec_lib_loader> string is up-to-date by continually re-generating
it.

=head1 TODO

=over

=item *

Rather than use elisp's "print", should probably use "prin1" (does what
you mean without need for a clean-up routine).

=item *

Look into cache tricks (just Memoize?) to speed things up a
little.  See L</The Tree of Method Calls>.

=item *

Have "new" fail (return undef) if emacs can not be
found on the system.  This way you can use the result
of "new" to determine if you should skip tests, etc.

=item *

I suspect some quoting issues still lurk e.g.  a library
filename containing a double-quote will probably crash things.

=item *

Add a method to match an emacs regexp against a string. See:
L<http://obsidianrook.com/devnotes/talks/test_everything/bin/1-test_emacs_regexps.t.html>

      (goto-char (point-min))
      (re-search-forward "$elisp_pattern")
      (setq first_capture (match-string 1))

=item *

In L</run_elisp_on_file>, add support for skipping to a line number
after opening a file

=item *

I think this feature of emacs invocation could be used to simplify
things a little (I'm manipulating load-path directly at present):

   `-L DIR'
   `--directory=DIR'
       Add directory DIR to the variable `load-path'.

=item *

loop in eval_elisp_full_emacs needs to time-out (e.g. if no output is written)

=item *

Write an alternate to the eval_elisp_full_emacs that captures an
image of the external emacs process. (Allows automated tests of
syntax coloring, etc.)  Can this be done portably?

=item *

Write more tests of redirectors -- found and fixed (?) bug in stderr_only.

=back

=head1 BUGS & LIMITATIONS

=over

=item *

When an elisp library is marked as "needed", and it is not available,
failure occurs relatively late: it does not happen during object
instantiation, but waits until an attempted run with the object
(that is, on a call such as "$er->eval_elisp", not "Emacs::Run->new").

=item *

This module was developed around Gnu emacs running on a
Gnu/linux platform.  Some attempts have been made to make it's
use portable to other platforms.  At present, using it with a
non-gnu emacs such as xemacs is not likely to work.

=item *

The L</clean_return_value> routine strips leading and trailing
newline-quote pairs, but that only covers the case of individual
elisp print functions.  Evaluating elisp code with multiple
prints will need something fancier to clean up their behavior.

=item *

L</genec_load_emacs_init> runs into trouble if there's a bug in the .emacs
file, because it proceeds when it can find the file via
L</find_dot_emacs>, but doesn't verify it will load cleanly:
it charges ahead and tries to use it while doing a L</detect_lib>,
which gets confused because it looks for a very specific message
to indicate failure, and doesn't understand any error messages from
an earlier stage.  It would probably be better for L</find_dot_emacs>
to also vet the file, and error out if it doesn't succeed.

=back

=head1 SEE ALSO

L<Emacs::Run::ExtractDocs>

Emacs Documentation: Command Line Arguments for Emacs Invocation
L<http://www.gnu.org/software/emacs/manual/html_node/emacs/Emacs-Invocation.html>

A lightning talk about (among other things) using perl to test
emacs code: "Using perl to test non-perl code":

L<http://obsidianrook.com/devnotes/talks/test_everything/index.html>

=head1 OTHER EXAMPLES

Examples of "advanced" features (i.e. ones you're unlikely to want to use):

   # Specify in detail how the emacs lisp libraries should be loaded
   # (initialization does not fail if a library that's merely "requested"
   # is unavailable):
   $lib_data = [
       [ 'dired',                 { type=>'lib',  priority=>'needed'    } ],
       [ '/tmp/my-load-path.el',  { type=>'file', priority=>'requested' } ],
       [ '/tmp/my-elisp.el',      { type=>'file', priority=>'needed'    } ],
     ];
   my $er = Emacs::Run->new({
                       lib_data => $lib_data,
                    });
   my $result = $er->eval_lisp(
                  qq{ (print (my-elisp-run-my-code "$perl_string")) }
                );



   # using a "redirector" code (capture only stderr, ignore stdout, like '1>/dev/null')
   $er = Emacs::Run->new({
                         redirector => 'stderr_only'
                        });
   my $result = $er->eval_elisp( '(message "hello world") (print "you can't see me"))' );



   # View your emacs load_path from the command-line
   perl -MEmacs::Run -le'my $er=Emacs::Run->new; print for @{ $er->get_load_path }';

   # Note that the obvious direct emacs invocation will not show .emacs customizations:
   emacs --batch --eval "(print (mapconcat 'identity load-path \"\n\"))"

   # This does though
   emacs --batch -l ~/.emacs --eval "(prin1 (mapconcat 'identity load-path \"\n\"))" 2>/dev/null


=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>,
07 Mar 2008

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Joseph Brenner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
