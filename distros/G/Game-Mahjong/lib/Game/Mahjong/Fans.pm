package Game::Mahjong::Fans;

use 5.010;
use strict;
use warnings;

use Game::Mahjong::Tiles;
use Game::Mahjong::Fan;

our $VERSION = '0.01';

our @GRADES = (88, 64, 48, 32, 24, 16, 12, 8, 6, 4, 2, 1);
our %PER_GRADE = (88 => 7, 64 => 6, 48 => 2, 32 => 3, 24 => 9, 16 => 6, 12 => 5, 8 => 10, 6 => 6, 4 => 4, 2 => 10, 1 => 13);
use constant COUNT => 81;

sub view {
	my ($split, $ctx) = @_;
	$ctx ||= {};
	my @sets;
	for my $i (0 .. $#{ $split->{sets} }) {
		my $s = $split->{sets}[$i];
		my $t0 = $s->{tiles}[0];
		push @sets, {
			%$s,
			i     => $i,
			suit  => Game::Mahjong::Tiles::suit_of($t0),
			base  => Game::Mahjong::Tiles::rank_of($t0),
			tile  => $t0,
			honour => Game::Mahjong::Tiles::is_honour($t0),
			exposed => ($s->{melded} && !$s->{concealed}) ? 1 : 0,
		};
	}
	my @chows = grep { $_->{kind} eq 'chow' } @sets;
	my @pungs = grep { $_->{kind} eq 'pung' || $_->{kind} eq 'kong' } @sets;
	my @kongs = grep { $_->{kind} eq 'kong' } @sets;
	my @knits = grep { $_->{kind} eq 'knit' } @sets;

	my @tiles;
	for my $s (@sets) {
		push @tiles, @{ $s->{tiles} };
	}
	push @tiles, ($split->{pair}) x 2 if $split->{pair} && $split->{form} ne 'seven_pairs' && $split->{form} ne 'thirteen_orphans';
	if ($split->{form} eq 'seven_pairs') {
		push @tiles, map { ($_) x 2 } @{ $split->{singles} };
	}
	elsif ($split->{form} eq 'thirteen_orphans') {
		push @tiles, @{ $split->{singles} }, $split->{pair};
	}
	elsif ($split->{form} eq 'honours_knitted') {
		push @tiles, @{ $split->{singles} };
	}
	my %count;
	$count{$_}++ for @tiles;
	my %suits;
	my $honours = 0;
	for my $t (@tiles) {
		if (my $s = Game::Mahjong::Tiles::suit_of($t)) { $suits{$s}++ }
		else { $honours++ }
	}

	my @elements = (@sets);
	if ($split->{form} eq 'seven_pairs') {
		@elements = map { { kind => 'pair', tiles => [ ($_) x 2 ], tile => $_, suit => Game::Mahjong::Tiles::suit_of($_), base => Game::Mahjong::Tiles::rank_of($_), honour => Game::Mahjong::Tiles::is_honour($_) } } @{ $split->{singles} };
	}
	elsif ($split->{pair}) {
		my $p = $split->{pair};
		push @elements, { kind => 'pair', tiles => [ $p, $p ], tile => $p, suit => Game::Mahjong::Tiles::suit_of($p), base => Game::Mahjong::Tiles::rank_of($p), honour => Game::Mahjong::Tiles::is_honour($p) };
	}

	return {
		split    => $split,
		ctx      => $ctx,
		form     => $split->{form},
		sets     => \@sets,
		chows    => \@chows,
		pungs    => \@pungs,
		kongs    => \@kongs,
		knits    => \@knits,
		pair     => $split->{pair},
		elements => \@elements,
		tiles    => \@tiles,
		count    => \%count,
		suits    => [ sort keys %suits ],
		nsuits   => scalar keys %suits,
		honours  => $honours,
		exposed  => scalar(grep { $_->{exposed} } @sets),
		concealed_pungs => [ grep { $_->{concealed} } @pungs ],
		wait     => $split->{placement}{wait},
		place_in => $split->{placement}{in},
		nwaits   => ($ctx->{waits} ? scalar @{ $ctx->{waits} } : 1),
	};
}

sub _every { my ($v, $pred) = @_; return 0 unless @{ $v->{tiles} }; for (@{ $v->{tiles} }) { return 0 unless $pred->($_) } return 1 }
sub _one   { return ({ sets => [ map { $_->{i} } @_ ] }) }
sub _standard { return $_[0]->{form} eq 'standard' ? 1 : 0 }
sub _pairs_of { my ($list) = @_; my @p; for my $i (0 .. $#$list) { for my $j ($i + 1 .. $#$list) { push @p, [ $list->[$i], $list->[$j] ] } } return @p }
sub _triples_of { my ($list) = @_; my @t; for my $i (0 .. $#$list) { for my $j ($i + 1 .. $#$list) { for my $k ($j + 1 .. $#$list) { push @t, [ $list->[$i], $list->[$j], $list->[$k] ] } } } return @t }
sub _wind_of  { my ($v, $which) = @_; my $i = $v->{ctx}{$which}; return defined $i ? 28 + $i : -1 }
sub _same_suit { my @s = @_; my $suit = $s[0]{suit}; return 0 unless defined $suit; for (@s) { return 0 unless defined $_->{suit} && $_->{suit} eq $suit } return 1 }
sub _three_suits { my @s = @_; my %seen; for (@s) { return 0 unless defined $_->{suit}; $seen{ $_->{suit} }++ } return scalar(keys %seen) == 3 ? 1 : 0 }
sub _bases_shifted { my ($by, @s) = @_; my @b = sort { $a <=> $b } map { $_->{base} } @s; for my $i (1 .. $#b) { return 0 unless $b[$i] == $b[$i - 1] + $by } return 1 }
sub _bases_are { my ($want, @s) = @_; return join(',', sort { $a <=> $b } map { $_->{base} } @s) eq $want ? 1 : 0 }
sub _wind_pungs { return grep { Game::Mahjong::Tiles::is_wind($_->{tile}) } @{ $_[0]->{pungs} } }
sub _dragon_pungs { return grep { Game::Mahjong::Tiles::is_dragon($_->{tile}) } @{ $_[0]->{pungs} } }
sub _is_terminal_or_honour { my ($t) = @_; return Game::Mahjong::Tiles::is_terminal($t) || Game::Mahjong::Tiles::is_honour($t) ? 1 : 0 }
sub _rank_in { my ($lo, $hi) = @_; return sub { my $r = Game::Mahjong::Tiles::rank_of($_[0]); defined $r && $r >= $lo && $r <= $hi } }

sub _f_big_four_winds { my ($v) = @_; my @w = _wind_pungs($v); return @w == 4 ? _one(@w) : () }
sub _f_big_three_dragons { my ($v) = @_; my @d = _dragon_pungs($v); return @d == 3 ? _one(@d) : () }
sub _f_all_green { my ($v) = @_; return _every($v, \&Game::Mahjong::Tiles::is_green) ? _one() : () }
sub _f_nine_gates {
	my ($v) = @_;
	return () unless _standard($v) && $v->{exposed} == 0 && !@{ $v->{kongs} } && $v->{nsuits} == 1 && !$v->{honours};
	my $win = $v->{ctx}{winning} or return ();
	my %c = %{ $v->{count} };
	return () unless $c{$win};
	$c{$win}--;
	my $suit = $v->{suits}[0];
	for my $r (1 .. 9) {
		my $k = Game::Mahjong::Tiles::id_of($suit . $r);
		my $want = ($r == 1 || $r == 9) ? 3 : 1;
		return () unless ($c{$k} || 0) == $want;
	}
	return _one();
}
sub _f_four_kongs { my ($v) = @_; return @{ $v->{kongs} } == 4 ? _one(@{ $v->{kongs} }) : () }
sub _f_seven_shifted_pairs {
	my ($v) = @_;
	return () unless $v->{form} eq 'seven_pairs';
	my @k = sort { $a <=> $b } @{ $v->{split}{singles} };
	my $suit = Game::Mahjong::Tiles::suit_of($k[0]);
	return () unless defined $suit;
	for my $i (0 .. 6) {
		return () unless (Game::Mahjong::Tiles::suit_of($k[$i]) // '') eq $suit;
		return () if $i && $k[$i] != $k[$i - 1] + 1;
	}
	return _one();
}
sub _f_thirteen_orphans { my ($v) = @_; return $v->{form} eq 'thirteen_orphans' ? _one() : () }
sub _f_all_terminals { my ($v) = @_; return _every($v, \&Game::Mahjong::Tiles::is_terminal) ? _one() : () }
sub _f_little_four_winds {
	my ($v) = @_;
	my @w = _wind_pungs($v);
	return () unless @w == 3 && $v->{pair} && Game::Mahjong::Tiles::is_wind($v->{pair});
	return (grep { $_->{tile} == $v->{pair} } @w) ? () : _one(@w);
}
sub _f_little_three_dragons {
	my ($v) = @_;
	my @d = _dragon_pungs($v);
	return () unless @d == 2 && $v->{pair} && Game::Mahjong::Tiles::is_dragon($v->{pair});
	return (grep { $_->{tile} == $v->{pair} } @d) ? () : _one(@d);
}
sub _f_all_honours { my ($v) = @_; return _every($v, \&Game::Mahjong::Tiles::is_honour) ? _one() : () }
sub _f_four_concealed_pungs { my ($v) = @_; my @c = @{ $v->{concealed_pungs} }; return @c == 4 ? _one(@c) : () }
sub _f_pure_terminal_chows {
	my ($v) = @_;
	my @c = @{ $v->{chows} };
	return () unless _standard($v) && @c == 4 && _same_suit(@c) && _bases_are('1,1,7,7', @c);
	return () unless $v->{pair} && (Game::Mahjong::Tiles::suit_of($v->{pair}) // '') eq $c[0]{suit} && Game::Mahjong::Tiles::rank_of($v->{pair}) == 5;
	return _one(@c);
}
sub _f_quadruple_chow { my ($v) = @_; my @c = @{ $v->{chows} }; return @c == 4 && _same_suit(@c) && _bases_shifted(0, @c) ? _one(@c) : () }
sub _f_four_pure_shifted_pungs { my ($v) = @_; my @p = grep { defined $_->{suit} } @{ $v->{pungs} }; return @p == 4 && _same_suit(@p) && _bases_shifted(1, @p) ? _one(@p) : () }
sub _f_four_pure_shifted_chows { my ($v) = @_; my @c = @{ $v->{chows} }; return @c == 4 && _same_suit(@c) && (_bases_shifted(1, @c) || _bases_shifted(2, @c)) ? _one(@c) : () }
sub _f_three_kongs { my ($v) = @_; return @{ $v->{kongs} } == 3 ? _one(@{ $v->{kongs} }) : () }
sub _f_all_terminals_and_honours { my ($v) = @_; return _every($v, \&_is_terminal_or_honour) && $v->{form} ne 'thirteen_orphans' ? _one() : () }
sub _f_seven_pairs { my ($v) = @_; return $v->{form} eq 'seven_pairs' ? _one() : () }
sub _f_greater_honours_and_knitted_tiles { my ($v) = @_; return $v->{form} eq 'honours_knitted' && $v->{honours} == 7 ? _one() : () }
sub _f_all_even_pungs {
	my ($v) = @_;
	return () unless _standard($v) && @{ $v->{pungs} } == 4;
	my $even = sub { my $r = Game::Mahjong::Tiles::rank_of($_[0]); defined $r && $r % 2 == 0 };
	return _every($v, $even) ? _one(@{ $v->{pungs} }) : ();
}
sub _f_full_flush { my ($v) = @_; return $v->{nsuits} == 1 && !$v->{honours} ? _one() : () }
sub _f_pure_triple_chow { my ($v) = @_; return map { _one(@$_) } grep { _same_suit(@$_) && _bases_shifted(0, @$_) } _triples_of($v->{chows}) }
sub _f_pure_shifted_pungs { my ($v) = @_; my @p = grep { defined $_->{suit} } @{ $v->{pungs} }; return map { _one(@$_) } grep { _same_suit(@$_) && _bases_shifted(1, @$_) } _triples_of(\@p) }
sub _f_upper_tiles { my ($v) = @_; return _every($v, _rank_in(7, 9)) ? _one() : () }
sub _f_middle_tiles { my ($v) = @_; return _every($v, _rank_in(4, 6)) ? _one() : () }
sub _f_lower_tiles { my ($v) = @_; return _every($v, _rank_in(1, 3)) ? _one() : () }
sub _f_pure_straight { my ($v) = @_; return map { _one(@$_) } grep { _same_suit(@$_) && _bases_are('1,4,7', @$_) } _triples_of($v->{chows}) }
sub _f_three_suited_terminal_chows {
	my ($v) = @_;
	my @c = @{ $v->{chows} };
	return () unless _standard($v) && @c == 4 && $v->{pair};
	my %by;
	push @{ $by{ $_->{suit} } }, $_->{base} for @c;
	my @s = keys %by;
	return () unless @s == 2;
	for my $suit (@s) { return () unless join(',', sort { $a <=> $b } @{ $by{$suit} }) eq '1,7' }
	my $ps = Game::Mahjong::Tiles::suit_of($v->{pair}) // return ();
	return () if $by{$ps};
	return Game::Mahjong::Tiles::rank_of($v->{pair}) == 5 ? _one(@c) : ();
}
sub _f_pure_shifted_chows { my ($v) = @_; return map { _one(@$_) } grep { _same_suit(@$_) && (_bases_shifted(1, @$_) || _bases_shifted(2, @$_)) } _triples_of($v->{chows}) }
sub _f_all_fives {
	my ($v) = @_;
	return () unless _standard($v);
	for my $e (@{ $v->{elements} }) {
		return () if $e->{kind} eq 'knit';
		return () unless defined $e->{base};
		my $has5 = $e->{kind} eq 'chow' ? ($e->{base} >= 3 && $e->{base} <= 5) : $e->{base} == 5;
		return () unless $has5;
	}
	return _one(@{ $v->{sets} });
}
sub _f_triple_pung { my ($v) = @_; my @p = grep { defined $_->{suit} } @{ $v->{pungs} }; return map { _one(@$_) } grep { _three_suits(@$_) && _bases_shifted(0, @$_) } _triples_of(\@p) }
sub _f_three_concealed_pungs { my ($v) = @_; my @c = @{ $v->{concealed_pungs} }; return @c == 3 ? _one(@c) : () }
sub _f_lesser_honours_and_knitted_tiles { my ($v) = @_; return $v->{form} eq 'honours_knitted' ? _one() : () }
sub _f_knitted_straight { my ($v) = @_; return $v->{form} eq 'knitted_straight' ? _one(@{ $v->{knits} }) : () }
sub _f_upper_four { my ($v) = @_; return _every($v, _rank_in(6, 9)) ? _one() : () }
sub _f_lower_four { my ($v) = @_; return _every($v, _rank_in(1, 4)) ? _one() : () }
sub _f_big_three_winds { my ($v) = @_; my @w = _wind_pungs($v); return @w == 3 ? _one(@w) : () }
sub _f_mixed_straight { my ($v) = @_; return map { _one(@$_) } grep { _three_suits(@$_) && _bases_are('1,4,7', @$_) } _triples_of($v->{chows}) }
sub _f_reversible_tiles { my ($v) = @_; return _every($v, \&Game::Mahjong::Tiles::is_reversible) ? _one() : () }
sub _f_mixed_triple_chow { my ($v) = @_; return map { _one(@$_) } grep { _three_suits(@$_) && _bases_shifted(0, @$_) } _triples_of($v->{chows}) }
sub _f_mixed_shifted_pungs { my ($v) = @_; my @p = grep { defined $_->{suit} } @{ $v->{pungs} }; return map { _one(@$_) } grep { _three_suits(@$_) && _bases_shifted(1, @$_) } _triples_of(\@p) }
sub _f_chicken_hand { return () }
sub _f_last_tile_draw { my ($v) = @_; return ($v->{ctx}{by} // '') eq 'self' && $v->{ctx}{last_of_wall} ? _one() : () }
sub _f_last_tile_claim { my ($v) = @_; return ($v->{ctx}{by} // '') eq 'discard' && $v->{ctx}{last_of_wall} ? _one() : () }
sub _f_out_with_replacement_tile { my ($v) = @_; return ($v->{ctx}{replacement} // '') eq 'kong' ? _one() : () }
sub _f_robbing_the_kong { my ($v) = @_; return ($v->{ctx}{by} // '') eq 'rob' ? _one() : () }
sub _f_two_concealed_kongs { my ($v) = @_; my @c = grep { $_->{concealed} } @{ $v->{kongs} }; return @c >= 2 ? _one(@c[0, 1]) : () }
sub _f_all_pungs { my ($v) = @_; return _standard($v) && @{ $v->{pungs} } == 4 ? _one(@{ $v->{pungs} }) : () }
sub _f_half_flush { my ($v) = @_; return $v->{nsuits} == 1 && $v->{honours} ? _one() : () }
sub _f_mixed_shifted_chows { my ($v) = @_; return map { _one(@$_) } grep { _three_suits(@$_) && _bases_shifted(1, @$_) } _triples_of($v->{chows}) }
sub _f_all_types {
	my ($v) = @_;
	return () unless $v->{form} eq 'standard' || $v->{form} eq 'seven_pairs';
	my %type;
	for my $e (@{ $v->{elements} }) {
		return () if $e->{kind} eq 'knit';
		my $t = $e->{suit} // (Game::Mahjong::Tiles::is_wind($e->{tile}) ? 'wind' : 'dragon');
		$type{$t}++;
	}
	return () unless keys %type == 5;
	return () if $v->{form} eq 'standard' && grep { $_ != 1 } values %type;
	return _one(@{ $v->{sets} });
}
sub _f_melded_hand {
	my ($v) = @_;
	return () unless _standard($v) && $v->{exposed} == 4 && ($v->{ctx}{by} // '') ne 'self' && ($v->{place_in} // '') eq 'pair';
	return _one(@{ $v->{sets} });
}
sub _f_two_dragon_pungs { my ($v) = @_; my @d = _dragon_pungs($v); return @d == 2 ? _one(@d) : () }
sub _f_outside_hand {
	my ($v) = @_;
	return () unless $v->{form} eq 'standard' || $v->{form} eq 'seven_pairs';
	for my $e (@{ $v->{elements} }) {
		return () if $e->{kind} eq 'knit';
		return () unless grep { _is_terminal_or_honour($_) } @{ $e->{tiles} };
	}
	return _one(@{ $v->{sets} });
}
sub _f_fully_concealed_hand { my ($v) = @_; return $v->{exposed} == 0 && ($v->{ctx}{by} // '') eq 'self' ? _one() : () }
sub _f_two_melded_kongs {
	my ($v) = @_;
	my @m = grep { !$_->{concealed} } @{ $v->{kongs} };
	my @c = grep { $_->{concealed} } @{ $v->{kongs} };
	return _one(@m[0, 1]) if @m >= 2;
	return ({ sets => [ $m[0]{i}, $c[0]{i} ], points => 6 }) if @m == 1 && @c == 1 && @{ $v->{kongs} } == 2;
	return ();
}
sub _f_last_tile { my ($v) = @_; return $v->{ctx}{last_tile} ? _one() : () }
sub _f_dragon_pung { my ($v) = @_; return map { _one($_) } _dragon_pungs($v) }
sub _f_prevalent_wind { my ($v) = @_; my $w = _wind_of($v, 'prevailing'); return map { _one($_) } grep { $_->{tile} == $w } @{ $v->{pungs} } }
sub _f_seat_wind { my ($v) = @_; my $w = _wind_of($v, 'seat'); return map { _one($_) } grep { $_->{tile} == $w } @{ $v->{pungs} } }
sub _f_concealed_hand { my ($v) = @_; return $v->{exposed} == 0 && ($v->{ctx}{by} // '') ne 'self' && defined $v->{ctx}{by} ? _one() : () }
sub _f_all_chows { my ($v) = @_; return _standard($v) && @{ $v->{chows} } == 4 && !$v->{honours} ? _one(@{ $v->{chows} }) : () }
sub _f_tile_hog {
	my ($v) = @_;
	my %konged = map { $_->{tile} => 1 } @{ $v->{kongs} };
	my @hogs = grep { $v->{count}{$_} == 4 && !$konged{$_} && Game::Mahjong::Tiles::is_suit($_) } sort { $a <=> $b } keys %{ $v->{count} };
	return map { ({ sets => [], kind => $_ }) } @hogs;
}
sub _f_double_pung { my ($v) = @_; my @p = grep { defined $_->{suit} } @{ $v->{pungs} }; return map { _one(@$_) } grep { $_->[0]{suit} ne $_->[1]{suit} && $_->[0]{base} == $_->[1]{base} } _pairs_of(\@p) }
sub _f_two_concealed_pungs { my ($v) = @_; my @c = @{ $v->{concealed_pungs} }; return @c == 2 ? _one(@c) : () }
sub _f_concealed_kong { my ($v) = @_; return map { _one($_) } grep { $_->{concealed} } @{ $v->{kongs} } }
sub _f_all_simples { my ($v) = @_; return _every($v, \&Game::Mahjong::Tiles::is_simple) ? _one() : () }
sub _f_pure_double_chow { my ($v) = @_; return map { _one(@$_) } grep { _same_suit(@$_) && $_->[0]{base} == $_->[1]{base} } _pairs_of($v->{chows}) }
sub _f_mixed_double_chow { my ($v) = @_; return map { _one(@$_) } grep { $_->[0]{suit} ne $_->[1]{suit} && $_->[0]{base} == $_->[1]{base} } _pairs_of($v->{chows}) }
sub _f_short_straight { my ($v) = @_; return map { _one(@$_) } grep { _same_suit(@$_) && abs($_->[0]{base} - $_->[1]{base}) == 3 } _pairs_of($v->{chows}) }
sub _f_two_terminal_chows { my ($v) = @_; return map { _one(@$_) } grep { _same_suit(@$_) && _bases_are('1,7', @$_) } _pairs_of($v->{chows}) }
sub _f_pung_of_terminals_or_honours {
	my ($v) = @_;
	my ($prev, $seat) = (_wind_of($v, 'prevailing'), _wind_of($v, 'seat'));
	return map { _one($_) } grep {
		my $t = $_->{tile};
		(Game::Mahjong::Tiles::is_terminal($t) || Game::Mahjong::Tiles::is_wind($t)) && $t != $prev && $t != $seat
	} @{ $v->{pungs} };
}
sub _f_melded_kong { my ($v) = @_; return map { _one($_) } grep { !$_->{concealed} } @{ $v->{kongs} } }
sub _f_one_voided_suit { my ($v) = @_; return $v->{nsuits} == 2 ? _one() : () }
sub _f_no_honours { my ($v) = @_; return !$v->{honours} && @{ $v->{tiles} } ? _one() : () }
sub _f_edge_wait { my ($v) = @_; return ($v->{wait} // '') eq 'edge' && $v->{nwaits} == 1 ? _one() : () }
sub _f_closed_wait { my ($v) = @_; return ($v->{wait} // '') eq 'closed' && $v->{nwaits} == 1 ? _one() : () }
sub _f_single_wait { my ($v) = @_; my $w = $v->{wait} // ''; return ($w eq 'pair' || $w eq 'single') && $v->{nwaits} == 1 ? _one() : () }
sub _f_self_drawn { my ($v) = @_; return ($v->{ctx}{by} // '') eq 'self' ? _one() : () }
sub _f_flower_tiles { my ($v) = @_; my $n = $v->{ctx}{flowers} || 0; return map { _one() } 1 .. $n }

my @ROWS = (
	[ 1, 'big_four_winds', 'Big Four Winds', 88,
		'The hand includes Pungs (or Kongs) of all four Wind Tiles. Does not combine with Big Three Winds, All Pungs, Prevalent Wind, Seat Wind, or Pung of Terminals or Honors.',
		[qw(big_three_winds all_pungs prevalent_wind seat_wind pung_of_terminals_or_honours)], [qw(little_four_winds)] ],
	[ 2, 'big_three_dragons', 'Big Three Dragons', 88,
		'The hand includes Pungs (or Kong) of all three Dragon tiles. Does not combine with Two Dragons or Dragon Pung.',
		[qw(two_dragon_pungs dragon_pung)], [qw(little_three_dragons)] ],
	[ 3, 'all_green', 'All Green', 88,
		'Hand is composed entirely of any of the 2, 3, 4, 6, 8 of Bamboo and Green Dragon. Combines with Full Flush and Half Flush.',
		[], [] ],
	[ 4, 'nine_gates', 'Nine Gates', 88,
		'Holding the 1,1,1,2,3,4,5,6,7,8,9,9,9 tiles in one suit, creating the nine-sided wait of 1, 2, 3, 4, 5, 6, 7, 8, 9. Does not combine with Full Flush, Concealed hand, and Pung of Terminals or Honors.',
		[qw(full_flush concealed_hand pung_of_terminals_or_honours)], [qw(no_honours one_voided_suit)] ],
	[ 5, 'four_kongs', 'Four Kongs', 88,
		'A hand that includes four Kongs. Points for concealed pungs may be added. Does not combine with Single Wait.',
		[qw(single_wait)], [qw(all_pungs three_kongs two_concealed_kongs two_melded_kongs concealed_kong melded_kong)] ],
	[ 6, 'seven_shifted_pairs', 'Seven Shifted Pairs', 88,
		'Hand is composed of seven pairs in the same suit, each shifted one up from the last. Does not combine with Full Flush, Concealed hand, or Single Wait.',
		[qw(full_flush concealed_hand single_wait)], [qw(seven_pairs no_honours one_voided_suit)] ],
	[ 7, 'thirteen_orphans', 'Thirteen Orphans', 88,
		'Hand is composed of singles of any 12 of the 1, 9, and Honor tiles, along with a pair of the 13th. Does not combine with All Types, Concealed Hand, or Single Wait.',
		[qw(all_types concealed_hand single_wait)], [qw(all_terminals_and_honours outside_hand)] ],
	[ 8, 'all_terminals', 'All Terminals', 64,
		'The pair(s), Pungs or Kongs are all made up of 1 or 9 Number Tiles, without Honor Tiles. Does not combine with All Pungs, Outside Hand, Pung of Terminals or Honors or No Honors. Can combine with Double Pung or Triple Pung.',
		[qw(all_pungs outside_hand pung_of_terminals_or_honours no_honours)], [qw(all_terminals_and_honours)] ],
	[ 9, 'little_four_winds', 'Little Four Winds', 64,
		'Hand includes three Pungs of Winds, and a pair of the fourth Wind. Combines with Prevalent Wind and Seat Wind, but does not combine with Big Three Winds, or Pung of Terminals or Honors.',
		[qw(big_three_winds pung_of_terminals_or_honours)], [] ],
	[ 10, 'little_three_dragons', 'Little Three Dragons', 64,
		'Hand includes Pungs of two Dragons and a pair of the third Dragon. Does not combine with Dragon Pung, or Two Dragons.',
		[qw(dragon_pung two_dragon_pungs)], [] ],
	[ 11, 'all_honours', 'All Honors', 64,
		'The pair(s), Pungs or Kongs are all made up of Honor Tiles. Can be formed with Pungs or Kongs, any of which may be concealed or melded. Does not combine with All Pungs, Outside Hand, and Pung of Terminals or Honors.',
		[qw(all_pungs outside_hand pung_of_terminals_or_honours)], [qw(all_terminals_and_honours)] ],
	[ 12, 'four_concealed_pungs', 'Four Concealed Pungs', 64,
		'Hand includes four Pungs achieved without melding. Does not combine with All Pungs or Concealed. Does combine with Fully Concealed if Self-Drawn.',
		[qw(all_pungs concealed_hand)], [qw(three_concealed_pungs two_concealed_pungs)] ],
	[ 13, 'pure_terminal_chows', 'Pure Terminal Chows', 64,
		'Hand consists of two each of the lower and upper terminal Chows in one suit, with a pair of fives in the same suit. Does not combine with Seven Pairs, Full Flush, All Chows, Pure Double Chow, or Two Terminal Chows.',
		[qw(seven_pairs full_flush all_chows pure_double_chow two_terminal_chows)], [qw(no_honours one_voided_suit)] ],
	[ 14, 'quadruple_chow', 'Quadruple Chow', 48,
		'Four chows of the same numerical sequences in the same suit. Does not combine with Pure Shifted Pungs, Tile Hog, or Pure Double Chow.',
		[qw(pure_shifted_pungs tile_hog pure_double_chow)], [qw(pure_triple_chow)] ],
	[ 15, 'four_pure_shifted_pungs', 'Four Pure Shifted Pungs', 48,
		'Four Pungs or Kongs in the same suit, each shifted up one from the last. Does not combine with Pure Triple Chow or All Pungs.',
		[qw(pure_triple_chow all_pungs)], [qw(pure_shifted_pungs)] ],
	[ 16, 'four_pure_shifted_chows', 'Four Pure Shifted Chows', 32,
		'Four chows in one suit, each shifted up 1 or 2 numbers from the last, but not a combination of both. Does not combine with Short Straight.',
		[qw(short_straight)], [qw(pure_shifted_chows)] ],
	[ 17, 'three_kongs', 'Three Kongs', 32,
		'Hand contains three Kongs. May combine with Three Concealed Pengs if the Kongs are all concealed.',
		[], [qw(two_melded_kongs two_concealed_kongs concealed_kong melded_kong)] ],
	[ 18, 'all_terminals_and_honours', 'All Terminals and Honors', 32,
		'The pair(s), Pungs or Kongs are all made up of 1 or 9 Number Tiles and Honor Tiles. Does not combine with All Pungs or Pung of Terminals or Honors.',
		[qw(all_pungs pung_of_terminals_or_honours)], [qw(outside_hand)] ],
	[ 19, 'seven_pairs', 'Seven Pairs', 24,
		'Hand consisting of seven pairs. Does not combine with Concealed Hand or Single Wait. May combine with Fully Concealed if Self-Drawn.',
		[qw(concealed_hand single_wait)], [] ],
	[ 20, 'greater_honours_and_knitted_tiles', 'Greater Honors and Knitted Tiles', 24,
		'Formed by 7 single Honors (one of every Wind and Dragon), and singles of suit tiles belonging to separate Knitted sequences (for example, 1-4-7 of Bamboos, 2-5-8 of Characters, and 3-6-9 of Dots). Does not combine with All Types or Concealed Hand. May be combined with Fully Concealed if Self-Drawn.',
		[qw(all_types concealed_hand)], [qw(lesser_honours_and_knitted_tiles)] ],
	[ 21, 'all_even_pungs', 'All Even Pungs', 24,
		'A hand formed with Pungs of even-numbered suit tiles, and a pair of the same. Does not combine with All Pungs or All Simples.',
		[qw(all_pungs all_simples)], [qw(no_honours)] ],
	[ 22, 'full_flush', 'Full Flush', 24,
		'All the tiles are in the same suit. Does not combine with No Honors.',
		[qw(no_honours)], [qw(one_voided_suit)] ],
	[ 23, 'pure_triple_chow', 'Pure Triple Chow', 24,
		'Three chows of the same numerical sequence and in the same suit. Does not combine with Pure Shifted Pungs or Pure Double Chow.',
		[qw(pure_shifted_pungs pure_double_chow)], [] ],
	[ 24, 'pure_shifted_pungs', 'Pure Shifted Pungs', 24,
		'Three Pungs or Kongs of the same suit, each shifted one up from the last. Does not combine with Pure Triple Chow.',
		[qw(pure_triple_chow)], [] ],
	[ 25, 'upper_tiles', 'Upper Tiles', 24,
		'Hand consisting entirely of 7, 8, and 9 tiles. Does not combine with No Honors.',
		[qw(no_honours)], [qw(upper_four)] ],
	[ 26, 'middle_tiles', 'Middle Tiles', 24,
		'A hand consisting entirely of 4, 5, and 6 tiles. Does not combine with No Honors or All Simples.',
		[qw(no_honours all_simples)], [] ],
	[ 27, 'lower_tiles', 'Lower Tiles', 24,
		'A hand consisting entirely of 1, 2, and 3 tiles. Does not combine with No Honors.',
		[qw(no_honours)], [qw(lower_four)] ],
	[ 28, 'pure_straight', 'Pure Straight', 16,
		'Hand using one of every number, 1-9, in three consecutive chows, in the same suit.',
		[], [] ],
	[ 29, 'three_suited_terminal_chows', 'Three-Suited Terminal Chows', 16,
		"Hand consisting of 1-2-3 + 7-8-9 in one suit (Two Terminal Chows), 1-2-3 + 7-8-9 in another suit, a pair of fives in the third suit. Doesn't combine with Pure Double Chow, Two Terminal Chows, No Honors, or All Chows.",
		[qw(pure_double_chow two_terminal_chows no_honours all_chows)], [qw(mixed_double_chow)] ],
	[ 30, 'pure_shifted_chows', 'Pure Shifted Chows', 16,
		'Three chows in one suit, each shifted up either one or two numbers from the last, but not a combination of both.',
		[], [] ],
	[ 31, 'all_fives', 'All Fives', 16,
		'A hand in which every element includes a 5 tile. Does not combine with All Simples.',
		[qw(all_simples)], [qw(no_honours)] ],
	[ 32, 'triple_pung', 'Triple Pung', 16,
		'Three Pungs of the same number, in each suit.',
		[], [qw(double_pung)] ],
	[ 33, 'three_concealed_pungs', 'Three Concealed Pungs', 16,
		'Three Pungs achieved without melding.',
		[], [qw(two_concealed_pungs)] ],
	[ 34, 'lesser_honours_and_knitted_tiles', 'Lesser Honors and Knitted Tiles', 12,
		'A hand made of singles of the following tiles: Any Honors, along with Suit tiles that belong to different Knitted sequences (for example, 1-4-7 of Characters, 2-5-8 of Bamboos, and 3-6-9 of Dots - each of the 3 suits must belong to a different Knitted sequence, but not necessarily in the order listed here). Does not Combines with All Types and Concealed Hand. (Combines with Fully Concealed if Self-Drawn.)',
		[qw(all_types concealed_hand)], [] ],
	[ 35, 'knitted_straight', 'Knitted Straight', 12,
		'A special Straight which is formed not with standard Chows but with 3 different Knitted sequences. For example, 1-4-7 of Dots, 2-5-8 of Characters, and 3-6-9 of Bamboos - but not necessarily in this order.',
		[], [] ],
	[ 36, 'upper_four', 'Upper Four', 12,
		'A hand created solely with suit tiles 6 through 9. Does not combine with No Honors.',
		[qw(no_honours)], [] ],
	[ 37, 'lower_four', 'Lower Four', 12,
		'A hand created with suit tiles 1 through 4 only. Does not combine with No Honors.',
		[qw(no_honours)], [] ],
	[ 38, 'big_three_winds', 'Big Three Winds', 12,
		'Hand includes Pungs or Kongs of three of the Winds.',
		[], [] ],
	[ 39, 'mixed_straight', 'Mixed Straight', 8,
		'Three chows in three suits making 9 continuous numbers (1-9).',
		[], [] ],
	[ 40, 'reversible_tiles', 'Reversible Tiles', 8,
		'A hand created entirely with those tiles which are vertically symmetrical (1,2,3,4,5,8,9 Dots - 2,4,5,6,8,9 Bams , and White Dragon). Does not combine with One Voided Suit.',
		[qw(one_voided_suit)], [] ],
	[ 41, 'mixed_triple_chow', 'Mixed Triple Chow', 8,
		'Three chows of the same numerical sequence, one in each suit.',
		[], [qw(mixed_double_chow)] ],
	[ 42, 'mixed_shifted_pungs', 'Mixed Shifted Pungs', 8,
		'Three Pungs or Kongs, one in each suit, each shifted up one number from the last.',
		[], [] ],
	[ 43, 'chicken_hand', 'Chicken Hand', 8,
		'A hand that would otherwise earn 0 points (excluding Flowers).',
		[], [], 'chicken' ],
	[ 44, 'last_tile_draw', 'Last Tile Draw', 8,
		'Going out (making mahjong) on a pick of the very last tile of the wall. (Points for Self-Drawn may not be combined.)',
		[qw(self_drawn)], [] ],
	[ 45, 'last_tile_claim', 'Last Tile Claim', 8,
		'The last tile (of the game) discarded by another player.',
		[], [] ],
	[ 46, 'out_with_replacement_tile', 'Out with Replacement Tile', 8,
		'Going out (making mahjong) on the replacement tile drawn after achieving a kong (not on a Flower replacement).',
		[], [] ],
	[ 47, 'robbing_the_kong', 'Robbing The Kong', 8,
		'Winning off the tile that somebody adds to a melded pung (to create a Kong). (The points for Last Tile may not be combined.)',
		[qw(last_tile)], [] ],
	[ 48, 'two_concealed_kongs', 'Two Concealed Kongs', 8,
		'Hand includes two Concealed Kongs.',
		[], [qw(concealed_kong two_concealed_pungs)] ],
	[ 49, 'all_pungs', 'All Pungs', 6,
		'Hand includes four Pungs or Kongs and a pair.',
		[], [] ],
	[ 50, 'half_flush', 'Half Flush', 6,
		'Formed by tiles from any one of the three suits, in combination with Honors.',
		[], [] ],
	[ 51, 'mixed_shifted_chows', 'Mixed Shifted Chows', 6,
		'Three chows one in each suit, each shifted up one number from the last.',
		[], [] ],
	[ 52, 'all_types', 'All Types', 6,
		'A hand in which each of the five sets is composed of a different type of tile (Characters, Bamboos, Dots, Winds, and Dragons).',
		[], [] ],
	[ 53, 'melded_hand', 'Melded Hand', 6,
		'Every element or set in the hand, including the pair, must be completed with tiles discarded by other players. Does not combine with Single Wait.',
		[qw(single_wait)], [] ],
	[ 54, 'two_dragon_pungs', 'Two Dragons Pungs', 6,
		'Two Pungs (or Kongs) of Dragon tiles.',
		[], [qw(dragon_pung)] ],
	[ 55, 'outside_hand', 'Outside Hand', 4,
		'Hand includes Terminals and Honors in each element or set, including the Pair.',
		[], [] ],
	[ 56, 'fully_concealed_hand', 'Fully Concealed Hand', 4,
		'A hand that a player completes without any melds and Self-Draws to win.',
		[], [qw(self_drawn)] ],
	[ 57, 'two_melded_kongs', 'Two Melded Kongs', 4,
		'Hand includes two Melded Kongs. (A Melded Kong and a Concealed Kong make 6 points.)',
		[], [qw(melded_kong concealed_kong)] ],
	[ 58, 'last_tile', 'Last Tile', 4,
		'Winning on a tile that is the last of its kind. (It must be clear to all players based on the discards and exposures.)',
		[], [] ],
	[ 59, 'dragon_pung', 'Dragon Pung', 2,
		'A Pung or Kong of Dragon Tiles.',
		[], [] ],
	[ 60, 'prevalent_wind', 'Prevalent Wind', 2,
		'A Pung or Kong of the Wind Tile corresponding to the current Prevalent Wind.',
		[], [] ],
	[ 61, 'seat_wind', 'Seat Wind', 2,
		"A Pung or Kong of the Wind Tile corresponding to the player's Seat position at the table.",
		[], [] ],
	[ 62, 'concealed_hand', 'Concealed Hand', 2,
		'All the tiles are Concealed; winning on a discard.',
		[], [] ],
	[ 63, 'all_chows', 'All Chows', 2,
		'Hand consists of all Chows and no Honors. No Honors is implied.',
		[], [qw(no_honours)] ],
	[ 64, 'tile_hog', 'Tile Hog', 2,
		'Using all four of a single suit tile, without using them as any kind of Kong.',
		[], [] ],
	[ 65, 'double_pung', 'Double Pung', 2,
		'Two Pungs of the same number in two different suits.',
		[], [] ],
	[ 66, 'two_concealed_pungs', 'Two Concealed Pungs', 2,
		'Two Pungs which are achieved without melding.',
		[], [] ],
	[ 67, 'concealed_kong', 'Concealed Kong', 2,
		'Created when four identical tiles, all self-drawn, are declared as a Kong.',
		[], [] ],
	[ 68, 'all_simples', 'All Simples', 2,
		'Hand formed without any Terminal or Honor Tiles.',
		[], [qw(no_honours)] ],
	[ 69, 'pure_double_chow', 'Pure Double Chow', 1,
		'Two identical chows in the same suit.',
		[], [] ],
	[ 70, 'mixed_double_chow', 'Mixed Double Chow', 1,
		'Two chows of the same numbers but in different suits.',
		[], [] ],
	[ 71, 'short_straight', 'Short Straight', 1,
		'Two chows in the same suit that runs consecutively after one another to make a six-tile straight.',
		[], [] ],
	[ 72, 'two_terminal_chows', 'Two Terminal Chows', 1,
		'Chows of 1-2-3 and 7-8-9 in the same suit.',
		[], [] ],
	[ 73, 'pung_of_terminals_or_honours', 'Pung of Terminals or Honors', 1,
		'A Pung or Kong of Ones, Nines, or Winds. (A dragon pung scores 2 points.)',
		[], [] ],
	[ 74, 'melded_kong', 'Melded Kong', 1,
		'A kong that was claimed from another player or promoted from a melded pung.',
		[], [] ],
	[ 75, 'one_voided_suit', 'One Voided Suit', 1,
		'A hand that uses tiles from only two of the three suits (it lacks any tiles from one of the three suits).',
		[], [] ],
	[ 76, 'no_honours', 'No Honors', 1,
		'A hand formed entirely of suit tiles, without Winds or Dragons.',
		[], [] ],
	[ 77, 'edge_wait', 'Edge Wait', 1,
		'Waiting solely for a 3 to form a 1-2-3 chow, or solely for a 7 to form a 7-8-9 chow. Not valid if waiting for more than one tile. Not valid if the edge wait is combined with any other waits.',
		[], [] ],
	[ 78, 'closed_wait', 'Closed Wait', 1,
		'Waiting solely for a tile whose number is "inside" (in the middle) to form a chow. Not valid if waiting for more than one tile. Not valid if the closed wait is combined with other waits',
		[], [] ],
	[ 79, 'single_wait', 'Single Waiting', 1,
		'Waiting solely for a tile to form a pair. Not valid if waiting for more than one tile (for example, holding 1-2-3-4 and waiting on the 1 and 4).',
		[], [] ],
	[ 80, 'self_drawn', 'Self-Drawn', 1,
		'Going out (making mahjong) with a fresh tile picked from the wall.',
		[], [] ],
	[ 81, 'flower_tiles', 'Flower Tiles', 1,
		'Each tile carved with Chinese word for Spring, Summer, Autumn, Winter, Plum, Orchid, Bamboo or Chrysanthemum, will award you one point when you succeed in Hu.',
		[], [] ],
);

my %COMBINING = map { $_ => 1 } qw(
	pure_double_chow mixed_double_chow short_straight two_terminal_chows double_pung
	pure_triple_chow mixed_triple_chow pure_straight mixed_straight
	pure_shifted_chows mixed_shifted_chows pure_shifted_pungs mixed_shifted_pungs triple_pung
	quadruple_chow four_pure_shifted_chows four_pure_shifted_pungs
	pure_terminal_chows three_suited_terminal_chows
);

my %WHOLE = map { $_ => 1 } qw(
	all_pungs all_chows all_fives all_even_pungs all_types outside_hand
	melded_hand knitted_straight
);

my (@FANS, %BY_KEY, %BY_N);
for my $row (@ROWS) {
	my ($n, $key, $name, $points, $says, $excludes, $implies, $special) = @$row;
	my $check = __PACKAGE__->can("_f_$key") or die "Game::Mahjong::Fans: no checker for $key";
	my $fan = Game::Mahjong::Fan->new(
		n => $n, key => $key, name => $name, points => $points, says => $says,
		excludes => $excludes, implies => $implies, check => $check,
		combining => $COMBINING{$key} ? 1 : 0,
		whole     => $WHOLE{$key} ? 1 : 0,
		(defined $special ? (special => $special) : ()),
	);
	push @FANS, $fan;
	$BY_KEY{$key} = $fan;
	$BY_N{$n} = $fan;
}

sub all { return @FANS }

sub by_key {
	my ($key) = @_;
	return $BY_KEY{$key} || die "Game::Mahjong::Fans: no fan '" . (defined $key ? $key : 'undef') . "'";
}

sub by_n {
	my ($n) = @_;
	return $BY_N{$n} || die "Game::Mahjong::Fans: no fan number " . (defined $n ? $n : 'undef');
}

sub keys_of { return map { $_->key } @FANS }

sub check_all {
	my ($split, $ctx) = @_;
	my $v = view($split, $ctx);
	my %found;
	for my $fan (@FANS) {
		next if $fan->special;
		my @i = $fan->instances($v);
		$found{ $fan->key } = \@i if @i;
	}
	return \%found;
}

1;

__END__

=head1 NAME

Game::Mahjong::Fans - the eighty-one scoring elements, as data with a checker each

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my @splits = Game::Mahjong::Decompose::decompose($hand, $winning);
    my $found  = Game::Mahjong::Fans::check_all($splits[0], {
        by => 'self', prevailing => 0, seat => 1, winning => $winning,
        waits => \@waits, flowers => 2,
    });
    # { mixed_triple_chow => [ { sets => [0, 1, 2] } ], self_drawn => [ {} ], ... }

    Game::Mahjong::Fans::by_key('all_pungs')->points;   # 6
    Game::Mahjong::Fans::COUNT;                          # 81

=head1 DESCRIPTION

The rulebook's 3.8.1 table and Appendix 1, one row per fan: the number, the
key, the name, the points, the rulebook's sentence, what the fan does not
combine with, what it inevitably implies, and a checker. The checkers find
instances; combining them under the five principles is
L<Game::Mahjong::Score>'s work.

=head2 The context

A checker that depends on how the hand was won reads a context hash:

    by            'self' | 'discard' | 'rob'
    prevailing    the prevalent wind, 0 east to 3 north
    seat          the seat wind, 0 to 3
    winning       the kind won on (Nine Gates reads it)
    waits         the kinds the thirteen were waiting on (the wait fans need one)
    last_of_wall  the winning tile was the last of the wall
    replacement   'kong' | 'flower' | undef, for a win on a replacement tile
    last_tile     the winning tile was the last of its kind visible to all
    flowers       how many bonus tiles the winner has exposed

=head2 Instances, not booleans

A checker returns every instance it finds, each naming the sets it used,
so a hand with two pungs of terminals scores the fan twice and the scorer
can apply account-once to the chow fans. A fan that names no set (a flush,
a wait, the self-draw) returns an instance with no sets.

=head2 Readings the rulebook's English forces

A pung of the prevalent or the seat wind scores its own fan and is not also
a Pung of Terminals or Honours; a dragon pung is never one (the sentence
says "Ones, Nines, or Winds"). A win on a flower replacement is self-drawn
and not Out with Replacement Tile. The two-kong fan is a ladder: two melded
4, one of each 6 (its own sentence), two concealed 8. Fan 16 is printed
"Four Shifted Chows" in Appendix 1 and "Four Pure Shifted Chows" in 3.8.1;
the table uses the latter. Chicken Hand has no checker: the scorer applies
it when nothing else scored.

=head1 FUNCTIONS

=head2 view

    my $v = view($split, $ctx);

The precomputed view of one split the checkers read: the sets with their
suit, base rank and exposure, the chows, pungs (kongs included), kongs and
knitted sequences, the pair, the elements (sets plus pair, or the seven
pairs), every tile with multiplicity, the counts, the suits, the honours,
the wait.

=head2 check_all

Every fan's instances for a split, keyed by fan key; fans with none are
absent.

=head2 all, by_key, by_n, keys_of

The rows.

=head2 COUNT, @GRADES, %PER_GRADE

81; the twelve grades; how many fans each grade holds in 3.8.1.

=head1 SEE ALSO

L<Game::Mahjong::Fan>, L<Game::Mahjong::Decompose>, L<Game::Mahjong::Score>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
