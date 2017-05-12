package Lingua::PT::Speaker::Numbers;

use Text::RewriteRules;

use strict;
our %letra;
our %mat;
use utf8;
our %fixnum;

BEGIN {
  %letra = (
	    a=>"á",
	    b=>"bê",
	    c=>"cê",
	    d=>"dê",
	    e=>"é",
	    f=>"éfe",
	    g=>"guê",
	    h=>"agá",
	    i=>"í",
	    j=>"jóta",
	    k=>"kápa",
	    l=>"éle",
	    m=>"éme",
	    n=>"éne",
	    o=>"ó",
	    p=>"pê",
            'π' => ' pi ',
	    q=>"quê",
	    r=>"érre",
	    s=>"ésse",
	    t=>"tê",
	    u=>"ú",
	    v=>"vê",
	    w=>"dablew",
	    x=>"xís",
	    y=>"ípslon",
	    z=>"zê",

	    '~' =>" til ",
	    ':' =>" dois pontos ",
	    '-' =>" ífen ",
	    '_' =>" sublinhado ",
	    '/' =>" barra ",
	    '=' => ' igual ',
	    '*' => ' asterisco ',
	    '<' => ' menor ',
	    '>' => ' maior ',
	    '|' => ' barra ',
	    '#' => ' cardinal ',
            '%' => ' prcento ',
	    "\cM" => ' nova página ',
	   );

  %mat = (
	    '~' =>" til ",
	    ':' =>" dois pontos ",
	    '-' =>" menos ",
	    '_' =>" sublinhado ",
	    '/' =>" sobre ",
	    '$' =>" dólar ",
	    '=' => ' é igual a ',
	    '=>' => ', implica ',
	    '<=>' => ', equivale a ',
	    '^' => ' elevado a ',
	    '/\\' => ' ii ',
	    '\/' => ', ouu ',
	    '+' => ' mais ',
	    '*' => ' vezes ',
	    '<' => ', menor ',
	    '{' => 'abre chaveta, ',
	    '}' => 'fecha chaveta, ',
	    '>' => ', maior ',
            '>=' => ' maior ou igual ',
            '<=' => ' menor ou igual ',
            '+-' =>"mais ou menos ",
            '±' => "mais ou menos ",
	    '|' => ' barra ',
	    '!' => ' factorial ',
            '%' => ' precento ',
	    '#' => ' cardinal de ',
            '²' => ' ao quadrado ',
            '³' => ' ao quadrado ',
            '∈' => ' pertence a ',
            '≠' => ' diferente de ',
            'π' => ' pi ',
	   );

  %fixnum=(
   0=> "zero", 1=> "um", 2=> "dois", 3=> "três", 4=> "quatro", 5=> "cinco",
   6=> "seis", 7=> "sete", 8=> "oito", 9=> "nove", 10=> "dez",

   11=> "onze", 12=> "doze", 13=> "treze", 14=> "catorze", 15=> "quinze",
   16=> "dezasseis", 17=> "dezassete", 18=> "dezoito", 19=> "dezanove",

   20=> "vinte", 30=> "trinta", 40=> "quarenta", 50=> "cinquenta",
   60=> "sessenta", 70=> "setenta", 80=> "oitenta", 90=> "noventa",

   100=> "cem", 200=> "duzentos", 300=> "trezentos", 400=> "quatrocentos",
   500=> "quinhentos", 600=> "seiscentos", 700=> "setecentos",
   800=> "oitocentos", 900=> "novecentos",

   1000=> "mil", 1000000=> "um milhão",
  );

}

RULES/m email
\n==>
\.==> ponto 
\@==> arroba 
:\/\/==> doispontos barra barra 
:==> doispontos 
(net)\b==> néte 
(www)\b==> dablidablidabliw 
(http)\b==> agátêtêpê 
(com)\b==> cóme 
(org)\b==> órg 
#([a-zA-Z]{1,3}?)\b=e=>join("",map {$letra{lc($_)}} split(//,$1)).", "
([a-zA-Z]{1,3}?)\b=e=>" ".sigla($1). " "
(.+?)\b==>$1 
ENDRULES

RULES/m acron
e(?=[nm])==>ê
a==>á
e==>é
i==>í
o==>ó
u==>ú
ENDRULES

RULES/m sigla
([a-zA-Z])=e=>$letra{lc($1)} || " $1 "
ENDRULES

RULES/m math
\(\s*(\d+)\s*\)==> $1 
\(\s*(\w)\s*\)==> $letra{$1} 
\(==> abre , 
\)==> , fecha 

([a-z])(?=\(\s*(\w+)\s*\))==> $letra{$1} de
([a-z])(?=\(\s*\w+\s*(,\s*\w+\s*)*\))==> $letra{$1} de,
#([a-z])\s+(?=\s*\()==> $letra{$1} vezes
(\d+)(?=\s*\()==> $1 vezes

(\d+\/\d)\b=e=>number($1)
(\d+)\/(\d+)==> $1 sobre $2
(\w+)\/(\d+)==> $letra{$1} sobre $2
(\d+)\/(\w+)==> $1 sobre $letra{$2}
(\w+)\/(\w+)==> $letra{$1} sobre $letra{$2}

([a-z])\s+2\b==> $letra{$1} ao quadrado
([a-z])\s+3\b==> $letra{$1} ao cubo
([a-z])\s+(\d)\b==> $letra{$1} à $2ª
\^\s*2\b==> $letra{$1} ao quadrado
\^\s*3\b==> $letra{$1} ao cubo
\^\s*(\d)\b==> $letra{$1} à $2ª
\^\s*(\d+)\b==> $letra{$1} elevado a $2

(\d+)\s+2\b==> $1 ao quadrado
(\d+)\s+3\b==> $1 ao cubo
(\d+)\s+(\d)\b==> $1 à $2ª

sqrt\((\w|\d+)\s*\)==> reiís de $1
sqrt\b==> reiís de
cbrt\b==> reiís cúbica de
sqrt(\d+)\b==> reiís $1ª de

([a-z])(?=[²³0-9]+)==> $letra{$1} 

([^\w\s]+)==> $mat{$1} !! defined $mat{$1}
([²³π])==> $mat{$1} !! defined $mat{$1}
([a-z])\b==> $letra{$1} 

log\b==>logaritmo de 
log10\b==>logaritmo base 10 de 
exp\b==>exponencial de 

cos\b==>cosseno de
s[ie]n\b==>seno de
tg\b==>tangente de 
tgh\b==>tangente hiperbólica de 
sinh\b==>seno hiperbólico de 
cosh\b==>cosseno hiperbólico de 

mod\b==>módulo de 
rand\d==>randome de
([a-zA-Z]+)==>$1

ENDRULES


RULES/m nontext
(\w)-(\w)==>$1 $2
([\-*=<>#\|\~_/\cM:%])=e=>" $letra{$1} "
ENDRULES

RULES number
(\d+)[Ee](-?\d+)==>$1 vezes 10 levantado a $2
-(\d+)==>menos $1
(\d+)\s*\%==>$1 por cento

(\d+)\.(0\d+)\b==>$1 ponto __digs$2.
(\d+)\.(\d{1,3})\b==>$1 ponto $2
(\d+)\.(\d+)==>$1 ponto __digs$2.
__digs(\d+)\.=e=>join(" ",split(//,$1))

#Fracções
\b1/2\b==>um meio 
\b1/3\b==>um terço 
\b1/([4-9])\b=e=>"um ". ordinais("$1º") ." "
\b(\d)/2\b==>$1 meios 
\b(\d)/3\b==>$1 terços 
\b(\d)/([4-9])\b=e=>"$1 ". ordinais("$2º") . "s "

\b(\d+)\b==>$fixnum{$1}!!defined $fixnum{$1}

(\d+)(000000)\b==>$1 milhões
(\d+)(000)(\d{3})==>$1 milhão e $3!!     $1 == 1
(\d+)(\d{3})(000)==>$1 milhão e $2 mil!! $1 == 1
(\d+)(\d{6})==>$1 milhão, $2!!           $1 == 1
(\d+)(000)(\d{3})==>$1 milhões e $3
(\d+)(\d{3})(000)==>$1 milhões e $2 mil
(\d+)(\d{6})==>$1 milhões, $2

(\d+)(000)\b==>$1 mil
(\d+)0(\d{2})==>mil e $2!!               $1 == 1
(\d+)(\d00)==>mil e $2!!                 $1 == 1
(\d+)(\d{3})==>mil $2!!                  $1 == 1
(\d+)0(\d{2})==>$1 mil e $2
(\d+)(\d00)==>$1 mil e $2
(\d+)(\d{3})==>$1 mil, $2

1(\d\d)==>cento e $1
0(\d\d)==>$1
(\d)(\d\d)==>${1}00 e $2
0(\d)==>$1
(\d)(\d)==>${1}0 e $2
0$==>zero
0==>
  ==> 
 ,==>,
ENDRULES

RULES ordinais
(\d)\.([ºª])==>$1$2
\b1000000º==>milionésimo
\b1000000ª==>milionésima
\b1000º==>milésimo
\b1000ª==>milésima 

([2-9]\d\d)([ºª])==>$1 $2

\b1(\d\d\d)([ºª])==>1000$2 $1$2

(\d\d\d\d)([ºª])==>$1 $2

100º==>centésimo
200º==>ducentésimo
300º==>tricentésimo
400º==>quadrigentésimo
500º==>quingentésimo
600º==>sexcentésimo
700º==>septingentésimo
800º==>octingentésimo
900º==>nongentésimo

100ª==>centésima 
200º==>ducentésima
300º==>tricentésima
400º==>quadrigentésima
500º==>quingentésima
600º==>sexcentésima
700º==>septingentésima
800º==>octingentésima
900º==>nongentésima

(\d)(\d)(\d)º==>${1}00º ${2}0º ${3}º
(\d)(\d)(\d)ª==>${1}00ª ${2}0ª ${3}ª

10º==>décimo
20º==>vigésimo
30º==>trigésimo
40º==>quadragésimo
50º==>quinquagésimo
60º==>sexagésimo
70º==>septuagésimo
80º==>octogésimo
90º==>nonagésimo

10ª==>décima 
20ª==>vigésima 
30ª==>trigésima 
40ª==>quadragésima 
50ª==>quinquagésima 
60ª==>sexagésima 
70ª==>septuagésima 
80ª==>octogésima 
90ª==>nonagésima 
(\d)(\d)º==>${1}0º $2º
(\d)(\d)ª==>${1}0ª $2ª

1º==>primeiro 
2º==>segundo 
3º==>terceiro 
4º==>quarto 
5º==>quinto 
6º==>sexto 
7º==>sétimo 
8º==>oitavo 
9º==>nono 
º==> ésimo

1ª==>primeira 
2ª==>segunda 
3ª==>terceira 
4ª==>quarta 
5ª==>quinta 
6ª==>sexta 
7ª==>sétima 
8ª==>oitava 
9ª==>nona 
ª==> ésima  

  ==> 
ENDRULES

1;
