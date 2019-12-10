use strict;
use Test::More 0.98;
use Plack::Test;
use HTTP::Request::Common;
use IIIF::Magick;
use IIIF::ImageAPI;
use File::Temp qw(tempdir);
use JSON::PP;

plan skip_all => "ImageMagick missing" unless IIIF::Magick::available();

my $cache = tempdir( CLEANUP => 1 );
my $app = IIIF::ImageAPI->new( images => 't/img', cache => $cache );
my $identifier = "67352ccc-d1b0-11e1-89ae-279075081939";

test_psgi $app, sub {
    my ( $cb, $res ) = @_;
    is $cb->( GET "/" )->code, "404", "/";

    # Image Information Request
    $res = $cb->( GET "/$identifier" );
    is $res->code, 303, "/{identifier}";
    $res = $cb->( GET "/$identifier/" );
    is $res->code, 303, "/{identifier}/";
    is $res->header('Location'), "http://localhost/$identifier/info.json";

    $res = $cb->( GET "/$identifier/info.json" );
    is $res->code, 200, "/{identifier}/info.json";

    # Image Request
    $res = $cb->( GET "/$identifier/pct:.1" );
    is $res->code, 303, "abbreviated, lax image request";
    is $res->header('Location'),
      "http://localhost/$identifier/full/pct:0.1/0/default.png";

    $res = $cb->( GET "/$identifier/full/max/0/default.png" );
    is $res->code, 200, "image request";

    $res = $cb->( GET "/$identifier/pct:200" );
    is $res->code, 400, "invalid image request (malformed)";

    $res = $cb->( GET "/$identifier/full/pct:0.01/0/default.png" );
    is $res->code, 400, "invalid image request (image size)";

    my $links = [ 
      '<http://iiif.io/api/image/3/level2.json>;rel="profile"',
      "<http://localhost/$identifier/0,0,10,10/max/0/default.png>;rel=\"canonical\"" ];

    $res = $cb->( GET "/$identifier/0,0,10,10/max/0/default.png" );
    is $res->code, 200, "valid image request";
    is_deeply [ sort $res->header('Link') ], $links, "Link headers";

    $res = $cb->( GET "/$identifier/0,0,10,10/10,10/0/default.png" );
    is $res->code, 200, "valid image request (from cache)";
    is_deeply [ sort $res->header('Link') ], $links, "Link headers";

    $res = $cb->( GET "/$identifier/0,0,10,10/max/0/default.xxx" );
    is $res->code, 400, "unsupported format";
};

$app = IIIF::ImageAPI->new(
    images    => sub { "t/img/$_[0].jpg"; },
    canonical => 1,
    base      => "https://example.org/iiif/",
    rights    => 'http://rightsstatements.org/vocab/InC-EDU/1.0/',
    maxHeight => 300,
    service   => []
);
test_psgi $app, sub {
    my ( $cb, $res ) = @_;

    $res = $cb->( GET "/example/pct:50" );
    is $res->code, 303, "redirect to canonical request";
    is $res->header('Location'),
      "https://example.org/iiif/example/full/150,100/0/default.jpg";

    $res = $cb->( GET "/example/info.json" );
    my $info = decode_json( $res->content );
    is_deeply [ sort keys %$info ], [
        qw(@context extraFeatures extraFormats extraQualities
          height id maxHeight profile protocol rights service type width)
      ],
      'info response';

    # TODO: maxHeight
};

test_psgi(
    IIIF::ImageAPI->new(
        images           => 't/img',
        magick_args      => [qw(-xxx)],
        formats          => [qw(jpg png gif pdf)],
        preferredFormats => [qw(gif png)]
    ),
    sub {
        my ( $cb, $res ) = @_;

        $res = $cb->( GET "/example/info.json" );
        my $info = decode_json( $res->content );
        is_deeply( $info->{extraFormats},     [qw(jpg png gif pdf)] );
        is_deeply( $info->{preferredFormats}, [qw(gif png)] );

        $res = $cb->( GET "/$identifier/full" );
        like $res->header('Location'), qr/\.gif/,
          "use preferred format as default";

        $res = $cb->( GET "/example/0,0,10,10/max/0/default.png" );
        is $res->code, 500, 'error response on ImageMagick error';
        is $res->header('Content-Type'), "application/json";
    }
);

done_testing;
