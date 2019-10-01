#!/usr/bin/perl

use strict;
use warnings;

use Eval::Safe;
use Test::More;

plan tests => 1;

# Lire https://perldoc.perl.org/functions/eval.html et l'impact de
# "unicode_eval" et utf8. Ajouter une option dans le constructeur pour passer
# use utf8 ou non lors de l'évaluation et tester le résultat. Essayer de voir
# si on peut le déterminer de la chaine qui est passée.

ok(1);