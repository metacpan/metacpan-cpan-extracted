# DO NOT EDIT! This file is written by perl_setup_dist.
# If needed, you can add content at the end of the file.

#!/usr/bin/perl

use strict;
use warnings;

use Test::CPANfile;
use Test2::V0;

our $VERSION = 0.01;

cpanfile_has_all_used_modules(perl_version => 5.026, develop => 1, suggests => 1);

done_testing;

# End of the template. You can add custom content below this line.
