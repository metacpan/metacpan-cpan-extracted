package IIIF::ImageAPI;
use 5.014001;

our $VERSION = "0.07";

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
  qw(images base cache formats rights service canonical magick_args preferredFormats maxWidth maxHeight maxArea);

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

    $request->{format} = $request->{format}
      // ( $self->{preferredFormats} || [] )->[0] // $file->{format};

    return error_response( 400, "unsupported format" )
      unless grep { $_ eq $request->{format} } @{ $self->formats };

    if ( !$self->canonical && "$request" ne $local ) {
        return redirect( $file->{id} . "/$request" );
    }

    my $info = info( $file->{path} );
    my $norm = $request->canonical( $info->{width}, $info->{height}, %$self )
      or return error_response();
    $request = IIIF::Request->new($norm);
    my $canonical = $file->{id} . "/$request";

    if ( $self->canonical && "$request" ne $local ) {
        return redirect($canonical);
    }

    # Image Request

    # directly serve unmodified image
    if ( $request->is_default && $request->{format} eq $file->{format} ) {
        return image_response( $file->{path}, $canonical );
    }

    # cache image segment and directly serve if found
    my $cache = $self->cache // $self->cache( tempdir( CLEANUP => 1 ) );
    my $cache_file = File::Spec->catfile( $cache,
        md5_hex("$request") . ".$request->{format}" );

    if ( -r $cache_file ) {
        return image_response( $cache_file, $canonical );
    }
    else {
        my @args = ( $request, $file->{path}, $cache_file );
        push @args, @{ $self->{magick_args} || [] };
        return image_response( $cache_file, $canonical ) if convert(@args);
    }

    error_response( 500, "Conversion failed" );
}

sub info_response {
    my ( $self, $file ) = @_;

    my $info = info(
        $file->{path},
        id      => $file->{id},
        profile => 'level2',

        extraQualities => [qw(color gray bitonal default)],
        extraFormats   => $self->formats,
        extraFeatures  => [
            qw(
              baseUriRedirect canonicalLinkHeader cors jsonldMediaType mirroring
              profileLinkHeader
              regionByPct regionByPx regionSquare rotationArbitrary rotationBy90s
              sizeByConfinedWh sizeByH sizeByPct sizeByW sizeByWh sizeUpscaling
              )
        ]
    );

    $info->{$_} = $self->{$_}
      for grep { $self->{$_} } qw(maxWidth maxHeight maxArea);

    if ( $self->preferredFormats ) {
        $info->{preferredFormats} = $self->preferredFormats;
    }

    # TODO: canonicalLinkHeader?

    $info->{rights}  = $self->rights  if $self->rights;
    $info->{service} = $self->service if $self->service;

    return json_response( 200, $info,
        'application/ld+json;profile="http://iiif.io/api/image/3/context.json"'
    );
}

sub find_file {
    my ( $self, $identifier ) = @_;

    foreach ( @{ $self->formats } ) {
        my $file = File::Spec->catfile( $self->images, "$identifier.$_" );
        return $file if -r $file;
    }
}

sub file {
    my ( $self, $identifier ) = @_;

    my $path =
      ref $self->images eq 'CODE'
      ? $self->images->($identifier)
      : $self->find_file($identifier);

    if ( -f $path && $path =~ /\.([^.]+)$/ ) {
        if ( grep { $1 eq $_ } @{ $self->formats } ) {
            return {
                path   => $path,
                format => $1
            };
        }
    }
}

sub redirect {
    return [ 303, [ Location => $_[0] ], [] ];
}

# adopted from Plack::App::File
sub image_response {
    my ( $file, $canonical ) = @_;

    open my $fh, "<:raw", $file
      or return error_response( 403, " Forbidden " );

    my $type = Plack::MIME->mime_type($file) // 'image';
    my @stat = stat $file;

    Plack::Util::set_io_path( $fh, Cwd::realpath($file) );

    return [
        200,
        [
            'Content-Type'   => $type,
            'Content-Length' => $stat[7],
            'Last-Modified'  => HTTP::Date::time2str( $stat[9] ),
            'Link' => '<http://iiif.io/api/image/3/level2.json>;rel="profile"',
            'Link' => "<$canonical>;rel=\"canonical\""
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
      // " Invalid IIIF Image API Request : region or size out of bounds ";
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

Either an image directory (set to the current directory by default) or a code
reference of a function that maps image identifiers to image files.

=item cache

Cache directory. Set to a temporary per-process directory by default. Please
use different cache directories for different settings of C<maxWidth> and
C<maxHeight>.

=item base

Base URI which the service is hosted at, including trailing slash. Likely
required if the service is put behind a web proxy.

=item canonical

Redirect requests to the L<canonical URI syntax|https://iiif.io/api/image/3.0/#47-canonical-uri-syntax>
and include (disabled by default). A canonical Link header is set anyway.

=item formats

List of supported image formats. Set to C<['jpg', 'png', 'gif']> by default. On
configuration with other formats make sure ImageMagick supports them (see
L<IIIF::Magick/REQUIREMENTS>).

=item preferredFormats

Optional list of preferred image formats. MUST be a subset of or equal to
C<formats>. The first preferred format, if given, will be used as default if a
request does no specify a file format.

=item maxWidth

Optional maximum width in pixels to be supported.

=item maxHeight

Optional maximum height in pixels to be supported.

=item maxArea

Optional maximum pixel area (width x height) to be supported.

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
