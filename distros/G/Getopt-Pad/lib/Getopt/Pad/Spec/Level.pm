use v5.26;
use Object::Pad;

use Getopt::Pad::Spec::Option;
use Getopt::Pad::Spec::Arg;

class Getopt::Pad::Spec::Level :strict(params) {
	use Getopt::Pad::Util qw(specError isValidName);

	our $VERSION = '0.02';

	field $raw  :param;
	field $path :param :reader = '';

	field @options;
	field %optionByName;
	field %takenNames;
	field @args;
	field %commands;
	field $commandRequired :reader = 1;
	field $description     :reader = '';
	field @examples;

	ADJUST {
		my $where = $self->where;
		specError("%sexpects a hash reference", $where) if ref $raw ne 'HASH';
		my %spec = $raw->%*;

		my $rawOptions = delete $spec{options} // {};
		specError("%s'options' must be a hash reference", $where) if ref $rawOptions ne 'HASH';
		foreach my $key (sort keys $rawOptions->%*) {
			$self->addOption(Getopt::Pad::Spec::Option->new(key => $key, raw => $rawOptions->{$key}));
		}

		my $rawArgs = delete $spec{args} // [];
		specError("%s'args' must be an array reference", $where) if ref $rawArgs ne 'ARRAY';
		foreach my $rawArg ($rawArgs->@*) {
			push @args, Getopt::Pad::Spec::Arg->new(raw => $rawArg);
		}
		my $sawOptional = 0;
		foreach my $index (0 .. $#args) {
			my $arg = $args[$index];
			specError("%sarg '%s': multiple is only allowed on the last arg", $where, $arg->short) if $arg->multiple && $index != $#args;
			specError("%sarg '%s': a required arg cannot follow an optional one", $where, $arg->short) if $arg->required && $sawOptional;
			$sawOptional = 1 if !$arg->required;
		}

		my $rawCommands = delete $spec{commands} // {};
		specError("%s'commands' must be a hash reference", $where) if ref $rawCommands ne 'HASH';
		foreach my $name (sort keys $rawCommands->%*) {
			specError("%sinvalid command name '%s'", $where, $name) if !isValidName($name);
			my $childPath = $path eq '' ? $name : $path . ' ' . $name;
			$commands{$name} = __CLASS__->new(raw => $rawCommands->{$name}, path => $childPath);
		}

		specError("%sargs and commands are mutually exclusive on one level", $where) if @args && %commands;

		if (exists $spec{commandRequired}) {
			specError("%scommandRequired without commands", $where) if !%commands;
			$commandRequired = delete $spec{commandRequired} ? 1 : 0;
		}

		$description = delete $spec{description} // '';

		my $rawExamples = delete $spec{examples} // [];
		specError("%s'examples' must be an array reference", $where) if ref $rawExamples ne 'ARRAY';
		foreach my $example ($rawExamples->@*) {
			specError("%seach example must be a hash with 'text' and 'args'", $where)
				if ref $example ne 'HASH' || !defined $example->{text} || !defined $example->{args};
			push @examples, { text => $example->{text}, args => $example->{args} };
		}

		specError("%sunknown key(s): %s", $where, join(', ', sort keys %spec)) if %spec;

		my %readerSource;
		foreach my $entry (@options, @args) {
			my $label = $entry->isa('Getopt::Pad::Spec::Option') ? sprintf("option '%s'", $entry->name) : sprintf("arg '%s'", $entry->short);
			my $seen  = $readerSource{$entry->reader};
			specError("%s%s and %s both map to reader '%s'", $where, $label, $seen, $entry->reader) if defined $seen;
			$readerSource{$entry->reader} = $label;
		}
	}

	method addOption($option) {
		my $name = $option->name;
		foreach my $candidate ($name, $option->aliases) {
			my $owner = $takenNames{$candidate} // next;
			specError("%soption '%s' collides with the automatic --%s option", $self->where, $candidate, $candidate) if $option->auto;
			specError("%soption '%s': name '%s' is already used by %s", $self->where, $name, $candidate, $owner);
		}

		$takenNames{$name} = sprintf("option '%s'", $name);
		$takenNames{$_} = sprintf("an alias of option '%s'", $name) foreach $option->aliases;
		push @options, $option;
		$optionByName{$name} = $option;
		return $self;
	}

	method isRoot()          { return $path eq '' ? 1 : 0 }
	method where()           { return $self->isRoot ? '' : sprintf("command '%s': ", $path) }
	method options()         { return @options }
	method declaredOptions() { return grep { !$_->auto } @options }
	method args()            { return @args }
	method examples()        { return @examples }
	method hasArgs()         { return @args ? 1 : 0 }
	method hasCommands()     { return %commands ? 1 : 0 }

	method optionByName($name) { return $optionByName{$name} }
	method commandNames()      { return sort keys %commands }
	method command($name)      { return $commands{$name} }
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Spec::Level - one spec level

=head1 DESCRIPTION

One level of a spec: its options plus either positional args or subcommands. Enforces name and alias uniqueness across all options of the level, reader uniqueness, arg ordering, and the args/commands exclusivity. options returns every option including the auto options; declaredOptions only those the spec declares.

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
