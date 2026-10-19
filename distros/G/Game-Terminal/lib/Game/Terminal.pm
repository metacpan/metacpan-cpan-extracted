package Game::Terminal;

use 5.014;
use strict;
use warnings;

use Getopt::Long ();
use Game::Terminal::Kit::Options ();

our $VERSION = '0.04';

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
			key     => 'senet',
			module  => 'Game::Senet',
			class   => 'Game::Senet::Terminal',
			blurb   => 'Senet, the race game of ancient Egypt',
			family  => 'board',
			players => '2',
			args    => [],
			aliases => [],
			flags   => { %ALL },
		},
		{
			key     => 'shogi',
			module  => 'Game::Shogi',
			class   => 'Game::Shogi::Terminal',
			blurb   => 'shogi, Japanese chess',
			family  => 'board',
			players => '2',
			args    => [],
			aliases => ['japanesechess'],
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
			key     => 'sternhalma',
			module  => 'Game::Sternhalma',
			class   => 'Game::Sternhalma::Terminal',
			blurb   => 'sternhalma, Chinese checkers, for two to six',
			family  => 'board',
			players => '2-6',
			args    => [],
			aliases => ['chinesecheckers'],
			flags   => { ascii => '--no-unicode', pick => '--no-pick' },
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


	for my $row (@ROSTER) {
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

sub options_for {
	my ($row, %seam) = @_;
	return $row->{options} if ref $row->{options} eq 'ARRAY';
	my $loader = $seam{loader} || \&load;
	my $class = eval { $loader->($row) };
	return [] unless $class && $class->can('options');
	my $fields = eval { $class->options };
	return ref $fields eq 'ARRAY' ? $fields : [];
}

sub step_value {
	return Game::Terminal::Kit::Options::step_value(@_);
}

sub check_value {
	return Game::Terminal::Kit::Options::check_value(@_);
}

sub argv_for {
	my ($row, $values, %seam) = @_;
	return Game::Terminal::Kit::Options::argv_for(options_for($row, %seam), $values);
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

Game::Terminal - one game command to rule all terminal games

=head1 VERSION

Version 0.02

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

Twenty-four rows for twenty-three games: Schnapsen is two rows, C<schnapsen> and
C<sixtysix>, because its program needs to be told the variant. Each row has
a C<key> (the word you type), the C<module> to install and the C<class> to
call, a one-line C<blurb>, a C<family> (board, card, tile, puzzle or arcade), the
number of C<players>, the C<args> the launcher puts before yours, the
C<aliases> that also find it, and the C<flags> that spell the launcher's own
C<--ascii> and C<--no-pick> in that game's words.

The aliases: C<draughts> is checkers, C<othello> is reversi, C<ur> is royalur,
C<morris> and C<mills> are merrills, C<tafl> is brandubh, C<weiqi> and
C<baduk> are go, C<chinesechess> is xiangqi, C<japanesechess> is shogi, C<chinesecheckers> is sternhalma, C<awale> and C<awari> are oware,
C<rummy> is gin, C<crib> is cribbage, C<flappy> is floppy, and C<66> is
sixtysix.

=head2 Where the options come from

The settings a person chooses before a game (the level, a side or seat, a
mode, a variant, a board size, a seed, the switches that turn a game into
hotseat play or a bot watching itself) are the game's own to list. Each
class in the roster has a class method C<options> that returns them as
fields, and L</options_for> asks it. A field is a hash of C<name>, C<type>
and C<help>, with C<min> and C<max> for an C<int> and C<choices> for an
C<enum>; L<Game::Terminal::Kit::Options> describes them in full. File paths,
replay records and layout widths are not among them; they stay on the
command line, and the menu's C<extra> line takes them.

The launcher never repeats a game's defaults: a field nobody set sends
nothing, so the game decides.

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

=head2 options_for

    my $fields = Game::Terminal::options_for($row);

The fields of a row's game, as an array reference: what its class's
C<options> method returns. The class is loaded to ask it, so this is called
when a game's options are about to be shown and not while the games are
listed. A game that is not installed, or whose class has no such method, has
no fields. A row that carries its own C<options> list is believed without
asking. C<loader> may be given as for L</launch>.

=head2 flags_for

    my @flags = Game::Terminal::flags_for($row, { ascii => 1, pick => 0 });

The launcher's common options spelt in the row's words: C<--ascii> becomes
C<--no-unicode> for brandubh and fanorona and nothing for maze, C<--no-pick>
is C<--no-pick> everywhere but maze, snake and floppy, which are played in real
time. Colour is not a flag: see C<no_colour>
under L</launch>.

=head2 step_value

    my $next = Game::Terminal::step_value($field, $current, +1);

L<Game::Terminal::Kit::Options/step_value>, under the name it has always had
here.

The value one step to the right (C<+1>) or left (C<-1>) of C<$current> for
a field: an C<int> moves by one and stops at its ends, and from unset goes
to C<min> or C<max>; an C<enum> cycles through its choices; a C<flag>
toggles; a C<bool> cycles through unset, on and off. C<str> fields do not
step.

=head2 check_value

    my ($value, $error) = Game::Terminal::check_value($field, $typed);

L<Game::Terminal::Kit::Options/check_value>, likewise.

A typed value for a field: the number, the matching choice regardless of
case, or the text, with C<$error> set and C<$value> undef when an C<int> is
out of range or an C<enum> is not a choice. Blank is unset.

=head2 argv_for

    my @argv = Game::Terminal::argv_for($row, \%values);

The command line the values make for the row's fields, in the order
L</options_for> gives them, with the C<extra> text split like a shell and
appended last.

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
L<Game::RoyalUr>, L<Game::Schnapsen>, L<Game::Senet>, L<Game::Shogi>, L<Game::Snake>, L<Game::Sternhalma>, L<Game::Xiangqi>,
L<Term::Maze>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
