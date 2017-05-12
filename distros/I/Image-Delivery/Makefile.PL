use strict;
use inc::Module::Install;

name           'Image-Delivery';
all_from       'lib/Image/Delivery.pm';
requires       'File::Spec'            => '0.80';
requires       'IO::Handle'            => 0;
requires       'Digest::MD5'           => 0;
requires       'File::Remove'          => '0.34';
requires       'File::Slurp'           => '9999.04';
requires       'List::Util'            => '1.11';
requires       'HTML::Location'        => '1.00';
requires       'Digest::TransformPath' => '0.01';
requires       'Params::Coerce'        => '0.13';
build_requires 'Test::More'            => '0.47';
build_requires 'Test::ClassAPI'        => '1.04';
build_requires 'IO::File'              => 0;

WriteAll;
