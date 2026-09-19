package Game::Go;

use 5.010;
use strict;
use warnings;

use Object::Proto::Sugar -types;

use Carp ();

use Game::Go::Rules;
use Game::Go::Engine;
use Game::Go::Board;
use Game::Go::Move;
use Game::Go::Error;
use Game::Go::Marking;
use Game::Go::Scoring;
use Game::Go::Result;

our $VERSION = '0.01';

use constant {
	EMPTY  => Game::Go::Rules::EMPTY,
	BLACK  => Game::Go::Rules::BLACK,
	WHITE  => Game::Go::Rules::WHITE,
	BORDER => Game::Go::Rules::BORDER,
};

use constant {
	OK          => Game::Go::Rules::OK,
	ILL_OFF     => Game::Go::Rules::ILL_OFF,
	ILL_TAKEN   => Game::Go::Rules::ILL_TAKEN,
	ILL_KO      => Game::Go::Rules::ILL_KO,
	ILL_SUICIDE => Game::Go::Rules::ILL_SUICIDE,
	ILL_REPEAT  => Game::Go::Rules::ILL_REPEAT,
	ILL_COLOUR  => Game::Go::Rules::ILL_COLOUR,
};

use constant MAX_DISPUTES => 3;

has size     => (is => 'ro', isa => Int, default => 19);
has komi     => (is => 'rw');
has handicap => (is => 'ro', isa => Int, default => 0);

has ko => (is => 'ro', isa => Str, default => 'positional');

has setup => (is => 'ro', private => 1);

has first => (is => 'ro', private => 1);

has status => (is => 'rw', isa => Str, default => 'active');
has phase  => (is => 'rw', isa => Str, default => 'play');
has turn   => (is => 'rw');

has [qw/winner result/] => (is => 'rw');

has scored_by => (is => 'rw');

has outcome => (is => 'rw');

has marking => (is => 'rw');

has disputes => (is => 'rw', default => 0);

has log => (is => 'rw', isa => ArrayRef, default => []);

has _engine => (is => 'rw', private => 1);
has _passes => (is => 'rw', private => 1, default => 0);

has _held_seed => (is => 'ro', init_arg => 'seed', private => 1);

sub BUILD {
	my ($self) = @_;

	my $size = $self->size;
	Carp::croak("Game::Go: size must be 9, 13 or 19, not '$size'")
		unless grep { $_ == $size } Game::Go::Rules::sizes();

	$self->komi(
		$self->handicap
			? Game::Go::Rules::HANDICAP_KOMI
			: Game::Go::Rules::DEFAULT_KOMI
	) unless defined $self->komi;

	my $komi = $self->komi;
	Carp::croak("Game::Go: komi must be a multiple of 0.5, not '$komi'")
		unless $komi =~ /\A-?[0-9]+(?:\.[05])?\z/;

	my $handicap = $self->handicap;
	my $most = Game::Go::Rules::max_handicap($size);
	Carp::croak("Game::Go: handicap must be 0 to $most on a ${size}x$size board, not '$handicap'")
		if $handicap < 0 || $handicap > $most;

	my $ko = $self->ko;
	Carp::croak("Game::Go: ko must be 'positional' or 'simple', not '$ko'")
		unless $ko eq 'positional' || $ko eq 'simple';

	$self->_engine(Game::Go::Engine->new(size => $size));
	$self->_engine->superko(0) if $ko eq 'simple';

	$self->turn(BLACK);

	$self->_log('sys', 'start', {
		size     => $size,
		komi     => $komi + 0,
		handicap => $handicap,
		ko       => $ko,
		first    => Game::Go::Rules::letter($self->turn),
	});

	$self->_place_setup($self->setup) if $self->setup;
	$self->_place_handicap($handicap) if $handicap > 1;

	if (my $first = $self->first) {
		my $who = Game::Go::Rules::from_letter($first);
		Carp::croak("Game::Go: first must be 'b' or 'w', not '$first'") unless $who;
		$self->turn($who);
	}

	return;
}

sub _place_setup {
	my ($self, $setup) = @_;
	my %placed;

	for my $letter (sort keys %$setup) {
		my $colour = Game::Go::Rules::from_letter($letter);
		Carp::croak("Game::Go: setup names '$letter', which is not a colour")
			unless $colour;
		for my $cr (@{ $setup->{$letter} }) {
			my $pt = $self->point(@$cr);
			Carp::croak('Game::Go: a setup stone is off the board') if $pt < 0;
			$self->_engine->put($pt, $colour);
			push @{ $placed{$letter} }, $pt;
		}
	}

	$self->_log('sys', 'setup', \%placed);
	$self->_engine->push_position;
	return;
}

sub _place_handicap {
	my ($self, $n) = @_;
	my $points = Game::Go::Rules::handicap_points($self->size, $n);

	for my $cr (@$points) {
		my $pt = $self->point(@$cr);

		$self->_engine->put($pt, BLACK);
		$self->_log(Game::Go::Rules::letter(BLACK), 'handicap', { pt => $pt });
	}

	$self->_engine->push_position;

	$self->turn(WHITE);
	return;
}

sub seats { (BLACK, WHITE) }

sub board { Game::Go::Board->new($_[0]->_engine) }

sub point { $_[0]->_engine->point_of($_[1], $_[2]) }

sub col_row {
	my ($self, $pt) = @_;
	my $engine = $self->_engine;
	return ($engine->col_of($pt), $engine->row_of($pt));
}

sub events { [ map { { %$_ } } @{ $_[0]->log } ] }

sub raw_score {
	my ($self) = @_;
	my $m = $self->marking;
	my $p = $self->prisoners;
	return $self->_engine->score(
		dead        => ($m ? $m->dead_points : []),
		seki        => ($m ? $m->seki_points : []),
		prisoners_b => $p->{ +BLACK },
		prisoners_w => $p->{ +WHITE },
		komi_tenths => int($self->komi * 10 + ($self->komi < 0 ? -0.5 : 0.5)),
	);
}

sub raw_area { $_[0]->_engine->area_score }

sub territory_map {
	my ($self) = @_;
	my $m = $self->marking;
	return $self->_engine->territory_map(
		dead => ($m ? $m->dead_points : []),
		seki => ($m ? $m->seki_points : []),
	);
}

sub _handicap_points {
	my ($self) = @_;
	return [ map { $self->point(@$_) }
		@{ Game::Go::Rules::handicap_points($self->size, $self->handicap) } ];
}

sub star_points {
	my ($self) = @_;
	return [ map { $self->point(@$_) } @{ Game::Go::Rules::star_points($self->size) } ];
}

sub ko_point  { $_[0]->_engine->ko_point }
sub ko_colour { $_[0]->_engine->ko_colour }

sub search_from {
	my ($self, %o) = @_;
	return $self->_engine->search(%o);
}

sub dead_guess_from {
	my ($self, %o) = @_;
	return $self->_engine->dead_guess(%o);
}

sub is_alive { $_[0]->_engine->is_alive($_[1]) }

sub chain_id { $_[0]->_chain_id($_[1]) }

sub marked_seki { $_[0]->marking ? $_[0]->marking->seki_points : [] }
sub marked_dead { $_[0]->marking ? $_[0]->marking->dead_points : [] }

sub prisoners {
	my ($self) = @_;
	my %taken = (BLACK, 0, WHITE, 0);
	for my $e (@{ $self->log }) {
		next unless $e->{kind} eq 'play';
		my $by = Game::Go::Rules::from_letter($e->{actor}) or next;
		$taken{$by} += scalar @{ $e->{payload}{caps} || [] };
	}
	return \%taken;
}

sub waiting_on {
	my ($self) = @_;
	return () unless $self->status eq 'active';
	return ($self->marking->turn) if $self->phase eq 'marking';
	return ($self->turn);
}

sub seed { $_[0]->status eq 'finished' ? $_[0]->_held_seed : undef }


sub _log {
	my ($self, $actor, $kind, $payload) = @_;
	push @{ $self->log }, {
		actor   => $actor,
		kind    => $kind,
		payload => $payload || {},
	};
	return;
}

sub _guard {
	my ($self, $colour) = @_;
	return Game::Go::Error->throw('bad_colour')
		unless Game::Go::Rules::is_colour($colour);
	return Game::Go::Error->throw('game_over')
		unless $self->status eq 'active';
	return Game::Go::Error->throw('still_marking')
		unless $self->phase eq 'play';
	return Game::Go::Error->throw('not_your_turn')
		unless $colour == $self->turn;
	return undef;
}

sub legal {
	my ($self, $colour) = @_;
	return [] unless Game::Go::Rules::is_colour($colour);
	return [] unless $self->status eq 'active';

	return $self->_legal_marking($colour) if $self->phase eq 'marking';

	return [] unless $colour == $self->turn;

	my $engine = $self->_engine;
	my @moves = map {
		Game::Go::Move->new(kind => 'play', colour => $colour, point => $_)
	} @{ $engine->legal_moves($colour) };

	push @moves, Game::Go::Move->new(kind => 'pass', colour => $colour);

	return \@moves;
}

sub play {
	my ($self, $colour, $pt) = @_;
	my $stop = $self->_guard($colour);
	return $stop if $stop;

	my $r = $self->_engine->play($pt, $colour);
	return Game::Go::Error->from_code($r->{code}) unless $r->{ok};

	$self->_passes(0);
	$self->_log(Game::Go::Rules::letter($colour), 'play', {
		pt   => $pt,
		caps => $r->{caps},
	});
	$self->turn(Game::Go::Rules::other($colour));

	return Game::Go::Move->new(
		kind   => 'play',
		colour => $colour,
		point  => $pt,
		caps   => $r->{caps},
	);
}

sub pass {
	my ($self, $colour) = @_;
	my $stop = $self->_guard($colour);
	return $stop if $stop;

	$self->_engine->pass($colour);
	$self->_log(Game::Go::Rules::letter($colour), 'pass');
	$self->_passes($self->_passes + 1);
	$self->turn(Game::Go::Rules::other($colour));

	$self->_stop if $self->_passes >= 2;

	return Game::Go::Move->new(kind => 'pass', colour => $colour);
}

sub _stop {
	my ($self) = @_;
	$self->_log('sys', 'stop');

	if ($self->disputes >= MAX_DISPUTES) {
		$self->_log('sys', 'area');
		return $self->_score('area');
	}

	$self->phase('marking');
	$self->marking(Game::Go::Marking->new(
		proposer => $self->turn,
		answerer => Game::Go::Rules::other($self->turn),
	));
	return;
}


sub _legal_marking {
	my ($self, $colour) = @_;
	my $m = $self->marking;
	return [] unless $m && $colour == $m->turn;

	my @moves;

	if (!$m->proposed) {
		my $engine = $self->_engine;
		my $alive  = $self->_alive_set;
		my %chain;
		for my $row (0 .. $self->size - 1) {
			for my $col (0 .. $self->size - 1) {
				my $pt = $engine->point_of($col, $row);
				my $at = $engine->at($pt);
				if ($at == EMPTY) {
					push @moves, Game::Go::Move->new(
						kind   => ($m->is_seki($pt) ? 'unseki' : 'seki'),
						colour => $colour,
						point  => $pt,
					);
					next;
				}
				next if $alive->{$pt};
				my $id = $self->_chain_id($pt);
				next if !defined $id || $chain{$id}++;
				push @moves, Game::Go::Move->new(
					kind   => ($m->is_dead($id) ? 'unmark' : 'mark'),
					colour => $colour,
					point  => $id,
				);
			}
		}
		push @moves, Game::Go::Move->new(kind => 'done', colour => $colour);
		return \@moves;
	}

	push @moves, Game::Go::Move->new(kind => 'accept', colour => $colour);
	push @moves, Game::Go::Move->new(kind => 'dispute', colour => $colour)
		if $self->disputes < MAX_DISPUTES;
	return \@moves;
}

sub _chain_id {
	my ($self, $pt) = @_;
	my $stones = $self->_engine->chain_at($pt);
	return undef unless @$stones;
	my ($low) = sort { $a <=> $b } @$stones;
	return $low;
}

sub _marking_guard {
	my ($self, $colour, $role) = @_;
	return Game::Go::Error->throw('bad_colour')
		unless Game::Go::Rules::is_colour($colour);
	return Game::Go::Error->throw('game_over')
		unless $self->status eq 'active';
	return Game::Go::Error->throw('not_marking')
		unless $self->phase eq 'marking';

	my $m = $self->marking;
	my $whose = $role eq 'proposer' ? $m->proposer : $m->answerer;
	return Game::Go::Error->throw('not_your_turn')
		unless $colour == $whose && $colour == $m->turn;
	return undef;
}

sub _alive_set {
	my ($self) = @_;
	my $engine = $self->_engine;
	my %alive;
	for my $colour ($self->seats) {
		$alive{$_} = 1 for @{ $engine->alive($colour) };
	}
	return \%alive;
}

sub mark {
	my ($self, $colour, $pt) = @_;
	my $stop = $self->_marking_guard($colour, 'proposer');
	return $stop if $stop;

	my $id = $self->_chain_id($pt);
	return Game::Go::Error->throw('not_a_chain') unless defined $id;

	return Game::Go::Error->throw('alive_chain')
		if $self->_alive_set->{$pt};

	my $on = $self->marking->toggle_dead($id);
	$self->_log(Game::Go::Rules::letter($colour), ($on ? 'mark' : 'unmark'), { chain => $id });
	return Game::Go::Move->new(
		kind   => ($on ? 'mark' : 'unmark'),
		colour => $colour,
		point  => $id,
	);
}

sub mark_seki {
	my ($self, $colour, $pt) = @_;
	my $stop = $self->_marking_guard($colour, 'proposer');
	return $stop if $stop;

	return Game::Go::Error->throw('off_board')
		unless $self->_engine->at($pt) == EMPTY;

	my $on = $self->marking->toggle_seki($pt);
	$self->_log(Game::Go::Rules::letter($colour), ($on ? 'seki' : 'unseki'), { region => $pt });
	return Game::Go::Move->new(
		kind   => ($on ? 'seki' : 'unseki'),
		colour => $colour,
		point  => $pt,
	);
}

sub done {
	my ($self, $colour) = @_;
	my $stop = $self->_marking_guard($colour, 'proposer');
	return $stop if $stop;

	$self->marking->proposed(1);
	$self->_log(Game::Go::Rules::letter($colour), 'done');
	return Game::Go::Move->new(kind => 'done', colour => $colour);
}

sub accept {
	my ($self, $colour) = @_;
	my $stop = $self->_marking_guard($colour, 'answerer');
	return $stop if $stop;

	$self->_log(Game::Go::Rules::letter($colour), 'accept');
	return $self->_score('territory');
}

sub dispute {
	my ($self, $colour) = @_;
	my $stop = $self->_marking_guard($colour, 'answerer');
	return $stop if $stop;

	my $proposer = $self->marking->proposer;
	$self->disputes($self->disputes + 1);
	$self->_log(Game::Go::Rules::letter($colour), 'dispute');

	$self->phase('play');
	$self->marking(undef);
	$self->_passes(0);
	$self->turn($proposer);
	$self->_log('sys', 'resumed', { first => Game::Go::Rules::letter($proposer) });

	return Game::Go::Move->new(kind => 'dispute', colour => $colour);
}

sub _score {
	my ($self, $how) = @_;
	$self->scored_by($how);

	my $scored = $how eq 'area'
		? Game::Go::Scoring::score_by_area($self)
		: Game::Go::Scoring::score($self, scored_by => 'territory');

	$self->phase('play');
	$self->marking(undef);
	$self->outcome($scored);
	return $self->_finish($scored->winner, 'score');
}


sub resign {
	my ($self, $colour) = @_;
	return Game::Go::Error->throw('bad_colour')
		unless Game::Go::Rules::is_colour($colour);
	return Game::Go::Error->throw('game_over')
		unless $self->status eq 'active';

	$self->_log(Game::Go::Rules::letter($colour), 'resign');
	return $self->_finish(Game::Go::Rules::other($colour), 'resign');
}

sub timeout {
	my ($self, $colour) = @_;
	return Game::Go::Error->throw('bad_colour')
		unless Game::Go::Rules::is_colour($colour);
	return Game::Go::Error->throw('game_over')
		unless $self->status eq 'active';

	$self->_log('sys', 'timeout', { p => Game::Go::Rules::letter($colour) });
	return $self->_finish(Game::Go::Rules::other($colour), 'timeout');
}

sub abandon {
	my ($self) = @_;
	return Game::Go::Error->throw('game_over')
		unless $self->status eq 'active';

	$self->_log('sys', 'abandon');
	return $self->_finish(undef, 'abandoned');
}

sub _finish {
	my ($self, $winner, $result) = @_;
	$self->status('finished');
	$self->winner($winner);
	$self->result($result);
	$self->turn(undef);
	$self->_log('sys', 'game_end', {
		winner    => (defined $winner ? Game::Go::Rules::letter($winner) : undef),
		result    => $result,
		scored_by => $self->scored_by,
	});
	return $result;
}


our %SITE_OWNED;
BEGIN { %SITE_OWNED = map { $_ => 1 } qw(timeout abandon) }

sub replay {
	my ($self, $events) = @_;
	Carp::croak('Game::Go: replay wants an arrayref of events')
		unless ref $events eq 'ARRAY';

	my $seen = 0;
	my $seen_handicap = 0;
	for my $e (@$events) {
		my $actor = $e->{actor};
		my $kind  = $e->{kind};
		my $load  = $e->{payload} || {};
		$seen++;

		if ($actor eq 'sys') {
			if ($kind eq 'timeout') {
				my $who = Game::Go::Rules::from_letter($load->{p} || '');
				Carp::croak("Game::Go: replay: timeout names no colour") unless $who;
				$self->timeout($who);
				next;
			}
			if ($kind eq 'abandon') {
				$self->abandon;
				next;
			}

			my $mine = $self->_last_sys($kind);
			Carp::croak("Game::Go: replay: the log claims a 'sys $kind' the engine did not produce")
				unless $mine;
			$self->_agree($kind, $load, $mine->{payload});
			next;
		}

		my $colour = Game::Go::Rules::from_letter($actor);
		Carp::croak("Game::Go: replay: '$actor' is not a player") unless $colour;

		if ($kind eq 'handicap') {
			my $mine = $self->_handicap_points;
			my $want = $mine->[ $seen_handicap++ ];
			Carp::croak('Game::Go: replay: the log has more handicap stones than this board places')
				unless defined $want;
			Carp::croak("Game::Go: replay: handicap stone $seen_handicap is on the wrong point")
				unless defined $load->{pt} && $load->{pt} == $want;
			next;
		}

		my $out;
		if    ($kind eq 'play')   { $out = $self->play($colour, $load->{pt}) }
		elsif ($kind eq 'pass')   { $out = $self->pass($colour) }
		elsif ($kind eq 'resign') { $out = $self->resign($colour); next }

		elsif ($kind eq 'mark' || $kind eq 'unmark') {
			$out = $self->mark($colour, $load->{chain});
			Carp::croak("Game::Go: replay: the log's '$kind' came out as a '"
				. $out->kind . "'")
				if ref $out eq 'Game::Go::Move' && $out->kind ne $kind;
		}
		elsif ($kind eq 'seki' || $kind eq 'unseki') {
			$out = $self->mark_seki($colour, $load->{region});
			Carp::croak("Game::Go: replay: the log's '$kind' came out as a '"
				. $out->kind . "'")
				if ref $out eq 'Game::Go::Move' && $out->kind ne $kind;
		}
		elsif ($kind eq 'done')    { $out = $self->done($colour) }
		elsif ($kind eq 'accept')  { $out = $self->accept($colour); next }
		elsif ($kind eq 'dispute') { $out = $self->dispute($colour) }

		else { Carp::croak("Game::Go: replay: no such player event '$kind'") }

		Carp::croak("Game::Go: replay: the log's '$kind' was refused: " . $out->message)
			if ref $out eq 'Game::Go::Error';
	}

	return $seen;
}

sub _last_sys {
	my ($self, $kind) = @_;
	for my $e (reverse @{ $self->log }) {
		return $e if $e->{actor} eq 'sys' && $e->{kind} eq $kind;
	}
	return undef;
}

sub _agree {
	my ($self, $kind, $theirs, $mine) = @_;
	for my $key (sort keys %$mine) {
		Carp::croak("Game::Go: replay: 'sys $kind' disagrees about $key")
			unless _same($mine->{$key}, $theirs->{$key});
	}
	return;
}

sub _same {
	my ($a, $b) = @_;
	return 1 if !defined $a && !defined $b;
	return 0 if !defined $a || !defined $b;

	if (ref $a eq 'ARRAY' || ref $b eq 'ARRAY') {
		return 0 unless ref $a eq 'ARRAY' && ref $b eq 'ARRAY';
		return 0 unless @$a == @$b;
		_same($a->[$_], $b->[$_]) or return 0 for 0 .. $#$a;
		return 1;
	}

	return $a eq $b ? 1 : 0;
}

sub clone {
	my ($self) = @_;
	my $new = ref($self)->new(
		size     => $self->size,
		komi     => $self->komi,
		handicap => $self->handicap,
		seed     => $self->_held_seed,
	);
	$new->replay($self->events);
	return $new;
}

sub sizes       { Game::Go::Rules::sizes() }
sub other       { Game::Go::Rules::other($_[-1]) }
sub refusal     { Game::Go::Rules::refusal($_[-1]) }
sub refusals    { Game::Go::Rules::refusals() }
sub abi_version { Game::Go::Engine::_abi_version() }

1;

__END__

=encoding utf8

=head1 NAME

Game::Go - the rules of Go, with the board in C

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Go;

    my $game = Game::Go->new(size => 9, seed => $bytes);

    my $moves = $game->legal($game->turn);          # plays, and a pass
    my $move  = $game->play(Game::Go::BLACK, $pt);

    if (ref $move eq 'Game::Go::Error') {
        say $move->message;
    }

    print $game->board->to_text;

=head1 DESCRIPTION

Go on a 9x9, 13x13 or 19x19 board, under the Japanese rules of 1989 with one
declared amendment. The board, the chains and the liberties are in C behind a
published ABI; this is the game over them.

It is the engine behind the go at L<https://peer2peergames.com>.

=head2 What is here in this version

Turn order, plays, passes, the log, and replay. Resignation, timeout and
abandonment.

B<Not here yet>: the confirmation phase that Article 9 requires, and therefore
scoring. Two consecutive passes stop play and put the game into the C<marking>
phase, which is as far as it goes: agreeing the dead stones and counting the
territory are the next two phases of work.

=head2 A point is opaque

A point is a padded index into a board that carries a sentinel ring, so that the
engine's four-neighbour walk needs no bounds test. It is B<not>
C<row * size + col>. Build one with L<Game::Go::Board>, or with
C<< $game->board >>, which speaks in columns and rows and never hands one out.

=head2 The log is the game

The event log is the canonical serialisation, not the position. For Go that is
not even arguable: a position cannot say what the ko point is, so a snapshot
loses the rule that makes a ko fight a ko fight, and it cannot say how many
prisoners each side holds, which under Article 10.2 is half the score.

So a log carries the engine's B<point index> and nothing prettier. A log written
in coordinates reads well and replays wrongly, because C<replay> hands each
player event straight back to the method that made it.

=head1 CONSTANTS

=head2 EMPTY, BLACK, WHITE, BORDER

=head2 OK, ILL_OFF, ILL_TAKEN, ILL_KO, ILL_SUICIDE, ILL_REPEAT, ILL_COLOUR

Aliases for the values in L<Game::Go::Rules>, where they are defined.

The C<ILL_> codes are what L<Game::Go::Engine> returns. This facade turns them
into L<Game::Go::Error> objects, so a caller of C<Game::Go> normally sees flags
and sentences rather than numbers.

=head1 METHODS

=head2 new

    Game::Go->new(size => 9, komi => 6.5, handicap => 0, seed => $bytes)

C<size> must be 9, 13 or 19. C<komi> must be a multiple of 0.5. C<handicap> is
accepted and B<not yet implemented>: a non-zero one croaks, because the
traditional placements are a convention that has to be cited before it is typed,
and guessing at them would be worse than refusing.

A bad argument croaks. That is programmer error, not a refused move.

=head2 size, komi, handicap, status, phase, turn, winner, result, log

C<status> is C<active> or C<finished>. C<phase> is C<play> or C<marking>, and it
is a separate thing from C<status> because Article 9 stops play and ends the
game in two different sentences: a game being counted has not ended.

=head2 ko

C<positional> by default, which is the shipped rule, or C<simple> to leave
Article 6's ko rule alone and turn the superko backstop off.

C<simple> exists for one reason: B<real records contain moves the shipped
ruleset refuses>, and a reader that could not be told to relax would refuse the
corpus that is meant to be testing us. See L<Game::Go::SGF>'s C<lenient>.

=head2 setup, first

Constructor arguments, not for general use: stones placed before anybody moves,
and which colour then plays. They are what SGF's C<AB>, C<AW> and C<PL>
properties need, so that a foreign record's handicap stones go where B<that>
record put them rather than where this distribution's own table would.

C<setup> is a hashref of colour letter to C<[$col, $row]> pairs, logged as one
C<sys setup> event so a replay reproduces the position. C<first> is C<b> or
C<w>.

=head2 territory_map

Who owns each empty point, as a hashref of point to colour, holding only the
points that belong to somebody.

B<It comes from the engine rather than being worked out here>, and that is not
laziness. Territory is a property of a B<region>: an empty point beside one
black stone on an otherwise open board is part of one big region that reaches
both colours, and it belongs to nobody. A per-point neighbour check says it is
black's, and an early version of the SGF writer did exactly that and gave a
nearly empty board eight points of territory the scorer had given it none of.

For a page that shades the territory, and for SGF's C<TB> and C<TW>.

=head2 search_from, dead_guess_from, is_alive, chain_id

What a searcher needs, and the whole of it.

L<Object::Proto::Sugar> makes the engine private, so a bot in another module
cannot reach past this class to the board, and it should not: a searcher that
did would be reaching past the rules.

C<search_from> takes the root moves B<this class has already filtered>, which is
how the C never has to see the superko history: the history lives here.
C<chain_id> is the id the confirmation phase names a chain by, its lowest point,
which survives a replay where the engine's own chain root does not.

=head2 seats

C<BLACK> and C<WHITE>.

=head2 board

A L<Game::Go::Board>: a read-only view in columns and rows.

=head2 point, col_row

    my $pt = $game->point($col, $row);      # -1 off the board
    my ($col, $row) = $game->col_row($pt);

The two ways across the boundary between what a person names and what C<play>
takes. They exist because a point is opaque and the engine that can build one is
private: without them the only route to a point would be through C<legal>, which
suits a bot and is useless to somebody who wants to play a particular square.

=head2 events

A copy of the log.

=head2 prisoners

How many stones each colour has captured, as a hashref keyed by colour. Derived
from the log rather than kept, because the log is the game.

=head2 waiting_on

The colours whose move is awaited: one while the game runs, none once it is
over.

=head2 seed

The seed, B<and only once the game is finished>. While it is running this
returns undef, which is what lets a site publish the seed at the end so anyone
can re-verify a bot's play without being able to read it in advance.

=head2 legal

    $game->legal($colour)

The moves this colour may make now, as L<Game::Go::Move> objects. An arrayref,
empty off turn, after the end, and during confirmation.

B<A pass is always in the list.> This is the opposite of the previous game the
house built, where the pass is forced, automatic, never offered and refused if
posted. In Go a pass is a move a player makes on purpose, at any time, and it is
the only way a game ever reaches a score, so a list without one would describe a
game that cannot end.

=head2 play

    $game->play($colour, $point)

A L<Game::Go::Move>, or a L<Game::Go::Error>. Never dies for a refused move.

=head2 pass

A L<Game::Go::Move>, or an error. Two consecutive passes stop play and move the
game into the C<marking> phase, per Article 9.1.

=head1 THE CONFIRMATION PHASE

Two consecutive passes B<stop play>. They do not end the game. Article 9.2 ends
it, "through confirmation and agreement by the two players about the life and
death of stones and territory", and that is a negotiation rather than a
computation.

B<It is sequential, and the site is the reason.> The obvious design has both
players confirming, so both seats wait; the site voids a game whose deadline
passes with two seats waiting, and a game that has reached this phase has been
played to the end. So the proposer marks and says C<done>, then the answerer
accepts or disputes, and exactly one seat is waiting in every reachable state.

=head2 marking

The L<Game::Go::Marking> while there is one, and undef otherwise.

=head2 scored_by

How a scored game was scored: C<territory> when the players agreed, C<area> when
they could not and the disputes ran out. Undef until the game is scored, and
undef forever on a resignation, timeout or abandonment.

=head2 outcome

The L<Game::Go::Result> once the game has been counted, and undef otherwise
(including after a resignation, a timeout or an abandonment, none of which is
counted).

B<It is not called C<result>, and the name is the site's doing.> C<result> is one
of four strings and goes straight into a column CHECK-constrained to exactly
those; the workings, the territory counts and the prisoner fill are a different
thing with a different lifetime. Naming both C<result> would have meant the
adapter reaching for a string and getting an object on the one code path where
it matters most.

=head2 raw_score, raw_area

The two scorers' own numbers, as hashrefs, before they are dressed as a result.
Scores in them are in B<tenths>, because komi is fractional and the C engine has
no floats.

These are public because the scorer is a separate module and the engine is
private: L<Object::Proto::Sugar> enforces that, so L<Game::Go::Scoring> cannot
reach past this class to the board, and it should not. A scorer that is a pure
function of numbers is a scorer a test can feed by hand, and a page that wants to
show the workings rather than print a bare margin wants these too.

=head2 star_points

The board's star points, as engine points. Nine on 19x19 and five on the other
two, which is why a nine-stone handicap is a 19x19 thing.

=head2 ko_point, ko_colour

The point a ko forbids, or -1, and the one colour it forbids it to.

Public because a client has to be able to draw it. A point that is empty and
refused needs a reason visible on the board, not only in the error a player gets
after clicking it.

A ko restricts B<one player>, per Article 6: "A player whose stone has been
captured in a ko cannot recapture in that ko on the next move." The capturer may
play the point, and on a filled board sometimes wants to.

=head2 marked_dead, marked_seki

What the confirmation phase has agreed, as arrayrefs of points, or empty when
there is no confirmation phase.

=head2 disputes

How many times the answerer has sent the game back to the board.

=head2 mark

    $game->mark($colour, $point)

Toggles the chain at a point between dead and not. The proposer's move.

B<Benson's algorithm is a veto here, not a proposal.> Nothing is marked dead by
default, because a dead-stone proposal is a life-and-death solver and this
distribution does not have one. What it does have is the set of chains that are
unconditionally alive, and a chain in that set B<cannot be agreed dead>: the
attempt is refused with C<alive_chain>.

Without that, a player who has lost could mark the opponent's living wall dead,
refuse to accept, and force the dispute path every game. With it, the worst they
can mark is something merely alive, which is exactly the case Article 9.3 exists
to settle by playing it out.

=head2 mark_seki

Toggles an empty point as seki. Article 8 gives seki no territory, not even its
eye points, and no flood fill can see that on its own, so seki is an agreed fact
rather than a detected one.

=head2 done

Ends the proposal and passes the turn to the answerer.

=head2 accept

Ends the game, scored by territory. The proposer's marks stand.

=head2 dispute

Sends the game back to the board, and B<the proposer gets the move>.

Article 9.3: "If a player requests resumption of a stopped game, his opponent
must oblige and has the right to play first." The answerer asked, so the
proposer moves. This reads backwards until you see what it is for: asking to
resume costs you the initiative, and that is the only thing stopping a player
who is losing from asking forever.

A game may be sent back three times. After that the next stoppage has B<no
confirmation phase at all> and the game is scored by area, which needs nobody's
agreement. Skipping the phase rather than forcing an acceptance is deliberate:
forcing the answerer to accept would let the proposer put up an absurd dead set
on the last round and win with it.

=head2 resign, timeout, abandon

The three ends that are not a score. Each finishes the game and returns the
result string.

C<timeout> and C<abandon> are B<the site talking, not the engine>: nothing in the
rules of Go knows about a clock or a player walking away. They are here because
the log has to carry them, and they are the only two kinds C<replay> applies
rather than regenerates.

=head2 replay

    $game->replay(\@events)

Applies a log to a fresh game and returns the number of events seen.

Player events are handed back to the method that made them and must be accepted.
C<sys timeout> and C<sys abandon> are applied. B<Every other sys event is
regenerated and compared>, and a disagreement croaks: a log the engine does not
reproduce is a log that cannot be trusted, and that is what makes a forged one
detectable.

=head2 clone

An independent game at the same position, by replaying this one's log.

=head2 sizes, other, refusal, refusals

Delegated to L<Game::Go::Rules>.

=head2 abi_version

The version of the C ABI this build carries. A consumer requires C<< >= >> the
version it was written against and never C<==>: the table only ever grows at the
end.

=head1 HOW THIS IS TESTED, AND WHAT IT IS TESTED AGAINST

There is B<no perft ladder for Go>, and that absence is a decision rather than
an omission.

A sibling distribution can check a move generator against an independently
published count of positions by ply, which is the strongest kind of oracle
there is: somebody else's arithmetic, arrived at by somebody else's code. Go has
no equivalent. The branching factor makes a leaf count useless as an oracle even
where one exists, the numbers are astronomical by depth five, nobody has
published them per ruleset, and a ruleset-dependent count would compare our
rules against somebody else's rather than test either. Generating a ladder from
this engine and calling it one would be the engine agreeing with itself with
extra steps.

What stands in its place, in the order of what each is worth:

=over 4

=item 1

B<The territory and area scorers, over the same position.> Two scorers, one
board, and a published condition under which they must agree exactly. This is
the only differential test a distribution with one implementation of everything
can have, and it runs over every game the suite plays.

=item 2

B<The maintained structures, recomputed from scratch in Perl.> The chains, the
liberty counts and the zobrist key are derived quantities, so they can be worked
out again from the colours alone by code that shares nothing with the C. See
F<t/12-invariants.t>, and F<xt/invariants-paranoid.t> which does it after every
move of every game.

=item 3

B<Real records, replayed.> F<t/05-sgf-replay.t> and F<t/26-score-sgf.t> read
F<t/sgf/>, which ships empty of records and explains why in its F<README>.

=item 4

B<Another engine, over GTP.> L<Game::Go::GTP> exists so that something outside
this distribution can answer C<final_status_list dead> and play a match.

=item 5

B<Benson's published positions>, which are exact, and hand-derived vectors, one
per pinned rule, each with its derivation written beside it.

=back

=head1 SEE ALSO

L<Game::Go::Board>, L<Game::Go::Engine>, L<Game::Go::Move>,
L<Game::Go::Error>, L<Game::Go::Rules>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
