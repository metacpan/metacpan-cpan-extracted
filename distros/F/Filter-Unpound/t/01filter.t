#!/usr/bin/env perl -w

use Test::More "no_plan";
use strict;

is(qx"$^X t/samplecode.pl",
   <<'EEOOFF', "no unpounding.");
Begin.
Always.
Text with #line# and #inline# stuff.
Maybe dangerous with #danger58> in v5.8
All Done.
EEOOFF
;
    
if ($]>=5.010) {


    is(qx"$^X -MFilter::Unpound=line t/samplecode.pl",
       <<'EEOOFF', "unpound line");
Begin.
. 'line'
. Auto-print > 'line'

. Auto-print #> 'line'; (var)

Always.
Text with #line# and #inline# stuff.
. For 'line' _or_ 'inline'
Maybe dangerous with #danger58> in v5.8
All Done.
EEOOFF
    ;


is(qx"$^X -MFilter::Unpound=inline t/samplecode.pl",
   <<'EEOOFF', "unpound inline");
Begin.
Always.
. 'inline'
Text with #line# and #inline# stuff.
. For 'line' _or_ 'inline'
Maybe dangerous with #danger58> in v5.8
All Done.
EEOOFF
    ;


is(qx"$^X -MFilter::Unpound=line,inline t/samplecode.pl",
   <<'EEOOFF', "unpound line and inline");
Begin.
. 'line'
. Auto-print > 'line'

. Auto-print #> 'line'; (var)

Always.
. 'inline'
Text with #line# and #inline# stuff.
. For 'line' _or_ 'inline'
. For 'line' _and_ 'inline'
Maybe dangerous with #danger58> in v5.8
All Done.
EEOOFF
    ;



is(qx"$^X -MFilter::Unpound=multi t/samplecode.pl",
   <<'EEOOFF', "unpound multi");
Begin.
Always.
Text with #line# and #inline# stuff.
Maybe dangerous with #danger58> in v5.8
.. Multi-line, 'multi'
.. Treatment of ( #multi# ) depends on version.
All Done.
EEOOFF
;


is(qx"$^X -MFilter::Unpound=unmulti t/samplecode.pl",
   <<'EEOOFF', 'unpound unmulti');
Begin.
Always.
Text with #line# and #inline# stuff.
Maybe dangerous with #danger58> in v5.8

.. Multi-line, 'unmulti'
.. variable declared


.. Multi-line, 'unmulti'; undeclared.
All Done.
EEOOFF
    ;
    }

else {

    is(qx"$^X -MFilter::Unpound=line t/samplecode.pl",
       <<'EEOOFF', 'unpound line');
Begin.
. 'line'
. Auto-print > 'line'

. Auto-print #> 'line'; (var)

Always.
Text with and #inline# stuff.
. For 'line' _or_ 'inline'
Maybe dangerous with #danger58> in v5.8
All Done.
EEOOFF
    ;


is(qx"$^X -MFilter::Unpound=inline t/samplecode.pl",
   <<'EEOOFF', "unpound inline");
Begin.
Always.
. 'inline'
Text with #line# and stuff.
. For 'line' _or_ 'inline'
Maybe dangerous with #danger58> in v5.8
All Done.
EEOOFF
    ;


is(qx"$^X -MFilter::Unpound=line,inline t/samplecode.pl",
   <<'EEOOFF', "unpound line and inline");
Begin.
. 'line'
. Auto-print > 'line'

. Auto-print #> 'line'; (var)

Always.
. 'inline'
Text with and stuff.
. For 'line' _or_ 'inline'
. For 'line' _and_ 'inline'
Maybe dangerous with #danger58> in v5.8
All Done.
EEOOFF
    ;



is(qx"$^X -MFilter::Unpound=multi t/samplecode.pl",
   <<'EEOOFF', "unpound multi");
Begin.
Always.
Text with #line# and #inline# stuff.
Maybe dangerous with #danger58> in v5.8
.. Multi-line, 'multi'
.. Treatment of ( ) depends on version.
All Done.
EEOOFF
;


is(qx"$^X -MFilter::Unpound=unmulti t/samplecode.pl",
   <<'EEOOFF', 'unpound unmulti');
Begin.
Always.
Text with #line# and #inline# stuff.
Maybe dangerous with #danger58> in v5.8

.. Multi-line, 'unmulti'
.. variable declared


.. Multi-line, 'unmulti'; undeclared.
All Done.
EEOOFF
    ;

# Also test the bad stuff

is(qx"$^X -MFilter::Unpound=danger58 t/samplecode.pl",
   <<'EEOOFF', '*Bad* (but expected) v4.8 behavior');
Begin.
Always.
Text with #line# and #inline# stuff.
Maybe dangerous with print <<fFilLTereD
in v5.8
All Done.
EEOOFF
    ;

is(qx"$^X -MFilter::Unpound=danger1 t/samplecode.pl",
   <<'EEOOFF', '5.8 #danger1> test');
Begin.
Always.
Text with #line# and #inline# stuff.
Maybe dangerous with #danger58> in v5.8
. Auto, maybe dangerous with #danger1> text

All Done.
EEOOFF
    ;

# Actually should fail.

is(qx"$^X -MFilter::Unpound=danger2 t/samplecode.pl 2>&1",
   <<'EEOOFF', '(Expected) failure in 5.8');
Semicolon seems to be missing at t/samplecode.pl line 21.
syntax error at t/samplecode.pl line 23, near "fFilLTereD
"
BEGIN not safe after errors--compilation aborted at t/samplecode.pl line 25.
EEOOFF
    ;


}
