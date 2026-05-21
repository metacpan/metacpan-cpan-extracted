use strict;
use warnings;
use Test::More;

plan skip_all => 'set RELEASE_TESTING' unless $ENV{RELEASE_TESTING};

eval { require Test::DistManifest; Test::DistManifest->import; 1 }
    or plan skip_all => 'Test::DistManifest required';

manifest_ok();
