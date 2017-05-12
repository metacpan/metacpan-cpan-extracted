#!/usr/bin/perl -w
use strict;

use lib qw(./lib);
use Devel::Platform::Info;

use Data::Dumper;

my $info = Devel::Platform::Info->new();
my $data = $info->get_info();

print Dumper($data);
#print Dumper($info);
