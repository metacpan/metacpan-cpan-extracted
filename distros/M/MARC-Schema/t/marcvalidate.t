use strict;
use warnings;

use Test2::V0;
use Test::Script;

script_compiles('script/marcvalidate');
script_runs(
    ['script/marcvalidate', '--type', 'RAW', '--file', 't/camel.mrc']);

script_runs(['script/marcvalidate', '--type', 'RAW', 't/camel.mrc']);

script_runs(
    [
        'script/marcvalidate',    '--type',
        'RAW',                    '--schema',
        'share/marc-schema.json', 't/camel.mrc'
    ]
);

done_testing;
