#!/usr/bin/perl -w

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
  'don22200.ru' => 
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

  'sex.ru' => 
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

  'trax007.ru' => 
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

  'upanishadi_xxx.ru' => 
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

  'sex17000453674323.ru' => 
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

  'air.ru' =>
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