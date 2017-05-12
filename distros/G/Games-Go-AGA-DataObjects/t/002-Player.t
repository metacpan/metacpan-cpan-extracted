# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 002-Player.t'

#########################

use strict;
use warnings;

use Test::More tests => 11;
BEGIN { use_ok('Games::Go::AGA::DataObjects::Player') };

my $player = Games::Go::AGA::DataObjects::Player->new(
                id         => 'tmp0201',
                last_name  => 'last_name',
                first_name => 'first_name',
                rank       => '5d',
                flags      => ['flags'],
                comment    => 'comment',
                );
isa_ok ($player, 'Games::Go::AGA::DataObjects::Player', 'create object');

is ($player->id,         'TMP201',     'id normalized');
is ($player->first_name, 'first_name', 'first name');
is ($player->last_name,  'last_name',  'last name');
is ($player->rank,       '5d',         'rank');
my %id = (
    x003     => 'X3',
    X00300   => 'X300',
    x00Y00   => 'X0Y0',
    x003y00  => 'X3Y0',
    );
foreach my $key (keys %id) {
    $player->id($key);
    is ($player->id,         $id{$key},         'id normalized');
}
$player->rank(2.0);
is ($player->rank,       2.0,         'changed rank to rating 2');
# can't test wins/losses methods until Games are verified
