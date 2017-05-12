#!perl -T

use Test::More tests => 18;
use strict;
no warnings 'utf8';

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse( <<'--end--' ), 'JE::Code');
  a = 'Hello World';
  b = "Hello World";
  c = 'Hello "World"';
  d = "'Hello' World";
  e = 'Hello \'World\'';
  f = "Hello \"World\"";
  g = "Hello \\World\\";

  h = '\u0041';
  i = "\u0041";
  j = '\x20\b\f\n\r\t\v\s' // \s is literal 's'
  k = "\x20\b\f\n\r\t\v\s"

  JE = 'JE'

--end--

my $code2 = $j->parse(qq/ foo = '\x{dfff}' + "\x{d800}" /);

#--------------------------------------------------------------------#
# Tests 3-4: Run code

$code->execute;
is($@, '', 'execute code');
$code2->execute;
is($@, '', 'execute code with surrogates in string literals');

#--------------------------------------------------------------------#
# Tests 5-17: Check side-effects

is( $j->prop('a'), 'Hello World', 'single quotes'  );
is( $j->prop('b'), 'Hello World',  'double quotes'       );
is( $j->prop('c'), 'Hello "World"', 'single containing double');
is( $j->prop('d'), "'Hello' World", 'double containing single'    );
is( $j->prop('e'), "Hello 'World'",  'single w/escaped single'       );
is( $j->prop('f'), 'Hello "World"',    'double w/escaped double'       );
is( $j->prop('g'), 'Hello \World\\',     'escaped wack'                 );
is( $j->prop('h'), 'A',                   'single with \uHHHH escapes'   );
is( $j->prop('i'), 'A',                   'double with \uHHHH escapes'   );
is( $j->prop('j'), " \b\f\n\r\t\cKs",    'single with wack escapes'     );
is( $j->prop('k'), " \b\f\n\r\t\cKs",    'double with wack escapes'     );
is( $j->prop('JE'), "JE",                'name of existing Perl package' );
       # Yes, that one *was* failing at one time.
is( $j->prop('foo'), "\x{dfff}\x{d800}" , 'surrogate in str literal'     );

#--------------------------------------------------------------------#
# Test 18: Make sure surrogates escape sequences in string literals do not
#          warn

$SIG{__WARN__} = sub {
	warn @_;
	fail 'surrogates escape sequences should not warn';
	exit;
};

no warnings 'utf8';
is $j->eval(q/ '\udf00' /), "\x{df00}",
	'surrogate escape sequence in string literal';
