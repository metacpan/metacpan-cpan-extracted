#!/usr/bin/perl

#
# Test for Github Issue #5
# pathmk doesn't make deep directories
#
# Created by Joelle Maslak
#

use strict;
use warnings;

use Test::More;

use File::Temp;
use File::Copy::Recursive qw(pathmk);

my $tmpd = File::Temp->newdir;
note("Temp Dir: $tmpd");

# pathmk()
pathmk("$tmpd/1");
ok( ( -d "$tmpd/1" ), "Directories (1 directory deep) are created" );
pathmk("$tmpd/2/2");
ok( ( -d "$tmpd/2/2" ), "Deep directories (2 directories deep) are created" );
pathmk("$tmpd/3/3/3");
ok( ( -d "$tmpd/3/3/3" ), "Deep directories (3 directories deep) are created" );
pathmk("$tmpd/4/4/4/4");
ok( ( -d "$tmpd/4/4/4/4" ), "Deep directories (4 directories deep) are created" );

done_testing;

