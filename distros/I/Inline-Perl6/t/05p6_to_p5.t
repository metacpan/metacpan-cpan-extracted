use 5.10.0;
use strict;
use warnings;
use utf8;

use Encode qw(decode);
use Test::More;
use Inline::Perl6;

is Inline::Perl6::p6_run('5'), 5;
is Inline::Perl6::p6_run('5.5'), 5.5;
is Inline::Perl6::p6_run('"Perl 5"'), 'Perl 5';
is_deeply Inline::Perl6::p6_run('$[1, 2]'), [1, 2];
is_deeply Inline::Perl6::p6_run('$[1, [2, 3]]'), [1, [2, 3]];
is_deeply Inline::Perl6::p6_run('${a => 1, b => 2}'), {a => 1, b => 2};
is_deeply Inline::Perl6::p6_run('${a => 1, b => {c => 3}}'), {a => 1, b => {c => 3}};
is_deeply Inline::Perl6::p6_run('$[1, {b => {c => 3}}]'), [1, {b => {c => 3}}];
ok not(defined Inline::Perl6::p6_run('Any')), 'p5 undef maps to p6 Any';

is Inline::Perl6::p6_run('
    "Pörl 5"
'), 'Pörl 5';

is decode('latin-1', Inline::Perl6::p6_run('
    "Pörl 5".encode("latin-1")
')), 'Pörl 5';

done_testing;
