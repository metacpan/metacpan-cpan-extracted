package File::Assets::Filter::Minifier::JavaScript;

use strict;
use warnings;

use base qw/File::Assets::Filter::Minifier::Base/;
use File::Assets::Carp;

sub minify {
    require JavaScript::Minifier;
    return JavaScript::Minifier::minify(input => shift);
}

1;
