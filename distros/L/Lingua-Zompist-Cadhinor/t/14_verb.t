# vim:set filetype=perl sw=4 et:

use Test::More tests => 92;
use Carp;

BEGIN { use_ok 'Lingua::Zompist::Cadhinor', '%verb'; }

is($verb{static}{definite}{present}->('SCRIFEC')->[0], 'SCRIFAO', 'static definite present');
is($verb{nuncre}{prilise}{demeric}->('SCRIFEC')->[0], 'SCRIFAO', 'nuncre prilise demeric');
is($verb{definite}{present}->('SCRIFEC')->[0], 'SCRIFAO', 'definite present');
is($verb{prilise}{demeric}->('SCRIFEC')->[0], 'SCRIFAO', 'prilise demeric');
is($verb{static}{present}->('SCRIFEC')->[0], 'SCRIFAO', 'static present');
is($verb{nuncre}{demeric}->('SCRIFEC')->[0], 'SCRIFAO', 'nuncre demeric');
is($verb{present}->('SCRIFEC')->[0], 'SCRIFAO', 'present');
is($verb{demeric}->('SCRIFEC')->[0], 'SCRIFAO', 'demeric');

is($verb{static}{definite}{past}->('SCRIFEC')->[1], 'SCRIFIUS', 'static definite past');
is($verb{nuncre}{prilise}{scrifel}->('SCRIFEC')->[1], 'SCRIFIUS', 'nuncre prilise scrifel');
is($verb{definite}{past}->('SCRIFEC')->[1], 'SCRIFIUS', 'definite past');
is($verb{prilise}{scrifel}->('SCRIFEC')->[1], 'SCRIFIUS', 'prilise scrifel');
is($verb{static}{past}->('SCRIFEC')->[1], 'SCRIFIUS', 'static past');
is($verb{nuncre}{scrifel}->('SCRIFEC')->[1], 'SCRIFIUS', 'nuncre scrifel');
is($verb{past}->('SCRIFEC')->[1], 'SCRIFIUS', 'past');
is($verb{scrifel}->('SCRIFEC')->[1], 'SCRIFIUS', 'scrifel');

is($verb{static}{definite}{pastanterior}->('SCRIFEC')->[2], 'SCRIFERU', 'static definite pastanterior');
is($verb{nuncre}{prilise}{izhcrifel}->('SCRIFEC')->[2], 'SCRIFERU', 'nuncre prilise izhcrifel');
is($verb{definite}{pastanterior}->('SCRIFEC')->[2], 'SCRIFERU', 'definite pastanterior');
is($verb{prilise}{izhcrifel}->('SCRIFEC')->[2], 'SCRIFERU', 'prilise izhcrifel');
is($verb{static}{pastanterior}->('SCRIFEC')->[2], 'SCRIFERU', 'static pastanterior');
is($verb{nuncre}{izhcrifel}->('SCRIFEC')->[2], 'SCRIFERU', 'nuncre izhcrifel');
is($verb{pastanterior}->('SCRIFEC')->[2], 'SCRIFERU', 'pastanterior');
is($verb{izhcrifel}->('SCRIFEC')->[2], 'SCRIFERU', 'izhcrifel');

is($verb{static}{definite}{"past anterior"}->('SCRIFEC')->[2], 'SCRIFERU', 'static definite "past anterior"');
is($verb{nuncre}{prilise}{izhcrifel}->('SCRIFEC')->[2], 'SCRIFERU', 'nuncre prilise izhcrifel');
is($verb{definite}{"past anterior"}->('SCRIFEC')->[2], 'SCRIFERU', 'definite "past anterior"');
is($verb{prilise}{izhcrifel}->('SCRIFEC')->[2], 'SCRIFERU', 'prilise izhcrifel');
is($verb{static}{"past anterior"}->('SCRIFEC')->[2], 'SCRIFERU', 'static "past anterior"');
is($verb{nuncre}{izhcrifel}->('SCRIFEC')->[2], 'SCRIFERU', 'nuncre izhcrifel');
is($verb{"past anterior"}->('SCRIFEC')->[2], 'SCRIFERU', '"past anterior"');
is($verb{izhcrifel}->('SCRIFEC')->[2], 'SCRIFERU', 'izhcrifel');

is($verb{static}{definite}{imperative}->('SCRIFEC'), undef, 'static definite imperative');
is($verb{nuncre}{prilise}{befel}->('SCRIFEC'), undef, 'nuncre prilise befel');
is($verb{definite}{imperative}->('SCRIFEC'), undef, 'definite imperative');
is($verb{prilise}{befel}->('SCRIFEC'), undef, 'prilise befel');

is($verb{static}{remote}{present}->('SCRIFEC')->[3], 'SCRIFETOM', 'static remote present');
is($verb{nuncre}{buprilise}{demeric}->('SCRIFEC')->[3], 'SCRIFETOM', 'nuncre buprilise demeric');
is($verb{remote}{present}->('SCRIFEC')->[3], 'SCRIFETOM', 'remote present');
is($verb{buprilise}{demeric}->('SCRIFEC')->[3], 'SCRIFETOM', 'buprilise demeric');

is($verb{static}{remote}{past}->('SCRIFEC')->[4], 'SCRIFECOS', 'static remote past');
is($verb{nuncre}{buprilise}{scrifel}->('SCRIFEC')->[4], 'SCRIFECOS', 'nuncre buprilise scrifel');
is($verb{remote}{past}->('SCRIFEC')->[4], 'SCRIFECOS', 'remote past');
is($verb{buprilise}{scrifel}->('SCRIFEC')->[4], 'SCRIFECOS', 'buprilise scrifel');

is($verb{static}{remote}{pastanterior}->('SCRIFEC'), undef, 'static remote pastanterior');
is($verb{nuncre}{buprilise}{izhcrifel}->('SCRIFEC'), undef, 'nuncre buprilise izhcrifel');
is($verb{remote}{pastanterior}->('SCRIFEC'), undef, 'remote pastanterior');
is($verb{buprilise}{izhcrifel}->('SCRIFEC'), undef, 'buprilise izhcrifel');

is($verb{static}{remote}{"past anterior"}->('SCRIFEC'), undef, 'static remote "past anterior"');
is($verb{nuncre}{buprilise}{izhcrifel}->('SCRIFEC'), undef, 'nuncre buprilise izhcrifel');
is($verb{remote}{"past anterior"}->('SCRIFEC'), undef, 'remote "past anterior"');
is($verb{buprilise}{izhcrifel}->('SCRIFEC'), undef, 'buprilise izhcrifel');

is($verb{static}{remote}{imperative}->('SCRIFEC')->[1], 'SCRIFE', 'static remote imperative');
is($verb{nuncre}{buprilise}{befel}->('SCRIFEC')->[1], 'SCRIFE', 'nuncre buprilise befel');
is($verb{remote}{imperative}->('SCRIFEC')->[1], 'SCRIFE', 'remote imperative');
is($verb{buprilise}{befel}->('SCRIFEC')->[1], 'SCRIFE', 'buprilise befel');
is($verb{static}{imperative}->('SCRIFEC')->[1], 'SCRIFE', 'static imperative');
is($verb{nuncre}{befel}->('SCRIFEC')->[1], 'SCRIFE', 'nuncre befel');
is($verb{imperative}->('SCRIFEC')->[1], 'SCRIFE', 'imperative');
is($verb{befel}->('SCRIFEC')->[1], 'SCRIFE', 'befel');


is($verb{dynamic}{definite}{present}->('SCRIFEC')->[0], 'SCRIFUI', 'dynamic definite present');
is($verb{olocec}{prilise}{demeric}->('SCRIFEC')->[0], 'SCRIFUI', 'olocec prilise demeric');
is($verb{dynamic}{present}->('SCRIFEC')->[0], 'SCRIFUI', 'dynamic present');
is($verb{olocec}{demeric}->('SCRIFEC')->[0], 'SCRIFUI', 'olocec demeric');

is($verb{dynamic}{definite}{past}->('SCRIFEC')->[1], 'SCRIFEVUIS', 'dynamic definite past');
is($verb{olocec}{prilise}{scrifel}->('SCRIFEC')->[1], 'SCRIFEVUIS', 'olocec prilise scrifel');
is($verb{dynamic}{past}->('SCRIFEC')->[1], 'SCRIFEVUIS', 'dynamic past');
is($verb{olocec}{scrifel}->('SCRIFEC')->[1], 'SCRIFEVUIS', 'olocec scrifel');

is($verb{dynamic}{definite}{pastanterior}->('SCRIFEC')->[2], 'SCRIFERUT', 'dynamic definite pastanterior');
is($verb{olocec}{prilise}{izhcrifel}->('SCRIFEC')->[2], 'SCRIFERUT', 'olocec prilise izhcrifel');
is($verb{dynamic}{pastanterior}->('SCRIFEC')->[2], 'SCRIFERUT', 'dynamic pastanterior');
is($verb{olocec}{izhcrifel}->('SCRIFEC')->[2], 'SCRIFERUT', 'olocec izhcrifel');

is($verb{dynamic}{definite}{"past anterior"}->('SCRIFEC')->[2], 'SCRIFERUT', 'dynamic definite "past anterior"');
is($verb{olocec}{prilise}{izhcrifel}->('SCRIFEC')->[2], 'SCRIFERUT', 'olocec prilise izhcrifel');
is($verb{dynamic}{"past anterior"}->('SCRIFEC')->[2], 'SCRIFERUT', 'dynamic "past anterior"');
is($verb{olocec}{izhcrifel}->('SCRIFEC')->[2], 'SCRIFERUT', 'olocec izhcrifel');

is($verb{dynamic}{definite}{imperative}->('SCRIFEC'), undef, 'dynamic definite imperative');
is($verb{olocec}{prilise}{befel}->('SCRIFEC'), undef, 'olocec prilise befel');

is($verb{dynamic}{remote}{present}->('SCRIFEC')->[3], 'SCRIFUAM', 'dynamic remote present');
is($verb{olocec}{buprilise}{demeric}->('SCRIFEC')->[3], 'SCRIFUAM', 'olocec buprilise demeric');

is($verb{dynamic}{remote}{past}->('SCRIFEC')->[4], 'SCRIFISAS', 'dynamic remote past');
is($verb{olocec}{buprilise}{scrifel}->('SCRIFEC')->[4], 'SCRIFISAS', 'olocec buprilise scrifel');

is($verb{dynamic}{remote}{pastanterior}->('SCRIFEC'), undef, 'dynamic remote pastanterior');
is($verb{olocec}{buprilise}{izhcrifel}->('SCRIFEC'), undef, 'olocec buprilise izhcrifel');

is($verb{dynamic}{remote}{"past anterior"}->('SCRIFEC'), undef, 'dynamic remote "past anterior"');
is($verb{olocec}{buprilise}{izhcrifel}->('SCRIFEC'), undef, 'olocec buprilise izhcrifel');

is($verb{dynamic}{remote}{imperative}->('SCRIFEC')->[1], 'SCRIFE', 'dynamic remote imperative');
is($verb{olocec}{buprilise}{befel}->('SCRIFEC')->[1], 'SCRIFE', 'olocec buprilise befel');
is($verb{dynamic}{imperative}->('SCRIFEC')->[1], 'SCRIFE', 'dynamic imperative');
is($verb{olocec}{befel}->('SCRIFEC')->[1], 'SCRIFE', 'olocec befel');

is($verb{part}->('SCRIFEC')->[0], 'SCRIFILES', 'part');
