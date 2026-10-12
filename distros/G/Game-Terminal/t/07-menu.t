#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use Game::Terminal;
use Game::Terminal::Menu;

my @ALL = Game::Terminal::games();

sub menu {
	my ($keys, %option) = @_;
	my @chars = split //, defined $keys ? $keys : '';
	my $output = '';
	open my $out, '>', \$output or die "in memory handle: $!";
	my @ran;
	my $menu = Game::Terminal::Menu->new(
		out => $out,
		interactive => 0,
		colour => 0,
		keysource => sub { shift @chars },
		picking => 1,
		games => [ map { { %{$_}, installed => 1 } } @ALL ],
		runner => sub { my ($row, $argv, %seam) = @_; push @ran, [ $row->{key}, @{$argv} ]; return (0, undef) },
		%option
	);
	return ($menu, \$output, \@ran);
}

subtest 'two downs, enter, and enter on Play run the third game, and q leaves' => sub {
	plan tests => 4;
	my ($menu, $output, $ran) = menu("\e[B\e[B\r\rq");
	is $menu->start, 0, 'start returns 0';
	is_deeply $ran, [[ $ALL[2]{key} ]], 'the third row ran once';
	like ${$output}, qr/\Q$ALL[2]{key}\E finished with status 0 \(won or drew\)/, 'and its result was shown';
	like ${$output}, qr/up and down to choose/, 'with the legend on the screen';
};

subtest 'the status words' => sub {
	plan tests => 4;
	my ($menu) = menu('');
	my $row = $ALL[0];
	is $menu->describe($row, 1), "$row->{key} finished with status 1 (lost)", 'lost';
	is $menu->describe($row, 2), "$row->{key} finished with status 2 (bad option)", 'bad option';
	is $menu->describe($row, 7), "$row->{key} finished with status 7", 'an unknown status has no word';
	is $menu->describe($row, undef, 'no board'), "$row->{key} died: no board", 'a death';
};

subtest 'a letter jumps, and jumps again' => sub {
	plan tests => 3;
	my ($menu) = menu('');
	$menu->jump('x');
	is $menu->games->[$menu->at]{key}, 'xiangqi', 'x finds xiangqi';
	$menu->jump('s');
	is $menu->games->[$menu->at]{key}, 'schnapsen', 's finds schnapsen';
	$menu->jump('s');
	is $menu->games->[$menu->at]{key}, 'sixtysix', 'and s again finds sixtysix';
};

subtest 'the cursor skips what is not installed' => sub {
	plan tests => 4;
	my @games = map { { %{$_}, installed => $_->{key} eq 'brandubh' ? 0 : 1 } } @ALL;
	my ($menu, $output, $ran) = menu("\e[B\r\rq", games => \@games);
	is $menu->games->[$menu->at]{key}, 'backgammon', 'the cursor starts on the first installed row';
	$menu->move(1);
	is $menu->games->[$menu->at]{key}, 'checkers', 'one down skips brandubh';
	$menu->move(-1);
	$menu->start;
	is_deeply $ran, [['checkers']], 'so enter, enter after one down plays checkers';
	like ${$output}, qr/brandubh.*\(not installed\)/, 'and brandubh is marked';
};

subtest 'enter on an uninstalled row runs nothing' => sub {
	plan tests => 2;
	my @games = map { { %{$_}, installed => $_->{key} eq 'backgammon' ? 1 : 0 } } @ALL;
	my ($menu, $output, $ran) = menu("\rq", games => \@games);
	$menu->at(1);
	$menu->start;
	is_deeply $ran, [], 'nothing ran';
	like ${$output}, qr/brandubh is not installed: cpanm Game::Brandubh/, 'and the install line was shown';
};

subtest 'a runner that reports a loss, and one that dies' => sub {
	plan tests => 2;
	my ($lost, $out1) = menu("\r\rq", runner => sub { return (1, undef) });
	$lost->start;
	like ${$out1}, qr/finished with status 1 \(lost\)/, 'a loss';
	my ($died, $out2) = menu("\r\rq", runner => sub { return (undef, 'no board') });
	$died->start;
	like ${$out2}, qr/backgammon died: no board/, 'a death';
};

subtest 'the flags reach the runner in the game\'s words' => sub {
	plan tests => 2;
	my ($menu, undef, $ran) = menu("b\r\rq", common => { ascii => 1, pick => 0, colour => 0 });
	my %seam;
	$menu->runner(sub { my ($row, $argv, %s) = @_; push @{$ran}, [ $row->{key}, @{$argv} ]; %seam = %s; return (0, undef) });
	$menu->start;
	is_deeply $ran, [['brandubh', '--no-unicode', '--no-pick']], 'brandubh spells ascii as --no-unicode';
	is $seam{no_colour}, 1, 'and colour off is passed as no_colour';
};

subtest 'colour paints the cursor row and dims the missing' => sub {
	plan tests => 4;
	my @games = map { { %{$_}, installed => $_->{key} eq 'maze' ? 0 : 1 } } @ALL;
	my ($menu, $output) = menu('q', colour => 1, games => \@games);
	$menu->start;
	like ${$output}, qr/\e\[1;7m> backgammon/, 'the cursor row is reverse video';
	like ${$output}, qr/\e\[2m   maze .*\(not installed\)\e\[0m/, 'and the missing one is dim';
	like ${$output}, qr/\e\[1mbrandubh   \e\[0m \e\[38;5;75mboard \e\[0m/, 'a plain row has a bold name and a blue board family';
	like ${$output}, qr/\e\[1mGame\e\[0m/, 'and the title is bold';
};

subtest 'the status line takes a tone' => sub {
	plan tests => 3;
	my ($lost, $out1) = menu("\r\rq", colour => 1, runner => sub { return (1, undef) });
	$lost->start;
	like ${$out1}, qr/\e\[38;5;203mbackgammon finished with status 1 \(lost\)\e\[0m/, 'a loss is red';
	my ($won, $out2) = menu("\r\rq", colour => 1, runner => sub { return (0, undef) });
	$won->start;
	like ${$out2}, qr/\e\[38;5;114mbackgammon finished with status 0 \(won or drew\)\e\[0m/, 'a win is green';
	my ($bad, $out3) = menu("\r\rq", colour => 1, runner => sub { return (2, undef) });
	$bad->start;
	like ${$out3}, qr/\e\[38;5;220mbackgammon finished with status 2 \(bad option\)\e\[0m/, 'and a bad option is yellow';
};

subtest 'the windowed list' => sub {
	plan tests => 3;
	my ($menu) = menu('', rows => 15);
	my $lines = $menu->list_lines;
	is scalar @{$lines}, 7, 'fifteen rows leave six rows of list and a further-down line';
	like $lines->[-1], qr/further down/, 'the tail says how many are below';
	$menu->at($#ALL);
	like $menu->list_lines->[0], qr/further up/, 'and at the end the head says how many are above';
};

subtest 'the prompt, without keys' => sub {
	plan tests => 5;
	my @ran;
	my $output = '';
	open my $out, '>', \$output or die $!;
	open my $in, '<', \"3\n\nchekers\nCheckers\n\n\n" or die $!;
	my $menu = Game::Terminal::Menu->new(
		in => $in, out => $out, interactive => 0, colour => 0, picking => 0,
		games => [ map { { %{$_}, installed => 1 } } @ALL ],
		runner => sub { push @ran, $_[0]{key}; return (0, undef) },
	);
	is $menu->start, 0, 'a blank line leaves';
	is_deeply \@ran, ['checkers', 'checkers'], 'row 3 and the name both played checkers, each with a blank options line';
	like $output, qr/Which game\? \(number, name, or q\)/, 'the prompt was asked';
	like $output, qr/No game called 'chekers'\. Did you mean checkers\?/, 'a typo was corrected';
	unlike $output, qr/\e\[/, 'and nothing was an escape code';
};

done_testing;
