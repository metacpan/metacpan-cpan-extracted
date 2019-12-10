package IIIF::Request;
use 5.014001;

our $VERSION = "0.07";

use Plack::Util::Accessor qw(region size rotation quality format);
use Carp qw(croak);
use List::Util qw(min);

our $XY  = qr{[0-9]+};               # non-negative integer
our $WH  = qr{[1-9][0-9]*};          # positive integer
our $NUM = qr{[0-9]*(\.[0-9]+)?};    # non-negative
our $REGION   = qr{full|square|($XY,$XY,$WH,$WH)|pct:($NUM,$NUM,$NUM,$NUM)};
our $SIZE     = qr{(\^)?(max|pct:($NUM)|($WH,)|(,$WH)|(!)?($WH,$WH))};
our $ROTATION = qr{([!])?($NUM)};
our $QUALITY  = qr{color|gray|bitonal|default};
our $FORMAT   = qr{[^.]+};

use overload '""' => \&as_string, fallback => 1;

sub new {
    my $class = shift;
    my $path = shift // "";

    my (
        $rotation, $mirror,     $degree,    $quality, $format,
        $region,   $region_pct, $region_px, $size,    $upscale,
        $size_px,  $size_pct,   $ratio
    );

    my @parts = split '/', $path;

    if ( @parts && $parts[0] =~ /^$REGION$/ ) {
        $region = shift @parts;
        if ($1) {
            $region_px = [ split ',', $1 ];
        }
        elsif ($2) {
            $region_pct = [ map { 1 * $_ } split ',', $2 ];
            error("disallowed percentage value")
              if !$region_pct->[2]
              || !$region_pct->[3]
              || grep { $_ > 100 } @$region_pct;
        }
    }

    if ( @parts && $parts[0] =~ /^$SIZE$/ ) {
        $size    = shift @parts;
        $upscale = $1;
        $ratio   = $7;
        $size_px = [ split ',', $5 // $6 // $8 ] if $5 // $6 // $8;

        if ( defined $3 ) {
            $size_pct = 1 * $3;
            if ($upscale) {
                $size = "^pct:$size_pct";
            }
            else {
                error("disallowed percentage value")
                  if $size_pct == 0.0 || $size_pct > 100.0;
                $size = "pct:$size_pct";
            }
        }
    }

    if ( @parts && $parts[0] =~ /^$ROTATION$/ ) {
        shift @parts;
        $mirror = !!$1;

        # normalize to 0...<360 with up to 6 decimal points
        $degree = 1 * sprintf( "%.6f", $2 - int( $2 / 360 ) * 360 );
        $rotation = $mirror ? "!$degree" : "$degree";
    }

    if ( @parts && $parts[0] =~ /^(($QUALITY)([.]($FORMAT))?|[.]($FORMAT))$/ ) {
        $quality = $2;
        $format = $4 // $5;
        shift @parts;
    }

    error( "failed to parse '" . join( '/', '', @parts ) . "'" )
      if @parts;

    bless {
        region => $region // 'full',
        region_pct => $region_pct,
        region_px  => $region_px,
        size       => $size // 'max',
        upscale    => $upscale,
        size_pct   => $size_pct,
        size_px    => $size_px,
        ratio      => $ratio,
        rotation   => $rotation // '0',
        mirror     => $mirror,
        degree     => $degree,
        quality    => $quality // 'default',
        format     => $format
    }, $class;
}

sub error {
    croak "Invalid IIIF Image API Request: $_[0]";
}

sub canonical {
    my ( $self, $width, $height, %max ) = @_;

    # convert region to /full|x,y,w,h/
    my $region = $self->{region};
    if ( $self->{region} eq 'square' ) {
        my $size = min( $width, $height );
        $region = "0,0,$size,$size";
    }
    elsif ( $self->{region_pct} ) {
        my ( $x, $y, $w, $h ) = @{ $self->{region_pct} };
        $x = pct2px( $x, $width );
        $y = pct2px( $y, $height );
        $w = pct2px( $w, $width ) or return;
        $h = pct2px( $h, $height ) or return;
        $region = "$x,$y,$w,$h";
    }
    elsif ( $self->{region_px} ) {    # region outside of image dimensions?
        my ( $x, $y, $w, $h ) = @{ $self->{region_px} };
        return if $x >= $width && $y >= $height;
    }
    $region = 'full' if $region eq "0,0,$width,$height";

    # proceed with region size
    if ( $region ne 'full' ) {
        ( undef, undef, $width, $height ) = split ',', $region;
    }

    if ( $self->{size_pct} ) {        # too small
        return
          if !pct2px( $self->{size_pct}, $width )
          || !pct2px( $self->{size_pct}, $height );
    }

    # convert size to /[^]?(max|w,h)/
    my $size    = $self->{size};
    my $upscale = $self->{upscale};
    my $ratio   = $self->{ratio};
    my $size_px = $self->{size_px};

    my $maxHeight = $max{maxHeight};
    my $maxWidth = $max{maxWidth} || $maxHeight;

    if ( $size eq '^max' && $maxHeight ) {
        $size_px = [ $maxWidth, $maxHeight ];
        $upscale = 1;
        $ratio   = 1;
        $size    = '^!' . join ',', @$size_px;
    }

    if ( $size !~ /\^?max/ ) {
        if ( $self->{size_pct} ) {
            $size = join ',',
              map { pct2px( $self->{size_pct}, $_ ) } ( $width, $height );
            $size = "^$size" if $upscale;
        }
        else {
            my ( $w, $h ) = @$size_px;
            return if !$w && !$h;
            return if !$upscale && ( $h > $height || $w > $width );

            if ( $w && $h ) {
                if ($ratio) {
                    if ( $w / $h > $width / $height ) {
                        $w = pct2px( 100 * $width / $height, $h );
                    }
                    else {
                        $h = pct2px( 100 * $height / $width, $w );
                    }
                }

                $size = "$w,$h";
            }
            elsif ($w) {
                $size = "$w," . pct2px( 100 * $height / $width, $w );
            }
            elsif ($h) {
                $size = pct2px( 100 * $width / $height, $h ) . ",$h";
            }

            $size = "^$size" if $upscale;
        }

        $size = "max" if $size =~ /^\^?$width,$height$/;
    }

    # give up if image too large
    if ($maxHeight) {
        ( $width, $height ) = ( $1, $2 ) if $size =~ /^\^?(\d+),(\d+)$/;
        return if $width > $maxWidth || $height > $maxHeight;
    }

    my $str = join '/', $region, $size, $self->{rotation}, $self->{quality};
    return defined $self->{format} ? "$str.$self->{format}" : $str;
}

sub pct2px {
    my ( $percent, $value ) = @_;
    return int( $percent * $value / 100 + 0.5 );
}

sub is_default {
    my ($self) = @_;

    return $self->as_string =~ qr{^full/max/0/default};
}

sub as_string {
    my ($self) = @_;

    my $str = join '/', map { $self->{$_} } qw(region size rotation quality);
    return defined $self->{format} ? "$str.$self->{format}" : $str;
}

1;
__END__

=head1 NAME

IIIF::Request - IIIF Image API request object

=head1 SYNOPSIS

    use IIIF::Request;

    my $request = IIIF::Request->new('125,15,120,140/90,/!345/gray.jpg');

=head1 DESCRIPTION

Stores parts of an L<IIIF ImageAPI|https://iiif.io/api/image/3.0/> after
C<{identifier}>:

    {region}/{size}/{rotation}/{quality}.{format}

In contrast to the IIIF Image API Specification, all parts are optional.
Omitted parts are set to their default value, except for C<format> which is
allowed to be undefined.  Parsing of percentage and degree values is more
forgiving than required by the specification as values are normalized (e.g.
removal of redundant digits).  The following additional fields are set if
deriveable form the request:

=over

=item region_pct 

=item region_px

=item upscale

=item size_pct

=item size_px

=item ratio

=item mirror

=item degree

=back

=head1 METHODS

=head2 new( [ $request ] )

Parses a request string. It's ok to only include selected image manipulations.
Will raise an error on invalid requests. The request is parsed independent from
a specific image so regions and sizes outside of the image bound are not
detected as invalid.

=head2 as_string

Returns the full request string. Percentage values and degrees are normalized.

=head2 is_default

Returns whether the request (without format) is the default request
C<full/max/0/default> to get an unmodified image.

=head2 canonical( $width, $height [, %max ] )

Returns the L<canonical request|https://iiif.io/api/image/3.0/#47-canonical-uri-syntax>
for an image of given width and height or C<undef> if this would result in an
invalid request (because region or size would be out of bounds). In contrast to
the specification, the C<format> is not required part of the canonical request.

Optional named arguments C<maxWidth> and C<maxHeight> in C<%max> can be used to
control maximum allowed image size. As specified, C<maxWidth> is ignored unless
C<maxHeight> is also given. Option C<maxArea> is not supported.

=head2 error

Raise an "Invalid IIIF Image API Request" error. Can also be used as function.

=cut
