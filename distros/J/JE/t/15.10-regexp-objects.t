#!perl -T
do './t/jstest.pl' or die __DATA__

// See also the regexp tests in non-ecma.t.

function joyne (sep,ary) { // Unlike the built-in, this does not convert
	var ret = '';      // undefined to an empty string.
	if(!(ary instanceof Array))return ary;
	for(var i = 0; i<ary.length;++i)ret +=(i?sep:'')+ary[i]
	return ret
}

// ====================================================================
// The extra-ECMA properties of the RegExp constructor (those beginning
// with $ and, where applicable, their alphabetical counterparts)
// We have to put these at the top of the file to test the initial values.
// 31 tests (not including the first few tests that have their own counts)
// ====================================================================

vars = [ // there are 17 of these
 "$'",'$`','$&','$+','$1','$2','$3','$4','$5','$6','$7','$8','$9',
 'lastMatch','lastParen','leftContext','rightContext'
];

// check for undeletability and initial values
// 34 tests
for(var i in vars)
 is(delete RegExp[vars[i]], false, vars[i] + ' is undeletable'),
 ok(RegExp[vars[i]] === '', vars[i] + ' is the empty string initially');

/(.)/.test("foo"); is(RegExp.$1, "f", '$1 after test');
is(
  RegExp.$1.length, 1,
 'length of RegExp.$1 (and $1 is not booby-trapped)' // (At first I was
);                              // using Perl scalars internally instead of
            // JE::Strings, causing problems in cases like this.)

/(.)/.exec("oo"); is(RegExp.$1, "o", '$1 after exec')
"abcdefg".search(/(.)/); is(RegExp.$1, "a", '$1 after search')

// replace
"abcdefg".replace(/(.)/g,"");
is(RegExp.$1, "g", '$1 after global str replace')
"abcdefg".replace(/(.)/,"");
is(RegExp.$1, "a", '$1 after single str replace')
var stuff = []
"abcdefg".replace(/(.)/g,function(){ stuff.push(RegExp.$1) });
is(stuff, 'a,b,c,d,e,f,g','$1 during global function replace')
stuff = []
"abcdefg".replace(/(.)/,function() { stuff.push(RegExp.$1) });
is(stuff, "a", '$1 after single replace with function')
name = 'only successful replacements must update the vars' // (at one point
// during developement, this caused ‘substr outside of string’ errors)
try{
  RegExp['$`'] = 'abcdef';
 "-7".replace(/\t/g,'%09');
 is(RegExp['$`'], 'abcdef', name)
}catch(ueo) { fail(name) }

"abcdefg".match(/(.)/); is(RegExp.$1, "a", '$1 after match')
"abcdefg".match(/(d)(.)/);
is(RegExp.lastMatch, 'de', 'RegExp.lastMatch');
is(RegExp['$&'], 'de', 'RegExp["$&"]');
is(RegExp.lastParen, 'e', 'RegExp.lastParen');
is(RegExp['$+'], 'e', 'RegExp["$+"]');
is(RegExp.leftContext, 'abc', 'leftContext');
is(RegExp['$`'], 'abc', '$`');
is(RegExp.rightContext, 'fg', 'rightContext');
is(RegExp['$\''], 'fg', '$\'');
is(RegExp.$2, 'e', '$2');

// Aliasing
vars
 = {
    lastMatch: '$&', lastParen: '$+', leftContext: '$`', rightContext: "$'"
   }
for(
 var i
  in
 vars
)
 RegExp[i] = 'jile',
 is(RegExp[vars[i]], 'jile', vars[i] + ' is aliased to ' + i),
 RegExp[vars[i]] = 'squew',
 is(RegExp[i], 'squew', i + ' is aliased to ' + vars[i]),
 isnt(
  peval("($::other_je ||= new JE)->{RegExp}{'" + i + "'}"), RegExp[i],
  i + ' is not shared between envs'
 );


// ===================================================
// 15.10.1 Pattern compilation
// 15 tests
// ===================================================

(function(){
function tcp /*try compiling pattern*/(re,tn/*test name*/) {
	try{ RegExp(re); pass('compilation of ' + tn)}
	catch(foo){fail('compilation of ' + tn), diag(foo)}
}

tcp('foo','alternative')
tcp('foo|foo','two-part disjunction')
tcp('foo|foo|foo','three-part disjunction')
tcp('','empty pattern')
tcp('^$\\b\\B','assertions')
tcp('f*o*?o+b+?a?r??b{0}a{33}?z{32,}a{98,}?o{6,7}e{32,54}?','quantifiers')
tcp('\nf\u0100\ud801.(foo)(?:foo)(?=foo)(?!foo)', 'atoms')
tcp("\\0\\9()()()()()()()()()", 'decimal escapes')
tcp("\\f\\n\\r\\t\\v", 'control escapes')
tcp('\\ca\\cb\\cc\\cd\\ce\\cf\\cg\\ch\\ci\\cj\\ck\\cl\\cm\\cn\\co\\cp\\cq'
   +'\\cr\\cs\\ct\\cu\\cv\\cw\\cx\\cy\\cz', 'lc control letter escapes')
tcp('\\cA\\cB\\cC\\cD\\cE\\cF\\cG\\cH\\cI\\cJ\\cK\\cL\\cM\\cN\\cO\\cP\\cQ'
   +'\\cR\\cS\\cT\\cU\\cV\\cW\\cX\\cY\\cZ', 'uc control letter escapes')
tcp('\\x00\\u1234','hex & unicode escapes')
tcp('\\ \\\n\\.\\\ud801','identity escapes')
tcp('\\d\\D\\s\\S\\W\\W','character class escapes')
tcp('[foo][^bar][^][-][\nb][\u0100-\ud801][\1\b\f][\da-z]','char classes')

}())

// ===================================================
// 15.10.2.3 Disjunction
// 4 tests
// ===================================================

is(/foo|bar/.exec("foo")[0], 'foo',
	'disjunction w/left-hand side matching')
is(/foo|bar/.exec("bar")[0], 'bar',
	'disjunciton w/right-hand side matching')
is(/a|ab/.exec('abc'), 'a', 'disjunction (example in the spec.)')
is(joyne(',',/((a)|(ab))((c)|(bc))/.exec('abc')),
	'abc,a,a,undefined,bc,undefined,bc',
	'disjunction (another example in the spec.)')


// ===================================================
// 15.10.2.4 Alternative
// 2 tests
// ===================================================

is(new RegExp('').exec('abcdefg'), '', 'empty pattern')
is(/[xy]?(y|x)/.exec('yx')[1], 'x', 'backtracking within an alternative')


// ===================================================
// 15.10.2.5 Term
// ===================================================

// 2 tests: Term :: Assertion
ok(/x\b/.exec('x '),'term with matching assertion')
ok(!/x\b/.exec('xy'),'term with failing assertion')

// 2 tests: Term :: Atom Quantifier
try{new RegExp('a{3,2}'); pass('skipped on this perl: {n,m} where n > m')}
catch(cold){ok(cold instanceof SyntaxError, '{n,m} where n > m')}
is(/f{0}/.exec('abcdefg'), '', 'quantifier with 0 max')

// 4 tests: RepeatMatcher
is(/f{0,3}/.exec('ffff'), 'fff',
	'greedy quantifier that reaches its maximum')
is(/o{0,3}/.exec('oo'), 'oo',
	'greedy quantifier that falls short of its maximum')
is(/f{1,3}?/.exec('ffff'), 'f',
	'stingy quantifier that meets its minimum')
is(/o{1,3}?$/.exec('oo'), 'oo',
	'stingy quantifier that exceeds its minimum')

// 7 tests: Examples from the spec.
is(/a[a-z]{2,4}/.exec('abcdefghi'), 'abcde', 'term (example in the spec.)')
is(/a[a-z]{2,4}?/.exec('abcdefghi'), 'abc',
	'term (stingy example in the spec.)')
is(/(aa|aabaac|ba|b|c)*/.exec('aabaac'), 'aaba,ba',
	'term (choice point ordering example)')
is('aaaaaaaaaa,aaaaaaaaaaaaaaa'.replace(/^(a+)\1*,\1+$/,"$1"), 'aaaaa',
	'term (gcm example)')
is(joyne(',',/(z)((a+)?(b+)?(c))*/.exec("zaacbbbcac")), 
	'zaacbbbcac,z,ac,a,undefined,c', 'capture erasure')
is(/(a*)*/.exec('b'), ',', 'term (infinite loop example)')
is(/(a*)b\1+/.exec('baaaac'), 'b,', 'term (second infinite loop example)')

// 9 tests: Some more capture erasure tests
is(joyne(',',/((a)?b)+/.exec('abb')),'abb,b,undefined',
	'capture erasure ((a)?b)+')
is(joyne(',',/((a+)?b)+/.exec('abb')),'abb,b,undefined',
	'capture erasure ((a+)b)+')
is(joyne(',',/((?:|(a))b)+/.exec('abb')), 'abb,b,undefined',
	'capture erasure ((?:|(a))b)+')
is(joyne(',','ba'.match(/(a|(b))+/)),'ba,a,undefined',
	'capture erasure (a|(b))+')
is('cbazyx'.replace(/(a|(b))+/, "$1$2"), 'cazyx',
	'capture erasure with String.prototype.replace')
is('cbazyx'.replace(/(a|(b))+/,
    function($and,$1,$2){return $1+$2}), 'cazyx',
   'capture erasure w/String.prototype.replace w/ a function replacement')
is(joyne(',','cbazyx'.split(/(a|(b))+/)), 'c,a,undefined,zyx',
	'capture erasure String.prototype.split')
is(joyne(',',/(?:a(b)?bc)+/.exec('abbcabc')), 'abbcabc,undefined',
	'capture erasure with backtracking')
is(joyne(',',/(?:a(b)?bc)+..c/.exec('abbcabc')), 'abbcabc,b',
	'make sure backtracking does not cause undue capture erasure')


// ===================================================
// 15.10.2.6 Assertion
// ===================================================

// 7 tests: ^
is('foo\nbar'.search(/^/), 0, '^ at beginning of string')
is('foo\nbar'.search(/^/m), 0, '/^/m at beginning of string')
is('foo\nbar'.search(/.^/), -1, '^ without m fails after beginning')
is('foo\nbar'.match(/[^]^/m), '\n', '/^/m matches an lf')
is('foo\rbar'.match(/[^]^/m), '\r', '/^/m matches a cr')
is('foo\u2028bar'.match(/[^]^/m), '\u2028', '/^/m matches an ls')
is('foo\u2029bar'.match(/[^]^/m), '\u2029', '/^/m matches a ps')

// 7 tests: $
is('foo\nbar'.search(/$/), 7, '$ at end of string')
is('foobar'.search(/$/m), 6, '/$/m at end of string')
is('foo\nbar'.search(/$\n/), -1, '$ without m fails before end of str')
is('foo\nbar'.match(/$[^]/m), '\n', '/$/m matches an lf')
is('foo\rbar'.match(/$[^]/m), '\r', '/$/m matches a cr')
is('foo\u2028bar'.match(/$[^]/m), '\u2028', '/$/m matches an ls')
is('foo\u2029bar'.match(/$[^]/m), '\u2029', '/^/m matches a ps')

// 7 tests: \b
is('a'.search(/^\b/), 0, 'successful \\b at beginning of string')
is('a'.search(/\b$/), 1, 'successful \\b at end of string')
is('.'.search(/^\b/), -1, 'failed \\b at beginning of string')
is('.'.search(/\b$/), -1, 'failed \\b at end of string')
is('føø'.search(/(?!^)\b/), 1,
	'non-ASCII chars following \\b are not word chars')
is('føo'.search(/\b.$/), 2,
	'non-ASCII chars preceding \\b are not word chars')
is('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890_'
	.search(/(?!^)\b/), 63, '\\b word chars');

// 7 tests: \B
is('.'.search(/^\B/), 0, 'successful \\B at beginning of string')
is('.'.search(/\B$/), 1, 'successful \\B at end of string')
is('a'.search(/^\B/), -1, 'failed \\B at beginning of string')
is('a'.search(/\B$/), -1, 'failed \\B at end of string')
is('føø'.search(/\B/), 2, // skips past fø
	'non-ASCII chars following \\B are not word chars')
is('ḟoo'.search(/(?!^)\B/), 2,
	'non-ASCII chars preceding \\B are not word chars')
is('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890_'
	.match(/\B/g).length, 62, '\\B word chars');


// ===================================================
// 15.10.2.7 Quantifiers
// 18 tests
// ===================================================

// {n,m} is tested above under 15.10.2.5 Term

is(''.match(/.*/), '', '* minimum')
// We can’t actually test the maximum, because we would need an infinite
// string. This test should suffice, as it’s unlikely that anyone would put
// an arbitrary ‘68’ in the regexp.
is('oeautnnttetttttttttttttttttttttttttttttttttttttttttttttttttttttttttt'
   .match(/.*/)[0].length, 68, '* maximum')
is('aaaaaaaaaaaa'.match(/.*?/), '', '*? minimum')
is('aaaaaaaaaaaaaaaaaaaaaaaaaab'.match(/.*?b/)[0].length, 27, '*? maximum')
is('1'.match(/(.*)(.+)/), '1,,1', '+ minimum')
is('oeautnnttetttttttttttttttttttttttttttttttttttttttttttttttttttttttttt'
   .match(/.+/)[0].length, 68, '+ maximum')
is('zaaaaaaaaaaa'.match(/.+?/), 'z', '+? minimum')
is('aaaaaaaaaaaaaaaaaaaaaaaaaab'.match(/.+?b/)[0].length, 27, '+? maximum')
is('1'.match(/(.?)(.?)/), '1,1,', '? min')
is('abcde'.match(/.?/), 'a', '? max')
is('aaa'.match(/.??/), '', '?? min')
is('abcde'.match(/.??c/), 'bc', '?? max')
is('abc'.match(/.{2}/), 'ab', '{m}')
is('abc'.match(/.{2}?/), 'ab', '{m}?')
is('1234'.match(/.*(.{2,})/), '1234,34', '{m,} minimum')
is('oeautnnttetttttttttttttttttttttttttttttttttttttttttttttttttttttttttt'
   .match(/.{2,}/)[0].length, 68, '{m,} maximum')
is('zaaaaaaaaaaa'.match(/.{2,}?/), 'za', '{m,}? minimum')
is('aaaaaaaaaaaaaaaaaaaaaaaaaab'.match(/.{2,}?b/)[0].length, 27,
	'{m,}? maximum')


// ===================================================
// 15.10.2.8 Atom
// ===================================================

// 7 test
is("\x00 <>1234_ABC-'\xff\u0100\ud800".match(
	/\0 <>1234_ABC-'\xff\u0100\ud800/
), "\x00 <>1234_ABC-'\xff\u0100\ud800", 'characters that match themselves')
is('\u2028\u2029\n\r\f\x00 <>1234_ABC-"\xff\u0100\ud800'.match(/./g)
	.join(''),
   '\f\x00 <>1234_ABC-"\xff\u0100\ud800', '.')
is("owt eerht".match(/((.).)((.).)/), 'owt ,ow,o,t ,t','captures')
is('eeno'.match('(?:...)').length, 1, '(?:)')
is('eeno'.match('(?=ee)ee'), 'ee', '(?=)')
is('aaa aaae'.match('(?=(a*))\\1(a|e)')[0],'aaae',
	'(?=) is not back-tracked into')
is(/(?=(a+))a*b\1/.exec("baaabac"),'aba,a',
	'(?=) is not back-tracked into (ECMAScript example)')

// 6 tests: interrobang groups

is (joyne(',',/(?!(foo)(?!))/.exec('foo')), ',undefined',
	'interrobang with captures');
is (joyne(',',/(?!(a)b)/.exec('ab')), ',undefined',
	'interrobang with captures (another)');
is (joyne(',',/(?!(a)|b)c/.exec('ac')), 'c,undefined',
	'interrobang with captures (yet another)');
is (joyne(',',/(?!(a)(?!)){0}/.exec('a')), ',undefined',
	'quantified interrobang')
is (joyne(',',/(?:(?!(a)(?!)){0})/.exec('a')), ',undefined',
	'quantified interrobang inside another group')
is(peval('my $warnings=0; local $SIG{__WARN__}=sub{++$warnings};'
     + '$je->{RegExp}("(?!(a)(?!))+"); $warnings;'
   ),0, 'quantified interrobangs don\'t warn')


// ===================================================
// 15.10.2.9 AtomEscape
// ===================================================

// 13 tests: DecimalEscape (15.10.2.11) (back-references and \0)

is("\x00".match(/\0/), "\x00", '\\0')

is(	joyne(',',/(.*?)a(?!(a+)b\2c)\2(.*)/.exec("baaabaac")),
 	'baaabaac,ba,undefined,abaac',
	'back-reference to (?!(...))' // example from the spec
)
is(joyne(',',/(?:a|(x))\1/.exec("ab")), 'a,undefined',
	'back-reference to undefined (without interrobang)')
is(joyne(',',/(?:(a)?b\1)+/.exec("abab")), 'abab,undefined',
	'another back-reference-to-undefined test (quantified capture)')
is(/(a{3})b\1/.exec('aaabaa'), null,
	'back-reference to string longer than the number of chars left')
is(/(.)\1/.exec('abba'), 'bb,b',
	'simple successful back-ref; no special cases')
ok(/(.)\1/i.test('iI'), 'case-insensitivity in back-references ...')
ok(!/(.)\1/.test('iI'),' ... but not without /i')
ok(!/(.)\1/i.test('ıI'), 'does not apply to dotlessi')
try{skip("doesn't work", 1);ok(!/(.)\1/i.test('ßSS'), 'nor to double s')}
catch(e){}
is(/()()()()()()()()()()()(.)\12/.exec('abba'), 'bb,,,,,,,,,,,,b',
	'multi-digit back-ref')
is(/(?:\1|(^a)){2}/.exec('aa'), ',', 'forward ref')
	// (with Perl’s behaviour, it produces 'aa,a')
is(/\12()()()()()()()()()()()()/.exec(''), ',,,,,,,,,,,,',
	'multi-digit forward-ref')


// ===================================================
// 15.10.2.10 CharacterEscape
// ===================================================

// 5 tests: ControlEscape
is('	'.match(/\t/), '	', '\\t')
is('\n'.match(/\n/), '\n', '\\n')
is(''.match(/\v/), '', '\\v')
is(''.match(/\f/), '', '\\f')
is('\r'.match(/\r/), '\r', '\\r')

// 4 tests: \cX
is('\x00'.match(/\c@/), '\x00', '\\c@')
is('\x01'.match(/\cA/), '\x01', '\\cA')
is(' '.match(/\c`/), ' ', '\\c`')
is(String.fromCharCode(26).match(/\cz/), String.fromCharCode(26),
	'\\c with lc char')

// ~~~ Need more tests here, for things like ß

// 2 tests: \xHH
is('\x00'.match(/\x00/), '\x00','\\x00')
is('\xff'.match(/\xfF/), '\xff','\\xfF')

// 2 tests: \uHHHH
is('\x00'.match(/\u0000/), '\x00','\\u0000')
is('\uffff'.match(/\ufffF/), '\uffff','\\ufffF')

// 2 test: IdentityEscape
is(' !"#$%&\'()*+,-./;:<=>?@[\\]^_`{|}~¡¢£·'.match(
	/\ \!\"\#\$\%\&\'\(\)\*\+\,\-\.\/\;\:\<\=\>\?\@\[\\\]\^\_\`\{\|\}\~\¡\¢\£\·/), ' !"#$%&\'()*+,-./;:<=>?@[\\]^_`{|}~¡¢£·','IdentityEscapes')
is(' \n.\ud801'.match('\\ \\\n\\.\\\ud801'), ' \n.\ud801',
   'IdentityEscapes including newline and surrogate')


// ===================================================
// 15.10.2.11 DecimalEscape
// ===================================================

// (See .9)

// ===================================================
// 15.10.2.12 CharacterClassEscape
// ===================================================

// 3 tests for \d
is('0123456789'.match(/\d{10}/), '0123456789', '\\d matches 0-9')
is(peval('join "", "\\0".."/",":".."\\xff"').match(/\d/),
  'null',
  '\\d matches no other ascii chars')
is("๕".match(/\d/),
  'null',
  '\\d does not match Unicode digits')

// 3 tests for \D
is('0123456789'.match(/\D/), null, '\\D does not match matches 0-9')
s = peval('join "", "\\0".."/",":".."\\xff"')
is(s.match(RegExp("\\D{" + s.length + "}")), s,
  '\\D matches all other ascii chars')
is("๕".match(/\D/),
   "๕",
   '\\D matches Unicode digits')

// 2 tests for \s
is('\t\v\f  \u2002\n\r\u2028\u2029'.match(/\s{10}/),
   '\t\v\f  \u2002\n\r\u2028\u2029',
   '\\s matches \\t\\v\\f sp nbsp U+2002 lf cr ls ps')
is('aoeu-!@#$1234'.match(/\s/),
  'null',
  '\\s does not match non-whitespace')

// 2 tests for \S
is('\t\v\f  \u2002\n\r\u2028\u2029'.match(/\S/), null,
   '\\S does not match \\t\\v\\f sp nbsp U+2002 lf cr ls ps')
is('aoeu-!@#$1234'.match(/\S{13}/), 'aoeu-!@#$1234',
   '\\S matches non-whitespace')

// 3 tests for \w
is(
 '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_'.match(
   /\w{63}/
  ),
 '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_',
 '\\w matches 0-9a-zA-Z_'
)
is(
  peval('join "", "\\0".."/",":".."@","[".."^","`","{".."\\xff"').match(
   /\w/
  ),
 'null',
 '\\w matches no other ascii chars'
)
is("๕α".match(/\w/),
  'null',
  '\\w does not match Unicode digits or letters')

// 3 tests for \W
is(
 '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_'.match(
   /\W/
  ),
 'null',
 '\\W does not match 0-9a-zA-Z_'
)
s = peval('join "", "\\0".."/",":".."@","[".."^","`","{".."\\xff"')
is(
  s.match(
   RegExp('\\W{'+s.length+'}')
  ),
  s,
 '\\W matches all other ascii chars'
)
is("๕α".match(/\W{2}/),
  '๕α',
  '\\W matches Unicode digits and letters')


// ===================================================
// 15.10.2.13 CharacterClass
// ===================================================

// We are just checking for (lack of) invertedness here. More specific
// tests are in the sections that follow.
// 2 tests
is('cheen'.match(/[chen]+/), 'cheen', 'positive char class')
is('cheen'.match(/[^chen]/), 'null', 'negative char class')

// ===================================================
// 15.10.2.14 ClassRanges
// ===================================================

// 2 tests for empty class ranges
is(peval('join "", map chr, 0..255').match(/[^]+/)[0].length, 256, '[^]')
is(peval('join "", "\\0".."\\xff"').match(/[]/), null, '[]')

// ===================================================
// 15.10.2.15 NonemptyClassRanges
// 15.10.2.16 NonemptyClassRangesNoDash
// 15.10.2.17 ClassAtom
// 15.10.2.18 ClassAtomNoDash
// ===================================================

// 2 tests
// This is a syntax error according to ECMAScript, but we support it any-
// way. See RT #51123.
name =  '- adjacent to \\w in char classes';
try{ ok(RegExp('[\\w-\\d]').test('-'),name) }
catch(e) { fail(name) }
// and a bug we almost introduced while adding this feature:
ok( /[\n-\r]/.test('\v'), '[\\n-\\r] is a range' )

// 10 tests
is(peval('join "", map chr, 0..255').match(/[d]+/)[0], 'd',
  'class with single character')
ok(/[-a]/.test('-'), 'hyphen at the beginning of a class')
ok(/[a-]/.test('-'), 'hyphen at the end of a class')
// This test is for completeness’ sake: It exercises the
// NonemptyClassRangesNoDash :: ClassAtomNoDash NonemptyClassRangesNoDash
// production in the grammar (that we don’t use anyway :-):
ok(/[ax-]/.test('-'),
 'hyphen at the end of a class (with at least 2 things before it)')
ok(/[a-c]/.test('b'),
 'hyphen after a ClassAtom (but not at the end) is a range')
// Another ‘completeness’ test:
// NonemptyClassRangesNoDash :: ClassAtomNoDash - ClassAtom ClassRanges
ok(/[xa-c]/.test('b'),
 'hyphen w/2 things b4 it (but not at the end) is a range')
name = 'inverted ranges';
try{ RegExp('[b-a]'); fail(name)}
catch(e) { ok(e instanceof SyntaxError, name) }
is("EFefi".match(/[E-F]+/i)[0],'EFef', 'class ranges are unaffected by /i')
is("SPRIThile[\\]^_`".match(/[E-f]+/i)[0], 'SPRIThile[\\]^_`',
 '/[A-b]/i where A is capital and b is lc matches A-Z a-z [ \\ ] ^ _')
ok(!/[.]/.test("s"), '[.] does not match "s"')


// ===================================================
// 15.10.2.14 ClassEscape
// ===================================================

// 7 tests for single-char escapes
is("\u0000".match(/[\0]/)[0], "\u0000", 'ClassEscape :: DecimalEscape')
is("\u0008".match(/[\b]/)[0], "\u0008", 'ClassEscape :: b')
is("\u0009".match(/[\t]/)[0], "\u0009", '[\\t]')
is("\u000A".match(/[\n]/)[0], "\u000a", '[\\n]')
is("\u000b".match(/[\v]/)[0], "\u000b", '[\\v]')
is("\u000c".match(/[\f]/)[0], "\u000c", '[\\f]')
is("\u000d".match(/[\r]/)[0], "\u000d", '[\\r]')

// 4 tests: [\cX]
is('\x00'.match(/[\c@]/), '\x00', '[\\c@]')
is('\x01'.match(/[\cA]/), '\x01', '[\\cA]')
is(' '.match(/[\c`]/), ' ', '[\\c`]')
is(String.fromCharCode(26).match(/[\cz]/), String.fromCharCode(26),
	'[\\c] with lc char')

// 2 tests: [\xHH]
is('\x00'.match(/[\x00]/), '\x00','[\\x00]')
is('\xff'.match(/[\xfF]/), '\xff','[\\xfF]')

// 2 tests: \uHHHH
is('\x00'.match(/[\u0000]/), '\x00','[\\u0000]')
is('\uffff'.match(/[\ufffF]/), '\uffff','[\\ufffF]')

// 1 test: IdentityEscape
is(' !"#$%&\'()*+,-./;:<=>?@[\\]^_`{|}~¡¢£·'.match(
 /[\ \!\"\#\$\%\&\'\(\)\*\+\,\-\.\/\;\:\<\=\>\?\@\[\\\]\^\_\`\{\|\}\~\¡\¢\£\·]+/
), ' !"#$%&\'()*+,-./;:<=>?@[\\]^_`{|}~¡¢£·','IdentityEscapes')

// 3 tests for [\d]
is('0123456789'.match(/[\d]{10}/), '0123456789', '[\\d] matches 0-9')
is(peval('join "", "\\0".."/",":".."\\xff"').match(/[\d]/),
  'null',
  '[\\d] matches no other ascii chars')
is("๕".match(/[\d]/),
  'null',
  '[\\d] does not match Unicode digits')

// 3 tests for [\D]
is('0123456789'.match(/[\D]/), null, '[\\D] does not match matches 0-9')
s = peval('join "", "\\0".."/",":".."\\xff"')
is(s.match(RegExp("[\\D]{" + s.length + "}")), s,
  '[\\D] matches all other ascii chars')
is("๕".match(/[\D]/),
   "๕",
   '[\\D] matches Unicode digits')

// 2 tests for [\s]
is('\t\v\f  \u2002\n\r\u2028\u2029'.match(/[\s]{10}/),
   '\t\v\f  \u2002\n\r\u2028\u2029',
   '[\\s] matches \\t\\v\\f sp nbsp U+2002 lf cr ls ps')
is('aoeu-!@#$1234'.match(/\s/),
  'null',
  '[\\s] does not match non-whitespace')

// 2 tests for [\S]
is('\t\v\f  \u2002\n\r\u2028\u2029'.match(/[\S]/), null,
   '[\\S] does not match \\t\\v\\f sp nbsp U+2002 lf cr ls ps')
is('aoeu-!@#$1234'.match(/[\S]{13}/), 'aoeu-!@#$1234',
   '[\\S] matches non-whitespace')

// 3 tests for [\w]
is(
 '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_'.match(
   /[\w]{63}/
  ),
 '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_',
 '[\\w] matches 0-9a-zA-Z_'
)
is(
  peval('join "", "\\0".."/",":".."@","[".."^","`","{".."\\xff"').match(
   /[\w]/
  ),
 'null',
 '[\\w] matches no other ascii chars'
)
is("๕α".match(/[\w]/),
  'null',
  '[\\w] does not match Unicode digits or letters')

// 3 tests for [\W]
is(
 '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_'.match(
   /[\W]/
  ),
 'null',
 '[\\W] does not match 0-9a-zA-Z_'
)
s = peval('join "", "\\0".."/",":".."@","[".."^","`","{".."\\xff"')
is(
  s.match(
   RegExp('[\\W]{'+s.length+'}')
  ),
  s,
 '[\\W] matches all other ascii chars'
)
is("๕α".match(/[\W]{2}/),
  '๕α',
  '[\\W] matches Unicode digits and letters')


// ===================================================
// 15.10.3 RegExp()
// ===================================================

// 2 test
r = /scrat/
ok(RegExp(r) === r, 'RegExp(re) returns a regexp unchanged')
ok(RegExp('r').constructor == RegExp,
  'RegExp with anything else calls new RegExp')


// ===================================================
// 15.10.4.1 new RegExp
// ===================================================

// 10 tests for new RegExp(re)
r2 = new RegExp(r = /a/)
ok(r !== r2, 'new RegExp(re) copies the re')
is(r, r2, 'the new re stringifies the same way')
is(r2.global, false, 'the global flag is copied (false)')
is(r2.ignoreCase, false, 'the /i flag is copied (false)')
is(r2.multiline, false, 'the /m flag is copied (false)')
r2 = new RegExp(/a/gim)
is(r2.global, true, 'the global flag is copied (true)')
is(r2.ignoreCase, true, 'the /i flag is copied (true)')
is(r2.multiline, true, 'the /m flag is copied (true)')
is(r2=new RegExp(r,undefined), r, 'explicit undefined 2nd arg ... ')
ok(r2 !== r, ' ... copies the re')

// 1 test for new RegExp(re,something)
name = "new RegExp(re,something) dies with a TypeError"
try { new RegExp(/a/,3); fail(name) }
catch(e) { ok (e instanceof TypeError, name) }

// 12 tests for new RegExp(something, ...)
r = new RegExp('a')
is(r.global + '' + r.ignoreCase + r.multiline, 'falsefalsefalse',
  'flags set by new RegExp when 2nd arg is omitted')
is('a'.match(r), 'a', 'RegExp created from a string')
r = new RegExp(12.0,'gim')
is(r.global + '' + r.ignoreCase + r.multiline, 'truetruetrue',
  'flags set by new RegExp when 2nd arg is gim')
is('12'.match(r), '12', 'RegExp created from a number')
r = new RegExp(true,'mig')
is(r.global + '' + r.ignoreCase + r.multiline, 'truetruetrue',
  'flags set by new RegExp when 2nd arg is mig')
is('true'.match(r), 'true', 'RegExp created from a bouillon')
r = new RegExp({},'i')
is(r.global + '' + r.ignoreCase + r.multiline, 'falsetruefalse',
  'flags set by new RegExp when 2nd arg am i')
is('T'.match(r), 'T', 'RegExp created from a nobject')
is('NULL'.match(new RegExp(null,'i')), 'NULL', 're created from null')
is('NULL'.match(new RegExp(void 0)), '', 're created from undef')
is('NULL'.match(new RegExp), '', 'new RegExp with no args')
r = new RegExp({},new String("mg"))
is(r.global + '' + r.ignoreCase + r.multiline, 'truefalsetrue',
  'flags set when second arg to new RegExp is an object')

// 5 tests for syntax errors
name = "new RegExp(something, non-ident) dies with a SyntaxError"
try { diag(new RegExp('','$')); fail(name) }
catch(e) { ok (e instanceof SyntaxError, name)||diag(e) }
name = "new RegExp(something, invalid flags) dies with a SyntaxError"
try { diag(new RegExp('','é')); fail(name) }
catch(e) { ok (e instanceof SyntaxError, name)||diag(e) }
// By Pattern with a capital P I am referring to the Pattern production in
// ECMAScript.
name = "new RegExp(invalid Pattern) dies with a SyntaxError"
try { diag(new RegExp(')))')); fail(name) }
catch(e) { ok (e instanceof SyntaxError, name)||diag(e) }
// These following examples match the Pattern production, but are still
// syntax errors.
name = "new RegExp(pattern with {3,2}) dies with a SyntaxError"
try { diag(new RegExp('a{3,2}')); pass("skipped on this perl: " + name) }
catch(e) { ok (e instanceof SyntaxError, name)||diag(e) }
name = "new RegExp(pattern with [b-a]) dies with a SyntaxError"
try { diag(new RegExp('[b-a]')); fail(name) }
catch(e) { ok (e instanceof SyntaxError, name)||diag(e) }

// 4 tests for setting source
ok (new RegExp('a').source === 'a', 'source of new RegExp')
ok (new RegExp('/').source === '\\/', 'source of new RegExp with /')
ok (new RegExp('\\/').source === '\\/', 'source of new RegExp with \\/')
ok (new RegExp('\\\\/').source === '\\\\\\/',
   'source of new RegExp with \\\\/')

// 2 tests for setting lastIndex
ok (new RegExp('a').lastIndex === 0, 'lastIndex is initially 0')
ok (new RegExp('a','g').lastIndex === 0, 'lastIndex is 0 with /g, too')

// 2 tests: internal props
ok(peval('shift->prototype', new RegExp) === RegExp.prototype,
  '[[Prototype]] of new RegExp')
is({}.toString.call(new RegExp), '[object RegExp]',
  '[[Class]] of new RegExp');


// ===================================================
// 15.10.5 RegExp
// ===================================================

// 10 tests (boilerplate stuff for constructors)
is(typeof RegExp, 'function', 'typeof RegExp');
is(Object.prototype.toString.apply(RegExp), '[object Function]',
	'class of RegExp')
ok(RegExp.constructor === Function, 'RegExp\'s prototype')
ok(RegExp.length === 2, 'RegExp.length')
ok(!RegExp.propertyIsEnumerable('length'),
	'RegExp.length is not enumerable')
ok(!delete RegExp.length, 'RegExp.length cannot be deleted')
is((RegExp.length++, RegExp.length), 2, 'RegExp.length is read-only')
ok(!RegExp.propertyIsEnumerable('prototype'),
	'RegExp.prototype is not enumerable')
ok(!delete RegExp.prototype, 'RegExp.prototype cannot be deleted')
ok((RegExp.prototype = 24, RegExp.prototype) !== 24,
	'RegExp.prototype is read-only')


// ===================================================
// 15.10.6 RegExp.prototype
// ===================================================

// 3 tests
is(Object.prototype.toString.apply(RegExp.prototype), '[object Object]',
	'class of RegExp.prototype')
ok(RegExp.prototype.valueOf === Object.prototype.valueOf, 'valueOf')
peval('is shift->prototype, shift, "RegExp.prototype\'s prototype"',
	RegExp.prototype, Object.prototype)

// ===================================================
// 15.10.6.1 RegExp.prototype.constructor
// ===================================================

// 2 tests
ok(RegExp.prototype.constructor === RegExp, 'RegExp.prototype.constructor')
ok(!RegExp.prototype.propertyIsEnumerable('constructor'),
	'RegExp.prototype.constructor is not enumerable')

// ===================================================
// 15.10.6.2 exec
// ===================================================

// 10 tests
method_boilerplate_tests(RegExp.prototype,'exec',1)

// 4 tests for misc this values
0,function(){
	var f = RegExp.prototype.exec;
	var testname='exec with number for this';
	try{f.call(8); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='exec with non-re object for this';
	try{f.call({}); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='exec with string for this';
	try{f.call('true'); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='exec with bool for this';
	try{f.call('true'); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
}()

// 1 test: Make sure exec can be called */

try{is(/a/.exec('a'), 'a', 'exec doesn\'t simply die')}
catch(e){fail('exec doesn\'t simply die')}

// 6 tests: various types for the arg
is(/..o/i.exec({}), 't O', 'exec with object arg')
is(/T/i.exec(true), 't', 'exec with boolean arg')
is(/[89]/i.exec(78), '8', 'exec with numeric arg')
is(/U/i.exec(null), 'u', 'exec with null arg')
is(/U./i.exec(void 0), 'un', 'exec with undefined arg')
is(/U./i.exec(), 'un', 'exec with no arg')

// 19 tests: exec and lastIndex
r = /a./
r.lastIndex=2
is(r.exec("the abacus"), 'ab', 'exec ignores lastIndex without /g')
rg = /a./g
rg.lastIndex=6
is(rg.exec("the abacus"), "ac", 'exec respects lastIndex with /g')
is(typeof rg.lastIndex + ': ' + rg.lastIndex, 'number: 8',
  'exec sets lastIndex')
rg.lastIndex=1.9
is(rg.exec('aah'), 'ah', 'exec with fractional lastIndex')
rg.lastIndex=57
is(rg.exec('abc'), null, 'exec with large lastIndex')
is(rg.lastIndex, 0,'exec with large lastIndex resets index to 0')
r.lastIndex=57
r.exec('the')
is(r.lastIndex, 0,'exec failure resets lastIndex even without /g')
rg.lastIndex=-5
is(rg.exec('abc'), null, 'exec with negative lastIndex')
is(rg.lastIndex, 0,'exec with negative lastIndex resets index to 0')
rg.lastIndex=NaN
is(rg.exec('abc'), 'ab', 'exec with NaN lastIndex')
;(rg2=/./g).lastIndex=Infinity
is(rg2.exec('abc'), null, 'exec with infinite lastIndex')
;(rg2=/(?:)/g).lastIndex=4
is(rg2.exec('abc'), null, 'exec with large lastIndex and null pattern')
r.lastIndex="57"
is(r.exec("abc"), "ab", 'exec ignores lastIndex without /g')
is(typeof r.lastIndex + ': ' + r.lastIndex, "string: 57",
  'successful exec without /g leaves lastIndex untouched');
rg.lastIndex="1"; is(rg.exec('abac'), 'ac', 'exec with string lastIndex')
rg.lastIndex=true; is(rg.exec('abac'), 'ac', 'exec with bool lastIndex')
rg.lastIndex=null; is(rg.exec('abac'), 'ab', 'exec with null lastIndex')
rg.lastIndex={}; is(rg.exec('abac'), 'ab', 'exec w/ objective lastIndex')
rg.lastIndex=void 0; is(rg.exec('abac'), 'ab', 'exec with undef lastIndex')

// 9 tests for the return value
r = /(u)(.)(.)/.exec(new String("squow"))
ok(r.constructor === Array, 'exec retval is an array')
is(r.length, 4, 'exec retval is one more than the number of captures')
ok(r.input === 'squow', 'exec retval .input is a plain string')
ok(r.index === 2, 'index property of exec retval')
is(r[0], 'uow', 'first elem of exec retval')
is(r[1], 'u', 'Subsequent elements of the return value of')
is(r[2], 'o', 'exec contain the  captured')
is(r[3], 'w', 'substrings.')
ok(!(4 in r), 'only as many positive int props as there are captures')

// 2 tests: function-style call (implicit exec)
is(
  /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/("11.12.13.14"),
 "11.12.13.14,11,12,13,14",
 'regexp()'
)
is(
  {foo:/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/}.foo("11.12.13.14"), 
 "11.12.13.14,11,12,13,14",
 'object.regexp()'
)

// 1 test
error = false
try{RegExp.prototype.exec.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'exec death')


// ===================================================
// 15.10.6.3 test
// 2 tests
// ===================================================

// 10 tests
method_boilerplate_tests(RegExp.prototype,'test',1)

// 4 tests for misc this values
0,function(){
	var f = RegExp.prototype.test;
	var testname='test with number for this';
	try{f.call(8); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='test with non-re object for this';
	try{f.call({}); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='test with string for this';
	try{f.call('true'); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='test with bool for this';
	try{f.call('true'); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
}()

ok(/(.)(.)(.)+/.test("abcd") === true, 'test returning true')
ok(/./.test("\n") === false, 'test returning false');

// 1 test
error = false
try{RegExp.prototype.test.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'test death')


// ===================================================
// 15.10.6.4 toString
// ===================================================

// 10 tests
method_boilerplate_tests(RegExp.prototype,'toString',0)

// 4 tests for misc this values
0,function(){
	var f = RegExp.prototype.toString;
	var testname='toString with number for this';
	try{f.call(8); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toString with non-re object for this';
	try{f.call({}); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toString with string for this';
	try{f.call('true'); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toString with bool for this';
	try{f.call('true'); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
}()

// 31 tests
;(function(){
	var re_strs =("/a/i /a/g /a/m /a/mg /a/gi /a/mi /a/mgi /a/ "
	            + "/^[^a]/ /^[^a]/m /$[$]/ /$[$]/m /\\b[\\b]/ /\\B/ "
	            + "/.[.]/ /\\v[\\v]/ /\\n[\\n]/ /\\r[\\r]/ "
	            + "/\\c`[\\c`]/ /\\u1234[\\uabcD]/ /\\d[\\d]/ "
	            + "/\\D[\\D]/ /\\s[\\s]/ /\\S[\\S]/ /\\w[\\w]/ "
	            + "/\\W[\\W]/ /[^]/ /[.a]/ /[a]/ /[.]/ /[\\D\\W]/"
	             )
	.split(' ');
	for (var i = 0;i<re_strs.length;++i)
		is(eval(re_strs[i]).toString(),re_strs[i],
			re_strs[i]+'.toString()');
}())

// 3 tests
ok (new RegExp('/').toString() === '/\\//',
   'toString of new RegExp with /')
ok (new RegExp('\\/').toString() === '/\\//',
   'toString of new RegExp with \\/')
ok (new RegExp('\\\\/').toString() === '/\\\\\\//',
   'toString of new RegExp with \\\\/')

// 1 test
error = false
try{RegExp.prototype.toString.apply([])}
catch(e){error = e}
ok(error instanceof TypeError, 'toString death')


// ===================================================
// 15.10.7 Properties of individual regexps
// ===================================================

r = / /;

// 15 tests
is(delete r.lastIndex, false, 'lastIndex is undeletable')
r.lastIndex = o = {}
ok(r.lastIndex == o, 'lastIndex is writable')
ok(!r.propertyIsEnumerable('lastIndex'), 'lastIndex is not enumerable')
for(k in {source:0, global:0, ignoreCase:0, multiline:0}) {
 is(delete r[k], false, k + ' is undeletable')
 what_it_was = r[k]
 is((r[k] = 'delp', r[k]), what_it_was, k + ' is read-only')
 ok(!r.propertyIsEnumerable('k'), k + ' is not enumerable')
}


// ===================================================
// Perl features that begin with (
// (The regexp-munging has special cases for most of these, so we have
// to test them individually.)  
// 60 tests
// ===================================================

is(new RegExp("fo(?#(li)o").exec('foo'), 'foo', '(?#...)');
is(/f(?im-sx)Oo/.exec('foo'), 'foo', '(?mod)')
is(RegExp("f(?i:(O))o").exec('foo'), 'foo,o','(?mod:)');
is(/.(?<=(f)oo)/.exec('foo'), 'o,f', '(?<=)')
is( /(?<!f(o)o)bar./ .exec('foobarrbard')[0], 'bard', '(?<!)')
is(/(foo)(?(1)bar)(baz)?(?(2)(bonk))ers/.exec('phfoobarers'),
	'foobarers,foo,,', '(?())')
is(/(foo)(?(1)bar|(ba))(?(2)(x)|y)/.exec('foobarx foobary'),
	'foobary,foo,,', '(?()|)')
is(/(?>()a+)(?<!aaa)../.exec('aaaaa aabc'), 'aabc,', '(?>)')

// ( ?...) is deprecated in 5.18 and an error in 5.20
try{peval('$]')>=5.017&&skip('Perl version >= 5.17',8)
 // You can’t put regexp literals here because they will cause com-
 // pilation to fail in 5.20 onwards.
 is(new RegExp("(?x)fo( ?#(li)o").exec('foo'), 'foo', '( ?#...)');
 is(RegExp('(?x)f( ?im-sx)Oo').exec('foo'), 'foo', '( ?mod)')
 is(RegExp("(?x)f( ?i:(O))o").exec('foo'), 'foo,o','( ?mod:)');
 is(RegExp('.( ?<=(f)oo)','x').exec('foo'), 'o,f', '( ?<=)')
 is(RegExp('( ?<!f(o)o)bar.','x').exec('foobarrbard')[0], 'bard', '( ?<!)')
 is(RegExp('(foo)( ?(1)bar)(baz)?( ?(2)(bonk))ers','x')
	.exec('phfoobarers'),
	'foobarers,foo,,', '( ?())')
 is(RegExp('(foo)( ?(1)bar|(ba))( ?(2)(x)|y)','x').exec('foobarx foobary'),
	'foobary,foo,,', '( ?()|)')
 is(RegExp('( ?>()a+)(?<!aaa)..','x').exec('aaaaa aabc'), 'aabc,', '( ?>)')
}catch($){}

function dies(what,name,like,instance_of) {
	try{ eval(what); fail(name); diag(name + ' doesn\'t die') }
	catch($at){ 
		if(like) ok(($at+'').match(like),name) || diag($at)
		if(instance_of) ok($at instanceof instance_of,
			name + ' error type') || diag($at)
	}
}
dies('/(?{})/', '(?{})', 'mbedded', SyntaxError)
dies('/(??{})/', '(??{})', 'mbedded', SyntaxError)
dies('/(?p{})/', '(?p{})', 'mbedded', SyntaxError)
dies('/( ?{})/x', '( ?{})', 'mbedded|adjacent', SyntaxError)
dies('/( ??{})/x', '( ??{})', 'mbedded|adjacent', SyntaxError)
dies('/( ?p{})/x', '( ?p{})', 'mbedded|adjacent', SyntaxError)
dies('/(?(?{}))/', '(?({}))', 'mbedded|adjacent', SyntaxError)

// These five (ten tests) don’t actually work in Perl, but if they ever do
// work we need to block them:
0,function(){
	var a  = ['/(?(??{}))/','/(?(?p{}))/','/(?( ?{}))/x',
	          '/(?( ??{}))/x','/(?( ?p{}))/x']
	for(var i = 0; i < a.length; ++ i)
		try{
			if(peval('use re "eval";' + a[i] + ";1"))
				dies(a[i],a[i],'mbedded')
			else skip ('unnecessary',2)
		}catch(e){}
}()

try{peval('$]')<5.01&&skip('Perl version < 5.10',20)
	// You can’t put regexp literals here because they will cause com-
	// pilation to fail in 5.8.x.
	try{skip('not yet supported', 2);
		is(joyne(',',
		     RegExp('(?|(f)(o)(o)|(b)a(r))+').exec('foobar')
		   ), 'foobar,b,undefined', '(?|)')
		is(joyne(',',
		     RegExp('(?x)( ?|(f)(o)(o)|(b)a(r))+').exec('foobar')
 		   ), 'foobar,b,undefined', '( ?|)')
	}catch(eoneou){}
	is(RegExp('foo(?0)?bar').exec('phoofoofoobarbarbarr'),
		'foofoobarbar', '(?0)')
	is(RegExp('foo(?R)?bar').exec('phoofoofoobarbarbarr'),
		'foofoobarbar', '(?R)')
	is(RegExp('foo(?1)bar|(baz)(?!)').exec('phoofoobazbarbump'),
		'foobazbar,', '(?1)')
	is(RegExp('()foo(?+1)bar|(baz)(?!)').exec('hoofoobazbarbump'),
		'foobazbar,,', '(?+1)')
	is(RegExp('()(baz)(?!)()|foo(?-2)bar').exec('ofoobazbarbump'),
		'foobazbar,,,', '(?-2)')
	is(RegExp('a+(*PRUNE)(?<!aaa)..').exec('aaaaa aabc'), 'aabc',
		'(*PRUNE)')
	is(RegExp('(.)\\1*(*:foo)(?:b(*SKIP:foo)(*FAIL)|c)')
		.exec('aaabbbccc')[0],
	  'bbbc', '(*:foo) (*bar:baz) (*bonk) syntax')
	is(RegExp(
	     "(?'foo'f..)(?<bar>b..)(?P<baz>p..)(?&foo)(?&bar)(?&baz)"
	   ).exec('   fgcbmwpyffgcbmwpyf.fedei'),
	   'fgcbmwpyffgcbmwpyf,fgc,bmw,pyf', 'named captures'
	)
	is(RegExp(
	    "(?'foo'f..())(?<bar>b..())(?P<baz>p..())(?&foo)(?&bar)(?&baz)"
	   ).exec('   fgcbmwpyffgcbmwpyf.fedei'),
	   'fgcbmwpyffgcbmwpyf,fgc,,bmw,,pyf,',
	   'named captures with nested regular captures'
	)
	// ( ?...) is deprecated in 5.18 and an error in 5.20
	try{peval('$]')>=5.017&&skip('Perl version >= 5.17',9)
	 is(RegExp('foo( ?0)?bar','x').exec('phoofoofoobarbarbarr'),
		'foofoobarbar', '( ?0)')
	 is(RegExp('foo( ?R)?bar','x').exec('phoofoofoobarbarbarr'),
		'foofoobarbar', '( ?R)')
	 is(RegExp('foo( ?1)bar|(baz)(?!)','x').exec('phoofoobazbarbump'),
		'foobazbar,', '( ?1)')
	 is(RegExp('()foo( ?+1)bar|(baz)(?!)','x').exec('hoofoobazbarbump')
		,'foobazbar,,', '( ?+1)')
	 is(RegExp('()(baz)(?!)()|foo( ?-2)bar','x').exec('ofoobazbarbump')
		,'foobazbar,,,', '( ?-2)')
	 is(RegExp('a+( *PRUNE)(?<!aaa)..','x').exec('aaaaa aabc'), 'aabc',
		'( *PRUNE)')
	 is(RegExp('(.)\\1*( *:foo)(?:b( *SKIP:foo)( *FAIL)|c)','x')
		.exec('aaabbbccc')[0],
	  'bbbc', '( *:foo) ( *bar:baz) ( *bonk) syntax')
	 is(RegExp(
	    "( ?'foo'f..)( ?<bar>b..)( ?P<baz>p..)( ?&foo)( ?&bar)( ?&baz)"
	    ,'x'
	   ).exec('   fgcbmwpyffgcbmwpyf.fedei'),
	   'fgcbmwpyffgcbmwpyf,fgc,bmw,pyf', '( ?...)-style named captures'
	 )
	 is(RegExp(
	    "( ?'foo'f..())( ?<bar>b..())( ?P<baz>p..())" +
	    "( ?&foo)( ?&bar)( ?&baz)"
	    ,'x'
	   ).exec('   fgcbmwpyffgcbmwpyf.fedei'),
	   'fgcbmwpyffgcbmwpyf,fgc,,bmw,,pyf,',
	   '( ?...) named captures with nested regular captures'
	 )
	}catch(oeuo){}
}catch($){}


// ===================================================
// Miscellaneous tests  
// ===================================================

// 5 tests: Regexps with surrogates

testname = 'surrogates in regexps don\'t cause fatal errors';
try{ new RegExp('\ud800'); pass(testname) }
catch(e){fail(testname)}

testname = 'surrogates in regexp char classes don\'t cause fatal errors';
try{ new RegExp('[\ud800]'); pass(testname) }
catch(e){fail(testname)}

ok('\ud800'.match(new RegExp('\ud800')),
	'regexps with surrogates in them work')
is(joyne(',',/(?:(a)?(b)?(c))+/.exec('abcc')),'abcc,undefined,undefined,c',
	'(?: ( )? ( )? )')
is(joyne(',',/a|(b)/.exec('a')),'a,undefined', 'a|(b)')


/// 4 tests: Make sure that our special capture-handling doesn’t break reg-
//          exps that originate from Perl
/*
function PerlRegExp(re) {
	return peval('new JE::Object::RegExp $je, qr/${\\shift}/',re)
	// ~~~ (This constructor doesn’t currently support qr//'s. It
	//      stringifies them.)
}

is(PerlRegExp('(a).').exec('abb'), 'ab,a',
	'exec with qr/()/')
is('ba'.match(PerlRegExp('(.).')),'ba,b',
	'String.prototype.match with qr/()/')
is('cbazyx'.replace(PerlRegExp('b(.)'), "$1"), 'cazyx',
	'String.prototype.replace with qr/()/')
is('cbazyx'.replace(PerlRegExp('b(.)'),
    function($and,$1){return $1}), 'cazyx',
	'String.prototype.replace with qr/()/ and a function')
*/
