use strict;
use warnings;
use Test::More;
use Eshu;

is(Eshu->detect_lang('foo.rs'),  'rust', '.rs detected as rust');
is(Eshu->detect_lang('src/main.rs'), 'rust', 'path/to/file.rs detected');
is(Eshu->detect_lang('Foo.RS'),  'rust', '.RS upper-case detected');

done_testing;
