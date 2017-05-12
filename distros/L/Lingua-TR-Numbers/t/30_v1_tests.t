use 5.006;
use strict;
use warnings;
use utf8;
use subs qw( _log );
use Test::More qw( no_plan );

## no critic (ValuesAndExpressions::ProhibitMagicNumbers, Subroutines::ProhibitSubroutinePrototypes)

use Lingua::TR::Numbers qw(num2tr num2tr_ordinal);

_log "# Using Lingua::TR::Numbers v$Lingua::TR::Numbers::VERSION\n";

sub N ($) { return num2tr(        shift) }
sub O ($) { return num2tr_ordinal(shift) }

is N   0, 'sıfır',        'num2tr';
is N   1, 'bir',          'num2tr';
is N   2, 'iki',          'num2tr';
is N   3, 'üç',           'num2tr';
is N   4, 'dört',         'num2tr';
is N   5, 'beş',          'num2tr';
is N   6, 'altı',         'num2tr';
is N   7, 'yedi',         'num2tr';
is N   8, 'sekiz',        'num2tr';
is N   9, 'dokuz',        'num2tr';
is N  10, 'on',           'num2tr';
is N  11, 'on bir',       'num2tr';
is N  12, 'on iki',       'num2tr';
is N  13, 'on üç',        'num2tr';
is N  14, 'on dört',      'num2tr';
is N  15, 'on beş',       'num2tr';
is N  16, 'on altı',      'num2tr';
is N  17, 'on yedi',      'num2tr';
is N  18, 'on sekiz',     'num2tr';
is N  19, 'on dokuz',     'num2tr';
is N  20, 'yirmi',        'num2tr';
is N  21, 'yirmi bir',    'num2tr';
is N  22, 'yirmi iki',    'num2tr';
is N  23, 'yirmi üç',     'num2tr';
is N  24, 'yirmi dört',   'num2tr';
is N  25, 'yirmi beş',    'num2tr';
is N  26, 'yirmi altı',   'num2tr';
is N  27, 'yirmi yedi',   'num2tr';
is N  28, 'yirmi sekiz',  'num2tr';
is N  29, 'yirmi dokuz',  'num2tr';
is N  30, 'otuz',         'num2tr';
is N  99, 'doksan dokuz', 'num2tr';

is N  103,        'yüz üç',                               'num2tr';
is N  139,        'yüz otuz dokuz',                       'num2tr';

is O(133),        'yüz otuz üçüncü',                      'num2tr_ordinal';

is N '3.14159'  , 'üç nokta bir dört bir beş dokuz',      'num2tr';
is N '-123'     , 'eksi yüz yirmi üç',                    'num2tr';
is N '+123'     , 'artı yüz yirmi üç',                    'num2tr';
is N '+123'     , 'artı yüz yirmi üç',                    'num2tr';

is N '0.0001'   , 'sıfır nokta sıfır sıfır sıfır bir',    'num2tr';
is N '-14.000'  , 'eksi on dört nokta sıfır sıfır sıfır', 'num2tr';

# and maybe even:
is N '-1.53e34' , 'eksi bir nokta beş üç çarpı on üzeri otuz dört',      'num2tr';
is N '-1.53e-34', 'eksi bir nokta beş üç çarpı on üzeri eksi otuz dört', 'num2tr';
is N '+19e009'  , 'artı on dokuz çarpı on üzeri dokuz',                  'num2tr';

is N '263415'   , 'iki yüz altmış üç bin dört yüz on beş',               'num2tr';

is N  '5001'    , 'beş bin bir',                                         'num2tr';
is N '-5001'    , 'eksi beş bin bir',                                    'num2tr';
is N '+5001'    , 'artı beş bin bir',                                    'num2tr';

is N '1,000,000' , 'bir milyon',                                         'num2tr';
is N '1,0,00,000', 'bir milyon',                                         'num2tr';

ok !defined N 'abc',                                                     'Bogus is undef';
ok !defined N '00.0.00.00.0.00.0.0',                                     'Bogus is undef';
ok !defined N '5 bananas' ,                                              'Bogus is undef';
ok !defined N 'x5x',                                                     'Bogus is undef';
ok !defined N q{},                                                       'Bogus is undef';
ok !defined N undef,                                                     'Bogus is undef';

_log "# TAMAM, bitti.\n";

sub _log {
   my @args = @_;
   print @args or die "Can not print to STDOUT: $!\n";
   return;
}

1;
