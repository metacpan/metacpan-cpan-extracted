use strict;
use warnings;

use Test::More;
use Test::CPANfile;

cpanfile_has_all_used_modules(
    exclude_core => 1,
    perl_version => '5.014',
);

done_testing;
