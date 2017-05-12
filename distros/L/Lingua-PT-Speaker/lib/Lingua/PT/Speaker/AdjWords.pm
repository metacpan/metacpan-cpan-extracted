package Lingua::PT::Speaker::AdjWords;

use Text::RewriteRules;

use strict;
our $vg;
our $con;
our $punt;

BEGIN{
  $vg='[@6EOQUaeiouwáéíóúãõâêôà]'  ;
  $con='[SJLRZdrstpsfgjklzcvbnm]' ; # consoante menos h
  $punt='[,.!?/]';
}

sub merge{my $a=shift;
  $b=a($a);
  $b=~ s/(($vg|$con|$punt)~?:?\s*)/$1 /g;
  $b;
}

RULES a

//==>/
(e|a)/\1==>/$1
6/6(?!~)==>/a
6/a==>/a
S/([a\@eA6iouOE])==>z/$1
\@/([eaoOEu])==>i/$1
\@/([\@i6])==>/$1
## u/($vg)==>w/$1

ENDRULES

1;
