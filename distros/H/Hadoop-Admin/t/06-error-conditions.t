# -*- Perl -*-

use strict;
use warnings;
use Test::More;

my %attributes=(
    jobtracker      => 'my.jt.hadoop',
    resourcemanager => 'my.rm.hadoop',
    );

use Hadoop::Admin;
my $ha='';

eval{ $ha=new Hadoop::Admin(%attributes); };
is($ha, '', "Can't have JobTracker and ResourceManager");

done_testing();
