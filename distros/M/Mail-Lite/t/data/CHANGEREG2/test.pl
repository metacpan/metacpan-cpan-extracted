#!/usr/bin/perl -w
# Передача регистратору Test1
#Тут don22200.ru - наш домен, upanishadixxx.ru - наш домен, но мы его еще не приняли (т.е. фактически еще не наш) , sex.ru, trax007.ru, air.ru - не наш домен, upanishadixxx21.ru - несуществующий домен, sex170004536_74323.ru - невалидный домен
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
qq[reg-ch: TESTREGRU1-REG-RIPN 
],

  'sex.ru' => 
qq[reg-ch: TESTREGRU1-REG-RIPN 
],

  'trax007.ru' => 
qq[reg-ch: TESTREGRU21-REG-RIPN 
],

  'upanishadixxx.ru' => 
qq[reg-ch: TESTREGRU1-REG-RIPN 
],

  'upanishadixxx21.ru' => 
qq[reg-ch: TESTREGRU1-REG-RIPN 
],

  'sex170004536_74323.ru' => 
qq[reg-ch: TESTREGRU2-REG-RIPN 
],

  'air.ru' =>
qq[reg-ch: TESTREGRU3-REG-RIPN 
]
  }
 };
 
 return $Examples->{$Type};
}