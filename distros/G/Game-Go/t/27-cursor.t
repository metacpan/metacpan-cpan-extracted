#!perl

use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Go;
use Game::Go::Terminal;

sub walk {
	my ($keys, %o) = @_;
	open my $in, '<', \(my $script = "resign\n") or die $!;
	my $text = '';
	open my $out, '>', \$text or die $!;
	my @chars = split //, $keys . 'q';

	my $t = Game::Go::Terminal->new(
		in => $in, out => $out, size => 9, level => 1, seed => 'cursor',
		ascii => 1, ansi => 0, picking => 1,
		keysource => sub { shift @chars },
		%o,
	);
	$t->enter_raw;
	$t->pick_point(Game::Go::BLACK);

	my @frames = grep { /\[/ } split /\n\n/, $text;
	my (@named, @drawn);
	for my $frame (@frames) {
		my @lines = split /\n/, $frame;
		my ($header) = grep { /\A\s+A B/ } @lines;
		my @letters = split ' ', $header;
		my ($row) = grep { /\A\s*\d+.*\[/ } @lines;
		my ($number, $body) = $row =~ /\A\s*(\d+)(.*?)\d+\z/;
		my $col = (index($body, '[')) / 2;
		push @drawn, $letters[$col] . $number;
		my ($caption) = $frame =~ /^  ([A-T]\d+):/m;
		push @named, $caption;
	}
	return (\@named, \@drawn);
}

my @letters = qw(A B C D E F G H J);

subtest 'right walks the columns in the order they are drawn, and goes round' => sub {
	my ($named, $drawn) = walk("\e[C" x 9);
	my @want = map { $letters[(4 + $_) % 9] . '5' } 0 .. 9;
	is_deeply($named, \@want, 'E5 to J5, then A5 round to E5');
	is_deeply($drawn, \@want, 'and the brackets are drawn on the point named');
	done_testing();
};

subtest 'left is the same walk backwards' => sub {
	my ($named, $drawn) = walk("\e[D" x 9);
	my @want = map { $letters[(4 - $_) % 9] . '5' } 0 .. 9;
	is_deeply($named, \@want, 'E5 to A5, then J5 round to E5');
	is_deeply($drawn, \@want, 'and the brackets are drawn on the point named');
	done_testing();
};

subtest 'down walks the rows in the order they are drawn, and goes round' => sub {
	my ($named, $drawn) = walk("\e[B" x 9);
	is_deeply($named, [qw(E5 E4 E3 E2 E1 E9 E8 E7 E6 E5)],
		'down the screen is down the numbers, then round to the top');
	is_deeply($drawn, $named, 'and the brackets are drawn on the point named');
	done_testing();
};

subtest 'up is the same walk backwards' => sub {
	my ($named, $drawn) = walk("\e[A" x 9);
	is_deeply($named, [qw(E5 E6 E7 E8 E9 E1 E2 E3 E4 E5)],
		'up the screen is up the numbers, then round to the bottom');
	is_deeply($drawn, $named, 'and the brackets are drawn on the point named');
	done_testing();
};

subtest 'home and end are the ends of the row the cursor is on' => sub {
	my ($named, $drawn) = walk("\e[B\e[H\e[F\e[1~\e[4~");
	is_deeply($named, [qw(E5 E4 A4 J4 A4 J4)], 'the row is kept');
	is_deeply($drawn, $named, 'and the brackets are drawn on the point named');
	done_testing();
};

done_testing();
