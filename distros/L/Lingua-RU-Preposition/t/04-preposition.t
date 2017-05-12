#!perl -T

use utf8;
use Test::More 'tests' => 39;

use Lingua::RU::Preposition;
*p  = \&Lingua::RU::Preposition::choose_preposition_by_next_word;

ok( p('без', 'всего') eq 'безо', 'bez/bezo: exception - vsego' ); # ambiguous: both words is OK
ok( p('без', 'ноги')  eq 'без',  'bez/bezo: common' );

ok( p('из', 'всех') eq 'изо', 'iz/izo: exception' );
ok( p('из', 'меня') eq 'из',  'iz/izo: common' );

ok( p('к', 'всем')   eq 'ко', 'k/ko: exception' );
ok( p('к', 'мне')    eq 'ко', 'k/ko: exception' );
ok( p('к', 'многим') eq 'ко', 'k/ko: exception' );
ok( p('к', 'вам')    eq 'к',  'k/ko: common' );

ok( p('о', 'ухе') eq 'об',  'o/ob/obo: vowel' );
ok( p('о', 'ели') eq 'о',   'o/ob/obo: iotified vowel' );
ok( p('о', 'пне') eq 'о',   'o/ob/obo: consonant' );

ok( p('о', 'мне') eq 'обо', 'o/ob/obo: exception - mne' );

ok( p('с', 'осой')   eq 'с',  's/so: vowel' );
ok( p('с', 'сном')   eq 'со', 's/so: s with consonant' );
ok( p('с', 'солью')  eq 'с',  's/so: s with vowel' );
ok( p('с', 'зноем')  eq 'со', 's/so: z with consonant' );
ok( p('с', 'зарёй')  eq 'с',  's/so: z with vowel' );
ok( p('с', 'шкафом') eq 'со', 's/so: sh with consonant' );
ok( p('с', 'шаром')  eq 'с',  's/so: sh with vowel' );
ok( p('с', 'жбаном') eq 'со', 's/so: zh with consonant' );
ok( p('с', 'жарой')  eq 'с',  's/so: zh with vowel' );

ok( p('с', 'мной')   eq 'со', 's/so: exception - mnoi' );

ok( p('в', 'вилке')    eq 'в',  'v/vo: v with vowel' );
ok( p('в', 'впадине')  eq 'во', 'v/vo: v with consonant' );
ok( p('в', 'всаднике') eq 'во', 'v/vo: v with consonant' );
ok( p('в', 'фраке')    eq 'во', 'v/vo: f with consonant' );

ok( p('в', 'мне')      eq 'во', 'v/vo: exception - mne' );
ok( p('в', 'многом')   eq 'во', 'v/vo: exception - mnogom' );

ok( p('над', 'мной')   eq 'надо',   'nad/nado: exception - mnoi' );
ok( p('над', 'лесом')  eq 'над',    'nad/nado: common - lesom' );

ok( p('от', 'всех')    eq 'ото',    'ot/oto: exception - vsekh' );
ok( p('от', 'рук')     eq 'от',     'ot/oto: common - ruk' );

ok( p('пред', 'мною')  eq 'предо',  'pred/predo: exception - mnoyu' );
ok( p('пред', 'Ноем')  eq 'пред',   'pred/predo: common - Noem' );

ok( p('перед', 'мной') eq 'передо', 'pered/peredo: exception - mnoi' );
ok( p('перед', 'роем') eq 'перед',  'pered/peredo: common - roem' );

ok( p('под', 'мной')   eq 'подо',   'pod/podo: exception - mnoi' );
ok( p('под', 'льдом')  eq 'подо',   'pod/podo: exception - ldom' );
ok( p('под', 'столом') eq 'под',    'pod/podo: common - stolom' );

