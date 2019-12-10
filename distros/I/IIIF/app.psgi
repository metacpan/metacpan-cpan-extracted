use Plack::Builder;
use IIIF::ImageAPI;

my $images = "t/img";

builder {
    enable 'CrossOrigin', origins => '*';
    IIIF::ImageAPI->new(
        images  => $images,
        maxHeight => 50,
        formats => [qw(jpg png gif tif pdf webp jp2)],
    );
};
