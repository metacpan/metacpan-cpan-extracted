package File::Assets::Filter::Minifier::CSS;

use strict;
use warnings;

use base qw/File::Assets::Filter::Minifier::Base/;
use File::Assets::Carp;

sub minify {
    require CSS::Minifier;
    return CSS::Minifier::minify(input => shift);
}

1;
