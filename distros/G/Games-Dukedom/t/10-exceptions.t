#!perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;

use Games::Dukedom;
use Games::Dukedom::Signal;

my $pkg = 'Games::Dukedom::Signal';

my $game = new_ok( 'Games::Dukedom' => [], '$game' );

isa_ok( $game->signal, $pkg, '$game->signal' );
can_ok( $game, 'throw' );

ok( $game->input('dummy'), 'input is not empty prior to throw' );
throws_ok( sub { $game->throw }, $pkg, "signal throws a $pkg" );
ok( !exists( $game->{input} ), 'input was cleared by throw' );

throws_ok( sub { $game->throw('message only') }, $pkg, 'accepts single param' );
is( $@->msg, 'message only', 'single param seen as "msg" param' );

done_testing();

exit;

__END__

