package HTTP::CDN::JavaScript::Minifier::XS;
{
  $HTTP::CDN::JavaScript::Minifier::XS::VERSION = '0.8';
}

use strict;
use warnings;
use JavaScript::Minifier::XS qw(minify);

sub preprocess {
    my ($cdn, $file, $stat, $fileinfo) = @_;

    return unless $fileinfo->{mime} and $fileinfo->{mime}->type eq 'application/javascript';

    $fileinfo->{data} = minify($cdn->_fileinfodata($fileinfo));
}

1;
