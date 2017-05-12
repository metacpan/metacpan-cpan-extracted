#!/usr/bin/perl -w

use strict;
use Test::More tests => 16;
use Games::WoW::Armory;
use Data::Dumper;

use_ok('Games::WoW::Armory');
can_ok('Games::WoW::Armory', 'fetch_data');
can_ok('Games::WoW::Armory', 'search_character');
can_ok('Games::WoW::Armory', 'search_guild');

my $char = Games::WoW::Armory->new();
$char->search_character({realm => "Elune", character => "Aarnn", country => "EU"});
is ($char->character->{name}, "Aarnn", "Character name ok");
is ($char->character->name, "Aarnn", "New character name ok");
is ($char->character->level, 70, "New characterlevel ok");
isa_ok ($char->character->reputation, 'HASH', 'Reputation' );
isa_ok ($char->character->arenaTeams, 'ARRAY', 'Arena Teams');

my $guild = Games::WoW::Armory->new();
$guild->search_guild({realm => "Elune", guild => "Cercle+De+L+Anneau+Rond", country => "EU"});
is ($guild->guild->name, "Cercle De L Anneau Rond", "Guild name");
is ($guild->guild->realm, "Elune", "Realm name");
is ($guild->guild->battleGroup, "Cataclysme", "Battlegroup name");

my $arena = Games::WoW::Armory->new();
$arena->search_team({team => 'prouteam', ts => 2, country => 'EU', realm => 'Elune'});
is ($arena->team->name, 'prouteam', 'Team name');
is ($arena->team->size, 2, 'Team Size');
is ($arena->team->battleGroup, 'Cataclysme', 'Battlegroup name');
is ($arena->team->realm, 'Elune', 'Realm name');
