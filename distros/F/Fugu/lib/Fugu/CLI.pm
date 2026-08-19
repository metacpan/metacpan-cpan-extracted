# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package Fugu::CLI;
our $VERSION = '0.1.2';

use Exporter qw(import);
use Fugu::Log;
use Getopt::Long ();

our @EXPORT_OK = qw(EXIT_SUCCESS EXIT_ERROR);

# Fugu::CLI - subcommand dispatch for a command-line tool.
#
# A tool declares its global options once and its commands in a table.
# The module parses the global options, finds the command, parses that
# command's own options, and calls it. Every command in a tool would
# otherwise repeat the same eight lines of Getopt::Long setup.
#
# Output has two channels, and they are not the same channel. Data
# that a script reads goes to standard output; a caller prints it
# itself. Diagnostics go to the logger, which writes to standard
# error. Thus `mytool list --names | xargs` keeps working when the
# tool starts to warn about something.

# The exit codes that every tool shares. A domain code belongs to the
# tool, not here, and starts above these. EXIT_SUCCESS and EXIT_ERROR
# are importable: they are the two codes that non-CLI modules also
# return.
use constant {
	EXIT_SUCCESS      => 0,
	EXIT_ERROR        => 1,
	EXIT_INVALID_ARGS => 2,
	EXIT_CONFIG_ERROR => 3,
	EXIT_TIMEOUT      => 7,
};

# Fugu::CLI->new(%args):
#	name     => $string	the program name in usage and diagnostics
#	commands => \%table	the subcommands (required)
#	options  => \%spec	global options, in Getopt::Long form
#	usage    => $string	one line after "usage: <name>"
#	epilogue => $string	text after the command list, for examples
#	log      => $logger	default: Fugu::Log->default
#
#	Each entry of %commands maps a name to a hashref:
#
#		run     => sub ($cli, @argv)	the body (required)
#		usage   => $string		the argument summary
#		summary => $string		one line for the help
#		options => \%spec		this command's own options
#
#	The body receives the CLI object and the remaining arguments,
#	and returns an exit code. It reads its parsed options from
#	$cli->option($name).
sub new ( $class, %args )
{
	my $commands = $args{commands};
	die 'commands parameter required (hashref)'
	    unless ref $commands eq 'HASH';

	for my $name ( keys %$commands ) {
		die "command $name needs a run code reference"
		    unless ref $commands->{$name}{run} eq 'CODE';
	}

	return bless {
		name     => $args{name} // 'cli',
		commands => $commands,
		options  => $args{options} // {},
		usage    => $args{usage},
		epilogue => $args{epilogue},
		log      => $args{log} // Fugu::Log->default,
		parsed   => {},
		command  => undef,
	}, $class;
}

# $self->name:
#	Return the program name.
sub name ($self)
{
	return $self->{name};
}

# $self->log:
#	Return the logger. A command body reports through it.
sub log ($self)
{
	return $self->{log};
}

# $self->command:
#	Return the name of the command that is running.
sub command ($self)
{
	return $self->{command};
}

# $self->option($name):
#	Return a parsed option value. Global options and the running
#	command's options share one namespace, because a tool that
#	gives the same name two meanings is a tool nobody can use.
sub option ( $self, $name )
{
	return $self->{parsed}{$name};
}

# $self->options:
#	Return every parsed option as a hashref.
sub options ($self)
{
	return $self->{parsed};
}

# $self->run(@argv):
#	Parse, dispatch, and return the exit code of the command.
#
#	An unknown command, a bad option, and a missing command all
#	give EXIT_INVALID_ARGS with usage on standard error. A command
#	name of help, and an empty argument list, print the help and
#	return EXIT_SUCCESS: asking for help is not a failure.
sub run ( $self, @argv )
{
	my $parser = Getopt::Long::Parser->new;
	$parser->configure( 'require_order', 'bundling', 'no_ignore_case' );

	my @specs = _specs( $self->{options} );
	my %values;
	unless ( $parser->getoptionsfromarray( \@argv, \%values, @specs ) ) {
		$self->usage_error;
		return EXIT_INVALID_ARGS;
	}
	$self->_store( \@specs, \%values );

	my $command = shift @argv;

	if ( !defined $command || $command eq 'help' ) {

		# --help before a command asks about the tool; after a
		# command it asks about that command, and the command's
		# own parse below handles it.
		$self->print_help( $argv[0] );
		return EXIT_SUCCESS;
	}

	my $entry = $self->{commands}{$command};
	unless ($entry) {
		$self->{log}->error( '%s: unknown command: %s',
			$self->{name}, $command );
		$self->usage_error;
		return EXIT_INVALID_ARGS;
	}
	$self->{command} = $command;

	# Every command takes --help, whether it declared the option or
	# not. A user who asks a command for its usage must not get an
	# "unknown option" instead.
	my @command_specs = _specs( $entry->{options} // {} );
	my $sub           = Getopt::Long::Parser->new;
	$sub->configure( 'bundling', 'no_ignore_case' );

	my %command_values;
	unless (
		$sub->getoptionsfromarray(
			\@argv, \%command_values, @command_specs
		) )
	{
		$self->command_usage_error($command);
		return EXIT_INVALID_ARGS;
	}
	$self->_store( \@command_specs, \%command_values );

	if ( $self->{parsed}{help} ) {
		$self->print_help($command);
		return EXIT_SUCCESS;
	}

	return $entry->{run}->( $self, @argv );
}

# $self->_usage_line($command):
#	The usage line: of one command when the caller names one it
#	has, of the whole tool otherwise. The four printers below
#	share this one formatter.
sub _usage_line ( $self, $command = undef )
{
	if ( defined $command && $self->{commands}{$command} ) {
		my $entry = $self->{commands}{$command};
		return sprintf 'usage: %s %s%s', $self->{name}, $command,
		    defined $entry->{usage} ? " $entry->{usage}" : '';
	}

	return sprintf 'usage: %s %s', $self->{name},
	    $self->{usage} // '[options] <command> [arguments]';
}

# $self->print_help($command):
#	Print the help for one command, or for the whole tool. The help
#	is what the user asked for, so it goes to standard output.
sub print_help ( $self, $command = undef )
{
	say $self->_usage_line($command);

	if ( defined $command && $self->{commands}{$command} ) {
		my $entry = $self->{commands}{$command};
		print "\n$entry->{summary}\n" if defined $entry->{summary};
		return EXIT_SUCCESS;
	}

	print "\nCommands:\n";
	my $width = 0;
	for my $name ( keys %{ $self->{commands} } ) {
		$width = length $name if length $name > $width;
	}
	for my $name ( sort keys %{ $self->{commands} } ) {
		printf "    %-*s  %s\n", $width, $name,
		    $self->{commands}{$name}{summary} // '';
	}
	print "\n";

	print $self->{epilogue} if defined $self->{epilogue};

	return EXIT_SUCCESS;
}

# $self->usage_error:
#	Print the usage line on standard error. A diagnostic is not
#	output that a script reads.
sub usage_error ($self)
{
	say STDERR $self->_usage_line;

	return EXIT_INVALID_ARGS;
}

# $self->command_usage_error($command):
#	Print the usage line of one command on standard error.
sub command_usage_error ( $self, $command )
{
	say STDERR $self->_usage_line($command);

	return EXIT_INVALID_ARGS;
}

# _specs($table):
#	The Getopt::Long specifications of an option table, plus the
#	implicit help option when the table does not declare one.
sub _specs ($table)
{
	my @specs = sort keys %$table;
	push @specs, 'help|h'
	    unless grep { _option_name($_) eq 'help' } @specs;

	return @specs;
}

# $self->_store($specs, $values):
#	Copy the parsed values under the plain name of each option.
#	Getopt::Long keys the hash by the first name of a
#	specification, so "config|c=s" arrives as "config".
sub _store ( $self, $specs, $values )
{
	for my $spec (@$specs) {
		my $key = _option_name($spec);
		$self->{parsed}{$key} = $values->{$key}
		    if exists $values->{$key};
	}

	return $self;
}

# _option_name($spec):
#	Reduce "config|c=s" to "config".
sub _option_name ($spec)
{
	my $name = $spec;
	$name =~ s/[=:!+].*$//;
	$name =~ s/\|.*$//;

	return $name;
}

1;
