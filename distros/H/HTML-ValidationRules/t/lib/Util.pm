package t::lib::Util;
use strict;
use warnings;
use File::Spec;
use FindBin;
use lib File::Spec->catfile($FindBin::Bin, '..', 'lib');
use lib File::Spec->catfile($FindBin::Bin, 'lib');

sub data_file ($) {
    File::Spec->catfile($FindBin::Bin, 'data', $_[0]);
}

!!1;
