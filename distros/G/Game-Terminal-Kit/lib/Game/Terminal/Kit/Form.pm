package Game::Terminal::Kit::Form;

use 5.014;
use strict;
use warnings;

use Object::Proto::Sugar -types;
use Game::Terminal::Kit::Line;
use Game::Terminal::Kit::Options;
use Game::Terminal::Kit::Widget;

our $VERSION = '0.05';

my $OWN = "the game\x27s own";

my %INK = (
	key    => '1',
	set    => '38;5;114',
	own    => '2',
	action => '1;32',
	legend => '2',
);

has [qw/title action/] => (
	is => 'rw',
	isa => Str,
	default => ''
);

has [qw/fields legend/] => (
	is => 'rw',
	isa => ArrayRef
);

has values => (
	is => 'rw',
	isa => HashRef
);

has extra => (
	is => 'rw',
	isa => Bool,
	default => 1
);

has [qw/at log screen/] => (
	is => 'rw'
);

sub BUILD {
	my ($self) = @_;
	$self->fields([]) unless $self->fields;
	$self->values({}) unless $self->values;
	$self->title('') unless defined $self->title;
	$self->action('Play') unless defined $self->action && length $self->action;
	$self->legend([
		'left and right change a value, enter edits a text, backspace clears,',
		'enter on ' . $self->action . ' starts, escape goes back',
	]) unless $self->legend;
	$self->at(scalar @{ $self->rows }) unless defined $self->at;
	return $self;
}

sub rows {
	my ($self) = @_;
	return [
		@{$self->fields},
		($self->extra
			? { name => 'extra', type => 'extra', help => 'anything else, as on the command line' }
			: ()),
	];
}

sub show_value {
	my ($self, $field, $value) = @_;
	my $type = $field->{type};
	return $value ? 'on' : 'off' if $type eq 'flag';
	return !defined $value ? $OWN : $value ? 'on' : 'off' if $type eq 'bool';
	return defined $value && length $value ? $value : '(none)' if $type eq 'extra';
	return defined $value ? $value : $OWN;
}

sub lines {
	my ($self) = @_;
	my $rows = $self->rows;
	my $values = $self->values;
	my $at = $self->at;
	my @lines;
	push @lines, $self->title, '' if length $self->title;
	for my $index (0 .. $#{$rows}) {
		my $field = $rows->[$index];
		my $value = $values->{ $field->{name} };
		my $shown = $self->show_value($field, $value);
		if ($index == $at) {
			my $line = sprintf '%-11s %-18s %s', $field->{name}, $shown, $field->{help};
			$line =~ s/\s+$//;
			push @lines, ' ' . Game::Terminal::Kit::Widget::paint($self, "> $line", '1;7');
			next;
		}
		my $set = $field->{type} eq 'flag' ? $value : defined $value && length $value;
		my $line = '   ' . Game::Terminal::Kit::Widget::paint($self, sprintf('%-11s', $field->{name}), $INK{key}) . ' '
			. Game::Terminal::Kit::Widget::paint($self, sprintf('%-18s', $shown), $set ? $INK{set} : $INK{own}) . ' '
			. $field->{help};
		$line =~ s/\s+$//;
		push @lines, $line;
	}
	push @lines, '', $at == @{$rows}
		? ' ' . Game::Terminal::Kit::Widget::paint($self, '> ' . $self->action, '1;7')
		: '   ' . Game::Terminal::Kit::Widget::paint($self, $self->action, $INK{action});
	my @said = $self->log ? $self->log->lines : ();
	push @lines, '', @said if @said;
	push @lines, '', map { Game::Terminal::Kit::Widget::paint($self, $_, $INK{legend}) } @{$self->legend}
		if @{$self->legend};
	return @lines;
}

sub _say {
	my ($self, $text) = @_;
	$self->log->note($text) if $self->log;
	return;
}

sub _keep {
	my ($self, $name, $value) = @_;
	if (defined $value) {
		$self->values->{$name} = $value;
	} else {
		delete $self->values->{$name};
	}
	return;
}

sub set {
	my ($self, $name, $text) = @_;
	my ($field) = grep { $_->{name} eq $name } @{ $self->rows };
	return 0 unless $field;
	if ($field->{type} eq 'extra') {
		$text = '' unless defined $text;
		$text =~ s/^\s+|\s+$//g;
		$self->_keep($name, length $text ? $text : undef);
		return 1;
	}
	my ($value, $error) = Game::Terminal::Kit::Options::check_value($field, $text);
	if (defined $error) {
		$self->_say($error);
		return 0;
	}
	$self->_keep($name, $value);
	return 1;
}

sub argv {
	my ($self) = @_;
	return Game::Terminal::Kit::Options::argv_for($self->fields, $self->values);
}

sub step {
	my ($self, $key) = @_;
	return ('quit') if !defined $key || $key eq 'eof' || $key eq 'interrupt';
	return ('back') if $key eq 'escape' || $key eq 'q';
	return ('chosen', $self->values) if $key eq 'p';

	my $rows = $self->rows;
	my $count = @{$rows} + 1;
	my $at = $self->at;
	if ($key eq 'up' || $key eq 'k' || $key eq 'back_tab') {
		$self->at(($at - 1) % $count);
		return ('moved');
	}
	if ($key eq 'down' || $key eq 'j' || $key eq 'tab') {
		$self->at(($at + 1) % $count);
		return ('moved');
	}
	if ($at == @{$rows}) {
		return ('chosen', $self->values) if $key eq 'enter' || $key eq ' ';
		$self->_say('That key does nothing here');
		return ('none');
	}

	my $field = $rows->[$at];
	my $name = $field->{name};
	my $type = $field->{type};
	my $typed = $type eq 'str' || $type eq 'extra' || $type eq 'int';
	if ($key eq 'backspace' || $key eq 'delete') {
		$self->_keep($name, undef);
		return ('changed');
	}
	if ($key eq 'left' || $key eq 'right') {
		if ($type eq 'str' || $type eq 'extra') {
			$self->_say("$name is typed: press enter");
			return ('none');
		}
		$self->_keep($name, Game::Terminal::Kit::Options::step_value(
			$field, $self->values->{$name}, $key eq 'right' ? 1 : -1,
		));
		return ('changed');
	}
	if ($key eq 'enter' || $key eq ' ') {
		return ('edit', $field) if $typed;
		$self->_keep($name, Game::Terminal::Kit::Options::step_value($field, $self->values->{$name}, 1));
		return ('changed');
	}
	$self->_say('That key does nothing here');
	return ('none');
}

sub run {
	my ($self, $keys, $screen) = @_;
	while (1) {
		my ($event, $value) = my @result = Game::Terminal::Kit::Widget::run($self, $keys, $screen);
		return @result unless $event eq 'edit';
		my $line = Game::Terminal::Kit::Line->new(
			prompt => "$value->{name}: ",
			head => [ $self->lines, '' ],
		);
		my ($answer, $text) = $line->run($keys, $screen);
		return ('quit') if $answer eq 'quit';
		$self->set($value->{name}, $text) if $answer eq 'chosen';
	}
}

1;

__END__

=head1 NAME

Game::Terminal::Kit::Form - a game's options, set before it starts

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    use Game::Terminal::Kit::Form;

    my $form = Game::Terminal::Kit::Form->new(
        title  => 'checkers: English draughts',
        fields => Game::Checkers::Terminal->options,
        values => \%remembered,
        log    => $log,
        screen => $screen,
    );

    my ($event) = $form->run($keys, $screen);
    Game::Checkers::Terminal->run($form->argv) if $event eq 'chosen';

=head1 DESCRIPTION

A screen of the fields a game says it has (see
L<Game::Terminal::Kit::Options>), each with its value, and a last row that
starts the game. The player moves up and down the rows and changes the one
under the cursor.

    checkers: English draughts

       level       the game's own     the strength of the bot
     > side        white              your side; black moves first
       hotseat     off                two people at one keyboard, no bot
       extra       (none)             anything else, as on the command line

       Play

A value nobody set is shown as the game's own, and nothing is sent for it,
so the form never has to know a default. The cursor starts on the last row:
enter straight away plays the game as it comes.

It is one of the kit's widgets; see L<Game::Terminal::Kit::Widget>.

=head2 The keys

Up and down, C<k> and C<j>, tab and shift-tab move between rows and go round.
Left and right step a number, a choice, a flag or a bool. Enter or space
steps a choice, a flag or a bool, and for a number or text asks for a line.
Backspace or delete puts a row back to the game's own. Enter on the last
row, or C<p> anywhere, answers. Escape or C<q> goes back.

=head1 ATTRIBUTES

=head2 title

A line above the fields, with a blank line after it.

=head2 fields

The fields, an array reference as L<Game::Terminal::Kit::Options> describes.

=head2 values

A hash reference from a field's name to its value, changed in place. Pass
the same one again and the form opens as the player left it.

=head2 extra

True, the default, for a last field of free text that is split like a shell
and added to the command line: the way to an option the game did not list.

=head2 action

The label of the last row; C<Play> by default.

=head2 at

The row under the cursor; the last by default.

=head2 legend

Lines below the form. By default the keys, in two lines.

=head2 log

A L<Game::Terminal::Kit::Log>, drawn under the last row. The form notes a
refused value and a key that does nothing there; without a log they are
simply not said.

=head2 screen

A L<Game::Terminal::Kit::Screen>, for colour.

=head1 METHODS

=head2 lines

The title, the rows, the action, the log, the legend.

=head2 step

    my ($event, $value) = $form->step($key);

C<chosen> with the values when the player starts the game; C<edit> with a
field when a line of text is wanted for it, to be answered with L</set>;
C<back>; C<quit>; C<moved>; C<changed>; C<none>.

=head2 run

    my ($event, $values) = $form->run($keys, $screen);

Draws and reads until the player starts the game or goes back. A line of
text is asked for with a L<Game::Terminal::Kit::Line> under the form.

=head2 set

    $form->set($name, $text) or redraw();

Gives a field typed text. The text is checked against the field; when it is
refused the reason is noted, the value is left as it was and the result is
false. Blank text puts the field back to the game's own.

=head2 argv

The command line for the values as they stand.

=head2 rows

The fields and, with L</extra>, the extra one, as an array reference.

=head2 show_value

    my $text = $form->show_value($field, $value);

How a value is drawn: C<on> or C<off>, the value, C<the game's own>.

=head1 SEE ALSO

L<Game::Terminal::Kit::Options>, L<Game::Terminal::Kit::Widget>,
L<Game::Terminal>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
