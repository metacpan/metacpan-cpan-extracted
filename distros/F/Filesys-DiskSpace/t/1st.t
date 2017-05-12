# -*- Mode: Perl -*-

# Pseudo test file. Usefull to avoid a failure when all other test files
# are skipped.

BEGIN { unshift @INC, "lib", "../lib" }
use strict;
use Filesys::DiskSpace;

print "1..1\nok 1\n";
