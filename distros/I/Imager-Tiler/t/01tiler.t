#
#   Imager::Tiler test script
#
use vars qw($tests $loaded);
BEGIN {
    push @INC, './t';
    $tests = 42;

    print STDERR "
 *** Note: test result images can be viewed by
 *** opening the generated results.html file
 *** in a web browser.
 ";
    $^W= 1;
    $| = 1;
    print "1..$tests\n";
}

END {print "not ok 1\n" unless $loaded;}

use strict;
use warnings;

use Imager::Tiler;

use Imager::Tiler qw(tile);

my $testno = 1;

my @imgfiles = ('t/imgs/smallimg.png', 't/imgs/mediumimg.png', 't/imgs/bigimg.png');
#
#   if standalone, add any path prefix
@imgfiles = map "$ARGV[0]/$_", @imgfiles
    if $ARGV[0];

my @images = ();
foreach (@imgfiles) {
    push @images, Imager->new();
    die $images[-1]->errstr()
        unless $images[-1]->read(file => $_);

if ( 1 == 0) {
    s!^t/imgs/!orig_!;
    my $newimg = Imager->new(xsize => $images[-1]->getwidth(),
        ysize => $images[-1]->getheight(), channels => 4);
    $newimg->paste(img => $images[-1],
        left => 0, top => 0,
#       src_minx => 0, src_miny => 0,
#       src_maxx => $images[-1]->getwidth(), src_maxy => $images[-1]->getheight()
        ) or die $newimg->errstr();
    $newimg->write(file => $_, type => 'png');
}
}

srand(time());

sub report_result {
    my ($result, $testmsg, $okmsg, $notokmsg) = @_;

    if ($result) {

        $okmsg = '' unless $okmsg;
        print STDOUT (($result eq 'skip') ?
            "ok $testno # skip $testmsg\n" :
            "ok $testno # $testmsg $okmsg\n");
    }
    else {
        $notokmsg = '' unless $notokmsg;
        print STDOUT
            "not ok $testno # $testmsg $notokmsg\n";
    }
    $testno++;
}

#
#   prelims: use shared test count for eventual
#   threaded tests
#
$loaded = 1;
report_result(1, 'load');
#   2. Tile single image, computed coords, not centered, default background, no margins

my $img = tile(Images => [ $images[0] ]);
saveimg($testno, $img);
report_result(defined $img, 'Tile single image, computed coords, not centered, default background, no margins');

#   3. Tile single image, computed coords, centered, default background, edge margin
$img = tile(Images => [ $images[0] ], Center => 1, EdgeMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile single image, computed coords, centered, default background, edge margin');

#   4. Tile single image, computed coords, centered, named background, vert edge only
$img = tile(Images => [ $images[0] ], Center => 1, Background => 'lorange', VEdgeMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile single image, computed coords, centered, named background, vert edge only');

#   5. Tile single image, computed coords, centered, hex background, horiz edge only
$img = tile(Images => [ $images[0] ], Center => 1, Background => '#FF00DEADBEEF', HEdgeMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile single image, computed coords, centered, hex background, horiz edge only');

#   6. Tile single image, computed coords, centered, hex background, tile margin
$img = tile(Images => [ $images[0] ], Center => 1, Background => '#FF00DEADBEEF', TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile single image, computed coords, centered, hex background, tile margin');

#   7. Tile single image, computed coords, centered, named background, vert tile only
$img = tile(Images => [ $images[0] ], Center => 1, Background => 'white', VTileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile single image, computed coords, centered, named background, vert tile only');

#   8. Tile single image, computed coords, centered, hex background, horiz tile only
$img = tile(Images => [ $images[0] ], Center => 1, Background => '#0000FFFFFFFF', HTileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile single image, computed coords, centered, hex background, horiz tile only');

#   9. Tile single image, computed coords, centered, named background, edge and tile margin
$img = tile(Images => [ $images[0] ], Center => 1, Background => 'green', EdgeMargin => 7, TileMargin => 10, Shadow => 1);
saveimg($testno, $img);
report_result(defined $img, 'Tile single image, computed coords, centered, named background, edge and tile margin');

#   9. Tile single image, computed coords, bad width/height, centered, named background, edge and tile margin
eval {
$img = tile(
    Images => [ $images[0] ],
    Width => 12,
    Height => 5,
    Center => 1,
    Background => 'green',
    EdgeMargin => 7,
    TileMargin => 10);
};
report_result($@, 'Tile single image, computed coords, bad width/height, centered, named background, edge and tile margin');

#   10. Tile single image, explicit coords
$img = tile(Images => [ $images[0] ], Coordinates => [ 10, 10 ], Width => 50, Height => 75);
saveimg($testno, $img);
report_result(defined $img, 'Tile single image, explicit coords');

#   11. Tile single image as filename, explicit coords
$img = tile(Images => [ $imgfiles[0] ], Coordinates => [ 10, 10 ], Width => 50, Height => 75);
saveimg($testno, $img);
report_result(defined $img, 'Tile single image as filename, explicit coords');

#   12. Tile 2 identical images, computed coords, not centered, hex background, edge and tile margin
$img = tile(Images => [ $images[0], $images[0] ], Background => '#800080008000', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 2 identical images, computed coords, not centered, hex background, edge and tile margin');

#   13. Tile 3 identical images, computed coords, not centered, hex background, edge and tile margin
$img = tile(Images => [ $images[0], $images[0], $images[0] ], Background => '#800080008000', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 3 identical images, computed coords, not centered, hex background, edge and tile margin');

#   14. Tile 4 identical images, computed coords, not centered, hex background, edge and tile margin
$img = tile(Images => [ $images[0], $images[0], $images[0], $images[0] ],
    Background => '#800080008000', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 4 identical images, computed coords, not centered, hex background, edge and tile margin');

#   15. Tile 5 identical images, computed coords, not centered, hex background, edge and tile margin
$img = tile(Images => [ $images[0], $images[0], $images[0], $images[0], $images[0] ],
    Background => '#800080008000', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 5 identical images, computed coords, not centered, hex background, edge and tile margin');

#   16. Tile 6 identical images, computed coords, not centered, hex background, edge and tile margin
$img = tile(Images => [ $images[0], $images[0], $images[0], $images[0], $images[0], $images[0] ],
    Background => '#FFFFFFFFFFFF', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 6 identical images, computed coords, not centered, hex background, edge and tile margin');

#   17. Tile 7 identical images, computed coords, not centered, hex background, edge and tile margin
$img = tile(Images => [ $images[0], $images[0], $images[0], $images[0], $images[0], $images[0], $images[0] ],
    Background => '#FFFFFFFFFFFF', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 7 identical images, computed coords, not centered, hex background, edge and tile margin');

#   18. Tile 8 identical images, computed coords, not centered, hex background, edge and tile margin
$img = tile(Images => [ $images[0], $images[0], $images[0] , $images[0] , $images[0] , $images[0] , $images[0] , $images[0]  ],
    Background => '#FFFFFFFFFFFF', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 8 identical images, computed coords, not centered, hex background, edge and tile margin');

#   19. Tile 9 identical images, computed coords, not centered, hex background, edge and tile margin
$img = tile(Images => [ $images[0], $images[0], $images[0], $images[0], $images[0], $images[0], $images[0], $images[0], $images[0] ],
    Background => '#FFFFFFFFFFFF', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 9 identical images, computed coords, not centered, hex background, edge and tile margin');

#   20. Tile 10 identical images, computed coords, not centered, hex background, edge and tile margin
$img = tile(Images => [ $images[0], $images[0], $images[0], $images[0], $images[0], $images[0], $images[0], $images[0], $images[0], $images[0] ],
    Background => '#FFFFFFFFFFFF', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 10 identical images, computed coords, not centered, hex background, edge and tile margin');


#   21. Tile 2 different images, computed coords, not centered, hex background, edge and tile margin
$img = tile(Images => [ $images[0], $images[1] ], Background => '#FFFFFFFFFFFF', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 2 different images, computed coords, not centered, hex background, edge and tile margin');

#   22. Tile 3 different images, computed coords, not centered, hex background, edge and tile margin
$img = tile(Images => [ @images ], Background => '#FFFFFFFFFFFF', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 3 different images, computed coords, not centered, hex background, edge and tile margin');

#   23. Tile 4 different images, computed coords, not centered, hex background, edge and tile margin
$img = tile(Images => [ random_images(4) ], Background => '#800080008000', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 4 different images, computed coords, not centered, hex background, edge and tile margin');

#   24. Tile 5 different images, computed coords, centered, hex background, edge and tile margin
$img = tile(Images => [ random_images(5) ], Background => '#800080008000', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 5 different images, computed coords, not centered, hex background, edge and tile margin');

#   25. Tile 6 different images, computed coords, centered, hex background, edge and tile margin
$img = tile(Images => [ random_images(6) ], Background => '#800080008000', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 6 different images, computed coords, not centered, hex background, edge and tile margin');

#   26. Tile 7 different images, computed coords, centered, hex background, edge and tile margin
$img = tile(Images => [ random_images(7) ], Background => '#800080008000', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 7 different images, computed coords, not centered, hex background, edge and tile margin');

#   27. Tile 8 different images, computed coords, centered, hex background, edge and tile margin
$img = tile(Images => [ random_images(8) ], Background => '#800080008000', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 8 different images, computed coords, not centered, hex background, edge and tile margin');

#   28. Tile 9 different images, computed coords, centered, hex background, edge and tile margin
$img = tile(Images => [ random_images(9) ], Background => '#800080008000', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 9 different images, computed coords, not centered, hex background, edge and tile margin');

#   29. Tile 10 different images, array context, computed coords, centered, hex background, edge and tile margin
my @coords;
($img, @coords) = tile(Images => [ random_images(10) ], Background => '#800080008000', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img && (scalar @coords == 20),
    'Tile 10 different images, array context, computed coords, not centered, hex background, edge and tile margin');

#   30. Tile  2 identical images, explicit coords
$img = tile(Images => [ $images[0], $images[0] ], Coordinates => [ 10, 10, 50, 50 ], Width => 100, Height => 100);
saveimg($testno, $img);
report_result(defined $img, 'Tile 2 identical images, explicit coords');

#   31. Tile 10 different images, explicit coords
$img = tile(Images => [ random_images(10) ],
    Coordinates => [
        10, 10, 10, 50, 10, 100,
        100, 10, 100, 50, 100, 100,
        350, 10, 350, 50, 350, 100,
        450, 50
    ],
    Width => 400, Height => 700);
saveimg($testno, $img);
report_result(defined $img, 'Tile 10 different images, explicit coords');
#
# images-per-row tests
#
#   32. Tile 2 identical images, computed coords, 1 image per row, not centered, hex background, edge and tile margin
$img = tile(Images => [ $images[0], $images[0] ], ImagesPerRow => 1, Background => '#800080008000', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 2 identical images, 1 image per row, computed coords, not centered, hex background, edge and tile margin');

#   33. Tile 2 identical images, computed coords, 20 image per row, not centered, hex background, edge and tile margin
$img = tile(Images => [ $images[0], $images[0] ], ImagesPerRow => 20, Background => '#800080008000', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 2 identical images, 20 images per row, computed coords, not centered, hex background, edge and tile margin');

#   34. Tile 3 identical images, computed coords, 1 image per row, not centered, hex background, edge and tile margin
$img = tile(Images => [ $images[0], $images[0], $images[0] ], ImagesPerRow => 1, Background => '#800080008000', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 3 identical images, 1 image per row, computed coords, not centered, hex background, edge and tile margin');

#   35. Tile 5 identical images, computed coords, 2 images per row, centered, hex background, edge and tile margin
$img = tile(Images => [ $images[0], $images[0], $images[0], $images[0], $images[0] ],
    ImagesPerRow => 2, Background => '#800080008000', Center => 1, EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 5 identical images, computed coords, 2 images per row, centered, hex background, edge and tile margin');

#   36. Tile 9 identical images, computed coords, 5 images per row, not centered, hex background, edge and tile margin
$img = tile(Images => [ $images[0], $images[0], $images[0], $images[0], $images[0], $images[0], $images[0], $images[0], $images[0] ],
    ImagesPerRow => 5, Background => '#FFFFFFFFFFFF', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 9 identical images, 5 images per row, computed coords, not centered, hex background, edge and tile margin');

#   37. Tile 10 identical images, computed coords, 5 images per row, not centered, hex background, edge and tile margin
$img = tile(Images => [ $images[0], $images[0], $images[0], $images[0], $images[0], $images[0], $images[0], $images[0], $images[0], $images[0] ],
    ImagesPerRow => 5, Background => '#FFFFFFFFFFFF', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 10 identical images, 5 images per row, computed coords, not centered, hex background, edge and tile margin');


#   38. Tile 2 different images, 1 image per row, computed coords, not centered, hex background, edge and tile margin
$img = tile(Images => [ $images[0], $images[1] ], ImagesPerRow => 1, Background => '#FFFFFFFFFFFF', EdgeMargin => 7, TileMargin => 10, Shadow => 1);
saveimg($testno, $img);
report_result(defined $img, 'Tile 2 different images, 1 image per row, computed coords, not centered, hex background, edge and tile margin');

#   39. Tile 6 different images, 2 images per row, computed coords, not centered, hex background, edge and tile margin
$img = tile(Images => [ random_images(6) ], ImagesPerRow => 2, Background => '#800080008000', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 6 different images, 2 images per row, computed coords, not centered, hex background, edge and tile margin');

#   40. Tile 7 different images, 4 images per row, computed coords, centered, hex background, edge and tile margin
$img = tile(Images => [ random_images(7) ], ImagesPerRow => 4, Background => '#800080008000', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img, 'Tile 7 different images, 4 images per row, computed coords, not centered, hex background, edge and tile margin');

#   41. Tile 10 different images, array context, 2 images per row, computed coords, centered, hex background, edge and tile margin
($img, @coords) = tile(Images => [ random_images(10) ], ImagesPerRow => 2, Center => 1, Background => '#800080008000', EdgeMargin => 7, TileMargin => 10);
saveimg($testno, $img);
report_result(defined $img && (scalar @coords == 20),
    'Tile 10 different images, array context, 2 images per row, computed coords, centered, hex background, edge and tile margin');

open OUTF, '>results.html';
print OUTF <<'HTML';

<html>
<body>
<h4>Tile single image, computed coords, not centered, default background, no margins</h4>
<img src='result2.png'><p>
<h4>Tile single image, computed coords, centered, default background, edge margin</h4>
<img src='result3.png'><p>
<h4>Tile single image, computed coords, centered, named background, vert edge only</h4>
<img src='result4.png'><p>
<h4>Tile single image, computed coords, centered, hex background, horiz edge only</h4>
<img src='result5.png'><p>
<h4>Tile single image, computed coords, centered, hex background, tile margin</h4>
<img src='result6.png'><p>
<h4>Tile single image, computed coords, centered, named background, vert tile only</h4>
<img src='result7.png'><p>
<h4>Tile single image, computed coords, centered, hex background, horiz tile only</h4>
<img src='result8.png'><p>
<h4>Tile single image, computed coords, centered, named background, edge and tile margin</h4>
<img src='result9.png'><p>
<h4>Tile single image, explicit coords</h4>
<img src='result11.png'><p>
<h4>Tile single image as filename, explicit coords</h4>
<img src='result12.png'><p>
<h4>Tile 2 identical images, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result13.png'><p>
<h4>Tile 3 identical images, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result14.png'><p>
<h4>Tile 4 identical images, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result15.png'><p>
<h4>Tile 5 identical images, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result16.png'><p>
<h4>Tile 6 identical images, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result17.png'><p>
<h4>Tile 7 identical images, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result18.png'><p>
<h4>Tile 8 identical images, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result19.png'><p>
<h4>Tile 9 identical images, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result20.png'><p>
<h4>Tile 10 identical images, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result21.png'><p>
<h4>Tile 2 different images, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result22.png'><p>
<h4>Tile 3 different images, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result23.png'><p>
<h4>Tile 4 different images, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result24.png'><p>
<h4>Tile 5 different images, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result25.png'><p>
<h4>Tile 6 different images, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result26.png'><p>
<h4>Tile 7 different images, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result27.png'><p>
<h4>Tile 8 different images, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result28.png'><p>
<h4>Tile 9 different images, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result29.png'><p>
<h4>Tile 10 different images, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result30.png'><p>
<h4>Tile 2 identical images, explicit coords</h4>
<img src='result31.png'><p>
<h4>Tile 10 different images, explicit coords</h4>
<img src='result32.png'><p>
<h4>Tile 2 identical images, 1 image per row, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result33.png'><p>
<h4>Tile 2 identical images, 20 images per row, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result34.png'><p>
<h4>Tile 3 identical images, 1 image per row, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result35.png'><p>
<h4>Tile 5 identical images, computed coords, 2 images per row, centered, hex background, edge and tile margin</h4>
<img src='result36.png'><p>
<h4>Tile 9 identical images, 5 images per row, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result37.png'><p>
<h4>Tile 10 identical images, 5 images per row, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result38.png'><p>
<h4>Tile 2 different images, 1 image per row, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result39.png'><p>
<h4>Tile 6 different images, 2 images per row, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result40.png'><p>
<h4>Tile 7 different images, 4 images per row, computed coords, not centered, hex background, edge and tile margin</h4>
<img src='result41.png'><p>
<h4>Tile 10 different images, array context, 2 images per row, computed coords, centered, hex background, edge and tile margin</h4>
<img src='result42.png'><p>
</body>
</html>

HTML

close OUTF;

sub saveimg {
    open OUTF, ">result$_[0].png";
    binmode OUTF;
    print OUTF $_[1];
    close OUTF;
}

sub random_images {
    my $count = shift;
    my @rnd_images = ();

    push @rnd_images, $images[int(rand() * 3)]
        foreach (1..$count);
    return @rnd_images;
}

