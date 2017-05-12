#!perl -T

use Test::More tests => 42;
use strict;
use utf8;
no warnings 'utf8';

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse( <<'--end--' ), 'JE::Code') or diag $@;

// flags:

t4 = /a/i
t5 = /a/g
t6 = /a/m
t7 = /a/mg
t8 = /a/gi
t9 = /a/mi
t10 = /a/mgi
t11 = /a/

// JS regexp features that differ from Perl's:

t12 = /^[^a]/
t13 = /^[^a]/m
t14 = /$[$]/
t15 = /$[$]/m
t16 = /\b[\b]/
t17 = /\B/
t18 = /.[.]/
t19 = /\v[\v]/
t20 = /\n[\n]/
t21 = /\r[\r]/
t22 = /\c`[\c`]/
t23 = /\u1234[\uabcD]/
t24 = /\d[\d]/
t25 = /\D[\D]/
t26 = /\s[\s]/
t27 = /\S[\S]/
t28 = /\w[\w]/
t29 = /\W[\W]/
t30 = /[]/
t31 = /[^]/      

t32 = /[\Sa]/  // negative and positive char classes together
t33 = /[a]/    // positive only
t34 = /[\S]/   // negative only
t35 = /[\D\W]/ // two negatives

t36 = /[^/]/   // unescaped / in initial character class (ECMAScript 5)
t37 = /a[^/]/  // unescaped / in character class (ECMAScript 5)

--end--

my $code2 = $j->parse(qq| foo = /\x{dfff}\x{d800}/ |);

#--------------------------------------------------------------------#
# Tests 3-4: Run code

$code->execute;
is($@, '', 'execute code');
$code2->execute;
is($@, '', 'execute code with surrogates in regexp literals');

#--------------------------------------------------------------------#
# Tests 5-39: Check to see whether regexps were parsed and com-
#             piled properly

my $B = qr/^\(\?(?:\^u?|-\w+):\(\?/;  # begin re
my $E = qr/\)\)/;            # end re
my $C = qr/\(\?(?:\^u?|-\w+):\(\?\{[^}]+}\)\)(?:\(\?\?\{""\}\))?/;
                     # embedded code

# Each regexp is embedded within (?-xism:(?<flags>: ... ))
# $B matches everything up to <flags>. 'xism' may be expanded in future
# Perl versions, so I'm using \w+ to match it. (So much for that ‘future-
# compatibility’! Now I have to check for (?^: and (?^u:, too.)
# $E matches the last two parens.

my $tmp;

like( $j->prop('t4'), qr/$B  i: $C a  $E/x, '/i' );

$tmp = $j->prop('t5');
ok( $tmp =~ /$B  : $C a  $E/x && $tmp->prop('global'), '/g' );

like( $j->prop('t6'), qr/$B  m: $C a  $E/x, '/m' );

$tmp = $j->prop('t7');
ok( $tmp =~ /$B  m: $C a  $E/x && $tmp->prop('global'), '/mg' );

$tmp = $j->prop('t8');
ok( $tmp =~ /$B  i: $C a  $E/x && $tmp->prop('global'), '/gi' );

like( $j->prop('t9'), qr/$B  mi: $C a  $E/x, '/mi' );

$tmp = $j->prop('t10');
ok( $tmp =~ /$B  mi: $C a  $E/x && $tmp->prop('global'), '/mgi' );

like( $j->prop('t11'), qr/$B  : $C a  $E/x, 'no modifiers' );


sub re_ok($$$) { # ignores flags
	my($var, $should_be, $test_name) = @_;
	like($j->prop($var), qr/$B\w*:$C\Q$should_be\E$E/, $test_name);
}

re_ok t12 => '^[^a]',                                    '/^[^a]/';
re_ok t13 => '(?:\A|(?<=[\cm\cj\x{2028}\x{2029}]))[^a]', '/^[^a]/m';
re_ok t14 => '\z[$]',                                    '/$[$]/';
re_ok t15 => '(?:\z|(?=[\cm\cj\x{2028}\x{2029}]))[$]',   '/$[$]/m';
re_ok t16 => '(?:(?<=[A-Za-z0-9_])(?![A-Za-z0-9_])|'
              . '(?<![A-Za-z0-9_])(?=[A-Za-z0-9_]))[\b]','/\b[\b]/';
re_ok t17 => '(?:(?<=[A-Za-z0-9_])(?=[A-Za-z0-9_])|'
              . '(?<![A-Za-z0-9_])(?![A-Za-z0-9_]))',    '/\B/';
re_ok t18 => '[^\cm\cj\x{2028}\x{2029}][.]',             '/.[.]/';
re_ok t19 => '\cK[\cK]',                                 '/\v[\v]/';
re_ok t20 => '\cj[\cj]',                                 '/\n[\n]/';
re_ok t21 => '\cm[\cm]',                                 '/\r[\r]/';
re_ok t22 => '\c`[\c`]',                                '/\c`[\c`]/';
re_ok t23 => '\x{1234}[\x{abcD}]',                      '/\u1234[\uabcD]/';
re_ok t24 => '[0-9][0-9]',                              '/\d[\d]/';
re_ok t25 => '[^0-9][^0-9]',                            '/\D[\D]/';
re_ok t26 => '[\p{Zs}\s\ck][\p{Zs}\s\ck]',              '/\s[\s]/';
re_ok t27 => '[^\p{Zs}\s\ck][^\p{Zs}\s\ck]',            '/\S[\S]/';
re_ok t28 => '[A-Za-z0-9_][A-Za-z0-9_]',                '/\w[\w]/';
re_ok t29 => '[^A-Za-z0-9_][^A-Za-z0-9_]',              '/\W[\W]/';
re_ok t30 => '(?!)',                                    '/[]/';
re_ok t31 => '(?s:.)',                                  '/[^]/';
re_ok t32 => '(?:[^\p{Zs}\s\ck]|[a])',                  '/[\Sa]/';
re_ok t33 => '[a]',                                     '/[a]/';
re_ok t34 => '[^\p{Zs}\s\ck]',                          '/[.]/';
re_ok t35 => '(?:[^0-9]|[^A-Za-z0-9_])',                '/[\D\W]/';
re_ok t36 => '[^/]',                                    '/[^/]/';
re_ok t37 => 'a[^/]',                                   'a/[^/]/';

re_ok foo => '\x{dfff}\x{d800}',                        'surrogates';

#--------------------------------------------------------------------#
# Test 40: Make sure invalid regexp modifiers do not warn

$SIG{__WARN__} = sub {
	warn @_;
	fail 'invalid regexp modifiers should not warn';
	exit;
};

is $j->eval(q| /uue/oeoentuUCGD |), undef,
	'invalid regexp modifiers do not warn';

#--------------------------------------------------------------------#
# Tests 41-2: Make sure invalid regexp modifiers do not warn

$j->new_function(ok => \&ok);
$j->eval(<<'---');
try{eval('/)/');fail('eval("/)/")')}
catch(e){ok(e instanceof SyntaxError, 'eval("/)/")')}
try{eval('/) /');fail('eval("/) /")')}
catch(e){ok(e instanceof SyntaxError, 'eval("/) /")')}
---
