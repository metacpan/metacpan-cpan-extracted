package Game::Terminal::Kit::Keys;

use 5.014;
use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.05';

my %SEQUENCE = (
	'A' => 'up',
	'B' => 'down',
	'C' => 'right',
	'D' => 'left',
	'H' => 'home',
	'F' => 'end',
	'Z' => 'back_tab',
	'1~' => 'home',
	'2~' => 'insert',
	'3~' => 'delete',
	'4~' => 'end',
	'5~' => 'page_up',
	'6~' => 'page_down',
	'7~' => 'home',
	'8~' => 'end',
);

my %CONTROL = (
	"\r" => 'enter',
	"\n" => 'enter',
	"\t" => 'tab',
	"\x7f" => 'backspace',
	"\x08" => 'backspace',
	"\x03" => 'interrupt',
	"\x04" => 'eof',
);

has in => (
	is => 'rw'
);

has raw => (
	is => 'rw',
	isa => Bool,
	default => 0
);

has [qw/keysource sleeper/] => (
	is => 'rw',
	isa => CodeRef
);

has pending => (
	is => 'rw',
	isa => ArrayRef,
	default => []
);

has sequence_wait => (
	is => 'rw',
	isa => Num
);

sub BUILD {
	my ($self) = @_;
	$self->in(\*STDIN) unless $self->in;
	$self->sequence_wait(0.05) unless defined $self->sequence_wait;
	$self->sleeper(sub { select undef, undef, undef, $_[0]; return })
		unless $self->sleeper;
	return $self;
}

sub names {
	my %seen;
	return sort grep { !$seen{$_}++ }
		values %SEQUENCE, values %CONTROL, 'escape', 'unknown';
}

sub _on_a_terminal {
	my ($self) = @_;
	return defined $self->in && -t $self->in ? 1 : 0;
}

sub keys_available {
	my ($self) = @_;
	return 1 if $self->keysource;
	return 0 unless $self->_on_a_terminal;
	return eval { require Term::ReadKey; 1 } ? 1 : 0;
}

sub enter_raw {
	my ($self) = @_;
	return $self if $self->raw;
	if ($self->keysource) {
		$self->raw(1);
		return $self;
	}
	return undef unless $self->keys_available;
	return undef unless eval { Term::ReadKey::ReadMode(3, $self->in); 1 };
	$self->raw(1);
	return $self;
}

sub leave_raw {
	my ($self) = @_;
	return $self unless $self->raw;
	eval { Term::ReadKey::ReadMode(0, $self->in) } unless $self->keysource;
	$self->raw(0);
	return $self;
}

sub unread {
	my ($self, @chars) = @_;
	unshift @{$self->pending}, @chars;
	return $self;
}

sub read_char {
	my ($self, $wait) = @_;
	my $pending = $self->pending;
	return shift @{$pending} if @{$pending};
	return $self->keysource->($wait) if $self->keysource;
	unless ($self->raw) {
		$self->sleeper->($wait) if $wait;
		return undef;
	}
	my $mode = !defined $wait ? 0 : $wait > 0 ? $wait : -1;
	return Term::ReadKey::ReadKey($mode, $self->in);
}

sub read_key {
	my ($self, $wait) = @_;
	my $char = $self->read_char($wait);
	return undef unless defined $char;
	return $CONTROL{$char} if $CONTROL{$char};
	return $self->read_sequence if $char eq "\e";
	return $char;
}

sub read_sequence {
	my ($self) = @_;
	my $opener = $self->read_char($self->sequence_wait);
	return 'escape' unless defined $opener;
	unless ($opener eq '[' || $opener eq 'O') {
		$self->unread($opener);
		return 'escape';
	}
	my $tail = '';
	while (length $tail < 8) {
		my $char = $self->read_char($self->sequence_wait);
		last unless defined $char;
		$tail .= $char;
		last if $char =~ m/[A-Za-z~]/;
	}
	return $SEQUENCE{$tail} || 'unknown';
}

sub read_line {
	my ($self, $prompt, $out) = @_;
	my $was_raw = $self->raw;
	$self->leave_raw;
	if (defined $prompt && $out) {
		my $previous = select $out;
		my $buffered = $|;
		print {$out} $prompt;
		$| = 1;
		$| = $buffered;
		select $previous;
	}
	my $line = readline $self->in;
	$self->enter_raw if $was_raw;
	return undef unless defined $line;
	$line =~ s/^\s+|\s+$//g;
	return $line;
}

1;

__END__

=head1 NAME

Game::Terminal::Kit::Keys - one key at a time, by name

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    use Game::Terminal::Kit::Keys;

    my $keys = Game::Terminal::Kit::Keys->new;
    $keys->enter_raw or die "no keys here\n";

    while (defined(my $key = $keys->read_key)) {
        last if $key eq 'q' || $key eq 'escape';
        move(-1) if $key eq 'up';
        move(+1) if $key eq 'down';
    }

    $keys->leave_raw;

=head1 DESCRIPTION

The keyboard of a terminal game. It puts the terminal in a mode where a key
arrives as it is pressed, reads one key, and gives it a name: C<up> for the
up arrow whichever of its spellings the terminal sent, C<enter> for return or
line feed, the character itself for anything printable.

L<Term::ReadKey> is used when it is installed and is never required. Without
it, or off a terminal, L</keys_available> is false and a game falls back to
whole lines with L</read_line>.

=head2 The names

C<enter>, C<tab>, C<back_tab>, C<backspace>, C<delete>, C<insert>, C<up>,
C<down>, C<left>, C<right>, C<home>, C<end>, C<page_up>, C<page_down>,
C<interrupt> for control-C, C<eof> for control-D, C<escape> for the escape key
alone, and C<unknown> for an escape sequence that is none of the above, such
as an arrow with a modifier held. Space is a space.

The mode is one in which control-C still raises C<SIGINT>, so C<interrupt> is
seen only from a L</keysource>.

=head2 Waiting

L</read_key> with no argument waits for a key. With a number of seconds it
waits that long and returns undef if none came, which is how a game that
moves on its own reads the keyboard between frames. With zero it does not
wait at all.

=head2 Testing

Give C<keysource> a code reference and no terminal is touched: it is called
for each character with the wait as its argument, and returns the character
or undef for none. Real escape sequences go through it a character at a time,
so a test types C<"\e[B\r"> for down then enter.

=head1 ATTRIBUTES

=head2 in

The handle keys and lines are read from. C<STDIN> by default.

=head2 raw

True between L</enter_raw> and L</leave_raw>.

=head2 keysource

A code reference standing in for the keyboard; see L</Testing>.

=head2 pending

Characters read and put back, an array reference, next first.

=head2 sleeper

A code reference called with a number of seconds when a wait was asked for
and there is no keyboard to wait on. It sleeps by default.

=head2 sequence_wait

How long, in seconds, to wait for the rest of an escape sequence before
deciding the escape key was pressed on its own. 0.05 by default.

=head1 METHODS

=head2 names

Every name L</read_key> can return for a key that is not printable, sorted.

=head2 keys_available

True when single keys can be read: there is a L</keysource>, or L</in> is a
terminal and L<Term::ReadKey> loads.

=head2 enter_raw

=head2 leave_raw

C<enter_raw> starts reading a key at a time and returns the object, or undef
when keys are not available. C<leave_raw> gives the terminal back as it was.
Either may be called twice. Call C<leave_raw> on every way out, a signal
included; L<Game::Terminal::Kit::Run> does.

=head2 read_key

    my $key = $keys->read_key;         # wait for one
    my $key = $keys->read_key(0.1);    # or undef after a tenth of a second

One key, as a name or a character; undef when the wait ran out or the input
ended.

=head2 read_char

=head2 read_sequence

=head2 unread

C<read_char> returns the next raw character, taking the same wait as
L</read_key>. C<read_sequence> reads what follows an escape character and
names it. C<unread> puts characters back to be read next. L</read_key> is
built from the three.

=head2 read_line

    my $text = $keys->read_line('Your move: ', \*STDOUT);

Leaves key-at-a-time mode, prints the prompt to the handle given if both are
given, reads a line, and goes back to key-at-a-time mode if it was in it. The
line comes back without the space around it; undef at the end of input.

=head1 SEE ALSO

L<Game::Terminal::Kit>, L<Game::Terminal::Kit::Screen>, L<Term::ReadKey>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
