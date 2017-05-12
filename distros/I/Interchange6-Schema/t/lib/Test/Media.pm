package Test::Media;

use Test::Exception;
use Test::Roo::Role;

test 'media tests' => sub {

    my $self = shift;

    my $ret;

    my $schema = $self->ic6s_schema;

    my %product_data = (
        sku               => 'G000X',
        name              => 'Six Tulips',
        short_description => 'What says I love you',
        description       => 'Surprise',
        price             => '19.95',
        uri               => 'six-tulips',
        weight            => '4',
        canonical_sku     => undef,
    );

    my @media = (
        {
            file      => 'product/image.jpg',
            uri       => 'image.jpg',
            mime_type => 'image/jpeg',
        },
        {
            file      => 'product/image2.jpg',
            uri       => 'image2.jpg',
            mime_type => 'image/jpeg',
        },
        {
            file      => 'product/image3.jpg',
            uri       => 'image3.jpg',
            mime_type => 'image/jpeg',
        }
    );

    # create the image types
    $schema->resultset('MediaType')->create( { type => 'video' } )
      ->add_to_media_displays(
        {
            type => 'video',
            name => 'video',
            path => '/video/',
            size => ''
        }
      );

    my $imagetype =
      $schema->resultset('MediaType')->create( { type => 'image' } );

    foreach my $display (qw/image_cart image_detail image_thumb/) {
        $imagetype->add_to_media_displays(
            {
                type => $display,
                name => $display,
                path => "/images/$display",
                size => "testsize",
            }
        );
    }

    my $product = $self->products->first;

    foreach my $media_hashref (@media) {
        my $m = $product->add_to_media(
            { %$media_hashref, media_type => { type => 'image' }, } );
    }

    # another product with 1 media

    my $second = $self->products->next;

    $second->add_to_media(
        { %{ $media[0] }, media_type => { type => 'image' } } );

    my @second_media = $second->media;

    ok( @second_media == 1, $second->sku . " has only one media " );

    my @first_media = $product->media;

    ok( @first_media == 3, $product->sku . "has 3 media" );

    foreach my $m ( @first_media, @second_media ) {
        is $m->media_type->type, 'image', $m->uri . " is an image";
        is $m->type, 'image', "Shortcut works";
        my %to_find = (
            image_cart   => 1,
            image_detail => 1,
            image_thumb  => 1,
        );
        foreach my $display ( $m->media_type->media_displays ) {
            my $display_type = $display->type;
            delete $to_find{$display_type};
        }
        ok !%to_find, "All the display type found";
        my @displays = $m->displays;
        foreach my $d (@displays) {
            unlike $d->type, qr/video/,    $d->type . ' is not a video';
            like $d->path,   qr!/images/!, "found the path " . $d->path;
        }
    }

    # add a product with a video

    $second->add_to_media(
        {
            file       => 'product/video.mp4',
            uri        => 'video.mp4',
            mime_type  => 'video/mp4',
            media_type => {
                type => 'video',
            },
        }
    );

    @second_media = $second->media;

    ok( @second_media == 2, $second->sku . " now has two media " )
      or diag scalar(@second_media);

    lives_ok( sub { $ret = $second->media_by_type('fruit') },
        "media_by_type 'fruit'" );
    is( $ret, undef, "returned undef" );

    my @videos = $second->media_by_type('video');

    ok( @videos == 1, "Found 1 video" );

    is $videos[0]->type, 'video',     "found the video";
    is $videos[0]->uri,  'video.mp4', "found the uri";

    is_deeply $videos[0]->display_uris, { 'video' => '/video/video.mp4', },
      "Found the display uris";

    is $videos[0]->display_uri('video'), '/video/video.mp4', "found the uri";

    my @images = $second->media_by_type('image');

    ok( @images == 1, "Found 1 image" );
    my $img = shift(@images);

    is $img->type, 'image',     "found the image";
    is $img->uri,  'image.jpg', "found the uri";

    my $uris = $img->display_uris;

    is_deeply $img->display_uris,
      {
        'image_detail' => '/images/image_detail/image.jpg',
        'image_cart'   => '/images/image_cart/image.jpg',
        'image_thumb'  => '/images/image_thumb/image.jpg'
      },
      "Found the display uris";

    is $img->display_uri('image_detail'), '/images/image_detail/image.jpg',
      "Found the image detail uri";

    is $img->display_uri('video'), undef, "No video found for the image";

    $product->add_to_media(
        {
            file       => 'product/video.mp4',
            uri        => 'video.mp4',
            mime_type  => 'video/mp4',
            media_type => {
                type => 'video',
            },
        }
    );

    my ($video1) = $product->media_by_type('video');

    my ($video2) = $second->media_by_type('video');

    ok( $video1->media_id, "Found the media id" );
    ok( $video2->media_id, "Found the media id" );

    ok( $video1->media_id == $video2->media_id,
        "media id match when adding the same media to other products" );

    # cleanup
    $self->clear_products;
};

1;
