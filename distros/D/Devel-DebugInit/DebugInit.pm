package Devel::DebugInit;
use English;
use Carp;
use C::Scan qw(0.4);
require Exporter;

@Devel::DebugInit::ISA = (Exporter);

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $MACROS_ALL $MACROS_LOCAL $MACROS_NONE);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.3';

$Devel::DebugInit::MACROS_NONE  = 0;
$Devel::DebugInit::MACROS_LOCAL = 1;
$Devel::DebugInit::MACROS_ALL   = 2;

=head1 NAME

Devel::DebugInit - Perl extension for creating a debugger
initialization files from C header file macros

=head1 SYNOPSIS

  use Devel::DebugInit::GDB;
  my $gdb = new Devel::DebugInit::GDB 'filenames' => ["/my/path/to/library.h"];
  $gdb->write("/my/path/to/library/.gdbinit");

=head1 DESCRIPTION

Devel::DebugInit is aimed at C/C++ developers who want access to C
macro definitions from within a debugger. It provides a simple and
automated way of creating debugger initialization files for a specific
project. The initialization files created contain user-defined
functions built from the macro definitions in the project's header
files.

By calling new(), the files specified by the 'filenames' parameter are
parsed by the C preprocessor, and all macros #define'd in the file
(and if desired, all macros #define'd by all #include'd files as
well), will be parsed and expanded. By then calling the write()
method, these macros can be written to an output file in the format of
user-defined functions specific for your debugger.

By automating the process, a new file can be created whenever the code
of a project changes, and that way there will not be antiquated copies
lying around to trap the unwary.

=head1 NOTES

This module requires the use of one of the debugger-specific backend
modules, such as Devel::DebugInit::GDB which is supplied with
DebugInit. The backends supply the output routines which are specific
for that debugger. 

This module also requires both the C::Scan and Data::Flow modules and
will not function without them.

=head1 WHY CARE?

Debugger initialization files can contain user-defined functions that
make doing complicated or repetitive actions easier. Normally, from
within the debugger a user can evaluate any C function call. But for a
number of reasons, many projects use C preprocessor macros (#define
statements) in place of an actual C function call. The use of macros
instead of function calls is transparent during compilation, but most
debuggers do not allow access to macros, and so the user must type in
the code by hand each time s/he wants to use a macro, or must build an
initialization file by hand. Retyping is tedious, but hand coding the
initialization file may result in antiquated code when the project changes. By
automating the process, I hope to alleviate a few headaches for
developers.

There are two types of macros: macros with arguments, e.g:

   #define min(x,y) ((x) < (y) ? (x) : (y))

and macros without arguments (simple macros), e.g.

   #define PI 3.14

Of the two types, macros with arguments are more useful from within a
debugger, and so, printing of simple macros is turned off by default
(but see L<INTERNALS> for how to turn them on).

=head1 INTERNALS

For the casual user the defaults, and the three lines given in the
L<SYNOPSIS> should be enough. But for the determined user, a few
details of how things happen under the hood might be useful in
customizing the output of this module.

=head2 How Devel::DebugInit Parses Files

When new() is called to create an instance of a Devel::DebugInit, the
following steps occur. The C preprocessor is invoked on the file with
the 'macros only' flag set (this flag defaults to '-dM' and if this does
not work on your system, change the value of $C::Scan::MACROS_ONLY and
let the author know, and he will try and fix it :-). This lists all
macros #define'd in the file PLUS all macros #define'd in all files
#include'd by that file (both the system files <types.h> and the user
files "mystring.h"). This may include many more macros than is desired
(not everybody really wants '_LINUX_C_LIB_VERSION_MAJOR' as a user
defined function in their debugger...), so there are 3 mode flags
defined that allow the user to control which macros are included:
MACROS_ALL, MACROS_LOCAL, and MACROS_NONE.

=head2 MACROS_ALL, MACROS_LOCAL, and MACROS_NONE

These flags can be used to control what macros go into the print
tables that Devel::DebugInit uses to create the output file. The
MACROS_ALL flag instructs DebugInit to included all macros of that
type in the output table. To avoid printing out all of the system level
macros that can get #include'd you can use the MACROS_LOCAL flag. This
indicates that only macros actually #define'd in that file should be
stored, and macros #define'd in other files which are #include'd into
the file should NOT be stored (they are, however, still made available
for expansion purposes). The MACROS_LOCAL flag is the default for
macros with arguments. Finally, the MACROS_NONE flag indicates that no
macros of that type should be put in the output table. The MACROS_NONE
flag is the default for the simple macros.

=head2 Output Tables and Lookup Tables

Devel::DebugInit has two separate groups of tables that it uses -
lookup tables for expanding macro definitions and output tables for
printing the fully expanded macros. The lookup tables always include
all macros that a given file has access to, but the output tables may
have many fewer. Because the user-defined functions of some debuggers
can be very limited, Devel::DebugInit fully expands all macros stored
in the output tables before writing them to a file. In this way, any
macro which utilized other macros in its body will have those expanded
in place. So by the end of the expansion process, all macros will be
self defined and not rely on any other macro definition. Each macro in
the output tables is expanded in this manner using the definitions in
the lookup tables. Using separate lookup tables and output tables
allows users to print out only those macros they care about while
still be able to fully expand all macros.

=cut

# Preloaded methods go here.

=head1 METHODS

=head2 new()

Returns a blessed reference to an instance of a Devel::DebugInit
subclass. Each Devel::DebugInit subclass takes a list of option value
pairs as optional arguments to new. Currently there are three
recognized options 'filenames', 'macros_args', and
'macros_no_args'. The 'filenames' option controls which file is used
for creating the output. The 'macros_args' option controls the level
of output support for macros with arguments. The 'macro_no_args'
option controls the level of output support for simple macros. For
example, to make a .gdbinit file useful for debugging perl or perl
XSUBs try the following:

   $gdb = new Devel::DebugInit::GDB 
       'filenames' => ["$Config{'archlib'}/CORE/perl.h"], 
       'macros_args'    => $Devel::DebugInit::MACROS_ALL,
       'macros_no_args' => $Devel::DebugInit::MACROS_ALL;

   $gdb->write();

When written, this will create a file that is about 110k in size and
have about 1750 user-defined functions. So it may be useful to limit
it in scope somewhat. It is not clear that simple macros are useful
from within a debugger, so the default value for 'macros_no_args' is
MACROS_NONE, and to avoid printing all system level macros, the
default for 'macros_args' is MACROS_LOCAL. NOTE that by using
MACROS_LOCAL, you will inhibit printing of all macros not #define'd in
the file listed, both from local header files and system headers
alike. To get around this multiple files can be included in the array
ref for the 'filenames' option. Each files macros are added to a
common lookup table, but only the macros #defined in each file are
printed. So could do the following:

   $gdb = new Devel::DebugInit::GDB 
       'filenames' => ["$Config{'archlib'}/CORE/perl.h",
		       "$Config{'archlib'}/CORE/sv.h", 
		       "$Config{'archlib'}/CORE/XSUB.h"], 
       'macros_args'    => $Devel::DebugInit::MACROS_LOCAL,
       'macros_no_args' => $Devel::DebugInit::MACROS_NONE;

   $gdb->write();

This reduces the output file to only 21k and 250 or so macros.

=head2 write()
=head2 write($filename)

This function is overloaded by each of the debugger specific
subclasses to produce output recognized by that debugger. If $filename
is not given, it defaults to something reasonable for that
debugger. All macros in the output table for each macro type (macros
with arguments and simple macros) will be printed if it passes
scrutiny by the L<scan()> method. See the L<INTERNALS> section for
more details on controlling what macros are stored in the print
tables.

=head2 scan()

The only other method of interest to users of this module is the
scan() method which is also overloaded by each backend subclass. This
method is called by write() to ascertain whether or not a given macro
should be written out to the output file. By default, scan() stops
undefined macros, blank macros (e.g. macros such as <#define VMS>
which are usually just conditional compiler flags and of no use in a
debugger), and macros with names that conflict with built-in debugger
commands. Users desiring a very fine grained control over the output
can override the builtin scan() with their own on a per need
basis. For example:

    package myGDB;
    use Devel::DebugInit::GDB;
    @myGDB::ISA = (Devel::DebugInit::GDB);
    
    sub scan {
      my ($gdb,$key,$macro) = @_;
    
      #first give the superclass scan a chance 
      return 0 unless $gdb->SUPER::scan(@_);
    
      # dont' print out any macros with a leading '_'
      return 0 if $macro =~ /^_/;
    
      # print the rest
      return 1;
    }

=cut

sub new {
  my ($class,%args) = @_;

  # set the default values
  my $ARGS = $MACROS_LOCAL;	# print only local macros with args
  my $NOARGS = $MACROS_NONE;	# don't print simple macros

  # check the input arguments to see what support is desired
  # we pass refs so that this call can modify the parameters
  Devel::DebugInit::setup_args(\$NOARGS,\$ARGS,%args);

  # see if an input file was specified
  die "Must specify array of filenames" unless exists $args{'filenames'} && ref $args{'filenames'};

  my $self = [];
  bless $self, $class;

  my ($file,$filename);
  foreach $filename (@{$args{'filenames'}}) {
    $file = new C::DebugFile 'filename' => $filename;
    if (defined $file) {
      push(@{$self}, $file);
    } else {
      die "Bad file name: $filename";
    }
  }

  foreach $file (@{$self}) {
    $file->setup_tables($NOARGS,$ARGS);
  }

  # expand all definitions using the lookup tables GDB's user defined
  # functions are pretty limited and one cannot call another, so they
  # all have to be expanded to the lowest common denominator
  foreach $file (@{$self}) {
    $file->defines_no_args($self);
    $file->defines_args($self);
  }
  return $self
}

sub files {
  my $self = @_;
  my (@files,$file);
  foreach $file (@{$self}) {
    push(@files,$file);
  }
  return (@files);
}

sub print {
  die "Can't call Devel::DebugInit::print(), must use a backend specific subclass";
}

sub setup_args {
  my ($NOARGS,$ARGS,%args) = @_;

  # see if any Debug specific args were given
  if (exists $args{'macros_args'}) {
    my $args = $args{'macros_args'};
    if ($args == $MACROS_NONE || 
	$args == $MACROS_LOCAL ||
	$args == $MACROS_ALL ) {
      $$ARGS = $args;
    } else {
      warn("bad argument %s given to macros_args, should be 0,1,2. Ignoring...", $args);
    }
  }

  if (exists $args{'macros_no_args'}) {
    my $no_args = $args{'macros_no_args'};
    if ($no_args == $MACROS_NONE || 
	$no_args == $MACROS_LOCAL ||
	$no_args == $MACROS_ALL ) {
      $$NOARGS = $no_args;
    } else {
      warn("bad argument %s given to macros_no_args, should be 0,1,2. Ignoring...", $no_args);
    }
  }
}

# the following are private methods. Don't use them as they are
# subject to change without warning. You've been warned ;-)

##################################
#
# C::DebugFile
#
package C::DebugFile;
@C::DebugFile::ISA = qw(C::Scan);

sub new {
  my ($class,%args) = @_;
  return $class->SUPER::new(%args);
}

sub setup_tables {
  my ($self,$NOARGS,$ARGS) = @_;

  # set up the lookup tables
  $self->set_no_args_lookup($self->get('defines_no_args_full'));
  $self->set_args_lookup($self->get('defines_args_full'));
  
  # set up the output tables
  if ($ARGS == $Devel::DebugInit::MACROS_ALL) {
    $self->set_args($self->get('defines_args_full'));
  } elsif ($ARGS == $Devel::DebugInit::MACROS_LOCAL) {
    $self->set_args($self->get('defines_args'));      
  }
  if ($NOARGS == $Devel::DebugInit::MACROS_ALL) {
    $self->set_no_args($self->get('defines_no_args_full'));
  } elsif ($NOARGS == $Devel::DebugInit::MACROS_LOCAL) {
    $self->set_no_args($self->get('defines_no_args'));      
  }
}

sub defines_no_args {
  my ($self,$debug) = @_;
  my $defines = $self->get_no_args();
  return unless defined $defines;

  my ($key,$define);
  foreach $key (keys %{$defines}) {
    $defines->{$key} = $self->strip($defines->{$key});
  }

  # this recursively refines each macro definition in the lookup table
  # and then stores the final fully expanded value in the output table
  foreach $key (keys %{$defines}) {
    $define = C::Define::NoArgs->new($debug,$self,$key); 
    $define->keep($define->expand());
  }
}

sub defines_args {
  my ($self,$debug) = @_;
  my $defines = $self->get_args();
  return unless defined $defines;

  my ($key,$define);
  foreach $key (keys %{$defines}) {
    $defines->{$key}->[1] = $self->strip($defines->{$key}->[1]);
  }

  # this recursively refines each macro definition in the lookup table
  # and then stores the final fully expanded value in the output table
  foreach $key (keys %{$defines}) {
    $define = C::Define::Args->new($debug,$self,$key); 
    $define->keep($define->expand());
  }
}

# Gets rid of unwanted characters in the macro
sub strip {
  my ($self,$define) = @_;

  # strip all comments - I think that C::Scan really ought to do this,
  # but until I understand what &sanitize does, I'm not touching it.
  # besides these are pretty simple regexp's...
  $define =~ s@\s*//.*@@; # Get rid of C++ comments
  $define =~ s@/\s*\*.*\*/\s*@@; # Get rid of C comments
  $define =~ s@\s*$@@; # Get rid of trailing whitespace
  $define =~ s@\n@@;	# Get rid of newlines
  $define =~ s@\s+@ @; # Get rid of extra whitespace
  return $define;
}  

# these methods operate on the output tables
sub get_args {
  my ($self) = @_;
  return $self->[1]->{'args'};
}

sub set_args {
  my ($self,$macros) = @_;
  return $self->[1]->{'args'} = $macros;
}

sub get_no_args {
  my ($self) = @_;
  return $self->[1]->{'no_args'};
}

sub set_no_args {
  my ($self,$macros) = @_;
  return $self->[1]->{'no_args'} = $macros;
}

# these methods operate on the lookup tables
sub get_no_args_lookup {
  my ($self) = @_;
  return $self->[1]->{'no_args_lookup'};
}

sub set_no_args_lookup {
  my ($self,$macros) = @_;
  return $self->[1]->{'no_args_lookup'} = $macros;
}

sub get_args_lookup {
  my ($self) = @_;
  return $self->[1]->{'args_lookup'};
}

sub set_args_lookup {
  my ($self,$macros) = @_;
  return $self->[1]->{'args_lookup'} = $macros;
}

##################################
#
# C::DEFINES
# C::DEFINES::NoArgs
# C::DEFINES::Args
#
# These classes abstract out the two different types of #define
# macros, Those with arguments, e.g. #define min(x,y) ((x) < (y) ? (x): (y)), 
# and simple macros, e.g. #define NEEDS_JPEG 1

package C::Define;

sub new {
  my ($class,$debug,$file,$name) = @_;
  my $self = {};
  $self->{'debug'} = $debug;
  $self->{'file'} = $file;
  $self->{'name'} = $name;
  bless $self, $class;
}

sub debug {return shift->{'debug'};}
sub file {return shift->{'file'};}

# by default, the macros don't have arguments
sub args {return 0;}

# is $name a macro in this file? If so, return an instance of the
# appropriate C::Define subclass, otherwise return undef.
# we now look up the symbol in every file in $debug's list of files.
sub defined {
  my $self = shift;
  my $name = shift;
  my $debug = $self->debug();
  my $file;
  foreach $file (@{$debug}) {
    if (exists $file->get_no_args_lookup()->{$name}) {
      return new('C::Define::NoArgs',$debug,$file,$name);
    } elsif (exists $file->get_args_lookup()->{$name}) {
      return new('C::Define::Args',$debug,$file,$name);    
    } 
  }
  return undef;
}

# Given a macro definition, we expand it - so that it relies on no
# other (known) macros - by tokenizing it and expanding each token in
# the macro depth first, and then replacing each token in the current
# macro by the fully expanded version of the token
sub expand {
  my $self = shift;
  my $macro = $self->get();

  # If local macros are being used, it is possible for them to be in
  # the local table but not in the global lookup table. The local
  # version just looks for all #define's in the file, without actually
  # expanding the #if's
  return undef unless defined $macro;

  my (@tokens,$token,$new_macro);

  # tokenize $macro and expand each of the tokens
  # abort if there are any unexpanded tokens
  @tokens = $macro =~ m/\w+/g;
  foreach $token (@tokens) {
    # is there a better way to tell if an sv is a number???
    if ($token =~ /^\d+$/ || $token =~ /0x[a-f0-9]+/) {
      # just a number, so skip it
      next;
    }
    
    # this is really a token that we might need to expand
    $new_macro = $self->defined($token); 
    unless (defined $new_macro) {
      # this token isn't in the macro tables so I take it to be a
      # global symbol so we don't need to replace it
      next;
    } 

    # refine the token
    $new_macro->expand();
    if (!defined $new_macro->get) {
      print "Broke on token = $token, macro = $macro\n";
    }
    # replace all occurrences of token with its definition
    if ($new_macro->args()) {
      # if it takes args, replace the arglist too
      $macro =~ s/\b$token\b\([^\)]*?\)/$new_macro->get()/e;      
    } else {
      $macro =~ s/\b$token\b/$new_macro->get()/e;      
    }
  }

  # replace the hash entry with the fully expanded definition
  return $self->set($macro);
}

# For simple macros, C::Scan stores the macro as the value of the name key.
package C::Define::NoArgs;
@C::Define::NoArgs::ISA = ('C::Define');

# NOTE: get() and set() only affect the lookup tables, keep()
# changes the value in the output table 
sub get {
  my $self = shift;
  my $hash = $self->file()->get_no_args_lookup();
  my $name = $self->{'name'};
  return $hash->{$name};
}

sub set {
  my $self = shift;
  my $value = shift;
  my $hash = $self->file()->get_no_args_lookup();
  my $name = $self->{'name'};
  return $hash->{$name} = $value;
}

sub keep {
  my $self = shift;
  my $value = shift;
  my $hash = $self->file()->get_no_args();
  my $name = $self->{'name'};
  return $hash->{$name} = $value;
}

# For macros with arguments, C::Scan stores the info in an array
# ref. The first position is an array ref of all the argumentment
# names. The second position is the string of the actual macro.
package C::Define::Args;
@C::Define::Args::ISA = ('C::Define');

# members of this class have arguments
sub args {return 1;}

# NOTE: get() and set() only affect the lookup tables, keep()
# changes the value in the output table 
sub get {
  my $self = shift;
  my $hash = $self->file()->get_args_lookup();
  my $name = $self->{'name'};
  return $hash->{$name}->[1];
}

sub set {
  my $self = shift;
  my $value = shift;
  my $hash = $self->file()->get_args_lookup();
  my $name = $self->{'name'};
  return $hash->{$name}->[1] = $value;
}

sub keep {
  my $self = shift;
  my $value = shift;
  my $hash = $self->file()->get_args();
  my $name = $self->{'name'};
  return $hash->{$name}->[1] = $value;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 AUTHOR

Jason E. Stewart, jasons@cs.unm.edu

=head1 SEE ALSO

perl(1), Devel::DebugInit::GDB(3), C::Scan(3), and Data::Flow(3).

=cut
