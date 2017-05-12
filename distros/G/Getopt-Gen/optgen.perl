#!/usr/bin/perl -w

#############################################################################
#
# File: optgen.perl
# Author: Bryan Jurish <moocow@cpan.org>
# Description: generate an option-parser from extended .ggo files
#
#############################################################################

use lib qw(. ./blib/lib);
use Getopt::Gen;
use Getopt::Gen::cmdline_h;
use Getopt::Gen::cmdline_c;
use Getopt::Gen::cmdline_pod;

use Getopt::Long qw(:config gnu_getopt); # be compatible with gnu getopt
use Pod::Usage;
use IO::File;

########################################################################
# Globals
########################################################################
our $VERSION = 0.07;
our $progname = 'optgen.perl';


########################################################################
# Command-line processing
########################################################################
$input = undef;
$funcname = 'cmdline_parser';
$filename = 'cmdline';
$wantc = 1;
$wanth = 1;
$wantpod = 1;
$longhelp = 0;
$unnamed = 0;
$structname = "gengetopt_args_info";
$reparse_action = 'error';

$handle_help = 1;
$handle_version = 1;
$handle_error = 1;
$handle_rcfile = 1;
%defines = ();


$cmdline_opts = join(' ',   @ARGV);  ##-- also, only options
$cmdline      = "$0 $cmdline_opts";  ##-- save for later

GetOptions(## General Options
	   'help|h|?' => \$help,
	   'man' => \$man,
	   'version|V' => \$version,
	   ## Generation options
	   "input|i=s" => \$input,
	   "func-name|f=s" => \$funcname,
	   "file-name|F=s" => \$filename,
	   "long-help|l!"  => \$longhelp,
	   "struct-name|n=s" => \$structname,
	   "unnamed|unnamed-opts|u!" => \$unnamed,
	   "hfile!" => \$wanth,
	   "cfile!" => \$wantc,
	   "pod!" => \$wantpod,
	   "template|t=s" => \$user_template,
	   "define|D=s" => \%defines,
	   #...more here
	   "timestamp!" => \$want_timestamp,
	   "reparse-action|r=s" => \$reparse_action,
	   "handle-help" => \$handle_help,
	   "handle-version" => \$handle_version,
	   "handle-error|handle-errors" => \$handle_error,
	   "handle-rcfile" => \$handle_rcfile,
	   "no-handle-help" => sub { $handle_help = !$_[1]; },
	   "no-handle-version" => sub { $handle_version = !$_[1]; },
	   "no-handle-error|no-handle-errors" => sub { $handle_error = !$_[1]; },
	   "no-handle-rcfile" => sub { $handle_rcfile = !$_[1]; },
	  );


########################################################################
# Command-line processing
########################################################################
if ($version) {
  print STDERR 
    ("\n$0 version $VERSION by Bryan Jurish <moocow\@cpan.org>\n",
     "\t using Getopt::Gen version $Getopt::Gen::VERSION\n",
     "\n"
    );
  exit 0 if ($version);
}
pod2usage({-verbose=>2,-exit=>0}) if ($man);
pod2usage({-verbose=>0,-exit=>0}) if ($help);


###############################################################
# MAIN
###############################################################
$og = Getopt::Gen->new(
		       ## -- generation-flags
		       name=>$progname,
		       #infile=>$input,
		       funcname=>$funcname,
		       filename=>$filename,
		       longhelp=>$longhelp,
		       unnamed=>$unnamed,
		       structname=>$structname,
		       reparse_action=>$reparse_action,
		       handle_help=>$handle_help,
		       handle_version=>$handle_version,
		       handle_error=>$handle_error,
		       handle_rcfile=>$handle_rcfile,
		       want_timestamp=>$want_timestamp,
		      )
  or die("$0: could not create Getopt::Gen object!");

push(@ARGV,$input) if (defined($input));
push(@ARGV,'-') if (!@ARGV);
foreach my $gogfile (@ARGV) {
  print STDERR "$progname: parsing '$gogfile'...\n";
  if (!($rc = $og->parse($gogfile))) {
    die("$0: could not parse options-file '$gogfile':\n",
	"Error: ",
	(defined($og->{errstr})
	 ? $og->{errstr}
	 : ("condition ".(defined($rc) ? $rc : '<undef>')."\n")));
  }
}


## -- GENERATION
%genhash =
  (
   CMDLINE         =>$cmdline,
   CMDLINE_OPTIONS =>$cmdline_opts,
   OptGenVersion=>$VERSION,
   %defines,
  );

#-----------------------------------------------------------------------
# Generate
#-----------------------------------------------------------------------
if ($wanth) {
  $HFILE = IO::File->new(">$filename.h")
    || die("$0: could not open output header-file '$filename.h' for write: $!");
  Getopt::Gen::cmdline_h::fill_in($og,OUTPUT=>$HFILE,HASH=>\%genhash);
  $HFILE->close();
}

if ($wantc) {
  $CFILE = IO::File->new(">$filename.c")
    || die("$0: could not open output C-file '$filename.c' for write: $!");
  Getopt::Gen::cmdline_c::fill_in($og,OUTPUT=>$CFILE,HASH=>\%genhash);
  $HFILE->close();
}

if ($wantpod) {
  $PODFILE = IO::File->new(">$filename.pod")
    || die("$0: could not open output Pod-file '$filename.pod' for write: $!");
  Getopt::Gen::cmdline_pod::fill_in($og,OUTPUT=>$PODFILE,HASH=>\%genhash);
  $PODFILE->close();
}

if (defined($user_template)) {
  $og->fill_in(TYPE=>'FILE',
	       SOURCE=>$user_template,
	       OUTPUT=>\*STDOUT,
	       PREPEND=>'Getopt::Gen->import(qw(:utils));',
	       HASH=>\%genhash,
	      );
}


## -- DEBUG: PARSING
#print $og->dump('og');

__END__

###############################################################
=pod

=head1 NAME

optgen.perl - Generate C source code for command-line parsing.

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

 optgen.perl [OPTIONS] INPUT_FILE(s)

 Arguments:
    INPUT_FILE(s)  Option specification files

 General Options
    -h           --help                Print a short help message and exit
    -V           --version             Print version and exit
    -h           --help                Print a short help message and exit
                 --man                 Print a long help message and exit
    -V           --version             Print version and exit

 Generation Options
    -iSTRING     --input=STRING        Initial input file for compatibility
    -fSTRING     --func-name=STRING    Name of function to generate
    -FSTRING     --file-name=STRING    Basename of output file(s)
    -l           --long-help           Include long options in help?
    -nSTRING     --struct-name=STRING  Basename of generated C struct
    -u           --unnamed             Allow unnamed 'options' (arguments)
                 --nohfile             Do not generate .h file
                 --nocfile             Do not generate .c file
                 --nopod               Do not generate .pod file
                 --notimestamp         Do not generate timestamp (for .pod file)
    -tFILE       --template=FILE       Use an alternate template
    -DKEY=VALUE  --define=KEY=VALUE    Define additional replacement macros
    -rACT        --reparse-action=ACT  What to do when an option is given > once
                 --no-handle-help      Do not handle --help and -h options
                 --no-handle-version   Do not handle --version and -V options
                 --no-handle-rcfile    Do not handle --rcfile and -c options
                 --no-handle-error     Do not handle errors

=cut

###############################################################
# Description
###############################################################
=pod

=head1 DESCRIPTION

Generate C source code for command-line parsers
and POD source for documenting them.

=cut

###############################################################
# Arguments
###############################################################
=pod

=head1 ARGUMENTS

=over 4

=item * C<INPUT_FILE(s)>

Option specification files


Command-line specification files.  Format is similar
to that used by gengetopt.  Lines are of one of the
forms listed below.  Double-quotes are literals.

=over 4

=item B<Gengetopt-Compatible Declarations>

See L<gengetopt> for details on how the syntax
below effects the generated code.

=over 4

=item * package "PACKAGE"

Sets the name of the program.

Warning: this may bite you if you use autoheader (HAVE_CONFIG_H is included!)


=item * version "VERSION"

Sets the program version.  Same caveats as for "PACKAGE".

=item * purpose "PURPOSE"

A brief description of the program and what it is meant to do.


=item * option "LONG" SHORT "DESCR" no

Declares a 'function' option.
Here and below,
LONG is a long option name, SHORT is a short option name (single char),
and DESCR is a brief description.


=item * option "LONG" SHORT "DESCR" flag STATE

Declares a 'flag' option.
STATE is one of: on, off.


=item * option "LONG" SHORT "DESCR" TYPE ATTRS REQ

Declares an option with an argument.  TYPE is one of:
string, int, short, long, float, double, longdouble.

Here and below, ATTRS is a list of attributes of the form:
KEY="VALUE", and REQ (indicates whether the option is required)
is one of: yes,no.

Attributes used: default, details.

=back


=item B<Extended Declarations>

Getopt::Gen also recognizes an alternate syntax, similar
to the above.

=over 4

=item * KEYWORD "VALUE"

Declare any keyword value.

Keywords used: author, on_reparse, code, rcfile.
Pod-only keywords used: details, addenda, bugs, acknowledge, seealso.
Actually, 'package', 'version', and 'purpose' are
just keywords, too.

Extensions:

=over 4

=item * User keywords

User keywords are parsed also.

=item * "code" keyword

The "code" keyword includes literal code near the beginning
of the .c file for cmdline_c.

=item * "rcfile" keyword

The "rcfile" keyword declares a configuration file.  If it begins
with a literal tilde "~", the tilde will be replaced by the
home directory of the calling user at runtime.  rcfiles are
expected to contain lines of the form:

  LONG_OPTION_NAME OPTION_VALUE

where LONG_OPTION_NAME is the long name of some option, without
the leading '--', and OPTION_VALUE is the option's argument, if any.
Fields are whitespace-separated.  Leading whitespace and comments
(lines beginning with '#') are ignored.

=back


=item * argument "NAME" "DESCR" ATTRS

Declares an 'unnamed' option, aka an 'argument'.
Attributes used: details (pod only).


=item * optionType "LONG" SHORT "DESCR" ATTRS

Another way of declaring options.
'optionType' is one of:
funct, toggle, flag, string, rcfile, int, short, long, float, double, longdouble.

Attributes used: default, envdefault, required, code,
is_help, is_version, is_rcfile, details (pod only).

If specified, the value of the 'envdefault' attribute should be
the name of an environment variable which will be used as a default
value for the option if the option has not been set
when the C function cmdline_envdefaults() is called.
If you want this to happen, you must call cmdline_envdefaults()
yourself.

The "code" attribute is special -- it should contain literal perl
code returning a scalar value.  This value will be inserted literally
into the output code file for the option after the default action of
modifying the option data-structure has been performed.
You may use the perl variable $opt to refer to the option structure itself.
In the case of Getopt::Gen::cmdline_c, you may use the C variable
"args_info" to refer to the option-parser structure itself.

The "rcfile" option type is like the "string" type,
but it causes its argument to be read as a configuration file.

=back

=item B<Extended String Syntax>

Getopt::Gen accepts gengetopt-style double-quoted strings,
even if these span multiple lines.  Additionally, Getopt::Gen
recognizes non-quoted single symbols, single-quoted strings,
shell-style backquoted strings,
as well as expressions surrounded by curly braces {,} as strings.
As with the q() and qq() constructs in Perl itself, the only
requirement for curly-braced strings is that any curly braces
occuring within the string itself nest 'properly'.

=back

=back



=cut


###############################################################
# Options
###############################################################
=pod

=head1 OPTIONS

=cut

#--------------------------------------------------------------
# Option-Group General Options
#--------------------------------------------------------------
=pod

=head2 General Options

=over 4

=item * C<--help> , C<-h>

Print a short help message and exit.

Default: '0'


=item * C<--man>

Print a long help message and exit

Default: '0'

=item * C<--version> , C<-V>

Print version and exit.

Default: '0'

=back

=cut

#--------------------------------------------------------------
# Option-Group Generation Options
#--------------------------------------------------------------
=pod

=head2 Generation Options

=over 4

=item * C<--input=STRING> , C<-iSTRING>

Initial input file for compatibility.

Default: '-'

See L<INPUT_FILE(s)>


=item * C<--func-name=STRING> , C<-fSTRING>

Name of the parsing function to generate.

Default: 'cmdline_parser'



=item * C<--file-name=STRING> , C<-FSTRING>

Basename of output file(s).

Default: 'cmdline'



=item * C<--long-help> , C<-l>

Whether to include long options in help.

Default: '0'



=item * C<--struct-name=STRING> , C<-nSTRING>

Name of the generated C struct.

Default: 'gengetopt_args_info'



=item * C<--unnamed> , C<-u>

Allow unnamed 'options' (aka 'arguments').

Default: no.



=item * C<--nohfile>

Do not generate .h file.

Default: file is generated.


=item * C<--nocfile>

Do not generate .c file.

Default: file is generated.



=item * C<--nopod>

Do not generate .pod file.

Default: file is generated.


=item * C<--template=FILE> , C<-t FILE>

Use an alternate template file -- output is
printed to STDOUT.


=item * C<--define=KEY=VALUE> , C<-D KEY=VALUE>

Define additional replacement macros,
useful if you use your own skeleton.


=item * C<--reparse-action=ACT> , C<-r ACT>

What to do when an option is given more than once.

ACT is one of: error, warn, clobber.
Default: 'error'
See L<Getopt::Gen> for details on how this
effects the generated code.



=item * C<--no-handle-help>

Do not handle --help and -h options

Default: options are handled.



=item * C<--no-handle-version>

Do not handle --version and -V options

Default: options are handled.


=item * C<--no-handle-rcfile>

Do not handle --rcfile and -c options

Default: options are handled.


=item * C<--no-handle-error>

Do not exit on errors.

Default: errors are handled.



=back



=cut

###############################################################
# Bugs
###############################################################
=pod

=head1 BUGS AND LIMITATIONS

Probably many.

=cut

###############################################################
# Footer
###############################################################
=pod

=head1 ACKNOWLEDGEMENTS

perl by Larry Wall.

'gengetopt' was originally written by Roberto Arturo Tena Sanchez,
and it is currently maintained by Lorenzo Bettini.


=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 SEE ALSO

L<gengetopt>,
L<Getopt::Gen>,
L<perl>.

=cut
