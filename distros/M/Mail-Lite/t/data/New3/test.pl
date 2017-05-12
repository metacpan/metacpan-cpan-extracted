#!/usr/bin/perl -w

#Все домены новые, только их 22 в пакете, кстати, получается 21 домен в заявке возможен
#повторная попытка этот же скрипт, т.е. все ошибки 20080724155915.156998:TESTREGRU2-REG-RIPN:TC-RIPN:0.ANS:0
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

my $Type = 'NEW';

my $query_text = SRS::Comm::FIDSU::fidsu_flex_action(
    'NEW', {drtp => 1}, &ExampleStructure( $Type )
);

print 'ok!'.$query_text.'~';

exit;

sub ExampleStructure{
 my $Type = shift || 'NEW';
 my $Examples = {
 'NEW' => {
  'oretest1.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

  'oretest2.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

'oretest3.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

'oretest4.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

'oretest5.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

'oretest6.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

'oretest7.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

'oretest8.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

'oretest9.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

'oretest10.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

'oretest11.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

'oretest12.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

'oretest13.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

'oretest14.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

'oretest15.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

'oretest16.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

'oretest17.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

'oretest18.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

'oretest19.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

'oretest20.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

'oretest21.ru' => 
qq[type: corporate
state: NOT DELEGATED
person: Iliya I Liss
person-r: Лисс Илья Александрович
passport: 4502096324, выдан ОВД "Даниловский" г. Москвы 01.04.2002 
birth-date: 05.03.1978
p-addr: 109208, Москва, ул. Ленинская слобода д.4, кв.3, Лисс Илья Александрович
phone: +7 9153038519
fax-no: 
e-mail: oreola\@mail.ru],

'oretest22.ru' => 
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