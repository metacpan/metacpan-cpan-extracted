#!/usr/local/bin/perl -w

use strict;
use warnings;
use Test::More tests => 7;
use Image::Epeg qw(:constants);

# from scalarref
do {
    open my $fh, "t/test.jpg" or die $!;
    binmode $fh;
    my $src = do { local $/; <$fh> };
    close $fh;

    my $epeg = Image::Epeg->new( \$src );
    isa_ok $epeg, 'Image::Epeg';

    is $epeg->get_width(), 640, 'get_width()';
    is $epeg->get_height(), 480, 'get_height()';

    $epeg->resize( 150, 150, MAINTAIN_ASPECT_RATIO );
    $epeg->set_comment( "foobar" );

    $epeg->write_file( "t/test2.jpg" );
    ok -f "t/test2.jpg", 'saved';
};

# from file
do {
    my $epeg = Image::Epeg->new( "t/test2.jpg" );
    isa_ok $epeg, 'Image::Epeg';

    is $epeg->get_comment(), "foobar", 'get_comment';

    $epeg->set_quality( 10 );

    $epeg->resize( $epeg->get_height(), $epeg->get_width() );
    my $data = $epeg->get_data();
    ok $data, 'valid response';
};

unlink 't/test2.jpg';

