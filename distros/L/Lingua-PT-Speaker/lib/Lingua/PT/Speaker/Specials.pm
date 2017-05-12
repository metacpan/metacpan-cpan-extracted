package Lingua::PT::Speaker::Specials;

use strict;

use Text::RewriteRules;

my %sotaques=(
  porto     => {txt => \&porto,
                pho => \&phoporto},
  viseu     => {pho => \&viseu},
  cebolinha => {txt => \&cebolinha},
  spain     => {txt => \&spain,
                pho => \&phospain},
  lamego    => {txt => \&lamego},
);

sub phospecials{  
 my ($sotaq,$t)=@_;
 print "PHO special ($sotaq)\n";
 if(defined($sotaques{$sotaq}{pho})){  &{$sotaques{$sotaq}{pho}}($t)}
 else {$t}; 
}

sub txtspecials{  
 my ($sotaq,$t)=@_;
 if(defined($sotaques{$sotaq}{txt})){&{$sotaques{$sotaq}{txt}}($t)}
 else {$t}; 
}

RULES cebolinha

rr==>r
r==>l

ENDRULES

RULES porto

oão==>uounhe
ão==>ounhe
am==>oum
em\b==>éinhee
v==>b

ENDRULES

RULES phoporto

o:? r==>u 6 r

ENDRULES

RULES lamego

ch([aeiou])==>tx$1
\bx([aeiou])==>tx$1

ENDRULES

RULES/m viseu

v==>b
s==>S
z==>Z
S==>Z
([^vszS]+)==>$1

ENDRULES

RULES/m spain

^o\b==>éle
\bj==>r
ção==>ción
ções==>cións
v==>b

ENDRULES

RULES phospain

6==>a
@==>E

ENDRULES

1;
