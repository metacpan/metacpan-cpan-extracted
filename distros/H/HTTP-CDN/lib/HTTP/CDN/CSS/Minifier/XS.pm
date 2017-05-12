package HTTP::CDN::CSS::Minifier::XS;
{
  $HTTP::CDN::CSS::Minifier::XS::VERSION = '0.8';
}

use strict;
use warnings;
use CSS::Minifier::XS qw(minify);

sub preprocess {
    my ($cdn, $file, $stat, $fileinfo) = @_;

    return unless $fileinfo->{mime} and $fileinfo->{mime}->type eq 'text/css';

    $fileinfo->{data} = minify($cdn->_fileinfodata($fileinfo));
}

1;
