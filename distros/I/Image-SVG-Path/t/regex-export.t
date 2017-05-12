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
use Image::SVG::Path ':regex';
ok ($svg_path);
like ('M 1 2 3 4', $moveto);
unlike ('M 1 2 3 4', $drawto_command);
like ('a25,25 -30 0,1 50,-25', $elliptical_arc);
like ('Q400,50 600,300', $quadratic_bezier_curveto);
like ('c0-1.68-1.36-3.03-3.03-3.03', $curveto);
like ('s0,75.97-0.23,82.08', $smooth_curveto);


# my $longinput = 'm60.356931,42.59396c2.215968,0.45727,4.098968,0.406462,5.361955,0,3.019688,-0.965348,10.746874,-2.680111,17.302926,-4.153536,3.524883,-0.787521,5.247139,0,4.408974,4.90295-0.654457,3.810584-4.328602,19.06562-4.902687,29.532023-0.47075,8.484899,1.733737,14.861275,9.9776,14.861275';

# TODO: {
#     local $TODO = 'Simplify regex';
#     my $warning;
#     local $SIG{__WARN__} = sub {
# 	$warning = shift;
#     };
# #    $longinput =~ s/([^eE])-/$1,-/g;
#     $longinput =~ $svg_path;
#     ok (! $warning || $warning !~ /exceeded/, "Regex does not blow up");
#     if ($warning) {
# 	diag ($warning);
#     }
# }

done_testing ();
