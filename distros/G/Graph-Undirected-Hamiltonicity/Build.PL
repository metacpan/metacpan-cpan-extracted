#!/usr/bin/env perl                                                                                                                                                             

use strict;
use warnings;

# This file is used by http://travis-ci.com/                                                                                                                                    
# to generate and test a Build file                                                                                                                                             

my $file = "./Build";

open(my $fh, ">", $file) or die $!;

my $dzil = 'dzil';

print $fh "cpanm Dist::Zilla\n";
print $fh "$dzil authordeps | cpanm\n";
print $fh "$dzil listdeps | cpanm\n";
print $fh "$dzil install\n";

close($fh);

chmod (0755, $file) or exit(1);
