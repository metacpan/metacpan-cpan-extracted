#!perl
use strict;
use warnings;
use lib 'lib';
use Path::Class;
use Test::More tests => 129;

use_ok('Image::Imlib2::Thumbnail');

dir( 't', 'tmp' )->rmtree;

my $thumbnail = Image::Imlib2::Thumbnail->new;

$thumbnail->add_size(
    {   type   => 'landscape',
        name   => 'header',
        width  => 350,
        height => 200
    }
);

$thumbnail->add_size(
    {   type   => 'portrait',
        name   => 'header',
        width  => 350,
        height => 200
    }
);

$thumbnail->add_size(
    {   type   => 'landscape',
        name   => '200_width',
        width  => 200,
        height => 0,
    }
);
$thumbnail->add_size(
    {   type   => 'portrait',
        name   => '200_height',
        width  => 0,
        height => 200,
    }
);

foreach my $source (<t/*.png>) {
    my $basename = file($source)->basename;
    $basename =~ s/.png//;
    my $directory = dir( 't', 'tmp', $basename );
    $directory->mkpath;
    my @thumbnails = $thumbnail->generate( $source, $directory->stringify );

    my ($header) = grep { $_->{name} eq 'header' } @thumbnails;
    my $filename = $header->{filename};
    is( $header->{name},      'header',    "$filename name" );
    is( $header->{width},     '350',       "$filename width" );
    is( $header->{height},    '200',       "$filename height" );
    is( $header->{mime_type}, 'image/png', "$filename mime_type" );
}

