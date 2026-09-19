package Game::Go::GTP;

use 5.010;
use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Go;
use Game::Go::Bot;
use Game::Go::Rules;
use Game::Go::Notation;

our $VERSION = '0.01';

my $B = Game::Go::Rules::BLACK;
my $W = Game::Go::Rules::WHITE;

has game  => (is => 'rw');
has bot   => (is => 'rw');
has size  => (is => 'rw', isa => Int, default => 19);
has komi  => (is => 'rw', default => 6.5);
has level => (is => 'ro', isa => Int, default => 2);
has seed  => (is => 'ro', default => 'gtp');

has quit => (is => 'rw', default => 0);

our @COMMANDS;
BEGIN {
	@COMMANDS = qw(
		protocol_version name version known_command list_commands quit
		boardsize clear_board komi play genmove undo showboard
		final_score final_status_list
	);
}

sub BUILD {
	my ($self) = @_;
	$self->_reset;
	return;
}

sub _reset {
	my ($self) = @_;
	$self->game(Game::Go->new(
		size => $self->size,
		komi => $self->komi,
		seed => $self->seed,
		ko   => 'simple',
	));
	$self->bot(Game::Go::Bot->new(level => $self->level, seed => $self->seed));
	return;
}

sub handle {
	my ($self, $line) = @_;
	return '' unless defined $line;

	$line =~ s/#.*\z//;
	$line =~ s/\s+\z//;
	$line =~ s/\A\s+//;
	return '' unless length $line;

	my ($id, @words) = ();
	my @parts = split /\s+/, $line;
	$id = shift @parts if @parts && $parts[0] =~ /\A[0-9]+\z/;
	my $cmd = lc(shift(@parts) // '');
	@words = @parts;

	my $tag = defined $id ? $id : '';

	unless (grep { $_ eq $cmd } @COMMANDS) {
		return "?$tag unknown command\n\n";
	}

	my ($ok, $body) = $self->_run($cmd, \@words);
	$body = '' unless defined $body;
	return ($ok ? '=' : '?') . "$tag $body\n\n";
}

sub _run {
	my ($self, $cmd, $words) = @_;
	my $game = $self->game;

	return (1, '2')                if $cmd eq 'protocol_version';
	return (1, 'Game::Go')         if $cmd eq 'name';
	return (1, $Game::Go::VERSION) if $cmd eq 'version';
	return (1, join "\n", @COMMANDS) if $cmd eq 'list_commands';
	return (1, (grep { $_ eq lc($words->[0] // '') } @COMMANDS) ? 'true' : 'false')
		if $cmd eq 'known_command';

	if ($cmd eq 'quit') { $self->quit(1); return (1, '') }

	if ($cmd eq 'boardsize') {
		my $n = $words->[0] // '';
		return (0, 'unacceptable size')
			unless $n =~ /\A[0-9]+\z/ && grep { $_ == $n } Game::Go->sizes;
		$self->size($n);
		$self->_reset;
		return (1, '');
	}

	if ($cmd eq 'clear_board') { $self->_reset; return (1, '') }

	if ($cmd eq 'komi') {
		my $k = $words->[0] // '';
		return (0, 'syntax error') unless $k =~ /\A-?[0-9]+(?:\.[0-9]+)?\z/;
		$self->komi($k + 0);
		$self->_reset;
		return (1, '');
	}

	if ($cmd eq 'play') {
		my $colour = $self->_colour($words->[0]);
		return (0, 'syntax error') unless $colour;
		my $where = uc($words->[1] // '');

		if ($where eq 'PASS') {
			my $out = $game->pass($colour);
			return (0, 'illegal move') if ref $out eq 'Game::Go::Error';
			return (1, '');
		}

		my ($col, $row) = Game::Go::Notation::from_human($game->size, $where);
		return (0, 'invalid coordinate') unless defined $col;

		$game->turn($colour) if $game->turn != $colour && $game->phase eq 'play';

		my $out = $game->play($colour, $game->point($col, $row));
		return (0, 'illegal move') if ref $out eq 'Game::Go::Error';
		return (1, '');
	}

	if ($cmd eq 'genmove') {
		my $colour = $self->_colour($words->[0]);
		return (0, 'syntax error') unless $colour;
		return (1, 'resign') unless $game->status eq 'active';

		$game->turn($colour) if $game->phase eq 'play' && $game->turn != $colour;

		my $move = $self->bot->choose($game, $colour);
		return (1, 'pass') unless $move && $move->kind eq 'play';

		my ($col, $row) = $game->col_row($move->point);
		my $where = Game::Go::Notation::to_human($game->size, $col, $row);
		$game->play($colour, $move->point);
		return (1, $where);
	}

	if ($cmd eq 'undo') {
		my $events = $game->events;
		my $cut = -1;
		for my $i (reverse 0 .. $#$events) {
			next if $events->[$i]{actor} eq 'sys';
			$cut = $i;
			last;
		}
		return (0, 'cannot undo') if $cut < 0;

		my @keep = @$events[0 .. $cut - 1];
		my $fresh = Game::Go->new(
			size => $game->size, komi => $game->komi,
			seed => $self->seed, ko => 'simple',
		);
		eval { $fresh->replay(\@keep); 1 } or return (0, 'cannot undo');
		$self->game($fresh);
		return (1, '');
	}

	if ($cmd eq 'showboard') {
		return (1, "\n" . $game->board->to_text);
	}

	if ($cmd eq 'final_score') {
		my $raw = $game->raw_score;
		my ($b, $w) = ($raw->{score_b} / 10, $raw->{score_w} / 10);
		return (1, '0') if $b == $w;
		return (1, $b > $w ? sprintf('B+%s', $b - $w) : sprintf('W+%s', $w - $b));
	}

	if ($cmd eq 'final_status_list') {
		my $what = lc($words->[0] // 'dead');
		return (0, 'syntax error') unless $what =~ /\A(?:dead|alive)\z/;

		my $dead = $game->dead_guess_from(playouts => 60, seed => 1);
		my %dead = map { $_ => 1 } @$dead;

		my @out;
		for my $row (0 .. $game->size - 1) {
			for my $col (0 .. $game->size - 1) {
				my $pt = $game->point($col, $row);
				my $at = $game->board->at($col, $row);
				next unless Game::Go::Rules::is_colour($at);
				my $is_dead = $dead{$pt} ? 1 : 0;
				next unless $what eq ($is_dead ? 'dead' : 'alive');
				push @out, Game::Go::Notation::to_human($game->size, $col, $row);
			}
		}
		return (1, join ' ', @out);
	}

	return (0, 'unknown command');
}

sub _colour {
	my ($self, $word) = @_;
	return undef unless defined $word;
	my $c = lc $word;
	return $B if $c eq 'b' || $c eq 'black';
	return $W if $c eq 'w' || $c eq 'white';
	return undef;
}

sub run {
	my ($self, $in, $out) = @_;
	while (my $line = <$in>) {
		my $response = $self->handle($line);
		next unless length $response;
		print {$out} $response;
		last if $self->quit;
	}
	return 0;
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Go::GTP - the Go Text Protocol, so another engine can be the oracle

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $gtp = Game::Go::GTP->new(level => 2);
    print $gtp->handle("boardsize 9");      # "= \n\n"
    print $gtp->handle("genmove b");        # "= D4\n\n"

    $gtp->run(\*STDIN, \*STDOUT);

=head1 DESCRIPTION

Enough of the Go Text Protocol for C<gogui-twogtp> to referee a match and for
C<gnugo --mode gtp> to be talked to:

    protocol_version  name  version  list_commands  known_command  quit
    boardsize  clear_board  komi  play  genmove  undo  showboard
    final_score  final_status_list

=head2 Why it is here

B<To let something from outside have an opinion.> The XS-only decision left this
distribution with one implementation of everything, and the two places that
matters most are the hardest ones: whether a group is dead, and whether the bot
plays well. An independent, mature engine answering C<final_status_list dead>
and playing a match is the only non-self-referential answer available to either
question.

GNU Go is neither shipped, linked nor depended on. F<xt/gnugo.t> runs only under
C<GO_GNUGO>, and when that is set and the binary is missing it B<dies> rather
than skipping, because a fallback that reports PASS is a failing test.

=head2 GTP's vertex format is this distribution's human notation

Columns C<A> to C<T> with C<I> left out, rows numbered from the bottom. That is
exactly what L<Game::Go::Notation>'s human half already does, so there is no
third coordinate system here and nothing to get wrong twice.

=head2 It speaks simple ko

Not the shipped positional superko. A refereeing engine and a record of a real
game may both contain a repetition this distribution's own amendment would
refuse, and refusing one mid-match would look like a crash rather than a rules
disagreement.

=head1 METHODS

=head2 handle

One line in, one GTP response out, including the blank line that ends it. A
response without that blank line hangs every controller there is.

An unknown command is B<answered> with C<? unknown command> rather than dying: a
controller sends commands an engine may not have and expects to be told so.

=head2 run

The loop, on two filehandles, so a test can drive it in process.

=head2 game, bot, size, komi, level, seed, quit

=head1 SEE ALSO

L<Game::Go>, F<bin/go-gtp>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
