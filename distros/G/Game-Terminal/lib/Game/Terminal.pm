package Game::Terminal;

use 5.014;
use strict;
use warnings;

use Getopt::Long ();
use Text::ParseWords ();

our $VERSION = '0.01';

our @ROSTER;
my %BY_NAME;

BEGIN {
	my %ALL = (ascii => '--ascii', pick => '--no-pick');

	@ROSTER = (
		{
			key     => 'backgammon',
			module  => 'Game::Backgammon',
			class   => 'Game::Backgammon::Terminal',
			blurb   => 'backgammon',
			family  => 'board',
			players => '2',
			args    => [],
			aliases => [],
			flags   => { %ALL },
		},
		{
			key     => 'brandubh',
			module  => 'Game::Brandubh',
			class   => 'Game::Brandubh::Terminal',
			blurb   => 'the Irish 7 by 7 tafl game',
			family  => 'board',
			players => '2',
			args    => [],
			aliases => ['tafl'],
			flags   => { ascii => '--no-unicode', pick => '--no-pick' },
		},
		{
			key     => 'checkers',
			module  => 'Game::Checkers',
			class   => 'Game::Checkers::Terminal',
			blurb   => 'English draughts',
			family  => 'board',
			players => '2',
			args    => [],
			aliases => ['draughts'],
			flags   => { %ALL },
		},
		{
			key     => 'chess',
			module  => 'Term::Chess',
			class   => 'Term::Chess',
			blurb   => 'chess',
			family  => 'board',
			players => '2',
			args    => [],
			aliases => [],
			flags   => { %ALL },
		},
		{
			key     => 'cribbage',
			module  => 'Game::Cribbage',
			class   => 'Game::Cribbage::Terminal',
			blurb   => 'cribbage',
			family  => 'card',
			players => '2',
			args    => [],
			aliases => ['crib'],
			flags   => { pick => '--no-pick' },
		},
		{
			key     => 'dominoes',
			module  => 'Game::Dominoes',
			class   => 'Game::Dominoes::Terminal',
			blurb   => 'draw dominoes with All Fives scoring',
			family  => 'tile',
			players => '2-4',
			args    => [],
			aliases => [],
			flags   => { %ALL },
		},
		{
			key     => 'durak',
			module  => 'Game::Durak',
			class   => 'Game::Durak::Terminal',
			blurb   => 'Podkidnoy Durak, the Russian beating game',
			family  => 'card',
			players => '2',
			args    => [],
			aliases => [],
			flags   => { %ALL },
		},
		{
			key     => 'fanorona',
			module  => 'Game::Fanorona',
			class   => 'Game::Fanorona::Terminal',
			blurb   => 'the board game of Madagascar',
			family  => 'board',
			players => '2',
			args    => [],
			aliases => [],
			flags   => { ascii => '--no-unicode', pick => '--no-pick' },
		},
		{
			key     => 'floppy',
			module  => 'Game::Floppy',
			class   => 'Game::Floppy::Terminal',
			blurb   => 'a one-button bird through a field of tubes',
			family  => 'arcade',
			players => '1',
			args    => [],
			aliases => ['flappy'],
			flags   => { ascii => '--ascii' },
		},
		{
			key     => 'gin',
			module  => 'Game::Gin',
			class   => 'Game::Gin::Terminal',
			blurb   => 'gin rummy',
			family  => 'card',
			players => '2',
			args    => [],
			aliases => ['rummy'],
			flags   => { %ALL },
		},
		{
			key     => 'go',
			module  => 'Game::Go',
			class   => 'Game::Go::Terminal',
			blurb   => 'Go',
			family  => 'board',
			players => '2',
			args    => [],
			aliases => ['weiqi', 'baduk'],
			flags   => { %ALL },
		},
		{
			key     => 'mahjong',
			module  => 'Game::Mahjong',
			class   => 'Game::Mahjong::Terminal',
			blurb   => 'Mahjong, Chinese Official rules',
			family  => 'tile',
			players => '4',
			args    => [],
			aliases => [],
			flags   => { %ALL },
		},
		{
			key     => 'maze',
			module  => 'Term::Maze',
			class   => 'Term::Maze',
			blurb   => 'mazes in the terminal',
			family  => 'puzzle',
			players => '1',
			args    => [],
			aliases => [],
			flags   => {},
		},
		{
			key     => 'merrills',
			module  => 'Game::Merrills',
			class   => 'Game::Merrills::Terminal',
			blurb   => "Nine Men's Morris",
			family  => 'board',
			players => '2',
			args    => [],
			aliases => ['morris', 'mills', 'ninemensmorris'],
			flags   => { %ALL },
		},
		{
			key     => 'oware',
			module  => 'Game::Oware',
			class   => 'Game::Oware::Terminal',
			blurb   => 'the African sow and capture game, Abapa rules',
			family  => 'board',
			players => '2',
			args    => [],
			aliases => ['awale', 'awari'],
			flags   => { %ALL },
		},
		{
			key     => 'reversi',
			module  => 'Game::Reversi',
			class   => 'Game::Reversi::Terminal',
			blurb   => 'Reversi, with its 1883 opening',
			family  => 'board',
			players => '2',
			args    => [],
			aliases => ['othello'],
			flags   => { %ALL },
		},
		{
			key     => 'royalur',
			module  => 'Game::RoyalUr',
			class   => 'Game::RoyalUr::Terminal',
			blurb   => 'the Royal Game of Ur',
			family  => 'board',
			players => '2',
			args    => [],
			aliases => ['ur'],
			flags   => { %ALL },
		},
		{
			key     => 'schnapsen',
			module  => 'Game::Schnapsen',
			class   => 'Game::Schnapsen::Terminal',
			blurb   => 'Schnapsen',
			family  => 'card',
			players => '2',
			args    => ['--variant', 'schnapsen'],
			aliases => [],
			flags   => { %ALL },
		},
		{
			key     => 'sixtysix',
			module  => 'Game::Schnapsen',
			class   => 'Game::Schnapsen::Terminal',
			blurb   => 'Sixty-Six, the German parent of Schnapsen',
			family  => 'card',
			players => '2',
			args    => ['--variant', 'sixtysix'],
			aliases => ['66'],
			flags   => { %ALL },
		},
		{
			key     => 'snake',
			module  => 'Game::Snake',
			class   => 'Game::Snake::Terminal',
			blurb   => 'the classic snake game',
			family  => 'arcade',
			players => '1',
			args    => [],
			aliases => [],
			flags   => { ascii => '--ascii' },
		},
		{
			key     => 'xiangqi',
			module  => 'Game::Xiangqi',
			class   => 'Game::Xiangqi::Terminal',
			blurb   => 'xiangqi, Chinese chess',
			family  => 'board',
			players => '2',
			args    => [],
			aliases => ['chinesechess'],
			flags   => { %ALL },
		},
	);

	my %OPTIONS = (
		backgammon => [
			{ name => 'mode',  type => 'enum', choices => [qw(bot hotseat watch)], help => 'you against the program, two people at one keyboard, or two programs' },
			{ name => 'level', type => 'int',  min => 1, max => 3,                   help => 'how hard the program plays' },
			{ name => 'seat',  type => 'enum', choices => [qw(white black)],         help => 'your side' },
		],
		brandubh => [
			{ name => 'side',  type => 'enum', choices => [qw(attackers defenders both none)], help => 'your side; both is hotseat, none is watching' },
			{ name => 'level', type => 'int',  min => 1, max => 3,                            help => 'how hard the program plays' },
			{ name => 'seed',  type => 'str',                                                 help => 'sixty-four hexadecimal characters; the same seed plays the same game' },
		],
		checkers => [
			{ name => 'level',      type => 'int',  min => 1, max => 5,                   help => 'the strength of the bot' },
			{ name => 'side',       type => 'enum', choices => [qw(black white random)],  help => 'your side; black moves first' },
			{ name => 'hotseat',    type => 'flag',                                       help => 'two people at one keyboard, no bot' },
			{ name => 'bot-vs-bot', type => 'flag',                                       help => 'watch two bots play' },
			{ name => 'seed',       type => 'str',                                        help => 'the bot varies its easy levels with it' },
		],
		chess => [
			{ name => 'level', type => 'int',  min => 0, max => 3,          help => 'a rung of the ladder, 0 the weakest' },
			{ name => 'white', type => 'enum', choices => [qw(p1 p2)],      help => 'whoever is White moves first' },
			{ name => 'seat',  type => 'enum', choices => [qw(p1 p2)],      help => 'which seat you play' },
			{ name => 'size',  type => 'int',  min => 1, max => 3,          help => 'squares of 2, 4 or 6 columns' },
			{ name => 'seed',  type => 'str',                               help => 'up to thirty-two bytes, for a reproducible game' },
		],
		dominoes => [
			{ name => 'players',    type => 'int',  min => 2, max => 4,                          help => 'seats at the table' },
			{ name => 'seat',       type => 'int',  min => 1, max => 4,                          help => 'which seat you take' },
			{ name => 'level',      type => 'int',  min => 1, max => 5,                          help => 'the bots\x27 level' },
			{ name => 'variant',    type => 'enum', choices => [qw(all_fives draw block)],       help => 'the rules' },
			{ name => 'target',     type => 'int',  min => 50, max => 500,                       help => 'the score that wins' },
			{ name => 'hotseat',    type => 'flag',                                              help => 'every seat is a person' },
			{ name => 'bot-vs-bot', type => 'flag',                                              help => 'nobody is a person' },
			{ name => 'seed',       type => 'str',                                               help => 'reproduce a game exactly' },
		],
		durak => [
			{ name => 'level', type => 'int',  min => 1, max => 5,       help => 'how hard the bot plays' },
			{ name => 'seat',  type => 'enum', choices => [qw(1 2)],     help => 'your seat; the bot takes the other' },
			{ name => 'seed',  type => 'str',                            help => 'the deal; the same seed deals the same cards' },
		],
		fanorona => [
			{ name => 'side',    type => 'enum', choices => [qw(white black both neither)], help => 'your side; White moves first' },
			{ name => 'level',   type => 'int',  min => 1, max => 5,                         help => 'how hard the program plays' },
			{ name => 'variant', type => 'enum', choices => [qw(sivy dimy telo)],            help => 'the board: nine by five, five by five, or three by three' },
		],
		floppy => [
			{ name => 'level', type => 'int',  min => 1, max => 3,   help => 'the bot\x27s level, for watch' },
			{ name => 'watch', type => 'flag',                       help => 'watch the bot fly' },
			{ name => 'rows',  type => 'int',  min => 10, max => 25, help => 'the view in cells; the default fits the window' },
			{ name => 'seed',  type => 'str',                        help => 'the same seed and the same flaps are the same game' },
		],
		gin => [
			{ name => 'mode',  type => 'enum', choices => [qw(bot hotseat watch)], help => 'you against the bot, two people, or two bots' },
			{ name => 'level', type => 'int',  min => 1, max => 2,                   help => 'the bot\x27s strength' },
			{ name => 'seat',  type => 'enum', choices => [qw(p1 p2)],               help => 'your seat' },
			{ name => 'seed',  type => 'str',                                        help => 'deal the same game every time' },
		],
		go => [
			{ name => 'size',     type => 'enum', choices => [qw(9 13 19)],    help => 'the board' },
			{ name => 'level',    type => 'int',  min => 1, max => 5,          help => 'how hard the program plays' },
			{ name => 'colour',   type => 'enum', choices => [qw(black white)], help => 'your stones' },
			{ name => 'handicap', type => 'int',  min => 2, max => 9,          help => 'stones for black; 2 to 5 on the smaller boards' },
			{ name => 'komi',     type => 'str',                               help => 'a multiple of 0.5; 6.5 by default' },
			{ name => 'seed',     type => 'str',                               help => 'the seed the bot plays from' },
		],
		mahjong => [
			{ name => 'level',  type => 'int', min => 1, max => 3, help => 'the bots\x27 strength' },
			{ name => 'seat',   type => 'int', min => 0, max => 3, help => 'your seat; seat 0 deals the first hand' },
			{ name => 'glyphs', type => 'flag',                    help => 'the Unicode Mahjong Tiles block on the tile faces' },
			{ name => 'auto',   type => 'flag',                    help => 'four bots, no prompt: watch a game' },
			{ name => 'seed',   type => 'str',                     help => 'the same seed deals the same tiles' },
		],
		maze => [
			{ name => 'width',  type => 'int', min => 5, max => 120, help => 'cells across' },
			{ name => 'height', type => 'int', min => 5, max => 60,  help => 'cells down' },
		],
		merrills => [
			{ name => 'level',      type => 'int',  min => 1, max => 5,                  help => 'the bot\x27s strength' },
			{ name => 'side',       type => 'enum', choices => [qw(white black random)], help => 'your side' },
			{ name => 'hotseat',    type => 'flag',                                      help => 'two people at one keyboard, no bot' },
			{ name => 'bot-vs-bot', type => 'flag',                                      help => 'watch two bots' },
			{ name => 'flying',     type => 'bool',                                      help => 'a side down to three men may fly' },
			{ name => 'seed',       type => 'str',                                       help => 'the same seed, the same game' },
		],
		oware => [
			{ name => 'level',   type => 'int',  min => 1, max => 5,              help => 'bot level' },
			{ name => 'seat',    type => 'enum', choices => [qw(p1 p2)],          help => 'the seat you play' },
			{ name => 'variant', type => 'enum', choices => [qw(abapa awari)],    help => 'the rules' },
			{ name => 'seed',    type => 'str',                                   help => 'so a game can be replayed' },
		],
		reversi => [
			{ name => 'level',   type => 'int',  min => 1, max => 5,                   help => 'how hard the opponent is' },
			{ name => 'variant', type => 'enum', choices => [qw(historic othello)],    help => 'place the first four discs yourselves, or find them down' },
			{ name => 'colour',  type => 'enum', choices => [qw(b w)],                 help => 'b plays dark and moves first, w plays light' },
			{ name => 'seed',    type => 'str',                                        help => 'makes a game reproducible' },
		],
		royalur => [
			{ name => 'mode',  type => 'enum', choices => [qw(bot hotseat watch)], help => 'you against the program, two people, or the program against itself' },
			{ name => 'rules', type => 'enum', choices => [qw(finkel masters)],    help => 'the route and the rules' },
			{ name => 'level', type => 'int',  min => 1, max => 4,                   help => 'how well the program plays; the top by default' },
			{ name => 'side',  type => 'enum', choices => [qw(light dark)],         help => 'your side against the program' },
			{ name => 'first', type => 'enum', choices => [qw(light dark roll)],    help => 'who moves first, or throw the dice for it' },
			{ name => 'seed',  type => 'str',                                        help => 'hexadecimal; the same seed throws the same dice' },
		],
		schnapsen => [
			{ name => 'mode',  type => 'enum', choices => [qw(bot hotseat watch)], help => 'you against the bot, two people, or two bots' },
			{ name => 'level', type => 'int',  min => 1, max => 2,                   help => 'the bot\x27s strength' },
			{ name => 'seat',  type => 'enum', choices => [qw(p1 p2)],               help => 'your seat' },
			{ name => 'seed',  type => 'str',                                        help => 'deal the same match every time' },
		],
		snake => [
			{ name => 'level', type => 'int',  min => 1, max => 2,  help => 'the bot\x27s level, for watch' },
			{ name => 'watch', type => 'flag',                      help => 'watch the bot play' },
			{ name => 'rows',  type => 'int',  min => 8, max => 28, help => 'the board; the default fits the window' },
			{ name => 'cols',  type => 'int',  min => 8, max => 40, help => 'the board; the default fits the window' },
			{ name => 'seed',  type => 'str',                       help => 'the same seed and the same moves are the same game' },
		],
		xiangqi => [
			{ name => 'level', type => 'int',  min => 0, max => 3,     help => 'a rung of the ladder, 0 the weakest' },
			{ name => 'red',   type => 'enum', choices => [qw(p1 p2)], help => 'whoever is Red moves first' },
			{ name => 'seat',  type => 'enum', choices => [qw(p1 p2)], help => 'which seat you play' },
			{ name => 'wxf',   type => 'flag',                         help => 'show WXF notation beside the coordinates' },
			{ name => 'seed',  type => 'str',                          help => 'up to thirty-two bytes, for a reproducible game' },
		],
	);
	$OPTIONS{sixtysix} = $OPTIONS{schnapsen};

	for my $row (@ROSTER) {
		$row->{options} = $OPTIONS{ $row->{key} } || [];
		$BY_NAME{$row->{key}} = $row;
		$BY_NAME{$_} = $row for @{$row->{aliases}};
	}
}

sub games { return @ROSTER }

sub names { return map { $_->{key} } @ROSTER }

sub normalise {
	my ($name) = @_;
	return '' unless defined $name;
	my $clean = lc $name;
	$clean =~ s/^game(?:::|-)//;
	$clean =~ s/[^a-z0-9]//g;
	return $clean;
}

sub find {
	my ($name) = @_;
	return $BY_NAME{normalise($name)};
}

sub distance {
	my ($a, $b) = @_;
	my @a = split //, $a;
	my @b = split //, $b;
	my @previous = (0 .. @b);
	for my $i (1 .. @a) {
		my @current = ($i);
		for my $j (1 .. @b) {
			my $cost = $a[$i - 1] eq $b[$j - 1] ? 0 : 1;
			my $least = $previous[$j] + 1;
			$least = $current[$j - 1] + 1 if $current[$j - 1] + 1 < $least;
			$least = $previous[$j - 1] + $cost if $previous[$j - 1] + $cost < $least;
			push @current, $least;
		}
		@previous = @current;
	}
	return $previous[-1];
}

sub nearest {
	my ($name) = @_;
	my $clean = normalise($name);
	return () unless length $clean;
	my @keys = names();
	my @prefix = grep { index($_, $clean) == 0 } @keys;
	return @prefix if @prefix;
	my %score = map { $_ => distance($clean, $_) } @keys;
	return grep { $score{$_} <= 3 } sort { $score{$a} <=> $score{$b} || $a cmp $b } @keys;
}

sub module_file {
	my ($row) = @_;
	(my $file = $row->{class} . '.pm') =~ s{::}{/}g;
	return $file;
}

sub installed {
	my ($row, @inc) = @_;
	@inc = @INC unless @inc;
	my $file = module_file($row);
	for my $dir (grep { !ref } @inc) {
		return "$dir/$file" if -f "$dir/$file";
	}
	return undef;
}

sub version_of {
	my ($row, @inc) = @_;
	my $path = installed($row, @inc);
	return undef unless defined $path;
	open my $fh, '<', $path or return undef;
	while (my $line = <$fh>) {
		return $1 if $line =~ m/^\s*our\s+\$VERSION\s*=\s*['"]([^'"]+)['"]/;
	}
	return undef;
}

sub load {
	my ($row) = @_;
	require(module_file($row));
	return $row->{class};
}

sub flags_for {
	my ($row, $common) = @_;
	$common ||= {};
	my @flags;
	push @flags, $row->{flags}{ascii}
		if $common->{ascii} && $row->{flags}{ascii};
	push @flags, $row->{flags}{pick}
		if defined $common->{pick} && !$common->{pick} && $row->{flags}{pick};
	return @flags;
}

sub step_value {
	my ($field, $current, $direction) = @_;
	my $type = $field->{type};
	if ($type eq 'int') {
		return $direction > 0 ? $field->{min} : $field->{max} unless defined $current;
		my $next = $current + $direction;
		return $next < $field->{min} ? $field->{min} : $next > $field->{max} ? $field->{max} : $next;
	}
	if ($type eq 'enum') {
		my @choices = @{$field->{choices}};
		return $direction > 0 ? $choices[0] : $choices[-1] unless defined $current;
		my ($index) = grep { $choices[$_] eq $current } 0 .. $#choices;
		$index = 0 unless defined $index;
		return $choices[ ($index + $direction) % @choices ];
	}
	if ($type eq 'flag') {
		return $current ? undef : 1;
	}
	if ($type eq 'bool') {
		my @cycle = (undef, 1, 0);
		my $index = !defined $current ? 0 : $current ? 1 : 2;
		return $cycle[ ($index + $direction) % 3 ];
	}
	return $current;
}

sub check_value {
	my ($field, $text) = @_;
	$text = '' unless defined $text;
	$text =~ s/^\s+|\s+$//g;
	return (undef, undef) unless length $text;
	my $type = $field->{type};
	if ($type eq 'int') {
		return (undef, "$field->{name} takes a whole number from $field->{min} to $field->{max}")
			unless $text =~ m/^-?\d+$/ && $text >= $field->{min} && $text <= $field->{max};
		return ($text + 0, undef);
	}
	if ($type eq 'enum') {
		my ($match) = grep { lc $_ eq lc $text } @{$field->{choices}};
		return ($match, undef) if defined $match;
		return (undef, "$field->{name} takes " . join(', ', @{$field->{choices}}));
	}
	return ($text, undef);
}

sub argv_for {
	my ($row, $values) = @_;
	$values ||= {};
	my @argv;
	for my $field (@{ $row->{options} || [] }) {
		my $value = $values->{ $field->{name} };
		next unless defined $value;
		my $type = $field->{type};
		if ($type eq 'flag') {
			push @argv, "--$field->{name}" if $value;
		} elsif ($type eq 'bool') {
			push @argv, $value ? "--$field->{name}" : "--no-$field->{name}";
		} else {
			push @argv, "--$field->{name}", $value;
		}
	}
	push @argv, Text::ParseWords::shellwords($values->{extra})
		if defined $values->{extra} && length $values->{extra};
	return @argv;
}

sub launch {
	my ($row, $argv, %seam) = @_;
	my $loader = $seam{loader} || \&load;
	my $out = $seam{out} || \*STDOUT;
	my @argv = (@{ $row->{args} || [] }, @{ $argv || [] });

	my $getopt = Getopt::Long::Configure('default');
	local @SIG{qw(INT TERM HUP)};
	local $ENV{NO_COLOR} = $ENV{NO_COLOR};
	$ENV{NO_COLOR} = 1 if $seam{no_colour};
	my $depth = () = PerlIO::get_layers($out);
	my $selected = select;
	my $flush = do { select $out; my $was = $|; select $selected; $was };

	my ($status, $error);
	my $ok = eval {
		my $class = $loader->($row);
		$status = $class->run(@argv);
		1;
	};
	unless ($ok) {
		$error = $@;
		$error = 'died without a message' unless defined $error && length $error;
		$error =~ s/ at \S+ line \d+\.?\s*\z//;
		$error =~ s/\s+\z//;
	}

	select $selected;
	{ select $out; $| = $flush; select $selected }
	binmode $out, ':pop' while (() = PerlIO::get_layers($out)) > $depth;
	Getopt::Long::Configure($getopt);
	eval { Term::ReadKey::ReadMode(0) } if $INC{'Term/ReadKey.pm'};

	return ($status, $error);
}

1;

__END__

=head1 NAME

Game::Terminal - one game command for every terminal game

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    game                        # the menu
    game checkers --level 3     # the same as: checkers --level 3
    game sixtysix               # Schnapsen, in the Sixty-Six variant
    game list
    game help oware

    use Game::Terminal;

    my $row = Game::Terminal::find('draughts');          # the checkers row
    my ($status, $error) = Game::Terminal::launch($row, ['--level', 1]);

=head1 DESCRIPTION

A roster of the terminal games in the C<Game> namespace, L<Term::Maze> and
L<Term::Chess>,
with one command, C<game>, that lists them and starts any of them. A game is
started B<inside the same process>: its Terminal class's C<run> method takes
the command line and returns the exit status, so C<game checkers --level 3>
is C<checkers --level 3> with nothing between them, and the menu is back when
the game ends.

This module is the roster and the functions over it, and does no terminal
input or output of its own; the menu is L<Game::Terminal::Menu> and the
command is F<bin/game>.

=head2 What a game promises

Every class in the roster has a class method C<run(@argv)> that returns 0
when you won, drew or quit, 1 when you lost and 2 for a bad option, and never
calls C<exit>. C<--help> prints to C<STDOUT> and returns 0; a bad option
prints the usage to C<STDERR> and returns 2. Colour is off when C<NO_COLOR>
is set. C<launch> relies on nothing else, and guards against a game that
forgets the rest (see below).

=head2 The roster

Twenty-one rows for twenty games: Schnapsen is two rows, C<schnapsen> and
C<sixtysix>, because its program needs to be told the variant. Each row has
a C<key> (the word you type), the C<module> to install and the C<class> to
call, a one-line C<blurb>, a C<family> (board, card, tile, puzzle or arcade), the
number of C<players>, the C<args> the launcher puts before yours, the
C<aliases> that also find it, and the C<flags> that spell the launcher's own
C<--ascii> and C<--no-pick> in that game's words.

The aliases: C<draughts> is checkers, C<othello> is reversi, C<ur> is royalur,
C<morris> and C<mills> are merrills, C<tafl> is brandubh, C<weiqi> and
C<baduk> are go, C<chinesechess> is xiangqi, C<awale> and C<awari> are oware,
C<rummy> is gin, C<crib> is cribbage, C<flappy> is floppy, and C<66> is
sixtysix.

=head2 The options table

Each row also carries C<options>, the settings a person chooses before a
game: the level, a side or seat, a mode, a variant, a board size, a seed,
and the switches that turn a game into hotseat play or a bot watching
itself. Each is a hash of C<name>, C<type>, C<help>, and for an C<int> its
C<min> and C<max>, for an C<enum> its C<choices>. The types are C<int>,
C<enum>, C<flag> (sent as C<--name> when on), C<bool> (sent as C<--name> or
C<--no-name>, or not at all) and C<str>. File paths, replay records and
layout widths are not in the table; they stay on the command line, and the
menu\x27s C<extra> line takes them.

The launcher never repeats a game\x27s defaults: a field nobody set sends
nothing, so the game decides. The ranges and choices were read from each
game\x27s own usage text, so when a game changes its options this table is
where the drift lands.

=head1 FUNCTIONS

=head2 games

The rows, in order.

=head2 names

The keys, in order.

=head2 normalise

Lowercases a name, drops a leading C<Game::> or C<game-> and every character
that is not a letter or a digit, so C<Game::Checkers>, C<game-checkers> and
C<CHECKERS> all become C<checkers>.

=head2 find

    my $row = Game::Terminal::find('Draughts');

The row for a key or an alias after L</normalise>, or undef.

=head2 nearest

    my @keys = Game::Terminal::nearest('chekers');

Keys that start with the name, or failing that the keys within three edits
of it, nearest first; empty when nothing is close. For "did you mean".

=head2 distance

The Levenshtein distance between two strings.

=head2 module_file

The path under C<@INC> of a row's class, C<Game/Checkers/Terminal.pm>.

=head2 installed

    my $path = Game::Terminal::installed($row);
    my $path = Game::Terminal::installed($row, @dirs);

The file a row's class would load from, searching C<@INC> or the directories
given, or undef when it is nowhere.

=head2 version_of

The C<$VERSION> written in that file, read without loading it, or undef.

=head2 load

Requires the row's class and returns its name.

=head2 flags_for

    my @flags = Game::Terminal::flags_for($row, { ascii => 1, pick => 0 });

The launcher's common options spelt in the row's words: C<--ascii> becomes
C<--no-unicode> for brandubh and fanorona and nothing for maze, C<--no-pick>
is C<--no-pick> everywhere but maze, snake and floppy, which are played in real
time. Colour is not a flag: see C<no_colour>
under L</launch>.

=head2 step_value

    my $next = Game::Terminal::step_value($field, $current, +1);

The value one step to the right (C<+1>) or left (C<-1>) of C<$current> for
a field: an C<int> moves by one and stops at its ends, and from unset goes
to C<min> or C<max>; an C<enum> cycles through its choices; a C<flag>
toggles; a C<bool> cycles through unset, on and off. C<str> fields do not
step.

=head2 check_value

    my ($value, $error) = Game::Terminal::check_value($field, $typed);

A typed value for a field: the number, the matching choice regardless of
case, or the text, with C<$error> set and C<$value> undef when an C<int> is
out of range or an C<enum> is not a choice. Blank is unset.

=head2 argv_for

    my @argv = Game::Terminal::argv_for($row, \%values);

The command line the values make, in the table\x27s order, with the
C<extra> text split like a shell and appended last.

=head2 launch

    my ($status, $error) = Game::Terminal::launch($row, \@argv, %seam);

Loads the row's class and calls C<run> with the row's C<args> followed by
C<@argv>, and returns the status it gave. If C<run> died, C<$status> is
undef and C<$error> is the message without the C<at FILE line N> tail.

Around the call, so that a game leaves the process as it found it for the
next one: the Getopt::Long configuration is saved and put back; the
C<INT>, C<TERM> and C<HUP> handlers are local; every layer the game pushes
onto the output handle is popped again, since a second game pushing its own
encoding layer on top of the first would double-encode; the handle's
autoflush and the selected handle are restored; and if L<Term::ReadKey> is
loaded the terminal is put back in cooked mode, for a game that died before
its own C<leave_raw>.

C<%seam> takes C<loader> (a code ref returning the class, in place of
L</load>), C<out> (the handle whose layers are guarded, C<STDOUT> by default)
and C<no_colour> (true sets C<NO_COLOR> for the duration of the call).

=head1 SEE ALSO

L<Game::Terminal::Menu>, and the games: L<Game::Backgammon>,
L<Game::Brandubh>, L<Game::Checkers>, L<Game::Cribbage>, L<Game::Dominoes>,
L<Game::Durak>, L<Game::Fanorona>, L<Game::Floppy>, L<Game::Gin>, L<Game::Go>,
L<Game::Mahjong>, L<Game::Merrills>, L<Game::Oware>, L<Game::Reversi>,
L<Game::RoyalUr>, L<Game::Schnapsen>, L<Game::Snake>, L<Game::Xiangqi>,
L<Term::Maze>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
