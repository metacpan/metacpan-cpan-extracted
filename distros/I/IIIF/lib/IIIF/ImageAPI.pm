package IIIF::ImageAPI;
use 5.014001;

our $VERSION = "0.06";

use parent 'Plack::Component';

use IIIF::Magick qw(info convert);
use File::Spec;
use Try::Tiny;
use Plack::Request;
use IIIF::Request;
use JSON::PP;
use File::Temp qw(tempdir);
use Digest::MD5 qw(md5_hex);
use HTTP::Date;

use Plack::MIME;
Plack::MIME->add_type( '.jp2',  'image/jp2' );
Plack::MIME->add_type( '.webp', 'image/webp' );

use Cwd;
use Plack::Util;

use Plack::Util::Accessor
  qw(images base cache formats rights service canonical magick_args);

our @FORMATS = qw(jpg png gif);

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->images('.') unless $self->images;
    $self->formats( [qw{jpg png gif}] ) unless $self->formats;

    $self;
}

sub call {
    my ( $self, $env ) = @_;
    my $req = Plack::Request->new($env);

    if ( $req->path_info =~ qr{^/([^/]+)/?(.*)$} ) {
        my ( $identifier, $request ) = ( $1, $2 );
        if ( my $file = $self->file($identifier) ) {
            $file->{id} = ( $self->base // $req->base ) . $identifier;
            return $self->response( $file, $request );
        }
    }

    return error_response( 404, "Not Found" );
}

sub response {
    my ( $self, $file, $local ) = @_;

    # Image Information Request
    if ( $local eq '' ) {
        return redirect( $file->{id} . "/info.json" );
    }
    elsif ( $local eq 'info.json' ) {
        return $self->info_response($file);
    }

    # allow abbreviated requests, redirect to full form
    my $request = eval { IIIF::Request->new($local) };
    if ($@) {
        return error_response( 400, ( split( " at ", $@ ) )[0] );
    }

    $request->{format} = $request->{format} // $file->{format};

    return error_response( 400, "unsupported format" )
      unless grep { $_ eq $request->{format} } @{ $self->formats };

    if ( $self->canonical ) {
        my $info = info( $file->{path} );
        my $canonical = $request->canonical( $info->{width}, $info->{height} )
          or return error_response();
        $request = IIIF::Request->new($canonical);
    }

    if ( "$request" ne $local ) {
        return redirect( $file->{id} . "/$request" );
    }

    # Image Request

    # directly serve unmodified image
    if ( $request->is_default && $request->{format} eq $file->{format} ) {
        return image_response( $file->{path} );
    }

    my $cache = $self->cache // $self->cache( tempdir( CLEANUP => 1 ) );
    my $cache_file = File::Spec->catfile( $cache,
        md5_hex("$request") . ".$request->{format}" );

    if ( -r $cache_file ) {
        return image_response($cache_file);
    }
    else {

        # TODO: only get image dimensions once and only if actually needed
        my $info = info( $file->{path} );
        if ( !$request->canonical( $info->{width}, $info->{height} ) ) {
            return error_response();
        }

        my @args = ( $request, $file->{path}, $cache_file );
        push @args, @{ $self->{magick_args} || [] };
        return image_response($cache_file) if convert(@args);
    }

    error_response( 500, "Conversion failed" );
}

sub info_response {
    my ( $self, $file ) = @_;

    my $info = info(
        $file->{path},
        id      => $file->{id},
        profile => 'level2',

        # TODO: maxWidth or maxArea, maxHeight (required!)

        extraQualities => [qw(color gray bitonal default)],
        extraFormats   => $self->formats,
        extraFeatures  => [
            qw(
              baseUriRedirect cors jsonldMediaType mirroring
              profileLinkHeader
              regionByPct regionByPx regionSquare rotationArbitrary rotationBy90s
              sizeByConfinedWh sizeByH sizeByPct sizeByW sizeByWh sizeUpscaling
              )
        ]
    );

    # TODO: canonicalLinkHeader?

    $info->{rights}  = $self->rights  if $self->rights;
    $info->{service} = $self->service if $self->service;

    return json_response( 200, $info,
        'application/ld+json;profile="http://iiif.io/api/image/3/context.json"'
    );
}

sub file {
    my ( $self, $identifier ) = @_;

    for my $format ( @{ $self->formats } ) {
        my $path = File::Spec->catfile( $self->images, "$identifier.$format" );
        if ( -r $path ) {
            return {
                path   => $path,
                format => $format
            };
        }
    }
}

sub redirect {
    return [ 303, [ Location => $_[0] ], [] ];
}

# adopted from Plack::App::File
sub image_response {
    my ($file) = @_;

    open my $fh, "<:raw", $file
      or return error_response( 403, "Forbidden" );

    my $type = Plack::MIME->mime_type($file) // 'image';
    my @stat = stat $file;

    Plack::Util::set_io_path( $fh, Cwd::realpath($file) );

    return [
        200,
        [
            'Content-Type'   => $type,
            'Content-Length' => $stat[7],
            'Last-Modified'  => HTTP::Date::time2str( $stat[9] ),
            'Link' => '<http://iiif.io/api/image/3/level2.json>;rel="profile"'
        ],
        $fh,
    ];
}

sub json_response {
    my ( $code, $body, $type ) = @_;

    state $JSON = JSON::PP->new->pretty->canonical(1);

    [
        $code,
        [
            'Content-Type' => $type // 'application/json',
            'Link' => '<http://iiif.io/api/image/3/level2.json>;rel="profile"'
        ],
        [ $JSON->encode($body) ]
    ];
}

sub error_response {
    my $code = shift // 400;
    my $message = shift
      // "Invalid IIIF Image API Request: region or size out of bounds";
    json_response( $code, { message => $message } );
}

1;

=head1 NAME

IIIF::ImageAPI - IIIF Image API implementation as Plack application

=head1 SYNOPSIS

    use Plack::Builder;
    use IIIF::ImageAPI;

    builder {
        enable 'CrossOrigin', origins => '*';
        IIIF::ImageAPI->new(
            images  => 'path/to/images',
            base    => 'https://example.org/iiif/',
            formats => [qw(jpg png gif tif pdf webp jp2)],
        );
    }

=head1 CONFIGURATION

=over

=item images

Image directory

=item cache

Cache directory. Set to a temporary per-process directory by default.

=item base

Base URI which the service is hosted at, including trailing slash. Likely
required if the service is put behind a web proxy.

=item canonical

Redirect requests to the L<canonical URI syntax|https://iiif.io/api/image/3.0/#47-canonical-uri-syntax>
and include (disabled by default).

=item formats

List of supported image formats. Set to C<['jpg', 'png', 'gif']> by default. On
configuration with other formats make sure ImageMagick supports them (see
L<IIIF::Magick/REQUIREMENTS>).

=item rights

Optional string that identifies a license or rights statement for all images,
to be included in image information responses.

=item service

Optional array with L<Services|https://iiif.io/api/image/3.0/#58-linking-properties>
to be included in image information responses.

=item magick_args

Additional command line arguments always used when calling ImageMagick. For
instance C<[qw(-limit memory 1GB -limit disk 1GB)]> to limit resources.

=back

=cut
