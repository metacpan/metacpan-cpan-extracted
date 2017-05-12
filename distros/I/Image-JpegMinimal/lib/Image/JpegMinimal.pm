package Image::JpegMinimal;
use strict;
use Imager;
use Carp qw(croak carp);
use MIME::Base64 'encode_base64';

use vars '$VERSION';
$VERSION = '0.02';

=head1 NAME

Image::JpegMinimal - create JPEG previews without headers

=head1 SYNOPSIS

    my $compressor = Image::JpegMinimal->new(
        xmax => 42,
        ymax => 42,
        jpegquality => 20,
    );

    sub gen_img {
        my @tags;
        for my $file (@_) {
            my $imager = Imager->new( file => $file );
            my $preview = $compressor->data_preview( $file );
            my ($w, $h ) = ($imager->getwidth,$imager->getheight);
        
            my $html = <<HTML;
    <img width="${w}px" height="${h}px"
       data-preview="$preview"
       src="$file"
       />
    HTML
            push @tags, $html;
        };
        
        return @tags
    }

    # This goes into your HTML
    print join "\n", gen_img(@ARGV);

    # The headers accumulate in $compressor
    my %headers = $compressor->headers;
    
    # This goes into your Javascript
    print $headers{l};
    print $headers{p};

=head1 DESCRIPTION

This module implements the ideas from
L<https://code.facebook.com/posts/991252547593574>
to create the data needed for inline previews of images that can be served
within the HTML page while keeping a low overhead of around 250 bytes per
image preview. This is achieved by splitting up the preview image into
a JPEG header which is common to all images and the JPEG image data.
With a Javascript-enabled browser, these previews will be shown until
the request for the real image has finished loading the data. This reduces
the latency and bandwidth needed until the user sees an image.

It turns the following image

=for html
  <img width="285" height="427" src="t/data/IMG_7468.JPG" />
  <img width="285" height="427" src="../../t/data/IMG_7468.JPG" />

into 250 bytes of image data representing this image:

=for html
  <img width="28" height="42" src="t/data/IMG_7468_preview.JPG" />
  <img width="28" height="42" src="../../t/data/IMG_7468_preview.JPG" />

The Javascript on the client side then scales and blurs that preview
image to create a very blurry placeholder until the real image data
arrives from the server.

=for html
  <img width="285" height="427" src="t/data/IMG_7468_blurred.JPG" />
  <img width="285" height="427" src="../../t/data/IMG_7468_blurred.JPG" />

See below for the Javascript needed to reassemble the image data
from the split header and scan data.

=head1 METHODS

=head2 C<< Image::JpegMinimal->new( %OPTIONS ) >>

  my $compressor = Image::JpegMinimal->new(
      xmax => 42,
      ymax => 42,
      jpegquality => 20,
  );

Creates a new compressor object. The C<xmax> and C<ymax> values
give the maximum dimensions for the size of the preview image.
It is suggested that the preview image is heavily blurred when
presenting the preview image to the user to hide the JPEG artifacts.

=cut

sub new {
    my( $class, %options ) = @_;

    # We really need Jpeg-support
    croak "We really need jpeg support but your version of Imager doesn't support it"
        unless $Imager::formats{'jpeg'};

    $options{ jpegquality } ||= 20;
    $options{ xmax } ||= 42;
    $options{ ymax } ||= 42;

    bless \%options => $class
}

sub get_imager {
    my( $self, $file ) = @_;
    # We should check that Imager can write jpeg images
    Imager->new( file => $file )
        or croak "Couldn't read $file: " . Imager->errstr();
}

sub compress_image {
    my( $self, $file, $xmax, $ymax, $jpegquality ) = @_;
    $xmax ||= $self->{xmax};
    $ymax ||= $self->{ymax};
    $jpegquality ||= $self->{jpegquality};
    my $imager = $self->get_imager( $file );
    
    # Rotate if EXIF data indicates portrait, this wrecks our headers,
    # so disabled :-((
    # We need two headers, one for portrait and one for landscape
    if( my $orientation = $imager->tags(name => 'exif_orientation')) {
        my %rotate = (
            1 => 0,
            #2 => 180,
            3 => 180,
            #4 => 0,
            #5 => 90,
            6 => 270,
            #7 => 0,
            8 => 90,
        );
        my $deg = $rotate{ $orientation };
        $imager = $imager->rotate( right => $deg );
    };
    
    # Resize
    $imager = $imager->scale(xpixels=> $xmax, ypixels=> $ymax, type=>'min')
        or die Imager->errstr;
    # Write with Q20
    $imager->write(type => 'jpeg', data => \my $data, jpegquality => $jpegquality);

    # Debug output for checking the original and reconstruction
    # of the image data in base64
    #(my $data64 = encode_base64($data)) =~ s!\s+!!g;
    #print $data64,"\n";
    
    my( $width,$height ) = ($imager->getheight, $imager->getwidth);
    return ($width,$height,$data);
}

sub strip_header {
    my( $self,$width,$height,$jpeg ) = @_;
    
    # Deparse the JPEG file into its sections
    # Maybe some other module already provides a JPEG header parser?
    my @sections;
    while($jpeg =~ /\G(((\x{ff}[^\0\x{d8}\x{d9}])(..))|\x{ff}\x{d8}|\x{ff}\x{d9})/csg) {
        my $header = $3 || $1;
        my $payload;
        if( $header eq "\x{ff}\x{da}" ) {
            # Start of scan
            $payload = substr( $jpeg, pos($jpeg)-2, length($jpeg)-pos($jpeg)+2);
            pos($jpeg) = pos($jpeg) + length $payload;
        } elsif( $header eq "\x{ff}\x{d8}" ) {
            # Start of image
            $payload = "";
        } elsif( $header eq "\x{ff}\x{d9}" ) {
            # End of Image
            $payload = "";
        } else {
            my $length = unpack "n", $4;
            $payload = substr( $jpeg, pos($jpeg)-2, $length );
            pos($jpeg) = pos($jpeg) + $length -2;
        };
        push @sections, { type => $header, payload => $payload }
    };

    my %priority = (
        "\x{ff}\x{d8}" =>  0,
        "\x{ff}\x{c4}" =>  1,
        "\x{ff}\x{db}" =>  2,
        "\x{ff}\x{c0}" => 50,
        "\x{ff}\x{da}" => 98,
        "\x{ff}\x{d9}" => 99,
    );
    
    # Only keep the important sections
    @sections = grep { exists $priority{ $_->{type}}} @sections;
    # Reorder them so that the image dimensions are at the end
    @sections = sort {$priority{$a->{type}} <=> $priority{$b->{type}}} @sections;
    
    #for my $s (@sections) {
    #    print sprintf "%02x%02x - %04d\n", unpack( "CC", $s->{type}), length $s->{payload};
    #};

    # Reassemble the (relevant) sections
    my $header = join "",
                 map { $_->{type}, $_->{payload }}
                 grep { $_->{type} ne "\x{ff}\x{da}" and $_->{type} ne "\x{ff}\x{d9}" }
                 @sections;
    
    my $payload = join "",
                 map { $_->{type}, $_->{payload }}
                 grep { $_->{type} eq "\x{ff}\x{da}" or $_->{type} eq "\x{ff}\x{d9}" }
                 @sections;

    my $min_header = $header;
                 
    # Do the actual packing
    my $stripped = pack "CCA*", $width, $height, $payload;

    ($stripped,$min_header)
};

sub btoa {
    my( $self, $data ) = @_;
    (my $res64 = encode_base64($data)) =~ s!\s+!!g;
    $res64
}

sub split_image {
    my( $self, $file, $xmax, $ymax ) = @_;
    $xmax ||= $self->{xmax};
    $ymax ||= $self->{ymax};
    
    my($width,$height, $data) = $self->compress_image( $file, $xmax, $ymax );
    my $orientation = $self->get_orientation( $width, $height );
    my( $payload, $min_header ) = $self->strip_header( $width,$height,$data );
    $self->{header}->{$orientation} ||= $self->btoa( $min_header );
    
    carp "Inconsistent header data"
        if $self->{header}->{$orientation} ne $self->btoa( $min_header );
    return ($payload, $min_header)
};

=head2 C<< $compressor->data_preview >>

  my $data_preview = $compressor->data_preview( $file );

Reads the JPEG data from a file and returns a base64 encoded string of
the reduced image data. You stuff this into the C<< data-preview >>
attribute of the C<< img >> tag in your HTML.

=cut

sub data_preview {
    my( $self, $file, $xmax, $ymax ) = @_;
    $xmax ||= $self->{xmax};
    $ymax ||= $self->{ymax};
    
    my( $payload, $min_header ) = $self->split_image( $file, $xmax, $ymax );
    
    my $payload64 = $self->btoa($payload);

    return $payload64;
}

sub get_orientation {
    my( $self, $w, $h ) = @_;
    if( $w < $h ) {
        return 'p' # portrait
    } else {
        return 'l' # landscape
    };
};

=head2 C<< $compressor->headers >>

  my %headers = $compressor->headers;

After processing all files, this method
returns the headers that are common to the images.
You need to pass this to your Javascript.

=cut

sub headers {
    my( $self, $file, $xmax, $ymax ) = @_;
    $xmax ||= $self->{xmax};
    $ymax ||= $self->{ymax};
    
    if( 2 != scalar values %{ $self->{ header }}) {
        # We need to extract at least one header from the image
        my( $data, $header) = $self->split_image( $file, $xmax, $ymax );
        # sets one entry in $self->{header} as a side effect
    };
    
    %{ $self->{header} };
}

=head1 HTML

Each image that has a pre-preview placeholder will need to store the
placeholder data in the C<< data-preview >> attribute. That is all
the modification you need. You should also set the C<< width >>
and C<< height >> attributes of the image so that no ugly image-popping
occurs when the real data arrives. The C<< $payload64 >> is the data
that is returned from the C<< ->data_preview >> call.

    <img width="${final_width}px" height="${final_height}px"
       data-preview="$payload64"
       src="$file"
       />

=head1 JAVASCRIPT

You will need to include some Javascript like the following in your
page, preferrably near the end so the code runs right after
the HTML has loaded completely but image loading has not yet fired.

The hash C<%headers> should be set to the base64
encoded fixed headers as returned by the C<< ->headers( $file ) >> call.
The image HTML should have been constructed as outlined above.

    "use strict";

    var header = {
        l : atob("$headers{l}"),
        h : atob("$headers{p}"),
    };
    function reconstruct(data) {
        // Reconstruct a JPEG header from our special data structure
        var raw = atob(data);
        // Keep as "char" so we don't have to bother with Unicode vs. ASCII
        var width  = raw.charAt(0);
        var height = raw.charAt(1);
        var payload = raw.substring(2,raw.length);
        var head;
        if( width < height ) {
            head = header["p"]
        } else {
            head = header["l"]
        };
        var dimension_patch = width+height;
        var patched_header = head.substring(0,head.length-13)
                           + width
                           + head.substring(head.length-12,head.length-11)
                           + height
                           + head.substring(head.length-10,head.length);
        var reconstructed = patched_header+payload;
        var encoded = "data:image/jpeg;base64,"+btoa(reconstructed);
        return encoded;
    }

    var image_it = document.evaluate("//img[\@data-preview]",document, null, XPathResult.ANY_TYPE, null);
    var images = [];
    var el = image_it.iterateNext();
    while( el ) {
        images.push(el);
        el = image_it.iterateNext();
    };

    for( var i = 0; i < images.length; i++ ) {
        var el = images[ i ];
        if( !el.complete || el.naturalWidth == 0 || el.naturalHeight == 0) {
        
            var fullsrc = el.src;
            var loadsrc = reconstruct( el.getAttribute("data-preview"));
            var container = document.createElement('div');
            container.style.overflow = "hidden";
            container.style.display = "inline";
            container.style.position = "relative";

            var parent = el.parentNode;
            parent.insertBefore(container, el);
            container.appendChild(el);

            // Set up the placeholder data
            el.src = loadsrc;
            el.style.filter = "blur(8px)";
            var img = document.createElement('img');
            img.width = el.width;
            img.height = el.height;
            // Shouldn't we also copy the style and maybe even some events?!
            // img = el.cloneNode(true); // except this doesn't copy the eventListeners etc. Duh.
            (function(img,container,src) {
                img.onload = function() {
                    // Put the loaded child in the place of the preloaded data
                    parent.replaceChild(img,container);
                };
                var timeout = 1000+Math.random()*3000;
                // Kick off the loading
                // The timeout is just for demonstration purposes
                // window.setTimeout(function() {
                    img.src = src;
                //}, timeout);
            }(img,container,fullsrc));
        } else {
            // Image has already been loaded (from cache), nothing to do here
        };
    };

=head1 REPOSITORY

The public repository of this module is 
L<http://github.com/Corion/image-jpegminimal>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Image-JpegMinimal>
or via mail to L<jpeg-minimal-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2015 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut

1;