use Test::More tests=>2;

use Image::ValidJpeg ':all';

open $fh, 't/data/small.jpg';
is( check_jpeg($fh), GOOD, "valid_jpeg on valid image" );
close($fh);

open $fh, 't/data/small.jpg';
my $rv = check_jpeg $fh;
is( $rv, GOOD, "valid_jpeg on valid image" );
close($fh);

