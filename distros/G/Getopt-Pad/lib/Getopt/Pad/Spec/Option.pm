use v5.26;
use Object::Pad;

use Getopt::Pad::Type;
use Getopt::Pad::Error;
use Getopt::Pad::Result;

class Getopt::Pad::Spec::Option :strict(params) {
	use Carp qw(croak);
	use Getopt::Pad::Util qw(camelize specError isValidName optionSpelling processedWith);

	our $VERSION = '0.06';

	# The Value sources a parse hands over, in order of precedence, each with
	# the wording of its user errors, which name the option as typed on the
	# command line and by its Primary name in a config file; the spec
	# default follows them. The command line gives a multiple option one
	# word per occurrence, a config file a lone value or a list.
	my @valueSources = (
		{ key => 'commandLine', problemFormat => "option '%s': %s",           givesWords => 1, namesAsTyped => 1 },
		{ key => 'config',      problemFormat => "config value for '%s': %s", givesWords => 0, namesAsTyped => 0 },
	);
	my %isValueSource = map { $_->{key} => 1 } @valueSources;

	field $key           :param;
	field $raw           :param;
	field $auto          :param :reader = 0;
	field $optionalValue :param :reader = 0;
	field $trigger       :param :reader = undef;
	# Where the option sits in the spec, as the start of a spec error, e.g.
	# "command 'image resize': ".
	field $where         :param = '';

	field $name     :reader;
	field @aliases  :reader;
	field $reader   :reader;
	field $type     :reader;
	field $typeName :reader;
	field $required   :reader = 0;
	field $hasDefault :reader = 0;
	field $default    :reader;
	field $specDefault;
	field $valid     :reader;
	field $lazyValid;
	field $processValue :reader;
	field $group    :reader;
	field $help     :reader = '';
	field $multiple   :reader = 0;
	field $hash       :reader = 0;
	field $csv        :reader = 0;
	field $objectlist :reader = 0;
	field $hidden     :reader = 0;
	field $inherit    :reader = 0;
	field $typehint   :reader;

	ADJUST {
		specError("%soption key must be a non-empty string", $where) if !defined $key || $key eq '';
		specError("%soption '%s': spec must be a hash reference", $where, $key) if ref $raw ne 'HASH';
		specError("%soption '%s': a trigger is only allowed on auto options", $where, $key) if defined $trigger && !$auto;

		($name, @aliases) = split /\|/, $key, -1;
		foreach my $candidate ($name, @aliases) {
			specError("%soption '%s': invalid name '%s'", $where, $key, $candidate // '') if !isValidName($candidate);
		}
		$reader = camelize($name);
		specError("%soption '%s': reader '%s' collides with a built-in result method", $where, $name, $reader) if !$auto && Getopt::Pad::Result->reservesReader($reader);

		my %spec = $raw->%*;
		($type, $typeName) = Getopt::Pad::Type::takeFromSpec(\%spec, 'flag', sprintf("%soption '%s'", $where, $name));

		$required = delete $spec{required} ? 1 : 0;
		if (exists $spec{default}) {
			$hasDefault = 1;
			$default    = delete $spec{default};
			$specDefault = $default;
		}
		$valid     = delete $spec{valid};
		$lazyValid = delete $spec{lazyValid};
		$processValue = delete $spec{processValue};
		$group    = delete $spec{group} // 'Options';
		$help     = delete $spec{help} // '';
		$multiple   = delete $spec{multiple} ? 1 : 0;
		$hash       = delete $spec{hash} ? 1 : 0;
		$csv        = delete $spec{csv} ? 1 : 0;
		$objectlist = delete $spec{objectlist} ? 1 : 0;
		$hidden     = delete $spec{hidden} ? 1 : 0;
		$inherit    = delete $spec{inherit} ? 1 : 0;
		$typehint   = delete $spec{typehint};

		specError("%soption '%s': unknown key(s): %s", $where, $name, join(', ', sort keys %spec)) if %spec;
		specError("%soption '%s': required and default are mutually exclusive", $where, $name) if $required && $hasDefault;
		my %shapeFlags = (multiple => $multiple, hash => $hash, objectlist => $objectlist);
		my @shapes     = grep { $shapeFlags{$_} } qw(multiple hash objectlist);
		specError("%soption '%s': %s requires a value-taking type, not '%s'", $where, $name, $shapes[0], $typeName) if @shapes && !$type->takesValue;
		specError("%soption '%s': %s are mutually exclusive", $where, $name, join(' and ', @shapes)) if @shapes > 1;
		specError("%soption '%s': csv requires multiple", $where, $name) if $csv && !$multiple;
		specError("%soption '%s': valid must be an array or code reference", $where, $name) if defined $valid && ref $valid ne 'ARRAY' && ref $valid ne 'CODE';
		specError("%soption '%s': lazyValid must be a code reference", $where, $name) if defined $lazyValid && ref $lazyValid ne 'CODE';
		specError("%soption '%s': processValue must be a code reference", $where, $name) if defined $processValue && ref $processValue ne 'CODE';
		specError("%soption '%s': typehint must be a non-empty string", $where, $name) if defined $typehint && (ref $typehint || $typehint eq '');

		$default = $self->checkedDefault($default) if $hasDefault;
	}

	# The spec default in the option's shape, every value checked and
	# coerced. Only a scalar default may be undef: it means "no default"
	# to the help output.
	method checkedDefault($value) {
		return undef if !defined $value && !$multiple && !$hash && !$objectlist;
		return $self->shapedValue($value, sub ($problem) { specError("%soption '%s': default value: %s", $where, $name, $problem) });
	}

	# The default as help output and config files show it: as the spec
	# wrote it. A converted value may not read back (a duration coerced to
	# seconds), or be an object that cannot be shown at all.
	method presentedDefault() {
		return $specDefault;
	}

	# The Primary name as it is typed on the command line.
	method spelling() {
		return optionSpelling($name);
	}

	# What the reader gets when no value source set the option and the spec
	# has no default: an empty list or mapping, or undef.
	method emptyValue() {
		return [] if $multiple || $objectlist;
		return {} if $hash;
		return undef;
	}

	# Each parse gets its own copy of a list, mapping or objectlist default.
	method copiedDefault() {
		return [map { ref $_ eq 'HASH' ? { $_->%* } : $_ } $default->@*] if ref $default eq 'ARRAY';
		return { $default->%* } if ref $default eq 'HASH';
		return $default;
	}

	# Whether the option collects key=value words: a hash option, or an
	# objectlist option with its INDEX.FIELD keys.
	method takesPairs() {
		return $hash || $objectlist ? 1 : 0;
	}

	# The tag the help output renders after the help text: the spec's
	# typehint, or what the type calls itself.
	method typeLabel() {
		return $typehint // $type->label;
	}

	# The values the valid constraint allows right now: the static list, or
	# what the valid coderef produces when asked. Empty without a constraint.
	method validValues() {
		return () if !defined $valid;
		return $valid->@* if ref $valid eq 'ARRAY';

		my $values = $valid->();
		specError("%soption '%s': the valid coderef must return an array reference", $where, $name) if ref $values ne 'ARRAY';
		return $values->@*;
	}

	# Check $value's shape, then the type, the valid list and the lazyValid
	# predicate. Returns the problem description (undef when the value is
	# acceptable) and the coerced value; the caller decides how to report
	# the problem.
	method checkValue($value) {
		return ('expected a single value, not a list or mapping', $value) if ref $value eq 'ARRAY' || ref $value eq 'HASH';

		my $problem = $type->check($value);
		return ($problem, $value) if defined $problem;

		$value = $type->coerce($value);
		if (defined $valid) {
			my @allowed = $self->validValues;
			return (sprintf("'%s' is not one of: %s", $value, join(', ', @allowed)), $value) if !grep { $_ eq $value } @allowed;
		}
		return (sprintf("'%s' is not a valid value", $value), $value) if defined $lazyValid && !$lazyValid->($value);
		return (undef, $value);
	}

	# The checked value one parse settles on, and the reporter for the
	# problems its type's verify and prepare find in it later, worded for
	# where the value came from. The empty value of an option no source
	# sets leaves nothing to verify: its reporter is undef. %sources maps
	# each Value source to the raw values it gave, keyed by Primary name; a
	# name missing from a map means that source did not set the option.
	method settledValue(%sources) {
		my @unknown = grep { !$isValueSource{$_} } sort keys %sources;
		croak(sprintf("Getopt::Pad: unknown value source(s): %s", join(', ', @unknown))) if @unknown;

		foreach my $source (@valueSources) {
			my $given = $sources{$source->{key}} // {};
			next if !exists $given->{$name};

			my $report = $self->reporterFor($source);
			return ($self->validatedValue($given->{$name}, $source, $report), $report);
		}

		return ($self->copiedDefault, $self->defaultReporter) if $hasDefault;
		Getopt::Pad::Error->throw("missing required option '%s'", $self->spelling) if $required;
		return ($self->emptyValue, undef);
	}

	# The checked value one parse settles on, see settledValue.
	method readerValue(%sources) {
		my ($value) = $self->settledValue(%sources);
		return $value;
	}

	method processedValue($result, $value) {
		return processedWith($processValue, $result, $value);
	}

	# A reporter that throws a problem in the wording of $source: the
	# option named as typed for the command line, by its Primary name for
	# a config file.
	method reporterFor($source) {
		my $named = $source->{namesAsTyped} ? $self->spelling : $name;
		return sub ($problem) { Getopt::Pad::Error->throw($source->{problemFormat}, $named, $problem) };
	}

	method defaultReporter() {
		return sub ($problem) { Getopt::Pad::Error->throw("option '%s': default value: %s", $self->spelling, $problem) };
	}

	# The value one source gave, in the option's shape, with problems told
	# to $report. The command line gives a multiple option its words and a
	# pair-taking option a flat mapping of its key=value pairs; a config
	# file gives the shape directly.
	method validatedValue($value, $source, $report) {
		return [map { $self->checkedScalar($_, $report) } $self->listItems($value, $source, $report)] if $multiple;
		$value = $self->objectsFromPairs($value, $report) if $objectlist && $source->{givesWords};
		return $self->shapedValue($value, $report);
	}

	# The items a multiple option received from $source. A csv option splits
	# every word and every lone config value at commas; a config list is
	# taken as given.
	method listItems($value, $source, $report) {
		my $isConfigList = ref $value eq 'ARRAY' && !$source->{givesWords};
		return $value->@* if $isConfigList;

		my @scalars = ref $value eq 'ARRAY' ? $value->@* : ($value);
		return @scalars if !$csv;
		return map { $self->csvItems($_, $report) } @scalars;
	}

	# Items are trimmed; one trailing comma is tolerated, an empty item is
	# not. An undefined value passes through to be reported as missing.
	method csvItems($word, $report) {
		return ($word) if !defined $word;

		my $trimmed = $word =~ s/\A\s+|\s+\z//gr =~ s/,\z//r;
		my @items   = map { s/\A\s+|\s+\z//gr } split /,/, $trimmed, -1;
		$report->(sprintf("'%s' contains an empty item", $word)) if !@items || grep { $_ eq '' } @items;
		return @items;
	}

	# The objects an objectlist option collects from its INDEX.FIELD=VALUE
	# words, handed over as a flat mapping. The indices must form 0..n-1,
	# each written one way only: a leading zero would make 0 and 00 two
	# keys for one object.
	method objectsFromPairs($pairs, $report) {
		my %objectAt;
		foreach my $key (sort keys $pairs->%*) {
			$report->(sprintf("invalid key '%s', the index must not have leading zeros", $key)) if $key =~ /\A0[0-9]+\./;
			my ($index, $field) = $key =~ /\A([0-9]+)\.([\w-]+)\z/ or $report->(sprintf("invalid key '%s', expected INDEX.FIELD=VALUE", $key));
			$objectAt{$index}{$field} = $pairs->{$key};
		}

		# The sorted indices match their positions unless one is missing;
		# comparing them needs no array as large as the largest index.
		my @indices = sort { $a <=> $b } keys %objectAt;
		foreach my $position (0 .. $#indices) {
			$report->(sprintf('missing index %d', $position)) if $indices[$position] != $position;
		}
		return [map { $objectAt{$_} } @indices];
	}

	# $value in the option's shape with every scalar checked and coerced: a
	# list for multiple, a mapping for hash, a list of mappings for
	# objectlist, else one scalar. $report is told about a problem, worded
	# without the option name, and does not return.
	method shapedValue($value, $report) {
		return $self->shapedList($value, $report)    if $multiple;
		return $self->shapedMapping($value, $report) if $hash;
		return $self->shapedObjects($value, $report) if $objectlist;
		return $self->checkedScalar($value, $report);
	}

	method shapedList($value, $report) {
		$report->('expected a list of values') if ref $value ne 'ARRAY';
		return [map { $self->checkedScalar($_, $report) } $value->@*];
	}

	method shapedMapping($value, $report) {
		$report->('expected a mapping of keys to values') if ref $value ne 'HASH';

		my %checked;
		foreach my $key (sort keys $value->%*) {
			$report->('empty key') if $key eq '';
			$checked{$key} = $self->checkedScalar($value->{$key}, $self->reportUnder($report, sprintf("key '%s'", $key)));
		}
		return \%checked;
	}

	method shapedObjects($value, $report) {
		$report->('expected a list of mappings') if ref $value ne 'ARRAY';
		return [map { $self->shapedMapping($value->[$_], $self->reportUnder($report, sprintf('entry %d', $_))) } 0 .. $#$value];
	}

	# A reporter that prefixes where the problem sits, e.g. "key 'os': ...".
	method reportUnder($report, $where) {
		return sub ($problem) { $report->(sprintf('%s: %s', $where, $problem)) };
	}

	method checkedScalar($value, $report) {
		$report->('no value given') if !defined $value;

		my ($problem, $coerced) = $self->checkValue($value);
		$report->($problem) if defined $problem;
		return $coerced;
	}

	method glSpec() {
		return $type->glSpec(join('|', $name, @aliases), optionalValue => $optionalValue, multiple => $multiple, hash => $self->takesPairs);
	}

	method negatable() {
		return $type->negatable;
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Spec::Option - One option of a spec, and how its value is
resolved (internal)

=head1 DESCRIPTION

This module is internal to Getopt::Pad. It is not part of the public
API and can change without notice. Programs use L<Getopt::Pad/GetOptions>;
this page is for people working on Getopt::Pad itself.

An option spec holds the checked settings of one option: the primary
name, the aliases, the reader name, the type (a L<Getopt::Pad::Type>
instance) and the keys C<required>, C<default>, C<valid>, C<lazyValid>,
C<group>, C<help>, C<multiple>, C<hash>, C<csv>, C<objectlist>,
C<hidden>, C<inherit>, C<typehint> and C<processValue>. The meaning of each key is
documented in L<Getopt::Pad/OPTION SPECS>.

The constructor checks every key and their combinations, and checks and
converts the default in the option's shape: a list for C<multiple>, a
mapping for C<hash>, a list of mappings for C<objectlist>, else a single
value. An invalid default is a spec error. Spec errors start with the
optional C<where> constructor param, which the declaring
L<Getopt::Pad::Spec::Level> sets to its command path
(C<command 'image resize': >).

=head2 Resolving a value

C<settledValue(%sources)> returns the checked value of the option for
one parse, and a reporter: a coderef that throws a problem found in the
value later (by the type's C<verify> or C<prepare>) as a
L<Getopt::Pad::Error> worded for the value's source, C<option '--NAME':
default value: ...> for the default. The reporter is C<undef> when
neither a source nor a default set the option. C<readerValue(%sources)>
returns the value alone. C<%sources> maps each value source (C<commandLine>, C<config>) to
the raw values it gave, keyed by primary name. The option takes the first
source that set it, in that order, or else the default. Without either,
a required option throws a L<Getopt::Pad::Error>, and any other option
reads as an empty list (C<multiple>, C<objectlist>), an empty mapping
(C<hash>) or C<undef>.

The raw value is brought into the option's shape: the words of a C<csv>
option and a single config value are split at commas, and the
C<INDEX.FIELD=VALUE> pairs of an C<objectlist> option are collected into
its list of mappings. Then every single value passes C<checkValue>: the
type's C<check> and C<coerce>, the C<valid> list and the C<lazyValid>
predicate. Problems are thrown as L<Getopt::Pad::Error>, worded for their
source (C<option '--NAME': ...> or C<config value for 'NAME': ...>) and
naming the key or entry for C<hash> and C<objectlist> options.

The type's C<verify> and C<prepare> are not called here: the parser
calls them on the settled values of every selected level, see
L<Getopt::Pad::Parser/Second pass: the values>.

C<processedValue($result, $value)> runs the C<processValue> coderef on
that reader value: every single value in it is replaced by what the
coderef returns when called with C<$result> and the value, the list or
mapping around them is kept (see C<processedWith> in
L<Getopt::Pad::Util>). An unset single value (C<undef>) is left alone.
Without C<processValue> the value is returned as it is.

=head1 METHODS

Besides the readers of its settings (C<name>, C<aliases>, C<reader>,
C<type>, C<typeName>, C<required>, C<hasDefault>, C<default>, C<valid>,
C<group>, C<help>, C<multiple>, C<hash>, C<csv>, C<objectlist>,
C<hidden>, C<inherit>, C<typehint>, C<processValue>, C<auto>,
C<optionalValue>, C<trigger>):

=over 4

=item settledValue(%sources), readerValue(%sources)

See L</Resolving a value>.

=item processedValue($result, $value)

See L</Resolving a value>.

=item checkValue($value)

Checks one single value; returns the problem (or C<undef>) and the
converted value.

=item validValues

The values the C<valid> key allows right now: the static list, or what
the coderef returns (a spec error unless it returns an arrayref). Empty
without C<valid>. Shell completion uses it too.

=item typeLabel

The tag the help output shows: C<typehint>, or the type's C<label>.

=item presentedDefault

The default as the help output and C<--create-default-config> show it:
as the spec wrote it, unchecked and unconverted. A converted value may
not read back in (a duration converted to seconds) or be an object.

=item spelling

The primary name as it is typed: with one dash for a name of one letter
(C<-v>), else with two (C<--verbose>). Command line errors name the
option this way.

=item takesPairs

Whether the option collects C<KEY=VALUE> words (C<hash> and
C<objectlist>).

=item glSpec, negatable

The L<Getopt::Long> specification of the option, and whether it can be
negated, both from its type.

=back

Automatic options are option specs with C<auto> set; they may carry a
C<trigger> (see L<Getopt::Pad::Spec>), and C<--config> has
C<optionalValue>.

=head1 SEE ALSO

L<Getopt::Pad::Spec::Level>, L<Getopt::Pad::Type>

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
