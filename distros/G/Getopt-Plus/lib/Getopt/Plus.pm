# (X)Emacs mode: -*- cperl -*-

# Check working/testing without Term::ProgressBar
# Document SUPER:: calling of check, etc.
# Add validity checks to check (e.g., modes set ok)
# Add check to mode to check mode is valid
# Document mode_info (esp. in init) (and add to SYNOPSIS)
# Document

package Getopt::Plus;

=head1 NAME

Getopt::Plus - Options wrapper with standard options, help system and more

=head1 SYNOPSIS

Z<>

=head1 DESCRIPTION

Z<>

=cut

# ----------------------------------------------------------------------------

# Pragmas -----------------------------

require 5.005_62;
use strict;
use warnings;

# Inheritance -------------------------

use base qw( Exporter );
our @EXPORT_OK   = qw( OPT_FLOAT OPT_INT OPT_STRING OPT_BOOLEAN OPT_FDLEVEL
                       ERR_OK ERR_ABNORMAL ERR_UTILITY ERR_USAGE
                       ERR_IO_READ ERR_IO_WRITE
                       ERR_DB_READ ERR_DB_WRITE
                       ERR_RDBMS_READ ERR_RDBMS_WRITE
                       ERR_EXTERNAL ERR_INTERNAL ERR_INPUT
                       ERR_UNKNOWN
                       find_exec ftime commify human_file_size
                       $PACKAGE $VERSION );
our %EXPORT_TAGS = ( opt_types  => [qw/ OPT_FLOAT OPT_INT OPT_STRING
                                        OPT_BOOLEAN OPT_FDLEVEL /],
                     exit_codes => [qw/ ERR_OK
                                        ERR_ABNORMAL ERR_UTILITY
                                        ERR_USAGE
                                        ERR_IO_READ ERR_IO_WRITE
                                        ERR_DB_READ ERR_DB_WRITE
                                        ERR_RDBMS_READ ERR_RDBMS_WRITE
                                        ERR_EXTERNAL ERR_INTERNAL
                                        ERR_INPUT
                                        ERR_UNKNOWN /],
                    );

# Utility -----------------------------

use Carp                             qw( carp croak );
use Class::MethodMaker          1.04 qw( );
use Data::Dumper                     qw( );
use Env                              qw( @PATH );
use Fatal                       1.02 qw( :void close open seek sysopen );
use Fcntl                       1.03 qw( :seek );
use File::Basename               2.6 qw( fileparse );
use File::Spec::Functions        1.1 qw( catfile );
use File::Temp                  0.12 qw( tempfile );
use FindBin                          qw( $Script );
use Getopt::Long                2.25 qw( );
use IPC::Run                    0.44 qw( harness );
use List::Util                  1.06 qw( first min max sum );
use Log::Info                   1.13 qw( :DEFAULT :log_levels
                                         :default_channels :trap );
use Pod::Select                 1.13 qw( podselect );
use Pod::Text                   2.08 qw( );
use Pod::Usage                  1.12 qw( pod2usage );
use Text::Tabs             98.112801 qw( expand );
use Text::Wrap             2001.0131 qw( wrap );

my ($ReadKeyPresent);
BEGIN {
  eval 'use Term::ReadKey 2.14 qw( );';
  $ReadKeyPresent = $@ ? 0 : 1;
}

BEGIN {
  select((select(STDOUT), $| = 1)[0]);
}

# ----------------------------------------------------------------------------

# CLASS METHODS --------------------------------------------------------------

# -------------------------------------
# CLASS CONSTANTS
# -------------------------------------

=head1 CLASS CONSTANTS

Z<>

=cut

# Maximum width of option name column in opt output
use constant MAX_OPT_WIDTH => 13;

=head2 FILE_SIZE_HUMAN

Map from file size in bytes to human name, as hashref, keys being name (full
name, lowercase, no trailing 's') and abbrev (one/two-letter abbreviation).

=cut

use constant FILE_SIZE_HUMAN =>
  +{ 1024**0 => +{ name => 'byte',     abbrev => 'b' },
     1024**1 => +{ name => 'kilobyte', abbrev => 'Kb' },
     1024**2 => +{ name => 'megabyte', abbrev => 'Mb' },
     1024**3 => +{ name => 'gigabyte', abbrev => 'Gb' },
     1024**4 => +{ name => 'terabyte', abbrev => 'Tb' },
   };

# OPTION TYPES ------------------------

=head2 Option Types

Permissable values to the C<type> field of an option specifier.

=over 4

=item OPT_FLOAT

=item OPT_INT

=item OPT_STRING

=item OPT_FDLEVEL

=item OPT_BOOLEAN

=back

=cut

use constant OPT_FLOAT          => 'f';
use constant OPT_INT            => 'i';
use constant OPT_STRING         => 's';
use constant OPT_FDLEVEL        => 'F';
use constant OPT_BOOLEAN        => '!';

use constant OPTION_NAMES => {
                              OPT_FLOAT   , 'float'    ,
                              OPT_INT     , 'int'      ,
                              OPT_STRING  , 'string'   ,
                              OPT_FDLEVEL , 'fd/level' ,
                             };

use constant GETOPT_TYPE_MAP => {
                                 OPT_FLOAT   , { char => 'f' } ,
                                 OPT_INT     , { char => 'i' } ,
                                 OPT_STRING  , { char => 's' } ,
                                 OPT_FDLEVEL , { char => 's' } ,
                                 OPT_BOOLEAN , { char => '!' } ,
                                };

# DEFAULT OPTIONS ---------------------

use constant STANDARD_OPTIONS =>
  [
   {
    names     => [qw/ v verbose /],
    summary   => 'output informational messages',
    desc      => <<'END',
Enable informational messages about choices made, etc. to stderr.
This option may be invoked multiple times to increase the level of
verbosity.
END
    default   => 0,
    linkage   => sub {
      my ($rse, $opt, $value) = @_;
      $value = 1+$rse->verbose;
      my $verboseness =
        Log::Info::enable_file_channel(CHAN_INFO, $value, 'verbose', SINK_STDERR);
      $rse->verbose($verboseness);
    }
   },

   {
    names     => [qw/ progress /],
    summary   => 'output progress messages',
    desc      => <<'END',
Enable regular messages to inform the user of progress made. These may be in
simple text form, or where appropriate, progress bars or the like may be used
(when connected to a suitable terminal).
END
    default   => 0,
    linkage   => sub {
      my ($rse, $opt, $value) = @_;
      Log::Info::enable_file_channel(CHAN_PROGRESS, $value, 'progress',
                                     'p-out', 1);
    }
   },

   {
    names     => [qw/ stats /],
    summary   => 'output statistical information',
    desc      => 'Enable statistical information to be output to the user.',
    default   => 0,
    linkage   => sub {
      my ($rse, $opt, $value) = @_;
      Log::Info::enable_file_channel(CHAN_STATS, $value, 'stats', 's-out');
    }
   },

    undef,

    {
     names     => [qw/ help /],
     type      => OPT_STRING,
     arg_reqd  => 0,
     mandatory => 0,
     summary   => 'produce summary help on stdout',
     desc      => <<'END',
Print a brief help message and exit.  If an argument is given, then it is
treated as an option name, and the description for that option is given (a la
longhelp).
END
     default   => 0,
     linkage   => sub { $_[0]->dump_help(undef, $_[2]) },
    },

    {
     names     => [qw/ longhelp /],
     arg_reqd  => 0,
     mandatory => 0,
     summary   => 'produce long help on stdout',
     desc      => 'Print a longer help message and exit.',
     default   => 0,
     linkage   => sub { $_[0]->dump_longhelp },
    },

    {
     names     => [qw/ man /],
     arg_reqd  => 0,
     mandatory => 0,
     summary   => 'produce full man page on stdout',
     desc      => 'Print the manual page and exit.',
     default   => 0,
     linkage   => sub { $_[0]->dump_man },
    },

    {
     names     => [qw/ version /],
     arg_reqd  => 0,
     mandatory => 0,
     summary   => 'produce full version on stdout',
     desc      => <<'END',
Print the version info (as for C<briefversion>) and the copyright notice,
and exit.
END
     default   => 0,
     linkage   => sub { $_[0]->dump_version },
    },

    {
     names     => [qw/ V briefversion /],
     arg_reqd  => 0,
     mandatory => 0,
     summary   => 'produce brief version on stdout',
     desc      => <<'END',
Print the version number (of the source package), in the form

  scriptname (packagename): version

and exit. scriptname is the canonical installed name of the script.
END
     default   => undef,
     linkage   => sub { $_[0]->dump_briefversion },
    },

    {
     names     => [qw/ copyright /],
     arg_reqd  => 0,
     mandatory => 0,
     summary   => 'produce full copyright on stdout',
     desc      => 'Print the copyright notice, and exit.',
     default   => 0,
     linkage   => sub { $_[0]->dump_copyright },
     arg_trigger => 1,
    },

    undef,

    {
     names     => [qw/ dry-run /],
     arg_reqd  => 0,
     mandatory => 0,
     summary   => "don't really do anything",
     desc      => <<'END',
Do not write any files (other than temporary files), nor make any changes to
any RDBMS (other than disposable ones).
END
     default   => 0,
     arg_trigger => 1,
    },

   {
    names     => [qw/ debug /],
    mandatory => 0,
    summary   => '',
    desc      => 'Enable debugging output.',
    default   => 0,
    linkage   => sub {
      my ($rse, $opt, $value) = @_;
      Log::Info::enable_file_channel(CHAN_DEBUG, $value, 'debug', 'd-out');
    }
   },

   {
    names     => [qw/ dump-pod /],
    type      => OPT_FDLEVEL,
    arg_reqd  => 0,
    mandatory => 0,
    summary   => 'dump generated pod',
    default   => 0,
    linkage   => sub { $_[0]->dump_as_pod(1); $_[0]->dump_man },
    hidden    => 1,
   },

   {
    names     => [qw/ allmodversions /],
    summary   => 'dump all versions of included modules',
    linkage   => sub {
      for my $modx (sort keys %INC) {
        next if substr($modx, 0, 1) eq '/';
        my $mod = $modx; $mod =~ s!/!::!g; $mod =~ s!\.pm$!!;
        no strict 'refs';
        my $version = ${*{"${mod}::VERSION"}{SCALAR}};
        my $vstring = defined($version) ? sprintf('%5.2f', $version) : 'undef';
        printf "%-20s\t%s\t%s\n", $mod, $vstring, $INC{$modx};
      }
    },
    hidden    => 1,
   },  ];

# STANDARD TEXT --------------------------------------------------------------

use constant OPTION_TEXT => <<'END';
Options come in short (single-character) and/or long forms. Short options are
preceded by a single dash (-x), whilst long options are preceded by a
double-dash (--option). Long options may be abbreviated to the minimal
distinct prefix. Single char options may not be bundled (-v -a -x !=
-vax). Options taking string values will assume that anything immediately
following is a string value, even if the string is optional and/or the "value"
could be interpreted as another option (if -v takes a string, -vax will give
the value "ax" to the option -v).

Options which are boolean must use the long form (if available) to negate,
prefixed by "no" (--foo may be negated by --nofoo).

Options which are repeating may be invoked multiple times for greater effect.

Option & argument order does not matter: all options will be processed prior
to any arguments.

A lone "--" may be used to terminate options processing; any text(s) following
this will be treated as arguments, rather than options.

Some options are marked as type 'fd/level'.  These take options of the form
C<+([0-9]+)> to set a specific level, and/or either a simple file name
([A-Za-z0-9_-.\/]+) or a file-descriptor number (preceded by a colon).  They
come in the order file,level,fd (but it is illegal to specify a filename and a
file descriptor together).  E.g., C<+1> sets to level one (to the default
filehandle), C</tmp/foo> sets it to output to F</tmp/foo> (at the default
level); C<+2:3> outputs at level 2 to file descriptor 3.

If a filename is given, an error will ensue if that file already exists (and
is a plain file). This is to avoid accidents due to the optional string
syntax.

Beware optional arguments; if you use an option that takes an optional
argument, then any likely-looking (in the case of string arguments, anything)
following it will be treated as an argument to the option. If you mean for an
argument-looking thing to be an argument to the option, use C<--foo=bob>
(for clarity). If you want to follow it with a value that looks like an
argument to the option (but you intend to be a value for the program), follow
it with C<-->, e.g., C<myprog --foo -- bob>
END

use constant DEFAULT_ENV_TEXT =>
  'This program has no special environment handling';

# ERROR CODES -------------------------

use constant DEFAULT_ERR =>
  [ 'Successful termination',
    'Successful, but abnormal termination',
    'A utility function was requested (--help, --version etc.)',
    'Incorrect usage',
    'Filesystem error on open/read',
    'Filesystem error on close/write',
    'RDBMS access error on read/connect',
    'RDBMS access error on on write',
    'Unexpected exit status from external program',
  ];
BEGIN {
  DEFAULT_ERR->[255] = 'Unknown Error';
}

=head2 Error Codes

=over 4

=cut

=item ERR_OK

Not an error at all.  Hence the name.

=cut

use constant ERR_OK             => 0;

=item ERR_ABNORMAL

Not so much an error as a non-erroneous circumstance worthy of signalling,
e.g., grep finding no matches.

=cut

use constant ERR_ABNORMAL       => 1;

=item ERR_UTILITY

Again, not really an error, rather a utility function being called --- e.g.,
the --help or --version.  This gets an error code because it is almost
certainly an error to call from batch scripts.

=cut

use constant ERR_UTILITY        => 2;

=item ERR_USAGE

The program was called wrong.

=cut

use constant ERR_USAGE          => 3;

=item ERR_IO_READ

Some problem reading from disk or network (system read).

=cut

use constant ERR_IO_READ        => 4;

=item ERR_IO_WRITE

Some problem writing to disk or network (system write).

=cut

use constant ERR_IO_WRITE       => 5;

=item ERR_DB_READ

Some problem reading from db or similar (application read).

=cut

use constant ERR_RDBMS_READ     => 6;
use constant ERR_DB_READ        => 6;

=item ERR_DB_WRITE

Some problem writing to db or similar (application write).

=cut

use constant ERR_RDBMS_WRITE    => 7;
use constant ERR_DB_WRITE       => 7;

=item ERR_EXTERNAL

Some problem with an external application.

=cut

use constant ERR_EXTERNAL       => 8;

=item ERR_INTERNAL

An internal logic error (the sort of thing that I<should> never happen, but
has been caught by an internal assertion or sanity check).

=cut

use constant ERR_INTERNAL       => 9;

=item ERR_INPUT

Some problem with the input file (which was read fine, but contains bad data).

=cut

use constant ERR_INPUT          => 10;

=item ERR_UNKNOWN

=cut

use constant ERR_UNKNOWN        => 255;

=back

=cut

# -------------------------------------

our $PACKAGE = 'Getopt-Plus';
our $VERSION = '0.99';

# -------------------------------------
# CLASS CONSTRUCTION
# -------------------------------------

# -------------------------------------
# CLASS COMPONENTS
# -------------------------------------

=head1 CLASS COMPONENTS

Z<>

=cut

my $DEFAULT_VERSION = undef;

# -------------------------------------
# CLASS HIGHER-LEVEL FUNCTIONS
# -------------------------------------

=head1 CLASS HIGHER-LEVEL FUNCTIONS

Z<>

=cut

# -------------------------------------
# CLASS HIGHER-LEVEL PROCEDURES
# -------------------------------------

=head1 CLASS HIGHER-LEVEL PROCEDURES

Z<>

=cut

sub VERSION { $DEFAULT_VERSION = $_[1]; $_[0]->SUPER::VERSION(@_>2?$_[1]:()) }

# -------------------------------------
# CLASS UTILITY FUNCTIONS
# -------------------------------------

=head2 find_exec

For each directory P of the current path (in order), check if the named
program exists in P and is executable (just as the shell would when executing
a command).

=over 4

=item ARGUMENTS

=over 4

=item exec

The name of the command to execute

=back

=item RETURNS

=over 4

=item path

If the command exists in the path, the path to the command.  The path will be
relative if the given path segment is.  If the command does not exist in the
path, then nothing (undef or the empty list) shall be returned.

=back

=back

=cut

sub find_exec {
  my ($exec) = @_;

  return $_
    for grep -x $_, map catfile($_, $exec), @PATH;

  return;
}

# -------------------------------------

sub columns {
  my ($outfh) = @_;

  return $ENV{COLUMNS}
    if exists $ENV{COLUMNS} and $ENV{COLUMNS} =~ /^\d+$/;

  my $columns = 72;

  if ( defined $outfh ) {
    if ( -t $outfh ) {
      if ( $ReadKeyPresent ) {
        eval {
          $columns = (Term::ReadKey::GetTerminalSize($outfh))[0];
        }; if ( $@ ) {
          warn $@;
        }
      } else {
        if ( my $stty = find_exec('stty') ) {
          my ($readfh, $writefh);
          pipe $readfh, $writefh
            or croak "Failed to forge pipe: $!\n";

          my $pid = fork;
          croak "Fork failed: $!\n"
            if ! defined $pid;

          my $sttyout;

          if ( $pid ) { # Parent
            close $writefh;
            local $/ = undef;
            $sttyout = <$readfh>;
            close $readfh;
            my $rv = waitpid($pid, 0);
            croak "waitpid returned $rv (expected $pid)\n"
              unless $rv == $pid;
          } else {      # Child
            open STDOUT, ">&" . fileno $writefh;
            exec $stty, '-a';
          }

          if ( $sttyout =~ /(?:^|;)\s*columns\s+(\d+)\;/m ) {
            $columns = $1;
          } elsif ( $sttyout =~ /(?:^|;)\s*(\d+)\s+columns\s*\;/m ) {
            $columns = $1;
          }
        }
      }
    }
  }

  return $columns;
}

# -------------------------------------

# Merge a set of values so that they use up the min. possible lines, subject
# to a max. line length & join field (and preserving order).

sub _merge_words {
  my ($words, $max_length, $join) = @_;

  my @lines;
  my $current = $words->[0];
  for (@{$words}[1..$#$words]) {
    if ( length($current) + length($_) + length($join) > $max_length ) {
      push @lines, $current;
      $current = $_;
    } else {
      $current = length($current) ? join($join,$current,$_) : $_;
    }
  }
  push @lines, $current;

  return @lines;
}

# -------------------------------------

=head2 ftime

This function is exported upon request.

=over

=item SYNOPSIS

  print ftime 86500; # 1d0h0m40s
  print ftime 357;   # 5m57s

=item ARGUMENTS

=over

=item time

time (duration) to format, as a number of seconds

=back

=item RETURNS

=over

=item *

The input time, formatted as days/hours/minutes/seconds (larger exponents
produced only as needed)

=back

=back

=cut

# Format time

sub ftime {
  my ($time) = @_;

  if ( $time < 60 ) {
    return sprintf '%ds', $time;
  } elsif ( $time < 60 * 60 ) {
    return sprintf '%dm%ds', int($time/60), $time % 60;
  } elsif ( $time < 60 * 60 * 24 ) {
    return sprintf('%dh%dm%ds',
                   int($time/(60*60)),
                   int(($time%60)/60),
                   $time % 60);
  } else {
    return sprintf('%dd%dh%dm%ds',
                   int($time/(24*60*60)),
                   int($time%(60*60)/(60*60)),
                   int(($time%60)/60),
                   $time % 60);
  }
}

# -------------------------------------

=head2 commify

This function is exported upon request.

=over

=item SYNOPSIS

  print commify 1_535_343;          # 1,535,343
  print commify 1_535_343.45459845; # 1,535,343.454,598,45

=item ARGUMENTS

=over

=item number

number to commify.

=back

=item RETURNS

=over

=item *

The input number, with commas between groups 3 digits.

=back

=back

=cut

sub commify ($) {
  (my $text = reverse $_[0]) =~ s/(\d{3})(?=\d)(?!\d*\.)/$1,/g;
  $text = reverse $text;
  1
    while $text =~ s/([.,])(\d{3})(?=\d)/$1$2,/g;
  return  $text;
}

# -------------------------------------

=head2 human_file_size

This function is exported upon request.

=over

=item SYNOPSIS

  print human_file_size(1_000);     # 1000b
  print human_file_size(1_024);     # 1Kb
  print human_file_size(1_535);     # 1Kb
  print human_file_size(1_535_343); #1Mb

=item ARGUMENTS

=over

=item bytes

An integer being a number of bytes

=back

=item RETURNS

=over

=item *

A human-readable representation of the size.  That is, the bytes suffixed with
the appropriate b/Kb/Mb/etc. exponent.  Note that the mantissa is rounded to
the nearest integer

=back

=back

=cut

sub human_file_size {
  my ($bytes) = @_;

  carp ("human_file_size: bytes not defined\n"), return ''
    unless defined $bytes;

  return $bytes
    if $bytes < 1;

  my $exponent =
    first { $bytes >= $_ } sort {$b<=>$a} keys %{FILE_SIZE_HUMAN()};

  return join('',
              sprintf('%1.0f', ($bytes / $exponent)),
              FILE_SIZE_HUMAN->{$exponent}->{abbrev});
}

# INSTANCE METHODS -----------------------------------------------------------

# -------------------------------------
# INSTANCE CONSTRUCTION
# -------------------------------------

=head1 INSTANCE CONSTRUCTION

Z<>

=cut

=head2 new

Create & return a new thing.

=over 4

=item SYNOPSIS

  my $RSE =
    Getopt::Plus->new(scriptname => 'exec-monitor',
                      scriptsumm => 'Exec a process, monitor resources',
                      copyright  => <<'END',
  This program is copyright __CYEARS__ Martyn J. Pearce. This program is free
  software; you can redistribute it and/or modify it under the same terms
  as Perl itself.
  END
                      main       => sub {},
                      argtype    => 'exec',
                      arg_ary    => '+',
                      options    =>
                        [{
                          names     => [qw( output o )],
                          type      => OPT_FDLEVEL,
                          arg_reqd  => 1,
                          mandatory => 0,
                          summary   => 'No meaning',
                          desc      => 'No description',
                          default   => 'foo',
                          linkage   => sub {
                            my ($rse, $opt, $value) = @_;
                            Log::Info::enable_file_channel(MONITOR_CHANNEL,
                                                           $value,
                                                           'output',
                                                           MONITOR_SINK);
                            $sink_added = 1;
                          },
                         },
                        ],
                      );

  $RSE->run;

=item ARGUMENTS

Arguments are taken as key => value pairs.  Recognized keys are:

=over 4

=item scriptname

B<Mandatory> The canonical name of the script.  This should I<not> be $0 ---
it should have no path, and be the I<canonical> name.  Hence, for C<gunzip> ,
this would be C<gzip>.

=item scriptsumm

B<Optional> A one-line summary of the purpose of the script; suitable for the
header (C<NAME>) line of a man page.

=item copyright

B<Optional> A (possibly multi-line) summary of the copyright status of this
program.  B<If no copyright option is provided, this program will state that
it has no copyright>.  If the copyright contains the text C<__CYEARS__>, this
will be replaced with the approraite copyright years.

=item main

B<Mandatory> This must be a coderef.  It will be called once for each argument
on the command line after options processing.  Its arguments will be:

=over 4

=item rse

This instance of Getopt::Plus.

=item arg_name

The ARGV item in question

=item output_fns

If output_suffix has any members, then this contains one filename for each
member, constructed appending the member onto the basename of the arg_name,
with any (single) trailing suffix stripped.  The value is an arrayref.

Hence, if C<arg_name> is F</tmp/blibble.foo.baz>, and C<output_suffix> is set
to C<(jim, kate)>, then C<output_fns> is C<[blibble.foo.jim,
blibble.foo.kate]>.

=back

=item c_years

B<Optional> An arrayref of copyright years.  This is required if the
C<copyright> option contains the text __CYEARS__.

=item package

B<Optional> The package from which this program comes.  Please set this
correctly, so a user can determine which package to install on their box to
install this program (this is useful when, for example, asking a friend or
colleague the origin a your cool script).  The package name should not be a
class name, e.g., C<Getopt::Plus>, but a partial file name, e.g., F<Getopt-Plus>.

=item version

B<Optional> A version number.  If the script comes from a package, then please
use the version number of the I<package> here, not some individual concept of
version for the executable.  This is for two reasons:

=over 4

=item *

Since the executable is a part of the package, it presumably utilizes common
libraries which have likely changed as the package got updated.  Therefore the
executable behaviour will have changed even if the specific script code has
not.

=item *

Users typically install the package as a whole (after all, that's why they're
distributed as packages...), so the version of the installed package is more
useful than a script version number which has no direct connection.

=back

=item options

B<Optional>

An arrayref of option specifications.

Each specification is a hashref, with the following keys:

=over 4

=item names

B<Mandatory> An arrayref of available names for this option.  Both short &
long options are given here; any single-char option is a short option, any
multi-char option is a long option.  There is no meaning to the order, other
than the "default" name comes first; this is used only by the C<linkage>
specifier.

=item type

B<Optional> A specifier of the type of the argument, if any.  Any value from
L<Option Type|"Option Types"> is permissable.  If not provided, this option
brooks no argument.

Default: empty (no argument)

=item arg_reqd

B<Optional> If true, the option I<requires> an argument.  The C<type> argument
is mandatory if this is true.  The program will fail with status ERR_USAGE if
this argument is provided without an argument.

Default: false

=item mandatory

B<Optional> If true, this option C<must> be invoked.  The program will fail
with status ERR_USAGE if this argument is not invoked.  Mandatory arguments
I<must> have simple scalar linkage.

Default: false

=item linkage

B<Optional> If provided, this may be any type that
L<Getopt::Long|"Getopt::Long"> accepts.

If the linkage is a coderef, it will be called as would
L<Getopt::Long|"Getopt::Long">, with the exception that the subject RSE
instance will be inserted as the first argument.

If linkage is not provided, then it must be provided in the first
(C<linkages>)
 argument to L<get_options|get_options>, or else you will not be
able to get at any values for the option (but the user will still be able to
use it).  This is probably only useful for compatibility options that are
ignored.

=item summary

B<Optional> A short summary of the meaning of the option.  Keep it short
(preferably 16 chars or less)

Default: the empty string

=item desc

B<Optional> A long description of the meaning of the option.

Default: the empty string

=item default

B<Optional> The default value of the option.  I<Currently>, this has no
semantic value (but this may change in future).  It is used for documentation,
however.

Default: the empty string

=item hidden

B<Optional> If true, the option is not documented.  This is intended for
developer-only options.

Default: false

=back

Default: empty list.

=item check

B<Optional> If provided, a coderef that is executed immediately after the
options have been processed.  It is passed a single argument, that this is
RSE instance.  This is intended to check that the program can run --- e.g.,
to detect incorrect options combinations, errors in the environment.  Any
return value is ignored; if an error is detected, call C<< $rse->die >>, and
the program will terminate appropriately before any real work is done.

This differs from C<initialize> in that it runs in I<every> mode.

Default: an empty coderef.

=item initialize

B<Optional> If provided, a coderef that is executed prior to any call of
C<main>.  It is passed a single argument, that this is RSE instance.  This is
intended to perform any initialization tasks common to all arguments.  Any
return value is ignored; if an error is detected, call C<< $rse->die >>, and
the program will terminate appropriately before any real work is done.

This differs from C<check> in that it only runs in B<normal> mode, so in other
modes (e.g., requisite checking other verification modes), this is not run.

Default: an empty coderef.

=item finalize

B<Optional> If provided, a coderef that is executed after to every call of
C<main>.  It is passed a single argument, that this is RSE instance.  This is
intended to perform any cleanup tasks common to all arguments; often cleaning
up resources allocated by C<initialize>.  Any return value is ignored; if an
error is detected, call C<< $rse->die >>, and the program will terminate
appropriately.

This is analogous to initialize.

Default: an empty coderef.

=item end

B<Optional> This is very much like C<finalize>, but is run in all modes, even
if one of these previous stages failed.

Default: an empty coderef.

=item argtype

B<Optional> The type of each argument.  This (currently) has no semantic
value; it is used in documentation.  A typical value might be 'file'.  This
makes sense only if arg_ary is not '0'.

=item arg_ary

B<Optional> The number of args permissable to this executable (after any
option processing).

Valid values are:

=over 4

=item '0'

=item '1'

=item '+'

=item '*'

=back

It is an error to specify an arg_ary that is not '0' without also specifying
an C<argtype>.

=item output_suffix

B<Optional> If defined, then for every file specified on the command line,
then output files named by adding the given extensions are considered to be
created.  The value should be a simple value or an arrayref.

=item dry_run

B<Optional> If true, this program respects the C<--dry-run> option.  Do not
set it unless it is true --- that would give the user a false sense of
security.

The C<dry_run> method will error if called on an instance that is does not
have this option set.

If set to the special value C<'hidden'>, then the option will be parsed and
the C<dry_run> method will work, but the option will be not documented to the
user.

=back

=back

=cut

Class::MethodMaker->import (new_with_init => 'new',
                            new_hash_init => 'hash_init',);

sub init {
  my $self = shift;
  my (%args) = @_;

  # Initialize config with defaults
  my %config = ( arg_ary         => 0,
                 check           => sub {},
                 initialize      => sub {},
                 finalize        => sub {},
                 end             => sub {},
                 interface       => $DEFAULT_VERSION,
                 verbose         => 0,
               );

  # Check for mandatory args
  my @missing = grep ! exists $args{$_}, qw( main );
  croak sprintf("Manadatory arguments missing: %s\n", join(', ', @missing))
    if @missing;

  # default scriptname
  $args{scriptname} = $Script
    unless exists $args{scriptname};

  # Check validity of options, c_years arguments
  $config{options} = delete $args{options} || [];

  croak sprintf("'$_' must be an arrayref (if defined)")
    for grep(exists $config{$_}                    &&
             defined $config{$_}                   &&
             ! UNIVERSAL::isa($config{$_}, 'ARRAY'),
             qw( options c_years ));

  for my $opt (undef, @{STANDARD_OPTIONS()}) {
    my $name;
    ($name = $opt->{names}->[0]) =~ tr/-/_/
      if defined $opt;
    push @{$config{options}}, $opt
      if  ! defined $opt || ! exists $opt->{arg_trigger} || $args{$name};
  }

  # Copy in config from arguments
  $config{$_} = delete $args{$_}
    for grep(exists $args{$_},
             qw( scriptname scriptsumm copyright c_years
                 argtype arg_ary envtext
                 output_suffix main initialize mode_info
                 package version finalize end check req_check ));

  # Check for consistency in arg_type & arg_ary
  croak
    sprintf("Cannot specify a possibly positive arg_ary (%s) without an " .
            "argtype\n", $config{arg_ary})
    if ! defined $config{argtype} and
       ( $config{arg_ary} !~ /^\d+$/ or $config{arg_ary} != 0 );

  if ( exists $args{dry_run} ) {
    if ( $args{dry_run} eq 'hidden' ) {
      $_->{hidden} = 1
        for grep(defined $_ && grep($_ eq 'dry-run', @{$_->{names}}),
                 @{$config{options}});
    }
    $config{_dry_run_known} = 1;
    delete $args{dry_run};
  }

  # Check copyright & c_years
  if ( exists $config{copyright} and $config{copyright} =~ /__CYEARS__/ ) {
    croak "c_years must be provided with __CYEARS__ in copyright text"
      unless defined $config{c_years};

    croak sprintf("'c_years' values out of range")
      if grep(($_ < 1990 || $_ > 1900+(localtime)[5]+1), @{$config{c_years}});
  }

  croak sprintf "'arg_ary' must be 0, 1, '*'  or '+'"
    unless ( $config{arg_ary} eq '+' or
             $config{arg_ary} eq '*' or
             $config{arg_ary} eq '0' or
             $config{arg_ary} eq '1'
           );
  croak sprintf("'arg_ary' must be 0 if argtype not defined, " .
                "and 1 or '+' otherwise")
    unless ( $config{arg_ary} xor
             ( ! exists $config{argtype} or ! defined $config{argtype} ) );


  my %optkeys = map({; $_ => 1 }
                    map keys %$_, grep defined $_, @{$config{options}});
  delete $optkeys{$_}
    for qw( names type arg_reqd mandatory summary desc default linkage hidden arg_trigger );
  croak sprintf("Options arg(s) not recognized: %s\n",join(', ',keys %optkeys))
    if keys %optkeys;

  # Error with bad arguments
  croak sprintf("Arguments %s unrecognized", join ', ', keys %args)
    if keys %args;

  $config{tempfh} = tempfile;

  # Set up defaults
  $self->hash_init(%config,
                   diag => DEFAULT_ERR,
                   outfh => \*STDIN,
                  );
}

# -------------------------------------
# INSTANCE FINALIZATION
# -------------------------------------

# -------------------------------------
# INSTANCE COMPONENTS
# -------------------------------------

=head1 INSTANCE COMPONENTS

The following components are implemented via Class::MethodMaker

=head2 Scalar Components

=over 4

=item mode

The current mode in force.  Defaults to undef.  This needs to be selected in
the check block to have effect.

=back

=head2 List Components

=over 4

=item output_suffix

If defined, the output suffix to use.  The value should not include any
initial '.'.  So, for mp3 files, use 'mp3', not '.mp3'.  This is a list
element; if it contains multiple values, then multiple output files are
considered to be created.  Output file names are always created in the same
order as the suffixes in this list.

=back

=head2 Hash Components

=over 4

=item mode_info

A map from a mode name to details about that mode.  This is for storage of run
modes.

The detail itself must be a hashref; recognized keys are

=over 4

=item initialize

A coderef

=item main

A coderef

=item finalize

A coderef

=back

=head2 Boolean Components

=over 4

=item args_done

Set this to true to prevent any main calls.  Implemented to all callbacks from
main to prevent further processing (without signalling an error).

=back

=cut

Class::MethodMaker->import
  (
   get_set => [qw/ scriptname scriptsumm tempfh outfh argtype arg_ary
                   envtext exit_code package version copyright interface
                   main initialize finalize dump_as_pod verbose
                   mode /
              ],
   list    => [qw/ options diag c_years output_suffix /],
   hash    => [qw/ mode_info /],
   boolean => [qw/ args_done
                   _dry_run_known
                   __opt_dry_run /],
   method  => [qw/ end check
                   req_check /],
  );


# -------------------------------------
# INSTANCE HIGHER-LEVEL FUNCTIONS
# -------------------------------------

=head1 INSTANCE HIGHER-LEVEL FUNCTIONS

=cut

=head2 dry_run

=over 4

=item PREREQUISITES

This instance was created with the C<dry_run> option set.

=item ARGUMENTS

I<None>

=item RETURNS

=over 4

=item dry_run

True if the program is in dry-run mode (the C<--dry-run> option has been
invoked).

=back

=back

=cut

sub dry_run {
  my $self = shift;
  croak sprintf("This program (%s) does not respect the dry-run option\n",
                $self->scriptname)
    unless $self->_dry_run_known;

  return $self->__opt_dry_run;
}

# -------------------------------------

sub dump_man      { $_[0]->_dump_pod(ERR_UTILITY, 2, $_[1]) }

# -------------------------------------

sub dump_help     {
  my $self = shift;
  my ($outfh, $optname) = @_;

  if ( defined $optname and length $optname ) {
    my $opt_found = 0;
    $outfh ||= \*STDOUT;

    for my $opt ($self->options) {
      if ( grep $_ eq $optname, @{$opt->{names}} ) {
        my $desc = $opt->{desc};

        if ( ! defined $desc or $desc =~ /^\s*$/ ) {
          print $outfh "No description available for option $optname\n";
          $self->exit_code(ERR_UTILITY);
        } else {

          my $columns = columns($outfh);
          local $Text::Wrap::columns = $columns;
          my @para = split /\n\n+/, $desc;
          for (@para) {
            tr/\n/ /;
            $_ = wrap('', '', $_);
            s/\s*\Z//s;
          }

          my $tempfh = tempfile;

          print $tempfh "=pod\n\n";
          print $tempfh join "\n\n", @para;
          print $tempfh "\n";
          print $tempfh "\n=cut";

          seek $tempfh, 0, SEEK_SET;
          my $parser = Pod::Text->new(indent => 0,
                                      sentence => 1,
                                      width => $columns);
          my $tempfh2 = tempfile;
          $parser->parse_from_filehandle($tempfh, $tempfh2);

          seek $tempfh2, 0, SEEK_SET;
          my $accum;
          while (<$tempfh2>) {
            if ( /^\s*$/ ) {
              if ( defined $accum ) {
                if ( $accum =~ /^\s*$/ ) {
                  $accum .= $_;
                } else {
                  print $outfh $accum;
                  $accum = $_;
                }
              } else {
                # We're at the start; do nothing, so as to strip leading
                # blank lines
              }
            } else {
              $accum .= $_;
            }
          }
          print $outfh $accum
            if defined $accum and $accum !~ /^\s*$/;
          $self->exit_code(ERR_UTILITY);
        }
        $opt_found = 1;
      }
    }

    unless ( $opt_found ) {
      print STDERR "No such option: $optname\n";
      $self->exit_code(ERR_USAGE);
    }
  } else {
    $self->_dump_pod(ERR_UTILITY, 0, $outfh);
  }
}

sub dump_longhelp { $_[0]->_dump_pod(ERR_UTILITY, 1, $_[1]) }

sub _dump_pod {
  my $self = shift;
  my ($exitval, $verbose, $outfh) = @_;
  $outfh ||= \*STDOUT;

  my $fh = $self->tempfh;
  seek $fh, 0, SEEK_SET;
  $self->_make_pod($fh);
  seek $fh, 0, SEEK_SET;
  if ( $self->dump_as_pod ) {
    print $_
      while <$fh>;
  } else {
    pod2usage( -exitval => 'NOEXIT',
               -verbose => $verbose,
               -output  => $outfh,
               -input => $fh,
             );
  }
  $self->exit_code($exitval);
}

sub dump_copyright    { $_[0]->_dump_version_info($_[1], 0, 1) }
sub dump_version      { $_[0]->_dump_version_info($_[1], 1, 1) }
sub dump_briefversion { $_[0]->_dump_version_info($_[1], 1, 0) }

sub _dump_version_info {
  my $self = shift;
  my ($outfh, $version, $copyright) = @_;
  $outfh ||= \*STDOUT;

  if ( $version ) {
    my ($scriptname, $package, $version) =
      map $self->$_, qw( scriptname package version );
    print $outfh $scriptname;
    print $outfh " ($package)"
      if defined $package and length $package;
    print $outfh ": $version"
      if defined $version and length $version;
    print $outfh "\n";
    print $outfh "\n"
      if $copyright and defined $self->_copyright;
  }

  print $outfh $self->_copyright
    if $copyright and defined $self->_copyright;

  $self->exit_code(ERR_UTILITY);
}

sub _copyright {
  my $self = shift;

  local $" = ', ';
  my @cyears = $self->c_years;
  return unless defined(my $copyright = $self->copyright);
  $copyright =~ s/__CYEARS__/@cyears/;
  $copyright .= "\n"
    unless substr($copyright, -1, 1) eq "\n";
  return $copyright;
}

# Generate a Getopt::Long spec list (and associated details) for the option
# set.
#
# Args:
#  -) linkages
#     A hashref from an option name (can be any name given to an option; it
#     is an error for two or more aliases to the same option to be provided)
#     to a linkage type.
#
# Returns:
#  -) spec
#     an arrayref to pass (expanded) to Getopt::Long::GetOptions as an
#     option specification
#  -) config
#     A config hash containing a scalar linkage for each option for which
#     no other linkage is provided, named by the first name of the option.
#  -) mandatory
#     A hash from (first) option name to linkage, for each mandatory option.
sub _opt_spec {
  my $self = shift;
  my ($linkages) = @_;
  my $opt_values = $_;

  my (@spec, %config, %mandatory);
  my %linkage_keys = map {;$_ => 1} (defined $linkages ? keys %$linkages : ());

  my @options;
  for my $opt ($self->options) {
    $opt->{fullname} = join '|', sort { length($b) <=> length($a) } @{$opt->{names}}
      if keys %$opt;
    # Split out single-char options with optional arguments;
    # the single-char version takes *no* argument
    if ( exists $opt->{type}
         and
         ! ( exists $opt->{arg_reqd} and $opt->{arg_reqd} )
         and
         grep length($_) == 1, @{$opt->{names}}
       ) {
      my %opt1 = %$opt;
      my %opt2 = %$opt;
      $opt1{fullname} = $opt2{fullname} = join '|', sort { length($b) <=> length($a) } @{$opt->{names}};
      $opt2{names} = [grep length($_) == 1, @{$opt->{names}} ];
      $opt1{names} = [grep length($_) >  1, @{$opt->{names}} ];
      die("No multi-char options named for opt arg option ",
          join(',', @{$opt2{names}}), "\n")
        unless @{$opt->{names}};
      delete $opt2{type};
      push @options, \%opt2;
      push @options, \%opt1;
    } else {
      push @options, $opt
        if defined $opt and keys %$opt;
    }
  }

  for my $opt ( @options) {
    my @names = sort { length($b) <=> length($a) } @{$opt->{names}};
    my $spec = join '|', @names;
    my $name = $spec;

    my $linkage;
    # Prefer linkage provided by function argument to those set in the object
    if ( defined $linkages ) {
      for my $name (@names) {
        if ( exists $linkages->{$name} ) {
          croak "Multiple linkages defined for option $name\n"
            if defined $linkage;
          $linkage = $linkages->{$name};
          delete $linkage_keys{$name};
        }
      }
    }
    # Fall back to linkage set in this instance, or failing that, a generated
    # scalar one in the default hash.
    $linkage =
      exists $opt->{linkage} ? $opt->{linkage} : \$config{$opt->{names}->[0]}
      unless defined $linkage;

    croak "Cannot handle mandatory args other than scalars ($name)\n"
      if $opt->{mandatory} && ! UNIVERSAL::isa($linkage, 'SCALAR');

    my $target = UNIVERSAL::isa($linkage, 'CODE') ?
                 sub { $linkage->($self, @_); }   :
                 $linkage;

    if ( exists $opt->{type} ) {
      my $join;
      if ( $opt->{type} eq OPT_BOOLEAN ) {
        $join = '';
        croak "Cannot have a boolean arg with a required value! ($name)\n"
          if $opt->{arg_reqd};
      } else {
        $join = exists $opt->{arg_reqd} && $opt->{arg_reqd} ? '=' : ':';
      }
      my $type = GETOPT_TYPE_MAP->{$opt->{type}}->{char};
      $spec   .= "$join$type";
    }

    push @spec, $spec, $target;

    croak "Cannot have a default value with a mandatory option: $name\n"
      if $opt->{mandatory} and defined $opt->{default};

    $mandatory{$opt->{fullname}} = $target
      if $opt->{mandatory};
  }

  carp(sprintf("Linkage names do not correspond to known options: %s\n",
               join(',', keys %linkage_keys)))
    if keys %linkage_keys;
  return \@spec, \%config, \%mandatory;
}

# -------------------------------------

# Don't set linkages for standard options (unless you want trouble!)
# Perhaps we should have a standard place for those so they can always be
# called by overriding methods (and so they should all be methods)
sub get_options {
  my $self = shift;
  my ($linkages) = @_;

  $linkages = {}
    unless defined $linkages;
  for (grep ! exists $linkages->{$_}, qw( dry-run )) {
    (my $opt_name = "__opt_$_") =~ tr/-/_/;
    $linkages->{$_} = sub { $self->$opt_name($_[2]) }
      unless $_ eq 'dry-run' && ! $self->_dry_run_known;
  }

  my ($spec, $config, $mandatory) = $self->_opt_spec($linkages);

  my $parser =
    Getopt::Long::Parser->new(config => [(qw( no_auto_abbrev no_bundling
                                              no_getopt_compat gnu_compat
                                              no_ignore_case permute
                                              prefix_pattern=(--|-)
                                            ))]);
  $parser->getoptions(@$spec)
    or warn("Options parsing failed\n"), $self->exit_code(ERR_USAGE);

  unless ( $self->exit_code ) {
    my @missing = grep ! defined ${$mandatory->{$_}}, keys %$mandatory;
    $self->die(ERR_USAGE, sprintf("Mandatory options missing: %s\n", join ', ', @missing))
      if @missing;
  }
}

# -------------------------------------

=head2 run

Do the business.

=over 4

=item 1

parse command-line options

=item 2

run C<check>

=item 3

select C<mode>, and therefore C<initialize>, C<main> & C<finalize>.

=item 4

run C<initialize>

=item 5

check number of arguments

=item 6

run C<main> with each argument (or with undef, if permissable and no arguments
provided)

=item 7

run C<finalize>

=item 8

run C<end>

=item 9

exit with the appropriate error code

=back

=cut

sub run {
  my $self = shift;

  eval { # Protect from early death so, e.g., end can run
    $self->get_options;
  }; if ( $@ ) {
    # Log it because die itself is caught.
    Log(CHAN_INFO, LOG_ERR, $@);
    eval {
      $self->die(ERR_USAGE, 'options parsing failed');
    };
  }

  # For arg. consistency checks, etc.
  # This differs from initialize in that this runs in both requisite & normal
  # mode, and a true return value is required.
  unless ( defined $self->exit_code and $self->exit_code > 1 ) {
    eval { # Protect from early death so, e.g., end can run
      $self->check;
    }; if ( $@ ) {
      # Log it because die itself is caught.
      Log(CHAN_INFO, LOG_ERR, $@);
      Log(CHAN_INFO, LOG_ERR, 'check failed');
      eval {
        $self->die(ERR_UNKNOWN, 'check failed');
      };
    }
  }

  my $mode = $self->mode;
  my ($initialize, $main, $finalize);
  if ( defined $mode ) {
    croak "Unknown mode -->$mode<-- selected\n"
      unless $self->mode_info_exists($mode);
    ($initialize, $main, $finalize) =
      @{$self->mode_info($mode)}{qw(initialize main finalize)};
  } else {
    ($initialize, $main, $finalize) =
      ($self->initialize, $self->main, $self->finalize);
  }

  unless ( $self->exit_code ) {
    my $arg_seen = 0;

    my $args_done = 0;

    # General set up prior to handling arguments.  This might include
    # frigging @ARGV itself
    eval {
      # Protect from early death so, e.g., C<end> can run
      if ( defined $self->interface && $self->interface >= 0.96 ) {
        my ($argv) = $initialize->($self, \@ARGV);
        @ARGV = @$argv
          if defined $argv;
      } else {
        $initialize->($self);
      }
    }; if ( $@ ) {
      # Log it because die itself is caught.
      Log(CHAN_INFO, LOG_ERR, $@);
      Log(CHAN_INFO, LOG_ERR, 'initialize failed');
      eval {
        $self->die(ERR_UNKNOWN, 'initialize failed');
      };
    }

    eval {
      # Protect from early death so, e.g., C<end> can run
      if ( @ARGV and $self->arg_ary eq '0' ) {
        my $message = sprintf "%s: brooks no argument\n", $self->scriptname;
        # Log it because die itself is caught.
        Log(CHAN_INFO, LOG_ERR, $message);
        $self->die(ERR_USAGE, $message);
      }
    };

    eval { # Protect from early death so, e.g., C<end> can run
      my $args = join('', map "-->$_<--", @ARGV);
      my $got = @ARGV ? sprintf('%d: %s', scalar @ARGV, $args) : '0';
      if ( $self->arg_ary eq '1' and @ARGV != 1 ) {
        my $message = sprintf("%s: takes exactly one argument (got %s)\n",
                           $self->scriptname,
                           $got);
        # Log it because die itself is caught.
        Log(CHAN_INFO, LOG_ERR, $message);
        $self->die(ERR_USAGE, $message);
      }
    };

    for my $arg (@ARGV) {
      last if defined $self->exit_code and $self->exit_code > 1;
      last if $self->args_done;
      eval {
        $main->($self, $arg, [$self->output_fn($arg)]);
        $args_done++;
        Logf(CHAN_PROGRESS, LOG_INFO,
             '[%d/%d Arguments Done] Done Argument %s',
             $args_done, scalar(@ARGV), $arg);
        $arg_seen = 1;
      }; if ( $@ ) {
        my $message = "failed processing argument: $arg";
        $message   .= ":\n  $@"
          if $@ !~ /^\s*$/;
        eval {
          # Protect from early death so, e.g., C<end> can run
          # Log it because die itself is caught.
          Log(CHAN_INFO, LOG_ERR, $message);
          $self->die(undef, $message);
        }
      }
    }

    unless ( $arg_seen or $self->exit_code ) {
      if ( $self->arg_ary eq '0' or $self->arg_ary eq '*' ) {
        eval {
          $main->($self);
          Log(CHAN_PROGRESS, LOG_INFO,
              '[1/1 Arguments Done] Done Empty Argument');
          $arg_seen = 1;
        }; if ( $@ ) {
          my $message = 'failed processing empty argument';
          $message   .= ":\n  $@"
            if $@ !~ /^\s*$/;
          eval {
            # Protect from early death so, e.g., C<end> can run
            # Log it because die itself is caught.
            Log(CHAN_INFO, LOG_ERR, $message);
            $self->die(undef, $message);
          }
        }
      } else {
        eval {
          $self->die(ERR_USAGE, 'At least one arg must be given');
        }
      }
    }

    eval {
      # Protect from early death so, e.g., C<end> can run
      # Deliberately at the same level as initialize
      $finalize->($self)
        unless $self->exit_code and $self->exit_code > 1;
    }; if ( $@ ) {
      # Log it because die itself is caught.
      Log(CHAN_INFO, LOG_ERR, $@);
      Log(CHAN_INFO, LOG_ERR, 'finalize failed');
      eval {
        $self->die(ERR_UNKNOWN, "finalize failed");
      };
    }
  }

  eval {
    # This deliberately runs even if a termination condition has been found.
    # Including help modes.
    # This even runs in help mode
    $self->end;
  }; if ( $@ ) {
    # Log it because die itself is caught.
    Log(CHAN_INFO, LOG_ERR, $@);
    Log(CHAN_INFO, LOG_ERR, "Error executing clean-up");
    eval { # Protect from early death so, e.g., C<end> can run
      $self->die(ERR_UNKNOWN, "Error executing clean-up");
    }
  }

  my $exit = $self->exit_code;
  $exit = 0
    unless defined $exit;
  exit (defined $exit ? $exit : 0);
}

# -------------------------------------

=head2 output_fn

=over 4

=item ARGUMENTS

=over 4

=item input_fn

Name of the input file to construct an output file name from.

=back

=item RETURNS

=over 4

=item output_fn+

Name of the output file.  Not defined if output_suffix is not set.  May be
multiple names if multiple output_suffixes are set.

=back

=back

=cut

sub output_fn {
  my $self = shift;
  my ($in_fn) = @_;

  confess "No in_fn specified!\n"
    unless defined $in_fn;
  my @Result;

  my $stub = (fileparse($in_fn, qr!\.[^.]*$!))[0];

  for my $suffix (grep defined $_, $self->output_suffix) {
    if ( length $suffix ) {
      push @Result, join '.', $stub, $suffix;
    } else {
      push @Result, $stub;
    }
  }

  return @Result;
}

# -------------------------------------

# Run a system command, throw an exception with command name & exit status on
# non-zero exit

=head2 check_run

=over 4

=item ARGUMENTS

The arguments are taken as key => value pairs.  Like a hash.  The recognized
keys are:

=over 4

=item cmd

B<Mandatory>.  The command to run, as an arrayref of items, where each item is
itself an arrayref (a command, as a list of arguments), or a '|' symbol (to
pipe commands into one another.)

=item name

B<Optional>.  A label for informational messages.

=item stdin

B<Optional>.  A scalar (filename) or scalar ref (ref to hold string) for std
input.

=item stdout

B<Optional>

=item stderr

B<Optional>

=item expect

B<Optional>.  The error code to expect.  Defaults to zero.  check_run will
croak if an unexpected error_code occurs.

=item err_code

B<Optional>.  The error code to set in case of failure.  Defaults to
ERR_EXTERNAL.

=item redirects

A list of redirects (other than std(in|out|err)), in C<IPC::Run> notation.

=item dry_run

If true, observes the dry_run flag --- i.e., if dry_run is set, then the
external executable is not run (but messages are still issued).  Defaults to 0
(for backward compatibility).

=back

=back

=cut

sub check_run {
  my $self = shift;
  my %args = @_;

  my $cmd  = delete $args{cmd}
    or croak "cmd value must be specified\n";
  my $name = ( exists $args{name}   ?
               delete $args{name}   :
               do{my $x=$cmd;$x=$x->[0] while UNIVERSAL::isa($x,"ARRAY");$x}
             );
  my $expect = delete $args{expect} || 0;

  my ($y, $z) = ('') x 2;
  my $stdin  = delete $args{stdin};
  my $stdout = delete $args{stdout} || \$y;
  my $stderr = delete $args{stderr} || \$z;

  my $obs_dr = delete $args{dry_run} || 0; # Observe Dry Run
  my $dry_run = 0;
  if ( $obs_dr ) {
    # Protect with eval for dry_run subr croaks if dry_run flag not set.
    eval { $dry_run = $self->dry_run };
  }

  my $err_code = delete $args{err_code} || ERR_EXTERNAL;

  my @redirects = @{delete $args{redirects}}
    if exists $args{redirects};

  croak sprintf 'Args not recognized: %s', join ',', keys %args
    if keys %args;

  my $expand;
  $expand =
    sub { map +(UNIVERSAL::isa($_, 'ARRAY') ? $expand->(@$_) : $_), @_ };
  my $cmdstring = join ' ', $expand->($cmd);

  Logf(CHAN_INFO, LOG_INFO+1,
       "%s cmd ($name): $cmdstring", ($dry_run ? 'Would run' : 'Running'));
  Logf(CHAN_DEBUG, LOG_INFO,
       'Cmd %s (expecting %d) : %s',
       $name, $expect,
       Data::Dumper->new([$a])->Terse(1)->Indent(0)->Useqq(1)->Dump);

  # Don't pass in even \undef to stdin unnecessarily, as IPC::Run consumes
  # memory if you do.
  my @args = ((defined $stdin ? ('<', $stdin) : ()),
              '>', $stdout, '2>', $stderr, @redirects);
  my $harness = harness @$cmd, @args;
  my $start = time;
  my $rv = $expect << 8;
  unless ( $dry_run ) {
    $harness->run;
    $rv = $harness->full_result;
  }
  my $end = time;

  Logf(CHAN_STATS, LOG_INFO,
       "Running %s took %s\n", $name, ftime($end-$start));

  if ( $rv & 255 or $rv >> 8 != $expect ) {
    Logf(CHAN_INFO, LOG_WARNING,
         'Command %s failed with err output: %s', $name, $$stderr)
      if defined $stderr and $$stderr !~ /^\s*$/;
    $self->exit_code($err_code)
      if $err_code;
    croak sprintf("Error running %s\n  Return Code %d, Signal %d, Core %d\n",
                  $cmdstring, $rv >> 8, $rv & 127, ($rv & 128) >> 7);
  }
}

# -------------------------------------
# INSTANCE HIGHER-LEVEL PROCEDURES
# -------------------------------------

=head1 INSTANCE HIGHER-LEVEL PROCEDURES

Z<>

=cut

=head2 new_exit_value

Generate a new exit value for a given error type.  An exception is thrown if
no new exit value is available.

=over 4

=item ARGUMENTS

=over 4

=item message

A small (<= 60 chars) message to associate with the exit value.  This is given
in the DIAGNOSTICS section of the manpage.

=back

=item RETURNS

=over 4

=item exit_value

An exit value to use for this error type (in the range 0--255).

=back

=back

=cut

sub new_exit_value {
  my $self = shift;
  my ($message) = @_;

  for (0..255) {
    my $errnum = 255 - $_;
    if ( ! defined $self->diag_index($errnum) ) {
      $self->diag_set($errnum, $message);
      return $errnum;
    }
  }

  croak "Sorry, all exit values allocated!\n";
}

# -------------------------------------

sub _make_pod {
  my $self = shift;
  my ($tempfh) = @_;

  my $columns = columns($self->outfh);
  # Offset columns to account for Pod::Usage reformatting
  $columns -= 4;
  local $Text::Wrap::columns = $columns;

  $self->_make_pod_head($tempfh, $columns);
  $self->_make_pod_opts($tempfh, $columns);

  podselect({-output => $tempfh,
             -sections => ["DESCRIPTION"]}, $0);

  $self->_make_pod_optl($tempfh, $columns);
  $self->_make_pod_env ($tempfh, $columns);
  $self->_make_pod_diag($tempfh, $columns);

  podselect
    ({-output => $tempfh,
      -sections => ["!NAME|DESCRIPTION|SYNOPSIS|OPTIONS|ENVIRONMENT|DIAGNOSTICS|COPYRIGHT|SEE ALSO"]}, $0);

  $self->_make_pod_cprt($tempfh, $columns);

  podselect
    ({-output => $tempfh,
      -sections => ["SEE ALSO"]}, $0);
}

# -------------------------------------

sub _make_pod_head {
  my $self = shift;
  my ($fh) = @_;

  my $scriptname = $self->scriptname;
  my $scriptsumm = $self->scriptsumm;
  {
    my $prefix = "$scriptname - ";
    print $fh "=head1 NAME\n\n";
    print $fh expand(wrap($prefix, ' ' x length $prefix, $scriptsumm)), "\n\n";
  }

  print $fh "=head1 SYNOPSIS\n\n$scriptname [options]";
  print $fh ' ', $self->argtype, ($self->arg_ary eq '+' ? '+' : '')
    if $self->arg_ary;
  print $fh "\n\n";
}

# -------------------------------------

sub _make_pod_opts {
  my $self = shift;
  my ($fh, $columns) = @_;

  my @summary;
 OPTION:
  for (@{$self->options}) {
    push(@summary, undef), next OPTION
      if ! defined $_;

    next OPTION
      if $_->{hidden};

    # Sort option names in ascending order of name length, including '--?'
    my @names = sort { length($a) <=> length($b) }
      map ((length($_) > 1 ? "--$_" : "-$_"),
           @{$_->{names}})
        ;

    my $type;
    $type = OPTION_NAMES->{$_->{type}}
      if exists $_->{type};

    $type = "[$type]"
      if defined $type and ! $_->{arg_reqd};
    $type ||= '';

    my $default = $_->{default};
    if ( $_->{mandatory} ) {
      $default = '------';
    } else {
      if ( defined $default ) {
        if ( $default =~ /^\d+(?:.\d+)?$/ ) {
          ; # Nothing to do
        } else {
          # Clarify that there's a string here
          $default =~ s/\'/\\\'/g;
          $default = "''"
            unless length $default;
        }
      } else {
#        $default = '*undef*';
        $default = '';
      }
    }

    my $unit    = $_->{unit}    || '';
    my $summary = $_->{summary} || '';

    my @nametext;
    my $current = '';
    for (@names) {
      if ( length($current) + length($_) + 1 > MAX_OPT_WIDTH ) {
        push @nametext, $current;
        $current = $_;
      } else {
        $current = length($current) ? join('|',$current,$_) : $_;
      }
    }
    push @nametext, $current;

    @nametext = _merge_words(\@names, MAX_OPT_WIDTH, '|')
      if @names > 1;
    push @summary, [ \@nametext, $type, $default, $unit, $summary ];
  }

  unshift @summary, ([[qw( Option )], qw( Value Default Unit Meaning )]);

  my @col_widths;
  for my $row (grep defined, @summary) {
    for (my $i = 0; $i < @$row; $i++) {
      my $length = $i ? length($row->[$i]) : length($row->[$i]->[0]);
      $col_widths[$i] = $length
        unless defined $col_widths[$i]     and
               $col_widths[$i] >= $length;
    }
  }

  # Limit option width; we have a wrapping trick below
  $col_widths[0] = min(MAX_OPT_WIDTH, $col_widths[0]);

  # Inter-column spacing
  # Offset by two for a initial 2 spaces to visually distinguish options
  my $space = max(2, int(($columns - 2 - sum @col_widths) / (@col_widths-1)));

  my $format = join ('', '  ',
                     join((' ' x $space),
                          map ("%-${_}s", @col_widths[0..$#col_widths-1])),
                     (' ' x $space)
                    );

  # Indent Meaning Field for wrapping
  (my $indent = $format) =~ s/%-?(\d+)s/' ' x $1/eg;
  for (@summary) {
    if ( ! defined $_ ) {
      print $fh ("\n");
    } else {
      my $last = pop @$_;

      my $thisformat = $format;

      # Potentially reformat names to fit onto fewer lines if space in
      # value/default/unit columns
      if ( $#{$_->[0]} and $_->[1] eq '' ) {
        my $name_space = $col_widths[0];
        my $i = 1;
        my $columns_usable = 1;
        while ( $i <= 3 and  $_->[$i] eq '' ) {
          $name_space += $space + $col_widths[$i];
          $columns_usable++;
        } continue {
          $i++;
        }

        my $replace = $columns_usable;
        $thisformat =~ s/^( *)(?:(?: *?)%-?\d+s){$replace}/$1%-${name_space}s/;

        $_->[0] = [ _merge_words($_->[0], $name_space, '|') ];
      }

      my $init = sprintf($thisformat,
                         map $_ || '', $_->[0]->[0], @{$_}[1..$#$_]);
      my @lines;
      if ( $last eq '' ) {
        @lines = $init;
      } else {
        eval {
          @lines = split/\n/, expand(wrap($init, $indent, $last));
        }; if ( $@ ) {
          die "Wrap failed: $@\n";
        }
      }
      for my $lineno ( 1..$#{$_->[0]} ) {
        my $opttext = (' ' x ($space + 2)) . $_->[0]->[$lineno];
        if ( $lineno > $#lines ) {
          $lines[$lineno] = $opttext;
        } else {
          substr($lines[$lineno], 0, length($opttext)) = $opttext;
        }
      }
      s/\s+$//
        for @lines;
      print $fh join("\n",@lines), "\n";
    }
  }

  print $fh "\n";
}

# -------------------------------------

sub _make_pod_optl {
  my $self = shift;
  my ($fh) = @_;

  print $fh "=head1 OPTIONS\n\n", OPTION_TEXT, "\n";

  my $over = 0;
 OPTION:
  for (grep defined, @{$self->options}) {
    next OPTION
      if $_->{hidden};
    # Place long options first in longhelp
    my $names = join '|', sort { length($b) <=> length($a) } @{$_->{names}};
    my $desc  = $_->{desc};
    $desc =~ s/\n+\Z//
      if defined $desc;
    if ( defined $desc and length $desc ) {
      print $fh "=over 4\n\n"
        unless $over;
      $over++;
      print $fh "=item $names\n\n";
      print $fh $desc, "\n\n";
    }
  }
  print $fh "=back\n\n"
    if $over;
}

# -------------------------------------

sub _make_pod_env {
  my $self = shift;
  my ($fh, $columns) = @_;

  print $fh "=head1 ENVIRONMENT\n\n";
  print $fh $self->envtext || DEFAULT_ENV_TEXT;
  print $fh "\n\n";
}

# -------------------------------------

sub _make_pod_diag {
  my $self = shift;
  my ($fh, $columns) = @_;

  print $fh "=head1 DIAGNOSTICS\n\n";
  print $fh "The following exit codes may be observed in abnormal cases:\n\n";

  for (1..255) {
    my $text = $self->diag_index($_);
    printf $fh " %3d   %s\n", $_, $text
      if defined $text;
  }

  print $fh "\n\n";
}

# -------------------------------------

sub _make_pod_cprt{
  my $self = shift;
  my ($fh, $columns) = @_;

  print $fh "=head1 COPYRIGHT\n\n";
  print $fh $self->_copyright, "\n";
}

# -------------------------------------

sub die {
  my $self = shift;
  my ($err, @msgs) = @_;
  croak "Not a numeric exit code: $err\n"
    if defined $err and $err !~ /^\d+$/;
  croak "Not a valid exit code: $err\n"
    if defined $err and ($err < 0 or $err > 255);

  my $exit = $self->exit_code;

  $exit = $err || ERR_UNKNOWN
    unless $exit;

  my @message = grep defined, @msgs;

  my $message = @message ? join('', @message, "\n") : "\n";

  $self->exit_code($exit);
  $! = $exit;
  die $message;
}

# ----------------------------------------------------------------------------

=head1 EXAMPLES

Z<>

=head1 BUGS

Z<>

=head1 REPORTING BUGS

Email the author.

=head1 AUTHOR

Martyn J. Pearce C<fluffy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2002, 2003, 2004, 2005 Martyn J. Pearce.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

Z<>

=cut

1; # keep require happy.

__END__
