package Game::Go::SGF;

use 5.010;
use strict;
use warnings;

use Carp ();

use Game::Go;
use Game::Go::Rules;
use Game::Go::Notation;

our $VERSION = '0.01';

my $B = Game::Go::Rules::BLACK;
my $W = Game::Go::Rules::WHITE;

sub _skip_ws { $_[1] += 1 while substr($_[0], $_[1], 1) =~ /\A\s\z/ }

sub _parse_value {
	my ($text, $p) = @_;
	$$p++;
	my $v = '';
	while ($$p < length $text) {
		my $c = substr($text, $$p, 1);
		if ($c eq "\\") {
			$$p++;
			$v .= substr($text, $$p, 1);
			$$p++;
			next;
		}
		last if $c eq ']';
		$v .= $c;
		$$p++;
	}
	$$p++;
	return $v;
}

sub _parse_node {
	my ($text, $p) = @_;
	$$p++;
	my %props;
	while ($$p < length $text) {
		_skip_ws($text, $$p);
		my ($ident) = substr($text, $$p) =~ /\A([A-Za-z]+)/;
		last unless defined $ident;
		$$p += length $ident;

		(my $key = $ident) =~ s/[a-z]//g;

		my @values;
		while (1) {
			_skip_ws($text, $$p);
			last unless substr($text, $$p, 1) eq '[';
			push @values, _parse_value($text, $p);
		}
		$props{$key} = \@values if length $key;
	}
	return \%props;
}

sub _parse_tree {
	my ($text, $p) = @_;
	$$p++;
	my (@nodes, @children);
	while ($$p < length $text) {
		_skip_ws($text, $$p);
		my $c = substr($text, $$p, 1);
		if    ($c eq ';') { push @nodes, _parse_node($text, $p) }
		elsif ($c eq '(') { push @children, _parse_tree($text, $p) }
		elsif ($c eq ')') { $$p++; last }
		else              { $$p++ }
	}
	return { nodes => \@nodes, children => \@children };
}

sub _main_line {
	my ($tree) = @_;
	my @nodes = @{ $tree->{nodes} };
	my $t = $tree;
	while (@{ $t->{children} }) {
		$t = $t->{children}[0];
		push @nodes, @{ $t->{nodes} };
	}
	return \@nodes;
}


sub read {
	my ($text, %o) = @_;
	Carp::croak('Game::Go::SGF: nothing to read') unless defined $text && length $text;

	my $pos = index($text, '(');
	Carp::croak('Game::Go::SGF: no game tree here') if $pos < 0;

	my $nodes = _main_line(_parse_tree($text, \$pos));
	Carp::croak('Game::Go::SGF: the game tree is empty') unless @$nodes;

	my $root = $nodes->[0];
	my $one  = sub { my $v = $root->{ $_[0] }; return $v && @$v ? $v->[0] : undef };

	my $gm = $one->('GM');
	Carp::croak("Game::Go::SGF: GM[$gm] is not Go") if defined $gm && $gm ne '1';

	my $size = $one->('SZ');
	$size = 19 unless defined $size && length $size;
	Carp::croak("Game::Go::SGF: SZ[$size] is not a square board this engine offers")
		unless $size =~ /\A[0-9]+\z/ && grep { $_ == $size } Game::Go->sizes;

	my $komi = $one->('KM');
	my $ha   = $one->('HA');

	my %setup;
	for my $pair (['AB', 'b'], ['AW', 'w']) {
		my ($prop, $letter) = @$pair;
		next unless $root->{$prop};
		for my $v (@{ $root->{$prop} }) {
			my @cr = Game::Go::Notation::from_sgf($size, $v);
			next unless @cr;
			push @{ $setup{$letter} }, \@cr;
		}
	}

	my $ab = scalar @{ $setup{b} || [] };
	if (defined $ha && $ha =~ /\A[0-9]+\z/ && $ha >= 2) {
		Carp::croak("Game::Go::SGF: HA[$ha] but AB places $ab stones")
			unless $ab == $ha;
	}

	my $pl = $one->('PL');
	my $first = defined $pl && $pl =~ /\A([BWbw])\z/ ? lc($1)
	          : ($ab && !@{ $setup{w} || [] }) ? 'w'
	          : 'b';

	my $game = Game::Go->new(
		size => $size,
		(defined $komi && length $komi ? (komi => _round_half($komi)) : ()),
		(%setup ? (setup => \%setup) : ()),
		first => $first,
		ko    => ($o{lenient} ? 'simple' : 'positional'),
	);

	my $moves = 0;
	for my $node (@$nodes[1 .. $#$nodes]) {
		for my $pair (['B', $B], ['W', $W]) {
			my ($prop, $colour) = @$pair;
			next unless exists $node->{$prop};
			my $v = $node->{$prop}[0];
			$v = '' unless defined $v;
			$moves++;

			if ($v eq '' || $v eq 'tt') {
				my $out = $game->pass($colour);
				_refused($out, $moves, 'pass', $o{lenient});
				next;
			}

			my @cr = Game::Go::Notation::from_sgf($size, $v);
			Carp::croak("Game::Go::SGF: move $moves, '$v' is not a point on a ${size}x$size board")
				unless @cr;

			_resume($game, $moves) if $game->phase eq 'marking';

			my $played = $game->play($colour, $game->point(@cr));
			_refused($played, $moves, $v, $o{lenient});
		}
	}

	my %territory;
	for my $node (@$nodes) {
		for my $pair (['TB', 'b'], ['TW', 'w']) {
			my ($prop, $letter) = @$pair;
			next unless $node->{$prop};
			for my $v (@{ $node->{$prop} }) {
				my @cr = Game::Go::Notation::from_sgf($size, $v);
				push @{ $territory{$letter} }, \@cr if @cr;
			}
		}
	}

	return {
		game      => $game,
		size      => $size,
		komi      => $game->komi,
		handicap  => (defined $ha ? $ha : 0),
		moves     => $moves,
		first     => $first,
		result    => parse_result($one->('RE')),
		players   => { b => $one->('PB'), w => $one->('PW') },
		ranks     => { b => $one->('BR'), w => $one->('WR') },
		date      => $one->('DT'),
		rules     => $one->('RU'),
		territory => \%territory,
		setup     => \%setup,
	};
}

sub _resume {
	my ($game, $n) = @_;
	my $m = $game->marking or return;

	my $done = $game->done($m->proposer);
	Carp::croak("Game::Go::SGF: move $n resumes a stopped game and the engine refused: "
		. $done->message) if ref $done eq 'Game::Go::Error';

	my $out = $game->dispute($m->answerer);
	Carp::croak("Game::Go::SGF: move $n resumes a stopped game and the engine refused: "
		. $out->message) if ref $out eq 'Game::Go::Error';

	return;
}

sub _refused {
	my ($out, $n, $what, $lenient) = @_;
	return unless ref $out eq 'Game::Go::Error';
	Carp::croak("Game::Go::SGF: move $n ($what) was refused: " . $out->message
		. ($lenient ? '' : '. Try lenient => 1 if this is a record of a real game'));
}

sub _round_half {
	my ($n) = @_;
	return 0 unless defined $n && $n =~ /\A-?[0-9.]+\z/;
	return int($n * 2 + ($n < 0 ? -0.5 : 0.5)) / 2;
}


sub parse_result {
	my ($re) = @_;
	return undef unless defined $re && length $re;

	return { kind => 'draw' }  if $re eq '0' || lc($re) eq 'draw';
	return { kind => 'void' }  if lc($re) eq 'void';
	return { kind => 'unknown' } if $re eq '?';

	my ($who, $rest) = $re =~ /\A([BW])\+(.*)\z/i;
	return { kind => 'unknown', text => $re } unless defined $who;

	my $winner = uc($who) eq 'B' ? $B : $W;
	return { kind => 'resign',  winner => $winner } if $rest =~ /\AR(esign)?\z/i;
	return { kind => 'timeout', winner => $winner } if $rest =~ /\AT(ime)?\z/i;
	return { kind => 'forfeit', winner => $winner } if $rest =~ /\AF(orfeit)?\z/i;
	return { kind => 'score', winner => $winner, margin => $rest + 0 }
		if $rest =~ /\A[0-9]+(?:\.[0-9]+)?\z/;

	return { kind => 'unknown', text => $re };
}

sub format_result {
	my ($game) = @_;
	my $r = $game->result;
	return undef unless defined $r;
	return 'Void' if $r eq 'abandoned';

	my $w = $game->winner;
	return 'Void' unless defined $w;
	my $letter = uc Game::Go::Rules::letter($w);

	return "$letter+R" if $r eq 'resign';
	return "$letter+T" if $r eq 'timeout';

	my $o = $game->outcome;
	return "$letter+" . ($o ? $o->margin : '') if $r eq 'score';
	return undef;
}

sub write {
	my ($game, %o) = @_;

	my $size = $game->size;
	my @root = (
		'GM[1]', 'FF[4]', 'CA[UTF-8]',
		"AP[Game::Go:$Game::Go::VERSION]",
		"SZ[$size]",
		'KM[' . $game->komi . ']',
		'RU[Japanese]',
	);
	push @root, 'PB[' . _escape($o{black}) . ']' if defined $o{black};
	push @root, 'PW[' . _escape($o{white}) . ']' if defined $o{white};
	push @root, 'DT[' . _escape($o{date}) . ']'  if defined $o{date};

	my @setup;
	my %stones;
	for my $e (@{ $game->log }) {
		if ($e->{kind} eq 'handicap') {
			push @{ $stones{b} }, $e->{payload}{pt};
		}
		elsif ($e->{kind} eq 'setup') {
			for my $letter (sort keys %{ $e->{payload} }) {
				push @{ $stones{$letter} }, @{ $e->{payload}{$letter} };
			}
		}
	}
	push @root, 'HA[' . $game->handicap . ']' if $game->handicap;
	for my $pair (['b', 'AB'], ['w', 'AW']) {
		my ($letter, $prop) = @$pair;
		next unless $stones{$letter};
		push @setup, $prop . join '', map {
			'[' . Game::Go::Notation::to_sgf($size, $game->col_row($_)) . ']'
		} @{ $stones{$letter} };
	}

	my $re = format_result($game);
	push @root, "RE[$re]" if defined $re;

	my $out = '(;' . join('', @root) . join('', @setup);

	for my $e (@{ $game->log }) {
		my $who = Game::Go::Rules::from_letter($e->{actor}) or next;
		my $prop = $who == $B ? 'B' : 'W';

		if ($e->{kind} eq 'pass') { $out .= ";${prop}[]"; next }
		next unless $e->{kind} eq 'play';
		$out .= ";${prop}[" . Game::Go::Notation::to_sgf($size, $game->col_row($e->{payload}{pt})) . ']';
	}

	if ($game->scored_by && $game->outcome) {
		my $raw = $game->raw_score;
		my $marks = _territory_points($game);
		for my $pair (['b', 'TB'], ['w', 'TW']) {
			my ($letter, $prop) = @$pair;
			next unless @{ $marks->{$letter} || [] };
			$out .= "\n$prop" . join '', map {
				'[' . Game::Go::Notation::to_sgf($size, $game->col_row($_)) . ']'
			} @{ $marks->{$letter} };
		}
	}

	return "$out\n)\n";
}

sub _territory_points {
	my ($game) = @_;
	my $map = $game->territory_map;
	my %out = (b => [], w => []);
	for my $pt (sort { $a <=> $b } keys %$map) {
		push @{ $out{ $map->{$pt} == $B ? 'b' : 'w' } }, $pt;
	}
	return \%out;
}

sub _escape {
	my ($s) = @_;
	$s =~ s/([\]\\])/\\$1/g;
	return $s;
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Go::SGF - read and write the SGF subset a Go record needs

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $in = Game::Go::SGF::read($text, lenient => 1);
    my $game = $in->{game};

    print Game::Go::SGF::write($game, black => 'Shusaku', white => 'Gennan');

=head1 DESCRIPTION

Smart Game Format, enough of it to consume a public record and to emit one.

Only the B<main line> is read: the first child at every branch. A record's
variations are somebody's analysis, and a game is what was played.

=head2 The reader is lenient on request, and strict by default

The shipped ruleset forbids suicide and enforces positional superko. B<Real
records contain moves that neither permits>, and a reader that could not be told
to relax would refuse the corpus that is meant to be testing us.

The SGF specification's own execution model permits suicide outright:

    When a B (resp. W) property is encountered, a stone of that color is placed
    on the given position (no matter what was there before). Then the
    application should check any W (resp. B) groups that are adjacent to the
    stone just placed. If they have no liberties they should be removed and the
    prisoner count increased accordingly. Lastly, the B (resp. W) group that the
    newest stone belongs to should be checked for liberties, and if it has no
    liberties, it should be removed (suicide) and the prisoner count increased
    accordingly.

Note also "no matter what was there before", which is the spec saying a record
may place a stone on an occupied point.

So:

    lenient => 0    (default)  the shipped rules. A record that breaks them is
                               refused, naming the move number and the reason
    lenient => 1               simple ko only, so a repetition a real game
                               contained is not refused

B<Making the default lenient would have been the easy mistake>: the site would
then accept an imported game that its own rules refuse. A leniently read game is
a record of what somebody played, not a game this engine would have allowed.

=head2 HA places nothing

The spec:

    Defines the number of handicap stones (>=2). If there is a handicap, the
    position should be set up with AB within the same node. HA itself doesn't
    add any stones to the board, nor does it imply any particular way of placing
    the handicap stones.

So the stones come from C<AB> and C<HA> is a B<cross-check>: a count that
disagrees with C<AB> is refused. A reader that placed stones from C<HA> would put
them on this distribution's star points rather than the ones the game was played
with, which for a free-placement record is a different game.

=head2 A pass has two spellings

    A pass move is shown as '[]' or alternatively as '[tt]' (only for boards
    <= 19x19), i.e. applications should be able to deal with both
    representations. '[tt]' is kept for compatibility with FF[3].

Both are read. Only C<[]> is written. C<tt> works as a sentinel precisely because
it is column 20, off any board this distribution offers, which is also why the
spec limits it to boards of 19 and under.

=head1 FUNCTIONS

=head2 read

    Game::Go::SGF::read($text, lenient => 0)

A hashref: the C<game>, and the record's C<size>, C<komi>, C<handicap>,
C<moves>, C<first>, C<result>, C<players>, C<ranks>, C<date>, C<rules>,
C<territory> and C<setup>.

C<territory> is the C<TB> and C<TW> properties, which is the agreed territory a
server wrote when the game was counted. It is the only external oracle this
distribution's territory scorer will ever have.

=head2 write

    Game::Go::SGF::write($game, black => $name, white => $name, date => $when)

The game as SGF. C<TB> and C<TW> are emitted only for a game that was actually
counted, because until the players agreed there is no agreed territory.

=head2 parse_result, format_result

C<RE> in its five forms and back again:

    B+3.5   a score           B+R   a resignation
    0       a jigo            B+T   a timeout
    Void    no result

C<parse_result> returns a hashref with a C<kind>, and C<unknown> rather than
undef for anything it does not recognise, so a caller can tell "no result
recorded" from "a result I could not read".

=head1 SEE ALSO

L<Game::Go::Notation>, which owns the two coordinate alphabets and the gap
between them.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
