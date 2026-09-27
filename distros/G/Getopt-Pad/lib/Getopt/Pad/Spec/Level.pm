use v5.26;
use Object::Pad;

use Getopt::Pad::Spec::Option;
use Getopt::Pad::Spec::Arg;

class Getopt::Pad::Spec::Level :strict(params) {
	use Getopt::Pad::Util qw(specError isValidName);

	our $VERSION = '0.04';

	field $raw  :param;
	field $path :param :reader = '';

	field @options;
	field @inheritedOptions;
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

		my @inheritable = grep { $_->inherit } @options;
		specError("%soption '%s': inherit requires commands on the same level", $where, $inheritable[0]->name) if @inheritable && !%commands;

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

		$self->takeNames($option);
		push @options, $option;
		$optionByName{$name} = $option;
		return $self;
	}

	# An option an outer Level passes on: accepted on this Level's command
	# line, but neither configurable nor readable here.
	method inheritOption($option, $fromLevel) {
		my $name = $option->name;
		foreach my $candidate ($name, $option->aliases) {
			my $owner = $takenNames{$candidate} // next;
			specError("%soption '%s' collides with the automatic --%s option", $self->where, $candidate, $candidate) if $option->auto;
			specError("%soption '%s' inherited from %s: name '%s' is already used by %s", $self->where, $name, $fromLevel->label, $candidate, $owner);
		}

		$self->takeNames($option);
		push @inheritedOptions, $option;
		return $self;
	}

	method takeNames($option) {
		my $name = $option->name;
		$takenNames{$name} = sprintf("option '%s'", $name);
		$takenNames{$_} = sprintf("an alias of option '%s'", $name) foreach $option->aliases;
		return;
	}

	method isRoot()             { return $path eq '' ? 1 : 0 }
	method label()              { return $self->isRoot ? 'the top level' : sprintf("command '%s'", $path) }
	method where()              { return $self->isRoot ? '' : $self->label . ': ' }
	method options()            { return (@options, @inheritedOptions) }
	method declaredOptions()    { return grep { !$_->auto } @options }
	method inheritableOptions() { return grep { $_->inherit } @options }
	method inheritedOptions()   { return @inheritedOptions }
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

Getopt::Pad::Spec::Level - One level of a spec: the top level or one
command (internal)

=head1 DESCRIPTION

This module is internal to Getopt::Pad. It is not part of the public
API and can change without notice. Programs use L<Getopt::Pad/GetOptions>;
this page is for people working on Getopt::Pad itself.

A level holds its options and either its args or its commands. It is
built from the hash of one level of the spec and checks everything that
concerns the level as a whole:

=over 4

=item *

every name and alias is used by only one option of the level, including
the options it inherits from outer levels and the automatic options;

=item *

no two options or args map to the same reader;

=item *

only the last arg has C<multiple>, and no required arg follows an optional
one;

=item *

a level has args or commands, not both;

=item *

only a level with commands marks options C<inherit>, and only such a level
has C<commandRequired>;

=item *

command names are valid names, C<examples> are well formed, and there are
no unknown keys.

=back

Commands are built recursively as levels of their own, each with its
command path.

=head1 METHODS

=over 4

=item path

The command path of the level, such as C<image resize>; the empty string
for the top level.

=item isRoot, label, where

Whether this is the top level; its name in messages (C<the top level> or
C<command 'PATH'>); and the prefix of spec errors about it (empty for the
top level, C<command 'PATH': > otherwise).

=item options

Every option the level's command line accepts: its own options, the
automatic options attached to it, and the options it inherits.

=item declaredOptions

Only the level's own options from the spec, without automatic and
inherited options. These are the options with readers.

=item inheritableOptions, inheritedOptions

The level's own options that are passed on to the levels below, and the
options it received from the levels above.

=item optionByName($name)

One of the level's own options, by primary name, or C<undef>. Inherited
options are not found here.

=item args, hasArgs

The arg specs in order, and whether there are any.

=item commandNames, command($name), hasCommands, commandRequired

The sorted command names, the level of one command, whether there are
commands, and whether one must be named.

=item description, examples

As given in the spec.

=item addOption($option), inheritOption($option, $fromLevel)

Used while the spec is built: add an own or automatic option, or an
option inherited from C<$fromLevel>. Both reserve the option's names on
this level.

=back

=head1 SEE ALSO

L<Getopt::Pad::Spec>, L<Getopt::Pad::Spec::Option>,
L<Getopt::Pad::Spec::Arg>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
