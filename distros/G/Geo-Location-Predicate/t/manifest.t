#!perl -w

# Author test: MANIFEST must list every file that is in the distribution, and
# nothing that is not.  This is the check that catches the classic packaging
# defect: a module or test the suite loads from the working directory, which
# would be absent for everyone installing from the tarball.
#
# Test::CheckManifest honours MANIFEST.SKIP, so build products and the author's
# own notes are excluded by the same rules `make dist` uses.

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs { 'Test::CheckManifest' => '0.9' };

Test::CheckManifest->import();
ok_manifest({ filter => [qr/(\.git)|(\..+\.yml$)/] });
