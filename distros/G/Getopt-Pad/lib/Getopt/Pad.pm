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

our $VERSION = '0.02';
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

Getopt::Pad - Object::Pad based POSIX compatible options processor

=head1 SYNOPSIS

	use Getopt::Pad;

	my $opt = GetOptions(
		options => {
			'owner|o' => {
				type     => 's',
				required => 1,
				help     => 'Target owner',
			},
		},
		args => [
			{ type => 'url', short => 'source-url', required => 1, help => 'Source URL' },
		],
		description => 'Migrate one Git repository into Forgejo.',
	);

	say $opt->owner;
	say $opt->sourceUrl;

Called with C<--help>, this script prints:

	# migrate [options] source-url
	# Migrate one Git repository into Forgejo.

	## Arguments
	   <source-url>                [REQ] Source URL [URL]

	## Completion
	   --create-completions <>     Print a completion script for this shell to
	                               STDOUT and exit
	                                   Valid   = [ bash, zsh ]

	## Options
	   --owner <>                  [REQ] Target owner

=head1 DESCRIPTION

Getopt::Pad parses command line options declared as a typed spec, validates
them, and returns a runtime-generated Object::Pad object with one camelCase
reader per option and positional argument. Parsing itself is delegated to
L<Getopt::Long>, configured with C<bundling>, C<no_ignore_case> and
C<no_auto_abbrev> (no long-option abbreviation).

Any parse or validation failure prints the specific error to STDERR,
followed by the help text of the command level the error occurred on, and
exits with status 2. Mistakes in the spec itself are programmer errors and
die instead, with a message pointing at the C<GetOptions> call rather than
into the library. C<--help> prints the generated usage text to STDOUT and
exits 0.

=head1 FUNCTIONS

=head2 GetOptions(%spec)

Parses C<@ARGV> (or the C<argv> arrayref, see below) against the spec and
returns a result object. Recognized top-level keys:

=over 4

=item options => \%options

Maps option keys to option specs. The key is the option's name, optionally
with pipe-separated aliases (C<'owner|o'>). The first name defines the
camelCase reader (C<work-dir> becomes C<workDir>). Each option spec accepts:

=over 4

=item * C<type> - a type name, see L</TYPES>. Defaults to a plain flag.

=item * C<required> - the option must be given (mutually exclusive with C<default>).

=item * C<default> - the value used when the option is absent. It is validated like user input when the spec is built.

=item * C<valid> - the allowed values: an arrayref, or a coderef returning
such an arrayref when called (with no arguments) - for lists that are only
known at run time, such as ids read from a database. The coderef runs when
a value has to be checked and when the shell asks for completions (see
L</SHELL COMPLETION>). The help output lists only a static arrayref.

=item * C<lazyValid> - a coderef called with one value, returning true when
it is acceptable. Use it for constraints that cannot be listed. It runs after
C<valid>.

=item * C<group> - the help section this option is rendered under (default C<Options>).

=item * C<help> - the help text.

=item * C<multiple> - the option may be repeated. The reader returns an arrayref.

=item * C<hidden> - accept the option but leave it out of the help output.

=back

Type-specific keys are accepted alongside: C<mustExist> (file, dir),
C<min> / C<max> (int, float).

=item args => \@args

Positional arguments, consumed in order. Each entry accepts C<short> (the
name, mandatory, defines the reader), C<type> (default C<string>),
C<required>, C<help>, and - on the last entry only - C<multiple> to slurp
all remaining positionals into an arrayref. Required args must precede
optional ones.

=item commands => \%commands

Nested subcommands: each value is a hashref with the same keys as the
top-level spec (except C<config>, C<version> and C<argv>). The first bare
word on the command line selects a command. Options before it belong to the
outer level, everything after it to the inner level. A level may declare
C<args> or C<commands>, never both.

When a level has commands, naming one is mandatory unless the level sets
C<commandRequired =E<gt> 0>. The result's C<command> and C<subcommand>
readers then return undef.

=item description => $text

One-line description shown in the help header.

=item examples => \@examples

Hashrefs with C<text> and C<args>, rendered in the help's Examples section.

=item config => \%config

Enables config file support and the automatic C<--config> option, which is
listed in the help output under a C<Config> group (unlike C<--help> and
C<--version>, which stay hidden). Keys:
C<format> (mandatory, C<yaml> or C<json>, see L</EXTENDING>), C<paths>
(arrayref, loaded in order when C<autoload> is on - later files override
earlier ones), C<defaultPath> (loaded by a bare C<--config>), C<autoload>
(default 1). An explicit C<--config PATH> replaces the autoload chain.
Precedence is always: command line over config file over spec default.
Config files can only set top-level options. A subcommand's options cannot
come from a config file. C<~> in paths expands to C<$HOME>.

A bare C<--config> takes the next word as its path unless that word starts
with a dash, so it also swallows a following positional or command name.
Write C<--config=> to load C<defaultPath> in that position.

Config files are structured by group: each top-level key is a group name
(as used in the option specs, with ungrouped options under C<Options>)
containing a mapping of option names to values:

	Target:
	  owner: dave
	Options:
	  log-level: debug

Config values run through the same checks as command line values. A value
without content (YAML C<~> or an empty entry, JSON C<null>) is an error, as
is a list or mapping for an option without C<multiple>. A C<multiple>
option takes a list or a single value. Flag and bool options accept only
C<true>/C<false>, 1 and 0, counters only non-negative integers.

A C<--create-default-config PATH> option is added as well: it writes a
config file prefilled with the spec's default values to PATH, refusing to
overwrite an existing file, and exits 0.

=item version => $string

Printed by the automatic C<--version> option. It defaults to the calling
script's C<$main::VERSION>.

=item argv => \@words

Parse these words instead of C<@ARGV>. C<@ARGV> itself is never modified.

=back

Every level gets an automatic C<--help> option and the root level an
automatic C<--version> and C<--create-completions SHELL> option, the latter
listed under a C<Completion> group. See L</SHELL COMPLETION>.

=head1 RESULT OBJECT

A successful parse returns an instance of a freshly generated Object::Pad
class with one C<:reader> per option and arg, plus:

=over 4

=item * C<command> - the selected subcommand name (or undef)

=item * C<subcommand> - the nested result object (or undef)

=item * C<help> - prints the usage text and exits 0

=item * C<version> - prints the version and exits 0

=back

An option that was never given (no command line value, no config value, no
default) reads as undef. A C<multiple> option or slurpy arg that was given
reads as an arrayref.

Option and arg names whose reader would collide with something every result
object already answers to are rejected when the spec is built: its methods
(C<command>, C<subcommand>, C<help>, C<version>, C<new> and what Object::Pad
and UNIVERSAL provide, such as C<can> or C<BUILDARGS>), its constructor
params, and the names Perl calls by itself (C<DESTROY>, C<AUTOLOAD>). The
result class answers that question from its own method table, so the list
is never copied. Duplicate names or aliases across the options of one level
are rejected the same way.

=head1 SHELL COMPLETION

C<--create-completions bash> or C<--create-completions zsh> prints a
completion script for the program to STDOUT and exits 0. Redirect it to
wherever your shell picks completions up from, or source it:

	tool --create-completions bash > ~/.local/share/bash-completion/completions/tool
	tool --create-completions zsh  > ~/.zsh/completions/_tool

The script is a thin shim: every time the user presses tab, it runs the
program again with the environment variable C<GETOPT_PAD_COMPLETE> set to
the shell name, C<GETOPT_PAD_COMPLETE_INDEX> set to the index of the word
under the cursor, and the words typed so far as arguments. C<GetOptions>
notices the variable, prints the candidates and exits 0 instead of parsing,
so nothing after the C<GetOptions> call runs, and the script never needs to
be regenerated when the spec changes. Anything the program does before it
calls C<GetOptions> runs on every tab, so keep the call early.

Completed are the command names of the current level, the option spellings
the help lists (hidden options are left out, negatable ones also as
C<--no-name>), the values an option's C<valid> list allows - a coderef is
called on every tab, so ids fetched from a database complete to the ids
that exist right now - and, for options and positional args of the C<file>
and C<dir> types, the shell's own path completion.

=head1 TYPES

Types validate and coerce values and annotate the help output.

	!      bool boolean       negatable flag (--name / --no-name)
	+      counter count      counting flag (-vvv)
	s      string str         plain string
	i      int integer        integer; min/max
	f      float num number   number; min/max
	file                      file path; mustExist
	dir    directory          directory path; mustExist
	url    uri                URL of the form scheme://...
	flag                      plain non-negatable flag (the default)

=head1 EXTENDING

Both extension seams follow the same pattern: subclass an abstract base
class, name the extension through a C<NAMES> constant, and register the
class. Runnable versions of the examples below live in the distribution's
F<examples/> directory.

=head2 Custom option types

A type subclasses L<Getopt::Pad::Type> and is registered with
C<Getopt::Pad::Type::registerType($class)>. Every name it lists must be
free: a name another type already holds (built-in or custom) makes the
registration die, so nothing can silently replace C<s> or C<int>. The
contract:

=over 4

=item NAMES (constant, required)

Arrayref of the names this type answers to in an option's C<type> key,
matched case insensitively (e.g. C<['i', 'int', 'integer']>).

=item glSuffix (method, required)

The Getopt::Long suffix ("gl" is short for Getopt::Long) appended to the
option names when the Getopt::Long option specification is built - for an
option declared as C<'owner|o'> with a C<'=s'> suffix, Getopt::Long is
handed C<owner|o=s>. Valid return values:

	''      plain flag, no value (--name)
	'!'     negatable flag (--name / --no-name)
	'+'     counting flag (-vvv)
	'=s'    the option takes a value

Value-taking types should return C<'=s'> even for numbers - never C<'=i'>
or C<'=f'> - and do their own checking in C<check>, so every invalid value
produces a Getopt::Pad error message instead of a Getopt::Long one. The
built-in Int and Float types work exactly this way. The suffix is the only
Getopt::Long spelling a type contributes: the base class derives
C<takesValue> and C<negatable> from it and assembles the full option
specification in C<glSpec>. Overriding those is rarely useful.

=item check($value) (method, optional)

Return C<undef> when the value is acceptable, otherwise a short problem
description B<without> the option name - the caller prefixes it with the
option or argument the value came from. Runs for command line, config file
and default values alike. Lists, mappings and null config values are
rejected before C<check> is called, so a config value always arrives as a
single scalar (or a JSON boolean object).

=item coerce($value) (method, optional)

Return the value to store after a successful check. The default returns it
unchanged. Numeric types use this to turn the string into a number.

=item label (method, optional)

A short tag rendered at the end of the help text, e.g. C<URL> renders as
C<[URL]>. Return C<undef> (the default) for none.

=item constraintNotes (method, optional)

A list of annotations rendered before the help text, e.g.
C<'has to exist'> renders as C<[has to exist]>. The list is empty by
default.

=item completes (method, optional)

Which of the shell's own completions a value of this type gets when the
user presses tab: C<'files'>, C<'dirs'>, or C<undef> (the default) for
none. The C<file> and C<dir> types use it.

=item SPEC_KEYS (constant, optional)

Arrayref of extra option-spec keys this type consumes. The type module
takes them out of the option or arg spec and passes them to the type's
constructor as named parameters, and any key left over is reported as
unknown. This is how C<mustExist>, C<min> and C<max> reach the built-in
types.

=item checkSpecKeys(%keys) (class method, optional)

Checks the SPEC_KEYS values before the type is constructed. Return
C<undef> when they are acceptable, otherwise a short problem description
B<without> the option name. It is reported as a spec error naming the
option or arg. The numeric types use this to reject a C<min> that is not
a number or larger than C<max>.

=back

A complete type accepting only even integers:

	use Object::Pad;
	use Getopt::Pad::Type;

	class My::Type::Even :isa(Getopt::Pad::Type) {
		use constant NAMES => ['even'];

		method glSuffix() { return '=s' }

		method coerce($value) { return $value + 0 }

		method check($value) {
			return "'$value' is not an integer" if $value !~ /^-?\d+$/;
			return "$value is not an even number" if $value % 2;
			return undef;
		}
	}

	Getopt::Pad::Type::registerType('My::Type::Even');

	# afterwards, in any spec:
	options => { workers => { type => 'even' } }

=head2 Custom config formats

A format subclasses L<Getopt::Pad::Config::Format> and is registered with
C<Getopt::Pad::Config::Format::registerFormat($class)>. It provides a
C<NAMES> constant (like types, and with the same rule that a name held by
another format cannot be taken over) and one method: C<parse($text)>, which
turns the file's contents into a hashref of group names, each holding a
hashref of option names to values. Getopt::Pad reads and writes the files
itself as UTF-8: C<parse> receives the decoded text as a Perl character
string and never opens a file, and encoding is not the format's concern.
On parse problems it should simply C<die>. The message is reported to the
user as a config error naming the file. A format may additionally provide
C<dump($data)>, returning such a structure serialized as text (again a
character string, not UTF-8 octets) - without it,
C<--create-default-config> refuses to write files in that format. A TOML
format via L<TOML::Tiny>:

	use Object::Pad;
	use Getopt::Pad::Config::Format;

	class My::Format::Toml :isa(Getopt::Pad::Config::Format) {
		use Carp qw(croak);
		use Feature::Compat::Try;

		use constant NAMES => ['toml'];

		method parse($text) {
			try { require TOML::Tiny }
			catch ($error) { croak "config format 'toml' requires the TOML::Tiny module" }

			return TOML::Tiny::from_toml($text);
		}
	}

	Getopt::Pad::Config::Format::registerFormat('My::Format::Toml');

	# afterwards, in any spec:
	config => { format => 'toml', paths => ['~/.mytool.toml'] }

=head1 EXAMPLES

The distribution ships runnable examples in F<examples/>. Each one parses
your arguments (its header comment lists invocations to try) and prints an
overview of the readers on the result object, indenting nested subcommand
results:

=over 4

=item * L<01-basic.pl|https://github.com/davenonymous/perl-getopt-pad/blob/master/examples/01-basic.pl> - options, defaults, valid lists, positionals

=item * L<02-types.pl|https://github.com/davenonymous/perl-getopt-pad/blob/master/examples/02-types.pl> - every built-in option type

=item * L<03-commands.pl|https://github.com/davenonymous/perl-getopt-pad/blob/master/examples/03-commands.pl> - nested subcommands and chained results

=item * L<04-custom-type.pl|https://github.com/davenonymous/perl-getopt-pad/blob/master/examples/04-custom-type.pl> - registering the C<even> type shown above

=item * L<05-custom-format.pl|https://github.com/davenonymous/perl-getopt-pad/blob/master/examples/05-custom-format.pl> - registering the TOML format shown above

=back

=head1 SEE ALSO

L<Getopt::Long>, L<Object::Pad>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
