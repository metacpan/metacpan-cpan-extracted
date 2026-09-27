package Getopt::Pad;

use v5.26;
use strict;
use warnings;

use experimental 'signatures';

use Exporter qw(import);
use Feature::Compat::Try;
use Scalar::Util qw(blessed);

use Getopt::Pad::Util ();
use Getopt::Pad::Spec;
use Getopt::Pad::Parser;
use Getopt::Pad::Completion;
use Getopt::Pad::Error;
use Getopt::Pad::ExitRequest;

our $VERSION = '0.04';
our @EXPORT  = qw(GetOptions);

sub GetOptions(%raw) {
	my $argv = delete $raw{argv} // [@ARGV];
	Getopt::Pad::Util::specError("'argv' must be an array reference") if ref $argv ne 'ARRAY';

	my $spec = Getopt::Pad::Spec->new(raw => \%raw);

	# A generated completion script asking for candidates: answer it
	# instead of parsing.
	if (defined $ENV{Getopt::Pad::Completion->SHELL_VARIABLE}) {
		print Getopt::Pad::Completion->new(spec => $spec)->renderCandidates($argv, $ENV{Getopt::Pad::Completion->INDEX_VARIABLE});
		exit 0;
	}

	my $parser = Getopt::Pad::Parser->new(spec => $spec, argv => $argv);

	try {
		return $parser->parse;
	}
	catch ($error) {
		if (blessed($error) && $error->isa('Getopt::Pad::ExitRequest')) {
			print $error->output;
			exit 0;
		}
		die $error if !blessed($error) || !$error->isa('Getopt::Pad::Error');

		my $errorTag = Getopt::Pad::Util::useColor(\*STDERR) ? "\e[1;31mERROR\e[0m" : 'ERROR';
		print {*STDERR} sprintf("%s: %s\n", $errorTag, $error);
		if (defined $error->level) {
			print {*STDERR} "\n";
			$spec->helperFor($error->level, handle => \*STDERR)->printHelp;
		}
		exit 2;
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad - Declarative command line parsing with types, subcommands and
config files

=head1 SYNOPSIS

=for highlighter language=perl

    use v5.26;
    use Getopt::Pad;

    my $opt = GetOptions(
        description => 'Copy a directory to a backup location.',
        options     => {
            'target|t' => {
                type     => 'dir',
                required => 1,
                help     => 'Directory the backup is written to',
            },
            'keep' => {
                type    => 'int',
                default => 7,
                min     => 1,
                help    => 'Number of backups to keep',
            },
            'exclude|x' => {
                type     => 'string',
                multiple => 1,
                help     => 'Pattern of files to skip; repeat for more patterns',
            },
            'compress' => {
                type    => 'bool',
                default => 1,
                help    => 'Compress the backup; --no-compress turns it off',
            },
            'verbose|v' => {
                type => 'counter',
                help => 'Print more details; repeat for even more (-vv)',
            },
        },
        args => [
            { short => 'source', type => 'dir', required => 1, help => 'Directory to back up' },
        ],
    );

    # backup -t /mnt/backup -x '*.tmp' -x '*.log' -vv --no-compress photos
    say $opt->source;                        # photos
    say $opt->target;                        # /mnt/backup
    say $opt->keep;                          # 7 (the default)
    say join ', ', $opt->exclude->@*;        # *.tmp, *.log
    say $opt->compress ? 'yes' : 'no';       # no
    say $opt->verbose;                       # 2

=head1 DESCRIPTION

Getopt::Pad parses the command line of a Perl program. You describe the
command line once, as a data structure called the I<spec>: it names every
option and positional argument, and can give each one a type, a default
value, a list of allowed values and a help text. C<GetOptions> reads
C<@ARGV> according to that spec, checks every value, and returns an object
with one method per option and argument. C<--log-level debug> becomes C<<
$opt->logLevel >>, which returns C<'debug'>.

From the same spec, Getopt::Pad also provides:

=over 4

=item * B<Typed values.> Strings, integers, floats, file and directory
paths, URLs, flags, negatable booleans and counters, with bounds,
existence checks, lists of allowed values and custom checks. You can add
your own types. See L</TYPES>.

=item * B<Value shapes.> An option can hold one value, a list of values
(C<--tag a --tag b>, or C<--tag a,b>), a mapping (C<--define os=linux>)
or a list of records (C<--server 0.host=a --server 0.port=80>). See
L</multiple>, L</csv>, L</hash> and L</objectlist>.

=item * B<Subcommands.> A command line like C<tool image resize --width
640> is described by nesting specs. Every command has its own options,
arguments and help. See L</COMMANDS>.

=item * B<Config files.> Option values can also come from YAML or JSON
files, for every command, with the precedence command line, then config
file, then default. You can add other file formats. See L</CONFIG FILES>.

=item * B<Generated help.> C<--help> prints a formatted usage text,
wrapped to the terminal width and colored on a terminal. C<--version>
prints the program version. See L</HELP OUTPUT>.

=item * B<Shell completion.> C<--create-completions bash> (or C<zsh>)
prints a completion script that completes commands, options, allowed
values and paths. See L</SHELL COMPLETION>.

=item * B<Clear errors.> A wrong command line prints the specific problem
and the help text, and exits with status 2. A mistake in the spec itself
makes C<GetOptions> die immediately with a message that points at your
C<GetOptions> call. See L</ERRORS AND EXIT STATUS>.

=back

=head2 How this documentation is organized

=over 4

=item L<Getopt::Pad::Tutorial>

A step-by-step introduction. Start here if you have not used Getopt::Pad
before.

=item L<Getopt::Pad::Cookbook>

Short recipes for common tasks, such as "Repeating an option (multiple)"
or "Options for all commands (inherit)". Each recipe shows the spec, a
command line and the result.

=item Getopt::Pad (this page)

The complete reference: every spec key, every type, the command line
syntax, config files, help output, completion and all error messages.

=item L<Getopt::Pad::Result>

The object C<GetOptions> returns.

=item L<Getopt::Pad::Type>

How to write your own option types.

=item L<Getopt::Pad::Config::Format>

How to support another config file format.

=back

The distribution also contains runnable example scripts in its
F<examples/> directory, see L</EXAMPLES>.

=head2 Sections of this page

=over 4

=item L</TERMINOLOGY> and L</QUICK REFERENCE>

The terms used here, and one table per kind of key.

=item L</FUNCTIONS>, L</SPEC KEYS>, L</OPTION SPECS>, L</ARG SPECS>, L</TYPES>

Everything you can write in a spec.

=item L</COMMAND LINE SYNTAX>, L</COMMANDS>, L</VALUES AND PRECEDENCE>

How the command line is read, and where values come from.

=item L</CONFIG FILES>, L</AUTOMATIC OPTIONS>, L</HELP OUTPUT>, L</SHELL COMPLETION>

What Getopt::Pad adds to a program by itself.

=item L</RESULT OBJECT>

What C<GetOptions> returns.

=item L</ERRORS AND EXIT STATUS>, L</DIAGNOSTICS>

What happens when something is wrong, and every message.

=item L</ENVIRONMENT>, L</EXTENDING>, L</EXAMPLES>, L</CAVEATS>, L</REQUIREMENTS>

Everything else.

=back

=head1 TERMINOLOGY

Terms used throughout this documentation:

=over 4

=item spec

The arguments you pass to C<GetOptions>: a list of key/value pairs that
describes the whole command line.

=item option

A named switch on the command line, such as C<--verbose> or
C<--log-level debug>. Options are declared under the C<options> key.

=item primary name, alias

An option is declared with one or more names separated by C<|>, such as
C<'owner|o'>. The first name (C<owner>) is the I<primary name>. It names
the reader and is shown in the help output. The other names (C<o>) are
I<aliases>: the command line accepts them and shell completion offers
them, but readers and the help output use only the primary name.

=item arg

A positional argument: a word on the command line that is not an option,
such as the file name in C<tool --verbose notes.txt>. Args are declared
in order under the C<args> key. Error messages about args call them
I<argument> (C<missing required argument E<lt>sourceE<gt>>). In the
messages C<Option NAME requires an argument> and C<Option NAME does not
take an argument>, which come from L<Getopt::Long>, "argument" means the
value of an option instead.

=item command, subcommand

A named mode of a program, selected by a word on the command line (the
I<command name>), such as C<resize> in C<tool resize --width 640>.
Commands are also known as I<subcommands>. Each command has a I<command
spec> under the C<commands> key, and commands can be nested.

=item level

The top level of the spec, or one command. Every level has its own
options and either args or commands. C<tool image resize> involves three
levels: the top level, the command C<image> and the command C<image
resize>.

=item command path

The command words that lead to a level, separated by spaces, such as
C<image resize>. The top level has an empty command path. Help output and
error messages identify commands by their command path.

=item option group

The heading an option is listed under in the help output, set with the
C<group> key. The same name is used as a section of config files.
Options without a C<group> are in the group C<Options>.

=item reader

A method of the result object that returns the value of one option or arg
(a getter), such as C<< $opt->logLevel >> for the option C<log-level>. See
L</Reader names>.

=item result object

The object C<GetOptions> returns. There is one result object per level
that the command line selects; each one holds the result object of the
next level as its C<subcommand>. See L</RESULT OBJECT>.

=item value source

Where the value of an option comes from: the command line, a config
file, or the default in the spec. See L</VALUES AND PRECEDENCE>.

=item automatic option

An option that Getopt::Pad adds by itself, such as C<--help>. See
L</AUTOMATIC OPTIONS>.

=item inherited option

An option that is declared on one level and also accepted on the command
line of every level below it. See L</inherit>.

=item config block

The C<config> key of the spec, which enables config files. See
L</CONFIG FILES>.

=item user error, spec error

A I<user error> is a mistake on the command line or in a config file. It
is reported to the user, and the program exits with status 2. A I<spec
error> is a mistake in the spec, that is, in your program. It makes
C<GetOptions> die. See L</ERRORS AND EXIT STATUS>.

=back

=head1 QUICK REFERENCE

Each key below links to its full description.

=head2 Spec keys

=for highlighter language=plain

    Key              Allowed on       Value
    ---------------  ---------------  ---------------------------------------
    options          every level      hashref: option key => option spec
    args             every level      arrayref of arg specs
    commands         every level      hashref: command name => command spec
    commandRequired  levels with      boolean, default true
                     commands
    description      every level      string
    examples         every level      arrayref of { text => ..., args => ... }
    config           top level only   hashref, see the config block keys
    version          top level only   string, default $main::VERSION
    argv             top level only   arrayref of words, default @ARGV

See L</options>, L</args>, L</commands>, L</commandRequired>,
L</description>, L</examples>, L</config>, L</version> and L</argv>.

=head2 Option spec keys

=for highlighter language=plain

    Key                  Value                  Default    Notes
    -------------------  ---------------------  ---------  ------------------------------
    type                 type name              'flag'     see TYPES
    required             boolean                false      not with default
    default              value in the           none       not with required
                         option's shape
    help                 string                 ''
    group                string                 'Options'
    hidden               boolean                false
    valid                arrayref or coderef    none       allowed values
    lazyValid            coderef                none       custom check
    multiple             boolean                false      value-taking types only
    csv                  boolean                false      requires multiple
    hash                 boolean                false      value-taking types only
    objectlist           boolean                false      value-taking types only
    inherit              boolean                false      levels with commands only
    typehint             string                 type's     label shown in the help
    min, max             number                 none       int and float only
    mustExist            boolean                false      file and dir only
    createPathIfMissing  boolean                false      file and dir only

See L</OPTION SPECS>. C<multiple>, C<hash> and C<objectlist> exclude each
other. C<mustExist> and C<createPathIfMissing> exclude each other.

=head2 Arg spec keys

=for highlighter language=plain

    Key                  Value      Default    Notes
    -------------------  ---------  ---------  -------------------------------
    short                name       -          mandatory, names the reader
    type                 type name  'string'   value-taking types only
    required             boolean    false      required args come first
    multiple             boolean    false      last arg only, takes the rest
    help                 string     ''
    typehint             string     type's     label shown in the help
    min, max             number     none       int and float only
    mustExist            boolean    false      file and dir only
    createPathIfMissing  boolean    false      file and dir only

See L</ARG SPECS>.

=head2 Config block keys

=for highlighter language=plain

    Key          Value            Default  Notes
    -----------  ---------------  -------  -----------------------------------
    format       format name      -        mandatory: 'yaml', 'yml' or 'json'
    paths        arrayref         []       files loaded automatically, in order
    defaultPath  path             none     loaded by a bare --config
    autoload     boolean          true     load 'paths' when --config is absent

See L</CONFIG FILES>.

=head2 Type names

=for highlighter language=plain

    Type names                   Command line         Reader value
    ---------------------------  -------------------  -------------------------
    flag (default for options)   --name               1, or undef when absent
    bool, boolean, !             --name, --no-name    1 or 0, undef when absent
    counter, count, +            --name --name, -nn   times given, or undef
    string, str, s (default      --name VALUE         the string
      for args)
    int, integer, i              --name 42            number
    float, num, number, f        --name 1.5           number
    file                         --name PATH          the path
    dir, directory               --name PATH          the path
    url, uri                     --name URL           the URL

See L</TYPES>.

=head1 FUNCTIONS

=head2 GetOptions

=for highlighter language=perl

    my $opt = GetOptions(%spec);

C<GetOptions> is exported by default. It takes the spec as a list of
key/value pairs (see L</SPEC KEYS>), parses the command line and returns
the result object of the top level (see L</RESULT OBJECT>).

It returns only when the command line is valid. In every other case it
ends the program itself:

=over 4

=item *

On a user error, it prints the error message and the help text of the
affected level to STDERR and exits with status 2.

=item *

When the command line contains an automatic option such as C<--help>,
C<--version>, C<--create-completions> or C<--create-default-config>, it
prints that option's output to STDOUT and exits with status 0.

=item *

When a generated shell completion script calls the program (see
L</SHELL COMPLETION>), it prints the completion candidates and exits with
status 0.

=back

Before it looks at the command line, C<GetOptions> checks the whole
spec. A mistake in the spec, such as an unknown key or an invalid
default, makes it C<die> with a spec error (see
L</ERRORS AND EXIT STATUS>).

C<GetOptions> reads C<@ARGV> unless you pass the words to parse with the
L</argv> key. It never modifies C<@ARGV>.

=head1 SPEC KEYS

A spec is a list of key/value pairs. The top level of a spec and the spec
of every command (see L</commands>) accept the keys L</options>,
L</args>, L</commands>, L</commandRequired>, L</description> and
L</examples>. The keys L</config>, L</version> and L</argv> are accepted
on the top level only. Any other key is a spec error.

=head2 options

=for highlighter language=perl

    options => {
        'log-level' => { type => 'string', default => 'info' },
        'verbose|v' => { type => 'counter' },
    },

A hashref that maps option keys to option specs. The key is the option's
name, optionally followed by aliases separated by C<|>. The value is a
hashref describing the option, see L</OPTION SPECS>.

=head2 args

=for highlighter language=perl

    args => [
        { short => 'source', required => 1 },
        { short => 'target' },
    ],

An arrayref of arg specs, one per positional argument, in command line
order. See L</ARG SPECS>. A level cannot have both C<args> and
C<commands>.

=head2 commands

=for highlighter language=perl

    commands => {
        add    => { args => [{ short => 'name', required => 1 }] },
        remove => { args => [{ short => 'name', required => 1 }] },
    },

A hashref that maps command names to the spec of that command. A command
spec accepts the same keys as the top level, except C<config>,
C<version> and C<argv>, so commands can have commands of their own. A
command name must start with a letter, followed by letters, digits,
underscores or dashes. See L</COMMANDS> for how commands are parsed and
read.

=head2 commandRequired

=for highlighter language=perl

    commandRequired => 0,

On a level with commands, whether the command line must name one of them.
The default is true: a missing command is a user error ("missing
command"). With a false value, the command word may be left out; the
level's C<command> and C<subcommand> methods then return C<undef>, and
there is no result object for a command. Using C<commandRequired> on a
level without commands is a spec error.

=head2 description

=for highlighter language=perl

    description => 'Copy a directory to a backup location.',

A one-line description of the program or command. It is shown in the
second line of the help output. The description of a command is also
shown next to the command's name in the C<Commands> section of the
parent level's help output.

=head2 examples

=for highlighter language=perl

    examples => [
        { text => 'Back up your photos', args => '--target /mnt/backup ~/photos' },
    ],

An arrayref of usage examples shown at the end of the help output. Each
example is a hashref with the keys C<text> (a short explanation) and
C<args> (the command line after the program name and command path, as a
single string). Both keys are mandatory. The help output shows the
example as:

=for highlighter language=plain

    # Examples:
    ## Back up your photos
    ##   backup --target /mnt/backup ~/photos

=head2 config

=for highlighter language=perl

    config => {
        format      => 'yaml',
        paths       => ['/etc/backup.yaml', '~/.backup.yaml'],
        defaultPath => '~/.backup.yaml',
    },

Enables config files. The value is a hashref with the keys C<format>
(mandatory), C<paths>, C<defaultPath> and C<autoload>. It also adds the
automatic options C<--config> and C<--create-default-config>. See
L</CONFIG FILES>. Top level only.

=head2 version

=for highlighter language=perl

    version => '1.2.0',

The version string that the automatic C<--version> option prints, as
C<PROGRAM VERSION> (for example C<backup 1.2.0>). Without this key,
C<--version> prints the value of C<$main::VERSION>, that is, the
C<our $VERSION> of your script, or C<unknown> when that is not set. Top
level only.

=head2 argv

=for highlighter language=perl

    argv => ['--verbose', 'input.txt'],

An arrayref of words to parse instead of C<@ARGV>. C<GetOptions> copies
the words; neither C<@ARGV> nor this arrayref is modified. This is useful
for tests (see L<Getopt::Pad::Cookbook/Testing a command line>) and for
parsing a command line that does not come from C<@ARGV>. Top level only.

=head1 OPTION SPECS

Every entry under L</options> has a key and a spec:

=for highlighter language=perl

    options => {
        'log-level|l' => {                 # key: primary name and aliases
            type    => 'string',           # spec: a hashref of the keys below
            default => 'info',
            valid   => ['debug', 'info', 'warn', 'error'],
            help    => 'How much to log',
        },
    },

An option spec is a hashref. An empty hashref (C<< verbose => {} >>)
declares a plain flag. Any key not described in this section is a spec
error, except the type-specific keys listed under L</Type-specific keys>.

=head2 Option names and aliases

The option key is the primary name, optionally followed by aliases, all
separated by C<|>: C<'owner|o'> declares the option C<--owner> with the
alias C<-o>. Every name must start with a letter, followed by letters,
digits, underscores or dashes.

A name of one letter is a short option: it is written with one dash
(C<-o>) and can be bundled with other short options (C<-vo dave>). A
longer name is written with two dashes (C<--owner>). See
L</COMMAND LINE SYNTAX>.

Names are case sensitive: C<-v> and C<-V> are different options. A name
or alias may be used by only one option per level; an inherited option
reserves its names on every level below (see L</inherit>).

=head2 Reader names

The reader of an option is named after its primary name, converted to
camelCase: the name is split at dashes and underscores, and every part
after the first starts with an upper case letter. The first part stays
as it is.

=for highlighter language=plain

    Option or arg name   Reader
    -------------------  ----------------
    verbose              $opt->verbose
    log-level            $opt->logLevel
    dry_run              $opt->dryRun
    work-dir-path        $opt->workDirPath
    o                    $opt->o

Aliases have no readers. Two options or args of one level whose names map
to the same reader (C<work-dir> and C<work_dir>) are a spec error. A name
whose reader would be one of the methods every result object has is a
spec error too, see L</Reserved names>.

=head2 type

=for highlighter language=perl

    type => 'int',

The type of the option's value, by name. The name is case insensitive.
The default is C<flag>: an option without a C<type> takes no value. See
L</TYPES> for the built-in types and L<Getopt::Pad::Type> for adding your
own. An unknown type name is a spec error.

=head2 required

=for highlighter language=perl

    required => 1,

The option must be set, on the command line or in a config file. If
neither sets it, parsing stops with the user error C<missing required
option '--NAME'>. This works for flags as well: a required flag must be
given. A value from a config file satisfies C<required>. The help
output marks required options with C<[REQ]>. C<required> and L</default>
exclude each other.

=head2 default

=for highlighter language=perl

    default => 'info',              # a single value
    default => ['a', 'b'],          # multiple
    default => { os => 'linux' },   # hash
    default => [{ host => 'a' }],   # objectlist

The value the reader returns when neither the command line nor a config
file sets the option. The default must have the option's shape: a single
value, an arrayref for a L</multiple> option, a hashref for a L</hash>
option, or an arrayref of hashrefs for an L</objectlist> option.

The default is checked like a value from the command line (type,
L</valid>, L</lazyValid>, bounds) when C<GetOptions> builds the spec. An
invalid default is a spec error, even when the option is not used. The
reader returns the checked value, for example a number for an C<int>
option. Every parse gets its own copy of a list or mapping default, so
changing it does not affect later parses.

The help output shows the default in a C<Default> line.

C<< default => undef >> is allowed for single-value options and mostly
means the same as no default. There are two differences: a custom type's
C<prepare> method is called with C<undef> (see
L<Getopt::Pad::Type/prepare>), and C<--create-default-config> writes the
option into the file with an empty value (YAML C<~>, JSON C<null>),
which the program then rejects with C<no value given> when it reads the
file. Remove such lines from a generated file.

C<default> and L</required> exclude each other.

=head2 help

=for highlighter language=perl

    help => 'Number of backups to keep',

The help text shown next to the option in the help output. It is wrapped
to the terminal width automatically. Without it, the option is listed
with its name only.

=head2 group

=for highlighter language=perl

    group => 'Target',

The heading the option is listed under in the help output. Options
without a group are listed under C<Options>. The help output lists the
groups in alphabetical order.

The group is also the section of a config file that sets the option (see
L</File layout>). On a level with commands, a spec with a L</config>
block cannot use the group name C<commands>, because config files use
that key for the command sections.

=head2 hidden

=for highlighter language=perl

    hidden => 1,

The option works as usual, but it is not listed in the help output and
not offered by shell completion. Config files can still set it.

=head2 valid

=for highlighter language=perl

    valid => ['debug', 'info', 'warn', 'error'],        # a fixed list
    valid => sub { [ map { $_->name } list_users() ] },   # computed when needed

The values the option accepts: a fixed set of choices, like an enum.
Any other value is the user error
C<'VALUE' is not one of: ALLOWED, VALUES>. The comparison is an exact
string comparison (C<eq>) with the value after the type's conversion, so
for an C<int> option C<--port 080> is compared as C<80>.

The value is either an arrayref of the allowed values, or a coderef that
is called without arguments and returns such an arrayref. Use a coderef
for lists that are only known at run time, such as ids from a database
or file names in a directory. The coderef is called every time a value
is checked (once per value for options with several values), when
C<GetOptions> checks the option's L</default>, and on every shell
completion request for the option. It must return an arrayref; anything
else is a spec error.

The help output lists the allowed values in a C<Valid> line for an
arrayref, but not for a coderef. Shell completion offers the allowed
values in both cases. For options with several values (L</multiple>,
L</hash>, L</objectlist>), C<valid> applies to every single value (for
L</hash> and L</objectlist>: to the values, not to the keys).

=head2 lazyValid

=for highlighter language=perl

    lazyValid => sub { my ($value) = @_; $value =~ /\A[a-z][a-z0-9-]*\z/ },

Your own validation code, for constraints that cannot be written as a
list. Despite its name, C<lazyValid> is not a list of allowed values
computed later (a L</valid> coderef does that); it is a yes/no check.
The coderef is called with one value, after the type's conversion and after
the L</valid> check, and returns true to accept the value. A false
result is the user error C<'VALUE' is not a valid value>. For options with
several values, it is called once per value. C<lazyValid> is not used
for the help output or for shell completion.

If you want a more specific error message than "is not a valid value",
write a custom type instead (see L<Getopt::Pad::Type>), whose C<check>
method returns the message.

=head2 multiple

=for highlighter language=perl

    tag => { type => 'string', multiple => 1 },

The option may be given more than once. The reader returns an arrayref of
all values in command line order:

=for highlighter language=plain

    $ tool --tag red --tag blue     # $opt->tag is ['red', 'blue']
    $ tool                          # $opt->tag is []

When the option is not set anywhere and has no default, the reader
returns an empty arrayref, so C<< $opt->tag->@* >> is always safe. Every
value is checked on its own. A config file sets the option with a list or
a single value (see L</Values in config files>). C<multiple> needs a
value-taking type (not C<flag>, C<bool> or C<counter>) and excludes
L</hash> and L</objectlist>.

=head2 csv

=for highlighter language=perl

    tag => { type => 'string', multiple => 1, csv => 1 },

Accepts comma-separated lists: every value of a L</multiple> option is
split at commas, so a list can be given in one word. Whitespace around the
items is removed, and one trailing comma is ignored. An empty item is the
user error C<'VALUE' contains an empty item>.

=for highlighter language=plain

    $ tool --tag red,blue --tag green     # $opt->tag is ['red', 'blue', 'green']
    $ tool --tag 'red, blue,'             # $opt->tag is ['red', 'blue']
    $ tool --tag red,,blue                # error: contains an empty item

A single value in a config file is split the same way. A list in a config
file is taken as it is, without splitting its items. There is no way to
escape a comma. The help output shows the option as C<< --tag <a,b,...> >>.
C<csv> without C<multiple> is a spec error.

=head2 hash

=for highlighter language=perl

    define => { type => 'string', hash => 1 },

The option takes C<KEY=VALUE> words and the reader returns a hashref:

=for highlighter language=plain

    $ tool --define os=linux --define arch=x86     # {os => 'linux', arch => 'x86'}
    $ tool --define path=a=b                        # {path => 'a=b'}
    $ tool                                          # {}

The word is split at the first C<=>. Giving the same key again replaces
its value. A word without C<=> is a user error (C<Option define, key
"os", requires a value>), and so is an empty key. The values are checked
with the type, L</valid> and L</lazyValid>; the keys are not checked. When
the option is not set anywhere and has no default, the reader returns an
empty hashref.

A default is a hashref, and a config file sets the option with a mapping.
The value from the highest-priority value source replaces the others as
a whole: C<--define os=bsd> on the command line discards all keys from
the config file (see L</VALUES AND PRECEDENCE>). The help output shows
the option as C<< --define <key=value> >>. C<hash> needs a value-taking
type and excludes L</multiple> and L</objectlist>.

=head2 objectlist

=for highlighter language=perl

    server => { type => 'string', objectlist => 1 },

The option takes C<INDEX.FIELD=VALUE> words and the reader returns an
arrayref of hashrefs, one per index, ordered by index:

=for highlighter language=plain

    $ tool --server 0.host=alpha --server 0.port=80 --server 1.host=beta
    # $opt->server is [ { host => 'alpha', port => '80' }, { host => 'beta' } ]

INDEX is a number starting at 0. The indices used must be exactly 0 to
n-1, in any order; a gap is the user error C<missing index N>. FIELD
consists of letters, digits, underscores and dashes. A word without C<=>
is the user error C<Option server, key "WORD", requires a value>; a word
whose key does not have the form C<INDEX.FIELD> is the user error
C<invalid key 'KEY', expected INDEX.FIELD=VALUE>. Giving the same
C<INDEX.FIELD> again replaces its value. The values are checked with the
type (so the C<port> above stays a string for a C<string> option),
L</valid> and L</lazyValid>. When the option is not set anywhere and has
no default, the reader returns an empty arrayref.

A default is an arrayref of hashrefs, and a config file sets the option
with a list of mappings. The help output shows the option as
C<< --server <N.key=value> >>. C<objectlist> needs a value-taking type and
excludes L</multiple> and L</hash>.

=head2 inherit

=for highlighter language=perl

    GetOptions(
        options  => { 'verbose|v' => { type => 'counter', inherit => 1 } },
        commands => { scan => { ... }, report => { ... } },
    );

Makes the option available on every level below the one that declares
it, so it can be given before or after the command words:

=for highlighter language=plain

    $ tool -v scan        # both set $opt->verbose to 1
    $ tool scan -v

The value still belongs to the declaring level: read it from that
level's result object (here the top level's C<< $opt->verbose >>, not
C<< $opt->subcommand->verbose >>), and set it in that level's groups of a
config file.

If the option is given on several levels, the words are combined as if
they had all been given on the declaring level: for a single value the
last one wins, a L</multiple> option collects all values, a L</hash>
option merges the pairs, and a counter adds up (C<tool -v scan -v> gives
2).

The help output of every level below lists the option, and shell
completion offers it there. No level below may declare an option or
alias with one of its names. C<inherit> is allowed only on levels that
have commands; anywhere else it is a spec error.

=head2 typehint

=for highlighter language=perl

    typehint => 'Hostname',

Replaces the type label that the help output shows at the end of the
help text. C<< typehint => 'Hostname' >> renders as C<[Hostname]>. Only
the C<file>, C<dir> and C<url> types have a label of their own
(C<[File Path]>, C<[Path]> and C<[URL]>); for the other types,
C<typehint> adds a label where there was none. It must be a non-empty
string.

=head2 Type-specific keys

Some types accept additional keys in the option or arg spec. Using them
with another type is a spec error (C<unknown key(s)>).

=over 4

=item min, max

For C<int> and C<float>. The smallest and largest accepted value,
inclusive. Values outside are user errors (C<5 is smaller than the
minimum of 10>). Both must be numbers and C<min> must not be larger than
C<max>, or the spec is invalid.

=item mustExist

For C<file> and C<dir>. The path must exist when the command line is
parsed: an existing file (not a directory) for C<file>, an existing
directory for C<dir>. The help output marks the option with
C<[has to exist]>.

Like every check, C<mustExist> also applies to the L</default>, and
defaults are checked when C<GetOptions> builds the spec. A default path
that does not exist on the machine the program runs on therefore makes
C<GetOptions> die with a spec error, even when the command line gives
another path. Give a C<mustExist> option a default only if the path is
certain to exist.

=item createPathIfMissing

For C<file> and C<dir>. If the path does not exist, it is created: a
directory with all missing parent directories for C<dir>, an empty file
and its missing parent directories for C<file>. An existing path is left
alone. The help output marks the option with C<[created if missing]>.

The path is created after all checks of that value passed, and only for
the value that is finally used: a default is created only if neither
the command line nor a config file overrides it. Nothing is created for
C<--help> and the other automatic options, or for a shell completion
request. Values are processed one option at a time, so a path can
already have been created when a later option or arg of the same command
line turns out to be invalid. If the path cannot be created, that is a
user error (C<cannot create directory 'PATH': REASON>).

C<mustExist> and C<createPathIfMissing> exclude each other.

=back

=head1 ARG SPECS

Args are the words of the command line that are not options. Every
entry under L</args> describes one of them, in order:

=for highlighter language=perl

    args => [
        { short => 'source', type => 'dir', required => 1, help => 'Directory to copy' },
        { short => 'target', type => 'dir', help => 'Where to copy to' },
    ],

An arg spec is a hashref with these keys:

=over 4

=item short

Mandatory. The name of the arg. It names the reader (converted to
camelCase like option names, see L</Reader names>) and is shown in the
help output. Despite its name, it has nothing to do with short options:
args have no names on the command line. It must start with a letter,
followed by letters, digits, underscores or dashes.

=item type

The type of the value, by name (see L</TYPES>). The default is
C<string>. Types that take no value (C<flag>, C<bool>, C<counter>) are a
spec error. The type-specific keys L</min, max>, L</mustExist> and
L</createPathIfMissing> work as for options.

=item required

The arg must be given; a missing one is the user error C<missing required
argument E<lt>NAMEE<gt>>. Required args must come before optional ones.

=item multiple

Only allowed on the last arg. It makes a I<multiple arg>, which takes
all remaining words; its reader returns an arrayref (an empty arrayref
when there are none). With C<required>, at least one word is needed.
This is different from a L</multiple> option, which is given several
times.

=item help

The help text shown in the C<Arguments> section of the help output.

=item typehint

Replaces the type label in the help output, see L</typehint>.

=back

Args do not support C<default>, C<valid>, C<lazyValid>, C<hidden>,
C<group>, C<csv>, C<hash>, C<objectlist> or C<inherit>. An optional arg
that is not given reads as C<undef>. Words left over after the last arg
are the user error C<unexpected extra argument 'WORD'>. A level without
C<args> accepts no positional words at all.

Args are checked with their type, including C<mustExist>, the bounds and
C<createPathIfMissing>. They cannot be set in config files.

=head1 TYPES

The type of an option or arg decides whether it takes a value, how the
value is checked and converted, and what the reader returns. Most types
have several names; they are interchangeable and case insensitive.

Types that take no value (C<flag>, C<bool>, C<counter>) can be used for
options only. All other types take a value and can be used for options
and args.

=head2 flag

Names: C<flag>. The default type of options.

A switch without a value: C<--dry-run>. The reader returns 1 when the
option is given and C<undef> when it is not (unless there is a default).
A flag cannot be turned off on the command line; use C<bool> if you need
that. In config files a flag accepts C<true>, C<false>, 1 and 0 (see
L</Values in config files>); C<false> and 0 read as 0.

=head2 bool

Names: C<bool>, C<boolean>, C<!>.

A switch that can be negated: C<--color> sets it to 1, C<--no-color>
(or C<--nocolor>) sets it to 0. The last one given wins. The reader
returns C<undef> when the option is not set anywhere and has no default.
It is typically combined with C<< default => 1 >> or C<< default => 0 >>.
The help output shows the option as C<--[no-]color>. In config files it
accepts C<true>, C<false>, 1 and 0 (see L</Values in config files>).

=head2 counter

Names: C<counter>, C<count>, C<+>.

A switch that counts how often it is given: C<-v -v -v>, C<-vvv> and
C<--verbose -vv> (with the alias C<v>) all read as 3. The reader returns
C<undef> when the option is not set anywhere and has no default, so write
C<< $opt->verbose // 0 >> when you need a number. In config files it
accepts non-negative integers.

=head2 string

Names: C<string>, C<str>, C<s>. The default type of args.

Any value. The reader returns it unchanged.

=head2 int

Names: C<int>, C<integer>, C<i>. Keys: L</min, max>.

An integer: optional C<+> or C<->, followed by decimal digits (C<42>,
C<-7>, C<+3>, C<007>). The reader returns a number (C<007> reads as 7).
Other values are the user error C<'VALUE' is not an integer>.

=head2 float

Names: C<float>, C<num>, C<number>, C<f>. Keys: L</min, max>.

A number in any notation Perl understands as a decimal number: C<1.5>,
C<-2>, C<.5>, C<1e3>. Values spelled C<inf>, C<infinity> or C<nan> are
rejected with C<'VALUE' is not a finite number>. Hexadecimal values such
as C<0x10> are rejected with C<'VALUE' is not a number>. A value too
large for a Perl number, such as
C<1e999>, is accepted and reads as C<Inf>; use C<max> to exclude it. The
reader returns a number. Other values are the user error C<'VALUE' is not
a number>.

=head2 file

Names: C<file>. Keys: L</mustExist>, L</createPathIfMissing>.

A path to a file. Without C<mustExist> any value is accepted. The reader
returns the path as given (a leading C<~> is B<not> expanded; the shell
usually does that before the program sees the word). The help output
labels the option C<[File Path]>. Shell completion completes file names.

=head2 dir

Names: C<dir>, C<directory>. Keys: L</mustExist>, L</createPathIfMissing>.

A path to a directory. Otherwise the same as C<file>. The help output
labels the option C<[Path]>. Shell completion completes directory names.

=head2 url

Names: C<url>, C<uri>.

A URL of the form C<scheme://rest>: a scheme that starts with a letter
(followed by letters, digits, C<+>, C<.> or C<->), then C<://>, then at
least one character, without whitespace. C<https://example.com/x> and
C<file:///tmp/x> are accepted; C<example.com> and C<mailto:me@example.com>
are not. The help output labels the option C<[URL]>.

=head2 Custom types

You can add types, for example one that accepts only even numbers or one
that converts C<5m> to 300 seconds. See L<Getopt::Pad::Type>.

=head1 COMMAND LINE SYNTAX

Getopt::Pad accepts the following command line syntax (it uses
L<Getopt::Long> with the settings C<bundling>, C<no_ignore_case> and
C<no_auto_abbrev>). In this section, the I<value> of an option is what
the command line gives it, either as the next word or attached to the
option.

=over 4

=item Long options

Names longer than one letter are written with two dashes. A value
follows as the next word or after C<=>: C<--owner dave> and
C<--owner=dave> are the same. Names must be written in full;
abbreviations such as C<--own> are unknown options. Case matters.

=item Short options

Single-letter names are written with one dash. A value follows as the
next word or directly: C<-o dave> and C<-odave> are the same. Note that
C<-o=dave> sets the value C<=dave>. The double-dash form C<--o> is
accepted as well.

=item Bundling

Several single-letter options can share one dash: C<-abc> is C<-a -b
-c>, and C<-vvv> counts three times. A letter that takes a value ends
the bundle: C<-vxfoo> is C<-v -x foo>. Because of bundling, a long option
written with one dash is read letter by letter: C<-force> is read as
C<-f -o -r -c -e>, and every letter that is not a declared short option
is reported as an unknown option.

=item Negation

A C<bool> option is turned off with C<--no-NAME> or C<--noNAME>.

=item Repeating options

A single-value option given several times keeps the last value. A
L</multiple> option collects all values; a L</hash> or L</objectlist>
option collects all pairs. A flag stays 1; a counter counts.

=item Values that start with a dash

A value-taking option always takes the next word as its value, even if
it starts with a dash: C<--offset -5> and C<--pattern --x> work. The only
exception is C<--config>, whose value is optional (see
L</Where config files are loaded from>).

=item Order of options and args

On a level without commands, options and args can be mixed in any order:
C<tool a.txt --verbose b.txt> is the same as C<tool --verbose a.txt
b.txt>.

=item Options and commands

On a level with commands, the level's options must come before the
command word. The first word that is not an option is the command name,
and every word after it belongs to that command's level. An option of an
outer level is an unknown option after the command word, unless it is
inherited (see L</inherit>).

=item The end of options

The word C<--> ends option processing on its level: on a level without
commands, every word after it is an arg, even if it starts with a dash.
Use it for positional values that start with a dash, such as negative
numbers: C<tool -- -5>. Without C<-->, C<-5> is read as the short option
C<-5>, which is unknown.

On a level with commands, the word after C<--> is the command name, and
the command's level reads options again. So put C<--> after the command
words: C<tool resize -- -5>.

=back

=head1 COMMANDS

Commands (subcommands) split a program into modes, each with its own
options, args and help. They are declared under the L</commands> key.
The value for each command name is a spec with the same keys as the top
level (except C<config>, C<version> and C<argv>), so commands can be
nested to any depth:

=for highlighter language=perl

    my $opt = GetOptions(
        options  => { 'dry-run' => { help => 'Show what would happen' } },
        commands => {
            image => {
                description => 'Work on images',
                commands    => {
                    resize => {
                        description => 'Resize an image',
                        options     => { width => { type => 'int', min => 1 } },
                        args        => [{ short => 'file', type => 'file', required => 1 }],
                    },
                },
            },
            document => {
                description => 'Work on documents',
                args        => [{ short => 'file', type => 'file', required => 1 }],
            },
        },
    );

=head2 How commands are parsed

The command line is read level by level. On the top level, Getopt::Pad
reads options until it reaches the first word that is not an option.
That word must be the name of one of the level's commands, otherwise it is
the user error C<unknown command 'WORD', expected one of: NAMES>. The
remaining words are read by that command's level in the same way, down to
a level without commands, which reads its options and args.

For the command line

=for highlighter language=plain

    $ tool --dry-run image resize --width 640 cat.png

=over 4

=item *

the top level reads C<--dry-run> and the command name C<image>,

=item *

the level C<image> reads the command name C<resize>,

=item *

the level C<image resize> reads C<--width 640> and the arg C<cat.png>.

=back

A level with commands has no args. If the command line ends before a
command is named, that is the user error C<missing command, expected one
of: NAMES>, unless the level sets L</commandRequired> to a false value.

=head2 Reading the result

Each level that the command line selects produces its own result object.
The top level's result object is returned by C<GetOptions>. Its
C<command> method returns the name of the selected command, and its
C<subcommand> method returns that command's result object, which again
has C<command> and C<subcommand> methods:

=for highlighter language=perl

    # tool --dry-run image resize --width 640 cat.png
    $opt->dryRun;                                  # 1
    $opt->command;                                 # 'image'
    $opt->subcommand->command;                     # 'resize'
    $opt->subcommand->subcommand->width;           # 640
    $opt->subcommand->subcommand->file;            # 'cat.png'
    $opt->subcommand->subcommand->command;         # undef (no commands)

Every result object has readers only for the options and args of its own
level. See L<Getopt::Pad::Cookbook/Dispatching commands to subroutines>
for a way to run code per command.

=head2 Help for commands

C<--help> prints the help of the level it is given on: C<tool --help>
shows the top level with the list of its commands, C<tool image resize
--help> shows the options and args of C<image resize>. An error on the
command line, or in the value of an option, is reported with the help of
the level where it happened. An invalid value of an inherited option is
reported with the help of the level that declares it, wherever on the
command line it was given. An error in the structure of a config file
(an unknown command or option, a parse error, a missing file) is
reported with the help of the top level.

=head2 Options for all commands (global options)

An option that should work on every level, such as C<--verbose>, is
declared once on the top level with L</inherit>. Config files can set
options of every level, see L</File layout>.

=head1 VALUES AND PRECEDENCE

=head2 Value sources

Every declared option gets its value from the first of these value
sources that sets it:

=over 4

=item 1.

the command line;

=item 2.

a config file (see L</CONFIG FILES>);

=item 3.

the spec's L</default>.

=back

The first source that sets the option provides the whole value; values
from different sources are never merged. If the command line sets a
L</multiple> option, the list from the config file is ignored; if the
command line sets a L</hash> option, all keys from the config file are
ignored. The same rule holds between config files, see
L</Where config files are loaded from>.

If no source sets the option, a L</required> option is a user error.
Otherwise the reader returns:

=over 4

=item *

an empty arrayref for L</multiple> and L</objectlist> options,

=item *

an empty hashref for L</hash> options,

=item *

C<undef> for all other options, including flags, bools and counters.

=back

Args come from the command line only.

=head2 How values are checked

Every option value, whether it comes from the command line, a config file
or the default, passes these checks in this order. The first failing
check produces the error message. Args and defaults skip some steps, as
noted below the list.

=over 4

=item 1.

The shape: a single value, or a list or mapping for L</multiple>,
L</csv>, L</hash> and L</objectlist> options. Values of a list or
mapping are checked one by one in the following steps.

=item 2.

The type's check, including the type-specific keys (L</min, max>,
L</mustExist>).

=item 3.

The type's conversion, for example C<'007'> to the number 7.

=item 4.

The L</valid> list, compared with the converted value.

=item 5.

The L</lazyValid> check, called with the converted value.

=item 6.

For the value that is finally used: preparation, which creates missing
paths for L</createPathIfMissing>.

=back

Args pass steps 2, 3 and 6. Defaults pass steps 1 to 5 when
C<GetOptions> builds the spec, and step 6 when a parse uses them.

=head1 CONFIG FILES

=head2 Enabling config files

Config files are enabled with the L</config> key on the top level:

=for highlighter language=perl

    config => {
        format      => 'yaml',
        paths       => ['/etc/backup.yaml', '~/.config/backup.yaml'],
        defaultPath => '~/.config/backup.yaml',
        autoload    => 1,
    },

=over 4

=item format

Mandatory. The file format: C<yaml> (or C<yml>) or C<json>. The YAML
format needs the module L<YAML::XS>; without it, C<GetOptions> dies with
a spec error. The JSON format uses L<JSON::PP>, which comes with Perl.
Other formats can be added, see L<Getopt::Pad::Config::Format>.

=item paths

An arrayref of files that are loaded automatically, in this order, when
the command line has no C<--config> option. Files that do not exist are
skipped silently. The default is an empty list.

=item defaultPath

The file that a bare C<--config> (without a path) loads. It is not
loaded automatically: add it to C<paths> as well if it should be.

=item autoload

Whether C<paths> is loaded when the command line has no C<--config>
option. The default is true. With a false value, config files are only
read when the user asks for one with C<--config>.

=back

A leading C<~> is replaced with the value of C<$HOME> in the paths that
locate config files: C<paths>, C<defaultPath>, and the paths given to
C<--config> and C<--create-default-config>. Other forms such as C<~user>
are not expanded. A C<~> in an option value, from the command line or
from a config file, is never expanded.

The config block adds two automatic options to the top level, which are
also accepted on every command level (they are inherited, see
L</inherit>): L</--config [PATH]> and L</--create-default-config PATH>.
No level may declare an option or alias named C<config> or
C<create-default-config>.

=head2 Where config files are loaded from

Without C<--config> on the command line, and with C<autoload> on, every
existing file in C<paths> is loaded in order. A later file overrides an
earlier one option by option, on every level: an option set in both
files gets its value from the later file, an option set in only one of
them keeps that value. As always, the whole value of an option is
replaced; the entries of a list or a mapping are not merged.

With C<--config PATH> on the command line, only that file is loaded;
C<paths> is ignored. Parsing then continues normally. A file given with
C<--config> must exist, otherwise that is the user error C<config file
'PATH' does not exist>.

A bare C<--config> loads C<defaultPath>. If the spec has no
C<defaultPath>, that is the user error C<--config without a path, and
the spec sets no defaultPath>. Because the value of C<--config> is
optional, it takes the next word as the path unless that word starts
with a dash (a lone C<-> is taken as the path, though). So in
C<tool --config input.txt>, C<input.txt> is the config path, not an
arg. Write C<--config=> to load C<defaultPath> when an arg or
command follows: C<tool --config= input.txt>. For a config file whose
name starts with a dash, write C<--config=-name.yaml> or
C<--config ./-name.yaml>.

C<--config> may be given on any level, before or after the command words.

=head2 File layout

A config file is a mapping of group names (see L</group>) to mappings of
option names to values. Options without a C<group> are in the group
C<Options>. Use the option's primary name, not an alias.

On a level with commands, the key C<commands> holds one section per
command, and each section has the same layout, down to any depth. For
this spec:

=for highlighter language=perl

    GetOptions(
        options => {
            'log-level' => { type => 'string', default => 'info' },
            owner       => { type => 'string', group => 'Target' },
        },
        commands => {
            document => {
                options  => { notes => { type => 'file' } },
                commands => {
                    create => {
                        options => { format => { type => 'string', valid => ['pdf', 'docx'] } },
                    },
                },
            },
        },
        config => { format => 'yaml', paths => ['~/.tool.yaml'] },
    );

a config file that sets every option looks like this in YAML:

=for highlighter language=yaml

    Options:
      log-level: debug
    Target:
      owner: dave
    commands:
      document:
        Options:
          notes: /srv/docs/notes.txt
        commands:
          create:
            Options:
              format: pdf

and like this in JSON:

=for highlighter language=javascript

    {
      "Options": { "log-level": "debug" },
      "Target": { "owner": "dave" },
      "commands": {
        "document": {
          "Options": { "notes": "/srv/docs/notes.txt" },
          "commands": {
            "create": { "Options": { "format": "pdf" } }
          }
        }
      }
    }

Every key is optional: a file sets only what it contains. An inherited
option (see L</inherit>) is set in the groups of the level that declares
it, not in the sections of the commands below.

=head2 Values in config files

Config values pass the same checks as command line values (see
L</How values are checked>). In addition:

=over 4

=item *

A key without a value (YAML C<~>, or nothing after the colon; JSON
C<null>) is the user error C<no value given>. For L</hash> and
L</objectlist> options it is reported as the wrong shape instead
(C<expected a mapping of keys to values>, C<expected a list of
mappings>). An explicitly empty string (C<''> in YAML, C<""> in JSON) is
a value: a C<string> option reads it as the empty string.

=item *

A list or a mapping for a single-value option is the user error
C<expected a single value, not a list or mapping>.

=item *

Values are used as they are: a C<~> or C<$HOME> in a value is not
expanded.

=item *

C<flag> and C<bool> options take the YAML or JSON boolean values C<true>
and C<false> (written without quotes), or 1 and 0, also as the strings
C<"1"> and C<"0">. An explicitly empty string reads as 0. Any other
string, such as C<yes>, C<on> or the quoted C<"true">, is rejected.

=item *

C<counter> options take a non-negative integer.

=item *

A JSON C<true> or C<false> given to an option that is not a C<flag> or
C<bool> reaches the reader as a L<JSON::PP::Boolean> object, which
stringifies to 1 or 0.

=item *

A L</multiple> option takes a list or a single value. For a L</csv>
option a single value is split at commas; a list is taken as it is.

=item *

A L</hash> option takes a mapping, an L</objectlist> option a list of
mappings.

=back

For these options:

=for highlighter language=perl

    options => {
        tag    => { type => 'string', multiple => 1 },
        color  => { type => 'string', multiple => 1, csv => 1 },
        define => { type => 'string', hash => 1 },
        server => { type => 'string', objectlist => 1 },
    },

a config file sets values like this:

=for highlighter language=yaml

    Options:
      tag: [red, blue]                # multiple: a list
      color: red, green               # multiple with csv: a single value is split
      define: { os: linux }           # hash: a mapping
      server:                         # objectlist: a list of mappings
        - { host: alpha, port: 80 }
        - { host: beta }

=head2 How config files are checked

Every loaded file is checked completely, whichever command the command
line selects. Each of these is a user error that names the file and, for
command sections, the command:

=over 4

=item *

a file that is not a mapping, or that the format cannot parse,

=item *

a group, a C<commands> key or a command section that is not a mapping,

=item *

an unknown command name under C<commands>,

=item *

an unknown option, an automatic option, or an option under the wrong
group.

=back

Only the values that are used are checked: values in the sections of
the levels that the command line selects, and among those only the ones
that neither the command line nor a later config file overrides. A
C<mustExist> path in the section of another command is not checked, and
C<createPathIfMissing> creates nothing for it.

An empty file is not an empty mapping. An empty YAML file (or one with
only comments) is the user error C<config file 'PATH' must contain a
mapping of group names>. For JSON, an empty file is a parse error; write
C<{}> for a JSON file that sets nothing.

=head2 Writing a starter config file

=for highlighter language=plain

    $ tool --create-default-config ~/.tool.yaml
    Wrote default config to /home/user/.tool.yaml

(Here the shell has replaced C<~> before the program sees it; the message
shows the path as the program received it.)

The automatic option C<--create-default-config PATH> writes a config file
that contains the default of every option that has one, on every level,
in the layout described above, and exits with status 0. Groups and
command sections without any defaults are left out. The values are the
checked and converted defaults, so an C<int> default of C<'007'> is
written as 7.

The option refuses to overwrite an existing file, and to write through a
symbolic link (C<config file 'PATH' already exists>). It works even when
the rest of the command line is incomplete, for example without a
required option or command. Formats that cannot write files (see
L<Getopt::Pad::Config::Format>) make it fail with C<config format 'NAME'
cannot write config files>. The built-in C<yaml> and C<json> formats can.

=head2 Encoding

Config files are read and written as UTF-8. Their values are Perl
character strings. See L</CAVEATS> for values from the command line.

=head1 AUTOMATIC OPTIONS

Getopt::Pad adds these options by itself. C<--config> only selects a
config file. The other automatic options stop the parse: as soon as the
level they are given on has been read, they print their output to STDOUT
and exit with status 0. Nothing else is checked first, so C<tool --help>
works even when a required option is missing. Only a malformed command
line on the same level (before or after the option) or on an outer level,
such as an unknown option, wins over them. Levels after it are not read
at all: C<tool --help scan --bogus> prints the help of the top level.

=over 4

=item --help

On every level. Prints the help of the level it is given on. It is not
listed in the help output itself.

=item --version

On the top level only. Prints the program name and version (see the
spec key L</version>). It is not listed in the help output. Every result
object also has a C<version> method that does the same, see
L</Methods>.

=item --create-completions SHELL

On the top level only. Prints a completion script for C<bash> or C<zsh>
(see L</SHELL COMPLETION>). Listed in the help group C<Completion>.

=item --config [PATH]

Only with a L</config> block. Loads the given config file instead of the
automatic ones, or C<defaultPath> without a path (see
L</Where config files are loaded from>). Listed in the help group
C<Config>. Accepted on every level.

=item --create-default-config PATH

Only with a L</config> block. Writes a config file with the spec's
defaults (see L</Writing a starter config file>). Listed in the help
group C<Config>. Accepted on every level.

=back

The names of the automatic options cannot be used for your own options
on the levels where the automatic options exist. There are no short
forms: C<-h> is not C<--help> unless you declare it yourself (see
L<Getopt::Pad::Cookbook/Adding -h as a short form of --help>). The
automatic options have no readers.

=head1 HELP OUTPUT

C<--help> prints a usage text built from the spec. For the program in the
L</SYNOPSIS> it looks like this:

=for highlighter language=plain

    # backup [options] source
    # Copy a directory to a backup location.

    ## Arguments
       <source>                    [REQ] Directory to back up [Path]

    ## Completion
       --create-completions <>     Print a completion script for this shell to
                                   STDOUT and exit
                                       Valid   = [ bash, zsh ]

    ## Options
       --[no-]compress             Compress the backup; --no-compress turns it
                                   off
                                       Default = 1
       --exclude <>                Pattern of files to skip; repeat for more
                                   patterns
       --keep <>                   Number of backups to keep
                                       Default = 7
       --target <>                 [REQ] Directory the backup is written to
                                   [Path]
       --verbose                   Print more details; repeat for even more
                                   (-vv)

=head2 Layout

=over 4

=item Header

The first line shows the program name (the file name of C<$0>), the
command path, C<[options]> when the level has visible options,
C<< <command> >> when it has commands, and the args: required args by
name, optional args in brackets, a multiple arg (see L</ARG SPECS>)
followed by C<...>.
The second line is the L</description>, if any.

=item Arguments

One entry per arg.

=item Option groups

One section per L</group>, in alphabetical order. Within a group, the
level's own options come first, in alphabetical order of their keys,
followed by the automatic options and then by the inherited options.
Hidden options are left out.

=item Commands

On levels with commands: every command with its L</description>.

=item Examples

The L</examples>, if any.

=back

=head2 Entries

An option is shown by its primary name. Aliases are not shown. The name
is followed by a placeholder for its value:

=for highlighter language=plain

    --name                 flag, counter
    --[no-]name            bool
    --name <>              takes a value
    --name <a,b,...>       csv
    --name <key=value>     hash
    --name <N.key=value>   objectlist

The text next to the name consists of, in this order: C<[REQ]> for a
required option or arg, C<[has to exist]> or C<[created if missing]> (for
options only; args do not show them), the L</help> text, and the type
label (C<[URL]>, C<[Path]>, C<[File Path]> or the L</typehint>). Below it,
a C<Valid> line lists the values of a static L</valid> arrayref, and a
C<Default> line shows the L</default>. A list default is shown as C<a, b>,
a hash default as C<k=v, k2=v2>, and an objectlist default as C<0.host=a,
0.port=80>.

=head2 Width and color

The help text is wrapped to the width in the environment variable
C<COLUMNS>, if that is a positive integer. Otherwise, when the output is
a terminal and L<Term::ReadKey> is installed, the terminal width is
used; otherwise the width is 100 columns. The help samples in this
documentation are shown with C<COLUMNS=76>.

On a terminal, the output is colored, unless the environment variable
C<NO_COLOR> is set to a non-empty value or C<TERM> is C<dumb>.

There is no spec key for the width or the colors. A program that wants a
fixed width or no colors sets C<$ENV{COLUMNS}> or C<$ENV{NO_COLOR}> before
it calls C<GetOptions>.

=head2 Printing the help from your program

The result object's C<help> method prints the help text of its level to
STDOUT and exits with status 0:

=for highlighter language=perl

    $opt->help if !$opt->files->@*;     # nothing to do: show the help

After a user error, the help is printed to STDERR instead, below the
error message.

=head1 SHELL COMPLETION

Every program that uses Getopt::Pad can print a completion script for
bash and zsh:

=for highlighter language=plain

    $ tool --create-completions bash > ~/.local/share/bash-completion/completions/tool
    $ tool --create-completions zsh  > ~/.zsh/completions/_tool

For zsh, the directory must be in your C<$fpath>. You can also source the
script from F<~/.bashrc> or F<~/.zshrc>. The script registers
completion for the program's file name (the file name of C<$0> when the
script is generated), so install the program under that name in your
C<PATH>. The bash script needs bash 4.0 or later.

=head2 What is completed

=over 4

=item *

the command names of the current level, when the level has commands,

=item *

the option names of the current level after a C<->, including inherited
options, C<--no-NAME> for C<bool> options whose name is longer than one
letter, and short names as C<-x>; hidden options are not offered,

=item *

the values of the option's L</valid> list, as the value of an option
(C<--level d>E<lt>TABE<gt>) or after C<=> (C<--level=d>E<lt>TABE<gt>).
For a L</hash> or L</objectlist> option the values are completed after
the C<KEY=> part, for a L</csv> option after the last comma. A
C<valid> coderef is called on every tab press, so the candidates are
always current,

=item *

file names for C<file> options and args, directory names for C<dir>
options and args, using the shell's own completion.

=back

=head2 How it works

The script contains no knowledge of your program's options. Every time
the user presses tab, it runs the program again with the environment
variables C<GETOPT_PAD_COMPLETE> (the shell name) and
C<GETOPT_PAD_COMPLETE_INDEX> (the position of the word under the cursor)
set, and the words typed so far as arguments. C<GetOptions> recognizes
this, prints the candidates and exits with status 0, so nothing after the
C<GetOptions> call runs. The script therefore never needs to be
regenerated when the spec changes.

Everything your program does before it calls C<GetOptions> runs on every
tab press. Call C<GetOptions> as early as possible, and do not do
anything with side effects before it.

=head1 RESULT OBJECT

C<GetOptions> returns an object with one reader per option and arg of the
top level (see L</Reader names>). There are no methods to set values:
calling a reader with an argument is an error. Lists and mappings are
returned as ordinary Perl references, which belong to this result object;
if your program changes their contents, the reader returns the changed
data from then on. Other parses are not affected.

The object is an instance of a class that Getopt::Pad generates for the
spec. That class inherits from L<Getopt::Pad::Result>; do not rely on its
name.

=head2 Values by option kind

=for highlighter language=plain

    Option or arg                      Given                  Not set anywhere,
                                                              no default
    ---------------------------------  ---------------------  -----------------
    flag                               1 (0 from config)      undef
    bool                               1 or 0                 undef
    counter                            number of times        undef
    single value                       the value              undef
    multiple option, multiple arg      arrayref of values     []
    hash option                        hashref                {}
    objectlist option                  arrayref of hashrefs   []
    optional arg                       the value              undef

Numbers from C<int> and C<float> options are returned as numbers.

=head2 Methods

Every result object has these methods in addition to its readers:

=over 4

=item command

The name of the command selected on this level, or C<undef> when the
level has no commands or none was given.

=item subcommand

The result object of the selected command's level, or C<undef>.

=item help

A method, not a reader: prints the help text of this level to STDOUT and
exits with status 0.

=item version

A method, not a reader: prints the program name and version to STDOUT
and exits with status 0, like the automatic C<--version> option.

=back

See L<Getopt::Pad::Result> for details.

=head2 Reserved names

No option or arg may have a reader name that the result object already
uses. These names are a spec error: C<command>, C<subcommand>, C<help>,
C<version>, C<helper>, C<reservesReader>, C<new>, C<can>, C<isa>,
C<DOES>, C<VERSION>, C<META>, C<BUILDARGS>, C<DESTROY> and C<AUTOLOAD>
(C<helper> and C<reservesReader> are internals of the result class).
Currently C<croak> is rejected as well, which is a known bug. The error
message is C<reader 'NAME' collides with a built-in result method>.

Aliases have no readers, so they may use these names, except C<help>
(on every level) and C<version> (on the top level), which are automatic
options. To offer C<--command> on the command line, make it an alias of
an option with another primary name: C<'cmd|command'> gives the reader
C<cmd>.

=head1 ERRORS AND EXIT STATUS

=head2 User errors

A mistake on the command line or in a config file is a user error.
C<GetOptions> prints it to STDERR as C<ERROR: MESSAGE> (with C<ERROR> in
red on a terminal), followed by an empty line and the help text of the
level the error belongs to, and exits with status 2:

=for highlighter language=plain

    $ backup photos
    ERROR: missing required option '--target'

    # backup [options] source
    # Copy a directory to a backup location.
    ...

Only the first error is reported, with one exception: all problems
the command line parser finds on one level, such as several unknown
options, are reported together in one message, separated by C<; >. All
messages are listed under L</DIAGNOSTICS>.

=head2 Spec errors

A mistake in the spec is a bug in the program, not a user error.
C<GetOptions> dies with a message that starts with C<Getopt::Pad spec:>
and ends with the file and line of your C<GetOptions> call, for example:

=for highlighter language=plain

    Getopt::Pad spec: option 'keep': default value: 'seven' is not an integer at backup line 11.

Messages from the checks of a command's level start with the command
path, such as C<Getopt::Pad spec: command 'image resize': ...>. These
include the checks between the options and args of that level: duplicate
names and aliases, reader clashes, the order of args and C<inherit>.
Messages about the keys of one option or arg spec (unknown keys, type,
default, bounds, C<valid>, C<typehint>) name only the option or arg, not
the command, and C<unknown option type> names neither. C<GetOptions>
checks the complete spec on every call, including all commands, before it looks
at the command line, so a broken spec fails on the first run, whatever
the command line is. The exception is an error raised by a L</valid>
coderef that returns something other than an arrayref, which is only
noticed when the coderef is called.

Exceptions thrown by your own coderefs (L</valid>, L</lazyValid>) are
not caught; they propagate out of C<GetOptions>.

=head2 Exit status (exit code)

=over 4

=item Exit status 0

After an automatic option (C<--help>, C<--version>,
C<--create-completions>, C<--create-default-config>), after answering a
shell completion request, and when your program calls C<help> or
C<version> on a result object.

=item Exit status 2

After a user error.

=back

C<GetOptions> itself never exits with any other status. When it returns,
your program continues normally. A spec error is an uncaught C<die>,
which ends the program with a non-zero status chosen by Perl from C<$!>
or C<$?> (see L<perlfunc/die>): usually 255, but it can be any value,
including 2. Do not use the exit status to tell spec errors from user
errors.

=head1 DIAGNOSTICS

This section lists the messages of Getopt::Pad, so you can search for the
text you see.
Upper case words stand for the actual values. In the messages that start
with C<Option> or C<Unknown option>, NAME is the option as the user typed
it, without dashes (C<Unknown option: taget> for C<--taget>). The other
command line messages name an option by its primary name with two dashes
(C<option '--keep': ...>). Config file and spec messages use the primary
name without dashes (C<config value for 'keep': ...>).

=head2 Command line errors

These are printed as C<ERROR: MESSAGE> with the help text, and the
program exits with status 2.

=over 4

=item Unknown option: NAME

The option does not exist on this level. Check the spelling (names must
not be abbreviated), whether it belongs to another level, and whether it
comes before the command word (see L</Options and commands>).

=item Option NAME requires an argument

The option takes a value, but the command line ends after it. (In this
message and the next one, "argument" means the option's value.)

=item Option NAME does not take an argument

A value was given to a flag, bool or counter with C<--name=value>.

=item Option NAME, key "KEY", requires a value

A L</hash> or L</objectlist> option was given a word without C<=>. Write
the word as C<KEY=VALUE> (C<--define os=linux>), or for an objectlist
option as C<INDEX.FIELD=VALUE>.

=item missing required option '--NAME'

A L</required> option was not set on the command line or in a config
file.

=item missing required argument <NAME>

A required arg (see L</ARG SPECS>) is missing.

=item unexpected extra argument 'WORD'

The command line has more words than the level has args.

=item missing command, expected one of: NAMES

The level has commands, and none was given. See L</commandRequired>.

=item unknown command 'WORD', expected one of: NAMES

The word after the options of a level with commands is not one of its
commands.

=item option '--NAME': PROBLEM

The value of an option failed a check. PROBLEM is one of the value
problems listed below.

=item argument <NAME>: PROBLEM

The value of an arg failed a check.

=back

=head2 Value problems

These are the PROBLEM part of C<option '--NAME': PROBLEM>,
C<argument E<lt>NAMEE<gt>: PROBLEM> and C<config value for 'NAME':
PROBLEM>.

=over 4

=item 'VALUE' is not an integer

=item 'VALUE' is not a number

The value of an C<int> or C<float> option is not a number of that kind.

=item 'VALUE' is not a finite number

A C<float> value spelled C<inf>, C<infinity> or C<nan> (in any case,
with an optional sign).

=item VALUE is smaller than the minimum of MIN

=item VALUE is larger than the maximum of MAX

The value is outside the L</min, max> bounds.

=item file 'PATH' does not exist

=item directory 'PATH' does not exist

The option has L</mustExist>, and the path is not an existing file or
directory. The message is the same when the path exists but is of the
other kind.

=item cannot create file 'PATH': REASON

=item cannot create directory 'PATH': REASON

L</createPathIfMissing> could not create the path.

=item 'VALUE' is not a URL

The value is not of the form C<scheme://...>, see L</url>.

=item 'VALUE' is not one of: VALUES

The value is not in the L</valid> list.

=item 'VALUE' is not a valid value

The L</lazyValid> check returned false.

=item 'VALUE' contains an empty item

A L</csv> value has an empty item, such as C<a,,b>.

=item empty key

A L</hash> option was given C<=VALUE> without a key.

=item key 'KEY': PROBLEM

The value for KEY of a L</hash> option failed a check.

=item invalid key 'KEY', expected INDEX.FIELD=VALUE

A word of an L</objectlist> option does not have the form
C<INDEX.FIELD=VALUE>.

=item missing index N

The indices of an L</objectlist> option have a gap.

=item entry N: PROBLEM

An entry of an L</objectlist> option failed a check. PROBLEM is
C<key 'KEY': ...> for a value, C<empty key>, or, in a config file,
C<expected a mapping of keys to values> for an entry that is not a
mapping.

=item 'VALUE' is not a boolean (use true or false)

A config file gives a C<flag> or C<bool> option a value that is not a
YAML or JSON boolean (C<true>, C<false>), 1 or 0 (as a number or a
string), or an explicitly empty string.

=item 'VALUE' is not a count

A config file gives a C<counter> option a value that is not a
non-negative integer.

=item no value given

A config file gives an option no value (YAML C<~> or a key with nothing
after the colon, JSON C<null>). An explicitly empty string (C<''>,
C<"">) is a value.

=item expected a single value, not a list or mapping

=item expected a mapping of keys to values

=item expected a list of mappings

A config value or a default does not have the option's shape (see
L</Values in config files> and L</default>).

=item expected a list of values

The default of a L</multiple> option is not an arrayref. This is a spec
error (C<option 'NAME': default value: expected a list of values>);
config files do not produce it.

=back

=head2 Config file errors

These are user errors as well (C<ERROR: MESSAGE>, exit status 2).

=over 4

=item config file 'PATH' does not exist

The file given with C<--config> does not exist.

=item --config without a path, and the spec sets no defaultPath

A bare C<--config> needs L</defaultPath>.

=item cannot read config file 'PATH': REASON

The file exists but cannot be read, for example because of its
permissions.

=item config file 'PATH': MESSAGE

The format could not parse the file. MESSAGE comes from the parser.

=item config file 'PATH' must contain a mapping of group names

The top level of the file is not a mapping, or the YAML file is empty.

=item config file 'PATH': group 'GROUP' must contain a mapping of option names

=item config file 'PATH': group 'GROUP' of command 'COMMAND' must contain a mapping of option names

=item config file 'PATH': 'commands' must contain a mapping of command names

=item config file 'PATH': 'commands' of command 'COMMAND' must contain a mapping of command names

=item config file 'PATH': command 'COMMAND' must contain a mapping of group names

A part of the file does not have the layout described under
L</File layout>.

=item config file 'PATH': unknown option 'NAME' in group 'GROUP'

=item config file 'PATH': unknown option 'NAME' in group 'GROUP' of command 'COMMAND'

The level has no option with this primary name, or the name belongs to an
automatic option.

=item config file 'PATH': option 'NAME' belongs to group 'GROUP', not 'OTHER'

=item config file 'PATH': option 'NAME' of command 'COMMAND' belongs to group 'GROUP', not 'OTHER'

The option is in the wrong group.

=item config file 'PATH': unknown command 'COMMAND', expected one of: NAMES

A section under C<commands> is not a command of that level. COMMAND is
the command path of the unknown section, such as C<image crop>.

=item config value for 'NAME': PROBLEM

A value failed a check, see L</Value problems>.

=item config file 'PATH' already exists

C<--create-default-config> does not overwrite files.

=item cannot write config file 'PATH': REASON

C<--create-default-config> could not create the file.

=item config format 'NAME' cannot write config files

The format has no C<dump> method, see L<Getopt::Pad::Config::Format>.

=back

=head2 Spec error messages

These make C<GetOptions> die with C<Getopt::Pad spec: MESSAGE at FILE
line LINE.> Messages from the checks of a command's level start with
C<command 'PATH': >; messages about the keys of a single option or arg
spec do not name the command.

=over 4

=item unknown key(s): KEYS

=item option 'NAME': unknown key(s): KEYS

=item arg 'NAME': unknown key(s): KEYS

=item config: unknown key(s): KEYS

A key is misspelled, or not allowed at this place (for example C<config>
in a command spec, or C<min> for a C<string> option).

=item 'options' must be a hash reference

=item 'args' must be an array reference

=item 'commands' must be a hash reference

=item 'examples' must be an array reference

=item 'argv' must be an array reference

=item each example must be a hash with 'text' and 'args'

A spec key has the wrong kind of value.

=item option 'KEY': spec must be a hash reference

=item arg: spec must be a hash reference

An option or arg spec is not a hashref.

=item option 'KEY': invalid name 'NAME'

=item arg: missing or invalid 'short' name

=item invalid command name 'NAME'

A name does not start with a letter or contains characters other than
letters, digits, underscores and dashes.

=item option 'NAME': reader 'READER' collides with a built-in result method

=item arg 'NAME': reader 'READER' collides with a built-in result method

See L</Reserved names>.

=item option 'A' and option 'B' both map to reader 'READER'

=item arg 'A' and option 'B' both map to reader 'READER'

Two options or args of one level have the same reader, see
L</Reader names>.

=item option 'NAME': name 'N' is already used by option 'OTHER'

=item option 'NAME': name 'N' is already used by an alias of option 'OTHER'

=item option 'NAME' inherited from LEVEL: name 'N' is already used by option 'OTHER'

Two options of one level share a name or alias, or an option reuses a
name of an inherited option. LEVEL is C<the top level> or
C<command 'PATH'>.

=item option 'NAME' collides with the automatic --NAME option

An option or alias uses the name of an automatic option, see
L</AUTOMATIC OPTIONS>. For an option whose primary name is C<help> or
C<version>, the message is C<reader 'NAME' collides with a built-in
result method> instead.

=item unknown option type 'TYPE' (known: NAMES)

See L</TYPES>.

=item option 'NAME': required and default are mutually exclusive

=item option 'NAME': multiple requires a value-taking type, not 'TYPE'

(also for C<hash> and C<objectlist>)

=item option 'NAME': multiple and hash are mutually exclusive

(and the other combinations of C<multiple>, C<hash> and C<objectlist>)

=item option 'NAME': csv requires multiple

=item option 'NAME': inherit requires commands on the same level

=item option 'NAME': valid must be an array or code reference

=item option 'NAME': the valid coderef must return an array reference

=item option 'NAME': lazyValid must be a code reference

=item option 'NAME': typehint must be a non-empty string

=item arg 'NAME': typehint must be a non-empty string

=item option 'NAME': default value: PROBLEM

The default failed a check, see L</Value problems>.

=item option 'NAME': min must be a number, not 'VALUE'

=item option 'NAME': max must be a number, not 'VALUE'

=item option 'NAME': min MIN is larger than max MAX

(For args, these and the other messages about one arg start with
C<arg 'NAME':> instead.)

=item option 'NAME': mustExist and createPathIfMissing are mutually exclusive

=item arg 'NAME': type 'TYPE' cannot be used for a positional arg

=item arg 'NAME': multiple is only allowed on the last arg

=item arg 'NAME': a required arg cannot follow an optional one

=item args and commands are mutually exclusive on one level

=item commandRequired without commands

=item group 'commands' is reserved for the command sections of config files

=item config: expects a hash reference

=item config: missing 'format'

=item config: 'paths' must be an array reference

=item unknown config format 'NAME' (known: NAMES)

=item config format 'yaml' requires the YAML::XS module

See L</CONFIG FILES>.

=item command 'PATH': expects a hash reference

A command spec is not a hashref, as in C<< commands => { add => 1 } >>.
A command without options or args is written C<< add => {} >>.

=item option key must be a non-empty string

An option key is the empty string.

=back

=head2 Other errors

These are not reported as C<Getopt::Pad spec:> messages, but they also
point at a mistake in the program.

=over 4

=item Odd name/value argument for subroutine 'Getopt::Pad::GetOptions'

Perl's own message: C<GetOptions> was called with an odd number of
arguments. Usually a value is missing, or the spec was passed as a
hashref (C<GetOptions($spec)> instead of C<GetOptions(%$spec)>).

=item Getopt::Pad: option type name 'NAME' is already registered by CLASS

=item Getopt::Pad: config format name 'NAME' is already registered by CLASS

C<registerType> or C<registerFormat> was called with a class that uses a
name another class has already registered. See L<Getopt::Pad::Type> and
L<Getopt::Pad::Config::Format>.

=item Getopt::Pad: option type class CLASS does not provide a NAMES list

=item Getopt::Pad: config format class CLASS does not provide a NAMES list

The registered class has no C<NAMES> constant. Before this check, the
class's module file is loaded, so if the class is defined in the script
itself, the message can be C<Can't locate My/Type/Foo.pm in @INC ...>
(for the class C<My::Type::Foo>) instead.

=item Getopt::Pad: no help renderer attached to this result

C<help> or C<version> was called on a result object that was not created
by C<GetOptions>.

=back

=head1 ENVIRONMENT

=over 4

=item COLUMNS

The width the help output is wrapped to, when set to a positive integer.

=item NO_COLOR

When set to a non-empty value, the help and error output is never
colored.

=item TERM

When set to C<dumb>, the help and error output is never colored.

=item HOME

Replaces a leading C<~> in config file paths.

=item GETOPT_PAD_COMPLETE, GETOPT_PAD_COMPLETE_INDEX

Set by the generated completion scripts. When C<GETOPT_PAD_COMPLETE> is
set, C<GetOptions> answers a completion request instead of parsing (see
L</SHELL COMPLETION>). Do not set them yourself.

=back

=head1 EXTENDING

Getopt::Pad has two extension points. Both work the same way: you write
an L<Object::Pad> class that inherits from a base class, list the names it
answers to in a C<NAMES> constant, and register it.

=over 4

=item Option types

See L<Getopt::Pad::Type>. Registered with
C<Getopt::Pad::Type::registerType('My::Type')>.

=item Config file formats

See L<Getopt::Pad::Config::Format>. Registered with
C<Getopt::Pad::Config::Format::registerFormat('My::Format')>.

=back

A registered name is available to every spec in the program. A name that
another class has already registered (built-in or not) cannot be taken
over; the registration dies.

=head1 EXAMPLES

The distribution contains runnable scripts in its F<examples/>
directory. Each one prints the values of its result object, so you can
try different command lines. The header comment of each script lists
command lines to try.

=over 4

=item F<01-basic.pl>

Options with groups, defaults and a C<valid> list, and a required arg.

=item F<02-types.pl>

One option per built-in type.

=item F<03-commands.pl>

Nested commands, an inherited option and a JSON config file with command
sections.

=item F<04-custom-type.pl>

A custom type that accepts only even numbers.

=item F<05-custom-format.pl>

A custom config format for TOML files.

=item F<06-value-shapes.pl>

C<multiple>, C<csv>, C<hash> and C<objectlist> options.

=item F<07-config.pl>

Config files: the autoload chain, C<defaultPath> and
C<--create-default-config>.

=item F<08-checks.pl>

C<valid> lists and coderefs, C<lazyValid>, float bounds, C<mustExist>,
C<createPathIfMissing>, C<hidden> and C<typehint>.

=back

The source of the examples is at
L<https://github.com/davenonymous/perl-getopt-pad/tree/master/examples>.

=head1 CAVEATS

=over 4

=item C<GetOptions> exits the program

On user errors and for the automatic options, C<GetOptions> calls
C<exit>. Code after the call only runs for a valid command line. To test
a command line that should fail, run your program in a separate process;
see L<Getopt::Pad::Cookbook/Testing a command line>.

=item Command line values are not decoded

Words from the command line reach your program as Perl receives them:
byte strings, not decoded character strings. Values from config files
are decoded from UTF-8. For non-ASCII values the two sources then
differ, and a C<valid> list with non-ASCII values written in a C<use
utf8> program matches config values but not command line values. If
your program handles non-ASCII input, decode C<@ARGV> before calling
C<GetOptions>:

=for highlighter language=perl

    use Encode qw(decode);
    @ARGV = map { decode('UTF-8', $_) } @ARGV;

or run perl with the C<-CA> switch.

=item Aliases are not shown in the help

The help output lists an option by its primary name only. Mention short
aliases in the L</help> text if users should know them.

=item The order in the help output is alphabetical

Groups and the options within a group are sorted alphabetically, not
in the order of the spec.

=back

=head1 REQUIREMENTS

Perl 5.26 or later, L<Object::Pad> 0.800 or later, L<Getopt::Long> 2.50
or later, L<Feature::Compat::Try> and L<JSON::PP>.

Optional: L<YAML::XS> for YAML config files, and L<Term::ReadKey> for
wrapping the help output to the terminal width.

=head1 SEE ALSO

L<Getopt::Pad::Tutorial>, L<Getopt::Pad::Cookbook>,
L<Getopt::Pad::Result>, L<Getopt::Pad::Type>,
L<Getopt::Pad::Config::Format>

L<Getopt::Long>, which Getopt::Pad uses to split the command line.

L<Object::Pad>, which the result objects and extension classes are built
with.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
