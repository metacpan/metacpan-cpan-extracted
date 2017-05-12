use 5.006;
use strict;
use warnings;
use subs qw( _log );
use utf8;
use Test::More qw( no_plan );

BEGIN {
   use_ok('Lingua::TR::Numbers', qw(num2tr));
}

_log "# Using Lingua::TR::Numbers v$Lingua::TR::Numbers::VERSION\n";

## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

is num2tr(  0    ), 'sıfır',             'num2tr';
is num2tr( '0'   ), 'sıfır',             'num2tr';
is num2tr('-0'   ), 'eksi sıfır',        'num2tr';
is num2tr( '0.0' ), 'sıfır nokta sıfır', 'num2tr';
is num2tr(  '.0' ), 'nokta sıfır',       'num2tr';
is num2tr(  1    ), 'bir',               'num2tr';
is num2tr(  2    ), 'iki',               'num2tr';
is num2tr(  3    ), 'üç',                'num2tr';
is num2tr(  4    ), 'dört',              'num2tr';
is num2tr( 40    ), 'kırk',              'num2tr';
is num2tr( 42    ), 'kırk iki',          'num2tr';
is num2tr(400    ), 'dört yüz',          'num2tr';
is num2tr( '0.1' ), 'sıfır nokta bir',   'num2tr';
is num2tr(  '.1' ), 'nokta bir',         'num2tr';
is num2tr(  '.01'), 'nokta sıfır bir',   'num2tr';
is num2tr('4003' ), 'dört bin üç',       'num2tr';

_log "# TAMAM, bitti.\n";

sub _log {
   my @args = @_;
   print @args or die "Can not print to STDOUT: $!\n";
   return;
}

1;
