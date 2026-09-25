use v5.26;
use Object::Pad;

class Getopt::Pad::Help :strict(params) {
	use Feature::Compat::Try;
	use List::Util      qw(max);
	use File::Basename  qw(basename);
	use Getopt::Pad::Util qw(useColor);
	use Text::Wrap ();

	our $VERSION = '0.03';

	field $level       :param;
	field $version     :param = undef;
	field $programName :param = undef;
	field $width       :param = undef;
	field $color       :param = undef;
	field $handle      :param = \*STDOUT;

	field @commandPath;
	field $labelWidth;

	ADJUST {
		$programName //= basename($0);
		@commandPath = split ' ', $level->path;
	}

	# The terminal is consulted when something is rendered, not when the
	# Helper is built: a parse builds one per Level without printing, and
	# $result->help may run much later, on a terminal of another size.
	method width() { return $width //= $self->detectWidth }
	method color() { return $color //= useColor($handle) }

	method labelWidth() {
		return $labelWidth //= do {
			my @labels = ((map { $self->optionLabel($_) } grep { !$_->hidden } $level->options), (map { $self->argLabel($_) } $level->args), $level->commandNames);
			3 + max(0, map { length } @labels) + 5;
		};
	}

	method detectWidth() {
		return $ENV{COLUMNS} if ($ENV{COLUMNS} // '') =~ /^\d+$/ && $ENV{COLUMNS} > 0;

		if (-t $handle) {
			try {
				require Term::ReadKey;
				local $SIG{__WARN__} = sub { };
				my ($columns) = Term::ReadKey::GetTerminalSize($handle);
				return $columns if $columns;
			}
			catch ($error) { }
		}

		return 100;
	}

	method paint($text, $ansiCode) {
		return $self->color ? sprintf("\e[%sm%s\e[0m", $ansiCode, $text) : $text;
	}

	method printHelp() {
		print {$handle} $self->renderHelp;
		return $self;
	}

	method printVersion() {
		print {$handle} $self->renderVersion, "\n";
		return $self;
	}

	method renderVersion() {
		my $shown = $version // $main::VERSION // 'unknown';
		return sprintf('%s %s', $programName, $shown);
	}

	method renderHelp() {
		my @visibleOptions = grep { !$_->hidden } $level->options;
		my @args           = $level->args;

		my @blocks = ($self->headerBlock(\@visibleOptions, \@args));
		push @blocks, $self->argsBlock(\@args)             if @args;
		push @blocks, $self->optionBlocks(\@visibleOptions) if @visibleOptions;
		push @blocks, $self->commandsBlock                  if $level->hasCommands;
		push @blocks, $self->examplesBlock                  if $level->examples;

		return join("\n\n", @blocks) . "\n";
	}

	my %palette = (
		usage        => '1;31',
		description  => '94',
		section      => '92',
		annotation   => '31',
		typeLabel    => '90',
		subKey       => '33',
		validValue   => '36',
		defaultValue => '35',
	);

	method headerBlock($options, $args) {
		my @tokens = ($programName, @commandPath);
		push @tokens, '[options]' if $options->@*;
		push @tokens, '<command>' if $level->hasCommands;
		foreach my $arg ($args->@*) {
			my $token = $arg->short;
			$token .= '...' if $arg->multiple;
			$token = sprintf('[%s]', $token) if !$arg->required;
			push @tokens, $token;
		}

		my $block = $self->paint('# ' . join(' ', @tokens), $palette{usage});
		$block .= "\n" . $self->paint('# ' . $level->description, $palette{description}) if $level->description ne '';
		return $block;
	}

	method sectionHeader($title) {
		return $self->paint('## ' . $title, $palette{section});
	}

	method argsBlock($args) {
		my @lines = ($self->sectionHeader('Arguments'));
		foreach my $arg ($args->@*) {
			my @parts;
			push @parts, ['[REQ]', $palette{annotation}] if $arg->required;
			push @parts, [$arg->help, undef] if $arg->help ne '';
			push @parts, [sprintf('[%s]', $arg->typeLabel), $palette{typeLabel}] if defined $arg->typeLabel;
			push @lines, $self->entryLines($self->argLabel($arg), \@parts);
		}
		return join("\n", @lines);
	}

	method optionBlocks($options) {
		my %grouped;
		push $grouped{$_->group}->@*, $_ foreach $options->@*;

		my @blocks;
		foreach my $group (sort keys %grouped) {
			my @lines = ($self->sectionHeader($group));
			foreach my $option ($grouped{$group}->@*) {
				my @parts;
				push @parts, ['[REQ]', $palette{annotation}] if $option->required;
				push @parts, map { [sprintf('[%s]', $_), $palette{annotation}] } $option->type->constraintNotes;
				push @parts, [$option->help, undef] if $option->help ne '';
				push @parts, [sprintf('[%s]', $option->typeLabel), $palette{typeLabel}] if defined $option->typeLabel;
				push @lines, $self->entryLines($self->optionLabel($option), \@parts);

				my $subIndent = ' ' x ($self->labelWidth + 4);
				push @lines, $subIndent . $self->paint('Valid', $palette{subKey})
					. '   = [ ' . join(', ', map { $self->paint($_, $palette{validValue}) } $option->valid->@*) . ' ]'
					if ref $option->valid eq 'ARRAY';
				# An undefined default is the same as none to the reader of the help.
				push @lines, $subIndent . $self->paint('Default', $palette{subKey})
					. ' = ' . $self->paint($self->stringifyDefault($option->default), $palette{defaultValue})
					if $option->hasDefault && defined $option->default;
			}
			push @blocks, join("\n", @lines);
		}
		return @blocks;
	}

	method commandsBlock() {
		my @lines = ($self->sectionHeader('Commands'));
		foreach my $name ($level->commandNames) {
			push @lines, $self->entryLines($name, [[$level->command($name)->description, undef]]);
		}
		return join("\n", @lines);
	}

	method examplesBlock() {
		my @lines = ($self->paint('# Examples:', $palette{usage}));
		foreach my $example ($level->examples) {
			push @lines, $self->paint('## ' . $example->{text}, $palette{section});
			push @lines, $self->paint('##', $palette{section}) . '   ' . join(' ', $programName, @commandPath, $example->{args});
			push @lines, '';
		}
		pop @lines while @lines && $lines[-1] eq '';
		return join("\n", @lines);
	}

	method optionLabel($option) {
		my $label = sprintf($option->negatable ? '--[no-]%s' : '--%s', $option->name);
		return $label . ' <key=value>'   if $option->hash;
		return $label . ' <N.key=value>' if $option->objectlist;
		return $label . ' <a,b,...>'     if $option->csv;
		return $label . ' <>'          if $option->type->takesValue;
		return $label;
	}

	method argLabel($arg) {
		return sprintf('<%s>', $arg->short);
	}

	# $parts is an arrayref of [text, ansiCode] pairs; wrapping happens on the
	# plain text and colors are substituted in afterwards, so escape codes
	# never distort the width computation or the column alignment.
	method entryLines($label, $parts) {
		my $text   = join(' ', grep { length } map { $_->[0] } $parts->@*);
		my $padded = sprintf('   %-*s', $self->labelWidth - 3, $label);

		my $block;
		if ($text eq '') {
			$block = $padded =~ s/\s+$//r;
		}
		else {
			# Text::Wrap widens its columns to fit the indent itself, with a
			# warning; do it up front so narrow terminals stay quiet.
			local $Text::Wrap::columns  = max($self->width, $self->labelWidth + 2);
			local $Text::Wrap::huge     = 'overflow';
			local $Text::Wrap::unexpand = 0;
			$block = Text::Wrap::wrap($padded, ' ' x $self->labelWidth, $text);
		}

		return $block if !$self->color;
		return $self->paintParts($block, $parts, length $padded);
	}

	# Parts are painted in occurrence order, each searched only past the previous
	# one, so a part whose text also appears in an earlier part never steals the
	# paint. A part the wrapping broke across lines is painted word by word.
	method paintParts($block, $parts, $searchFrom) {
		foreach my $part (grep { length $_->[0] } $parts->@*) {
			my @pieces = index($block, $part->[0], $searchFrom) < 0 ? grep { length } split(/\s+/, $part->[0]) : ($part->[0]);
			foreach my $piece (@pieces) {
				my $at = index($block, $piece, $searchFrom);
				next if $at < 0;
				my $painted = defined $part->[1] ? $self->paint($piece, $part->[1]) : $piece;
				substr($block, $at, length $piece) = $painted;
				$searchFrom = $at + length $painted;
			}
		}
		return $block;
	}

	method stringifyDefault($default) {
		return $default if !ref $default;
		return join(', ', map { sprintf('%s=%s', $_, $default->{$_}) } sort keys $default->%*) if ref $default eq 'HASH';
		return join(', ', map { $self->stringifyEntry($default->[$_], $_) } 0 .. $#$default);
	}

	# A list entry: the value itself, or for an objectlist the entry's pairs
	# prefixed with its index.
	method stringifyEntry($entry, $index) {
		return $entry if ref $entry ne 'HASH';
		return $self->stringifyDefault({ map { (sprintf('%d.%s', $index, $_) => $entry->{$_}) } keys $entry->%* });
	}
}

1;

__END__

=encoding utf8

=head1 NAME

Getopt::Pad::Help - usage and version renderer

=head1 DESCRIPTION

Renders the usage and version output for one spec Level: header, Arguments section, grouped options with annotations, Commands section, and examples - wrapped to the terminal width and colorized on a tty. Constructed through the Spec's helperFor method; the command path shown in the header is derived from the Level itself.

Part of the L<Getopt::Pad> distribution; see its documentation for the user-facing API.

=head1 AUTHOR

davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
