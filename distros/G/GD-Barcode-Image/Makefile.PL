use ExtUtils::MakeMaker;
use 5.005;
WriteMakefile(
    'NAME'	=> 'GD::Barcode::Image',
    'VERSION_FROM' => 'lib/GD/Barcode/Image.pm', # finds $VERSION
    'EXE_FILES'  => [ 'bin/barcodegen' ],
    'ABSTRACT' => 'Script to create images of barcodes',
    'AUTHOR'   => 'Avinash Chopde <avinash@acm.org>',
    'PREREQ_PM' => { 'GD::Barcode' => 0, 'GD' => 0,  'Image::Magick' => 0, },
);
