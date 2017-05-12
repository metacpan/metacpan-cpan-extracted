#!/usr/bin/perl -w

#ѕринимаем домены - тут don22200.ru - наш домен, sex.ru, trax007.ru, upanishadi.ru, air.ru - не наши, upanishadixxx21.ru - несуществующий домен, sex170004536_74323.ru - невалидный домен
#“ут получились сплошные ошибке в запросе :)
use strict;
use lib qw( . /www/srs/modules );
use Test::More;
use Data::Dumper;
use Getopt::Long;
use Time::Seconds;
use Getopt::Long;

use WebMySQLDBI();
use SRS::Utils qw( lstjoin dumper_sorted );
use SRS::Const;

use SRS::Comm::FIDSU;

# ---------------- CMDLINE -----------------

my $Type = 'UPDATE';

my $query_text = SRS::Comm::FIDSU::fidsu_flex_action(
    'UPDATE', {drtp => 1}, &ExampleStructure( $Type )
);

print 'ok!'.$query_text.'~';

exit;

sub ExampleStructure{
 my $Type = shift || 'UPDATE';
 my $Examples = {
 'UPDATE' => {
  'don22200.ru',

  'sex.ru',

  'trax007.ru',

  'upanishadi.ru',

  'upanishadixxx21.ru',

  'sex170004536_74323.ru',

  'air.ru'
  }
 };
 
 return $Examples->{$Type};
}