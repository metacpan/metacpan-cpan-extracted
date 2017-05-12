use strict;
use Test::More tests => 4;

my $name        =   "GOST 7.79 RUS OLD";
my $reversible  =   0;

# Taken from http://www.ohchr.org/EN/UDHR/Pages/Language.aspx?LangID=rus
my $input       =   "№1 " .
                    "Все люди рождаются свободными и равными в своем " .
                    "достоинстве и правах. Они наделены разумом и " .
                    "совестью и должны поступать в отношении друг друга " .
                    "в духе братства.";
my $output_ok   =   "#1 " .
                    "Vse lyudi rozhdayutsya svobodny'mi i ravny'mi v " .
                    "svoem dostoinstve i pravax. Oni nadeleny' razumom i " .
                    "sovest`yu i dolzhny' postupat` v otnoshenii drug " .
                    "druga v duxe bratstva.";

my $context     =   "публикация - Властелин колец - Царства - " .
                    "ЦИК СССР - " .
                    "ЯЗЫК - ВООБЩЕ - вообще - Частной переписке";
my $context_ok  =   "publikaciya - Vlastelin kolecz - Czarstva - " .
                    "CIK SSSR - YAZY'K - VOOBSHHE - voobshhe - Chastnoj " .
                    "perepiske";

my $old         =   "сентябрѣ - міръ - Царь Ѳеодоръ - мѵро - сѵнодъ - " .
                    "типографіи - МОСКОВІЯ - далекій"; 
my $old_ok      =   "sentyabrye - mi'r`` - Czar` Fheodor`` - myhro - " .
                    "syhnod`` - tipografii - MOSKOVIYA - daleki'j";


use Lingua::Translit;

my $tr = new Lingua::Translit($name);


my $output = $tr->translit($input);

# 1
is($tr->can_reverse(), $reversible, "$name: reversibility");

# 2
is($output, $output_ok, "$name: UDOHR");

$output = $tr->translit($context);

# 3
is($output, $context_ok, "$name: context-sensitive");

$output = $tr->translit($old);

# 4
is($output, $old_ok, "$name: Old Russian");


# vim: sts=4 sw=4 ai et
