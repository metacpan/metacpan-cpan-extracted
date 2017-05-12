#!/usr/bin/perl

use 5.010;

use strict;
use warnings;
no warnings 'syntax';

use Test::More 0.88;

use Games::Wumpus::Room;

our $r = eval "require Test::NoWarnings; 1";


my $room = Games::Wumpus::Room -> new -> init;

isa_ok $room, 'Games::Wumpus::Room';

is $room -> set_name ("Room name"), $room, "Set room name";
is $room -> name, "Room name", "Get room name";

is  $room -> hazards, 0, "No hazards set";
is  $room -> set_hazard (2), $room, "Set hazard";
is  $room -> hazards, 2, "One hazard set";
is  $room -> set_hazard (4), $room, "Set hazard";
is  $room -> hazards, 6, "Two hazards set";
is  $room -> set_hazard (4), $room, "Set hazard";
is  $room -> hazards, 6, "Two hazards set";
ok  $room -> has_hazard (2), "Has hazard";
ok !$room -> has_hazard (1), "Does not have hazard";
is  $room -> clear_hazard (2), $room, "Clear hazard";
is  $room -> hazards, 4, "One hazard set";
is  $room -> clear_hazards, $room, "Cleared all hazard";
is  $room -> hazards, 0, "No hazards set";

is  scalar $room -> exits, 0, "No exits";
is  $room -> add_exit (bless \do {my $x = "one"}), $room, "Add exit";
is  $room -> add_exit (bless \do {my $x = "two"}), $room, "Add exit";
is  scalar $room -> exits, 2, "Two exits";
ok  scalar $room -> exit_by_name ("one"), "Got exit";
ok  scalar $room -> exit_by_name ("two"), "Got exit";
ok !scalar $room -> exit_by_name ("three"), "Didn't get exit";


sub name {${$_ [0]}}

Test::NoWarnings::had_no_warnings () if $r;

done_testing;


__END__
