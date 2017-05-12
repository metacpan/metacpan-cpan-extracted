use strict;
require 5.008;
use utf8;
use Encode;
use Test::More tests => 3;

use Lingua::Translit;

my $name = "ISO 8859-16 RON";

# Taken from http://www.unhchr.ch/udhr/lang/rum.htm
my $text_cedila = "Fiecare om se poate prevala de toate drepturile şi ".
		  "libertăţile proclamate în prezenta Declaraţie fără ".
		  "nici un fel de deosebire ca, de pildă, deosebirea ".
		  "de rasă, culoare, sex, limbă, religie, opinie ".
		  "politică sau orice altă opinie, de origine ".
		  "naţională sau socială, avere, naştere sau orice ".
		  "alte împrejurări.";

my $text_comma = "Fiecare om se poate prevala de toate drepturile și ".
		  "libertățile proclamate în prezenta Declarație fără ".
		  "nici un fel de deosebire ca, de pildă, deosebirea ".
		  "de rasă, culoare, sex, limbă, religie, opinie ".
		  "politică sau orice altă opinie, de origine ".
		  "națională sau socială, avere, naștere sau orice ".
		  "alte împrejurări.";

my $tr = Lingua::Translit->new($name);

# 1
is $tr->can_reverse(), 1, "$name: is reversible";

my $o = $tr->translit($text_cedila);

# 2
is $o, $text_comma, "$name: UDOHR transliteration";

my $r = $tr->translit_reverse($text_comma);

# 3
is $r, $text_cedila, "$name: UDOHR transliteration (reverse)";
