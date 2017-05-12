#!perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;

use Games::Dukedom;

my $pkg = 'Games::Dukedom';

my $game = new_ok( $pkg => [], '$game' );

my @good_yn = (
    qw(
      y
      Y
      n
      N
      ),

);

my @good_value = (
    qw(
      0
      1
      10
      99
      100
      999
      ),
    1.0
);

my @bad_yn = (
    qw(
      yes
      no
      quit
      q
      ),
    ' ',
    "\n",
    @good_value
);

my @bad_value = ( 0.1, -1, 1.1, '1.0', ' ', "\n", 'quit', 'q', @good_yn );

for (@good_yn) {
    $game->input($_);
    ok( $game->input_is_yn, "$_ passes input_is_yn" );
}

for (@bad_yn) {
    $game->input($_);
    ok( !$game->input_is_yn, "$_ is rejected by input_is_yn" );
}

for (@good_value) {
    $game->input($_);
    ok( $game->input_is_value, "$_ passes input_is_value" );
}

for (@bad_value) {
    $game->input($_);
    ok( !$game->input_is_value, "$_ is rejected by input_is_value" );
}

done_testing();

exit;

__END__

