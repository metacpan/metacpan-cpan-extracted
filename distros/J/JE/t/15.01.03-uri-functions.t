#!perl -T
do './t/jstest.pl' or die __DATA__

function is_nan(n){ // checks to see whether the number is *really* NaN
                    // & not something which converts to NaN when numified
	return n!=n
}

// ===================================================
// 15.1.3.1: decodeURI
// ===================================================

// 10 tests (boilerplate stuff for built-ins)
is(typeof decodeURI, 'function', 'typeof decodeURI');
is(Object.prototype.toString.apply(decodeURI), '[object Function]',
	'class of decodeURI')
ok(Function.prototype.isPrototypeOf(decodeURI), 'decodeURI\'s prototype')
$catched = false;
try{ new decodeURI } catch(e) { $catched = e }
ok($catched, 'new decodeURI fails')
ok(!('prototype' in decodeURI), 'decodeURI has no prototype property')
ok(decodeURI.length === 1, 'decodeURI.length')
ok(!decodeURI.propertyIsEnumerable('length'),
	'decodeURI.length is not enumerable')
ok(!delete decodeURI.length, 'decodeURI.length cannot be deleted')
is((decodeURI.length++, decodeURI.length), 1, 'decodeURI.length is read-only')
ok(decodeURI() === 'undefined', 'decodeURI() w/o args')


// 5 tests for type conversion
ok(decodeURI(undefined) === 'undefined', 'decodeURI(undefined)')
ok(decodeURI(null     ) === 'null',      'decodeURI(null)')
ok(decodeURI(true     ) === 'true',      'decodeURI(bool)')
ok(decodeURI(0        ) === '0',         'decodeURI(num)')
ok(decodeURI({})==='[object Object]',    'decodeURI({})')

// 18 tests for the algorithm itself

ok(decodeURI('blah@#!$(&@\u0100\xff\ud800') ===
	'blah@#!$(&@\u0100\xff\ud800', 'non-% chars go right through')

ok(decodeURI('%ed%a0%80') === '\ud800', 'encoded surrogates get decoded')

error = false
try{decodeURI('oenh%')}catch(e){error = e}
ok(error instanceof URIError, 'decodeURI dies with a final %')

error = false
try{decodeURI('oenh%a')}catch(e){error = e}
ok(error instanceof URIError, 'decodeURI dies with a partial %xx')

error = false
try{decodeURI('oenh%g3')}catch(e){error = e}
ok(error instanceof URIError, 'decodeURI dies with a invalid %xx')

error = false
try{decodeURI('oenh%3H')}catch(e){error = e}
ok(error instanceof URIError, 'decodeURI dies with a invalid %xx (again)')

// I mix capitalisation in this test, to make sure that what doesn’t get
// unescaped retains it capitalisation:
is(decodeURI('%00%01%02%03%04%05%06%07%08%09%0A%0B%0C%0D%0E%0F' +
             '%10%11%12%13%14%15%16%17%18%19%1A%1B%1C%1D%1E%1F' +
             '%20%21%22%23%24%25%26%27%28%29%2A%2B%2C%2D%2E%2f' +
             '%30%31%32%33%34%35%36%37%38%39%3a%3B%3C%3D%3E%3F' +
             '%40%41%42%43%44%45%46%47%48%49%4A%4B%4C%4D%4E%4F' +
             '%50%51%52%53%54%55%56%57%58%59%5A%5B%5C%5D%5E%5F' +
             '%60%61%62%63%64%65%66%67%68%69%6A%6B%6C%6D%6E%6F' +
             '%70%71%72%73%74%75%76%77%78%79%7A%7B%7C%7D%7E%7F'),
	'\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F'+
	'\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1A\x1B\x1C\x1D\x1E\x1F'+
	'\x20!"%23%24%%26\'()*%2B%2C-.%2f0123456789%3a%3B<%3D>%3F' +
	'%40ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_' +
	'`abcdefghijklmnopqrstuvwxyz{|}~\x7f',
	'decodeURI with all seven-bit escapes')

error = false
try{decodeURI('%f8%88%80%80%80' /* chr 0x20_0000 */)}catch(e){error = e}
ok(error instanceof URIError, 'decodeURI dies with 5-byte utf8 chars')

error = false
try{decodeURI('a%80a'); error = true}catch(e){error = e}

ok(error instanceof URIError,
	'decodeURI dies with an unexpected continuation byte')

error = false
try{decodeURI('%ef%bb')}catch(e){error = e}
ok(error instanceof URIError,
 'decodeURI dies when the string is too short for the expected utf-8 char')
	// i.e., %ef indicates that there are at least six more bytes

error = false
try{decodeURI('%ef%bb%b')}catch(e){error = e}
ok(error instanceof URIError,
 'decodeURI dies when string is 1 char too short for expected utf-8 char')

error = false
try{decodeURI('%efbbbbbbb')}catch(e){error = e}
ok(error instanceof URIError,
    'decodeURI dies when %xx start byte is not followed by %')

error = false
try{decodeURI('%ef%hb%bf')}catch(e){error = e}
ok(error instanceof URIError,
    'decodeURI dies when utf-8 char\'s initial %xx% is not followed by x')

error = false
try{decodeURI('%ef%bh%bf')}catch(e){error = e}
ok(error instanceof URIError,
    'decodeURI dies when utf-8 char\'s initial %xx%x is not followed by x')

error = false
try{decodeURI('%ef%20%bf')}catch(e){error = e}
ok(error instanceof URIError,
    'decodeURI dies when utf-8 char\'s continuation octet is bad')

is(decodeURI('%c4%80%ef%bb%be'), '\u0100\ufefe',
	'decodeURI: successful surrogateless utf-8 decoding')

error = false
try{decodeURI('%f4%90%80%80')}catch(e){error = e}
ok(error instanceof URIError,
    'decodeURI dies when utf-8 char > 0x10ffff')

is(decodeURI('%f0%90%84%82'), '\ud800\udd02',
	'decodeURI: surrogate pairs')


// ===================================================
// 15.1.3.2: decodeURIComponent
// ===================================================

// 10 tests (boilerplate stuff for built-ins)
is(typeof decodeURIComponent, 'function', 'typeof decodeURIComponent');
is(Object.prototype.toString.apply(decodeURIComponent),
	'[object Function]',
	'class of decodeURIComponent')
ok(Function.prototype.isPrototypeOf(decodeURIComponent),
	'decodeURIComponent\'s prototype')
$catched = false;
try{ new decodeURIComponent } catch(e) { $catched = e }
ok($catched, 'new decodeURIComponent fails')
ok(!('prototype' in decodeURIComponent), 'decodeURIComponent has no prototype property')
ok(decodeURIComponent.length === 1, 'decodeURIComponent.length')
ok(!decodeURIComponent.propertyIsEnumerable('length'),
	'decodeURIComponent.length is not enumerable')
ok(!delete decodeURIComponent.length, 'decodeURIComponent.length cannot be deleted')
is((decodeURIComponent.length++, decodeURIComponent.length), 1, 'decodeURIComponent.length is read-only')
ok(decodeURIComponent() === 'undefined', 'decodeURIComponent() w/o args')

// 5 tests for type conversion
ok(decodeURIComponent(undefined) === 'undefined', 
	'decodeURIComponent(undefined)')
ok(decodeURIComponent(null     ) === 'null',     
	'decodeURIComponent(null)')
ok(decodeURIComponent(true     ) === 'true',     
	'decodeURIComponent(beeloan)')
ok(decodeURIComponent(0        ) === '0',        
	'decodeURIComponent(number)')
ok(decodeURIComponent({})==='[object Object]',    
	'decodeURIComponent(string)')


// 18 tests for the algorithm itself

ok(decodeURIComponent('blah@#!$(&@\u0100\xff\ud800') ===
	'blah@#!$(&@\u0100\xff\ud800', 'non-% chars go right through')

ok(decodeURIComponent('%ed%a0%80') === '\ud800', 'encoded surrogates get decoded')

error = false
try{decodeURIComponent('oenh%')}catch(e){error = e}
ok(error instanceof URIError, 'decodeURIComponent dies with a final %')

error = false
try{decodeURIComponent('oenh%a')}catch(e){error = e}
ok(error instanceof URIError, 'decodeURIComponent dies with a partial %xx')

error = false
try{decodeURIComponent('oenh%g3')}catch(e){error = e}
ok(error instanceof URIError, 'decodeURIComponent dies with a invalid %xx')

error = false
try{decodeURIComponent('oenh%3H')}catch(e){error = e}
ok(error instanceof URIError, 'decodeURIComponent dies with a invalid %xx (again)')

// I mix capitalisation in this test, to make sure that what doesn’t get
// unescaped retains it capitalisation:
is(decodeURIComponent('%00%01%02%03%04%05%06%07%08%09%0A%0B%0C%0D%0E%0F' +
             '%10%11%12%13%14%15%16%17%18%19%1A%1B%1C%1D%1E%1F' +
             '%20%21%22%23%24%25%26%27%28%29%2A%2B%2C%2D%2E%2f' +
             '%30%31%32%33%34%35%36%37%38%39%3a%3B%3C%3D%3E%3F' +
             '%40%41%42%43%44%45%46%47%48%49%4A%4B%4C%4D%4E%4F' +
             '%50%51%52%53%54%55%56%57%58%59%5A%5B%5C%5D%5E%5F' +
             '%60%61%62%63%64%65%66%67%68%69%6A%6B%6C%6D%6E%6F' +
             '%70%71%72%73%74%75%76%77%78%79%7A%7B%7C%7D%7E%7F'),
	'\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F'+
	'\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1A\x1B\x1C\x1D\x1E\x1F'+
	'\x20!"#$%&\'()*+,-./0123456789:;<=>?' +
	'@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_' +
	'`abcdefghijklmnopqrstuvwxyz{|}~\x7f',
	'decodeURIComponent with all seven-bit escapes')

error = false
try{decodeURIComponent('%f8%88%80%80%80' /* chr 0x20_0000 */)}catch(e){error = e}
ok(error instanceof URIError, 'decodeURIComponent dies with 5-byte utf8 chars')

error = false
try{decodeURIComponent('a%80a'); error = true}catch(e){error = e}

ok(error instanceof URIError,
	'decodeURIComponent dies with an unexpected continuation byte')

error = false
try{decodeURIComponent('%ef%bb')}catch(e){error = e}
ok(error instanceof URIError,
 'decodeURIComponent dies when the string is too short for the expected utf-8 char')
	// i.e., %ef indicates that there are at least six more bytes

error = false
try{decodeURIComponent('%ef%bb%b')}catch(e){error = e}
ok(error instanceof URIError,
 'decodeURIComponent dies when string is 1 char too short for expected utf-8 char')

error = false
try{decodeURIComponent('%efbbbbbbb')}catch(e){error = e}
ok(error instanceof URIError,
    'decodeURIComponent dies when %xx start byte is not followed by %')

error = false
try{decodeURIComponent('%ef%hb%bf')}catch(e){error = e}
ok(error instanceof URIError,
    'decodeURIComponent dies when utf-8 char\'s initial %xx% is not followed by x')

error = false
try{decodeURIComponent('%ef%bh%bf')}catch(e){error = e}
ok(error instanceof URIError,
    'decodeURIComponent dies when utf-8 char\'s initial %xx%x is not followed by x')

error = false
try{decodeURIComponent('%ef%20%bf')}catch(e){error = e}
ok(error instanceof URIError,
    'decodeURIComponent dies when utf-8 char\'s continuation octet is bad')

is(decodeURIComponent('%c4%80%ef%bb%be'), '\u0100\ufefe',
	'decodeURIComponent: successful surrogateless utf-8 decoding')

error = false
try{decodeURIComponent('%f4%90%80%80')}catch(e){error = e}
ok(error instanceof URIError,
    'decodeURIComponent dies when utf-8 char > 0x10ffff')

is(decodeURIComponent('%f0%90%84%82'), '\ud800\udd02',
	'decodeURIComponent: surrogate pairs')

// ===================================================
// 15.1.3.3: encodeURI
// ===================================================

// 10 tests (boilerplate stuff for built-ins)
is(typeof encodeURI, 'function', 'typeof encodeURI');
is(Object.prototype.toString.apply(encodeURI),
	'[object Function]',
	'class of encodeURI')
ok(Function.prototype.isPrototypeOf(encodeURI),
	'encodeURI\'s prototype')
$catched = false;
try{ new encodeURI } catch(e) { $catched = e }
ok($catched, 'new encodeURI fails')
ok(!('prototype' in encodeURI), 'encodeURI has no prototype property')
ok(encodeURI.length === 1, 'encodeURI.length')
ok(!encodeURI.propertyIsEnumerable('length'),
	'encodeURI.length is not enumerable')
ok(!delete encodeURI.length, 'encodeURI.length cannot be deleted')
is((encodeURI.length++, encodeURI.length), 1,
	'encodeURI.length is read-only')
ok(encodeURI() === 'undefined', 'encodeURI() w/o args')

// 5 tests for type conversion
ok(encodeURI(undefined) === 'undefined', 'encodeURI(undefined)')
ok(encodeURI(null     ) === 'null',      'encodeURI(null)')
ok(encodeURI(true     ) === 'true',      'encodeURI(boolean)')
ok(encodeURI(0        ) === '0',         'encodeURI(num)')
ok(encodeURI({})==='%5Bobject%20Object%5D','encodeURI({})')


// 5 tests  for the algorithm

error = false
try{encodeURI('oeu\udcbaabdetued')}catch(e){error = e}
ok(error instanceof URIError,
    'encodeURI dies on unexpected low surrogate dcba')

ok(encodeURI('Ő࿇𐅴') === '%C5%90'+'%E0%BF%87'+'%F0%90%85%B4',
	'encodeURI: utf-8 sequences of different lengths')

error = false
try{encodeURI('oeu\ud888')}catch(e){error = e}
ok(error instanceof URIError,
    'encodeURI dies on high surrogate at the end of the string')

error = false
try{encodeURI('oeu\ud888oeua')}catch(e){error = e}
ok(error instanceof URIError,
    'encodeURI dies on finding a lone high surrogate')

is(encodeURI(
	'\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F'+
	'\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1A\x1B\x1C\x1D\x1E\x1F'+
	'\x20!"#$%&\'()*+,-./0123456789:;<=>?' +
	'@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_' +
	'`abcdefghijklmnopqrstuvwxyz{|}~\x7f'),
		'%00%01%02%03%04%05%06%07%08%09%0A%0B%0C%0D%0E%0F' +
		'%10%11%12%13%14%15%16%17%18%19%1A%1B%1C%1D%1E%1F' +
		'%20!%22#$%25&\'()*+,-./' +
		'0123456789:;%3C=%3E?' +
		'@ABCDEFGHIJKLMNOPQRSTUVWXYZ%5B%5C%5D%5E_' +
		'%60abcdefghijklmnopqrstuvwxyz%7B%7C%7D~%7F',
	'encodeURI: full 7-bit test')


// ===================================================
// 15.1.3.4: encodeURIComponent
// ===================================================

// 10 tests (boilerplate stuff for built-ins)
is(typeof encodeURIComponent, 'function', 'typeof encodeURIComponent');
is(Object.prototype.toString.apply(encodeURIComponent),
	'[object Function]',
	'class of encodeURIComponent')
ok(Function.prototype.isPrototypeOf(encodeURIComponent),
	'encodeURIComponent\'s prototype')
$catched = false;
try{ new encodeURIComponent } catch(e) { $catched = e }
ok($catched, 'new encodeURIComponent fails')
ok(!('prototype' in encodeURIComponent), 'encodeURIComponent has no prototype property')
ok(encodeURIComponent.length === 1, 'encodeURIComponent.length')
ok(!encodeURIComponent.propertyIsEnumerable('length'),
	'encodeURIComponent.length is not enumerable')
ok(!delete encodeURIComponent.length, 'encodeURIComponent.length cannot be deleted')
is((encodeURIComponent.length++, encodeURIComponent.length), 1, 'encodeURIComponent.length is read-only')
ok(encodeURIComponent() === 'undefined', 'encodeURIComponent() w/o args')

// 5 tests for type conversion
ok(encodeURIComponent(undefined) === 'undefined', 
	'encodeURIComponent(undefined)')
ok(encodeURIComponent(null     ) === 'null',     
	'encodeURIComponent(null)')
ok(encodeURIComponent(true     ) === 'true',     
	'encodeURIComponent(boolean)')
ok(encodeURIComponent(0        ) === '0',        'encodeURIComponent(num)')
ok(encodeURIComponent({})==='%5Bobject%20Object%5D',
	'encodeURIComponent({})')


// 5 tests  for the algorithm

error = false
try{encodeURIComponent('oeu\udcbaabdetued')}catch(e){error = e}
ok(error instanceof URIError,
    'encodeURIComponent dies on unexpected low surrogate dcba')

ok(encodeURIComponent('Ő࿇𐅴') === '%C5%90'+'%E0%BF%87'+'%F0%90%85%B4',
	'encodeURIComponent: utf-8 sequences of different lengths')

error = false
try{encodeURIComponent('oeu\ud888')}catch(e){error = e}
ok(error instanceof URIError,
    'encodeURIComponent dies on high surrogate at the end of the string')

error = false
try{encodeURIComponent('oeu\ud888oeua')}catch(e){error = e}
ok(error instanceof URIError,
    'encodeURIComponent dies on finding a lone high surrogate')

is(encodeURIComponent(
	'\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F'+
	'\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1A\x1B\x1C\x1D\x1E\x1F'+
	'\x20!"#$%&\'()*+,-./0123456789:;<=>?' +
	'@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_' +
	'`abcdefghijklmnopqrstuvwxyz{|}~\x7f'),
		'%00%01%02%03%04%05%06%07%08%09%0A%0B%0C%0D%0E%0F' +
		'%10%11%12%13%14%15%16%17%18%19%1A%1B%1C%1D%1E%1F' +
		'%20!%22%23%24%25%26\'()*%2B%2C-.%2F' +
		'0123456789%3A%3B%3C%3D%3E%3F' +
		'%40ABCDEFGHIJKLMNOPQRSTUVWXYZ%5B%5C%5D%5E_' +
		'%60abcdefghijklmnopqrstuvwxyz%7B%7C%7D~%7F',
	'encodeURIComponent: full 7-bit test')
