#!/usr/bin/perl -w
#Тут sex.ru - не наш домен, upanishadi.ru - невалидное мыло, trax.ru - невалидная дата, air_23.ru - невалидное имя домена, don2000-1.ru - домен не существует, sex170004536743.ru - смена NOT DELEGATED на DELEGATED
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
  'don2000-1.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya1 I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

  'sex.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya1 I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

  'trax.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya1 I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: дата
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

  'upanishadi.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya1 I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: мыло],

  'sex170004536743.ru' => 
qq[type: corporate
state: DELEGATED
person: Iliya1 I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

  'air_23.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru]
  }
 };
 
 return $Examples->{$Type};
}