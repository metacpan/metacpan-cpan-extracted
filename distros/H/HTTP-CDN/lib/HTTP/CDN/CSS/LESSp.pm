package HTTP::CDN::CSS::LESSp;
{
  $HTTP::CDN::CSS::LESSp::VERSION = '0.8';
}

use strict;
use warnings;
use CSS::LESSp;

$HTTP::CDN::mimetypes->addType(
    MIME::Type->new(
        type => 'text/less',
        extensions => ['less'],
    ),
);

sub preprocess {
    my ($cdn, $file, $stat, $fileinfo) = @_;

    return unless $fileinfo->{mime} and $fileinfo->{mime}->type eq 'text/less';

    $fileinfo->{mime} = $HTTP::CDN::mimetypes->type('text/css');
    $fileinfo->{data} = join('', CSS::LESSp->parse($cdn->_fileinfodata($fileinfo)));
}

1;
