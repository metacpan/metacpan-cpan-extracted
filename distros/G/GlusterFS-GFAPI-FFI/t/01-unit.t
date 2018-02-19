#/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::Most;
use Data::Dumper;
use Test::Class;

our $ROOTDIR;

BEGIN
{
    use File::Basename          qw/dirname/;
    use File::Spec::Functions   qw/rel2abs/;

    ($ROOTDIR = dirname(rel2abs(__FILE__))) =~ s/\/[^\/]+$//g;
}

use lib "$ROOTDIR/lib", "$ROOTDIR/t/lib";

use TestFile;
use TestDir;
use TestVolume;

Test::Class->runtests;

done_testing();
