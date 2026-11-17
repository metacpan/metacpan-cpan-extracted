use strict;
use warnings;
use Test::More;

eval "use Test::CheckManifest 1.29; 1"
    or plan skip_all => 'Test::CheckManifest 1.29 required';

ok_manifest();
