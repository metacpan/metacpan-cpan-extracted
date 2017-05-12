#!perl -w
use strict;
use Test::More tests => 1;
use Image::JpegMinimal;

@ARGV = qw(t/data/IMG_7467.JPG t/data/IMG_7468.JPG);

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
    my @html = join "\n", gen_img(@ARGV);

    # The headers accumulate in $compressor
    my %headers = $compressor->headers;

    # This goes into your Javascript
    #print $headers{l};
    #print $headers{p};

is_deeply [ sort keys %headers ], ['l','p'], "We get the expected headers";