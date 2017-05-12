# Welcome to a -*- perl -*- test script
use strict;
use Test::More qw(no_plan);

use lib 't/';

use Cwd;

my $root = getcwd . '/t/';

warn "ROOT: $root";

my @html = glob 't/html/*.html';
system 
    "./spkg.pl --base_pkg_root=$root --base_pkg=html::Seamstress::Base $_"
    for @html;

ok 1;

