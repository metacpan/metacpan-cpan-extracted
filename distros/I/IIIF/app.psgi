use Plack::Builder;
use IIIF::ImageAPI;

my $images = "t/img";

builder {
    enable 'CrossOrigin', origins => '*';
    IIIF::ImageAPI->new(images => $images);
}

