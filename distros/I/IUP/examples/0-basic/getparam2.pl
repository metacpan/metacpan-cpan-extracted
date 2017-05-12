# IUP->GetParam example (used for screenshot - IUP.pod)

use strict;
use warnings;

use IUP ':all';
my ($ret, $b, $i, $a, $s, $l, $f, $c) = IUP->GetParam(
  "Simple Dialog Title", undef,
  #define dialog controls
  "Boolean: %b[No,Yes]{Boolean Tip}\n".
  "Integer: %i[0,255]{Integer Tip 2}\n".
  "Angle: %a[0,360]{Angle Tip}\n".
  "String: %s{String Tip}\n".
  "List: %l|item1|item2|item3|{List Tip}\n".
  "File: %f[OPEN|*.bmp;*.jpg|CURRENT|NO|NO]{File Tip}\n".
  "Color: %c{Color Tip}\n",
  #set default values
  1, 100, 45, 'test string', 2, 'test.jpg', '255 0 128'
);

IUP->Message("Results",
  "Boolean:\t$b\n".
  "Integer:\t$i\n".
  "Angle:\t$a\n".
  "String:\t$s\n".
  "List Index:\t$l\n".
  "File:\t$f\n".
  "Color:\t$c\n"
) if $ret;
