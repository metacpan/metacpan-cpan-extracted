use strict;
use warnings;
use utf8;

use Test::More tests => 24;

use Lingua::Identify::CLD2 qw/:all/;

can_ok("Lingua::Identify::CLD2", "DetectLanguage");
can_ok("Lingua::Identify::CLD2", "LanguageName");
can_ok("Lingua::Identify::CLD2", "LanguageCode");
can_ok("Lingua::Identify::CLD2", "LanguageDeclaredName");

my $res;

$res = DetectLanguage("This is English text.");

is(ref($res), "HASH");
is($res->{text_bytes}, 22);
is($res->{language_name}, 'ENGLISH');
is($res->{language_code}, 'en');
cmp_ok($res->{languages}->[0]->{score}, '>', 0);
$res->{languages}->[0]->{score} = 1;
is_deeply($res->{languages}, [
    {
        'language_code' => 'en',
        'percent' => 95,
        'score' => 1
    }], "languages");

$res = DetectLanguage(
  "Dies ist ein deutscher Text und die Sprache wird korrekt erkannt!
   Das ist nicht so ganz einfach, aber das Werkzeug ist ja total super.
   Mal gucken, ob sich das also totale Falscheinschätzung herausstellt.",
);

is(ref($res), "HASH");
is($res->{text_bytes}, 201);
is($res->{language_name}, 'GERMAN');
is($res->{language_code}, 'de');
$res->{languages}->[0]->{score} = 1;
is_deeply($res->{languages}, [
    {
        'language_code' => 'de',
        'percent' => 99,
        'score' => 1
    }], "languages");

$res = DetectLanguage("Привет", {bestEffort => 1});
is($res->{language_name}, "RUSSIAN");
is($res->{language_code}, "ru");

$res = DetectLanguage("Hello world, Привет мир", {bestEffort => 1});

is($res->{language_name}, "RUSSIAN");
is($res->{language_code}, "ru");

$res->{languages}->[0]->{score} = 1;
$res->{languages}->[1]->{score} = 1;

is_deeply($res->{languages}, [
       {
         'language_code' => 'ru',
         'percent' => 58,
         'score' => 1
       },
       {
         'language_code' => 'en',
         'percent' => 36,
         'score' => 1
       }], 'languages');


# in 'full' mode this returns UNKNOWN. In 'chrome' mode it returns correct answer.
$res = DetectLanguage("При регистрации заезда гостям необходимо предъявить действительное удостоверение личности, выданное государственным органом, или паспорт.", {bestEffort=>1});
is($res->{language_code}, "ru");
is($res->{is_reliable}, 1);


# in chrome_2 this returns 'pt'. In 'full' this returns 'es'
#$res = DetectLanguage("Para garantizar la reserva deberá abonar un depósito mediante transferencia bancaria o PayPal (consulte las condiciones del hotel). Una vez efectuada la reserva, el establecimiento le facilitará las instrucciones necesarias.");
#is($res->{language_code}, "es");
#is($res->{is_reliable}, 1);

# works with a hint though
$res = DetectLanguage("Para garantizar la reserva deberá abonar un depósito mediante transferencia bancaria o PayPal
(consulte las condiciones del hotel). Una vez efectuada la reserva, el establecimiento le facilitará las instrucciones necesarias.", {language_hint=>'es'});
is($res->{language_code}, "es");
is($res->{is_reliable}, 1);
