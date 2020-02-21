package main;

use strict;
use warnings;

use Test2::V0;
use Test2::Tools::LoadModule;

load_module_or_skip_all 'ExtUtils::Manifest', undef, [
    qw{ manicheck filecheck } ];

my @got = manicheck();
ok @got == 0, 'Missing files per MANIFEST';

@got = filecheck();
ok @got == 0, 'Files not in MANIFEST or MANIFEST.SKIP';

done_testing;

1;
