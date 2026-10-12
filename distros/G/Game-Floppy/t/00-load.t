#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use File::Find;
use Test::More;

# EVERY MODULE UNDER lib/ MUST COMPILE HERE, with no raylib and no
# Term::ReadKey installed. That is the whole point of the front ends keeping
# their optional dependencies out of compile time, and the only test that
# would notice a `use Raylib::FFI` creeping back in.

my $lib = "$FindBin::Bin/../lib";

my @modules;
find(sub {
	return unless /\.pm\z/;
	my $name = $File::Find::name;
	$name =~ s{^\Q$lib\E/}{};
	$name =~ s{/}{::}g;
	$name =~ s{\.pm\z}{};
	push @modules, $name;
}, $lib);
@modules = sort @modules;

cmp_ok(scalar @modules, '>=', 3, 'there is more than one module under lib');

use_ok($_) for @modules;

for my $module (grep { $_ ne 'Game::Floppy' } @modules) {
	is($module->VERSION, Game::Floppy->VERSION, "$module carries the distribution's version");
}

can_ok('Game::Floppy', qw(new flap tick bird tubes circle_hits_rectangle width height seed
	bird_x bird_radius gravity lift tube_every tube_speed tube_width gap tube_score
	score passed ticks status error result quit reset));
can_ok('Game::Floppy::Error', qw(of code message error codes messages stringify));
can_ok('Game::Floppy::Result', qw(new cause score tubes ticks died causes stringify));

ok(!$INC{'Raylib/FFI.pm'}, 'and nothing loaded raylib');

diag("Testing Game::Floppy $Game::Floppy::VERSION, Perl $], $^X");

done_testing();
