#!perl -T
do './t/jstest.pl' or die __DATA__

// ===================================================
// 15.9.2 Date()
// ===================================================

// 8 tests
thyme = Date();
peval('sleep 2');
rosemary = Date(1,2.3,45);

ok(thyme.match(/^(Sun|Mon|Tue|Wed|Thu|Fri|Sat)[ ]
                 (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[ ]
                 ([ \d]\d)\ (\d\d):(\d\d):(\d\d)\ (\d{4})
                 [ ][+-]\d{4}
               \z/x), // stolen from perl’s own tests (and modified)
	'thyme is the right format')
interval = new Date(thyme).getTimezoneOffset();
sign = interval > 0 ? '-' : '+';
interval = Math.abs(interval);
ok(thyme.substr(-5, 1) == sign &&
   (interval - interval % 60) / 60 == thyme.substr(-4,2) &&
   (interval % 60) == thyme.substring(thyme.length-2),
	'Date() time zone')
|| diag(
	'"' + thyme + '".substr(-5, 1)' + '==' + sign + '&&' +
	(interval - interval % 60) / 60 + '==' + thyme.substr(-4,2) + '&&'+
	(interval % 60) + '==' + thyme.substring(thyme.length-2)
);

ok(rosemary.match(/^(Sun|Mon|Tue|Wed|Thu|Fri|Sat)[ ]
                    (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[ ]
                    ([ \d]\d)\ (\d\d):(\d\d):(\d\d)\ (\d{4})
                    [ ][+-]\d{4}
                  \z/x),
	'rosemary is the right format')
interval = new Date(rosemary).getTimezoneOffset();
sign = interval > 0 ? '-' : '+';
interval = Math.abs(interval);
ok(rosemary.substr(-5, 1) == sign &&
   (interval - interval % 60) / 60 ==
	rosemary.substr(-4,2) &&
   (interval % 60) == rosemary.substring(rosemary.length-2),
	'time zone when Date() has args');

is(typeof thyme, 'string', 'Date() returns a string')
is(typeof rosemary, 'string', 'Date() with args returns a string')
cmp_ok( rosemary, 'ne', thyme,
	'Date() returns something different 2 secs later')
cmp_ok( Date.parse(thyme), '<', Date.parse(rosemary),
	'what it returns is a later time')

// # ~~~ need to test whether the time zone is set correctly


// ===================================================
// 15.9.3.1 new Date (2-7 args)
// ===================================================

// 18 tests

thyme = new Date(89, 4)
ok(thyme.constructor === Date, 'prototype of retval of new Date(foo,foo)')
is(Object.prototype.toString.call(thyme), '[object Date]',
	'class of new Date(foo,foo)')
is(thyme.getFullYear(), 1989, '2-digit first arg to new Date(foo,foo)')
is(thyme.getMonth(), 4, '2nd arg to new Date(foo,foo)')
is(new Date(0,3).getFullYear(), 1900, 'new Date(0,foo)')
is(new Date(99,2).getFullYear(), 1999, 'new Date(99,foo)')
is(new Date(100,3).getFullYear(), 100, 'new Date(100,foo)')
is(new Date(NaN,3).valueOf(), NaN, 'new Date(NaN, foo)')
is(new Date(2007,11,24).getDate(), 24, '3rd arg to new Date')
is(new Date(2007,11).getDate(), 1, 'implied 3rd arg to new Date')
is(new Date(2007,11,24,23).getHours(), 23, '4th arg to new Date')
is(new Date(2007,11,24).getHours(), 0, 'implied 4th arg to new Date')
is(new Date(2007,11,24,23,36).getMinutes(), 36, '5th arg to new Date')
is(new Date(2007,11,24,23).getMinutes(), 0, 'implied 5th arg to new Date')
is(new Date(2007,11,24,23,36,20).getSeconds(), 20, '6th arg to new Date')
is(new Date(2007,11,24,23,36).getSeconds(), 0,
	'implied 6th arg to new Date')
is(new Date(2007,11,24,23,36,20,865).getMilliseconds(), 865,
	'7th arg to new Date')
is(new Date(2007,11,24,23,36,20).getMilliseconds(), 0,
	'implied 7th arg to new Date')

// 11 tests (MakeDay)
is(new Date(0,NaN).valueOf(), NaN, 'new Date with NaN month')
is(new Date(0,0,NaN).valueOf(), NaN, 'new Date with nan date within month')
is(new Date(Infinity,0).valueOf(), NaN, 'new Date with inf year')
is(new Date(0,Infinity).valueOf(), NaN, 'new Date with inf month')
is(new Date(0,0,Infinity).valueOf(), NaN, 'new Date with inf mdate')
is(new Date(2007.87,0).getFullYear(), 2007, 'new Date with float year')
is(new Date(0,7.87).getMonth(), 7, 'new Date with float month')
is(new Date(0,0,27.87).getDate(), 27, 'new Date with float mdate')
is(new Date(0,0,32).getMonth(), 1, 'new Date\'s date overflow')
is(new Date(0,0,32).getDate(), 1, 'new Date\'s date overflow (again)')
is(new Date(0,85,32).getMonth(), 2, 'new Date with month out of range')

// 12 tests for MakeTime
is(new Date(0,0,1,6.5,0,0).getHours(), 6, 'new Date with float hours')
is(new Date(0,0,1,0,5.8,0).getMinutes(), 5, 'new Date with float mins')
is(new Date(0,0,1,0,5.8,7.9).getSeconds(), 7, 'new Date with float secs')
is(new Date(0,0,1,0,0,0,7.9).getMilliseconds(), 7, 'new Date w/ float ms')
is(new Date(0,0,1,26).getHours(), 2, 'new Date with hour overflow')
is(new Date(0,0,1,26).getDate(), 2, 'new Date with hour overflow (again)')
is(new Date(0,0,1,0,61).getMinutes(), 1, 'new Date w/min overflow')
is(new Date(0,0,1,0,61).getHours(), 1, 'new Date w/min overflow (again)')
is(new Date(0,0,1,0,0,65).getSeconds(), 5, 'new Date with sec overflow')
is(new Date(0,0,1,0,0,65).getMinutes(), 1, 'new Date w/sec overflow again')
is(new Date(0,0,1,0,0,0,1200).getMilliseconds(), 200,
	'new Date with ms overflow')
is(new Date(0,0,1,0,0,0,1200).getSeconds(), 1,
	'new Date with ms overflow (again)')

// 4 tests for MakeDate
is(new Date(0,0,1,Infinity).valueOf(), NaN, 'new Date with infinite hours')
is(new Date(0,0,1,0,Infinity).valueOf(), NaN, 'new Date w/infinite mins')
is(new Date(0,0,1,0,0,Infinity).valueOf(), NaN, 'new Date w/infinite secs')
is(new Date(0,0,1,0,0,0,Infinity).valueOf(), NaN, 'new Date w/infinite ms')

// 2 tests for ThymeClip
is(new Date(285619+1970,0).valueOf(), NaN,
	'new Date with year out of range')
is(new Date(1970-285619,0).valueOf(), NaN,
	'new Date with negative year out of range')

// 1 test for UTC
thyme = new Date(7,8)
is(thyme.valueOf() - Date.UTC(7,8), thyme.getTimezoneOffset() * 60000,
	'new Date(foo,foo)\'s local-->GMT conversion')

// 5 tests for type conversion
d = new Date(null,null,null,null,null,null,null)
is(+d, -2209075200000 + d.getTimezoneOffset()*60000,
	'new Date(nullx7)')
is(+new Date(void 0,void 0,void 0,void 0,void 0,void 0,void 0), NaN,
	'new Date(undefinedx7)')
d = new Date(true,true,true,true,true,true,true)
is(+d, -2174770738999 + d.getTimezoneOffset()*60000,
	'new Date(boolx7)')
d = new Date('1','1','1','1','1','1','1')
is(+d, -2174770738999 + d.getTimezoneOffset()*60000,
	'new Date(strx7)')
is(+new Date({},{},{},{},{},{},{}), NaN,
	'new Date(objx7)')

// 3 tests for edge cases
// We  used  to  cache  date+year-to-timevalue  calculations  keyed  on
// pack("ll"), but that made Infinity, 4294967295 and -1 all share the
// same entry.  So  new Date(-1,0)  would give different results after
// new Date(Infinity,0). Also, new Date() with 2 args or more couldn’t
// handle negative years or months.
new Date(Infinity,0);
is(new Date(4294967295,0).valueOf(), NaN, 'new Date(4294967295,0)')
like(new Date(-1,0), '/^Fri Jan  1 00:00:00 -001 /',
  'new Date(-1,0)')
like(new Date(-1,-1), '/^Tue Dec  1 00:00:00 -002 /',
  'new Date(-1,-1)')


// ===================================================
// 15.9.3.2 new Date (1 arg)
// ===================================================

// 10 tests

thyme = new Date(89)
ok(thyme.constructor === Date, 'prototype of retval of new Date(foo)')
is(Object.prototype.toString.call(thyme), '[object Date]',
	'class of new Date(foo)')
ok(thyme.valueOf()===89, 'value of new Date(num)')
ok(new Date(new Number(673)).valueOf()===673,
	'value of new Date(new Number)')
is(new Date(8.65e15).valueOf(), NaN, 'value of new Date(8.65e15)')
is(new Date('Wed, 28 May 268155 05:20:00 GMT').valueOf(), 8400000000000000,
	'new Date(gmt string)')
is(new Date(new String('Mon, 31 Dec 2007 17:59:32 GMT')).valueOf(),
	1199123972000, 'new Date(gmt string obj)')
is(new Date('Tue Apr 11 08:06:40 271324 -0700').getTime(),
	8500000000000000, 'new Date(c string)')
is(new Date(new String('Mon Dec 31 11:42:40 2007 -0800')).getTime(),
	1199130160000, 'new Date(c string object)')
is(+new Date('1 apr 2007 GMT'), 1175385600000,
	'new Date(str) using Date::Parse')

// 4 tests for type conversion
is(+new Date(undefined), NaN, 'new Date(undefined)')
is(+new Date(true), 1, 'new Date(bool)')
is(+new Date(null), 0, 'new Date(null)')
is(new Date({
	toString: function(){return '4 apr 2007'},
	valueOf: function(){ return '1 apr 2007' /* april fools’ */ }
}).getDate(), 4,
'new Date(foo) parses foo, not foo->primitive, when the latter is a string'
)


// ===================================================
// 15.9.3.3 new Date
// ===================================================

// 3 tests

thyme = new Date()
ok(thyme.constructor === Date, 'prototype of retval of new Date')
is(Object.prototype.toString.call(thyme), '[object Date]',
	'class of new Date()')
peval('sleep 2')
rosemary = new Date
cmp_ok(rosemary, ">", thyme,
	'new Date returns a different time 2 secs later')


// ===================================================
// 15.9.4 Date
// ===================================================

// 10 tests (boilerplate stuff for constructors)
is(typeof Date, 'function', 'typeof Object');
is(Object.prototype.toString.apply(Date), '[object Function]',
	'class of Date')
ok(Date.constructor === Function, 'Date\'s prototype')
ok(Date.length === 7, 'Date.length')
ok(!Date.propertyIsEnumerable('length'),
	'Date.length is not enumerable')
ok(!delete Date.length, 'Date.length cannot be deleted')
is((Date.length++, Date.length), 7, 'Date.length is read-only')
ok(!Date.propertyIsEnumerable('prototype'),
	'Date.prototype is not enumerable')
ok(!delete Date.prototype, 'Date.prototype cannot be deleted')
cmp_ok((Date.prototype = 24, Date.prototype), '!=', 24,
	'Date.prototype is read-only')


// ===================================================
// 15.9.4.2 Date.parse
// ===================================================

// 10 tests
method_boilerplate_tests(Date,'parse',1)

// 5 tests
ok(is_nan(Date.parse()), 'Date.parse without args')
ok(Date.parse('Wed, 28 May 268155 05:20:00 GMT') === 8400000000000000,
	'Date.parse(gmt string)')
is(Date.parse(new String('Mon, 31 Dec 2007 17:59:32 GMT')),
	1199123972000, 'Date.parse(gmt string obj)')
is(Date.parse('Tue Apr 11 08:06:40 271324 -0700'),
	8500000000000000, 'Date.parse(c string)')
is(Date.parse('1 apr 2007 GMT'), 1175385600000,
	'Date.parse(str) using Date::Parse')

// 4 tests for type conversion
is(Date.parse(null), NaN, 'Date.parse(null)')
is(Date.parse(void 0), NaN, 'Date.parse(undefined)')
is(Date.parse(true), NaN, 'Date.parse(bool)')
is(Date.parse(678), Date.parse('678'), 'Date.parse(number)')


// ===================================================
// 15.9.4.3 Date.UTC
// ===================================================

// 10 tests
method_boilerplate_tests(Date,'UTC',7)

// 12 tests
ok(is_nan(Date.UTC()), 'Date.UTC()')
ok(is_nan(Date.UTC(1)),'Date.UTC(1 arg)')
ok(Date.UTC(89,4) === 609984000000,
	'Date.UTC(foo,foo) with 2-digit first arg')
is(Date.UTC(0,3), -2201212800000, 'Date.UTC(0,foo)')
is(Date.UTC(99,2), 920246400000, 'Date.UTC(99,foo)')
is(Date.UTC(100,3), -59003683200000, 'Date.UTC(100,foo)')
is(Date.UTC(NaN,3), NaN, 'Date.UTC(NaN, foo)')
is(Date.UTC(2007,11,24), 1198454400000, 'Date.UTC(3 args)')
is(Date.UTC(2007,11,24,23), 1198537200000, 'Date.UTC(4 args)')
is(Date.UTC(2007,11,24,23,36), 1198539360000, 'Date.UTC(5 args)')
is(Date.UTC(2007,11,24,23,36,20), 1198539380000, 'Date.UTC (6 args)')
is(Date.UTC(2007,11,24,23,36,20,865), 1198539380865,
	'Date.UTC (7 args)')

// 10 tests (MakeDay)
is(Date.UTC(0,NaN), NaN, 'Date.UTC with NaN month')
is(Date.UTC(0,0,NaN), NaN, 'Date.UTC with nan date within month')
is(Date.UTC(Infinity,0), NaN, 'Date.UTC with inf year')
is(Date.UTC(0,Infinity), NaN, 'Date.UTC with inf month')
is(Date.UTC(0,0,Infinity), NaN, 'Date.UTC with inf mdate')
is(Date.UTC(2007.87,0), 1167609600000, 'Date.UTC with float year')
is(Date.UTC(0,7.87), -2190672000000, 'Date.UTC with float month')
is(Date.UTC(0,0,27.87), -2206742400000, 'Date.UTC with float mdate')
is(Date.UTC(0,0,32), -2206310400000, 'Date.UTC\'s date overflow')
is(Date.UTC(0,85,32), -1982793600000, 'Date.UTC with month out of range')

// 8 tests for MakeTime
is(Date.UTC(0,0,1,6.5,0,0), -2208967200000, 'Date.UTC with float hours')
is(Date.UTC(0,0,1,0,5.8,0), -2208988500000, 'Date.UTC with float mins')
is(Date.UTC(0,0,1,0,5.8,7.9), -2208988493000, 'Date.UTC with float secs')
is(Date.UTC(0,0,1,0,0,0,7.9), -2208988799993, 'Date.UTC w/ float ms')
is(Date.UTC(0,0,1,26), -2208895200000, 'Date.UTC with hour overflow')
is(Date.UTC(0,0,1,0,61), -2208985140000, 'Date.UTC w/min overflow')
is(Date.UTC(0,0,1,0,0,65), -2208988735000, 'Date.UTC with sec overflow')
is(Date.UTC(0,0,1,0,0,0,1200), -2208988798800,
	'Date.UTC with ms overflow')

// 4 tests for MakeDate
is(Date.UTC(0,0,1,Infinity), NaN, 'Date.UTC with infinite hours')
is(Date.UTC(0,0,1,0,Infinity), NaN, 'Date.UTC w/infinite mins')
is(Date.UTC(0,0,1,0,0,Infinity), NaN, 'Date.UTC w/infinite secs')
is(Date.UTC(0,0,1,0,0,0,Infinity), NaN, 'Date.UTC w/infinite ms')

// 2 tests for ThymeClip
is(Date.UTC(285619+1970,0), NaN,
	'Date.UTC with year out of range')
is(Date.UTC(1970-285619,0), NaN,
	'Date.UTC with negative year out of range')

// 5 tests for type conversion
is(+Date.UTC(null,null,null,null,null,null,null), -2209075200000,
	'Date.UTC(nullx7)')
is(+Date.UTC(void 0,void 0,void 0,void 0,void 0,void 0,void 0), NaN,
	'Date.UTC(undefinedx7)')
is(+Date.UTC(true,true,true,true,true,true,true), -2174770738999,
	'Date.UTC(boolx7)')
is(+Date.UTC('1','1','1','1','1','1','1'), -2174770738999,
	'Date.UTC(strx7)')
is(+Date.UTC({},{},{},{},{},{},{}), NaN,
	'Date.UTC(objx7)')


// ===================================================
// 15.9.5 Date.prototype
// ===================================================

// 3 tests
is(Object.prototype.toString.apply(Date.prototype), '[object Date]',
	'class of Date.prototype')
ok(is_nan(Date.prototype.valueOf()), 'value of Date.prototype')
peval('is shift->prototype, shift, "Date.prototype\' prototype"',
	Date.prototype, Object.prototype)

// ===================================================
// 15.9.5.1 Date.prototype.constructor
// ===================================================

// 2 tests
ok(Date.prototype.constructor === Date, 'Date.prototype.constructor')
ok(!Date.prototype.propertyIsEnumerable('constructor'),
	'Date.prototype.constructor is not enumerable')


// ===================================================
// 15.9.5.2 Date.prototype.toString
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'toString',0)

// 21 tests
match = new Date(1199275200000).toString().match(
    /^(T(?:ue|hu)|Wed) Jan  (\d) (\d\d):(\d\d):00 2008 ([+-])(\d\d)(\d\d)$/
)
ok(match && (
	match[1] == 'Tue' && match[2] == 1 && match[5] == '-' &&
		36-match[3]*60-match[4] == -match[6]*60-match[7]
	  ||
	match[1] == 'Wed' && match[2] == 2 &&
	    (match[5]+match[6])*-60-(match[5]+match[7]) +
	     match[3]*60+ +match[4]          == 720
	  ||
	match[1] == 'Thu' && match[2] == 3 && match[5] == '+' &&
		match[6]*60+ +match[7]-match[3]*60-match[4] == 720
), 'toString') || diag(new Date(1199275200000).toString())

is(new Date(2008,0,6).toString().substring(0,3), 'Sun', 'toString - Sun')
is(new Date(2008,0,7).toString().substring(0,3), 'Mon', 'toString - Mon')
is(new Date(2008,0,8).toString().substring(0,3), 'Tue', 'toString - Tue')
is(new Date(2008,0,9).toString().substring(0,3), 'Wed', 'toString - Wed')
is(new Date(2008,0,10).toString().substring(0,3), 'Thu', 'toString - Thu')
is(new Date(2008,0,11).toString().substring(0,3), 'Fri', 'toString - Fri')
is(new Date(2008,0,12).toString().substring(0,3), 'Sat', 'toString - Sat')
is(new Date(2008,0).toString().substring(4,7), 'Jan', 'toString - Jan')
is(new Date(2008,1).toString().substring(4,7), 'Feb', 'toString - Feb')
is(new Date(2008,2).toString().substring(4,7), 'Mar', 'toString - Mar')
is(new Date(2008,3).toString().substring(4,7), 'Apr', 'toString - Apr')
is(new Date(2008,4).toString().substring(4,7), 'May', 'toString - May')
is(new Date(2008,5).toString().substring(4,7), 'Jun', 'toString - Jun')
is(new Date(2008,6).toString().substring(4,7), 'Jul', 'toString - Jul')
is(new Date(2008,7).toString().substring(4,7), 'Aug', 'toString - Aug')
is(new Date(2008,8).toString().substring(4,7), 'Sep', 'toString - Sep')
is(new Date(2008,9).toString().substring(4,7), 'Oct', 'toString - Oct')
is(new Date(2008,10).toString().substring(4,7), 'Nov', 'toString - Nov')
is(new Date(2008,11).toString().substring(4,7), 'Dec', 'toString - Dec')

error = false
try{Date.prototype.toString.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'toString death')

// ===================================================
// 15.9.5.3 Date.prototype.toDateString
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'toDateString',0)

// 21 tests
match = (d = new Date(1199275200000)).toDateString().match(
    /^(T(?:ue|hu)|Wed) Jan (\d) 2008$/
)
o = d.getTimezoneOffset();
ok(match && (
	o > 720 ? match[1] == 'Tue' && match[2] == 1 :
	o > -720 ? match[1] == 'Wed' && match[2] == 2 :
	            match[1] == 'Thu' && match[2] == 3
), 'toDateString')

is(new Date(2008,0,6).toDateString().substring(0,3), 'Sun',
	'toDateString - Sun')
is(new Date(2008,0,7).toDateString().substring(0,3), 'Mon',
	'toDateString - Mon')
is(new Date(2008,0,8).toDateString().substring(0,3), 'Tue',
	'toDateString - Tue')
is(new Date(2008,0,9).toDateString().substring(0,3), 'Wed',
	'toDateString - Wed')
is(new Date(2008,0,10).toDateString().substring(0,3), 'Thu',
	'toDateString - Thu')
is(new Date(2008,0,11).toDateString().substring(0,3), 'Fri',
	'toDateString - Fri')
is(new Date(2008,0,12).toDateString().substring(0,3), 'Sat',
	'toDateString - Sat')
is(new Date(2008,0).toDateString().substring(4,7), 'Jan',
	'toDateString - Jan')
is(new Date(2008,1).toDateString().substring(4,7), 'Feb',
	'toDateString - Feb')
is(new Date(2008,2).toDateString().substring(4,7), 'Mar',
	'toDateString - Mar')
is(new Date(2008,3).toDateString().substring(4,7), 'Apr',
	'toDateString - Apr')
is(new Date(2008,4).toDateString().substring(4,7), 'May',
	'toDateString - May')
is(new Date(2008,5).toDateString().substring(4,7), 'Jun',
	'toDateString - Jun')
is(new Date(2008,6).toDateString().substring(4,7), 'Jul',
	'toDateString - Jul')
is(new Date(2008,7).toDateString().substring(4,7), 'Aug',
	'toDateString - Aug')
is(new Date(2008,8).toDateString().substring(4,7), 'Sep',
	'toDateString - Sep')
is(new Date(2008,9).toDateString().substring(4,7), 'Oct',
	'toDateString - Oct')
is(new Date(2008,10).toDateString().substring(4,7), 'Nov',
	'toDateString - Nov')
is(new Date(2008,11).toDateString().substring(4,7), 'Dec',
	'toDateString - Dec')

error = false
try{Date.prototype.toDateString.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'toDateString death')


// ===================================================
// 15.9.5.4 Date.prototype.toTimeString
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'toTimeString',0)

// 2 tests
match = (d = new Date(1199275200000)).toTimeString().match(
    /^(\d\d):(\d\d):00$/
)
t = 720-d.getTimezoneOffset();
ok(match && match[1] == (t-t%60)/60%24 && match[2] == t%60, 'toTimeString')

error = false
try{Date.prototype.toTimeString.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'toTimeString death')


// ===================================================
// 15.9.5.5 Date.prototype.toLocaleString
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'toLocaleString',0)

// 21 tests
match = new Date(1199275200000).toLocaleString().match(
    /^(T(?:ue|hu)|Wed) Jan  (\d) (\d\d):(\d\d):00 2008 ([+-])(\d\d)(\d\d)$/
)
ok(match && (
	match[1] == 'Tue' && match[2] == 1 && match[5] == '-' &&
		36-match[3]*60-match[4] == -match[6]*60-match[7]
	  ||
	match[1] == 'Wed' && match[2] == 2 &&
	    (match[5]+match[6])*-60-(match[5]+match[7]) +
	     match[3]*60+ +match[4]          == 720
	  ||
	match[1] == 'Thu' && match[2] == 3 && match[5] == '+' &&
		match[6]*60+ +match[7]-match[3]*60-match[4] == 720
), 'toLocaleString')

is(new Date(2008,0,6).toLocaleString().substring(0,3), 'Sun',
	'toLocaleString - Sun')
is(new Date(2008,0,7).toLocaleString().substring(0,3), 'Mon',
	'toLocaleString - Mon')
is(new Date(2008,0,8).toLocaleString().substring(0,3), 'Tue',
	'toLocaleString - Tue')
is(new Date(2008,0,9).toLocaleString().substring(0,3), 'Wed',
	'toLocaleString - Wed')
is(new Date(2008,0,10).toLocaleString().substring(0,3), 'Thu',
	'toLocaleString - Thu')
is(new Date(2008,0,11).toLocaleString().substring(0,3), 'Fri',
	'toLocaleString - Fri')
is(new Date(2008,0,12).toLocaleString().substring(0,3), 'Sat',
	'toLocaleString - Sat')
is(new Date(2008,0).toLocaleString().substring(4,7), 'Jan',
	'toLocaleString - Jan')
is(new Date(2008,1).toLocaleString().substring(4,7), 'Feb',
	'toLocaleString - Feb')
is(new Date(2008,2).toLocaleString().substring(4,7), 'Mar',
	'toLocaleString - Mar')
is(new Date(2008,3).toLocaleString().substring(4,7), 'Apr',
	'toLocaleString - Apr')
is(new Date(2008,4).toLocaleString().substring(4,7), 'May',
	'toLocaleString - May')
is(new Date(2008,5).toLocaleString().substring(4,7), 'Jun',
	'toLocaleString - Jun')
is(new Date(2008,6).toLocaleString().substring(4,7), 'Jul',
	'toLocaleString - Jul')
is(new Date(2008,7).toLocaleString().substring(4,7), 'Aug',
	'toLocaleString - Aug')
is(new Date(2008,8).toLocaleString().substring(4,7), 'Sep',
	'toLocaleString - Sep')
is(new Date(2008,9).toLocaleString().substring(4,7), 'Oct',
	'toLocaleString - Oct')
is(new Date(2008,10).toLocaleString().substring(4,7), 'Nov',
	'toLocaleString - Nov')
is(new Date(2008,11).toLocaleString().substring(4,7), 'Dec',
	'toLocaleString - Dec')

error = false
try{Date.prototype.toLocaleString.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'toLocaleString death')


// ===================================================
// 15.9.5.6 Date.prototype.toLocaleDateString
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'toLocaleDateString',0)

// 21 tests
match = (d = new Date(1199275200000)).toLocaleDateString().match(
    /^(T(?:ue|hu)|Wed) Jan (\d) 2008$/
)
o = d.getTimezoneOffset();
ok(match && (
	o > 720 ? match[1] == 'Tue' && match[2] == 1 :
	o > -720 ? match[1] == 'Wed' && match[2] == 2 :
	            match[1] == 'Thu' && match[2] == 3
), 'toLocaleDateString')

is(new Date(2008,0,6).toLocaleDateString().substring(0,3), 'Sun',
	'toLocaleDateString - Sun')
is(new Date(2008,0,7).toLocaleDateString().substring(0,3), 'Mon',
	'toLocaleDateString - Mon')
is(new Date(2008,0,8).toLocaleDateString().substring(0,3), 'Tue',
	'toLocaleDateString - Tue')
is(new Date(2008,0,9).toLocaleDateString().substring(0,3), 'Wed',
	'toLocaleDateString - Wed')
is(new Date(2008,0,10).toLocaleDateString().substring(0,3), 'Thu',
	'toLocaleDateString - Thu')
is(new Date(2008,0,11).toLocaleDateString().substring(0,3), 'Fri',
	'toLocaleDateString - Fri')
is(new Date(2008,0,12).toLocaleDateString().substring(0,3), 'Sat',
	'toLocaleDateString - Sat')
is(new Date(2008,0).toLocaleDateString().substring(4,7), 'Jan',
	'toLocaleDateString - Jan')
is(new Date(2008,1).toLocaleDateString().substring(4,7), 'Feb',
	'toLocaleDateString - Feb')
is(new Date(2008,2).toLocaleDateString().substring(4,7), 'Mar',
	'toLocaleDateString - Mar')
is(new Date(2008,3).toLocaleDateString().substring(4,7), 'Apr',
	'toLocaleDateString - Apr')
is(new Date(2008,4).toLocaleDateString().substring(4,7), 'May',
	'toLocaleDateString - May')
is(new Date(2008,5).toLocaleDateString().substring(4,7), 'Jun',
	'toLocaleDateString - Jun')
is(new Date(2008,6).toLocaleDateString().substring(4,7), 'Jul',
	'toLocaleDateString - Jul')
is(new Date(2008,7).toLocaleDateString().substring(4,7), 'Aug',
	'toLocaleDateString - Aug')
is(new Date(2008,8).toLocaleDateString().substring(4,7), 'Sep',
	'toLocaleDateString - Sep')
is(new Date(2008,9).toLocaleDateString().substring(4,7), 'Oct',
	'toLocaleDateString - Oct')
is(new Date(2008,10).toLocaleDateString().substring(4,7), 'Nov',
	'toLocaleDateString - Nov')
is(new Date(2008,11).toLocaleDateString().substring(4,7), 'Dec',
	'toLocaleDateString - Dec')

error = false
try{Date.prototype.toLocaleDateString.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'toLocaleDateString death')


// ===================================================
// 15.9.5.7 Date.prototype.toLocaleTimeString
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'toLocaleTimeString',0)

// 2 tests
match = (d = new Date(1199275200000)).toLocaleTimeString().match(
    /^(\d\d):(\d\d):00$/
)
t = 720-d.getTimezoneOffset();
ok(match && match[1] == (t-t%60)/60%24 && match[2] == t%60,
	'toLocaleTimeString')

error = false
try{Date.prototype.toLocaleTimeString.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'toLocaleTimeString death')


// ===================================================
// 15.9.5.8 Date.prototype.valueOf
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'valueOf',0)

// 2 tests
ok(new Date(1199275200000).valueOf() === 1199275200000,'valueOf')

error = false
try{Date.prototype.valueOf.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'valueOf death')


// ===================================================
// 15.9.5.9 Date.prototype. getTime
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getTime',0)

// 2 tests
ok(new Date(1199275200000). getTime() === 1199275200000,'getTime')

error = false
try{Date.prototype. getTime.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getTime death')


// ===================================================
// 15.9.5.10 Date.prototype. getFullYear
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getFullYear',0)

/* I hope no one changes dst on new year’s day. These tests assume that
   never happens. */

offset = new Date(new Date().getYear(), 0, 1).getTimezoneOffset() * 60000;

// 12 tests
ok(is_nan(new Date(NaN).getFullYear()), 'getFullYear (NaN)')
ok(new Date(26223868800000+offset).getFullYear() === 2801,
	'getFullYear with 1 Jan quadricentennial+1')
ok(new Date(26223868799999+offset).getFullYear() === 2800,
	'getFullYear with 1 Jan quadricentennial+1 year - 1 ms')
ok(new Date(26197387200000+offset).getFullYear()===2800,
	'getFullYear with quadricentennial leap day')
ok(new Date(23068108800000+offset).getFullYear() === 2701,
	'getFullYear - turn of the century...')
ok(new Date(23068108799999+offset).getFullYear() === 2700,
	'              ... when year % 400')
ok(new Date(1230768000000+offset).getFullYear()===2009,
	'getFullYear - first day after a leap year')
ok(new Date(1230767999999+offset).getFullYear()===2008,
	'getFullYear - last millisecond of a leap year')
ok(new Date(13827153600000+offset).getFullYear()===2408,
	'getFullYear - leap day')
ok(new Date(13632624000000+offset).getFullYear()===2402,
	'getFullYear - regular...')
ok(new Date(13632623999999+offset).getFullYear()===2401,
	'getFullYear - ...year')

error = false
try{Date.prototype. getFullYear.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getFullYear death')


// ===================================================
// 15.9.5.11 Date.prototype. getUTCFullYear
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getUTCFullYear',0)

// 12 tests
ok(is_nan(new Date(NaN).getUTCFullYear()), 'getUTCFullYear (NaN)')
ok(new Date(26223868800000).getUTCFullYear() === 2801,
	'getUTCFullYear with 1 Jan quadricentennial+1')
ok(new Date(26223868799999).getUTCFullYear() === 2800,
	'getUTCFullYear with 1 Jan quadricentennial+1 year - 1 ms')
ok(new Date(26197387200000).getUTCFullYear()===2800,
	'getUTCFullYear with quadricentennial leap day')
ok(new Date(23068108800000).getUTCFullYear() === 2701,
	'getUTCFullYear - turn of the century...')
ok(new Date(23068108799999).getUTCFullYear() === 2700,
	'              ... when year % 400')
ok(new Date(1230768000000).getUTCFullYear()===2009,
	'getUTCFullYear - first day after a leap year')
ok(new Date(1230767999999).getUTCFullYear()===2008,
	'getUTCFullYear - last millisecond of a leap year')
ok(new Date(13827153600000).getUTCFullYear()===2408,
	'getUTCFullYear - leap day')
ok(new Date(13632624000000).getUTCFullYear()===2402,
	'getUTCFullYear - regular...')
ok(new Date(13632623999999).getUTCFullYear()===2401,
	'getUTCFullYear - ...year')

error = false
try{Date.prototype. getUTCFullYear.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getUTCFullYear death')


// ===================================================
// 15.9.5.12 Date.prototype. getMonth
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getMonth',0)

offset = new Date(new Date().getYear(), 0, 1).getTimezoneOffset() * 60000;

// 50 tests
ok(is_nan(new Date(NaN).getMonth()), 'getMonth (NaN)')

ok(new Date(1199188800000 +offset).getMonth() === 0,
	'getMonth - 1 Jan in leap year')
is(new Date(1201780800000 +offset).getMonth(),  0,
	'getMonth - 31 Jan in leap year')
is(new Date(1201867200000 +offset).getMonth(),  1,
	'getMonth - 1 Feb in leap year')
is(new Date(1204286400000 +offset).getMonth(),  1,
	'getMonth - 29 Feb in leap year')
is(new Date(1204372800000 +offset).getMonth(),  2,
	'getMonth - 1 Mar in leap year')
is(new Date(1206964800000 +offset).getMonth(),  2,
	'getMonth - 31 Mar in leap year')
is(new Date(1207051200000 +offset).getMonth(),  3,
	'getMonth - 1 Apr in leap year')
is(new Date(1209556800000 +offset).getMonth(),  3,
	'getMonth - 30 Apr in leap year')
is(new Date(1209643200000 +offset).getMonth(),  4,
	'getMonth - 1 May in leap year')
is(new Date(1212235200000 +offset).getMonth(),  4,
	'getMonth - 31 May in leap year')
is(new Date(1212321600000 +offset).getMonth(),  5,
	'getMonth - 1 Jun in leap year')
is(new Date(1214827200000 +offset).getMonth(),  5,
	'getMonth - 30 Jun in leap year')
is(new Date(1214913600000 +offset).getMonth(),  6,
	'getMonth - 1 Jul in leap year')
is(new Date(1217505600000 +offset).getMonth(),  6,
	'getMonth - 31 Jul in leap year')
is(new Date(1217592000000 +offset).getMonth(),  7,
	'getMonth - 1 Aug in leap year')
is(new Date(1220184000000 +offset).getMonth(),  7,
	'getMonth - 31 Aug in leap year')
is(new Date(1220270400000 +offset).getMonth(),  8,
	'getMonth - 1 Sep in leap year')
is(new Date(1222776000000 +offset).getMonth(),  8,
	'getMonth - 30 Sep in leap year')
is(new Date(1222862400000 +offset).getMonth(),  9,
	'getMonth - 1 Oct in leap year')
is(new Date(1225454400000 +offset).getMonth(),  9,
	'getMonth - 31 Oct in leap year')
is(new Date(1225540800000 +offset).getMonth(),  10,
	'getMonth - 1 Nov in leap year')
is(new Date(1228003200000 +offset).getMonth(),  10,
	'getMonth - 30 Nov in leap year')
is(new Date(1228132800000 +offset).getMonth(),  11,
	'getMonth - 1 Dec in leap year')
is(new Date(1230724800000 +offset).getMonth(),  11,
	'getMonth - 31 Dec in leap year')

is(new Date(1230811200000 +offset).getMonth(), 0,
	'getMonth - 1 Jan in common year')
is(new Date(1233403200000 +offset).getMonth(),  0,
	'getMonth - 31 Jan in common year')
is(new Date(1233489600000 +offset).getMonth(),  1,
	'getMonth - 1 Feb in common year')
is(new Date(1235822400000 +offset).getMonth(),  1,
	'getMonth - 28 Feb in common year')
is(new Date(1235908800000 +offset).getMonth(),  2,
	'getMonth - 1 Mar in common year')
is(new Date(1238500800000 +offset).getMonth(),  2,
	'getMonth - 31 Mar in common year')
is(new Date(1238587200000 +offset).getMonth(),  3,
	'getMonth - 1 Apr in common year')
is(new Date(1241092800000 +offset).getMonth(),  3,
	'getMonth - 30 Apr in common year')
is(new Date(1241179200000 +offset).getMonth(),  4,
	'getMonth - 1 May in common year')
is(new Date(1243771200000 +offset).getMonth(),  4,
	'getMonth - 31 May in common year')
is(new Date(1243857600000 +offset).getMonth(),  5,
	'getMonth - 1 Jun in common year')
is(new Date(1246363200000 +offset).getMonth(),  5,
	'getMonth - 30 Jun in common year')
is(new Date(1246449600000 +offset).getMonth(),  6,
	'getMonth - 1 Jul in common year')
is(new Date(1249041600000 +offset).getMonth(),  6,
	'getMonth - 31 Jul in common year')
is(new Date(1249128000000 +offset).getMonth(),  7,
	'getMonth - 1 Aug in common year')
is(new Date(1251720000000 +offset).getMonth(),  7,
	'getMonth - 31 Aug in common year')
is(new Date(1251806400000 +offset).getMonth(),  8,
	'getMonth - 1 Sep in common year')
is(new Date(1254312000000 +offset).getMonth(),  8,
	'getMonth - 30 Sep in common year')
is(new Date(1254398400000 +offset).getMonth(),  9,
	'getMonth - 1 Oct in common year')
is(new Date(1256990400000 +offset).getMonth(),  9,
	'getMonth - 31 Oct in common year')
is(new Date(1257076800000 +offset).getMonth(),  10,
	'getMonth - 1 Nov in common year')
is(new Date(1259582400000 +offset).getMonth(),  10,
	'getMonth - 30 Nov in common year')
is(new Date(1259668800000 +offset).getMonth(),  11,
	'getMonth - 1 Dec in common year')
is(new Date(1262260800000 +offset).getMonth(),  11,
	'getMonth - 31 Dec in common year')

error = false
try{Date.prototype. getMonth.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getMonth death')


// ===================================================
// 15.9.5.13 Date.prototype. getUTCMonth
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getUTCMonth',0)

// 50 tests
ok(is_nan(new Date(NaN).getUTCMonth()), 'getUTCMonth (NaN)')

ok(new Date(1199188800000 ).getUTCMonth() === 0,
	'getUTCMonth - 1 Jan in leap year')
is(new Date(1201780800000 ).getUTCMonth(),  0,
	'getUTCMonth - 31 Jan in leap year')
is(new Date(1201867200000 ).getUTCMonth(),  1,
	'getUTCMonth - 1 Feb in leap year')
is(new Date(1204286400000 ).getUTCMonth(),  1,
	'getUTCMonth - 29 Feb in leap year')
is(new Date(1204372800000 ).getUTCMonth(),  2,
	'getUTCMonth - 1 Mar in leap year')
is(new Date(1206964800000 ).getUTCMonth(),  2,
	'getUTCMonth - 31 Mar in leap year')
is(new Date(1207051200000 ).getUTCMonth(),  3,
	'getUTCMonth - 1 Apr in leap year')
is(new Date(1209556800000 ).getUTCMonth(),  3,
	'getUTCMonth - 30 Apr in leap year')
is(new Date(1209643200000 ).getUTCMonth(),  4,
	'getUTCMonth - 1 May in leap year')
is(new Date(1212235200000 ).getUTCMonth(),  4,
	'getUTCMonth - 31 May in leap year')
is(new Date(1212321600000 ).getUTCMonth(),  5,
	'getUTCMonth - 1 Jun in leap year')
is(new Date(1214827200000 ).getUTCMonth(),  5,
	'getUTCMonth - 30 Jun in leap year')
is(new Date(1214913600000 ).getUTCMonth(),  6,
	'getUTCMonth - 1 Jul in leap year')
is(new Date(1217505600000 ).getUTCMonth(),  6,
	'getUTCMonth - 31 Jul in leap year')
is(new Date(1217592000000 ).getUTCMonth(),  7,
	'getUTCMonth - 1 Aug in leap year')
is(new Date(1220184000000 ).getUTCMonth(),  7,
	'getUTCMonth - 31 Aug in leap year')
is(new Date(1220270400000 ).getUTCMonth(),  8,
	'getUTCMonth - 1 Sep in leap year')
is(new Date(1222776000000 ).getUTCMonth(),  8,
	'getUTCMonth - 30 Sep in leap year')
is(new Date(1222862400000 ).getUTCMonth(),  9,
	'getUTCMonth - 1 Oct in leap year')
is(new Date(1225454400000 ).getUTCMonth(),  9,
	'getUTCMonth - 31 Oct in leap year')
is(new Date(1225540800000 ).getUTCMonth(),  10,
	'getUTCMonth - 1 Nov in leap year')
is(new Date(1228003200000 ).getUTCMonth(),  10,
	'getUTCMonth - 30 Nov in leap year')
is(new Date(1228132800000 ).getUTCMonth(),  11,
	'getUTCMonth - 1 Dec in leap year')
is(new Date(1230724800000 ).getUTCMonth(),  11,
	'getUTCMonth - 31 Dec in leap year')

is(new Date(1230811200000 ).getUTCMonth(), 0,
	'getUTCMonth - 1 Jan in common year')
is(new Date(1233403200000 ).getUTCMonth(),  0,
	'getUTCMonth - 31 Jan in common year')
is(new Date(1233489600000 ).getUTCMonth(),  1,
	'getUTCMonth - 1 Feb in common year')
is(new Date(1235822400000 ).getUTCMonth(),  1,
	'getUTCMonth - 28 Feb in common year')
is(new Date(1235908800000 ).getUTCMonth(),  2,
	'getUTCMonth - 1 Mar in common year')
is(new Date(1238500800000 ).getUTCMonth(),  2,
	'getUTCMonth - 31 Mar in common year')
is(new Date(1238587200000 ).getUTCMonth(),  3,
	'getUTCMonth - 1 Apr in common year')
is(new Date(1241092800000 ).getUTCMonth(),  3,
	'getUTCMonth - 30 Apr in common year')
is(new Date(1241179200000 ).getUTCMonth(),  4,
	'getUTCMonth - 1 May in common year')
is(new Date(1243771200000 ).getUTCMonth(),  4,
	'getUTCMonth - 31 May in common year')
is(new Date(1243857600000 ).getUTCMonth(),  5,
	'getUTCMonth - 1 Jun in common year')
is(new Date(1246363200000 ).getUTCMonth(),  5,
	'getUTCMonth - 30 Jun in common year')
is(new Date(1246449600000 ).getUTCMonth(),  6,
	'getUTCMonth - 1 Jul in common year')
is(new Date(1249041600000 ).getUTCMonth(),  6,
	'getUTCMonth - 31 Jul in common year')
is(new Date(1249128000000 ).getUTCMonth(),  7,
	'getUTCMonth - 1 Aug in common year')
is(new Date(1251720000000 ).getUTCMonth(),  7,
	'getUTCMonth - 31 Aug in common year')
is(new Date(1251806400000 ).getUTCMonth(),  8,
	'getUTCMonth - 1 Sep in common year')
is(new Date(1254312000000 ).getUTCMonth(),  8,
	'getUTCMonth - 30 Sep in common year')
is(new Date(1254398400000 ).getUTCMonth(),  9,
	'getUTCMonth - 1 Oct in common year')
is(new Date(1256990400000 ).getUTCMonth(),  9,
	'getUTCMonth - 31 Oct in common year')
is(new Date(1257076800000 ).getUTCMonth(),  10,
	'getUTCMonth - 1 Nov in common year')
is(new Date(1259582400000 ).getUTCMonth(),  10,
	'getUTCMonth - 30 Nov in common year')
is(new Date(1259668800000 ).getUTCMonth(),  11,
	'getUTCMonth - 1 Dec in common year')
is(new Date(1262260800000 ).getUTCMonth(),  11,
	'getUTCMonth - 31 Dec in common year')

error = false
try{Date.prototype. getUTCMonth.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getUTCMonth death')


// ===================================================
// 15.9.5.14 Date.prototype. getDate
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getDate',0)

offset = new Date(new Date().getYear(), 0, 1).getTimezoneOffset() * 60000;

// 50 tests
ok(is_nan(new Date(NaN).getDate()), 'getDate (NaN)')

ok(new Date(1199188800000 +offset).getDate() === 1,
	'getDate - 1 Jan in leap year')
is(new Date(1201780800000 +offset).getDate(),  31,
	'getDate - 31 Jan in leap year')
is(new Date(1201867200000 +offset).getDate(),  1,
	'getDate - 1 Feb in leap year')
is(new Date(1204286400000 +offset).getDate(),  29,
	'getDate - 29 Feb in leap year')
is(new Date(1204372800000 +offset).getDate(),  1,
	'getDate - 1 Mar in leap year')
is(new Date(1206964800000 +offset).getDate(),  31,
	'getDate - 31 Mar in leap year')
is(new Date(1207051200000 +offset).getDate(),  1,
	'getDate - 1 Apr in leap year')
is(new Date(1209556800000 +offset).getDate(),  30,
	'getDate - 30 Apr in leap year')
is(new Date(1209643200000 +offset).getDate(),  1,
	'getDate - 1 May in leap year')
is(new Date(1212235200000 +offset).getDate(),  31,
	'getDate - 31 May in leap year')
is(new Date(1212321600000 +offset).getDate(),  1,
	'getDate - 1 Jun in leap year')
is(new Date(1214827200000 +offset).getDate(),  30,
	'getDate - 30 Jun in leap year')
is(new Date(1214913600000 +offset).getDate(),  1,
	'getDate - 1 Jul in leap year')
is(new Date(1217505600000 +offset).getDate(),  31,
	'getDate - 31 Jul in leap year')
is(new Date(1217592000000 +offset).getDate(),  1,
	'getDate - 1 Aug in leap year')
is(new Date(1220184000000 +offset).getDate(),  31,
	'getDate - 31 Aug in leap year')
is(new Date(1220270400000 +offset).getDate(),  1,
	'getDate - 1 Sep in leap year')
is(new Date(1222776000000 +offset).getDate(),  30,
	'getDate - 30 Sep in leap year')
is(new Date(1222862400000 +offset).getDate(),  1,
	'getDate - 1 Oct in leap year')
is(new Date(1225454400000 +offset).getDate(),  31,
	'getDate - 31 Oct in leap year')
is(new Date(1225540800000 +offset).getDate(),  1,
	'getDate - 1 Nov in leap year')
is(new Date(1228003200000 +offset).getDate(),  30,
	'getDate - 30 Nov in leap year')
is(new Date(1228132800000 +offset).getDate(),  1,
	'getDate - 1 Dec in leap year')
is(new Date(1230724800000 +offset).getDate(),  31,
	'getDate - 31 Dec in leap year')

is(new Date(1230811200000 +offset).getDate(), 1,
	'getDate - 1 Jan in common year')
is(new Date(1233403200000 +offset).getDate(),  31,
	'getDate - 31 Jan in common year')
is(new Date(1233489600000 +offset).getDate(),  1,
	'getDate - 1 Feb in common year')
is(new Date(1235822400000 +offset).getDate(),  28,
	'getDate - 28 Feb in common year')
is(new Date(1235908800000 +offset).getDate(),  1,
	'getDate - 1 Mar in common year')
is(new Date(1238500800000 +offset).getDate(),  31,
	'getDate - 31 Mar in common year')
is(new Date(1238587200000 +offset).getDate(),  1,
	'getDate - 1 Apr in common year')
is(new Date(1241092800000 +offset).getDate(),  30,
	'getDate - 30 Apr in common year')
is(new Date(1241179200000 +offset).getDate(),  1,
	'getDate - 1 May in common year')
is(new Date(1243771200000 +offset).getDate(),  31,
	'getDate - 31 May in common year')
is(new Date(1243857600000 +offset).getDate(),  1,
	'getDate - 1 Jun in common year')
is(new Date(1246363200000 +offset).getDate(),  30,
	'getDate - 30 Jun in common year')
is(new Date(1246449600000 +offset).getDate(),  1,
	'getDate - 1 Jul in common year')
is(new Date(1249041600000 +offset).getDate(),  31,
	'getDate - 31 Jul in common year')
is(new Date(1249128000000 +offset).getDate(),  1,
	'getDate - 1 Aug in common year')
is(new Date(1251720000000 +offset).getDate(),  31,
	'getDate - 31 Aug in common year')
is(new Date(1251806400000 +offset).getDate(),  1,
	'getDate - 1 Sep in common year')
is(new Date(1254312000000 +offset).getDate(),  30,
	'getDate - 30 Sep in common year')
is(new Date(1254398400000 +offset).getDate(),  1,
	'getDate - 1 Oct in common year')
is(new Date(1256990400000 +offset).getDate(),  31,
	'getDate - 31 Oct in common year')
is(new Date(1257076800000 +offset).getDate(),  1,
	'getDate - 1 Nov in common year')
is(new Date(1259582400000 +offset).getDate(),  30,
	'getDate - 30 Nov in common year')
is(new Date(1259668800000 +offset).getDate(),  1,
	'getDate - 1 Dec in common year')
is(new Date(1262260800000 +offset).getDate(),  31,
	'getDate - 31 Dec in common year')

error = false
try{Date.prototype. getDate.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getDate death')


// ===================================================
// 15.9.5.15 Date.prototype. getUTCDate
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getUTCDate',0)

// 50 tests
ok(is_nan(new Date(NaN).getUTCDate()), 'getUTCDate (NaN)')

ok(new Date(1199188800000 ).getUTCDate() === 1,
	'getUTCDate - 1 Jan in leap year')
is(new Date(1201780800000 ).getUTCDate(),  31,
	'getUTCDate - 31 Jan in leap year')
is(new Date(1201867200000 ).getUTCDate(),  1,
	'getUTCDate - 1 Feb in leap year')
is(new Date(1204286400000 ).getUTCDate(),  29,
	'getUTCDate - 29 Feb in leap year')
is(new Date(1204372800000 ).getUTCDate(),  1,
	'getUTCDate - 1 Mar in leap year')
is(new Date(1206964800000 ).getUTCDate(),  31,
	'getUTCDate - 31 Mar in leap year')
is(new Date(1207051200000 ).getUTCDate(),  1,
	'getUTCDate - 1 Apr in leap year')
is(new Date(1209556800000 ).getUTCDate(),  30,
	'getUTCDate - 30 Apr in leap year')
is(new Date(1209643200000 ).getUTCDate(),  1,
	'getUTCDate - 1 May in leap year')
is(new Date(1212235200000 ).getUTCDate(),  31,
	'getUTCDate - 31 May in leap year')
is(new Date(1212321600000 ).getUTCDate(),  1,
	'getUTCDate - 1 Jun in leap year')
is(new Date(1214827200000 ).getUTCDate(),  30,
	'getUTCDate - 30 Jun in leap year')
is(new Date(1214913600000 ).getUTCDate(),  1,
	'getUTCDate - 1 Jul in leap year')
is(new Date(1217505600000 ).getUTCDate(),  31,
	'getUTCDate - 31 Jul in leap year')
is(new Date(1217592000000 ).getUTCDate(),  1,
	'getUTCDate - 1 Aug in leap year')
is(new Date(1220184000000 ).getUTCDate(),  31,
	'getUTCDate - 31 Aug in leap year')
is(new Date(1220270400000 ).getUTCDate(),  1,
	'getUTCDate - 1 Sep in leap year')
is(new Date(1222776000000 ).getUTCDate(),  30,
	'getUTCDate - 30 Sep in leap year')
is(new Date(1222862400000 ).getUTCDate(),  1,
	'getUTCDate - 1 Oct in leap year')
is(new Date(1225454400000 ).getUTCDate(),  31,
	'getUTCDate - 31 Oct in leap year')
is(new Date(1225540800000 ).getUTCDate(),  1,
	'getUTCDate - 1 Nov in leap year')
is(new Date(1228003200000 ).getUTCDate(),  30,
	'getUTCDate - 30 Nov in leap year')
is(new Date(1228132800000 ).getUTCDate(),  1,
	'getUTCDate - 1 Dec in leap year')
is(new Date(1230724800000 ).getUTCDate(),  31,
	'getUTCDate - 31 Dec in leap year')

is(new Date(1230811200000 ).getUTCDate(), 1,
	'getUTCDate - 1 Jan in common year')
is(new Date(1233403200000 ).getUTCDate(),  31,
	'getUTCDate - 31 Jan in common year')
is(new Date(1233489600000 ).getUTCDate(),  1,
	'getUTCDate - 1 Feb in common year')
is(new Date(1235822400000 ).getUTCDate(),  28,
	'getUTCDate - 28 Feb in common year')
is(new Date(1235908800000 ).getUTCDate(),  1,
	'getUTCDate - 1 Mar in common year')
is(new Date(1238500800000 ).getUTCDate(),  31,
	'getUTCDate - 31 Mar in common year')
is(new Date(1238587200000 ).getUTCDate(),  1,
	'getUTCDate - 1 Apr in common year')
is(new Date(1241092800000 ).getUTCDate(),  30,
	'getUTCDate - 30 Apr in common year')
is(new Date(1241179200000 ).getUTCDate(),  1,
	'getUTCDate - 1 May in common year')
is(new Date(1243771200000 ).getUTCDate(),  31,
	'getUTCDate - 31 May in common year')
is(new Date(1243857600000 ).getUTCDate(),  1,
	'getUTCDate - 1 Jun in common year')
is(new Date(1246363200000 ).getUTCDate(),  30,
	'getUTCDate - 30 Jun in common year')
is(new Date(1246449600000 ).getUTCDate(),  1,
	'getUTCDate - 1 Jul in common year')
is(new Date(1249041600000 ).getUTCDate(),  31,
	'getUTCDate - 31 Jul in common year')
is(new Date(1249128000000 ).getUTCDate(),  1,
	'getUTCDate - 1 Aug in common year')
is(new Date(1251720000000 ).getUTCDate(),  31,
	'getUTCDate - 31 Aug in common year')
is(new Date(1251806400000 ).getUTCDate(),  1,
	'getUTCDate - 1 Sep in common year')
is(new Date(1254312000000 ).getUTCDate(),  30,
	'getUTCDate - 30 Sep in common year')
is(new Date(1254398400000 ).getUTCDate(),  1,
	'getUTCDate - 1 Oct in common year')
is(new Date(1256990400000 ).getUTCDate(),  31,
	'getUTCDate - 31 Oct in common year')
is(new Date(1257076800000 ).getUTCDate(),  1,
	'getUTCDate - 1 Nov in common year')
is(new Date(1259582400000 ).getUTCDate(),  30,
	'getUTCDate - 30 Nov in common year')
is(new Date(1259668800000 ).getUTCDate(),  1,
	'getUTCDate - 1 Dec in common year')
is(new Date(1262260800000 ).getUTCDate(),  31,
	'getUTCDate - 31 Dec in common year')

error = false
try{Date.prototype. getUTCDate.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getUTCDate death')


// ===================================================
// 15.9.5.16 Date.prototype. getDay
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getDay',0)

offset = new Date(new Date().getYear(), 0, 1).getTimezoneOffset() * 60000;

// 9 tests
ok(is_nan(new Date(NaN).getDay()), 'getDay (NaN)')
ok(new Date(1200225600000+offset).getDay() === 0, 'getDay (Sunday)')
ok(new Date(1200312000000+offset).getDay() === 1, 'getDay (Monday)')
ok(new Date(1200398400000+offset).getDay() === 2, 'getDay (Tuesday)')
ok(new Date(1200484800000+offset).getDay() === 3, 'getDay (Wednesday)')
ok(new Date(1200571200000+offset).getDay() === 4, 'getDay (Thursday)')
ok(new Date(1200657600000+offset).getDay() === 5, 'getDay (Friday)')
ok(new Date(1200744000000+offset).getDay() === 6, 'getDay (Saturday)')

error = false
try{Date.prototype. getDay.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getDay death')


// ===================================================
// 15.9.5.17 Date.prototype. getUTCDay
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getUTCDay',0)

// 9 tests
ok(is_nan(new Date(NaN).getUTCDay()), 'getUTCDay (NaN)')
ok(new Date(1200225600000).getUTCDay() === 0, 'getUTCDay (Sunday)')
ok(new Date(1200312000000).getUTCDay() === 1, 'getUTCDay (Monday)')
ok(new Date(1200398400000).getUTCDay() === 2, 'getUTCDay (Tuesday)')
ok(new Date(1200484800000).getUTCDay() === 3,
	'getUTCDay (Wednesday)')
ok(new Date(1200571200000).getUTCDay() === 4,
	'getUTCDay (Thursday)')
ok(new Date(1200657600000).getUTCDay() === 5, 'getUTCDay (Friday)')
ok(new Date(1200744000000).getUTCDay() === 6,
	'getUTCDay (Saturday)')

error = false
try{Date.prototype. getUTCDay.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getUTCDay death')


// ===================================================
// 15.9.5.18 Date.prototype. getHours
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getHours',0)

offset = new Date(new Date().getYear(), 0, 1).getTimezoneOffset() * 60000;

// 3 tests
ok(is_nan(new Date(NaN).getHours()), 'getHours (NaN)')
ok(new Date(1200225612345+offset).getHours() === 12, 'getHours')

error = false
try{Date.prototype. getHours.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getHours death')


// ===================================================
// 15.9.5.19 Date.prototype. getUTCHours
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getUTCHours',0)

// 3 tests
ok(is_nan(new Date(NaN).getUTCHours()), 'getUTCHours (NaN)')
ok(new Date(1200225612345).getUTCHours() === 12, 'getUTCHours')

error = false
try{Date.prototype. getUTCHours.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getUTCHours death')


// ===================================================
// 15.9.5.20 Date.prototype. getMinutes
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getMinutes',0)

offset = new Date(new Date().getYear(), 0, 1).getTimezoneOffset() * 60000;

// 3 tests
ok(is_nan(new Date(NaN).getMinutes()), 'getMinutes (NaN)')
ok(new Date(1200225612345+offset).getMinutes() === 0, 'getMinutes')

error = false
try{Date.prototype. getMinutes.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getMinutes death')


// ===================================================
// 15.9.5.21 Date.prototype. getUTCMinutes
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getUTCMinutes',0)

// 3 tests
ok(is_nan(new Date(NaN).getUTCMinutes()), 'getUTCMinutes (NaN)')
ok(new Date(1200225612345).getUTCMinutes() === 0, 'getUTCMinutes')

error = false
try{Date.prototype. getUTCMinutes.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getUTCMinutes death')


// ===================================================
// 15.9.5.22 Date.prototype.getSeconds
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getSeconds',0)

// 3 tests
ok(is_nan(new Date(NaN).getSeconds()), 'getSeconds (NaN)')
ok(new Date(1200225613345).getSeconds() === 13, 'getSeconds')

error = false
try{Date.prototype. getSeconds.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getSeconds death')


// ===================================================
// 15.9.5.23 Date.prototype.getUTCSeconds
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getUTCSeconds',0)

// 3 tests
ok(is_nan(new Date(NaN).getUTCSeconds()), 'getUTCSeconds (NaN)')
ok(new Date(1200225613345).getUTCSeconds() === 13, 'getUTCSeconds')

error = false
try{Date.prototype. getUTCSeconds.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getUTCSeconds death')


// ===================================================
// 15.9.5.24 Date.prototype.getMilliseconds
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getMilliseconds',0)

// 3 tests
ok(is_nan(new Date(NaN).getMilliseconds()), 'getMilliseconds (NaN)')
ok(new Date(1200225613345).getMilliseconds() === 345, 'getMilliseconds')

error = false
try{Date.prototype. getMilliseconds.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getMilliseconds death')


// ===================================================
// 15.9.5.25 Date.prototype.getUTCMilliseconds
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getUTCMilliseconds',0)

// 3 tests
ok(is_nan(new Date(NaN).getUTCMilliseconds()), 'getUTCMilliseconds (NaN)')
ok(new Date(1200225613345).getUTCMilliseconds() === 345, 'getUTCMilliseconds')

error = false
try{Date.prototype. getUTCMilliseconds.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getUTCMilliseconds death')


// ===================================================
// 15.9.5.26 Date.prototype.getTimezoneOffset
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'getTimezoneOffset',0)

// I’m not sure how to test this here. But many tests above rely on its
// correct behaviour, so maybe that’s enough.

// 1 test
error = false
try{Date.prototype. getUTCMilliseconds.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'getUTCMilliseconds death')


// ===================================================
// 15.9.5.27 Date.prototype.setTime
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'setTime',1)

// 8 tests
ok(is_nan(d = new Date().setTime(285619*365*24000*3600)),
	'retval of setTime out of range')
ok(is_nan(+d), 'affect of setTime out of range')
ok(is_nan(d = new Date().setTime()),
	'retval of setTime w/o args')
ok(is_nan(+d), 'affect of setTime w/o args')
is((d=new Date).setTime(785), 785, 'setTime retval')
is(+d, 785, 'affect of setTime')
ok(new Date().setTime("3") === 3, 'setTime with string arg')

error = false
try{Date.prototype. setTime.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'setTime death')


// ===================================================
// 15.9.5.28 Date.prototype.setMilliseconds
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'setMilliseconds',1)

// 2 tests
ok(is_nan(new Date().setMilliseconds()), 'setMilliseconds without args')
d = new Date(+(e=new Date()));
is(d.setMilliseconds("3"), e.setMilliseconds(3),
  'setMilliseconds treats strings the same way as numbers')

// 6 tests
d = new Date(+(e = new Date)); // two identical objects
ok(d.setMilliseconds(85)===+e-e.getMilliseconds()+85,
	'retval of setMilliseconds')
is(d.getTime(),e-e.getMilliseconds()+85,
	 'affect of setMilliseconds')
d = new Date(+(e = new Date)); // two identical objects
ok(d.setMilliseconds(1000)===+e-e.getMilliseconds()+1000,
	'retval of setMilliseconds(1000)')
is(d.getMilliseconds(),0,
	 'affect of setMilliseconds(1000)')
is(d.getTime(),e-e.getMilliseconds()+1000,
	 'affect of setMilliseconds(1000)')

error = false
try{Date.prototype. setMilliseconds.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'setMilliseconds death')


// ===================================================
// 15.9.5.29 Date.prototype.setUTCMilliseconds
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'setUTCMilliseconds',1)

// 2 tests
ok(is_nan(new Date().setUTCMilliseconds()),
  'setUTCMilliseconds without args')
d = new Date(+(e=new Date()));
is(d.setUTCMilliseconds("3"), e.setUTCMilliseconds(3),
  'setUTCMilliseconds treats strings the same way as numbers')

// 6 tests
d = new Date(+(e = new Date)); // two identical objects
ok(d.setUTCMilliseconds(85)===+e-e.getMilliseconds()+85,
	'retval of setUTCMilliseconds')
is(d.getTime(),e-e.getMilliseconds()+85,
	 'affect of setUTCMilliseconds')
d = new Date(+(e = new Date)); // two identical objects
ok(d.setUTCMilliseconds(1000)===+e-e.getMilliseconds()+1000,
	'retval of setUTCMilliseconds(1000)')
is(d.getMilliseconds(),0,
	 'affect of setUTCMilliseconds(1000)')
is(d.getTime(),e-e.getMilliseconds()+1000,
	 'affect of setUTCMilliseconds(1000)')

error = false
try{Date.prototype. setUTCMilliseconds.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'setUTCMilliseconds death')


// ===================================================
// 15.9.5.30 Date.prototype.setSeconds
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'setSeconds',2)

// 2 test
d = new Date
d.setSeconds("1","2")
ok(d.getSeconds() === 1, 'getSeconds after setSeconds with strings')
ok(d.getMilliseconds() === 2, 'getMilliseconds after setSeconds w/strings')

// 8 tests
d = new Date(+(e = new Date)); // two identical objects
ok(d.setSeconds(15)===d.getTime(), 'retval of setSeconds')
is(d.getYear(), e.getYear(), 'setSeconds does not change the year')
is(d.getMonth(), e.getMonth(), 'setSeconds does not change the month')
is(d.getDate(), e.getDate(), 'setSeconds does not change the date')
is(d.getHours(), e.getHours(), 'setSeconds does not change the hours')
is(d.getMinutes(), e.getMinutes(), 'setSeconds does not set the minutes')
is(d.getSeconds(), 15, 'setSeconds changes the seconds')
is(d.getMilliseconds(), e.getMilliseconds(),
 'setSeconds does not change the ms')

// 8 tests: setSeconds with two args
d = new Date(+(e = new Date)); // two identical objects
ok(d.setSeconds(15,3)===d.getTime(), 'retval of setSeconds w/2 args')
is(d.getYear(), e.getYear(), 'setSeconds w/2 args does not change year')
is(d.getDate(), e.getDate(), 'setSeconds w/2 args does not change date')
is(d.getMonth(), e.getMonth(), 'setSeconds w/2 args changeth not month')
is(d.getHours(), e.getHours(), 'setSeconds w/2 args does not change hours')
is(d.getMinutes(), e.getMinutes(),'setSeconds w/2 args does not set mins')
is(d.getSeconds(), 15, 'setSeconds w/2 args sets the sec')
is(d.getMilliseconds(), 3,
 'setSeconds w/2 args changes the ms')

// 1 test for setSeconds without arguments
ok(is_nan(d.setSeconds()), 'setSeconds without arguments')

// 1 test here
error = false
try{Date.prototype. setSeconds.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'setSeconds death')


// ===================================================
// 15.9.5.31 Date.prototype.setUTCSeconds
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'setUTCSeconds',2)

// 2 test
d = new Date
d.setUTCSeconds("1","2")
ok(d.getSeconds() === 1, 'getSeconds after setUTCSeconds with strings')
ok(d.getMilliseconds() === 2,
 'getMilliseconds after setUTCSeconds w/strings')

// 8 tests
d = new Date(+(e = new Date)); // two identical objects
ok(d.setUTCSeconds(15)===d.getTime(), 'retval of setUTCSeconds')
is(d.getYear(), e.getYear(), 'setUTCSeconds does not change the year')
is(d.getMonth(), e.getMonth(), 'setUTCSeconds does not change the month')
is(d.getDate(), e.getDate(), 'setUTCSeconds does not change the date')
is(d.getHours(), e.getHours(), 'setUTCSeconds does not change the hours')
is(d.getMinutes(), e.getMinutes(),'setUTCSeconds does not set the minutes')
is(d.getSeconds(), 15, 'setUTCSeconds changes the seconds')
is(d.getMilliseconds(), e.getMilliseconds(),
 'setUTCSeconds does not change the ms')

// 8 tests: setUTCSeconds with two args
d = new Date(+(e = new Date)); // two identical objects
ok(d.setUTCSeconds(15,3)===d.getTime(), 'retval of setUTCSeconds w/2 args')
is(d.getYear(), e.getYear(), 'setUTCSeconds w/2 args does not change year')
is(d.getDate(), e.getDate(), 'setUTCSeconds w/2 args does not change date')
is(d.getMonth(), e.getMonth(), 'setUTCSeconds w/2 args changeth not month')
is(d.getHours(), e.getHours(),
  'setUTCSeconds w/2 args does not change hours')
is(d.getMinutes(), e.getMinutes(),'setUTCSeconds w/2 args does not set mins')
is(d.getSeconds(), 15, 'setUTCSeconds w/2 args sets the sec')
is(d.getMilliseconds(), 3,
 'setUTCSeconds w/2 args changes the ms')

// 1 test for setUTCSeconds without arguments
ok(is_nan(d.setUTCSeconds()), 'setUTCSeconds without arguments')

// 1 test here
error = false
try{Date.prototype. setUTCSeconds.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'setUTCSeconds death')


// ===================================================
// 15.9.5.33 Date.prototype.setMinutes
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'setMinutes',3)

// 3 test
d = new Date
d.setMinutes("1","2","3")
ok(d.getMinutes() === 1, 'getMinutes after setMinutes with strings')
ok(d.getSeconds() === 2, 'getSeconds after setMinutes with strings')
ok(d.getMilliseconds() === 3, 'getMilliseconds after setMinutes w/strings')

// 8 tests
d = new Date(+(e = new Date)); // two identical objects
ok(d.setMinutes(15)===d.getTime(), 'retval of setMinutes')
is(d.getYear(), e.getYear(), 'setMinutes does not change the year')
is(d.getMonth(), e.getMonth(), 'setMinutes does not change the month')
is(d.getDate(), e.getDate(), 'setMinutes does not change the date')
is(d.getHours(), e.getHours(), 'setMinutes does not change the hours')
is(d.getMinutes(), 15, 'setMinutes sets the minutes')
is(d.getSeconds(), e.getSeconds(), 'setMinutes does not change the seconds')
is(d.getMilliseconds(), e.getMilliseconds(),
 'setMinutes does not change the ms')

// Let’s try a date six months from now (so DST offset will be different)
// 8 tests more
d = new Date(+(e = new Date(e.getTime()+180*3600*24000)));
ok(d.setMinutes(15)===d.getTime(), 'retval of setMinutes (in 6 mths)')
is(d.getYear(), e.getYear(), 'setMinutes does not change year (in 6 mths)')
is(d.getDate(), e.getDate(), 'setMinutes does not change date (in 6 mo.)')
is(d.getMonth(), e.getMonth(), 'setMinutes changeth not month (in 6 mths)')
is(d.getHours(), e.getHours(), 'setMinutes does not change hrs (in 6 mo.)')
is(d.getMinutes(), 15, 'setMinutes changeth not min (in 6 mths)')
is(d.getSeconds(),e.getSeconds(),'setMinutes changeth not sec (in 6 mths)')
is(d.getMilliseconds(), e.getMilliseconds(),
 'setMinutes does not change the ms (in 6 mths)')

// 8 tests: setMinutes with two args
d = new Date(+(e = new Date)); // two identical objects
ok(d.setMinutes(15,3)===d.getTime(), 'retval of setMinutes w/2 args')
is(d.getYear(), e.getYear(), 'setMinutes w/2 args does not change year')
is(d.getDate(), e.getDate(), 'setMinutes w/2 args does not change date')
is(d.getMonth(), e.getMonth(), 'setMinutes w/2 args changeth not month')
is(d.getHours(), e.getHours(), 'setMinutes w/2 args does not change hours')
is(d.getMinutes(), 15, 'setMinutes w/2 args sets the minutes')
is(d.getSeconds(), 3, 'setMinutes w/2 args sets the sec')
is(d.getMilliseconds(), e.getMilliseconds(),
 'setMinutes w/2 args does not change the ms')

// 8 tests: setMinutes with 3 args
d = new Date(+(e = new Date)); // two identical objects
ok(d.setMinutes(15,3,34)===d.getTime(), 'retval of setMinutes w/3 args')
is(d.getYear(), e.getYear(), 'setMinutes w/3 args does not change year')
is(d.getDate(), e.getDate(), 'setMinutes w/3 args does not change date')
is(d.getMonth(), e.getMonth(), 'setMinutes w/3 args changeth not month')
is(d.getHours(), e.getHours(), 'setMinutes w/3 args does not change hours')
is(d.getMinutes(), 15, 'setMinutes w/3 args sets the minutes')
is(d.getSeconds(), 3, 'setMinutes w/3 args sets the seconds')
is(d.getMilliseconds(), 34,
 'setMinutes w/3 args sets the the ms')

// 1 test for setMinutes without arguments
ok(is_nan(d.setMinutes()), 'setMinutes without arguments')

// 2 tests here
error = false
try{Date.prototype. setMinutes.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'setMinutes death')
// This test is not really normative, but is here since at one point it was
// saying ‘setHours cannot be called....’
like(error, '/setMinutes/', 'error message from setMinutes death')


// ===================================================
// 15.9.5.34 Date.prototype.setUTCMinutes
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'setUTCMinutes',3)

// 3 test
d = new Date
d.setUTCMinutes("1","2","3")
ok(d.getUTCMinutes() === 1,
  'getUTCMinutes after setUTCMinutes with strings')
ok(d.getSeconds() === 2, 'getSeconds after setUTCMinutes with strings')
ok(d.getMilliseconds() === 3,
  'getMilliseconds after setUTCMinutes w/strings')

// 8 tests
d = new Date(+(e = new Date)); // two identical objects
ok(d.setUTCMinutes(15)===d.getTime(), 'retval of setUTCMinutes')
is(d.getUTCFullYear(), e.getUTCFullYear(),
  'setUTCMinutes does not change the year')
is(d.getUTCMonth(), e.getUTCMonth(),
  'setUTCMinutes does not change the month')
is(d.getUTCDate(), e.getUTCDate(),
  'setUTCMinutes does not change the date')
is(d.getUTCHours(), e.getUTCHours(),
  'setUTCMinutes does not change the hours')
is(d.getUTCMinutes(), 15, 'setUTCMinutes sets the minutes')
is(d.getSeconds(), e.getSeconds(),
  'setUTCMinutes does not change the seconds')
is(d.getMilliseconds(), e.getMilliseconds(),
 'setUTCMinutes does not change the ms')

// Let’s try a date six months from now (so DST offset will be different)
// 8 tests more
d = new Date(+(e = new Date(e.getTime()+180*3600*24000)));
ok(d.setUTCMinutes(15)===d.getTime(), 'retval of setUTCMinutes (in 6 mos)')
is(d.getUTCFullYear(), e.getUTCFullYear(),
  'setUTCMinutes changeth not year (in 6 mths)')
is(d.getUTCDate(), e.getUTCDate(),
  'setUTCMinutes changethe not date (in 6 mo.)')
is(d.getUTCMonth(), e.getUTCMonth(),
  'setUTCMinutes changes not month (in 6 mo)')
is(d.getUTCHours(), e.getUTCHours(),
  'setUTCMinutes changeth not hrs (in 6 mo.)')
is(d.getUTCMinutes(), 15, 'setUTCMinutes changeth not min (in 6 mths)')
is(d.getSeconds(),e.getSeconds(),'setUTCMinutes changes no sec (in 6 mos)')
is(d.getMilliseconds(), e.getMilliseconds(),
 'setUTCMinutes does not change the ms (in 6 mths)')

// 8 tests: setUTCMinutes with two args
d = new Date(+(e = new Date)); // two identical objects
ok(d.setUTCMinutes(15,3)===d.getTime(), 'retval of setUTCMinutes w/2 args')
is(d.getUTCFullYear(), e.getUTCFullYear(),
  'setUTCMinutes w/2 args does not change year')
is(d.getUTCDate(), e.getUTCDate(),
  'setUTCMinutes w/2 args does not change date')
is(d.getUTCMonth(), e.getUTCMonth(),
  'setUTCMinutes w/2 args changeth not month')
is(d.getUTCHours(), e.getUTCHours(),
  'setUTCMinutes w/2 args does not change hours')
is(d.getUTCMinutes(), 15, 'setUTCMinutes w/2 args sets the minutes')
is(d.getSeconds(), 3, 'setUTCMinutes w/2 args sets the sec')
is(d.getMilliseconds(), e.getMilliseconds(),
 'setUTCMinutes w/2 args does not change the ms')

// 8 tests: setUTCMinutes with 3 args
d = new Date(+(e = new Date)); // two identical objects
ok(d.setUTCMinutes(15,3,34)===d.getTime(),
  'retval of setUTCMinutes w/3 args')
is(d.getUTCFullYear(), e.getUTCFullYear(),
  'setUTCMinutes w/3 args does not change year')
is(d.getUTCDate(), e.getUTCDate(),
  'setUTCMinutes w/3 args does not change date')
is(d.getUTCMonth(), e.getUTCMonth(),
  'setUTCMinutes w/3 args changeth not month')
is(d.getUTCHours(), e.getUTCHours(),
  'setUTCMinutes w/3 args does not change hours')
is(d.getUTCMinutes(), 15, 'setUTCMinutes w/3 args sets the minutes')
is(d.getSeconds(), 3, 'setUTCMinutes w/3 args sets the seconds')
is(d.getMilliseconds(), 34,
 'setUTCMinutes w/3 args sets the the ms')

// 1 test for setUTCMinutes without arguments
ok(is_nan(d.setUTCMinutes()), 'setUTCMinutes without arguments')

// 1 test here
error = false
try{Date.prototype. setUTCMinutes.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'setUTCMinutes death')


// ===================================================
// 15.9.5.35 Date.prototype.setHours
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'setHours',4)

// 4 test
d = new Date
d.setHours("1","2","3","4")
ok(d.getHours() === 1, 'getHours after setHours with strings')
ok(d.getMinutes() === 2, 'getMinutes after setHours with strings')
ok(d.getSeconds() === 3, 'getSeconds after setHours with strings')
ok(d.getMilliseconds() === 4, 'getMilliseconds after setHours w/strings')

// 8 tests
d = new Date(+(e = new Date)); // two identical objects
ok(d.setHours(15)===d.getTime(), 'retval of setHours')
is(d.getHours(), 15, 'setHours set the hours')
is(d.getYear(), e.getYear(), 'setHours does not change the year')
is(d.getDate(), e.getDate(), 'setHours does not change the date')
is(d.getMonth(), e.getMonth(), 'setHours does not change the month')
is(d.getMinutes(), e.getMinutes(), 'setHours does not change the minutes')
is(d.getSeconds(), e.getSeconds(), 'setHours does not change the seconds')
is(d.getMilliseconds(), e.getMilliseconds(),
 'setHours does not change the ms')

// Let’s try a date six months from now (so DST offset will be different)
// 8 tests more
d = new Date(+(e = new Date(e.getTime()+180*3600*24000)));
ok(d.setHours(15)===d.getTime(), 'retval of setHours (in 6 mths)')
is(d.getHours(), 15, 'setHours set the date (6 months hence)')
is(d.getYear(), e.getYear(), 'setHours does not change year (in 6 mths)')
is(d.getDate(), e.getDate(), 'setHours does not change date (in 6 mo.)')
is(d.getMonth(), e.getMonth(), 'setHours changeth not month (in 6 mths)')
is(d.getMinutes(), e.getMinutes(), 'setHours changeth not min (in 6 mths)')
is(d.getSeconds(), e.getSeconds(), 'setHours changeth not sec (in 6 mths)')
is(d.getMilliseconds(), e.getMilliseconds(),
 'setHours does not change the ms (in 6 mths)')

// 8 tests: setHours with two args
d = new Date(+(e = new Date)); // two identical objects
ok(d.setHours(15,3)===d.getTime(), 'retval of setHours w/2 args')
is(d.getHours(), 15, 'setHours w/2 args set the hours')
is(d.getYear(), e.getYear(), 'setHours w/2 args does not change the year')
is(d.getDate(), e.getDate(), 'setHours w/2 args does not change the date')
is(d.getMonth(), e.getMonth(), 'setHours w/2 args does not change  month')
is(d.getMinutes(), 3, 'setHours w/2 args sets the minutes')
is(d.getSeconds(), e.getSeconds(), 'setHours w/2 args does not change sec')
is(d.getMilliseconds(), e.getMilliseconds(),
 'setHours w/2 args does not change the ms')

// 8 tests: setHours with 3 args
d = new Date(+(e = new Date)); // two identical objects
ok(d.setHours(15,3,34)===d.getTime(), 'retval of setHours w/3 args')
is(d.getHours(), 15, 'setHours w/3 args set the hours')
is(d.getYear(), e.getYear(), 'setHours w/3 args does not change the year')
is(d.getDate(), e.getDate(), 'setHours w/3 args does not change the date')
is(d.getMonth(), e.getMonth(), 'setHours w/3 args does not change  month')
is(d.getMinutes(), 3, 'setHours w/3 args sets the minutes')
is(d.getSeconds(), 34, 'setHours w/3 args sets the seconds')
is(d.getMilliseconds(), e.getMilliseconds(),
 'setHours w/3 args does not change the ms')

// 8 tests: setHours with 4 args
d = new Date(+(e = new Date)); // two identical objects
ok(d.setHours(15,3,34,695)===d.getTime(), 'retval of setHours w/4 args')
is(d.getHours(), 15, 'setHours w/4 args set the hours')
is(d.getYear(), e.getYear(), 'setHours w/4 args does not change the year')
is(d.getDate(), e.getDate(), 'setHours w/4 args does not change the date')
is(d.getMonth(), e.getMonth(), 'setHours w/4 args does not change  month')
is(d.getMinutes(), 3, 'setHours w/4 args sets the minutes')
is(d.getSeconds(), 34, 'setHours w/4 args sets the seconds')
is(d.getMilliseconds(), 695, 'setHours w/4 args sets the ms')

// 1 test for setHours without arguments
ok(is_nan(d.setHours()), 'setHours without arguments') ||diag(d.setHours())

// 1 test here
error = false
try{Date.prototype. setHours.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'setHours death')


// ===================================================
// 15.9.5.36a Date.prototype.setUTCHours
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'setUTCHours',4)

// 4 test
d = new Date
d.setUTCHours("1","2","3","4")
ok(d.getUTCHours() === 1, 'getUTCHours after setUTCHours with strings')
ok(d.getUTCMinutes() === 2, 'getUTCMinutes after setUTCHours with strings')
ok(d.getSeconds() === 3, 'getSeconds after setUTCHours with strings')
ok(d.getMilliseconds() === 4,
  'getMilliseconds after setUTCHours w/strings')

// 8 tests
d = new Date(+(e = new Date)); // two identical objects
ok(d.setUTCHours(15)===d.getTime(), 'retval of setUTCHours')
is(d.getUTCHours(), 15, 'setUTCHours set the hours')
is(d.getUTCFullYear(), e.getUTCFullYear(),
  'setUTCHours does not change the year')
is(d.getUTCDate(), e.getUTCDate(), 'setUTCHours does not change the date')
is(d.getUTCMonth(), e.getUTCMonth(),
  'setUTCHours does not change the month')
is(d.getUTCMinutes(), e.getUTCMinutes(),
  'setUTCHours does not change the minutes')
is(d.getSeconds(), e.getSeconds(),
  'setUTCHours does not change the seconds')
is(d.getMilliseconds(), e.getMilliseconds(),
 'setUTCHours does not change the ms')

// Let’s try a date six months from now (so DST offset will be different)
// 8 tests more
d = new Date(+(e = new Date(e.getTime()+180*3600*24000)));
ok(d.setUTCHours(15)===d.getTime(), 'retval of setUTCHours (in 6 mths)')
is(d.getUTCHours(), 15, 'setUTCHours set the date (6 months hence)')
is(d.getUTCFullYear(), e.getUTCFullYear(),
  'setUTCHours does not change year (in 6 mths)')
is(d.getUTCDate(), e.getUTCDate(),
  'setUTCHours does not change date (in 6 mo.)')
is(d.getUTCMonth(), e.getUTCMonth(),
  'setUTCHours changeth not month (in 6 mths)')
is(d.getUTCMinutes(), e.getUTCMinutes(),
  'setUTCHours changeth not min (in 6 mths)')
is(d.getSeconds(), e.getSeconds(),
  'setUTCHours changeth not sec (in 6 mths)')
is(d.getMilliseconds(), e.getMilliseconds(),
 'setUTCHours does not change the ms (in 6 mths)')

// 8 tests: setUTCHours with two args
d = new Date(+(e = new Date)); // two identical objects
ok(d.setUTCHours(15,3)===d.getTime(), 'retval of setUTCHours w/2 args')
is(d.getUTCHours(), 15, 'setUTCHours w/2 args set the hours')
is(d.getUTCFullYear(), e.getUTCFullYear(),
  'setUTCHours w/2 args does not change the year')
is(d.getUTCDate(), e.getUTCDate(),
  'setUTCHours w/2 args does not change the date')
is(d.getUTCMonth(), e.getUTCMonth(),
  'setUTCHours w/2 args does not change  month')
is(d.getUTCMinutes(), 3, 'setUTCHours w/2 args sets the minutes')
is(d.getSeconds(), e.getSeconds(),
  'setUTCHours w/2 args does not change sec')
is(d.getMilliseconds(), e.getMilliseconds(),
 'setUTCHours w/2 args does not change the ms')

// 8 tests: setUTCHours with 3 args
d = new Date(+(e = new Date)); // two identical objects
ok(d.setUTCHours(15,3,34)===d.getTime(), 'retval of setUTCHours w/3 args')
is(d.getUTCHours(), 15, 'setUTCHours w/3 args set the hours')
is(d.getUTCFullYear(), e.getUTCFullYear(),
  'setUTCHours w/3 args does not change the year')
is(d.getUTCDate(), e.getUTCDate(),
  'setUTCHours w/3 args does not change the date')
is(d.getUTCMonth(), e.getUTCMonth(),
  'setUTCHours w/3 args does not change  month')
is(d.getUTCMinutes(), 3, 'setUTCHours w/3 args sets the minutes')
is(d.getSeconds(), 34, 'setUTCHours w/3 args sets the seconds')
is(d.getMilliseconds(), e.getMilliseconds(),
 'setUTCHours w/3 args does not change the ms')

// 8 tests: setUTCHours with 4 args
d = new Date(+(e = new Date)); // two identical objects
ok(d.setUTCHours(15,3,34,695)===d.getTime(),
  'retval of setUTCHours w/4 args')
is(d.getUTCHours(), 15, 'setUTCHours w/4 args set the hours')
is(d.getUTCFullYear(), e.getUTCFullYear(),
  'setUTCHours w/4 args does not change the year')
is(d.getUTCDate(), e.getUTCDate(),
  'setUTCHours w/4 args does not change the date')
is(d.getUTCMonth(), e.getUTCMonth(),
  'setUTCHours w/4 args does not change  month')
is(d.getUTCMinutes(), 3, 'setUTCHours w/4 args sets the minutes')
is(d.getSeconds(), 34, 'setUTCHours w/4 args sets the seconds')
is(d.getMilliseconds(), 695, 'setUTCHours w/4 args sets the ms')

// 1 test for setUTCHours without arguments
ok(is_nan(d.setUTCHours()), 'setUTCHours without arguments') ||diag(d.setUTCHours())

// 1 test here
error = false
try{Date.prototype. setUTCHours.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'setUTCHours death')


// ===================================================
// 15.9.5.36b Date.prototype.setDate
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'setDate',1)

// 2 tests
d = new Date()
ok(is_nan(d.setDate()), 'setDate without arguments')
d.setDate("5")
is(d.getDate(), 5, 'setDate with string arg')

// 8 tests
d = new Date(+(e = new Date)); // two identical objects
ok(d.setDate(15)===d.getTime(), 'retval of setDate')
is(d.getDate(), 15, 'setDate set the date')
is(d.getYear(), e.getYear(), 'setDate does not change the year')
is(d.getMonth(), e.getMonth(), 'setDate does not change the month')
is(d.getHours(), e.getHours(), 'setDate does not change the hours')
is(d.getMinutes(), e.getMinutes(), 'setDate does not change the minutes')
is(d.getSeconds(), e.getSeconds(), 'setDate does not change the seconds')
is(d.getMilliseconds(), e.getMilliseconds(),
 'setDate does not change the ms')

// Let’s try a date six months from now (so DST offset will be different)
// 8 tests more
d = new Date(+(e = new Date(e.getTime()+180*3600*24000)));
ok(d.setDate(15)===d.getTime(), 'retval of setDate (in 6 mths)')
is(d.getDate(), 15, 'setDate set the date (6 months hence)')
is(d.getYear(), e.getYear(), 'setDate does not change  year (in 6 mths)')
is(d.getMonth(), e.getMonth(), 'setDate does not change month (in 6 mths)')
is(d.getHours(), e.getHours(), 'setDate does not change hours (in 6 mths)')
is(d.getMinutes(), e.getMinutes(), 'setDate changeth not min (in 6 mths)')
is(d.getSeconds(), e.getSeconds(), 'setDate changeth not sec (in 6 mths)')
is(d.getMilliseconds(), e.getMilliseconds(),
 'setDate does not change the ms (in 6 mths)')

// 1 test here
error = false
try{Date.prototype. setDate.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'setDate death')


// ===================================================
// 15.9.5.37 Date.prototype.setUTCDate
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'setUTCDate',1)

// 2 tests
d = new Date()
ok(is_nan(d.setUTCDate()), 'setUTCDate without arguments')
d.setUTCDate("5")
is(d.getUTCDate(), 5, 'setUTCDate with string arg')

// 8 tests
d = new Date(+(e = new Date)); // two identical objects
ok(d.setUTCDate(15)===d.getTime(), 'retval of setUTCDate')
is(d.getUTCDate(), 15, 'setUTCDate set the date')
is(d.getUTCFullYear(), e.getUTCFullYear(),
  'setUTCDate does not change the year')
is(d.getUTCMonth(), e.getUTCMonth(),
  'setUTCDate does not change the month')
is(d.getUTCHours(), e.getUTCHours(),
  'setUTCDate does not change the hours')
is(d.getUTCMinutes(), e.getUTCMinutes(),
  'setUTCDate does not change the minutes')
is(d.getSeconds(), e.getSeconds(),
  'setUTCDate does not change the seconds')
is(d.getMilliseconds(), e.getMilliseconds(),
 'setUTCDate does not change the ms')

// Let’s try a date six months from now (so DST offset will be different)
// 8 tests more
d = new Date(+(e = new Date(e.getTime()+180*3600*24000)));
ok(d.setUTCDate(15)===d.getTime(), 'retval of setUTCDate (in 6 mths)')
is(d.getUTCDate(), 15, 'setUTCDate set the date (6 months hence)')
is(d.getUTCFullYear(), e.getUTCFullYear(),
  'setUTCDate does not change  year (in 6 mths)')
is(d.getUTCMonth(), e.getUTCMonth(), 
 'setUTCDate does not change month (in 6 mths)')
is(d.getUTCHours(), e.getUTCHours(),
  'setUTCDate does not change hours (in 6 mths)')
is(d.getUTCMinutes(), e.getUTCMinutes(),
  'setUTCDate changeth not min (in 6 mths)')
is(d.getSeconds(), e.getSeconds(),
  'setUTCDate changeth not sec (in 6 mths)')
is(d.getMilliseconds(), e.getMilliseconds(),
 'setUTCDate does not change the ms (in 6 mths)')

// 1 test here
error = false
try{Date.prototype. setUTCDate.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'setUTCDate death')


// ===================================================
// 15.9.5.38 Date.prototype.setMonth
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'setMonth',2)

// 3 tests
d = new Date()
ok(is_nan(d.setMonth()), 'setMonth without arguments')
d.setMonth("5","12")
is(d.getMonth(), 5, 'setMonth with string arg')
is(d.getDate(), 12, 'setMonth with string 2nd arg')

// 96 tests
for(i = 0; i<=11; ++i)
 d = new Date(+(e = new Date(2009, i, 15))),
 ok(d.setMonth(i==11?10:i+1)===d.getTime(),'retval of setMonth('+i+')'),
 is(d.getYear(), e.getYear(), 'setMonth('+i+') does not change the year'),
 is(d.getMonth(), i==11 ? 10 : i+1, 'setMonth('+i+') set the month'),
 is(d.getDate(), e.getDate(), 'setDate('+i+') set the date'),
 is(d.getHours(), e.getHours(), 'setMonth('+i+') does not change hours'),
 is(d.getMinutes(), e.getMinutes(),'setMonth('+i+') does not change min'),
 is(d.getSeconds(), e.getSeconds(),'setMonth('+i+') does not change secs'),
 is(d.getMilliseconds(), e.getMilliseconds(),
 'setMonth('+i+') does not change the ms')

// 2 tests
d = new Date(+(e = new Date(2009, 0, 31))),
d.setMonth(1),
is(d.getMonth(), 2, 'setMonth() overflowing into the following month')
is(d.getDate(), 3, 'date set my overflowing setMonth')

// 8 tests: setMonth with two args
d = new Date(+(e = new Date)); // two identical objects
ok(d.setMonth(5,3)===d.getTime(), 'retval of setMonth w/2 args')
is(d.getYear(), e.getYear(), 'setMonth w/2 args does not change the year')
is(d.getMonth(), 5, 'setMonth w/2 args does not change  month')
is(d.getDate(), 3, 'setMonth w/2 args does not change the date')
is(d.getHours(), e.getHours(), 'setMonth w/2 args does not set the hours')
is(d.getMinutes(), e.getMinutes(), 'setMonth w/2 args sets no minutes')
is(d.getSeconds(), e.getSeconds(), 'setMonth w/2 args does not change sec')
is(d.getMilliseconds(), e.getMilliseconds(),
 'setMonth w/2 args does not change the ms')

// 1 test here
error = false
try{Date.prototype. setMonth.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'setMonth death')


// ===================================================
// 15.9.5.39 Date.prototype.setUTCMonth
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'setUTCMonth',2)

// 3 tests
d = new Date()
ok(is_nan(d.setUTCMonth()), 'setUTCMonth without arguments')
d.setUTCMonth("5","12")
is(d.getUTCMonth(), 5, 'setUTCMonth with string arg')
is(d.getUTCDate(), 12, 'setUTCMonth with string 2nd arg')

// 96 tests
for(i = 0; i<=11; ++i)
 d = new Date(+(e = new Date(2009, i, 15))),
 ok(d.setUTCMonth(i==11?10:i+1)===d.getTime(),
   'retval of setUTCMonth('+i+')'),
 is(d.getUTCFullYear(), e.getUTCFullYear(),
   'setUTCMonth('+i+') does not change the year'),
 is(d.getUTCMonth(), i==11 ? 10 : i+1, 'setUTCMonth('+i+') set the month'),
 is(d.getUTCDate(), e.getUTCDate(), 'setDate('+i+') set the date'),
 is(d.getUTCHours(), e.getUTCHours(),
   'setUTCMonth('+i+') does not change hours'),
 is(d.getUTCMinutes(), e.getUTCMinutes(),
   'setUTCMonth('+i+') does not change min'),
 is(d.getSeconds(), e.getSeconds(),
   'setUTCMonth('+i+') does not change secs'),
 is(d.getMilliseconds(), e.getMilliseconds(),
 'setUTCMonth('+i+') does not change the ms')

// 2 tests
d = new Date(+(e = new Date(Date.UTC(2009, 0, 31)))),
d.setUTCMonth(1),
is(d.getUTCMonth(), 2,
  'setUTCMonth() overflowing into the following month')
is(d.getUTCDate(), 3, 'date set by overflowing setUTCMonth')

// 8 tests: setUTCMonth with two args
d = new Date(+(e = new Date)); // two identical objects
ok(d.setUTCMonth(5,3)===d.getTime(), 'retval of setUTCMonth w/2 args')
is(d.getUTCFullYear(), e.getUTCFullYear(),
  'setUTCMonth w/2 args does not change the year')
is(d.getUTCMonth(), 5, 'setUTCMonth w/2 args does not change  month')
is(d.getUTCDate(), 3, 'setUTCMonth w/2 args does not change the date')
is(d.getUTCHours(), e.getUTCHours(),
  'setUTCMonth w/2 args does not set the hours')
is(d.getUTCMinutes(), e.getUTCMinutes(),
  'setUTCMonth w/2 args sets no minutes')
is(d.getSeconds(), e.getSeconds(),
  'setUTCMonth w/2 args does not change sec')
is(d.getMilliseconds(), e.getMilliseconds(),
 'setUTCMonth w/2 args does not change the ms')

// 1 test here
error = false
try{Date.prototype. setUTCMonth.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'setUTCMonth death')


// ===================================================
// 15.9.5.40 Date.prototype.setFullYear
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'setFullYear',3)

// 4 tests
d = new Date()
ok(is_nan(d.setFullYear()), 'setFullYear without arguments')
d.setFullYear("5","11","13")
is(d.getFullYear(), 5, 'setFullYear with string arg')
is(d.getMonth(), 11, 'setFullYear with string 2nd arg')
is(d.getDate(), 13, 'setFullYear with stringy 3rd arg')

// 8 tests
d = new Date(+(e = new Date)); // two identical objects
// This test will fail on 29th of Feb, as it checks to make sure that set-
// ting the year does not change the date (which it does for Feb 29).
if (d.getDate() == 29 && d.getMonth()==1) d.setDate(28), e.setDate(28)
ok(d.setFullYear(11)===d.getTime(),'retval of setFullYear'),
is(d.getFullYear(), 11, 'setFullYear sets the year'),
is(d.getMonth(), d.getMonth(), 'setFullYear does not set the month'),
is(d.getDate(), e.getDate(), 'setFullYear does not set the date'),
is(d.getHours(), e.getHours(), 'setFullYear does not change hours'),
is(d.getMinutes(), e.getMinutes(),'setFullYear does not change min'),
is(d.getSeconds(), e.getSeconds(),'setFullYear does not change secs'),
is(d.getMilliseconds(), e.getMilliseconds(), 'setFullYear leaves ms alone')

// 96 tests for setFullYear with two quarrelsome arguments
for(i = 0; i<=11; ++i)
 d = new Date(+(e = new Date(2009, i, 15))),
 ok(d.setFullYear(645,i==11?10:i+1)===d.getTime(),
   'retval of setFullYear(y,'+i+')'),
 is(d.getFullYear(), 645, 'setFullYear(y,'+i+') sets the year'),
 is(d.getMonth(), i==11 ? 10 : i+1, 'setFullYear(y,'+i+') set the month'),
 is(d.getDate(), e.getDate(), 'setDate(y,'+i+') set the date'),
 is(d.getHours(), e.getHours(), 'setFullYear(y,'+i+') does not set hrs'),
 is(d.getMinutes(), e.getMinutes(),'setFullYear(y,'+i+') setteth not min'),
 is(d.getSeconds(), e.getSeconds(),'setFullYear(y,'+i+') sets not sec'),
 is(d.getMilliseconds(), e.getMilliseconds(),
 'setFullYear(y,'+i+') does not change the ms')

// 2 tests
d = new Date(+(e = new Date(2012, 1, 29))),
d.setFullYear(2013),
is(d.getMonth(), 2, 'setFullYear() overflowing into the following month')
is(d.getDate(), 1, 'date set by overflowing setFullYear')

// 8 tests: setFullYear with three args
d = new Date(+(e = new Date)); // two identical objects
ok(d.setFullYear(324,5,3)===d.getTime(), 'retval of setFullYear w/2 args')
is(d.getFullYear(), 324, 'setFullYear w/3 args changes the year')
is(d.getMonth(), 5, 'setFullYear w/3 args does not change  month')
is(d.getDate(), 3, 'setFullYear w/3 args does not change the date')
is(d.getHours(), e.getHours(),
  'setFullYear w/3 args does not set the hours')
is(d.getMinutes(), e.getMinutes(),
  'setFullYear w/3 args sets no minutes')
is(d.getSeconds(), e.getSeconds(),
  'setFullYear w/3 args does not change sec')
is(d.getMilliseconds(), e.getMilliseconds(),
 'setFullYear w/3 args does not change the ms')

// 1 test here
error = false
try{Date.prototype. setFullYear.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'setFullYear death')


// ===================================================
// 15.9.5.41 Date.prototype.setUTCFullYear
// ===================================================

// 10 tests
method_boilerplate_tests(Date.prototype,'setUTCFullYear',3)

// 4 tests
d = new Date()
ok(is_nan(d.setUTCFullYear()), 'setUTCFullYear without arguments')
d.setUTCFullYear("5","11","13")
is(d.getUTCFullYear(), 5, 'setUTCFullYear with string arg')
is(d.getUTCMonth(), 11, 'setUTCFullYear with string 2nd arg')
is(d.getUTCDate(), 13, 'setUTCFullYear with stringy 3rd arg')

// 8 tests
d = new Date(+(e = new Date)); // two identical objects
// This test will fail on 29th of Feb, as it checks to make sure that set-
// ting the year does not change the date (which it does for Feb 29).
if (d.getUTCDate() == 29 && d.getUTCMonth()==1)
  d.setUTCDate(28), e.setUTCDate(28)
ok(d.setUTCFullYear(11)===d.getTime(),'retval of setUTCFullYear'),
is(d.getUTCFullYear(), 11, 'setUTCFullYear sets the year'),
is(d.getUTCMonth(), d.getUTCMonth(),
  'setUTCFullYear does not set the month'),
is(d.getUTCDate(), e.getUTCDate(), 'setUTCFullYear does not set the date'),
is(d.getUTCHours(), e.getUTCHours(),
  'setUTCFullYear does not change hours'),
is(d.getUTCMinutes(), e.getUTCMinutes(),
  'setUTCFullYear does not change min'),
is(d.getSeconds(), e.getSeconds(),'setUTCFullYear does not change secs'),
is(d.getMilliseconds(), e.getMilliseconds(),
  'setUTCFullYear leaves ms alone')

// 96 tests for setUTCFullYear with two quarrelsome arguments
for(i = 0; i<=11; ++i)
 d = new Date(+(e = new Date(2009, i, 15))),
 ok(d.setUTCFullYear(645,i==11?10:i+1)===d.getTime(),
   'retval of setUTCFullYear(y,'+i+')'),
 is(d.getUTCFullYear(), 645, 'setUTCFullYear(y,'+i+') sets the year'),
 is(d.getUTCMonth(), i==11 ? 10 : i+1,
   'setUTCFullYear(y,'+i+') set the month'),
 is(d.getUTCDate(), e.getUTCDate(),
   'setUTCFullYear(y,'+i+') set the date'),
 is(d.getUTCHours(), e.getUTCHours(),
   'setUTCFullYear(y,'+i+') does not set hrs'),
 is(d.getUTCMinutes(), e.getUTCMinutes(),
   'setUTCFullYear(y,'+i+') setteth not min'),
 is(d.getSeconds(), e.getSeconds(),'setUTCFullYear(y,'+i+') sets not sec'),
 is(d.getMilliseconds(), e.getMilliseconds(),
 'setUTCFullYear(y,'+i+') does not change the ms')

// 2 tests
d = new Date(+(e = new Date(Date.UTC(2012, 1, 29)))),
d.setUTCFullYear(2013),
is(d.getUTCMonth(), 2, 'setUTCFullYear() overflowing into the following month')
is(d.getUTCDate(), 1, 'date set by overflowing setUTCFullYear')

// 8 tests: setUTCFullYear with three args
d = new Date(+(e = new Date)); // two identical objects
ok(d.setUTCFullYear(324,5,3)===d.getTime(), 'retval of setUTCFullYear w/2 args')
is(d.getUTCFullYear(), 324, 'setUTCFullYear w/3 args changes the year')
is(d.getUTCMonth(), 5, 'setUTCFullYear w/3 args does not change  month')
is(d.getUTCDate(), 3, 'setUTCFullYear w/3 args does not change the date')
is(d.getUTCHours(), e.getUTCHours(),
  'setUTCFullYear w/3 args does not set the hours')
is(d.getUTCMinutes(), e.getUTCMinutes(),
  'setUTCFullYear w/3 args sets no minutes')
is(d.getSeconds(), e.getSeconds(),
  'setUTCFullYear w/3 args does not change sec')
is(d.getMilliseconds(), e.getMilliseconds(),
 'setUTCFullYear w/3 args does not change the ms')

// 1 test here
error = false
try{Date.prototype. setUTCFullYear.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'setUTCFullYear death')


// ===================================================
// 15.9.5.42 Date.prototype.toUTCString
// ===================================================

// 1 test
ok(Date.prototype.toUTCString === Date.prototype.toGMTString,
  'toUTCString');
