#!/usr/bin/perl -w

#Принимаем домены - тут don22200.ru - наш домен, sex.ru, trax007.ru, upanishadi.ru, air.ru - не наши, upanishadixxx21.ru - несуществующий домен, sex170004536_74323.ru - невалидный домен
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
  'don22200.ru' => 
qq[state: NOT DELEGATED
],

  'sex.ru' => 
qq[state: NOT DELEGATED
],

  'trax007.ru' => 
qq[state: NOT DELEGATED
],

  'upanishadi.ru' => 
qq[state: NOT DELEGATED
],

  'upanishadixxx21.ru' => 
qq[state: NOT DELEGATED
],

  'sex170004536_74323.ru' => 
qq[state: NOT DELEGATED
],

  'air.ru' => 
qq[state: NOT DELEGATED
]
  }
 };
 
 return $Examples->{$Type};
}