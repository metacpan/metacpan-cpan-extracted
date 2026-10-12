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

for my $module (grep { $_ ne 'Game::Snake' } @modules) {
	is($module->VERSION, Game::Snake->VERSION, "$module carries the distribution's version");
}

can_ok('Game::Snake', qw(new turn tick segments at free_cells food cols rows seed
	start_length food_score start_speed length heading status score speed ticks growing
	error result quit reset));
can_ok('Game::Snake::Error', qw(of code message error codes messages stringify));
can_ok('Game::Snake::Result', qw(new cause score length ticks speed died causes stringify));

ok(!$INC{'Raylib/FFI.pm'}, 'and nothing loaded raylib');

diag("Testing Game::Snake $Game::Snake::VERSION, Perl $], $^X");

done_testing();
