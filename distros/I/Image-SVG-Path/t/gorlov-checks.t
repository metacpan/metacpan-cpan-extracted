# This is to check some things about Alexander Gorlov's patch.

use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use Image::SVG::Path 'extract_path_info';
my @ex = extract_path_info ('M1,2,3,4');
ok (@ex == 2, "got implicit lineto");
is ($ex[0]->{name}, 'moveto', "got moveto as first element");
is ($ex[1]->{name}, 'lineto', "got correct name for implicit lineto");
done_testing ();
