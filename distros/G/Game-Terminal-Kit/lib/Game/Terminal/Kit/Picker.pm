package Game::Terminal::Kit::Picker;

use 5.014;
use strict;
use warnings;

use Object::Proto::Sugar -types;
use Game::Terminal::Kit::Steer;
use Game::Terminal::Kit::Widget;

our $VERSION = '0.05';

has [qw/items head legend chosen/] => (
	is => 'rw',
	isa => ArrayRef
);

has game_keys => (
	is => 'rw',
	isa => HashRef
);

has prefer => (
	is => 'rw',
	isa => CodeRef
);

has [qw/at log screen/] => (
	is => 'rw'
);

has window => (
	is => 'rw',
	isa => Int,
	default => 8
);

has need => (
	is => 'rw',
	isa => Int,
	default => 0
);

has numbered => (
	is => 'rw',
	isa => Bool,
	default => 1
);

has across => (
	is => 'rw',
	isa => Bool,
	default => 0
);

sub BUILD {
	my ($self) = @_;
	$self->items([]) unless $self->items;
	$self->head([]) unless $self->head;
	$self->legend([]) unless $self->legend;
	$self->game_keys({}) unless $self->game_keys;
	$self->chosen([]) unless $self->chosen;
	$self->at($self->resting) unless defined $self->at;
	return $self;
}

sub resting {
	my ($self) = @_;
	return Game::Terminal::Kit::Steer::rest($self->items, $self->prefer);
}

sub reset {
	my ($self, $items) = @_;
	$self->items($items) if $items;
	$self->chosen([]);
	$self->at($self->resting);
	return $self;
}

sub skipped {
	my ($self, $index) = @_;
	my $item = $self->items->[$index];
	return ref $item eq 'HASH' && $item->{skip} ? 1 : 0;
}

sub label_of {
	my ($self, $index) = @_;
	my $item = $self->items->[$index];
	return ref $item eq 'HASH' ? (defined $item->{label} ? $item->{label} : '') : "$item";
}

sub value_of {
	my ($self, $index) = @_;
	my $item = $self->items->[$index];
	return ref $item eq 'HASH' && exists $item->{value} ? $item->{value} : $item;
}

sub current {
	my ($self) = @_;
	my $at = $self->at;
	return undef unless @{$self->items} && !$self->skipped($at);
	return $self->value_of($at);
}

sub rows {
	my ($self) = @_;
	my $items = $self->items;
	my $at = $self->at;
	my $window = $self->window;
	my ($first, $last) = (0, $#{$items});
	if ($window > 0 && @{$items} > $window) {
		$first = $at - int($window / 2);
		$first = 0 if $first < 0;
		$first = @{$items} - $window if $first > @{$items} - $window;
		$last = $first + $window - 1;
	}
	my $any_about = grep { ref $_ eq 'HASH' && defined $_->{about} && length $_->{about} } @{$items};
	my ($wide) = sort { $b <=> $a } map { length $self->label_of($_) } 0 .. $#{$items};
	my %taken = map { $_ => 1 } @{$self->chosen};

	my @rows;
	push @rows, sprintf '    %d further up', $first if $first;
	for my $index ($first .. $last) {
		my $item = $items->[$index];
		my $line = '';
		$line .= sprintf '%2d. ', $index + 1 if $self->numbered;
		$line .= ($taken{$index} ? '[x] ' : '[ ] ') if $self->need > 0;
		if ($any_about) {
			my $about = ref $item eq 'HASH' && defined $item->{about} ? $item->{about} : '';
			$line .= sprintf '%-*s  %s', $wide, $self->label_of($index), $about;
		} else {
			$line .= $self->label_of($index);
		}
		$line =~ s/\s+$//;
		push @rows, $index == $at && !$self->skipped($index)
			? ' ' . Game::Terminal::Kit::Widget::paint($self, "> $line", '1;7')
			: $self->skipped($index)
			? '   ' . Game::Terminal::Kit::Widget::paint($self, $line, '2')
			: "   $line";
	}
	push @rows, sprintf '    %d further down', $#{$items} - $last if $last < $#{$items};
	return @rows;
}

sub lines {
	my ($self) = @_;
	my @said = $self->log ? $self->log->lines : ();
	return (@{$self->head}, (@said ? (@said, '') : ()), $self->rows, @{$self->legend});
}

sub move {
	my ($self, $delta) = @_;
	my $next = Game::Terminal::Kit::Steer::ring(
		scalar @{$self->items}, $self->at, $delta, sub { $self->skipped($_[0]) },
	);
	return ('none') if $next == $self->at;
	$self->at($next);
	return ('moved');
}

sub jump {
	my ($self, $index) = @_;
	return ('none') if $index < 0 || $index > $#{$self->items} || $self->skipped($index);
	return ('none') if $index == $self->at;
	$self->at($index);
	return ('moved');
}

sub take {
	my ($self) = @_;
	my $at = $self->at;
	return ('none') unless @{$self->items} && !$self->skipped($at);
	return ('chosen', $self->value_of($at)) unless $self->need > 0;
	my %taken = map { $_ => 1 } @{$self->chosen};
	if ($taken{$at}) { delete $taken{$at} } else { $taken{$at} = 1 }
	my @chosen = sort { $a <=> $b } keys %taken;
	$self->chosen(\@chosen);
	return ('changed') unless @chosen == $self->need;
	return ('chosen', [ map { $self->value_of($_) } @chosen ]);
}

sub step {
	my ($self, $key) = @_;
	return ('quit') if !defined $key || $key eq 'eof' || $key eq 'interrupt';
	return ('key', $self->game_keys->{$key}) if exists $self->game_keys->{$key};

	my ($back, $on) = $self->across ? ('down', 'up') : ('up', 'down');
	return $self->move(-1) if $key eq 'left' || $key eq $back || $key eq 'back_tab';
	return $self->move(+1) if $key eq 'right' || $key eq $on || $key eq 'tab';

	my @open = grep { !$self->skipped($_) } 0 .. $#{$self->items};
	return @open ? $self->jump($open[0]) : ('none') if $key eq 'home' || $key eq 'page_up';
	return @open ? $self->jump($open[-1]) : ('none') if $key eq 'end' || $key eq 'page_down';
	return $self->jump($key - 1) if $self->numbered && $key =~ m/^[1-9]$/ && $key <= @{$self->items};

	return $self->take if $key eq 'enter' || $key eq ' ';
	return ('back') if $key eq 'escape' || $key eq 'backspace';
	return ('quit') if $key eq 'q';

	$self->log->note('That key does nothing here.'
		. (exists $self->game_keys->{'?'} ? ' Press ? for the ones that do.' : ''))
		if $self->log;
	return ('none');
}

sub run {
	my ($self, $keys, $screen) = @_;
	return Game::Terminal::Kit::Widget::run($self, $keys, $screen);
}

1;

__END__

=head1 NAME

Game::Terminal::Kit::Picker - a list the player chooses from with the arrow keys

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    use Game::Terminal::Kit::Picker;

    my $picker = Game::Terminal::Kit::Picker->new(
        items  => [ map { { label => $_->notation, about => describe($_), value => $_ } } @legal ],
        head   => [ @board_lines, '' ],
        legend => [ '', 'up and down to choose, enter to play, ? for help, q to quit' ],
        game_keys => { '?' => 'help', u => 'undo' },
        log    => $log,
        screen => $screen,
    );

    my ($event, $value) = $picker->run($keys, $screen);

    play($value)   if $event eq 'chosen';
    show_help()    if $event eq 'key' && $value eq 'help';

=head1 DESCRIPTION

The legal moves, the cards in a hand, the tiles that can be played: a list,
a cursor, and enter. It is one of the kit's widgets; see
L<Game::Terminal::Kit::Widget> for C<lines>, C<step> and C<run>.

=head2 The items are what is drawn

Give the items B<in the order they appear on the screen>. If the screen
shows a hand sorted into suits, sort the hand once, draw from that, and pass
that. The cursor walks the list it is given and nothing else, so right means
right for as long as the two are the same list.

An item is a string, or a hash reference with

=over 4

=item C<label>

What is drawn.

=item C<value>

What comes back when it is chosen. The item itself when there is none.

=item C<about>

A few words drawn in a second column.

=item C<skip>

True for an item that is drawn and cannot be chosen, such as the card just
picked up that may not be thrown straight back. The cursor steps over it.

=back

=head2 The keys

Up and down move the cursor and go round at the ends; so do left and right,
tab and shift-tab. Home and end go to the ends, and a digit goes to that row
when the rows are numbered. Enter or space chooses. Escape or backspace goes
back, and C<q> quits.

Any key in C<game_keys> is the game's: it comes back as the event C<key> with the
name the game gave it, before the picker considers it, so a game may take
any letter it likes, C<q> included.

=head2 What just happened

Give the picker the game's L<Game::Terminal::Kit::Log> and it draws the log
between the head and the rows, every frame. The opponent's move is then
still on screen while the player chooses a reply to it.

=head2 Choosing several

With C<need> set to a number the rows have boxes, enter ticks and unticks
the row under the cursor, and the picker answers when that many are ticked,
with their values in the order they are drawn.

=head2 A turn made of several moves

Do not list every combination. List the next move of every legal turn that
begins with what has been chosen so far, let the player choose one, and ask
again with L</reset>; on C<back>, take the last one off and ask again. The
list stays short, and since every row is the next move of a turn the rules
already allow, no path through it ends somewhere illegal.

=head1 ATTRIBUTES

=head2 items

The list, an array reference, in drawn order.

=head2 at

The index under the cursor. It starts where L</resting> says.

=head2 prefer

A code reference called with an item and its index, true for one the cursor
should start on: the card the player usually means. The first such item is
the start; without one, the first that can be chosen.

=head2 window

The most rows drawn, 8 by default, so that a long list cannot push the board
off the screen; the rest are counted above and below. 0 draws them all.

=head2 head

=head2 legend

Lines drawn above the list and below it, array references. The picker adds
no blank lines of its own around them.

=head2 game_keys

A hash reference from a key to the name the game wants back for it.

=head2 need

How many rows to tick before the picker answers; 0, the default, is one
choice and no boxes.

=head2 chosen

The indexes ticked so far.

=head2 numbered

True, the default, to number the rows and let a digit jump to one.

=head2 across

True when the list is drawn as a row, so that up goes the way right does and
down the way left does. Up and down otherwise go the way left and right do.

=head2 log

A L<Game::Terminal::Kit::Log>, drawn in every frame.

=head2 screen

A L<Game::Terminal::Kit::Screen>, for colour: the row under the cursor is
reverse video and a skipped row is dim. Without one the rows are plain, and
the cursor is still the row that starts C<< > >>.

=head1 METHODS

=head2 lines

The head, the log and a blank line if it has anything to say, the rows, the
legend.

=head2 rows

The rows alone, for a game that lays the frame out itself.

=head2 step

    my ($event, $value) = $picker->step($key);

C<chosen> with the value, or an array reference of values under L</need>;
C<back>; C<quit>; C<key> with its name; C<moved>; C<changed> when a row was
ticked or unticked; C<none> for a key that does nothing, which is also noted
in the log.

=head2 run

    my ($event, $value) = $picker->run($keys, $screen);

Draws and reads until the player chooses, goes back, quits or presses one of
the game's keys.

=head2 reset

    $picker->reset(\@items);

New items, nothing ticked, and the cursor at rest. Returns the picker.

=head2 current

The value under the cursor, or undef when there is nothing to choose: what a
game previews while the player is still deciding.

=head2 resting

The index the cursor starts on.

=head2 move

=head2 jump

=head2 take

What the keys do: move the cursor by one either way, put it on an index, and
choose or tick what is under it. Each returns what L</step> would.

=head2 skipped

=head2 label_of

=head2 value_of

Whether the item at an index is skipped, and its label and its value.

=head1 SEE ALSO

L<Game::Terminal::Kit::Widget>, L<Game::Terminal::Kit::Steer>,
L<Game::Terminal::Kit::Choose>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
