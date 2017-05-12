package Lingua::PT::Speaker::Prosody;

use Text::RewriteRules;

use strict;
our %dur;
our %durac;
our %tra;
our ($vg,$con,$translateit);

BEGIN{
%dur = (
	#Vogais e semivogais

        'a', '100',
        '6', '80', # mim
        '6~', '108',

        'e', '100',
        'e~', '100',
        'E', '100',
        '@', '30',

        'i', '60',
        'i~', '80',
        'j', '40',
        'j~', '40', # = i~ mais curto

        'o', '70',
        'ô', '70',
        'o~', '80',
        'O', '90',

        'U', '50',  # = u mais curto...
        'U~', '50', # = u~ mas mais curto...
        'u', '70',
        'u~', '80',
        'w','30',
        'w~', '50',

	#consoantes

        'J', '60',
        'L', '105',
        'Q', '10',
        'R', '120',
        'S', '60',
        'Z', '60',
        'b', '60',
        'd', '60',
        'f', '100',
        'g', '50',
        'k', '100',
        'l', '80',
        'm', '70',
        'n', '80',
        'p', '100',
        'r', '50',
        's', '110',
        't', '85',
        'v', '60',
        'z', '60',
       );

%durac = (
	  'a', '108',
	  '6~', '108',
	  '6', '108',

	  'e', '108',
	  'e~', '108',
	  'E', '108',
	  '@', '30',

	  'i', '66',
	  'i~', '100',

	  'o', '88',
	  'ô', '88',
	  'o~', '88',
	  'O', '108',

	  'u', '96',
	  'u~', '100',
	 );

%tra=(
      'U~' => 'u~',
      'w~' => 'u~',
      'j~' => 'i~',
      'U' => 'u',
      'ô' => 'o',
     );

$vg = '[6AEOIQUaeiouwáéíóúãõâêôàj\@]~?'  ;
$con = '[SJLRZdrstpsfgklzcvbnm]' ; # consoante menos h
$translateit = join('|',(map {quotemeta($_)} keys %tra));

}

RULES a

=b=> $_ = "=Arranque$_ "; s/  / /g;

($vg|$con)=Sub=Sup==>\n$1-dur=$durac{$1}-30-80-80-190!! defined $durac{$1}
($vg|$con)=Sup==>\n$1-dur=$durac{$1}-80-190!!           defined $durac{$1}
($vg|$con)=Sub==>\n$1-dur=$durac{$1}-10-100-30-80!!     defined $durac{$1}

($vg|$con)=Sub=Sup==>\n$1-dur=100-30-80-80-190!!      ! defined $durac{$1}
($vg|$con)=Sup==>\n$1-dur=100-80-190!!                ! defined $durac{$1}
($vg|$con)=Sub==>\n$1-dur=100-10-100-30-80!!          ! defined $durac{$1}


($vg): \? ==>$1=Sub=Sup=Pausa500
($vg): ($vg) \? ==>$1=Sub $2=Sup=Pausa500
($vg): ($con) ($vg) \? ==>$1=Sub $2 $3=Sup=Pausa500
($vg): ($con) ($vg) ($con) \? ==>$1=Sub $2 $3=Sup $4 =Pausa500
($vg): ($vg) ($con) ($vg) \? ==>$1=Sub $2 $3 $4=Sup=Pausa500
($vg): ($vg) ($con) ($con) ($vg) \? ==>$1=Sub $2 $3 $4 $5=Sup=Pausa500
($vg): ($vg) ($vg) ($con) \? ==>$1=Sub $2 $3=Sup $4 =Pausa500
($vg) ($con) \? ==>$1=Sup $2 =Pausa500

\? ==> =Pausa500

($vg)=Acen==>\n$1-dur=$durac{$1}-30-130!! defined $durac{$1}
($vg)=Acen==>\n$1-dur=100-30-130!! ! defined $durac{$1}

($vg): ==>$1=Acen

/ ($con|$vg) ==>\n$1-dur=$dur{$1}-0-100!! defined $dur{$1}
/ ($con|$vg) ==>\n$1-dur=100-0-100!! ! defined $dur{$1}

($con|$vg) ==>\n$1-dur=$dur{$1} !! defined $dur{$1}
($con|$vg) ==>\n$1-dur=100 !! ! defined $dur{$1}

\.==>-80-90=Pausa450
\;==>-80-90=Pausa350
\,==>-90-100=Pausa300
\!==>-50-100=Pausa500
\?==>=Sup=Pausa500
=Arranque==>\n_	100	20   100

($translateit)-==>$tra{$1}	!! defined $tra{$1}

=Sub==>-31-80
=Sup==>-81-190

\n($vg|$con|_)\s+(\d+)(.*?)=Pausa\s*(\d+)=e=>"\n$1	" .(100+$2). "$3\n_ $4	90 90"

-==>	
dur===>
/==>

=Pausa\s*(\d+)==>"\n_ $1	90 90"

ENDRULES

1;
