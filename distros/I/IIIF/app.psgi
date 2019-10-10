use Plack::Builder;
use IIIF::ImageAPI;

my $root = "t/img";

builder {
    enable 'CrossOrigin', origins => '*';
    IIIF::ImageAPI->new(root => $root);
}

