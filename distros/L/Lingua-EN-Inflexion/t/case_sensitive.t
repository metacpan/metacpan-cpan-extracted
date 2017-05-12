use Test::More;
use Lingua::EN::Inflexion;

is noun('maximum')->plural,            'maximums', 'maximum  --> maximums';
is noun('maximum')->classical->plural, 'maxima',   'maximum  --> maxima';
is noun('maximums')->singular,         'maximum',  'maximums --> maximum';
is noun('maxima')->singular,           'maximum',  'maxima   --> maximum';
ok noun('maximum')->is_singular,                   'maximum  is singular';
ok noun('maximums')->is_plural,                    'maximums is plural';
ok noun('maxima')->is_plural,                      'maxima   is plural';

is noun('Maximum')->plural,            'Maximums', 'Maximum  --> Maximums';
is noun('Maximum')->classical->plural, 'Maxima',   'Maximum  --> Maxima';
is noun('Maximums')->singular,         'Maximum',  'Maximums --> Maximum';
is noun('Maxima')->singular,           'Maximum',  'Maxima   --> Maximum';
ok noun('Maximum')->is_singular,                   'Maximum  is singular';
ok noun('Maximums')->is_plural,                    'Maximums is plural';
ok noun('Maxima')->is_plural,                      'Maxima   is plural';

is noun('MAXIMUM')->plural,            'MAXIMUMS', 'MAXIMUM  --> MAXIMUMS';
is noun('MAXIMUM')->classical->plural, 'MAXIMA',   'MAXIMUM  --> MAXIMA';
is noun('MAXIMUMS')->singular,         'MAXIMUM',  'MAXIMUMS --> MAXIMUM';
is noun('MAXIMA')->singular,           'MAXIMUM',  'MAXIMA   --> MAXIMUM';
ok noun('MAXIMUM')->is_singular,                   'MAXIMUM  is singular';
ok noun('MAXIMUMS')->is_plural,                    'MAXIMUMS is plural';
ok noun('MAXIMA')->is_plural,                      'MAXIMA   is plural';

done_testing();
