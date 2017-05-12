package File::Assets::Filter::Minifier::XS;

use strict;
use warnings;

use base qw/File::Assets::Filter::Minifier/;
use File::Assets::Carp;

sub signature {
    return "minifier-xs";
}

sub _css_minifier {
    return \&File::Assets::Filter::Minifier::CSS::XS::minify;
}

sub _js_minifier {
    return \&File::Assets::Filter::Minifier::JavaScript::XS::minify;
}

1;
