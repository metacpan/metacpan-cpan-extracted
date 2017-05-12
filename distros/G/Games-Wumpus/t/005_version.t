#!/usr/bin/perl

use 5.010;

use strict;
use warnings;
no  warnings 'syntax';

use Test::More 0.88;

use Games::Wumpus;
use Games::Wumpus::Cave;
use Games::Wumpus::Room;
use Games::Wumpus::Constants;

our $r = eval "require Test::NoWarnings; 1";

is $Games::Wumpus::Cave::VERSION,      $Games::Wumpus::VERSION, "VERSION check";
is $Games::Wumpus::Room::VERSION,      $Games::Wumpus::VERSION, "VERSION check";
is $Games::Wumpus::Constants::VERSION, $Games::Wumpus::VERSION, "VERSION check";


ok $Games::Wumpus::Cave::VERSION =~ /^2009[01][0-9][0-3][0-9][0-9]{2}$/,
  "VERSION format";

Test::NoWarnings::had_no_warnings () if $r;

done_testing;

__END__
