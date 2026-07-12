use strict;
use warnings;
use Test::More;
use Eshu;

plan tests => 8;

# Extension-based detection
is(Eshu->detect_lang('foo.c'),  'c',    '.c -> c');
is(Eshu->detect_lang('foo.h'),  'c',    '.h -> c');
is(Eshu->detect_lang('Foo.xs'), 'xs',   '.xs -> xs');
is(Eshu->detect_lang('foo.pl'), 'perl', '.pl -> perl');
is(Eshu->detect_lang('Foo.pm'), 'perl', '.pm -> perl');
is(Eshu->detect_lang('foo.t'),  'perl', '.t -> perl');

# Unknown extension
is(Eshu->detect_lang('foo.txt'), undef, '.txt -> undef');

# No extension
is(Eshu->detect_lang('Makefile'), undef, 'no extension -> undef');
