#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Merrills;
use Game::Merrills::Terminal;
use Game::Merrills::Test::Position qw/p position_of/;

sub terminal {
	my ($keys, %option) = @_;
	my @chars = split //, $keys;
	my $output = '';
	open my $out, '>', \$output or die "in memory handle: $!";
	open my $in, '<', \'' or die "in memory handle: $!";
	my $terminal = Game::Merrills::Terminal->new(
		in => $in,
		out => $out,
		interactive => 0,
		colour => 0,
		ascii => 1,
		human => 'both',
		keysource => sub { shift @chars },
		picking => 1,
		%option
	);
	return ($terminal, \$output);
}

sub visits {
	my ($keys, %option) = @_;
	my ($terminal, $output) = terminal($keys, %option);
	$terminal->enter_raw;
	$terminal->pick;
	my @visits;
	for my $frame (split /^(?=7 [ (\[{<])/m, ${$output}) {
		my @lines = split /\n/, $frame;
		my ($row) = grep { $lines[$_] =~ m/\[/ } 0 .. 12;
		my ($name) = $frame =~ m/^ > ([a-g][1-7])/m;
		next unless defined $row && defined $name;
		push @visits, { name => $name, row => $row, col => index $lines[$row], '[' };
	}
	return \@visits;
}

sub reading_order {
	my (@visits) = @_;
	return [ map { $_->{name} } sort { $a->{row} <=> $b->{row} || $a->{col} <=> $b->{col} } @visits ];
}

my %MILL = (white => [qw/a7 d7 g4 c3 e3/], black => [qw/a1 d1 g1 b4 e5/]);

subtest 'tab walks the points in the order they are drawn' => sub {
	my $visits = visits("\t" x 24);
	is(scalar @{$visits}, 25, 'twenty-five screens, each with the cursor on the board');
	my @round = @{$visits}[ 0 .. 23 ];
	is_deeply([ map { $_->{name} } @round ], reading_order(@round),
		'left to right along a row, then the row below');
	is($round[0]{row}, 0, 'beginning on the top row');
	is($round[-1]{row}, 12, 'and ending on the bottom one');
	is($visits->[24]{name}, $round[0]{name}, 'before going round to the first');
};

subtest 'shift-tab walks them backwards' => sub {
	my $visits = visits("\e[Z" x 24);
	my @round = @{$visits}[ 1 .. 24 ];
	is_deeply([ map { $_->{name} } @round ], [ reverse @{ reading_order(@round) } ],
		'right to left along a row, then the row above');
};

subtest 'and so at every step of a move' => sub {
	my $game = sub { Game::Merrills->new(position => position_of(%MILL)) };

	my $men = visits("\t" x 5, game => $game->());
	my @round = @{$men}[ 0 .. 4 ];
	is_deeply([ map { $_->{name} } @round ], reading_order(@round), 'the men that can move: ' . join ' ', map { $_->{name} } @round);
	is_deeply([ sort map { $_->{name} } @round ], [ sort @{ $MILL{white} } ], 'all five of them');

	my $taken = visits("g4\rg7\r\t\t", game => $game->());
	@round = @{$taken}[ -3, -2 ];
	is_deeply([ map { $_->{name} } @round ], reading_order(@round), 'the men that can be taken: ' . join ' ', map { $_->{name} } @round);
	is($taken->[-1]{name}, $round[0]{name}, 'and round again');
};

subtest 'an arrow moves the cursor the way it points on the screen' => sub {
	my %drawn = map { $_->{name} => $_ } @{ visits("\t" x 23) };
	is(scalar keys %drawn, 24, 'where each of the 24 points is drawn');
	my ($terminal) = terminal('');
	my @all = Game::Merrills::Points::all_points();
	my %toward = (
		up => sub { $_[1]{row} < $_[0]{row} },
		down => sub { $_[1]{row} > $_[0]{row} },
		left => sub { $_[1]{col} < $_[0]{col} },
		right => sub { $_[1]{col} > $_[0]{col} },
	);
	my ($moved, $astray) = (0, 0);
	for my $from (@all) {
		my $here = $drawn{ Game::Merrills::Points::name($from) };
		for my $direction (sort keys %toward) {
			my $to = $terminal->nearest($from, $direction, \@all);
			my $any = grep { $toward{$direction}->($here, $_) } values %drawn;
			if ($to == $from) {
				$astray++ if $any;
				next;
			}
			$moved++;
			$astray++ unless $toward{$direction}->($here, $drawn{ Game::Merrills::Points::name($to) });
		}
	}
	cmp_ok($moved, '>', 60, "$moved presses moved the cursor");
	is($astray, 0, 'each of them that way, and none stayed where there was somewhere to go');
};

done_testing;
