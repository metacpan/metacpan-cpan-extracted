#!/usr/bin/env perl

42;
__END__

### That's the way to do it. 

use FindBin qw($Bin);

use strict;
use warnings;

# This file is used by http://travis-ci.com/
# to generate and test a Build file

my $file = "./Build";

open(my $fh, ">", $file) or die $!;

# my $dzil=qx(which dzil);
# chomp $dzil;

my $dzil = 'dzil';

say $fh "cpanm Dist::Zilla";
say $fh "$dzil authordeps | cpanm";
say $fh "$dzil listdeps | cpanm";
 

### say $fh "$dzil test && $dzil install ";
say $fh "$dzil test";

# if ( $ARGV[0] ) {
#     say $fh "$dzil install";
# } else {
#     say $fh "$dzil test";
# }

close($fh);

chmod (0755, $file) or exit(1);
