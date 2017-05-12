# -*- cperl -*-
package Lingua::PT::Speaker::Words2Sampa;
use strict;
use Text::RewriteRules;

our ($vg, $con);

BEGIN{
  $vg='[@6EOQUaeiouwáéíóúãõâêôà]'  ;
  $con='[SJLRZdrstpsfgjklzcvbnmç]' ; # consoante menos h
}

#foneticos (SAMPA) S=x J=nh L=lh R=rr O=ó E=é Z=j
#auxiliares meus Q=e/3 I=i_dos_ditongos U=u_semivogal

sub run{
  my $a = shift;
  my $debug = shift || 0;
  print "\nttf:'$a'=" if $debug;
  $b=b(a($a));
  #  $b=~ s/(($vg|$con)~?:?)/$1 /g;
  print $b if $debug;
  $b;
}

RULES a

# â==>a:n
lh==>L
ch==>S
nh==>J
ñ==>J

qu(:?)(o~?[nm])==>kw$2$1
qu(:?)o==>kuO$1
qu(:?)([aáóã6]~?)==>kw$2$1
qu(:?)([eiéíê\@]~?)==>k$2$1
qu?==>k

c([Eeiéíê\@])==>ç$1

ass==>6ss
ss==>ç
^ho==>O
^o:==>O:
^h==>
ã:?o==>6~:w~
ã:?e==>6~:I~

osi==>uzi
^act==>_act
^al($con)==>_al$1
^a($con)==>6$1

rr==>R
^r==>R
([nls])r==>$1R
el$==>El
([aEei])([rl])$==>$1:$2 !! $_!~/:/

^es($con)==>iS$1
e[xS](?=[cp])==>6IS
^e([nmui])==>_e$1
^e(?![:~])==>i

g([eiéíê\@])==>Z$1
gu(:?)([eiéíê\@])==>g_$2$1

#($vg)(:?)([nm])($con)==>$1~$2$3$4
($vg)(:?)([nm])($con)==>$1~$2$4
a(:?)[nm]$==>6~$1w~
a~==>6~
O~==>o~
#õ(:?)e==>o$1ein
õ(:?)e==>o:e~I~n
[eé](:?)m$==>6~$1I~
($vg)m$==>$1~

ecç==>Eç
cç==>ç

# e(:?)Z==>6$1IZ

sZ==>j
j==>Z
ct==>t

ba==>b6
($vg)(:?)s($vg)==>$1$2z$3
esc==>esk

s([Z])==>$1
s([bdgvZzlRmnJL])==>Z$1

s($con)==>S$1
^([ie\@])x([ioae])==>iz$2
e:xo==>e:kso
exo==>ekso
#($vg)x($vg)==>$1z$2
($vg)(:?)x($vg)==>$1$2S$3

o:z$==>OS
z$==>:S
x$==>S

os$==>uS
as$==>6S
es$==>\@S
o$==>u
a$==>6
e$==>\@
a(:?)i(?!:)==>a$1I
a(:?)u==>a$1w
e(:?)i==>6$1I
e(:?)u==>e$1w
o(:?)[a6](S?)$==>o$1u6$2
o(:?)i==>o$1I
ou==>ow
u(:?)i(?!:)==>u$1I
y==>i
s$==>S

ENDRULES

RULES b

e(?![:~wIj])==>@
o(?![:~wIj])==>u
a(?![:~wIj])==>6

ç==>s
c==>k
x==>S
I==>j
h==>

à==>a:
á==>a:

é==>E:
í==>i:
ó==>O:
ú==>u:
ã==>6~:
â(~?)==>6~:
ê~==>e~:
ê(:?)n==>e~:n
ê==>e:
ô~==>o~:
ô(:?)n==>o~:n
ô==>o:
::==>:
_==>

ENDRULES

1;
