use strict;
require 5.008;
use utf8;
use Encode;
use Test::More tests => 2;

my $name	=   "Common RON";

# Taken from http://www.unhchr.ch/udhr/lang/rum.htm
my $input	= "Fiecare om se poate prevala de toate drepturile şi ".
		  "libertăţile proclamate în prezenta Declaraţie fără ".
		  "nici un fel de deosebire ca, de pildă, deosebirea ".
		  "de rasă, culoare, sex, limbă, religie, opinie ".
		  "politică sau orice altă opinie, de origine ".
		  "naţională sau socială, avere, naştere sau orice ".
		  "alte împrejurări.";  

my $output_ok	= "Fiecare om se poate prevala de toate drepturile si ".
		  "libertatile proclamate in prezenta Declaratie fara ".
		  "nici un fel de deosebire ca, de pilda, deosebirea ".
		  "de rasa, culoare, sex, limba, religie, opinie ".
		  "politica sau orice alta opinie, de origine ".
		  "nationala sau sociala, avere, nastere sau orice ".
		  "alte imprejurari."; 

use Lingua::Translit;

my $tr = new Lingua::Translit($name);

# 1
is($tr->can_reverse(), 0, "$name: not reversible");

my $o = $tr->translit($input);

# 2
is($o, $output_ok, "$name: UDOHR transliteration");
