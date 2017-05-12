#!perl -T
do './t/jstest.pl' or die __DATA__

plan('tests', 183)

function is_eval(x,y,name) {
	is(/*we want the eval to have its own namespace*/
	   function(){return eval(x)}(), y, name||x)
}

// ===================================================
// 12.1 {}
// ===================================================

/* Tests 1-13 */

is_eval('{}', undefined)
is_eval('3;{}', 3, '{} returns nothing, not even undefined')
is_eval('{3;{}}', 3)
is_eval('{3}', 3)
is_eval('{3;4}', 4)

try { { throw 'away' } }
catch(e) { error = e }
is(error, 'away', 'throw within a bare block')
delete error

try { { throw 'away'; bad_var = 5 } }
catch(e) {  }
is(this.bad_var, undefined,
	'throw within a bare block skips subsequent statements')

delete bad_var,function(){ { return; bad_var=5 } }()
is(this.bad_var, undefined,	
	'return within a bare block skips subsequent statements')

delete bad_var;do{ continue; bad_var=5 }while(0)
is(this.bad_var, undefined,	
	'continue within a bare block skips subsequent statements')

delete bad_var;do{ break; bad_var=5 }while(0)
is(this.bad_var, undefined,	
	'break within a bare block skips subsequent statements')

is_eval('do{3;break}while(0)', 3)
is_eval('do{3;continue}while(0)', 3)
is_eval('var x=0; do if(x);else{3;continue}while(!x++)', 3)

// ===================================================
// 12.2 var
// ===================================================

// Var initialisation that occurs before the code runs is tested in 
// 10.01-execution-context-definitions.t. Here we just test the run-
// time effect.

/* 14-19 */

var Potshriggly = 3
is(Potshriggly, 3, 'var a = 3')
var Cholmondeley = 2, Chargoggagoggmanchaugagoggchaubunagungamaugg = 1
ok(Cholmondeley == 2 && Chargoggagoggmanchaugagoggchaubunagungamaugg == 1,
	'var a = 2, b = 3 (two of them)')
var Waikaretu, Marjoribanks = 5, Blagoveshchensk
is(Marjoribanks, 5,
	'var declarations with and without initialisers interspersed')
error = false
try{var a = ntoebthoheiuoetditehduioethuitehodiuthoediuteohdi }
catch(e){error=true}
is(error, true, 'var initalisers call GetValue')

is_eval('var a = 5', undefined, 'eval("var...") returns undefined')
is_eval('3;var a= 5', 3,
	'var returns absolutely nothing, as opposed to undefined')

// ===================================================
// 12.3 ;
// ===================================================

/* 20-1 */

is_eval(';', undefined, "I'm  even  bothering  to")
is_eval('3;;', 3,       "test the empty statement.")


// ===================================================
// 12.4 expression statements
// ===================================================

// just need to make sure that GetValue is called and that the value is
// returned

/* 22-3 */

error = false
try{var a = ntoebthoheiuoetditehduioethuitehodiuthoediuteohdi }
catch(e){error=true}
is(error, true, 'expression statements call GetValue')

is_eval('3',3,'return value of expression statements')

// ===================================================
// 12.5 if
// ===================================================

/* 24-32 */

// if-else

error = false
try{if(ntoebthoheiuoetditehduioethuitehodiuthoediuteohdi);else; }
catch(e){error=true}
is(error, true, 'if-else calls GetValue')

is_eval('if(true)5;else 4', 5, 'if(true) with else')
is_eval('if(false)5;else 4', 4, 'if(false) with else')
is_eval('3; if(true);else 5', 3,
	'if(true) with else is able to return nothing')
is_eval('3; if(false)23;else ;', 3,
	'if(false) with else is able to return nothing')

// if without else

error = false
try{if(ntoebthoheiuoetditehduioethuitehodiuthoediuteohdi); }
catch(e){error=true}
is(error, true, 'if calls GetValue')

is_eval('if(true)5;', 5, 'if(true)')
is_eval('3 ;if(false)5;', 3, 'if(false) returns nothing')
is_eval('3; if(true);', 3,
	'if(true) is able to return nothing')


// ===================================================
// 12.6.1 do
// ===================================================

/* 33-45 */

is_eval('3;do;while(0)', 3, 'do with one iteration returning nothing')
is_eval('do 3;while(0)', 3, 'do with one iteration returning something')
is_eval('var x=0; do if(x);else 3;while(!x++)', 3,
	'do with two iterations, returning the value of the first')
is_eval('var x=0; do if(x)4;else 3;while(!x++)', 4,
	'do with two iterations, returning the value of the 2nd')
is_eval('3;var x=0; do;while(!x++)', 3,
	'do with two iterations, returning nothing')

x = 0; y=0
do { if(!x) continue; else ++y; ++y; } while(!x++)
is(y, 2, 'do-continue without label')

x = 0  /* might as well test multiple labels at the same time: */
Saanen: Toggenburg: do { continue Saanen; x = 1 } while (0)
is(x, 0, 'do-continue label')

x = 0, y=0,z=0
LaMancha:while(++y <= 2){
	z += 5
	do { continue LaMancha } while (x++)
	z += 5
}
is(x+z, 10, 'do-continue label when label does not belong to do')


x = 0
do { break } while(x++)
is(x, 0, 'do-break without label')

x = 0
Nubian: Alpine: do { break Alpine; } while (++x)
is(x, 0, 'do-break label')

x = 0
Boer:{
	do { break Boer } while (0)
	++x
}
is(x, 0, 'do-break label when label does not belong to do')

try { x=0; do { throw 'somith,eg'; x++} while (x+=2) }
catch(e){ x = x == 0 }
ok(x, 'do-throw')

error=false
try { do; while(aontehu) }
catch(e){error=true}
ok(error, 'do calls GetValue on the while() condition')


// ===================================================
// 12.6.2 while
// ===================================================

/* 46-58 */

is_eval('var x=0;3;while(!x++);', 3,
	'while with one iteration returning nothing')
is_eval('var x=0;while(!x++)3', 3,
	'while with one iteration returning something')
is_eval('var x=-1; while(++x<2)if(x);else 3;', 3,
	'while with two iterations, returning the value of the first')
is_eval('var x=-1; while(++x<2)if(x)4;else 3;', 4,
	'while with two iterations, returning the value of the 2nd')
is_eval('3;var x=-1; while(++x<2);', 3,
	'do with two iterations, returning nothing')

x = -1; y=0
while(++x<2) { if(!x) continue; else ++y; ++y; }
is(y, 2, 'while-continue without label')

x = 0, y=0
Margaret: Elvira: while(!y++) { continue Margaret; x = 1 }
is(x, 0, 'while-continue label')

x = 0, y=0,z=0
Inga:while(++y <= 2){
	z += 5
	while(++x) {continue Inga}
	z += 5
}
is(x+z, 12, 'while-continue label when label does not belong to while')


x = 0
while(++x) break
is(x, 1, 'while-break without label')

x = 0
Chelsea: Mona: while(++x) break Mona
is(x, 1, 'while-break label')

x = 0
Lisa:{
	while(1) break Lisa
	++x
}
is(x, 0, 'while-break label when label does not belong to while')

try { x=0;  while((x+=2) < 10) { throw 'somith,eg'; x++} }
catch(e){ x = x == 2 }
ok(x, 'while-throw')

error=false
try { while(aontehu); }
catch(e){error=true}
ok(error, 'while calls GetValue on the while() condition')


// ===================================================
// 12.6.3 for(;;)
// ===================================================

/* 59-75: for without in or var */

for(;;) {x=3; break;}
is(x, 3, 'for(/*blank*/;/*blank*/;etc)')

for(x=4;;)break;
is(x,4, 'for(x,y,z) does evaluate x')

error=false
try{for(uoentuh;0;);}catch(enh){error=true}
is(error,true,'for(x;y;z) calls GetValue on x')

error=false
try{for(;oeunth;)break;}catch(eonht){error=true}
is(error,true,'for(x;y;z) calls GetValue on y')

error=false, x=0
try{for(;!x++;aouhtnb);}catch(eonht){error=true}
is(error,true,'for(x;y;z) calls GetValue on z')

is_eval('var x=0;3;for(;x<1;++x);', 3,
	'for(;;) with one iteration returning nothing')
is_eval('var x=0;for(;x<1;++x)3', 3,
	'for(;;) with one iteration returning something')
is_eval('var x=-1; for(;++x<2;)if(x);else 3;', 3,
	'for(;;) with two iterations, returning the value of the first')
is_eval('var x=-1; for(;++x<2;)if(x)4;else 3;', 4,
	'for(;;) with two iterations, returning the value of the 2nd')
is_eval('3;var x=-1; for(;++x<2;);', 3,
	'do with two iterations, returning nothing')

x = 0; y=0
for(;x<2;x++) { if(!x) continue; else ++y; ++y; }
is(y+' '+x, '2 2', 'for(;;)-continue without label')

x = 0, y=0
mvemjsun: tgcfaoqtcd: for(;!y++;) { continue tgcfaoqtcd; x = 1 }
is(x, 0, 'while-continue label')

x = 0, z=0
roygbiv:for(y=0;y < 2;++y){
	z += 5
	for(;;++x) {continue roygbiv}
	z += 5
}
is(x+z, 10, 'for(;;)-continue label when label does not belong to for')


for(x=0;;++x) break
is(x, 0, 'for(;;)-break without label')

depanjgactmamd: scnhvanyncri: for(x=0;;++x) break scnhvanyncri
is(x, 0, 'for(;;)-break label')

x = 0
pyfgcrl:{
	for(;;) break pyfgcrl
	++x
}
is(x, 0, 'for(;;)-break label when label does not belong to for')

try { x=0;  for(;(x+=2) < 10;) { throw 'somith,eg'; x++} }
catch(e){ x = x == 2 }
ok(x, 'for(;;)-throw')


/* 76-91: for-var without in */

for(var x;;) {x=3; break;}
is(x, 3, 'for(var;/*blank*/;etc)')

for(var x=4;;)break;
is(x,4, 'for(var x;y;z) does evaluate var')

error=false
try{for(var x;oeunth;)break;}catch(eonht){error=true}
is(error,true,'for(var x;y;z) calls GetValue on y')

error=false, x=0
try{for(var x;!x++;aouhtnb);}catch(eonht){error=true}
is(error,true,'for(var x;y;z) calls GetValue on z')

is_eval('3;for(var x=0;x<1;++x);', 3,
	'for(var;;) with one iteration returning nothing')
is_eval('for(var x=0;x<1;++x)3', 3,
	'for(var;;) with one iteration returning something')
is_eval('; for(var x=-1;++x<2;)if(x);else 3;', 3,
	'for(var;;) with two iterations, returning the value of the first')
is_eval('; for(var x=-1;++x<2;)if(x)4;else 3;', 4,
	'for(var;;) with two iterations, returning the value of the 2nd')
is_eval('3;; for(var x=-1;++x<2;);', 3,
	'for(var;;) with two iterations, returning nothing')

for(var x = 0, y=0;x<2;x++) { if(!x) continue; else ++y; ++y; }
is(y+' '+x, '2 2', 'for(var ;;)-continue without label')

ihat: aur: for(var x = 0, y=0;!y++;) { continue ihat; x = 1 }
is(x, 0, 'for(var;;)-continue label')

x = 0, z=0
urot:for(var y=0;y < 2;++y){
	z += 5
	for(var x;;++x) {continue urot}
	z += 5
}
is(x+z, 10, 'for(var;;)-continue label when label does not belong to for')


for(var x=0;;++x) break
is(x, 0, 'for(var;;)-break without label')

ahw: amir: for(var x=0;;++x) break amir
is(x, 0, 'for(var ;;)-break label')

x = 0
ono:{
	for(var x;;) break ono
	++x
}
is(x, 0, 'for(var;;)-break label when label does not belong to for')

try { for(var x=0;(x+=2) < 10;) { throw 'somith,eg'; x++} }
catch(e){ x = x == 2 }
ok(x, 'for(var ;;)-throw')


// ===================================================
// 12.6.4 for-in (not duh-mess-tick)
// ===================================================

/* 92-108: for-in without var */

var o = {a:'b',c:'d'};
var m = ''
/* I want to test that expressions are evaluated in order, so I need an
   lvalue function, which requires a dirty trick: */
var lfunc = peval('my $o = $je->upgrade({}); ' +
                  'sub{ $je->{m} .= "lhs"; new JE::LValue $o, "p"}')
for(lfunc() in function(){m += 'rhs';return o}())m+='body';
is(m, 'rhslhsbodylhsbody')

error=false
try{for(x in oentuhnhtueohnteunoht);}catch(me){error=true}
is(error,true,'for-in calls GetValue on the rhs expr')

Boolean.prototype.thing='foo', m=''
for(x in true)m+=x+true[x]
is(m, 'thingfoo','for-in converts its rhs to an object')
delete Boolean.prototype.thing

var o1 = {thing:'foo'}

is_eval('var x;3;for(x in o1);', 3,
	'for-in with one iteration returning nothing')
is_eval('var x;for(x in o1)3', 3,
	'for-in with one iteration returning something')
is_eval('var x=0,y;for(y in o)if(x++);else 3;', 3,
	'for-in with two iterations, returning the value of the first')
is_eval('var x=0,y; for(y in o)if(x++)4;else 3;', 4,
	'for-in with two iterations, returning the value of the 2nd')
is_eval('3;var x;for(x in o);', 3,
	'for-in with two iterations, returning nothing')

var a = []
for(a[a.length] in o);
is(a.sort(), 'a,c', 'the lhs gets property names assigned')

x = 0; y=0
for(m in o) { if(x++) continue; else ++y; ++y; }
is(y+' '+x, '2 2', 'for-in-continue without label')

x = 0
utihw: uraw: for(y in o1) { continue utihw; x = 1 }
is(x, 0, 'for-in-continue label')

x = 0, z=0
awi: for(y in o){
	z += 5
	for(y in {a:1,b:2,c:3,d:4}) {continue awi}
	z += 5
}
is(x+z, 10, 'for-in-continue label when label does not belong to for')

y = 0
for(x in o) { break; ++y }
is(y, 0, 'for-in-break without label')

y = 0
uaket: ihat_am_uaket: for(x in o) { break ihat_am_uaket; ++y }
is(y, 0, 'for-in-break label')

x = 0
aur_am_uaket:{
	for(y in o) break aur_am_uaket
	++x
}
is(x, 0, 'for-in-break label when label does not belong to for')

try { x=0;  for(x in o) { throw 'somith,eg'; x++} }
catch(e){ x = x.match(/^[ac]$/) }
ok(x, 'for-in-throw')

error = false
try { for(x in null); for(x in undefined); }
catch(e){error = e}
is(error, false, 'for(x in null) and for(x in undefined) do not die')


/* 109-25: for-var-in */

var o = {a:'b',c:'d'};
var m = ''
with(tmpob = {myvar:true})
	for(var myvar in function(){m += 'rhs';return o}())
		m += tmpob.myvar + this.myvar, delete myvar
ok(m.match(/^rhs([ac])(?:undefined){2}(?!\1)[ac]$/), 
	'expressions in for-var-in loops are executed in order')

error=false
try{for(var x in oentuhnhtueohnteunoht);}catch(me){error=true}
is(error,true,'for-var-in calls GetValue on the rhs expr')

Boolean.prototype.thing='foo', m=''
for(var x in true)m+=x+true[x]
is(m, 'thingfoo','for-var-in converts its rhs to an object')
delete Boolean.prototype.thing

var o1 = {thing:'foo'}

is_eval('3;for(var x in o1);', 3,
	'for-var-in with one iteration returning nothing')
is_eval('for(var x in o1)3', 3,
	'for-var-in with one iteration returning something')
is_eval('var x=0;for(var y in o)if(x++);else 3;', 3,
	'for-var-in with two iterations, returning the value of the first')
is_eval('var x=0; for(var y in o)if(x++)4;else 3;', 4,
	'for-var-in with two iterations, returning the value of the 2nd')
is_eval('3;for(var x in o);', 3,
	'for-var-in with two iterations, returning nothing')

var a = []
for(var x in o) a.push(x);
is(a.sort(), 'a,c', 'the lhs gets property names assigned')

x = 0; y=0
for(var m in o) { if(x++) continue; else ++y; ++y; }
is(y+' '+x, '2 2', 'for-var-in-continue without label')

x = 0
tahi: rua: for(var y in o1) { continue rua; x = 1 }
is(x, 0, 'for-var-in-continue label')

x = 0, z=0
toru: for(var y in o){
	z += 5
	for(var y in {a:1,b:2,c:3,d:4}) {continue toru}
	z += 5
}
is(x+z, 10, 'for-var-in-continue label when label does not belong to for')

y = 0
for(var x in o) { break; ++y }
is(y, 0, 'for-var-in-break without label')

y = 0
wha: rima: for(var x in o) { break rima; ++y }
is(y, 0, 'for-var-in-break label')

x = 0
whitu:{
	for(var y in o) break whitu
	++x
}
is(x, 0, 'for-var-in-break label when label does not belong to for')

try { x=0;  for(var x in o) { throw 'somith,eg'; x++} }
catch(e){ x = x.match(/^[ac]$/) }
ok(x, 'for-var-in-throw')

error = false
try { for(var x in null); for(var x in undefined); }
catch(e){error = e}
is(error,false, 'for(var x in null) and for(var x in undefined) die not')


// ===================================================
// 12.7-8 continue and break
// ===================================================

// Hmm, seems we've already tested these.


// ===================================================
// 12.9 return
// ===================================================

/* 126-8 */

is(function(){return}(), undefined, 'return')
is(function(){return 'something'}(), 'something', 'return something')

error=false
try{0,function(){return ueonthauntggc}()}catch(it){error=true}
ok(error,'return nonexistent_var dies appropriately')


// ===================================================
// 12.10 with
// ===================================================

/* 129-33 */

error=false;
try{with(a_var_that_thinks_it_doesnt_exist_and_is_not_mistaken);}
catch(fire){error=true}
ok(error,'with retrieves the value within its parentheses')

 var ettet // ( avoid ReferencErrors on test failure)
Boolean.prototype.ettet='nennenen';
with(true) // we're testing two things here:
	is(ettet, 'nennenen', 'with converts its arg to an obj ' +
	                      'and puts it on the scope chain')
is(ettet, undefined, 'the scope chain is restored after "with"')

error=false; var your
try{with({your:'hands to'}) throw 'and'} catch(a_ball){
error=true}
ok(error, 'throw within with')
is(your, undefined, 'the scope chain is restored after with-throw')


// ===================================================
// 12.11 switch
// ===================================================

/* 134-52 */

error=false
try{switch(ucpcpcn){}}
catch(oeudee){error=true}
ok(error,'switch retrieves the value from its input')

is_eval('3;switch(5){default:break;}', 3,
	'switch is capable of returnirng nothing')
is_eval('3;switch(5){default:5;}', 5,
	'switch always returns nothing')

x = 0
a_switch_statement: anothir_label: switch('on'){
	default: ++x; break a_switch_statement; ++x
}
is(x, 1,'switch-break label')

x=0;some_block:{ switch(5) { default: break some_block;} ++x}
is(x, 0, 'switch-break label of anothir block')

switch(5) {}
pass('empty switch') // well, nothing happened; er, what exactly am I try-
                    // ing to test here?

x = 0; switch(5) {
	case 1: ++x
	case 5: x+=2
}
is(x, 2, 'defaultless switch with 1 case not matching & another matching')

x=0; switch(5) { case 7: ++x; case 8:++x}
is(x, 0, 'defaultless switch with no matching cases')

x=0; switch(5) {case 5: ++x; case 7: x+=2 }
is(x,3,'defaultless switch with fall-through and run-off')

x=0; switch(5) {case 5: ++x; break; case 7 : x+=2 }
is(x,1,'defaultless switch with break')

x=0;switch(5){default:break; case 7: ++x}
is(x,0,'default:break')

x=0;switch(5){
	case '5': x+=60;
	case 2+3: ++x;
	case 98: ++x; break
	default: x+=10
} is(x, 2, 'switch w/ !==, ===, fall-through b4 def., & break b4 def.')

x=0;switch(5){
	case '5': x+=50;
	default: ++x;
} is(x,1,
  'switch with no matching cases before default & run-off from default')

x=0;switch(5){case 5: break; default: ++x}
is(x,0,'switch with break in the very case that matched')

x=0;switch(5){
	case 5: ++x;
	default: ++x;
	case 87: ++x;
	case 389: ++x;
} is(x, 4, 'fall-thru to def., from def. & from case 2 case after def.; and run-off from case after def.')

x=0;switch(5){default:++x}
is(x,1,'switch with default and no cases')

x=0;switch(5){default: case '5': ++x; case 5: break; case 87: ++x}
is(x,0,
   'non- & matching cases after def., & break in the case that matched')

x=0;switch(5){default: ++x; case 3636: ++x; case 838: break; case 3:++x}
is(x,2,'no cases matching, fall-through from default, and break')

error=false;try{switch(5){case eoun:}}catch($){error=true}
ok(error,'"case non_existent_var" dies')


// ===================================================
// 12.12 labelled statements
// ===================================================

/* 153-5 */

is_eval("3;label:;", 3, 'labelled statements are able to return nothing')
is_eval("while(1)label:{3;break}", 3,
	'labelled statements return an abrupt completion')
is_eval("label:{3; break label; 4}", 3,
	'break with non-iterative labelled statements')



// ===================================================
// 12.13 thr=ow
// ===================================================

/* 156-7 */

error=false
try{throw 'something'}catch(it){error=it}
is(error, 'something', 'throw something')

try{throw nothing}catch(it){error=it}
ok(error instanceof ReferenceError, 'throw nonexistent var')

// ===================================================
// 12.14 try
// ===================================================

/* 158-83 */

is_eval('try{"to"}catch(it){now}', 'to', 'try-catch without exception')
is_eval('try{to}catch(it){"now"}', 'now', 'exceptional try-catch')

ok(eval('please:do try{2;continue please;"before"}finally{giving="up"}'+
        'while(0)') == 2 && giving=='up', 'try-finally')
is_eval('do{try{""}finally{"to"; continue}_="it"}while(!"possible")',
	"to", 'try-finally with an abrupt completion in finally')

m = ''
is_eval('free:try{m="5";break free}catch(me){m+=6}finally{m+=7}', 5,
	'try-catch-finally')
is(m, 57, 'side-effect of try-catch-finally')

m = ''
is_eval('free:try{m="5"}catch(me){m+=6}finally{m+=7; break free}', 57,
	'try-catch-finally with abrupt completion in finally')
is(m, 57, 'side-effect of try-catch-finally with break in finally')

m = '', error=undefined
is_eval('try{throw m="5";++m}catch(me){error=me;m+=6; }finally{m+=7}', 56,
	'try throw-catch-finally')
is(m, 567, 'side-effect of try throw-catch-finally')
is(error, 5, 'error thrown by try throw-catch-finally')

m = '', error=undefined
is_eval('free: try{5();++m}catch(e){error=e;m+=6;break free}finally{m+=7}',
	6, 'try-throw-catch-break-finally')
is(m, 67, 'side-effect of try-throw-catch-break-finally')
ok(error instanceof TypeError,
	'error thrown by try-throw-catch-break-finally')

m = '', error=undefined
is_eval('free: try{5();++m}catch(e){error=e;m+=6}finally{m+=7;break free}',
	67, 'try-throw-catch-finally-break')
is(m, 67, 'side-effect of try-throw-catch-finally-break')
ok(error instanceof TypeError,
	'error thrown by try-throw-catch-finally-break')

m = '', error=undefined
is_eval('free: try{5();++m}catch(e){error=e;m+=6;break free}' +
        'finally{m+=7;break free}',
	67, 'try-throw-catch-break-finally-break')
is(m, 67, 'side-effect of try-throw-catch-break-finally-break')
ok(error instanceof TypeError,
	'error thrown by try-throw-catch-break-finally-break')

error= '1+1=3'
try{5()}
catch(error){
	is(delete error, false, 'error in a catch block is undeletable')
	ok(error instanceof TypeError, 'the error really is undeletable')
}
finally{ is(error,'1+1=3', 'scope chain is restored after catch') }

is_eval('3;try{}catch(_){}', 3, 'try returning nothing')
is_eval('3;try{throw 3}catch($){}', 3,'try-catch returning nothing')
is_eval('3;attempt:try{throw 3}catch($){}finally{3;break attempt}', 3,
	'finally returning nothing')
