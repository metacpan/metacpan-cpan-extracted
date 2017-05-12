package File::Assets::Filter::Minifier::Best;

use strict;
use warnings;

use base qw/File::Assets::Filter::Minifier/;
use File::Assets::Carp;

sub signature {
    return "minifier-best";
}

my %best;
sub _css_minifier {
    return $best{css} ||= 
        File::Assets::Filter::Minifier::CSS::XS->_minifier_package_is_available ?
        \&File::Assets::Filter::Minifier::CSS::XS::minify :
        \&File::Assets::Filter::Minifier::CSS::minify
    ;
}

sub _js_minifier {
    return $best{js} ||= 
        File::Assets::Filter::Minifier::JavaScript::XS->_minifier_package_is_available ?
        \&File::Assets::Filter::Minifier::JavaScript::XS::minify :
        \&File::Assets::Filter::Minifier::JavaScript::minify
    ;
}

1;
