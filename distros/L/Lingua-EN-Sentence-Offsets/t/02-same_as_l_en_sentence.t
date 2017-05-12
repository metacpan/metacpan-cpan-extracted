#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;
use Lingua::EN::Sentence qw/get_sentences/;
use Lingua::EN::Sentence::Offsets qw/get_sentences/;
use Data::Dump qw/dump/;

my $text = join '',<DATA>;
my $expected_s1 = Lingua::EN::Sentence::get_sentences($text);
my $got_s2 = Lingua::EN::Sentence::Offsets::get_sentences($text);

is_deeply($got_s2,$expected_s1,"L::EN::S::O vs L::EN::S");

__DATA__
Over the caption December 31st 1999 a crude spaceship flies through space, cruising over and under planets and a man speaks.
(voice-over) Space. It seems to go on and on forever. But then you get to the end and the gorilla starts throwing barrels at you.

A planet opens up and a huge gorilla starts throwing barrels at the spaceship. It dodges a few but one hits it and it explodes. The gorilla thumps its chest and "Game Over" flashes on the screen. The spaceship and gorilla isn't real and the man, called Fry, was playing an arcade game called "Monkey Fracas Jr". He is in his mid-20s, wears a red jacket and has orange hair with two distinct forks at the front. There is a little kid standing next to him. The game is against the wall in a pizzeria called Panucci's Pizza.

And that's how you play the game!
You stink, loser!
               
Mr Panucci, a middle-aged balding man
wearing a vest, leans over the counter
with a pizza box. Hey, Fry. Pizza goin' out!
C'mon!! Fry sighs, takes the pizza from him
and walks out. New York Street. Fry cycles past
people enjoying their New Millennium Eve. A cab
pulls up and he sees his girlfriend inside.
Michelle, baby! Where you going? It's not working out, Fry. I put your stuff out on the sidewalk! Time Lapse. Fry is still on his bike getting more and more depressed.
I hate my life I hate my life I hate my life.
 
Cut to: Outside Applied Cryogenics. He stops outside a building and locks up his bike. A man sneaks up behind him, cuts the chain and steals his bike.
Happy new year! Applied Cryogenics. Fry steps out of the elevator on the 64th floor. He knocks on a door marked Applied Cryogenics. A sign underneath indicates No Power Failures Since 199[7]. No one opens the door so Fry goes in.
