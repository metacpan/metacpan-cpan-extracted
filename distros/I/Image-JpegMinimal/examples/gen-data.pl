#!perl -w
use strict;
use Imager;
use Image::JpegMinimal;
use File::Glob 'bsd_glob';

BEGIN {
    # Glob filespec if on Windows
    warn "@ARGV";
    if( $^O =~ /mswin/i ) {
        @ARGV= map { s!\\!/!g; bsd_glob( $_ ) } @ARGV;
    };
};


my $compressor = Image::JpegMinimal->new(
    xmax => 42,
    ymax => 42,
    jpegquality => 20,
);

sub gen_html {
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
    
    # The headers accumulate in $compressor
    my %headers = $compressor->headers;

    my $html = <<HTML;
<!DOCTYPE html><html><meta charset='utf-8'>
<head>
</head>
<body>
@tags
<script>
"use strict";

var header = {
    l : atob("$headers{l}"),
    p : atob("$headers{p}"),
}
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
    var reconstructed = patched_header+payload;
    // XXX Patch appropriate width and height into the header
    var encoded = "data:image/jpeg;base64,"+btoa(reconstructed);
    // Why are we missing this part?! Or some parts at all?!
    //encoded = encoded.substring(0,encoded.length-3)+"//Z";
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
            window.setTimeout(function() {
                img.src = src;
            }, timeout);
        }(img,container,fullsrc));
    } else {
        // Image has already been loaded (from cache), nothing to do here
    };
};
</script>
</body>
</html>
HTML

    return ($html);
}

my($html) = gen_html(@ARGV);

open my $fh, '>', 'tmp.html'
    or die "Couldn't write 'tmp.html': $!";
binmode $fh;
print $fh $html;
