package Oreo::View;
use strict;
use warnings;

use Markapl;
use JiftyX::Markapl::Helpers;

sub page(&) {
    my $content_cb = shift;
    return sub {
        outs_raw ("<!doctype html>\n");
        html {
            head {
                title { "Oreo" };
            };
            body {
                div("#doc") {
                    $content_cb->();
                }
            }
        };
    }
};


template '/' => page {
    h1 { "Hi, I am Oreo" };

    p {
        outs_raw q{<a href="http://www.flickr.com/photos/gugod/2050976269/" title="Flickr 上 gugod 的 IMG 1714"><img src="http://farm3.static.flickr.com/2132/2050976269_db8d55747b.jpg" width="500" height="332" alt="IMG 1714" /></a>};
    };
};

1;

