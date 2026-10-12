#!perl
use 5.014;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Getopt::Long ();

use Game::Terminal;
use Game::Fake::Terminal;

my $row = Game::Terminal::find('sixtysix');
my %fake = (loader => sub { 'Game::Fake::Terminal' });

sub reset_fake {
	@Game::Fake::Terminal::CALLS = ();
	$Game::Fake::Terminal::STATUS = 0;
	$Game::Fake::Terminal::DIE = undef;
	$Game::Fake::Terminal::MISBEHAVE = 0;
	$Game::Fake::Terminal::OUT = undef;
}

subtest 'the row args come first, then the caller\'s' => sub {
	plan tests => 3;
	reset_fake();
	$Game::Fake::Terminal::STATUS = 1;
	my ($status, $error) = Game::Terminal::launch($row, ['--level', 2], %fake);
	is $status, 1, 'the status is what run returned';
	is $error, undef, 'and there was no error';
	is_deeply $Game::Fake::Terminal::CALLS[0], ['--variant', 'sixtysix', '--level', 2],
		'the variant came before the caller\'s options';
};

subtest 'a game that dies' => sub {
	plan tests => 2;
	reset_fake();
	$Game::Fake::Terminal::DIE = "no board\n";
	my ($status, $error) = Game::Terminal::launch($row, [], %fake);
	is $status, undef, 'no status';
	is $error, 'no board', 'the message, trimmed';

	reset_fake();
	$Game::Fake::Terminal::DIE = 'the engine said no at lib/Game/Fake/Terminal.pm line 12.';
	(undef, $error) = Game::Terminal::launch($row, [], %fake);
};

subtest 'the at FILE line N tail is stripped' => sub {
	plan tests => 1;
	reset_fake();
	$Game::Fake::Terminal::DIE = "the engine said no at lib/Game/Fake/Terminal.pm line 12.\n";
	my (undef, $error) = Game::Terminal::launch($row, [], %fake);
	is $error, 'the engine said no', 'just the message';
};

subtest 'a game that misbehaves leaves nothing behind' => sub {
	plan tests => 5;
	reset_fake();
	my $output = '';
	open my $out, '>', \$output or die $!;
	$Game::Fake::Terminal::OUT = $out;
	$Game::Fake::Terminal::MISBEHAVE = 1;

	my $getopt = Getopt::Long::Configure('default');
	Getopt::Long::Configure($getopt);
	my @layers = PerlIO::get_layers($out);
	my $flush = do { my $previous = select $out; my $was = $|; select $previous; $was };
	my $selected = select;
	local $SIG{INT};

	my ($status) = Game::Terminal::launch($row, [], %fake, out => $out);
	is $status, 0, 'the game ran';

	my $after = Getopt::Long::Configure('default');
	Getopt::Long::Configure($after);
	is_deeply $after, $getopt, 'the Getopt configuration is back';
	is_deeply [ PerlIO::get_layers($out) ], \@layers, 'the layers the game pushed are gone';
	is +(do { my $previous = select $out; my $was = $|; select $previous; $was }), $flush,
		'autoflush is back';
	is $SIG{INT}, undef, 'and the handler the game installed is gone';
};

subtest 'NO_COLOR is set for the call when asked, and only then' => sub {
	plan tests => 3;
	local $ENV{NO_COLOR};
	delete $ENV{NO_COLOR};
	my $seen;
	my %spy = (loader => sub { 'Game::Fake::Terminal' });
	no warnings 'redefine';
	local *Game::Fake::Terminal::run = sub { $seen = $ENV{NO_COLOR}; return 0 };
	Game::Terminal::launch($row, [], %spy, no_colour => 1);
	is $seen, 1, 'set during the call';
	ok !exists $ENV{NO_COLOR} || !defined $ENV{NO_COLOR}, 'and not after it';
	Game::Terminal::launch($row, [], %spy);
	is $seen, undef, 'and not set when not asked';
};

subtest 'the default loader requires the class' => sub {
	plan tests => 2;
	local @INC = ('t/lib', @INC);
	my $checkers = Game::Terminal::find('checkers');
	my $output = '';
	open my $out, '>', \$output or die $!;
	my ($status) = do {
		local *STDOUT = $out;
		Game::Terminal::launch($checkers, ['--level', 3]);
	};
	is $status, 3, 'the shadow in t/lib answered';
	is $output, "stub checkers: --level 3\n", 'with the arguments it was given';
};

done_testing;
