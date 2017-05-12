package HTTP::CDN::CSS::LESSJS;
{
  $HTTP::CDN::CSS::LESSJS::VERSION = '0.8';
}

use strict;
use warnings;
use HTTP::CDN::CSS;

$HTTP::CDN::mimetypes->addType(
    MIME::Type->new(
        type => 'text/less',
        extensions => ['less'],
    ),
);

sub preprocess {
    my ($cdn, $file, $stat, $fileinfo) = @_;

    return unless $fileinfo->{mime} and $fileinfo->{mime}->type eq 'text/less';

    $fileinfo->{data} = $cdn->_fileinfodata($fileinfo);

    open my $fh, '-|', 'lessc', $fileinfo->{fullpath};
    local $/ = undef;
    $fileinfo->{data} = <$fh>;
    close $fh;

    $fileinfo->{mime} = $HTTP::CDN::mimetypes->type('text/css');
}

1;
