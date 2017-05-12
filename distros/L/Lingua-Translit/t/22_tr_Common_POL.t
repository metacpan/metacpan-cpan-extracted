use strict;
use Test::More tests => 3;

my $name	=   "Common POL";

# Taken from http://www.unhchr.ch/udhr/lang/pql.htm
my $input	=   "Nie wolno ponadto czynić żadnej różnicy w zależności " .
		    "od sytuacji politycznej, prawnej lub międzynarodowej " .
		    "kraju lub obszaru, do którego dana osoba przynależy, " .
		    "bez względu na to, czy dany kraj lub obszar jest " .
		    "niepodległy, czy też podlega systemowi powiernictwa, " .
		    "nie rządzi się samodzielnie lub jest w jakikolwiek " .
		    "sposób ograniczony w swej niepodległości.";
my $output_ok	=   "Nie wolno ponadto czynic zadnej roznicy w zaleznosci " .
		    "od sytuacji politycznej, prawnej lub miedzynarodowej " .
		    "kraju lub obszaru, do ktorego dana osoba przynalezy, " .
		    "bez wzgledu na to, czy dany kraj lub obszar jest " .
		    "niepodlegly, czy tez podlega systemowi powiernictwa, " .
		    "nie rzadzi sie samodzielnie lub jest w jakikolwiek " .
		    "sposob ograniczony w swej niepodleglosci.";

my $alphabet	=   "A Ą B C Ć D E Ę F G H I J K L Ł M N Ń O Ó P R S Ś T " .
		    "U W Y Z Ź Ż " .
		    "a ą b c ć d e ę f g h i j k l ł m n ń o ó p r s ś t " .
		    "u w y z ź ż";
my $alphabet_ok =   "A A B C C D E E F G H I J K L L M N N O O P R S S T " .
		    "U W Y Z Z Z " .
		    "a a b c c d e e f g h i j k l l m n n o o p r s s t " .
		    "u w y z z z";

use Lingua::Translit;

my $tr = new Lingua::Translit($name);


my $output = $tr->translit($input);

# 1
is($tr->can_reverse(), 0, "$name: not reversible");

# 2
is($output, $output_ok, "$name: UDOHR transliteration");

my $o = $tr->translit($alphabet);

# 3
is($o, $alphabet_ok, "$name: alphabet");

# vim: sts=4
