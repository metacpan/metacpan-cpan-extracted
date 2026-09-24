use v5.26;
use Object::Pad;

use Getopt::Long ();
use Getopt::Pad::Error;
use Getopt::Pad::Result::Generator;

class Getopt::Pad::Parser :strict(params) {
	use Feature::Compat::Try;
	use Scalar::Util ();

	our $VERSION = '0.02';

	field $spec :param;
	field $argv :param;

	method parse() {
		my @words = $argv->@*;
		return $self->parseLevel($spec->root, \@words);
	}

	method parseLevel($level, $words) {
		try {
			return $self->parseLevelInner($level, $words);
		}
		catch ($error) {
			$error->attachContext($level) if Scalar::Util::blessed($error) && $error->isa('Getopt::Pad::Error');
			die $error;
		}
	}

	method parseLevelInner($level, $words) {
		my %values = $self->parseOptions($level, $words);

		# A Trigger sees its option's value after the Value pipeline, so an
		# unsupported --create-completions shell is a user error, not a crash.
		my $helper = $spec->helperFor($level);
		foreach my $option (grep { defined $_->trigger && exists $values{$_->name} } $level->options) {
			$option->trigger->($helper, $spec, $level, $option->readerValue(commandLine => \%values));
		}

		# Descend before resolving this Level's values, so a nested Trigger
		# such as --help is never blocked by an outer required option.
		my ($commandName, $subResult) = $level->hasCommands ? $self->descendCommand($level, $words) : ();

		my %configValues = $level->isRoot ? $self->loadConfigValues($level, \%values) : ();

		my %readerValues;
		$readerValues{$_->reader} = $_->readerValue(commandLine => \%values, config => \%configValues) foreach $level->declaredOptions;

		my $class = Getopt::Pad::Result::Generator::generate($level);
		return $class->new(%readerValues, command => $commandName, subcommand => $subResult, helper => $helper) if $level->hasCommands;
		return $class->new(%readerValues, $self->consumeArgs($level, $words), helper => $helper);
	}

	method descendCommand($level, $words) {
		my $expected = join(', ', $level->commandNames);

		if (!$words->@*) {
			return (undef, undef) if !$level->commandRequired;
			Getopt::Pad::Error->throw("missing command, expected one of: %s", $expected);
		}

		my $word     = shift $words->@*;
		my $subLevel = $level->command($word);
		Getopt::Pad::Error->throw("unknown command '%s', expected one of: %s", $word, $expected) if !defined $subLevel;

		my $subResult = $self->parseLevel($subLevel, $words);
		return ($word, $subResult);
	}

	method parseOptions($level, $words) {
		my @glSpecs = map { $_->glSpec } $level->options;
		my @config  = qw(bundling no_ignore_case no_auto_abbrev);
		push @config, $level->hasCommands ? 'require_order' : 'permute';

		my $gl = Getopt::Long::Parser->new(config => \@config);
		my %values;
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

	method loadConfigValues($level, $values) {
		my $configSpec = $spec->config;
		return () if !defined $configSpec;

		my $configOption = $spec->CONFIG_OPTION;
		return $configSpec->io->autoloadValues($level)->%* if !exists $values->{$configOption};
		return $configSpec->io->explicitValues($level, $values->{$configOption})->%*;
	}

	method validatedArgValue($arg, $value) {
		my $problem = $arg->type->check($value);
		Getopt::Pad::Error->throw("argument <%s>: %s", $arg->short, $problem) if defined $problem;
		return $arg->type->coerce($value);
	}

	method consumeArgs($level, $words) {
		my %readerValues;
		my @args = $level->args;

		foreach my $index (0 .. $#args) {
			my $arg = $args[$index];

			if ($arg->multiple) {
				my @rest = splice($words->@*);
				Getopt::Pad::Error->throw("missing required argument <%s>", $arg->short) if !@rest && $arg->required;
				$readerValues{$arg->reader} = [map { $self->validatedArgValue($arg, $_) } @rest] if @rest;
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

Getopt::Pad::Parser - the parsing engine

=head1 DESCRIPTION

The parsing engine: runs Getopt::Long per level, fires the triggers of auto options seen on the command line, descends into subcommands before resolving a level's values, loads the config values for the root level, hands every declared option its command line and config values to resolve, consumes positionals, and builds the generated result objects. Throws Getopt::Pad::Error for user mistakes; the triggers throw Getopt::Pad::ExitRequest carrying their output. It never exits itself.

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
