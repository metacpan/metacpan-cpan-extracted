use strict;
use warnings;
use Test::More;
use Eshu;

is(Eshu->detect_lang('schema.sql'),   'sql', '.sql detected');
is(Eshu->detect_lang('query.SQL'),    'sql', '.SQL upper-case detected');
is(Eshu->detect_lang('create.ddl'),   'sql', '.ddl detected');
is(Eshu->detect_lang('query.psql'),   'sql', '.psql detected');

done_testing;
