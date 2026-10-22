#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

BEGIN { plan skip_all => 'the op keyword needs perl 5.14' if $] < 5.014 }

use Ex::Op ();

sub compile_err {
    my ($src) = @_;
    local $@;
    eval qq{package EO::KwErr${\ int rand 1e9};\nuse Ex::Op;\n#line 10 "kw.pl"\n$src\n1} and return undef;
    return $@;
}

like( compile_err('op f (@x) { 1 }'),
      qr/^Ex::Op: the parameters of op f must be scalars, like \$x at kw\.pl line 10\b/,
      'an array parameter' );
like( compile_err('op f ($) { 1 }'),
      qr/^Ex::Op: a parameter of op f needs a name after the \$ at kw\.pl line 10\b/,
      'a $ with no name' );
like( compile_err('op f ($x, $x) { 1 }'),
      qr/^Ex::Op: op f has the parameter \$x twice at kw\.pl line 10\b/,
      'the same parameter twice' );
like( compile_err('op f ($x $y) { 1 }'),
      qr/^Ex::Op: expected , or \) in the parameters of op f at kw\.pl line 10\b/,
      'a missing comma' );
like( compile_err('op f ($x);'),
      qr/^Ex::Op: op f needs a block at kw\.pl line 10\b/,
      'no block' );
like( compile_err("op f (\n\$x,\n\$y\n)\n;"),
      qr/^Ex::Op: op f needs a block at kw\.pl line 14\b/,
      '... reported on the line where the block was wanted' );
like( compile_err("op f (\$x) {\n  my \$t = ;\n}"),
      qr/syntax error at kw\.pl line 11\b/,
      'a syntax error in the body is reported on its own line' );
like( compile_err("op f (\$x) {\n  \$x +\n  \$nope;\n}"),
      qr/Global symbol "\$nope" requires explicit package name.* at kw\.pl line 12\b/s,
      '... and so is a strict error two lines in' );
ok( compile_err('op ($x) { 1 }'), 'op with no name is not the keyword, and here a syntax error' );

done_testing;
