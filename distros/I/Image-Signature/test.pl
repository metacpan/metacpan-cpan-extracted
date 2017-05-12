use Test;
BEGIN { plan tests => 5 };

use Image::Signature;
ok(1);

sub prompt { print "$_[0] ... " }

print "Please specify the path of an image file [leave it blank to skip]: ";
chomp( $imgfile1 = <STDIN>);
if(-e $imgfile1){
    $img1 = new Image::Signature('ori.jpg');

    prompt "Producing color histograms";
    skip((-e$imgfile1) => $img1->color_histogram());

    prompt "Producing gray-level moment";
    skip((-e$imgfile1) => $img1->gray_moment());

    prompt "Producing signature";
    skip((-e$imgfile1) => $img1->signature());
}


print "Please specify the path of another image file for comparison [leave it blank to skip]: ";
chomp ( $imgfile2 = <STDIN> );
if(-e $imgfile2){
    $img2 = new Image::Signature($imgfile2);
    $img2->signature;

    prompt "Comparing files";
    ($img2->compare($img1));
    skip((-e$imgfile2) => $img2->compare($img1));
}


