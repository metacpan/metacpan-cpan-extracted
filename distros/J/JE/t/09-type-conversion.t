#!perl -T

BEGIN { require './t/test.pl' }

use Test::More tests => 301;
use strict;
use utf8;

# Test 1: See if the module loads
BEGIN { use_ok('JE') };


my $j = new JE;


# Tests 2-3: Bind the ok and diag functions
isa_ok( $j->new_function( ok  => \&ok   ), 'JE::Object::Function' );
isa_ok( $j->new_function( diag => \&diag ), 'JE::Object::Function' );


# Run JS tests

defined $j->eval( <<'--end--' ) or die;

// ---------------------------------------------------
/* Tests 4-12: ToBoolean */

ok(!void 0 === true, 'undefined to boolean')
ok(!null  === true, 'null to boolean')
ok(!true === false, 'boolean to boolean')
ok(!0   === true,  '0 to boolean')
ok(!NaN === true,  'NaN to boolean')
ok(!1    === false, '1 to boolean')
ok(!''    === true,  'null string to boolean')
ok(!'false' === false, 'non-empty string to boolean')
ok(!{}       === false, 'object to boolean')

// ---------------------------------------------------
/* Tests 13-286: ToNumber */

ok(isNaN(+void 0), 'undefined to number')
ok(+null === 0,   'null to number')
ok(+true === 1,  'true to number')
ok(+false === 0, 'false to number')
ok(+0     === 0, 'number to number')

// string to number (ws stands for whitespace):
ok(+''                              === 0, 'empty string')
ok(+'\t  \f\v\r\n\u2028\u2029\u2002' === 0,    'ws')
ok(+' Infinity\t'                    === Infinity, 'ws Infinity ws')
ok(+'Infinity \n  '                 === Infinity,     'Infinity ws')
ok(+'Infinity'                    === Infinity,         'Infinity')
ok(+' +Infinity '              === Infinity,             'ws +Infinity ws')
ok(+'+Infinity '           === Infinity,                 '+Infinity ws')
ok(+'+Infinity'        ===  Infinity,                   '+Infinity')
ok(+' -Infinity '   === -Infinity,                    'ws -Infinity ws')
ok(+'-Infinity '  === -Infinity,                   '-Infinity ws')
ok(+'-Infinity' === -Infinity,                 '-Infinity')
ok(+' 12.34 '  === 12.34,                 'ws digits.digits ws')
ok(+'56.78 '  === 56.78,             'digits.digits ws')
ok(+'90.12'   === 90.12,         'digits.digits')
ok(+' +34.56 ' === 34.56,     'ws +digits.digits ws')
ok(+'+78.90 '  === 78.9,    '+digits.digits ws')
ok(+'+12.34'   === 12.34,  '+digits.digits')
ok(+' -56.78 ' === -56.78, 'ws -digits.digits ws')
ok(+'-90.12 ' ===  -90.12, '-digits.digits ws')
ok(+'-34.56' ===  -34.56, '-digits.digits')
ok(+' 78. ' ===  78,    'ws digits. ws')
ok(+'90. '  === 90,   'digits. ws')
ok(+'12.'   === 12,  'digits.')
ok(+' +13. ' === 13, 'ws +digits. ws')
ok(+'+45. '  === 45, '+digits. ws')
ok(+'+67.'   === 67, '+digits.')
ok(+' -89. ' === -89, 'ws -digits. ws')
ok(+'-01. ' ===  -1,  '-digits. ws')
ok(+'-23.' ===  -23, '-digits.')
ok(+' .46 ' === .46, 'ws .digits ws')
ok(+'.788 ' === .788, '.digits ws')
ok(+'.24'    === .24,   '.digits')
ok(+' +.7841 ' === .7841, 'ws +.digits ws')
ok(+'+.58 '     === .58,   '+.digits ws')
ok(+'+.58'      === .58,   '+.digits')
ok(+' -.64 '   === -.64,  'ws -.digits ws')
ok(+'-.64 '  === -.64,  '-.digits ws')
ok(+'-.64'  === -.64, '-.digits')
ok(+' 85 ' === 85,  'ws digits ws')
ok(+'85 '  === 85, 'digits ws')
ok(+'85'   === 85, 'digits')
ok(+' +85 ' === 85, 'ws +digits ws')
ok(+'+85 '  === 85, '+digits ws')
ok(+'+85'   === 85,  '+digits')
ok(+' -85 ' === -85,   'ws -digits ws')
ok(+'-85 '   === -85,     '-digits ws')
ok(+'-85'      === -85,      '-digits')
ok(+' 858.54e51 ' === 858.54e51, 'ws digits.digits e digits ws')
ok(+'858.54e51 '    === 858.54e51,  'digits.digits e digits ws')
ok(+'858.54e51'      === 858.54e51,  'digits.digits e digits')
ok(+' +858.54e51 '   === 858.54e51,  'ws +digits.digits e digits ws')
ok(+'+858.54e51 '   === 858.54e51,  '+digits.digits e digits ws')
ok(+'+858.54e51'   ===  858.54e51, '+digits.digits e digits')
ok(+' -858.54e51 ' === -858.54e51, 'ws -digits.digits e digits ws')
ok(+'-858.54e51 ' === -858.54e51, '-digits.digits e digits ws')
ok(+'-858.54e51' === -858.54e51,  '-digits.digits e digits')
ok(+' 54.e12'  === 54000000000000, 'ws digits. e digits ws')
ok(+'54.e12 '  === 54000000000000, 'digits. e digits ws')
ok(+'54.e12'   === 54000000000000, 'digits. e digits')
ok(+' +54.e12 ' === 54000000000000, 'ws +digits. e digits ws')
ok(+'+54.e12 '  === 54000000000000, '+digits. e digits ws')
ok(+'+54.e12'   === 54000000000000, '+digits. e digits')
ok(+' -54.e12 ' === -54000000000000, 'ws -digits. e digits ws')
ok(+'-54.e12 ' ===  -54000000000000, '-digits. e digits ws')
ok(+'-54.e12' ===  -54000000000000, '-digits. e digits')
ok(+' .74e3 ' === 740,            'ws .digits e digits ws')
ok(+'.74e3 '  === 740,         '.digits e digits ws')
ok(+'.74e3'   === 740,      '.digits e digits')
ok(+' +.74e3 ' === 740,   'ws +.digits e digits ws')
ok(+'+.74e3 '  === 740,  '+.digits e digits ws')
ok(+'.74e3'    === 740,  '+.digits e digits')
ok(+' -.74e3 ' === -740, 'ws -.digits e digits ws')
ok(+'-.74e3 ' === -740,  '-.digits e digits ws')
ok(+'-.74e3' === -740,   '-.digits e digits')
ok(+' 84e6' === 84000000, 'ws digits e digits ws')
ok(+'84e6 ' === 84000000, 'digits e digits ws')
ok(+'84e6'   === 84000000, 'digits e digits')
ok(+' +84e6 ' === 84000000, 'ws +digits e digits ws')
ok(+'+84e6 '  === 84000000, '+digits e digits ws')
ok(+'+84e6'   === 84000000, '+digits e digits')
ok(+' -84e6 ' === -84000000, 'ws -digits e digits ws')
ok(+'-84e6 '   === -84000000, '-digits e digits ws')
ok(+'-84e6'      === -84000000, '-digits e digits')
ok(+' 858.54e+51 ' === 858.54e51, 'ws digits.digits e+digits ws')
ok(+'858.54e+51 '   === 858.54e51, 'digits.digits e+digits ws')
ok(+'858.54e+51'    === 858.54e51, 'digits.digits e+digits')
ok(+' +858.54e+51 ' === 858.54e51, 'ws +digits.digits e+digits ws')
ok(+'+858.54e+51 '  === 858.54e51, '+digits.digits e+digits ws')
ok(+'+858.54e+51'   === 858.54e51, '+digits.digits e+digits')
ok(+' -858.54e+51 ' === -858.54e51, 'ws -digits.digits e+digits ws')
ok(+'-858.54e+51 ' ===  -858.54e51, '-digits.digits e+digits ws')
ok(+'-858.54e+51' ===  -858.54e51,   '-digits.digits e+digits')
ok(+' 54.e+12'   ===  54000000000000, 'ws digits. e+digits ws')
ok(+'54.e+12 '  ===  54000000000000,  'digits. e+digits ws')
ok(+'54.e+12'   ===  54000000000000, 'digits. e+digits')
ok(+' +54.e+12 ' === 54000000000000, 'ws +digits. e+digits ws')
ok(+'+54.e+12 '  === 54000000000000, '+digits. e+digits ws')
ok(+'+54.e+12'   === 54000000000000, '+digits. e+digits')
ok(+' -54.e+12 ' === -54000000000000, 'ws -digits. e+digits ws')
ok(+'-54.e+12 ' ===  -54000000000000, '-digits. e+digits ws')
ok(+'-54.e+12' ===  -54000000000000, '-digits. e+digits')
ok(+' .74e+3 ' ===  740,           'ws .digits e+digits ws')
ok(+'.74e+3 '  === 740,         '.digits e+digits ws')
ok(+'.74e+3'   === 740,      '.digits e+digits')
ok(+' +.74e+3 ' === 740,   'ws +.digits e+digits ws')
ok(+'+.74e+3 '  === 740,  '+.digits e+digits ws')
ok(+'.74e+3'    === 740,  '+.digits e+digits')
ok(+' -.74e+3 ' === -740, 'ws -.digits e+digits ws')
ok(+'-.74e+3 ' === -740,  '-.digits e+digits ws')
ok(+'-.74e+3' === -740,   '-.digits e+digits')
ok(+' 84e+6' === 84000000, 'ws digits e+digits ws')
ok(+'84e+6 ' === 84000000, 'digits e+digits ws')
ok(+'84e+6'   === 84000000, 'digits e+digits')
ok(+' +84e+6 ' === 84000000, 'ws +digits e+digits ws')
ok(+'+84e+6 '  === 84000000, '+digits e+digits ws')
ok(+'+84e+6'   === 84000000, '+digits e+digits')
ok(+' -84e+6 ' === -84000000, 'ws -digits e+digits ws')
ok(+'-84e+6 '   === -84000000, '-digits e+digits ws')
ok(+'-84e+6'     === -84000000,  '-digits e+digits')
ok(+' 858.54e-51 ' === 858.54e-51, 'ws digits.digits e-digits ws')
ok(+'858.54e-51 '   === 858.54e-51, 'digits.digits e-digits ws')
ok(+'858.54e-51'    === 858.54e-51, 'digits.digits e-digits')
ok(+' +858.54e-51 ' === 858.54e-51, 'ws +digits.digits e-digits ws')
ok(+'+858.54e-51 '  === 858.54e-51, '+digits.digits e-digits ws')
ok(+'+858.54e-51'   === 858.54e-51, '+digits.digits e-digits')
ok(+' -858.54e-51 ' === -858.54e-51, 'ws -digits.digits e-digits ws')
ok(+'-858.54e-51 ' ===  -858.54e-51, '-digits.digits e-digits ws')
ok(+'-858.54e-51' ===  -858.54e-51, '-digits.digits e-digits')
ok(+' 54.e-12'   === .000000000054, 'ws digits. e-digits ws')
ok(+'54.e-12 '  === .000000000054, 'digits. e-digits ws')
ok(+'54.e-12'   === .000000000054, 'digits. e-digits')
ok(+' +54.e-12 ' === .000000000054, 'ws +digits. e-digits ws')
ok(+'+54.e-12 '  === .000000000054, '+digits. e-digits ws')
ok(+'+54.e-12'   === .000000000054, '+digits. e-digits')
ok(+' -54.e-12 ' === -.000000000054, 'ws -digits. e-digits ws')
ok(+'-54.e-12 ' ===  -.000000000054, '-digits. e-digits ws')
ok(+'-54.e-12' ===  -.000000000054, '-digits. e-digits')
ok(+' .74e-3 ' === .00074,         'ws .digits e-digits ws')
ok(+'.74e-3 '  === .00074,       '.digits e-digits ws')
ok(+'.74e-3'   === .00074,     '.digits e-digits')
ok(+' +.74e-3 ' === .00074,  'ws +.digits e-digits ws')
ok(+'+.74e-3 '  === .00074, '+.digits e-digits ws')
ok(+'.74e-3'    === .00074, '+.digits e-digits')
ok(+' -.74e-3 ' === -.00074, 'ws -.digits e-digits ws')
ok(+'-.74e-3 ' === -.00074,  '-.digits e-digits ws')
ok(+'-.74e-3' === -.00074,  '-.digits e-digits')
ok(+' 84e-6' === .000084,  'ws digits e-digits ws')
ok(+'84e-6 ' === .000084,  'digits e-digits ws')
ok(+'84e-6'   === .000084, 'digits e-digits')
ok(+' +84e-6 ' === .000084, 'ws +digits e-digits ws')
ok(+'+84e-6 '  === .000084, '+digits e-digits ws')
ok(+'+84e-6'   === .000084, '+digits e-digits')
ok(+' -84e-6 ' === -.000084, 'ws -digits e-digits ws')
ok(+'-84e-6 '  === -.000084,  '-digits e-digits ws')
ok(+'-84e-6'    === -.000084,  '-digits e-digits')
ok(+' 858.54E51 ' === 858.54E51, 'ws digits.digits E digits ws')
ok(+'858.54E51 '   === 858.54E51, 'digits.digits E digits ws')
ok(+'858.54E51'    === 858.54E51, 'digits.digits E digits')
ok(+' +858.54E51 ' === 858.54E51, 'ws +digits.digits E digits ws')
ok(+'+858.54E51 ' ===  858.54E51, '+digits.digits E digits ws')
ok(+'+858.54E51'  ===  858.54E51, '+digits.digits E digits')
ok(+' -858.54E51 ' === -858.54E51, 'ws -digits.digits E digits ws')
ok(+'-858.54E51 '  === -858.54E51, '-digits.digits E digits ws')
ok(+'-858.54E51'  === -858.54E51,   '-digits.digits E digits')
ok(+' 54.E12'    === 54000000000000, 'ws digits. E digits ws')
ok(+'54.E12 '   === 54000000000000,  'digits. E digits ws')
ok(+'54.E12'    === 54000000000000, 'digits. E digits')
ok(+' +54.E12 ' === 54000000000000, 'ws +digits. E digits ws')
ok(+'+54.E12 '  === 54000000000000, '+digits. E digits ws')
ok(+'+54.E12'   === 54000000000000, '+digits. E digits')
ok(+' -54.E12 ' === -54000000000000, 'ws -digits. E digits ws')
ok(+'-54.E12 ' ===  -54000000000000, '-digits. E digits ws')
ok(+'-54.E12' ===  -54000000000000, '-digits. E digits')
ok(+' .74E3 ' === 740,            'ws .digits E digits ws')
ok(+'.74E3 '  === 740,         '.digits E digits ws')
ok(+'.74E3'   === 740,      '.digits E digits')
ok(+' +.74E3 ' === 740,   'ws +.digits E digits ws')
ok(+'+.74E3 '  === 740,  '+.digits E digits ws')
ok(+'.74E3'    === 740,  '+.digits E digits')
ok(+' -.74E3 ' === -740, 'ws -.digits E digits ws')
ok(+'-.74E3 ' === -740,  '-.digits E digits ws')
ok(+'-.74E3' === -740,   '-.digits E digits')
ok(+' 84E6' === 84000000, 'ws digits E digits ws')
ok(+'84E6 ' === 84000000, 'digits E digits ws')
ok(+'84E6'   === 84000000, 'digits E digits')
ok(+' +84E6 ' === 84000000, 'ws +digits E digits ws')
ok(+'+84E6 '  === 84000000, '+digits E digits ws')
ok(+'+84E6'   === 84000000, '+digits E digits')
ok(+' -84E6 ' === -84000000, 'ws -digits E digits ws')
ok(+'-84E6 '   === -84000000, '-digits E digits ws')
ok(+'-84E6'      === -84000000, '-digits E digits')
ok(+' 858.54E+51 ' === 858.54E51, 'ws digits.digits E+digits ws')
ok(+'858.54E+51 '   === 858.54E51, 'digits.digits E+digits ws')
ok(+'858.54E+51'    === 858.54E51, 'digits.digits E+digits')
ok(+' +858.54E+51 ' === 858.54E51, 'ws +digits.digits E+digits ws')
ok(+'+858.54E+51 '  === 858.54E51, '+digits.digits E+digits ws')
ok(+'+858.54E+51'   === 858.54E51, '+digits.digits E+digits')
ok(+' -858.54E+51 ' === -858.54E51, 'ws -digits.digits E+digits ws')
ok(+'-858.54E+51 ' ===  -858.54E51, '-digits.digits E+digits ws')
ok(+'-858.54E+51' ===  -858.54E51,   '-digits.digits E+digits')
ok(+' 54.E+12'   ===  54000000000000, 'ws digits. E+digits ws')
ok(+'54.E+12 '  ===  54000000000000,  'digits. E+digits ws')
ok(+'54.E+12'   ===  54000000000000, 'digits. E+digits')
ok(+' +54.E+12 ' === 54000000000000, 'ws +digits. E+digits ws')
ok(+'+54.E+12 '  === 54000000000000, '+digits. E+digits ws')
ok(+'+54.E+12'   === 54000000000000, '+digits. E+digits')
ok(+' -54.E+12 ' === -54000000000000, 'ws -digits. E+digits ws')
ok(+'-54.E+12 ' ===  -54000000000000, '-digits. E+digits ws')
ok(+'-54.E+12' ===  -54000000000000, '-digits. E+digits')
ok(+' .74E+3 ' ===  740,           'ws .digits E+digits ws')
ok(+'.74E+3 '  === 740,         '.digits E+digits ws')
ok(+'.74E+3'   === 740,      '.digits E+digits')
ok(+' +.74E+3 ' === 740,   'ws +.digits E+digits ws')
ok(+'+.74E+3 '  === 740,  '+.digits E+digits ws')
ok(+'.74E+3'    === 740,  '+.digits E+digits')
ok(+' -.74E+3 ' === -740, 'ws -.digits E+digits ws')
ok(+'-.74E+3 ' === -740,  '-.digits E+digits ws')
ok(+'-.74E+3' === -740,   '-.digits E+digits')
ok(+' 84E+6' === 84000000, 'ws digits E+digits ws')
ok(+'84E+6 ' === 84000000, 'digits E+digits ws')
ok(+'84E+6'   === 84000000, 'digits E+digits')
ok(+' +84E+6 ' === 84000000, 'ws +digits E+digits ws')
ok(+'+84E+6 '  === 84000000, '+digits E+digits ws')
ok(+'+84E+6'   === 84000000, '+digits E+digits')
ok(+' -84E+6 ' === -84000000, 'ws -digits E+digits ws')
ok(+'-84E+6 '   === -84000000, '-digits E+digits ws')
ok(+'-84E+6'     === -84000000,  '-digits E+digits')
ok(+' 858.54E-51 ' === 858.54E-51, 'ws digits.digits E-digits ws')
ok(+'858.54E-51 '   === 858.54E-51, 'digits.digits E-digits ws')
ok(+'858.54E-51'    === 858.54E-51, 'digits.digits E-digits')
ok(+' +858.54E-51 ' === 858.54E-51, 'ws +digits.digits E-digits ws')
ok(+'+858.54E-51 '  === 858.54E-51, '+digits.digits E-digits ws')
ok(+'+858.54E-51'   === 858.54E-51, '+digits.digits E-digits')
ok(+' -858.54E-51 ' === -858.54E-51, 'ws -digits.digits E-digits ws')
ok(+'-858.54E-51 ' ===  -858.54E-51, '-digits.digits E-digits ws')
ok(+'-858.54E-51' ===  -858.54E-51, '-digits.digits E-digits')
ok(+' 54.E-12'   === .000000000054, 'ws digits. E-digits ws')
ok(+'54.E-12 '  === .000000000054, 'digits. E-digits ws')
ok(+'54.E-12'   === .000000000054, 'digits. E-digits')
ok(+' +54.E-12 ' === .000000000054, 'ws +digits. E-digits ws')
ok(+'+54.E-12 '  === .000000000054, '+digits. E-digits ws')
ok(+'+54.E-12'   === .000000000054, '+digits. E-digits')
ok(+' -54.E-12 ' === -.000000000054, 'ws -digits. E-digits ws')
ok(+'-54.E-12 ' ===  -.000000000054, '-digits. E-digits ws')
ok(+'-54.E-12' ===  -.000000000054, '-digits. E-digits')
ok(+' .74E-3 ' === .00074,         'ws .digits E-digits ws')
ok(+'.74E-3 '  === .00074,       '.digits E-digits ws')
ok(+'.74E-3'   === .00074,    '.digits E-digits')
ok(+' +.74E-3 ' === .00074, 'ws +.digits E-digits ws')
ok(+'+.74E-3 '  === .00074, '+.digits E-digits ws')
ok(+'.74E-3'    === .00074, '+.digits E-digits')
ok(+' -.74E-3 ' === -.00074, 'ws -.digits E-digits ws')
ok(+'-.74E-3 ' === -.00074,  '-.digits E-digits ws')
ok(+'-.74E-3' === -.00074,  '-.digits E-digits')
ok(+' 84E-6' === .000084,  'ws digits E-digits ws')
ok(+'84E-6 ' === .000084,  'digits E-digits ws')
ok(+'84E-6'   === .000084, 'digits E-digits')
ok(+' +84E-6 ' === .000084, 'ws +digits E-digits ws')
ok(+'+84E-6 '  === .000084, '+digits E-digits ws')
ok(+'+84E-6'   === .000084, '+digits E-digits')
ok(+' -84E-6 ' === -.000084, 'ws -digits E-digits ws')
ok(+'-84E-6 ' === -.000084,  '-digits E-digits ws')
ok(+'-84E-6'  === -.000084,  '-digits E-digits')
ok(+' 0xdeaf ' === 0xdeaf,  'ws 0xHHH ws')
ok(+'0xDEAF '  === 0xdeaf, '0xHHH ws')
ok(+'0x1234'   === 0x1234, '0xHHH')
ok(+' 0X5678 ' === 0x5678, 'ws 0XHHH ws')
ok(+'0X9cbB '  === 0x9cbb,  '0XHHH ws')
ok(+'0XC0ffee' === 0xC0ffee, '0XHHH')

// No need to test object-->number conversion here because
// 08.06.02-internal-properties.t takes care of that.


// There is no easy way to test ToInteger et al. from JavaScript. In each
// case that the spec uses these internal functions,  however,  the imple-
// mentation differs slightly, so a test here wouldn't do any good anyway.

/*
ToInt32
Input		Output
----------------------
undefined	0
null		0
true		1
false		0
'a'		0
'3'		3
{}		0
NaN		0
+0		0
-0		0
inf		0
-inf		0
1		1
32.5		32
2147483648	-2147483648
3000000000	-1294967296
4000000000.23	-294967296
5000000000	705032704
4294967296	0
4294967298.479	2
6442450942	2147483646
6442450943.674	2147483647
6442450944	-2147483648
6442450945	-2147483647
6442450946.74	-2147483646
-1		-1
-32.5		-32
-3000000000	1294967296
-4000000000.23	294967296
-5000000000	-705032704
-4294967298.479	-2
-6442450942	-2147483646
-6442450943.674	-2147483647
-6442450944	-2147483648
-6442450945	2147483647
-6442450946.74	2147483646

ToUInt32
Input		Output
----------------------
undefined	0
null		0
true		1
false		0
'a'		0
'3'		3
{}		0
NaN		0
+0		0
-0		0
inf		0
-inf		0
1		1
32.5		32
2147483648	2147483648
3000000000	3000000000
4000000000.23	4000000000
5000000000	705032704
4294967296	0
4294967298.479	2
6442450942	2147483646
6442450943.674	2147483647
6442450944	2147483648
6442450945	2147483649
6442450946.74	2147483650
-1		4294967295
-32.5		4294967264
-3000000000	1294967296
-4000000000.23	294967296
-5000000000	3589934592
-4294967298.479	4294967294
-6442450942	2147483650
-6442450943.674	2147483649
-6442450944	2147483648
-6442450945	2147483647
-6442450946.74	2147483646
*/


// ---------------------------------------------------
/* Tests 287-295: ToString */

ok(''+void 0 === 'undefined', 'undefined to string')
ok(''+null  === 'null',      'null to string')
ok(''+true  === 'true',    'true to string')
ok(''+false === 'false',   'false to string')
ok(''+NaN    === 'NaN',     'NaN to string')
ok(''+0        === '0',       '0 to string')
ok(''+-0        === '0',       '-0 to string')
ok(''+-Infinity === '-Infinity', '-Infinity to string')
ok(''+Infinity  === 'Infinity',    'Infinity to string')
diag('TO DO: Write tests for number-to-string conversion')

// ---------------------------------------------------
/* Tests 296-301: ToObject */

Object.prototype.to_object = function() {
	return this
}

is_TypeError = false
try { undefined.to_object() }
catch(it) { it instanceof TypeError && ++is_TypeError }
ok(is_TypeError, 'undefined to object')

is_TypeError = false
try { null.to_object() }
catch(it) { it instanceof TypeError && ++is_TypeError }
ok(is_TypeError, 'null to object')

obj = true.to_object();
ok(obj instanceof Boolean && obj.valueOf() === true, 'boolean to object')

obj = 76..to_object();
ok(obj instanceof Number && obj.valueOf() === 76, 'number to object')

obj = '.7.pns'.to_object();
ok(obj instanceof String && obj.valueOf() === '.7.pns', 'string to object')

obj = {};
ok(obj.to_object() === obj, 'object to object')

--end--
