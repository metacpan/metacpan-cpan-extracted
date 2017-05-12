use strict;
use warnings;

use Test::More 'no_plan';
use Data::Dumper;
use Test::Exception;


BEGIN { use_ok 'Graphics::DZI' }

use constant DONE => 1;

if (DONE) {
    throws_ok {
	my $dzi = new Graphics::DZI (image => 23,
				     overlap  => 4,
				     tilesize => 128,
	    );
    } qr/Validation failed/i, 'invalid image';

    use Image::Magick;
    my $image = Image::Magick->new (size=> "100x50");
    $image->Read('xc:white');
    my $dzi = new Graphics::DZI (image => $image,
				 overlap  => 4,
				 tilesize => 128,
	);

    isa_ok ($dzi, 'Graphics::DZI');

    like ($dzi->descriptor, qr/xml/,         'XML descriptor exists');
    like ($dzi->descriptor, qr/Width='100'/, 'XML descriptor width');
    like ($dzi->descriptor, qr/Height='50'/, 'XML descriptor height');

    is ($dzi->tilesize, 128, 'tilesize echo');
    is ($dzi->overlap,    4, 'overlap echo');
}

if (DONE) {
    use Image::Magick;
    my $image = Image::Magick->new (size=> "100x50");
    $image->Read('xc:white');
    use Graphics::DZI::Files;
    my $dzi = new Graphics::DZI::Files (image => $image,
					prefix => 'xxx',
					path   => '/tmp/',
	);

    isa_ok ($dzi, 'Graphics::DZI::Files');
    is ($dzi->path,    '/tmp/', 'path echo');
}

__END__
