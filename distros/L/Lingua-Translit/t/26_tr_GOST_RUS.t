use strict;
use Test::More tests => 7;

my $name        =   "GOST 7.79 RUS";
my $reversible  =   1;

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
                    "ЦИК СССР - ЯЗЫК - ВООБЩЕ - вообще - Частной переписке";
my $context_ok  =   "publikaciya - Vlastelin kolecz - Czarstva - " .
                    "CIK SSSR - YAZY'K - VOOBSHHE - voobshhe - Chastnoj " .
                    "perepiske";

my $reverse     =   "провозглашает настоящую Всеобщую декларацию прав " .
                    "человека в качестве задачи - цвета кожи - " .
                    "провозглашено - характера этих прав - неотъемлемых";
my $reverse_ok  =   "provozglashaet nastoyashhuyu Vseobshhuyu " .
                    "deklaraciyu prav cheloveka v kachestve zadachi - " .
                    "czveta kozhi - provozglasheno - xaraktera e`tix " .
                    "prav - neot``emlemy'x";


use Lingua::Translit;

my $tr = new Lingua::Translit($name);


my $output = $tr->translit($input);

# 1
is($tr->can_reverse(), $reversible, "$name: reversibility");


# 2
is($output, $output_ok, "$name: UDOHR");

# 3
$output = $tr->translit_reverse($output);

is($output, $input, "$name: UDOHR (reverse)");


# 4
$output = $tr->translit($context);

is($output, $context_ok, "$name: context-sensitive");

# 5
$output = $tr->translit_reverse($output);

is($output, $context, "$name: context-sensitive (reverse)");


# 6
$output = $tr->translit($reverse);

is($output, $reverse_ok, "$name: reverse");

# 7
$output = $tr->translit_reverse($output);

is($output, $reverse, "$name: reverse (reverse)");


# vim: sts=4 sw=4 ai et
