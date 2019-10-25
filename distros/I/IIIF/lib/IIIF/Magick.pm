package IIIF::Magick;
use 5.014001;

our $VERSION = "0.06";

use parent 'Exporter';
our @EXPORT = qw(info available convert convert_command convert_args);

use IPC::Cmd qw(can_run);
use List::Util qw(min);

sub available {
    return can_run("magick") || ( can_run("identify") && can_run("convert") );
}

sub info {
    my $file = shift;

    -f $file or die "$file: No such file\n";
    my $cmd = join ' ', map shell_quote($_), qw(identify -format %Wx%H), $file;

    ( `$cmd` =~ /^(\d+)x(\d+)$/ )
      or die "$file: Failed to get image dimensions";

    return {
        '@context' => 'http://iiif.io/api/image/3/context.json',
        type       => 'ImageService3',
        protocol   => 'http://iiif.io/api/image',
        width      => 1 * $1,
        height     => 1 * $2,
        @_
    };
}

sub convert_args {
    my $req = shift;
    my @args;

    # apply region
    if ( $req->{region} eq 'square' ) {

     # could be simpler in ImageMagick 7:
     # push @args, qw(-gravity center -crop), "%[fx:w>h?h:w]x%[fx:w>h?h:w]+0+0";
        push @args, qw(-set option:distort:viewport
          %[fx:w>h?h:w]x%[fx:w>h?h:w]+%[fx:w>h?(w-h)/2:0]+%[fx:w>h?0:(h-w)/2]
          -filter point -distort SRT 0 +repage);
    }
    elsif ( my $region_px = $req->{region_px} ) {
        my ( $x, $y, $w, $h ) = @$region_px;
        @args = ( '-crop', "${w}x$h+$x+$y" );
    }
    elsif ( my $region_pct = $req->{region_pct} ) {
        my ( $x, $y, $w, $h ) = @$region_pct;

        if ( $x || $y ) {
            my $px = $x / 100;
            my $py = $y / 100;
            push @args, '-set', 'page', "-%[fx:w*$px]-%[fx:h*$py]";
        }

        # could also be simpler in ImageMagick 7
        push @args, '-crop', "${w}x$h%+0+0";
    }

    # apply size
    if ( $req->{size_pct} ) {
        push @args, '-resize', $req->{size_pct} . '%';
    }
    elsif ( $req->{size_px} ) {
        my ( $x, $y ) = @{ $req->{size_px} };

        if ( $x && !$y ) {
            push @args, '-resize', "${x}";
        }
        elsif ( !$x && $y ) {
            push @args, '-resize', "x${y}";
        }
        elsif ( $req->{ratio} ) {
            push @args, '-resize', "${x}x$y";
        }
        else {
            push @args, '-resize', "${x}x$y!";
        }
    }

    # apply rotation
    push @args, '-flop' if $req->{mirror};
    if ( my $degree = $req->{degree} ) {
        push @args, '-rotate', $degree;
        if ( $degree - 90 * int( $degree / 90 ) ) {
            push @args, '-background', 'none';
        }
    }

    # apply quality
    if ( $req->{quality} eq 'gray' ) {
        push @args, qw(-colorspace Gray);
    }
    elsif ( $req->{quality} eq 'bitonal' ) {
        push @args, qw(-monochrome -colors 2);
    }

    return @args;
}

sub convert_command {
    my ( $req, $in, $out ) = splice @_, 0, 3;

    my @cmd = ( 'convert', @_, convert_args($req) );
    push @cmd, $in  if defined $in  and $in ne '';
    push @cmd, $out if defined $out and $out ne '';
    unshift @cmd, "magick" if can_run("magick");

    return join ' ', map shell_quote($_), @cmd;
}

sub convert {
    my $command = convert_command(@_);
    qx{$command};
    return !$?;
}

# adopted from <https://metacpan.org/release/ShellQuote-Any-Tiny>
sub shell_quote {
    my $arg = shift;

    if ( $^O eq 'MSWin32' ) {
        if ( $arg !~ /\A[\w_+-]+\z/ ) {
            $arg =~ s/\\(?=\\*(?:"|$))/\\\\/g;
            $arg =~ s/"/\\"/g;
            return qq("$arg");
        }
    }
    elsif ( $arg !~ qr{\A[\w,_+/.-]+\z} ) {
        $arg =~ s/'/'"'"'/g;
        return "'$arg'";
    }

    return $arg;
}

1;
__END__

=head1 NAME

IIIF::Magick - transform image with IIIF Image API Request using Image Magick

=head1 SYNOPSIS

    use IIIF::Magick qw(info convert);

    my $info = info($file, profile => "level0", id => "...") ;
    
    convert( $request, $file, "target.png" );

=head1 DESCRIPTION

This module maps L<IIIF ImageAPI|https://iiif.io/api/image/3.0/> request
parameters to L<ImageMagick|https://www.imagemagick.org/> command line
arguments. See L<i3f> (command line) and L<IIIF::ImageAPI> (web service)
for applications that make use of it.

=head1 REQUIREMENTS

Function C<info> and C<convert> require ImageMagick to be installed. Converting
to PDF and/or WebP may not be enabled by default. For instance at Ubuntu Linux
remove the line

  <policy domain="coder" rights="none" pattern="PDF" />

fro C</etc/ImageMagick*/policy.xml> and install WebP support via:

  sudo apt-get install webp libwebp-dev

=head1 FUNCTIONS

=head2 available

Returns whether ImageMagick is available.

=head2 info( $file [, id => $id ] [, profile => $profile ] )

Returns L<image information|https://iiif.io/api/image/3.0/#5-image-information>
object with fields C<@context>, C<type>, C<profile>, C<width>, and C<height>.
Fields C<id> and C<profile> must be added for full IIIF compliance.

=head2 convert( $request, $file, $output [, @args ] )

Convert an image file as specified with a L<IIIF::Request> into an output file.
Returns true on success. Additional arguments are prepended to the call of
ImageMagick's C<convert>.

Requires at least ImageMagick 6.9.

=head2 convert_command( $request, $file, $output [, @args ] )

Get a shell-quoted command to convert an image with a L<IIIF::Request>.

=head2 convert_args( $request )

Get the list of command line arguments to C<convert> to transform an image file
as specified via a L<IIIF::Request>.

=head2 LIMITATIONS

The upscale option of L<size|https://iiif.io/api/image/3.0/#42-size> parameter
is ignored: size C<^max> will not upscale the image as the resulting size
depends on additional variables C<maxWidth>, C<maxHeight>, C<maxArea>. 

The IIIF Image API Request is not validated before processing. Sizes larger
than the selected region will therefore always result in an upscaled image.
Use method C<canonical> of L<IIIF::Request> to filter out such invalid
requests.

=cut
