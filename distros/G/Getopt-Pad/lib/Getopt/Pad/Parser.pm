use v5.26;
use Object::Pad;

use Getopt::Long ();
use Getopt::Pad::Error;
use Getopt::Pad::Result::Generator;

class Getopt::Pad::Parser :strict(params) {
	use Feature::Compat::Try;
	use Scalar::Util ();

	our $VERSION = '0.04';

	field $spec :param;
	field $argv :param;

	# The command line is parsed Level by Level first, and the Levels it
	# selects are resolved afterwards, innermost first, since each Result
	# holds the one below it. Every Trigger has fired before anything is
	# resolved, so --help anywhere on the line wins over a missing required
	# option or a broken config file.
	method parse() {
		my @words           = $argv->@*;
		my @steps           = $self->parseCommandLine(\@words);
		my $inheritedValues = $steps[-1]{inheritedValues};
		my $configValues    = $self->inContext($spec->root, sub { $self->loadConfigValues($inheritedValues) });

		my $result;
		foreach my $step (reverse @steps) {
			my $subResult = $result;
			$result = $self->inContext($step->{level}, sub { $self->resolveStep($step, $inheritedValues, $configValues, \@words, $subResult) });
		}
		return $result;
	}

	# User errors raised by $code are attributed to $level, whose help the
	# user sees next to the message.
	method inContext($level, $code) {
		try {
			return $code->();
		}
		catch ($error) {
			$error->attachContext($level) if Scalar::Util::blessed($error) && $error->isa('Getopt::Pad::Error');
			die $error;
		}
	}

	# One step per selected Level: its own command line values, the values
	# of every inherited option given so far, and the command it names.
	method parseCommandLine($words) {
		my @steps;
		my $level           = $spec->root;
		my $inheritedValues = {};
		while (defined $level) {
			my $step = $self->inContext($level, sub { $self->parseLevel($level, $words, $inheritedValues) });
			push @steps, $step;
			$inheritedValues = $step->{inheritedValues};
			$level           = defined $step->{command} ? $level->command($step->{command}) : undef;
		}
		return @steps;
	}

	method parseLevel($level, $words, $inheritedSoFar) {
		my %values = $self->parseOptions($level, $words, $inheritedSoFar);
		$self->fireTriggers($level, \%values);

		# Inherited options leave the Level's own values: they carry on to
		# the next Level and end up with the Level declaring them.
		my %inheritedValues = map { $_->name => delete $values{$_->name} } grep { exists $values{$_->name} } $level->inheritableOptions, $level->inheritedOptions;
		my $command         = $level->hasCommands ? $self->selectCommand($level, $words) : undef;
		return { level => $level, values => \%values, inheritedValues => \%inheritedValues, command => $command };
	}

	# A Trigger sees its option's value after the Value pipeline, so an
	# unsupported --create-completions shell is a user error, not a crash.
	# The values inherited from an outer Level never hold the option of a
	# Trigger: every Trigger ends the parse where it fires.
	method fireTriggers($level, $values) {
		my $helper = $spec->helperFor($level);
		foreach my $option (grep { defined $_->trigger && exists $values->{$_->name} } $level->options) {
			$option->trigger->($helper, $spec, $level, $option->readerValue(commandLine => $values));
		}
		return;
	}

	method selectCommand($level, $words) {
		my $expected = join(', ', $level->commandNames);

		if (!$words->@*) {
			return undef if !$level->commandRequired;
			Getopt::Pad::Error->throw("missing command, expected one of: %s", $expected);
		}

		my $word = shift $words->@*;
		Getopt::Pad::Error->throw("unknown command '%s', expected one of: %s", $word, $expected) if !defined $level->command($word);
		return $word;
	}

	# Getopt::Long stores into a copy of the inherited values given so far,
	# so an inherited option repeated across Levels accumulates exactly as
	# it does when repeated on one.
	method parseOptions($level, $words, $inheritedSoFar) {
		my @glSpecs = map { $_->glSpec } $level->options;
		my @config  = qw(bundling no_ignore_case no_auto_abbrev);
		push @config, $level->hasCommands ? 'require_order' : 'permute';

		my $gl = Getopt::Long::Parser->new(config => \@config);
		my %values = map { $_ => $self->copiedWords($inheritedSoFar->{$_}) } keys $inheritedSoFar->%*;
		my @glWarnings;
		my $ok;
		{
			local $SIG{__WARN__} = sub { push @glWarnings, $_[0] };
			$ok = $gl->getoptionsfromarray($words, \%values, @glSpecs);
		}

		if (!$ok) {
			my $message = join('; ', map { s/\s+$//r } @glWarnings) || 'invalid command line';
			Getopt::Pad::Error->throw('%s', $message);
		}

		return %values;
	}

	method copiedWords($given) {
		return [$given->@*] if ref $given eq 'ARRAY';
		return { $given->%* } if ref $given eq 'HASH';
		return $given;
	}

	method loadConfigValues($inheritedValues) {
		my $configSpec = $spec->config // return {};

		my $configOption = $spec->CONFIG_OPTION;
		return $configSpec->io->autoloadValues($spec->root) if !exists $inheritedValues->{$configOption};
		return $configSpec->io->explicitValues($spec->root, $inheritedValues->{$configOption});
	}

	# The Result of one selected Level. Its inherited options take the words
	# collected on every Level down from it, its options the config values
	# of its own section.
	method resolveStep($step, $inheritedValues, $configValues, $words, $subResult) {
		my $level       = $step->{level};
		my %commandLine = ($step->{values}->%*, map { $_->name => $inheritedValues->{$_->name} } grep { exists $inheritedValues->{$_->name} } $level->inheritableOptions);
		my $config      = $configValues->{$level->path} // {};

		my %readerValues;
		$readerValues{$_->reader} = $_->readerValue(commandLine => \%commandLine, config => $config) foreach $level->declaredOptions;

		my $class  = Getopt::Pad::Result::Generator::generate($level);
		my $helper = $spec->helperFor($level);
		return $class->new(%readerValues, command => $step->{command}, subcommand => $subResult, helper => $helper) if $level->hasCommands;
		return $class->new(%readerValues, $self->consumeArgs($level, $words), helper => $helper);
	}

	method validatedArgValue($arg, $value) {
		my $problem = $arg->type->check($value);
		Getopt::Pad::Error->throw("argument <%s>: %s", $arg->short, $problem) if defined $problem;

		my $coerced = $arg->type->coerce($value);
		$problem = $arg->type->prepare($coerced);
		Getopt::Pad::Error->throw("argument <%s>: %s", $arg->short, $problem) if defined $problem;
		return $coerced;
	}

	method consumeArgs($level, $words) {
		my %readerValues;
		my @args = $level->args;

		foreach my $index (0 .. $#args) {
			my $arg = $args[$index];

			if ($arg->multiple) {
				my @rest = splice($words->@*);
				Getopt::Pad::Error->throw("missing required argument <%s>", $arg->short) if !@rest && $arg->required;
				$readerValues{$arg->reader} = [map { $self->validatedArgValue($arg, $_) } @rest];
				next;
			}

			if (!$words->@*) {
				Getopt::Pad::Error->throw("missing required argument <%s>", $arg->short) if $arg->required;
				next;
			}

			$readerValues{$arg->reader} = $self->validatedArgValue($arg, shift $words->@*);
		}

		Getopt::Pad::Error->throw("unexpected extra argument '%s'", $words->[0]) if $words->@*;

		return %readerValues;
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Parser - Parses a command line against a spec (internal)

=head1 DESCRIPTION

This module is internal to Getopt::Pad. It is not part of the public
API and can change without notice. Programs use L<Getopt::Pad/GetOptions>;
this page is for people working on Getopt::Pad itself.

C<< Getopt::Pad::Parser->new(spec => $spec, argv => \@words)->parse >>
returns the result object of the top level, or throws. It works in two
passes.

=head2 First pass: the command line

The command line is read level by level, starting at the top level:

=over 4

=item 1.

L<Getopt::Long> reads the level's options, configured with C<bundling>,
C<no_ignore_case>, C<no_auto_abbrev>, and C<require_order> on a level
with commands (so the first non-option word ends the level) or
C<permute> on a level without commands. Its warnings become the error
message.

=item 2.

The triggers of the automatic options set on this level run. A trigger
throws a L<Getopt::Pad::ExitRequest>, which ends the parse before
anything else is checked.

=item 3.

The values of inherited options are set aside. When the next level is
read, Getopt::Long stores into a copy of them, so an inherited option
given on several levels accumulates as if it had been given on one.

=item 4.

On a level with commands, the next word selects the command, and the
loop continues with that command's level.

=back

=head2 Second pass: the values

The config values are loaded once (an explicit C<--config>, given on any
level, replaces the autoload chain). Then the selected levels are
resolved from the innermost to the top level. Each declared option gets
its value from the command line words of its level and the config values
of its level's section (see L<Getopt::Pad::Spec::Option>); an inherited
option gets the words collected on all levels. The innermost level
consumes the positional words for its args (type check, conversion,
C<prepare>). Each level's result object, created by
L<Getopt::Pad::Result::Generator>, holds the result object of the level
below.

=head2 Errors

User errors are thrown as L<Getopt::Pad::Error> objects. The parser
attaches the level they happened on, so that C<GetOptions> can print
that level's help. The parser never prints and never exits; that is left
to C<GetOptions>.

=head1 SEE ALSO

L<Getopt::Pad::Spec>, L<Getopt::Pad::Config>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
