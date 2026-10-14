package Game::Terminal::Kit::Options;

use 5.014;
use strict;
use warnings;

use Text::ParseWords ();

our $VERSION = '0.05';

my %TYPE = map { $_ => 1 } qw/int enum flag bool str/;
my %RESERVED = map { $_ => 1 } qw/ascii pick help version extra/;

sub types { return sort keys %TYPE }

sub reserved { return sort keys %RESERVED }

sub step_value {
	my ($field, $current, $direction) = @_;
	my $type = $field->{type};
	if ($type eq 'int') {
		return $direction > 0 ? $field->{min} : $field->{max} unless defined $current;
		my $next = $current + $direction;
		return $next < $field->{min} ? $field->{min} : $next > $field->{max} ? $field->{max} : $next;
	}
	if ($type eq 'enum') {
		my @choices = @{$field->{choices}};
		return $direction > 0 ? $choices[0] : $choices[-1] unless defined $current;
		my ($index) = grep { $choices[$_] eq $current } 0 .. $#choices;
		$index = 0 unless defined $index;
		return $choices[ ($index + $direction) % @choices ];
	}
	if ($type eq 'flag') {
		return $current ? undef : 1;
	}
	if ($type eq 'bool') {
		my @cycle = (undef, 1, 0);
		my $index = !defined $current ? 0 : $current ? 1 : 2;
		return $cycle[ ($index + $direction) % 3 ];
	}
	return $current;
}

sub check_value {
	my ($field, $text) = @_;
	$text = '' unless defined $text;
	$text =~ s/^\s+|\s+$//g;
	return (undef, undef) unless length $text;
	my $type = $field->{type};
	if ($type eq 'int') {
		return (undef, "$field->{name} takes a whole number from $field->{min} to $field->{max}")
			unless $text =~ m/^-?\d+$/ && $text >= $field->{min} && $text <= $field->{max};
		return ($text + 0, undef);
	}
	if ($type eq 'enum') {
		my ($match) = grep { lc $_ eq lc $text } @{$field->{choices}};
		return ($match, undef) if defined $match;
		return (undef, "$field->{name} takes " . join(', ', @{$field->{choices}}));
	}
	return ($text, undef);
}

sub argv_for {
	my ($fields, $values) = @_;
	$values ||= {};
	my @argv;
	for my $field (@{ $fields || [] }) {
		my $value = $values->{ $field->{name} };
		next unless defined $value;
		my $type = $field->{type};
		if ($type eq 'flag') {
			push @argv, "--$field->{name}" if $value;
		} elsif ($type eq 'bool') {
			push @argv, $value ? "--$field->{name}" : "--no-$field->{name}";
		} else {
			push @argv, "--$field->{name}", $value;
		}
	}
	push @argv, Text::ParseWords::shellwords($values->{extra})
		if defined $values->{extra} && length $values->{extra};
	return @argv;
}

sub validate {
	my ($fields) = @_;
	return ('the options are not an array reference') unless ref $fields eq 'ARRAY';
	my (@wrong, %seen);
	for my $index (0 .. $#{$fields}) {
		my $field = $fields->[$index];
		unless (ref $field eq 'HASH') {
			push @wrong, "option $index is not a hash reference";
			next;
		}
		my $name = $field->{name};
		unless (defined $name && $name =~ m/^[a-z][a-z0-9-]*$/) {
			push @wrong, "option $index has no name a command line could carry";
			next;
		}
		push @wrong, "$name is there twice" if $seen{$name}++;
		push @wrong, "$name is a name the launcher keeps" if $RESERVED{$name};
		push @wrong, "$name has no help"
			unless defined $field->{help} && length $field->{help};
		my $type = $field->{type};
		unless (defined $type && $TYPE{$type}) {
			push @wrong, "$name has no known type";
			next;
		}
		if ($type eq 'int') {
			my @ends = grep { defined $_ && m/^-?\d+$/ } $field->{min}, $field->{max};
			push @wrong, "$name needs a whole min and max, min first"
				unless @ends == 2 && $field->{min} <= $field->{max};
		}
		if ($type eq 'enum') {
			my $choices = $field->{choices};
			push @wrong, "$name needs two or more choices"
				unless ref $choices eq 'ARRAY' && @{$choices} >= 2
				&& !grep { !defined $_ || !length $_ } @{$choices};
		}
	}
	return @wrong;
}

1;

__END__

=head1 NAME

Game::Terminal::Kit::Options - the options a game offers before it starts

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    package Game::Checkers::Terminal;

    sub options {
        return [
            { name => 'level', type => 'int', min => 1, max => 5,
              help => 'the strength of the bot' },
            { name => 'side', type => 'enum', choices => [qw(black white random)],
              help => 'your side; black moves first' },
            { name => 'hotseat', type => 'flag',
              help => 'two people at one keyboard, no bot' },
        ];
    }

    # and in whatever asks the player

    use Game::Terminal::Kit::Options;

    my $fields = Game::Checkers::Terminal->options;
    my %values = (level => 3, hotseat => 1);
    my @argv = Game::Terminal::Kit::Options::argv_for($fields, \%values);
    # --level 3 --hotseat

=head1 DESCRIPTION

A game says which of its command line options a person would want to set
before playing, as a list of fields, and anything that starts the game can
then show them as a form and turn the answers back into a command line. The
game stays the one place its options are written down.

=head2 A field

A hash reference with a C<name>, which is the option without its dashes, a
C<type>, and a C<help> of one short clause. The types:

=over 4

=item C<int>

A whole number from C<min> to C<max>. Sent as C<--name 3>.

=item C<enum>

One of C<choices>, an array reference of two or more. Sent as
C<--name choice>.

=item C<flag>

On or off. Sent as C<--name> when on and not at all when off.

=item C<bool>

On, off, or left alone. Sent as C<--name>, as C<--no-name>, or not at all.

=item C<str>

Any text. Sent as C<--name text>.

=back

A value that is undef is one the player left alone, and nothing is sent for
it: the game's own default applies, and nobody else has to know what it is.

=head1 FUNCTIONS

None is exported.

=head2 step_value

    my $next = Game::Terminal::Kit::Options::step_value($field, $current, +1);

The value one step up or down from the current one. A number stops at its
ends; a choice goes round; a flag turns over; a bool goes round its three
states. From a value left alone, up gives the least number or the first
choice and down gives the greatest or the last. Text does not step.

=head2 check_value

    my ($value, $error) = Game::Terminal::Kit::Options::check_value($field, $text);

What typed text means for the field: the value, or a sentence saying what the
field takes. Blank text is a value left alone, undef with no error. A choice
is matched without regard to case.

=head2 argv_for

    my @argv = Game::Terminal::Kit::Options::argv_for(\@fields, \%values);

The command line for those values, in the order of the fields. A value under
C<extra> is split as a shell would split it and put last.

=head2 validate

    my @wrong = Game::Terminal::Kit::Options::validate(\@fields);

What is wrong with a list of fields, one sentence each; nothing when it is
sound. A name must be lower case letters, digits and dashes and may not be
there twice; C<ascii>, C<pick>, C<help>, C<version> and C<extra> are kept by
the launcher; every field needs help and a type; a number needs its ends in
order and a choice needs two.

=head2 types

=head2 reserved

The types and the kept names, sorted.

=head1 SEE ALSO

L<Game::Terminal::Kit>, L<Game::Terminal>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
