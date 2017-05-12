package Getopt::Mixed::Help;

# Author, Copyright and License: see end of file

=head1 NAME

Getopt::Mixed::Help - combine L<C<Getopt::Mixed>> with usage and help

=head1 SYNOPSIS

    use constant DEFAULT_LOOPS => 10;
    use Getopt::Mixed::Help
	('<filenames>...' => 'filenames to be processed',
	 'ENV' => 'SCRIPT_OPT_',
	 'ENV_' => 'SCRIPT_OPT_',
	 'd>debug:i number' => 'turn on debugging information (*)',
	 'e>execute' => 'do it without asking for confirmation',
	 'f>force' => 'override all safety checks',
	 'i>interactive' => 'asks for confirmation before doing it',
	 'l>loops count' => 'number of loops to do',
	 'n>no-execute' => 'just print what would be done without doing it',
	 'q>quiet' => 'suppress all information',
	 's>summary' => 'print summary information on exit',
	 'v>verbose:i number' => 'turn on verbose information (*)',
	 '(*)' => '(*) You may add a positive integer for a higher level.'
	);
    if ($opt_...

    export SCRIPT_OPT_INTERACTIVE=1
    test_script -d -v 2 --summary some_file.ext other_file.ext

=head1 ABSTRACT

Getopt::Mixed::Help is a simplified interface to Getopt::Long adding
usage (help) functionality.  It automatically adds the options -?, -h
and --help (the last two configurable) to print the usage text.  It
allows to get option values from the environment (if the operating
system it runs on supports environment variables).  It can
automatically get default values from Perl constants.  It can also add
different flavours of support for multiple options.  Finally it
supports debugging output of the options used.

So like Getopt::Long it is (just another) module that parses options
passed on the command line into variables while removing them from
@ARGV.  Only normal parameters remain in @ARGV.

=head1 DESCRIPTION

The module uses a direct import mechanism called with a hash as
parameter.  The structure of the hash is as follows:

The key is a combined (SHORT > LONG [ARGUMENT SPECIFIER [VALUE
IDENTIFIER]]) option description for the outdated module
L<C<Getopt::Mixed>>, except for the VALUE IDENTIFIER which is simply
included into the help text.  The value following the key is simply
the help text for this option.  The examples should make everything
clear even if you are not familiar with L<C<Getopt::Mixed>>.

If the second character of the first key is not C<E<gt>>, the first
key is taken as descriptive identifiers for additional parameters and
the help for them.

Any key starting with C<(> and ending with C<)> will be interpreted as
a footnote (additional help text) to the real options.  They should be
used at the end of the list only.

A key equal to C<ENV> is used to get default values for the remaining
options from the environment.  For any option not initialised on the
command line an environment variable with the prefix of the value
following C<ENV> and a rest of the name identical to the uppercase
long option name (e.g. C<SCRIPT_OPT_DEBUG>) will be checked.  If this
environment variable exists, it will be used to set the option.  Note
that in the name of the rest of the environment variable uppercase is
used and hyphens are relaced with underlines.

A key equal to C<ENV_> is used in the same way as the key C<ENV>.  In
addition it allows for a special environment variable with the prefix
of the value following C<ENV> followed by a single underline (C<_>) as
combined initialiser (for more than one option, e.g. C<export
SCRIPT_OPT__='debug verbose=2'>).  Note that no whitespaces are
allowed in the values of the options initialised this way as the
string in the environment variable is parsed in a simple way.

The module defines the variable $optUsage containing the complete help
text.

If an option C<debug> exists and is choosen on the command line, this
module will print all option values and all remaining parameters to
standard error.  The name of this option may be changed, see
C<"changing the debug option"> below in the L</"CHANGING DEFAULT
BEHAVIOUR"> section.

Perl constants with the prefix C<DEBUG_> and a name matching the
option are used as default values for the options, see below for
details.

=head1 EXPORT

The module automatically exports all option variables (C<$opt_>) as
well as the usage text (C<$optUsage>).

=head1 OPTION DETAILS

=head2 parameter help ('parameter text' => 'parameter description')

If a script takes normal parameters (as oposed to options starting
with a hyphen), their description for the help text must be the first
parameter of the hash passed on import.  It is also necessary that the
second character of the key is not C<E<gt>>.  An example, if a script
using this module accepts one or more filenames as parameters, you
might want to use the following import parameter:

    '<filenames>...' => 'filenames to be processed'

This would produce the following help text:

    usage: script.pl [<options>] [--] <filenames>...

    filenames to be processed

=head2 combined options ('o>long-option ...' => 'option description')

Combined options are options that allow to use both a long and a short
option to set the same option variable for a script (see
L<C<Getopt::Mixed>> for details).  In principle Getopt::Mixed::Help
uses a syntax similar to L<C<Getopt::Mixed>> for the key of the import
parameter, but it changes their sequence within the alias.  The
minimal key for the import parameter just uses the character of the
short option followed by C<E<gt>> followed by the long option (without
C<-->).  It would define a boolean option variable, for example the
import parameter

    'o>long-option' => 'some long option'

defines a boolean option with the identifier C<$opt_long_option> that
can be set with the short option C<-o> and the long option
C<--long-option> (which may be abbreviated as described in
L<C<Getopt::Mixed>>).  Its help text would look as follows:

        -o|--long-option
            some long option

For string, integer or real number options the key of the import
parameter must be extended with an argument specifier.  There are 6
possible argument specifiers:

    =s for a mandatory string argument
    =i for a mandatory integer argument
    =f for a mandatory real number argument
    :s for an optional string argument
    :i for an optional integer argument
    :f for an optional real number argument

The argument specifieres may be followed by a blank and the value
identifier, a short text describing the argument.  This text will
become part of the help text.  If no describing text is specified,
C<string> will be used for strings, C<integer> for integers and
C<float> for real numbers.  Consider the import parameters of the
following example:

    'd>directory=s directory' => 'name of the directory',
    'o>offset:f' => 'offset in the file in % (default 0.0)'

This defines a string option with a mandatory value and the
indentifier C<$opt_directory> as well as a real number option with an
optional value and the identifier C<$opt_offset>.  The help text for
these options would be:

        -d|--directory <directory>
            name of the directory
        -o|--offset [<float>]
            offset in the file in % (default 0.0)

For an optional value the default value that is used if no value is
specified depends on its type.  For strings it is an empty string
(C<''>), for integers it is 1 and for real numbers it is 0.0.

=head2 long options ('long-option ...' => 'option description')

If you run out of characters for short options you end up with the
need for options that only exist as a long option.  They are just
declared like the combined options without the leading short option
character and the C<E<gt>>, e.g.

    'long-optional-string:s' => 'optional string'

The only pitfall with long options comes when the first option you
declare is not a combined option and you don't have normal parameters
as Getopt::Mixed::Help then would treat your long option declaration
as a L</"parameter help">.  To avoid this just put a C<-E<gt>->
declaration before it (see C<separator> in L</"CHANGING DEFAULT
BEHAVIOUR"> below).

=head2 getting options from environment variables ('ENV' => 'SCRIPT_OPT_')

There are two special import parameter keys that allow your script to
be able to read options from environment variables (if your operating
system supports it).

The first key is the string C<'ENV'>.  If it is defined, each option
variable cat get its default value from an environment variable if
that environment variable is set.  The name of that environment
variable is composed of the value of the C<'ENV'> import parameter and
the name of the long option where all characters are turned into
uppercase and all hyphens are replaces with underscores, e.g. for the
import parameters

    'ENV' => 'MYSEARCH',
    'd>start-dir=s directory' => 'name of the first directory'

the option variable C<$opt_start_dir> will be filled with the value of
the environment variable MYSEARCHSTART_DIR if that is set and the
option is not set on the command line.

The second environment import parameter key is the string C<'ENV_'>.
It works similar to the other one except that it defines an
environment variable that can be used to set a whole default command
line at once (well, only its options and not if their values would
contain blanks).  For this key the name of that environment variable
is composed of the value of the C<'ENV_'> import parameter followed by
an underscore (C<_>).  To put several long options into the
environment variable so created, just concatenate them together with
blanks and without their leading C<-->.  If for example above's
directory and offset options are preceeded by

    'ENV_' => 'MYSEARCH'

you could set the environment variable MYSEARCH_ from a shell like
this:

    export MYSEARCH_='offset=12.5 directory=/tmp/somewhere'

But remember, this works for simple things only, for more complicated
defaults from the environment you must create one variable for each
option as described above.  If you do both the value of the specific
environment variable overwrites that of the combined one.

And a warnings for this features, if you use both environment import
parameters (which is quite reasonable) you must use the same value for
both of them, otherwise only the last one specified works.

=head2 footnotes

Sometimes you'll like to describe an option in more details, want to
give additional information concerning more than one option or just
like to add some more text at the end of a generated help.  To do
that, Getopt::Mixed::Help allows you to add just about any text you
like to your import parameter list using keys that begin and end in
parentheses.  The key is not used any further, so you can use any text
as long as you put it into parentheses.  The text of the description
is put into the help text as it is, but preceeded and followed by a
newline.

Normally all footnotes are put at the end of the option list but
theoretically you could also put one in-between to split the option
list into two (or more) parts - the footnote is put into the help text
just where it occurs.

=head1 DEFINING DEFAULT VALUES USING PERL CONSTANTS

If you define a Perl constant (C<use constant>) beginning with
C<DEFAULT_> and ending with the name of the long option where all
characters are turned into uppercase and all hyphens are replaces with
underscores, e.g. for the import parameters

    'd>start-dir=s directory' => 'name of the first directory'

a

    use constant DEFAULT_START_DIR => '.';

the variable C<$opt_start_dir> will be initialised, if no other value
is specified by environment variable or on the command line.  (Options
on the command line overrule the values specified in environment
variables, which themselves overrule the default values of the Perl
constants.)

In addition the default value will also be added to the help text for
that option.  The additional text will be put into parentheses and
starts with the words C<defaults to>.  See below how to change that.

Note that all Perl constants with default values must be defined
before the C<use> command including this module, otherwise they have
no effect.  Also note that they must belong to the C<main::>
namespace.  And finally note that only simple values and array
references are supported yet.

=head1 CHANGING DEFAULT BEHAVIOUR

Some declarations looking like silly declarations (they all start with
a hyphen as the short option character) can change the behaviour of
the module.

=head2 separator ('->-' => '')

The separator is only needed if you don't have normal parameters and
your first option only comes in a long form, e.g. like in

    '->-' => '', 'long-optional-string:s' => 'optional string'

which produces the following help text:

    usage: script.pl [<options>] [--]

    options:  --long-optional-string [<string>]
                  optional string

Instead of the separator any of the other behavior changing
declarations will have the same effect.

=head2 changing the help option ('->help' => 'H>Hilfe')

With C<-E<gt>help> you can replace the default names C<h> (as short
option) and C<help> (as long option) of the help options.  The value
part of this declaration must contain the new short option character
followed by C<E<gt>> followed by the long option (without C<-->) as in
a normal boolean option declaration.

Note that C<-?> will always remain as help option as well and can not
be renamed or removed!

=head2 changing the debug option ('->debug' => 'verbose')

With C<-E<gt>debug> you can replace the default (long option) name
C<debug> of the debug option.  (Remember that the module prints all
options on STDERR if a long option called C<debug> is declared and
set.)  The value part of this declaration is just the new long option
name (without C<-->).

Note that the debugging option still has to be declared as normal
option as well.

=head2 changing the usage text ('->usage' => 'use as')

With this modifying option you can replace the text C<usage> at the
beginning of the help text with the string specified in the value part
of this declaration.

Note that the variable used for the help text is still called
C<$optUsage>.

=head2 changing the options text ('->options' => 'switches')

With this modifying option you can replace the text C<options> in the
help text with the string specified in the value part of this
declaration.  Note that the string occurs two times.

Due to the way the help text is constructed this option has to be
specified before the first normal option of the import (use)
statement!

=head2 changing the default value text ('->default' => ' (init. %s)')

With this modifying option you can replace the text appended for
options with default values set by Perl constant (C< (defaults to
%s)>) in the help text with the string specified in the value part of
this declaration.  Note that the string must contain a C<%s> as it is
put together with C<sprintf> (see L<perldoc/sprintf>).  You may also
set this modifying option to C<undef> to disable the additional help
text.

Due to the way the help text is constructed this option has to be
specified before the first normal option of the import (use)
statement!

=head2 enabling multiple support ('->multiple' => ...)

This neat modifying option gives you support to process multiple
occurances of the same option.  It comes in two flavours, depending on
the value part of the declaration:

=head3 multiple support using concatenation ('->multiple' => 'text')

With this flavour multiple occurances of the same option are (sort of)
concatenated.  The kind of C<concatenation> depends on the type of the
option: string options are concatenated (joined) with the given text
put between each occurance, integers and floats are added together and
boolean are just counted.

If you take the following example declaration of import parameters

    '->multiple' => ', ',
    'd>directory=s directory' => 'name of the directory',
    'o>offset:f' => 'offset in the file in % (default 0.0)'

and call the script using them with a command line like:

    -d a --offset -o=0.25 -d b -d=c -o=0.33

Now your option variable C<$opt_directory> will be set to C<a, b, c>
and your option variable C<$opt_offset> will be set to the value 0.58
(0.0 + 0.25 + 0.33).

Note that an empty string is a valid input for this flavour of
multiple occurances, the strings then are just concatenated without
anything between them.

=head3 multiple support using arrays ('->multiple' => undef)

With this flavour (yes, this one uses an explicit C<undef> value to
distinguish it from the last one) each option passed more than once
will not be returned in a normal scalar variable but in a reference to
an array.

For example take the declaration from the C<concatenation> flavour and
just replace the value part C<', '> with C<undef>.  If you use this
with the following options on your command line:

    -d a -o 0.25 --directory=b

This time your option variable C<$opt_offset> will be a scalar with
the value 0.25 but the option variable C<$opt_directory> will be a
reference to an array containing the values C<a> and C<b> (in that
sequence).

It is up to you to handle the different variable types adequately!
(But it is guaranteed that a C<ref> will either return C<''> or
C<'ARRAY'>.)

=head2 multiple per option support using arrays

A third method to support multiple options, again as arrays but only
for selected options works by slightly modifying their import
parameter key using a double C<E<gt>E<gt>>.  So suppose you have the
following import parameters (without any C<-E<gt>multiple> option at
all):

    'd>>directory=s directory' => 'name of the directory',
    'o>offset:f' => 'offset in the file in % (default 0.0)'

If you now call your script with

    -d a -o0.25 --directory=b -o0.5

you'll end up with the value 0.5 in C<$opt_offset> and a reference to
an array with C<a> and C<b> in C<$opt_directory>.  So this gives you
an easy way to enable multiple option support just for selected
options easing the overhead for analysing all of them to be possible
array references.

For long options (without a character for a short option) you just
start them with the double C<E<gt>E<gt>>.

Multiple options as string on a per-option-base is not supported, but
you can get that with short statement like the following:

    $opt_directory = join(' ', @$opt_directory)
        if ref($opt_directory) eq 'ARRAY';

=head1 FUNCTIONS

=cut

#########################################################################

use 5.006;
use strict;
use warnings;

use Carp;
use File::Basename;
use Getopt::Long qw(:config posix_default no_ignore_case bundling_override
);
# debug);

#******************************************************************

use vars '$optUsage';

our $VERSION = '0.26';

# default strings (they are the ones used for indent!):
use constant DEFAULT_USAGE => 'usage';
use constant DEFAULT_OPTIONS => 'options';
use constant DEFAULT_DEFAULT => ' (defaults to %s)';

#########################################################################

=head2 B<import> - main and only function

see above in the main documentation how to use it

One confession about the internals, this function doesn't use a real
hash; it just uses the same syntax as it really expects an array of
pairs (as most of you might have guessed already ;-).

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub import
{
    local $_;
    my $this = shift;
    croak 'bad usage of ', __PACKAGE__ unless $this eq __PACKAGE__;
    croak 'no parameter passed to ', __PACKAGE__ unless 0 < @_;
    croak 'unbalanced parameter list passed to ', __PACKAGE__
	unless @_ % 2 == 0;
    my %env = %ENV;

    my $usage_text = DEFAULT_USAGE;
    my $options_text = DEFAULT_OPTIONS;
    my $indent_opt1 = $options_text.':  ';
    my $indent_opt2 = ' ' x (length($options_text) + 3);
    my $indent_help = ' ' x (length($options_text) + 7);
    my $default_template = DEFAULT_DEFAULT;

    $optUsage = '';
    # check/support commandline parameters that are NOT options:
    my $has_only_options = 1;
    if ($_[0] =~ m/^.[^>].*$/ and $_[0] ne 'ENV' and $_[0] ne 'ENV_')
    {
	$optUsage .= ' '.(shift)."\n\n".(shift);
	$has_only_options = 0;
    }
    $optUsage .= "\n\n";

    my $help_long = 'help';
    my $help_opt_name = 'opt_help';
    my $help_options = 'help|h|?+';
    my $debug_opt_name = 'opt_debug';

    my @options = ();
    my @option_vars = ();
    my %default_value = ();
    my %option_type = ();
    my %optional_integers = ();
    my %optional_floats = ();
    my $max_length = 0;
    my $env_prefix = undef;
    my $use_multiple = 0;
    my $multiple = undef;
    my %multiple_options = ();
    my $package = (caller)[0];

    # preparation loop (module parameters):
    while (@_ > 0)
    {
	my $option = shift;
	if ($option =~
	    m/^(?:(\w)?>(>)?)?([-a-z0-9]{2,})(?:([:=][isf])\s*(.*))?$/)
	{
	    my ($short_option, $is_multiple, $long_option, $specifier,
		$opt_valtext) = ($1, $2, $3, $4, $5);
	    my $var = 'opt_'.$long_option;
	    $var =~ s/\W/_/g;
	    my $default_text = '';
	    {
		my $default_constant = 'DEFAULT_'.uc($long_option);
		$default_constant =~ s/\W/_/g;
		no strict 'refs';
		no warnings 'once';
		my $default_cref = *{$package.'::'.$default_constant}{CODE};
		if ( ref($default_cref) eq 'CODE')
		{
		    if (ref(&$default_cref) eq '')
		    {
			$default_text =
			    sprintf($default_template, &$default_cref);
		    }
		    elsif (ref(&$default_cref) eq 'ARRAY')
		    {
			$default_text =
			    sprintf($default_template,
				    join(', ', @{&$default_cref}));
		    }
		    else
		    {
			croak(ref(&$default_cref), ' constants as ',
			      'default values are not yet supported in ',
			      __PACKAGE__);
		    }
		    $default_value{$var} = &$default_cref;
		}
	    }
	    $specifier = '' unless defined $specifier;
	    if ($opt_valtext  and  $specifier =~ m/^=/)
	    {
		if ($opt_valtext =~ m/^{.*}$/)
		{
		    $opt_valtext = ' '.$opt_valtext;
		}
		else
		{
		    $opt_valtext = ' <'.$opt_valtext.'>';
		}
	    }
	    elsif ($opt_valtext  and  $specifier =~ m/^:/)
	    {
		$opt_valtext = ' [<'.$opt_valtext.'>]';
	    }
	    elsif ($specifier =~ m/^=/)
	    {
		$opt_valtext = ($specifier =~ m/i$/ ? ' <integer>' :
				$specifier =~ m/s$/ ? ' <string>' :
				$specifier =~ m/f$/ ? ' <float>' : ' <???>');
	    }
	    elsif ($specifier =~ m/^:/)
	    {
		$opt_valtext = ($specifier =~ m/i$/ ? ' [<integer>]' :
				$specifier =~ m/s$/ ? ' [<string>]' :
				$specifier =~ m/f$/ ? ' [<float>]' :
				' [<???>]');
	    }
	    elsif (defined $opt_valtext)
	    {
		die 'internal inconsistency: specifierless value text in ',
		    $option
		}
	    else
	    {
		$opt_valtext = '';
	    }
	    $optUsage .= 0 == @option_vars ? $indent_opt1 : $indent_opt2;
	    $optUsage .= '-'.$short_option.'|' if defined $short_option;
	    $optUsage .= '--'.$long_option.$opt_valtext."\n";
	    $optUsage .= $indent_help.(shift).$default_text."\n";
	    my $option_key = $long_option;
	    $option_key .= '|'.$short_option if defined $short_option;
	    # fix default numeric values of optional integer parameters:
	    $option_key .= $specifier eq ':i' ? ':+' : $specifier;
	    {
		no strict 'refs';
		push @options, $option_key, *{$var}{SCALAR};
	    }
	    push @option_vars, $var;
	    $option_type{$var} = $specifier;
	    $option_type{$var} =~ s/[:=]//;
	    $max_length = length($var) if $max_length < length($var);
	    if ($is_multiple)
	    {
		croak('multiple option support per option and per global',
		      ' flag is mutually exclusive in ', __PACKAGE__)
		    if $use_multiple;
		$options[-2] .= '@';
		$multiple_options{$var} = $long_option;
	    }
	    # Undefined optional options must be defaulted to undef to
	    # distinguish them from the default value "empty string":
	    if ($specifier =~ m/^:i$/)
	    {
		$optional_integers{$var} = 1;
	    }
	    elsif ($specifier =~ m/^:f$/)
	    {
		$optional_floats{$var} = 0.0;
	    }
	}

	elsif ($option =~ m/^\(.+\)$/)
	{
	    $optUsage .= "\n".(shift)."\n";
	}
	elsif ($option eq '->-')
	{
	    shift;
	}
	elsif ($option eq '->debug')
	{
	    $_ = shift;
	    m/^([-a-z0-9]{2,})$/i  or
		croak 'bad renaming of debug in ', __PACKAGE__;
	    $debug_opt_name = 'opt_'.$1;
	}
	elsif ($option eq '->default')
	{
	    $_ = shift;
	    m/%s/i  or
		croak 'default text must contain %s in ', __PACKAGE__;
	    $default_template = $_;
	}
	elsif ($option eq '->help')
	{
	    $_ = shift;
	    m/^(\w)>([-a-z0-9]{2,})$/i  or
		croak 'bad renaming of help in ', __PACKAGE__;
	    $help_long = $2;
	    $help_opt_name = 'opt_'.$2;
	    $help_options = $2.'|'.$1.'|?+';
	}
	elsif ($option eq '->multiple')
	{
	    croak('multiple option support per option and per global',
		  ' flag is mutually exclusive in ', __PACKAGE__)
		if 0 < (my @list = %multiple_options);
	    $use_multiple = 1;
	    $multiple = shift;
	}
	elsif ($option eq '->options')
	{
	    $options_text = shift;
	    $indent_opt1 = $options_text.':  ';
	    $indent_opt2 = ' ' x (length($options_text) + 3);
	    $indent_help = ' ' x (length($options_text) + 7);
	}
	elsif ($option eq '->usage')
	{
	    $usage_text = shift;
	}
	elsif ($option eq 'ENV')
	{
	    $env_prefix = shift;
	}
	elsif ($option eq 'ENV_')
	{
	    $env_prefix = shift;
	    if (defined $env{$env_prefix.'_'})
	    {
		foreach (split(/\s+/, $env{$env_prefix.'_'}))
		{
		    s/^([-_a-z0-9]{2,})=?//;
		    (my $env_var = $env_prefix.uc($1)) =~ tr/-/_/;
		    $env{$env_var} = $_ ne '' ? $_ : 1
			unless defined $env{$env_var};
		}
	    }
	}
	else
	{
	    croak 'bad option ', $option, ' passed to ', __PACKAGE__;
	}
    }
    # for global multiple set-up using arrays:
    if ($use_multiple)
    {
	for ($_ = 0; $_ < $#options; $_ += 2)
	{
	    $options[$_] =~ s/:\+/:i/;
	    if ($options[$_] =~ m/[:=][fis]$/)
	    {
		$options[$_] .= '@';
	    }
	    else
	    {
		$options[$_] .= ':+';
	    }
	}
    }
    # finish help text:
    $optUsage =
	$usage_text.': '.basename($0).' [<'.$options_text.'>] [--]'.$optUsage;

    {
	no strict 'refs';
	unshift @options, $help_options, *{$help_opt_name}{SCALAR};
    }
    unless (GetOptions(@options))
    {
	$_ = $0;
	s|.*/||;
	print STDERR "Try `$_ --$help_long' for more information.\n";
	exit 1;
    }

    no strict 'refs';
    no warnings 'once';
    if ($$help_opt_name  or  ($has_only_options  and  0 <= $#ARGV))
    {
	print STDERR $optUsage; exit -1;
    }

    # handle concatenated multiples:
    if ($use_multiple)
    {
	if (defined $multiple)
	{
	    foreach my $option (@option_vars)
	    {
		next unless defined $$option;
		next unless ref($$option) eq 'ARRAY';
		if ($option_type{$option} eq 's')
		{
		    $$option = join($multiple, @$$option);
		}
		elsif ($option_type{$option} eq 'i'  or
		       $option_type{$option} eq 'f')
		{
		    my $sum = 0;
		    $sum += $_ foreach @$$option;
		    $$option = $sum;
		}
		else
		{
		    die 'internal inconsistency: $option_type{$option} is ',
			$option_type{$option};
		}
	    }
	}
	# support for multiple options, array flavour:
	else
	{
	    foreach my $option (@option_vars)
	    {
		next unless $option_type{$option} eq '';
		next	    # paranoia check, this should never occur!
		    if ref($$option) ne '';
		next if $$option == 1;
		$_ = [ (1) x $$option ];
		$$option = $_;
	    }
	}
    }

    # get defaults from environment, if applicable:
    if (defined $env_prefix)
    {
	# set default values, if not overwritten:
	foreach (@option_vars)
	{
	    next if defined $$_;
	    my $env_var = $env_prefix.uc(substr($_, 4));
	    $$_ = $env{$env_var} if defined $env{$env_var};
	}
    }

    # get defaults from constants:
    foreach (keys %default_value)
    {
	next if defined $$_;
	$$_ = $default_value{$_};
    }

    # declare main option variables and export local option variables to it:
    *{$package.'::optUsage'} = \$optUsage;
    {
	no warnings "once"; # disable "GMH::opt_ ... used only once" warning
	foreach (@option_vars)
	{
	    # single element arrays become scalars instead:
	    if (ref($$_) eq 'ARRAY' and 1 == @$$_)
	    {
		*{$package.'::'.$_} = \$$_->[0];
	    }
	    else
	    {
		*{$package.'::'.$_} = \$$_;
	    }
	}
    }

    # print debug info, if $opt_debug is used:
    if ($$debug_opt_name)
    {
	print STDERR $indent_opt1, "\n";
	foreach (@option_vars)
	{
	    print(STDERR
		  $indent_opt2, '$', $_, ':',
		  (' ' x ( $max_length - length($_) + 1 )),
		  (! defined $$_ ? 'undef' :
		   ref($$_) eq 'ARRAY'
		   ? '('.join(', ', @$$_).')'
		   : $$_ =~ m/^-?\d+(?:\.\d+)?$/ ? $$_ : '"'.$$_.'"'),
		  "\n");
	}
	print STDERR "parameter:\n" if @ARGV;
	print STDERR $indent_opt2,
	    ($_ =~ m/^-?\d+(?:\.\d+)?$/ ? $_ : '"'.$_.'"'), "\n"
		foreach (@ARGV);
    }
}
1;

#******************************************************************

__END__

=head1 KNOWN BUGS

The ones from L<C<Getopt::Long>> and maybe some more.  Tell me, if
you find one.

Getopt::Mixed::Help used to support setting short options using C<=>,
e.g. C<test_script -d -v=2>.  This no longer works as it this was a
feature of the underlying L<C<Getopt::Mixed>> which does not exist in
L<C<Getopt::Long>>.

=head1 SEE ALSO

L<C<Getopt::Long>>,
L<C<Getopt::Mixed>>

The tests for this module were checked with L<C<Devel::Cover>> to make
sure it is throughly tested.  I highly recommend this module to
others, it helped to find quirks that otherwise would have gone
unnoticed!

=head1 AUTHOR

Thomas Dorner, E<lt>dorner (AT) cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2012 by Thomas Dorner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
