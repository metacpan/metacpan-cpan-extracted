package IIIF::Magick;
use 5.014001;

our $VERSION = "0.04";

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(info available convert args);

use IPC::Cmd qw(can_run);
use List::Util qw(min);

sub available {
    return can_run("magick") || ( can_run("identify") && can_run("convert") );
}

sub info {
    my $file = shift;

    -f $file or die "$file: No such file\n";
    my $out = run( qw(identify -format %Wx%H), $file );

    ( $out =~ /^(\d+)x(\d+)$/ ) or die "$file: Failed to get image dimensions";

    return {
        '@context' => 'http://iiif.io/api/image/3/context.json',
        type       => 'ImageService3',
        protocol   => 'http://iiif.io/api/image',
        width      => 1 * $1,
        height     => 1 * $2,
        @_
    };
}

sub args {
    my ( $req, $file ) = @_;

    my @args;

    # apply region
    if ( $req->{region} eq 'square' ) {
        my $info = info($file);
        if ( $info->{width} ne $info->{height} ) {
            my $size = min( $info->{width}, $info->{height} );
            @args = ( qw(-gravity center -crop), "${size}x${size}+0+0" );
        }
    }
    elsif ( my $region_px = $req->{region_px} ) {
        my ( $x, $y, $w, $h ) = @$region_px;
        @args = ( '-crop', "${w}x$h+$x+$y" );
    }
    elsif ( my $region_pct = $req->{region_pct} ) {
        my ( $x, $y, $w, $h ) = @$region_pct;

        my $info = info($file);
        $x = int( $x * $info->{width} / 100 + 0.5 );
        $y = int( $y * $info->{height} / 100 + 0.5 );

        @args = ( '-crop', "${w}x$h%+$x+$y" );
    }

    # apply size
    if ( $req->{size_pct} ) {
        push @args, '-resize', $req->{size_pct} . '%';
    }
    elsif ( $req->{size_px} ) {
        my ( $x, $y ) = @{ $req->{size_px} };

        # TODO: respect upscale

        if ( $x && $y ) {
            if ( $req->{ratio} ) {
                push @args, '-resize', "${x}x$y";
            }
            else {
                push @args, '-resize', "${x}x$y!";
            }
        }
        elsif ( $x && !$y ) {
            push @args, '-resize', "${x}";
        }
        elsif ( !$x && $y ) {
            push @args, '-resize', "x${y}";
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

    push @args, $file if defined $file;

    return @args;
}

# adopted from <https://metacpan.org/release/ShellQuote-Any-Tiny>
sub shell_quote {
    my $arg = shift;

    if ( $^O eq 'MSWin32' ) {
        if ( $arg =~ /\A\w+\z/ ) {
            return $arg;
        }
        $arg =~ s/\\(?=\\*(?:"|$))/\\\\/g;
        $arg =~ s/"/\\"/g;
        return qq("$arg");
    }
    else {
        if ( $arg =~ qr{\A[\w,_+/.-]+\z} ) {
            return $arg;
        }
        $arg =~ s/'/'"'"'/g;
        return "'$arg'";
    }
}

sub convert {
    my ( $req, $in, $out, @args ) = @_;

    run( 'convert', @args, args( $req, $in ), $out );
    return !$?;
}

sub run {
    unshift @_, "magick" if can_run("magick");
    my $command = join ' ', map &shell_quote, @_;
    qx{$command};
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

=head1 FUNCTIONS

=head2 available

Returns whether ImageMagick is available.

=head2 info( $file [, id => $id ] [, profile => $profile ] )

Returns L<image information|https://iiif.io/api/image/3.0/#5-image-information>
object with fields C<@context>, C<type>, C<protocol>, C<width>, and C<height>.
Fields C<id> and C<profile> must be added for full IIIF compliance.

=head2 convert( $request, $file, $output [, @args ] )

Convert an image file as specified with a L<IIIF::Request> into an output file.
Returns true on success. Additional arguments are prepended to the call of
ImageMagick's C<convert>.

=head2 args( $request, $file )

Get the list of command line arguments to C<convert> to transform an image file
as specified via a L<IIIF::Request>.

=cut
