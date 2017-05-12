use strict;
use Test::More tests => 7;

my $name        =   "GOST 7.79 UKR";
my $reversible  =   1;

# Taken from http://www.ohchr.org/EN/UDHR/Pages/Language.aspx?LangID=ukr
my $input       =   "№1 " .
                    "Всі люди народжуються вільними і рівними у своїй " .
                    "гідності та правах. Вони наділені розумом і совістю " .
                    "і повинні діяти у відношенні один до одного в дусі " .
                    "братерства.";
my $output_ok   =   "#1 " .
                    "Vsi lyudy` narodzhuyut`sya vil`ny`my` i rivny`my` u " .
                    "svoyij gidnosti ta pravax. Vony` nadileni rozumom i " .
                    "sovistyu i povy`nni diyaty` u vidnoshenni ody`n do " .
                    "odnogo v dusi braterstva.";

my $context     =   "вдаватиця - Націй - співробітництві - цих";
my $context_ok  =   "vdavaty`cya - Nacij - spivrobitny`cztvi - cy`x";

my $reverse     =   "справедливості - Ємних Їх Прав - щоб людина - " .
                    "між - ґудзик - Націй - співробітництві - членам - " .
                    "проголошено - становища - людина - визнання";
my $reverse_ok  =   "spravedly`vosti - Yemny`x Yix Prav - shhob " .
                    "lyudy`na - mizh - g`udzy`k - Nacij - " .
                    "spivrobitny`cztvi - chlenam - progolosheno - " .
                    "stanovy`shha - lyudy`na - vy`znannya";


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
